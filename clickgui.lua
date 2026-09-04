-- AscendHub ClickGUI library (original visual core)
-- Usage: local GUI = loadstring(game:HttpGet(URL))(); local ui = GUI.new("My Hub")

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local Library = {}
Library.__index = Library

local C = {
    bg = Color3.fromRGB(15, 16, 16), sidebar = Color3.fromRGB(13, 14, 14),
    surface = Color3.fromRGB(20, 21, 21), hover = Color3.fromRGB(31, 32, 32),
    text = Color3.fromRGB(235, 236, 234), muted = Color3.fromRGB(164, 166, 163),
    dim = Color3.fromRGB(103, 106, 103), accent = Color3.fromRGB(48, 210, 128),
    border = Color3.fromRGB(48, 50, 49), red = Color3.fromRGB(242, 92, 88),
}

local function make(className, parent, props)
    local object = Instance.new(className)
    for key, value in pairs(props or {}) do object[key] = value end
    object.Parent = parent
    if object:IsA("TextButton") then object.AutoButtonColor = false end
    return object
end

local function corner(parent, radius)
    return make("UICorner", parent, { CornerRadius = UDim.new(0, radius or 8) })
end

local function tween(object, props, duration)
    local animation = TweenService:Create(object, TweenInfo.new(duration or 0.18, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), props)
    animation:Play()
    return animation
end

function Library.new(title)
    local self = setmetatable({ title = title or "AscendHub", categories = {}, selected = nil }, Library)
    local player = Players.LocalPlayer
    local gui = make("ScreenGui", player:WaitForChild("PlayerGui"), {
        Name = "AscendHubClickGUI", ResetOnSpawn = false, IgnoreGuiInset = true,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling, DisplayOrder = 999,
    })
    self.Gui = gui
    local window = make("Frame", gui, {
        AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromOffset(900, 540), BackgroundColor3 = C.bg, BorderSizePixel = 0,
        ClipsDescendants = true,
    })
    corner(window, 12)
    make("UIStroke", window, { Color = C.border, Thickness = 1.5 })
    self.Window = window
    local titlebar = make("Frame", window, { Size = UDim2.new(1, 0, 0, 54), BackgroundColor3 = C.sidebar, BorderSizePixel = 0 })
    make("TextLabel", titlebar, { Size = UDim2.new(1, -90, 1, 0), Position = UDim2.fromOffset(18, 0), BackgroundTransparency = 1, Text = self.title, TextColor3 = C.text, TextSize = 17, Font = Enum.Font.GothamBold, TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Center })
    local close = make("TextButton", titlebar, { Size = UDim2.fromOffset(26, 26), Position = UDim2.new(1, -38, 0, 14), BackgroundColor3 = C.red, Text = "", BorderSizePixel = 0 })
    corner(close, 13)
    close.MouseButton1Click:Connect(function() self:Destroy() end)
    local minimize = make("TextButton", titlebar, { Size = UDim2.fromOffset(26, 26), Position = UDim2.new(1, -72, 0, 14), BackgroundColor3 = C.muted, Text = "", BorderSizePixel = 0 })
    corner(minimize, 13)
    local sidebar = make("Frame", window, { Position = UDim2.fromOffset(0, 54), Size = UDim2.new(0, 190, 1, -54), BackgroundColor3 = C.sidebar, BorderSizePixel = 0 })
    local nav = make("ScrollingFrame", sidebar, { Position = UDim2.fromOffset(10, 12), Size = UDim2.new(1, -20, 1, -24), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 2, CanvasSize = UDim2.new() })
    make("UIListLayout", nav, { Padding = UDim.new(0, 5), SortOrder = Enum.SortOrder.LayoutOrder })
    local content = make("Frame", window, { Position = UDim2.fromOffset(190, 54), Size = UDim2.new(1, -190, 1, -54), BackgroundColor3 = C.bg, BorderSizePixel = 0 })
    self._nav, self._content, self._minimize = nav, content, minimize
    local dragging, dragStart, windowStart
    titlebar.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging, dragStart, windowStart = true, input.Position, window.Position end end)
    UserInputService.InputEnded:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end end)
    UserInputService.InputChanged:Connect(function(input) if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then local delta = input.Position - dragStart; window.Position = UDim2.new(windowStart.X.Scale, windowStart.X.Offset + delta.X, windowStart.Y.Scale, windowStart.Y.Offset + delta.Y) end end)
    minimize.MouseButton1Click:Connect(function() self._collapsed = not self._collapsed; content.Visible = not self._collapsed; sidebar.Visible = not self._collapsed; window.Size = self._collapsed and UDim2.fromOffset(420, 54) or UDim2.fromOffset(900, 540) end)
    self._visible = true
    return self
end

function Library:SetVisible(visible)
    self._visible = visible ~= false
    self.Window.Visible = self._visible
end

function Library:Destroy()
    if self.Gui then self.Gui:Destroy() end
end

function Library:AddCategory(name)
    local page = make("ScrollingFrame", self._content, { Name = name, Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 3, CanvasSize = UDim2.new() })
    local padding = make("UIPadding", page, { PaddingTop = UDim.new(0, 16), PaddingLeft = UDim.new(0, 18), PaddingRight = UDim.new(0, 18), PaddingBottom = UDim.new(0, 16) })
    local list = make("UIListLayout", page, { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder })
    list:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function() page.CanvasSize = UDim2.fromOffset(0, list.AbsoluteContentSize.Y + 32) end)
    local button = make("TextButton", self._nav, { Size = UDim2.new(1, 0, 0, 36), BackgroundColor3 = C.sidebar, Text = name, TextColor3 = C.muted, TextSize = 14, Font = Enum.Font.Gotham, BorderSizePixel = 0 })
    corner(button, 7)
    local category = { Name = name, Page = page, Button = button, Gui = self }
    table.insert(self.categories, category)
    function category:_row(label, height)
        return make("Frame", page, { Size = UDim2.new(1, 0, 0, height or 46), BackgroundColor3 = C.surface, BorderSizePixel = 0 })
    end
    function category:AddLabel(text)
        local row = self:_row(text, 32); make("TextLabel", row, { Size = UDim2.new(1, -20, 1, 0), Position = UDim2.fromOffset(10, 0), BackgroundTransparency = 1, Text = text, TextColor3 = C.muted, TextSize = 13, Font = Enum.Font.Gotham, TextXAlignment = Enum.TextXAlignment.Left }); return row
    end
    function category:AddButton(text, callback)
        local row = self:_row(text, 42); local button = make("TextButton", row, { Size = UDim2.new(1, -16, 1, -10), Position = UDim2.fromOffset(8, 5), BackgroundColor3 = C.hover, Text = text, TextColor3 = C.text, TextSize = 13, Font = Enum.Font.Gotham, BorderSizePixel = 0 }); corner(button, 6); button.MouseButton1Click:Connect(function() if callback then callback() end end); return button
    end
    function category:AddToggle(text, default, callback)
        local row = self:_row(text); make("TextLabel", row, { Size = UDim2.new(1, -72, 1, 0), Position = UDim2.fromOffset(12, 0), BackgroundTransparency = 1, Text = text, TextColor3 = C.text, TextSize = 13, Font = Enum.Font.Gotham, TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Center }); local hit = make("TextButton", row, { Size = UDim2.fromOffset(42, 22), Position = UDim2.new(1, -54, 0.5, -11), BackgroundColor3 = default and C.accent or C.hover, Text = "", BorderSizePixel = 0 }); corner(hit, 11); local state = default == true; local control = { Value = state, Set = function(_, value) state = value == true; control.Value = state; hit.BackgroundColor3 = state and C.accent or C.hover; if callback then callback(state) end end }; hit.MouseButton1Click:Connect(function() control:Set(not state) end); return control
    end
    function category:AddSlider(text, min, max, default, callback)
        local row = self:_row(text, 60); make("TextLabel", row, { Size = UDim2.new(1, -24, 0, 24), Position = UDim2.fromOffset(12, 4), BackgroundTransparency = 1, Text = text, TextColor3 = C.text, TextSize = 13, Font = Enum.Font.Gotham, TextXAlignment = Enum.TextXAlignment.Left }); local input = make("TextBox", row, { Size = UDim2.fromOffset(70, 24), Position = UDim2.new(1, -82, 0, 4), BackgroundTransparency = 1, Text = tostring(default or min), TextColor3 = C.muted, TextSize = 13, Font = Enum.Font.Gotham, ClearTextOnFocus = false }); local box = make("Frame", row, { Position = UDim2.fromOffset(12, 38), Size = UDim2.new(1, -24, 0, 5), BackgroundColor3 = C.hover, BorderSizePixel = 0 }); corner(box, 3); local fill = make("Frame", box, { Size = UDim2.new(((default or min) - min) / (max - min), 0, 1, 0), BackgroundColor3 = C.accent, BorderSizePixel = 0 }); corner(fill, 3); local control = { Value = default or min }; function control:Set(value) self.Value = math.clamp(tonumber(value) or min, min, max); input.Text = tostring(self.Value); fill.Size = UDim2.new((self.Value - min) / (max - min), 0, 1, 0); if callback then callback(self.Value) end end; input.FocusLost:Connect(function() control:Set(input.Text) end); return control
    end
    function category:AddDropdown(text, options, default, callback)
        local row = self:_row(text, 46); make("TextLabel", row, { Size = UDim2.new(0.5, 0, 1, 0), Position = UDim2.fromOffset(12, 0), BackgroundTransparency = 1, Text = text, TextColor3 = C.text, TextSize = 13, Font = Enum.Font.Gotham, TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Center }); local selected = default or options[1]; local button = make("TextButton", row, { Size = UDim2.fromOffset(150, 28), Position = UDim2.new(1, -162, 0.5, -14), BackgroundColor3 = C.hover, Text = tostring(selected), TextColor3 = C.text, TextSize = 12, Font = Enum.Font.Gotham, BorderSizePixel = 0 }); corner(button, 6); local index = table.find(options, selected) or 1; local control = { Value = selected }; button.MouseButton1Click:Connect(function() index = index % #options + 1; control.Value = options[index]; button.Text = tostring(control.Value); if callback then callback(control.Value) end end); return control
    end
    function category:AddInput(text, default, placeholder, callback)
        local row = self:_row(text, 46); make("TextLabel", row, { Size = UDim2.new(0.45, 0, 1, 0), Position = UDim2.fromOffset(12, 0), BackgroundTransparency = 1, Text = text, TextColor3 = C.text, TextSize = 13, Font = Enum.Font.Gotham, TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Center }); local input = make("TextBox", row, { Size = UDim2.fromOffset(180, 28), Position = UDim2.new(1, -192, 0.5, -14), BackgroundColor3 = C.hover, Text = tostring(default or ""), PlaceholderText = placeholder or "", PlaceholderColor3 = C.dim, TextColor3 = C.text, TextSize = 12, Font = Enum.Font.Gotham, ClearTextOnFocus = false, BorderSizePixel = 0 }); corner(input, 6); local control = { Value = input.Text }; input.FocusLost:Connect(function() control.Value = input.Text; if callback then callback(input.Text) end end); return control
    end
    button.MouseButton1Click:Connect(function() self:SelectCategory(category) end)
    if #self.categories == 1 then self:SelectCategory(category) end
    return category
end

function Library:SelectCategory(category)
    for _, item in ipairs(self.categories) do item.Page.Visible = item == category; item.Button.BackgroundColor3 = item == category and C.hover or C.sidebar; item.Button.TextColor3 = item == category and C.text or C.muted end
    self.selected = category
end

function Library:Notify(title, message, duration)
    local toast = make("TextLabel", self.Gui, { AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -22, 1, -22), Size = UDim2.fromOffset(280, 54), BackgroundColor3 = C.surface, Text = tostring(title or "AscendHub") .. "\n" .. tostring(message or ""), TextColor3 = C.text, TextSize = 13, Font = Enum.Font.Gotham, TextWrapped = true, ZIndex = 20 })
    corner(toast, 8)
    task.delay(duration or 3, function() if toast.Parent then tween(toast, { BackgroundTransparency = 1, TextTransparency = 1 }, 0.2); task.wait(0.25); toast:Destroy() end end)
end

return Library
