-- Anchors.lua -- the controls that sit on Blizzard's frames.
--
-- Level one. A control knows two things: where it sits, and which context it
-- puts in which board. No phrases, no menu of its own.
--
-- They anchor to the stock unit frames, so anyone running replacement unit
-- frames would find them pointing at nothing. That is why every control can be
-- dragged with the right mouse button and remembers where it was dropped -- once
-- moved it hangs off the screen rather than off the frame, and survives the
-- frame being hidden entirely.

local ADDON, ns = ...

local Anchors = {}
ns.Anchors = Anchors

local SPEAK_ICON = "Interface\\GossipFrame\\GossipGossipIcon"

-- Declared up here, not beside the row that lays them out: a local declared
-- after the function that reads it compiles as a global and arrives nil.
local PLAYER_ICON_SIZE = 15

-- The four under your portrait. Swapping any of these is one line.
--
-- CLASS has no entry because it uses the game's own class circle, which every
-- player already reads without being told and which changes with the character.
-- Attitude deliberately avoids Challenging Shout, the obvious pick: it is
-- another shouting warrior and would be indistinguishable from Battle Shout at
-- this size.
local PLAYER_ICONS = {
    GENERAL  = "Interface\\Icons\\INV_Misc_GroupLooking",
    FACTION  = "Interface\\Icons\\Ability_Warrior_BattleShout",
    ATTITUDE = "Interface\\Icons\\Spell_Shadow_PsychicScream",
}

-- Spell icons carry a border in the texture. Trimming it is what stops them
-- reading as stickers stuck on the frame.
local ICON_TRIM = 0.07

-- The fan drops straight down from the bubble, one row per category.
local FAN_ROW_H  = 17
local FAN_WIDTH  = 74

-- One board per anchor group, each sized for its own longest context.
local function targetBoard() return ns.Board:New("Target") end
local function playerBoard() return ns.Board:New("Player") end
local function partyBoard()  return ns.Board:New("Party") end

local controls = {}

local function savePosition(control)
    local point, _, relPoint, x, y = control:GetPoint()
    local db = ns.addon and ns.addon.db
    if not db then return end
    db.profile.anchors = db.profile.anchors or {}
    db.profile.anchors[control.anchorKey] = { point = point, relPoint = relPoint, x = x, y = y }
end

local function restorePosition(control, parent, default)
    local saved = ns.addon and ns.addon.db
        and ns.addon.db.profile.anchors
        and ns.addon.db.profile.anchors[control.anchorKey]

    control:ClearAllPoints()
    if saved then
        control:SetPoint(saved.point, UIParent, saved.relPoint, saved.x, saved.y)
    elseif parent then
        control:SetPoint(default.point, parent, default.relPoint, default.x, default.y)
    else
        control:SetPoint(default.point, UIParent, "CENTER", default.x, default.y)
    end
end

local function makeDraggable(control)
    control:SetMovable(true)
    control:RegisterForDrag("RightButton")
    control:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    control:SetScript("OnDragStart", control.StartMoving)
    control:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        savePosition(self)
    end)
end

local function tooltip(control, title, line)
    control:SetScript("OnEnter", function(self)
        if self.highlight then self.highlight(self, true) end
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(title)
        GameTooltip:AddLine(line, 1, 1, 1, true)
        GameTooltip:AddLine("Right-click and drag to move it.", 0.7, 0.7, 0.7, true)
        GameTooltip:Show()
    end)
    control:SetScript("OnLeave", function(self)
        if self.highlight then self.highlight(self, false) end
        GameTooltip:Hide()
    end)
end

-- A speech bubble: the gossip icon the game already uses for "talk to this".
local function createIcon(key, parent, default, onClick)
    local control = CreateFrame("Button", "SilvertongueAnchor" .. key, UIParent)
    -- Above the click catcher, so pressing a bubble while a menu is open
    -- switches to it rather than being swallowed as a click outside.
    control:SetFrameStrata("DIALOG")
    control:SetSize(16, 16)
    control.anchorKey = key

    local icon = control:CreateTexture(nil, "ARTWORK")
    icon:SetAllPoints()
    icon:SetTexture(SPEAK_ICON)
    icon:SetAlpha(0.75)
    control.icon = icon

    local function paint(self)
        icon:SetAlpha((self.active or self.hovered) and 1 or 0.75)
        icon:SetVertexColor(self.active and 1 or 1, self.active and 0.9 or 1,
                            self.active and 0.5 or 1)
    end
    control.highlight = function(self, on) self.hovered = on; paint(self) end
    control.setActive = function(self, on) self.active = on; paint(self) end

    control:SetScript("OnClick", function(self, button)
        if button == "RightButton" then return end
        onClick(self)
    end)
    makeDraggable(control)
    restorePosition(control, parent, default)
    control:Hide()

    controls[key] = control
    return control
end

-- A row: the icon, and what it is, beside it. An arc of bare icons looked
-- ragged and said nothing about which was which; a short stack says both and
-- takes about as much room.
local function createLabel(key, parent, default, tabKey, text, onClick)
    local control = CreateFrame("Button", "SilvertongueAnchor" .. key, UIParent)
    control:SetFrameStrata("DIALOG")
    control:SetSize(FAN_WIDTH, PLAYER_ICON_SIZE)
    control.anchorKey = key

    local icon = control:CreateTexture(nil, "ARTWORK")
    icon:SetSize(PLAYER_ICON_SIZE, PLAYER_ICON_SIZE)
    icon:SetPoint("LEFT")

    if tabKey == "CLASS" then
        -- The game's own class circle, and the coordinates that cut this class
        -- out of the shared sheet.
        local _, classToken = UnitClass("player")
        local coords = classToken and CLASS_ICON_TCOORDS and CLASS_ICON_TCOORDS[classToken]
        icon:SetTexture("Interface\\TargetingFrame\\UI-Classes-Circles")
        if coords then
            icon:SetTexCoord(coords[1], coords[2], coords[3], coords[4])
        end
    else
        icon:SetTexture(PLAYER_ICONS[tabKey] or SPEAK_ICON)
        icon:SetTexCoord(ICON_TRIM, 1 - ICON_TRIM, ICON_TRIM, 1 - ICON_TRIM)
    end
    icon:SetAlpha(0.75)
    control.icon = icon

    local label = control:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    label:SetPoint("LEFT", icon, "RIGHT", 4, 0)
    label:SetJustifyH("LEFT")
    label:SetText(text)
    control.label = label

    -- Hovering brightens; being the open one stays gold until it closes.
    local function paint(self)
        if self.active then
            icon:SetAlpha(1)
            label:SetTextColor(1, 0.82, 0)
        elseif self.hovered then
            icon:SetAlpha(1)
            label:SetTextColor(1, 1, 1)
        else
            icon:SetAlpha(0.75)
            label:SetTextColor(0.85, 0.85, 0.85)
        end
    end
    control.highlight = function(self, on) self.hovered = on; paint(self) end
    control.setActive = function(self, on) self.active = on; paint(self) end
    paint(control)

    control:SetScript("OnClick", function(self, button)
        if button == "RightButton" then return end
        onClick(self)
    end)
    -- A fan row is placed by the bubble it belongs to, so it is not draggable
    -- on its own: pulling one out of the stack would only break the stack.
    if parent then
        makeDraggable(control)
        restorePosition(control, parent, default)
    end
    control:Hide()

    controls[key] = control
    return control
end

local function enabled()
    return ns.addon and ns.addon.db and ns.addon.db.profile.anchorsEnabled
end

--------------------------------------------------------------------------------
-- Your own portrait: four categories.
--------------------------------------------------------------------------------

local PLAYER_TABS = { "GENERAL", "FACTION", "CLASS", "ATTITUDE" }

-- Straight down from the bubble, evenly spaced.
local function placeInStack(control, hub, index)
    control:ClearAllPoints()
    control:SetPoint("TOPLEFT", hub, "BOTTOMLEFT", 0, -2 - (index - 1) * FAN_ROW_H)
end

function Anchors:CreatePlayer()
    if self.playerBuilt then return end
    self.playerBuilt = true

    -- At rest this is one small bubble tucked under the level badge. It is the
    -- switch: pressing it fans the categories out around itself, pressing it
    -- again folds them away. Nothing else is on screen until you ask for it.
    local hub = createIcon("PLAYER_HUB", PlayerLevelText or PlayerFrame,
        { point = "TOPLEFT", relPoint = "BOTTOMLEFT", x = -3, y = -3 },
        function() Anchors:ToggleFan() end)
    tooltip(hub, "Speak as " .. (UnitName("player") or "yourself"),
        "Opens the things you can say. Press again to fold them away.")
    self.hub = hub

    self.fanControls = {}
    for _, tabKey in ipairs(PLAYER_TABS) do
        local context = ns.Contexts:Player(tabKey)
        -- A character with no class or faction phrases gets no icon for it, and
        -- the arc closes up rather than leaving a gap in the ring.
        if context then
            local control = createLabel("PLAYER_" .. tabKey, nil,
                { point = "CENTER", x = 0, y = 0 }, tabKey, context.subtitle,
                function(self)
                    local fresh = ns.Contexts:Player(tabKey)
                    if fresh then playerBoard():Toggle(self, fresh) end
                end)
            tooltip(control, context.subtitle, "The " .. context.subtitle .. " phrases.")
            self.fanControls[#self.fanControls + 1] = control
        end
    end

    for i, control in ipairs(self.fanControls) do
        placeInStack(control, hub, i)
    end
end

--------------------------------------------------------------------------------
-- The target.
--------------------------------------------------------------------------------

function Anchors:CreateTarget()
    if self.targetControl then return self.targetControl end

    self.targetControl = createIcon("TARGET", TargetFrame,
        { point = "TOPLEFT", relPoint = "BOTTOMLEFT", x = 30, y = 8 },
        function(self)
            local context = ns.Contexts:Target()
            if not context then
                targetBoard():Close()
                return
            end
            targetBoard():Toggle(self, context)
        end)
    tooltip(self.targetControl, "Speak to your target", "The phrases that fit whoever you have selected.")
    return self.targetControl
end

function Anchors:UpdateTarget()
    local control = self:CreateTarget()
    if not control then return end

    local show = enabled()
        and UnitExists("target")
        and not UnitIsUnit("target", "player")

    if show then
        control:Show()
    else
        control:Hide()
        targetBoard():Close()
    end
end

--------------------------------------------------------------------------------
-- The group: one icon per member, plus one for the group as a whole.
--------------------------------------------------------------------------------

function Anchors:CreateParty()
    if self.partyBuilt then return end
    self.partyBuilt = true

    for i = 1, 4 do
        local frame = _G["PartyMemberFrame" .. i]
        local control = createIcon("PARTY" .. i, frame,
            { point = "TOPLEFT", relPoint = "TOPRIGHT", x = -8, y = -4 },
            function(self)
                local unit = "party" .. i
                if not UnitExists(unit) then return end
                local context = ns.Contexts:PartyMember(unit)
                if context then partyBoard():Toggle(self, context) end
            end)
        tooltip(control, "Speak to this one", "The phrases aimed at that member.")
        control.partyIndex = i
    end

    -- The group as a whole. Its own control, above the party block: when the
    -- group wipes you are looking there, not at your own portrait.
    local control = createIcon("PARTY_ALL", PartyMemberFrame1,
        { point = "BOTTOMLEFT", relPoint = "TOPLEFT", x = 8, y = 10 },
        function(self)
            partyBoard():Toggle(self, ns.Contexts:PartyAll())
        end)
    tooltip(control, "Speak to the group", "Ready, boss, wipe, and the rest.")
end

function Anchors:UpdateParty()
    self:CreateParty()

    local inGroup = IsInGroup() and not IsInRaid()
    for i = 1, 4 do
        local control = controls["PARTY" .. i]
        if control then
            if enabled() and inGroup and UnitExists("party" .. i) then
                control:Show()
            else
                control:Hide()
            end
        end
    end

    local all = controls.PARTY_ALL
    if all then
        if enabled() and IsInGroup() then all:Show() else all:Hide() end
    end

    if not IsInGroup() then partyBoard():Close() end
end

--------------------------------------------------------------------------------

function Anchors:ToggleFan()
    self:SetFanOpen(not self.fanOpen)
end

-- Not remembered between sessions. At rest this is meant to be one bubble, and
-- a menu that was left open an hour ago is not a preference worth restoring.
function Anchors:SetFanOpen(open)
    self.fanOpen = open and true or false
    for _, control in ipairs(self.fanControls or {}) do
        if self.fanOpen and enabled() then control:Show() else control:Hide() end
    end
    if not self.fanOpen then playerBoard():Close() end
end

function Anchors:SetEnabled(on)
    ns.addon.db.profile.anchorsEnabled = on and true or false
    self:Refresh()
    if not on then
        for _, board in pairs(ns.Board:All()) do board:Close() end
    end
end

function Anchors:Refresh()
    self:CreatePlayer()
    if self.hub then
        if enabled() then self.hub:Show() else self.hub:Hide() end
    end
    self:SetFanOpen(enabled() and self.fanOpen)
    self:UpdateTarget()
    self:UpdateParty()
end
