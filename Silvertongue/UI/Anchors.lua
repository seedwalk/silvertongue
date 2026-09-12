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
    -- On the screen, not on the anchor. Some of the things these hang off are
    -- font strings rather than frames -- a player's level text, for one -- and
    -- a frame cannot be parented to one of those: the client refuses with
    -- "Wrong object type for function" and the addon does not load.
    local control = CreateFrame("Button", "SilvertongueAnchor" .. key, UIParent)

    -- Where the unit frames live, and no higher. It used to sit at the very top
    -- of the draw order so that pressing a bubble while a menu was open would
    -- switch to it rather than be swallowed by the click catcher -- and the
    -- price of that was five bubbles floating over the group browser, through
    -- a window they should have been behind. Two clicks to switch menus is the
    -- cheaper of the two.
    control:SetFrameStrata("MEDIUM")
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
-- Paints a fan row's icon. `spec` is either a texture path or { classOf = unit },
-- which draws that unit's class circle -- the one icon every WoW player reads
-- without being told.
local function paintIcon(icon, spec)
    if type(spec) == "table" and spec.classOf then
        local _, classToken = UnitClass(spec.classOf)
        local coords = classToken and CLASS_ICON_TCOORDS and CLASS_ICON_TCOORDS[classToken]
        if coords then
            icon:SetTexture("Interface\\TargetingFrame\\UI-Classes-Circles")
            icon:SetTexCoord(coords[1], coords[2], coords[3], coords[4])
            return
        end
        -- A creature has no class, so it falls back to the speech bubble.
        icon:SetTexture(SPEAK_ICON)
        icon:SetTexCoord(0, 1, 0, 1)
        return
    end

    local path = spec or SPEAK_ICON
    icon:SetTexture(path)
    if path:find("Icons") then
        icon:SetTexCoord(ICON_TRIM, 1 - ICON_TRIM, ICON_TRIM, 1 - ICON_TRIM)
    else
        icon:SetTexCoord(0, 1, 0, 1)
    end
end

local function createLabel(key, parent, default, iconSpec, text, onClick, backdrop)
    local control = CreateFrame("Button", "SilvertongueAnchor" .. key, UIParent,
        backdrop and "BackdropTemplate" or nil)
    control:SetFrameStrata("MEDIUM")

    -- One row on its own reads as a stray pixel over the world; in the fan it
    -- has four neighbours to give it an edge. A plate supplies the edge.
    if backdrop and control.SetBackdrop then
        control:SetBackdrop({
            bgFile   = "Interface\\Buttons\\WHITE8X8",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            edgeSize = 10,
            insets = { left = 2, right = 2, top = 2, bottom = 2 },
        })
        control:SetBackdropColor(0, 0, 0, 0.7)
        control:SetBackdropBorderColor(0.3, 0.3, 0.3, 0.8)
    end
    control:SetSize(FAN_WIDTH, PLAYER_ICON_SIZE)
    control.anchorKey = key

    local icon = control:CreateTexture(nil, "ARTWORK")
    icon:SetSize(PLAYER_ICON_SIZE, PLAYER_ICON_SIZE)
    icon:SetPoint("LEFT", backdrop and 5 or 0, 0)

    paintIcon(icon, iconSpec)
    icon:SetAlpha(0.75)
    control.repaint = function(self, spec) paintIcon(icon, spec) end
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

-- Straight down from a bubble, evenly spaced. Shared by both fans.
local function placeInStack(control, hub, index)
    control:ClearAllPoints()
    control:SetPoint("TOPLEFT", hub, "BOTTOMLEFT", 0, -2 - (index - 1) * FAN_ROW_H)
end

local function enabled()
    return ns.addon and ns.addon.db and ns.addon.db.profile.anchorsEnabled
end

--------------------------------------------------------------------------------
-- Your own portrait: four categories.
--------------------------------------------------------------------------------

local PLAYER_TABS = { "GENERAL", "FACTION", "CLASS", "ATTITUDE" }

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
            local iconSpec = (tabKey == "CLASS") and { classOf = "player" }
                or PLAYER_ICONS[tabKey]
            local control = createLabel("PLAYER_" .. tabKey, nil,
                { point = "CENTER", x = 0, y = 0 }, iconSpec, context.subtitle,
                function(self)
                    -- Rebuilt on click: the group changes, and so does what is
                    -- worth asking for.
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
-- The target: a bubble under their level, fanning out the same way.
--------------------------------------------------------------------------------

-- Speak leads, because talking is what this addon is for. Invite, Trade and
-- Duel act the moment you press them -- all three are only requests the other
-- player still has to accept, and burying them a menu deep made inviting
-- someone a three-click errand.
local TARGET_FAN = {
    {
        key = "SPEAK", label = "Speak",
        icon = "Interface\\Icons\\INV_Misc_GroupLooking",
        applies = function() return true end,
    },
    {
        key = "INVITE", label = "Invite",
        -- A plain plus rather than a spell icon: it means "add them" with no
        -- ambiguity, and being flat UI art it sets the rows that act apart from
        -- the round icons that identify.
        icon = "Interface\\Buttons\\UI-PlusButton-Up",
        -- Not offered for someone already in the group, or anything hostile.
        applies = function(info) return info.isPlayer and not info.hostile and not info.grouped end,
        run = function(name)
            if C_PartyInfo and C_PartyInfo.InviteUnit then
                C_PartyInfo.InviteUnit(name)
            elseif InviteUnit then
                InviteUnit(name)
            end
        end,
    },
    {
        key = "TRADE", label = "Trade",
        icon = "Interface\\Icons\\INV_Misc_Coin_01",
        applies = function(info) return info.isPlayer and not info.hostile end,
        run = function() if InitiateTrade then InitiateTrade("target") end end,
    },
    {
        key = "DUEL", label = "Duel",
        icon = "Interface\\Icons\\Ability_DualWield",
        applies = function(info) return info.isPlayer and not info.hostile end,
        run = function() if StartDuel then StartDuel("target") end end,
    },
}

function Anchors:CreateTarget()
    if self.targetBuilt then return end
    self.targetBuilt = true

    -- Under the target's level, mirroring where the player's sits.
    local parent = _G["TargetFrameTextureFrameLevelText"]
        or _G["TargetLevelText"] or TargetFrame

    self.targetControl = createIcon("TARGET", parent,
        { point = "TOPLEFT", relPoint = "BOTTOMLEFT", x = -3, y = -3 },
        function() Anchors:ToggleTargetFan() end)
    tooltip(self.targetControl, "Your target",
        "Opens what you can do with them. Press again to fold it away.")

    self.targetFan = {}
    for _, entry in ipairs(TARGET_FAN) do
        local control = createLabel("TARGET_" .. entry.key, nil,
            { point = "CENTER", x = 0, y = 0 }, entry.icon, entry.label,
            function(self)
                if not UnitExists("target") then return end
                if entry.run then
                    -- Guarded: a missing or protected API must not break the panel.
                    pcall(entry.run, UnitName("target"))
                    return
                end
                local context = ns.Contexts:Target()
                if context then targetBoard():Toggle(self, context) end
            end)
        tooltip(control, entry.label, entry.run
            and "Acts immediately -- they still have to accept."
            or "The phrases that fit whoever you have selected.")
        control.entry = entry
        self.targetFan[#self.targetFan + 1] = control
    end
end

function Anchors:ToggleTargetFan()
    self.targetFanOpen = not self.targetFanOpen
    self:UpdateTarget()
end

-- Follows the selection. The fan stays open or folded across targets -- it is
-- one switch, not one per person -- but which rows it holds is recomputed, and
-- an open phrase menu is refilled for whoever is selected now, or closed when
-- there is nobody left to talk to.
function Anchors:UpdateTarget()
    self:CreateTarget()
    local control = self.targetControl
    if not control then return end

    local info = enabled() and ns.Contexts:Target() or nil
    if not info then
        control:Hide()
        for _, row in ipairs(self.targetFan) do row:Hide() end
        targetBoard():Close()
        return
    end

    control:Show()

    local shown = 0
    for _, row in ipairs(self.targetFan) do
        if self.targetFanOpen and row.entry.applies(info) then
            shown = shown + 1
            placeInStack(row, control, shown)
            row:Show()
        else
            row:Hide()
        end
    end

    if targetBoard():IsShown() then
        if self.targetFanOpen then
            targetBoard():Open(targetBoard().anchorControl, info)
        else
            targetBoard():Close()
        end
    end
end

--------------------------------------------------------------------------------
-- The group: one icon per member, plus one for the group as a whole.
--------------------------------------------------------------------------------

-- The party frames have been renamed more than once across versions, so try the
-- shapes that exist rather than one guess. Returning nil is not fatal: the
-- caller falls back to the screen, where the control can at least be seen and
-- dragged somewhere useful.
local function partyMemberFrame(i)
    return _G["PartyMemberFrame" .. i]
        or (_G.PartyFrame and _G.PartyFrame["MemberFrame" .. i])
        or _G["CompactPartyFrameMember" .. i]
        or nil
end

function Anchors:CreateParty()
    if self.partyBuilt then return end
    self.partyBuilt = true

    for i = 1, 4 do
        local frame = partyMemberFrame(i)
        -- Anchored to the member's frame when there is one; otherwise stacked
        -- down the left of the screen, roughly where those frames live.
        local default = frame
            and { point = "TOPLEFT", relPoint = "TOPRIGHT", x = -8, y = -4 }
            or { point = "TOPLEFT", relPoint = "TOPLEFT", x = 30, y = -190 - (i - 1) * 50 }
        local control = createIcon("PARTY" .. i, frame or UIParent, default,
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
    local first = partyMemberFrame(1)
    local allDefault = first
        and { point = "BOTTOMLEFT", relPoint = "TOPLEFT", x = 8, y = 10 }
        or { point = "TOPLEFT", relPoint = "TOPLEFT", x = 30, y = -170 }
    -- Labelled rather than bare. The four member bubbles sit on frames that
    -- name the person for them; this one hangs above the block with nothing
    -- around it, and a 16-pixel icon alone up there reads as a smudge.
    local control = createLabel("PARTY_ALL", first or UIParent, allDefault,
        nil, "Party",
        function(self)
            partyBoard():Toggle(self, ns.Contexts:PartyAll())
        end, true)
    control:SetSize(76, PLAYER_ICON_SIZE + 6)
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

-- Reports what the party controls actually attached to.
function Anchors:DescribeParty()
    local lines = {}
    for i = 1, 4 do
        local frame = partyMemberFrame(i)
        lines[#lines + 1] = "  member " .. i .. ": "
            .. (frame and (frame:GetName() or "an unnamed frame") or "no frame found, using the screen")
    end
    return lines
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
