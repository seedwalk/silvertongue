-- Tabs.lua -- intent grids. A click fills the preview. A click never speaks.

local ADDON, ns = ...

local Tabs = {}
ns.Tabs = Tabs

local COLUMNS, BUTTON_W, BUTTON_H, GAP = 3, 100, 24, 4

-- Intent keys per tab, in display order, with their button labels.
ns.INTENTS = {
    -- Grouped: fifteen in a flat column is a wall to read. The panel's grid
    -- ignores the separators; the menus draw a line.
    GENERAL = {
        { "HELLO", "Hello" },         { "GOODBYE", "Goodbye" },
        ns.SEP,
        { "THANKS", "Thanks" },       { "RESPECT", "Respect" },
        { "CONGRATULATE", "Congrats" }, { "APOLOGIZE", "Apologize" },
        ns.SEP,
        { "AGREE", "Agree" },         { "DISAGREE", "Disagree" },
        { "LAUGH", "Laugh" },         { "ENCOURAGE", "Encourage" },
        ns.SEP,
        { "READY", "Ready" },         { "WAIT", "Wait" },
        { "FOLLOW_ME", "Follow Me" },
        ns.SEP,
        { "VICTORY", "Victory" },     { "DEFEAT", "Defeat" },
    },
    ATTITUDE = {
        { "ANGRY", "Angry" },         { "SUSPICIOUS", "Suspicious" },   { "MOCK", "Mock" },
        { "THREATEN", "Threaten" },   { "IMPRESSED", "Impressed" },     { "DISAPPOINTED", "Let Down" },
        { "CONFUSED", "Confused" },   { "ANNOYED", "Annoyed" },         { "RESPECT", "Respect" },
    },
}

-- The faction tab's grid, one per faction. Same shape as the class grids.
ns.FACTION_INTENTS = {
    HORDE = {
        { "FOR_THE_HORDE", "For the Horde" }, { "LOKTAR", "Lok'tar" },   { "VICTORY", "Victory" },
        { "HONOR", "Honor" },                 { "THRALL", "Thrall" },    { "ORGRIMMAR", "Orgrimmar" },
        { "HORDE_PRIDE", "Horde Pride" },     { "BATTLE_CRY", "Battle Cry" },
    },
    ALLIANCE = {
        { "FOR_THE_ALLIANCE", "For the Alliance" }, { "RALLY", "Rally" },   { "VICTORY", "Victory" },
        { "HONOR", "Honor" },                       { "LEADER", "Leader" }, { "CAPITAL", "Capital" },
        { "PRIDE", "Pride" },                       { "BATTLE_CRY", "Battle Cry" },
    },
}

-- The class tab's grid, one per class that has phrases. The phrase category is
-- the class token itself, so these keys match ns.Phrases.SHAMAN / .ROGUE.
ns.CLASS_INTENTS = {
    SHAMAN = {
        { "ELEMENTS", "Elements" },   { "ANCESTORS", "Ancestors" }, { "SPIRITS", "Spirits" },
        { "TOTEMS", "Totems" },       { "EARTH", "Earth" },         { "FIRE", "Fire" },
        { "WATER", "Water" },         { "AIR", "Air" },             { "BLESSING", "Blessing" },
        { "WARNING", "Warning" },
    },
    ROGUE = {
        { "SHADOWS", "Shadows" },     { "BLADES", "Blades" },       { "STEALTH", "Stealth" },
        { "POISON", "Poison" },       { "PATIENCE", "Patience" },   { "SCOUT", "Scout" },
        { "KILL", "Kill" },           { "HONOR", "Honor" },         { "LUCK", "Luck" },
        { "WARNING", "Warning" },
    },
    WARRIOR = {
        { "RAGE", "Rage" },           { "SHIELD", "Shield" },       { "WEAPONS", "Weapons" },
        { "CHARGE", "Charge" },       { "WOUNDS", "Wounds" },       { "DISCIPLINE", "Discipline" },
        { "HONOR", "Honor" },         { "TAUNT", "Taunt" },         { "LUCK", "Luck" },
        { "WARNING", "Warning" },
    },
    PALADIN = {
        { "LIGHT", "Light" },         { "OATH", "Oath" },           { "JUDGEMENT", "Judgement" },
        { "PROTECTION", "Protect" },  { "HEALING", "Healing" },     { "MERCY", "Mercy" },
        { "HONOR", "Honor" },         { "DOUBT", "Doubt" },         { "BLESSING", "Blessing" },
        { "WARNING", "Warning" },
    },
    HUNTER = {
        { "BEAST", "Beast" },         { "TRACKING", "Tracking" },   { "THE_SHOT", "The Shot" },
        { "TRAPS", "Traps" },         { "WILDS", "Wilds" },         { "PATIENCE", "Patience" },
        { "SCOUT", "Scout" },         { "HONOR", "Honor" },         { "LUCK", "Luck" },
        { "WARNING", "Warning" },
    },
    PRIEST = {
        { "LIGHT", "Light" },         { "SHADOW", "Shadow" },       { "HEALING", "Healing" },
        { "FAITH", "Faith" },         { "MERCY", "Mercy" },         { "DOUBT", "Doubt" },
        { "DEATH", "Death" },         { "PRAYER", "Prayer" },       { "BLESSING", "Blessing" },
        { "WARNING", "Warning" },
    },
    MAGE = {
        { "ARCANE", "Arcane" },       { "FIRE", "Fire" },           { "FROST", "Frost" },
        { "PORTALS", "Portals" },     { "FOOD", "Food" },           { "STUDY", "Study" },
        { "POLYMORPH", "Sheep" },     { "DISDAIN", "Disdain" },     { "BLESSING", "Blessing" },
        { "WARNING", "Warning" },
    },
    WARLOCK = {
        { "FEL", "Fel" },             { "DEMON", "Demon" },         { "SOULS", "Souls" },
        { "PACT", "Pact" },           { "PAIN", "Pain" },           { "POWER", "Power" },
        { "COST", "The Cost" },       { "MOCK", "Mock" },           { "BLESSING", "Blessing" },
        { "WARNING", "Warning" },
    },
    DRUID = {
        { "SHAPES", "Shapes" },       { "NATURE", "Nature" },       { "BALANCE", "Balance" },
        { "THE_DREAM", "The Dream" }, { "CLAWS", "Claws" },         { "HEALING", "Healing" },
        { "PATIENCE", "Patience" },   { "WILD", "The Wild" },       { "BLESSING", "Blessing" },
        { "WARNING", "Warning" },
    },
}

-- The class and faction tabs borrow their key from whoever is logged in.
local function tabCategory(tabKey)
    if tabKey == "CLASS" then return ns.Engine:GetPlayerClass() end
    if tabKey == "FACTION" then return ns.Engine:GetPlayerFaction() end
    return tabKey
end

-- The key a menu's arrangement is stored under. The class and faction menus are
-- keyed by the class or faction itself, so a shaman and a rogue keep their own.
function ns.MenuKey(tabKey)
    if tabKey == "CLASS" then return "CLASS:" .. tostring(ns.Engine:GetPlayerClass()) end
    if tabKey == "FACTION" then return "FACTION:" .. tostring(ns.Engine:GetPlayerFaction()) end
    return tabKey
end

local function tabIntents(tabKey)
    local token, grids
    if tabKey == "CLASS" then
        token, grids = ns.Engine:GetPlayerClass(), ns.CLASS_INTENTS
    elseif tabKey == "FACTION" then
        token, grids = ns.Engine:GetPlayerFaction(), ns.FACTION_INTENTS
    else
        local builtin = ns.INTENTS[tabKey]
        return builtin and ns.ResolveMenu(tabKey, builtin) or nil
    end
    local builtin = token and grids[token]
    return builtin and ns.ResolveMenu(ns.MenuKey(tabKey), builtin) or nil
end

ns.TabIntents = tabIntents

-- Buttons are created once and reused across tabs.
local pool = {}

function ns.AcquireButton(parent, index)
    local b = pool[index]
    if not b then
        b = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
        b:SetSize(BUTTON_W, BUTTON_H)
        b:GetFontString():SetFontObject("GameFontHighlightSmall")
        pool[index] = b
    end
    b:SetParent(parent)
    b:ClearAllPoints()
    b:Show()
    return b
end

function ns.ReleaseButtonsFrom(index)
    for i = index, #pool do
        pool[i]:Hide()
    end
end

-- Lays out entries in a grid and returns the next free pool index.
-- Each entry is { label = ..., onClick = function() end }.
function ns.LayoutGrid(parent, entries, startIndex, topOffset)
    local index = startIndex
    for i, entry in ipairs(entries) do
        local b = ns.AcquireButton(parent, index)
        local col = (i - 1) % COLUMNS
        local row = math.floor((i - 1) / COLUMNS)
        b:SetPoint("TOPLEFT", parent, "TOPLEFT",
            8 + col * (BUTTON_W + GAP),
            -topOffset - row * (BUTTON_H + GAP))
        b:SetText(entry.label)
        b:SetScript("OnClick", entry.onClick)
        index = index + 1
    end
    local rows = math.ceil(#entries / COLUMNS)
    return index, topOffset + rows * (BUTTON_H + GAP)
end

local function renderSimpleTab(tabKey)
    local content = ns.Window.frame.content
    local category = tabCategory(tabKey)
    local entries = {}
    for _, pair in ipairs(tabIntents(tabKey) or {}) do
        local intent, label = pair[1], pair[2]
        if pair ~= ns.SEP and ns.Engine:HasAnyPhrase(category, intent) then
        entries[#entries + 1] = {
            label = label,
            onClick = function()
                ns.Preview:SetRecipient(nil)
                ns.Preview:RequestOrReroll(category, intent, nil)
            end,
        }
        end
    end
    local nextIndex = ns.LayoutGrid(content, entries, 1, 8)
    ns.ReleaseButtonsFrom(nextIndex)
end

function Tabs:Select(tabKey)
    ns.Window:Create()
    -- An unknown tab, or the class tab on a character that has none, falls back.
    if tabKey ~= "PARTY" and tabKey ~= "TARGET" and not tabIntents(tabKey) then
        tabKey = "GENERAL"
    end

    self.current = tabKey
    ns.addon.db.profile.lastTab = tabKey

    for key, button in pairs(ns.Window.frame.tabs) do
        button:SetEnabled(key ~= tabKey)
    end

    ns.PartyUI:Hide()
    ns.TargetUI:Hide()
    if tabKey == "PARTY" then
        ns.PartyUI:Show()
    elseif tabKey == "TARGET" then
        ns.TargetUI:Show()
    else
        renderSimpleTab(tabKey)
    end

    ns.Preview:ApplyTabChannel(tabKey)
    ns.Preview:UpdateButtons()
end

function Tabs:Refresh()
    if self.current then self:Select(self.current) end
end
