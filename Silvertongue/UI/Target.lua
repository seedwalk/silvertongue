-- Target.lua (UI) -- speak to whoever you have selected in the world.
-- Reads "target" live and stores nothing.

local ADDON, ns = ...

local TargetUI = {}
ns.TargetUI = TargetUI

-- Friendly targets borrow the PERSON pools; only the greetings and the social
-- asks are their own, because the GENERAL ones name nobody.
--
-- The fourth field marks an intent that only makes sense aimed at a real player:
-- a quest giver is not going to accept your group invite.
ns.TARGET_FRIENDLY = {
    { "TARGET", "HELLO",       "Hello"     },
    { "TARGET", "GOODBYE",     "Goodbye"   },
    ns.SEP,
    { "PERSON", "THANK",       "Thank"     },
    { "PERSON", "PRAISE",      "Praise"    },
    { "PERSON", "RESPECT",     "Respect"   },
    { "PERSON", "ENCOURAGE",   "Encourage" },
    { "PERSON", "JOKE",        "Joke"      },
    ns.SEP,
    { "PERSON", "WARN",        "Warn"      },
    { "PERSON", "APOLOGIZE",   "Apologize" },
    ns.SEP,
    { "TARGET", "PARTY",       "Party?",    true },
    { "TARGET", "TRADE",       "Trade",     true },
    { "TARGET", "DUEL",        "Duel",      true },
    { "TARGET", "HELP_OFFER",  "Help?",     true },
    { "TARGET", "HELP_NEED",   "Need Help", true },
    { "TARGET", "OFFER",       "Offer",     true },
}

ns.TARGET_WARLOCK_EXTRA = {
    { "PERSON", "DISTRUST",  "Distrust"  },
    { "PERSON", "DEMON",     "Demon"     },
    { "PERSON", "FEL_MAGIC", "Fel Magic" },
}

ns.TARGET_HOSTILE = {
    { "ENEMY", "ENEMY_CHALLENGE", "Challenge" },
    { "ENEMY", "ENEMY_TAUNT",     "Taunt"     },
    { "ENEMY", "ENEMY_MOCK",      "Mock"      },
    { "ENEMY", "ENEMY_RESPECT",   "Respect"   },
    { "ENEMY", "ENEMY_VICTORY",   "Victory"   },
    { "ENEMY", "ENEMY_WARNING",   "Warning"   },
}

local function ensureHeaders(content)
    if TargetUI.headers then return end

    local name = content:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    name:SetPoint("TOPLEFT", 8, -8)

    local info = content:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    info:SetPoint("TOPLEFT", name, "BOTTOMLEFT", 0, -2)

    local empty = content:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    empty:SetPoint("TOPLEFT", 10, -10)

    TargetUI.headers = { name = name, info = info, empty = empty }
end

local function hideAll()
    if not TargetUI.headers then return end
    TargetUI.headers.name:Hide()
    TargetUI.headers.info:Hide()
    TargetUI.headers.empty:Hide()
end

-- Nothing to talk to: say why, and offer no buttons.
local function showEmpty(message)
    hideAll()
    if TargetUI.actionButtons then
        TargetUI.actionLabel:Hide()
        for _, b in ipairs(TargetUI.actionButtons) do b:Hide() end
    end
    TargetUI.headers.empty:SetText(message)
    TargetUI.headers.empty:Show()
    ns.ReleaseButtonsFrom(1)
end

-- Everything the panel needs to know about the current selection: who they are,
-- whether they are hostile, and which intents apply. Returns nil and a reason
-- when there is nothing to say to.
function TargetUI:BuildContext()
    if not UnitExists("target") then
        return nil, "No target. Select someone and Silvertongue will find the words."
    end
    if UnitIsUnit("target", "player") then
        return nil, "That is you. Talking to yourself is a shaman's privilege, not a button."
    end

    local ctx = ns.Engine:BuildUnitContext("target")
    local isPlayer = UnitIsPlayer("target") and true or false

    -- Two separate questions, and treating them as one is what offered a
    -- draenei a group invite. UnitCanAttack is about whether a fight is
    -- possible right now; an Alliance player in a neutral zone without a PvP
    -- flag answers no to that and is still not somebody you invite, trade with
    -- or whisper.
    local opposed = ns.IsOppositeFaction("target")
    local hostile = (UnitCanAttack("player", "target") and true or false) or opposed

    local descriptor = ((ctx.raceName or "") .. " " .. (ctx.className or "")):gsub("^%s+", ""):gsub("%s+$", "")
    if descriptor == "" then descriptor = isPlayer and "Player" or "Creature" end


    local list = {}
    if hostile then
        for _, entry in ipairs(ns.ResolveMenu("TARGET_HOSTILE", ns.TARGET_HOSTILE)) do
            list[#list + 1] = entry
        end
    else
        for _, entry in ipairs(ns.ResolveMenu("TARGET_FRIENDLY", ns.TARGET_FRIENDLY)) do
            -- A quest giver is not going to accept your group invite.
            if entry == ns.SEP or isPlayer or not entry[4] then
                list[#list + 1] = entry
            end
        end
        if ctx.classToken == "WARLOCK" then
            for _, entry in ipairs(ns.TARGET_WARLOCK_EXTRA) do list[#list + 1] = entry end
        end
    end

    -- Worth saying on screen, because it changes what is worth saying at all.
    -- "Hostile" would be wrong for somebody peacefully mining in Nagrand; what
    -- matters about them is that your words land on everyone except them.
    local note = descriptor
    if opposed then
        note = descriptor .. "  --  will not understand you"
    elseif hostile then
        note = descriptor .. "  --  hostile"
    end

    return {
        ctx        = ctx,
        hostile    = hostile,
        opposed    = opposed,
        isPlayer   = isPlayer,
        name       = ctx.name,
        descriptor = note,
        intents    = list,
    }
end

function TargetUI:Show()
    local content = ns.Window.frame.content
    ensureHeaders(content)

    local info, why = self:BuildContext()
    if not info then
        self.hostile = nil
        showEmpty(why)
        return
    end

    local ctx, hostile = info.ctx, info.hostile
    self.hostile = hostile

    hideAll()
    self.headers.name:SetText(ctx.name)
    local color = ctx.classToken and RAID_CLASS_COLORS[ctx.classToken]
    if color then
        self.headers.name:SetTextColor(color.r, color.g, color.b)
    elseif hostile then
        self.headers.name:SetTextColor(0.85, 0.35, 0.25)
    else
        self.headers.name:SetTextColor(1, 0.82, 0)
    end
    self.headers.name:Show()

    self.headers.info:SetText(info.descriptor)
    self.headers.info:Show()

    local isPlayer, list = info.isPlayer, info.intents

    local entries = {}
    for _, entry in ipairs(list) do
      if entry ~= ns.SEP then
        local category, intent, label = entry[1], entry[2], entry[3]
        entries[#entries + 1] = {
            label = label,
            -- Rebuilt at click time so the phrase always names whoever is
            -- selected now, not whoever was selected when this was drawn.
            onClick = function()
                local live = ns.Engine:BuildUnitContext("target")
                if not live then
                    TargetUI:Show()
                    return
                end
                ns.Preview:SetRecipient(live.name)
                ns.Preview:RequestOrReroll(category, intent, live)
            end,
        }
      end
    end

    local nextIndex, bottom = ns.LayoutGrid(content, entries, 1, 50)
    ns.ReleaseButtonsFrom(nextIndex)

    self:ShowActions(content, bottom, (not hostile) and isPlayer)
end

-- The one place the addon does something besides talk. All three are requests
-- the other player still has to accept, so nothing happens behind their back.
ns.TARGET_ACTIONS = {
    {
        label = "Invite",
        tip = "Invite them to your group.",
        run = function(name)
            if C_PartyInfo and C_PartyInfo.InviteUnit then
                C_PartyInfo.InviteUnit(name)
            elseif InviteUnit then
                InviteUnit(name)
            end
        end,
    },
    {
        label = "Trade",
        tip = "Open a trade window with them.",
        run = function() if InitiateTrade then InitiateTrade("target") end end,
    },
    {
        label = "Duel",
        tip = "Challenge them to a friendly duel.",
        run = function() if StartDuel then StartDuel("target") end end,
    },
}

function TargetUI:ShowActions(content, top, enabled)
    if not self.actionButtons then
        self.actionLabel = content:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        self.actionLabel:SetTextColor(0.85, 0.35, 0.25)

        self.actionButtons = {}
        for i, action in ipairs(ns.TARGET_ACTIONS) do
            local b = CreateFrame("Button", nil, content, "UIPanelButtonTemplate")
            b:SetSize(100, 22)
            b:GetFontString():SetFontObject("GameFontHighlightSmall")
            b:SetText(action.label)
            b:SetScript("OnClick", function()
                if not UnitExists("target") then return end
                local name = UnitName("target")
                -- Guarded: a missing or protected API must not break the panel.
                pcall(action.run, name)
            end)
            b:SetScript("OnEnter", function(self)
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                GameTooltip:SetText(action.label)
                GameTooltip:AddLine(action.tip, 1, 1, 1, true)
                GameTooltip:AddLine("Acts immediately -- they still have to accept.", 0.7, 0.7, 0.7, true)
                GameTooltip:Show()
            end)
            b:SetScript("OnLeave", function() GameTooltip:Hide() end)
            self.actionButtons[i] = b
        end
    end

    if not enabled then
        self.actionLabel:Hide()
        for _, b in ipairs(self.actionButtons) do b:Hide() end
        return
    end

    self.actionLabel:ClearAllPoints()
    self.actionLabel:SetPoint("TOPLEFT", 8, -(top + 4))
    self.actionLabel:SetText("ACTIONS")
    self.actionLabel:Show()

    for i, b in ipairs(self.actionButtons) do
        b:ClearAllPoints()
        b:SetPoint("TOPLEFT", 8 + (i - 1) * 104, -(top + 18))
        b:Show()
    end
end

function TargetUI:Hide()
    hideAll()
    if self.actionButtons then
        self.actionLabel:Hide()
        for _, b in ipairs(self.actionButtons) do b:Hide() end
    end
end

function TargetUI:ClearRecipient()
    if ns.Preview then ns.Preview:SetRecipient(nil) end
end

-- Called on PLAYER_TARGET_CHANGED. Redraws the buttons but deliberately leaves
-- the preview alone: a phrase you have not sent yet is not the target's to lose.
function TargetUI:Refresh()
    if not ns.Window.frame or not ns.Window.frame:IsShown() then return end
    if ns.Tabs.current ~= "TARGET" then return end
    self:Show()
    ns.Preview:UpdateToggles()
end
