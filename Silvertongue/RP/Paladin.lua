-- Paladin.lua -- the class tab for a paladin.
--
-- Deliberately written so a human, a dwarf, a draenei and a blood elf can all
-- speak it. Where each of them got the Light is a matter for their own lines;
-- what they do with it is the same.

local ADDON, ns = ...
ns.Phrases = ns.Phrases or {}

ns.Phrases.PALADIN = {
    LIGHT = {
        "The Light does not care how I feel about it. It works anyway.",
        "I do not own this. I only carry it.",
        "The Light is not a reward. It is a duty with a glow.",
        "It answers. That is all I can tell you, and all I need to.",
        "I have felt it fail once. I have not forgotten.",
        "Stand in it. It is not only for me.",
    },

    OATH = {
        "I swore something once and I have not needed to swear it again.",
        "An oath you can keep easily was not worth making.",
        "I do not break my word. I have very little else.",
        "The vow is the point. The armour is just armour.",
        "Ask me to do something dishonourable and watch what happens.",
    },

    JUDGEMENT = {
        "I have judged. You will not like it.",
        "This is not cruelty. It is arithmetic with consequences.",
        "Some things do not get forgiven. They get ended.",
        "I would rather be merciful. You have made that difficult.",
        "The verdict was yours to change and you did not.",
    },

    PROTECTION = {
        "Behind me. Now.",
        "Nothing reaches you through me.",
        "I am here to be hit. It is not glamorous and it is necessary.",
        "Stay close. My shield reaches further than my arm.",
        "You are under my protection whether you wanted it or not.",
    },

    HEALING = {
        "Hold still. This is easier when you do not squirm.",
        "You are not dying today. I have decided.",
        "Up you get. The Light has better things to do than argue with you.",
        "Mended. Try not to undo it immediately.",
        "I can close the wound. I cannot make you less reckless.",
    },

    BLESSING = {
        "May the Light find you where you are, not where you should be.",
        "Go with a blessing. It weighs nothing and it helps.",
        "Strength to you, friend.",
        "The Light keep you, and keep you honest.",
        "Walk safely. If you cannot, walk anyway.",
    },

    DOUBT = {
        "I have doubted. It did not make me faithless, only awake.",
        "Anyone who has never questioned it was never really holding it.",
        "Faith that has never been tested is just a habit.",
        "Some nights it is quiet. I keep going regardless.",
        "I do not need to be certain. I need to be here.",
    },

    HONOR = {
        "Honor is what you do when the Light is not watching.",
        "I will not win by a method I would have to hide.",
        "There is no holy way to stab someone in the back.",
        "Fight cleanly or find someone else to fight beside.",
        "The cause does not sanctify the method. It never has.",
    },

    MERCY = {
        "Go. I will not ask twice and I will not chase you.",
        "You are beaten. That is enough for me.",
        "Mercy is not weakness. It is a decision, and I have made it.",
        "Live with what you did. That is the harder sentence anyway.",
        "I could end this. I am choosing not to. Do not waste it.",
    },

    WARNING = {
        "Something in here is unclean. Tread carefully.",
        "Stop. This place has been used for something wrong.",
        "The Light dims here. That is never a good sign.",
        "Do not touch anything until I have looked at it.",
        "I feel it too. We go slowly or we do not go.",
    },
}
