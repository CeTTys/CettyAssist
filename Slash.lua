local _, addon = ...

addon.slash = {}

local slash = addon.slash

local function printUsage()
    addon:Printf("Commands:")
    addon:Printf("/cetty (toggle GUI)")
    addon:Printf("/cetty on | off")
    addon:Printf("/cetty debug")
    addon:Printf("/cetty direction left | right")
    addon:Printf("/cetty status")
    addon:Printf("/cetty test")
end

local function runAssistTest()
    local state = addon.state:Build()
    local recs = addon.engine:GetRecommendations(state, 3)
    local rec = recs and recs[1] or nil

    addon:Printf("Assist source: %s", tostring(addon.engine.lastSource or "none"))
    if rec then
        addon:Printf("Current recommendation: %s (%d)", rec.name or "unknown", rec.spellID or -1)
    else
        addon:Printf("Current recommendation: none (check Assisted Combat + action bar highlight)")
    end
end

function slash:Init()
    SLASH_CETTYASSIST1 = "/cetty"
    SLASH_CETTYASSIST2 = "/cettyassist"

    SlashCmdList.CETTYASSIST = function(msg)
        local command, arg = string.match((msg or ""):lower(), "^(%S*)%s*(.-)$")

        if command == "" or command == "help" then
            if command == "" then
                addon.ui:ToggleOptions()
            else
                printUsage()
            end
            return
        end

        if command == "gui" then
            addon.ui:ToggleOptions()
            return
        end

        if command == "on" then
            addon:GetDB().enabled = true
            addon:Printf("Enabled")
            addon:Recompute(true)
            return
        end

        if command == "off" then
            addon:GetDB().enabled = false
            addon.ui:ClearRecommendation()
            addon.ui.frame:Hide()
            addon:Printf("Disabled")
            return
        end

        if command == "lock" or command == "unlock" then
            addon:Printf("Frame movement is managed in Edit Mode via the Cetty anchor.")
            return
        end

        if command == "debug" then
            addon:GetDB().debug = not addon:GetDB().debug
            addon:Printf("Debug %s", addon:GetDB().debug and "enabled" or "disabled")
            return
        end

        if command == "status" then
            local state = addon.state:Build()
            addon:Printf(
                "enabled=%s spec=%d target=%s melee=%s combat=%s showOOC=%s source=%s mode=assisted-only",
                tostring(addon:GetDB().enabled),
                state.specID or 0,
                tostring(state.targetExists),
                tostring(state.inMeleeRange),
                tostring(state.inCombat),
                tostring(addon:GetDB().showOutOfCombat),
                tostring(addon.engine.lastSource or "none")
            )
            addon:Printf("direction=%s", addon:GetDB().queueDirection or "right")
            return
        end

        if command == "direction" then
            if arg == "left" then
                addon:GetDB().queueDirection = "left"
                addon.ui:ApplyQueueDirection()
                addon:Printf("Queue direction set to left")
                return
            end
            if arg == "right" then
                addon:GetDB().queueDirection = "right"
                addon.ui:ApplyQueueDirection()
                addon:Printf("Queue direction set to right")
                return
            end
            addon:Printf("Usage: /cetty direction left|right")
            return
        end

        if command == "test" then
            runAssistTest()
            return
        end

        printUsage()
    end
end
