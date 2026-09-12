-- Races.lua -- race-flavored phrases. These supplement the generic pools,
-- they never replace them. Keys are UnitRace tokens, uppercased.

local ADDON, ns = ...
ns.Phrases = ns.Phrases or {}

ns.Phrases.RACE = {
    ORC = {
        RESPECT = {
            "Strength and honor, brother.",
            "{name}, we carry the same history. Let us carry it well.",
            "An orc who fights with honor, {name}. That is the whole point of us.",
        },
        PRAISE = {
            "That was orcish work, {name}. The good kind.",
            "{name}, our ancestors saw that and they were pleased.",
        },
        JOKE = {
            "{name}, you are almost as stubborn as I am. Almost.",
        },
    },

    TROLL = {
        RESPECT = {
            "The Darkspear stand with the Horde. So do I, {name}.",
            "{name}, your people gave us a home when we had none. I have not forgotten.",
            "There is old strength in the Darkspear, {name}. I see it in you.",
        },
        PRAISE = {
            "{name}, your loa and my spirits seem to be getting along today.",
        },
        JOKE = {
            "{name}, I still do not understand your jokes. I laugh anyway.",
        },
    },

    TAUREN = {
        RESPECT = {
            "Your people have stood beside mine when we needed friends. You have my respect, {name}.",
            "{name}, the tauren taught the orcs how to listen again. That debt is not small.",
            "There is no steadier ally than a tauren, {name}. None.",
            "Earth Mother keep you, {name}. I mean it sincerely.",
        },
        PRAISE = {
            "{name}, you fight the way the earth moves. Slowly, then all at once.",
        },
        JOKE = {
            "{name}, you are the calmest person here and I find that suspicious.",
        },
    },

    SCOURGE = {
        RESPECT = {
            "You fight well, {name}. Whatever else we may disagree on, I respect that.",
            "{name}, the spirits have nothing to say about you. I have decided that is not your fault.",
            "You chose the Horde, {name}. That choice counts for something with me.",
        },
        PRAISE = {
            "That was cold work, {name}. Effective, but cold.",
        },
        WARN = {
            "{name}, whatever your Queen wants, we are in this fight together today.",
        },
    },

    BLOODELF = {
        RESPECT = {
            "You have lost a great deal, {name}. So did we. That is a kind of kinship.",
            "{name}, you fight for the Horde. That is what I judge you by.",
        },
        PRAISE = {
            "Elegant, {name}. I would not fight that way, but it worked.",
        },
        WARN = {
            "{name}, be careful what you draw that power from. My people learned that lesson badly.",
        },
        JOKE = {
            "{name}, you look far too clean for a dungeon.",
        },
    },
}
