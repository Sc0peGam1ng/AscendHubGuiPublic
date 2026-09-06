-- AscendHub Sell Ores v6 — Premium Edition

if not game:IsLoaded() then game.Loaded:Wait() end

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local player = Players.LocalPlayer

local Settings = { MacOSButtons = false, Animations = true }

local gui = Instance.new("ScreenGui")
gui.Name = "AscendHub"
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.DisplayOrder = 999
gui.IgnoreGuiInset = true
-- prevent the game's localization tables from translating our UI text
gui.AutoLocalize = false
gui.Parent = player:WaitForChild("PlayerGui")

local C = {
    BG = Color3.fromRGB(26, 30, 35),
    SB = Color3.fromRGB(22, 26, 31),
    SBH = Color3.fromRGB(35, 41, 48),
    SBA = Color3.fromRGB(43, 50, 58),
    CT = Color3.fromRGB(32, 38, 45),
    CD = Color3.fromRGB(39, 46, 54),
    CDH = Color3.fromRGB(47, 55, 64),
    GR = Color3.fromRGB(48, 210, 128),
    GRD = Color3.fromRGB(30, 165, 95),
    TX = Color3.fromRGB(235, 236, 234),
    TS = Color3.fromRGB(164, 166, 163),
    TD = Color3.fromRGB(103, 106, 103),
    BD = Color3.fromRGB(60, 65, 72),
    TO = Color3.fromRGB(73, 78, 86),
    RD = Color3.fromRGB(242, 92, 88),
    OR = Color3.fromRGB(244, 174, 68),
    PU = Color3.fromRGB(190, 111, 255),
    WH = Color3.fromRGB(255, 255, 255),
}
local ThemeAccent = C.GR

-- BuilderSans is the cleanest modern Roblox UI face; keep an older-client fallback.
local FONT = Enum.Font.BuilderSans or Enum.Font.SourceSans
local FONT_BOLD = Enum.Font.BuilderSansBold or Enum.Font.SourceSansBold
-- BuilderSans is Roblox's clean default face — far more readable than GothamSSm.
local FONT_FACE = Font.new("rbxasset://fonts/families/BuilderSans.json", Enum.FontWeight.Medium, Enum.FontStyle.Normal)
local FONT_FACE_BOLD = Font.new("rbxasset://fonts/families/BuilderSans.json", Enum.FontWeight.Bold, Enum.FontStyle.Normal)
local FONT_FACE_REGULAR = Font.new("rbxasset://fonts/families/BuilderSans.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal)
local ICONS = {
    Search = "rbxassetid://10734943674",
    Settings = "rbxassetid://10734950309",
    Main = "rbxassetid://10723407389",
    Farm = "rbxassetid://10723405360",
    Shop = "rbxassetid://10734952479",
    Misc = "rbxassetid://10734963191",
    Roll = "rbxassetid://10723343321",
    Tunnels = "rbxassetid://10734886202",
    Pets = "rbxassetid://10723396000",
    Rewards = "rbxassetid://10723396402",
}
local CATEGORY_ICONS = {
    house = ICONS.Main,
    pickaxe = ICONS.Farm,
    dices = ICONS.Roll,
    route = ICONS.Tunnels,
    ["shopping-cart"] = ICONS.Shop,
    ["paw-print"] = ICONS.Pets,
    gift = ICONS.Rewards,
    settings = ICONS.Misc,
}
local function resolveIcon(icon, categoryName)
    if type(icon) ~= "string" or icon == "" then
        return CATEGORY_ICONS[string.lower(tostring(categoryName or ""))] or ICONS.Main
    end
    if icon:match("^rbxasset") or icon:match("^rbxgameasset") then return icon end
    local key = icon:lower():gsub("^lucide/", "")
    return CATEGORY_ICONS[key] or CATEGORY_ICONS[string.lower(tostring(categoryName or ""))] or ICONS.Main
end
local function tw(o, p, d, s)
    if not Settings.Animations then
        for k, v in pairs(p) do o[k] = v end
        return nil
    end
    local tween = TweenService:Create(o, TweenInfo.new(d or 0.2, s or Enum.EasingStyle.Quint, Enum.EasingDirection.Out), p)
    tween:Play()
    return tween
end

local function ui(cls, p, pr)
    local o = Instance.new(cls)
    for k, v in pairs(pr or {}) do
        if k ~= "Parent" then o[k] = v end
    end
    if o:IsA("TextButton") or o:IsA("ImageButton") then
        o.AutoButtonColor = false
        o.Selectable = false
    end
    if o:IsA("TextLabel") or o:IsA("TextButton") or o:IsA("TextBox") then
        pcall(function()
            o.FontFace = (pr and pr.Font == FONT_BOLD) and FONT_FACE_BOLD or FONT_FACE
        end)
    end
    if p then o.Parent = p end
    return o
end

-- ═══ MAIN WINDOW ═══
-- Plain Frame (no CanvasGroup): CanvasGroup re-renders its texture on every
-- visual change, which caused pixel jitter. Rounded bottom corners are kept
-- by rounding the sidebar/content themselves (see UICorner below).
local normalWidth, normalHeight = 960, 560
local Main = ui("Frame", gui, {
    AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.new(0.5, 0, 0.5, 0),
    Size = UDim2.new(0, 0, 0, 0),
    BackgroundColor3 = C.BG,
    BackgroundTransparency = 0.06,
    BorderSizePixel = 0,
    ClipsDescendants = true,
})
ui("UICorner", Main, {CornerRadius = UDim.new(0, 12)})
ui("UIStroke", Main, {Color = Color3.fromRGB(58, 61, 60), Thickness = 1.5, Transparency = 0})
local mainGradient = ui("UIGradient", Main, {
    Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, C.BG),
        ColorSequenceKeypoint.new(0.55, C.CD),
        ColorSequenceKeypoint.new(1, C.SB),
    }),
    Rotation = 28,
})

local resizeHandle = ui("TextButton", Main, {
    Position = UDim2.new(1, -20, 1, -20),
    Size = UDim2.fromOffset(20, 20),
    BackgroundTransparency = 1,
    Text = "",
    AutoButtonColor = false,
    ZIndex = 40,
})
ui("ImageLabel", resizeHandle, {
    Size = UDim2.fromOffset(16, 16),
    Position = UDim2.new(1, -2, 1, -2),
    AnchorPoint = Vector2.new(1, 1),
    BackgroundTransparency = 1,
    Image = "rbxassetid://10734898934",
    ImageColor3 = C.TS,
    ImageTransparency = 0.1,
    ScaleType = Enum.ScaleType.Fit,
    ZIndex = 41,
})

local resizing = false
local resizeStart, resizeStartSize
resizeHandle.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        resizing = true
        resizeStart = input.Position
        resizeStartSize = Main.AbsoluteSize
    end
end)
resizeHandle.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then resizing = false end
end)
UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        resizing = false
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if resizing and input.UserInputType == Enum.UserInputType.MouseMovement then
        local delta = input.Position - resizeStart
        local width = math.clamp(resizeStartSize.X + delta.X, 700, 1400)
        local height = math.clamp(resizeStartSize.Y + delta.Y, 420, 800)
        normalWidth, normalHeight = width, height
        Main.Size = UDim2.fromOffset(width, height)
    end
end)

-- Animate in
tw(Main, {Size = UDim2.fromOffset(normalWidth, normalHeight)}, 0.45, Enum.EasingStyle.Back)

-- Glow effect
local glow = ui("ImageLabel", Main, {
    AnchorPoint = Vector2.new(0.5, 0.5),
    BackgroundTransparency = 1,
    Position = UDim2.new(0.5, 0, 0, -2),
    Size = UDim2.new(1, -40, 0, 2),
    Image = "rbxassetid://7912134082",
    ImageColor3 = C.GR,
    ImageTransparency = 1,
    Visible = false,
    ScaleType = Enum.ScaleType.Slice,
    SliceCenter = Rect.new(100, 100, 100, 100),
    ZIndex = 1,
})

-- ═══ TITLEBAR ═══
local TB = ui("Frame", Main, {
    Size = UDim2.new(1, 0, 0, 56),
    BackgroundColor3 = C.SB,
    BackgroundTransparency = 0.04,
    BorderSizePixel = 0,
    ZIndex = 5,
    ClipsDescendants = true,
})
ui("UICorner", TB, {CornerRadius = UDim.new(0, 12)})
-- squares the titlebar's bottom corners while sidebar/content are visible
local tbPatch = ui("Frame", TB, {
    Size = UDim2.new(1, 0, 0, 14),
    Position = UDim2.new(0, 0, 1, -16),
    BackgroundColor3 = C.SB,
    BackgroundTransparency = 0.04,
    BorderSizePixel = 0,
    ZIndex = 5,
})
local titleLabel = ui("TextLabel", TB, {
    Size = UDim2.new(0, 160, 1, 0),
    Position = UDim2.new(0, 18, 0, 0),
    BackgroundTransparency = 1,
    Text = "AscendHub",
    TextColor3 = C.TX,
    TextSize = 20,
    Font = FONT_BOLD,
    TextXAlignment = Enum.TextXAlignment.Left,
    TextYAlignment = Enum.TextYAlignment.Center,
    ZIndex = 6,
})

local subtitleLabel = ui("TextLabel", TB, {
    Size = UDim2.new(0, 120, 1, 0),
    Position = UDim2.new(0, 220, 0, 0),
    BackgroundTransparency = 1,
    Text = "",
    TextColor3 = C.TD,
    TextSize = 14,
    Font = FONT,
    TextXAlignment = Enum.TextXAlignment.Left,
    TextYAlignment = Enum.TextYAlignment.Center,
    ZIndex = 6,
})

-- Right side buttons
local SB, Content
local minimized = false
local closeBtn = ui("TextButton", TB, {
    Size = UDim2.new(0, 14, 0, 14),
    Position = UDim2.new(1, -22, 0, 21),
    BackgroundTransparency = 1,
    Text = "",
    BorderSizePixel = 0,
    ZIndex = 7,
})
ui("UICorner", closeBtn, {CornerRadius = UDim.new(1, 0)})
local closeIcon = ui("ImageLabel", closeBtn, {
    Size = UDim2.new(0, 14, 0, 14),
    Position = UDim2.new(0.5, -7, 0.5, -7),
    BackgroundTransparency = 1,
    Image = "rbxassetid://9886659671",
    ImageColor3 = C.WH,
    ImageTransparency = 0,
    ScaleType = Enum.ScaleType.Fit,
    ZIndex = 8,
})
closeBtn.MouseButton1Click:Connect(function()
    tw(Main, {Size = UDim2.new(0, 960, 0, 0), BackgroundTransparency = 0.3}, 0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.In)
    task.wait(0.25)
    gui:Destroy()
end)

local minBtn = ui("TextButton", TB, {
    Size = UDim2.new(0, 14, 0, 14),
    Position = UDim2.new(1, -42, 0, 21),
    BackgroundTransparency = 1,
    Text = "",
    BorderSizePixel = 0,
    ZIndex = 7,
})
ui("UICorner", minBtn, {CornerRadius = UDim.new(1, 0)})
local minIcon = ui("ImageLabel", minBtn, {
    Size = UDim2.new(0, 14, 0, 14),
    Position = UDim2.new(0.5, -7, 0.5, -7),
    BackgroundTransparency = 1,
    Image = "rbxassetid://9886659406",
    ImageColor3 = C.WH,
    ImageTransparency = 0,
    ScaleType = Enum.ScaleType.Fit,
    ZIndex = 8,
})

local maxBtn = ui("TextButton", TB, {
    Size = UDim2.new(0, 14, 0, 14),
    Position = UDim2.new(1, -62, 0, 21),
    BackgroundColor3 = C.GR,
    Text = "",
    BorderSizePixel = 0,
    ZIndex = 7,
})
ui("UICorner", maxBtn, {CornerRadius = UDim.new(1, 0)})
maxBtn.Visible = false
maxBtn.MouseButton1Click:Connect(function()
    SB.Visible = true
    Content.Visible = true
    minimized = false
    tbPatch.Visible = true
    tw(Main, {Size = UDim2.fromOffset(normalWidth, normalHeight)}, 0.25)
end)

minBtn.MouseButton1Click:Connect(function()
    minimized = not minimized
    if minimized then
        SB.Visible = false
        Content.Visible = false
        tbPatch.Visible = false
        tw(Main, {Size = UDim2.fromOffset(normalWidth, 56)}, 0.3)
    else
        SB.Visible = true
        Content.Visible = true
        tbPatch.Visible = true
        tw(Main, {Size = UDim2.fromOffset(normalWidth, normalHeight)}, 0.3)
    end
end)

local function setMacOSLayout(enabled)
    Settings.MacOSButtons = enabled
    local closeCorner = closeBtn:FindFirstChildOfClass("UICorner")
    local minCorner = minBtn:FindFirstChildOfClass("UICorner")
    if enabled then
        if closeCorner then closeCorner.CornerRadius = UDim.new(1, 0) end
        if minCorner then minCorner.CornerRadius = UDim.new(1, 0) end
        maxBtn.Visible = true
        tw(closeBtn, {Size = UDim2.new(0, 14, 0, 14), BackgroundTransparency = 0, BackgroundColor3 = C.RD, Position = UDim2.new(0, 58, 0, 21)}, 0.3, Enum.EasingStyle.Quint)
        tw(minBtn, {Size = UDim2.new(0, 14, 0, 14), BackgroundTransparency = 0, BackgroundColor3 = C.OR, Position = UDim2.new(0, 38, 0, 21)}, 0.3, Enum.EasingStyle.Quint)
        tw(maxBtn, {Size = UDim2.new(0, 14, 0, 14), Position = UDim2.new(0, 18, 0, 21)}, 0.3, Enum.EasingStyle.Quint)
        tw(closeIcon, {ImageTransparency = 1}, 0.2)
        tw(minIcon, {ImageTransparency = 1}, 0.2)
        tw(titleLabel, {Position = UDim2.new(0, 138, 0, 0)}, 0.35, Enum.EasingStyle.Quint)
    else
        if closeCorner then closeCorner.CornerRadius = UDim.new(0, 4) end
        if minCorner then minCorner.CornerRadius = UDim.new(0, 4) end
        maxBtn.Visible = false
        tw(closeBtn, {Size = UDim2.new(0, 28, 0, 28), BackgroundTransparency = 1, Position = UDim2.new(1, -44, 0, 14)}, 0.3, Enum.EasingStyle.Quint)
        tw(minBtn, {Size = UDim2.new(0, 28, 0, 28), BackgroundTransparency = 1, Position = UDim2.new(1, -80, 0, 14)}, 0.3, Enum.EasingStyle.Quint)
        tw(closeIcon, {ImageTransparency = 0}, 0.2)
        tw(minIcon, {ImageTransparency = 0}, 0.2)
        tw(titleLabel, {Position = UDim2.new(0, 18, 0, 0)}, 0.35, Enum.EasingStyle.Quint)
    end
end
setMacOSLayout(false)

-- Drag
local dragging, dragStart, startPos
TB.InputBegan:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true; dragStart = i.Position; startPos = Main.Position
    end
end)
TB.InputEnded:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
end)
UserInputService.InputChanged:Connect(function(i)
    if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then
        local d = i.Position - dragStart
        Main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
    end
end)

-- ═══ SIDEBAR ═══
SB = ui("Frame", Main, {
    Size = UDim2.new(0, 210, 1, -56),
    Position = UDim2.new(0, 0, 0, 56),
    BackgroundColor3 = C.SB,
    BackgroundTransparency = 0.08,
    BorderSizePixel = 0,
    ZIndex = 3,
})
-- round the sidebar so the window's bottom-left corner stays rounded
ui("UICorner", SB, {CornerRadius = UDim.new(0, 0)})
ui("TextLabel", SB, {
    Size = UDim2.new(1, -28, 0, 28),
    Position = UDim2.new(0, 14, 0, 14),
    BackgroundTransparency = 1,
    Text = "Settings",
    TextColor3 = C.TX,
    TextSize = 22,
    Font = FONT_BOLD,
    TextXAlignment = Enum.TextXAlignment.Left,
    TextYAlignment = Enum.TextYAlignment.Center,
    ZIndex = 7,
})

-- Search
local searchBg = ui("Frame", SB, {
    Size = UDim2.new(1, -28, 0, 34),
    Position = UDim2.new(0, 14, 0, 54),
    BackgroundColor3 = C.CD,
    BorderSizePixel = 0,
    ZIndex = 4,
    ClipsDescendants = true,
})
ui("UICorner", searchBg, {CornerRadius = UDim.new(0, 7)})
ui("UIStroke", searchBg, {Color = C.BD, Thickness = 1})

ui("ImageLabel", searchBg, {
    Size = UDim2.new(0, 16, 0, 16),
    Position = UDim2.new(0, 10, 0.5, -8),
    BackgroundTransparency = 1,
    Image = ICONS.Search,
    ImageColor3 = C.TS,
    ImageTransparency = 0.05,
    ScaleType = Enum.ScaleType.Fit,
    ZIndex = 8,
})

local searchBox = ui("TextBox", searchBg, {
    Size = UDim2.new(1, -44, 1, 0),
    Position = UDim2.new(0, 32, 0, 0),
    BackgroundTransparency = 1,
    Text = "",
    TextTransparency = 0,
    PlaceholderText = "Search",
    PlaceholderColor3 = C.TS,
    TextColor3 = C.TX,
    TextSize = 14,
    Font = FONT,
    TextXAlignment = Enum.TextXAlignment.Left,
    TextYAlignment = Enum.TextYAlignment.Center,
    TextWrapped = false,
    ClearTextOnFocus = false,
    ZIndex = 7,
})
pcall(function() searchBox.FontFace = FONT_FACE_REGULAR end)

local searchStroke = searchBg:FindFirstChildOfClass("UIStroke")
searchBox.Focused:Connect(function()
    if searchStroke then tw(searchStroke, {Transparency = 0}, 0.15) end
end)
searchBox.FocusLost:Connect(function()
    if searchStroke then tw(searchStroke, {Transparency = 0.25}, 0.18) end
end)
-- Nav
local navHolder = ui("Frame", SB, {
    Size = UDim2.new(1, -28, 1, -106),
    Position = UDim2.new(0, 14, 0, 100),
    BackgroundTransparency = 1,
    ZIndex = 4,
})
ui("UIListLayout", navHolder, {
    FillDirection = Enum.FillDirection.Vertical,
    SortOrder = Enum.SortOrder.LayoutOrder,
    Padding = UDim.new(0, 5),
})

local NavItems = {}

-- ═══ CONTENT ═══
Content = ui("Frame", Main, {
    Size = UDim2.new(1, -210, 1, -56),
    Position = UDim2.new(0, 210, 0, 56),
    BackgroundColor3 = C.CT,
    BackgroundTransparency = 0,
    BorderSizePixel = 0,
    ZIndex = 3,
    ClipsDescendants = true,
})
local contentGradient = ui("UIGradient", Content, {
    Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, C.CT:Lerp(C.GR, 0.035)),
        ColorSequenceKeypoint.new(0.42, C.CT),
        ColorSequenceKeypoint.new(1, C.CD),
    }),
    Rotation = 24,
})
contentGradient.Enabled = false
local ambientGlow = ui("Frame", Content, {
    Size = UDim2.new(1, 0, 0, 190),
    Position = UDim2.new(0, 0, 0, 0),
    BackgroundColor3 = C.GR,
    BackgroundTransparency = 0.94,
    BorderSizePixel = 0,
    ZIndex = 1,
})
ambientGlow.Visible = false
ui("UIGradient", ambientGlow, {
    Color = ColorSequence.new(C.GR, C.GR),
    Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.05),
        NumberSequenceKeypoint.new(0.7, 0.72),
        NumberSequenceKeypoint.new(1, 1),
    }),
    Rotation = 90,
})
-- round the content so the window's bottom-right corner stays rounded
ui("UICorner", Content, {CornerRadius = UDim.new(0, 0)})
local ContentScroll = ui("ScrollingFrame", Content, {
    Size = UDim2.new(1, -28, 1, -18),
    Position = UDim2.new(0, 14, 0, 9),
    BackgroundTransparency = 1,
    ScrollBarThickness = 2,
    ScrollBarImageColor3 = C.WH,
    ScrollBarImageTransparency = 0.35,
    BorderSizePixel = 0,
    CanvasSize = UDim2.new(0, 0, 0, 0),
    ZIndex = 4,
})
ui("UIPadding", ContentScroll, {
    PaddingLeft = UDim.new(0, 2),
    PaddingRight = UDim.new(0, 6),
    PaddingTop = UDim.new(0, 2),
    PaddingBottom = UDim.new(0, 4),
})
ui("UIListLayout", ContentScroll, {
    FillDirection = Enum.FillDirection.Vertical,
    SortOrder = Enum.SortOrder.LayoutOrder,
    Padding = UDim.new(0, 8),
})

ContentScroll.UIListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    ContentScroll.CanvasSize = UDim2.new(0, 0, 0, ContentScroll.UIListLayout.AbsoluteContentSize.Y + 16)
end)

-- ═══ PAGE SYSTEM ═══
local Pages = {}
local NavButtons = {}
local navCount = 0
local activePage = nil

-- Single settings button in the title bar, matching the reference application.
local topDock = ui("Frame", TB, {
    Size = UDim2.new(0, 42, 1, 0),
    Position = UDim2.new(0.5, -21, 0, 0),
    BackgroundTransparency = 1,
    Visible = false,
    ZIndex = 6,
})

-- Selection surface stays outside the list so it never changes button layout.
local navSelection = ui("Frame", SB, {
    Size = UDim2.new(1, -28, 0, 36),
    Position = UDim2.new(0, 14, 0, 100),
    BackgroundColor3 = C.SBH,
    BackgroundTransparency = 0.05,
    BorderSizePixel = 0,
    ZIndex = 3,
    Visible = false,
})
ui("UICorner", navSelection, {CornerRadius = UDim.new(0, 8)})
local function moveNavSelection(index, instant)
    local target = UDim2.new(0, 14, 0, 100 + ((index - 1) * 41))
    navSelection.Visible = true
    if instant or not Settings.Animations then navSelection.Position = target
    else tw(navSelection, {Position = target}, 0.26, Enum.EasingStyle.Quint) end
end
local topBtn = ui("ImageButton", topDock, {
    Size = UDim2.new(0, 24, 0, 24),
    Position = UDim2.new(0.5, -12, 0.5, -12),
    BackgroundTransparency = 1,
    Image = ICONS.Settings,
    ImageColor3 = C.TS,
    ImageTransparency = 0.05,
    BorderSizePixel = 0,
    ZIndex = 7,
})

-- Hover label: letters reveal individually beside the settings gear.
local settingsTooltip = ui("Frame", topDock, {
    Size = UDim2.new(0, 90, 0, 28),
    Position = UDim2.new(1, -2, 0.5, -14),
    BackgroundTransparency = 1,
    Visible = false,
    ZIndex = 21,
})
local settingsText = ui("TextLabel", settingsTooltip, {
    Size = UDim2.new(1, 0, 1, 0),
    BackgroundTransparency = 1,
    Text = "Settings",
    TextColor3 = C.TX,
    TextSize = 13,
    Font = FONT_BOLD,
    TextXAlignment = Enum.TextXAlignment.Left,
    TextYAlignment = Enum.TextYAlignment.Center,
    MaxVisibleGraphemes = 0,
    ZIndex = 22,
})
local tooltipHovered = false
local tooltipSerial = 0
-- Hover is intentionally inert across the library.

local SearchSections = {}
local SearchEntries = {}
local SearchDecorations = {}

local function applySearch(query)
    query = string.lower(tostring(query or "")):gsub("^%s+", ""):gsub("%s+$", "")
    if query == "" then
        for name, page in pairs(Pages) do page.Visible = (name == activePage) end
        for _, entry in ipairs(SearchEntries) do
            if entry.Instance and entry.Instance.Parent then entry.Instance.Visible = true end
        end
        return
    end
    for _, page in pairs(Pages) do page.Visible = true end
    local sectionMatches = {}
    for _, entry in ipairs(SearchEntries) do
        local match = string.find(entry.Text or "", query, 1, true) ~= nil
        if entry.Instance and entry.Instance.Parent then entry.Instance.Visible = match end
        if match and entry.Section then sectionMatches[entry.Section.Frame] = true end
    end
    for content in pairs(SearchSections) do
        content.Parent.Visible = sectionMatches[SearchSections[content].Frame] == true
    end
end

searchBox:GetPropertyChangedSignal("Text"):Connect(function()
    applySearch(searchBox.Text)
end)

local function makePage(name)
    -- plain Frame: no CanvasGroup/UIScale — nothing that can shift pixels
    local page = ui("Frame", ContentScroll, {
        Name = name, Size = UDim2.new(1, 0, 0, 0),
        BackgroundTransparency = 1, Visible = false, ClipsDescendants = true, ZIndex = 5,
    })
    -- Inner padding gives card outlines room so the edges never cut them.
    ui("UIPadding", page, {
        PaddingLeft = UDim.new(0, 2),
        PaddingRight = UDim.new(0, 2),
        PaddingTop = UDim.new(0, 2),
        PaddingBottom = UDim.new(0, 2),
    })
    local pl = ui("UIListLayout", page, {
        FillDirection = Enum.FillDirection.Vertical,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 8),
    })
    pl:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        page.Size = UDim2.new(1, 0, 0, pl.AbsoluteContentSize.Y + 4)
    end)
    Pages[name] = page
    return page
end

local function makeSection(parent, title, desc)
    local s = ui("Frame", parent, {
        Size = UDim2.new(1, 0, 0, 0),
        BackgroundColor3 = C.CD,
        BorderSizePixel = 0,
        ClipsDescendants = true,
        ZIndex = 6,
    })
    ui("UICorner", s, {CornerRadius = UDim.new(0, 10)})
    ui("UIStroke", s, {Color = C.BD, Thickness = 1})

    local h = 10
    if title then
        ui("TextLabel", s, {
            Size = UDim2.new(1, -20, 0, 20),
            Position = UDim2.new(0, 14, 0, h),
            BackgroundTransparency = 1,
            Text = title,
            TextColor3 = C.TX,
            TextSize = 16,
            Font = FONT_BOLD,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextYAlignment = Enum.TextYAlignment.Center,
            ZIndex = 7,
        })
        h = h + 26
        if desc then
            ui("TextLabel", s, {
                Size = UDim2.new(1, -20, 0, 16),
                Position = UDim2.new(0, 14, 0, h),
                BackgroundTransparency = 1,
                Text = desc,
                TextColor3 = C.TD,
                TextSize = 13,
                Font = FONT,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextYAlignment = Enum.TextYAlignment.Center,
                ZIndex = 7,
            })
            h = h + 20
        end
    end
    h = h + 4

    local content = ui("Frame", s, {
        Size = UDim2.new(1, -28, 0, 0),
        Position = UDim2.new(0, 14, 0, h),
        BackgroundTransparency = 1,
        ClipsDescendants = true,
        ZIndex = 7,
    })
    local cl = ui("UIListLayout", content, {
        FillDirection = Enum.FillDirection.Vertical,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 5),
    })
    cl:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        content.Size = UDim2.new(1, -28, 0, cl.AbsoluteContentSize.Y)
        s.Size = UDim2.new(1, 0, 0, h + cl.AbsoluteContentSize.Y + 10)
    end)
    SearchSections[content] = {
        Frame = s,
        Page = parent,
        Title = title or "",
        Text = string.lower((title or "") .. " " .. (desc or "")),
    }
    return content
end

local function registerSearchEntry(instance, parent, text, desc)
    local section = SearchSections[parent]
    table.insert(SearchEntries, {
        Instance = instance,
        Section = section,
        Title = text or "",
        Text = string.lower((text or "") .. " " .. (desc or "") .. " " .. (section and section.Text or "")),
    })
end

-- ═══ TOGGLE ═══
local function makeToggle(parent, text, desc, default, cb)
    local row = ui("Frame", parent, {
        Size = UDim2.new(1, 0, 0, desc and 42 or 36),
        BackgroundColor3 = C.CDH,
        BorderSizePixel = 0,
        ZIndex = 8,
    })
    registerSearchEntry(row, parent, text, desc)
    ui("UICorner", row, {CornerRadius = UDim.new(0, 8)})

    ui("TextLabel", row, {
        Size = UDim2.new(1, -58, 0, 18),
        Position = UDim2.new(0, 12, 0, desc and 5 or 9),
        BackgroundTransparency = 1,
        Text = text,
        TextColor3 = C.TX,
        TextSize = 14,
        Font = FONT,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Center,
        ZIndex = 9,
    })

    if desc then
        ui("TextLabel", row, {
            Size = UDim2.new(1, -58, 0, 14),
            Position = UDim2.new(0, 12, 0, 23),
            BackgroundTransparency = 1,
            Text = desc,
            TextColor3 = C.TD,
            TextSize = 12,
            Font = FONT,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextYAlignment = Enum.TextYAlignment.Center,
            ZIndex = 9,
        })
    end

    local tBg = ui("Frame", row, {
        Size = UDim2.new(0, 40, 0, 22),
        Position = UDim2.new(1, -50, 0.5, -11),
        BackgroundColor3 = default and C.TS or C.TO,
        BorderSizePixel = 0,
        ZIndex = 9,
    })
    ui("UICorner", tBg, {CornerRadius = UDim.new(0, 11)})

    local tKn = ui("Frame", tBg, {
        Size = UDim2.new(0, 18, 0, 18),
        Position = default and UDim2.new(1, -20, 0, 2) or UDim2.new(0, 2, 0, 2),
        BackgroundColor3 = default and C.BG or C.WH,
        BorderSizePixel = 0,
        ZIndex = 10,
    })
    ui("UICorner", tKn, {CornerRadius = UDim.new(0, 9)})

    local state = default or false
    local btn = ui("TextButton", row, {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Text = "",
        ZIndex = 10,
    })

    btn.MouseButton1Click:Connect(function()
        state = not state
        if state then
            tw(tBg, {BackgroundColor3 = ThemeAccent}, 0.15)
            tw(tKn, {Position = UDim2.new(1, -20, 0, 2)}, 0.15)
            tw(tKn, {BackgroundColor3 = C.BG}, 0.15)
        else
            tw(tBg, {BackgroundColor3 = C.TO}, 0.15)
            tw(tKn, {Position = UDim2.new(0, 2, 0, 2)}, 0.15)
            tw(tKn, {BackgroundColor3 = C.WH}, 0.15)
        end
        if cb then cb(state) end
    end)

end

-- ═══ ACCENT ═══
-- Elements registered here follow the user-chosen accent color.
local AccentFills, AccentLabels = {}, {}
local ThemeFills, ThemeLabels = {}, {}

local function applyAccent(color)
    C.GR = color
    C.GRD = color:Lerp(Color3.new(0, 0, 0), 0.3)
    for _, f in ipairs(AccentFills) do
        if f.Parent then tw(f, {BackgroundColor3 = color}, 0.2) end
    end
    for _, l in ipairs(AccentLabels) do
        if l.Parent then tw(l, {TextColor3 = color}, 0.2) end
    end
    maxBtn.BackgroundColor3 = color
end

-- ═══ SLIDER ═══
local function makeSlider(parent, text, min, max, def, suf, cb)
    local row = ui("Frame", parent, {
        Size = UDim2.new(1, 0, 0, 52),
        BackgroundColor3 = C.CDH,
        BorderSizePixel = 0,
        ZIndex = 8,
    })
    registerSearchEntry(row, parent, text)
    ui("UICorner", row, {CornerRadius = UDim.new(0, 8)})

    ui("TextLabel", row, {
        Size = UDim2.new(0.6, 0, 0, 18),
        Position = UDim2.new(0, 12, 0, 8),
        BackgroundTransparency = 1,
        Text = text,
        TextColor3 = C.TX,
        TextSize = 14,
        Font = FONT,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Center,
        ZIndex = 9,
    })

    local valLbl = ui("TextBox", row, {
        Size = UDim2.new(0.4, -16, 0, 18),
        Position = UDim2.new(0.6, 0, 0, 8),
        BackgroundTransparency = 1,
        Text = tostring(def) .. (suf or ""),
        ClearTextOnFocus = false,
        TextEditable = true,
        TextColor3 = C.GR,
        TextSize = 14,
        Font = FONT_BOLD,
        TextXAlignment = Enum.TextXAlignment.Right,
        TextYAlignment = Enum.TextYAlignment.Center,
        ZIndex = 9,
    })
    table.insert(ThemeLabels, valLbl)

    local currentValue = def

    local track = ui("Frame", row, {
        Size = UDim2.new(1, -24, 0, 5),
        Position = UDim2.new(0, 12, 0, 38),
        BackgroundColor3 = C.TO,
        BorderSizePixel = 0,
        ZIndex = 9,
    })
    ui("UICorner", track, {CornerRadius = UDim.new(0, 3)})

    local pct = (def - min) / (max - min)
    local fill = ui("Frame", track, {
        Size = UDim2.new(pct, 0, 1, 0),
        BackgroundColor3 = C.GR,
        BorderSizePixel = 0,
        ZIndex = 10,
    })
    ui("UICorner", fill, {CornerRadius = UDim.new(0, 3)})
    table.insert(ThemeFills, fill)

    local knob = ui("Frame", track, {
        Size = UDim2.new(0, 14, 0, 14),
        Position = UDim2.new(pct, -7, 0.5, -7),
        BackgroundColor3 = C.WH,
        BorderSizePixel = 0,
        ZIndex = 11,
    })
    ui("UICorner", knob, {CornerRadius = UDim.new(0, 7)})

    local dragging = false
    local hit = ui("TextButton", track, {
        Size = UDim2.new(1, 16, 0, 22),
        Position = UDim2.new(0, -8, 0.5, -11),
        BackgroundTransparency = 1,
        Text = "",
        ZIndex = 12,
    })

    local function setValue(v)
        v = tonumber(v)
        if not v then
            valLbl.Text = tostring(currentValue) .. (suf or "")
            return
        end
        v = math.clamp(v, min, max)
        v = math.floor(v * 10 + 0.5) / 10
        currentValue = v
        local normalized = (v - min) / (max - min)
        fill.Size = UDim2.new(normalized, 0, 1, 0)
        knob.Position = UDim2.new(normalized, -7, 0.5, -7)
        valLbl.Text = tostring(v) .. (suf or "")
        if cb then cb(v) end
    end

    local function update(input)
        local p = math.clamp((input.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
        local v = min + (max - min) * p
        setValue(v)
    end

    valLbl.Focused:Connect(function()
        valLbl.Text = tostring(currentValue)
        valLbl.CursorPosition = #valLbl.Text + 1
    end)
    valLbl.FocusLost:Connect(function()
        setValue(valLbl.Text)
    end)

    hit.MouseButton1Down:Connect(function()
        dragging = true
    end)
    UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
    end)
    UserInputService.InputChanged:Connect(function(i)
        if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then update(i) end
    end)
end

-- ═══ BUTTON ═══
local function makeButton(parent, text, accent, cb)
    -- Standard action buttons use the same dark surface as the rest of the GUI.
    -- Accent is reserved for callers that explicitly request a colored button.
    local isAccent = accent ~= nil
    local btn = ui("TextButton", parent, {
        Size = UDim2.new(1, 0, 0, 38),
        BackgroundColor3 = accent or C.CD,
        Text = "",
        BorderSizePixel = 0,
        ZIndex = 8,
    })
    registerSearchEntry(btn, parent, text)
    ui("UICorner", btn, {CornerRadius = UDim.new(0, 8)})
    ui("UIStroke", btn, {Color = C.BD, Thickness = 1})
    ui("TextLabel", btn, {
        Size = UDim2.new(1, -16, 1, 0),
        Position = UDim2.new(0, 12, 0, 0),
        BackgroundTransparency = 1,
        Text = text,
        TextColor3 = accent and C.WH or C.TX,
        TextSize = 14,
        Font = FONT_BOLD,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Center,
        ZIndex = 9,
    })

    -- default-accent buttons follow the user's chosen accent color
    if isAccent then
        table.insert(AccentFills, btn)
    end
    local getBase = function()
        return accent or C.CD
    end

    btn.MouseButton1Click:Connect(function()
        if cb then cb() end
    end)
end

local function makeDivider(parent)
    local divider = ui("Frame", parent, {
        Size = UDim2.new(1, 0, 0, 1),
        BackgroundColor3 = C.BD,
        BackgroundTransparency = 0.4,
        BorderSizePixel = 0,
        ZIndex = 7,
    })
    table.insert(SearchDecorations, divider)
end

local function makeDropdown(parent, text, options, default, cb)
    local row = ui("Frame", parent, {
        Size = UDim2.new(1, -8, 0, 38), BackgroundColor3 = C.CDH,
        BorderSizePixel = 0, ClipsDescendants = true, ZIndex = 8,
    })
    registerSearchEntry(row, parent, text, table.concat(options, " "))
    ui("UICorner", row, {CornerRadius = UDim.new(0, 8)})
    ui("TextLabel", row, {Size = UDim2.new(0.5, 0, 1, 0), Position = UDim2.new(0, 12, 0, 0), BackgroundTransparency = 1, Text = text, TextColor3 = C.TX, TextSize = 14, Font = FONT, TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Center, ZIndex = 9})
    local value = ui("TextLabel", row, {Size = UDim2.fromOffset(116, 38), Position = UDim2.new(1, -28, 0, 0), AnchorPoint = Vector2.new(1, 0), BackgroundTransparency = 1, Text = default or options[1], TextColor3 = C.TS, TextSize = 13, Font = FONT, TextXAlignment = Enum.TextXAlignment.Right, TextYAlignment = Enum.TextYAlignment.Center, ZIndex = 9})
    local arrow = ui("TextLabel", row, {Size = UDim2.fromOffset(18, 38), Position = UDim2.new(1, -6, 0, 0), AnchorPoint = Vector2.new(1, 0), BackgroundTransparency = 1, Text = "▼", TextColor3 = C.TS, TextSize = 10, Font = FONT_BOLD, TextXAlignment = Enum.TextXAlignment.Center, TextYAlignment = Enum.TextYAlignment.Center, ZIndex = 9})
    local hit = ui("TextButton", row, {Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "", BorderSizePixel = 0, ZIndex = 10})
    local index = table.find(options, default) or 1

    -- slide-out options window below the row
    local popup, catcher
    local function closePopup()
        if not popup then return end
        local p, c = popup, catcher
        popup, catcher = nil, nil
        arrow.Text = "▼"
        tw(p, {Size = UDim2.new(0, p.AbsoluteSize.X, 0, 0)}, 0.16, Enum.EasingStyle.Quint, Enum.EasingDirection.In)
        if c then c:Destroy() end
        task.delay(0.18, function() p:Destroy() end)
    end

    hit.MouseButton1Click:Connect(function()
        if popup then closePopup() return end
        local w, h = 190, #options * 34 + 10
        catcher = ui("TextButton", Main, {
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1,
            Text = "",
            ZIndex = 29,
        })
        catcher.MouseButton1Click:Connect(closePopup)

        popup = ui("Frame", Main, {
            BackgroundColor3 = C.CD,
            BorderSizePixel = 0,
            ClipsDescendants = true,
            ZIndex = 30,
        })
        ui("UICorner", popup, {CornerRadius = UDim.new(0, 10)})
        ui("UIStroke", popup, {Color = C.BD, Thickness = 1})
        local list = ui("Frame", popup, {
            Size = UDim2.new(1, -8, 1, -8),
            Position = UDim2.new(0, 4, 0, 4),
            BackgroundTransparency = 1,
            ZIndex = 31,
        })
        ui("UIListLayout", list, {Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder})
        for i, opt in ipairs(options) do
            local optBtn = ui("TextButton", list, {
                Size = UDim2.new(1, 0, 0, 30),
                BackgroundColor3 = (i == index) and C.SBA or C.CDH,
                Text = "",
                BorderSizePixel = 0,
                ZIndex = 32,
                LayoutOrder = i,
            })
            ui("UICorner", optBtn, {CornerRadius = UDim.new(0, 6)})
            ui("TextLabel", optBtn, {
                Size = UDim2.new(1, -16, 1, 0),
                Position = UDim2.new(0, 10, 0, 0),
                BackgroundTransparency = 1,
                Text = opt,
                TextColor3 = (i == index) and C.TX or C.TS,
                TextSize = 13,
                Font = FONT,
                TextXAlignment = Enum.TextXAlignment.Left,
                TextYAlignment = Enum.TextYAlignment.Center,
                ZIndex = 33,
            })
            optBtn.MouseButton1Click:Connect(function()
                index = i
                value.Text = opt
                if cb then cb(opt) end
                closePopup()
            end)
        end

        arrow.Text = "▲"
        task.defer(function()
            if not popup then return end
            task.wait(0.05)
            if not popup or not row.Parent then return end
            local rel = row.AbsolutePosition - Main.AbsolutePosition
            local x = math.clamp(rel.X + 14, 8, math.max(8, Main.AbsoluteSize.X - w - 8))
            if rel.Y + row.AbsoluteSize.Y + 6 + h > Main.AbsoluteSize.Y - 8 then
                popup.Position = UDim2.new(0, x, 0, rel.Y - h - 6)
            else
                popup.Position = UDim2.new(0, x, 0, rel.Y + row.AbsoluteSize.Y + 6)
            end
            popup.Size = UDim2.new(0, w, 0, 0)
            tw(popup, {Size = UDim2.new(0, w, 0, h)}, 0.22, Enum.EasingStyle.Quint)
        end)
    end)

end

local function makeTextInput(parent, text, initial, placeholder, cb)
    local row = ui("Frame", parent, {Size = UDim2.new(1, 0, 0, 42), BackgroundColor3 = C.CDH, BorderSizePixel = 0, ZIndex = 8})
    registerSearchEntry(row, parent, text, placeholder)
    ui("UICorner", row, {CornerRadius = UDim.new(0, 8)})
    ui("TextLabel", row, {Size = UDim2.new(0.35, 0, 1, 0), Position = UDim2.new(0, 14, 0, 0), BackgroundTransparency = 1, Text = text, TextColor3 = C.TX, TextSize = 14, Font = FONT, TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Center, ZIndex = 9})
    -- input sits just a little to the right of the label, right edge aligned with other rows
    local input = ui("TextBox", row, {Size = UDim2.new(0.65, -40, 0, 28), Position = UDim2.new(0.35, 30, 0.5, -14), BackgroundColor3 = C.CD, BorderSizePixel = 0, Text = initial or "", PlaceholderText = placeholder or "Enter value", PlaceholderColor3 = C.TD, TextColor3 = C.TS, TextSize = 13, Font = FONT, ClearTextOnFocus = false, TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Center, TextWrapped = false, ClipsDescendants = true, ZIndex = 9})
    ui("UICorner", input, {CornerRadius = UDim.new(0, 6)})
    ui("UIPadding", input, {PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 6)})
    input.FocusLost:Connect(function()
        if cb then cb(input.Text) end
    end)
end

local function makeKeybind(parent, text, default, cb)
    local row = ui("TextButton", parent, {Size = UDim2.new(1, 0, 0, 38), BackgroundColor3 = C.CDH, Text = "", BorderSizePixel = 0, ClipsDescendants = true, ZIndex = 8})
    registerSearchEntry(row, parent, text, default)
    ui("UICorner", row, {CornerRadius = UDim.new(0, 8)})
    ui("TextLabel", row, {Size = UDim2.new(0.6, 0, 1, 0), Position = UDim2.new(0, 12, 0, 0), BackgroundTransparency = 1, Text = text, TextColor3 = C.TX, TextSize = 14, Font = FONT, TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Center, ZIndex = 9})
    local key = ui("TextLabel", row, {Size = UDim2.new(0, 74, 0, 24), Position = UDim2.new(1, -86, 0.5, -12), BackgroundColor3 = C.CD, Text = default or "None", TextColor3 = C.TS, TextSize = 12, Font = FONT_BOLD, TextXAlignment = Enum.TextXAlignment.Center, TextYAlignment = Enum.TextYAlignment.Center, ZIndex = 9})
    ui("UICorner", key, {CornerRadius = UDim.new(0, 6)})
    local listening = false
    row.MouseButton1Click:Connect(function()
        listening = true
        key.Text = "Press key"
        tw(key, {TextColor3 = C.GR}, 0.18)
    end)
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if listening and not gameProcessed then
            listening = false
            key.Text = input.KeyCode.Name
            tw(key, {TextColor3 = C.TS}, 0.22)
            if cb then cb(input.KeyCode) end
        end
    end)
end

-- ═══ COLOR PICKER ═══
-- HSV picker: saturation/value box + hue strip, live preview, apply.
local function openColorPicker(current, onApply)
    local hue, sat, val = Color3.toHSV(current)

    local backdrop = ui("Frame", Main, {
        Size = UDim2.new(1, 0, 0, 0),
        Position = UDim2.new(0, 0, 0, 56),
        BackgroundColor3 = Color3.new(0, 0, 0),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ZIndex = 40,
    })
    tw(backdrop, {Size = UDim2.new(1, 0, 1, -56), BackgroundTransparency = 0.45}, 0.2)
    local backdropHit = ui("TextButton", backdrop, {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Text = "",
        ZIndex = 41,
    })

    local panel = ui("Frame", Main, {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.5, 0, 0.5, 20),
        Size = UDim2.new(0, 0, 0, 0),
        BackgroundColor3 = C.CD,
        BorderSizePixel = 0,
        ClipsDescendants = true,
        ZIndex = 42,
    })
    ui("UICorner", panel, {CornerRadius = UDim.new(0, 12)})
    ui("UIStroke", panel, {Color = C.BD, Thickness = 1})
    tw(panel, {Size = UDim2.new(0, 260, 0, 262)}, 0.3, Enum.EasingStyle.Back)

    ui("TextLabel", panel, {
        Size = UDim2.new(1, -48, 0, 26),
        Position = UDim2.new(0, 16, 0, 8),
        BackgroundTransparency = 1,
        Text = "Accent Color",
        TextColor3 = C.TX,
        TextSize = 15,
        Font = FONT_BOLD,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Center,
        ZIndex = 44,
    })
    local closeX = ui("TextButton", panel, {
        Size = UDim2.new(0, 22, 0, 22),
        Position = UDim2.new(1, -32, 0, 9),
        BackgroundTransparency = 1,
        Text = "✕",
        TextColor3 = C.TS,
        TextSize = 13,
        Font = FONT_BOLD,
        ZIndex = 44,
    })

    -- Saturation/value box
    local svBox = ui("Frame", panel, {
        Size = UDim2.new(1, -32, 0, 128),
        Position = UDim2.new(0, 16, 0, 42),
        BackgroundColor3 = Color3.fromHSV(hue, 1, 1),
        BorderSizePixel = 0,
        ClipsDescendants = true,
        ZIndex = 44,
    })
    ui("UICorner", svBox, {CornerRadius = UDim.new(0, 8)})

    local satLayer = ui("Frame", svBox, {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundColor3 = Color3.new(1, 1, 1),
        BorderSizePixel = 0,
        ZIndex = 45,
    })
    local satGrad = Instance.new("UIGradient")
    satGrad.Color = ColorSequence.new(Color3.new(1, 1, 1))
    satGrad.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0),
        NumberSequenceKeypoint.new(1, 1),
    })
    satGrad.Parent = satLayer

    local valLayer = ui("Frame", svBox, {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundColor3 = Color3.new(0, 0, 0),
        BorderSizePixel = 0,
        ZIndex = 46,
    })
    local valGrad = Instance.new("UIGradient")
    valGrad.Color = ColorSequence.new(Color3.new(0, 0, 0))
    valGrad.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 1),
        NumberSequenceKeypoint.new(1, 0),
    })
    valGrad.Rotation = 90
    valGrad.Parent = valLayer

    local svCursor = ui("Frame", svBox, {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Size = UDim2.new(0, 14, 0, 14),
        Position = UDim2.new(sat, 0, 1 - val, 0),
        BackgroundTransparency = 1,
        ZIndex = 48,
    })
    ui("UICorner", svCursor, {CornerRadius = UDim.new(1, 0)})
    ui("UIStroke", svCursor, {Color = C.WH, Thickness = 2})

    -- Hue strip
    local hueBar = ui("Frame", panel, {
        Size = UDim2.new(1, -32, 0, 14),
        Position = UDim2.new(0, 16, 0, 182),
        BackgroundColor3 = C.WH,
        BorderSizePixel = 0,
        ZIndex = 44,
    })
    ui("UICorner", hueBar, {CornerRadius = UDim.new(0, 7)})
    local hueGrad = Instance.new("UIGradient")
    hueGrad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0.00, Color3.fromHSV(0.00, 1, 1)),
        ColorSequenceKeypoint.new(0.17, Color3.fromHSV(0.17, 1, 1)),
        ColorSequenceKeypoint.new(0.33, Color3.fromHSV(0.33, 1, 1)),
        ColorSequenceKeypoint.new(0.50, Color3.fromHSV(0.50, 1, 1)),
        ColorSequenceKeypoint.new(0.67, Color3.fromHSV(0.67, 1, 1)),
        ColorSequenceKeypoint.new(0.83, Color3.fromHSV(0.83, 1, 1)),
        ColorSequenceKeypoint.new(1.00, Color3.fromHSV(1.00, 1, 1)),
    })
    hueGrad.Parent = hueBar

    local hueKnob = ui("Frame", hueBar, {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Size = UDim2.new(0, 10, 0, 20),
        Position = UDim2.new(hue, 0, 0.5, 0),
        BackgroundColor3 = C.WH,
        BorderSizePixel = 0,
        ZIndex = 46,
    })
    ui("UICorner", hueKnob, {CornerRadius = UDim.new(0, 5)})
    ui("UIStroke", hueKnob, {Color = C.BD, Thickness = 1})

    -- Apply (GUI style: dark + outline, full width)
    local applyBtn = ui("TextButton", panel, {
        Size = UDim2.new(1, -32, 0, 34),
        Position = UDim2.new(0, 16, 0, 212),
        BackgroundColor3 = C.CDH,
        Text = "",
        BorderSizePixel = 0,
        ZIndex = 44,
    })
    ui("UICorner", applyBtn, {CornerRadius = UDim.new(0, 8)})
    ui("UIStroke", applyBtn, {Color = C.BD, Thickness = 1})
    ui("TextLabel", applyBtn, {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Text = "Apply",
        TextColor3 = C.TX,
        TextSize = 14,
        Font = FONT_BOLD,
        ZIndex = 45,
    })

    local function refresh()
        svBox.BackgroundColor3 = Color3.fromHSV(hue, 1, 1)
        svCursor.Position = UDim2.new(sat, 0, 1 - val, 0)
        hueKnob.Position = UDim2.new(hue, 0, 0.5, 0)
    end

    local svDrag, hueDrag = false, false
    local svHit = ui("TextButton", svBox, {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Text = "",
        ZIndex = 49,
    })
    local hueHit = ui("TextButton", hueBar, {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Text = "",
        ZIndex = 47,
    })

    svHit.MouseButton1Down:Connect(function(i)
        svDrag = true
        sat = math.clamp((i.Position.X - svBox.AbsolutePosition.X) / math.max(svBox.AbsoluteSize.X, 1), 0, 1)
        val = math.clamp(1 - (i.Position.Y - svBox.AbsolutePosition.Y) / math.max(svBox.AbsoluteSize.Y, 1), 0, 1)
        refresh()
    end)
    hueHit.MouseButton1Down:Connect(function(i)
        hueDrag = true
        hue = math.clamp((i.Position.X - hueBar.AbsolutePosition.X) / math.max(hueBar.AbsoluteSize.X, 1), 0, 1)
        refresh()
    end)

    -- drag the panel by its header / empty areas
    local pickerDragging, pickerStart, pickerStartPos
    panel.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then
            pickerDragging = true
            pickerStart = i.Position
            pickerStartPos = panel.Position
        end
    end)
    panel.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then pickerDragging = false end
    end)

    local moveConn = UserInputService.InputChanged:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseMovement then
            if pickerDragging then
                local d = i.Position - pickerStart
                panel.Position = UDim2.new(
                    pickerStartPos.X.Scale, pickerStartPos.X.Offset + d.X,
                    pickerStartPos.Y.Scale, pickerStartPos.Y.Offset + d.Y
                )
            elseif svDrag then
                sat = math.clamp((i.Position.X - svBox.AbsolutePosition.X) / math.max(svBox.AbsoluteSize.X, 1), 0, 1)
                val = math.clamp(1 - (i.Position.Y - svBox.AbsolutePosition.Y) / math.max(svBox.AbsoluteSize.Y, 1), 0, 1)
                refresh()
            elseif hueDrag then
                hue = math.clamp((i.Position.X - hueBar.AbsolutePosition.X) / math.max(hueBar.AbsoluteSize.X, 1), 0, 1)
                refresh()
            end
        end
    end)
    local endConn = UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then
            svDrag = false
            hueDrag = false
        end
    end)

    local closed = false
    local function close()
        if closed then return end
        closed = true
        moveConn:Disconnect()
        endConn:Disconnect()
        tw(panel, {Size = UDim2.new(0, 0, 0, 0)}, 0.2, Enum.EasingStyle.Quint, Enum.EasingDirection.In)
        tw(backdrop, {BackgroundTransparency = 1}, 0.2)
        task.delay(0.22, function()
            backdrop:Destroy()
            panel:Destroy()
        end)
    end
    backdropHit.MouseButton1Click:Connect(close)
    closeX.MouseButton1Click:Connect(close)

    applyBtn.MouseButton1Click:Connect(function()
        onApply(Color3.fromHSV(hue, sat, val))
        close()
    end)
end

local function makeColorRow(parent, text, default, cb)
    local row = ui("TextButton", parent, {Size = UDim2.new(1, 0, 0, 38), BackgroundColor3 = C.CDH, Text = "", BorderSizePixel = 0, ZIndex = 8})
    registerSearchEntry(row, parent, text)
    ui("UICorner", row, {CornerRadius = UDim.new(0, 8)})
    ui("TextLabel", row, {Size = UDim2.new(1, -58, 1, 0), Position = UDim2.new(0, 12, 0, 0), BackgroundTransparency = 1, Text = text, TextColor3 = C.TX, TextSize = 14, Font = FONT, TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Center, ZIndex = 9})
    local swatch = ui("Frame", row, {Size = UDim2.new(0, 24, 0, 24), Position = UDim2.new(1, -36, 0.5, -12), BackgroundColor3 = default or C.GR, BorderSizePixel = 0, ZIndex = 9})
    ui("UICorner", swatch, {CornerRadius = UDim.new(0, 6)})
    row.MouseButton1Click:Connect(function()
        openColorPicker(swatch.BackgroundColor3, function(col)
            tw(swatch, {BackgroundColor3 = col}, 0.2)
            if cb then cb(col) end
        end)
    end)
end

local function makeThemePicker(parent)
    local holder = ui("Frame", parent, {Size = UDim2.new(1, 0, 0, 72), BackgroundTransparency = 1, ZIndex = 8})
    registerSearchEntry(holder, parent, "Theme", "Midnight Charcoal Ash Ocean Violet appearance color")
    ui("TextLabel", holder, {Size = UDim2.new(1, 0, 0, 18), BackgroundTransparency = 1, Text = "Theme", TextColor3 = C.TX, TextSize = 14, Font = FONT_BOLD, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 9})
    local colors = {
        {"Midnight", Color3.fromRGB(15, 16, 16), Color3.fromRGB(48, 210, 128)},
        {"Charcoal", Color3.fromRGB(29, 31, 34), Color3.fromRGB(106, 180, 255)},
        {"Ash", Color3.fromRGB(57, 62, 68), Color3.fromRGB(255, 184, 92)},
        {"Ocean", Color3.fromRGB(20, 42, 58), Color3.fromRGB(74, 190, 255)},
        {"Violet", Color3.fromRGB(43, 30, 61), Color3.fromRGB(205, 132, 255)},
    }

    local function sameColor(a, b)
        return a and b and math.abs(a.R - b.R) < 0.002 and math.abs(a.G - b.G) < 0.002 and math.abs(a.B - b.B) < 0.002
    end

    local function applyTheme(base, accent)
        local old = {BG=C.BG, SB=C.SB, CT=C.CT, CD=C.CD, CDH=C.CDH, SBH=C.SBH, SBA=C.SBA, BD=C.BD, TO=C.TO, TX=C.TX, TS=C.TS, TD=C.TD}
        local nextPalette = {
            BG=base:Lerp(Color3.new(0,0,0), 0.62), SB=base:Lerp(Color3.new(0,0,0), 0.76), CT=base:Lerp(Color3.new(0,0,0), 0.48),
            CD=base:Lerp(Color3.new(1,1,1), 0.035), CDH=base:Lerp(Color3.new(1,1,1), 0.075), SBH=base:Lerp(Color3.new(1,1,1), 0.09),
            SBA=base:Lerp(Color3.new(1,1,1), 0.13), BD=base:Lerp(Color3.new(1,1,1), 0.19), TO=base:Lerp(Color3.new(1,1,1), 0.24),
            TX=base:Lerp(Color3.new(1,1,1), 0.92), TS=base:Lerp(Color3.new(1,1,1), 0.62), TD=base:Lerp(Color3.new(1,1,1), 0.38),
        }
        for _, obj in ipairs(gui:GetDescendants()) do
            for _, property in ipairs({"BackgroundColor3", "TextColor3", "ImageColor3", "Color"}) do
                local ok, current = pcall(function() return obj[property] end)
                if ok and typeof(current) == "Color3" then
                    for key, value in pairs(nextPalette) do
                        if sameColor(current, old[key]) then pcall(function() obj[property] = value end) break end
                    end
                end
            end
        end
        for key, value in pairs(nextPalette) do C[key] = value end
        ThemeAccent = accent
        mainGradient.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, C.BG),
            ColorSequenceKeypoint.new(0.55, C.CD),
            ColorSequenceKeypoint.new(1, C.SB),
        })
        contentGradient.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, C.CT:Lerp(C.GR, 0.035)),
            ColorSequenceKeypoint.new(1, C.CD),
        })
        ambientGlow.BackgroundColor3 = accent
        local ambientGradient = ambientGlow:FindFirstChildOfClass("UIGradient")
        if ambientGradient then ambientGradient.Color = ColorSequence.new(accent, accent) end
        applyAccent(accent)
        for _, fill in ipairs(ThemeFills) do
            if fill.Parent then fill.BackgroundColor3 = accent end
        end
        for _, label in ipairs(ThemeLabels) do
            if label.Parent then label.TextColor3 = accent end
        end
    end

    local themeCards = {}
    local selectedTheme = 1
    for i, item in ipairs(colors) do
        local card = ui("TextButton", holder, {
            Size = UDim2.new(0, 106, 0, 46),
            Position = UDim2.new(0, (i - 1) * 114, 0, 24),
            BackgroundColor3 = C.CD,
            Text = "",
            BorderSizePixel = 0,
            AutoButtonColor = false,
            ZIndex = 9,
        })
        ui("UICorner", card, {CornerRadius = UDim.new(0, 7)})
        local cardStroke = ui("UIStroke", card, {Color = item[3], Transparency = (i == 1) and 0 or 0.72, Thickness = (i == 1) and 1.5 or 1})
        local preview = ui("Frame", card, {Size = UDim2.new(0, 34, 0, 30), Position = UDim2.new(0, 7, 0.5, -15), BackgroundColor3 = item[2], BorderSizePixel = 0, ZIndex = 10})
        ui("UICorner", preview, {CornerRadius = UDim.new(0, 5)})
        ui("Frame", preview, {Size = UDim2.new(1, -8, 0, 3), Position = UDim2.new(0, 4, 0, 6), BackgroundColor3 = item[3], BorderSizePixel = 0, ZIndex = 11})
        ui("Frame", preview, {Size = UDim2.new(1, -12, 0, 3), Position = UDim2.new(0, 4, 0, 13), BackgroundColor3 = Color3.new(1, 1, 1), BackgroundTransparency = 0.45, BorderSizePixel = 0, ZIndex = 11})
        ui("TextLabel", card, {Size = UDim2.new(1, -50, 0, 18), Position = UDim2.new(0, 48, 0.5, -9), BackgroundTransparency = 1, Text = item[1], TextColor3 = C.TX, TextSize = 12, Font = FONT_BOLD, TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Center, ZIndex = 10})
        themeCards[i] = {card = card, stroke = cardStroke}
        card.MouseButton1Click:Connect(function()
            selectedTheme = i
            for index, data in ipairs(themeCards) do
                data.stroke.Color = colors[index][3]
                data.stroke.Transparency = index == selectedTheme and 0 or 0.72
                data.stroke.Thickness = index == selectedTheme and 1.5 or 1
            end
            applyTheme(item[2], item[3])
        end)
    end
end

-- ═══ NOTIFICATION ═══
local function notify(title, text)
    local n = ui("Frame", gui, {
        Size = UDim2.new(0, 280, 0, 56),
        Position = UDim2.new(1, 20, 1, -20),
        AnchorPoint = Vector2.new(1, 1),
        BackgroundColor3 = C.CD,
        BorderSizePixel = 0,
        ZIndex = 100,
    })
    ui("UICorner", n, {CornerRadius = UDim.new(0, 10)})
    ui("UIStroke", n, {Color = C.GR, Thickness = 1})
    ui("Frame", n, {
        Size = UDim2.new(0, 3, 0.5, 0),
        Position = UDim2.new(0, 8, 0.25, 0),
        BackgroundColor3 = C.GR,
        BorderSizePixel = 0,
        ZIndex = 101,
    })
    ui("TextLabel", n, {
        Size = UDim2.new(1, -28, 0, 20),
        Position = UDim2.new(0, 18, 0, 8),
        BackgroundTransparency = 1,
        Text = title,
        TextColor3 = C.TX,
        TextSize = 14,
    Font = FONT_BOLD,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 101,
    })
    ui("TextLabel", n, {
        Size = UDim2.new(1, -28, 0, 16),
        Position = UDim2.new(0, 18, 0, 30),
        BackgroundTransparency = 1,
        Text = text,
        TextColor3 = C.TS,
        TextSize = 12,
    Font = FONT,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 101,
    })

    n.Position = UDim2.new(1, 300, 1, -20)
    tw(n, {Position = UDim2.new(1, 20, 1, -20)}, 0.35, Enum.EasingStyle.Back)
    task.delay(3, function()
        tw(n, {Position = UDim2.new(1, 300, 1, -20), BackgroundTransparency = 0.3}, 0.25)
        task.wait(0.25)
        n:Destroy()
    end)
end


local ClickGUI = {}
ClickGUI.__index = ClickGUI
function ClickGUI.new(title)
    local self = setmetatable({Title = title or "AscendHub", Gui = gui, Window = Main}, ClickGUI)
    titleLabel.Text = self.Title
    return self
end
function ClickGUI:SetVisible(value) Main.Visible = value ~= false end
function ClickGUI:Destroy() if gui then gui:Destroy() end end
function ClickGUI:AddCategory(name, icon, color)
    navCount += 1
    local categoryIndex = navCount
    local page = makePage(name)
    local navBtn = ui("TextButton", navHolder, {Size = UDim2.new(1, 0, 0, 36), BackgroundColor3 = C.SB, BackgroundTransparency = 1, Text = "", BorderSizePixel = 0, ZIndex = 5})
    local lbl = ui("TextLabel", navBtn, {Size = UDim2.new(1, -48, 1, 0), Position = UDim2.new(0, 38, 0, 0), BackgroundTransparency = 1, Text = name, TextColor3 = C.TS, TextSize = 14, Font = FONT, TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Center, ZIndex = 6})
    local iconObj = ui("ImageLabel", navBtn, {Size = UDim2.new(0, 20, 0, 20), Position = UDim2.new(0, 12, 0.5, -10), BackgroundTransparency = 1, Image = resolveIcon(icon, name), ImageColor3 = color or C.TX, ImageTransparency = 0.05, ScaleType = Enum.ScaleType.Fit, ZIndex = 6})
    local data = {Name = name, Page = page, Button = navBtn}
    NavButtons[name] = {btn = navBtn, lbl = lbl, icon = iconObj}
    navBtn.MouseButton1Click:Connect(function()
        for pageName, otherPage in pairs(Pages) do
            otherPage.Visible = pageName == name
        end
        for _, item in pairs(NavButtons) do
            item.btn.BackgroundColor3 = C.SB
            item.btn.BackgroundTransparency = 1
            item.lbl.TextColor3 = C.TS
            item.icon.ImageColor3 = C.TS
        end
        lbl.TextColor3 = C.TX
        iconObj.ImageColor3 = C.TX
        activePage = name
        ContentScroll.CanvasPosition = Vector2.new(0, 0)
        moveNavSelection(categoryIndex)
    end)
    if activePage == nil then
        activePage = name
        page.Visible = true
        lbl.TextColor3 = C.TX
        iconObj.ImageColor3 = C.TX
        moveNavSelection(categoryIndex, true)
    end
    function data:AddSection(title, desc)
        local content = makeSection(page, title, desc)
        local section = {Frame = content}
        function section:AddLabel(text)
            local label = ui("TextLabel", content, {Size = UDim2.new(1, 0, 0, 28), BackgroundTransparency = 1, Text = tostring(text or ""), TextColor3 = C.TS, TextSize = 13, Font = FONT, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 8})
            return {SetText = function(_, value) label.Text = tostring(value or "") end}
        end
        function section:AddToggle(text, default, cb) return makeToggle(content, text, nil, default, cb) end
        function section:AddButton(text, cb) return makeButton(content, text, nil, cb) end
        function section:AddSlider(text, min, max, default, suffix, cb) return makeSlider(content, text, min, max, default, suffix or "", cb) end
        function section:AddDropdown(text, options, default, cb) return makeDropdown(content, text, options, default, cb) end
        function section:AddInput(text, initial, placeholder, cb) return makeTextInput(content, text, initial, placeholder, cb) end
        return section
    end
    function data:AddLabel(text) return data:AddSection(nil, nil):AddLabel(text) end
    function data:AddToggle(text, default, cb) return data:AddSection(nil, nil):AddToggle(text, default, cb) end
    function data:AddButton(text, cb) return data:AddSection(nil, nil):AddButton(text, cb) end
    function data:AddSlider(text, min, max, default, suffix, cb) return data:AddSection(nil, nil):AddSlider(text, min, max, default, suffix, cb) end
    function data:AddDropdown(text, options, default, cb) return data:AddSection(nil, nil):AddDropdown(text, options, default, cb) end
    function data:AddInput(text, initial, placeholder, cb) return data:AddSection(nil, nil):AddInput(text, initial, placeholder, cb) end
    return data
end
function ClickGUI:Notify(title, message, duration) notify(title, message, duration) end
local function makeLabel(parent, text)
    local section = makeSection(parent, nil, nil)
    local label = ui("TextLabel", section, {Size = UDim2.new(1, 0, 0, 28), BackgroundTransparency = 1, Text = tostring(text or ""), TextColor3 = C.TS, TextSize = 13, Font = FONT, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 8})
    return {SetText = function(_, value) label.Text = tostring(value or "") end}
end
return ClickGUI


