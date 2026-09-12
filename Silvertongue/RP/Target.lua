-- Target.lua -- phrases aimed at whoever you have selected in the world.
-- Every line here names the person: when you speak to someone in SAY,
-- nobody nearby should have to guess who he meant.

local ADDON, ns = ...
ns.Phrases = ns.Phrases or {}

-- Friendly targets reuse the PERSON pools from RP/Party.lua for thanks, praise
-- and the rest. Only greetings need their own, because the GENERAL ones name
-- nobody.
ns.Phrases.TARGET = {
    HELLO = {
        "Strength and honor, {name}.",
        "Well met, {name}.",
        "Greetings, {name}. You have the look of someone with somewhere to be.",
        "Hail, {name}. May the wind be at your back.",
        "{name}. You are still upright. That is worth something these days.",
    },

    PARTY = {
        "{name}. We are killing the same things. Shall we do it together?",
        "Group with me, {name}. Two blades are better than one, and I have seen yours.",
        "{name}, this goes faster with company. Are you interested?",
        "I could use a second, {name}. Say the word and I will send the invite.",
        "Party up, {name}? I promise to be useful and only occasionally stubborn.",
        "{name}, I am headed the same way you are. We may as well go together.",
    },

    TRADE = {
        "{name}, I have something for you. Open a trade.",
        "Hold on, {name}. This is worth more to you than to me.",
        "{name}. Trade with me, I am not using this.",
        "I found something you can use, {name}. Take it.",
        "{name}, let me hand this over before I forget I have it.",
        "This belongs in your hands, {name}, not my bags.",
    },

    DUEL = {
        "{name}. A friendly bout. No grudges after.",
        "Show me what you can do, {name}. Nothing at stake but pride.",
        "{name}, I have been itching for a proper fight. Interested?",
        "Draw on me, {name}. We both walk away from this one.",
        "{name}, let us settle who is better the honest way.",
    },

    HELP_OFFER = {
        "{name}, you look like you could use a hand. Mine is free.",
        "Need help with that, {name}?",
        "{name}. That is too much for one. Let me in.",
        "I can take some of that off you, {name}. Say the word.",
        "{name}, I am not busy and you clearly are.",
        "Stand aside if you like, {name}, or stand with me. Either way it dies.",
    },

    HELP_NEED = {
        "{name}, I could use a hand here.",
        "This is more than I can manage alone, {name}. Help me.",
        "{name}. I am not too proud to ask. I am asking.",
        "Lend me your strength, {name}. I will return it.",
        "{name}, I need help, and you are the one standing here.",
        "I would rather ask than die stubborn, {name}. Help.",
    },

    OFFER = {
        "{name}, do you need anything before we move?",
        "Is there something I can do for you, {name}?",
        "{name}, say it if you need it. I do not read minds.",
        "Before we go, {name} -- anything?",
        "{name}, I have supplies and time. Both are yours if you need them.",
    },

    GOODBYE = {
        "Safe roads, {name}.",
        "Until next time, {name}.",
        "Go well, {name}. Keep your weapon close.",
        "Until the road brings us together again, {name}.",
        "Farewell, {name}. Keep your weapon close.",
        "{name}. We part. That is all it is.",
    },
}

-- Hostile targets: Alliance, hostile creatures, duel opponents. The intents are
-- named ENEMY_* on purpose, so the engine never mixes in the race lines written
-- for a brother in arms.
ns.Phrases.ENEMY = {
    ENEMY_CHALLENGE = {
        "{name}. Draw your weapon or walk away.",
        "You have been looking at me too long, {name}. Decide.",
        "Come then, {name}. Let the earth remember this fight.",
        "{name}, I am right here. That is the whole invitation.",
        "One of us walks away from this, {name}. I am confident about which.",
        "Face me properly, {name}. I will not chase you.",
    },

    ENEMY_TAUNT = {
        "{name}, is that the best you have?",
        "You are trying very hard, {name}. It shows.",
        "Is that all of it, {name}?",
        "You fight like you are afraid of the ground, {name}. You should be.",
        "{name}, I have been struck harder by weather.",
        "Keep swinging, {name}. One of them may land.",
        "{name}, this is the part where you run. Most of them do.",
    },

    ENEMY_MOCK = {
        "Impressive, {name}. For a first attempt.",
        "{name}, that was almost a plan.",
        "You talk a great deal, {name}, for someone bleeding.",
        "{name}, do continue. I am learning what not to do.",
        "The Alliance sent you, {name}? They must be busy.",
        "I would mock you properly, {name}, but you seem to have it handled.",
    },

    ENEMY_RESPECT = {
        "That was well fought, {name}. I will say so once.",
        "You did not make that easy, {name}. Good.",
        "{name}, you fought better than the cause deserved.",
        "{name}. You fight with honor. That is rarer than skill, on either side.",
        "I will not pretend that was easy, {name}. You earned it.",
        "{name}, we are enemies. That does not make you nothing.",
        "You did not run, {name}. I will remember that about you.",
        "A worthy fight, {name}. Go and heal. Then find me again.",
    },

    ENEMY_VICTORY = {
        "It is finished, {name}. Get up when you can.",
        "Stay down, {name}.",
        "It is finished, {name}. Get up when you are able.",
        "The earth held, {name}. You did not.",
        "You fought, {name}. It was not enough. There is no shame in the first part.",
        "Tell them who did this, {name}. Say it properly.",
    },

    ENEMY_WARNING = {
        "Walk away, {name}. I will not say it twice.",
        "{name}, you are one step from a very short conversation.",
        "I have killed for less, {name}. I try not to. Do not make it harder.",
        "The ground beneath you is listening to me, {name}, not you.",
        "Choose carefully, {name}. I am in no mood to be merciful.",
    },
}

-- Race flavor for Alliance targets. Pure data: the engine already supplements
-- pools by race token, so these simply add to what is above.
local ALLIANCE = {
    HUMAN = {
        ENEMY_TAUNT = {
            "{name}, your kind builds fine walls. Let us see how you do without one.",
            "Stormwind is far away, {name}. No one is coming.",
        },
        ENEMY_RESPECT = {
            "{name}, your people and mine have hated each other for good reasons. You are still worth respecting.",
            "I have fought humans who fought like cowards, {name}. You are not one of them.",
        },
    },
    DWARF = {
        ENEMY_TAUNT = {
            "{name}, you dig up the past for a living. Today you join it.",
            "All that armor, {name}, and still so easy to find.",
        },
        ENEMY_RESPECT = {
            "{name}, your people are stubborn as stone. I mean that well.",
            "A dwarf who does not yield, {name}. The ancestors understand that.",
        },
    },
    NIGHTELF = {
        ENEMY_TAUNT = {
            "{name}, ten thousand years and you still fight like that?",
            "The shadows will not hide you from the earth, {name}.",
        },
        ENEMY_RESPECT = {
            "{name}, your people listen to the wild. That is not so far from my own path.",
            "I do not forgive what was done in Ashenvale, {name}. I still know honor when I see it.",
        },
    },
    GNOME = {
        ENEMY_TAUNT = {
            "{name}, I nearly stepped on you. That would have been an undignified end for us both.",
            "Whatever that machine does, {name}, it is not doing it.",
        },
        ENEMY_RESPECT = {
            "{name}, small and unafraid. The spirits notice that sort of thing.",
            "You fight above your size, {name}. Take that as praise.",
        },
    },
    DRAENEI = {
        ENEMY_TAUNT = {
            "{name}, you fled a world my people burned. Now you stand on mine.",
            "Your Light is very bright, {name}. It will not hold the earth.",
        },
        ENEMY_RESPECT = {
            "{name}, our peoples share a wound. Neither of us chose it.",
            "I know what the fel did to your world, {name}. I know what it did to mine.",
        },
    },
}

ns.Phrases.RACE = ns.Phrases.RACE or {}
for raceToken, pools in pairs(ALLIANCE) do
    ns.Phrases.RACE[raceToken] = ns.Phrases.RACE[raceToken] or {}
    for intent, lines in pairs(pools) do
        ns.Phrases.RACE[raceToken][intent] = lines
    end
end
