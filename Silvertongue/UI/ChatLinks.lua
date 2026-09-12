-- ChatLinks.lua -- the bubble beside someone's name in chat.
--
-- A whisper is the one conversation the addon could not reach: the person is
-- not your target, not in your group, not in a listing. They are a line of
-- text. So the line itself gets the mark, and clicking it opens their window.
--
-- Two decisions worth keeping:
--
-- It goes on whispers and on guild chat, and on nothing else by default. On a
-- busy evening general chat is fifty lines that have nothing to do with you,
-- and a mark that appears on things you do not care about stops being a button
-- and becomes wallpaper -- at which point you will not see it on the whisper
-- either.
--
-- The click is a link of our own rather than a hook on the game's player menu.
-- This client hands unrecognised links to the item tooltip, which would pop an
-- empty tooltip over the screen; LinkUtil.RegisterLinkHandler is the supported
-- way to claim a type, and claiming it means the game stops there.

local ADDON, ns = ...

local ChatLinks = {}
ns.ChatLinks = ChatLinks

local LINK_TYPE = "silvertongue"

-- Inline textures take their size in the escape itself. Fourteen sits on the
-- cap height of the chat font without pushing the line spacing out.
local MARK = "|TInterface\\GossipFrame\\GossipGossipIcon:14:14|t"

-- Which events carry a name worth marking, and whether we do it. Guild is on
-- because a guild line is a person you can answer; everything else is off.
ChatLinks.EVENTS = {
    CHAT_MSG_WHISPER = "whisper",
    CHAT_MSG_GUILD   = "guild",
}

-- Lines the game writes itself: "[Baddiebolts] has invited you to join a
-- group." These have no author -- the name lives inside the sentence -- so the
-- two above cannot reach them.
--
-- They do not need parsing either, which is the part worth knowing. The game
-- writes the name as a player link, which is why clicking it already opens a
-- tell. That link is the name, marked, in the text: finding it is a pattern
-- over an escape sequence rather than a guess at a localised sentence, so this
-- works for every system line that names somebody and keeps working when the
-- wording changes.
ChatLinks.SYSTEM_EVENTS = { CHAT_MSG_SYSTEM = "system" }

-- |Hplayer:Name|h[Name]|h, and the longer form that carries the line id and
-- chat type after the name.
-- No captures: gsub hands the whole link to the replacement, and the name is
-- read back out of it. With a capture it would hand over the name alone and the
-- link itself would be lost.
local PLAYER_LINK = "|Hplayer:[^|]+|h.-|h"

-- |HBNplayer:<display name>:<account id>:...|h[Name]|h. The account id is what
-- a Battle.net whisper is addressed to: there may be no character to whisper at
-- all, and if they are on the other faction or another realm there certainly is
-- not.
local BN_LINK = "|HBNplayer[^|]*|h.-|h"

local function enabled(kind)
    local db = ns.addon and ns.addon.db
    if not db then return true end
    local chat = db.profile.chatIcons
    if not chat then return true end
    if chat[kind] == nil then return true end
    return chat[kind] and true or false
end

-- What the icon is wrapped in. The name travels inside the link, so the click
-- knows who it was about without looking at anything that may have moved on.
local function markLink(name)
    return "|H" .. LINK_TYPE .. ":" .. name .. "|h" .. MARK .. "|h"
end

-- Battle.net conversations are addressed by account, so the mark carries the
-- id and the name is only there to put in the window's title bar.
local function markBattleNet(id, display)
    return "|H" .. LINK_TYPE .. ":bn:" .. id .. ":" .. display .. "|h" .. MARK .. "|h"
end

-- Ahead of the message, so the icon sits where the name is.
local function mark(name)
    return markLink(name) .. " "
end

-- Message filters may rewrite the arguments and must pass the rest through
-- untouched. Returning true here would eat the line out of the chat frame,
-- which is emphatically not the deal.
function ChatLinks:Filter(kind, event, message, author, ...)
    if not enabled(kind) then return false, message, author, ... end
    if not author or author == "" then return false, message, author, ... end

    -- Your own line in guild chat does not need a button to answer yourself.
    local me = UnitName and UnitName("player")
    if me and author == me then return false, message, author, ... end

    return false, mark(author) .. message, author, ...
end

-- The mark goes after the name rather than before it, so the sentence still
-- reads from its first word.
function ChatLinks:MarkNamesInText(message)
    if not message or message:find("|H" .. LINK_TYPE .. ":", 1, true) then return message end

    local me = UnitName and UnitName("player")
    local seen, changed = {}, false

    local out = message:gsub(PLAYER_LINK, function(link)
        local name = link:match("|Hplayer:([^:|]+)")
        if not name or name == me or seen[name] then return link end
        seen[name] = true
        changed = true
        return link .. " " .. markLink(name)
    end)

    return changed and out or message
end

function ChatLinks:FilterSystem(event, message, ...)
    if not enabled("system") then return false, message, ... end
    return false, self:MarkNamesInText(message), ...
end

-- "[Diego Vinas] (Olfer) has come online."
--
-- This one cannot be done with a filter, and finding out why took removing a
-- test that was only ever testing my own assumption. The event does not carry
-- that sentence: it carries the token FRIEND_ONLINE, the name, and the account
-- id, and the chat frame builds the sentence and the link itself afterwards --
-- for a friend in-game, inside an asynchronous texture callback that writes
-- straight into the window. By the time the line exists, every filter has run.
--
-- So this wraps the frames' own AddMessage, which sees the finished text, and it
-- marks Battle.net links only. That restriction is the whole reason this is
-- safe: an ordinary say or guild line also has its sender written as a link by
-- the time it gets here, and marking those would put a bubble on every line of
-- general chat -- the exact thing we decided not to do. A BNplayer link appears
-- only in friend toasts, broadcasts and Battle.net whispers, which is precisely
-- the set worth marking.
-- Printing the raw text of a line, escapes and all.
--
-- This exists because I have now guessed wrong twice about what that Battle.net
-- line actually contains, and a guess dressed as a fix wastes a round trip
-- through the game each time. `/silvertongue chatdebug` prints the next few
-- lines exactly as they reach the frame, with every pipe doubled so the client
-- shows the escapes instead of rendering them.
local debugLeft = 0
local printing = false

function ChatLinks:Debug(count)
    debugLeft = count or 12
    if ns.addon then
        ns.addon:Print("Printing the next " .. debugLeft ..
            " chat lines raw. Make a friend come online, then paste what appears.")
    end
end

local function debugLine(text)
    if debugLeft <= 0 or printing or type(text) ~= "string" then return end
    -- Print writes to a chat frame, which comes straight back through here.
    printing = true
    debugLeft = debugLeft - 1
    if ns.addon then ns.addon:Print("RAW: " .. text:gsub("|", "||")) end
    printing = false
end

-- Counted off the frames themselves rather than remembered here. What the
-- probe has to answer is "is the wrapper on the frames", and a flag on this
-- table answers "did I once believe I put it there" -- which is not the same
-- question the moment anything else reloads or replaces a frame.
function ChatLinks:IsHooked()
    local count = 0
    for i = 1, (NUM_CHAT_WINDOWS or 10) do
        local frame = _G["ChatFrame" .. i]
        if frame and frame.silvertongueWrapped then count = count + 1 end
    end
    return count > 0, count
end

function ChatLinks:HookFrames()
    if self.framesHooked then return end
    self.framesHooked = true

    for i = 1, (NUM_CHAT_WINDOWS or 10) do
        local frame = _G["ChatFrame" .. i]
        if frame and frame.AddMessage and not frame.silvertongueWrapped then
            frame.silvertongueWrapped = true
            local original = frame.AddMessage
            frame.AddMessage = function(self, text, ...)
                debugLine(text)
                if type(text) == "string" and text:find("|HBNplayer", 1, true) then
                    text = ChatLinks:MarkBattleNetIn(text)
                end
                return original(self, text, ...)
            end
        end
    end
end

function ChatLinks:MarkBattleNetIn(message)
    if not enabled("friends") then return message end
    if message:find("|H" .. LINK_TYPE .. ":bn:", 1, true) then return message end

    local seen, changed = {}, false
    local out = message:gsub(BN_LINK, function(link)
        local display, id = link:match("|HBNplayer[^:]*:([^:|]*):([^:|]+)")
        if not id or seen[id] then return link end
        seen[id] = true
        changed = true
        return link .. " " .. markBattleNet(id, display or "")
    end)
    return changed and out or message
end

function ChatLinks:OnClick(payload)
    if not payload or payload == "" then return end
    if not ns.Whisper then return end

    local id, display = payload:match("^bn:([^:]+):?(.*)$")
    if id then
        ns.Whisper:Open((display ~= "" and display) or ("Battle.net " .. id), nil, id)
        return
    end
    ns.Whisper:Open(payload)
end

-- The link type is claimed once. Registering the same type twice trips an
-- assert inside the game rather than replacing the handler.
function ChatLinks:Register()
    if self.registered then return end
    self.registered = true

    if LinkUtil and LinkUtil.RegisterLinkHandler then
        if not (LinkUtil.IsLinkHandlerRegistered and LinkUtil.IsLinkHandlerRegistered(LINK_TYPE)) then
            LinkUtil.RegisterLinkHandler(LINK_TYPE, function(link)
                ChatLinks:OnClick(link:match("^" .. LINK_TYPE .. ":(.+)$"))
            end)
        end
    elseif hooksecurefunc then
        -- A client without the registry. The hook runs after the default, so
        -- the stray tooltip is closed rather than prevented.
        hooksecurefunc("SetItemRef", function(link)
            local name = link and link:match("^" .. LINK_TYPE .. ":(.+)$")
            if not name then return end
            if ItemRefTooltip then ItemRefTooltip:Hide() end
            ChatLinks:OnClick(name)
        end)
    end

    if not ChatFrame_AddMessageEventFilter then return end
    for event, kind in pairs(self.EVENTS) do
        ChatFrame_AddMessageEventFilter(event, function(_, e, ...)
            return ChatLinks:Filter(kind, e, ...)
        end)
    end
    for event in pairs(self.SYSTEM_EVENTS) do
        ChatFrame_AddMessageEventFilter(event, function(_, e, ...)
            return ChatLinks:FilterSystem(e, ...)
        end)
    end

    self:HookFrames()
end
