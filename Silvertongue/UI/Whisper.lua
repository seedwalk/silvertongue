-- Whisper.lua -- one small window per person you are talking to.
--
-- Everywhere else in the addon the subject is a frame the game already draws:
-- your portrait, your target, a party member, a row of the group browser. A
-- person who whispers you is none of those. They are text in a chat window that
-- scrolls away, and once it has scrolled there is nothing left to click.
--
-- So this window IS the subject. It persists, several can be open at once, and
-- it is what the chat icon and the target's "open a window" both lead to.
--
-- It deliberately does NOT show the conversation. Reading the thread is what
-- the chat frame is for and it already does it well; duplicating it here would
-- mean owning your chat, and owning your chat is a different addon. What it
-- shows is the last thing they said, which is all you need to know what you are
-- answering.
--
-- The close button is the one exception to the rule that nothing in Silvertongue
-- has an X. Everything else behaves like a context menu and closes when you
-- click away -- this is meant to stay open while you do other things, so
-- clicking away must not touch it, and something has to dismiss it.

local ADDON, ns = ...

local Whisper = {}
ns.Whisper = Whisper

local WIDTH      = 208
local PAD        = 10
local ICON       = 18
local CASCADE    = 26       -- each new window sits down and right of the last

-- Blizzard's own mark for a whisper conversation window: FloatingChatFrame.lua
-- puts this on the tab when the game opens one. Using anything else for the
-- same idea would be inventing a symbol next to an existing one.
local WHISPER_ICON = "Interface\\ChatFrame\\UI-ChatWhisperIcon"
local GOSSIP_ICON  = "Interface\\GossipFrame\\GossipGossipIcon"
local INVITE_ICON  = "Interface\\FriendsFrame\\TravelPass-Invite"
local TRADE_ICON   = "Interface\\Icons\\INV_Misc_Coin_01"

local windows = {}
local openCount = 0

-- ---------------------------------------------------------------------------
-- Who they are, as far as the game is willing to say.
--
-- Of a stranger's whisper we get a name and nothing else. Everything below is
-- an attempt to turn that name into something, and every one of them can fail,
-- which is why the header is built to read correctly with only a name in it.
-- ---------------------------------------------------------------------------

local whoCache = {}          -- name -> { className, raceName, level }
local whoAsked = {}          -- name -> true, so one lookup per name per session

local function fromUnit(unit, name)
    if not UnitExists(unit) then return nil end
    if UnitName(unit) ~= name then return nil end
    local className = UnitClass(unit)
    local raceName  = UnitRace(unit)
    return {
        className = className,
        raceName  = raceName,
        level     = UnitLevel and UnitLevel(unit) or nil,
    }
end

-- The guild roster knows level and class but not race -- GetGuildRosterInfo
-- simply does not return one. A guildmate therefore shows as "Shaman, 41"
-- rather than "Orc Shaman, 41", and that is the truth rather than a gap.
local function fromGuild(name)
    if not IsInGuild or not IsInGuild() then return nil end
    if not GetNumGuildMembers or not GetGuildRosterInfo then return nil end
    for i = 1, (GetNumGuildMembers() or 0) do
        local member, _, _, level, class = GetGuildRosterInfo(i)
        if member == name then
            return { className = class, level = level }
        end
    end
    return nil
end

function ns.IdentifyPlayer(name)
    if not name then return nil end

    local units = { "target", "mouseover" }
    for _, candidate in ipairs(ns.GroupUnits and ns.GroupUnits() or {}) do
        units[#units + 1] = candidate
    end
    for _, unit in ipairs(units) do
        local info = fromUnit(unit, name)
        if info then return info end
    end

    return whoCache[name] or fromGuild(name)
end

-- One /who per name per session. The server throttles these hard: asking on
-- every window would get the later ones answered with nothing, so a name is
-- asked about once and the answer kept.
function ns.AskWho(name)
    if not name or whoAsked[name] or whoCache[name] then return end
    if not C_FriendList or not C_FriendList.SendWho then return end
    whoAsked[name] = true
    -- The exact-name tag. Without it the server pattern-matches and answers
    -- with everyone whose name merely starts this way.
    C_FriendList.SendWho("n-\"" .. name .. "\"", Enum and Enum.SocialWhoOrigin
        and Enum.SocialWhoOrigin.Chat or nil)
end

function ns.ReadWhoResults()
    if not C_FriendList or not C_FriendList.GetNumWhoResults then return end
    local count = C_FriendList.GetNumWhoResults() or 0
    for i = 1, count do
        local info = C_FriendList.GetWhoInfo(i)
        if info and info.fullName then
            whoCache[info.fullName] = {
                className = info.classStr,
                raceName  = info.raceStr,
                level     = info.level,
            }
            local window = windows[info.fullName]
            if window then Whisper:RefreshHeader(window) end
        end
    end
end

-- "Orc Shaman, 41" from whatever parts turned up, and nothing at all when none
-- did. Half a description is better than a line of placeholders.
local function describe(info)
    if not info then return nil end
    local who = ((info.raceName or "") .. " " .. (info.className or "")):gsub("^%s+", "")
    if who == "" then
        return info.level and ("Level " .. info.level) or nil
    end
    if info.level then return who .. ", " .. info.level end
    return who
end

-- ---------------------------------------------------------------------------
-- The window
-- ---------------------------------------------------------------------------

local function iconButton(parent, texture, size)
    local button = CreateFrame("Button", nil, parent)
    button:SetSize(size, size)

    local icon = button:CreateTexture(nil, "ARTWORK")
    icon:SetAllPoints()
    icon:SetTexture(texture)
    icon:SetAlpha(0.85)
    button.icon = icon

    button:SetScript("OnEnter", function(self)
        icon:SetAlpha(1)
        if not self.tipTitle then return end
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(self.tipTitle)
        if self.tipBody then GameTooltip:AddLine(self.tipBody, 1, 1, 1, true) end
        GameTooltip:Show()
    end)
    button:SetScript("OnLeave", function()
        icon:SetAlpha(0.85)
        GameTooltip:Hide()
    end)
    return button
end

function Whisper:Build(name)
    local frame = CreateFrame("Frame", "SilvertongueWhisper" .. openCount,
        UIParent, "BackdropTemplate")
    frame:SetWidth(WIDTH)
    frame:SetHeight(96)
    frame:SetFrameStrata("DIALOG")
    frame:SetToplevel(true)
    frame:SetBackdrop({
        bgFile   = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 14,
        insets = { left = 4, right = 4, top = 4, bottom = 4 },
    })
    frame:SetBackdropColor(0, 0, 0, 0.92)
    frame:EnableMouse(true)
    frame:SetMovable(true)
    frame:SetClampedToScreen(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", function(self) self:StartMoving() end)
    frame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        Whisper:RememberPosition(self)
    end)

    local mark = frame:CreateTexture(nil, "ARTWORK")
    mark:SetSize(16, 16)
    mark:SetPoint("TOPLEFT", PAD, -PAD)
    mark:SetTexture(WHISPER_ICON)

    frame.title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    frame.title:SetPoint("LEFT", mark, "RIGHT", 5, 0)
    frame.title:SetJustifyH("LEFT")

    frame.subtitle = frame:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    frame.subtitle:SetPoint("TOPLEFT", PAD, -PAD - 17)
    frame.subtitle:SetJustifyH("LEFT")

    -- The last thing they said. One line, clipped: this is a reminder of what
    -- you are answering, not a transcript.
    frame.said = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    frame.said:SetPoint("TOPLEFT", PAD, -PAD - 34)
    frame.said:SetWidth(WIDTH - PAD * 2)
    frame.said:SetJustifyH("LEFT")
    frame.said:SetHeight(26)

    local close = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    close:SetSize(24, 24)
    close:SetPoint("TOPRIGHT", 2, 2)
    close:SetScript("OnClick", function() Whisper:Close(name) end)

    -- The three that act. Speak is ours and always works; the other two are the
    -- game's and are switched off when the game would refuse them.
    frame.speak = iconButton(frame, GOSSIP_ICON, ICON)
    frame.speak:SetPoint("BOTTOMLEFT", PAD, PAD)
    frame.speak.tipTitle = "Say something"
    frame.speak.tipBody = "Answer them in character. Nothing is sent until you press the channel."
    frame.speak:SetScript("OnClick", function(self)
        ns.Board:New("WHISPER:" .. name):Toggle(self, ns.Contexts:Whisper(name))
    end)

    frame.invite = iconButton(frame, INVITE_ICON, ICON)
    frame.invite:SetPoint("LEFT", frame.speak, "RIGHT", 6, 0)
    -- One image holding all four button states side by side, so the normal one
    -- has to be cut out of it. The coordinates are Blizzard's own, from
    -- FriendsFrame.xml.
    frame.invite.icon:SetTexCoord(0.015625, 0.390625, 0.2734375, 0.5234375)
    frame.invite.tipTitle = "Invite them"
    frame.invite.tipBody = "Invites " .. name .. " to your group. They still have to accept."
    frame.invite:SetScript("OnClick", function()
        if InviteToGroup then InviteToGroup(name)
        elseif InviteUnit then InviteUnit(name) end
    end)

    frame.trade = iconButton(frame, TRADE_ICON, ICON)
    frame.trade:SetPoint("LEFT", frame.invite, "RIGHT", 6, 0)
    frame.trade.tipTitle = "Trade"
    frame.trade.tipBody = "Only works while they are standing next to you and selected."
    frame.trade:SetScript("OnClick", function()
        if UnitExists("target") and UnitName("target") == name and InitiateTrade then
            InitiateTrade("target")
        end
    end)

    frame.name = name
    return frame
end

-- Where a new window lands. The first sits where you last dragged one; the rest
-- cascade off it, because three windows stacked exactly on top of each other
-- look like one window.
function Whisper:PlaceNew(frame, index)
    local saved = ns.addon and ns.addon.db and ns.addon.db.profile.whisperAnchor
    local step = ((index - 1) % 6) * CASCADE
    frame:ClearAllPoints()
    if saved and saved.point then
        frame:SetPoint(saved.point, UIParent, saved.point,
            (saved.x or 0) + step, (saved.y or 0) - step)
    else
        frame:SetPoint("CENTER", UIParent, "CENTER", -180 + step, 40 - step)
    end
end

function Whisper:RememberPosition(frame)
    local db = ns.addon and ns.addon.db
    if not db then return end
    local point, _, _, x, y = frame:GetPoint()
    if not point then return end
    db.profile.whisperAnchor = { point = point, x = x or 0, y = y or 0 }
end

function Whisper:RefreshHeader(frame)
    frame.title:SetText(frame.name)
    frame.subtitle:SetText(describe(ns.IdentifyPlayer(frame.name)) or "")
end

function Whisper:Open(name, said)
    if not name or name == "" then return nil end

    local frame = windows[name]
    if not frame then
        openCount = openCount + 1
        frame = self:Build(name)
        windows[name] = frame
        self:PlaceNew(frame, openCount)
        ns.AskWho(name)
    end

    self:RefreshHeader(frame)
    if said then frame.said:SetText("\"" .. said .. "\"") end
    frame:Show()
    self:UpdateActions(frame)
    return frame
end

-- A button that cannot do anything must not look like it can. Trade needs them
-- selected and beside you, which in a whisper is the exception rather than the
-- rule; invite is off once they are already with you.
function Whisper:UpdateActions(frame)
    local targeted = UnitExists("target") and UnitName("target") == frame.name
    frame.trade:SetEnabled(targeted and true or false)
    frame.trade.icon:SetAlpha(targeted and 0.85 or 0.3)

    local already = false
    for _, unit in ipairs(ns.GroupUnits and ns.GroupUnits() or {}) do
        if UnitName(unit) == frame.name then already = true end
    end
    frame.invite:SetEnabled(not already)
    frame.invite.icon:SetAlpha(already and 0.3 or 0.85)
end

function Whisper:RefreshAll()
    for _, frame in pairs(windows) do
        if frame:IsShown() then self:UpdateActions(frame) end
    end
end

-- A whisper from someone whose window is open updates it rather than opening
-- anything. Windows do not open themselves: a window appearing over the game
-- because somebody typed at you is the behaviour we refused for the target
-- board, and it is worse here because it takes a corner of the screen.
function Whisper:Heard(name, message)
    local frame = windows[name]
    if not frame or not frame:IsShown() then return false end
    frame.said:SetText("\"" .. message .. "\"")
    self:RefreshHeader(frame)
    return true
end

function Whisper:Close(name)
    local frame = windows[name]
    if not frame then return end
    frame:Hide()
    local board = ns.Board and ns.Board:New("WHISPER:" .. name)
    if board then board:Close() end
end

function Whisper:IsOpen(name)
    local frame = windows[name]
    return frame ~= nil and frame:IsShown()
end

function Whisper:Windows()
    return windows
end
