-- Warrior.lua -- the class tab for a warrior.
--
-- No magic, no patron, no excuses. A warrior's voice is the plainest of them
-- all, and that plainness is the character: everyone else explains where their
-- power comes from, and he does not have to.

local ADDON, ns = ...
ns.Phrases = ns.Phrases or {}

ns.Phrases.WARRIOR = {
    RAGE = {
        "Anger is a tool. I keep mine sharp.",
        "I do not lose my temper. I spend it.",
        "The rage comes when it is needed. It leaves when the work is done.",
        "Hit me. I get stronger. It is a poor bargain for you.",
        "I fight better bleeding. I have never been sure that is a virtue.",
        "Rage is honest. It never pretends to be something else.",
    },

    SHIELD = {
        "This shield has outlived three owners. I intend to be the fourth.",
        "Get behind me and stay there.",
        "A shield is not for hiding. It is for deciding where the fight happens.",
        "I will hold. That is the whole of my plan and it has never failed badly.",
        "Nothing gets past me while I am standing.",
        "Mind the shield. It is the only thing between you and the floor.",
    },

    WEAPONS = {
        "Steel does not need explaining.",
        "I have carried this blade longer than most people carry a grudge.",
        "Two hands. One swing. Very little argument afterwards.",
        "Keep your edge and your edge keeps you.",
        "I do not name my weapons. They are tools, and tools get replaced.",
        "A good weapon is one you do not have to think about.",
    },

    CHARGE = {
        "Stand still. I am coming through.",
        "The fastest way across a battlefield is straight at someone.",
        "I close the distance. You decide what to do about it.",
        "Let me in first. I make an excellent door.",
        "Charge now, think later. It has worked so far.",
    },

    WOUNDS = {
        "It is not deep. Most of them are not.",
        "I have been cut worse by people I liked.",
        "Scars are only a record. Read them and move on.",
        "Bleeding is not dying. Do not confuse the two.",
        "I will feel this tomorrow. Today I am busy.",
        "Stitch it later. It is still attached.",
    },

    DISCIPLINE = {
        "Anyone can swing. Knowing when not to is the craft.",
        "I drill because the fight is no place to learn.",
        "Hold the line means hold it. Not almost.",
        "Panic kills more than steel does.",
        "Do it the same way every time and it works the time that matters.",
    },

    HONOR = {
        "I fight in front of people, not behind them.",
        "A warrior who needs an excuse has already lost something.",
        "I have never struck someone who could not strike back.",
        "Win properly or do not bother telling anyone.",
        "My word costs nothing to give and everything to break.",
    },

    TAUNT = {
        "Look at me. Yes. Me.",
        "Over here. You are going to want to deal with me first.",
        "Leave them alone. I am the problem.",
        "I have your attention. Now let us see what you do with it.",
        "Come on then. I have been waiting all day for someone your size.",
    },

    LUCK = {
        "Keep your shield up and your feet under you.",
        "Go well. Hit first if it comes to it.",
        "May your enemies be slow and your armour hold.",
        "Stand your ground, friend. It is all any of us can do.",
        "Good hunting. Come back with all of it attached.",
    },

    WARNING = {
        "Stop. I do not like the shape of this.",
        "Back up. Something in here is wrong.",
        "Do not go in there without me.",
        "I have walked into an ambush before. It felt like this.",
        "Slow down. Nothing ahead of us is going anywhere.",
    },
}
