-- Settings.lua -- saved variable defaults and small config helpers.

local ADDON, ns = ...

-- Channels Silvertongue may speak through, in menu order.
ns.CHANNELS = {
    { key = "SAY",           label = "Say" },
    { key = "PARTY",         label = "Party" },
    { key = "RAID",          label = "Raid" },
    { key = "INSTANCE_CHAT", label = "Instance" },
    { key = "WHISPER",       label = "Whisper" },
    { key = "LFG",           label = "LookingForGroup" },
    { key = "GUILD",         label = "Guild" },
    { key = "YELL",          label = "Yell" },
    { key = "EMOTE",         label = "Emote" },
}

ns.CHANNEL_LABEL = {}
for _, c in ipairs(ns.CHANNELS) do
    ns.CHANNEL_LABEL[c.key] = c.label
end

ns.defaults = {
    profile = {
        position       = { point = "CENTER", x = 0, y = 0 },
        channelPerTab  = {
            GENERAL  = "SAY",
            PARTY    = "PARTY",
            TARGET   = "SAY",
            FACTION  = "SAY",
            CLASS    = "SAY",
            ATTITUDE = "SAY",
        },
        favorites      = {},
        lastTab        = "GENERAL",
        minimap        = { hide = false, minimapPos = 220 },
        anchorsEnabled = true,
        menus          = {},
        lfgDungeon     = nil,
        anchors        = {},
        -- Which chat lines get the bubble beside the name. Guild is on because
        -- a guild line is a person you can answer; if it turns into noise it is
        -- one switch away.
        chatIcons      = { whisper = true, guild = true, system = true, friends = true },
        whisperAnchor  = nil,
        log            = {},
    },
}

-- The only function in the addon that speaks. Trims to the client limit,
-- falls back when the channel no longer applies, and routes a whisper to the
-- person the line is about rather than to whatever is selected right now.
ns.MAX_MESSAGE = 255

-- The gesture goes first: "Silvertongue bows before Grumgar." then the line. That
-- is the order roleplay reads in.
function ns.SendPhrase(text, channel, recipient, emote, emoteTarget)
    text = (text or ""):gsub("^%s+", ""):gsub("%s+$", "")
    if text == "" then return nil end

    if #text > ns.MAX_MESSAGE then
        text = text:sub(1, ns.MAX_MESSAGE)
    end

    if emote and emote ~= ns.EMOTE_NONE and DoEmote then
        DoEmote(emote, emoteTarget)
    end

    -- A named recipient is enough on its own. The target-based check below is
    -- for lines aimed at whoever you have selected; this name came from a
    -- group listing, where there is no unit to inspect.
    -- Addressed to a Battle.net account rather than a character. There may be
    -- no character to whisper at all -- they can be on the other faction, on
    -- another realm, or in a different game entirely.
    if channel == "BN_WHISPER" then
        if recipient and BNSendWhisper then
            BNSendWhisper(tonumber(recipient) or recipient, text)
            return "BN_WHISPER"
        end
        return nil
    end

    if channel == "WHISPER" and recipient then
        SendChatMessage(text, "WHISPER", nil, recipient)
        return "WHISPER"
    end

    -- Before the fallback below: an advert with nowhere to go must not be
    -- shouted at whoever happens to be standing next to you instead.
    if channel == "LFG" then
        local id = ns.LookingForGroupChannel()
        if not id then
            -- Join now and let the next press speak. Sending from a timer once
            -- the join answers is refused outright: the click is over by then,
            -- and a public channel will not take a line without one behind it.
            ns.JoinLookingForGroup()
            if ns.addon then
                ns.addon:Print("Joined LookingForGroup. Press it once more and it goes out.")
            end
            return nil
        end

        -- Before speaking, not after: the first thing that happens next is
        -- somebody answering, and it has to land somewhere you are looking.
        ns.EnsureChannelVisible("LookingForGroup")
        SendChatMessage(text, "CHANNEL", nil, id)
        return "LFG"
    end

    -- Resolve: this is what turns a whisper at an Alliance target or a creature
    -- back into say. Checking it after would let those through.
    channel = ns.ResolveChannel(channel)

    if channel == "WHISPER" then
        local to = recipient or ns.UnitFullName("target")
        if to then
            SendChatMessage(text, "WHISPER", nil, to)
            return "WHISPER"
        end
        channel = "SAY"     -- nobody to whisper: say it rather than swallow it
    end

    SendChatMessage(text, channel)
    return channel
end

-- Dropped into an intent list to ask for a dividing line there. A unique table
-- rather than a string, so it can never collide with a real intent.
ns.SEP = { "SEPARATOR" }

-- Menu order, as you arranged it.
--
-- What is stored is a list of intent keys and the word "SEP", never the entries
-- themselves. On load it is reconciled against the built-in list: anything that
-- no longer exists falls away, and anything added since is appended. That is
-- what keeps a menu you rearranged from freezing out every intent added later.
function ns.ResolveMenu(listKey, builtin)
    local saved = ns.addon and ns.addon.db and ns.addon.db.profile.menus
        and ns.addon.db.profile.menus[listKey]
    if not saved or #saved == 0 then return builtin end

    local byIntent = {}
    for _, entry in ipairs(builtin) do
        if entry ~= ns.SEP then byIntent[ns.MenuEntryKey(entry)] = entry end
    end

    local out, seen, lastWasSep = {}, {}, true
    for _, key in ipairs(saved) do
        if key == "SEP" then
            -- Never two lines running, and never one before the first row: an
            -- intent between them may have gone away.
            if not lastWasSep then
                out[#out + 1] = ns.SEP
                lastWasSep = true
            end
        else
            local entry = byIntent[key]
            if entry and not seen[key] then
                out[#out + 1] = entry
                seen[key], lastWasSep = true, false
            end
        end
    end

    for _, entry in ipairs(builtin) do
        if entry ~= ns.SEP then
            local key = ns.MenuEntryKey(entry)
            if not seen[key] then
                out[#out + 1] = entry
                seen[key] = true
            end
        end
    end

    -- A trailing line has nothing left to separate.
    if out[#out] == ns.SEP then table.remove(out) end
    return out
end

-- The key each entry is remembered by. Intents are unique inside one menu, so
-- the intent alone identifies a row.
--
-- Two shapes of list feed this. The tab grids are { intent, label }; the target
-- and party lists are { category, intent, label } because they draw on more
-- than one category. The length tells them apart -- reading position two
-- blindly would store a label for half the menus and never match again.
function ns.MenuEntryKey(entry)
    if entry == ns.SEP then return "SEP" end
    if #entry >= 3 then return entry[2] end
    return entry[1]
end

function ns.SaveMenu(listKey, entries)
    local db = ns.addon and ns.addon.db
    if not db then return end
    db.profile.menus = db.profile.menus or {}

    local keys = {}
    for _, entry in ipairs(entries) do keys[#keys + 1] = ns.MenuEntryKey(entry) end
    db.profile.menus[listKey] = keys
end

function ns.ResetMenu(listKey)
    local db = ns.addon and ns.addon.db
    if db and db.profile.menus then db.profile.menus[listKey] = nil end
end

-- FOR_THE_HORDE becomes "For The Horde". Used for headings built from data, so
-- adding an intent never means adding a label somewhere else.
function ns.Titlecase(token)
    local words = {}
    for word in tostring(token):gmatch("[^_]+") do
        words[#words + 1] = word:sub(1, 1):upper() .. word:sub(2):lower()
    end
    return table.concat(words, " ")
end

-- A channel is only offered when the player could actually speak on it.
function ns.IsChannelAvailable(key)
    if key == "PARTY" then
        return IsInGroup() and not IsInRaid()
    elseif key == "RAID" then
        return IsInRaid()
    elseif key == "INSTANCE_CHAT" then
        return IsInInstance() and IsInGroup()
    elseif key == "WHISPER" then
        return ns.CanWhisperTarget()
    elseif key == "LFG" then
        return true     -- not joined yet is not a reason to hide it; we join
    elseif key == "GUILD" then
        return IsInGuild and IsInGuild() and true or false
    end
    return true
end

-- The number of the LookingForGroup channel, or nil when it is not joined.
function ns.LookingForGroupChannel()
    if not GetChannelName then return nil end
    local id = GetChannelName("LookingForGroup")
    if id and id > 0 then return id end
    return nil
end

-- Is any chat window actually showing this channel?
--
-- Being in a channel and seeing it are different things, and the gap between
-- them looks exactly like a broken addon: the advert goes out, nobody's reply
-- is visible, and the button appears to do nothing.
function ns.ChannelIsVisible(name)
    local wanted = tostring(name):lower()
    for i = 1, (NUM_CHAT_WINDOWS or 10) do
        local frame = _G["ChatFrame" .. i]
        for _, carried in ipairs((frame and frame.channelList) or {}) do
            if tostring(carried):lower() == wanted then return true, i end
        end
    end
    return false
end

-- Puts it in the main window if nothing is carrying it. Advertising somewhere
-- you cannot read is not advertising: the answers come back on that channel.
function ns.EnsureChannelVisible(name)
    if ns.ChannelIsVisible(name) then return false end
    local frame = DEFAULT_CHAT_FRAME
    if not frame or not frame.AddChannel then return false end
    frame:AddChannel(name)
    if ns.addon then
        ns.addon:Print("Showing " .. name .. " in your main chat window -- "
            .. "you were in it but no window was carrying it, so the replies had nowhere to land.")
    end
    return true
end

-- Joins the channel, and does NOT then speak.
--
-- This is the whole lesson of the day. Sending to a public channel needs a
-- hardware event behind it -- a real click or keypress -- which is how the game
-- keeps spam bots off the channels. Pressing the button is such an event, so
-- speaking straight from the click works and always did. Waiting for the join to
-- come back and speaking from a timer is not: by then the click is over and the
-- client refuses the line, which is the "Interface action failed because of an
-- AddOn" that survived three attempts at fixing the wrong thing.
--
-- So no wait of any length could have worked. Waiting was the bug. The join
-- happens, the channel is made visible, and it says plainly that the next press
-- will send -- one extra click, once, the first time you advertise in a session.
function ns.JoinLookingForGroup()
    local NAME = "LookingForGroup"

    -- The main chat window, not "the current" one. The current one can be a
    -- temporary window, whose lines land somewhere you are not looking.
    local frame = DEFAULT_CHAT_FRAME
    local frameID = (frame and frame.GetID and frame:GetID()) or 1

    if JoinPermanentChannel then
        JoinPermanentChannel(NAME, nil, frameID, 1)
        if frame and frame.AddChannel then frame:AddChannel(NAME) end
    elseif JoinChannelByName then
        JoinChannelByName(NAME)
    else
        return false
    end
    return true
end

-- Called when you open something that advertises, which is itself a click, so
-- by the time you pick a line the channel is usually already there and the
-- second press never comes up.
function ns.PrepareLookingForGroup()
    if ns.LookingForGroupChannel() then
        ns.EnsureChannelVisible("LookingForGroup")
        return
    end
    ns.JoinLookingForGroup()
end

-- A unit's name as chat writes it.
--
-- UnitName drops the realm, and the chat events never do: a whisper from
-- somebody on a connected realm arrives as "Arthuruno-Dreamscythe" while the
-- unit behind it answers "Arthuruno". Anything that files a conversation under
-- one and looks it up under the other finds nothing, which is how a transcript
-- came up empty for exactly the people most likely to have one.
function ns.UnitFullName(unit)
    if not unit or not UnitExists(unit) then return nil end
    local name, realm = UnitName(unit)
    if not name then return nil end
    if realm and realm ~= "" then return name .. "-" .. realm end
    return name
end

-- The name a conversation is filed under: the character, without the realm.
--
-- I argued against this at first, because names are only unique within a realm
-- and two people called Faithshade on connected realms would share a window.
-- The argument that beats it is that the two sides do not agree on the name.
-- A unit answers "Faithshade" while chat says "Faithshade-Dreamscythe", or the
-- reverse, and which of them carries the realm depends on the client, the realm
-- connection and where the name came from. Filing under one and looking up
-- under the other loses the conversation, and that has now happened twice.
--
-- Stripping it means the two sides always meet. The realm is not thrown away:
-- what is displayed and what a whisper is addressed to are still the full name
-- exactly as it arrived, so a cross-realm whisper still reaches them.
function ns.ConversationKey(name)
    if not name then return nil end
    return (tostring(name):gsub("%-.*$", ""))
end

-- A player of the other side.
--
-- This is not the same question as "can I attack them", and assuming it was is
-- what put a group invite in front of a draenei. An Alliance player standing in
-- a neutral zone with no PvP flag cannot be attacked at all, so UnitCanAttack
-- says no and everything downstream treated them as a friend.
function ns.IsOppositeFaction(unit)
    unit = unit or "target"
    if not UnitExists(unit) or not UnitIsPlayer(unit) then return false end
    if UnitIsUnit(unit, "player") then return false end
    if not UnitFactionGroup then return false end
    local theirs = UnitFactionGroup(unit)
    local mine = UnitFactionGroup("player")
    if not theirs or not mine or theirs == "Neutral" then return false end
    return theirs ~= mine
end

-- You can only whisper a player on your own side. The other faction, creatures
-- and an empty selection all rule it out.
function ns.CanWhisperTarget(unit)
    unit = unit or "target"
    if not UnitExists(unit) then return false end
    if not UnitIsPlayer(unit) then return false end
    if UnitIsUnit(unit, "player") then return false end
    if ns.IsOppositeFaction(unit) then return false end
    if UnitCanCooperate and UnitCanCooperate("player", unit) then return true end
    return not UnitCanAttack("player", unit)
end

-- Falls back to SAY when the remembered channel no longer applies.
function ns.ResolveChannel(key)
    if key and ns.IsChannelAvailable(key) then return key end
    if key == "PARTY" and IsInRaid() then return "RAID" end
    return "SAY"
end
