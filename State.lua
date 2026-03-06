local _, addon = ...

addon.state = {}

local state = addon.state

local GCD_SPELL_ID = 61304

local function safeEnum(powerTypeName, fallback)
    if Enum and Enum.PowerType and Enum.PowerType[powerTypeName] ~= nil then
        return Enum.PowerType[powerTypeName]
    end
    return fallback
end

local POWER = {
    holyPower = safeEnum("HolyPower", 9),
    astralPower = safeEnum("LunarPower", 8),
    comboPoints = safeEnum("ComboPoints", 4),
    energy = safeEnum("Energy", 3),
    mana = safeEnum("Mana", 0),
    rage = safeEnum("Rage", 1),
    focus = safeEnum("Focus", 2),
    runicPower = safeEnum("RunicPower", 6),
    soulShards = safeEnum("SoulShards", 7),
    insanity = safeEnum("Insanity", 13),
    fury = safeEnum("Fury", 17),
    pain = safeEnum("Pain", 18),
    chi = safeEnum("Chi", 12),
    essence = safeEnum("Essence", 19),
}

local function normalizeNumber(value)
    if type(value) == "number" then
        return value
    end

    local okToNumber, num = pcall(tonumber, value)
    if okToNumber and type(num) == "number" then
        return num
    end

    local okToString, text = pcall(tostring, value)
    if okToString and type(text) == "string" then
        local extracted = text:match("[-+]?%d+%.?%d*")
        if extracted then
            local parsed = tonumber(extracted)
            if type(parsed) == "number" then
                return parsed
            end
        end
    end

    local okCoerce, coerced = pcall(function()
        return value + 0
    end)
    if okCoerce and type(coerced) == "number" then
        return coerced
    end

    return nil
end

local function safeCooldownRemaining(startTime, duration)
    local ok, result = pcall(function()
        local s = normalizeNumber(startTime)
        local d = normalizeNumber(duration)
        if not s or not d or s <= 0 or d <= 0 then
            return 0
        end

        return math.max(0, (s + d) - GetTime())
    end)

    if ok and type(result) == "number" then
        return result
    end

    return 0
end

local function getCooldownRemaining(spellID)
    if C_Spell and C_Spell.GetSpellCooldown then
        local info = C_Spell.GetSpellCooldown(spellID)
        if info then
            return safeCooldownRemaining(info.startTime, info.duration)
        end
    end

    local a, b = GetSpellCooldown(spellID)
    local startTime = a
    local duration = b
    if type(a) == "table" then
        startTime = a.startTime
        duration = a.duration
    end

    return safeCooldownRemaining(startTime, duration)
end

local function getCharges(spellID)
    if C_Spell and C_Spell.GetSpellCharges then
        local info = C_Spell.GetSpellCharges(spellID)
        if info then
            return info.currentCharges or 0, info.maxCharges or 0
        end
    end

    local charges, maxCharges = GetSpellCharges(spellID)
    return charges or 0, maxCharges or 0
end

local function isSpellInRangeSafe(spellID, unit)
    if C_Spell and C_Spell.IsSpellInRange then
        local inRange = C_Spell.IsSpellInRange(spellID, unit)
        if inRange ~= nil then
            return inRange
        end
    end

    return nil
end

local function isSpellKnown(spellID)
    if C_Spell and C_Spell.IsSpellUsable then
        local usable = C_Spell.IsSpellUsable(spellID)
        if usable ~= nil then
            return IsSpellKnownOrOverridesKnown(spellID)
        end
    end

    return IsSpellKnownOrOverridesKnown(spellID)
end

local function isSpellUsableSafe(spellID)
    if C_Spell and C_Spell.IsSpellUsable then
        local a, b = C_Spell.IsSpellUsable(spellID)
        if type(a) == "table" then
            local usable = a.usable
            local noMana = a.noMana
            if usable ~= nil then
                return usable, noMana
            end
        elseif a ~= nil then
            return a, b
        end
    end

    if IsUsableSpell then
        return IsUsableSpell(spellID)
    end

    return true, false
end

local function findAuraBySpellID(unit, spellID, filter)
    if AuraUtil and AuraUtil.FindAuraBySpellID then
        local aura = AuraUtil.FindAuraBySpellID(spellID, unit, filter)
        if aura then
            local expirationTime = aura.expirationTime or select(6, aura)
            local applications = aura.applications or select(3, aura) or 0
            local now = GetTime()
            local remaining = 0
            if expirationTime and expirationTime > 0 then
                remaining = math.max(0, expirationTime - now)
            end

            return true, remaining, applications
        end
    end

    return false, 0, 0
end

function state:Init()
    self.last = {}
end

function state:Build()
    local now = GetTime()
    local targetExists = UnitExists("target") and not UnitIsDead("target") and UnitCanAttack("player", "target")
    local inCombat = UnitAffectingCombat("player")
    local specIndex = GetSpecialization()
    local specID = specIndex and GetSpecializationInfo(specIndex) or 0
    local _, classTag = UnitClass("player")
    local primaryPowerType, primaryPowerToken = UnitPowerType("player")

    local holyPower = UnitPower("player", POWER.holyPower)
    local maxHolyPower = UnitPowerMax("player", POWER.holyPower)
    local astralPower = UnitPower("player", POWER.astralPower)
    local maxAstralPower = UnitPowerMax("player", POWER.astralPower)
    local comboPoints = UnitPower("player", POWER.comboPoints)
    local maxComboPoints = UnitPowerMax("player", POWER.comboPoints)
    local energy = UnitPower("player", POWER.energy)
    local maxEnergy = UnitPowerMax("player", POWER.energy)
    local gcdRemains = getCooldownRemaining(GCD_SPELL_ID)
    local primaryPowerCurrent = UnitPower("player", primaryPowerType)
    local primaryPowerMax = UnitPowerMax("player", primaryPowerType)

    local meleeRange = isSpellInRangeSafe(6603, "target")
    if meleeRange == nil and targetExists then
        meleeRange = CheckInteractDistance("target", 3) and 1 or 0
    end
    local inMeleeRange = meleeRange == 1

    local stateSnapshot = {
        now = now,
        inCombat = inCombat,
        targetExists = targetExists,
        inMeleeRange = inMeleeRange,
        specID = specID,
        classTag = classTag,
        holyPower = holyPower,
        maxHolyPower = maxHolyPower,
        astralPower = astralPower,
        maxAstralPower = maxAstralPower,
        comboPoints = comboPoints,
        maxComboPoints = maxComboPoints,
        energy = energy,
        maxEnergy = maxEnergy,
        primaryPowerType = primaryPowerType,
        primaryPowerToken = primaryPowerToken,
        primaryPowerCurrent = primaryPowerCurrent,
        primaryPowerMax = primaryPowerMax,
        gcdRemains = gcdRemains,
    }

    local classResourceType
    local classResourceToken
    local classResourceLabel

    if classTag == "PALADIN" then
        classResourceType = POWER.holyPower
        classResourceToken = "HOLY_POWER"
        classResourceLabel = "Holy Power"
    elseif classTag == "ROGUE" then
        classResourceType = POWER.comboPoints
        classResourceToken = "COMBO_POINTS"
        classResourceLabel = "Combo Points"
    elseif classTag == "DRUID" and specID == 103 then
        classResourceType = POWER.comboPoints
        classResourceToken = "COMBO_POINTS"
        classResourceLabel = "Combo Points"
    elseif classTag == "DRUID" and specID == 102 then
        classResourceType = POWER.astralPower
        classResourceToken = "LUNAR_POWER"
        classResourceLabel = "Astral Power"
    elseif classTag == "MONK" then
        classResourceType = POWER.chi
        classResourceToken = "CHI"
        classResourceLabel = "Chi"
    elseif classTag == "WARLOCK" then
        classResourceType = POWER.soulShards
        classResourceToken = "SOUL_SHARDS"
        classResourceLabel = "Soul Shards"
    elseif classTag == "PRIEST" and specID == 258 then
        classResourceType = POWER.insanity
        classResourceToken = "INSANITY"
        classResourceLabel = "Insanity"
    elseif classTag == "DEMONHUNTER" and specID == 577 then
        classResourceType = POWER.fury
        classResourceToken = "FURY"
        classResourceLabel = "Fury"
    elseif classTag == "DEMONHUNTER" and specID == 581 then
        classResourceType = POWER.pain
        classResourceToken = "PAIN"
        classResourceLabel = "Pain"
    elseif classTag == "EVOKER" then
        classResourceType = POWER.essence
        classResourceToken = "ESSENCE"
        classResourceLabel = "Essence"
    end

    if classResourceType then
        stateSnapshot.classResource = {
            type = classResourceType,
            token = classResourceToken,
            label = classResourceLabel,
            current = UnitPower("player", classResourceType),
            max = UnitPowerMax("player", classResourceType),
        }
    end

    function stateSnapshot:Cooldown(spellID)
        return getCooldownRemaining(spellID)
    end

    function stateSnapshot:Charges(spellID)
        return getCharges(spellID)
    end

    function stateSnapshot:IsKnown(spellID)
        return isSpellKnown(spellID)
    end

    function stateSnapshot:Usable(spellID)
        if not self:IsKnown(spellID) then
            return false
        end

        local usable, noMana = isSpellUsableSafe(spellID)
        if not usable and noMana then
            return false
        end

        return self:Cooldown(spellID) <= 0
    end

    function stateSnapshot:TargetDebuff(spellID)
        local present, remaining = findAuraBySpellID("target", spellID, "HARMFUL|PLAYER")
        return present, remaining
    end

    function stateSnapshot:PlayerBuff(spellID)
        local present, remaining = findAuraBySpellID("player", spellID, "HELPFUL")
        return present, remaining
    end

    function stateSnapshot:PlayerBuffStacks(spellID)
        local present, _, stacks = findAuraBySpellID("player", spellID, "HELPFUL")
        if not present then
            return 0
        end
        return stacks or 0
    end

    return stateSnapshot
end
