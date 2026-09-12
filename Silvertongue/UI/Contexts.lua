-- Contexts.lua -- what each control puts in its board.
--
-- A context answers three questions and nothing else: who you are speaking to,
-- what you can say to them, and how it can go out. The boards render it and the
-- display sends it; neither decides any of this.
--
-- The channel rule: the context decides which channels are even on offer, and
-- in what order. While you are grouped party chat leads everywhere, because
-- that is where most of what you say while grouped is meant to land. Each
-- button is labelled with where it actually goes.

local ADDON, ns = ...

local Contexts = {}
ns.Contexts = Contexts

-- Each button says where it goes. An earlier version labelled the first one
-- "Say" whatever channel it meant, which read well with one button and badly
-- with two: a party menu showed "Say" twice, going to two different places.
local TO_PARTY  = { key = "PARTY",   label = "Party",   hint = "Goes to party chat, wherever they are." }
local SAY_ALOUD = { key = "SAY",     label = "Say",     hint = "Everyone nearby hears it." }
local YELL      = { key = "YELL",    label = "Yell",    hint = "Heard far past the room." }
local WHISPER   = { key = "WHISPER", label = "Whisper", hint = "Only they read it." }

-- In a group, party chat leads. It is where almost everything said while
-- grouped is meant to land, and it should not be the second thing you reach for.
local function leadWithParty(channels)
    if not IsInGroup() then return channels end
    local out = { TO_PARTY }
    for _, channel in ipairs(channels) do
        if channel.key ~= "PARTY" then out[#out + 1] = channel end
    end
    return out
end

local function inMyGroup(unit)
    if not unit or not UnitExists(unit) then return false end
    if UnitIsUnit(unit, "player") then return false end
    if UnitInParty and UnitInParty(unit) then return true end
    if UnitInRaid and UnitInRaid(unit) then return true end
    return false
end

-- Whoever you have selected in the world.
function Contexts:Target()
    local info = ns.TargetUI:BuildContext()
    if not info then return nil end

    local grouped = inMyGroup("target")

    local intents = {}
    for _, entry in ipairs(info.intents) do
        -- Asking someone to group up who is already in your group is noise.
        local redundant = entry ~= ns.SEP and grouped and (entry[2] == "PARTY")
        if not redundant then intents[#intents + 1] = entry end
    end

    local channels
    if info.opposed then
        -- Cross-faction speech arrives as gibberish, so the line is not for
        -- them: it is for your own side standing there, and the tooltips say so
        -- rather than letting you think it landed.
        --
        -- The gesture is the half that does arrive. An emote is an animation and
        -- a sentence in the reader's own language, so a bow or a rude gesture
        -- crosses the faction line when nothing you type does.
        channels = {
            { key = "SAY",  label = "Say",
              hint = "Your own side nearby reads it. They will not -- but the gesture lands." },
            { key = "YELL", label = "Yell",
              hint = "Heard well past the room, by everyone on your side." },
        }
    else
        channels = { SAY_ALOUD }
        -- Yelling at someone in your own group is shouting across a table.
        if not grouped then channels[#channels + 1] = YELL end
        if info.isPlayer and not info.hostile then
            channels[#channels + 1] = WHISPER
        end
    end
    channels = leadWithParty(channels)

    -- Until this existed a conversation could only begin if they spoke first:
    -- the window was born from a chat line. This is the other door.
    local actions
    if info.isPlayer and not info.hostile and ns.CanWhisperTarget("target") then
        actions = { {
            label = "Open a window",
            tip = "Opens a small window for " .. info.name .. ", to talk to them privately.",
            local_ = true,
            run = function() ns.Whisper:Open(info.name) end,
        } }
    end

    return {
        key         = "TARGET:" .. info.name,
        title       = info.name,
        subtitle    = info.descriptor,
        intents     = intents,
        ctx         = info.ctx,
        recipient   = info.name,
        emoteTarget = info.name,
        channels    = channels,
        actions     = actions,
        grouped     = grouped,
        isPlayer    = info.isPlayer,
        hostile     = info.hostile,
        opposed     = info.opposed,
        rebuild     = function() return ns.Engine:BuildUnitContext("target") end,
    }
end

local TO_LFG   = { key = "LFG",   label = "LFG",   hint = "Goes to the LookingForGroup channel, joining it if you have not." }
local TO_GUILD = { key = "GUILD", label = "Guild", hint = "Asks your guild first, which is usually where groups come from." }

-- Looking for a group, or looking for people to fill one. The line talks about
-- you, so the context is built from your own character rather than a target.
function Contexts:Group()
    local composition = ns.Engine:GroupComposition()
    local ctx = ns.Engine:BuildPlayerContext()
    ctx.have, ctx.needs = composition.have, composition.needs
    ctx.missing = composition.missing
    ctx.dungeon = ns.CurrentDungeon()

    local inGroup = IsInGroup()
    local intents = {}

    if not inGroup then
        intents[#intents + 1] = { "LFG", "SOLO", "Looking for a group" }
        intents[#intents + 1] = { "LFG", "OFFER", "Answer a listing" }

        -- Offering yourself is not the same as forming a group, and until now
        -- the only advert available said what you are without saying what you
        -- would be doing. The role is the first thing anyone reads for.
        local ROLE_SOLO = {
            { "TANK",    "SOLO_TANK",   "Looking, as a tank"   },
            { "HEALER",  "SOLO_HEALER", "Looking, as a healer" },
            { "DAMAGER", "SOLO_DPS",    "Looking, as damage"   },
        }
        local added = false
        for _, role in ipairs(ROLE_SOLO) do
            if ns.CanFillRole(role[1]) then
                if not added then
                    intents[#intents + 1] = ns.SEP
                    added = true
                end
                intents[#intents + 1] = { "LFG", role[2], role[3] }
            end
        end
    else
        -- What is worth asking for is yours to say: the classes in a group are
        -- known, but who is actually tanking or healing is not.
        intents[#intents + 1] = { "LFG", "NEED_MORE",   "Fill the group" }
        intents[#intents + 1] = ns.SEP
        intents[#intents + 1] = { "LFG", "NEED_TANK",   "Ask for a tank" }
        intents[#intents + 1] = { "LFG", "NEED_HEALER", "Ask for a healer" }
        intents[#intents + 1] = { "LFG", "NEED_DPS",    "Ask for damage" }

    end

    local channels = { TO_LFG }
    if IsInGuild and IsInGuild() then channels[#channels + 1] = TO_GUILD end
    channels[#channels + 1] = SAY_ALOUD
    if inGroup then channels[#channels + 1] = TO_PARTY end

    -- Which dungeon the advert names. Without one it reads "LFG anything",
    -- which is honest but finds nobody, so the nearest few to your level are
    -- offered right here rather than hidden in a settings panel.
    intents[#intents + 1] = ns.SEP
    for _, dungeon in ipairs(ns.NearbyDungeons(ctx.level, 5)) do
        local current = (ctx.dungeon == dungeon.name)
        intents[#intents + 1] = {
            setDungeon = dungeon.name,
            label = (current and "> " or "") .. dungeon.name,
        }
    end

    return {
        key      = "GROUP:" .. tostring(ctx.dungeon) .. ":" .. tostring(inGroup),
        title    = "Looking for a group",
        subtitle = inGroup and (composition.size .. " of 5") or "On your own",
        intents  = intents,
        ctx      = ctx,
        channels = channels,
    }
end

-- Is this name on your guild roster? Decides whether answering them in guild
-- chat is even offered.
local function isGuildmate(name)
    if not name or not IsInGuild or not IsInGuild() then return false end
    if not GetNumGuildMembers or not GetGuildRosterInfo then return false end
    for i = 1, (GetNumGuildMembers() or 0) do
        if GetGuildRosterInfo(i) == name then return true end
    end
    return false
end

local IN_GUILD = { key = "GUILD", label = "Guild",
                   hint = "Everyone in the guild reads it, them included." }

-- One person, reached by name rather than by a frame. This is what the whisper
-- window speaks through.
--
-- Two things are deliberately missing. There is no Say and no Yell: the point
-- of this context is that the person is somewhere else, and shouting into your
-- own room reaches nobody who matters. And there is no gesture -- a bow aimed
-- at someone who is not on your screen plays to an empty room, so the whole
-- emote row is switched off rather than left on to mislead.
function Contexts:Whisper(name, bnetID)
    if not name or name == "" then return nil end

    local list = {}
    for _, pair in ipairs(ns.ResolveMenu("WHISPER", ns.WHISPER_INTENTS)) do
        if pair == ns.SEP then
            list[#list + 1] = ns.SEP
        elseif ns.Engine:HasAnyPhrase("WHISPER", pair[1]) then
            list[#list + 1] = { "WHISPER", pair[1], pair[2] }
        end
    end

    local channels
    if bnetID then
        channels = { { key = "BN_WHISPER", label = "Whisper",
                       hint = "Reaches " .. name .. " wherever they are, on any character." } }
    else
        channels = { { key = "WHISPER", label = "Whisper",
                       hint = "Only " .. name .. " reads it." } }
    end
    -- Addressing a guildmate by name in guild chat is a normal thing to do, and
    -- the line already carries their name either way. The channel only decides
    -- who else hears it. A Battle.net account is nobody's guildmate.
    if not bnetID and isGuildmate(name) then channels[#channels + 1] = IN_GUILD end

    local info = ns.IdentifyPlayer and ns.IdentifyPlayer(name)
    local subtitle
    if info then
        subtitle = ((info.raceName or "") .. " " .. (info.className or "")):gsub("^%s+", "")
        if subtitle == "" then subtitle = nil end
    end

    return {
        key       = "WHISPER:" .. (bnetID and ("bn:" .. bnetID) or name),
        title     = name,
        subtitle  = subtitle,
        intents   = list,
        ctx       = { name = name },
        recipient = bnetID or name,
        channels  = channels,
        noEmote   = true,
    }
end

-- One of the four categories hanging off your own portrait.
function Contexts:Player(tabKey)
    local category, intents
    if tabKey == "CLASS" then
        category = ns.Engine:GetPlayerClass()
        intents = category and ns.CLASS_INTENTS[category]
    elseif tabKey == "FACTION" then
        category = ns.Engine:GetPlayerFaction()
        intents = category and ns.FACTION_INTENTS[category]
    else
        category = tabKey
        intents = ns.INTENTS[tabKey]
    end
    if not intents then return nil end

    local list = {}
    for _, pair in ipairs(intents) do
        if pair == ns.SEP then
            list[#list + 1] = ns.SEP
        elseif ns.Engine:HasAnyPhrase(category, pair[1]) then
            list[#list + 1] = { category, pair[1], pair[2] }
        end
    end

    local label = (tabKey == "CLASS" or tabKey == "FACTION")
        and ns.Titlecase(category) or ns.Titlecase(tabKey)

    return {
        key      = "PLAYER:" .. tabKey,
        title    = UnitName("player") or "",
        subtitle = label,
        intents  = list,
        ctx      = nil,
        channels = leadWithParty({ SAY_ALOUD, YELL }),
    }
end

-- One member of your group.
function Contexts:PartyMember(unit)
    local ctx = ns.Engine:BuildUnitContext(unit)
    if not ctx then return nil end

    local list = {}
    for _, pair in ipairs(ns.ResolveMenu("PERSON", ns.PERSON_INTENTS)) do
        list[#list + 1] = (pair == ns.SEP) and ns.SEP or { "PERSON", pair[1], pair[2] }
    end
    if ctx.classToken == "WARLOCK" then
        for _, pair in ipairs(ns.PERSON_WARLOCK_EXTRA) do
            list[#list + 1] = { "PERSON", pair[1], pair[2] }
        end
    end

    local name = ctx.name
    return {
        key         = "PARTY:" .. tostring(name),
        title       = name,
        subtitle    = ((ctx.raceName or "") .. " " .. (ctx.className or "")):gsub("^%s+", ""),
        intents     = list,
        ctx         = ctx,
        recipient   = name,
        emoteTarget = name,
        channels    = { TO_PARTY, SAY_ALOUD, WHISPER },
        -- Unit ids shift when someone leaves; the name does not.
        rebuild     = function()
            for _, candidate in ipairs(ns.GroupUnits()) do
                if UnitName(candidate) == name then
                    return ns.Engine:BuildUnitContext(candidate)
                end
            end
        end,
    }
end

-- The group as a whole: ready, boss, wipe, and the rest.
function Contexts:PartyAll()
    local list = {}
    for _, pair in ipairs(ns.ResolveMenu("PARTY_ALL", ns.PartyEveryoneIntents())) do
        if pair == ns.SEP then
            list[#list + 1] = ns.SEP
        elseif ns.Engine:HasAnyPhrase("PARTY", pair[1]) then
            list[#list + 1] = { "PARTY", pair[1], pair[2] }
        end
    end

    return {
        key      = "PARTY:ALL",
        title    = "Everyone",
        subtitle = "Your group",
        intents  = list,
        ctx      = nil,
        channels = { TO_PARTY, SAY_ALOUD },
    }
end
