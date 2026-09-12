-- Hunter.lua -- the class tab for a hunter.
--
-- Quiet competence and a companion. Where a warrior fills a doorway, a hunter
-- has already looked through it.

local ADDON, ns = ...
ns.Phrases = ns.Phrases or {}

ns.Phrases.HUNTER = {
    BEAST = {
        "He knows the plan. He usually likes it more than I do.",
        "We hunt together. That is the whole arrangement and it works.",
        "Do not feed him. He is eating well enough.",
        "He was wild once. So was I.",
        "If he does not like you, I would think about why.",
        "He goes first. Not because he is expendable -- because he is faster.",
    },

    TRACKING = {
        "They came through here. Recently, and in a hurry.",
        "Three of them, and one is hurt.",
        "The ground remembers everything if you bother to look down.",
        "This trail is cold. Someone wanted it that way.",
        "I can follow that. Give me a moment.",
        "They went east. They will regret it.",
    },

    THE_SHOT = {
        "One arrow. One less problem.",
        "I had the shot. I took it. There is not much more to say.",
        "Breathe out, then loose. Everything else is decoration.",
        "Distance is a weapon. I use it.",
        "He never saw where it came from. That was the idea.",
    },

    TRAPS = {
        "Do not step there.",
        "Something is going to have a very bad moment shortly.",
        "I have prepared the ground. Push them onto it.",
        "A trap is patience made useful.",
        "Mind where you walk. I have been busy.",
    },

    WILDS = {
        "I sleep better outside. Walls make me uneasy.",
        "The wild does not forgive, but it does not lie either.",
        "Everything out here is trying to eat something. It is honest work.",
        "I know this country. It is why I am here.",
        "Give me a treeline and I will give you an advantage.",
    },

    PATIENCE = {
        "Wait. The moment is coming.",
        "I have sat still longer than this for worse quarry.",
        "Rushing a hunt is how you become part of one.",
        "Hold. Let them come to us.",
        "The good shot is always a little later than you want it.",
    },

    SCOUT = {
        "I will go ahead. Do not follow until I say.",
        "Let me look. I am quieter than all of you together.",
        "Give me a minute and I will tell you what is waiting.",
        "There is another way in. There usually is.",
        "I have seen it. You are not going to enjoy this.",
    },

    HONOR = {
        "I kill what needs killing and I eat what I kill.",
        "A clean shot is a kindness. A bad one is carelessness.",
        "I do not hunt for sport. That is a sickness, not a craft.",
        "Respect the animal or leave it alone.",
        "Take only what you came for.",
    },

    LUCK = {
        "Straight arrows, friend.",
        "May you see them first.",
        "Good hunting. Bring something back.",
        "Keep downwind and keep quiet.",
        "May your quarry be slow and your aim be not.",
    },

    WARNING = {
        "Stop. Something is watching us.",
        "There are more of them than we were told.",
        "I do not like this ground. Too open, or not open enough.",
        "Wait. Listen. The birds have stopped.",
        "Back away slowly. Do not turn around.",
    },
}
