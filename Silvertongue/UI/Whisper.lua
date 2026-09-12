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

local WIDTH      = 260
local PAD        = 10
local ICON       = 18
local CASCADE    = 26       -- each new window sits down and right of the last
local HEAD_H     = 52       -- name and who they are
local LOG_H      = 118      -- the conversation, when it is showing
local INPUT_H    = 20

-- Blizzard's own mark for a whisper conversation window: FloatingChatFrame.lua
-- puts this on the tab when the game opens one. Using anything else for the
-- same idea would be inventing a symbol next to an existing one.
local WHISPER_ICON = "Interface\\ChatFrame\\UI-ChatWhisperIcon"
local GOSSIP_ICON  = "Interface\\GossipFrame\\GossipGossipIcon"
local INVITE_ICON  = "Interface\\FriendsFrame\\TravelPass-Invite"
local TRADE_ICON   = "Interface\\Icons\\INV_Misc_Coin_01"

local windows = {}
local openCount = 0

-- How much of a long conversation the window holds at once. The rest is still
-- on disk; this is what it costs to have it on screen.
local Log_MAX_SHOWN = 300

-- ---------------------------------------------------------------------------
-- Who they are, as far as the game is willing to say.
--
-- Of a stranger's whisper we get a name and nothing else. Everything below is
-- an attempt to turn that name into something, and every one of them can fail,
-- which is why the header is built to read correctly with only a name in it.
-- ---------------------------------------------------------------------------

-- What we have ever learned about somebody, kept across sessions. Once you have
-- met Rhottyn you have met him: the window opens knowing he is a troll shaman
-- rather than asking the server again and showing nothing meanwhile.
local function people()
    local db = ns.addon and ns.addon.db
    if not db then return nil end
    db.profile.people = db.profile.people or {}
    return db.profile.people
end

-- Keeps the store from growing without limit. Everyone you have ever spoken to
-- is not worth remembering; the last few hundred are.
local PEOPLE_MAX = 300

local function forget_oldest()
    local store = people()
    if not store then return end
    local count = 0
    for _ in pairs(store) do count = count + 1 end
    while count > PEOPLE_MAX do
        local oldestName, oldestSeen
        for name, info in pairs(store) do
            if not oldestSeen or (info.seen or 0) < oldestSeen then
                oldestName, oldestSeen = name, info.seen or 0
            end
        end
        if not oldestName then return end
        store[oldestName] = nil
        count = count - 1
    end
end

-- Names confirmed during this session. What is in the store is otherwise a
-- memory of unknown age, and a memory has to say so; something the server told
-- us five seconds ago does not.
local confirmed = {}

-- Everything we learn, from wherever we learn it, lands here.
function ns.RememberPlayer(name, info)
    if not name or not info then return end
    local store = people()
    if not store then return end

    local known = store[name] or {}
    known.className = info.className or known.className
    known.raceName  = info.raceName  or known.raceName
    known.level     = info.level     or known.level
    known.seen      = time and time() or known.seen
    store[name] = known
    confirmed[name] = true
    forget_oldest()
end

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

-- A Battle.net friend is the easy case, and the only one where no lookup is
-- needed: the client already holds their character, race, class and level, and
-- hands them over for nothing.
function ns.IdentifyBattleNet(bnetID)
    if not bnetID or not C_BattleNet or not C_BattleNet.GetAccountInfoByID then return nil end
    local account = C_BattleNet.GetAccountInfoByID(bnetID)
    local game = account and account.gameAccountInfo
    if not game then return nil end
    return {
        className     = game.className,
        raceName      = game.raceName,
        level         = game.characterLevel,
        characterName = game.characterName,
        realmName     = game.realmName,
        online        = game.isOnline,
    }
end

-- The best source of the lot, and the one I missed: every chat message carries
-- the sender's GUID, and a GUID is enough for the client to hand back race and
-- class on the spot.
--
-- It beats a /who twice over. It costs nothing and is never throttled, and it
-- works across realms -- the who service is realm-local, so the one person the
-- lookup could never answer for is exactly the one whose name arrives with a
-- realm attached.
--
-- It does not carry a level, which is why the guild roster and the lookup are
-- still worth having: between them a guildmate reads "Human Priest, 70" rather
-- than "Priest, 70".
function ns.LearnFromGUID(name, guid)
    if not name or not guid or not GetPlayerInfoByGUID then return end
    local ok, className, _, raceName = pcall(GetPlayerInfoByGUID, guid)
    if not ok or (not className and not raceName) then return end
    ns.RememberPlayer(name, { className = className, raceName = raceName })
end

function ns.IdentifyPlayer(name)
    if not name then return nil end

    local units = { "target", "mouseover" }
    for _, candidate in ipairs(ns.GroupUnits and ns.GroupUnits() or {}) do
        units[#units + 1] = candidate
    end
    for _, unit in ipairs(units) do
        local info = fromUnit(unit, name)
        if info then
            ns.RememberPlayer(name, info)
            return info
        end
    end

    local store = people()
    local remembered = store and store[name]
    local guild = fromGuild(name)

    -- The roster is current and the store may be months old, so what the roster
    -- knows wins -- but it never carries a race, so a remembered one fills that
    -- gap rather than being thrown away.
    if guild then
        return {
            className = guild.className or (remembered and remembered.className),
            raceName  = remembered and remembered.raceName,
            level     = guild.level or (remembered and remembered.level),
            seen      = remembered and remembered.seen,
            stale     = false,
        }
    end

    if remembered then
        local copy = {}
        for key, value in pairs(remembered) do copy[key] = value end
        copy.stale = not confirmed[name]
        return copy
    end
    return nil
end

-- There is no lookup any more, and this is where it was.
--
-- Reading a /who answer required SetWhoToUi, which is not a quiet flag: it means
-- "put who results in the interface", and the interface for who results is the
-- Social window. So every window you opened on a stranger opened that panel over
-- the game a moment later. It also leaked -- the flag was only put back after an
-- answer arrived, so a lookup that found nobody left it on and hijacked the
-- player's own /who afterwards.
--
-- It is not worth fixing because it is barely worth having. The sender's GUID
-- gives race and class for nothing, the guild roster gives level and class, and
-- between them the only thing the lookup still added was the level of a stranger
-- -- which is not worth a window opening in your face, a server throttle, and a
-- global flag left switched on.


-- "seen 3 days ago". Rough on purpose: the point is whether this is current or
-- a memory, not the hour it happened.
function ns.SeenAgo(when)
    if not when or not time then return nil end
    local gap = time() - when
    if gap < 3600 then return "seen just now" end
    if gap < 86400 then
        local hours = math.floor(gap / 3600)
        return "seen " .. hours .. (hours == 1 and " hour ago" or " hours ago")
    end
    local days = math.floor(gap / 86400)
    if days < 30 then return "seen " .. days .. (days == 1 and " day ago" or " days ago")
    end
    local months = math.floor(days / 30)
    return "seen " .. months .. (months == 1 and " month ago" or " months ago")
end

-- "Orc Shaman, 41" from whatever parts turned up, and never an empty line.
--
-- Every part of this can be missing and each gap is said rather than hidden. A
-- guildmate has no race because the roster does not carry one; a stranger has
-- nothing at all until the server answers; somebody you met months ago has
-- everything, but out of date, and saying when you last saw them is the
-- difference between a fact and a guess.
local function describe(name, info)
    if not info then return "Unknown" end

    local who = ((info.raceName or "") .. " " .. (info.className or "")):gsub("^%s+", "")
    local parts = {}
    if who ~= "" then parts[#parts + 1] = who end
    if info.level then
        parts[#parts + 1] = (who ~= "" and ", " or "level ") .. info.level
    end

    local line = table.concat(parts)
    if line == "" then return "Unknown" end

    -- Remembered rather than current. Without this the window would state a
    -- level from three months ago as though it were true today.
    if info.stale then
        local ago = ns.SeenAgo(info.seen)
        if ago then line = line .. " - " .. ago end
    end
    return line
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

function Whisper:Build(name, bnetID)
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

    -- The conversation. A ScrollingMessageFrame is what the game's own chat
    -- windows are, so scrolling, wrapping and line limits come for free rather
    -- than being rebuilt badly on top of a scroll frame.
    local log = CreateFrame("ScrollingMessageFrame", nil, frame)
    log:SetPoint("TOPLEFT", PAD, -HEAD_H)
    log:SetSize(WIDTH - PAD * 2, LOG_H)
    log:SetFontObject("GameFontHighlightSmall")
    log:SetJustifyH("LEFT")
    log:SetFading(false)              -- a transcript must not dissolve as you read it
    log:SetMaxLines(Log_MAX_SHOWN)
    log:SetInsertMode("BOTTOM")
    log:EnableMouseWheel(true)
    log:SetScript("OnMouseWheel", function(self, delta)
        if delta > 0 then self:ScrollUp() else self:ScrollDown() end
    end)
    frame.log = log

    -- Three windows open with a transcript each is most of a screen, so the
    -- conversation folds away and the window becomes the strip it used to be.
    local fold = CreateFrame("Button", nil, frame)
    fold:SetSize(16, 16)
    fold:SetPoint("TOPRIGHT", -24, -8)
    fold:SetNormalTexture("Interface\\Buttons\\UI-MinusButton-Up")
    fold:SetScript("OnClick", function() Whisper:ToggleLog(frame) end)
    fold:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(frame.collapsed and "Show the conversation" or "Hide the conversation")
        GameTooltip:Show()
    end)
    fold:SetScript("OnLeave", function() GameTooltip:Hide() end)
    frame.fold = fold

    local close = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    close:SetSize(24, 24)
    close:SetPoint("TOPRIGHT", 2, 2)
    close:SetScript("OnClick", function() Whisper:Close(name, bnetID) end)

    -- The three that act. Speak is ours and always works; the other two are the
    -- game's and are switched off when the game would refuse them.
    frame.speak = iconButton(frame, GOSSIP_ICON, ICON)
    frame.speak:SetPoint("BOTTOMLEFT", PAD, PAD + INPUT_H + 5)
    frame.speak.tipTitle = "Say something"
    frame.speak.tipBody = "Answer them in character. Nothing is sent until you press the channel."
    frame.speak:SetScript("OnClick", function(self)
        ns.Board:New("WHISPER:" .. Whisper:Key(name, bnetID))
            :Toggle(self, ns.Contexts:Whisper(name, bnetID))
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
        -- An account has no name to invite; the character behind it does, and
        -- it needs its realm because they may not be on yours.
        local who = name
        if bnetID then
            local info = ns.IdentifyBattleNet(bnetID)
            if not info or not info.characterName then return end
            who = info.realmName and (info.characterName .. "-" .. info.realmName)
                or info.characterName
        end
        if InviteToGroup then InviteToGroup(who)
        elseif InviteUnit then InviteUnit(who) end
    end)

    frame.trade = iconButton(frame, TRADE_ICON, ICON)
    frame.trade:SetPoint("LEFT", frame.invite, "RIGHT", 6, 0)
    frame.trade.tipTitle = "Trade"
    frame.trade.tipBody = "Only works while they are standing next to you and selected."
    -- Typing. The one rule this must not break: it never takes the keyboard on
    -- its own. Autofocus here would mean pressing W to walk and writing a "w"
    -- into a whisper instead, which is the fastest way to make an addon
    -- unusable. You click in to type, and Escape or Enter hands the keys back.
    local input = CreateFrame("EditBox", nil, frame, "InputBoxTemplate")
    input:SetHeight(INPUT_H)
    input:SetPoint("BOTTOMLEFT", PAD + 6, PAD)
    input:SetPoint("BOTTOMRIGHT", -PAD, PAD)
    input:SetAutoFocus(false)
    input:SetMaxLetters(ns.MAX_MESSAGE)
    input:SetFontObject("ChatFontSmall")
    input:SetScript("OnEscapePressed", function(self)
        self:SetText("")
        self:ClearFocus()
    end)
    input:SetScript("OnEnterPressed", function(self)
        local text = self:GetText()
        self:SetText("")
        self:ClearFocus()
        Whisper:Say(frame, text)
    end)
    frame.input = input

    frame.trade:SetScript("OnClick", function()
        if UnitExists("target") and UnitName("target") == name and InitiateTrade then
            InitiateTrade("target")
        end
    end)

    frame.name = name
    frame.bnetID = bnetID
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

-- Redrawn from the store rather than appended to, so a window opened now and a
-- window opened after six weeks show the same thing.
function Whisper:RefreshLog(frame)
    if not frame.log then return end
    frame.log:Clear()

    local key = ns.Log:Key(frame.name, frame.bnetID)
    local lines = ns.Log:Lines(key)
    local me = UnitName and UnitName("player") or "you"

    local from = math.max(1, #lines - Log_MAX_SHOWN + 1)
    for i = from, #lines do
        frame.log:AddMessage(ns.Log:Format(lines[i], frame.name, me))
    end
end

function Whisper:Append(frame, entry)
    if not frame.log then return end
    local me = UnitName and UnitName("player") or "you"
    frame.log:AddMessage(ns.Log:Format(entry, frame.name, me))
end

-- Anything typed goes out through the same function every other line in the
-- addon goes through, which is what keeps "nothing is ever sent without you
-- asking" true of one place rather than two.
--
-- Nothing is written to the transcript here. Sending raises the event that
-- records it, exactly as it does when you type in the game's own chat, so
-- recording it again would show every line twice.
function Whisper:Say(frame, text)
    text = (text or ""):gsub("^%s+", ""):gsub("%s+$", "")
    if text == "" then return end

    if frame.bnetID then
        ns.SendPhrase(text, "BN_WHISPER", frame.bnetID)
    else
        ns.SendPhrase(text, "WHISPER", frame.name)
    end
end

function Whisper:ApplyFold(frame)
    -- The input stays whichever way it folds: a folded window is still a
    -- conversation you are in, it is just one you are not reading back.
    local base = HEAD_H + ICON + INPUT_H + PAD * 2 + 5
    if frame.collapsed then
        frame.log:Hide()
        frame:SetHeight(base)
        frame.fold:SetNormalTexture("Interface\\Buttons\\UI-PlusButton-Up")
    else
        frame.log:Show()
        frame:SetHeight(base + LOG_H + 4)
        frame.fold:SetNormalTexture("Interface\\Buttons\\UI-MinusButton-Up")
    end
end

function Whisper:ToggleLog(frame)
    frame.collapsed = not frame.collapsed
    local db = ns.addon and ns.addon.db
    if db then db.profile.whisperCollapsed = frame.collapsed end
    self:ApplyFold(frame)
end

function Whisper:RefreshHeader(frame)
    frame.title:SetText(frame.name)

    if frame.bnetID then
        local info = ns.IdentifyBattleNet(frame.bnetID)
        if not info then
            frame.subtitle:SetText("Battle.net friend")
        elseif info.characterName then
            -- Who they are playing right now, which is the useful half.
            frame.subtitle:SetText(info.characterName .. " - " .. describe(frame.name, info))
        else
            frame.subtitle:SetText(info.online and "Online" or "Offline")
        end
        return
    end

    frame.subtitle:SetText(describe(frame.name, ns.IdentifyPlayer(frame.name)))
end

-- Windows are keyed by who they are about. A Battle.net conversation is about
-- an account, not a character: the same person may be on a different character
-- tomorrow, and the whisper still reaches them.
function Whisper:Key(name, bnetID)
    return bnetID and ("bn:" .. bnetID) or name
end

function Whisper:Open(name, said, bnetID)
    if not name or name == "" then return nil end

    local key = self:Key(name, bnetID)
    local frame = windows[key]
    if not frame then
        openCount = openCount + 1
        frame = self:Build(name, bnetID)
        local db = ns.addon and ns.addon.db
        frame.collapsed = db and db.profile.whisperCollapsed or false
        windows[key] = frame
        self:PlaceNew(frame, openCount)
    end

    self:RefreshHeader(frame)
    self:RefreshLog(frame)
    self:ApplyFold(frame)
    frame:Show()
    self:UpdateActions(frame)
    return frame
end

-- A button that cannot do anything must not look like it can. Trade needs them
-- selected and beside you, which in a whisper is the exception rather than the
-- rule; invite is off once they are already with you.
function Whisper:UpdateActions(frame)
    if frame.bnetID then
        -- Trade needs someone standing beside you, which an account is not, and
        -- inviting needs them to be playing something right now.
        local info = ns.IdentifyBattleNet(frame.bnetID)
        local invitable = info ~= nil and info.characterName ~= nil and info.online == true
        frame.trade:SetEnabled(false)
        frame.trade.icon:SetAlpha(0.3)
        frame.invite:SetEnabled(invitable)
        frame.invite.icon:SetAlpha(invitable and 0.85 or 0.3)
        return
    end

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

-- Every whisper is written down, whether or not a window is open: the
-- conversation is the record, not the window. An open one also shows the line
-- as it arrives.
--
-- What this never does is open a window. A window appearing over the game
-- because somebody typed at you is the behaviour we refused for the target
-- board, and it is worse here because it takes a corner of the screen.
function Whisper:Heard(name, message, incoming, bnetID)
    if not name or not message then return false end

    local key = ns.Log:Key(name, bnetID)
    ns.Log:Record(key, message, incoming)

    local frame = windows[key]
    if not frame or not frame:IsShown() then return false end

    local lines = ns.Log:Lines(key)
    self:Append(frame, lines[#lines])
    self:RefreshHeader(frame)
    return true
end

function Whisper:Close(name, bnetID)
    local key = self:Key(name, bnetID)
    local frame = windows[key]
    if not frame then return end
    frame:Hide()
    local board = ns.Board and ns.Board:New("WHISPER:" .. key)
    if board then board:Close() end
end

function Whisper:IsOpen(name, bnetID)
    local frame = windows[self:Key(name, bnetID)]
    return frame ~= nil and frame:IsShown()
end

function Whisper:Windows()
    return windows
end
