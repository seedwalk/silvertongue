-- Party.lua -- party-wide intents and person-directed intents.
-- PERSON phrases use {name}; the engine fills it from the selected member.

local ADDON, ns = ...
ns.Phrases = ns.Phrases or {}

ns.Phrases.PARTY = {
    HELLO = {
        "Good to have company.",
        "Right. Let us get to work.",
        "Well met, all of you.",
        "Good. Strong company.",
        "Well met, all of you. Try to stay alive.",
        "Strength and honor to every one of you.",
    },

    READY = {
        "Ready.",
        "Say the word.",
        "I am prepared. Are we all?",
        "Ready. Waiting on the rest of you.",
        "I am set. Someone else is not.",
        "Ready when you are, and I mean that politely.",
    },

    GOOD_JOB = {
        "Well fought, all of you.",
        "That was clean. Do it again.",
        "Good work. I mean it, which is rare.",
        "We moved as one. That is how it is supposed to feel.",
        "No one fell. That is the highest praise I have.",
        "Strong. Every one of you.",
        "I have fought beside worse. Far worse.",
        "Good. Now do not let it go to your heads.",
    },

    WIPE = {
        "We fell. We rise. Again.",
        "No shame in falling. Only in refusing to rise.",
        "Again.",
        "That went poorly. Let us go poorly in a different direction next time.",
        "Run back. Say nothing. We try again.",
        "We learned something. It cost us everything, but we learned it.",
        "Do not blame each other. Blame the thing that killed us.",
    },

    BOSS = {
        "We know what stands ahead. Let us finish it.",
        "Ready yourselves.",
        "This one is worth killing properly. No mistakes.",
        "Breathe. Then kill it.",
        "It is large. It is angry. It will still fall.",
    },

    WAIT = {
        "Hold. Not yet.",
        "Wait for me.",
        "Hold. Not yet.",
        "Stop. Someone is not with us.",
        "Hold here. I want a moment to look at this.",
        "Wait. Rushing this would be stupid, and I would rather not be stupid today.",
    },

    MANA = {
        "Wait. I need mana.",
        "Mana first. Heroics later.",
        "Drinking. Do not pull.",
        "I am empty. Give me a moment.",
        "Hold. I am no use to you like this.",
    },

    -- The rogue's version of "wait, I need a moment": going ahead in the dark.
    SCOUT = {
        "Hold here. I will go ahead and look.",
        "Wait. Let me see what is around that corner before it sees us.",
        "Give me a moment in the dark. I will come back knowing more than I do now.",
        "Stay. I am better at this alone and quiet.",
        "Do not follow. If I am not back, you will hear about it.",
        "Let me walk it first. Surprises are only good when they are ours.",
    },

    VICTORY = {
        "It is finished. Well fought, all of you.",
        "We stood. It did not. That is the whole story.",
        "Good. Take what is yours and let us move.",
        "We won. Do not look so surprised.",
        "A worthy kill. Honor to every one of you.",
        "Let them remember who stood here.",
    },

    GOODBYE = {
        "That was good company. Not everyone is.",
        "Until next time, all of you.",
        "Good hunting, all of you.",
        "It was an honor. Truly.",
        "Until the next fight. There is always a next fight.",
        "My thanks for the company. Not everyone is worth fighting beside.",
    },
}

ns.Phrases.PERSON = {
    THANK = {
        "{name}, you have my thanks.",
        "Well done, {name}. I will remember that.",
        "My thanks, {name}. That was no small thing.",
        "You saved me some trouble, {name}. And possibly my life.",
        "I owe you one, {name}. I pay my debts.",
        "That was timely, {name}. Timing is half of everything.",
        "Thank you, {name}. I do not say it often, so mark the day.",
        "You have my gratitude, {name}, and my axe if you need it.",
    },

    PRAISE = {
        "That was excellent work, {name}.",
        "{name}, that was worth seeing.",
        "Strong, {name}. Very strong.",
        "You know your craft, {name}. That is rarer than courage.",
        "I have fought beside many, {name}. Few like you.",
        "That was no accident, {name}. That was skill.",
        "Keep fighting like that, {name}, and they will sing about you. Badly, but they will sing.",
    },

    ENCOURAGE = {
        "Stand, {name}. You are not done.",
        "Keep your feet, {name}. That is all I ask.",
        "You are stronger than this moment, {name}.",
        "Do not falter now, {name}. Not when we are this close.",
        "{name}, I have seen you do harder things.",
    },

    WARN = {
        "{name}. Careful.",
        "{name}, think for one second before you do that.",
        "Stop, {name}. That is a worse idea than it looks.",
        "Watch yourself, {name}. Something is wrong here.",
        "{name}, that is a mistake waiting to happen.",
        "Slow down, {name}. Dead is a long time.",
    },

    APOLOGIZE = {
        "{name}, that was my error.",
        "I failed you there, {name}. It will not happen twice.",
        "My apologies, {name}. The fault was mine alone.",
        "{name}, I was wrong. I say so plainly.",
        "I should have been faster, {name}. I know it.",
        "Forgive it, {name}. I do not make excuses.",
    },

    RESPECT = {
        "You have my respect, {name}.",
        "{name}, you fight with honor. That is worth more than skill.",
        "I see what you are, {name}. It is worth something.",
        "There is honor in you, {name}. I do not say that lightly.",
        "{name}, you carry yourself well. I notice such things.",
    },

    JOKE = {
        "{name}, if you die I am taking your boots.",
        "{name}, I have decided you are worth keeping alive. Do not test it.",
        "Stay close, {name}. You are useful and I am lazy.",
        "You fight well, {name}. For someone who moves like that.",
        "{name}, I have decided you may live. For now.",
        "Do not tell anyone, {name}, but I am glad you are here.",
    },
}
