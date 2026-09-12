-- Alliance.lua -- the faction tab for an Alliance character.
--
-- A seed, not a finished voice. The Horde set in RP/Horde.lua is the model for
-- how full this should eventually be; this exists so the faction tab works the
-- day someone rolls Alliance, and so there is somewhere obvious to put lines as
-- they get written. Intents with no lines simply show no button.

local ADDON, ns = ...
ns.Phrases = ns.Phrases or {}

ns.Phrases.ALLIANCE = {
    FOR_THE_ALLIANCE = {
        "For the Alliance!",
        "For the Alliance, and everyone still standing behind it!",
        "Let them remember who held this ground. For the Alliance!",
        "For the Alliance! Say it like you mean it!",
        "For Stormwind, for Ironforge, for every hall still standing. For the Alliance!",
    },

    RALLY = {
        "Hold the line!",
        "Stand together or fall apart. Choose.",
        "On me! We are not finished!",
        "Steady. We have held worse than this.",
        "Back to your feet. We are not done here.",
    },

    VICTORY = {
        "Victory to the Alliance!",
        "We stood. They did not.",
        "It is done. Well fought, all of you.",
        "Let them count their dead. We will count ours later.",
        "Another day the Alliance does not fall.",
    },

    HONOR = {
        "Honor is not a word. It is what you do when it costs you.",
        "Fight with honor or do not fight beside me.",
        "We are judged by how we win, not only that we did.",
        "Honor first. Then victory. In that order, always.",
        "An soldier without honor is just a threat with a uniform.",
    },

    LEADER = {
        "The regent holds Stormwind together. That is no small thing.",
        "I follow those who lead from the front. Few of them do.",
        "Our leaders are not perfect. They are still ours.",
        "I did not swear to a person. I swore to what they protect.",
        "Command asks a great deal. So far it has been worth giving.",
    },

    CAPITAL = {
        "Stormwind stands because we stand. Simple as that.",
        "Ironforge has never fallen. Let us keep that true.",
        "When I am far from home, I think of the trade district at dusk.",
        "Darnassus is beautiful and I will never be comfortable there.",
        "Home is a city with walls. Everything else is a road back to it.",
    },

    PRIDE = {
        "Human, dwarf, elf, gnome, draenei. We chose each other.",
        "I have no shame in what I am. None.",
        "We were scattered once. Look at us now.",
        "The Alliance is not a banner. It is a promise we keep.",
        "I am Alliance. That is not decoration.",
    },

    BATTLE_CRY = {
        "For the Light! Forward!",
        "Let them come! I have been waiting!",
        "Today is a good day. Someone is about to disagree.",
        "Blades up! Now!",
        "Hold nothing back! Go!",
    },
}
