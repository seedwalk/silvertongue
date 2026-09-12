-- Dungeons.lua -- what to name in a group advert.
--
-- Level ranges are the usual ones people quote, not exact bracket data: they
-- only decide which handful gets suggested first, and you pick from there.

local ADDON, ns = ...

ns.DUNGEONS = {
    { name = "Ragefire Chasm",        min = 13, max = 18 },
    { name = "Wailing Caverns",       min = 15, max = 25 },
    { name = "The Deadmines",         min = 15, max = 25 },
    { name = "Shadowfang Keep",       min = 18, max = 28 },
    { name = "Blackfathom Deeps",     min = 20, max = 30 },
    { name = "The Stockade",          min = 22, max = 30 },
    { name = "Gnomeregan",            min = 24, max = 34 },
    { name = "Razorfen Kraul",        min = 25, max = 35 },
    { name = "Scarlet Monastery",     min = 28, max = 42 },
    { name = "Razorfen Downs",        min = 35, max = 45 },
    { name = "Uldaman",               min = 36, max = 46 },
    { name = "Zul'Farrak",            min = 42, max = 52 },
    { name = "Maraudon",              min = 45, max = 55 },
    { name = "Temple of Atal'Hakkar", min = 50, max = 60 },
    { name = "Blackrock Depths",      min = 52, max = 60 },
    { name = "Lower Blackrock Spire", min = 55, max = 60 },
    { name = "Dire Maul",             min = 55, max = 60 },
    { name = "Stratholme",            min = 58, max = 60 },
    { name = "Scholomance",           min = 58, max = 60 },
    { name = "Hellfire Ramparts",     min = 58, max = 64 },
    { name = "The Blood Furnace",     min = 59, max = 65 },
    { name = "The Slave Pens",        min = 60, max = 66 },
    { name = "The Underbog",          min = 61, max = 67 },
    { name = "Mana-Tombs",            min = 62, max = 68 },
    { name = "Auchenai Crypts",       min = 63, max = 69 },
    { name = "Sethekk Halls",         min = 64, max = 70 },
    { name = "The Escape from Durnholde", min = 64, max = 70 },
    { name = "The Steamvault",        min = 65, max = 70 },
    { name = "Shadow Labyrinth",      min = 65, max = 70 },
    { name = "The Shattered Halls",   min = 67, max = 70 },
    { name = "The Arcatraz",          min = 67, max = 70 },
    { name = "The Botanica",          min = 67, max = 70 },
    { name = "The Mechanar",          min = 67, max = 70 },
    { name = "Magisters' Terrace",    min = 68, max = 70 },
}

-- The handful worth offering first: whatever brackets your level, closest
-- first, so the list is short enough to read.
function ns.NearbyDungeons(level, count)
    level = level or (UnitLevel and UnitLevel("player")) or 1
    count = count or 5

    local scored = {}
    for _, dungeon in ipairs(ns.DUNGEONS) do
        local distance
        if level < dungeon.min then
            distance = dungeon.min - level
        elseif level > dungeon.max then
            distance = level - dungeon.max
        else
            distance = 0
        end
        scored[#scored + 1] = { dungeon = dungeon, distance = distance }
    end

    table.sort(scored, function(a, b)
        if a.distance ~= b.distance then return a.distance < b.distance end
        return a.dungeon.min < b.dungeon.min
    end)

    local out = {}
    for i = 1, math.min(count, #scored) do out[i] = scored[i].dungeon end
    return out
end

-- What the adverts name. Remembered, and seeded from wherever you are standing
-- if that happens to be an instance.
function ns.CurrentDungeon()
    local db = ns.addon and ns.addon.db
    local chosen = db and db.profile.lfgDungeon
    if chosen and chosen ~= "" then return chosen end

    if IsInInstance and IsInInstance() and GetInstanceInfo then
        local name = GetInstanceInfo()
        if name and name ~= "" then return name end
    end
    return nil
end

function ns.SetDungeon(name)
    local db = ns.addon and ns.addon.db
    if db then db.profile.lfgDungeon = name end
end
