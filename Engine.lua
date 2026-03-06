local _, addon = ...

addon.engine = {}

local engine = addon.engine

local BUTTON_PREFIXES = {
    "ActionButton",
    "MultiBarBottomLeftButton",
    "MultiBarBottomRightButton",
    "MultiBarRightButton",
    "MultiBarLeftButton",
    "MultiBar5Button",
    "MultiBar6Button",
    "MultiBar7Button",
    "MultiBar8Button",
}

local SLOT_COMMAND_PREFIXES = {
    [1] = "ACTIONBUTTON",
    [2] = "MULTIACTIONBAR1BUTTON",
    [3] = "MULTIACTIONBAR2BUTTON",
    [4] = "MULTIACTIONBAR3BUTTON",
    [5] = "MULTIACTIONBAR4BUTTON",
    [6] = "MULTIACTIONBAR5BUTTON",
    [7] = "MULTIACTIONBAR6BUTTON",
    [8] = "MULTIACTIONBAR7BUTTON",
    [9] = "MULTIACTIONBAR8BUTTON",
}

local macroSpellCache = {}

local function cleanKeyText(text)
    if not text or text == "" then
        return nil
    end

    text = tostring(text)
    text = text:gsub("|T.-|t", "")
    text = text:gsub("%s+", "")

    if text == "" then
        return nil
    end

    text = text:gsub("SHIFT%-", "S-")
    text = text:gsub("CTRL%-", "C-")
    text = text:gsub("ALT%-", "A-")
    text = text:gsub("NUMPAD", "N")
    text = text:gsub("MOUSEWHEELUP", "MWU")
    text = text:gsub("MOUSEWHEELDOWN", "MWD")
    text = text:gsub("MOUSEBUTTON", "M")
    text = text:gsub("^BUTTON", "M")
    text = text:gsub("SPACE", "SPC")
    text = text:gsub("BACKSPACE", "BSP")
    text = text:gsub("INSERT", "INS")
    text = text:gsub("DELETE", "DEL")
    text = text:gsub("PAGEDOWN", "PGDN")
    text = text:gsub("PAGEUP", "PGUP")

    if text:find("[^%w%-%+=]") then
        return nil
    end

    return text
end

local function makeSpellRecord(spellID, keybind)
    if not spellID then
        return nil
    end

    local name = C_Spell and C_Spell.GetSpellName and C_Spell.GetSpellName(spellID) or GetSpellInfo(spellID)
    local icon = C_Spell and C_Spell.GetSpellTexture and C_Spell.GetSpellTexture(spellID) or select(3, GetSpellInfo(spellID))

    return {
        spellID = spellID,
        name = name,
        icon = icon,
        keybind = keybind,
    }
end

local function iterateButtons()
    local idx = 0
    return function()
        while true do
            idx = idx + 1
            local pIndex = math.floor((idx - 1) / 12) + 1
            local bIndex = ((idx - 1) % 12) + 1
            local prefix = BUTTON_PREFIXES[pIndex]
            if not prefix then
                return nil
            end
            local btn = _G[prefix .. bIndex]
            if btn then
                return btn
            end
        end
    end
end

local function getAssistedCombatFrame(btn)
    if not btn then
        return nil
    end
    if btn.AssistedCombatRotationFrame then
        return btn.AssistedCombatRotationFrame
    end
    local name = btn.GetName and btn:GetName()
    if name then
        return _G[name .. "AssistedCombatRotationFrame"]
    end
    return nil
end

local function isRecommendedButton(btn)
    local ac = getAssistedCombatFrame(btn)
    return ac and ac.IsShown and ac:IsShown()
end

local function findRecommendedButton()
    for btn in iterateButtons() do
        if btn.IsShown and btn:IsShown() and isRecommendedButton(btn) then
            return btn
        end
    end
    return nil
end

local function getActionSlotFromButton(btn)
    if not btn then
        return nil
    end
    if type(btn.action) == "number" and btn.action > 0 then
        return btn.action
    end
    if btn.GetAttribute then
        local action = btn:GetAttribute("action")
        if type(action) == "number" and action > 0 then
            return action
        end
    end
    return nil
end

local function getSpellIDFromActionSlot(slot)
    if not slot or slot <= 0 then
        return nil
    end
    local actionType, id = GetActionInfo(slot)
    if actionType == "spell" then
        return id
    end
    if actionType == "macro" then
        return select(2, GetMacroSpell(id))
    end
    return nil
end

local function trim(s)
    if not s then
        return ""
    end
    return (s:gsub("^%s+", ""):gsub("%s+$", ""))
end

local function resolveSpellIDFromToken(token)
    token = trim(token or "")
    if token == "" then
        return nil
    end

    token = token:gsub("^!", "")
    token = token:gsub("^spell:", "")
    token = trim(token)
    if token == "" then
        return nil
    end

    local asNumber = tonumber(token)
    if asNumber then
        if IsSpellKnownOrOverridesKnown(asNumber) or (C_Spell and C_Spell.GetSpellInfo and C_Spell.GetSpellInfo(asNumber)) then
            return asNumber
        end
    end

    if C_Spell and C_Spell.GetSpellInfo then
        local info = C_Spell.GetSpellInfo(token)
        if info and info.spellID then
            return info.spellID
        end
    end

    if GetSpellInfo then
        local _, _, _, _, _, _, spellID = GetSpellInfo(token)
        if spellID then
            return spellID
        end
    end

    return nil
end

local function stripMacroConditionals(token)
    token = trim(token)
    while token:sub(1, 1) == "[" do
        local closeIndex = token:find("]", 1, true)
        if not closeIndex then
            break
        end
        token = trim(token:sub(closeIndex + 1))
    end
    return token
end

local function parseMacroSpellIDs(macroID)
    if not macroID then
        return {}
    end

    local body = GetMacroBody(macroID) or ""
    if body == "" then
        return {}
    end

    local cacheKey = tostring(macroID) .. "::" .. body
    if macroSpellCache[cacheKey] then
        return macroSpellCache[cacheKey]
    end

    local spellIDs = {}
    local seen = {}

    local function addFromToken(rawToken)
        local token = stripMacroConditionals(rawToken)
        token = token:gsub(",.*$", "")
        token = trim(token)
        if token == "" then
            return
        end
        if tonumber(token) and #token <= 2 then
            return
        end
        local spellID = resolveSpellIDFromToken(token)
        if spellID and not seen[spellID] then
            seen[spellID] = true
            table.insert(spellIDs, spellID)
        end
    end

    for line in body:gmatch("[^\r\n]+") do
        local cmd, args = line:match("^%s*/([%w]+)%s+(.+)$")
        if cmd and args then
            cmd = cmd:lower()
            if cmd == "cast" or cmd == "use" then
                for choice in args:gmatch("[^;]+") do
                    addFromToken(choice)
                end
            elseif cmd == "castsequence" then
                local seq = args:gsub("reset=[^%s]+", "")
                for choice in seq:gmatch("[^;]+") do
                    local first = choice:match("([^,]+)") or choice
                    addFromToken(first)
                end
            end
        end
    end

    macroSpellCache[cacheKey] = spellIDs
    return spellIDs
end

local function getSpellIDsFromActionSlot(slot)
    local results = {}
    local seen = {}
    if not slot or slot <= 0 then
        return results
    end

    local actionType, id = GetActionInfo(slot)
    if actionType == "spell" then
        if id then
            table.insert(results, id)
        end
        return results
    end

    if actionType ~= "macro" then
        return results
    end

    local directSpell = select(2, GetMacroSpell(id))
    if directSpell and not seen[directSpell] then
        seen[directSpell] = true
        table.insert(results, directSpell)
    end

    local parsed = parseMacroSpellIDs(id)
    for i = 1, #parsed do
        local spellID = parsed[i]
        if spellID and not seen[spellID] then
            seen[spellID] = true
            table.insert(results, spellID)
        end
    end

    return results
end

local function slotContainsSpell(slot, spellID)
    if not slot or not spellID then
        return false
    end

    local spellIDs = getSpellIDsFromActionSlot(slot)
    for i = 1, #spellIDs do
        if spellIDs[i] == spellID then
            return true
        end
    end
    return false
end

local function getSlotBindingCommand(slot)
    if not slot or slot <= 0 then
        return nil
    end

    local barIndex = math.floor((slot - 1) / 12) + 1
    local buttonIndex = ((slot - 1) % 12) + 1
    local prefix = SLOT_COMMAND_PREFIXES[barIndex]
    if not prefix then
        return nil
    end

    return prefix .. buttonIndex
end

local function getButtonKeybind(btn)
    if not btn then
        return nil
    end

    if btn.HotKey and btn.HotKey.GetText then
        local hotKeyText = cleanKeyText(btn.HotKey:GetText())
        if hotKeyText and hotKeyText ~= "" then
            return hotKeyText
        end
    end

    local name = btn.GetName and btn:GetName()
    if name then
        local key1 = GetBindingKey("CLICK " .. name .. ":LeftButton")
        if key1 and key1 ~= "" then
            return cleanKeyText(key1)
        end
    end

    return nil
end

local function findVisibleButtonForSpell(spellID)
    if not spellID then
        return nil
    end

    for btn in iterateButtons() do
        if btn.IsShown and btn:IsShown() then
            local slot = getActionSlotFromButton(btn)
            if slotContainsSpell(slot, spellID) then
                return btn
            end
        end
    end

    return nil
end

local function findBestSlotForSpell(spellID)
    if not spellID then
        return nil, nil
    end

    local firstSlot = nil
    for slot = 1, 180 do
        if slotContainsSpell(slot, spellID) then
            firstSlot = firstSlot or slot
            local btn = findVisibleButtonForSpell(spellID)
            if btn then
                return slot, btn
            end
        end
    end

    return firstSlot, nil
end

local function getKeybindForSpell(spellID, preferredButton)
    if preferredButton then
        local fromButton = getButtonKeybind(preferredButton)
        if fromButton then
            return fromButton
        end
    end

    local slot, btn = findBestSlotForSpell(spellID)
    if btn then
        local fromVisible = getButtonKeybind(btn)
        if fromVisible then
            return fromVisible
        end
    end

    local command = getSlotBindingCommand(slot)
    if command then
        local key = GetBindingKey(command)
        if key then
            return cleanKeyText(key)
        end
    end

    return nil
end

function engine:Init()
    self.lastRecommendations = nil
    self.lastSource = "none"
    self.streamSpellIDs = {}
    self.lastStreamSpellID = nil
end

function engine:PushStreamSpell(spellID, maxCount)
    if not spellID then
        return
    end

    if type(self.streamSpellIDs) ~= "table" then
        self.streamSpellIDs = {}
    end

    if self.lastStreamSpellID == spellID then
        return
    end

    self.lastStreamSpellID = spellID
    table.insert(self.streamSpellIDs, 1, spellID)

    local maxItems = maxCount or 3
    while #self.streamSpellIDs > maxItems do
        table.remove(self.streamSpellIDs)
    end
end

function engine:GetAssistedCombatRecommendations(maxCount)
    local maxItems = maxCount or 3
    if type(self.streamSpellIDs) ~= "table" then
        self.streamSpellIDs = {}
    end

    local recButton = findRecommendedButton()
    if not recButton then
        self.lastStreamSpellID = nil
        return nil
    end

    local slot = getActionSlotFromButton(recButton)
    local spellID = getSpellIDFromActionSlot(slot)
    if spellID then
        self:PushStreamSpell(spellID, maxItems)
    end

    local recommendations = {}
    for i = 1, math.min(maxItems, #self.streamSpellIDs) do
        local streamSpellID = self.streamSpellIDs[i]
        local recBtn = i == 1 and recButton or findVisibleButtonForSpell(streamSpellID)
        local rec = makeSpellRecord(streamSpellID, getKeybindForSpell(streamSpellID, recBtn))
        if rec then
            table.insert(recommendations, rec)
        end
    end

    if #recommendations == 0 then
        return nil
    end

    return recommendations
end

function engine:GetRecommendations(state, maxCount)
    local maxItems = maxCount or 3
    local assistedRecs = self:GetAssistedCombatRecommendations(maxItems)
    if not assistedRecs or #assistedRecs == 0 then
        self.lastSource = "none"
        return nil
    end

    self.lastRecommendations = assistedRecs
    self.lastSource = "assisted"
    return assistedRecs
end

function engine:GetNextRecommendation(state)
    local recs = self:GetRecommendations(state, 1)
    return recs and recs[1] or nil
end
