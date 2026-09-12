-- Whisper.lua -- what you say to one person, privately.
--
-- The person-directed pool that already existed (PERSON: thank, praise, warn,
-- apologize) was written for a party in a dungeon: it answers things people DO.
-- A whisper answers things people ASK. "Can you make me one", "where are you",
-- "are you coming" -- none of which had a line anywhere in the addon.
--
-- Lines use {name} and nothing else. That is not an oversight: of someone who
-- whispers you, the game tells you their name and not one thing more. No class,
-- no race, no level. Anything here that leaned on those would read as "a {race}
-- {class}" half the time, which is worse than not saying it.
--
-- FAVOUR is the one worth explaining. It answers "can you do the thing your
-- class does" -- a portal, a summon, a lock -- and the shared lines below are
-- deliberately vague about what the thing is, because the class layers in
-- Self.lua say it properly for the classes people actually pester.

local ADDON, ns = ...
ns.Phrases = ns.Phrases or {}

ns.Phrases.WHISPER = {
    HELLO = {
        "{name}. You have my attention.",
        "Well met, {name}. Speak.",
        "{name}. Good to hear from you.",
        "Yes, {name}?",
        "{name}. It has been a while.",
        "Go on, {name}. I am listening.",
    },

    COMING = {
        "On my way, {name}.",
        "Coming. Give me a moment to get there.",
        "I am moving, {name}. Do not start without me.",
        "Say where and I will be there.",
        "Already walking, {name}.",
        "Coming. I am closer than you think.",
    },

    WAIT = {
        "A moment, {name}. I am in the middle of something.",
        "Hold on. I will be free shortly.",
        "Give me a minute, {name}, and then I am yours.",
        "Not this second. Soon.",
        "{name}, wait for me. I have not forgotten.",
        "Two minutes. I am finishing something I would rather not restart.",
    },

    BUSY = {
        "Not now, {name}. I am in the middle of a fight.",
        "I cannot, {name}. Another time and gladly.",
        "Sorry, {name}. My hands are full.",
        "Ask me later and the answer will be yes.",
        "{name}, I would if I could. I cannot.",
        "Not today, {name}. I am already committed to something foolish.",
    },

    WHERE = {
        "Where are you, {name}?",
        "{name}, tell me where and I will find you.",
        "I do not see you. Where should I be?",
        "Name the place, {name}.",
        "Where am I meeting you?",
    },

    FAVOUR = {
        "I can do that, {name}. Where are you?",
        "Yes. Come to me, or tell me where to stand.",
        "That I can manage, {name}. Give me a moment.",
        "Consider it done. I only need you next to me.",
        "Easily done, {name}. Say where.",
    },

    THANK = {
        "That was decent of you, {name}. Thank you.",
        "My thanks, {name}. I will remember it.",
        "You did not have to do that, {name}. I noticed that you did.",
        "Thank you, {name}. Ask me for something one day.",
        "I owe you, {name}. I pay what I owe.",
    },

    SORRY = {
        "That was my fault, {name}. I say so plainly.",
        "My apologies, {name}. I should have been quicker.",
        "I was wrong, {name}. It will not happen twice.",
        "Sorry, {name}. No excuse worth your time.",
    },

    FAREWELL = {
        "Until next time, {name}.",
        "Go well, {name}.",
        "I am logging off, {name}. It was good to talk.",
        "Safe roads, {name}.",
        "Later, {name}. Stay alive.",
    },
}

-- The menu, in the order it opens. Answering comes first because answering is
-- why the window is open at all; the pleasantries sit below a line.
ns.WHISPER_INTENTS = {
    { "COMING", "On my way" },
    { "WAIT",   "In a moment" },
    { "BUSY",   "Cannot right now" },
    { "FAVOUR", "Yes, I can do that" },
    { "WHERE",  "Where are you?" },
    ns.SEP,
    { "HELLO",    "Greet" },
    { "THANK",    "Thank" },
    { "SORRY",    "Apologize" },
    { "FAREWELL", "Farewell" },
}
