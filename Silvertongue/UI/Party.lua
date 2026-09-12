-- Party.lua (UI) -- the roster, and the per-person action screen.
-- Party data is read live from the group and kept nowhere.

local ADDON, ns = ...

local PartyUI = {}
ns.PartyUI = PartyUI

local ROW_HEIGHT = 20
local MAX_ROWS = 5

local EVERYONE = {
    { "HELLO", "Hello" },   { "READY", "Ready" },     { "GOOD_JOB", "Good Job" },
    { "WIPE", "Wipe" },     { "BOSS", "Boss" },       { "WAIT", "Wait" },
    { "MANA", "OOM" },      { "VICTORY", "Victory" }, { "GOODBYE", "Goodbye" },
}

-- One slot in that grid does not survive a change of class: a rogue never runs
-- out of mana, so the OOM button becomes the thing a rogue actually says when
-- the group needs to hold -- that he is going ahead to look.
local CLASS_SLOT = {
    ROGUE = { "SCOUT", "Scout" },
}

function ns.PartyEveryoneIntents()
    local swap = CLASS_SLOT[ns.Engine:GetPlayerClass() or ""]
    if not swap then return EVERYONE end

    local list = {}
    for _, pair in ipairs(EVERYONE) do
        list[#list + 1] = (pair[1] == "MANA") and swap or pair
    end
    return list
end

ns.PERSON_INTENTS = {
    { "THANK", "Thank" },         { "PRAISE", "Praise" },
    { "ENCOURAGE", "Encourage" }, { "RESPECT", "Respect" },
    { "WARN", "Warn" },           { "APOLOGIZE", "Apologize" },
    { "JOKE", "Joke" },
}

-- Silvertongue has opinions about fel magic. Warlocks get extra buttons.
ns.PERSON_WARLOCK_EXTRA = {
    { "DISTRUST", "Distrust" }, { "DEMON", "Demon" }, { "FEL_MAGIC", "Fel Magic" },
}

-- Member rows live in their own pool; they are not shaped like intent buttons.
local rows = {}

local function acquireRow(parent, index)
    local row = rows[index]
    if not row then
        row = CreateFrame("Button", nil, parent)
        row:SetHeight(ROW_HEIGHT)
        row:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight")

        row.name = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        row.name:SetPoint("LEFT", 6, 0)

        row.info = row:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
        row.info:SetPoint("RIGHT", -8, 0)

        rows[index] = row
    end
    row:SetParent(parent)
    row:ClearAllPoints()
    row:Show()
    return row
end

local function releaseRowsFrom(index)
    for i = index, #rows do rows[i]:Hide() end
end

-- Units in the current group, excluding the player.
function ns.GroupUnits()
    local units = {}
    local n = GetNumGroupMembers()
    if IsInRaid() then
        for i = 1, n do
            local unit = "raid" .. i
            if UnitExists(unit) and not UnitIsUnit(unit, "player") then
                units[#units + 1] = unit
            end
        end
    else
        for i = 1, n - 1 do
            local unit = "party" .. i
            if UnitExists(unit) then units[#units + 1] = unit end
        end
    end
    return units
end

local function ensureHeaders(content)
    if PartyUI.headers then return end
    PartyUI.headers = {}

    local everyone = content:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    everyone:SetPoint("TOPLEFT", 8, -6)
    everyone:SetText("EVERYONE")
    everyone:SetTextColor(0.85, 0.35, 0.25)
    PartyUI.headers.everyone = everyone

    local members = content:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    members:SetText("MEMBERS")
    members:SetTextColor(0.85, 0.35, 0.25)
    PartyUI.headers.members = members

    local empty = content:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    empty:SetText("You walk alone.")
    PartyUI.headers.empty = empty

    -- Person screen: back button and target header.
    local back = CreateFrame("Button", nil, content, "UIPanelButtonTemplate")
    back:SetSize(70, 20)
    back:SetPoint("TOPLEFT", 8, -6)
    back:SetText("< Party")
    back:SetScript("OnClick", function() PartyUI:ShowRoster() end)
    PartyUI.backButton = back

    local target = content:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    target:SetPoint("TOPLEFT", back, "BOTTOMLEFT", 0, -6)
    PartyUI.targetName = target

    local targetInfo = content:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    targetInfo:SetPoint("TOPLEFT", target, "BOTTOMLEFT", 0, -2)
    PartyUI.targetInfo = targetInfo
end

local function hideAll()
    if not PartyUI.headers then return end
    PartyUI.headers.everyone:Hide()
    PartyUI.headers.members:Hide()
    PartyUI.headers.empty:Hide()
    PartyUI.backButton:Hide()
    PartyUI.targetName:Hide()
    PartyUI.targetInfo:Hide()
    releaseRowsFrom(1)
end

function PartyUI:ShowRoster()
    local content = ns.Window.frame.content
    ensureHeaders(content)
    hideAll()
    self.view = "ROSTER"
    self.unitName = nil

    self.headers.everyone:Show()

    local entries = {}
    for _, pair in ipairs(ns.PartyEveryoneIntents()) do
        local intent, label = pair[1], pair[2]
        entries[#entries + 1] = {
            label = label,
            onClick = function()
                ns.Preview:SetRecipient(nil)
                ns.Preview:RequestOrReroll("PARTY", intent, nil)
            end,
        }
    end
    local nextIndex, bottom = ns.LayoutGrid(content, entries, 1, 24)
    ns.ReleaseButtonsFrom(nextIndex)

    self.headers.members:ClearAllPoints()
    self.headers.members:SetPoint("TOPLEFT", 8, -(bottom + 4))
    self.headers.members:Show()

    local units = ns.GroupUnits()
    local overflow = 0
    if #units > MAX_ROWS then
        overflow = #units - MAX_ROWS
        for i = #units, MAX_ROWS + 1, -1 do units[i] = nil end
    end

    if #units == 0 then
        self.headers.empty:ClearAllPoints()
        self.headers.empty:SetPoint("TOPLEFT", 12, -(bottom + 24))
        self.headers.empty:Show()
        return
    end

    for i, unit in ipairs(units) do
        local row = acquireRow(content, i)
        row:SetPoint("TOPLEFT", 6, -(bottom + 20 + (i - 1) * ROW_HEIGHT))
        row:SetPoint("RIGHT", content, "RIGHT", -6, 0)

        local ctx = ns.Engine:BuildUnitContext(unit)
        local color = ctx.classToken and RAID_CLASS_COLORS[ctx.classToken]
        row.name:SetText(ctx.name)
        if color then row.name:SetTextColor(color.r, color.g, color.b) end
        row.info:SetText((ctx.raceName or "") .. " " .. (ctx.className or ""))

        row.unit = unit
        row:SetScript("OnClick", function(self) PartyUI:ShowPerson(self.unit) end)
    end
    releaseRowsFrom(#units + 1)

    if overflow > 0 then
        self.headers.empty:ClearAllPoints()
        self.headers.empty:SetPoint("TOPLEFT", 12, -(bottom + 20 + #units * ROW_HEIGHT))
        self.headers.empty:SetText("...and " .. overflow .. " more in the raid.")
        self.headers.empty:Show()
    else
        self.headers.empty:SetText("You walk alone.")
    end
end

-- Finds the unit id currently holding a given member name, or nil if they left.
function PartyUI:ResolveUnit(name)
    if not name then return nil end
    for _, unit in ipairs(ns.GroupUnits()) do
        if ns.UnitFullName(unit) == name then return unit end
    end
    return nil
end

function PartyUI:ShowPerson(unit)
    local ctx = ns.Engine:BuildUnitContext(unit)
    if not ctx then
        self:ShowRoster()
        return
    end

    local content = ns.Window.frame.content
    ensureHeaders(content)
    hideAll()
    self.view = "PERSON"
    self.unit = unit
    self.unitName = ctx.name

    self.backButton:Show()
    self.targetName:SetText(ctx.name)
    local color = ctx.classToken and RAID_CLASS_COLORS[ctx.classToken]
    if color then self.targetName:SetTextColor(color.r, color.g, color.b) end
    self.targetName:Show()
    self.targetInfo:SetText((ctx.raceName or "") .. " " .. (ctx.className or ""))
    self.targetInfo:Show()

    local list = {}
    for _, pair in ipairs(ns.PERSON_INTENTS) do list[#list + 1] = pair end
    if ctx.classToken == "WARLOCK" then
        for _, pair in ipairs(ns.PERSON_WARLOCK_EXTRA) do list[#list + 1] = pair end
    end

    local entries = {}
    for _, pair in ipairs(list) do
        local intent, label = pair[1], pair[2]
        entries[#entries + 1] = {
            label = label,
            -- The unit is resolved by name at click time: ids shift when the
            -- group changes, names do not.
            onClick = function()
                local live = PartyUI:ResolveUnit(ctx.name)
                ns.Preview:SetRecipient(ctx.name)
                ns.Preview:RequestOrReroll("PERSON", intent, live and ns.Engine:BuildUnitContext(live) or ctx)
            end,
        }
    end

    local nextIndex = ns.LayoutGrid(content, entries, 1, 64)
    ns.ReleaseButtonsFrom(nextIndex)
end

function PartyUI:Show()
    local unit = self.view == "PERSON" and self:ResolveUnit(self.unitName) or nil
    if unit then
        self:ShowPerson(unit)
    else
        self:ShowRoster()
    end
end

function PartyUI:Hide()
    hideAll()
end

-- Called on GROUP_ROSTER_UPDATE.
function PartyUI:Refresh()
    if not ns.Window.frame or not ns.Window.frame:IsShown() then return end
    if ns.Tabs.current ~= "PARTY" then return end
    self:Show()
end
