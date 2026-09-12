-- Standalone harness: loads Settings + RP/* with stubs and hammers the engine.
local DIR = "../Silvertongue/"
local ns = {}

-- Minimal WoW API stubs the RP layer touches.
IsInGroup = function() return true end
IsInRaid = function() return false end
IsInInstance = function() return true end
UnitExists = function(u) return u == "party1" end
UnitClass = function() return "Warlock", "WARLOCK" end
UnitRace = function() return "Orc", "Orc" end
UnitName = function() return "Morghul" end

-- The character the harness is "logged in" as; flipped below to test several.
local playerClass, playerRace, playerFaction = "SHAMAN", "Orc", "Horde"
local realUnitClass, realUnitRace = UnitClass, UnitRace
UnitClass = function(unit)
    if unit == "player" then return playerClass:sub(1,1) .. playerClass:sub(2):lower(), playerClass end
    return realUnitClass(unit)
end
UnitRace = function(unit)
    if unit == "player" then return playerRace, playerRace end
    return realUnitRace(unit)
end
UnitFactionGroup = function() return playerFaction end

local function load(file)
    local chunk = assert(loadfile(DIR .. file))
    return chunk("Silvertongue", ns)
end

load("Settings.lua")
for _, f in ipairs({"Engine", "General", "Party", "Horde", "Shaman", "Rogue", "Warrior", "Paladin", "Hunter", "Priest", "Mage", "Warlock", "Druid", "Attitude", "Classes", "Races", "Target", "Self", "Alliance", "Dungeons", "Group", "Emotes"}) do
    load("RP/" .. f .. ".lua")
end

ns.addon = { db = { profile = { favorites = {} } } }
local Engine = ns.Engine
math.randomseed(1234)

local errors, total, pools = 0, 0, 0
local function fail(fmt, ...) errors = errors + 1; print("FAIL: " .. string.format(fmt, ...)) end

-- Count the whole library and check every line individually.
local function checkLine(where, line)
    total = total + 1
    if #line > 255 then fail("%s: over 255 bytes: %s", where, line) end
    if line:match("^%s") or line:match("%s$") then fail("%s: stray whitespace: %q", where, line) end
    -- Anything the engine can actually substitute. A variable outside this set
    -- would reach chat as a literal placeholder.
    local KNOWN = { name = true, race = true, class = true, level = true,
                    have = true, needs = true, dungeon = true, missing = true }
    for var in line:gmatch("{(%w+)}") do
        if not KNOWN[var] then fail("%s: unknown variable {%s}", where, var) end
    end
end

-- Every target-directed line must name the person. Silvertongue speaks these in
-- say, where bystanders cannot tell who he meant otherwise.
for _, category in ipairs({"TARGET", "ENEMY", "PERSON"}) do
    for intent, lines in pairs(ns.Phrases[category]) do
        for _, line in ipairs(lines) do
            if not line:find("{name}", 1, true) then
                fail("%s.%s does not name the target: %s", category, intent, line)
            end
        end
    end
end
for raceToken, pools in pairs(ns.Phrases.RACE) do
    for intent, lines in pairs(pools) do
        if intent:sub(1, 6) == "ENEMY_" then
            for _, line in ipairs(lines) do
                if not line:find("{name}", 1, true) then
                    fail("RACE.%s.%s does not name the target: %s", raceToken, intent, line)
                end
            end
        end
    end
end

for category, intents in pairs(ns.Phrases) do
    for intent, value in pairs(intents) do
        if category == "SELF" then
            -- SELF.<axis>.<token>.<category>.<intent>
            for token, byCategory in pairs(value) do
                for cat, subPools in pairs(byCategory) do
                  if cat ~= "replace" then
                    for subIntent, lines in pairs(subPools) do
                        pools = pools + 1
                        for _, l in ipairs(lines) do
                            checkLine("SELF."..intent.."."..token.."."..cat.."."..subIntent, l)
                        end
                    end
                  end
                end
            end
        elseif category == "CLASS" or category == "RACE" then
            for sub, lines in pairs(value) do
                pools = pools + 1
                for _, l in ipairs(lines) do checkLine(category.."."..intent.."."..sub, l) end
            end
        else
            pools = pools + 1
            if #value < 5 then fail("%s.%s has only %d phrases", category, intent, #value) end
            for _, l in ipairs(value) do checkLine(category.."."..intent, l) end
        end
    end
end

-- Exercise every undirected intent: 30 rerolls, no unresolved vars, no immediate repeat.
local UNDIRECTED = {"GENERAL", "PARTY", "HORDE", "SHAMAN", "ATTITUDE"}
local DIRECTED = {"TARGET", "ENEMY"}
for _, category in ipairs(UNDIRECTED) do
    for intent in pairs(ns.Phrases[category]) do
        local text = Engine:Request(category, intent, nil)
        if not text then fail("%s.%s returned nothing", category, intent) end
        local prev = text
        for i = 1, 30 do
            local t = Engine:Reroll()
            if not t then fail("%s.%s reroll returned nothing", category, intent) break end
            if t:find("{") then fail("%s.%s unresolved variable: %s", category, intent, t) end
            if t == prev then fail("%s.%s repeated immediately: %s", category, intent, t) end
            prev = t
        end
    end
end

-- Target and enemy pools, with a context standing in for the selected unit.
local targetCtx = { name = "Gromkar", classToken = "WARRIOR", raceToken = "ORC" }
for _, category in ipairs(DIRECTED) do
    for intent in pairs(ns.Phrases[category]) do
        local text = Engine:Request(category, intent, targetCtx)
        if not text then fail("%s.%s returned nothing", category, intent) end
        local prev = text
        for i = 1, 30 do
            local t = Engine:Reroll()
            if not t then fail("%s.%s reroll returned nothing", category, intent) break end
            if t:find("{") then fail("%s.%s unresolved variable: %s", category, intent, t) end
            if not t:find("Gromkar", 1, true) then fail("%s.%s lost the name: %s", category, intent, t) end
            if t == prev then fail("%s.%s repeated immediately: %s", category, intent, t) end
            prev = t
        end
    end
end

-- An Alliance target must pull its race lines into the enemy pools.
local elfCtx = { name = "Aelindra", raceToken = "NIGHTELF" }
local seenElf = {}
for i = 1, 400 do
    Engine:Request("ENEMY", "ENEMY_TAUNT", elfCtx)
    seenElf[Engine:GetCurrentTemplate()] = true
end
local elfCount = 0
for _ in pairs(seenElf) do elfCount = elfCount + 1 end
if elfCount <= #ns.Phrases.ENEMY.ENEMY_TAUNT then
    fail("night elf taunts never reached the pool (%d seen, %d generic)", elfCount, #ns.Phrases.ENEMY.ENEMY_TAUNT)
end

-- A creature has no class or race token; the generic pool must still serve it.
local mobCtx = { name = "Ragged Timber Wolf" }
for intent in pairs(ns.Phrases.ENEMY) do
    local t = Engine:Request("ENEMY", intent, mobCtx)
    if not t then fail("ENEMY.%s produced nothing for a creature", intent) end
    if t:find("{") then fail("ENEMY.%s unresolved variable for a creature: %s", intent, t) end
end

-- Directed intents with a warlock context: must resolve {name} and pull class lines.
local ctx = Engine:BuildUnitContext("party1")
if ctx.classToken ~= "WARLOCK" then fail("context class token wrong: %s", tostring(ctx.classToken)) end
local sawClassLine = false
for intent in pairs(ns.Phrases.PERSON) do
    local text = Engine:Request("PERSON", intent, ctx)
    if not text then fail("PERSON.%s returned nothing", intent) end
    local prev = text
    for i = 1, 30 do
        local t = Engine:Reroll()
        if t:find("{") then fail("PERSON.%s unresolved variable: %s", intent, t) end
        if t == prev then fail("PERSON.%s repeated immediately: %s", intent, t) end
        if #t > 255 then fail("PERSON.%s over 255 bytes after fill: %s", intent, t) end
        prev = t
    end
end
for _, intent in ipairs({"DISTRUST", "DEMON", "FEL_MAGIC"}) do
    local t = Engine:Request("PERSON", intent, ctx)
    if not t then fail("warlock-only intent %s produced nothing", intent) end
    sawClassLine = true
end
-- Class lines must supplement, not replace: praise pool should exceed the generic one.
local genericPraise = #ns.Phrases.PERSON.PRAISE
local seen = {}
for i = 1, 400 do
    Engine:Request("PERSON", "PRAISE", ctx)
    seen[Engine:GetCurrentTemplate()] = true
end
local count = 0
for _ in pairs(seen) do count = count + 1 end
if count <= genericPraise then
    fail("class praise lines not reaching the pool (%d seen, %d generic)", count, genericPraise)
end

-- Class flagging. The overlay must reach its own class and no other.
local function poolFor(category, intent)
    local seen = {}
    for i = 1, 600 do
        Engine:Request(category, intent, nil)
        seen[Engine:GetCurrentTemplate()] = true
    end
    return seen
end

local SHAMAN_ONLY = "Totems are down. I am set."
local ROGUE_ONLY  = "Ready. I have been in position for some time."

playerClass = "SHAMAN"
Engine:ForgetPlayer()
local asShaman = poolFor("PARTY", "READY")
if not asShaman[SHAMAN_ONLY] then fail("a shaman never got his own READY line") end
if asShaman[ROGUE_ONLY] then fail("a shaman was served a rogue line") end

playerClass = "ROGUE"
Engine:ForgetPlayer()
local asRogue = poolFor("PARTY", "READY")
if not asRogue[ROGUE_ONLY] then fail("a rogue never got his own READY line") end
if asRogue[SHAMAN_ONLY] then fail("a rogue was served a shaman line") end

-- No shared pool may carry words belonging to one people. The pool started as
-- one orc's voice and those lines have been moved to where they belong; this
-- keeps them from drifting back. A line that needs a people behind it goes in a
-- race layer, not in the pool everybody draws on.
local RACIAL = { "ancestor", "spirit", "horde", "orc", "warband", "thrall", "lok'tar", "kodo" }
for _, category in ipairs({"GENERAL", "PARTY", "ATTITUDE", "PERSON", "TARGET", "ENEMY", "LFG"}) do
    for intent, lines in pairs(ns.Phrases[category]) do
        for _, line in ipairs(lines) do
            for _, word in ipairs(RACIAL) do
                if line:lower():find(word, 1, true) then
                    fail("%s.%s is shared but belongs to one people: %s", category, intent, line)
                end
            end
        end
    end
end

-- No shared pool may still carry class-specific words for everyone.
local LEAKS = { "totem", "Totem", "the elements", "The elements" }
for _, category in ipairs({"GENERAL", "PARTY", "HORDE", "ATTITUDE", "PERSON", "TARGET", "ENEMY"}) do
    for intent, lines in pairs(ns.Phrases[category]) do
        for _, line in ipairs(lines) do
            for _, word in ipairs(LEAKS) do
                if line:find(word, 1, true) then
                    fail("%s.%s is shared but shaman-only: %s", category, intent, line)
                end
            end
        end
    end
end

-- The rogue class tab must be complete and free of unresolved variables.
playerClass = "ROGUE"
Engine:ForgetPlayer()
for intent in pairs(ns.Phrases.ROGUE) do
    local text = Engine:Request("ROGUE", intent, nil)
    if not text then fail("ROGUE.%s returned nothing", intent) end
    for i = 1, 20 do
        local t = Engine:Reroll()
        if t:find("{") then fail("ROGUE.%s unresolved variable: %s", intent, t) end
    end
end
playerClass = "SHAMAN"
Engine:ForgetPlayer()

-- Faction. A Horde greeting must not reach an Alliance character, and each
-- faction tab must have something to say on every intent its grid declares.
HORDE_ONLY = "Lok'tar. You look like you have somewhere to be."
playerFaction = "HORDE"
Engine:ForgetPlayer()
local hordeHello = poolFor("GENERAL", "HELLO")
if not hordeHello[HORDE_ONLY] then fail("a Horde character never got the Horde greeting") end

playerFaction = "ALLIANCE"
Engine:ForgetPlayer()
local allianceHello = poolFor("GENERAL", "HELLO")
if allianceHello[HORDE_ONLY] then fail("an Alliance character was served a Horde greeting") end

for _, faction in ipairs({"HORDE", "ALLIANCE"}) do
    for intent, lines in pairs(ns.Phrases[faction]) do
        if #lines < 3 then fail("%s.%s has only %d phrases", faction, intent, #lines) end
    end
end
playerFaction = "HORDE"
Engine:ForgetPlayer()

-- Replacing. A race that declares an intent under `replace` must own it
-- outright: none of the shared lines may survive.
local TAUREN_ONLY = "Well met. The Earth Mother walks this road with you."
ns.Phrases.SELF.RACE.TAUREN = {
    replace = { GENERAL = { HELLO = true } },
    GENERAL = { HELLO = { TAUREN_ONLY, "Peace, friend. There is no hurry here." } },
}
ns.Phrases.SELF.RACE.TROLL = {
    GENERAL = { HELLO = { "Hey mon. Da spirits be watchin' you." } },
}

local sharedHello = ns.Phrases.GENERAL.HELLO[1]

playerRace, playerFaction = "Tauren", "Horde"
Engine:ForgetPlayer()
local asTauren = poolFor("GENERAL", "HELLO")
if not asTauren[TAUREN_ONLY] then fail("a tauren never got his own greeting") end
if asTauren[sharedHello] then fail("a replacing race still served the shared line") end
-- Layers merge class, then race, then faction, and a replace wipes only what
-- came before it. So faction flavour survives a race takeover on purpose: a
-- tauren in the Horde still says Lok'tar.
if not asTauren[HORDE_ONLY] then fail("a race takeover swallowed the faction line") end

-- And a faction can take over in turn, over the top of a race.
ns.Phrases.SELF.FACTION.HORDE.replace = { GENERAL = { HELLO = true } }
Engine:ForgetPlayer()
local factionWins = poolFor("GENERAL", "HELLO")
if factionWins[TAUREN_ONLY] then fail("a faction takeover left the race lines behind") end
if not factionWins[HORDE_ONLY] then fail("a faction takeover served nothing of its own") end
ns.Phrases.SELF.FACTION.HORDE.replace = nil

-- A race that only adds keeps the shared pool underneath it.
playerRace = "Troll"
Engine:ForgetPlayer()
local asTroll = poolFor("GENERAL", "HELLO")
if not asTroll["Hey mon. Da spirits be watchin' you."] then fail("a troll never got his own line") end
if not asTroll[sharedHello] then fail("an adding race lost the shared pool") end

-- A race with nothing written falls back to the shared pool rather than going
-- silent, which is what keeps an unwritten race usable.
playerRace = "Scourge"
Engine:ForgetPlayer()
if not poolFor("GENERAL", "HELLO")[sharedHello] then fail("an unwritten race got no lines at all") end

ns.Phrases.SELF.RACE.TAUREN, ns.Phrases.SELF.RACE.TROLL = nil, nil
playerRace = "Orc"
Engine:ForgetPlayer()

-- The combination axis. A blood elf paladin says something no other paladin and
-- no other blood elf says, and nobody else gets it.
local BLOOD_KNIGHT = "I did not ask the Light for this. I took it."
playerRace, playerClass, playerFaction = "BloodElf", "PALADIN", "Horde"
Engine:ForgetPlayer()
local asBloodKnight = poolFor("PALADIN", "LIGHT")
if not asBloodKnight[BLOOD_KNIGHT] then fail("a blood elf paladin never got his own line") end

playerRace = "Human"
playerFaction = "Alliance"
Engine:ForgetPlayer()
if poolFor("PALADIN", "LIGHT")[BLOOD_KNIGHT] then fail("a human paladin was given the Blood Knight line") end

playerRace, playerClass, playerFaction = "BloodElf", "MAGE", "Horde"
Engine:ForgetPlayer()
if poolFor("PALADIN", "LIGHT")[BLOOD_KNIGHT] then fail("a blood elf mage was given the paladin line") end

-- And the axis stays small on purpose: it is the escape hatch, not the model.
local combos = 0
for _ in pairs(ns.Phrases.SELF.COMBO) do combos = combos + 1 end
if combos > 12 then
    fail("%d combinations written; layering is meant to avoid needing a table of them", combos)
end

playerRace, playerClass, playerFaction = "Orc", "SHAMAN", "Horde"
Engine:ForgetPlayer()

-- Phrases you write yourself, in four scopes that mirror the four layers.
ns.addon.db.profile.custom = {}
local MINE = "I have decided to say this instead."

playerClass, playerRace, playerFaction = "SHAMAN", "Orc", "Horde"
Engine:ForgetPlayer()
local seededCount = #ns.Phrases.GENERAL.THANKS

local ok = Engine:AddPhrase("GENERAL", "THANKS", MINE, "CLASS")
if not ok then fail("adding a phrase was refused") end
if Engine:AddPhrase("GENERAL", "THANKS", MINE, "CLASS") then fail("the same phrase was added twice") end
if not Engine:IsCustom("GENERAL", "THANKS", MINE) then fail("the added phrase was not recorded as custom") end

local withMine = poolFor("GENERAL", "THANKS")
if not withMine[MINE] then fail("the added phrase never came up") end

-- A class line reaches every race of that class, and no other class.
playerRace = "Troll"
Engine:ForgetPlayer()
if not poolFor("GENERAL", "THANKS")[MINE] then fail("a class line did not reach a troll shaman") end
playerRace = "Orc"
playerClass = "ROGUE"
Engine:ForgetPlayer()
if poolFor("GENERAL", "THANKS")[MINE] then fail("a shaman's class line leaked to the rogue") end

-- A race line reaches every class of that race, and no other race.
local ORCISH = "Strength and honor, brother."
Engine:AddPhrase("GENERAL", "THANKS", ORCISH, "RACE")
if not poolFor("GENERAL", "THANKS")[ORCISH] then fail("a race line did not reach the orc rogue that wrote it") end
playerClass = "SHAMAN"
Engine:ForgetPlayer()
if not poolFor("GENERAL", "THANKS")[ORCISH] then fail("a race line did not reach the orc shaman") end
playerRace = "Troll"
Engine:ForgetPlayer()
if poolFor("GENERAL", "THANKS")[ORCISH] then fail("an orc line leaked to a troll") end

-- A faction line reaches the whole faction and stops there.
playerRace = "Orc"
Engine:ForgetPlayer()
local HORDE_LINE = "The Warchief would approve of that."
Engine:AddPhrase("GENERAL", "THANKS", HORDE_LINE, "FACTION")
playerRace, playerClass = "Troll", "ROGUE"
Engine:ForgetPlayer()
if not poolFor("GENERAL", "THANKS")[HORDE_LINE] then fail("a faction line did not reach another Horde character") end
playerRace, playerFaction = "Human", "Alliance"
Engine:ForgetPlayer()
if poolFor("GENERAL", "THANKS")[HORDE_LINE] then fail("a Horde line leaked to an Alliance character") end

-- An ALL line reaches everyone.
local EVERYONE = "That will do."
Engine:AddPhrase("GENERAL", "THANKS", EVERYONE, "ALL")
if not poolFor("GENERAL", "THANKS")[EVERYONE] then fail("an ALL line did not reach the character that wrote it") end
playerRace, playerClass, playerFaction = "Orc", "SHAMAN", "Horde"
Engine:ForgetPlayer()
if not poolFor("GENERAL", "THANKS")[EVERYONE] then fail("an ALL line did not reach another character") end

-- Dropping inherits the scope the origin names.
if Engine:ScopeForOrigin("shared") ~= "ALL" then fail("a shared line does not drop for everyone") end
if Engine:ScopeForOrigin("your class") ~= "CLASS" then fail("a class line does not drop per class") end
if Engine:ScopeForOrigin("your race") ~= "RACE" then fail("a race line does not drop per race") end
if Engine:ScopeForOrigin("your faction") ~= "FACTION" then fail("a faction line does not drop per faction") end
if Engine:ScopeForOrigin("their class") ~= "ALL" then fail("a target-class line should drop for everyone") end

-- A shared line dropped on one character is gone on all of them.
local SHARED = ns.Phrases.GENERAL.THANKS[1]
Engine:HidePhrase("GENERAL", "THANKS", SHARED, "ALL")
playerClass = "ROGUE"
Engine:ForgetPlayer()
if poolFor("GENERAL", "THANKS")[SHARED] then fail("a shared line dropped as ALL survived on another class") end
playerClass = "SHAMAN"
Engine:ForgetPlayer()

-- Every line says which scope it came from, which is what the window reads.
local described = Engine:DescribePool("GENERAL", "THANKS", nil)
local sawScope = {}
for _, entry in ipairs(described) do sawScope[entry.origin] = true end
if not sawScope["yours shaman"] then fail("a class line is not tagged with its scope") end
if not sawScope["yours orc"] then fail("a race line is not tagged with its scope") end
if not sawScope["yours all my characters"] then fail("an ALL line is not tagged with its scope") end

-- Saved variables from before scopes existed are moved, not lost.
ns.addon.db.profile.custom = { SHAMAN = { GENERAL = { HELLO = { added = { "Old line." }, hidden = {} } } } }
Engine:MigrateCustom(ns.addon.db)
if ns.addon.db.profile.custom.SHAMAN then fail("the old class key was left behind") end
if not (ns.addon.db.profile.custom.CLASS
        and ns.addon.db.profile.custom.CLASS.SHAMAN) then fail("the old data was not migrated under CLASS") end
if not poolFor("GENERAL", "HELLO")["Old line."] then fail("the migrated line does not come up") end

ns.addon.db.profile.custom = {}

-- Hiding a seeded line takes it out and keeps it out.
local seeded = ns.Phrases.GENERAL.THANKS[1]
Engine:AddPhrase("GENERAL", "THANKS", MINE, "CLASS")
Engine:HidePhrase("GENERAL", "THANKS", seeded, "ALL")
if not Engine:IsHidden("GENERAL", "THANKS", seeded) then fail("the hidden line was not recorded") end
if poolFor("GENERAL", "THANKS")[seeded] then fail("a hidden line still came up") end

-- Hiding your own line deletes it rather than remembering it forever.
Engine:HidePhrase("GENERAL", "THANKS", MINE, "CLASS")
if Engine:IsCustom("GENERAL", "THANKS", MINE) then fail("a dropped custom line survived") end
if Engine:IsHidden("GENERAL", "THANKS", MINE) then fail("a dropped custom line was remembered as hidden") end

-- Adding back something hidden simply restores it.
Engine:AddPhrase("GENERAL", "THANKS", seeded, "ALL")
if Engine:IsHidden("GENERAL", "THANKS", seeded) then fail("re-adding a hidden line did not restore it") end
if not poolFor("GENERAL", "THANKS")[seeded] then fail("the restored line never came back") end

-- Emptying an intent completely must be survivable. Hiding the shared pool is
-- no longer enough on its own: a character's race and class contribute too, so
-- this drops everything the intent can actually reach.
for _, entry in ipairs(Engine:DescribePool("GENERAL", "THANKS", nil)) do
    Engine:HidePhrase("GENERAL", "THANKS", entry.text, "ALL")
end
if Engine:HasAnyPhrase("GENERAL", "THANKS") then fail("the emptied intent still reports phrases") end
if Engine:Request("GENERAL", "THANKS", nil) ~= nil then fail("an emptied intent returned a phrase") end
Engine:AddPhrase("GENERAL", "THANKS", MINE, "CLASS")
if not Engine:HasAnyPhrase("GENERAL", "THANKS") then fail("an intent with only a custom line reports empty") end
if Engine:Request("GENERAL", "THANKS", nil) ~= MINE then fail("the only remaining line was not served") end

ns.addon.db.profile.custom = {}
if #ns.Phrases.GENERAL.THANKS ~= seededCount then fail("the seeded pool was mutated by editing") end

-- Gestures. Resolution order: your choice, then the line's own, then the
-- intent's default. NONE is a value, not an absence.
playerClass, playerRace, playerFaction = "SHAMAN", "Orc", "Horde"
Engine:ForgetPlayer()
ns.addon.db.profile.custom = {}

local thanksLine = ns.Phrases.GENERAL.THANKS[1]
if Engine:EmoteFor("GENERAL", "THANKS", thanksLine) ~= "THANK" then
    fail("Thanks did not take its intent default")
end
if Engine:EmoteFor("PARTY", "WIPE", ns.Phrases.PARTY.WIPE[1]) ~= nil then
    fail("Wipe was given a gesture it should not have")
end

-- A line can override its intent.
ns.Emotes.BY_TEXT[thanksLine] = "KNEEL"
if Engine:EmoteFor("GENERAL", "THANKS", thanksLine) ~= "KNEEL" then
    fail("a line did not override its intent default")
end
ns.Emotes.BY_TEXT[thanksLine] = nil

-- And you can override the line.
Engine:SetEmote("GENERAL", "THANKS", thanksLine, "BOW", "CLASS")
if Engine:EmoteFor("GENERAL", "THANKS", thanksLine) ~= "BOW" then
    fail("your own choice did not win")
end

-- NONE turns off a gesture the line came with.
Engine:SetEmote("GENERAL", "THANKS", thanksLine, ns.EMOTE_NONE, "CLASS")
if Engine:EmoteFor("GENERAL", "THANKS", thanksLine) ~= nil then
    fail("choosing no gesture did not turn it off")
end
if Engine:EmoteChoice("GENERAL", "THANKS", thanksLine) ~= ns.EMOTE_NONE then
    fail("the window would not show the no-gesture choice")
end

-- Clearing falls back rather than meaning none.
Engine:SetEmote("GENERAL", "THANKS", thanksLine, nil, "CLASS")
if Engine:EmoteFor("GENERAL", "THANKS", thanksLine) ~= "THANK" then
    fail("clearing a choice did not fall back to the default")
end

-- The choice is scoped like everything else.
Engine:SetEmote("GENERAL", "THANKS", thanksLine, "BOW", "RACE")
playerClass = "ROGUE"
Engine:ForgetPlayer()
if Engine:EmoteFor("GENERAL", "THANKS", thanksLine) ~= "BOW" then
    fail("a race-scoped gesture did not reach another class of that race")
end
playerRace = "Troll"
Engine:ForgetPlayer()
if Engine:EmoteFor("GENERAL", "THANKS", thanksLine) ~= "THANK" then
    fail("a race-scoped gesture leaked to another race")
end
playerRace, playerClass = "Orc", "SHAMAN"
Engine:ForgetPlayer()
ns.addon.db.profile.custom = {}

-- Writing a line as a table must flatten: a phrase stays a plain string
-- everywhere, or favorites and hiding would stop matching it.
ns.Phrases.GENERAL.TESTPOOL = { "plain", { "fancy", emote = "FLEX" } }
ns.NormalizePhrases()
if type(ns.Phrases.GENERAL.TESTPOOL[2]) ~= "string" then
    fail("a table-form phrase was not flattened to a string")
end
if ns.Phrases.GENERAL.TESTPOOL[2] ~= "fancy" then
    fail("flattening lost the text")
end
if Engine:EmoteFor("GENERAL", "TESTPOOL", "fancy") ~= "FLEX" then
    fail("flattening lost the gesture")
end
ns.Phrases.GENERAL.TESTPOOL = nil

-- Group-finding lines describe you and what the group holds. Every variable
-- they use must resolve, or the channel sees a raw placeholder.
UnitLevel = function() return 36 end
local groupCtx = { name = "Bellaco", raceName = "Orc", className = "Rogue",
                   level = 36, have = "rogue, priest", needs = 3,
                   dungeon = "Scarlet Monastery", missing = "a tank" }
for intent in pairs(ns.Phrases.LFG) do
    local text = Engine:Request("LFG", intent, groupCtx)
    if not text then fail("LFG.%s returned nothing", intent) end
    for i = 1, 20 do
        local t = Engine:Reroll()
        if t:find("{") then fail("LFG.%s left a variable unresolved: %s", intent, t) end
        if #t > 255 then fail("LFG.%s is over the message limit: %s", intent, t) end
    end
end

-- Every advert has to carry the shorthand people actually scan the channel
-- for. A line in character that nobody finds is worth nothing.
for intent, lines in pairs(ns.Phrases.LFG) do
    -- Anything OFFER is whispered to one person who already knows what they
    -- listed, and FULL closes an advert rather than placing one. Only the lines
    -- that go out to a whole channel need the shorthand.
    if intent:sub(1, 5) ~= "OFFER" and intent ~= "FULL" then
        for _, line in ipairs(lines) do
            if not (line:find("^LFG ") or line:find("^LFM ")) then
                fail("LFG.%s does not open with LFG or LFM: %s", intent, line)
            end
        end
    end
    for _, line in ipairs(lines) do
        if not line:find("{dungeon}", 1, true) then
            fail("LFG.%s never names the dungeon: %s", intent, line)
        end
    end
end

-- Role counts read as a sentence, because they go out inside one.
if ns.DescribeRoles(1, 1, 2) ~= "a tank, a healer and 2 dps" then
    fail("roles read as: %s", tostring(ns.DescribeRoles(1, 1, 2)))
end
if ns.DescribeRoles(0, 1, 0) ~= "a healer" then
    fail("a lone healer reads as: %s", tostring(ns.DescribeRoles(0, 1, 0)))
end
if ns.DescribeRoles(0, 0, 0) ~= nil then fail("an empty group described itself") end
if ns.DescribeRoles(2, 0, 0) ~= "2 tanks" then
    fail("two tanks read as: %s", tostring(ns.DescribeRoles(2, 0, 0)))
end

-- The suggestions have to bracket your level rather than list everything.
local nearby = ns.NearbyDungeons(36, 5)
if #nearby ~= 5 then fail("expected five suggestions, got %d", #nearby) end
local named = {}
for _, dungeon in ipairs(nearby) do named[dungeon.name] = true end
if not (named["Uldaman"] or named["Scarlet Monastery"] or named["Razorfen Downs"]) then
    fail("nothing near level 36 was suggested")
end
if named["Magisters' Terrace"] then fail("a level 70 dungeon was suggested at 36") end

-- What the group holds is counted, never guessed at.
local composition = Engine:GroupComposition()
if composition.needs + composition.size ~= 5 then
    fail("the group maths does not add up: %d in a group of five leaves %d",
         composition.size, composition.needs)
end

-- Every gesture offered in the window has a readable name.
for _, token in ipairs(ns.EMOTE_LIST) do
    if ns.EmoteLabel(token) == "" then fail("emote %s has no label", token) end
end
if ns.EMOTE_LIST[1] ~= ns.EMOTE_NONE then fail("the no-gesture option is not first in the list") end

print(string.format("phrases: %d across %d pools", total, pools))
print(string.format("PERSON.PRAISE pool with warlock context: %d distinct templates (generic %d)", count, genericPraise))
print(errors == 0 and "ALL CHECKS PASSED" or (errors .. " FAILURES"))
os.exit(errors == 0 and 0 or 1)
