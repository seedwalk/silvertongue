-- Mocks just enough of the WoW UI so the whole addon can be loaded and driven.
-- It will not prove the layout looks right; it does prove no code path nils out.
local DIR = "../Silvertongue/"
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
    self.__w = w
end
passthrough.SetHeight = function(self, h)
    if type(h) ~= "number" then error("bad argument to SetHeight (" .. tostring(h) .. ")", 2) end
    self.__h = h
end
-- An edit box that never focuses itself. Getting this wrong means pressing W to
-- walk and typing a "w" into somebody's whisper instead.
passthrough.SetAutoFocus = function(self, value)
    if value then error("an edit box asked for the keyboard on its own", 2) end
    self.__autoFocus = false
end
passthrough.SetPoint = function(self, point, a, b, c, d)
    self.__point = point
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
-- Roughly what the small font measures, which is all the layout needs.
passthrough.GetStringWidth = function(self) return #(self.__text or "") * 5.5 end
passthrough.SetNormalTexture = function(self, path) self.__normalTexture = path end
passthrough.GetNormalTexture = function(self) return newMock("texture") end
passthrough.IsMouseOver = function() return false end
-- A ScrollingMessageFrame keeps its own lines; the tests read them back.
passthrough.AddMessage = function(self, text)
    self.__lines = self.__lines or {}
    self.__lines[#self.__lines + 1] = text
end
passthrough.Clear = function(self) self.__lines = {} end
passthrough.SetMaxLines = function(self, n)
    if type(n) ~= "number" then error("bad argument to SetMaxLines", 2) end
end

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
-- A client where the party frames are named something else entirely.
local function hidePartyFrames()
    for i = 1, 4 do _G["PartyMemberFrame" .. i] = nil end
end

local emoted = {}
function DoEmote(token, target) emoted[#emoted + 1] = { token, target } end
UnitInParty = function(u)
    for i = 1, 4 do
        if UnitExists("party" .. i) and UnitName("party" .. i) == UnitName(u) then return true end
    end
    return false
end
UnitInRaid = function() return false end
UnitLevel = function() return 36 end
date = function(fmt, when) return "12:00" end
-- Race and class straight off a chat message's sender GUID.
local guids = {}
GetPlayerInfoByGUID = function(guid)
    local g = guids[guid]
    if not g then return nil end
    return g.className, g.classToken, g.raceName, g.raceToken, 2, g.name, g.realm
end
local lfgChannelId = 4
local joined = {}
GetChannelName = function(name) return (name == "LookingForGroup") and lfgChannelId or 0 end
JoinChannelByName = function(name) joined[#joined + 1] = name; lfgChannelId = 4 end
-- Runs straight away so the test can see what the delayed send does.
C_Timer = { After = function(_, fn) fn() end }
UnitIsGroupLeader = function() return true end
local assignedRoles = {}
UnitGroupRolesAssigned = function(unit) return assignedRoles[unit] or "NONE" end
UnitIsGroupAssistant = function() return false end

-- The group browser, as this client reports it.
local listings = {}
C_LFGList = {
    HasSearchResultInfo = function(id) return listings[id] ~= nil end,
    GetSearchResultInfo = function(id) return listings[id] end,
    GetSearchResultPlayerInfo = function(id) return listings[id] and listings[id].player end,
    GetSearchResultMemberCounts = function(id) return listings[id] and listings[id].counts end,
    GetActivityInfoTable = function(activityID)
        return { fullName = "Scarlet Monastery", shortName = "SM" }
    end,
}
ScrollUtil = {
    AddAcquiredFrameCallback = function() end,
    AddReleasedFrameCallback = function() end,
}
GetInstanceInfo = function() return "" end

NUM_CHAT_WINDOWS = 2
for i = 1, NUM_CHAT_WINDOWS do
    local frame = newMock("ScrollingMessageFrame", "ChatFrame" .. i)
    frame.AddMessage = function(self, text)
        self.__written = self.__written or {}
        self.__written[#self.__written + 1] = text
    end
    _G["ChatFrame" .. i] = frame
end

-- The chat message filters and our own link type.
local filters = {}
function ChatFrame_AddMessageEventFilter(event, fn)
    filters[event] = filters[event] or {}
    table.insert(filters[event], fn)
end
local linkHandlers = {}
LinkUtil = {
    RegisterLinkHandler = function(kind, fn)
        if linkHandlers[kind] then error("duplicate link handler for " .. kind) end
        linkHandlers[kind] = fn
    end,
    IsLinkHandlerRegistered = function(kind) return linkHandlers[kind] ~= nil end,
}
-- Runs one message through every filter, the way the chat frame does.
local function deliver(event, message, author)
    local out, name = message, author
    for _, fn in ipairs(filters[event] or {}) do
        local blocked, newMessage, newAuthor = fn(nil, event, out, name)
        if blocked then return nil end
        out, name = newMessage or out, newAuthor or name
    end
    return out
end
local function clickLink(link) return linkHandlers.silvertongue(link) end

-- The guild roster: level and class, and deliberately no race, because
-- GetGuildRosterInfo does not return one.
local guild = {}
IsInGuild = function() return true end
GetNumGuildMembers = function() return #guild end
GetGuildRosterInfo = function(i)
    local m = guild[i]
    if not m then return nil end
    return m.name, "Member", 1, m.level, m.className
end

local whoSent = {}
local whoResults = {}
local whoToUi = false
Enum = { SocialWhoOrigin = { Chat = 1 } }
WHO_TAG_EXACT = "n-\""
C_FriendList = {
    -- A who answer only reaches the list when this is on. Off, which is the
    -- default, the server prints it into the chat frame instead and the list
    -- stays empty -- which is what the window was showing.
    SendWho = function(query) whoSent[#whoSent + 1] = { query = query, toUi = whoToUi } end,
    SetWhoToUi = function(value) whoToUi = value and true or false end,
    GetNumWhoResults = function() return whoToUi and #whoResults or 0 end,
    GetWhoInfo = function(i) return whoToUi and whoResults[i] or nil end,
}
local now = 1757000000
time = function() return now end

-- A Battle.net friend. The client simply knows all of this, which is why these
-- windows need no lookup at all.
local bnAccounts = {}
C_BattleNet = { GetAccountInfoByID = function(id) return bnAccounts[tostring(id)] end }
local bnSent = {}
BNSendWhisper = function(id, text) bnSent[#bnSent + 1] = { id = id, text = text } end

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
InviteToGroup = function(name) acted[#acted + 1] = { "invite", name } end
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
load("Log.lua")
for _, f in ipairs({"Engine","General","Party","Horde","Shaman","Rogue","Warrior","Paladin",
                    "Hunter","Priest","Mage","Warlock","Druid","Attitude","Classes","Races",
                    "Target","Self","Alliance","Dungeons","Group","Whisper","Emotes"}) do load("RP/"..f..".lua") end
for _, f in ipairs({"Window","Preview","Tabs","Party","Target","Config","Board","Display","Contexts","Anchors","LFGBrowse","Whisper","ChatLinks"}) do load("UI/"..f..".lua") end
load("Core.lua")

local addon = ns.addon
addon:OnInitialize()
addon:OnEnable()

local errors = 0
local function check(cond, fmt, ...)
    if not cond then errors = errors + 1; print("FAIL: " .. string.format(fmt, ...)) end
end

-- 1. Open the panel and walk every tab, clicking every intent button.
-- The bare command opens the library, which is the front door now.
addon.__cmd("")
check(ns.Config.frame ~= nil and ns.Config.frame:IsShown(), "the library did not open")
ns.Config:Hide()
addon.__cmd("panel")
check(ns.Window.frame:IsShown(), "the tabbed panel did not open")

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
for _, f in ipairs({"Window","Preview","Tabs","Party","Target","Config","Board","Display","Contexts","Anchors","LFGBrowse","Whisper","ChatLinks"}) do load("UI/"..f..".lua") end
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

-- A class with nothing written for it simply gets no tab, and nothing breaks.
-- Every class playable in this expansion now has one, so this uses a token that
-- does not exist here.
_G.__player = { name = "Eldrin", className = "Death Knight", classToken = "DEATHKNIGHT",
                raceName = "Blood Elf", raceToken = "BloodElf", faction = "Horde" }
ns.Engine:ForgetPlayer()
ns.Window.frame = nil
ns.TargetUI.headers = nil
ns.PartyUI.headers = nil
for _, f in ipairs({"Window","Preview","Tabs","Party","Target","Config","Board","Display","Contexts","Anchors","LFGBrowse","Whisper","ChatLinks"}) do load("UI/"..f..".lua") end
ns.Window:Show("GENERAL")
check(labelFor("CLASS") == nil, "a class with no phrases was given a tab")
addon.__cmd("shaman")   -- must not land on a tab that does not exist
check(ns.Tabs.current == "GENERAL", "a class tab request with no tab landed on %s", tostring(ns.Tabs.current))
ns.Tabs:Select("PARTY")
ns.Preview:RequestOrReroll("PARTY", "MANA", nil)
check(ns.Preview:GetText() ~= "", "that character got no OOM line")

-- 13. The key binding. One binding, no header, and it must not be able to put
--     anything in chat on its own.
_G.__player = { name = "Silvertongue", className = "Shaman", classToken = "SHAMAN",
                raceName = "Orc", raceToken = "Orc", faction = "Horde" }
ns.Engine:ForgetPlayer()
ns.Window.frame = nil
ns.TargetUI.headers = nil
ns.PartyUI.headers = nil
for _, f in ipairs({"Window","Preview","Tabs","Party","Target","Config","Board","Display","Contexts","Anchors","LFGBrowse","Whisper","ChatLinks"}) do load("UI/"..f..".lua") end

local xml = io.open(DIR .. "Bindings.xml"):read("*a")
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

ns.Config:Hide()
local beforeBind = #sent
Silvertongue_BindingToggle()
check(ns.Config.frame:IsShown(), "the binding did not open Silvertongue")
Silvertongue_BindingToggle()
check(not ns.Config.frame:IsShown(), "the binding did not close it")
check(#sent == beforeBind, "the binding put something in chat")

-- 14. The faction tab follows the character the same way the class tab does.
local function labelOf(key)
    for _, tab in ipairs(ns.TABS) do if tab.key == key then return tab.label end end
end

_G.__player = { name = "Silvertongue", className = "Shaman", classToken = "SHAMAN",
                raceName = "Orc", raceToken = "Orc", faction = "Horde" }
ns.Engine:ForgetPlayer()
ns.Window.frame, ns.TargetUI.headers, ns.PartyUI.headers = nil, nil, nil
for _, f in ipairs({"Window","Preview","Tabs","Party","Target","Config","Board","Display","Contexts","Anchors","LFGBrowse","Whisper","ChatLinks"}) do load("UI/"..f..".lua") end
ns.Window:Show("GENERAL")
check(labelOf("FACTION") == "Horde", "a Horde character got the %s tab", tostring(labelOf("FACTION")))
ns.Tabs:Select("FACTION")
ns.Preview:RequestOrReroll("HORDE", "FOR_THE_HORDE", nil)
check(ns.Preview:GetText() ~= "", "the Horde tab produced nothing")

_G.__player = { name = "Alaric", className = "Rogue", classToken = "ROGUE",
                raceName = "Human", raceToken = "Human", faction = "Alliance" }
ns.Engine:ForgetPlayer()
ns.Window.frame, ns.TargetUI.headers, ns.PartyUI.headers = nil, nil, nil
for _, f in ipairs({"Window","Preview","Tabs","Party","Target","Config","Board","Display","Contexts","Anchors","LFGBrowse","Whisper","ChatLinks"}) do load("UI/"..f..".lua") end
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
for _, f in ipairs({"Window","Preview","Tabs","Party","Target","Config","Board","Display","Contexts","Anchors","LFGBrowse","Whisper","ChatLinks"}) do load("UI/"..f..".lua") end
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
local clickableIntents = 0
for _, entry in ipairs(warlockContext.intents) do
    if entry ~= ns.SEP then clickableIntents = clickableIntents + 1 end
end
check(shownRows >= clickableIntents,
      "the menu showed %d rows for %d intents", shownRows, clickableIntents)
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

-- In a group, party chat leads everywhere: it is where most of what you say
-- while grouped is meant to land.
group = { { name = "Altheon", className = "Priest", classToken = "PRIEST", raceName = "Troll", raceToken = "Troll" } }
check(channelKeys(ns.Contexts:Target()) == "PARTY,SAY,YELL,WHISPER",
      "grouped, a stranger offered %s", channelKeys(ns.Contexts:Target()))
check(channelKeys(ns.Contexts:Player("GENERAL")) == "PARTY,SAY,YELL",
      "grouped, your own menu offered %s", channelKeys(ns.Contexts:Player("GENERAL")))
group = {}
check(channelKeys(ns.Contexts:Player("GENERAL")) == "SAY,YELL",
      "alone, your own menu offered %s", channelKeys(ns.Contexts:Player("GENERAL")))

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
check(channelKeys(grouped) == "PARTY,SAY,WHISPER", "a grouped target offered %s", channelKeys(grouped))

-- Party contexts speak to the party without anyone choosing a channel.
check(ns.Contexts:PartyAll().channels[1].key == "PARTY", "the group context does not default to party chat")
-- Two buttons labelled "Say" going to two places is worse than none.
local seenLabels = {}
for _, channel in ipairs(ns.Contexts:PartyMember("party1").channels) do
    check(not seenLabels[channel.label], "two channel buttons are both labelled %s", channel.label)
    seenLabels[channel.label] = true
end
check(ns.Contexts:PartyAll().channels[1].label == "Party", "the group's first button is labelled %s",
      ns.Contexts:PartyAll().channels[1].label)
check(ns.Contexts:PartyMember("party1").channels[1].key == "PARTY", "a member context does not default to party chat")

-- At rest the portrait carries one bubble and nothing else. Pressing it fans
-- the categories out; pressing it again folds them away.
ns.Anchors.fanOpen = false
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
-- Deliberately not persisted: the resting state is one bubble.
check(addon.db.profile.playerFanOpen == nil, "the fan state is being saved")

ns.Anchors:ToggleFan()
check(not ns.Anchors.fanControls[1]:IsShown(), "the fan did not fold away")
check(not playerBoard:IsShown(), "folding the fan left its menu open")
ns.Anchors:SetFanOpen(true)

-- Your own portrait: four categories, each with its own phrases.
group = {}
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

-- Two rows, cut to the phrase rather than a fixed size.
check(ns.Display.frame.__h and ns.Display.frame.__h <= 56,
      "the display is %s tall", tostring(ns.Display.frame.__h))
-- Reroll is an icon, not a word: it must carry a texture and a tooltip.
check(ns.Display.rerollButton.__normalTexture ~= nil, "the reroll button has no icon")
check(ns.Display.rerollButton:GetScript("OnEnter") ~= nil, "the reroll icon has no tooltip")
-- Rerolling may widen the strip, but nothing you click may move: the controls
-- chain from the left edge, which is the edge that stays put.
local buttonAnchor = ns.Display.channelButtons[1].__point
local shortWidth = ns.Display.frame.__w
ns.Display:Layout(string.rep("a very long line indeed ", 8))
check(ns.Display.frame.__w > shortWidth, "a longer phrase did not widen the strip")
check(ns.Display.channelButtons[1].__point == buttonAnchor,
      "a longer phrase moved the channel buttons")
local cappedWidth = ns.Display.frame.__w
ns.Display:Layout(string.rep("a very long line indeed ", 40))
check(ns.Display.frame.__w == cappedWidth, "the strip kept growing past its cap")

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
check(not targetBoard:IsShown(), "speaking left the menu open")

-- Clicking away closes everything: an X in a corner is not how a context menu
-- is dismissed.
targetBoard:Open(ns.Anchors.targetControl, ns.Contexts:Target())
targetBoard:Pick({ "PERSON", "THANK", "Thank" })
check(SilvertongueClickCatcher:IsShown(), "nothing was catching clicks outside the menu")
-- Neither the menu nor the line carries a close button: clicking away is the
-- gesture, and a fifth way to dismiss would just take room.
check(not targetBoard.closeButton, "the menu still has a close button")
check(not ns.Display.closeButton, "the line still has a close button")
SilvertongueClickCatcher:GetScript("OnMouseDown")(SilvertongueClickCatcher)
check(not targetBoard:IsShown(), "clicking away left the menu open")
check(not ns.Display:IsShown(), "clicking away left the line on screen")
check(not SilvertongueClickCatcher:IsShown(), "the catcher stayed up with nothing open")

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

-- The target's bubble fans out the same way the portrait's does: the three
-- things that act, then the phrases.
ns.Anchors.targetFanOpen = false
target = { name = "Gromkar", className = "Warrior", classToken = "WARRIOR", raceName = "Orc", raceToken = "Orc" }
group = {}
ns.Anchors:UpdateTarget()
check(ns.Anchors.targetControl:IsShown(), "the target bubble is hidden with a target selected")
for _, row in ipairs(ns.Anchors.targetFan) do
    check(not row:IsShown(), "a target fan row showed while folded away")
end

ns.Anchors:ToggleTargetFan()
local fanLabels = {}
for _, row in ipairs(ns.Anchors.targetFan) do
    if row:IsShown() then fanLabels[row.entry.key] = true end
end
for _, key in ipairs({ "SPEAK", "INVITE", "TRADE", "DUEL" }) do
    check(fanLabels[key], "a friendly player is missing the %s row", key)
end
-- Talking is what this is for, so it leads.
check(ns.Anchors.targetFan[1].entry.key == "SPEAK",
      "the fan leads with %s", ns.Anchors.targetFan[1].entry.key)
for _, row in ipairs(ns.Anchors.targetFan) do
    check(row.entry.icon ~= nil, "the %s row has no icon", row.entry.key)
end

-- The three that act fire against the right unit and say nothing.
acted = {}
local beforeActions = #sent
for _, row in ipairs(ns.Anchors.targetFan) do
    if row:IsShown() and row.entry.run then row:GetScript("OnClick")(row) end
end
check(#acted == 3, "expected three actions, got %d", #acted)
check(acted[1][2] == "Gromkar", "the invite went to %s", tostring(acted[1][2]))
check(#sent == beforeActions, "an action row spoke")

-- Someone already in the group cannot be invited into it.
group = { { name = "Gromkar", className = "Warrior", classToken = "WARRIOR", raceName = "Orc", raceToken = "Orc" } }
ns.Anchors:UpdateTarget()
local grouped = {}
for _, row in ipairs(ns.Anchors.targetFan) do
    if row:IsShown() then grouped[row.entry.key] = true end
end
check(not grouped["INVITE"], "someone already in the group was offered an invite")
check(grouped["SPEAK"], "a grouped target lost the speak row")
group = {}

-- A creature gets only the phrases.
target = { name = "Ragged Timber Wolf", hostile = true }
ns.Anchors:UpdateTarget()
local creature = {}
for _, row in ipairs(ns.Anchors.targetFan) do
    if row:IsShown() then creature[row.entry.key] = true end
end
check(not creature["TRADE"] and not creature["DUEL"] and not creature["INVITE"],
      "a hostile creature was offered something to accept")
check(creature["SPEAK"], "a creature cannot be spoken to")

-- The fan is one switch, not one per person: it stays open across targets.
target = { name = "Gromkar", className = "Warrior", classToken = "WARRIOR", raceName = "Orc", raceToken = "Orc" }
ns.Anchors:UpdateTarget()
check(ns.Anchors.targetFan[1]:IsShown(), "the fan folded itself when the target changed")

-- An open phrase menu is refilled for whoever is selected now.
local speakRow
for _, row in ipairs(ns.Anchors.targetFan) do
    if row.entry.key == "SPEAK" then speakRow = row end
end
speakRow:GetScript("OnClick")(speakRow)
check(targetBoard:IsShown(), "the speak row did not open the menu")
target = { name = "Zulko", className = "Rogue", classToken = "ROGUE", raceName = "Troll", raceToken = "Troll" }
ns.Anchors:UpdateTarget()
check(targetBoard.context.title == "Zulko",
      "the open menu still belonged to %s", tostring(targetBoard.context.title))

-- And closed outright when there is nobody to talk to.
target = nil
ns.Anchors:UpdateTarget()
check(not targetBoard:IsShown(), "the menu survived losing the target")
check(not ns.Anchors.targetControl:IsShown(), "the bubble survived losing the target")
target = { name = "Gromkar", className = "Warrior", classToken = "WARRIOR", raceName = "Orc", raceToken = "Orc" }
ns.Anchors:UpdateTarget()

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

-- Three explicit sends in this section, and nothing else may have spoken.
check(#sent == beforeSend + 3, "something spoke outside the explicit sends")

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

-- 19. Looking for a group.
group = {}
local soloContext = ns.Contexts:Group()
local soloLabels = {}
for _, entry in ipairs(soloContext.intents) do
    if entry ~= ns.SEP and entry[2] then soloLabels[entry[2]] = true end
end
check(soloLabels["SOLO"], "alone, there is no way to say you are looking")
check(not soloLabels["NEED_TANK"], "alone, it offered to recruit for a group you do not have")
check(soloContext.channels[1].key == "LFG", "the group context does not lead with the LFG channel")
local groupChannels = {}
for _, channel in ipairs(soloContext.channels) do groupChannels[channel.key] = true end
check(groupChannels["GUILD"], "a guilded character cannot ask their guild")

-- The dungeon the advert names is picked from the menu itself.
local offered = {}
for _, entry in ipairs(soloContext.intents) do
    if entry ~= ns.SEP and entry.setDungeon then offered[entry.setDungeon] = true end
end
local anyOffered = false
for _ in pairs(offered) do anyOffered = true end
check(anyOffered, "the menu offers no dungeon to name")

ns.SetDungeon("Uldaman")
check(ns.CurrentDungeon() == "Uldaman", "picking a dungeon did not stick")
ns.Engine:Request("LFG", "SOLO", ns.Contexts:Group().ctx)
check(ns.Engine:GetCurrent():find("Uldaman", 1, true),
      "the advert does not name the chosen dungeon: %s", ns.Engine:GetCurrent())
ns.SetDungeon(nil)

-- In a group, it recruits instead, and knows how many seats are open.
group = {
    { name = "Gromkar", className = "Warrior", classToken = "WARRIOR", raceName = "Orc", raceToken = "Orc" },
    { name = "Altheon", className = "Priest",  classToken = "PRIEST",  raceName = "Troll", raceToken = "Troll" },
}
local groupContext = ns.Contexts:Group()
local groupLabels = {}
for _, entry in ipairs(groupContext.intents) do
    if entry ~= ns.SEP and entry[2] then groupLabels[entry[2]] = true end
end
check(groupLabels["NEED_TANK"] and groupLabels["NEED_HEALER"], "a group cannot ask for roles")
check(not groupLabels["SOLO"], "a group was offered the line for being alone")
check(groupContext.subtitle == "3 of 5", "the group is described as %s", groupContext.subtitle)

-- With roles assigned, the recruiting line talks about roles rather than about
-- classes, because that is what anyone reading it cares about.
assignedRoles = { player = "DAMAGER", party1 = "TANK", party2 = "HEALER" }
local byRole = ns.Contexts:Group()
check(byRole.ctx.have == "a tank, a healer and 1 dps",
      "with roles assigned it says it holds %s", tostring(byRole.ctx.have))
check(byRole.ctx.missing == "2 dps",
      "with roles assigned it says it needs %s", tostring(byRole.ctx.missing))
assignedRoles = {}

-- The line names what the group actually holds.
ns.Engine:Request("LFG", "NEED_MORE", groupContext.ctx)
local recruiting = ns.Engine:GetCurrent()
check(recruiting:find("warrior") or recruiting:find("priest") or recruiting:find("2"),
      "the recruiting line says nothing about the group: %s", recruiting)
check(not recruiting:find("{"), "the recruiting line left a placeholder: %s", recruiting)

-- It goes out on the channel, and only when that channel is joined.
local beforeLFG = #sent
ns.SendPhrase("Testing the channel.", "LFG")
check(#sent == beforeLFG + 1, "the LFG line did not go out")
check(sent[#sent].channel == "CHANNEL", "it went out on %s", sent[#sent].channel)

-- Not being in the channel yet is not a refusal: asking for a group is asking
-- to be where groups are found, so it joins and then speaks.
lfgChannelId = 0
joined = {}
local beforeUnjoined = #sent
ns.SendPhrase("Let me in.", "LFG")
check(joined[1] == "LookingForGroup", "it did not join the channel")
check(#sent == beforeUnjoined + 1, "it did not speak after joining")
check(sent[#sent].channel == "CHANNEL", "after joining it went out on %s", sent[#sent].channel)

-- And it is never said aloud to whoever is standing next to you instead.
lfgChannelId = 0
JoinChannelByName = function() end      -- a join that does not take
local beforeFailed = #sent
ns.SendPhrase("Nobody is listening.", "LFG")
check(#sent == beforeFailed, "a failed join shouted the advert somewhere else")
JoinChannelByName = function(name) joined[#joined + 1] = name; lfgChannelId = 4 end
lfgChannelId = 4
group = {}

-- 20. The group browser. Reading a listing, and speaking to whoever posted it.
listings[7] = {
    leaderName = "Chudlightly",
    numMembers = 1,
    activityIDs = { 42 },
    comment = "friendly run",
    player = { level = 34, className = "Hunter", classFilename = "HUNTER" },
    counts = { TANK_REMAINING = 1, HEALER_REMAINING = 0, DAMAGER_REMAINING = 2 },
}

local read = ns.LFGBrowse:ReadResult(7)
check(read ~= nil, "a listing could not be read")
check(read.leaderName == "Chudlightly", "the leader is %s", tostring(read.leaderName))
check(read.activity == "Scarlet Monastery", "the activity is %s", tostring(read.activity))
check(read.level == 34, "the level is %s", tostring(read.level))
-- What they are missing comes from the game, not from a guess about classes.
check(read.missing:find("tank"), "it did not read what they are short of: %s", tostring(read.missing))
check(read.missing:find("2 dps"), "it did not read the open dps places: %s", tostring(read.missing))
check(not read.missing:find("healer"), "it invented a missing healer: %s", read.missing)

-- Nothing to read is not an error.
check(ns.LFGBrowse:ReadResult(999) == nil, "an absent listing returned something")
check(ns.LFGBrowse:BuildContext(999) == nil, "an absent listing built a context")

local listing = ns.LFGBrowse:BuildContext(7)
check(listing.title == "Chudlightly", "the menu is titled %s", tostring(listing.title))
check(listing.subtitle:find("Scarlet Monastery"), "the menu does not name the dungeon")
check(listing.subtitle:find("tank"), "the menu does not say what they need")
check(listing.recipient == "Chudlightly", "the whisper would go to %s", tostring(listing.recipient))
check(listing.channels[1].key == "WHISPER", "a listing does not whisper")

-- The advert names their dungeon, taken from the listing rather than typed.
ns.Engine:Request("LFG", "OFFER", listing.ctx)
local offer = ns.Engine:GetCurrent()
check(offer:find("Scarlet Monastery", 1, true), "the offer does not name their dungeon: %s", offer)
check(not offer:find("{"), "the offer left a placeholder: %s", offer)

-- A whisper from a listing does not depend on what you have targeted.
target = nil
local beforeWhisper = #sent
ns.SendPhrase(offer, "WHISPER", listing.recipient)
check(#sent == beforeWhisper + 1, "the whisper never went out")
check(sent[#sent].to == "Chudlightly", "it whispered %s", tostring(sent[#sent].to))

-- The offers match what the listing is short of, and what you could fill.
-- Listing 7 needs a tank and 2 dps; the character here is a shaman, who can
-- heal and fight but not tank.
local listingLabels = {}
for _, entry in ipairs(listing.intents) do
    if entry[2] then listingLabels[entry[2]] = true end
end
check(listingLabels["OFFER"], "there is no way to simply offer to join")
check(listingLabels["OFFER_DPS"], "a shaman was not offered the open damage place")
check(not listingLabels["OFFER_TANK"], "a shaman was offered to tank")
check(not listingLabels["OFFER_HEALER"], "it offered a healer place that is not open")
check(not listingLabels["ASK"], "it still offers to ask what they already published")

-- Blizzard's own rule: only a lone player can be invited.
acted = {}
check(listing.actions ~= nil, "a lone player could not be invited")
listing.actions[1].run("Chudlightly")
check(acted[1] and acted[1][2] == "Chudlightly", "the invite went nowhere")

listings[8] = {
    leaderName = "Qvictor", numMembers = 3, activityIDs = { 42 },
    player = { level = 38, className = "Mage", classFilename = "MAGE" },
    counts = { TANK_REMAINING = 0, HEALER_REMAINING = 1, DAMAGER_REMAINING = 0 },
}
check(ns.LFGBrowse:BuildContext(8).actions == nil,
      "a group of three was offered an invite, which the game refuses")

-- Your own listing recruits, and recruits from what the game says it holds:
-- two dps in, still short a tank and a healer.
listings[9] = {
    leaderName = "Bellaco", numMembers = 2, hasSelf = true, activityIDs = { 42 },
    player = { level = 36, className = "Rogue", classFilename = "ROGUE" },
    counts = { TANK = 0, HEALER = 0, DAMAGER = 2,
               TANK_REMAINING = 1, HEALER_REMAINING = 1, DAMAGER_REMAINING = 1 },
}
local own = ns.LFGBrowse:BuildContext(9)
check(own ~= nil, "your own listing could not be read")
local ownLabels = {}
for _, entry in ipairs(own.intents) do
    if entry ~= ns.SEP and entry[2] then ownLabels[entry[2]] = true end
end
check(not ownLabels["OFFER"], "your own listing offered to join itself")
check(not ownLabels["OFFER_TANK"], "your own listing offered itself a tank")
check(ownLabels["NEED_MORE"], "your own listing cannot say it is recruiting")
check(not ownLabels["FULL"], "the closing line is still offered as a row")
check(own.actions == nil, "your own listing offered to invite you")
check(own.ctx.dungeon == "Scarlet Monastery", "your own listing lost its dungeon")

-- It says what it holds and what it is short of, both from the game.
check(own.ctx.have == "2 dps", "the listing says it holds %s", tostring(own.ctx.have))
check(own.ctx.missing == "a tank, a healer and 1 dps",
      "the listing says it needs %s", tostring(own.ctx.missing))
ns.Engine:Request("LFG", "NEED_MORE", own.ctx)
local advert = ns.Engine:GetCurrent()
check(advert:find("2 dps", 1, true), "the advert does not say what it holds: %s", advert)
check(advert:find("tank", 1, true), "the advert does not say what it needs: %s", advert)
check(advert:find("^LFM "), "the advert does not read as looking for more: %s", advert)

-- And it never asks for a role it already filled.
listings[10] = {
    leaderName = "Bellaco", numMembers = 3, hasSelf = true, activityIDs = { 42 },
    player = { level = 36, className = "Rogue", classFilename = "ROGUE" },
    counts = { TANK = 0, HEALER = 1, DAMAGER = 2,
               TANK_REMAINING = 1, HEALER_REMAINING = 0, DAMAGER_REMAINING = 1 },
}
local withHealer = ns.LFGBrowse:BuildContext(10)
local healerLabels = {}
for _, entry in ipairs(withHealer.intents) do
    if entry ~= ns.SEP and entry[2] then healerLabels[entry[2]] = true end
end
check(healerLabels["NEED_TANK"], "a listing short a tank cannot ask for one")
check(not healerLabels["NEED_HEALER"], "it asked for a healer it already has")
check(withHealer.ctx.have == "a healer and 2 dps",
      "it holds %s", tostring(withHealer.ctx.have))

-- The menu rereads when a line is picked, so changing the dungeon filter with
-- it open names the new one rather than the one it opened on.
check(type(own.rebuild) == "function", "your own listing never rereads itself")
check(type(listing.rebuild) == "function", "someone else's listing never rereads itself")
check(own.rebuild() ~= nil, "rereading your own listing returned nothing")
listings[9] = nil
check(own.rebuild() == nil, "a listing that went away still reread as present")

-- A control with no frame to hang off must still land somewhere on screen.
-- Built without an anchor it is simply invisible, which is what happened when
-- the party frames were not named what the code expected.
for i = 1, 4 do
    local control = _G["SilvertongueAnchorPARTY" .. i]
    check(control ~= nil, "party control %d was never built", i)
    check(control.__point ~= nil, "party control %d was built with no anchor", i)
end
check(_G.SilvertongueAnchorPARTY_ALL ~= nil, "the group control was never built")
check(_G.SilvertongueAnchorPARTY_ALL.__point ~= nil, "the group control has no anchor")

-- Advertising for a group lives in the group window, not on your portrait.
for _, control in ipairs(ns.Anchors.fanControls) do
    check(control.entry == nil or control.entry.key ~= "GROUP",
          "the portrait still carries the group row")
end

-- A row that cannot be read says so rather than doing nothing.
ns.LFGBrowse:Explain(nil)
ns.LFGBrowse:Explain(999)

-- Hooking a client that has no such browser must do nothing rather than error.
local realScrollUtil = ScrollUtil
ScrollUtil = nil
ns.LFGBrowse.hooked = false
ns.LFGBrowse:Watch()
check(not ns.LFGBrowse.hooked, "it claimed to hook a browser that is not there")
ScrollUtil = realScrollUtil


-- ---------------------------------------------------------------------------
-- The whisper window: a person who is not a frame.
-- ---------------------------------------------------------------------------

local sentBefore = #sent

local function whisperEvent(event, ...)
    addon.__events[event](event, ...)
end

-- A whisper arrives. The line keeps its text and gains our mark, and nothing
-- opens on its own: a window appearing because somebody typed at you takes a
-- corner of the screen without being asked.
local line = deliver("CHAT_MSG_WHISPER", "can you make me a portal?", "Grumgar")
check(line ~= nil, "the filter swallowed a whisper out of the chat frame")
check(line:find("can you make me a portal?", 1, true) ~= nil,
      "the whisper lost its text: %s", tostring(line))
check(line:find("|Hsilvertongue:Grumgar|h", 1, true) ~= nil,
      "the whisper carried no clickable mark: %s", tostring(line))
check(not ns.Whisper:IsOpen("Grumgar"), "a whisper opened a window by itself")

-- Your own guild line does not need a button to answer yourself.
local mine = deliver("CHAT_MSG_GUILD", "anyone for SM?", "Silvertongue")
check(mine:find("silvertongue:", 1, true) == nil, "our own guild line got a mark")

local theirs = deliver("CHAT_MSG_GUILD", "anyone for SM?", "Kelda")
check(theirs:find("|Hsilvertongue:Kelda|h", 1, true) ~= nil, "a guild line got no mark")

-- Switching whispers off leaves the line exactly as it came.
addon.db.profile.chatIcons.whisper = false
local plain = deliver("CHAT_MSG_WHISPER", "hello?", "Grumgar")
check(plain == "hello?", "a switched-off mark still changed the line: %s", tostring(plain))
addon.db.profile.chatIcons.whisper = true

-- A system line has no author at all: the name lives inside the sentence, as
-- the player link that already makes it clickable. This is the invite exactly
-- as the client writes it.
local invite = "|Hplayer:Baddiebolts|h[Baddiebolts]|h has invited you to join a group."
local marked = deliver("CHAT_MSG_SYSTEM", invite, nil)
check(marked:find("|Hsilvertongue:Baddiebolts|h", 1, true) ~= nil,
      "the invite line got no mark: %s", tostring(marked))
check(marked:find("|Hplayer:Baddiebolts|h[Baddiebolts]|h", 1, true) ~= nil,
      "marking the invite broke the game's own link: %s", tostring(marked))
check(marked:find("has invited you to join a group.", 1, true) ~= nil,
      "the invite line lost its text: %s", tostring(marked))
-- After the name, so the sentence still starts with its first word.
check(marked:find("|h |Hsilvertongue", 1, true) ~= nil,
      "the mark did not land beside the name: %s", tostring(marked))

-- The longer link form, which carries the line id and chat type after the name.
local long = deliver("CHAT_MSG_SYSTEM",
    "|Hplayer:Kelda:12:WHISPER|h[Kelda]|h has come online.", nil)
check(long:find("|Hsilvertongue:Kelda|h", 1, true) ~= nil,
      "the longer link form was not recognised: %s", tostring(long))

-- Your own name in a system line needs no button, and a line naming the same
-- person twice gets one mark, not two.
local mineSystem = deliver("CHAT_MSG_SYSTEM",
    "|Hplayer:Silvertongue|h[Silvertongue]|h has joined the party.", nil)
check(mineSystem:find("silvertongue:Silvertongue", 1, true) == nil,
      "we marked ourselves: %s", tostring(mineSystem))
local twice = deliver("CHAT_MSG_SYSTEM",
    "|Hplayer:Kelda|h[Kelda]|h and |Hplayer:Kelda|h[Kelda]|h.", nil)
local count = select(2, twice:gsub("|Hsilvertongue:", ""))
check(count == 1, "one name got %d marks", count)

-- A system line that names nobody is left exactly as it came.
local plainSystem = deliver("CHAT_MSG_SYSTEM", "Your group has been disbanded.", nil)
check(plainSystem == "Your group has been disbanded.",
      "a line with no name was rewritten: %s", tostring(plainSystem))

-- And the mark on the invite opens the same window as everything else.
clickLink("silvertongue:Baddiebolts")
check(ns.Whisper:IsOpen("Baddiebolts"), "the invite mark opened no window")
ns.Whisper:Close("Baddiebolts")
-- Clicking the mark is what opens the window.
clickLink("silvertongue:Grumgar")
check(ns.Whisper:IsOpen("Grumgar"), "clicking the mark opened no window")
local window = ns.Whisper:Windows()["Grumgar"]
check(window.__point ~= nil, "the window was built with no anchor")
check(window.title:GetText() == "Grumgar", "the window is not titled with their name")

-- What we know about him came from the message he sent: a chat message carries
-- the sender's GUID, and that is race and class for nothing.
guids["Player-1-GRUM"] = { className = "Shaman", classToken = "SHAMAN",
                           raceName = "Orc", raceToken = "Orc", name = "Grumgar" }
whisperEvent("CHAT_MSG_WHISPER", "you there?", "Grumgar",
    nil, nil, nil, nil, nil, nil, nil, nil, nil, "Player-1-GRUM")
ns.Whisper:RefreshHeader(window)
check(window.subtitle:GetText() == "Orc Shaman",
      "what his message told us did not reach the header: %s", tostring(window.subtitle:GetText()))

-- Nothing is asked of the server at all. Reading a who answer meant switching
-- results over to the interface, and the interface for who results is the Social
-- window opening over the game.
check(#whoSent == 0, "a window opened a /who: %d sent", #whoSent)
-- The flag is the actual bug, not the query: it means "put who results in the
-- interface", and the interface for who results is the Social window opening
-- over the game. Nothing in the addon may switch it on.
check(whoToUi == false, "something turned on who-to-interface")

-- Nobody we have ever heard of says so, rather than showing a blank line.
ns.Whisper:Open("Nobody")
local nobody = ns.Whisper:Windows()["Nobody"]
check(nobody.subtitle:GetText() == "Unknown",
      "a stranger showed: %s", tostring(nobody.subtitle:GetText()))
ns.Whisper:Close("Nobody")

-- What we learn is kept. Closing the window and opening it months later must
-- not throw away that Rhottyn is a troll -- and must not claim the level is
-- current either.
ns.Whisper:Close("Grumgar")
local stored = addon.db.profile.people["Grumgar"]
check(stored ~= nil and stored.raceName == "Orc" and stored.className == "Shaman",
      "what Grumgar's message told us was not kept")

-- Somebody met before this session, never seen since: remembered, and dated.
addon.db.profile.people["Rhottyn"] = {
    className = "Shaman", raceName = "Troll", level = 44, seen = now - 86400 * 3,
}
ns.Whisper:Open("Rhottyn")
local rhottyn = ns.Whisper:Windows()["Rhottyn"]
check(rhottyn.subtitle:GetText() == "Troll Shaman, 44 - seen 3 days ago",
      "a remembered person showed: %s", tostring(rhottyn.subtitle:GetText()))
ns.Whisper:Close("Rhottyn")

-- Seeing them for real replaces the memory and drops the date: this is no
-- longer something we recall, it is something we can see.
target = { name = "Rhottyn", className = "Shaman", classToken = "SHAMAN",
           raceName = "Troll", raceToken = "TROLL" }
ns.Whisper:Open("Rhottyn")
check(rhottyn.subtitle:GetText() == "Troll Shaman, 36",
      "seeing them in person still read as a memory: %s", tostring(rhottyn.subtitle:GetText()))
target = nil
ns.Whisper:Close("Rhottyn")

-- The store is bounded, and it is the oldest that goes.
for i = 1, 340 do
    ns.RememberPlayer("Filler" .. i, { className = "Rogue", level = i })
    addon.db.profile.people["Filler" .. i].seen = now - (400 - i) * 86400
end
local kept = 0
for _ in pairs(addon.db.profile.people) do kept = kept + 1 end
check(kept <= 300, "the store grew to %d people", kept)
check(addon.db.profile.people["Filler1"] == nil, "the oldest entry was kept")
check(addon.db.profile.people["Filler340"] ~= nil, "the newest entry was dropped")

-- Put Grumgar's window back: the checks further down are about it.
ns.Whisper:Open("Grumgar")

-- Somebody on another realm. The who service is realm-local, so the lookup can
-- never answer for them -- but their message carries a GUID, and that is enough
-- for race and class.
guids["Player-4-ABC"] = { className = "Priest", classToken = "PRIEST",
                          raceName = "Human", raceToken = "Human",
                          name = "Arthuruno", realm = "Dreamscythe" }
guild[1] = { name = "Arthuruno-Dreamscythe", level = 70, className = "Priest" }
whisperEvent("CHAT_MSG_WHISPER", "test", "Arthuruno-Dreamscythe",
    nil, nil, nil, nil, nil, nil, nil, nil, nil, "Player-4-ABC")
ns.Whisper:Open("Arthuruno-Dreamscythe")
local cross = ns.Whisper:Windows()["Arthuruno-Dreamscythe"]
-- The race comes from the message, the level from the roster, and neither on
-- its own would have made that line.
check(cross.subtitle:GetText() == "Human Priest, 70",
      "a cross-realm guildmate showed: %s", tostring(cross.subtitle:GetText()))
ns.Whisper:Close("Arthuruno-Dreamscythe")
guild[1] = nil

-- A guildmate is known without asking anyone: level and class, and no race,
-- because the roster does not carry one.
guild[1] = { name = "Kelda", level = 38, className = "Priest" }
ns.Whisper:Open("Kelda")
local kelda = ns.Whisper:Windows()["Kelda"]
check(kelda.subtitle:GetText() == "Priest, 38",
      "a guildmate was described as: %s", tostring(kelda.subtitle:GetText()))

-- Two windows at once, which is the whole reason they are per person.
check(ns.Whisper:IsOpen("Grumgar") and ns.Whisper:IsOpen("Kelda"),
      "two conversations could not be open at the same time")

-- ---------------------------------------------------------------------------
-- The conversation, which outlives the window and the session.
-- ---------------------------------------------------------------------------

-- Recorded from the events rather than the chat filters, so a line counts as
-- said whether or not it reached a chat frame you happen to be watching.
whisperEvent("CHAT_MSG_WHISPER", "still there?", "Grumgar")
local transcript = table.concat(window.log.__lines or {}, "\n")
check(transcript:find("still there?", 1, true) ~= nil,
      "an open window ignored the next whisper: %s", transcript)
check(transcript:find("Grumgar", 1, true) ~= nil,
      "the line does not say who said it: %s", transcript)

-- Both sides of it, and told apart.
whisperEvent("CHAT_MSG_WHISPER_INFORM", "on my way", "Grumgar")
transcript = table.concat(window.log.__lines or {}, "\n")
check(transcript:find("on my way", 1, true) ~= nil, "our own reply was not recorded")
check(transcript:find("Silvertongue:", 1, true) ~= nil,
      "our own reply is not marked as ours: %s", transcript)

-- A whisper with no window open is still written down: the conversation is the
-- record, not the window.
whisperEvent("CHAT_MSG_WHISPER", "you around?", "Faranell")
check(not ns.Whisper:IsOpen("Faranell"), "a whisper opened a window by itself")
check(#ns.Log:Lines("Faranell") == 1, "a whisper with no window open was lost")
-- And it is there when you finally open one.
ns.Whisper:Open("Faranell")
local late = ns.Whisper:Windows()["Faranell"]
check(table.concat(late.log.__lines or {}, "\n"):find("you around?", 1, true) ~= nil,
      "opening a window later did not show what was already said")
ns.Whisper:Close("Faranell")

-- Folding it away turns the window back into the strip it was, and the choice
-- is remembered for the next one.
ns.Whisper:ToggleLog(window)
check(window.collapsed == true, "the conversation did not fold away")
check(not window.log:IsShown(), "the conversation is folded but still showing")
check(addon.db.profile.whisperCollapsed == true, "the fold was not remembered")
ns.Whisper:ToggleLog(window)
check(window.log:IsShown(), "the conversation did not come back")

-- The bound. Not privacy -- the file is read and written whole at login and
-- logout, so a store that only grows costs time at both ends forever.
for i = 1, ns.Log.MAX_PER_PERSON + 60 do
    ns.Log:Record("Talker", "line " .. i, true)
end
local talked = ns.Log:Lines("Talker")
check(#talked == ns.Log.MAX_PER_PERSON, "one conversation grew to %d lines", #talked)
check(talked[#talked].m == "line " .. (ns.Log.MAX_PER_PERSON + 60),
      "the newest line was the one dropped")
check(talked[1].m ~= "line 1", "the oldest line was kept")

-- Months are kept. Years are not.
ns.Log:Record("Ancient", "hello from long ago", true)
addon.db.profile.log["Ancient"][1].t = now - 86400 * 400
ns.Log:Record("Recent", "last month", true)
addon.db.profile.log["Recent"][1].t = now - 86400 * 60
ns.Log:Prune()
check(addon.db.profile.log["Ancient"] == nil, "a conversation from over a year ago was kept")
check(addon.db.profile.log["Recent"] ~= nil, "a conversation from two months ago was dropped")
ns.Log:Clear("Talker")

-- A Battle.net friend coming online. The name there is a link too, but a
-- different type: it carries an account id, because there may be no character
-- to whisper -- they can be on the other faction, another realm, or in another
-- game entirely.
bnAccounts["42"] = { gameAccountInfo = { isOnline = true, characterName = "Olfer",
    realmName = "Nethergarde", raceName = "Troll", className = "Shaman",
    characterLevel = 44 } }
-- Not through a filter, because that line does not exist yet when the filters
-- run: the event carries the token FRIEND_ONLINE and the account id, and the
-- chat frame writes the sentence afterwards. So it is the frame's own
-- AddMessage that has to be watched, and this is the line as it finally lands.
ChatFrame1:AddMessage("|HBNplayer:Diego:42:0:0:|h[Diego] (Olfer)|h has come online.")
local toast = ChatFrame1.__written[#ChatFrame1.__written]
check(toast:find("|Hsilvertongue:bn:42:Diego|h", 1, true) ~= nil,
      "the friend-online line got no mark: %s", tostring(toast))
check(toast:find("has come online.", 1, true) ~= nil,
      "marking it broke the line: %s", tostring(toast))

-- And an ordinary chat line is left alone, even though by this point its sender
-- is a link too. Marking those would put a bubble on every line of general chat.
ChatFrame1:AddMessage("|Hplayer:Meowmix|h[Meowmix]|h: oh spam, the ultimate")
local ordinary = ChatFrame1.__written[#ChatFrame1.__written]
check(ordinary:find("silvertongue", 1, true) == nil,
      "a general chat line got marked: %s", tostring(ordinary))

clickLink("silvertongue:bn:42:Diego")
check(ns.Whisper:IsOpen("Diego", "42"), "clicking a Battle.net mark opened no window")
local bnWindow = ns.Whisper:Windows()["bn:42"]
check(bnWindow.title:GetText() == "Diego", "the window is not titled with their name")
-- No /who: the client already holds their character, race, class and level.
check(bnWindow.subtitle:GetText() == "Olfer - Troll Shaman, 44",
      "a Battle.net friend showed: %s", tostring(bnWindow.subtitle:GetText()))

-- And it goes out through the Battle.net route, not as a normal whisper, which
-- would simply fail for a friend on the other faction.
local bnContext = ns.Contexts:Whisper("Diego", "42")
check(#bnContext.channels == 1 and bnContext.channels[1].key == "BN_WHISPER",
      "a Battle.net conversation offered the wrong channel")
local bnBoard = ns.Board:New("WHISPER:bn:42")
bnBoard:Open(bnWindow.speak, bnContext)
bnBoard:Pick({ "WHISPER", "HELLO", "Greet" }, nil)
local chatBefore = #sent
ns.Display:Send("BN_WHISPER")
check(#bnSent == 1, "the Battle.net line did not go out: %d sent", #bnSent)
check(bnSent[1].id == 42, "it was addressed to %s", tostring(bnSent[1].id))
check(#sent == chatBefore, "a Battle.net line also went out as normal chat")
ns.Whisper:Close("Diego", "42")

-- Speaking: every intent must produce a line, and none of it may reach chat.
local whisperContext = ns.Contexts:Whisper("Grumgar")
check(whisperContext ~= nil, "no context for a whisper")
check(#whisperContext.intents > 0, "the whisper menu came out empty")
local board = ns.Board:New("WHISPER:Grumgar")
board:Open(window.speak, whisperContext)
for _, entry in ipairs(whisperContext.intents) do
    if entry ~= ns.SEP then
        board:Pick(entry, nil)
        check(ns.Display.edit:GetText() ~= "", "WHISPER.%s produced nothing", entry[2])
        check(ns.Display.edit:GetText():find("{") == nil,
              "WHISPER.%s left a placeholder unfilled: %s", entry[2], ns.Display.edit:GetText())
    end
end
check(#sent == sentBefore, "%d messages escaped while building whisper phrases",
      #sent - sentBefore)

-- The channels: whisper always, guild only for a guildmate, and never say or
-- yell -- the whole point is that they are somewhere else.
local function channelKeys(context)
    local keys = {}
    for _, channel in ipairs(context.channels) do keys[#keys + 1] = channel.key end
    return table.concat(keys, ",")
end
check(channelKeys(whisperContext) == "WHISPER",
      "a stranger offered: %s", channelKeys(whisperContext))
check(channelKeys(ns.Contexts:Whisper("Kelda")) == "WHISPER,GUILD",
      "a guildmate offered: %s", channelKeys(ns.Contexts:Whisper("Kelda")))

-- No gesture. A bow aimed at someone who is not on your screen plays to an
-- empty room, and DoEmote would name a unit the client cannot see.
local emotesBefore = #emoted
board:Pick({ "WHISPER", "THANK", "Thank" }, nil)
check(not ns.Display.emoteCheck:IsShown(), "a whisper offered a gesture")
ns.Display:Send("WHISPER")
check(#emoted == emotesBefore, "a whisper fired an emote at nobody")
check(#sent == sentBefore + 1, "pressing whisper did not send exactly one line")
check(sent[#sent].channel == "WHISPER" and sent[#sent].to == "Grumgar",
      "the line went to %s on %s", tostring(sent[#sent].to), tostring(sent[#sent].channel))

-- The target's door into the same window, for someone who has not spoken yet.
target = { name = "Vaelen", className = "Paladin", classToken = "PALADIN",
           raceName = "Blood Elf", raceToken = "BLOODELF" }
ns.TargetUI:Refresh()
local targetContext = ns.Contexts:Target()
local opener
for _, action in ipairs(targetContext.actions or {}) do
    if action.label == "Open a window" then opener = action end
end
check(opener ~= nil, "the target has no way to open a conversation")
check(opener.local_ == true, "opening our own window claims to act on them")
opener.run()
check(ns.Whisper:IsOpen("Vaelen"), "the target's opener opened nothing")

-- A hostile target has nobody to whisper, so the door is not there.
target = { name = "Snarl", hostile = true }
ns.TargetUI:Refresh()
local hostile = ns.Contexts:Target()
check(hostile.actions == nil, "a hostile target offered a private conversation")
target = nil
ns.TargetUI:Refresh()

-- Typing in it. This is a whisper window, so the line has to be able to come
-- from you and not only from the addon's own phrases.
local typedBefore = #sent
window.input:SetText("see you there")
window.input:GetScript("OnEnterPressed")(window.input)
check(#sent == typedBefore + 1, "typing a line and pressing enter sent %d", #sent - typedBefore)
check(sent[#sent].text == "see you there" and sent[#sent].to == "Grumgar",
      "it sent %s to %s", tostring(sent[#sent].text), tostring(sent[#sent].to))
check(window.input:GetText() == "", "the box kept the line after sending it")

-- Nothing goes out from an empty box, or from one you escaped out of.
local quiet = #sent
window.input:SetText("   ")
window.input:GetScript("OnEnterPressed")(window.input)
window.input:SetText("never mind")
window.input:GetScript("OnEscapePressed")(window.input)
check(#sent == quiet, "%d lines escaped from a box nobody sent", #sent - quiet)
check(window.input:GetText() == "", "escape left the line in the box")

-- A Battle.net window types down the Battle.net route, not as a normal whisper.
ns.Whisper:Open("Diego", nil, "42")
local bnAgain = ns.Whisper:Windows()["bn:42"]
local bnBefore, chatBefore2 = #bnSent, #sent
bnAgain.input:SetText("hey")
bnAgain.input:GetScript("OnEnterPressed")(bnAgain.input)
check(#bnSent == bnBefore + 1, "typing to a Battle.net friend sent nothing")
check(#sent == chatBefore2, "typing to a Battle.net friend also went out as normal chat")
ns.Whisper:Close("Diego", "42")

-- What we send is not written down here: the game raises the event that records
-- it, exactly as it does when you type in its own chat. Recording it again
-- would show every line twice.
local linesBefore = #ns.Log:Lines("Grumgar")
window.input:SetText("twice?")
window.input:GetScript("OnEnterPressed")(window.input)
check(#ns.Log:Lines("Grumgar") == linesBefore,
      "sending wrote the line to the transcript before the event did")
whisperEvent("CHAT_MSG_WHISPER_INFORM", "twice?", "Grumgar")
check(#ns.Log:Lines("Grumgar") == linesBefore + 1, "the sent line was never recorded")

-- Closing is the one X in the addon, and it takes its menu with it.
ns.Whisper:Close("Grumgar")
check(not ns.Whisper:IsOpen("Grumgar"), "the window did not close")
check(not board:IsShown(), "closing the window left its menu on screen")

print(errors == 0 and "UI SMOKE: ALL CHECKS PASSED" or ("UI SMOKE: " .. errors .. " FAILURES"))
print(string.format("messages sent during the whole run: %d (all via explicit Send calls)", #sent))
os.exit(errors == 0 and 0 or 1)
