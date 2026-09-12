-- Druid.lua -- the class tab for a druid.
--
-- Written so a night elf of Cenarius and a tauren of the Earth Mother can both
-- speak it: what is said is about the balance itself, not about who taught it.

local ADDON, ns = ...
ns.Phrases = ns.Phrases or {}

ns.Phrases.DRUID = {
    SHAPES = {
        "I have been four things today and I am tired of all of them.",
        "The shape is a tool. I put it down when the work is done.",
        "You get used to claws. That is the part nobody warns you about.",
        "Give me a moment to be myself.",
        "Bear, cat, or something with wings. Pick one and I will manage.",
        "I remember being each of them. That is the strange part.",
    },

    NATURE = {
        "The wild is not gentle. It is only indifferent, which people confuse for peace.",
        "Everything here is eating something else. That is the arrangement.",
        "I do not protect nature. I am part of it, which is a harder job.",
        "Growth and rot are the same process viewed from different ends.",
        "Listen. It is saying something and it is not about us.",
    },

    BALANCE = {
        "Nothing is only one thing. Not the moon, not the sun, not me.",
        "Too much of any good is a blight.",
        "I hold two halves and neither of them wins.",
        "Balance is not a resting place. It is constant work.",
        "Push anything far enough and it becomes its opposite.",
    },

    THE_DREAM = {
        "I have slept in a place that was more real than this one.",
        "The Dream remembers the world as it should have been.",
        "Some nights I am not entirely here.",
        "There is a green world under this one. I have walked in it.",
        "You would not sleep well there. It is not restful, it is true.",
    },

    CLAWS = {
        "Teeth settle most arguments.",
        "I do not need a weapon. I grew one.",
        "Do not mistake fur for gentleness.",
        "I will open this one up. Stand clear.",
        "There is nothing civilised about the way I fight. There does not need to be.",
    },

    HEALING = {
        "Growth, not repair. It takes a moment longer and it holds.",
        "Hold still and let it knit.",
        "Life wants to continue. I am only helping it along.",
        "You will mend. Everything does, given the chance.",
        "Rest. That is also medicine, and it is free.",
    },

    PATIENCE = {
        "A tree does not hurry and it outlives all of us.",
        "Wait. Things arrive when they arrive.",
        "I have watched a season turn from one spot. This is nothing.",
        "Slow is not the same as stopped.",
        "Give it time. Most things resolve without our help.",
    },

    WILD = {
        "I sleep outside. Roofs make me restless.",
        "The road is a scar. Walk beside it.",
        "I know this country better than the people who mapped it.",
        "Out here I am not a guest.",
        "Cities are just very dense forests with worse manners.",
    },

    BLESSING = {
        "Grow well, friend.",
        "May the road be soft and the season kind.",
        "Go. The wild will not mind you passing through.",
        "Rest when you can. It is not weakness, it is sense.",
        "May you mend faster than you break.",
    },

    WARNING = {
        "This ground is sick. Something poisoned it deliberately.",
        "Stop. Nothing has grown here in a long time.",
        "The balance is broken here, and not by accident.",
        "Careful. What lives in this place should not.",
        "Do not drink that. Do not touch that. Come away.",
    },
}
