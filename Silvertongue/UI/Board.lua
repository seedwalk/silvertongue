-- Board.lua -- the menu that hangs off a control.
--
-- Shaped like the game's own right-click menu: a heading, clickable text rows,
-- and a divider before the things that act rather than speak. It should read as
-- part of the UI, not as a panel that landed on top of it.
--
-- One board per anchor group, not one global board: the target's, the party's
-- and your own are separate windows with separate state, so a line waiting in
-- one is not lost by opening another. They are instances of this one class --
-- the code is single, the windows are not.
--
-- It grows downward from a fixed top edge, so a longer context never shifts
-- what you are already looking at.

local ADDON, ns = ...

local Board = {}
Board.__index = Board
ns.Board = Board

local WIDTH      = 152
local ROW_H      = 15
local PAD        = 8
local MAX_ROWS   = 26

local instances = {}

-- A transparent sheet over the world, shown while any menu is open. Clicking
-- anywhere that is not the menu closes everything.
--
-- An X in a corner is the wrong gesture for something that behaves like a
-- context menu: nobody aims for it, they click away and expect it gone. It
-- sits below the menus and above the world, so the menus and the controls that
-- open them still take their own clicks.
local catcher

local function ensureCatcher()
    if catcher then return catcher end

    catcher = CreateFrame("Frame", "SilvertongueClickCatcher", UIParent)
    catcher:SetAllPoints(UIParent)
    catcher:SetFrameStrata("HIGH")
    catcher:EnableMouse(true)
    catcher:Hide()
    catcher:SetScript("OnMouseDown", function()
        ns.Board:CloseAll()
    end)
    return catcher
end

-- Up while anything is open, down the moment nothing is.
local function updateCatcher()
    ensureCatcher()
    for _, board in pairs(instances) do
        if board:IsShown() then
            catcher:Show()
            return
        end
    end
    catcher:Hide()
end

function Board:CloseAll()
    for _, board in pairs(instances) do board:Close() end
    if ns.Display then ns.Display:Close() end
end

function Board:New(key)
    if instances[key] then return instances[key] end
    local board = setmetatable({ key = key, rows = {} }, Board)
    instances[key] = board
    return board
end

function Board:All()
    return instances
end

local function makeDivider(parent)
    local line = parent:CreateTexture(nil, "ARTWORK")
    line:SetTexture("Interface\\Buttons\\WHITE8X8")
    line:SetVertexColor(0.45, 0.38, 0.28, 0.7)
    line:SetHeight(1)
    line:Hide()
    return line
end

function Board:Create()
    if self.frame then return self.frame end

    local f = CreateFrame("Frame", "SilvertongueBoard" .. self.key, UIParent, "BackdropTemplate")
    f:SetWidth(WIDTH)
    -- Above the click catcher, and above Blizzard's own dialogs: the group
    -- browser is one, and a menu opening behind it looks like a dead button.
    f:SetFrameStrata("FULLSCREEN_DIALOG")
    f:SetToplevel(true)
    f:SetBackdrop({
        bgFile   = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 12,
        insets = { left = 3, right = 3, top = 3, bottom = 3 },
    })
    f:EnableMouse(true)
    f:SetClampedToScreen(true)
    f:Hide()
    self.frame = f

    -- No close button. Clicking away dismisses it, pressing the control that
    -- opened it dismisses it, Escape dismisses it, and speaking dismisses it.
    -- An X in the corner was a fifth way that nobody reaches for, on a frame
    -- with no room to spare.
    tinsert(UISpecialFrames, f:GetName())

    self.actionDivider = makeDivider(f)
    self.groupDividers = {}

    return f
end

-- Rows are plain highlighted text, built once and reused.
function Board:AcquireRow(index)
    local row = self.rows[index]
    if row then return row end

    row = CreateFrame("Button", nil, self.frame)
    row:SetSize(WIDTH - PAD * 2, ROW_H)
    row:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight")

    row.label = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    row.label:SetPoint("LEFT", 2, 0)
    row.label:SetJustifyH("LEFT")

    row:SetScript("OnClick", function(self)
        if self.setDungeon then
            ns.SetDungeon(self.setDungeon)
            -- Reopened rather than closed: you picked it to then say something.
            self.board:Open(self.board.anchorControl, ns.Contexts:Group())
            return
        end
        if self.entry then Board.Pick(self.board, self.entry, self) end
        if self.action then
            -- Opening one of our own windows acts on a name we already hold, so
            -- it does not need a selection the way inviting or trading does.
            if self.action.local_ then
                pcall(self.action.run)
                return
            end
            if not UnitExists("target") then return end
            pcall(self.action.run, UnitName("target"))
        end
    end)
    row:SetScript("OnEnter", function(self)
        if not self.action then return end
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(self.action.label)
        GameTooltip:AddLine(self.action.tip, 1, 1, 1, true)
        if not self.action.local_ then
            GameTooltip:AddLine("Acts immediately -- they still have to accept.", 0.7, 0.7, 0.7, true)
        end
        GameTooltip:Show()
    end)
    row:SetScript("OnLeave", function() GameTooltip:Hide() end)

    row.board = self
    self.rows[index] = row
    return row
end

-- context = { key, title, subtitle, intents, actions, ctx, rebuild,
--             recipient, channels, emoteTarget }
function Board:Open(anchor, context)
    self:Create()

    if self.anchorControl and self.anchorControl ~= anchor and self.anchorControl.setActive then
        self.anchorControl.setActive(self.anchorControl, false)
    end
    self.anchorControl = anchor
    if anchor and anchor.setActive then anchor.setActive(anchor, true) end

    self.context = context

    -- No heading. The unit frame this hangs off already names who you are
    -- talking to, and which category is open is shown on the control itself.
    local top = 8

    local index, y, groups = 1, top, 0
    local emitted = false
    for _, entry in ipairs(context.intents) do
        if index > MAX_ROWS then break end

        if entry == ns.SEP then
            -- Never a line before the first row or two in a row: an intent may
            -- have been filtered out of the group it was separating.
            if emitted then
                groups = groups + 1
                local line = self.groupDividers[groups] or makeDivider(self.frame)
                self.groupDividers[groups] = line
                y = y + 3
                line:ClearAllPoints()
                line:SetPoint("TOPLEFT", PAD + 2, -y)
                line:SetPoint("TOPRIGHT", -PAD - 2, -y)
                line:Show()
                y = y + 4
                emitted = false
            end
        elseif entry.setDungeon then
            -- A setting rather than something to say: it changes what the
            -- adverts name and closes nothing.
            local row = self:AcquireRow(index)
            row:ClearAllPoints()
            row:SetPoint("TOPLEFT", PAD, -y)
            row.label:SetText(entry.label)
            row.label:SetTextColor(0.75, 0.75, 0.75)
            row.entry, row.action, row.setDungeon = nil, nil, entry.setDungeon
            row:Show()
            index, y, emitted = index + 1, y + ROW_H, true
        else
            local row = self:AcquireRow(index)
            row:ClearAllPoints()
            row:SetPoint("TOPLEFT", PAD, -y)
            row.label:SetText(entry[3])
            row.label:SetTextColor(1, 1, 1)
            row.entry, row.action, row.setDungeon = entry, nil, nil
            row:Show()
            index, y, emitted = index + 1, y + ROW_H, true
        end
    end
    for i = groups + 1, #self.groupDividers do self.groupDividers[i]:Hide() end

    -- The things that act rather than speak, below a line, the way the game's
    -- own menu separates its sections.
    if context.actions and #context.actions > 0 then
        y = y + 4
        self.actionDivider:ClearAllPoints()
        self.actionDivider:SetPoint("TOPLEFT", PAD, -y)
        self.actionDivider:SetPoint("TOPRIGHT", -PAD, -y)
        self.actionDivider:Show()
        y = y + 5

        for _, action in ipairs(context.actions) do
            if index > MAX_ROWS then break end
            local row = self:AcquireRow(index)
            row:ClearAllPoints()
            row:SetPoint("TOPLEFT", PAD, -y)
            row.label:SetText(action.label)
            row.label:SetTextColor(1, 0.82, 0)
            row.entry, row.action, row.setDungeon = nil, action, nil
            row:Show()
            index, y = index + 1, y + ROW_H
        end
    else
        self.actionDivider:Hide()
    end

    for i = index, #self.rows do self.rows[i]:Hide() end
    self.frame:SetHeight(y + PAD)

    -- Opens to the right of what you clicked, not underneath it: a menu that
    -- drops down covers the very rows you would reach for next. Anchored by its
    -- top edge, so a longer menu grows downward and never shifts what is
    -- already under the cursor. Clamping keeps it on screen at the edges.
    if anchor then
        self.frame:ClearAllPoints()
        self.frame:SetPoint("TOPLEFT", anchor, "TOPRIGHT", 10, 6)
    elseif not self.frame:GetPoint() then
        self.frame:SetPoint("CENTER")
    end
    self.frame:Show()
    updateCatcher()
end

function Board:Close()
    if self.anchorControl and self.anchorControl.setActive then
        self.anchorControl.setActive(self.anchorControl, false)
    end
    self.anchorControl = nil
    if self.frame then self.frame:Hide() end
    if ns.Display and ns.Display:BelongsTo(self) then ns.Display:Close() end
    updateCatcher()
end

function Board:IsShown()
    return self.frame ~= nil and self.frame:IsShown()
end

function Board:Toggle(anchor, context)
    if self:IsShown() and self.context and self.context.key == context.key then
        self:Close()
        return
    end
    self:Open(anchor, context)
end

-- Picking fills the confirmation display. Picking the same intent again rerolls
-- it. Nothing here speaks.
function Board:Pick(entry, row)
    if not entry or not self.context then return end
    local category, intent = entry[1], entry[2]

    local ctx = self.context.ctx
    if self.context.rebuild then ctx = self.context.rebuild() or ctx end

    local text
    if ns.Engine:IsCurrent(category, intent, ctx) and ns.Display:IsShown() then
        text = ns.Engine:Reroll()
    else
        text = ns.Engine:Request(category, intent, ctx)
    end
    if not text then return end

    ns.Display:Show(self, category, intent, text, row)
end

-- Speaking leaves the menu up. It closes on its own control, its X, or Escape,
-- which is every way you would think to dismiss it.
function Board:AfterSend()
end
