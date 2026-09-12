-- Log.lua -- what was actually said, kept.
--
-- The window shows the conversation, and the conversation outlives the session:
-- open Rhottyn six weeks later and the last thing either of you said is still
-- there. That is the point of it.
--
-- There is still a bound, and it is not about privacy. SavedVariables is read
-- whole when you log in and written whole when you log out, so a store that
-- only ever grows eventually costs you time at both ends for lines nobody will
-- read again. The limits below are set so that "months of conversation" is
-- comfortably inside them and "forever" is not.
--
-- Entries are deliberately cramped -- t, i, m rather than time, incoming,
-- message -- because every one of those keys is written out as text for every
-- line in the file.

local ADDON, ns = ...

local Log = {}
ns.Log = Log

Log.MAX_PER_PERSON = 500        -- generous: a real conversation is tens of lines
Log.MAX_PEOPLE     = 120
Log.MAX_AGE_DAYS   = 180

local function store()
    local db = ns.addon and ns.addon.db
    if not db then return nil end
    db.profile.log = db.profile.log or {}
    return db.profile.log
end

-- The key a conversation is filed under. A Battle.net friend is filed by
-- account, because the same person on another character is the same
-- conversation.
function Log:Key(name, bnetID)
    return bnetID and ("bn:" .. bnetID) or ns.ConversationKey(name)
end

function Log:Record(key, text, incoming)
    if not key or not text or text == "" then return end
    local all = store()
    if not all then return end

    local lines = all[key]
    if not lines then
        lines = {}
        all[key] = lines
    end

    lines[#lines + 1] = {
        t = time and time() or 0,
        i = incoming and 1 or 0,
        m = text,
    }

    while #lines > self.MAX_PER_PERSON do table.remove(lines, 1) end
end

function Log:Lines(key)
    local all = store()
    return (all and all[key]) or {}
end

function Log:Clear(key)
    local all = store()
    if all then all[key] = nil end
end

-- Run once at login. Old conversations go by age first, and if there are still
-- too many people the ones you have not spoken to in longest go next.
function Log:Prune()
    local all = store()
    if not all or not time then return end

    local cutoff = time() - self.MAX_AGE_DAYS * 86400
    local newest = {}

    for key, lines in pairs(all) do
        local kept = {}
        for _, entry in ipairs(lines) do
            if (entry.t or 0) >= cutoff then kept[#kept + 1] = entry end
        end
        if #kept == 0 then
            all[key] = nil
        else
            all[key] = kept
            newest[key] = kept[#kept].t or 0
        end
    end

    local count = 0
    for _ in pairs(all) do count = count + 1 end
    while count > self.MAX_PEOPLE do
        local oldestKey, oldestAt
        for key, at in pairs(newest) do
            if not oldestAt or at < oldestAt then oldestKey, oldestAt = key, at end
        end
        if not oldestKey then return end
        all[oldestKey], newest[oldestKey] = nil, nil
        count = count - 1
    end
end

-- One line as it reads in the window: the hour, who said it, and the words.
-- Their name rather than "them", because a window you reopen weeks later should
-- not need you to remember which side you were on.
function Log:Format(entry, theirName, myName)
    local stamp = ""
    if entry.t and entry.t > 0 and date then
        stamp = "|cff808080" .. date("%H:%M", entry.t) .. "|r "
    end

    local who = (entry.i == 1) and (theirName or "them") or (myName or "you")
    local colour = (entry.i == 1) and "|cffffd200" or "|cff9bb4d4"
    return stamp .. colour .. who .. ":|r " .. entry.m
end
