-- Display.lua -- the confirmation.
--
-- You opened this because you want to say something, so it is the line and the
-- ways to say it, and nothing else. The channel buttons ARE the send: one click
-- picks how it goes out and sends it. Which channel each one means is decided by
-- where you opened the board from, not by you.
--
-- There is one of these, shared by every board. It is movable and remembers
-- where you put it, so it can live at the top of the screen if you like.

local ADDON, ns = ...

local Display = {}
ns.Display = Display

local WIDTH   = 380
local PAD     = 10

local state = {
    board = nil, category = nil, intent = nil, ctx = nil, emote = nil, emoteOn = true,
}

local function savePosition()
    local point, _, relPoint, x, y = Display.frame:GetPoint()
    local db = ns.addon and ns.addon.db
    if db then
        db.profile.displayPosition = { point = point, relPoint = relPoint, x = x, y = y }
    end
end

function Display:Create()
    if self.frame then return self.frame end

    local f = CreateFrame("Frame", "SilvertongueDisplay", UIParent, "BackdropTemplate")
    f:SetSize(WIDTH, 110)
    f:SetFrameStrata("FULLSCREEN_DIALOG")
    f:SetToplevel(true)
    f:SetBackdrop({
        bgFile   = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 14,
        insets = { left = 4, right = 4, top = 4, bottom = 4 },
    })
    f:SetBackdropColor(0, 0, 0, 0.92)
    f:SetMovable(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        Display.placed = true
        savePosition()
    end)
    f:SetClampedToScreen(true)
    f:Hide()
    tinsert(UISpecialFrames, "SilvertongueDisplay")
    self.frame = f

    local close = CreateFrame("Button", nil, f, "UIPanelCloseButton")
    close:SetSize(24, 24)
    close:SetPoint("TOPRIGHT", -2, -2)
    close:SetScript("OnClick", function() Display:Close() end)

    -- Plain text to look at, a text box to use. Clicking it puts the cursor in,
    -- so a line can be adjusted before it goes out without the panel looking
    -- like a form.
    local edit = CreateFrame("EditBox", nil, f)
    edit:SetPoint("TOPLEFT", PAD, -PAD)
    edit:SetPoint("TOPRIGHT", -28, -PAD)
    edit:SetHeight(40)
    edit:SetMultiLine(true)
    edit:SetAutoFocus(false)          -- never steal the keyboard: W must walk
    edit:SetFontObject("GameFontHighlightSmall")
    edit:SetMaxLetters(ns.MAX_MESSAGE)
    edit:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    edit:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)
    self.edit = edit

    -- The gesture that goes with the line. Shown before it happens, because
    -- other people see it too.
    local emoteCheck = CreateFrame("CheckButton", nil, f, "UICheckButtonTemplate")
    emoteCheck:SetSize(20, 20)
    emoteCheck:SetPoint("TOPLEFT", PAD - 2, -54)
    emoteCheck:SetScript("OnClick", function(button)
        state.emoteOn = button:GetChecked() and true or false
    end)
    self.emoteCheck = emoteCheck

    local emoteLabel = f:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    emoteLabel:SetPoint("LEFT", emoteCheck, "RIGHT", 2, 0)
    emoteLabel:SetJustifyH("LEFT")
    self.emoteLabel = emoteLabel

    local reroll = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    reroll:SetSize(28, 22)
    reroll:SetPoint("BOTTOMLEFT", PAD, 8)
    reroll:SetText("R")
    reroll:GetFontString():SetFontObject("GameFontHighlightSmall")
    reroll:SetScript("OnClick", function() Display:Reroll() end)
    reroll:SetScript("OnEnter", function(button)
        GameTooltip:SetOwner(button, "ANCHOR_RIGHT")
        GameTooltip:SetText("Say it differently")
        GameTooltip:AddLine("Another phrase for the same thing.", 1, 1, 1, true)
        GameTooltip:Show()
    end)
    reroll:SetScript("OnLeave", function() GameTooltip:Hide() end)
    self.rerollButton = reroll

    -- Up to three ways to say it, filled per context.
    self.channelButtons = {}
    for i = 1, 3 do
        local b = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
        b:SetSize(76, 22)
        b:GetFontString():SetFontObject("GameFontHighlightSmall")
        b:SetScript("OnClick", function(button) Display:Send(button.channel) end)
        b:SetScript("OnEnter", function(button)
            if not button.hint then return end
            GameTooltip:SetOwner(button, "ANCHOR_RIGHT")
            GameTooltip:SetText(button:GetText())
            GameTooltip:AddLine(button.hint, 1, 1, 1, true)
            GameTooltip:Show()
        end)
        b:SetScript("OnLeave", function() GameTooltip:Hide() end)
        b:Hide()
        self.channelButtons[i] = b
    end

    return f
end

function Display:BelongsTo(board)
    return state.board == board
end

function Display:IsShown()
    return self.frame ~= nil and self.frame:IsShown()
end

function Display:Show(board, category, intent, text)
    self:Create()

    state.board    = board
    state.category = category
    state.intent   = intent
    state.ctx      = board.context and board.context.ctx

    self.edit:SetText(text)
    self.edit:ClearFocus()
    self:RefreshEmote(text)
    self:RefreshChannels(board.context)

    -- Sits just above the board until you drag it, then stays where you put it.
    if not self.placed then
        local saved = ns.addon and ns.addon.db and ns.addon.db.profile.displayPosition
        self.frame:ClearAllPoints()
        if saved then
            self.frame:SetPoint(saved.point, UIParent, saved.relPoint, saved.x, saved.y)
            self.placed = true
        elseif board.frame then
            self.frame:SetPoint("BOTTOMLEFT", board.frame, "TOPLEFT", 0, 4)
        else
            self.frame:SetPoint("CENTER", UIParent, "CENTER", 0, 200)
        end
    end

    self.frame:Show()
end

function Display:RefreshEmote(text)
    local emote = ns.Engine:EmoteFor(state.category, state.intent, text)
    state.emote = emote

    if not emote then
        self.emoteCheck:Hide()
        self.emoteLabel:SetText("")
        return
    end

    state.emoteOn = true
    self.emoteCheck:SetChecked(true)
    self.emoteCheck:Show()

    local target = state.ctx and state.ctx.name
    self.emoteLabel:SetText(target
        and (ns.EmoteLabel(emote):lower() .. "s before " .. target)
        or ("also " .. ns.EmoteLabel(emote):lower() .. "s"))
end

-- The buttons are the send, and which channels exist is the context's call.
function Display:RefreshChannels(context)
    local channels = context and context.channels or { { key = "SAY", label = "Say" } }

    for i, button in ipairs(self.channelButtons) do
        local channel = channels[i]
        if channel then
            button.channel = channel.key
            button.hint = channel.hint
            button:SetText(channel.label)
            button:Show()
        else
            button.channel = nil
            button:Hide()
        end
    end

    -- Laid out right to left so the primary way to speak sits at the edge.
    local previous
    for i = #channels, 1, -1 do
        local button = self.channelButtons[i]
        button:ClearAllPoints()
        if previous then
            button:SetPoint("RIGHT", previous, "LEFT", -4, 0)
        else
            button:SetPoint("BOTTOMRIGHT", -PAD, 8)
        end
        previous = button
    end
end

function Display:Reroll()
    if not state.category then return end
    local text = ns.Engine:Reroll()
    if not text then return end
    self.edit:SetText(text)
    self.edit:ClearFocus()
    self:RefreshEmote(text)
end

function Display:Send(channel)
    if not channel then return end
    local context = state.board and state.board.context

    local emote = state.emoteOn and state.emote or nil
    local used = ns.SendPhrase(self.edit:GetText(), channel,
        context and context.recipient, emote, context and context.emoteTarget)
    if not used then return end

    local board = state.board
    self.edit:ClearFocus()
    self:Close()                -- clears state.board, so hold it first
    if board then board:AfterSend() end
end

function Display:Close()
    if self.frame then self.frame:Hide() end
    state.board = nil
end
