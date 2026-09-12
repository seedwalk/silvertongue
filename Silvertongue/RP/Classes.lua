-- Classes.lua -- class-flavored phrases, added on top of the generic PERSON pools.
-- Keys are the class tokens returned by UnitClass.

local ADDON, ns = ...
ns.Phrases = ns.Phrases or {}

ns.Phrases.CLASS = {
    WARRIOR = {
        PRAISE = {
            "Strong shield, {name}. Keep it between me and them.",
            "You hold the line well, {name}.",
            "A warrior who stands his ground deserves respect, {name}.",
            "Strong shield, {name}. Glad it was in front of me.",
            "{name}, you take a hit like the earth takes rain.",
        },
        THANK = {
            "You took that blow for me, {name}. I noticed.",
            "{name}, my thanks. You stood where I could not.",
        },
        JOKE = {
            "{name}, you fight like an orc. I mean that kindly.",
            "No magic, no spirits, just rage and a large weapon. I respect the simplicity, {name}.",
        },
    },

    HUNTER = {
        PRAISE = {
            "Clean shot, {name}. The wind carried it true.",
            "{name}, your beast fights as well as you do.",
            "You see things before the rest of us, {name}. Keep doing that.",
            "A steady hand, {name}. The elements favor patience.",
        },
        JOKE = {
            "{name}, your pet has better manners than most orcs I know.",
            "Feed the beast, {name}. An angry companion is a shared problem.",
        },
    },

    ROGUE = {
        PRAISE = {
            "I barely saw you fight, {name}. I suppose that means you did it well.",
            "Quick blades, {name}.",
            "You strike from shadows, {name}. Strange way to fight, but effective.",
            "{name}, the thing was dead before it knew you existed. Efficient.",
        },
        JOKE = {
            "{name}, stop appearing behind me. The spirits warn me, and it is embarrassing.",
            "One day, {name}, I will hear you coming. Not today.",
        },
        WARN = {
            "{name}, the shadows do not hide you from everything.",
        },
    },

    PRIEST = {
        PRAISE = {
            "Your faith kept us standing, {name}.",
            "Your healing honors you, {name}.",
            "{name}, we walk out of here because of you.",
            "You mend what the fight breaks, {name}. That is no small calling.",
        },
        THANK = {
            "{name}, I was nearly with the ancestors. You had other plans.",
            "My thanks, {name}. My spirit was halfway gone.",
        },
        RESPECT = {
            "Different spirits, {name}, but the same listening. I respect that.",
        },
    },

    SHAMAN = {
        PRAISE = {
            "The elements speak to us both, {name}.",
            "Good to fight beside another who listens, {name}.",
            "{name}, your totems are well placed. I notice such things.",
            "We call the same storm, {name}. It answered you well.",
        },
        JOKE = {
            "{name}, between the two of us this ground is more totem than dirt.",
            "Try not to step on my totems, {name}. I will know.",
        },
        RESPECT = {
            "{name}, you walk the path Thrall opened. So do I. That is enough.",
        },
    },

    MAGE = {
        PRAISE = {
            "Good magic, {name}. Try not to burn the totems.",
            "Your fire is useful, {name}. Mostly.",
            "{name}, I do not understand what you do. It works. That is enough.",
            "Arcane is a cold thing, {name}, but you wield it well.",
        },
        JOKE = {
            "{name}, the food you conjure tastes like a rumor. My thanks anyway.",
            "Send me somewhere useful, {name}. Preferably not into a wall.",
        },
        WARN = {
            "{name}, that magic came from somewhere. Remember to ask where.",
        },
    },

    WARLOCK = {
        PRAISE = {
            "Your magic helped us, {name}. I still do not trust it.",
            "I respect the fighter, {name}. The magic is another matter.",
            "That worked, {name}. I will not pretend I enjoyed watching it.",
            "You are useful, {name}. That is the word I have chosen.",
        },
        THANK = {
            "You saved us, {name}. With that. I am still deciding how I feel.",
            "My thanks, {name}. The ancestors will hear a shortened version.",
        },
        DISTRUST = {
            "I am watching you, {name}. Nothing personal. Entirely personal.",
            "{name}, I have seen where that road ends. Our people walked it once.",
            "You have not earned my distrust, {name}. Your craft did that long ago.",
            "I will fight beside you, {name}. I will not turn my back.",
            "The spirits go quiet around you, {name}. That tells me something.",
        },
        DEMON = {
            "{name}... keep that demon under control.",
            "Your pet is looking at me, {name}. Tell it not to.",
            "That thing is a slave, {name}, and slaves remember.",
            "Keep it away from my totems, {name}. I will not ask twice.",
            "I have seen what happens when the leash slips, {name}. So have you.",
        },
        FEL_MAGIC = {
            "Fel magic nearly destroyed our people once. Remember that, {name}.",
            "{name}, that green fire is the same fire that put us in chains.",
            "The earth still screams where fel has touched it, {name}. Ask it yourself.",
            "Every orc alive carries the price of that magic, {name}. Do not spend more.",
            "I do not hate you, {name}. I hate what you borrowed it from.",
        },
    },

    DRUID = {
        PRAISE = {
            "You listen to the wild, {name}. That is close enough to my path.",
            "{name}, the elements and your wild gods seem to agree today.",
            "Whatever shape you wear, {name}, you fight well in it.",
            "Balance is hard, {name}. You keep it.",
        },
        JOKE = {
            "{name}, pick a shape and stay in it. I am becoming dizzy.",
            "You sleep more than any orc I know, {name}, and you still fight better than most.",
        },
        RESPECT = {
            "The tauren taught you well, {name}. That is a good lineage.",
        },
    },

    PALADIN = {
        PRAISE = {
            "Your Light holds, {name}. I will not argue with results.",
            "{name}, you fight with conviction. I understand conviction.",
            "That was well done, {name}. Your faith is not idle.",
        },
        RESPECT = {
            "We do not pray the same way, {name}. We stand the same way.",
            "{name}, the Light is not my path. Your honor is plain enough regardless.",
        },
        JOKE = {
            "{name}, your Light is very bright. Some of us are trying to see the fight.",
        },
    },
}
