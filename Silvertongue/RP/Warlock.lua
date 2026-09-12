-- Warlock.lua -- the class tab for a warlock.
--
-- Played rather than talked to. The addon already has a great deal to say
-- *about* warlocks, all of it suspicious; this is the other side of that
-- conversation, and it does not apologise.

local ADDON, ns = ...
ns.Phrases = ns.Phrases or {}

ns.Phrases.WARLOCK = {
    FEL = {
        "Yes, it is fel. It is also working.",
        "I know exactly what this costs. I did the sum before you were worried.",
        "Everyone is frightened of this power until they need it.",
        "The green is not the problem. The people who use it badly are.",
        "I did not choose an easy craft. I chose an effective one.",
        "Call it corruption if you like. It has not corrupted the outcome.",
    },

    DEMON = {
        "He is bound, he is bitter, and he is mine.",
        "Do not talk to it. It will remember that you did.",
        "The leash is not a metaphor. I check it daily.",
        "It hates me. That is the correct relationship.",
        "He will do as he is told. The day he does not, I will handle it.",
        "Yes, it is looking at you. It looks at everyone.",
    },

    SOULS = {
        "A soul is a currency. I did not invent the exchange rate.",
        "I take what is already lost. Make of that what you will.",
        "These were spent long before I arrived.",
        "It is not theft if there was nobody left to rob.",
        "I keep the ledger honest. That is more than most can say.",
    },

    PACT = {
        "Everything is a bargain. Most people simply never read theirs.",
        "I signed knowing the terms. Who else here can say that?",
        "The deal is the deal. I do not whine about the price.",
        "Power is never free. At least mine has an invoice.",
        "I made a choice. I am not going to pretend it was forced on me.",
    },

    PAIN = {
        "This will hurt for a long time. That is the point.",
        "I do not need you dead quickly.",
        "Suffering is just damage with patience.",
        "It spreads. Try not to stand near your friends.",
        "You will have a while to think about this.",
    },

    POWER = {
        "I am the most dangerous thing in this room and everyone knows it.",
        "Fear me or do not. It changes nothing about what I can do.",
        "I did not come here to be liked.",
        "Strength you can see is the least interesting kind.",
        "There is more of this. I am being restrained.",
    },

    COST = {
        "I know what it did to the orcs. I am not an idiot.",
        "Every power has ruined someone. Mine is simply honest about it.",
        "I watch myself more carefully than any of you watch me.",
        "The day I stop being afraid of this is the day to worry.",
        "I carry it deliberately. That is not the same as carrying it lightly.",
    },

    MOCK = {
        "Pray harder. Perhaps it will start working.",
        "How brave. How loud. How unhelpful.",
        "You object to my methods and stand behind my results.",
        "Say it again with your sword. It was almost convincing.",
        "I have been judged by better and buried them.",
    },

    BLESSING = {
        "Go. Try not to owe anyone anything.",
        "May your bargains be clearly worded.",
        "Safe travels, and read what you sign.",
        "Go well. You will be fine. Probably.",
        "May whatever you serve be worth serving.",
    },

    WARNING = {
        "Something has been summoned here, and badly.",
        "Stop. I recognise this and I do not like recognising it.",
        "Whoever worked here did not know what they were doing.",
        "Do not break that circle. It is holding something.",
        "Back up. This is the sort of mistake I am qualified to notice.",
    },
}
