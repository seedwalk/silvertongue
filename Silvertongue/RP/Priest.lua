-- Priest.lua -- the class tab for a priest.
--
-- Two halves that do not quite agree with each other, which is the character.
-- Written so a Light-sworn human and a Forsaken of the Forgotten Shadow can
-- both find their half of it.

local ADDON, ns = ...
ns.Phrases = ns.Phrases or {}

ns.Phrases.PRIEST = {
    LIGHT = {
        "The Light is not a weapon. It is a refusal to let go.",
        "I hold people together. It is less glorious than it sounds.",
        "It answers when I am steady. So I stay steady.",
        "Faith is a discipline, not a feeling.",
        "I have carried people who were already gone. It still mattered.",
    },

    SHADOW = {
        "The shadow is not evil. It is only what the Light does not reach.",
        "I have looked into it. It looked back, politely.",
        "There is power in the parts of the mind nobody visits.",
        "Do not be frightened. Or do. It makes no difference to it.",
        "I use both halves. Pretending otherwise would be a lie.",
        "The mind is a door. Most people never check whether it is locked.",
    },

    HEALING = {
        "Hold still. You are worse than you think.",
        "I have you. Breathe.",
        "Stop bleeding on things and let me work.",
        "You will live. You will also hear about this later.",
        "Mended. The scar is yours to explain.",
        "I cannot heal what you keep walking back into.",
    },

    FAITH = {
        "I believe on the days it is inconvenient. That is the whole test.",
        "Certainty is not faith. Certainty is just comfort.",
        "I have asked for things and been answered with silence. I kept asking.",
        "You do not need to share it. You only need to not spit on it.",
        "Something is listening. Whether it cares is a separate question.",
    },

    MERCY = {
        "Even that one deserved a clean end.",
        "I will not enjoy this. That is the line I keep.",
        "Cruelty is a choice and it is always available. Choose otherwise.",
        "Let them go. They are no use to anyone dead.",
        "I have seen enough suffering to stop finding it interesting.",
    },

    DOUBT = {
        "Some nights nothing answers. I still sit with it.",
        "Anyone who tells you they never doubted is selling something.",
        "I do not have answers. I have a practice.",
        "The silence is the hard part. Not the pain.",
        "I keep going because stopping helps nobody.",
    },

    DEATH = {
        "Death is not the enemy. Dying badly is.",
        "I have sat with the dying. It is quieter than you expect.",
        "Let them rest. They have earned it.",
        "I do not fear it. I simply have work first.",
        "Say what you need to say now. Later is not guaranteed.",
    },

    PRAYER = {
        "Give me a moment. I am asking for something.",
        "Peace to whoever died here.",
        "I will say the words. Whether anyone hears them is not my part.",
        "Rest. You are not needed any more.",
        "A moment of quiet, and then we go on.",
    },

    BLESSING = {
        "Go well. You will be looked after, one way or another.",
        "Strength to you, and the sense to use it.",
        "May what you believe in hold when you lean on it.",
        "Walk safely, friend.",
        "Be well. Come back and let me see for myself.",
    },

    WARNING = {
        "Something died badly here, and it has not finished.",
        "Stop. This place is heavy.",
        "I can feel it from here and I would rather not get closer.",
        "The dead here are not at rest. Somebody saw to that.",
        "Careful. Whatever is in here was once someone.",
    },
}
