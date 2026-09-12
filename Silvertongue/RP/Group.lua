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
    NEED_MORE = {
        "LFM {dungeon}, need {needs} -- we have {have}.",
        "LFM {dungeon}. {have} so far, {needs} places left. Who is coming?",
        "LFM {dungeon}, {needs} short. We have {have} and we are not waiting all night.",
        "LFM {dungeon} -- need {needs}. Currently {have}. Whisper me.",
        "LFM {dungeon}: {have}. Room for {needs} more.",
        "LFM {dungeon}, {needs} more and we go. We have {have}.",
    },

    NEED_TANK = {
        "LFM {dungeon}, need a tank -- we have {have}.",
        "LFM {dungeon}. Looking for someone who can hold a line. {have} so far.",
        "LFM {dungeon} -- tank wanted. The rest of us are {have} and none of us want the job.",
        "LFM {dungeon}, need a tank. {have} behind you, and we will keep you standing.",
        "LFM {dungeon}. We have {have}. What we do not have is anyone willing to be hit.",
    },

    NEED_HEALER = {
        "LFM {dungeon}, need a healer -- we have {have}.",
        "LFM {dungeon}. Need someone to keep us alive. Currently {have}.",
        "LFM {dungeon} -- healer wanted. We are {have}, and we bleed like anyone else.",
        "LFM {dungeon}, one healer and we are away. We have {have}.",
        "LFM {dungeon}. {have} so far, and nobody who can mend us. That seems unwise.",
    },

    NEED_DPS = {
        "LFM {dungeon}, need {needs} dps -- we have {have}.",
        "LFM {dungeon}. Need someone who hits things. {have} already here.",
        "LFM {dungeon} -- room for {needs} who can kill quickly. We are {have}.",
        "LFM {dungeon}, {needs} dps. {have} so far. Bring a weapon and know how to use it.",
        "LFM {dungeon}. Two hands and a sharp edge, that is all we ask. {needs} places.",
    },

    -- Answering someone else's listing.
    OFFER = {
        "{race} {class}, {level}, for {dungeon}. I saw you are short and I am free.",
        "I can fill that place for {dungeon}. {race} {class}, level {level}.",
        "You need someone for {dungeon}. I am a {level} {race} {class} and I am here.",
        "I will take that spot for {dungeon} if it is still open. {race} {class}, {level}.",
        "A {race} {class} at your service for {dungeon}, if you will have him. Level {level}.",
    },

    -- The group is full and moving.
    FULL = {
        "{dungeon} group is full. Good hunting to the rest of you.",
        "{dungeon}: closed. Thank you to everyone who spoke up.",
        "We have what we need for {dungeon}. Off we go.",
        "Full up for {dungeon}. Try me again another night.",
        "We have our five for {dungeon}. Good hunting.",
    },
}
