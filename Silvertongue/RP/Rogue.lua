-- Rogue.lua -- the class tab for an orc rogue. Same orc underneath: proud,
-- honorable, dry. He simply does his killing from a different angle, and knows
-- some of his people think less of him for it.

local ADDON, ns = ...
ns.Phrases = ns.Phrases or {}

ns.Phrases.ROGUE = {
    SHADOWS = {
        "The shadows are honest. They hide everyone equally.",
        "I do not hide because I am afraid. I hide because it works.",
        "Some orcs think this is a coward's craft. They are welcome to say so to my face.",
        "The dark is not a place. It is a discipline.",
        "I learned patience in the shadows. It is the only thing I learned easily.",
        "Where I stand, no one is looking. That is the entire trick.",
    },

    BLADES = {
        "Two blades. One answer.",
        "A sharp edge asks no permission.",
        "My axe was honest. My knives are faster. I made a choice.",
        "Keep them sharp and keep them close. Nothing else about this is complicated.",
        "One good cut is worth ten loud ones.",
        "The blade does not need to be big. It needs to be somewhere unexpected.",
    },

    STEALTH = {
        "Quiet. I am working.",
        "Do not follow me in. You breathe like a kodo.",
        "I am already past them. Wait for my word.",
        "Walk soft or do not walk with me.",
        "They will not know I was here until they count their dead.",
        "Stay behind. I do this better alone.",
    },

    POISON = {
        "The blade is only the delivery. The rest takes its time.",
        "Poison is not dishonorable. Dying slowly for a bad cause is.",
        "I coat them myself. I trust no one else's mixture.",
        "It is not cruelty. It is arithmetic.",
        "Let it work. Patience is most of my craft.",
        "One drop. Then wait. That is the whole lesson.",
    },

    PATIENCE = {
        "I have waited longer than this for worse targets.",
        "The hurried blade misses. The patient one does not need to be fast.",
        "Wait. The moment will come and it will be obvious.",
        "Everyone tires eventually. I have simply learned to tire last.",
        "Do not rush me. Rushing is how amateurs die.",
        "Stillness is a weapon. Most never learn to hold it.",
    },

    KILL = {
        "It is done. He never knew.",
        "Clean. No noise, no mess, no argument.",
        "One strike. That is all it should ever take.",
        "The ancestors do not ask where I stood when I did it.",
        "Finished. Let us not stand here admiring it.",
        "He had a moment to understand. That is more than he gave others.",
    },

    HONOR = {
        "I fight from shadows. I still fight for the Horde. Both are true.",
        "Honor is not about where you stand. It is about who you stand for.",
        "An orc who kills the right enemy is honorable, whatever angle he came from.",
        "I have never struck someone who did not have it coming.",
        "Call it dishonorable if you like. I will be behind you either way.",
        "The Warchief does not ask me to fight loudly. Only to fight.",
    },

    LUCK = {
        "Walk quiet, friend.",
        "May they never see you coming either.",
        "Keep to the shadows and the shadows will keep you.",
        "Go. And do not make noise doing it.",
        "May your blade find the gap. There is always a gap.",
        "The ancestors watch even the ones who move quietly.",
    },

    SCOUT = {
        "I have seen what is ahead. You will not enjoy it.",
        "Three of them, and one is watching the door.",
        "It is clear. For now. That never lasts.",
        "Give me a moment. I would rather know than guess.",
        "There is another way around. There usually is.",
        "I looked. We should not go that way.",
    },

    WARNING = {
        "Stop. Someone has been here recently.",
        "That is a trap, and not a good one. Which somehow worries me more.",
        "Do not move. Let me look at this properly.",
        "Something is watching us. I know the feeling well enough to trust it.",
        "Back up. Slowly. Do not make it interesting for them.",
        "I do not like this. I am rarely wrong about not liking things.",
    },
}
