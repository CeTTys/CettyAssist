local addonName, addon = ...

addon.name = addonName
addon.version = "0.1.0"

local frame = CreateFrame("Frame")
addon.frame = frame

local defaultDB = {
    enabled = true,
    locked = false,
    showOutOfCombat = true,
    queueDirection = "right",
    iconSize = 80,
    queueIconSize = 52,
    iconSpacing = 8,
    queueOffsetX = 0,
    queueOffsetY = 0,
    numIconsShown = 3,
    keybindFontSize = 18,
    keybindPosition = "center",
    keybindOffsetX = 0,
    keybindOffsetY = 0,
    iconShape = "square",
    uiTheme = "elvui",
    emptyIconTexture = "Interface\\Buttons\\WHITE8x8",
    updateInterval = 0.10,
    debug = false,
    point = {
        anchor = "CENTER",
        relativeTo = "UIParent",
        relativePoint = "CENTER",
        x = 0,
        y = -120,
    },
}

local function copyDefaults(src, dst)
    if type(src) ~= "table" then
        return dst
    end

    if type(dst) ~= "table" then
        dst = {}
    end

    for k, v in pairs(src) do
        if type(v) == "table" then
            dst[k] = copyDefaults(v, dst[k])
        elseif dst[k] == nil then
            dst[k] = v
        end
    end

    return dst
end

function addon:Printf(fmt, ...)
    local msg = string.format(fmt, ...)
    DEFAULT_CHAT_FRAME:AddMessage(string.format("|cff58a6ff%s|r: %s", addonName, msg))
end

function addon:GetDB()
    return CeTTyAssistDB
end

function addon:ShouldRun()
    if not self:GetDB().enabled then
        return false
    end

    if UnitIsDeadOrGhost("player") then
        return false
    end

    if not self:GetDB().showOutOfCombat and not UnitAffectingCombat("player") then
        return false
    end

    return true
end

function addon:Recompute(force)
    if self.ui and self.ui.UpdateAnchorVisibility then
        self.ui:UpdateAnchorVisibility()
    end

    if not self:ShouldRun() then
        self.ui:ClearRecommendation()
        if self.ui.frame then
            self.ui.frame:Hide()
        end
        if self.ui and self.ui.UpdateAnchorVisibility then
            self.ui:UpdateAnchorVisibility()
        end
        return
    end

    local state = self.state:Build()
    local maxIcons = math.max(1, math.min(5, self:GetDB().numIconsShown or 3))
    local recommendations = self.engine:GetRecommendations(state, maxIcons)

    if self:GetDB().debug and recommendations and recommendations[1] then
        local recommendation = recommendations[1]
        self:Printf(
            "Suggesting %s (%d) via %s",
            recommendation.name or "unknown",
            recommendation.spellID or -1,
            self.engine.lastSource or "unknown"
        )
    end

    self.ui:SetRecommendations(recommendations, state)
    if self.ui and self.ui.UpdateAnchorVisibility then
        self.ui:UpdateAnchorVisibility()
    end
end

frame:SetScript("OnEvent", function(_, event, ...)
    if addon.OnEvent then
        addon:OnEvent(event, ...)
    end
end)

local elapsedSinceUpdate = 0
frame:SetScript("OnUpdate", function(_, elapsed)
    local db = addon:GetDB()
    if not db then
        return
    end

    elapsedSinceUpdate = elapsedSinceUpdate + elapsed
    if elapsedSinceUpdate < db.updateInterval then
        return
    end

    elapsedSinceUpdate = 0
    addon:Recompute(false)
end)

function addon:OnEvent(event, ...)
    if event == "PLAYER_LOGIN" then
        -- Migrate existing settings from the old SavedVariables name.
        if not CeTTyAssistDB and CettyRotationsDB then
            CeTTyAssistDB = CettyRotationsDB
        end
        CeTTyAssistDB = copyDefaults(defaultDB, CeTTyAssistDB or {})

        self.state:Init()
        self.engine:Init()
        self.ui:Init()
        self.slash:Init()

        self:Printf("Loaded v%s. /cetty or /cettyassist for commands.", addon.version)
        self:Recompute(true)
        return
    end

    if event == "PLAYER_LOGOUT" then
        self.ui:SavePosition()
        return
    end

    if event == "PLAYER_SPECIALIZATION_CHANGED" then
        local unit = ...
        if unit ~= "player" then
            return
        end
    end

    self:Recompute(true)
end

frame:RegisterEvent("PLAYER_LOGIN")
frame:RegisterEvent("PLAYER_LOGOUT")
frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:RegisterEvent("PLAYER_REGEN_DISABLED")
frame:RegisterEvent("PLAYER_REGEN_ENABLED")
frame:RegisterEvent("PLAYER_TARGET_CHANGED")
frame:RegisterEvent("SPELL_UPDATE_COOLDOWN")
frame:RegisterEvent("SPELLS_CHANGED")
frame:RegisterEvent("ACTIONBAR_UPDATE_USABLE")
frame:RegisterEvent("UNIT_AURA")
frame:RegisterEvent("UNIT_POWER_FREQUENT")
frame:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
frame:RegisterEvent("PLAYER_TALENT_UPDATE")
frame:RegisterEvent("ACTIVE_TALENT_GROUP_CHANGED")
frame:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
frame:RegisterEvent("EDIT_MODE_LAYOUTS_UPDATED")
