-- Engine.lua -- turns an intent into a phrase. No memory, no inference.

local ADDON, ns = ...

ns.Phrases = ns.Phrases or {}

local Engine = {}
ns.Engine = Engine

-- Runtime-only UX state: keeps your character from repeating himself. Not persisted.
local RECENT_MAX = 15
local recent = {}

local current = {
    category = nil,
    intent   = nil,
    ctx      = nil,
    pool     = nil,
    template = nil,
    text     = nil,
}

local function remember(template)
    for i = #recent, 1, -1 do
        if recent[i] == template then table.remove(recent, i) end
    end
    table.insert(recent, 1, template)
    while #recent > RECENT_MAX do table.remove(recent) end
end

local function isRecent(template)
    for i = 1, #recent do
        if recent[i] == template then return true end
    end
    return false
end

-- Who you are playing. Three axes, each one a layer of phrases: class, race and
-- faction. A phrase flagged for one value of an axis never reaches another.
function Engine:GetPlayerClass()
    if not self.playerClass then
        local _, token = UnitClass("player")
        self.playerClass = token
    end
    return self.playerClass
end

function Engine:GetPlayerRace()
    if not self.playerRace then
        local _, token = UnitRace("player")
        self.playerRace = token and token:upper() or nil
    end
    return self.playerRace
end

function Engine:GetPlayerFaction()
    if not self.playerFaction then
        local token = UnitFactionGroup("player")
        self.playerFaction = token and token:upper() or nil
    end
    return self.playerFaction
end

-- Forgets the cached identity. Only the tests need this; the game never changes
-- character without reloading the UI.
function Engine:ForgetPlayer()
    self.playerClass, self.playerRace, self.playerFaction = nil, nil, nil
end

-- The player layers, in the order they are merged. Each entry is the table
-- under ns.Phrases.SELF and the function that says which key applies to you.
local SELF_LAYERS = {
    { "CLASS",   function() return Engine:GetPlayerClass() end },
    { "RACE",    function() return Engine:GetPlayerRace() end },
    { "FACTION", function() return Engine:GetPlayerFaction() end },

    -- A few pairings mean something neither half says alone: a blood elf
    -- paladin took the Light rather than being given it, a draenei shaman
    -- adopted a tradition the orcs inherited. Last, so it colours everything
    -- else, and deliberately small -- there are six of these, not forty-five.
    { "COMBO", function()
        local race, class = Engine:GetPlayerRace(), Engine:GetPlayerClass()
        if not race or not class then return nil end
        return race .. ":" .. class
    end },
}

-- Lines you wrote yourself are stored in one of four scopes, mirroring the four
-- layers a phrase can come from: every character you play, everyone of your
-- race, everyone of your class, everyone of your faction. Dropping a line uses
-- the scope its origin already names on screen, so what you see is what changes.
ns.SCOPES = { "ALL", "RACE", "CLASS", "FACTION" }

-- The value of each scope for this character. ALL has no token.
function Engine:ScopeToken(scope)
    if scope == "ALL" then return "ALL" end
    if scope == "CLASS" then return self:GetPlayerClass() end
    if scope == "RACE" then return self:GetPlayerRace() end
    if scope == "FACTION" then return self:GetPlayerFaction() end
    return nil
end

-- What to call a scope in the interface.
function Engine:ScopeLabel(scope)
    if scope == "ALL" then return "All my characters" end
    local token = self:ScopeToken(scope)
    return token and ns.Titlecase(token) or ns.Titlecase(scope)
end

-- Which scope a line belongs to, from the origin tag it was collected with.
-- Lines that come from the target's class or race are not tied to who you are,
-- so dropping one drops it everywhere.
local ORIGIN_SCOPE = {
    ["shared"]        = "ALL",
    ["their class"]   = "ALL",
    ["their race"]    = "ALL",
    ["your class"]    = "CLASS",
    ["your race"]     = "RACE",
    ["your faction"]  = "FACTION",
}

function Engine:ScopeForOrigin(origin)
    if not origin then return "CLASS" end
    local mapped = ORIGIN_SCOPE[origin]
    if mapped then return mapped end
    -- "yours * shamans" and friends carry their own scope.
    for _, scope in ipairs(ns.SCOPES) do
        if origin == "yours " .. self:ScopeLabel(scope):lower() then return scope end
    end
    return "CLASS"
end

-- The table for one (category, intent) in one scope, created only when asked.
function Engine:CustomPool(category, intent, create, scope)
    local db = ns.addon and ns.addon.db
    if not db then return nil end

    scope = scope or "CLASS"
    local token = self:ScopeToken(scope)
    if not token then return nil end

    local custom = db.profile.custom
    if not custom then
        if not create then return nil end
        custom = {}
        db.profile.custom = custom
    end

    local byScope = custom[scope]
    if not byScope then
        if not create then return nil end
        byScope = {}
        custom[scope] = byScope
    end

    local byToken = byScope[token]
    if not byToken then
        if not create then return nil end
        byToken = {}
        byScope[token] = byToken
    end

    local byCategory = byToken[category]
    if not byCategory then
        if not create then return nil end
        byCategory = {}
        byToken[category] = byCategory
    end

    local pool = byCategory[intent]
    if not pool then
        if not create then return nil end
        pool = { added = {}, hidden = {} }
        byCategory[intent] = pool
    end

    pool.added = pool.added or {}
    pool.hidden = pool.hidden or {}
    pool.emotes = pool.emotes or {}
    return pool
end

-- Every scope that applies to this character, in merge order.
function Engine:EachCustomPool(category, intent, fn)
    for _, scope in ipairs(ns.SCOPES) do
        local pool = self:CustomPool(category, intent, false, scope)
        if pool then fn(pool, scope) end
    end
end

-- Saved variables written before scopes existed were keyed by class token at the
-- top level. Move them under CLASS rather than losing them.
function Engine:MigrateCustom(db)
    local custom = db and db.profile and db.profile.custom
    if not custom then return false end

    local moved = false
    for key, value in pairs(custom) do
        local isScope = false
        for _, scope in ipairs(ns.SCOPES) do
            if key == scope then isScope = true end
        end
        if not isScope and type(value) == "table" then
            custom.CLASS = custom.CLASS or {}
            custom.CLASS[key] = value
            custom[key] = nil
            moved = true
        end
    end
    return moved
end

-- One walk over every source that can contribute to an intent, tagging each line
-- with where it came from. buildPool throws the tags away; the config window
-- keeps them. Having a single walk is the point: two of them would drift.
--
-- Sources, in merge order: the shared pool, then your class, race and faction,
-- then the target's class and race, then the lines you wrote. A layer that
-- declares the intent under `replace` wipes what came before it instead of
-- adding to it -- that is how a race takes a voice over rather than borrowing
-- one, and it matters because the shared pools are written in an orcish
-- register rather than a neutral one.
local function collectPool(category, intent, ctx, keepHidden)
    local entries = {}

    local function add(lines, origin)
        if not lines then return end
        for _, line in ipairs(lines) do
            entries[#entries + 1] = { text = line, origin = origin }
        end
    end

    add(ns.Phrases[category] and ns.Phrases[category][intent], "shared")

    local layers = ns.Phrases.SELF
    if layers then
        for _, layer in ipairs(SELF_LAYERS) do
            local axis, key = layer[1], layer[2]()
            local mine = key and layers[axis] and layers[axis][key]
            if mine then
                local replaces = mine.replace
                if replaces and replaces[category] and replaces[category][intent] then
                    entries = {}
                end
                add(mine[category] and mine[category][intent], "your " .. axis:lower())
            end
        end
    end

    if ctx then
        if ctx.classToken and ns.Phrases.CLASS[ctx.classToken] then
            add(ns.Phrases.CLASS[ctx.classToken][intent], "their class")
        end
        if ctx.raceToken and ns.Phrases.RACE[ctx.raceToken] then
            add(ns.Phrases.RACE[ctx.raceToken][intent], "their race")
        end
    end

    local hidden = nil
    Engine:EachCustomPool(category, intent, function(pool, scope)
        add(pool.added, "yours " .. Engine:ScopeLabel(scope):lower())
        for text in pairs(pool.hidden) do
            hidden = hidden or {}
            hidden[text] = true
        end
    end)

    if hidden then
        if keepHidden then
            for _, entry in ipairs(entries) do
                entry.hidden = hidden[entry.text] == true
            end
        else
            local kept = {}
            for _, entry in ipairs(entries) do
                if not hidden[entry.text] then kept[#kept + 1] = entry end
            end
            entries = kept
        end
    end

    return entries
end

local function buildPool(category, intent, ctx)
    local pool = {}
    for _, entry in ipairs(collectPool(category, intent, ctx, false)) do
        pool[#pool + 1] = entry.text
    end
    return pool
end

-- Every line an intent could serve this character, hidden ones included and
-- marked. This is what the config window lists.
function Engine:DescribePool(category, intent, ctx)
    return collectPool(category, intent, ctx, true)
end

-- The gesture a line goes out with. Your own choice wins over the one the line
-- was written with, which wins over the intent's default. NONE is a real value,
-- not an absence: it is how you turn off a gesture a line came with.
function Engine:EmoteFor(category, intent, text)
    if not text then return nil end

    local chosen
    self:EachCustomPool(category, intent, function(pool)
        if pool.emotes[text] then chosen = pool.emotes[text] end
    end)
    if chosen then
        return chosen ~= ns.EMOTE_NONE and chosen or nil
    end

    local byText = ns.Emotes.BY_TEXT[text]
    if byText then
        return byText ~= ns.EMOTE_NONE and byText or nil
    end

    local byIntent = ns.Emotes.BY_INTENT[intent]
    return byIntent ~= ns.EMOTE_NONE and byIntent or nil
end

-- What the library window shows as the current choice, NONE and all.
function Engine:EmoteChoice(category, intent, text)
    local chosen
    self:EachCustomPool(category, intent, function(pool)
        if pool.emotes[text] then chosen = pool.emotes[text] end
    end)
    return chosen
        or ns.Emotes.BY_TEXT[text]
        or ns.Emotes.BY_INTENT[intent]
        or ns.EMOTE_NONE
end

-- Assigning a gesture is stored like everything else you edit: in a scope.
function Engine:SetEmote(category, intent, text, token, scope)
    if not category or not intent or not text then return false end

    local custom = self:CustomPool(category, intent, true, scope or "CLASS")
    if not custom then return false end

    -- Clearing means "fall back to what it came with", which is not the same as
    -- choosing NONE, so it has to be able to erase the entry entirely.
    if token == nil then
        custom.emotes[text] = nil
    else
        custom.emotes[text] = token
    end
    return true
end

-- Whether an intent has any line left at all, once flags and hiding are applied.
function Engine:HasAnyPhrase(category, intent)
    return #buildPool(category, intent, nil) > 0
end

function Engine:Format(template, ctx)
    if not ctx then return template end
    local text = template
    text = text:gsub("{name}", ctx.name or "friend")
    text = text:gsub("{race}", ctx.raceName or "warrior")
    text = text:gsub("{class}", ctx.className or "fighter")
    -- Group-finding lines speak about you and about the group you have.
    text = text:gsub("{level}", tostring(ctx.level or ""))
    text = text:gsub("{have}", ctx.have or "no one yet")
    text = text:gsub("{needs}", tostring(ctx.needs or ""))
    text = text:gsub("{dungeon}", ctx.dungeon or "anything")
    text = text:gsub("{missing}", ctx.missing or "more")
    return text
end

-- Who you are, for lines that talk about yourself rather than someone else.
function Engine:BuildPlayerContext()
    local ctx = self:BuildUnitContext("player") or {}
    ctx.level = UnitLevel and UnitLevel("player") or nil
    return ctx
end

-- "a tank, a healer and 2 dps", from counts. Reads as English rather than as a
-- table, because it goes out in a sentence.
function ns.DescribeRoles(tank, healer, dps)
    local parts = {}
    if (tank or 0) > 0 then
        parts[#parts + 1] = (tank == 1) and "a tank" or (tank .. " tanks")
    end
    if (healer or 0) > 0 then
        parts[#parts + 1] = (healer == 1) and "a healer" or (healer .. " healers")
    end
    if (dps or 0) > 0 then
        parts[#parts + 1] = dps .. " dps"
    end

    if #parts == 0 then return nil end
    if #parts == 1 then return parts[1] end
    return table.concat(parts, ", ", 1, #parts - 1) .. " and " .. parts[#parts]
end

-- What the group actually holds, counted rather than guessed: the classes are
-- known, the specs are not, so the line never claims a role nobody said they
-- were playing.
function Engine:GroupComposition()
    local myClass = UnitClass("player")
    local classes = { myClass }
    for _, unit in ipairs(ns.GroupUnits and ns.GroupUnits() or {}) do
        local className = UnitClass(unit)
        if className then classes[#classes + 1] = className end
    end

    local size = #classes

    -- If roles have been assigned, say them: they are what a recruiting line is
    -- actually about. Otherwise fall back to the classes, which are always
    -- known, rather than guessing a role from a class.
    local tank, healer, dps, unassigned = 0, 0, 0, 0
    if UnitGroupRolesAssigned then
        local units = { "player" }
        for _, unit in ipairs(ns.GroupUnits and ns.GroupUnits() or {}) do
            units[#units + 1] = unit
        end
        for _, unit in ipairs(units) do
            local role = UnitGroupRolesAssigned(unit)
            if role == "TANK" then tank = tank + 1
            elseif role == "HEALER" then healer = healer + 1
            elseif role == "DAMAGER" then dps = dps + 1
            else unassigned = unassigned + 1 end
        end
    else
        unassigned = size
    end

    local have
    if unassigned == 0 and size > 0 then
        have = ns.DescribeRoles(tank, healer, dps)
    else
        have = table.concat(classes, ", "):lower()
    end

    -- A five-man wants one of each and three who hit things.
    local missing = (unassigned == 0)
        and ns.DescribeRoles(math.max(0, 1 - tank), math.max(0, 1 - healer),
                             math.max(0, 3 - dps))
        or nil

    return {
        have    = have,
        missing = missing,
        size    = size,
        needs   = math.max(0, 5 - size),
    }
end

-- Picks from the pool, avoiding anything said recently and never repeating the
-- phrase currently on screen. Favorites get a light thumb on the scale.
local function pick(pool, avoid, favorites)
    if #pool == 0 then return nil end
    if #pool == 1 then return pool[1] end

    local function gather(strict)
        local weighted = {}
        for _, template in ipairs(pool) do
            if template ~= avoid and (not strict or not isRecent(template)) then
                weighted[#weighted + 1] = template
                if favorites and favorites[template] then
                    weighted[#weighted + 1] = template
                end
            end
        end
        return weighted
    end

    local candidates = gather(true)
    if #candidates == 0 then candidates = gather(false) end
    if #candidates == 0 then return avoid end

    return candidates[math.random(#candidates)]
end

local function favorites()
    return ns.addon and ns.addon.db and ns.addon.db.profile.favorites or nil
end

-- Start a new intent. ctx is nil for undirected intents, or a table with
-- name / classToken / raceToken / className / raceName for directed ones.
function Engine:Request(category, intent, ctx)
    local pool = buildPool(category, intent, ctx)
    if #pool == 0 then
        current.pool, current.template, current.text = nil, nil, nil
        return nil
    end

    current.category = category
    current.intent   = intent
    current.ctx      = ctx
    current.pool     = pool
    current.template = pick(pool, nil, favorites())
    current.text     = self:Format(current.template, ctx)

    remember(current.template)
    return current.text
end

-- Same intent, same person, different phrase.
function Engine:Reroll()
    if not current.pool then return nil end

    current.template = pick(current.pool, current.template, favorites())
    current.text     = self:Format(current.template, current.ctx)

    remember(current.template)
    return current.text
end

function Engine:GetCurrent()
    return current.text
end

-- True when the given click targets the phrase already in the preview, which is
-- what turns a second click on the same button into a reroll.
function Engine:IsCurrent(category, intent, ctx)
    if not current.template then return false end
    if current.category ~= category or current.intent ~= intent then return false end
    local currentName = current.ctx and current.ctx.name
    local incomingName = ctx and ctx.name
    return currentName == incomingName
end

function Engine:GetCurrentTemplate()
    return current.template
end

function Engine:HasPhrase()
    return current.template ~= nil
end

function Engine:Clear()
    current.pool, current.template, current.text, current.ctx = nil, nil, nil, nil
end

-- Context for a party unit, used to unlock class and race specific phrases.
-- The pool is cached for rerolling, so editing the library has to rebuild it.
-- Without this, a line you just added would not come up until you left the
-- intent and came back.
local function refreshCurrentPool(category, intent)
    if current.category ~= category or current.intent ~= intent then return end
    current.pool = buildPool(category, intent, current.ctx)
end

-- Adds a line of your own. The scope decides which of your characters get it;
-- it defaults to your class, which is the narrowest useful answer.
function Engine:AddPhrase(category, intent, text, scope)
    if not category or not intent then return false, "no intent selected" end
    text = (text or ""):gsub("^%s+", ""):gsub("%s+$", "")
    if text == "" then return false, "nothing to add" end

    scope = scope or "CLASS"

    -- Un-hiding takes priority, and has to reach whichever scope hid it.
    local unhid = false
    self:EachCustomPool(category, intent, function(pool)
        if pool.hidden[text] then
            pool.hidden[text] = nil
            unhid = true
        end
    end)
    if unhid then
        refreshCurrentPool(category, intent)
        return true
    end

    for _, existing in ipairs(collectPool(category, intent, nil, false)) do
        if existing.text == text then return false, "already there" end
    end

    local custom = self:CustomPool(category, intent, true, scope)
    if not custom then return false, "that scope does not apply to this character" end

    custom.added[#custom.added + 1] = text
    refreshCurrentPool(category, intent)
    return true
end

-- Takes a line out of the rotation. A line you wrote is deleted outright from
-- wherever you wrote it; a seeded one is remembered as hidden in the scope its
-- origin names, so dropping a shared line drops it on every character and
-- dropping a class line drops it only for that class.
function Engine:HidePhrase(category, intent, template, scope)
    if not category or not intent or not template then return false end

    -- Deleting your own line wins, whichever scope holds it.
    local deleted = false
    self:EachCustomPool(category, intent, function(pool)
        for i, existing in ipairs(pool.added) do
            if existing == template then
                table.remove(pool.added, i)
                deleted = true
                return
            end
        end
    end)
    if deleted then
        refreshCurrentPool(category, intent)
        return true
    end

    local custom = self:CustomPool(category, intent, true, scope or "CLASS")
    if not custom then return false end

    custom.hidden[template] = true
    refreshCurrentPool(category, intent)
    return true
end

function Engine:IsHidden(category, intent, template)
    local found = false
    self:EachCustomPool(category, intent, function(pool)
        if pool.hidden[template] then found = true end
    end)
    return found
end

function Engine:IsCustom(category, intent, template)
    local found = false
    self:EachCustomPool(category, intent, function(pool)
        for _, existing in ipairs(pool.added) do
            if existing == template then found = true end
        end
    end)
    return found
end

-- The categories this character can actually reach, in panel order. Built from
-- the data rather than a hand-kept list, so adding a class or a faction shows up
-- here with no extra code.
function Engine:Sections()
    local sections = {
        { category = "GENERAL",  label = "General"        },
        { category = "PARTY",    label = "Party"          },
        { category = "PERSON",   label = "To a person"    },
        { category = "TARGET",   label = "To your target" },
        { category = "ENEMY",    label = "To an enemy"    },
        { category = "LFG",      label = "Looking for a group" },
    }

    local faction = self:GetPlayerFaction()
    if faction and ns.Phrases[faction] then
        sections[#sections + 1] = { category = faction, label = ns.Titlecase(faction) }
    end

    local class = self:GetPlayerClass()
    if class and ns.Phrases[class] then
        sections[#sections + 1] = { category = class, label = ns.Titlecase(class) }
    end

    sections[#sections + 1] = { category = "ATTITUDE", label = "Attitude" }

    -- Drop anything with no phrases at all rather than showing a dead heading.
    local kept = {}
    for _, section in ipairs(sections) do
        if ns.Phrases[section.category] then kept[#kept + 1] = section end
    end
    return kept
end

-- The intents inside a category, alphabetical, with how many lines each has.
function Engine:Intents(category)
    local pools = ns.Phrases[category]
    if not pools then return {} end

    local intents = {}
    for intent in pairs(pools) do
        intents[#intents + 1] = {
            intent = intent,
            label  = ns.Titlecase(intent),
            count  = #buildPool(category, intent, nil),
        }
    end
    table.sort(intents, function(a, b) return a.label < b.label end)
    return intents
end

-- What the panel is showing right now, so the buttons know what they act on.
function Engine:GetCurrentIntent()
    return current.category, current.intent
end

function Engine:BuildUnitContext(unit)
    if not UnitExists(unit) then return nil end
    local className, classToken = UnitClass(unit)
    local raceName, raceToken   = UnitRace(unit)
    return {
        unit       = unit,
        name       = UnitName(unit),
        className  = className,
        classToken = classToken,
        raceName   = raceName,
        raceToken  = raceToken and raceToken:upper() or nil,
    }
end
