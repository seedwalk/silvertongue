-- Attitude.lua -- personality. The player decides who deserves it.

local ADDON, ns = ...
ns.Phrases = ns.Phrases or {}

ns.Phrases.ATTITUDE = {
    ANGRY = {
        "Enough.",
        "Do not test me today.",
        "I have been patient. I am finished being patient.",
        "Say that again. Slowly. I want to be certain.",
        "My axe is not a threat. It is simply nearby.",
    },

    SUSPICIOUS = {
        "I do not trust this.",
        "Something here smells wrong, and it is not the corpses.",
        "The spirits are uneasy. That is usually about someone.",
        "I am watching. I am always watching.",
        "Explain yourself. Slowly and completely.",
        "I have been lied to before. I learned the shape of it.",
    },

    MOCK = {
        "Impressive. For a first attempt.",
        "That was almost a plan.",
        "You talk a great deal for someone standing behind me.",
        "The ancestors are laughing. I am being polite about it.",
        "I have seen tauren calves fight better. Younger ones.",
        "Do continue. I am learning what not to do.",
    },

    THREATEN = {
        "Walk away. I will not say it twice.",
        "You are one word from a very short conversation.",
        "I have killed for less. I try not to. Do not make it harder.",
        "The earth beneath you is listening to me, not you.",
        "Leave, or I will introduce you to my ancestors personally.",
        "Choose carefully. I am in no mood to be merciful.",
    },

    IMPRESSED = {
        "Now that was worth watching.",
        "Hah! Do that again.",
        "I did not expect that. I am rarely surprised.",
        "The spirits noticed that one.",
        "Well. You have my attention.",
        "That was genuinely well done. I do not say it lightly.",
    },

    DISAPPOINTED = {
        "That was beneath you.",
        "I expected better. That is why I am saying anything at all.",
        "The ancestors saw that too. Think about it.",
        "No. Just no.",
        "You are capable of more. That is what makes this worse.",
        "I will not shout about it. I will simply remember it.",
    },

    CONFUSED = {
        "I do not understand, and I dislike not understanding.",
        "Explain that again. In fewer words.",
        "The spirits are silent on this. So am I.",
        "What in the ancestors' name was that?",
        "I have questions. None of them are polite.",
        "Either I am slow today or that made no sense.",
    },

    ANNOYED = {
        "Are we finished?",
        "Yes. Wonderful. Can we move?",
        "This is a poor use of a perfectly good day.",
        "I am not angry. I am simply done listening.",
        "We have been at this far longer than it deserves.",
        "Say it once more and I will simply start walking.",
    },

    RESPECT = {
        "You have my respect. Do not waste it.",
        "There is honor in you. I see it.",
        "I would fight beside you. That is the highest thing I can say.",
        "You are worth taking seriously. Few are.",
        "Whatever else is true, you fight with honor.",
        "I have no quarrel with you. Only respect.",
    },
}
