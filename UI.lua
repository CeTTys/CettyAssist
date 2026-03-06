local _, addon = ...

addon.ui = {}

local ui = addon.ui

local ICON_FALLBACK = 134400
local EMPTY_TEXTURE = "Interface\\Buttons\\WHITE8x8"
local CIRCLE_MASK = "Interface\\CHARACTERFRAME\\TempPortraitAlphaMask"
local HEX_OVERLAY = "Interface\\Artifacts\\RelicIconFrame"
local sliderCounter = 0
local dropdownCounter = 0
local THEMES = {
    blizzard = {
        name = "Blizzard (scaling issue - WIP)",
        iconBg = { 0.00, 0.00, 0.00, 0.00 },
        iconBorder = { 0.95, 0.82, 0.24, 1.0 },
        iconBorderCircle = { 0.95, 0.82, 0.24, 1.0 },
        iconBorderHex = { 0.95, 0.82, 0.24, 1.0 },
        glow = { 1.00, 0.82, 0.24, 0.70 },
        keybind = { 1.00, 0.96, 0.82, 1.0 },
        keybindOutline = "THICKOUTLINE",
    },
    elvui = {
        name = "Modern (Default)",
        iconBg = { 0.04, 0.04, 0.04, 0.92 },
        iconBorder = { 0.35, 0.35, 0.35, 1.0 },
        iconBorderCircle = { 0.08, 0.72, 0.67, 1.0 },
        iconBorderHex = { 0.08, 0.72, 0.67, 1.0 },
        glow = { 0.08, 0.72, 0.67, 0.85 },
        keybind = { 1.00, 1.00, 1.00, 1.0 },
        keybindOutline = "OUTLINE",
    },
}

local BACKGROUND_TEXTURES = {
    { text = "Flat Dark (Default)", value = "Interface\\Buttons\\WHITE8x8" },
    { text = "Question Mark", value = "Interface\\Icons\\INV_Misc_QuestionMark" },
    { text = "Arcane Orb", value = "Interface\\Icons\\Spell_Arcane_Arcane01" },
    { text = "Gear", value = "Interface\\Icons\\INV_Misc_Gear_01" },
    { text = "Shield", value = "Interface\\Icons\\Ability_Warrior_DefensiveStance" },
}

local function isEditModeActive()
    return EditModeManagerFrame and EditModeManagerFrame:IsShown()
end

local function setFrameMovable(frame, movable)
    frame:SetMovable(movable)
    frame:EnableMouse(movable)

    if movable then
        frame:RegisterForDrag("LeftButton")
        frame:SetScript("OnDragStart", function(self)
            self:StartMoving()
        end)
        frame:SetScript("OnDragStop", function(self)
            self:StopMovingOrSizing()
            addon.ui:SavePosition()
        end)
    else
        frame:RegisterForDrag()
        frame:SetScript("OnDragStart", nil)
        frame:SetScript("OnDragStop", nil)
    end
end

local function shapeLabel(shape)
    if shape == "circle" then
        return "Circle"
    end
    if shape == "hex" then
        return "Hexagon"
    end
    return "Square"
end

local function getThemeKey()
    local key = addon:GetDB().uiTheme or "elvui"
    if not THEMES[key] then
        key = "elvui"
    end
    return key
end

local function themeLabel(theme)
    local key = theme or getThemeKey()
    return (THEMES[key] and THEMES[key].name) or "Modern (Default)"
end

local function createIconSlot(parent, size)
    local slot = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    slot:SetSize(size, size)
    slot:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    slot:SetBackdropColor(0.02, 0.02, 0.02, 0.9)
    slot:SetBackdropBorderColor(0.25, 0.25, 0.25, 1)

    slot.icon = slot:CreateTexture(nil, "ARTWORK")
    slot.icon:SetAllPoints()
    slot.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    slot.icon:SetTexture(ICON_FALLBACK)

    slot.quickslot = slot:CreateTexture(nil, "OVERLAY")
    slot.quickslot:SetAllPoints(slot)
    slot.quickslot:SetTexture("Interface\\Buttons\\UI-Quickslot2")
    slot.quickslot:SetBlendMode("BLEND")
    slot.quickslot:Hide()

    slot.sheen = slot:CreateTexture(nil, "OVERLAY")
    slot.sheen:SetPoint("TOPLEFT", slot, "TOPLEFT", 2, -2)
    slot.sheen:SetPoint("BOTTOMRIGHT", slot, "BOTTOMRIGHT", -2, 2)
    slot.sheen:SetTexture("Interface\\Buttons\\CheckButtonHilight")
    slot.sheen:SetBlendMode("ADD")
    slot.sheen:SetAlpha(0.08)
    slot.sheen:Hide()

    slot.circleMask = slot:CreateMaskTexture()
    slot.circleMask:SetAllPoints(slot.icon)
    slot.circleMask:SetTexture(CIRCLE_MASK, "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")

    slot.shapeOverlay = slot:CreateTexture(nil, "OVERLAY")
    slot.shapeOverlay:SetAllPoints()
    slot.shapeOverlay:SetTexture(HEX_OVERLAY)
    slot.shapeOverlay:SetBlendMode("BLEND")
    slot.shapeOverlay:SetAlpha(0.5)
    slot.shapeOverlay:Hide()

    slot.keyText = slot:CreateFontString(nil, "OVERLAY")
    slot.keyText:SetPoint("CENTER", slot, "CENTER", 0, 0)
    slot.keyText:SetFont(STANDARD_TEXT_FONT, 14, "OUTLINE")
    slot.keyText:SetTextColor(1, 1, 1, 1)
    slot.keyText:SetShadowColor(0, 0, 0, 1)
    slot.keyText:SetShadowOffset(1, -1)
    slot.keyText:SetText("")

    return slot
end

local function createSectionTitle(parent, text, y)
    local fs = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    fs:SetPoint("TOPLEFT", parent, "TOPLEFT", 14, y)
    fs:SetText(text)
    fs:SetTextColor(1, 0.82, 0.2, 1)
    return fs
end

local function createToggle(parent, label, y)
    local cb = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
    cb:SetPoint("TOPLEFT", parent, "TOPLEFT", 12, y)
    cb.label = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    cb.label:SetPoint("LEFT", cb, "RIGHT", 6, 0)
    cb.label:SetText(label)
    return cb
end

local function createSlider(parent, label, minVal, maxVal, step, y)
    sliderCounter = sliderCounter + 1
    local name = "CeTTyAssistSlider" .. sliderCounter

    local slider = CreateFrame("Slider", name, parent, "OptionsSliderTemplate")
    slider:SetPoint("TOPLEFT", parent, "TOPLEFT", 14, y)
    slider:SetWidth(280)
    slider:SetMinMaxValues(minVal, maxVal)
    slider:SetValueStep(step)
    slider:SetObeyStepOnDrag(true)

    _G[name .. "Text"]:SetText(label)
    _G[name .. "Low"]:SetText(tostring(minVal))
    _G[name .. "High"]:SetText(tostring(maxVal))

    slider.valueText = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    slider.valueText:SetPoint("LEFT", slider, "RIGHT", 12, 0)
    slider.valueText:SetText("")

    return slider
end

local function createDropdown(parent, label, y, width, items, onChanged)
    dropdownCounter = dropdownCounter + 1
    local name = "CeTTyAssistDropdown" .. dropdownCounter

    local title = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    title:SetPoint("TOPLEFT", parent, "TOPLEFT", 16, y)
    title:SetText(label)

    local dd = CreateFrame("Frame", name, parent, "UIDropDownMenuTemplate")
    dd:SetPoint("TOPLEFT", title, "BOTTOMLEFT", -16, -2)
    UIDropDownMenu_SetWidth(dd, width or 160)
    UIDropDownMenu_Initialize(dd, function(self, level)
        for i = 1, #items do
            local item = items[i]
            local info = UIDropDownMenu_CreateInfo()
            info.text = item.text
            info.value = item.value
            info.notCheckable = true
            info.func = function()
                UIDropDownMenu_SetSelectedValue(dd, item.value)
                UIDropDownMenu_SetText(dd, item.text)
                if onChanged then
                    onChanged(item.value)
                end
            end
            UIDropDownMenu_AddButton(info, level)
        end
    end)

    function dd:SetValue(value)
        for i = 1, #items do
            local item = items[i]
            if item.value == value then
                UIDropDownMenu_SetSelectedValue(dd, value)
                UIDropDownMenu_SetText(dd, item.text)
                return
            end
        end
        UIDropDownMenu_SetSelectedValue(dd, items[1].value)
        UIDropDownMenu_SetText(dd, items[1].text)
    end

    return dd
end

local function getFilledTexCoords()
    if getThemeKey() == "blizzard" then
        return 0.07, 0.93, 0.07, 0.93
    end
    return 0.08, 0.92, 0.08, 0.92
end

local function applyKeybindPosition(slot, pos)
    local db = addon:GetDB()
    local offsetX = math.floor(db.keybindOffsetX or 0)
    local offsetY = math.floor(db.keybindOffsetY or 0)
    slot.keyText:ClearAllPoints()
    if pos == "top_left" then
        slot.keyText:SetPoint("TOPLEFT", slot, "TOPLEFT", 3 + offsetX, -3 + offsetY)
        slot.keyText:SetJustifyH("LEFT")
    elseif pos == "top_right" then
        slot.keyText:SetPoint("TOPRIGHT", slot, "TOPRIGHT", -3 + offsetX, -3 + offsetY)
        slot.keyText:SetJustifyH("RIGHT")
    else
        slot.keyText:SetPoint("CENTER", slot, "CENTER", offsetX, offsetY)
        slot.keyText:SetJustifyH("CENTER")
    end
    slot.keyText:SetJustifyV("MIDDLE")
end

local function createEditBox(parent, label, y)
    local title = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    title:SetPoint("TOPLEFT", parent, "TOPLEFT", 16, y)
    title:SetText(label)

    local box = CreateFrame("EditBox", nil, parent, "InputBoxTemplate")
    box:SetAutoFocus(false)
    box:SetSize(260, 22)
    box:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -6)
    box:SetTextInsets(6, 6, 2, 2)

    return box
end

function ui:ApplyIconShape()
    if not self.slots then
        return
    end

    local shape = addon:GetDB().iconShape or "square"
    local theme = THEMES[getThemeKey()]
    local themeKey = getThemeKey()
    for i = 1, #self.slots do
        local slot = self.slots[i]
        slot.icon:RemoveMaskTexture(slot.circleMask)
        slot.shapeOverlay:Hide()

        if shape == "circle" then
            slot.icon:AddMaskTexture(slot.circleMask)
            slot:SetBackdropBorderColor(unpack(theme.iconBorderCircle))
        elseif shape == "hex" then
            slot.shapeOverlay:Show()
            slot:SetBackdropBorderColor(unpack(theme.iconBorderHex))
        else
            slot:SetBackdropBorderColor(unpack(theme.iconBorder))
        end

        if themeKey == "blizzard" and shape == "square" then
            slot.shapeOverlay:Hide()
        end
    end
end

function ui:ApplySizingAndLayout()
    if not self.frame or not self.slots then
        return
    end

    local db = addon:GetDB()
    local numIcons = math.max(1, math.min(5, db.numIconsShown or 3))
    local mainSize = math.max(36, math.floor(db.iconSize or 80))
    local queueSize = math.max(24, math.floor(db.queueIconSize or (mainSize * 0.66)))
    local spacing = math.max(0, math.floor(db.iconSpacing or 8))

    for i = 1, #self.slots do
        local isMain = i == 1
        local size = isMain and mainSize or queueSize
        self.slots[i]:SetSize(size, size)
        self.slots[i].slotSize = size

        local quickslotOutset = math.max(6, math.floor(size * 0.14))
        self.slots[i].quickslot:ClearAllPoints()
        self.slots[i].quickslot:SetPoint("TOPLEFT", self.slots[i], "TOPLEFT", -quickslotOutset, quickslotOutset)
        self.slots[i].quickslot:SetPoint("BOTTOMRIGHT", self.slots[i], "BOTTOMRIGHT", quickslotOutset, -quickslotOutset)
    end

    local baseKey = math.max(10, math.floor(db.keybindFontSize or 18))
    for i = 1, #self.slots do
        local size = (i == 1) and baseKey or math.max(10, baseKey - 2)
        self.slots[i].keyText:SetFont(STANDARD_TEXT_FONT, size, "OUTLINE")
    end

    local width = mainSize + ((numIcons - 1) * queueSize) + (math.max(0, numIcons - 1) * spacing) + 16
    local height = math.max(mainSize, queueSize) + 16
    self.frame:SetSize(width, height)
    if self.anchor then
        self.anchor:SetSize(width, height)
    end

    if self.glow and self.slots[1] then
        local glowPad = math.max(2, math.floor(mainSize * 0.05))
        self.glow:ClearAllPoints()
        self.glow:SetPoint("TOPLEFT", self.slots[1], "TOPLEFT", -glowPad, glowPad)
        self.glow:SetPoint("BOTTOMRIGHT", self.slots[1], "BOTTOMRIGHT", glowPad, -glowPad)
    end

    self:ApplyQueueDirection()
    self:ApplyTheme()
end

function ui:ApplyQueueDirection()
    if not self.frame or not self.slots then
        return
    end

    local spacing = math.max(0, math.floor(addon:GetDB().iconSpacing or 8))
    local numIcons = math.max(1, math.min(5, addon:GetDB().numIconsShown or 3))
    local direction = addon:GetDB().queueDirection or "right"
    local offsetX = math.floor(addon:GetDB().queueOffsetX or 0)
    local offsetY = math.floor(addon:GetDB().queueOffsetY or 0)

    for i = 1, #self.slots do
        self.slots[i]:ClearAllPoints()
    end

    local main = self.slots[1]

    if direction == "left" then
        main:SetPoint("RIGHT", self.frame, "RIGHT", -8, 0)
        if numIcons >= 2 then
            self.slots[2]:SetPoint("RIGHT", main, "LEFT", -spacing + offsetX, offsetY)
        end
        for i = 3, numIcons do
            self.slots[i]:SetPoint("RIGHT", self.slots[i - 1], "LEFT", -spacing, 0)
        end
    else
        main:SetPoint("LEFT", self.frame, "LEFT", 8, 0)
        if numIcons >= 2 then
            self.slots[2]:SetPoint("LEFT", main, "RIGHT", spacing + offsetX, offsetY)
        end
        for i = 3, numIcons do
            self.slots[i]:SetPoint("LEFT", self.slots[i - 1], "RIGHT", spacing, 0)
        end
    end
end

function ui:ApplyTheme()
    if not self.frame or not self.slots then
        return
    end

    local themeKey = getThemeKey()
    local theme = THEMES[themeKey]
    for i = 1, #self.slots do
        local slot = self.slots[i]
        local _, fontSize = slot.keyText:GetFont()
        slot:SetBackdropColor(unpack(theme.iconBg))
        slot.keyText:SetTextColor(unpack(theme.keybind))
        slot.keyText:SetFont(STANDARD_TEXT_FONT, fontSize or 14, theme.keybindOutline)

        if themeKey == "blizzard" then
            slot.quickslot:Show()
            slot.sheen:Show()
            slot:SetBackdropBorderColor(0, 0, 0, 0)
            slot.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
        else
            slot.quickslot:Hide()
            slot.sheen:Hide()
            slot.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        end
    end

    self.glow:SetVertexColor(unpack(theme.glow))
    self:ApplyIconShape()
    self:ApplyKeybindPosition()
end

function ui:ApplyKeybindPosition()
    if not self.slots then
        return
    end

    local pos = addon:GetDB().keybindPosition or "center"
    for i = 1, #self.slots do
        applyKeybindPosition(self.slots[i], pos)
    end
end

function ui:UpdateResourceLayout() end

function ui:UpdateResources(state) end

function ui:UpdateAnchorVisibility()
    if not self.anchor or not self.frame then
        return
    end

    if self.anchorDragging then
        return
    end

    if isEditModeActive() then
        local anchor, relativeTo, relativePoint, x, y = self.frame:GetPoint(1)
        self.anchor:ClearAllPoints()
        self.anchor:SetPoint(anchor, relativeTo, relativePoint, x, y)
        self.anchor:SetSize(self.frame:GetWidth(), self.frame:GetHeight())
        self.anchor:Show()
    else
        self.anchor:Hide()
    end
end

function ui:Init()
    local frame = CreateFrame("Frame", "CeTTyAssistFrame", UIParent)
    frame:SetSize(172, 80)
    frame:SetFrameStrata("HIGH")
    frame:SetClampedToScreen(true)

    local point = addon:GetDB().point
    frame:ClearAllPoints()
    frame:SetPoint(point.anchor, _G[point.relativeTo] or UIParent, point.relativePoint, point.x, point.y)

    local main = createIconSlot(frame, 80)
    local next1 = createIconSlot(frame, 52)
    local next2 = createIconSlot(frame, 52)
    local next3 = createIconSlot(frame, 52)
    local next4 = createIconSlot(frame, 52)

    local glow = main:CreateTexture(nil, "OVERLAY")
    glow:SetPoint("TOPLEFT", -6, 6)
    glow:SetPoint("BOTTOMRIGHT", 6, -6)
    glow:SetTexture("Interface\\Buttons\\WHITE8x8")
    glow:SetVertexColor(0.2, 0.8, 1.0, 0.8)
    glow:SetBlendMode("ADD")
    glow:SetAlpha(0.75)

    local pulse = glow:CreateAnimationGroup()
    pulse:SetLooping("REPEAT")

    local fadeIn = pulse:CreateAnimation("Alpha")
    fadeIn:SetFromAlpha(0.25)
    fadeIn:SetToAlpha(0.9)
    fadeIn:SetDuration(0.40)
    fadeIn:SetSmoothing("IN_OUT")

    local fadeOut = pulse:CreateAnimation("Alpha")
    fadeOut:SetOrder(2)
    fadeOut:SetFromAlpha(0.9)
    fadeOut:SetToAlpha(0.25)
    fadeOut:SetDuration(0.40)
    fadeOut:SetSmoothing("IN_OUT")

    local anchorFrame = CreateFrame("Frame", "CeTTyAssistAnchor", UIParent, "BackdropTemplate")
    anchorFrame:SetSize(frame:GetWidth(), frame:GetHeight())
    anchorFrame:SetFrameStrata("DIALOG")
    anchorFrame:SetClampedToScreen(true)
    anchorFrame:EnableMouse(true)
    anchorFrame:SetMovable(true)
    anchorFrame:RegisterForDrag("LeftButton")
    anchorFrame:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 2,
    })
    anchorFrame:SetBackdropColor(0.1, 0.45, 0.85, 0.18)
    anchorFrame:SetBackdropBorderColor(0.2, 0.7, 1.0, 0.95)
    anchorFrame:Hide()

    local anchorText = anchorFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    anchorText:SetPoint("CENTER", anchorFrame, "CENTER", 0, 0)
    anchorText:SetText("CeTTyAssist Anchor")
    anchorText:SetTextColor(0.9, 0.95, 1.0, 1.0)

    anchorFrame:SetScript("OnDragStart", function(self)
        addon.ui.anchorDragging = true
        self:StartMoving()
    end)
    anchorFrame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        local anchor, relativeTo, relativePoint, x, y = self:GetPoint(1)
        frame:ClearAllPoints()
        frame:SetPoint(anchor, relativeTo, relativePoint, x, y)
        addon.ui:SavePosition()
        addon.ui.anchorDragging = false
        addon.ui:UpdateAnchorVisibility()
    end)
    anchorFrame:SetScript("OnMouseUp", function(_, button)
        if button == "RightButton" and isEditModeActive() then
            addon.ui:ToggleOptions()
        end
    end)

    self.frame = frame
    self.slots = { main, next1, next2, next3, next4 }
    self.glow = glow
    self.pulse = pulse
    self.anchor = anchorFrame
    self.anchorDragging = false

    self:ApplySizingAndLayout()
    self:ApplyTheme()
    self:UpdateAnchorVisibility()
    setFrameMovable(frame, false)
    self:InitOptions()
end

function ui:InitOptions()
    local panel = CreateFrame("Frame", "CeTTyAssistOptions", UIParent, "BasicFrameTemplateWithInset")
    panel:SetSize(450, 560)
    panel:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    panel:SetFrameStrata("DIALOG")
    panel:SetClampedToScreen(true)
    panel:EnableMouse(true)
    panel:SetMovable(true)
    panel:RegisterForDrag("LeftButton")
    panel:SetScript("OnDragStart", panel.StartMoving)
    panel:SetScript("OnDragStop", panel.StopMovingOrSizing)
    panel:Hide()

    panel.TitleText:SetText("CeTTyAssist Settings")

    local scroll = CreateFrame("ScrollFrame", nil, panel, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", panel, "TOPLEFT", 28, -48)
    scroll:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", -28, 46)

    local content = CreateFrame("Frame", nil, scroll)
    content:SetSize(360, 1280)
    scroll:SetScrollChild(content)

    local infoBox = CreateFrame("Frame", nil, content, "BackdropTemplate")
    infoBox:SetPoint("TOPLEFT", content, "TOPLEFT", 10, -10)
    infoBox:SetPoint("TOPRIGHT", content, "TOPRIGHT", -18, -10)
    infoBox:SetHeight(150)
    infoBox:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    infoBox:SetBackdropColor(0.12, 0.02, 0.02, 0.82)
    infoBox:SetBackdropBorderColor(0.9, 0.15, 0.15, 0.85)

    local warningTitle = infoBox:CreateFontString(nil, "OVERLAY")
    warningTitle:SetPoint("TOPLEFT", infoBox, "TOPLEFT", 12, -10)
    warningTitle:SetPoint("TOPRIGHT", infoBox, "TOPRIGHT", -12, -10)
    warningTitle:SetFont(STANDARD_TEXT_FONT, 18, "OUTLINE")
    warningTitle:SetJustifyH("LEFT")
    warningTitle:SetJustifyV("TOP")
    if warningTitle.SetWordWrap then
        warningTitle:SetWordWrap(true)
    end
    warningTitle:SetTextColor(1.0, 0.2, 0.2, 1.0)
    warningTitle:SetText("IMPORTANT: Single Button Assist is required on your action bars.")

    local warningBody = infoBox:CreateFontString(nil, "OVERLAY")
    warningBody:SetPoint("TOPLEFT", warningTitle, "BOTTOMLEFT", 0, -10)
    warningBody:SetPoint("TOPRIGHT", infoBox, "TOPRIGHT", -12, -48)
    warningBody:SetFont(STANDARD_TEXT_FONT, 14, "")
    warningBody:SetJustifyH("LEFT")
    warningBody:SetJustifyV("TOP")
    if warningBody.SetWordWrap then
        warningBody:SetWordWrap(true)
    end
    warningBody:SetTextColor(1.0, 0.95, 0.90, 1.0)
    warningBody:SetText(
        "CeTTyAssist reads Single Button Assist recommendations and helps you visualize the next ability in your rotation. "
            .. "It is not automation, not a one-button macro, and not an optimized rotation engine."
    )

    local y = -184
    createSectionTitle(content, "General", y)
    y = y - 26

    local enabled = createToggle(content, "Enable Addon", y)
    y = y - 28
    local outOfCombat = createToggle(content, "Show Out Of Combat", y)

    y = y - 40
    createSectionTitle(content, "Layout", y)
    y = y - 30

    local queueLeft = createToggle(content, "Queue To Left", y)
    y = y - 52
    local iconCount = createSlider(content, "Icons Shown", 1, 5, 1, y)
    y = y - 56
    local iconSize = createSlider(content, "Main Icon Size", 36, 120, 1, y)
    y = y - 56
    local queueIconSize = createSlider(content, "Queue Icon Size", 24, 120, 1, y)
    y = y - 56
    local iconSpacing = createSlider(content, "Queue Spacing", 0, 30, 1, y)
    y = y - 56
    local queueOffsetX = createSlider(content, "Queue X Offset", -100, 100, 1, y)
    y = y - 56
    local queueOffsetY = createSlider(content, "Queue Y Offset", -100, 100, 1, y)
    y = y - 56
    local keybindSize = createSlider(content, "Keybind Font Size", 10, 34, 1, y)
    y = y - 56

    local hotkeyPosDropdown = createDropdown(content, "Hotkey Position", y, 160, {
        { text = "Center", value = "center" },
        { text = "Top Left", value = "top_left" },
        { text = "Top Right", value = "top_right" },
    }, function(value)
        addon:GetDB().keybindPosition = value
        ui:ApplyKeybindPosition()
    end)

    y = y - 72
    local hotkeyOffsetX = createSlider(content, "Hotkey X Offset", -40, 40, 1, y)
    y = y - 56
    local hotkeyOffsetY = createSlider(content, "Hotkey Y Offset", -40, 40, 1, y)

    y = y - 66
    local shapeDropdown = createDropdown(content, "Icon Shape", y, 160, {
        { text = "Square", value = "square" },
        { text = "Circle", value = "circle" },
        { text = "Hexagon", value = "hex" },
    }, function(value)
        addon:GetDB().iconShape = value
        ui:ApplyIconShape()
    end)

    y = y - 72
    createSectionTitle(content, "Theme", y)
    y = y - 30

    local themeDropdown = createDropdown(content, "Theme Preset", y, 160, {
        { text = "Blizzard (scaling issue - WIP)", value = "blizzard" },
        { text = "Modern (Default)", value = "elvui" },
    }, function(value)
        addon:GetDB().uiTheme = value
        ui:ApplyTheme()
    end)

    y = y - 72
    local bgTextureDropdown = createDropdown(content, "Background Texture", y, 200, BACKGROUND_TEXTURES, function(value)
        addon:GetDB().emptyIconTexture = value
        addon:Recompute(true)
    end)

    local close = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    close:SetSize(100, 24)
    close:SetPoint("BOTTOM", panel, "BOTTOM", 0, 14)
    close:SetText("Close")
    close:SetScript("OnClick", function()
        panel:Hide()
    end)

    enabled:SetScript("OnClick", function(self)
        addon:GetDB().enabled = self:GetChecked() and true or false
        addon:Recompute(true)
    end)

    outOfCombat:SetScript("OnClick", function(self)
        addon:GetDB().showOutOfCombat = self:GetChecked() and true or false
        addon:Recompute(true)
    end)

    queueLeft:SetScript("OnClick", function(self)
        addon:GetDB().queueDirection = self:GetChecked() and "left" or "right"
        ui:ApplyQueueDirection()
    end)

    iconCount:SetScript("OnValueChanged", function(self, value)
        local v = math.floor(value + 0.5)
        addon:GetDB().numIconsShown = v
        self.valueText:SetText(tostring(v))
        ui:ApplySizingAndLayout()
        addon:Recompute(true)
    end)

    iconSize:SetScript("OnValueChanged", function(self, value)
        local v = math.floor(value + 0.5)
        addon:GetDB().iconSize = v
        self.valueText:SetText(tostring(v))
        ui:ApplySizingAndLayout()
    end)

    queueIconSize:SetScript("OnValueChanged", function(self, value)
        local v = math.floor(value + 0.5)
        addon:GetDB().queueIconSize = v
        self.valueText:SetText(tostring(v))
        ui:ApplySizingAndLayout()
    end)

    iconSpacing:SetScript("OnValueChanged", function(self, value)
        local v = math.floor(value + 0.5)
        addon:GetDB().iconSpacing = v
        self.valueText:SetText(tostring(v))
        ui:ApplySizingAndLayout()
    end)

    queueOffsetX:SetScript("OnValueChanged", function(self, value)
        local v = math.floor(value + 0.5)
        addon:GetDB().queueOffsetX = v
        self.valueText:SetText(tostring(v))
        ui:ApplyQueueDirection()
    end)

    queueOffsetY:SetScript("OnValueChanged", function(self, value)
        local v = math.floor(value + 0.5)
        addon:GetDB().queueOffsetY = v
        self.valueText:SetText(tostring(v))
        ui:ApplyQueueDirection()
    end)

    keybindSize:SetScript("OnValueChanged", function(self, value)
        local v = math.floor(value + 0.5)
        addon:GetDB().keybindFontSize = v
        self.valueText:SetText(tostring(v))
        ui:ApplySizingAndLayout()
    end)

    hotkeyOffsetX:SetScript("OnValueChanged", function(self, value)
        local v = math.floor(value + 0.5)
        addon:GetDB().keybindOffsetX = v
        self.valueText:SetText(tostring(v))
        ui:ApplyKeybindPosition()
    end)

    hotkeyOffsetY:SetScript("OnValueChanged", function(self, value)
        local v = math.floor(value + 0.5)
        addon:GetDB().keybindOffsetY = v
        self.valueText:SetText(tostring(v))
        ui:ApplyKeybindPosition()
    end)

    self.options = {
        panel = panel,
        enabled = enabled,
        outOfCombat = outOfCombat,
        queueLeft = queueLeft,
        iconCount = iconCount,
        iconSize = iconSize,
        queueIconSize = queueIconSize,
        iconSpacing = iconSpacing,
        queueOffsetX = queueOffsetX,
        queueOffsetY = queueOffsetY,
        keybindSize = keybindSize,
        hotkeyPosDropdown = hotkeyPosDropdown,
        hotkeyOffsetX = hotkeyOffsetX,
        hotkeyOffsetY = hotkeyOffsetY,
        shapeDropdown = shapeDropdown,
        themeDropdown = themeDropdown,
        bgTextureDropdown = bgTextureDropdown,
    }
end

function ui:ToggleOptions()
    if not self.options or not self.options.panel then
        return
    end

    if self.options.panel:IsShown() then
        self.options.panel:Hide()
    else
        self:RefreshOptions()
        self.options.panel:Show()
    end
end

function ui:RefreshOptions()
    if not self.options then
        return
    end

    local db = addon:GetDB()
    self.options.enabled:SetChecked(db.enabled and true or false)
    self.options.outOfCombat:SetChecked(db.showOutOfCombat and true or false)
    self.options.queueLeft:SetChecked((db.queueDirection or "right") == "left")
    self.options.iconCount:SetValue(db.numIconsShown or 3)
    self.options.iconCount.valueText:SetText(tostring(db.numIconsShown or 3))

    self.options.iconSize:SetValue(db.iconSize or 80)
    self.options.iconSize.valueText:SetText(tostring(db.iconSize or 80))

    self.options.queueIconSize:SetValue(db.queueIconSize or 52)
    self.options.queueIconSize.valueText:SetText(tostring(db.queueIconSize or 52))

    self.options.iconSpacing:SetValue(db.iconSpacing or 8)
    self.options.iconSpacing.valueText:SetText(tostring(db.iconSpacing or 8))

    self.options.queueOffsetX:SetValue(db.queueOffsetX or 0)
    self.options.queueOffsetX.valueText:SetText(tostring(db.queueOffsetX or 0))

    self.options.queueOffsetY:SetValue(db.queueOffsetY or 0)
    self.options.queueOffsetY.valueText:SetText(tostring(db.queueOffsetY or 0))

    self.options.keybindSize:SetValue(db.keybindFontSize or 18)
    self.options.keybindSize.valueText:SetText(tostring(db.keybindFontSize or 18))

    self.options.hotkeyPosDropdown:SetValue(db.keybindPosition or "center")
    self.options.hotkeyOffsetX:SetValue(db.keybindOffsetX or 0)
    self.options.hotkeyOffsetX.valueText:SetText(tostring(db.keybindOffsetX or 0))
    self.options.hotkeyOffsetY:SetValue(db.keybindOffsetY or 0)
    self.options.hotkeyOffsetY.valueText:SetText(tostring(db.keybindOffsetY or 0))
    self.options.shapeDropdown:SetValue(db.iconShape or "square")
    self.options.themeDropdown:SetValue(getThemeKey())
    self.options.bgTextureDropdown:SetValue(db.emptyIconTexture or EMPTY_TEXTURE)

    self:ApplyTheme()
end

function ui:SavePosition()
    if not self.frame then
        return
    end

    local anchor, _, relativePoint, x, y = self.frame:GetPoint(1)
    local dbPoint = addon:GetDB().point
    dbPoint.anchor = anchor
    dbPoint.relativeTo = "UIParent"
    dbPoint.relativePoint = relativePoint
    dbPoint.x = x
    dbPoint.y = y
end

function ui:SetLocked(locked)
    addon:GetDB().locked = locked
    setFrameMovable(self.frame, false)
end

function ui:SetRecommendations(recommendations, state)
    if not self.frame then
        return
    end

    if not addon:GetDB().enabled then
        self.frame:Hide()
        self:UpdateAnchorVisibility()
        return
    end

    if not addon:GetDB().showOutOfCombat and state and not state.inCombat then
        self.frame:Hide()
        self:UpdateAnchorVisibility()
        return
    end

    self.frame:Show()
    self:UpdateAnchorVisibility()

    if not recommendations or #recommendations == 0 then
        self:ClearRecommendation(state)
        return
    end

    local numIcons = math.max(1, math.min(5, addon:GetDB().numIconsShown or 3))
    for i = 1, #self.slots do
        local rec = recommendations[i]
        local slot = self.slots[i]

        if i > numIcons then
            slot:Hide()
        else
            slot:Show()
        end

        if i > numIcons then
            -- Skip processing hidden slots.
        elseif rec then
            local l, r, t, b = getFilledTexCoords()
            slot.icon:SetTexture(rec.icon or ICON_FALLBACK)
            slot.icon:SetTexCoord(l, r, t, b)
            slot.icon:SetVertexColor(1, 1, 1, 1)
            slot.icon:SetDesaturated(false)
            slot:SetAlpha(i == 1 and 1.0 or 0.85)
            slot.keyText:SetText(rec.keybind or "")
            slot.keyText:SetShown(rec.keybind ~= nil and rec.keybind ~= "")
        else
            slot.icon:SetTexture(addon:GetDB().emptyIconTexture or EMPTY_TEXTURE)
            slot.icon:SetTexCoord(0, 1, 0, 1)
            slot.icon:SetVertexColor(0.08, 0.08, 0.08, 0.95)
            slot.icon:SetDesaturated(false)
            slot:SetAlpha(0.6)
            slot.keyText:SetText("")
            slot.keyText:Hide()
        end
    end

    self.glow:Show()
    if not self.pulse:IsPlaying() then
        self.pulse:Play()
    end

    if state and state.gcdRemains and state.gcdRemains > 0 then
        self.frame:SetAlpha(0.75)
    else
        self.frame:SetAlpha(1.0)
    end
end

function ui:SetRecommendation(rec, state)
    if rec and rec.spellID then
        self:SetRecommendations({ rec }, state)
        return
    end

    self:SetRecommendations(rec, state)
end

function ui:ClearRecommendation(state)
    if not self.frame then
        return
    end

    local numIcons = math.max(1, math.min(5, addon:GetDB().numIconsShown or 3))
    for i = 1, #self.slots do
        local slot = self.slots[i]
        if i > numIcons then
            slot:Hide()
        else
            slot:Show()
        end
        if i > numIcons then
            -- Skip hidden.
        else
            slot.icon:SetTexture(addon:GetDB().emptyIconTexture or EMPTY_TEXTURE)
            slot.icon:SetTexCoord(0, 1, 0, 1)
            slot.icon:SetVertexColor(0.08, 0.08, 0.08, 0.95)
            slot.icon:SetDesaturated(false)
            slot:SetAlpha(0.6)
            slot.keyText:SetText("")
            slot.keyText:Hide()
        end
    end

    self.glow:Hide()
    self.pulse:Stop()

    if state and state.inCombat then
        self.frame:SetAlpha(0.5)
    else
        self.frame:SetAlpha(0.35)
    end

    self:UpdateAnchorVisibility()
end
