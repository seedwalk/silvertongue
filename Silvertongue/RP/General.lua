-- General.lua -- everyday social intents. Undirected, usually SAY.

local ADDON, ns = ...
ns.Phrases = ns.Phrases or {}

ns.Phrases.GENERAL = {
    HELLO = {
        "Strength and honor.",
        "Well met.",
        "You look like you have somewhere to be. Do not let me hold you.",
        "The spirits guide your path, friend.",
        "Hail. May the wind be at your back.",
    },

    GOODBYE = {
        "Walk with the spirits.",
        "Until the road brings us together again.",
        "Go. The Horde has work for both of us.",
        "Farewell, friend. Keep your weapon close.",
        "May the ancestors watch your road.",
        "We part. That is all it is.",
    },

    THANKS = {
        "You have my thanks.",
        "The spirits remember kindness. As do I.",
        "My thanks, friend.",
        "You have done me a kindness. I will remember it.",
        "Strength and honor, friend. You have my thanks.",
        "That was well done. I am in your debt.",
        "I will not forget this.",
    },

    APOLOGIZE = {
        "That was my error. I own it.",
        "I was wrong. I will not be wrong the same way twice.",
        "My apologies. The fault was mine.",
        "I misjudged. It will not happen again.",
        "I spoke too quickly. Forgive it.",
        "An orc who cannot admit a mistake is only half an orc.",
    },

    CONGRATULATE = {
        "Well earned.",
        "You have done something worth telling. Tell it.",
        "The ancestors saw that. So did I.",
        "A fine thing. Be proud of it.",
        "That was no small feat. Congratulations.",
        "Honor to you.",
    },

    ENCOURAGE = {
        "Stand. You are not finished.",
        "The spirits do not abandon those who keep moving.",
        "You are stronger than the thing in front of you.",
        "Doubt is heavier than any axe. Put it down.",
        "Keep going. I have seen worse odds broken.",
        "One more step. Then another. That is all strength has ever been.",
    },

    RESPECT = {
        "You have my respect.",
        "You fight with honor. That is rarer than skill.",
        "I have seen what you are. It is worth something.",
        "The Horde is better for having you in it.",
        "Respect. Earned, not given.",
        "You carry yourself well. I notice such things.",
    },

    LAUGH = {
        "Hah! That is worth remembering.",
        "The ancestors would have laughed at that. Quietly.",
        "Good. A warrior who cannot laugh is only waiting to die.",
        "Hah. You are not as dull as you look.",
        "That is funny. I am told I do not say that often.",
        "Heh. Careful, I may begin to enjoy your company.",
    },

    AGREE = {
        "Agreed.",
        "You speak sense. Rare, but welcome.",
        "Yes. That is the way of it.",
        "The spirits and I are of one mind on this.",
        "So be it.",
        "I will not argue with the truth.",
    },

    DISAGREE = {
        "No. I see it differently.",
        "That is wrong, and I will say why.",
        "I hear you. I do not accept it.",
        "You are mistaken. There is no shame in it, but you are.",
        "No. My answer will be the same tomorrow.",
    },

    READY = {
        "I am ready.",
        "Ready. I have been ready.",
        "Ready. Let us not stand here admiring the scenery.",
        "I am set. Whenever the rest of the world catches up.",
        "Whenever you are. I do not tire of waiting, but I do notice it.",
        "Say the word and it is done.",
    },

    WAIT = {
        "Hold.",
        "Wait. One moment.",
        "Give me a breath. The spirits are not hurried.",
        "Stop. Something is not right yet.",
        "Patience. Rushing has killed more orcs than any blade.",
        "Wait for me. I am not finished here.",
    },

    FOLLOW_ME = {
        "Follow me.",
        "This way. Stay close.",
        "With me. The path is clear enough.",
        "Come. I know where we are going. Mostly.",
        "Follow. I will take the front.",
        "Move. I will explain while we walk.",
    },

    VICTORY = {
        "Victory!",
        "It is done. The spirits favored us.",
        "We stood. They did not.",
        "Lok'tar ogar. Victory or death, and it was not death.",
        "A good fight, well finished.",
        "Let them remember who was still standing.",
    },

    DEFEAT = {
        "We fell. We rise. Again.",
        "No shame in falling. Only in refusing to rise.",
        "The spirits taught us something today. I did not enjoy the lesson.",
        "That was a defeat. Say it plainly and move on.",
        "We were beaten. We were not broken.",
        "Remember this feeling. It is useful.",
    },
}
