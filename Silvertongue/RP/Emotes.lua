-- Emotes.lua -- the gesture that goes with a line.
--
-- A WoW emote is not just text: it plays the animation too, and DoEmote takes a
-- target, so a directed line reads as "Gromkar bows before Grumgar" rather
-- than the generic form. For roleplay that is worth more than the sentence.
--
-- This file loads after every phrase file, because it walks them.

local ADDON, ns = ...

ns.Emotes = ns.Emotes or {}

-- Offered in the library window, in this order. Curated rather than complete:
-- the client has about a hundred and a list that long cannot be navigated.
-- Adding one is a line here and nothing else.
ns.EMOTE_LIST = {
    "NONE",
    "BOW", "SALUTE", "KNEEL", "NOD", "WAVE", "GREET", "WELCOME", "FAREWELL",
    "THANK", "APOLOGIZE", "CONGRATULATE", "APPLAUD", "CHEER", "VICTORY",
    "LAUGH", "CHUCKLE", "SMILE", "YES", "NO", "SHRUG", "SIGH", "POINT",
    "FLEX", "ROAR", "CHARGE", "THREATEN", "GLARE", "STARE", "RUDE",
    "MOURN", "PRAY", "TALK",
}

ns.EMOTE_NONE = "NONE"

function ns.EmoteLabel(token)
    if not token or token == ns.EMOTE_NONE then return "No gesture" end
    return ns.Titlecase(token)
end

-- The gesture an intent takes unless a line says otherwise. Most of the value
-- lives here: setting Thanks once covers every phrase under it.
ns.Emotes.BY_INTENT = {
    HELLO            = "GREET",
    GOODBYE          = "FAREWELL",
    THANKS           = "THANK",
    THANK            = "THANK",
    APOLOGIZE        = "APOLOGIZE",
    CONGRATULATE     = "CONGRATULATE",
    RESPECT          = "SALUTE",
    HONOR            = "SALUTE",
    LAUGH            = "LAUGH",
    AGREE            = "YES",
    DISAGREE         = "NO",
    VICTORY          = "CHEER",
    GOOD_JOB         = "APPLAUD",
    PRAISE           = "APPLAUD",
    ENCOURAGE        = "CHEER",
    CONFUSED         = "SHRUG",
    DISAPPOINTED     = "SIGH",
    IMPRESSED        = "APPLAUD",
    MOCK             = "RUDE",
    THREATEN         = "THREATEN",
    ANGRY            = "GLARE",
    SUSPICIOUS       = "STARE",
    BATTLE_CRY       = "ROAR",
    FOR_THE_HORDE    = "ROAR",
    FOR_THE_ALLIANCE = "CHARGE",
    LOKTAR           = "ROAR",
    RALLY            = "CHARGE",
    ANCESTORS        = "PRAY",
    BLESSING         = "PRAY",
    ENEMY_CHALLENGE  = "POINT",
    ENEMY_TAUNT      = "RUDE",
    ENEMY_MOCK       = "RUDE",
    ENEMY_RESPECT    = "SALUTE",
    ENEMY_VICTORY    = "FLEX",
    -- Deliberately left without a gesture: WARN, WIPE, MANA, SCOUT, WAIT and
    -- the rest read worse with one.
}

-- Gestures a single line asks for, overriding its intent. Filled by the walk
-- below, keyed by the line itself so a phrase stays a plain string everywhere
-- else in the addon -- favorites, hiding and your own lines all index by text.
ns.Emotes.BY_TEXT = {}

-- Phrase files may write a line as a bare string or as { "text", emote = "BOW" }.
-- Flatten the second form so everything downstream sees strings.
local function normalize(pool)
    for i, line in ipairs(pool) do
        if type(line) == "table" then
            local text = line[1]
            if line.emote then ns.Emotes.BY_TEXT[text] = line.emote end
            pool[i] = text
        end
    end
end

local function walk(node, depth)
    if depth > 4 then return end
    for key, value in pairs(node) do
        if type(value) == "table" and key ~= "replace" then
            if type(value[1]) ~= "nil" then
                normalize(value)
            else
                walk(value, depth + 1)
            end
        end
    end
end

function ns.NormalizePhrases()
    ns.Emotes.BY_TEXT = {}
    for category, pools in pairs(ns.Phrases) do
        if category ~= "SELF" then
            walk(pools, 1)
        else
            walk(pools, 0)
        end
    end
end

ns.NormalizePhrases()
