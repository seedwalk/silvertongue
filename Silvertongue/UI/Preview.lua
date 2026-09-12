-- Preview.lua -- nothing Silvertongue says leaves this frame without a click on SEND.

local ADDON, ns = ...

local Preview = {}
ns.Preview = Preview

local MAX_MESSAGE = 255

-- A tiny self-contained dropdown, so we do not depend on UIDropDownMenu.
local function createChannelPicker(parent)
    local button = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    button:SetSize(96, 20)
    button:SetText("Say")

    local menu = ns.MakePanel(parent)
    menu:EnableMouse(true)
    menu:SetFrameStrata("FULLSCREEN_DIALOG")
    menu:SetPoint("BOTTOMLEFT", button, "TOPLEFT", 0, 2)
    menu:SetWidth(96)
    menu:Hide()

    menu.items = {}
    for i, channel in ipairs(ns.CHANNELS) do
        local item = CreateFrame("Button", nil, menu)
        item:SetSize(88, 18)
        item:SetPoint("TOPLEFT", 4, -4 - (i - 1) * 18)
        item:SetNormalFontObject("GameFontHighlightSmall")
        item:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight")
        item:SetText(channel.label)
        item:GetFontString():SetPoint("LEFT", 4, 0)
        item.key = channel.key
        item:SetScript("OnClick", function(self)
            Preview:SetChannel(self.key)
            menu:Hide()
        end)
        menu.items[i] = item
    end

    button:SetScript("OnClick", function()
        if menu:IsShown() then
            menu:Hide()
            return
        end
        -- Only offer channels the player can actually speak on right now.
        local shown = 0
        for _, item in ipairs(menu.items) do
            if ns.IsChannelAvailable(item.key) then
                shown = shown + 1
                item:SetPoint("TOPLEFT", 4, -4 - (shown - 1) * 18)
                item:Show()
            else
                item:Hide()
            end
        end
        menu:SetHeight(shown * 18 + 8)
        menu:Show()
    end)

    return button, menu
end

function Preview:Create(parent)
    if self.frame then return self.frame end

    local panel = ns.MakePanel(parent, true)
    panel:SetPoint("TOPLEFT", parent.content, "BOTTOMLEFT", 0, -6)
    panel:SetPoint("BOTTOMRIGHT", -16, 16)
    self.frame = panel

    local channelButton, channelMenu = createChannelPicker(panel)
    channelButton:SetPoint("TOPLEFT", 6, -6)
    self.channelButton = channelButton
    self.channelMenu = channelMenu

    local sayToggle = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    sayToggle:SetSize(52, 20)
    sayToggle:SetPoint("TOPLEFT", 6, -6)
    sayToggle:SetText("Say")
    sayToggle:GetFontString():SetFontObject("GameFontHighlightSmall")
    sayToggle:SetScript("OnClick", function() Preview:SetChannel("SAY") end)
    sayToggle:Hide()
    self.sayToggle = sayToggle

    local whisperToggle = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    whisperToggle:SetSize(68, 20)
    whisperToggle:SetPoint("LEFT", sayToggle, "RIGHT", 4, 0)
    whisperToggle:SetText("Whisper")
    whisperToggle:GetFontString():SetFontObject("GameFontHighlightSmall")
    whisperToggle:SetScript("OnClick", function() Preview:SetChannel("WHISPER") end)
    whisperToggle:Hide()
    self.whisperToggle = whisperToggle

    local hint = panel:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    hint:SetPoint("LEFT", channelButton, "RIGHT", 8, 0)
    hint:SetText("editable -- click again to reroll")

    -- The editable preview. What is visible here is exactly what gets sent.
    local box = ns.MakePanel(panel)
    box:SetPoint("TOPLEFT", channelButton, "BOTTOMLEFT", 0, -6)
    box:SetPoint("RIGHT", -6, 0)
    box:SetHeight(72)

    local edit = CreateFrame("EditBox", nil, box)
    edit:SetPoint("TOPLEFT", 8, -6)
    edit:SetPoint("BOTTOMRIGHT", -8, 6)
    edit:SetMultiLine(true)
    edit:SetAutoFocus(false)
    edit:SetFontObject("GameFontHighlightSmall")
    edit:SetMaxLetters(MAX_MESSAGE)
    edit:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    edit:SetScript("OnTextChanged", function() Preview:UpdateButtons() end)
    -- Enter never sends. SEND is the only way anything reaches chat.
    edit:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)
    self.edit = edit

    -- A text button rather than an icon: no texture path to guess wrong.
    local star = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    star:SetSize(46, 24)
    star:SetPoint("BOTTOMLEFT", 6, 5)
    star:SetText("FAV")
    star:GetFontString():SetFontObject("GameFontDisableSmall")
    star:SetScript("OnClick", function() Preview:ToggleFavorite() end)
    star:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText("Favorite this phrase")
        GameTooltip:AddLine("Favorites come up a little more often.", 1, 1, 1, true)
        GameTooltip:Show()
    end)
    star:SetScript("OnLeave", function() GameTooltip:Hide() end)
    self.star = star

    -- Your own phrase library, edited from the box you are already looking at.
    local add = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    add:SetSize(46, 24)
    add:SetPoint("LEFT", star, "RIGHT", 4, 0)
    add:SetText("Add")
    add:GetFontString():SetFontObject("GameFontHighlightSmall")
    add:SetScript("OnClick", function() Preview:AddCurrent() end)
    add:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText("Add to this intent")
        GameTooltip:AddLine("Saves whatever is in the box as a line for this button, for every character of your class.", 1, 1, 1, true)
        GameTooltip:Show()
    end)
    add:SetScript("OnLeave", function() GameTooltip:Hide() end)
    self.addButton = add

    local hide = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    hide:SetSize(46, 24)
    hide:SetPoint("LEFT", add, "RIGHT", 4, 0)
    hide:SetText("Hide")
    hide:GetFontString():SetFontObject("GameFontHighlightSmall")
    hide:SetScript("OnClick", function() Preview:HideCurrent() end)
    hide:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText("Drop this line")
        GameTooltip:AddLine("Takes the phrase on screen out of the rotation for good, for whoever its layer covers.", 1, 1, 1, true)
        GameTooltip:Show()
    end)
    hide:SetScript("OnLeave", function() GameTooltip:Hide() end)
    self.hideButton = hide

    local send = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    send:SetSize(120, 24)
    send:SetPoint("BOTTOMRIGHT", -6, 5)
    send:SetText("SEND")
    send:SetScript("OnClick", function() Preview:Send() end)
    self.sendButton = send

    self:SetChannel(ns.addon.db.profile.channelPerTab.GENERAL)
    self:UpdateButtons()
    return panel
end

function Preview:SetChannel(key)
    self.channel = key
    self.channelButton:SetText(ns.CHANNEL_LABEL[key] or key)
    -- Remember the choice for whichever tab is open.
    local tab = ns.Tabs and ns.Tabs.current
    if tab then
        ns.addon.db.profile.channelPerTab[tab] = key
    end
    self:UpdateToggles()
end

-- The active toggle is the disabled one, the same way the tab strip reads.
function Preview:UpdateToggles()
    if not self.sayToggle or not self.sayToggle:IsShown() then return end
    local canWhisper = ns.CanWhisperTarget()
    self.sayToggle:SetEnabled(self.channel ~= "SAY")
    self.whisperToggle:SetEnabled(canWhisper and self.channel ~= "WHISPER")
    if not canWhisper and self.channel == "WHISPER" then
        self.channel = "SAY"
        self.channelButton:SetText(ns.CHANNEL_LABEL.SAY)
        self.sayToggle:SetEnabled(false)
    end
end

-- Called when switching tabs so PARTY defaults to party chat, GENERAL to say.
function Preview:ApplyTabChannel(tabKey)
    local stored = ns.addon.db.profile.channelPerTab[tabKey]
    self.channel = ns.ResolveChannel(stored)
    self.channelButton:SetText(ns.CHANNEL_LABEL[self.channel] or self.channel)
    if self.channelMenu then self.channelMenu:Hide() end

    -- On the target tab the two choices that matter get a button each.
    local targeting = tabKey == "TARGET"
    self.channelButton:SetShown(not targeting)
    self.sayToggle:SetShown(targeting)
    self.whisperToggle:SetShown(targeting)
    self:UpdateToggles()
end

-- Remembered when a phrase is built for a specific person, so a whisper goes to
-- whoever the line names rather than to whatever is selected at send time.
function Preview:SetRecipient(name)
    self.recipient = name
end

function Preview:Set(text)
    if not text then return end
    self.edit:SetText(text)
    self.edit:ClearFocus()
    self:UpdateFavoriteState()
    self:UpdateButtons()
end

function Preview:GetText()
    return (self.edit:GetText() or ""):gsub("^%s+", ""):gsub("%s+$", "")
end

function Preview:Clear()
    self.edit:SetText("")
    ns.Engine:Clear()
    self:UpdateFavoriteState()
    self:UpdateButtons()
end

function Preview:UpdateButtons()
    if not self.sendButton then return end
    local hasText = self:GetText() ~= ""
    self.sendButton:SetEnabled(hasText)
    self.star:SetEnabled(ns.Engine:HasPhrase())

    local category, intent = ns.Engine:GetCurrentIntent()
    -- Add works on edited text too, which is how you rewrite a seeded line.
    self.addButton:SetEnabled(hasText and category ~= nil)
    self.hideButton:SetEnabled(ns.Engine:HasPhrase())
end

function Preview:UpdateFavoriteState()
    local template = ns.Engine:GetCurrentTemplate()
    local on = template and ns.addon.db.profile.favorites[template] or false
    local label = self.star:GetFontString()
    if on then
        label:SetFontObject("GameFontNormalSmall")
        label:SetTextColor(1, 0.82, 0)
    else
        label:SetFontObject("GameFontDisableSmall")
        label:SetTextColor(0.5, 0.5, 0.5)
    end
end

function Preview:ToggleFavorite()
    local template = ns.Engine:GetCurrentTemplate()
    if not template then return end
    local favorites = ns.addon.db.profile.favorites
    favorites[template] = (not favorites[template]) or nil
    self:UpdateFavoriteState()
end

-- Saves what is in the box as a line for whichever button is selected. Editing
-- the text first and adding it is how you rewrite one of the seeded phrases:
-- your version joins the pool, and Hide takes the original out.
function Preview:AddCurrent()
    local category, intent = ns.Engine:GetCurrentIntent()
    if not category then return end

    local ok, why = ns.Engine:AddPhrase(category, intent, self:GetText(), "CLASS")
    if ok then
        ns.addon:Print("Added to " .. category .. " / " .. intent
            .. " for " .. ns.Engine:ScopeLabel("CLASS"):lower()
            .. ". Use /silvertongue config to widen it.")
    elseif why then
        ns.addon:Print("Not added: " .. why .. ".")
    end
    self:UpdateButtons()
end

-- Drops the phrase on screen and shows another one from what is left.
function Preview:HideCurrent()
    local category, intent = ns.Engine:GetCurrentIntent()
    local template = ns.Engine:GetCurrentTemplate()
    if not category or not template then return end

    -- Dropping from the panel uses the same rule as the library: the line's
    -- own layer decides who loses it.
    local origin
    for _, entry in ipairs(ns.Engine:DescribePool(category, intent, self.lastContext)) do
        if entry.text == template then origin = entry.origin end
    end
    ns.Engine:HidePhrase(category, intent, template, ns.Engine:ScopeForOrigin(origin))
    ns.addon:Print("Dropped one line from " .. category .. " / " .. intent .. ".")

    -- Rebuild from the smaller pool rather than rerolling the stale one.
    local text = ns.Engine:Request(category, intent, self.lastContext)
    if text then
        self:Set(text)
    else
        self:Clear()
        ns.addon:Print("That was the last line for " .. intent .. ". Add one of your own.")
    end
end

-- Ask the engine for a phrase. This never sends anything.
function Preview:Request(category, intent, ctx)
    self.lastContext = ctx
    local text = ns.Engine:Request(category, intent, ctx)
    if not text then
        self:Set("(no phrases for " .. tostring(intent) .. ")")
        return
    end
    self:Set(text)
end

-- Clicking an intent gives a phrase; clicking the same intent again rerolls it.
function Preview:RequestOrReroll(category, intent, ctx)
    if ns.Engine:IsCurrent(category, intent, ctx) then
        self:Reroll()
    else
        self:Request(category, intent, ctx)
    end
end

function Preview:Reroll()
    local text = ns.Engine:Reroll()
    if text then self:Set(text) end
end

function Preview:Send()
    local used = ns.SendPhrase(self:GetText(), self.channel, self.recipient)
    if used and used ~= self.channel then
        self:SetChannel(used)
    end
    self.edit:ClearFocus()
end
