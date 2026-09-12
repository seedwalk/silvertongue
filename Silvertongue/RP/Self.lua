-- Self.lua -- lines flagged for who you are playing.
--
-- Three axes: CLASS, RACE and FACTION. They merge in that order, and a layer's
-- `replace` wipes only what was merged before it -- so a race can take over the
-- shared voice while faction flavour still lands on top, and a faction can take
-- over in turn. See the RACE section below for how `replace` is written. Each is keyed by the token the game
-- reports for your character, and each holds the same shape underneath --
-- category, then intent, then lines. They are added to the shared pools, so the
-- buttons stay the same everywhere: "Ready" is still "Ready", but a shaman
-- answers with totems and a rogue with blades. A line flagged for one value
-- never reaches a character with another.
--
-- Growing this is data, not code. Add a class token, a race token or a faction
-- token here and the engine picks it up. Nothing else needs to change.

local ADDON, ns = ...
ns.Phrases = ns.Phrases or {}

ns.Phrases.SELF = {}

ns.Phrases.SELF.CLASS = {
    SHAMAN = {
        GENERAL = {
            HELLO = {
                "Greetings. The elements are quiet today. That is usually good.",
            },
            READY = {
                "Totems set. Say the word.",
                "The elements are with me. Let us begin.",
            },
            DISAGREE = {
                "The elements do not agree with you. Neither do I.",
            },
        },

        PARTY = {
            READY = {
                "Totems are down. I am set.",
                "The elements are willing. So am I.",
                "Ready when you are. I have my mana and my patience.",
            },
            WIPE = {
                "The elements warned me. I did not listen either.",
                "My totems survived. Nothing else did.",
            },
            BOSS = {
                "Mind the totems. Mind each other.",
            },
            WAIT = {
                "Wait. Let me set the totems.",
            },
            MANA = {
                "Give me a moment. The elements are willing. My mana is not.",
                "Hold. I cannot call upon the elements with an empty mind.",
                "The spirits answer. They do not answer for free.",
            },
        },

        PERSON = {
            WARN = {
                "The elements are uneasy, {name}. So am I.",
            },
            JOKE = {
                "{name}, stand behind the totems. They are worth more than both of us.",
            },
        },

        HORDE = {
            BATTLE_CRY = {
                "The elements are with us! Forward!",
                "Come then! I have totems and a bad temper!",
            },
        },

        ATTITUDE = {
            ANGRY = {
                "The elements are angry. They learned it from me.",
            },
            ANNOYED = {
                "I have totems older than this argument.",
                "The elements are patient. I am a shaman, not an element.",
            },
        },

        TARGET = {
            HELLO = {
                "The elements greet you, {name}. So do I.",
            },
            PARTY = {
                "{name}, I keep the totems up and the wounded standing. Group with me.",
            },
            OFFER = {
                "{name}, I can bring you back if it comes to that. Hold still when it does.",
                "I can put totems down for you, {name}. Say which ones.",
                "{name}, if you fall, the spirits and I will have words with them. Then I will raise you.",
                "Need water or a shield of it, {name}? I have both.",
            },
            HELP_OFFER = {
                "{name}, I can keep you standing. That is most of what I do.",
            },
        },

        ENEMY = {
            ENEMY_CHALLENGE = {
                "{name}, the elements are awake and I am in a mood.",
                "Step forward, {name}. I have totems to spare and patience I do not.",
            },
            ENEMY_TAUNT = {
                "You brought that to a fight with a shaman, {name}? Bold.",
            },
        },
    },

    ROGUE = {
        GENERAL = {
            HELLO = {
                "Greetings. I saw you before you saw me. Do not take it personally.",
            },
            READY = {
                "Blades are out. Say the word.",
                "I am where I need to be. You simply cannot see it.",
            },
            DISAGREE = {
                "No. I have watched this go wrong before, from closer than you did.",
            },
        },

        PARTY = {
            READY = {
                "Ready. I have been in position for some time.",
                "Blades are ready. So am I.",
                "Say the word and it is already done.",
            },
            WIPE = {
                "I saw that coming. I was too far ahead to say so.",
                "I got out. That is the one thing I am reliably good at.",
            },
            BOSS = {
                "I will take the back of it. Keep its eyes on you.",
            },
            WAIT = {
                "Wait. Let me look at this first.",
            },
            MANA = {
                "Hold. I need a breath, not a drink.",
            },
        },

        PERSON = {
            WARN = {
                "{name}, there is something behind you. I am not joking.",
            },
            JOKE = {
                "{name}, if you keep standing in front, I will keep standing behind. It is a good arrangement.",
            },
        },

        HORDE = {
            BATTLE_CRY = {
                "They will not see us coming! Move!",
                "Quietly, then all at once! For the Horde!",
            },
        },

        ATTITUDE = {
            ANGRY = {
                "I have been patient in the dark for a long time. I am done being patient.",
            },
            ANNOYED = {
                "I could have ended this argument three different ways by now.",
                "I am a blade, not a diplomat. Somebody else talk.",
            },
        },

        TARGET = {
            HELLO = {
                "{name}. I have been standing here a while. You did not notice.",
            },
            PARTY = {
                "{name}, I will go ahead and tell you what is coming. Group with me.",
            },
            OFFER = {
                "{name}, if you are carrying a locked box, I can open it. No charge.",
                "I can go ahead and look, {name}. It costs you nothing.",
                "{name}, any lock you cannot open, bring it to me.",
                "Need something scouted, {name}? That is the one thing I am reliably good at.",
            },
            HELP_OFFER = {
                "{name}, I can take the one at the back before it knows we are here.",
            },
        },

        ENEMY = {
            ENEMY_CHALLENGE = {
                "{name}, I am already closer than you think. Turn around.",
                "Draw it, {name}. I would rather do this facing you.",
            },
            ENEMY_TAUNT = {
                "You never saw me coming, {name}. You still do not.",
            },
        },
    },
}

-- Your own race.
--
-- Read this before adding one. The shared pools in RP/General.lua, RP/Party.lua,
-- RP/Attitude.lua and RP/Target.lua are NOT neutral: they are written in an
-- orcish register -- blunt, proud, ancestor-minded, "strength and honor". They
-- work unchanged for an orc and they are the fallback for everyone else, which
-- is why a troll or a tauren sounds faintly orcish today.
--
-- Giving a race its own voice therefore comes in two flavours:
--
--   * ADD -- a handful of lines that join the shared pool, for a race that is
--     close enough to the default register.
--
--   * REPLACE -- list the intent under `replace` and this race's lines are used
--     INSTEAD of the shared ones. That is how a tauren stops borrowing an orc's
--     mouth. Replacing an intent means writing enough lines to carry it alone,
--     five or more, because nothing else will come up.
--
-- A worked example, left commented rather than half-written:
--
--   TAUREN = {
--       replace = { GENERAL = { HELLO = true } },
--       GENERAL = {
--           HELLO = {
--               "Well met. The Earth Mother watches this road.",
--               ... four or five more, because these are now the only ones ...
--           },
--       },
--   },
--
-- Tokens are what UnitRace returns, uppercased: ORC, TROLL, TAUREN, SCOURGE,
-- BLOODELF, HUMAN, DWARF, NIGHTELF, GNOME, DRAENEI.
ns.Phrases.SELF.RACE = {
}

-- Your own faction. This is what keeps "our people" and "the Warchief" off an
-- Alliance character's tongue.
ns.Phrases.SELF.FACTION = {
    HORDE = {
        GENERAL = {
            HELLO = {
                "Lok'tar. You look like you have somewhere to be.",
            },
        },
    },

    ALLIANCE = {
    },
}
