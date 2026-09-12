-- Mage.lua -- the class tab for a mage.
--
-- Precision and a slightly insufferable confidence. He is usually right, which
-- is what makes it insufferable.

local ADDON, ns = ...
ns.Phrases = ns.Phrases or {}

ns.Phrases.MAGE = {
    ARCANE = {
        "Magic is a discipline. Anyone calling it a gift has not studied.",
        "The arcane is precise. It is the wielder who tends not to be.",
        "I did not find this power. I earned it, slowly and in libraries.",
        "Everything you find impressive, I find load-bearing.",
        "It is not mysterious. It is difficult. Those are different words.",
    },

    FIRE = {
        "Everything burns at the right temperature. Everything.",
        "Fire is the simplest answer and it is frequently correct.",
        "Stand back. I am about to be unsubtle.",
        "I can make this problem hot. That usually settles it.",
        "Yes, I meant to do that. Mostly.",
    },

    FROST = {
        "Cold buys time. Time is what wins fights.",
        "Do not chase it. It cannot go anywhere.",
        "I would rather freeze a problem than negotiate with it.",
        "Slowed, held, then finished. In that order.",
        "Frost is patient. So am I, when it suits me.",
    },

    PORTALS = {
        "Where do you want to be? Be specific.",
        "I can save you a week of walking. You could say thank you.",
        "Step through and do not touch the edges.",
        "Yes, it is safe. Reasonably.",
        "Everybody wants a portal and nobody wants to carry my reagents.",
    },

    FOOD = {
        "It is food. It is not a banquet. Eat it.",
        "Conjured, and it tastes like the idea of bread. You are welcome.",
        "I can feed this entire group. Try to remember that occasionally.",
        "Water is free. Gratitude, apparently, is expensive.",
        "Take it. It will vanish eventually and then you will miss it.",
    },

    STUDY = {
        "I read about this for a year before I tried it once.",
        "Somebody wrote this down so I would not have to die learning it.",
        "The library is not an escape from the world. It is a map of it.",
        "I will know the answer shortly. Give me the book.",
        "Ignorance is curable and most people refuse the treatment.",
    },

    POLYMORPH = {
        "He is a sheep now. He will be fine. Mostly fine.",
        "Do not hit the sheep.",
        "I have removed him from the conversation.",
        "Nobody touch that. It is temporary and it is load-bearing.",
        "The sheep is not a joke. The sheep is a strategy.",
    },

    DISDAIN = {
        "That was not a plan. That was a sequence of accidents.",
        "Fascinating. Wrong, but fascinating.",
        "I could explain, but you would have to want to understand.",
        "You are all very brave and I will be over here, thinking.",
        "Strength solves fewer problems than you have been told.",
    },

    BLESSING = {
        "Go well. Try not to need rescuing.",
        "Take some water and my sincere hopes.",
        "May your enemies be flammable.",
        "Safe travels. I will be here, being useful.",
        "Go. And remember which way the portal was.",
    },

    WARNING = {
        "Stop. The magic in here is wrong and I would like to know why.",
        "Somebody has been doing something ambitious and stupid.",
        "Do not touch that. I am not certain what it is yet.",
        "The weave here is torn. Step carefully.",
        "I am reading something I do not like. Back up.",
    },
}
