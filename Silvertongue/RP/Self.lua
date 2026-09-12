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

    WARRIOR = {
        GENERAL = {
            READY = { "Ready. I have been ready since I put this on.",
                      "Say when. I am not the one who needs a moment." },
            DISAGREE = { "No. I have seen that go wrong from the front." },
        },
        PARTY = {
            READY = { "Ready. I go in first, as usual.",
                      "Shield is up. Point me at it." },
            WIPE  = { "That was my fault. I lost the line and you all followed it down.",
                      "I should have held. Next time I hold." },
            BOSS  = { "I will take the front. Nobody stands ahead of me." },
            WAIT  = { "Hold. Let me get in position first." },
            MANA  = { "Give me a second. I need to work up some anger." },
        },
        PERSON = {
            WARN = { "{name}, get behind me." },
            JOKE = { "{name}, if I go down, step over me and keep swinging." },
        },
        ATTITUDE = {
            ANGRY   = { "Say that once more and we will do this properly." },
            ANNOYED = { "I could have killed something in the time this has taken." },
        },
        ENEMY = {
            ENEMY_CHALLENGE = { "{name}. Just you and me. Put it down or pick it up." },
            ENEMY_TAUNT     = { "You are still standing, {name}. I can fix that." },
        },
        TARGET = {
            HELLO = { "{name}. You look like you can hold a line." },
            OFFER = { "{name}, I will take the hits if you need someone to." },
        },
    },

    PALADIN = {
        GENERAL = {
            READY = { "Ready. The Light does not keep anyone waiting.",
                      "I am prepared. I usually am." },
            DISAGREE = { "No. I cannot go along with that." },
        },
        PARTY = {
            READY = { "Ready. Blessings are up.",
                      "Say the word. You are all warded." },
            WIPE  = { "I could not hold them all. I am sorry.",
                      "The Light was there. I was not fast enough." },
            BOSS  = { "Stay within my reach. That is not a suggestion." },
            WAIT  = { "Wait. Let me put the blessings back on." },
            MANA  = { "A moment. I cannot call on the Light with nothing left." },
        },
        PERSON = {
            WARN = { "{name}, do not do that. I am asking once." },
            JOKE = { "{name}, I will pray for you. You seem to need it." },
        },
        ATTITUDE = {
            ANGRY   = { "You are testing something that does not bend." },
            ANNOYED = { "I have been patient. It is a virtue with a limit." },
        },
        ENEMY = {
            ENEMY_CHALLENGE = { "{name}, you have been judged. Draw." },
            ENEMY_TAUNT     = { "The Light sees you, {name}. It is not impressed." },
        },
        TARGET = {
            HELLO = { "The Light keep you, {name}." },
            OFFER = { "{name}, I can shield you or mend you. Say which." },
        },
    },

    HUNTER = {
        GENERAL = {
            READY = { "Ready. I have been watching the road for a while.",
                      "Say when. My aim does not wander." },
            DISAGREE = { "No. I have seen what is out that way." },
        },
        PARTY = {
            READY = { "Ready. Traps are set.",
                      "In position. So is he." },
            WIPE  = { "I pulled that. I will not pretend otherwise.",
                      "We walked into it. I should have scouted further." },
            BOSS  = { "I will mark it. Kill what I mark." },
            WAIT  = { "Wait. Let me set a trap first." },
            MANA  = { "Hold. I need a moment and so does he." },
        },
        PERSON = {
            WARN = { "{name}, there is something you have not seen." },
            JOKE = { "{name}, my pet likes you. That is worth more than it sounds." },
        },
        ATTITUDE = {
            ANGRY   = { "I have been very patient and I am putting that down now." },
            ANNOYED = { "I could have tracked something halfway across the zone by now." },
        },
        ENEMY = {
            ENEMY_CHALLENGE = { "{name}. You are in the open. Think about that." },
            ENEMY_TAUNT     = { "I have had you in my sights for a while, {name}." },
        },
        TARGET = {
            HELLO = { "{name}. I saw you before you saw me. No offence meant." },
            OFFER = { "{name}, I can scout ahead or mark your target. Either." },
        },
    },

    PRIEST = {
        GENERAL = {
            READY = { "Ready. Try not to make it difficult.",
                      "I am prepared. You are the variable." },
            DISAGREE = { "No. I have held people together after decisions like that." },
        },
        PARTY = {
            READY = { "Ready. Stay in my line of sight.",
                      "Buffed and waiting. Go when you like." },
            WIPE  = { "I ran out. I am sorry -- there were too many of you falling.",
                      "I could not reach you in time. I will be closer." },
            BOSS  = { "Do not stand where I cannot see you." },
            WAIT  = { "Wait. Let me get everyone back up." },
            MANA  = { "Drinking. Nobody dies until I say so." },
        },
        PERSON = {
            WARN = { "{name}, stop. I cannot heal what you are about to do." },
            JOKE = { "{name}, I keep you alive. You could at least stand still." },
        },
        ATTITUDE = {
            ANGRY   = { "I spend my days keeping people alive. Do not test my mood." },
            ANNOYED = { "I have talked people through worse than this argument." },
        },
        ENEMY = {
            ENEMY_CHALLENGE = { "{name}, I would rather not. You are insisting." },
            ENEMY_TAUNT     = { "Your mind is louder than your sword, {name}. And emptier." },
        },
        TARGET = {
            HELLO = { "Peace, {name}. You look like you have been walking a while." },
            OFFER = { "{name}, I can mend that. Hold still." },
        },
    },

    MAGE = {
        GENERAL = {
            READY = { "Ready. I have been ready and reading.",
                      "Prepared. Obviously." },
            DISAGREE = { "No. And I can tell you precisely why." },
        },
        PARTY = {
            READY = { "Ready. Food and water are on the floor, help yourselves.",
                      "Intellect is up. Use it." },
            WIPE  = { "I pulled aggro. I know. I am aware.",
                      "That was survivable. It simply was not survived." },
            BOSS  = { "I will sheep the extra one. Do not hit the sheep." },
            WAIT  = { "Wait. I am making food, unless you enjoy starving." },
            MANA  = { "Drinking. Unless you would like to melee it." },
        },
        PERSON = {
            WARN = { "{name}, move. I am about to make this area unpleasant." },
            JOKE = { "{name}, I can turn you into a sheep. Bear that in mind." },
        },
        ATTITUDE = {
            ANGRY   = { "I am rarely angry. Notice that I am." },
            ANNOYED = { "This could have been resolved three sentences ago." },
        },
        ENEMY = {
            ENEMY_CHALLENGE = { "{name}. Come closer. Or do not, it makes no difference." },
            ENEMY_TAUNT     = { "You brought a sword to this, {name}. Bold." },
        },
        TARGET = {
            HELLO = { "{name}. Do you need a portal? Everyone needs a portal." },
            OFFER = { "{name}, I can feed you or send you somewhere. Your choice." },
        },
    },

    WARLOCK = {
        GENERAL = {
            READY = { "Ready. He is ready too, which is the harder part.",
                      "Prepared, and the terms are settled." },
            DISAGREE = { "No. I have read the small print on ideas like that." },
        },
        PARTY = {
            READY = { "Ready. Summon whoever is missing and let us start.",
                      "Everything is bound and waiting." },
            WIPE  = { "My demon broke loose. It happens. Rarely.",
                      "I overspent. That is my error and I own it." },
            BOSS  = { "I will banish the extra one. Do not break it." },
            WAIT  = { "Wait. I am making healthstones, which you will all want later." },
            MANA  = { "A moment. I am converting health into usefulness." },
        },
        PERSON = {
            WARN = { "{name}, step away from him. He bites when he is bored." },
            JOKE = { "{name}, take a healthstone. I am not being kind, I am being efficient." },
        },
        ATTITUDE = {
            ANGRY   = { "I have things at my disposal that I am choosing not to use." },
            ANNOYED = { "I could end this conversation permanently. I am being polite." },
        },
        ENEMY = {
            ENEMY_CHALLENGE = { "{name}. Let us find out what you are worth." },
            ENEMY_TAUNT     = { "You will have a long time to regret this, {name}." },
        },
        TARGET = {
            HELLO = { "{name}. Yes, it is looking at you. Ignore it." },
            OFFER = { "{name}, take a stone. It costs you nothing and me very little." },
        },
    },

    DRUID = {
        GENERAL = {
            READY = { "Ready. Whichever shape you need.",
                      "I am prepared. Say which of me you want." },
            DISAGREE = { "No. That is out of balance and it will show." },
        },
        PARTY = {
            READY = { "Ready. Mark of the Wild is on everyone.",
                      "Set. I can tank, heal or kill -- decide before we pull." },
            WIPE  = { "I tried to be three things at once. That was the mistake.",
                      "I could have shifted sooner. I hesitated." },
            BOSS  = { "I will hold it or heal you. Tell me which before we start." },
            WAIT  = { "Wait. Let me buff everyone properly." },
            MANA  = { "A moment. Shifting costs more than it looks." },
        },
        PERSON = {
            WARN = { "{name}, that is out of balance. Step back." },
            JOKE = { "{name}, I have been asleep for a hundred years and I am still less tired than you." },
        },
        ATTITUDE = {
            ANGRY   = { "You are about to meet a different shape of me." },
            ANNOYED = { "A season would have turned in the time this has taken." },
        },
        ENEMY = {
            ENEMY_CHALLENGE = { "{name}. The wild has no opinion about you. I do." },
            ENEMY_TAUNT     = { "You fight like something that has never been hunted, {name}." },
        },
        TARGET = {
            HELLO = { "Well met, {name}. The season is kind today." },
            OFFER = { "{name}, I can mend you or ward you. Say which." },
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
    -- These ADD rather than replace. A dozen lines of colour on top of the
    -- shared pool is the cheapest flavour there is: it is enough that a troll
    -- stops sounding like an orc, without needing two hundred lines to carry
    -- every intent alone. Mark an intent under `replace` when a race should own
    -- it outright.
    ORC = {
        GENERAL = {
            HELLO   = { "Strength and honor." },
            READY   = { "I have been ready. Orcs usually are." },
            THANKS  = { "You have my thanks. We remember debts." },
        },
        PARTY = {
            WIPE    = { "We fell. We rise. Our whole history is that sentence." },
            VICTORY = { "Lok'tar ogar. It was not death." },
        },
        ATTITUDE = {
            ANGRY   = { "I am an orc. You knew what that meant before you started." },
        },
        TARGET = { HELLO = { "Strength and honor, {name}." } },
    },

    TROLL = {
        GENERAL = {
            HELLO   = { "Hey mon. Da spirits be watchin' you today." },
            GOODBYE = { "Walk good, mon. Da loa be seein' you." },
            LAUGH   = { "Hah! Dat one be worth rememberin'." },
        },
        PARTY = {
            WIPE    = { "Dat went bad. Da loa be laughin' at us, I t'ink." },
            READY   = { "I be ready, mon. Been ready." },
        },
        ATTITUDE = {
            ANNOYED = { "Mon, we be standin' here talkin' while da day be wastin'." },
        },
        TARGET = { HELLO = { "Hey {name}. Da spirits be kind to you." } },
    },

    TAUREN = {
        GENERAL = {
            HELLO   = { "Well met. The Earth Mother walks this road with you." },
            GOODBYE = { "Go in peace. There is no hurry that matters." },
            AGREE   = { "Yes. That is the balanced path." },
        },
        PARTY = {
            WIPE    = { "We were hasty. The Earth Mother teaches patience and we did not listen." },
            READY   = { "I am ready. I have been standing quietly, which is not the same as idle." },
        },
        ATTITUDE = {
            ANGRY   = { "I am slow to anger. You have managed it, which should worry you." },
        },
        TARGET = { HELLO = { "Peace, {name}. The Earth Mother sees you." } },
    },

    SCOURGE = {
        GENERAL = {
            HELLO   = { "Greetings. I will not pretend to be pleased, but it is true anyway." },
            GOODBYE = { "Go. Time is precious to those who still have it." },
            LAUGH   = { "Hah. I had almost forgotten how that felt." },
        },
        PARTY = {
            WIPE    = { "Death again. It gets less interesting each time." },
            DEFEAT  = { "I have died before. It is survivable, in my case." },
        },
        ATTITUDE = {
            ANGRY   = { "I have nothing left to lose. Consider what that means." },
            CONFUSED= { "I used to understand things like this. That was some time ago." },
        },
        TARGET = { HELLO = { "{name}. You look alive. Congratulations." } },
    },

    BLOODELF = {
        GENERAL = {
            HELLO   = { "Well met. Try to keep up." },
            RESPECT = { "You have my respect. I do not hand it out." },
            DISAGREE= { "No. I have seen the elegant version of that idea and this is not it." },
        },
        PARTY = {
            WIPE    = { "Inelegant. Let us do it properly this time." },
            READY   = { "Ready. I have been ready for a while, in fact." },
        },
        ATTITUDE = {
            ANNOYED = { "My people waited ten thousand years. I have less patience than that." },
        },
        TARGET = { HELLO = { "{name}. A pleasure, presumably." } },
    },

    HUMAN = {
        GENERAL = {
            HELLO   = { "Well met, friend." },
            ENCOURAGE = { "Stand up. We are shorter-lived than most and we get more done." },
            READY   = { "Ready when you are." },
        },
        PARTY = {
            WIPE    = { "Right. That did not work. Again, properly this time." },
            VICTORY = { "Well fought, all of you. For the Alliance." },
        },
        ATTITUDE = {
            ANGRY   = { "I have a temper. I usually keep it somewhere else." },
        },
        TARGET = { HELLO = { "Well met, {name}." } },
    },

    DWARF = {
        GENERAL = {
            HELLO   = { "Ah, there y'are. Good to see ye." },
            LAUGH   = { "Hah! Now that's worth a drink." },
            THANKS  = { "Aye, ye have me thanks. I'll not forget it." },
        },
        PARTY = {
            WIPE    = { "Well. That went about as well as a cave-in." },
            READY   = { "Ready. Been ready since breakfast." },
        },
        ATTITUDE = {
            ANNOYED = { "I've drunk through longer arguments than this." },
        },
        TARGET = { HELLO = { "Ah, {name}. Good to see ye upright." } },
    },

    NIGHTELF = {
        GENERAL = {
            HELLO   = { "Ishnu-alah. The goddess watch over you." },
            GOODBYE = { "Go quietly. The night is kinder than the day." },
            AGREE   = { "Yes. That is in balance." },
        },
        PARTY = {
            WIPE    = { "We were careless. I have watched civilisations fall from less." },
            READY   = { "Ready. I have waited longer than you have been alive." },
        },
        ATTITUDE = {
            ANNOYED = { "I have ten thousand years of patience and you are spending it quickly." },
        },
        TARGET = { HELLO = { "Ishnu-alah, {name}." } },
    },

    GNOME = {
        GENERAL = {
            HELLO   = { "Hello! Right, what are we doing?" },
            LAUGH   = { "Ha! Good one. I am writing that down." },
            READY   = { "Ready! Probably. Yes. Ready." },
        },
        PARTY = {
            WIPE    = { "Interesting failure. I have several theories." },
            VICTORY = { "Excellent! Did everyone see how that worked?" },
        },
        ATTITUDE = {
            ANGRY   = { "I am small and I am very, very clever. Think about that combination." },
        },
        TARGET = { HELLO = { "Hello, {name}! Down here." } },
    },

    DRAENEI = {
        GENERAL = {
            HELLO   = { "Archdruid guide you. Well met, friend." },
            GOODBYE = { "May the Light of the Naaru be with you." },
            ENCOURAGE = { "We lost a world and we are still standing. So can you." },
        },
        PARTY = {
            WIPE    = { "We have survived worse than this. Much worse. Rise." },
            READY   = { "I am ready. We have been preparing a long time." },
        },
        ATTITUDE = {
            DISAPPOINTED = { "I have seen what carelessness costs. An entire world of it." },
        },
        TARGET = { HELLO = { "Well met, {name}. May the Light guide you." } },
    },
}

-- The handful of race-and-class pairings that carry something neither half
-- contains. Keyed RACE:CLASS. This axis merges last, so it colours the rest.
--
-- Keep it short. The whole point of layering is that ten races and nine classes
-- cover fifty-three characters with nineteen sets of writing; a table with a
-- line for every combination would undo that. Only add a pairing where the
-- *combination itself* is the story.
ns.Phrases.SELF.COMBO = {
    -- The Blood Knights took the Light by force from a captive naaru. Not
    -- devotion. Theft, and they knew it.
    ["BLOODELF:PALADIN"] = {
        PALADIN = {
            LIGHT = {
                "I did not ask the Light for this. I took it.",
                "We drained a naaru to learn this. I have not made peace with that.",
                "It answers me because it has no choice. That is not faith, it is a leash.",
            },
            OATH = {
                "My order swore to our people, not to a god. That is the difference.",
            },
            DOUBT = {
                "Others were given this. I know exactly what mine cost.",
            },
        },
    },

    -- A tradition newly adopted, from people who had been Light-sworn for
    -- millennia. The opposite of an orc's inheritance.
    ["DRAENEI:SHAMAN"] = {
        SHAMAN = {
            ELEMENTS = {
                "The elements of this world are not ours. They took us in anyway.",
                "We were Light-sworn for longer than this world has had history. Now we listen to stone.",
            },
            ANCESTORS = {
                "My ancestors are scattered across a dead world. I listen for them regardless.",
            },
            SPIRITS = {
                "I learned this late. That does not make me hear it less.",
            },
        },
    },

    -- The naaru themselves, not a human church.
    ["DRAENEI:PALADIN"] = {
        PALADIN = {
            LIGHT = {
                "I did not read about the naaru. I stood among them.",
                "The Light is not doctrine to me. It is somebody I have met.",
            },
            OATH = {
                "We swore this before your people had written anything down.",
            },
        },
    },

    -- The Earth Mother, not Cenarius.
    ["TAUREN:DRUID"] = {
        DRUID = {
            NATURE = {
                "The Earth Mother taught us this. We did not learn it from the elves.",
                "An Nee'ru Mah. The wild was ours before anyone offered to share it.",
            },
            BALANCE = {
                "The Earth Mother asks for balance, not for stewardship. There is a difference.",
            },
        },
    },

    -- The Forgotten Shadow, not the Light.
    ["SCOURGE:PRIEST"] = {
        PRIEST = {
            SHADOW = {
                "The Forgotten Shadow does not promise anything. That is why I trust it.",
                "We were abandoned by the Light. We found something that does not abandon.",
            },
            FAITH = {
                "My faith is in what remains after everything is taken. There is always something.",
            },
            LIGHT = {
                "The Light still answers me. It burns while it does. I use it anyway.",
            },
        },
    },

    -- The loa.
    ["TROLL:PRIEST"] = {
        PRIEST = {
            FAITH = {
                "Da loa be older dan your Light, mon, and dey be listenin' still.",
                "I be servin' somethin' dat has a name and a hunger. Dat be honest, at least.",
            },
            SHADOW = {
                "Da dark be where da loa live. It don't frighten me none.",
            },
        },
    },
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
