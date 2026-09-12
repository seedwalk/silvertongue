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

-- One line tall. It hugs the phrase and grows to the right, so the edge you
-- anchored it by never moves.
-- Two rows: the line, and what to do with it. It hugs the row you clicked --
-- it is part of that menu, not a window of its own, so it is neither draggable
-- nor remembered anywhere. Dragging it was what made it drift off the menu and
-- shift about as phrases changed length.
local TEXT_H     = 18
local BUTTON_H   = 20
local PAD        = 8
local TEXT_MIN   = 170
local TEXT_MAX   = 430

local state = {
    board = nil, category = nil, intent = nil, ctx = nil, emote = nil, emoteOn = true,
}

function Display:Create()
    if self.frame then return self.frame end

    local f = CreateFrame("Frame", "SilvertongueDisplay", UIParent, "BackdropTemplate")
    f:SetHeight(PAD * 2 + TEXT_H + BUTTON_H + 2)
    f:SetFrameStrata("FULLSCREEN_DIALOG")
    f:SetToplevel(true)
    f:SetBackdrop({
        bgFile   = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 14,
        insets = { left = 4, right = 4, top = 4, bottom = 4 },
    })
    f:SetBackdropColor(0, 0, 0, 0.92)
    f:EnableMouse(true)
    f:SetClampedToScreen(true)
    f:Hide()
    tinsert(UISpecialFrames, "SilvertongueDisplay")
    self.frame = f

    -- Plain text to look at, a text box to use. Clicking it puts the cursor in,
    -- so a line can be adjusted before it goes out.
    local edit = CreateFrame("EditBox", nil, f)
    edit:SetPoint("TOPLEFT", PAD, -PAD)
    edit:SetHeight(TEXT_H)
    edit:SetAutoFocus(false)          -- never steal the keyboard: W must walk
    edit:SetFontObject("GameFontHighlightSmall")
    edit:SetMaxLetters(ns.MAX_MESSAGE)
    edit:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    edit:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)
    self.edit = edit

    -- An EditBox cannot report its own text width, so a hidden font string does
    -- the measuring.
    local ruler = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    ruler:Hide()
    self.ruler = ruler

    -- The gesture that goes with the line, on the second row where there is
    -- room to say what it actually is.
    local emoteCheck = CreateFrame("CheckButton", nil, f, "UICheckButtonTemplate")
    emoteCheck:SetSize(18, 18)
    emoteCheck:SetScript("OnClick", function(button)
        state.emoteOn = button:GetChecked() and true or false
    end)
    self.emoteCheck = emoteCheck

    local emoteLabel = f:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    emoteLabel:SetPoint("LEFT", emoteCheck, "RIGHT", 1, 0)
    emoteLabel:SetJustifyH("LEFT")
    self.emoteLabel = emoteLabel

    -- The game's own refresh arrow. A letter on a button said nothing, and the
    -- word took the room two channel buttons needed.
    local reroll = CreateFrame("Button", nil, f)
    reroll:SetSize(BUTTON_H, BUTTON_H)
    reroll:SetNormalTexture("Interface\\Buttons\\UI-RefreshButton")
    reroll:SetPushedTexture("Interface\\Buttons\\UI-RefreshButton")
    reroll:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight", "ADD")
    reroll:GetPushedTexture():SetVertexColor(0.7, 0.7, 0.7)
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
        b:SetSize(58, BUTTON_H)
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

function Display:Show(board, category, intent, text, row)
    self:Create()

    state.board    = board
    state.category = category
    state.intent   = intent
    state.ctx      = board.context and board.context.ctx

    self.edit:SetText(text)
    self.edit:ClearFocus()
    self:RefreshEmote(text)
    self:RefreshChannels(board.context)
    self:Layout(text)

    -- Glued to the row you clicked. It is part of that menu, so it is placed
    -- fresh every time rather than remembering anywhere it has been.
    self.frame:ClearAllPoints()
    if row then
        self.frame:SetPoint("LEFT", row, "RIGHT", PAD, 0)
    elseif board.frame then
        self.frame:SetPoint("LEFT", board.frame, "RIGHT", 2, 0)
    else
        self.frame:SetPoint("CENTER", UIParent, "CENTER", 0, 200)
    end

    self.frame:Show()
end

function Display:RefreshEmote(text)
    local emote = ns.Engine:EmoteFor(state.category, state.intent, text)
    state.emote = emote

    if not emote then
        self.emoteCheck:Hide()
        self.emoteLabel:Hide()
        return
    end

    state.emoteOn = true
    self.emoteCheck:SetChecked(true)
    self.emoteCheck:Show()

    local target = state.ctx and state.ctx.name
    self.emoteLabel:SetText(target
        and (ns.EmoteLabel(emote):lower() .. "s before " .. target)
        or ("also " .. ns.EmoteLabel(emote):lower() .. "s"))
    self.emoteLabel:Show()
end

-- Everything sits on one row. The controls pin to the right edge in a fixed
-- order, and the strip is then cut to whatever the line needs.
function Display:Layout(text)
    -- Laid out left to right, chained from the edge that stays put. The strip
    -- grows to the right as phrases change length, and nothing you click moves.
    local previous, controls = nil, 0

    local function place(control, width, gap)
        control:ClearAllPoints()
        if previous then
            control:SetPoint("LEFT", previous, "RIGHT", gap, 0)
        else
            control:SetPoint("BOTTOMLEFT", PAD, PAD - 2)
        end
        previous = control
        controls = controls + width + gap
    end

    for _, button in ipairs(self.channelButtons) do
        if button:IsShown() then place(button, 58, 3) end
    end
    place(self.rerollButton, BUTTON_H, 4)

    if self.emoteCheck:IsShown() then
        place(self.emoteCheck, 18, 6)
        controls = controls + (self.emoteLabel:GetStringWidth() or 0) + 6
    end

    self.ruler:SetText(text or "")
    local textWidth = self.ruler:GetStringWidth() or TEXT_MIN
    if textWidth < TEXT_MIN then textWidth = TEXT_MIN end
    if textWidth > TEXT_MAX then textWidth = TEXT_MAX end

    local width = textWidth
    if controls > width then width = controls end

    self.edit:SetWidth(width + 4)
    self.frame:SetWidth(PAD * 2 + width + 4)
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

end

function Display:Reroll()
    if not state.category then return end
    local text = ns.Engine:Reroll()
    if not text then return end
    self.edit:SetText(text)
    self.edit:ClearFocus()
    self:RefreshEmote(text)
    self:Layout(text)
end

function Display:Send(channel)
    if not channel then return end
    local context = state.board and state.board.context

    local emote = state.emoteOn and state.emote or nil
    local used = ns.SendPhrase(self.edit:GetText(), channel,
        context and context.recipient, emote, context and context.emoteTarget)
    if not used then return end

    self.edit:ClearFocus()
    self:Close()
    ns.Board:CloseAll()
end

function Display:Close()
    if self.frame then self.frame:Hide() end
    state.board = nil
end
