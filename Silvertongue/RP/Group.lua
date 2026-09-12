-- Group.lua -- looking for a group, and looking for people to fill one.
--
-- These go out on the LookingForGroup channel, where the whole server reads
-- them. That is exactly why they are written in character: "Rogue 36 LF Scarlet"
-- is a classified ad, and one more of those is worth nothing. Someone who reads
-- "An orc who fights from shadows looks for work" remembers it.
--
-- {have} lists the classes already in the group and {needs} how many seats are
-- open. Both are counted, not guessed -- the line never claims a role nobody
-- said they were playing.

local ADDON, ns = ...

-- Which roles a class could plausibly offer in this expansion. Specs are not
-- readable, so this is about what you *could* do and you are the one choosing
-- to say it. Shared, because advertising yourself and answering someone else's
-- listing have to agree about this.
ns.ROLE_CLASSES = {
    TANK   = { WARRIOR = true, DRUID = true, PALADIN = true },
    HEALER = { PRIEST = true, DRUID = true, PALADIN = true, SHAMAN = true },
}

function ns.CanFillRole(role)
    if role == "DAMAGER" then return true end
    local _, classToken = UnitClass("player")
    return classToken ~= nil and ns.ROLE_CLASSES[role] ~= nil
        and ns.ROLE_CLASSES[role][classToken] == true
end
ns.Phrases = ns.Phrases or {}

ns.Phrases.LFG = {
    -- Alone, looking for anyone who will have you.
    SOLO = {
        "LFG {dungeon} -- {race} {class}, {level}. Ready when you are.",
        "LFG {dungeon}. A {race} {class} with time on his hands and nothing to kill.",
        "LFG {dungeon} -- {level} {race} {class}. I do not complain and I do not ninja.",
        "LFG {dungeon}. {race} {class}, {level}. Point me at it and I will fight it.",
        "LFG {dungeon} -- {race} {class} {level}, in no mood to stand around.",
        "LFG {dungeon}. I am {name}, a {race} {class} of {level} winters, and I would rather be fighting.",
        "LFG {dungeon} -- {level} {race} {class}. I know the way and I know when to run.",
    },

    -- You have a group with room in it.
    -- The same advert with the one word that makes it useful. "Orc Shaman, 36"
    -- does not tell anybody whether you are offering to heal or to hit things,
    -- and that is the first thing a group leader reads for.
    SOLO_TANK = {
        "LFG {dungeon} -- {level} {race} {class}, happy to tank. I hold what I pull.",
        "LFG {dungeon}. {race} {class}, {level}, tanking. Put me at the front and keep up.",
        "LFG {dungeon} -- tank available. {level} {race} {class}, and I do not lose threat.",
        "LFG {dungeon}, tanking. {race} {class}, {level}. I know the pulls.",
        "LFG {dungeon} as tank -- {level} {race} {class}. Bring a healer who pays attention.",
    },

    SOLO_HEALER = {
        "LFG {dungeon} -- {level} {race} {class}, healing. I will keep you upright.",
        "LFG {dungeon}. {race} {class}, {level}, happy to heal. Do not stand in things.",
        "LFG {dungeon}, healing. {level} {race} {class}, and I watch the whole group.",
        "LFG {dungeon} as healer -- {race} {class}, {level}. I have mana and patience.",
        "LFG {dungeon}, healing. {level} {race} {class}. Pull carefully and nobody dies.",
    },

    SOLO_DPS = {
        "LFG {dungeon} -- {level} {race} {class}, damage. Point me at it.",
        "LFG {dungeon}. {race} {class}, {level}, dps. I kill what the tank tells me to.",
        "LFG {dungeon} as dps -- {level} {race} {class}. I wait for threat like a civilised person.",
        "LFG {dungeon}, damage. {race} {class}, {level}, ready now.",
        "LFG {dungeon} -- {level} {race} {class}, dps and no fuss.",
    },

    -- The same asks, for when the listing holds only you. The ones below recite
    -- what the group has, which reads as a lie when the group is one person:
    -- "need a tank, we have 1 dps" is a roster of yourself.
    NEED_MORE_SOLO = {
        "LFM {dungeon}. It is just me so far -- everything is open.",
        "LFM {dungeon}, starting from nothing. Whisper me and we build it.",
        "LFM {dungeon} -- I have the listing and nobody in it yet. Come and fix that.",
        "LFM {dungeon}. First one in picks the pace.",
        "LFM {dungeon}, all four places open. I am not fussy.",
    },

    NEED_TANK_SOLO = {
        "LFM {dungeon} -- need a tank. I will build the rest around you.",
        "LFM {dungeon}, tank wanted first. Everything else follows.",
        "LFM {dungeon} -- looking for a tank to start with. Whisper me.",
        "LFM {dungeon}. Give me a tank and I will find the rest.",
        "LFM {dungeon} -- a tank and this group happens.",
    },

    NEED_HEALER_SOLO = {
        "LFM {dungeon} -- need a healer. I will build the rest around you.",
        "LFM {dungeon}, healer wanted first. The rest is easy to find.",
        "LFM {dungeon} -- looking for a healer to start with. Whisper me.",
        "LFM {dungeon}. Give me a healer and the rest follows.",
        "LFM {dungeon} -- a healer and we are halfway there.",
    },

    NEED_DPS_SOLO = {
        "LFM {dungeon} -- need damage. Whisper me.",
        "LFM {dungeon}, looking for damage to start with.",
        "LFM {dungeon} -- damage wanted. I am building this from scratch.",
        "LFM {dungeon}. Damage first, the rest as it comes.",
        "LFM {dungeon} -- room for damage. Say the word and you are in.",
    },

    NEED_MORE = {
        "LFM {dungeon}, need {missing} -- we have {have}.",
        "LFM {dungeon}. {have} so far, still need {missing}. Who is coming?",
        "LFM {dungeon}, short {missing}. We have {have} and we are not waiting all night.",
        "LFM {dungeon} -- need {missing}. Currently {have}. Whisper me.",
        "LFM {dungeon}: {have}. Looking for {missing}.",
        "LFM {dungeon}, {missing} and we go. We have {have}.",
    },

    NEED_TANK = {
        "LFM {dungeon}, need a tank -- we have {have}.",
        "LFM {dungeon}. Looking for a tank -- someone who can hold a line. {have} so far.",
        "LFM {dungeon} -- tank wanted. The rest of us are {have} and none of us want the job.",
        "LFM {dungeon}, need a tank. {have} behind you, and we will keep you standing.",
        "LFM {dungeon}, need a tank. We have {have}, and none of us wants to be hit.",
    },

    NEED_HEALER = {
        "LFM {dungeon}, need a healer -- we have {have}.",
        "LFM {dungeon}. Need a healer to keep us alive. Currently {have}.",
        "LFM {dungeon} -- healer wanted. We are {have}, and we bleed like anyone else.",
        "LFM {dungeon}, one healer and we are away. We have {have}.",
        "LFM {dungeon}, need a healer. {have} so far, and nobody who can mend us.",
    },

    NEED_DPS = {
        "LFM {dungeon}, need {needs} dps -- we have {have}.",
        "LFM {dungeon}. Need {needs} dps. {have} already here.",
        "LFM {dungeon} -- room for {needs} dps who can kill quickly. We are {have}.",
        "LFM {dungeon}, {needs} dps. {have} so far. Bring a weapon and know how to use it.",
        "LFM {dungeon}, {needs} dps. Two hands and a sharp edge, that is all we ask.",
    },

    -- Answering someone else's listing.
    OFFER = {
        "{race} {class}, {level}, for {dungeon}. I saw you are short and I am free.",
        "I can fill that place for {dungeon}. {race} {class}, level {level}.",
        "You need someone for {dungeon}. I am a {level} {race} {class} and I am here.",
        "I will take that spot for {dungeon} if it is still open. {race} {class}, {level}.",
        "A {race} {class} at your service for {dungeon}, if you will have him. Level {level}.",
    },

    -- Offering for the exact role a listing is short of. The game publishes
    -- which slots are empty, so there is no reason to ask.
    OFFER_TANK = {
        "You need a tank for {dungeon}. I will take the hits. {race} {class}, {level}.",
        "{dungeon} -- I can tank it. Level {level} {race} {class}.",
        "I will stand in front for {dungeon}. {level} {race} {class}, and I do not run.",
        "Tank here for {dungeon}. {race} {class}, {level}. Put me at the door.",
        "You are short a tank for {dungeon}. I am a {level} {race} {class} and that is my job.",
    },

    OFFER_HEALER = {
        "You need a healer for {dungeon}. I will keep you standing. {race} {class}, {level}.",
        "{dungeon} -- I can heal it. Level {level} {race} {class}.",
        "Healer here for {dungeon}. {race} {class}, {level}. Try not to make it hard.",
        "I will mend you through {dungeon}. {level} {race} {class}.",
        "You are short a healer for {dungeon}. That is what I do. {race} {class}, {level}.",
    },

    OFFER_DPS = {
        "You need damage for {dungeon}. {race} {class}, {level}, and a sharp one.",
        "{dungeon} -- I will kill things. Level {level} {race} {class}.",
        "Damage here for {dungeon}. {race} {class}, {level}.",
        "I hit hard and I stand out of the fire. {level} {race} {class}, for {dungeon}.",
        "You have a place for damage in {dungeon}. I am a {level} {race} {class} and I will fill it.",
    },

    -- Closing an advert you placed in the channel. No menu offers this any
    -- more -- delisting is what people actually do -- but the lines are kept:
    -- they are reachable from the library, and someone may want the row back.
    FULL = {
        "{dungeon} group is full. Good hunting to the rest of you.",
        "{dungeon}: closed. Thank you to everyone who spoke up.",
        "We have what we need for {dungeon}. Off we go.",
        "Full up for {dungeon}. Try me again another night.",
        "We have our five for {dungeon}. Good hunting.",
    },
}
