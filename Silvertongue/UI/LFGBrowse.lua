-- LFGBrowse.lua -- a bubble on every row of the group browser.
--
-- The listing is readable: C_LFGList's getters are unrestricted in this client,
-- so the leader's name, level, class, what they are running and what they are
-- short of all come straight from the game. What we add is the words.
--
-- Rows are recycled frames from a ScrollBox with no global names, so they are
-- reached through the scroll callbacks rather than by guessing at frame names.
-- Starting a search is restricted, so nothing here searches: it reads whatever
-- your own refresh brought back.

local ADDON, ns = ...

local LFGBrowse = {}
ns.LFGBrowse = LFGBrowse

local BROWSER_ADDON = "Blizzard_GroupFinder_VanillaStyle"

local function listingBoard() return ns.Board:New("Listing") end

local ROLE_INTENT = { TANK = "OFFER_TANK", HEALER = "OFFER_HEALER", DAMAGER = "OFFER_DPS" }
local ROLE_LABEL  = { TANK = "Offer to tank", HEALER = "Offer to heal", DAMAGER = "Offer damage" }

local function canFill(role) return ns.CanFillRole(role) end

-- Everything the game will tell us about one row.
function LFGBrowse:ReadResult(resultID)
    if not resultID or not C_LFGList then return nil end
    if C_LFGList.HasSearchResultInfo and not C_LFGList.HasSearchResultInfo(resultID) then
        return nil
    end

    local info = C_LFGList.GetSearchResultInfo and C_LFGList.GetSearchResultInfo(resultID)
    if not info or not info.leaderName then return nil end

    local player = C_LFGList.GetSearchResultPlayerInfo
        and C_LFGList.GetSearchResultPlayerInfo(resultID, 1)
    local counts = C_LFGList.GetSearchResultMemberCounts
        and C_LFGList.GetSearchResultMemberCounts(resultID)

    -- What they are running. A listing can carry several, so the first is the
    -- one worth naming.
    local activity
    local firstID = info.activityIDs and info.activityIDs[1]
    if firstID and C_LFGList.GetActivityInfoTable then
        local table_ = C_LFGList.GetActivityInfoTable(firstID)
        activity = table_ and (table_.fullName or table_.shortName)
    end

    -- What they are short of, as the game reports it rather than as a guess.
    local missing, openRoles = {}, {}
    if counts then
        if (counts.TANK_REMAINING or 0) > 0 then
            missing[#missing + 1] = "a tank"
            openRoles[#openRoles + 1] = "TANK"
        end
        if (counts.HEALER_REMAINING or 0) > 0 then
            missing[#missing + 1] = "a healer"
            openRoles[#openRoles + 1] = "HEALER"
        end
        local dps = counts.DAMAGER_REMAINING or 0
        if dps > 0 then
            missing[#missing + 1] = dps .. " dps"
            openRoles[#openRoles + 1] = "DAMAGER"
        end
    end

    return {
        resultID   = resultID,
        leaderName = info.leaderName,
        hasSelf    = info.hasSelf and true or false,
        members    = info.numMembers or 1,
        comment    = info.comment,
        activity   = activity,
        level      = player and player.level,
        className  = player and player.className,
        classToken = player and player.classFilename,
        missing    = (#missing > 0) and table.concat(missing, ", ") or nil,
        openRoles  = openRoles,

        -- Said in a sentence rather than as a list, for the advert itself.
        holds      = counts and ns.DescribeRoles(counts.TANK, counts.HEALER, counts.DAMAGER) or nil,
        short      = counts and ns.DescribeRoles(counts.TANK_REMAINING,
                        counts.HEALER_REMAINING, counts.DAMAGER_REMAINING) or nil,
    }
end

-- Blizzard's own rule for whether the invite is on: only a lone player can be
-- invited, and only if you are in a position to invite anyone.
local function canInvite(result)
    if result.members ~= 1 then return false end
    if not IsInGroup() then return true end
    return (UnitIsGroupLeader and UnitIsGroupLeader("player"))
        or (UnitIsGroupAssistant and UnitIsGroupAssistant("player"))
        or false
end

-- Your own listing.
--
-- Two things are true at once and an earlier version of this picked one. Your
-- listing is the group you are forming, so asking for what it is short of
-- belongs here -- and while you are still the only one in it, you are also a
-- person offering himself, which is the half that was missing entirely.
--
-- So both are offered. What changes with the size is only the order: alone, the
-- advert about you comes first; once somebody has joined, recruiting does.
function LFGBrowse:BuildOwnListingContext(result)
    local ctx = ns.Engine:BuildPlayerContext()
    ctx.dungeon = result.activity or ns.CurrentDungeon()
    ctx.have    = result.holds or "no one yet"
    ctx.missing = result.short or "more"
    ctx.needs   = math.max(0, 5 - (result.members or 1))

    local alone = (result.members or 1) <= 1

    -- Offering yourself: the plain advert, then the roles your class could
    -- actually take. The role is the first thing a group leader reads for.
    local function advertiseSelf(list)
        list[#list + 1] = { "LFG", "SOLO", "Looking for a group" }
        local ROLE_SOLO = {
            { "TANK",    "SOLO_TANK",   "Looking, as a tank"   },
            { "HEALER",  "SOLO_HEALER", "Looking, as a healer" },
            { "DAMAGER", "SOLO_DPS",    "Looking, as damage"   },
        }
        for _, role in ipairs(ROLE_SOLO) do
            if ns.CanFillRole(role[1]) then
                list[#list + 1] = { "LFG", role[2], role[3] }
            end
        end
    end

    -- Recruiting: everything at once, then the roles the game says are still
    -- open. Asking for a healer you already have is how a listing gets ignored.
    local function recruit(list)
        -- Alone, the lines that recite what the group holds read as a roster of
        -- yourself: "need a tank, we have 1 dps" is one person describing
        -- himself in the plural. The solo pools ask for the role and stop.
        local suffix = alone and "_SOLO" or ""
        if result.short then
            list[#list + 1] = { "LFG", "NEED_MORE" .. suffix, "Fill the group" }
        end
        local ROLE_NEED = {
            TANK    = { "NEED_TANK" .. suffix,   "Ask for a tank"   },
            HEALER  = { "NEED_HEALER" .. suffix, "Ask for a healer" },
            DAMAGER = { "NEED_DPS" .. suffix,    "Ask for damage"   },
        }
        for _, role in ipairs(result.openRoles or {}) do
            local need = ROLE_NEED[role]
            if need then list[#list + 1] = { "LFG", need[1], need[2] } end
        end
    end

    local intents = {}
    if alone then
        advertiseSelf(intents)
        if #intents > 0 then intents[#intents + 1] = ns.SEP end
        recruit(intents)
    else
        recruit(intents)
        if #intents > 0 then intents[#intents + 1] = ns.SEP end
        advertiseSelf(intents)
    end
    if intents[#intents] == ns.SEP then table.remove(intents) end

    local subtitle = result.activity or "Your listing"
    if result.short then subtitle = subtitle .. " - need " .. result.short end

    local channels = { { key = "LFG", label = "LFG",
                         hint = "Goes to the LookingForGroup channel, joining it if you have not." } }
    if IsInGuild and IsInGuild() then
        channels[#channels + 1] = { key = "GUILD", label = "Guild",
                                    hint = "Asks your guild first." }
    end
    channels[#channels + 1] = { key = "SAY", label = "Say",
                                hint = "Everyone nearby hears it." }

    return {
        key      = "LISTING:SELF",
        title    = "Your listing",
        subtitle = subtitle,
        intents  = intents,
        ctx      = ctx,
        channels = channels,
        -- Re-read when a line is picked. Leaving the menu open and changing the
        -- dungeon filter would otherwise keep naming the one it opened on.
        rebuild  = function()
            local fresh = LFGBrowse:ReadResult(result.resultID)
            if not fresh then return nil end
            local updated = LFGBrowse:BuildOwnListingContext(fresh)
            return updated and updated.ctx
        end,
    }
end

function LFGBrowse:BuildContext(resultID)
    local result = self:ReadResult(resultID)
    if not result then return nil end

    -- Your own listing is the one case where you are not trying to get in. The
    -- game marks it, so offering to join yourself never comes up.
    if result.hasSelf then
        return self:BuildOwnListingContext(result)
    end

    local ctx = ns.Engine:BuildPlayerContext()
    ctx.dungeon = result.activity or ns.CurrentDungeon()

    local subtitle = result.activity or "Looking for a group"
    if result.missing then subtitle = subtitle .. " - needs " .. result.missing end

    -- Offer for what they are actually short of. Asking what they need would be
    -- wasting their time: the listing already says, and so does the row above.
    local intents = { { "LFG", "OFFER", "Offer to join" } }
    for _, role in ipairs(result.openRoles or {}) do
        if canFill(role) then
            intents[#intents + 1] = { "LFG", ROLE_INTENT[role], ROLE_LABEL[role] }
        end
    end

    local actions
    if canInvite(result) then
        actions = { {
            label = "Invite them",
            tip = "Invites " .. result.leaderName .. " to your group.",
            run = function() if InviteToGroup then InviteToGroup(result.leaderName) end end,
        } }
    end

    return {
        key       = "LISTING:" .. tostring(resultID),
        title     = result.leaderName,
        subtitle  = subtitle,
        intents   = intents,
        ctx       = ctx,
        recipient = result.leaderName,
        channels  = { { key = "WHISPER", label = "Whisper",
                        hint = "Only " .. result.leaderName .. " reads it." } },
        actions   = actions,
        rebuild   = function()
            local fresh = LFGBrowse:ReadResult(resultID)
            if not fresh then return nil end
            local updated = ns.Engine:BuildPlayerContext()
            updated.dungeon = fresh.activity or ns.CurrentDungeon()
            return updated
        end,
    }
end

-- A real listing row, as the client builds them: LFGBrowseSearchEntryTemplate
-- carries all of these. The scroll box hands out other frames too, and hanging
-- a bubble on every one of them is how they ended up scattered over the window
-- in places that are not rows at all.
local function isResultRow(frame)
    return frame ~= nil
        and frame.Name ~= nil
        and frame.Level ~= nil
        and frame.ActivityName ~= nil
end

-- Every bubble we made, so the probe can say which of the things on screen are
-- ours and which belong to the game.
local attached = {}

-- The bubble itself, one per recycled row.
local function attach(row)
    if not isResultRow(row) then return end
    if not row.silvertongue then
        local button = CreateFrame("Button", nil, row)
        button:SetSize(14, 14)
        button:SetFrameLevel(row:GetFrameLevel() + 5)

        local icon = button:CreateTexture(nil, "OVERLAY")
        icon:SetAllPoints()
        icon:SetTexture("Interface\\GossipFrame\\GossipGossipIcon")
        icon:SetAlpha(0.8)

        button:SetScript("OnEnter", function(self)
            icon:SetAlpha(1)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetText("Speak to them")
            GameTooltip:AddLine("Offer to join, ask what they need, or invite them.", 1, 1, 1, true)
            GameTooltip:Show()
        end)
        button:SetScript("OnLeave", function()
            icon:SetAlpha(0.8)
            GameTooltip:Hide()
        end)
        button:SetScript("OnClick", function(self)
            -- Read from the row at click time. The scroll box recycles rows and
            -- rebinds their data after we attach, so anything cached here goes
            -- stale the moment the list scrolls.
            local id = self:GetParent() and self:GetParent().resultID
            local context = id and ns.LFGBrowse:BuildContext(id)
            if context then
                ns.PrepareLookingForGroup()
                listingBoard():Toggle(self, context)
            else
                ns.LFGBrowse:Explain(id)
            end
        end)

        -- Beside the name, which is who it acts on, and clear of the role
        -- icons the row keeps on its right.
        button:ClearAllPoints()
        if row.Name then
            button:SetPoint("LEFT", row.Name, "RIGHT", 4, 0)
        else
            button:SetPoint("LEFT", 4, 0)
        end

        row.silvertongue = button
        attached[#attached + 1] = button
    end

    row.silvertongue:Show()
end

function LFGBrowse:DescribeIcons()
    local lines = { "  row bubbles built: " .. #attached }
    for i, button in ipairs(attached) do
        local parent = button:GetParent()
        local name = parent and parent.Name and parent.Name.GetText and parent.Name:GetText()
        lines[#lines + 1] = "   " .. i .. ": on " .. tostring(name or "?")
            .. (button:IsShown() and " (shown)" or " (hidden)")
    end
    lines[#lines + 1] = "  header bubble: " .. (LFGBrowse.headerButton and "built" or "no")
    return lines
end

local function release(row)
    if row.silvertongue then row.silvertongue:Hide() end
end

-- When a row cannot be read, say which step failed rather than doing nothing.
-- Silence is the worst outcome: it looks like a dead button.
function LFGBrowse:Explain(resultID)
    if not ns.addon then return end
    if not resultID then
        ns.addon:Print("That row carries no listing id.")
    elseif not C_LFGList then
        ns.addon:Print("This client has no C_LFGList.")
    elseif not (C_LFGList.GetSearchResultInfo and C_LFGList.GetSearchResultInfo(resultID)) then
        ns.addon:Print("The game returned nothing for listing " .. tostring(resultID) .. ".")
    else
        ns.addon:Print("Listing " .. tostring(resultID) .. " has no leader name.")
    end
end

-- A bubble on the window itself, for advertising yourself or recruiting. This
-- lives here rather than on your portrait because it is only ever wanted while
-- you are looking at this window.
function LFGBrowse:AttachHeader(browse)
    if self.headerButton then return end

    local button = CreateFrame("Button", "SilvertongueLFGHeader", browse)
    button:SetSize(18, 18)
    button:SetFrameStrata("FULLSCREEN_DIALOG")

    local icon = button:CreateTexture(nil, "OVERLAY")
    icon:SetAllPoints()
    icon:SetTexture("Interface\\GossipFrame\\GossipGossipIcon")
    icon:SetAlpha(0.8)

    -- Beside the refresh button, which is the other thing you press here.
    -- Clear of the controls along that row: beside the refresh button it landed
    -- on top of the dungeon dropdown.
    button:ClearAllPoints()
    if _G.LFGBrowseFrameRefreshButton then
        button:SetPoint("TOP", _G.LFGBrowseFrameRefreshButton, "BOTTOM", 0, -4)
    else
        button:SetPoint("TOPRIGHT", browse, "TOPRIGHT", -14, -60)
    end

    button:SetScript("OnEnter", function(self)
        icon:SetAlpha(1)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText("Say you are looking")
        GameTooltip:AddLine("Advertise yourself, or recruit for the group you have.", 1, 1, 1, true)
        GameTooltip:Show()
    end)
    button:SetScript("OnLeave", function() icon:SetAlpha(0.8); GameTooltip:Hide() end)
    button:SetScript("OnClick", function(self)
        ns.PrepareLookingForGroup()
        ns.Board:New("Group"):Toggle(self, ns.Contexts:Group())
    end)

    self.headerButton = button
end

function LFGBrowse:Hook()
    if self.hooked then return end

    local browse = _G.LFGBrowseFrame
    if browse then self:AttachHeader(browse) end

    local scroll = browse and browse.ScrollBox
    if not scroll or not ScrollUtil or not ScrollUtil.AddAcquiredFrameCallback then
        return          -- a client that does not have this UI simply gets nothing
    end

    ScrollUtil.AddAcquiredFrameCallback(scroll, function(_, row) attach(row) end, self, true)
    ScrollUtil.AddReleasedFrameCallback(scroll, function(_, row) release(row) end, self)
    self.hooked = true
end

-- The browser is loaded on demand, so the hook waits for it.
function LFGBrowse:Watch()
    if self.hooked then return end
    self:Hook()
    if self.hooked then return end

    local loaded = (C_AddOns and C_AddOns.IsAddOnLoaded and C_AddOns.IsAddOnLoaded(BROWSER_ADDON))
        or (IsAddOnLoaded and IsAddOnLoaded(BROWSER_ADDON))
    if loaded then self:Hook() end
end

function LFGBrowse:OnAddonLoaded(name)
    if name == BROWSER_ADDON then self:Hook() end
end
