-- Core.lua -- addon object, slash commands, minimap launcher.

local ADDON, ns = ...

-- Reports which of the group-finder's frames and functions this client
-- actually has. None of the installed addons touch the LFG tool, so there was
-- no evidence to read: rather than guess at names and ship something that
-- silently does nothing, this asks the client directly.
function ns.Probe()
    ns.addon:Print("--- party frames ---")
    for _, line in ipairs(ns.Anchors:DescribeParty()) do ns.addon:Print(line) end
    ns.addon:Print("  in a group: " .. tostring(IsInGroup()) .. ", in a raid: " .. tostring(IsInRaid()))
    ns.addon:Print("  controls on: " .. tostring(ns.addon.db.profile.anchorsEnabled))
    for i = 1, 4 do
        local control = _G["SilvertongueAnchorPARTY" .. i]
        ns.addon:Print("  control " .. i .. ": "
            .. (control and (control:IsShown() and "shown" or "hidden") or "never built"))
    end
    local hooked, count = ns.ChatLinks:IsHooked()
    ns.addon:Print("--- chat ---")
    ns.addon:Print("  frames wrapped: " .. tostring(hooked) .. " (" .. count .. ")")

    ns.addon:Print("--- conversations kept ---")
    local kept, lines = 0, 0
    for key, entries in pairs(ns.addon.db.profile.log or {}) do
        kept = kept + 1
        lines = lines + #entries
        if kept <= 8 then
            ns.addon:Print("  " .. key .. ": " .. #entries .. " lines")
        end
    end
    ns.addon:Print("  " .. kept .. " conversations, " .. lines .. " lines in total")

    ns.addon:Print("--- group browser bubbles ---")
    for _, line in ipairs(ns.LFGBrowse:DescribeIcons()) do ns.addon:Print(line) end

    ns.ProbeLFG()
end

-- Joining the LookingForGroup channel has now failed twice for two different
-- reasons I inferred rather than measured. This measures: which of the calls
-- exist, what the channel id is before and after, what the join returned, and
-- what the client thinks you are in.
-- The LookingForGroup question is answered, and the two probes that answered it
-- are gone: one of them wrote a test line into a public channel, which is not
-- something to leave a typo away from.
--
-- What they found, because it cost three wrong fixes to learn: being in a
-- channel and having a window that shows it are different things, and the gap
-- between them is invisible from the outside. The send had been working the
-- whole time.

function ns.ProbeLFG()
    local CANDIDATES = {
        "LFGBrowseFrame", "LFGBrowseFrameButton1", "LFGBrowseSearchEntry1",
        "LFGParentFrame", "LFGFrame", "LookingForGroupFrame", "LFGListFrame",
        "LFGBrowseFrameScrollFrame", "LFGBrowseFrameColumnHeader1",
        "SocialBrowseFrame", "GroupFinderFrame", "PVEFrame",
        "LFGListSearchPanel", "LFGListFrame",
    }
    local FUNCTIONS = {
        "LFGBrowseSearchEntry_OnClick", "SearchLFGGetResults", "SearchLFGGetNumResults",
        "GetLFGRoles", "SetLFGRoles", "SendWho", "C_LFGList", "GetNumLFGResults",
        "LFGBrowseFrame_UpdateResults",
    }

    ns.addon:Print("--- frames ---")
    for _, name in ipairs(CANDIDATES) do
        local frame = _G[name]
        if frame then
            local kind = type(frame)
            if kind == "table" and frame.GetObjectType then
                kind = frame:GetObjectType()
            end
            ns.addon:Print("  " .. name .. " = " .. kind)
        end
    end

    ns.addon:Print("--- functions ---")
    for _, name in ipairs(FUNCTIONS) do
        if _G[name] then ns.addon:Print("  " .. name .. " = " .. type(_G[name])) end
    end

    -- The LookingForGroup channel, if joined.
    local id = GetChannelName and GetChannelName("LookingForGroup")
    ns.addon:Print("--- LookingForGroup channel id: " .. tostring(id) .. " (0 means not joined)")

    -- Anything global whose name mentions the group finder, so a name nobody
    -- guessed still turns up.
    ns.addon:Print("--- other globals mentioning LFG ---")
    local found = 0
    for name, value in pairs(_G) do
        if type(name) == "string" and found < 25
           and (name:find("^LFG") or name:find("^LookingForGroup")) then
            found = found + 1
            ns.addon:Print("  " .. name)
        end
    end
    ns.addon:Print("--- end of probe ---")
end

-- One key binding: open and close the panel, under its own heading in
-- Esc -> Key Bindings. This client's binding UI reads the XML `category`
-- attribute as a full global name and looks up BINDING_ plus the rest, so the
-- category there is "BINDING_HEADER_SILVERTONGUE" and the global is this one. The
-- `header` attribute is not honoured and renders as raw text instead.
BINDING_HEADER_SILVERTONGUE      = "Silvertongue"
BINDING_NAME_SILVERTONGUE_TOGGLE = "Silvertongue: open/close"

function Silvertongue_BindingToggle()
    ns.Config:Toggle()
end

local Silvertongue = LibStub("AceAddon-3.0"):NewAddon(ADDON, "AceEvent-3.0", "AceConsole-3.0")
ns.addon = Silvertongue

local ldb = LibStub("LibDataBroker-1.1", true)
local icon = LibStub("LibDBIcon-1.0", true)

-- The rallying cry and the hold-on button both depend on who you are playing.
local FACTION_CRY = { HORDE = "FOR_THE_HORDE", ALLIANCE = "FOR_THE_ALLIANCE" }

-- Right-click shortcuts. These fill the preview and open the window.
-- They never send anything on their own. An entry either names its pool, or
-- resolves one from the character at click time.
local QUICK = {
    {
        label = "Battle cry", tab = "FACTION",
        resolve = function()
            local faction = ns.Engine:GetPlayerFaction()
            return faction, faction and FACTION_CRY[faction] or nil
        end,
    },
    { label = "Thanks",   category = "GENERAL", intent = "THANKS",   tab = "GENERAL" },
    { label = "Ready",    category = "PARTY",   intent = "READY",    tab = "PARTY"   },
    { label = "Wait",     category = "PARTY",   intent = "WAIT",     tab = "PARTY"   },
    {
        label = "Hold on", tab = "PARTY",
        resolve = function()
            -- A rogue scouts ahead where everyone else drinks.
            return "PARTY", (ns.Engine:GetPlayerClass() == "ROGUE") and "SCOUT" or "MANA"
        end,
    },
    { label = "Good Job", category = "PARTY",   intent = "GOOD_JOB", tab = "PARTY"   },
    { label = "Edit phrases...", config = true },
}

local TAB_ARGS = {
    general  = "GENERAL",
    party    = "PARTY",
    target   = "TARGET",
    horde    = "FACTION",
    alliance = "FACTION",
    faction  = "FACTION",
    shaman   = "CLASS",
    rogue    = "CLASS",
    class    = "CLASS",
    attitude = "ATTITUDE",
}

function Silvertongue:OnInitialize()
    self.db = LibStub("AceDB-3.0"):New("SilvertongueDB", ns.defaults, true)
    ns.Engine:MigrateCustom(self.db)

    self:RegisterChatCommand("silvertongue", "HandleSlash")
    self:RegisterChatCommand("silver", "HandleSlash")

    if ldb then
        self.launcher = ldb:NewDataObject(ADDON, {
            type = "launcher",
            text = "Silvertongue",
            icon = "Interface\\Icons\\Spell_Nature_GroundingTotem",
            OnClick = function(_, button)
                if button == "RightButton" then
                    Silvertongue:ShowQuickMenu()
                else
                    ns.Config:Toggle()
                end
            end,
            OnTooltipShow = function(tooltip)
                tooltip:AddLine("Silvertongue")
                tooltip:AddLine("Left-click: open Silvertongue.", 1, 1, 1)
                tooltip:AddLine("Right-click: quick actions.", 1, 1, 1)
            end,
        })
        if icon then
            icon:Register(ADDON, self.launcher, self.db.profile.minimap)
        end
    end
end

function Silvertongue:OnEnable()
    self:RegisterEvent("GROUP_ROSTER_UPDATE", function()
        ns.PartyUI:Refresh()
        ns.Anchors:UpdateParty()
        ns.Whisper:RefreshAll()
    end)
    self:RegisterEvent("PLAYER_TARGET_CHANGED", function()
        ns.TargetUI:Refresh()
        ns.Anchors:UpdateTarget()
        ns.Whisper:RefreshAll()
    end)
    self:RegisterEvent("PLAYER_ENTERING_WORLD", function()
        ns.Anchors:Refresh()
        ns.LFGBrowse:Watch()
    end)
    -- The group browser is loaded on demand, so the row bubbles wait for it.
    self:RegisterEvent("ADDON_LOADED", function(_, name) ns.LFGBrowse:OnAddonLoaded(name) end)
    self:RegisterEvent("LFG_LIST_SEARCH_RESULTS_RECEIVED", function() ns.LFGBrowse:Watch() end)
    -- Whose turn it is to be reachable changes with your selection and your
    -- group, and the window's invite and trade buttons say so.
    -- The conversation is recorded from the events rather than from the chat
    -- filters: a whisper counts as said whether or not it reached a chat frame
    -- you happen to be watching.
    -- Argument twelve of a chat event is the sender's GUID, which is where the
    -- race comes from. Nothing else in the game will tell us the race of
    -- somebody on another realm.
    self:RegisterEvent("CHAT_MSG_WHISPER", function(_, message, author, ...)
        ns.LearnFromGUID(author, select(10, ...))
        ns.Whisper:Heard(author, message, true)
    end)
    -- Guild chat is listened to only to learn who people are: a guildmate who
    -- has said anything is then known by race as well as by rank.
    self:RegisterEvent("CHAT_MSG_GUILD", function(_, _, author, ...)
        ns.LearnFromGUID(author, select(10, ...))
    end)
    self:RegisterEvent("CHAT_MSG_WHISPER_INFORM", function(_, message, to)
        ns.Whisper:Heard(to, message, false)
    end)
    -- On Battle.net the conversation belongs to the account, which arrives as
    -- the thirteenth argument, the same one the game's own chat code reads.
    self:RegisterEvent("CHAT_MSG_BN_WHISPER", function(_, message, author, ...)
        ns.Whisper:Heard(author, message, true, select(11, ...))
    end)
    self:RegisterEvent("CHAT_MSG_BN_WHISPER_INFORM", function(_, message, to, ...)
        ns.Whisper:Heard(to, message, false, select(11, ...))
    end)

    ns.Log:Prune()
    ns.ChatLinks:Register()
    ns.Anchors:Refresh()
end

function Silvertongue:HandleSlash(input)
    local arg = (input or ""):lower():match("^%s*(%S*)")
    if arg == "" then
        ns.Config:Toggle()
    elseif arg == "panel" then
        ns.Window:Toggle()
    elseif arg == "anchors" then
        ns.Anchors:SetEnabled(not self.db.profile.anchorsEnabled)
        self:Print(self.db.profile.anchorsEnabled
            and "Frame controls shown. Right-click and drag to move them."
            or "Frame controls hidden.")
    elseif arg == "probe" or arg == "lfgprobe" then
        ns.Probe()
    elseif arg == "chatdebug" then
        ns.ChatLinks:Debug(12)
    elseif arg == "config" or arg == "phrases" or arg == "library" then
        ns.Config:Toggle()
    elseif TAB_ARGS[arg] then
        ns.Window:Show(TAB_ARGS[arg])
    elseif arg == "minimap" then
        local hidden = not self.db.profile.minimap.hide
        self.db.profile.minimap.hide = hidden
        if icon then
            if hidden then icon:Hide(ADDON) else icon:Show(ADDON) end
        end
        self:Print(hidden and "Minimap button hidden." or "Minimap button shown.")
    else
        self:Print("Usage: /silvertongue [panel|anchors|general|party|target|faction|class|attitude|minimap|probe|chatdebug]")
    end
end

-- A plain frame menu, so quick actions behave exactly like the panel buttons.
function Silvertongue:ShowQuickMenu()
    if not self.quickMenu then
        local menu = ns.MakePanel(UIParent)
        menu:EnableMouse(true)
        menu:SetFrameStrata("FULLSCREEN_DIALOG")
        menu:SetSize(130, #QUICK * 18 + 8)
        menu:Hide()

        for i, entry in ipairs(QUICK) do
            local item = CreateFrame("Button", nil, menu)
            item:SetSize(122, 18)
            item:SetPoint("TOPLEFT", 4, -4 - (i - 1) * 18)
            item:SetNormalFontObject("GameFontHighlightSmall")
            item:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight")
            item:SetText(entry.label)
            item:GetFontString():SetPoint("LEFT", 4, 0)
            item:SetScript("OnClick", function()
                menu:Hide()
                if entry.config then
                    ns.Config:Toggle()
                    return
                end
                ns.Window:Show(entry.tab)

                local category, intent = entry.category, entry.intent
                if entry.resolve then category, intent = entry.resolve() end
                if not category or not intent then return end

                ns.Preview:SetRecipient(nil)
                ns.Preview:RequestOrReroll(category, intent, nil)
            end)
        end

        menu:SetScript("OnLeave", function(self)
            if not self:IsMouseOver() then self:Hide() end
        end)
        self.quickMenu = menu
    end

    local menu = self.quickMenu
    menu:ClearAllPoints()
    menu:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    if Minimap then
        menu:ClearAllPoints()
        menu:SetPoint("TOPRIGHT", Minimap, "BOTTOMLEFT", 0, 0)
    end
    menu:SetShown(not menu:IsShown())
end
