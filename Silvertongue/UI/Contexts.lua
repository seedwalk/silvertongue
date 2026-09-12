-- Contexts.lua -- what each control puts in its board.
--
-- A context answers three questions and nothing else: who you are speaking to,
-- what you can say to them, and how it can go out. The boards render it and the
-- display sends it; neither decides any of this.
--
-- The channel rule: you never pick one. You clicked in the party, so it goes to
-- the party. The primary button always says "Say" and its tooltip tells the
-- truth about where that lands. Only genuinely different intents -- yell at
-- everyone, whisper privately -- get a button of their own.

local ADDON, ns = ...

local Contexts = {}
ns.Contexts = Contexts

local SAY_TO_PARTY = { key = "PARTY", label = "Say", hint = "Goes to party chat." }
local SAY_ALOUD    = { key = "SAY",   label = "Say", hint = "Everyone nearby hears it." }
local YELL         = { key = "YELL",  label = "Yell", hint = "Heard far past the room." }
local WHISPER      = { key = "WHISPER", label = "Whisper", hint = "Only they read it." }
local TO_PARTY     = { key = "PARTY", label = "Party", hint = "Goes to party chat, wherever they are." }

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

    local channels = { SAY_ALOUD }
    if grouped then
        -- They may be across the dungeon, where saying it aloud reaches nobody.
        channels[#channels + 1] = TO_PARTY
    else
        channels[#channels + 1] = YELL
    end
    if info.isPlayer and not info.hostile then
        channels[#channels + 1] = WHISPER
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
        grouped     = grouped,
        isPlayer    = info.isPlayer,
        hostile     = info.hostile,
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
    ctx.dungeon = ns.CurrentDungeon()

    local inGroup = IsInGroup()
    local intents = {}

    if not inGroup then
        intents[#intents + 1] = { "LFG", "SOLO", "Looking for a group" }
        intents[#intents + 1] = { "LFG", "OFFER", "Answer a listing" }
    else
        -- What is worth asking for is yours to say: the classes in a group are
        -- known, but who is actually tanking or healing is not.
        intents[#intents + 1] = { "LFG", "NEED_MORE",   "Need " .. composition.needs .. " more" }
        intents[#intents + 1] = ns.SEP
        intents[#intents + 1] = { "LFG", "NEED_TANK",   "Need a tank" }
        intents[#intents + 1] = { "LFG", "NEED_HEALER", "Need a healer" }
        intents[#intents + 1] = { "LFG", "NEED_DPS",    "Need damage" }
        intents[#intents + 1] = ns.SEP
        intents[#intents + 1] = { "LFG", "FULL",        "We are full" }
    end

    local channels = { TO_LFG }
    if IsInGuild and IsInGuild() then channels[#channels + 1] = TO_GUILD end
    channels[#channels + 1] = SAY_ALOUD
    if inGroup then channels[#channels + 1] = SAY_TO_PARTY end

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
        channels = { SAY_ALOUD, YELL },
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
        channels    = { SAY_TO_PARTY, SAY_ALOUD, WHISPER },
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
        channels = { SAY_TO_PARTY, SAY_ALOUD },
    }
end
