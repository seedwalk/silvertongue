-- Window.lua -- the main frame: header, tab strip, content area, preview block.

local ADDON, ns = ...

local Window = {}
ns.Window = Window

local WIDTH, HEIGHT = 360, 500

-- Two tabs are resolved from the character rather than fixed: the class tab and
-- the faction tab. Both work the same way -- a label here, a phrase table named
-- by the same token, and a grid in UI/Tabs.lua. Adding a class or a faction is
-- three table entries and no new code.
ns.CLASS_TAB_LABEL = {
    SHAMAN  = "Shaman",
    ROGUE   = "Rogue",
}

ns.FACTION_TAB_LABEL = {
    HORDE    = "Horde",
    ALLIANCE = "Alliance",
}

function ns.ClassTabLabel()
    local token = ns.Engine:GetPlayerClass()
    return token and ns.CLASS_TAB_LABEL[token] or nil
end

function ns.FactionTabLabel()
    local token = ns.Engine:GetPlayerFaction()
    return token and ns.FACTION_TAB_LABEL[token] or nil
end

function ns.BuildTabs()
    local tabs = {
        { key = "GENERAL",  label = "General"  },
        { key = "PARTY",    label = "Party"    },
        { key = "TARGET",   label = "Target"   },
    }
    local factionLabel = ns.FactionTabLabel()
    if factionLabel then
        tabs[#tabs + 1] = { key = "FACTION", label = factionLabel }
    end
    local classLabel = ns.ClassTabLabel()
    if classLabel then
        tabs[#tabs + 1] = { key = "CLASS", label = classLabel }
    end
    tabs[#tabs + 1] = { key = "ATTITUDE", label = "Attitude" }
    return tabs
end

ns.TABS = nil

-- Shared look for the panels inside the window.
function ns.MakePanel(parent, inset)
    local f = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    f:SetBackdrop({
        bgFile   = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 12,
        insets = { left = 3, right = 3, top = 3, bottom = 3 },
    })
    f:SetBackdropColor(0, 0, 0, inset and 0.45 or 0.25)
    f:SetBackdropBorderColor(0.35, 0.30, 0.22, 1)
    return f
end

local function savePosition(frame)
    local point, _, _, x, y = frame:GetPoint()
    local db = ns.addon and ns.addon.db
    if db then
        db.profile.position = { point = point, x = x, y = y }
    end
end

local function restorePosition(frame)
    local pos = ns.addon and ns.addon.db and ns.addon.db.profile.position
    frame:ClearAllPoints()
    if pos and pos.point then
        frame:SetPoint(pos.point, UIParent, pos.point, pos.x, pos.y)
    else
        frame:SetPoint("CENTER")
    end
end

function Window:Create()
    if self.frame then return self.frame end

    local f = CreateFrame("Frame", "SilvertongueFrame", UIParent, "BackdropTemplate")
    f:SetSize(WIDTH, HEIGHT)
    f:SetFrameStrata("DIALOG")
    f:SetBackdrop({
        bgFile   = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true, tileSize = 32, edgeSize = 32,
        insets = { left = 11, right = 12, top = 12, bottom = 11 },
    })
    f:SetMovable(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        savePosition(self)
    end)
    f:SetClampedToScreen(true)
    f:Hide()

    -- Closes with Escape.
    tinsert(UISpecialFrames, "SilvertongueFrame")

    local playerName = UnitName("player") or "SILVERTONGUE"
    local raceName = UnitRace("player")
    local className = UnitClass("player")

    local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", 0, -16)
    title:SetText(playerName:upper())
    title:SetTextColor(0.85, 0.35, 0.25)

    local subtitle = f:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    subtitle:SetPoint("TOP", title, "BOTTOM", 0, -2)
    subtitle:SetText(((raceName or "") .. " " .. (className or "")):gsub("^%s+", ""))

    local close = CreateFrame("Button", nil, f, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", -6, -6)

    local config = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    config:SetSize(48, 18)
    config:SetPoint("TOPLEFT", 14, -16)
    config:SetText("Edit")
    config:GetFontString():SetFontObject("GameFontDisableSmall")
    config:SetScript("OnClick", function() ns.Config:Toggle() end)
    config:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText("Phrase library")
        GameTooltip:AddLine("Browse, add and drop lines. Also /silvertongue config.", 1, 1, 1, true)
        GameTooltip:Show()
    end)
    config:SetScript("OnLeave", function() GameTooltip:Hide() end)

    -- Tab strip, sized to however many tabs this character has.
    ns.TABS = ns.BuildTabs()
    f.tabs = {}
    local tabWidth = (WIDTH - 20) / #ns.TABS
    for i, tab in ipairs(ns.TABS) do
        local b = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
        b:SetSize(tabWidth - 2, 22)
        b:SetPoint("TOPLEFT", 10 + (i - 1) * tabWidth, -52)
        b:SetText(tab.label)
        b:GetFontString():SetFontObject("GameFontHighlightSmall")
        b.key = tab.key
        b:SetScript("OnClick", function(self) ns.Tabs:Select(self.key) end)
        f.tabs[tab.key] = b
    end

    -- Content area. Each tab renders into this.
    local content = ns.MakePanel(f, true)
    content:SetPoint("TOPLEFT", 16, -78)
    content:SetPoint("TOPRIGHT", -16, -78)
    content:SetHeight(240)
    f.content = content

    ns.Preview:Create(f)

    restorePosition(f)
    self.frame = f
    return f
end

function Window:IsShown()
    return self.frame and self.frame:IsShown()
end

function Window:Show(tabKey)
    local f = self:Create()
    f:Show()
    ns.Tabs:Select(tabKey or (ns.addon.db.profile.lastTab or "GENERAL"))
end

function Window:Hide()
    if self.frame then self.frame:Hide() end
end

function Window:Toggle(tabKey)
    if self:IsShown() and not tabKey then
        self:Hide()
    else
        self:Show(tabKey)
    end
end
