-- Config.lua -- the phrase library, browsable and editable in game.
--
-- Two panes. On the left every intent this character can reach, built from the
-- data rather than a hand-kept list. On the right every line that intent could
-- serve, tagged with where it came from and whether it is dropped.
--
-- Nothing here can speak. There is no channel and no send.

local ADDON, ns = ...

local Config = {}
ns.Config = Config

local WIDTH, HEIGHT   = 720, 480
local LEFT_WIDTH      = 210
local INDEX_ROW_H     = 16
local INDEX_ROWS      = 22
local PHRASE_ROW_H    = 42
local PHRASE_ROWS     = 8

-- Flat list of headings and intents, rebuilt whenever the library changes.
local index = {}
local selected = { category = nil, intent = nil }

-- The menus you can rearrange, and where each one's built-in order comes from.
local function menuList()
    local menus = {
        { key = "GENERAL",  label = "General",      builtin = function() return ns.INTENTS.GENERAL end },
        { key = "ATTITUDE", label = "Attitude",     builtin = function() return ns.INTENTS.ATTITUDE end },
        { key = ns.MenuKey("FACTION"), label = ns.Titlecase(ns.Engine:GetPlayerFaction() or ""),
          builtin = function() return ns.FACTION_INTENTS[ns.Engine:GetPlayerFaction()] end },
        { key = ns.MenuKey("CLASS"), label = ns.Titlecase(ns.Engine:GetPlayerClass() or ""),
          builtin = function() return ns.CLASS_INTENTS[ns.Engine:GetPlayerClass()] end },
        { key = "TARGET_FRIENDLY", label = "Target, friendly", builtin = function() return ns.TARGET_FRIENDLY end },
        { key = "TARGET_HOSTILE",  label = "Target, hostile",  builtin = function() return ns.TARGET_HOSTILE end },
        { key = "PERSON",          label = "A party member",   builtin = function() return ns.PERSON_INTENTS end },
        { key = "PARTY_ALL",       label = "The whole group",  builtin = function() return ns.PartyEveryoneIntents() end },
    }

    local kept = {}
    for _, menu in ipairs(menus) do
        if menu.builtin() then kept[#kept + 1] = menu end
    end
    return kept
end

local function rebuildIndex()
    index = {}

    -- First, not last: it is eight rows, and at the bottom it sits under two
    -- hundred intents where nobody will scroll to find it.
    index[#index + 1] = { header = true, label = "Menu order" }
    for _, menu in ipairs(menuList()) do
        index[#index + 1] = { menu = menu, label = menu.label }
    end

    for _, section in ipairs(ns.Engine:Sections()) do
        index[#index + 1] = { header = true, label = section.label }
        for _, entry in ipairs(ns.Engine:Intents(section.category)) do
            index[#index + 1] = {
                category = section.category,
                intent   = entry.intent,
                label    = entry.label,
                count    = entry.count,
            }
        end
    end

end

local function selectFirstIntent()
    for _, row in ipairs(index) do
        if not row.header then
            selected.category, selected.intent = row.category, row.intent
            return
        end
    end
end

-- A scrolling list of fixed-height rows, the stock Classic pattern.
local function makeList(parent, name, rowHeight, rowCount, width, makeRow, refresh)
    local scroll = CreateFrame("ScrollFrame", name, parent, "FauxScrollFrameTemplate")
    scroll:SetSize(width, rowHeight * rowCount)
    scroll:SetScript("OnVerticalScroll", function(self, offset)
        FauxScrollFrame_OnVerticalScroll(self, offset, rowHeight, refresh)
    end)

    local rows = {}
    for i = 1, rowCount do
        local row = makeRow(parent, i)
        row:SetPoint("TOPLEFT", scroll, "TOPLEFT", 0, -(i - 1) * rowHeight)
        rows[i] = row
    end

    return scroll, rows
end

function Config:Refresh()
    if not self.frame then return end
    rebuildIndex()
    self:RefreshIndex()
    self:RefreshPhrases()
end

function Config:RefreshIndex()
    local offset = FauxScrollFrame_GetOffset(self.indexScroll) or 0
    for i, row in ipairs(self.indexRows) do
        local entry = index[i + offset]
        if not entry then
            row:Hide()
        else
            row:Show()
            if entry.header then
                row.label:SetText(entry.label)
                row.label:SetFontObject("GameFontNormalSmall")
                row.label:SetTextColor(0.85, 0.35, 0.25)
                row.count:SetText("")
                row:SetEnabled(false)
                row.category, row.intent = nil, nil
            elseif entry.menu then
                local current = selected.menu and selected.menu.key == entry.menu.key
                row.label:SetText("   " .. entry.label)
                row.label:SetFontObject(current and "GameFontNormalSmall" or "GameFontHighlightSmall")
                row.label:SetTextColor(1, 1, 1)
                row.count:SetText("")
                row:SetEnabled(true)
                row.category, row.intent, row.menu = nil, nil, entry.menu
            else
                local current = entry.category == selected.category
                    and entry.intent == selected.intent
                row.label:SetText("   " .. entry.label)
                row.label:SetFontObject(current and "GameFontNormalSmall" or "GameFontHighlightSmall")
                row.label:SetTextColor(1, 1, 1)
                row.count:SetText(entry.count)
                row:SetEnabled(true)
                row.category, row.intent, row.menu = entry.category, entry.intent, nil
            end
        end
    end
    FauxScrollFrame_Update(self.indexScroll, #index, INDEX_ROWS, INDEX_ROW_H)
end

function Config:SelectMenu(menu)
    selected.category, selected.intent = nil, nil
    selected.menu = menu
    self.menuOrder = ns.ResolveMenu(menu.key, menu.builtin())
    if self.emoteMenu then self.emoteMenu:Hide() end
    self:RefreshIndex()
    self:RefreshPhrases()
end

local function menuRowLabel(entry)
    if entry == ns.SEP then return "---- line ----" end
    return entry[3] or entry[2] or "?"
end

-- Moving a row is the whole editor: no dragging, which in this frame API costs
-- far more than it is worth here.
function Config:MoveMenuRow(from, to)
    local order = self.menuOrder
    if not order or not order[from] or to < 1 or to > #order then return end
    local entry = table.remove(order, from)
    table.insert(order, to, entry)
    ns.SaveMenu(selected.menu.key, order)
    self:RefreshPhrases()
end

function Config:AddMenuLine(after)
    local order = self.menuOrder
    if not order then return end
    table.insert(order, math.min(after + 1, #order + 1), ns.SEP)
    ns.SaveMenu(selected.menu.key, order)
    self:RefreshPhrases()
end

function Config:RemoveMenuRow(index)
    local order = self.menuOrder
    if not order or order[index] ~= ns.SEP then return end
    table.remove(order, index)
    ns.SaveMenu(selected.menu.key, order)
    self:RefreshPhrases()
end

function Config:ResetMenu()
    if not selected.menu then return end
    ns.ResetMenu(selected.menu.key)
    self.menuOrder = ns.ResolveMenu(selected.menu.key, selected.menu.builtin())
    self.status:SetText("Back to the order it came with.")
    self:RefreshPhrases()
end

function Config:RefreshMenuOrder()
    local order = self.menuOrder or {}
    self.heading:SetText(selected.menu.label .. "  >  order")
    self.subheading:SetText(#order .. " rows")

    local offset = FauxScrollFrame_GetOffset(self.phraseScroll) or 0
    for i, row in ipairs(self.phraseRows) do
        local index = i + offset
        local entry = order[index]
        if not entry then
            row:Hide()
        else
            row:Show()
            row.phrase, row.hidden = nil, nil
            row.text:SetText(menuRowLabel(entry))
            row.text:SetTextColor(entry == ns.SEP and 0.5 or 1,
                                  entry == ns.SEP and 0.5 or 1,
                                  entry == ns.SEP and 0.5 or 1)
            row.origin:SetText("")
            row.emote:Hide()

            row.action:SetText(entry == ns.SEP and "Remove" or "Add line")
            row.action:SetScript("OnClick", function()
                if entry == ns.SEP then Config:RemoveMenuRow(index) else Config:AddMenuLine(index) end
            end)
            row.action:Show()

            row.up:Show()
            row.down:Show()
            row.up:SetEnabled(index > 1)
            row.down:SetEnabled(index < #order)
            row.up:SetScript("OnClick", function() Config:MoveMenuRow(index, index - 1) end)
            row.down:SetScript("OnClick", function() Config:MoveMenuRow(index, index + 1) end)

            row.pick:Hide()
        end
    end
    FauxScrollFrame_Update(self.phraseScroll, #order, PHRASE_ROWS, PHRASE_ROW_H)

    self.editBox:Hide()
    self.editBoxPanel:Hide()
    self.addButton:SetText("Reset order")
    self.addButton:SetScript("OnClick", function() Config:ResetMenu() end)
    self.scopeButton:Hide()
end

function Config:RefreshPhrases()
    if selected.menu then
        self:RefreshMenuOrder()
        return
    end

    self.editBox:Show()
    self.editBoxPanel:Show()
    self.scopeButton:Show()
    self.addButton:SetText("Add line")
    self.addButton:SetScript("OnClick", function() Config:AddFromBox() end)

    local rows = {}
    if selected.category then
        rows = ns.Engine:DescribePool(selected.category, selected.intent, nil)
    end
    self.phraseData = rows

    if selected.category then
        self.heading:SetText(ns.Titlecase(selected.category) .. "  >  " .. ns.Titlecase(selected.intent))
        local live = 0
        for _, entry in ipairs(rows) do
            if not entry.hidden then live = live + 1 end
        end
        self.subheading:SetText(live .. " in rotation, " .. (#rows - live) .. " dropped")
    else
        self.heading:SetText("")
        self.subheading:SetText("")
    end

    local offset = FauxScrollFrame_GetOffset(self.phraseScroll) or 0
    for i, row in ipairs(self.phraseRows) do
        local entry = rows[i + offset]
        if not entry then
            row:Hide()
        else
            row:Show()
            row.text:SetText(entry.text)
            row.origin:SetText(entry.origin)
            if entry.hidden then
                row.text:SetTextColor(0.45, 0.45, 0.45)
                row.action:SetText("Restore")
            else
                row.text:SetTextColor(entry.origin == "yours" and 1 or 0.85,
                                      entry.origin == "yours" and 0.82 or 0.85,
                                      entry.origin == "yours" and 0 or 0.85)
                row.action:SetText("Drop")
            end
            row.phrase = entry.text
            row.hidden = entry.hidden
            row.emote:Show()
            row.up:Hide()
            row.down:Hide()
            row.pick:Show()
            row.action:SetScript("OnClick", function() Config:ToggleRow(row) end)
            row.emote:SetText(ns.EmoteLabel(
                ns.Engine:EmoteChoice(selected.category, selected.intent, entry.text)))
        end
    end
    FauxScrollFrame_Update(self.phraseScroll, #rows, PHRASE_ROWS, PHRASE_ROW_H)
end

-- FauxScrollFrame's bar is a global named after the frame in this client, not a
-- .ScrollBar member as on retail. Guarded so neither shape breaks the window.
local function resetScroll(scroll, name)
    FauxScrollFrame_SetOffset(scroll, 0)
    local bar = rawget(scroll, "ScrollBar") or _G[name .. "ScrollBar"]
    if type(bar) == "table" and type(bar.SetValue) == "function" then
        bar:SetValue(0)
    end
end

-- A scrolling list of the curated gestures, anchored to the row it belongs to.
function Config:OpenEmotePicker(row)
    if not row.phrase or not selected.category then return end

    if not self.emoteMenu then
        local menu = ns.MakePanel(self.frame)
        menu:EnableMouse(true)
        menu:SetFrameStrata("FULLSCREEN_DIALOG")
        menu:SetSize(120, 18 * 12 + 8)
        menu:Hide()

        local scroll = CreateFrame("ScrollFrame", "SilvertongueEmoteScroll", menu, "FauxScrollFrameTemplate")
        scroll:SetSize(100, 18 * 12)
        scroll:SetPoint("TOPLEFT", 4, -4)
        scroll:SetScript("OnVerticalScroll", function(self, offset)
            FauxScrollFrame_OnVerticalScroll(self, offset, 18, function() Config:RefreshEmoteMenu() end)
        end)
        menu.scroll = scroll

        menu.items = {}
        for i = 1, 12 do
            local item = CreateFrame("Button", nil, menu)
            item:SetSize(100, 18)
            item:SetPoint("TOPLEFT", 4, -4 - (i - 1) * 18)
            item:SetNormalFontObject("GameFontHighlightSmall")
            item:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight")
            item:SetText(" ")     -- same: no font string until it has text
            item:GetFontString():SetPoint("LEFT", 4, 0)
            item:SetScript("OnClick", function(button)
                Config:ChooseEmote(button.token)
                menu:Hide()
            end)
            menu.items[i] = item
        end
        self.emoteMenu = menu
    end

    self.emoteRow = row
    self.emoteMenu:ClearAllPoints()
    self.emoteMenu:SetPoint("TOPLEFT", row.emote, "BOTTOMLEFT", 0, -2)
    self.emoteMenu:Show()
    self:RefreshEmoteMenu()
end

function Config:RefreshEmoteMenu()
    local menu = self.emoteMenu
    if not menu or not menu:IsShown() then return end

    local offset = FauxScrollFrame_GetOffset(menu.scroll) or 0
    for i, item in ipairs(menu.items) do
        local token = ns.EMOTE_LIST[i + offset]
        if token then
            item.token = token
            item:SetText(ns.EmoteLabel(token))
            item:Show()
        else
            item.token = nil
            item:Hide()
        end
    end
    FauxScrollFrame_Update(menu.scroll, #ns.EMOTE_LIST, 12, 18)
end

function Config:ChooseEmote(token)
    local row = self.emoteRow
    if not row or not row.phrase then return end

    ns.Engine:SetEmote(selected.category, selected.intent, row.phrase, token, self.scope or "CLASS")
    self.status:SetText("Gesture set to " .. ns.EmoteLabel(token):lower() .. ".")
    self:RefreshPhrases()
end

function Config:Select(category, intent)
    selected.category, selected.intent = category, intent
    selected.menu = nil
    if self.emoteMenu then self.emoteMenu:Hide() end
    resetScroll(self.phraseScroll, "SilvertongueConfigPhraseScroll")
    self:RefreshIndex()
    self:RefreshPhrases()
end

-- Drop or restore one line, then redraw. The scope is inherited from the line's
-- own origin, so dropping something tagged "shared" drops it on every character
-- while dropping something tagged "your class" drops it only for that class.
-- You act on what the row already says it is.
function Config:ToggleRow(row)
    if not row.phrase or not selected.category then return end

    local scope = ns.Engine:ScopeForOrigin(row.origin and row.origin:GetText())
    if row.hidden then
        ns.Engine:AddPhrase(selected.category, selected.intent, row.phrase, scope)
        self.status:SetText("Restored for " .. ns.Engine:ScopeLabel(scope):lower() .. ".")
    else
        ns.Engine:HidePhrase(selected.category, selected.intent, row.phrase, scope)
        self.status:SetText("Dropped for " .. ns.Engine:ScopeLabel(scope):lower() .. ".")
    end
    self:Refresh()
end

function Config:AddFromBox()
    if not selected.category then return end
    local text = (self.editBox:GetText() or ""):gsub("^%s+", ""):gsub("%s+$", "")
    if text == "" then return end

    local scope = self.scope or "CLASS"
    local ok, why = ns.Engine:AddPhrase(selected.category, selected.intent, text, scope)
    if ok then
        self.editBox:SetText("")
        self.editBox:ClearFocus()
        self.status:SetText("Added for " .. ns.Engine:ScopeLabel(scope):lower() .. ".")
    else
        self.status:SetText("Not added: " .. (why or "unknown") .. ".")
    end
    self:Refresh()
end

-- Which of your characters a new line is written for. Only offered for scopes
-- this character actually has, so a scope can never be set to nothing.
function Config:SetScope(scope)
    self.scope = scope
    if self.scopeButton then
        self.scopeButton:SetText(ns.Engine:ScopeLabel(scope))
    end
end

local function createScopePicker(parent)
    local button = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    button:SetSize(130, 22)
    button:GetFontString():SetFontObject("GameFontHighlightSmall")

    local menu = ns.MakePanel(parent)
    menu:EnableMouse(true)
    menu:SetFrameStrata("FULLSCREEN_DIALOG")
    menu:SetPoint("BOTTOMLEFT", button, "TOPLEFT", 0, 2)
    menu:SetWidth(130)
    menu:Hide()

    menu.items = {}
    for i, scope in ipairs(ns.SCOPES) do
        local item = CreateFrame("Button", nil, menu)
        item:SetSize(122, 18)
        item:SetPoint("TOPLEFT", 4, -4 - (i - 1) * 18)
        item:SetNormalFontObject("GameFontHighlightSmall")
        item:SetHighlightTexture("Interface\QuestFrame\UI-QuestTitleHighlight")
        item:SetText(" ")     -- no font string until it has text
        item:GetFontString():SetPoint("LEFT", 4, 0)
        item.scope = scope
        item:SetScript("OnClick", function(self)
            Config:SetScope(self.scope)
            menu:Hide()
        end)
        menu.items[i] = item
    end

    button:SetScript("OnClick", function()
        if menu:IsShown() then menu:Hide() return end
        local shown = 0
        for _, item in ipairs(menu.items) do
            if ns.Engine:ScopeToken(item.scope) then
                shown = shown + 1
                item:SetText(ns.Engine:ScopeLabel(item.scope))
                item:SetPoint("TOPLEFT", 4, -4 - (shown - 1) * 18)
                item:Show()
            else
                item:Hide()
            end
        end
        menu:SetHeight(shown * 18 + 8)
        menu:Show()
    end)

    button:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText("Who gets this line")
        GameTooltip:AddLine("A new line can be written for every character you play, "
            .. "or only for your race, your class or your faction.", 1, 1, 1, true)
        GameTooltip:Show()
    end)
    button:SetScript("OnLeave", function() GameTooltip:Hide() end)

    return button
end

function Config:Create()
    if self.frame then return self.frame end

    local f = CreateFrame("Frame", "SilvertongueConfigFrame", UIParent, "BackdropTemplate")
    f:SetSize(WIDTH, HEIGHT)
    f:SetFrameStrata("DIALOG")
    f:SetBackdrop({
        bgFile   = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true, tileSize = 32, edgeSize = 32,
        insets = { left = 11, right = 12, top = 12, bottom = 11 },
    })
    f:SetMovable(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", f.StopMovingOrSizing)
    f:SetClampedToScreen(true)
    f:SetPoint("CENTER")
    f:Hide()
    tinsert(UISpecialFrames, "SilvertongueConfigFrame")
    self.frame = f

    local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", 0, -16)
    title:SetText("SILVERTONGUE")
    title:SetTextColor(0.85, 0.35, 0.25)

    local who = f:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    who:SetPoint("TOP", title, "BOTTOM", 0, -2)
    who:SetText("Give your character a voice")

    CreateFrame("Button", nil, f, "UIPanelCloseButton"):SetPoint("TOPRIGHT", -6, -6)

    -- Left pane: every intent, grouped.
    local left = ns.MakePanel(f, true)
    left:SetPoint("TOPLEFT", 16, -56)
    left:SetSize(LEFT_WIDTH, HEIGHT - 76)

    self.indexScroll, self.indexRows = makeList(left, "SilvertongueConfigIndexScroll",
        INDEX_ROW_H, INDEX_ROWS, LEFT_WIDTH - 30,
        function(parent, i)
            local row = CreateFrame("Button", nil, parent)
            row:SetSize(LEFT_WIDTH - 30, INDEX_ROW_H)
            row:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight")

            row.label = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            row.label:SetPoint("LEFT", 4, 0)
            row.label:SetJustifyH("LEFT")

            row.count = row:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
            row.count:SetPoint("RIGHT", -4, 0)

            row:SetScript("OnClick", function(self)
                if self.menu then
                    Config:SelectMenu(self.menu)
                elseif self.category then
                    Config:Select(self.category, self.intent)
                end
            end)
            return row
        end,
        function() Config:RefreshIndex() end)
    self.indexScroll:SetPoint("TOPLEFT", 6, -6)

    -- Right pane: the lines themselves.
    local right = ns.MakePanel(f, true)
    right:SetPoint("TOPLEFT", left, "TOPRIGHT", 8, 0)
    right:SetPoint("BOTTOMRIGHT", -16, 20)

    self.heading = right:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    self.heading:SetPoint("TOPLEFT", 8, -8)
    self.heading:SetTextColor(0.85, 0.35, 0.25)

    self.subheading = right:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    self.subheading:SetPoint("TOPRIGHT", -8, -8)

    local rowWidth = WIDTH - LEFT_WIDTH - 70
    self.phraseScroll, self.phraseRows = makeList(right, "SilvertongueConfigPhraseScroll",
        PHRASE_ROW_H, PHRASE_ROWS, rowWidth,
        function(parent, i)
            local row = CreateFrame("Frame", nil, parent)
            row:SetSize(rowWidth, PHRASE_ROW_H)

            row.text = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            row.text:SetPoint("TOPLEFT", 4, -2)
            row.text:SetWidth(rowWidth - 76)
            row.text:SetJustifyH("LEFT")
            row.text:SetWordWrap(true)

            row.origin = row:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
            row.origin:SetPoint("BOTTOMLEFT", 4, 4)
            row.origin:SetWidth(120)
            row.origin:SetJustifyH("LEFT")

            -- The gesture that goes out with this line. On the bottom row so it
            -- costs the phrase no width.
            row.emote = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
            row.emote:SetSize(96, 18)
            row.emote:SetPoint("LEFT", row.origin, "RIGHT", 4, 0)
            row.emote:GetFontString():SetFontObject("GameFontDisableSmall")
            row.emote:SetScript("OnClick", function() Config:OpenEmotePicker(row) end)
            row.emote:SetScript("OnEnter", function(button)
                GameTooltip:SetOwner(button, "ANCHOR_RIGHT")
                GameTooltip:SetText("Gesture")
                GameTooltip:AddLine("Played alongside this line. Saved with the same scope as the line itself.", 1, 1, 1, true)
                GameTooltip:Show()
            end)
            row.emote:SetScript("OnLeave", function() GameTooltip:Hide() end)

            row.action = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
            row.action:SetSize(66, 20)
            row.action:SetPoint("TOPRIGHT", -4, -4)
            row.action:GetFontString():SetFontObject("GameFontHighlightSmall")
            row.action:SetScript("OnClick", function() Config:ToggleRow(row) end)

            row.up = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
            row.up:SetSize(22, 18)
            row.up:SetPoint("RIGHT", row.action, "LEFT", -22, 0)
            row.up:SetText("^")
            row.up:GetFontString():SetFontObject("GameFontHighlightSmall")
            row.up:Hide()

            row.down = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
            row.down:SetSize(22, 18)
            row.down:SetPoint("LEFT", row.up, "RIGHT", 2, 0)
            row.down:SetText("v")
            row.down:GetFontString():SetFontObject("GameFontHighlightSmall")
            row.down:Hide()

            -- Clicking a line loads it for editing, which is how you rewrite one.
            row.pick = CreateFrame("Button", nil, row)
            row.pick:SetPoint("TOPLEFT", 0, 0)
            row.pick:SetSize(rowWidth - 76, PHRASE_ROW_H)
            row.pick:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight")
            row.pick:SetScript("OnClick", function()
                if not row.phrase then return end
                Config.editBox:SetText(row.phrase)
                Config.editBox:SetFocus()
                Config.status:SetText("Edit it and Add to keep both, then Drop the original.")
            end)
            return row
        end,
        function() Config:RefreshPhrases() end)
    self.phraseScroll:SetPoint("TOPLEFT", 6, -28)

    -- Write a new line for the selected intent.
    local box = ns.MakePanel(right)
    box:SetPoint("BOTTOMLEFT", 6, 34)
    box:SetPoint("RIGHT", -6, 0)
    box:SetHeight(46)
    self.editBoxPanel = box

    local edit = CreateFrame("EditBox", nil, box)
    edit:SetPoint("TOPLEFT", 8, -6)
    edit:SetPoint("BOTTOMRIGHT", -8, 6)
    edit:SetMultiLine(true)
    edit:SetAutoFocus(false)
    edit:SetFontObject("GameFontHighlightSmall")
    edit:SetMaxLetters(255)
    edit:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    edit:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)
    self.editBox = edit

    self.status = right:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    self.status:SetPoint("BOTTOMLEFT", 8, 14)
    self.status:SetWidth(WIDTH - LEFT_WIDTH - 290)
    self.status:SetJustifyH("LEFT")

    local addButton = CreateFrame("Button", nil, right, "UIPanelButtonTemplate")
    addButton:SetSize(90, 22)
    addButton:SetPoint("BOTTOMRIGHT", -6, 8)
    addButton:SetText("Add line")
    addButton:SetScript("OnClick", function() Config:AddFromBox() end)
    self.addButton = addButton

    self.scopeButton = createScopePicker(right)
    self.scopeButton:SetPoint("RIGHT", addButton, "LEFT", -6, 0)
    self:SetScope(self.scope or "CLASS")

    local hint = f:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    hint:SetPoint("BOTTOMLEFT", 20, 8)
    hint:SetText("Dropping a line uses the scope it is tagged with. Nothing here can speak.")

    -- Start on the first intent rather than on nothing.
    selected.menu = nil

    rebuildIndex()
    selectFirstIntent()
    return f
end

function Config:Show()
    local f = self:Create()
    f:Show()
    self:Refresh()
end

function Config:Hide()
    if self.frame then self.frame:Hide() end
end

function Config:Toggle()
    if self.frame and self.frame:IsShown() then
        self:Hide()
    else
        self:Show()
    end
end
