-- Mocks just enough of the WoW UI so the whole addon can be loaded and driven.
-- It will not prove the layout looks right; it does prove no code path nils out.
local DIR = "/home/fede/sites/shamanolo/Silvertongue/"
local ns = {}

local sent = {}          -- everything that reached "chat"
local shownFrames = {}

local mockMeta
local function newMock(kind, name)
    local t = { __kind = kind, __name = name, __shown = false, __text = "", __enabled = true }
    return setmetatable(t, mockMeta)
end

-- Any method not modelled below returns another mock, so chained calls work.
local passthrough = {}
mockMeta = {
    __index = function(t, key)
        -- Only PascalCase names are methods, the way the WoW API is written.
        -- Anything else is a data field and must read back as nil when unset,
        -- or clearing a field would quietly turn it into a truthy stub.
        if type(key) ~= "string" or not key:match("^%u") then return nil end
        local fn = passthrough[key]
        if fn then return fn end
        local generic = function(self, ...) return newMock("generic", key) end
        rawset(t, key, generic)
        return generic
    end,
}

passthrough.Show      = function(self) self.__shown = true; shownFrames[self] = true end
passthrough.Hide      = function(self) self.__shown = false; shownFrames[self] = nil end
passthrough.IsShown   = function(self) return self.__shown end
passthrough.SetShown  = function(self, v) if v then self:Show() else self:Hide() end end
passthrough.SetText   = function(self, v) self.__text = v; self.__hasText = true end

-- A plain Button has no font string until it is given text; only a template
-- brings one along. Handing one back unconditionally hides a real crash.
passthrough.GetFontString = function(self)
    if not self.__hasText and not self.__templated then return nil end
    return passthrough.GetFontStringReal(self)
end
passthrough.GetText   = function(self) return self.__text end
passthrough.SetEnabled= function(self, v) self.__enabled = v end
passthrough.SetChecked = function(self, v) self.__checked = v and true or false end
passthrough.GetChecked = function(self) return self.__checked end
passthrough.IsEnabled = function(self) return self.__enabled end
passthrough.SetScript = function(self, name, fn) self.__scripts = self.__scripts or {}; self.__scripts[name] = fn end
passthrough.GetScript = function(self, name) return self.__scripts and self.__scripts[name] end
passthrough.GetPoint  = function(self) return "CENTER", nil, "CENTER", 0, 0 end

-- The real client rejects these; the mock has to as well, or a nil constant
-- sails through the tests and blows up in game.
local VALID_POINTS = {
    TOPLEFT = true, TOP = true, TOPRIGHT = true, LEFT = true, CENTER = true,
    RIGHT = true, BOTTOMLEFT = true, BOTTOM = true, BOTTOMRIGHT = true,
}
passthrough.SetSize = function(self, w, h)
    if type(w) ~= "number" or type(h) ~= "number" then
        error("bad argument to SetSize (" .. tostring(w) .. ", " .. tostring(h) .. ")", 2)
    end
    self.__w, self.__h = w, h
end
passthrough.SetWidth  = function(self, w)
    if type(w) ~= "number" then error("bad argument to SetWidth (" .. tostring(w) .. ")", 2) end
end
passthrough.SetHeight = function(self, h)
    if type(h) ~= "number" then error("bad argument to SetHeight (" .. tostring(h) .. ")", 2) end
end
passthrough.SetPoint = function(self, point, a, b, c, d)
    if not VALID_POINTS[point] then
        error("bad anchor point to SetPoint (" .. tostring(point) .. ")", 2)
    end
    -- SetPoint(point, x, y) and SetPoint(point, rel, relPoint, x, y) are both
    -- legal; whichever form, the offsets have to be numbers.
    local offsets = (type(a) == "number") and { a, b } or { c, d }
    for _, value in ipairs(offsets) do
        if value ~= nil and type(value) ~= "number" then
            error("bad offset to SetPoint (" .. tostring(value) .. ")", 2)
        end
    end
end
passthrough.StartMoving = function() end
passthrough.StopMovingOrSizing = function() end
passthrough.GetFontStringReal = function(self)
    self.__fs = self.__fs or newMock("fontstring")
    -- The label mirrors the button text so assertions can read it.
    self.__fs.SetText = function(fs, v) self.__text = v end
    self.__fs.GetText = function() return self.__text end
    return self.__fs
end
passthrough.CreateFontString = function(self) return newMock("fontstring") end
passthrough.GetNormalTexture = function(self) return newMock("texture") end
passthrough.IsMouseOver = function() return false end

function CreateFrame(kind, name, parent, template)
    local f = newMock(kind, name)
    f.__templated = template ~= nil
    if name then _G[name] = f end
    return f
end

UIParent, Minimap, GameTooltip = newMock("Frame"), newMock("Frame"), newMock("Frame")
PlayerFrame, TargetFrame = newMock("Frame"), newMock("Frame")
PlayerFrameManaBar = newMock("StatusBar")
PlayerLevelText = newMock("FontString")
for i = 1, 4 do _G["PartyMemberFrame" .. i] = newMock("Frame") end

local emoted = {}
function DoEmote(token, target) emoted[#emoted + 1] = { token, target } end
UnitInParty = function(u)
    for i = 1, 4 do
        if UnitExists("party" .. i) and UnitName("party" .. i) == UnitName(u) then return true end
    end
    return false
end
UnitInRaid = function() return false end

-- The stock scrolling-list helpers the config window uses.
local scrollOffset = setmetatable({}, { __mode = "k" })
function FauxScrollFrame_GetOffset(frame) return scrollOffset[frame] or 0 end
function FauxScrollFrame_SetOffset(frame, offset) scrollOffset[frame] = offset end
function FauxScrollFrame_Update(frame, count, shown, height) frame.__count = count end
function FauxScrollFrame_OnVerticalScroll() end
UISpecialFrames = {}
tinsert = table.insert
RAID_CLASS_COLORS = setmetatable({}, { __index = function() return { r = 1, g = 1, b = 1 } end })
CLASS_ICON_TCOORDS = setmetatable({}, { __index = function() return { 0, 0.25, 0, 0.25 } end })

-- Group state, flipped by the scenarios below.
local group = {}
IsInGroup    = function() return #group > 0 end
IsInRaid     = function() return false end
IsInInstance = function() return true end
GetNumGroupMembers = function() return #group > 0 and #group + 1 or 0 end
local target = nil          -- the currently selected unit, or nil
_G.__player = { name = "Silvertongue", className = "Shaman", classToken = "SHAMAN",
                raceName = "Orc", raceToken = "Orc", faction = "Horde" }
UnitFactionGroup = function(u) local m = _G.__player; return m and m.faction or "Horde" end
local function unitIndex(unit) return tonumber(unit:match("^party(%d)$")) end
local function resolve(u)
    if u == "target" then return target end
    if u == "player" then return _G.__player end
    return group[unitIndex(u) or 0]
end
UnitExists   = function(u) return u ~= nil and resolve(u) ~= nil end
UnitName     = function(u) local m = resolve(u); return m and m.name end
UnitClass    = function(u) local m = resolve(u); return m and m.className, m and m.classToken end
UnitRace     = function(u) local m = resolve(u); return m and m.raceName, m and m.raceToken end
UnitIsUnit   = function(a, b) local x, y = resolve(a), resolve(b); return x ~= nil and x == y end
UnitCanAttack= function(_, u) local m = resolve(u); return m ~= nil and m.hostile == true end
UnitIsPlayer = function(u) local m = resolve(u); return m ~= nil and m.classToken ~= nil end

function SendChatMessage(text, channel, _, to)
    sent[#sent + 1] = { text = text, channel = channel, to = to }
end
UnitCanCooperate = function(_, u) local m = resolve(u); return m ~= nil and m.hostile ~= true and m.classToken ~= nil end

-- The three real actions the panel can take, recorded rather than performed.
local acted = {}
InviteUnit    = function(name) acted[#acted + 1] = { "invite", name } end
InitiateTrade = function(unit) acted[#acted + 1] = { "trade", unit } end
StartDuel     = function(unit) acted[#acted + 1] = { "duel", unit } end

-- Library stubs.
local libs = {}
LibStub = setmetatable({
    GetLibrary = function(_, name) return libs[name] end,
}, { __call = function(_, name) return libs[name] end })

libs["AceAddon-3.0"] = {
    NewAddon = function(_, name, ...)
        local addon = { name = name }
        function addon:RegisterChatCommand(cmd, handler)
            -- AceConsole takes a method name or a function; support both.
            self.__cmd = function(input)
                if type(handler) == "string" then return self[handler](self, input) end
                return handler(input)
            end
        end
        function addon:RegisterEvent(event, fn) self.__events = self.__events or {}; self.__events[event] = fn end
        function addon:Print(...) end
        return addon
    end,
}
local function deepcopy(t)
    if type(t) ~= "table" then return t end
    local out = {}
    for k, v in pairs(t) do out[k] = deepcopy(v) end
    return out
end
libs["AceDB-3.0"] = { New = function(_, _, defaults) return { profile = deepcopy(defaults.profile) } end }
libs["LibDataBroker-1.1"] = { NewDataObject = function(_, _, obj) return obj end }
libs["LibDBIcon-1.0"] = { Register = function() end, Hide = function() end, Show = function() end }

local function load(file) return assert(loadfile(DIR .. file))("Silvertongue", ns) end
load("Settings.lua")
for _, f in ipairs({"Engine","General","Party","Horde","Shaman","Attitude","Classes","Races","Target","Rogue","Self","Alliance","Emotes"}) do load("RP/"..f..".lua") end
for _, f in ipairs({"Window","Preview","Tabs","Party","Target","Config","Board","Display","Contexts","Anchors"}) do load("UI/"..f..".lua") end
load("Core.lua")

local addon = ns.addon
addon:OnInitialize()
addon:OnEnable()

local errors = 0
local function check(cond, fmt, ...)
    if not cond then errors = errors + 1; print("FAIL: " .. string.format(fmt, ...)) end
end

-- 1. Open the panel and walk every tab, clicking every intent button.
addon.__cmd("")
check(ns.Window.frame:IsShown(), "window did not open")

-- Drive the tabs through the real tab buttons.
check(ns.TABS ~= nil, "tabs were never built")
for _, tab in ipairs(ns.TABS) do
    ns.Tabs:Select(tab.key)
    check(ns.Tabs.current == tab.key, "tab %s did not become current", tab.key)
end

-- 2. Every intent in every simple tab must produce a phrase, and never send.
for _, tab in ipairs({"GENERAL", "HORDE", "SHAMAN", "ATTITUDE"}) do
    ns.Tabs:Select(tab == "SHAMAN" and "CLASS" or (tab == "HORDE" and "FACTION" or tab))
    for intent in pairs(ns.Phrases[tab]) do
        ns.Preview:Request(tab, intent, nil)
        local text = ns.Preview:GetText()
        check(text ~= "" and not text:find("no phrases"), "%s.%s produced no preview", tab, intent)
        ns.Preview:Reroll()
        check(ns.Preview:GetText() ~= "", "%s.%s reroll emptied the preview", tab, intent)
    end
end
check(#sent == 0, "%d messages were sent before SEND was ever clicked", #sent)

-- 2b. Clicking the same intent twice rerolls; a different intent starts fresh.
ns.Tabs:Select("CLASS")
ns.Preview:RequestOrReroll("SHAMAN", "EARTH", nil)
local first = ns.Preview:GetText()
local changed = false
for i = 1, 10 do
    ns.Preview:RequestOrReroll("SHAMAN", "EARTH", nil)   -- same button again
    local again = ns.Preview:GetText()
    check(again ~= first, "re-clicking Earth repeated the phrase: %s", again)
    if again ~= first then changed = true end
    first = again
end
check(changed, "re-clicking an intent never changed the phrase")
ns.Preview:RequestOrReroll("SHAMAN", "FIRE", nil)
local fire = ns.Preview:GetText()
local isFire = false
for _, line in ipairs(ns.Phrases.SHAMAN.FIRE) do if line == fire then isFire = true end end
check(isFire, "clicking a different intent did not switch pools: %s", fire)

-- Re-clicking a member intent must reroll too, and keep naming the same person.
group = { { name = "Grumgar", className = "Warrior", classToken = "WARRIOR", raceName = "Orc", raceToken = "Orc" } }
local gctx = ns.Engine:BuildUnitContext("party1")
ns.Preview:RequestOrReroll("PERSON", "PRAISE", gctx)
local p1 = ns.Preview:GetText()
ns.Preview:RequestOrReroll("PERSON", "PRAISE", ns.Engine:BuildUnitContext("party1"))
local p2 = ns.Preview:GetText()
check(p1 ~= p2, "re-clicking Praise repeated the phrase")
check(p2:find("Grumgar"), "re-click lost the member name: %s", p2)
group = {}

-- 3. Solo party tab.
ns.Tabs:Select("PARTY")
check(ns.PartyUI.view == "ROSTER", "party tab did not land on the roster")

-- 4. With a group: roster, a member screen, warlock extras.
group = {
    { name = "Grumgar", className = "Warrior", classToken = "WARRIOR", raceName = "Orc",   raceToken = "Orc"    },
    { name = "Zulko",   className = "Rogue",   classToken = "ROGUE",   raceName = "Troll", raceToken = "Troll"  },
    { name = "Morghul", className = "Warlock", classToken = "WARLOCK", raceName = "Orc",   raceToken = "Orc"    },
    { name = "Cairne",  className = "Druid",   classToken = "DRUID",   raceName = "Tauren",raceToken = "Tauren" },
}
addon.__events["GROUP_ROSTER_UPDATE"]()
ns.Tabs:Select("PARTY")
check(ns.Preview.channel == "PARTY", "party tab did not default to party chat (got %s)", tostring(ns.Preview.channel))

ns.PartyUI:ShowPerson("party1")
check(ns.PartyUI.view == "PERSON", "member screen did not open")
ns.Preview:Request("PERSON", "PRAISE", ns.Engine:BuildUnitContext("party1"))
local praise = ns.Preview:GetText()
check(praise:find("Grumgar"), "praise did not name the member: %s", praise)
check(not praise:find("{"), "praise left a variable unresolved: %s", praise)

ns.PartyUI:ShowPerson("party3")
for _, intent in ipairs({"DISTRUST", "DEMON", "FEL_MAGIC"}) do
    ns.Preview:Request("PERSON", intent, ns.Engine:BuildUnitContext("party3"))
    check(ns.Preview:GetText():find("Morghul"), "warlock %s did not name the member", intent)
end

-- 5a. Another member leaves and the unit ids shift: the screen must stay on the
--     same person, not silently retarget whoever inherited the unit id.
ns.PartyUI:ShowPerson("party4")                 -- Cairne
check(ns.PartyUI.unitName == "Cairne", "member screen tracked the wrong name")
table.remove(group, 1)                          -- Grumgar leaves; Cairne becomes party3
addon.__events["GROUP_ROSTER_UPDATE"]()
check(ns.PartyUI.view == "PERSON", "left the member screen when an unrelated member left")
check(ns.PartyUI.unitName == "Cairne", "retargeted to %s after the ids shifted", tostring(ns.PartyUI.unitName))
ns.Preview:Request("PERSON", "PRAISE", ns.Engine:BuildUnitContext(ns.PartyUI:ResolveUnit("Cairne")))
check(ns.Preview:GetText():find("Cairne"), "praise named the wrong member: %s", ns.Preview:GetText())

-- 5b. The selected member leaves: must fall back to the roster, not error.
for i = #group, 1, -1 do if group[i].name == "Cairne" then table.remove(group, i) end end
addon.__events["GROUP_ROSTER_UPDATE"]()
check(ns.PartyUI.view == "ROSTER", "did not fall back to the roster when the member left")

-- 5c. The Target tab.
local sentBeforeTarget = #sent

target = nil
ns.Tabs:Select("TARGET")
check(ns.Tabs.current == "TARGET", "target tab did not open")
check(ns.Preview.channel == "SAY", "target tab did not default to say (got %s)", tostring(ns.Preview.channel))

-- A friendly player: every intent must produce a line naming them.
target = { name = "Gromkar", className = "Warrior", classToken = "WARRIOR", raceName = "Orc", raceToken = "Orc" }
addon.__events["PLAYER_TARGET_CHANGED"]()
check(ns.TargetUI.hostile == false, "friendly target was read as hostile")
for _, entry in ipairs({ {"TARGET","HELLO"}, {"PERSON","PRAISE"}, {"PERSON","JOKE"}, {"TARGET","GOODBYE"} }) do
    ns.Preview:RequestOrReroll(entry[1], entry[2], ns.Engine:BuildUnitContext("target"))
    local text = ns.Preview:GetText()
    check(text:find("Gromkar", 1, true), "%s.%s did not name the target: %s", entry[1], entry[2], text)
    check(not text:find("{"), "%s.%s left a variable unresolved: %s", entry[1], entry[2], text)
end

-- Re-clicking the same intent rerolls and keeps naming the same person.
ns.Preview:RequestOrReroll("PERSON", "PRAISE", ns.Engine:BuildUnitContext("target"))
local t1 = ns.Preview:GetText()
ns.Preview:RequestOrReroll("PERSON", "PRAISE", ns.Engine:BuildUnitContext("target"))
local t2 = ns.Preview:GetText()
check(t1 ~= t2, "re-clicking a target intent repeated the phrase")
check(t2:find("Gromkar", 1, true), "re-click lost the target name: %s", t2)

-- Switching target must not disturb a phrase that has not been sent.
local pending = ns.Preview:GetText()
target = { name = "Aelindra", className = "Rogue", classToken = "ROGUE", raceName = "Night Elf", raceToken = "NightElf", hostile = true }
addon.__events["PLAYER_TARGET_CHANGED"]()
check(ns.Preview:GetText() == pending, "changing target overwrote the pending preview")
check(ns.TargetUI.hostile == true, "hostile target was read as friendly")

-- A hostile target speaks through the enemy pools, never the friendly ones.
for _, intent in ipairs({"ENEMY_CHALLENGE", "ENEMY_TAUNT", "ENEMY_RESPECT", "ENEMY_VICTORY"}) do
    ns.Preview:RequestOrReroll("ENEMY", intent, ns.Engine:BuildUnitContext("target"))
    local text = ns.Preview:GetText()
    check(text:find("Aelindra", 1, true), "ENEMY.%s did not name the target: %s", intent, text)
    local friendly = false
    for _, line in ipairs(ns.Phrases.PERSON.PRAISE) do
        if line:gsub("{name}", "Aelindra") == text then friendly = true end
    end
    check(not friendly, "ENEMY.%s served a friendly line: %s", intent, text)
end

-- A creature: no class, no race, still addressable and still no errors.
target = { name = "Ragged Timber Wolf", hostile = true }
addon.__events["PLAYER_TARGET_CHANGED"]()
ns.Preview:RequestOrReroll("ENEMY", "ENEMY_TAUNT", ns.Engine:BuildUnitContext("target"))
check(ns.Preview:GetText():find("Ragged Timber Wolf", 1, true), "creature target was not named")

-- A friendly warlock gets the fel-magic buttons; the engine must serve them.
target = { name = "Morghul", className = "Warlock", classToken = "WARLOCK", raceName = "Orc", raceToken = "Orc" }
addon.__events["PLAYER_TARGET_CHANGED"]()
for _, intent in ipairs({"DISTRUST", "DEMON", "FEL_MAGIC"}) do
    ns.Preview:RequestOrReroll("PERSON", intent, ns.Engine:BuildUnitContext("target"))
    check(ns.Preview:GetText():find("Morghul", 1, true), "warlock target %s did not name them", intent)
end

-- No target, and targeting yourself: both must render without erroring.
target = nil
addon.__events["PLAYER_TARGET_CHANGED"]()
target = { name = "Silvertongue" }
addon.__events["PLAYER_TARGET_CHANGED"]()
UnitIsUnit = function(a, b) return (a == "target" and b == "player") or (a == b) end
ns.TargetUI:Show()
UnitIsUnit = function(a, b) local x, y = resolve(a), resolve(b); return x ~= nil and x == y end
target = nil
ns.Tabs:Select("GENERAL")

check(#sent == sentBeforeTarget, "the target tab sent %d messages on its own", #sent - sentBeforeTarget)

-- 5d. Say and whisper on the target tab.
target = { name = "Gromkar", className = "Warrior", classToken = "WARRIOR", raceName = "Orc", raceToken = "Orc" }
addon.__events["PLAYER_TARGET_CHANGED"]()
ns.Tabs:Select("TARGET")
check(ns.Preview.sayToggle:IsShown(), "the say toggle is missing on the target tab")
check(ns.Preview.whisperToggle:IsShown(), "the whisper toggle is missing on the target tab")
check(not ns.Preview.channelButton:IsShown(), "the channel dropdown is still showing on the target tab")

-- Asking someone to group up must name them.
ns.Preview:SetRecipient("Gromkar")
ns.Preview:RequestOrReroll("TARGET", "PARTY", ns.Engine:BuildUnitContext("target"))
check(ns.Preview:GetText():find("Gromkar", 1, true), "the party request did not name them: %s", ns.Preview:GetText())

-- A whisper reaches the person the line is about.
ns.Preview:SetChannel("WHISPER")
check(ns.Preview.channel == "WHISPER", "could not switch to whisper on a friendly player")
local beforeWhisper = #sent
ns.Preview:Send()
check(#sent == beforeWhisper + 1, "the whisper never went out")
check(sent[#sent].channel == "WHISPER", "sent on %s instead of whisper", sent[#sent].channel)
check(sent[#sent].to == "Gromkar", "whispered %s instead of Gromkar", tostring(sent[#sent].to))

-- The recipient is the person the phrase names, even if the selection moved on.
ns.Preview:SetRecipient("Gromkar")
ns.Preview:Set("Gromkar, you have my thanks.")
ns.Preview:SetChannel("WHISPER")
target = { name = "Zulko", className = "Rogue", classToken = "ROGUE", raceName = "Troll", raceToken = "Troll" }
addon.__events["PLAYER_TARGET_CHANGED"]()
ns.Preview:Send()
check(sent[#sent].to == "Gromkar", "the whisper followed the selection instead of the phrase: %s", tostring(sent[#sent].to))

-- An Alliance target cannot be whispered, so the toggle must refuse and fall back.
target = { name = "Aelindra", className = "Rogue", classToken = "ROGUE", raceName = "Night Elf", raceToken = "NightElf", hostile = true }
addon.__events["PLAYER_TARGET_CHANGED"]()
check(not ns.Preview.whisperToggle:IsEnabled(), "the whisper toggle stayed live on an Alliance target")
ns.Preview:SetRecipient(nil)
ns.Preview.channel = "WHISPER"
ns.Preview:Set("You fought well, Aelindra.")
ns.Preview:Send()
check(sent[#sent].channel == "SAY", "a whisper to an enemy was not turned into say (got %s)", sent[#sent].channel)

-- A creature cannot be whispered either.
target = { name = "Ragged Timber Wolf", hostile = true }
addon.__events["PLAYER_TARGET_CHANGED"]()
check(not ns.CanWhisperTarget(), "a creature was considered whisperable")

target = nil
addon.__events["PLAYER_TARGET_CHANGED"]()
check(not ns.CanWhisperTarget(), "an empty selection was considered whisperable")

-- Undirected intents must not leave a recipient behind for a later whisper.
ns.Tabs:Select("GENERAL")
check(ns.Preview.channelButton:IsShown(), "the channel dropdown did not come back off the target tab")
ns.Preview:RequestOrReroll("GENERAL", "HELLO", nil)
check(ns.Preview.recipient == nil, "a general intent left a whisper recipient set")

-- 5e. A player gets the social asks and the action row; an NPC gets neither.
local captured
local realLayout = ns.LayoutGrid
ns.LayoutGrid = function(parent, entries, startIndex, topOffset)
    captured = {}
    for _, e in ipairs(entries) do captured[e.label] = true end
    return realLayout(parent, entries, startIndex, topOffset)
end

local function actionsShown()
    return ns.TargetUI.actionButtons ~= nil and ns.TargetUI.actionButtons[1]:IsShown()
end

target = { name = "Gromkar", className = "Warrior", classToken = "WARRIOR", raceName = "Orc", raceToken = "Orc" }
ns.Tabs:Select("TARGET")
for _, label in ipairs({"Hello", "Party?", "Trade", "Duel", "Help?", "Need Help", "Offer", "Goodbye"}) do
    check(captured[label], "a friendly player is missing the %s button", label)
end
check(actionsShown(), "the action row is missing on a friendly player")

-- A friendly creature: talk to it, but do not offer it a duel or a group invite.
target = { name = "Innkeeper Gryshka" }
addon.__events["PLAYER_TARGET_CHANGED"]()
for _, label in ipairs({"Hello", "Thank", "Respect", "Goodbye"}) do
    check(captured[label], "a friendly NPC is missing the %s button", label)
end
for _, label in ipairs({"Party?", "Trade", "Duel", "Help?", "Need Help", "Offer"}) do
    check(not captured[label], "a friendly NPC was offered %s", label)
end
check(not actionsShown(), "the action row appeared on an NPC")

-- Hostile: no action row either.
target = { name = "Aelindra", className = "Rogue", classToken = "ROGUE", raceName = "Night Elf", raceToken = "NightElf", hostile = true }
addon.__events["PLAYER_TARGET_CHANGED"]()
check(captured["Challenge"], "a hostile target is missing the Challenge button")
check(not captured["Party?"], "a hostile target was offered a group invite")
check(not actionsShown(), "the action row appeared on a hostile target")

-- The actions themselves fire against the right unit, and say nothing.
target = { name = "Gromkar", className = "Warrior", classToken = "WARRIOR", raceName = "Orc", raceToken = "Orc" }
addon.__events["PLAYER_TARGET_CHANGED"]()
local sentBeforeActions = #sent
for _, b in ipairs(ns.TargetUI.actionButtons) do
    b:GetScript("OnClick")(b)
end
check(#acted == 3, "expected three actions, got %d", #acted)
check(acted[1][1] == "invite" and acted[1][2] == "Gromkar", "invite went to %s", tostring(acted[1][2]))
check(acted[2][1] == "trade", "the second action was %s", acted[2][1])
check(acted[3][1] == "duel", "the third action was %s", acted[3][1])
check(#sent == sentBeforeActions, "an action button sent a chat message")

-- With nothing selected the actions must do nothing rather than error.
target = nil
addon.__events["PLAYER_TARGET_CHANGED"]()
local actedBefore = #acted
for _, b in ipairs(ns.TargetUI.actionButtons) do
    b:GetScript("OnClick")(b)
end
check(#acted == actedBefore, "an action fired with no target selected")

ns.LayoutGrid = realLayout
target = nil
ns.Tabs:Select("GENERAL")

sentBeforeTarget = #sent


-- 6. SEND is the only thing that speaks, and it sends exactly what is visible.
local base = #sent
ns.Preview:Set("Testing, one two.")
ns.Preview.channel = "SAY"
ns.Preview:Send()
check(#sent == base + 1, "expected exactly one message, got %d", #sent - base)
check(sent[base + 1].text == "Testing, one two.", "sent the wrong text: %s", sent[base + 1].text)

-- 7. An edited preview is sent verbatim.
ns.Preview:Request("GENERAL", "THANKS", nil)
ns.Preview.edit:SetText("Hand-written line, {not} a template.")
ns.Preview:Send()
check(sent[base + 2].text == "Hand-written line, {not} a template.", "edited text was altered: %s", sent[base + 2].text)

-- 8. Over-long text is trimmed to the client limit.
ns.Preview.edit:SetText(string.rep("A", 400))
ns.Preview:Send()
check(#sent[base + 3].text == 255, "long message was not trimmed (%d bytes)", #sent[base + 3].text)

-- 9. A channel the player cannot use falls back rather than erroring.
group = {}
ns.Preview.channel = "PARTY"
ns.Preview.edit:SetText("Alone now.")
ns.Preview:Send()
check(sent[base + 4].channel == "SAY", "unavailable channel did not fall back to SAY (got %s)", sent[base + 4].channel)

-- 10. Favorites round-trip.
ns.Tabs:Select("CLASS")
ns.Preview:Request("SHAMAN", "TOTEMS", nil)
local template = ns.Engine:GetCurrentTemplate()
ns.Preview:ToggleFavorite()
check(addon.db.profile.favorites[template] == true, "favorite was not stored")
ns.Preview:ToggleFavorite()
check(addon.db.profile.favorites[template] == nil, "favorite was not cleared")

-- 11. Slash routing and quick actions.
for arg, tab in pairs({ party = "PARTY", target = "TARGET", horde = "FACTION", shaman = "CLASS", attitude = "ATTITUDE", general = "GENERAL" }) do
    addon.__cmd(arg)
    check(ns.Tabs.current == tab, "/silvertongue %s opened %s", arg, tostring(ns.Tabs.current))
end
addon.__cmd("minimap")
addon.__cmd("nonsense")

local before = #sent
addon:ShowQuickMenu()
check(#sent == before, "a quick action sent a message on its own")

-- 12. The class tab follows the character, and class-flagged lines do too.
local function tabKeys()
    local keys = {}
    for _, tab in ipairs(ns.TABS) do keys[#keys + 1] = tab.key end
    return table.concat(keys, ",")
end
local function labelFor(key)
    for _, tab in ipairs(ns.TABS) do if tab.key == key then return tab.label end end
end
-- As a shaman.
check(labelFor("CLASS") == "Shaman", "shaman got class tab labelled %s", tostring(labelFor("CLASS")))
ns.Tabs:Select("CLASS")
ns.Preview:RequestOrReroll("SHAMAN", "TOTEMS", nil)
check(ns.Preview:GetText() ~= "", "shaman class tab produced nothing")

-- Rebuild the world as a rogue and reload the UI layer from scratch.
_G.__player = { name = "Sombra", className = "Rogue", classToken = "ROGUE",
                raceName = "Orc", raceToken = "Orc", faction = "Horde" }
ns.Engine:ForgetPlayer()
ns.Window.frame = nil
ns.TargetUI.headers = nil
ns.PartyUI.headers = nil
for _, f in ipairs({"Window","Preview","Tabs","Party","Target","Config","Board","Display","Contexts","Anchors"}) do load("UI/"..f..".lua") end
ns.Window:Show("GENERAL")

check(labelFor("CLASS") == "Rogue", "rogue got class tab labelled %s", tostring(labelFor("CLASS")))
check(not tabKeys():find("SHAMAN"), "a stale shaman tab survived the class change: %s", tabKeys())

ns.Tabs:Select("CLASS")
ns.Preview:RequestOrReroll("ROGUE", "SHADOWS", nil)
local rogueLine = ns.Preview:GetText()
check(rogueLine ~= "", "rogue class tab produced nothing")
local knownRogue = false
for _, line in ipairs(ns.Phrases.ROGUE.SHADOWS) do if line == rogueLine then knownRogue = true end end
check(knownRogue, "rogue class tab served a foreign line: %s", rogueLine)

-- Shared buttons, class-flagged content: a rogue must never say totems.
local ROGUE_READY = "Ready. I have been in position for some time."
local SHAMAN_READY = "Totems are down. I am set."
local seenReady = {}
for i = 1, 600 do
    ns.Preview:RequestOrReroll("PARTY", "READY", nil)
    seenReady[ns.Preview:GetText()] = true
end
check(seenReady[ROGUE_READY], "rogue never got his own Ready line")
check(not seenReady[SHAMAN_READY], "rogue was served the shaman Ready line")

-- A class with no tab of its own simply gets none, and nothing breaks.
_G.__player = { name = "Eldrin", className = "Mage", classToken = "MAGE",
                raceName = "Blood Elf", raceToken = "BloodElf", faction = "Horde" }
ns.Engine:ForgetPlayer()
ns.Window.frame = nil
ns.TargetUI.headers = nil
ns.PartyUI.headers = nil
for _, f in ipairs({"Window","Preview","Tabs","Party","Target","Config","Board","Display","Contexts","Anchors"}) do load("UI/"..f..".lua") end
ns.Window:Show("GENERAL")
check(labelFor("CLASS") == nil, "a mage was given a class tab")
addon.__cmd("shaman")   -- must not land on a tab that does not exist
check(ns.Tabs.current == "GENERAL", "class tab request on a mage landed on %s", tostring(ns.Tabs.current))
ns.Tabs:Select("PARTY")
ns.Preview:RequestOrReroll("PARTY", "MANA", nil)
check(ns.Preview:GetText() ~= "", "a mage got no OOM line")

-- 13. The key binding. One binding, no header, and it must not be able to put
--     anything in chat on its own.
_G.__player = { name = "Silvertongue", className = "Shaman", classToken = "SHAMAN",
                raceName = "Orc", raceToken = "Orc", faction = "Horde" }
ns.Engine:ForgetPlayer()
ns.Window.frame = nil
ns.TargetUI.headers = nil
ns.PartyUI.headers = nil
for _, f in ipairs({"Window","Preview","Tabs","Party","Target","Config","Board","Display","Contexts","Anchors"}) do load("UI/"..f..".lua") end

local xml = io.open("../Silvertongue/Bindings.xml"):read("*a")
local declared = {}
for name in xml:gmatch('<Binding name="([%w_]+)"') do declared[#declared + 1] = name end
check(#declared == 1, "expected one binding, Bindings.xml declares %d", #declared)
check(declared[1] == "SILVERTONGUE_TOGGLE", "the binding is named %s", declared[1])
check(_G["BINDING_NAME_" .. declared[1]] ~= nil, "%s has no display name", declared[1])
check(type(Silvertongue_BindingToggle) == "function", "the binding has no handler")

-- This client honours `category`, not `header`, and reads the category as a
-- full global name. Getting this wrong renders the heading as raw text.
check(not xml:find("header="), "the binding uses header=, which this client renders as raw text")
local category = xml:match('category="([%w_]+)"')
check(category ~= nil, "the binding declares no category, so it lands under Other")
check(category:sub(1, 8) == "BINDING_", "the category %s is not a full global name", tostring(category))
check(_G[category] ~= nil, "the category names %s, which no file defines", tostring(category))

-- XML comments must never contain a double hyphen: the client discards the
-- whole file and the binding silently disappears.
for comment in xml:gmatch("<!%-%-(.-)%-%->") do
    check(not comment:find("%-%-"), "an XML comment contains a double hyphen")
end

-- The binding body has to survive the addon failing to load.
local body = xml:match("<Binding[^>]*>(.-)</Binding>")
check(body:find("if Silvertongue_BindingToggle"), "the binding body is not guarded against a failed load")

ns.Window:Hide()
local beforeBind = #sent
Silvertongue_BindingToggle()
check(ns.Window:IsShown(), "the binding did not open the panel")
Silvertongue_BindingToggle()
check(not ns.Window:IsShown(), "the binding did not close the panel")
check(#sent == beforeBind, "the binding put something in chat")

-- 14. The faction tab follows the character the same way the class tab does.
local function labelOf(key)
    for _, tab in ipairs(ns.TABS) do if tab.key == key then return tab.label end end
end

_G.__player = { name = "Silvertongue", className = "Shaman", classToken = "SHAMAN",
                raceName = "Orc", raceToken = "Orc", faction = "Horde" }
ns.Engine:ForgetPlayer()
ns.Window.frame, ns.TargetUI.headers, ns.PartyUI.headers = nil, nil, nil
for _, f in ipairs({"Window","Preview","Tabs","Party","Target","Config","Board","Display","Contexts","Anchors"}) do load("UI/"..f..".lua") end
ns.Window:Show("GENERAL")
check(labelOf("FACTION") == "Horde", "a Horde character got the %s tab", tostring(labelOf("FACTION")))
ns.Tabs:Select("FACTION")
ns.Preview:RequestOrReroll("HORDE", "FOR_THE_HORDE", nil)
check(ns.Preview:GetText() ~= "", "the Horde tab produced nothing")

_G.__player = { name = "Alaric", className = "Rogue", classToken = "ROGUE",
                raceName = "Human", raceToken = "Human", faction = "Alliance" }
ns.Engine:ForgetPlayer()
ns.Window.frame, ns.TargetUI.headers, ns.PartyUI.headers = nil, nil, nil
for _, f in ipairs({"Window","Preview","Tabs","Party","Target","Config","Board","Display","Contexts","Anchors"}) do load("UI/"..f..".lua") end
ns.Window:Show("GENERAL")
check(labelOf("FACTION") == "Alliance", "an Alliance character got the %s tab", tostring(labelOf("FACTION")))
ns.Tabs:Select("FACTION")
ns.Preview:RequestOrReroll("ALLIANCE", "FOR_THE_ALLIANCE", nil)
local allianceLine = ns.Preview:GetText()
check(allianceLine ~= "", "the Alliance tab produced nothing")
check(not allianceLine:find("Horde"), "the Alliance tab served a Horde line: %s", allianceLine)

-- 15. Add and Hide, from the box you are already looking at.
_G.__player = { name = "Silvertongue", className = "Shaman", classToken = "SHAMAN",
                raceName = "Orc", raceToken = "Orc", faction = "Horde" }
ns.Engine:ForgetPlayer()
ns.Window.frame, ns.TargetUI.headers, ns.PartyUI.headers = nil, nil, nil
for _, f in ipairs({"Window","Preview","Tabs","Party","Target","Config","Board","Display","Contexts","Anchors"}) do load("UI/"..f..".lua") end
ns.Window:Show("GENERAL")
addon.db.profile.custom = {}

ns.Tabs:Select("GENERAL")
ns.Preview:RequestOrReroll("GENERAL", "LAUGH", nil)
check(ns.Preview.addButton:IsEnabled(), "Add was not available with a phrase loaded")
check(ns.Preview.hideButton:IsEnabled(), "Hide was not available with a phrase loaded")

local MINE = "Hah. Write that one down."
ns.Preview.edit:SetText(MINE)
ns.Preview:AddCurrent()
check(ns.Engine:IsCustom("GENERAL", "LAUGH", MINE), "Add did not save the edited line")
-- The panel writes for your class; the library is where you widen it.
check(addon.db.profile.custom.CLASS and addon.db.profile.custom.CLASS.SHAMAN,
      "the panel's Add did not write into the class scope")

local seen = {}
for i = 1, 400 do
    ns.Preview:RequestOrReroll("GENERAL", "LAUGH", nil)
    seen[ns.Preview:GetText()] = true
end
check(seen[MINE], "the added line never came up in the rotation")

-- Hide drops what is on screen and immediately shows something else.
ns.Preview:RequestOrReroll("GENERAL", "LAUGH", nil)
local doomed = ns.Engine:GetCurrentTemplate()
ns.Preview:HideCurrent()
check(ns.Engine:IsHidden("GENERAL", "LAUGH", doomed) or not ns.Engine:IsCustom("GENERAL", "LAUGH", doomed),
      "Hide did not record the dropped line")
check(ns.Preview:GetText() ~= "", "Hide left the preview empty while lines remained")
check(ns.Preview:GetText() ~= doomed, "Hide left the dropped line on screen")

-- Neither button may speak.
local beforeEdit = #sent
ns.Preview:AddCurrent()
ns.Preview:HideCurrent()
check(#sent == beforeEdit, "editing the library sent something to chat")

-- Add is refused when no intent is loaded.
ns.Preview:Clear()
ns.Preview.edit:SetText("Orphan line.")
check(not ns.Preview.addButton:IsEnabled() or select(1, ns.Engine:GetCurrentIntent()) ~= nil,
      "Add stayed live with no intent selected")

addon.db.profile.custom = {}

-- 16. The phrase library window.
addon.db.profile.custom = {}
ns.Config.frame = nil
ns.Config:Show()
check(ns.Config.frame:IsShown(), "the library window did not open")

-- The index is built from the data, and covers the character's own tabs.
local headings, intents = {}, {}
for _, section in ipairs(ns.Engine:Sections()) do
    headings[section.category] = section.label
    for _, entry in ipairs(ns.Engine:Intents(section.category)) do
        intents[section.category .. "." .. entry.intent] = entry.count
    end
end
for _, category in ipairs({"GENERAL", "PARTY", "PERSON", "TARGET", "ENEMY", "ATTITUDE", "HORDE", "SHAMAN"}) do
    check(headings[category], "the library is missing the %s section", category)
end
check(not headings["ROGUE"], "a shaman's library listed the rogue section")
check(not headings["ALLIANCE"], "a Horde character's library listed the Alliance section")
check(intents["ATTITUDE.ANGRY"] and intents["ATTITUDE.ANGRY"] > 0, "Attitude/Angry listed no lines")
check(ns.Titlecase("FOR_THE_HORDE") == "For The Horde", "headings are not being titlecased")

-- Every line is tagged with where it came from.
local described = ns.Engine:DescribePool("PARTY", "READY", nil)
local origins = {}
for _, entry in ipairs(described) do origins[entry.origin] = true end
check(origins["shared"], "no line was tagged as shared")
check(origins["your class"], "the shaman's own Ready lines were not tagged")

-- The scope picker, and what each scope reaches.
check(ns.Config.scope == "CLASS", "the library did not default to the class scope")
check(ns.Engine:ScopeLabel("ALL") == "All my characters", "the ALL scope is labelled %s", ns.Engine:ScopeLabel("ALL"))
check(ns.Engine:ScopeLabel("CLASS") == "Shaman", "the class scope is labelled %s", ns.Engine:ScopeLabel("CLASS"))
check(ns.Engine:ScopeLabel("RACE") == "Orc", "the race scope is labelled %s", ns.Engine:ScopeLabel("RACE"))

-- Selecting an intent and adding a line through the window.
ns.Config:Select("ATTITUDE", "ANGRY")
local before = #ns.Engine:DescribePool("ATTITUDE", "ANGRY", nil)
local LIBRARY_LINE = "I am going to remember this conversation."
ns.Config.editBox:SetText(LIBRARY_LINE)
ns.Config:AddFromBox()
check(ns.Engine:IsCustom("ATTITUDE", "ANGRY", LIBRARY_LINE), "the library window did not save the line")
check(#ns.Engine:DescribePool("ATTITUDE", "ANGRY", nil) == before + 1, "the new line did not appear in the list")
check(ns.Config.editBox:GetText() == "", "the box was not cleared after adding")

-- A line written for every character reaches another character.
ns.Config:SetScope("ALL")
local SHARED_LINE = "That will do."
ns.Config.editBox:SetText(SHARED_LINE)
ns.Config:AddFromBox()
_G.__player = { name = "Sombra", className = "Rogue", classToken = "ROGUE",
                raceName = "Troll", raceToken = "Troll", faction = "Horde" }
ns.Engine:ForgetPlayer()
local reachesOthers = false
for _, entry in ipairs(ns.Engine:DescribePool("ATTITUDE", "ANGRY", nil)) do
    if entry.text == SHARED_LINE then reachesOthers = true end
end
check(reachesOthers, "a line written for all characters did not reach another one")
_G.__player = { name = "Silvertongue", className = "Shaman", classToken = "SHAMAN",
                raceName = "Orc", raceToken = "Orc", faction = "Horde" }
ns.Engine:ForgetPlayer()
ns.Config:SetScope("CLASS")

-- Dropping and restoring through a row.
local row = ns.Config.phraseRows[1]
row.phrase, row.hidden = ns.Phrases.ATTITUDE.ANGRY[1], false
row.origin:SetText("shared")
ns.Config:ToggleRow(row)

-- Dropping a shared line must take it out on every character, not just this one.
_G.__player = { name = "Sombra", className = "Rogue", classToken = "ROGUE",
                raceName = "Troll", raceToken = "Troll", faction = "Horde" }
ns.Engine:ForgetPlayer()
check(ns.Engine:IsHidden("ATTITUDE", "ANGRY", ns.Phrases.ATTITUDE.ANGRY[1]),
      "a shared line dropped on the shaman was still live on the rogue")
_G.__player = { name = "Silvertongue", className = "Shaman", classToken = "SHAMAN",
                raceName = "Orc", raceToken = "Orc", faction = "Horde" }
ns.Engine:ForgetPlayer()
check(ns.Engine:IsHidden("ATTITUDE", "ANGRY", ns.Phrases.ATTITUDE.ANGRY[1]), "the row did not drop the line")

local dropped = ns.Engine:DescribePool("ATTITUDE", "ANGRY", nil)
local foundHidden = false
for _, entry in ipairs(dropped) do
    if entry.text == ns.Phrases.ATTITUDE.ANGRY[1] then
        foundHidden = entry.hidden == true
    end
end
check(foundHidden, "a dropped line vanished from the list instead of being marked")

row.hidden = true
ns.Config:ToggleRow(row)
check(not ns.Engine:IsHidden("ATTITUDE", "ANGRY", ns.Phrases.ATTITUDE.ANGRY[1]), "the row did not restore the line")

-- The library must not be able to speak.
local beforeLibrary = #sent
ns.Config:AddFromBox()
ns.Config:ToggleRow(row)
ns.Config:Refresh()
check(#sent == beforeLibrary, "the library window sent something to chat")

-- An Alliance character sees its own sections and not the Horde ones.
_G.__player = { name = "Alaric", className = "Rogue", classToken = "ROGUE",
                raceName = "Human", raceToken = "Human", faction = "Alliance" }
ns.Engine:ForgetPlayer()
local allianceHeadings = {}
for _, section in ipairs(ns.Engine:Sections()) do allianceHeadings[section.category] = true end
check(allianceHeadings["ALLIANCE"], "an Alliance character's library has no Alliance section")
check(not allianceHeadings["HORDE"], "an Alliance character's library listed the Horde section")
check(allianceHeadings["ROGUE"], "a rogue's library has no Rogue section")

_G.__player = { name = "Silvertongue", className = "Shaman", classToken = "SHAMAN",
                raceName = "Orc", raceToken = "Orc", faction = "Horde" }
ns.Engine:ForgetPlayer()
addon.db.profile.custom = {}

-- 17. The contextual layer: controls on the frames, one board per group, and
--     the floating display that is the only thing able to speak.
addon.db.profile.custom = {}
addon.db.profile.anchorsEnabled = true
group = {}
target = nil

ns.Anchors:Refresh()
check(ns.Anchors.targetControl ~= nil, "no control was built for the target frame")
check(not ns.Anchors.targetControl:IsShown(), "the target control showed with nothing selected")

-- Each anchor group gets its own board, sized for its own longest context.
local targetBoard = ns.Board:New("Target")
local playerBoard = ns.Board:New("Player")
local partyBoard  = ns.Board:New("Party")
check(targetBoard ~= playerBoard and playerBoard ~= partyBoard, "the boards are not separate")
check(ns.Board:New("Target") == targetBoard, "asking for a board twice built two")
check(#ns.Board:New("Target").key > 0, "a board has no key")

-- A friendly player: the target control appears and the board fills.
target = { name = "Gromkar", className = "Warrior", classToken = "WARRIOR", raceName = "Orc", raceToken = "Orc" }
addon.__events["PLAYER_TARGET_CHANGED"]()
check(ns.Anchors.targetControl:IsShown(), "the target control stayed hidden with a target selected")

local context = ns.Contexts:Target()
check(context ~= nil, "no context was built for a friendly player")
check(context.title == "Gromkar", "the context is titled %s", tostring(context.title))
-- The menu no longer draws a heading: the frame it hangs off already names them.
check(targetBoard.title == nil, "the menu still builds a heading")
local labels = {}
for _, entry in ipairs(context.intents) do
    if entry ~= ns.SEP then labels[entry[3]] = true end
end
check(labels["Party?"], "a friendly player outside the group was not offered Party?")

-- The longest context must still fit: a friendly warlock.
target = { name = "Morghul", className = "Warlock", classToken = "WARLOCK", raceName = "Orc", raceToken = "Orc" }
local warlockContext = ns.Contexts:Target()
targetBoard:Open(nil, warlockContext)
local shownRows = 0
for _, row in ipairs(targetBoard.rows) do
    if row:IsShown() then shownRows = shownRows + 1 end
end
check(shownRows >= #warlockContext.intents,
      "the menu showed %d rows for %d intents", shownRows, #warlockContext.intents)
targetBoard:Close()

-- Channels come from the context, never from the player.
target = { name = "Gromkar", className = "Warrior", classToken = "WARRIOR", raceName = "Orc", raceToken = "Orc" }
local function channelKeys(ctx)
    local keys = {}
    for _, channel in ipairs(ctx.channels) do keys[#keys + 1] = channel.key end
    return table.concat(keys, ",")
end
check(channelKeys(ns.Contexts:Target()) == "SAY,YELL,WHISPER",
      "a stranger offered %s", channelKeys(ns.Contexts:Target()))

target = { name = "Aelindra", className = "Rogue", classToken = "ROGUE", raceName = "Night Elf", raceToken = "NightElf", hostile = true }
check(channelKeys(ns.Contexts:Target()) == "SAY,YELL",
      "a hostile target offered %s", channelKeys(ns.Contexts:Target()))

-- Someone already in your group: no Party?, and party chat becomes an option
-- because they may be across the dungeon.
group = { { name = "Gromkar", className = "Warrior", classToken = "WARRIOR", raceName = "Orc", raceToken = "Orc" } }
target = group[1]
local grouped = ns.Contexts:Target()
local groupedLabels = {}
for _, entry in ipairs(grouped.intents) do
    if entry ~= ns.SEP then groupedLabels[entry[3]] = true end
end
check(not groupedLabels["Party?"], "someone already in the group was offered Party?")
check(channelKeys(grouped) == "SAY,PARTY,WHISPER", "a grouped target offered %s", channelKeys(grouped))

-- Party contexts speak to the party without anyone choosing a channel.
check(ns.Contexts:PartyAll().channels[1].key == "PARTY", "the group context does not default to party chat")
check(ns.Contexts:PartyAll().channels[1].label == "Say", "the group's first button is not labelled Say")
check(ns.Contexts:PartyMember("party1").channels[1].key == "PARTY", "a member context does not default to party chat")

-- At rest the portrait carries one bubble and nothing else. Pressing it fans
-- the categories out; pressing it again folds them away.
addon.db.profile.playerFanOpen = false
ns.Anchors:Refresh()
check(ns.Anchors.hub ~= nil, "no bubble was built on the portrait")
check(ns.Anchors.hub:IsShown(), "the bubble is hidden")
check(#ns.Anchors.fanControls == 4, "a shaman got %d category icons instead of four",
      #ns.Anchors.fanControls)
for _, control in ipairs(ns.Anchors.fanControls) do
    check(not control:IsShown(), "a category icon was showing while folded away")
end

ns.Anchors:ToggleFan()
for _, control in ipairs(ns.Anchors.fanControls) do
    check(control:IsShown(), "a category icon stayed hidden after opening the fan")
end
check(addon.db.profile.playerFanOpen, "the fan state was not remembered")

ns.Anchors:ToggleFan()
check(not ns.Anchors.fanControls[1]:IsShown(), "the fan did not fold away")
check(not playerBoard:IsShown(), "folding the fan left its menu open")
ns.Anchors:SetFanOpen(true)

-- Your own portrait: four categories, each with its own phrases.
local playerContext = ns.Contexts:Player("GENERAL")
check(playerContext and #playerContext.intents > 0, "the General context is empty")
check(channelKeys(playerContext) == "SAY,YELL", "your own context offered %s", channelKeys(playerContext))
check(ns.Contexts:Player("CLASS").subtitle == "Shaman", "the class context is titled %s",
      tostring(ns.Contexts:Player("CLASS").subtitle))
check(ns.Contexts:Player("FACTION").subtitle == "Horde", "the faction context is titled %s",
      tostring(ns.Contexts:Player("FACTION").subtitle))
check(#ns.Contexts:Player("GENERAL").intents > 0, "the player General menu is empty")

-- Opening a board fills it and speaks to nobody.
local beforeBoards = #sent
target = { name = "Gromkar", className = "Warrior", classToken = "WARRIOR", raceName = "Orc", raceToken = "Orc" }
group = {}
targetBoard:Open(ns.Anchors.targetControl, ns.Contexts:Target())
check(targetBoard:IsShown(), "the board did not open")
check(targetBoard.rows[1]:IsShown(), "the board opened with no rows")
check(#sent == beforeBoards, "opening a board sent something")

-- Picking an intent fills the display. It still says nothing.
targetBoard:Pick({ "PERSON", "PRAISE", "Praise" })
check(ns.Display:IsShown(), "picking an intent did not open the display")
check(ns.Display.edit:GetText():find("Gromkar", 1, true), "the display did not name the target")
check(#sent == beforeBoards, "picking an intent sent something")

-- Picking the same intent again rerolls rather than repeating.
local first = ns.Display.edit:GetText()
targetBoard:Pick({ "PERSON", "PRAISE", "Praise" })
check(ns.Display.edit:GetText() ~= first, "picking the same intent twice repeated the phrase")

-- The channel buttons are the send.
local beforeSend = #sent
ns.Display:Send("SAY")
check(#sent == beforeSend + 1, "the channel button did not send")
check(sent[#sent].channel == "SAY", "it went out on %s", sent[#sent].channel)
check(not ns.Display:IsShown(), "the display stayed open after speaking")
check(targetBoard:IsShown(), "the menu closed itself after speaking")

-- The menu stays up after speaking, so a conversation does not need it
-- reopened between every line.
targetBoard:Open(ns.Anchors.targetControl, ns.Contexts:Target())
targetBoard:Pick({ "PERSON", "THANK", "Thank" })
ns.Display:Send("SAY")
check(targetBoard:IsShown(), "the menu closed itself after speaking")
targetBoard:Close()

-- The gesture fires with the line, and only when it is left on.
emoted = {}
targetBoard:Open(ns.Anchors.targetControl, ns.Contexts:Target())
targetBoard:Pick({ "PERSON", "THANK", "Thank" })
check(ns.Display.emoteCheck:IsShown(), "Thank showed no gesture")
ns.Display:Send("SAY")
check(#emoted == 1, "the gesture did not fire with the line")
check(emoted[1][1] == "THANK", "the gesture was %s", tostring(emoted[1][1]))
check(emoted[1][2] == "Gromkar", "the gesture was not aimed at the target")

-- Unchecked, it must not fire.
emoted = {}
targetBoard:Open(ns.Anchors.targetControl, ns.Contexts:Target())
targetBoard:Pick({ "PERSON", "THANK", "Thank" })
ns.Display.emoteCheck:SetChecked(false)
ns.Display.emoteCheck:GetScript("OnClick")(ns.Display.emoteCheck)
ns.Display:Send("SAY")
check(#emoted == 0, "the gesture fired with its checkbox off")

-- An intent with no gesture shows no checkbox.
targetBoard:Open(ns.Anchors.targetControl, ns.Contexts:Target())
targetBoard:Pick({ "PERSON", "WARN", "Warn" })
check(not ns.Display.emoteCheck:IsShown(), "Warn was given a gesture")

-- The actions ride on the board, beside the phrases, and act without speaking.
targetBoard:Open(ns.Anchors.targetControl, ns.Contexts:Target())
acted = {}
local beforeActions = #sent
local actionRows = 0
for _, row in ipairs(targetBoard.rows) do
    if row:IsShown() and row.action then
        actionRows = actionRows + 1
        row:GetScript("OnClick")(row)
    end
end
check(actionRows == 3, "expected three action rows in the menu, got %d", actionRows)
check(#acted == 3, "the action rows did not fire, got %d", #acted)
check(#sent == beforeActions, "an action row spoke")

-- Already in the group: no invite offered.
group = { { name = "Gromkar", className = "Warrior", classToken = "WARRIOR", raceName = "Orc", raceToken = "Orc" } }
local groupedActions = ns.Contexts:Target().actions
local sawInvite = false
for _, action in ipairs(groupedActions or {}) do
    if action.label == "Invite" then sawInvite = true end
end
check(not sawInvite, "someone already in the group was offered an invite")
group = {}

-- A creature gets none at all.
target = { name = "Ragged Timber Wolf", hostile = true }
check(ns.Contexts:Target().actions == nil, "a creature was given actions")
target = { name = "Gromkar", className = "Warrior", classToken = "WARRIOR", raceName = "Orc", raceToken = "Orc" }
targetBoard:Close()

-- The control that opened a menu marks itself, since the menu no longer says
-- which one is open.
local generalControl = ns.Anchors.fanControls[1]
playerBoard:Open(generalControl, ns.Contexts:Player("GENERAL"))
check(generalControl.active, "the open category did not mark itself")
local hordeControl = ns.Anchors.fanControls[2]
playerBoard:Open(hordeControl, ns.Contexts:Player("FACTION"))
check(hordeControl.active, "the newly opened category did not mark itself")
check(not generalControl.active, "the previous category stayed marked")
playerBoard:Close()
check(not hordeControl.active, "closing the menu left the category marked")

-- Separators draw a line and never become a clickable row.
targetBoard:Open(ns.Anchors.targetControl, ns.Contexts:Target())
for _, row in ipairs(targetBoard.rows) do
    if row:IsShown() and row.entry then
        check(row.entry ~= ns.SEP, "a separator was rendered as a clickable row")
    end
end
local sepCount = 0
for _, entry in ipairs(ns.Contexts:Target().intents) do
    if entry == ns.SEP then sepCount = sepCount + 1 end
end
check(sepCount > 0, "the target menu declares no groups")
targetBoard:Close()

-- The panel's grids must ignore them entirely.
ns.Tabs:Select("GENERAL")
local generalContext = ns.Contexts:Player("GENERAL")
local clickable = 0
for _, entry in ipairs(generalContext.intents) do
    if entry ~= ns.SEP then
        clickable = clickable + 1
        check(type(entry[2]) == "string", "an intent entry has no key")
    end
end
check(clickable == 15, "General offers %d intents instead of fifteen", clickable)

-- Losing the target takes the control and the board with it.
target = nil
addon.__events["PLAYER_TARGET_CHANGED"]()
check(not ns.Anchors.targetControl:IsShown(), "the control survived losing the target")
check(not targetBoard:IsShown(), "the board survived losing the target")

-- Turning the controls off hides everything and closes the boards.
ns.Anchors:SetEnabled(false)
check(not ns.Anchors.targetControl:IsShown(), "a control survived being switched off")
ns.Anchors:SetEnabled(true)

-- The gesture picker in the library.
ns.Config:Select("GENERAL", "THANKS")
local libraryRow = ns.Config.phraseRows[1]
libraryRow.phrase = ns.Phrases.GENERAL.THANKS[1]
ns.Config:OpenEmotePicker(libraryRow)
check(ns.Config.emoteMenu:IsShown(), "the gesture picker did not open")
ns.Config:ChooseEmote("BOW")
check(ns.Engine:EmoteFor("GENERAL", "THANKS", libraryRow.phrase) == "BOW",
      "the picker did not set the gesture")
ns.Config:ChooseEmote(ns.EMOTE_NONE)
check(ns.Engine:EmoteFor("GENERAL", "THANKS", libraryRow.phrase) == nil,
      "the picker could not clear a gesture")
addon.db.profile.custom = {}

check(#sent == beforeSend + 4, "something spoke outside the explicit sends")

-- 18. Rearranging a menu, and the reconciliation that keeps it from freezing.
addon.db.profile.menus = {}
ns.Config:Show()

local generalMenu = nil
for _, menu in ipairs({ { key = "GENERAL", label = "General",
                          builtin = function() return ns.INTENTS.GENERAL end } }) do
    generalMenu = menu
end
ns.Config:SelectMenu(generalMenu)
check(ns.Config.menuOrder ~= nil, "selecting a menu built no order")

local function keysOf(order)
    local out = {}
    for _, entry in ipairs(order) do out[#out + 1] = ns.MenuEntryKey(entry) end
    return out
end
local before = keysOf(ns.Config.menuOrder)
check(#before > 0, "the General menu resolved empty")

-- Moving a row moves it, and is remembered.
local firstKey, secondKey = before[1], before[2]
ns.Config:MoveMenuRow(2, 1)
local after = keysOf(ns.Config.menuOrder)
check(after[1] == secondKey and after[2] == firstKey, "moving a row did not swap it")
check(addon.db.profile.menus.GENERAL ~= nil, "the new order was not saved")
check(#ns.ResolveMenu("GENERAL", ns.INTENTS.GENERAL) == #ns.Config.menuOrder,
      "the saved order did not come back the same length")
check(ns.MenuEntryKey(ns.ResolveMenu("GENERAL", ns.INTENTS.GENERAL)[1]) == secondKey,
      "the saved order did not survive a reload")

-- Adding and removing a dividing line.
local rowsBefore = #ns.Config.menuOrder
ns.Config:AddMenuLine(3)
check(#ns.Config.menuOrder == rowsBefore + 1, "adding a line changed nothing")
check(ns.Config.menuOrder[4] == ns.SEP, "the line did not land where it was asked for")
ns.Config:RemoveMenuRow(4)
check(#ns.Config.menuOrder == rowsBefore, "removing a line changed nothing")

-- An intent added after you rearranged must still reach you, on the end.
ns.INTENTS.GENERAL[#ns.INTENTS.GENERAL + 1] = { "NEWTHING", "New Thing" }
local reconciled = ns.ResolveMenu("GENERAL", ns.INTENTS.GENERAL)
check(ns.MenuEntryKey(reconciled[#reconciled]) == "NEWTHING",
      "an intent added later never reached a rearranged menu")

-- And one that no longer exists simply falls away rather than erroring.
table.remove(ns.INTENTS.GENERAL)
local pruned = ns.ResolveMenu("GENERAL", ns.INTENTS.GENERAL)
for _, entry in ipairs(pruned) do
    check(ns.MenuEntryKey(entry) ~= "NEWTHING", "a removed intent stayed in the saved order")
end

-- Never two lines running, nor one at either end.
addon.db.profile.menus.GENERAL = { "SEP", "SEP", "HELLO", "SEP", "SEP", "GOODBYE", "SEP" }
local tidy = ns.ResolveMenu("GENERAL", ns.INTENTS.GENERAL)
check(tidy[1] ~= ns.SEP, "a menu began with a dividing line")
check(tidy[#tidy] ~= ns.SEP, "a menu ended with a dividing line")
local runs = 0
for i = 2, #tidy do
    if tidy[i] == ns.SEP and tidy[i - 1] == ns.SEP then runs = runs + 1 end
end
check(runs == 0, "two dividing lines ended up next to each other")

-- Reset puts back what it came with.
ns.Config:SelectMenu(generalMenu)
ns.Config:ResetMenu()
check(addon.db.profile.menus.GENERAL == nil, "resetting did not clear the saved order")

-- The order editor must not be able to speak either.
local beforeMenus = #sent
ns.Config:MoveMenuRow(1, 2)
ns.Config:AddMenuLine(1)
ns.Config:ResetMenu()
check(#sent == beforeMenus, "the order editor sent something to chat")

addon.db.profile.menus = {}
ns.Config:Select("GENERAL", "THANKS")

print(errors == 0 and "UI SMOKE: ALL CHECKS PASSED" or ("UI SMOKE: " .. errors .. " FAILURES"))
print(string.format("messages sent during the whole run: %d (all via explicit Send calls)", #sent))
os.exit(errors == 0 and 0 or 1)
