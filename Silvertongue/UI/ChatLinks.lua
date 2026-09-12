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

    -- An open window follows the conversation without being asked. It never
    -- opens one: a window that appears because somebody typed at you takes a
    -- corner of your screen without permission.
    if kind == "whisper" and ns.Whisper then
        ns.Whisper:Heard(author, message)
    end

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

function ChatLinks:OnClick(name)
    if not name or name == "" then return end
    if not ns.Whisper then return end
    ns.Whisper:Open(name)
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
end
