--[[
    VANZ // PREMIUM CONTROL CENTER
    UI VERSION 4

    FIXES:
    - Sidebar tabs fixed
    - Sidebar punya scrolling sendiri
    - Content tidak menutupi tab
    - Minimize benar-benar hide semua visual
    - Restore animation
    - Close / FORCE STOP
    - Semua registered connections diputus
    - Semua registered cleanup dijalankan
    - GUI dihancurkan
    - Animation loops dihentikan
    - Bisa rerun script dengan bersih

    GUI ONLY
]]

--//========================================================
--// SERVICES
--//========================================================

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer

--//========================================================
--// GLOBAL
--//========================================================

_G.vanz = _G.vanz or {}

--========================================================
-- CONFIG
--========================================================

_G.vanz.Config = {
    Title = "VANZ",
    Subtitle = "PREMIUM CONTROL CENTER",

    -- Default 100%
    Scale = 1.00,

    DynamicColors = true,

    -- Sidebar
    SidebarWidth = 205,

    -- Window
    DefaultWidth = 820,
    DefaultHeight = 520,

    -- Responsive margins
    ScreenMargin = 22,
}

--========================================================
-- FORCE CLEAN OLD VERSION
--========================================================

do
    local old = _G.vanz

    if old then
        -- Disconnect old connections
        if old.Connections then
            for _, connection in pairs(old.Connections) do
                if typeof(connection) == "RBXScriptConnection" then
                    pcall(function()
                        connection:Disconnect()
                    end)
                end
            end
        end

        -- Run old cleanup functions
        if old.Cleanups then
            for _, cleanup in pairs(old.Cleanups) do
                if typeof(cleanup) == "function" then
                    pcall(cleanup)
                end
            end
        end

        -- Destroy old GUI
        if old.UI and old.UI.Gui then
            pcall(function()
                old.UI.Gui:Destroy()
            end)
        end

        local playerGui = LocalPlayer:FindFirstChildOfClass("PlayerGui")

        if playerGui then
            local oldGui = playerGui:FindFirstChild("VANZ_PREMIUM_GUI")

            if oldGui then
                pcall(function()
                    oldGui:Destroy()
                end)
            end
        end
    end
end

-- Reset runtime
_G.vanz.Connections = {}
_G.vanz.Cleanups = {}
_G.vanz.UI = {}
_G.vanz.State = {
    Open = true,
    Closed = false,
    Destroyed = false,
}

--========================================================
-- CONNECTION / CLEANUP SYSTEM
--========================================================

local Connections = _G.vanz.Connections
local Cleanups = _G.vanz.Cleanups

local function RegisterConnection(connection)
    if connection then
        table.insert(Connections, connection)
    end

    return connection
end

local function RegisterCleanup(callback)
    if typeof(callback) == "function" then
        table.insert(Cleanups, callback)
    end

    return callback
end

local function DisconnectAll()
    for i = #Connections, 1, -1 do
        local connection = Connections[i]

        if typeof(connection) == "RBXScriptConnection" then
            pcall(function()
                connection:Disconnect()
            end)
        end

        Connections[i] = nil
    end
end

local function RunAllCleanups()
    for i = #Cleanups, 1, -1 do
        local cleanup = Cleanups[i]

        if typeof(cleanup) == "function" then
            pcall(cleanup)
        end

        Cleanups[i] = nil
    end
end

-- Public API
_G.vanz.RegisterConnection = RegisterConnection
_G.vanz.RegisterCleanup = RegisterCleanup

--========================================================
-- COLORS
--========================================================

local Colors = {
    Background = Color3.fromRGB(8, 10, 15),
    Sidebar = Color3.fromRGB(11, 14, 21),
    Panel = Color3.fromRGB(15, 18, 27),

    PanelLight = Color3.fromRGB(20, 24, 34),

    Text = Color3.fromRGB(240, 243, 250),
    TextMuted = Color3.fromRGB(145, 151, 166),

    Accent = Color3.fromRGB(95, 125, 255),
    Accent2 = Color3.fromRGB(170, 90, 255),

    Success = Color3.fromRGB(75, 220, 145),
    Danger = Color3.fromRGB(255, 85, 105),

    Stroke = Color3.fromRGB(42, 48, 65),
    Divider = Color3.fromRGB(31, 36, 49),

    Black = Color3.fromRGB(0, 0, 0),
}

_G.vanz.UI.Colors = Colors

--========================================================
-- HELPERS
--========================================================

local function New(className, properties)
    local object = Instance.new(className)

    for property, value in pairs(properties or {}) do
        pcall(function()
            object[property] = value
        end)
    end

    return object
end

local function Corner(parent, radius)
    return New("UICorner", {
        Parent = parent,
        CornerRadius = UDim.new(0, radius or 10),
    })
end

local function Stroke(parent, color, thickness, transparency)
    return New("UIStroke", {
        Parent = parent,
        Color = color or Colors.Stroke,
        Thickness = thickness or 1,
        Transparency = transparency or 0,
    })
end

local function Padding(parent, left, right, top, bottom)
    return New("UIPadding", {
        Parent = parent,

        PaddingLeft = UDim.new(0, left or 0),
        PaddingRight = UDim.new(0, right or 0),
        PaddingTop = UDim.new(0, top or 0),
        PaddingBottom = UDim.new(0, bottom or 0),
    })
end

local function Tween(object, properties, duration, style, direction)
    if not object or not object.Parent then
        return
    end

    local tween = TweenService:Create(
        object,
        TweenInfo.new(
            duration or 0.25,
            style or Enum.EasingStyle.Quint,
            direction or Enum.EasingDirection.Out
        ),
        properties
    )

    tween:Play()

    return tween
end

--========================================================
-- DESTROY CHECK
--========================================================

local function IsDead()
    return _G.vanz.State.Destroyed or _G.vanz.State.Closed
end

--========================================================
-- SCREEN GUI
--========================================================

local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local ScreenGui = New("ScreenGui", {
    Name = "VANZ_PREMIUM_GUI",
    Parent = PlayerGui,

    ResetOnSpawn = false,
    IgnoreGuiInset = true,

    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
})

_G.vanz.UI.Gui = ScreenGui

--========================================================
-- SCALE
--========================================================

local UIScale = New("UIScale", {
    Parent = ScreenGui,
    Scale = _G.vanz.Config.Scale,
})

_G.vanz.UI.UIScale = UIScale

--========================================================
-- MAIN HOLDER
--========================================================

local MainHolder = New("Frame", {
    Name = "MainHolder",
    Parent = ScreenGui,

    AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.fromScale(0.5, 0.5),

    Size = UDim2.fromOffset(
        _G.vanz.Config.DefaultWidth,
        _G.vanz.Config.DefaultHeight
    ),

    BackgroundTransparency = 1,

    Visible = true,
    ZIndex = 10,
})

_G.vanz.UI.Main = MainHolder

--========================================================
-- SHADOW
--========================================================

local Shadow = New("ImageLabel", {
    Name = "Shadow",
    Parent = MainHolder,

    AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.new(0.5, 0, 0.5, 7),

    Size = UDim2.new(1, 60, 1, 60),

    BackgroundTransparency = 1,

    Image = "rbxassetid://1316045217",
    ImageColor3 = Colors.Black,

    ImageTransparency = 0.45,

    ScaleType = Enum.ScaleType.Slice,
    SliceCenter = Rect.new(10, 10, 118, 118),

    ZIndex = 8,
})

_G.vanz.UI.Shadow = Shadow

--========================================================
-- OUTER GLOW
--========================================================

local OuterGlow = New("Frame", {
    Name = "OuterGlow",
    Parent = MainHolder,

    AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.fromScale(0.5, 0.5),

    Size = UDim2.new(1, 12, 1, 12),

    BackgroundColor3 = Colors.Accent,
    BackgroundTransparency = 0.88,

    ZIndex = 9,
})

Corner(OuterGlow, 18)

--========================================================
-- MAIN PANEL
--========================================================

local MainPanel = New("Frame", {
    Name = "MainPanel",
    Parent = MainHolder,

    Size = UDim2.fromScale(1, 1),

    BackgroundColor3 = Colors.Background,
    BackgroundTransparency = 0,

    ClipsDescendants = true,

    ZIndex = 10,
})

Corner(MainPanel, 16)
Stroke(MainPanel, Colors.Stroke, 1, 0.15)

_G.vanz.UI.MainPanel = MainPanel

--========================================================
-- HEADER
--========================================================

local Header = New("Frame", {
    Name = "Header",
    Parent = MainPanel,

    Position = UDim2.fromOffset(0, 0),

    Size = UDim2.new(1, 0, 0, 72),

    BackgroundColor3 = Colors.Panel,
    BackgroundTransparency = 0,

    ZIndex = 30,
})

Corner(Header, 16)

local HeaderMask = New("Frame", {
    Name = "HeaderMask",
    Parent = Header,

    Position = UDim2.fromOffset(0, 35),

    Size = UDim2.new(1, 0, 0, 40),

    BackgroundColor3 = Colors.Panel,
    BorderSizePixel = 0,

    ZIndex = 30,
})

--========================================================
-- LOGO
--========================================================

local Logo = New("Frame", {
    Name = "Logo",
    Parent = Header,

    Position = UDim2.fromOffset(18, 16),

    Size = UDim2.fromOffset(40, 40),

    BackgroundColor3 = Colors.Accent,

    ZIndex = 32,
})

Corner(Logo, 12)

local LogoText = New("TextLabel", {
    Parent = Logo,

    Size = UDim2.fromScale(1, 1),

    BackgroundTransparency = 1,

    Text = "V",

    TextColor3 = Colors.Text,
    TextSize = 21,
    Font = Enum.Font.GothamBold,

    ZIndex = 33,
})

--========================================================
-- TITLE
--========================================================

local Title = New("TextLabel", {
    Name = "Title",
    Parent = Header,

    Position = UDim2.fromOffset(70, 14),

    Size = UDim2.new(0.5, 0, 0, 24),

    BackgroundTransparency = 1,

    Text = _G.vanz.Config.Title,
    TextColor3 = Colors.Text,

    TextSize = 19,
    Font = Enum.Font.GothamBold,

    TextXAlignment = Enum.TextXAlignment.Left,

    ZIndex = 32,
})

local Subtitle = New("TextLabel", {
    Name = "Subtitle",
    Parent = Header,

    Position = UDim2.fromOffset(70, 37),

    Size = UDim2.new(0.5, 0, 0, 18),

    BackgroundTransparency = 1,

    Text = _G.vanz.Config.Subtitle,

    TextColor3 = Colors.TextMuted,

    TextSize = 10,
    Font = Enum.Font.GothamMedium,

    TextXAlignment = Enum.TextXAlignment.Left,

    ZIndex = 32,
})

--========================================================
-- ONLINE STATUS
--========================================================

local Status = New("Frame", {
    Name = "Status",
    Parent = Header,

    AnchorPoint = Vector2.new(1, 0.5),
    Position = UDim2.new(1, -100, 0.5, 0),

    Size = UDim2.fromOffset(78, 30),

    BackgroundColor3 = Colors.PanelLight,

    ZIndex = 32,
})

Corner(Status, 9)
Stroke(Status, Colors.Stroke, 1, 0.25)

local StatusDot = New("Frame", {
    Parent = Status,

    Position = UDim2.fromOffset(9, 11),

    Size = UDim2.fromOffset(8, 8),

    BackgroundColor3 = Colors.Success,

    ZIndex = 33,
})

Corner(StatusDot, 10)

local StatusText = New("TextLabel", {
    Parent = Status,

    Position = UDim2.fromOffset(23, 0),

    Size = UDim2.new(1, -25, 1, 0),

    BackgroundTransparency = 1,

    Text = "ONLINE",

    TextColor3 = Colors.Text,

    TextSize = 9,
    Font = Enum.Font.GothamBold,

    TextXAlignment = Enum.TextXAlignment.Left,

    ZIndex = 33,
})

--========================================================
-- MINIMIZE BUTTON
--========================================================

local MinimizeButton = New("TextButton", {
    Name = "Minimize",
    Parent = Header,

    AnchorPoint = Vector2.new(1, 0.5),
    Position = UDim2.new(1, -48, 0.5, 0),

    Size = UDim2.fromOffset(32, 32),

    BackgroundColor3 = Colors.PanelLight,

    Text = "—",

    TextColor3 = Colors.TextMuted,
    TextSize = 18,
    Font = Enum.Font.GothamBold,

    AutoButtonColor = false,

    ZIndex = 35,
})

Corner(MinimizeButton, 9)
Stroke(MinimizeButton, Colors.Stroke, 1, 0.2)

--========================================================
-- CLOSE BUTTON
--========================================================

local CloseButton = New("TextButton", {
    Name = "Close",
    Parent = Header,

    AnchorPoint = Vector2.new(1, 0.5),
    Position = UDim2.new(1, -10, 0.5, 0),

    Size = UDim2.fromOffset(32, 32),

    BackgroundColor3 = Colors.PanelLight,

    Text = "×",

    TextColor3 = Colors.TextMuted,
    TextSize = 21,
    Font = Enum.Font.GothamBold,

    AutoButtonColor = false,

    ZIndex = 35,
})

Corner(CloseButton, 9)
Stroke(CloseButton, Colors.Stroke, 1, 0.2)

--========================================================
-- BODY
--========================================================

local Body = New("Frame", {
    Name = "Body",
    Parent = MainPanel,

    Position = UDim2.fromOffset(0, 72),

    Size = UDim2.new(1, 0, 1, -72),

    BackgroundTransparency = 1,

    ClipsDescendants = true,

    ZIndex = 20,
})

--========================================================
-- SIDEBAR
--========================================================

local Sidebar = New("Frame", {
    Name = "Sidebar",
    Parent = Body,

    Position = UDim2.fromOffset(0, 0),

    Size = UDim2.new(
        0,
        _G.vanz.Config.SidebarWidth,
        1,
        0
    ),

    BackgroundColor3 = Colors.Sidebar,

    BorderSizePixel = 0,

    ZIndex = 21,
})

_G.vanz.UI.Sidebar = Sidebar

-- Divider
local SidebarDivider = New("Frame", {
    Parent = Body,

    Position = UDim2.new(
        0,
        _G.vanz.Config.SidebarWidth,
        0,
        0
    ),

    Size = UDim2.fromOffset(1, 9999),

    BackgroundColor3 = Colors.Divider,

    BorderSizePixel = 0,

    ZIndex = 25,
})

--========================================================
-- SIDEBAR HEADER
--========================================================

local SidebarHeader = New("TextLabel", {
    Parent = Sidebar,

    Position = UDim2.fromOffset(16, 14),

    Size = UDim2.new(1, -32, 0, 22),

    BackgroundTransparency = 1,

    Text = "NAVIGATION",

    TextColor3 = Colors.TextMuted,

    TextSize = 9,
    Font = Enum.Font.GothamBold,

    TextXAlignment = Enum.TextXAlignment.Left,

    ZIndex = 23,
})

--========================================================
-- SIDEBAR SCROLL
--========================================================

local SidebarScroll = New("ScrollingFrame", {
    Name = "TabScroll",
    Parent = Sidebar,

    Position = UDim2.fromOffset(8, 43),

    Size = UDim2.new(1, -16, 1, -51),

    BackgroundTransparency = 1,

    BorderSizePixel = 0,

    CanvasSize = UDim2.fromOffset(0, 0),

    AutomaticCanvasSize = Enum.AutomaticSize.Y,

    ScrollingDirection = Enum.ScrollingDirection.Y,

    ScrollBarThickness = 3,

    ScrollBarImageColor3 = Colors.Accent,
    ScrollBarImageTransparency = 0.2,

    ScrollingEnabled = true,

    ClipsDescendants = true,

    ZIndex = 22,
})

Padding(SidebarScroll, 2, 5, 2, 10)

local TabLayout = New("UIListLayout", {
    Parent = SidebarScroll,

    Padding = UDim.new(0, 7),

    SortOrder = Enum.SortOrder.LayoutOrder,
})

TabLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center

--========================================================
-- CONTENT AREA
--========================================================

local Content = New("Frame", {
    Name = "Content",
    Parent = Body,

    Position = UDim2.new(
        0,
        _G.vanz.Config.SidebarWidth + 1,
        0,
        0
    ),

    Size = UDim2.new(
        1,
        -(_G.vanz.Config.SidebarWidth + 1),
        1,
        0
    ),

    BackgroundColor3 = Colors.Background,

    BorderSizePixel = 0,

    ClipsDescendants = true,

    ZIndex = 20,
})

_G.vanz.UI.Content = Content

--========================================================
-- PAGE SYSTEM
--========================================================

local Pages = {}
local Tabs = {}
local CurrentPage = nil

local function CreatePage(name)
    local page = New("ScrollingFrame", {
        Name = name .. "Page",
        Parent = Content,

        Position = UDim2.fromOffset(0, 0),

        Size = UDim2.fromScale(1, 1),

        BackgroundTransparency = 1,

        BorderSizePixel = 0,

        CanvasSize = UDim2.fromOffset(0, 0),

        AutomaticCanvasSize = Enum.AutomaticSize.Y,

        ScrollingDirection = Enum.ScrollingDirection.Y,

        ScrollBarThickness = 4,

        ScrollBarImageColor3 = Colors.Accent,
        ScrollBarImageTransparency = 0.25,

        Visible = false,

        ClipsDescendants = true,

        ZIndex = 22,
    })

    Padding(page, 18, 18, 18, 24)

    local layout = New("UIListLayout", {
        Parent = page,

        Padding = UDim.new(0, 12),

        SortOrder = Enum.SortOrder.LayoutOrder,
    })

    layout.HorizontalAlignment = Enum.HorizontalAlignment.Center

    Pages[name] = page

    return page
end

--========================================================
-- SECTION
--========================================================

local function CreateSection(parent, title, description)
    local holder = New("Frame", {
        Parent = parent,

        Size = UDim2.new(1, 0, 0, description and 55 or 35),

        BackgroundTransparency = 1,

        ZIndex = 23,
    })

    local titleLabel = New("TextLabel", {
        Parent = holder,

        Position = UDim2.fromOffset(0, 0),

        Size = UDim2.new(1, 0, 0, 22),

        BackgroundTransparency = 1,

        Text = title,

        TextColor3 = Colors.Text,

        TextSize = 15,
        Font = Enum.Font.GothamBold,

        TextXAlignment = Enum.TextXAlignment.Left,

        ZIndex = 24,
    })

    if description then
        local desc = New("TextLabel", {
            Parent = holder,

            Position = UDim2.fromOffset(0, 24),

            Size = UDim2.new(1, 0, 0, 28),

            BackgroundTransparency = 1,

            Text = description,

            TextColor3 = Colors.TextMuted,

            TextSize = 10,
            Font = Enum.Font.GothamMedium,

            TextXAlignment = Enum.TextXAlignment.Left,

            TextWrapped = true,

            ZIndex = 24,
        })
    end

    return holder
end

--========================================================
-- INFO CARD
--========================================================

local function CreateInfo(parent, title, text)
    local card = New("Frame", {
        Parent = parent,

        Size = UDim2.new(1, 0, 0, 68),

        BackgroundColor3 = Colors.Panel,

        ZIndex = 23,
    })

    Corner(card, 11)
    Stroke(card, Colors.Stroke, 1, 0.3)

    local titleLabel = New("TextLabel", {
        Parent = card,

        Position = UDim2.fromOffset(14, 10),

        Size = UDim2.new(1, -28, 0, 18),

        BackgroundTransparency = 1,

        Text = title,

        TextColor3 = Colors.Text,

        TextSize = 12,
        Font = Enum.Font.GothamBold,

        TextXAlignment = Enum.TextXAlignment.Left,

        ZIndex = 24,
    })

    local body = New("TextLabel", {
        Parent = card,

        Position = UDim2.fromOffset(14, 30),

        Size = UDim2.new(1, -28, 0, 28),

        BackgroundTransparency = 1,

        Text = text,

        TextColor3 = Colors.TextMuted,

        TextSize = 10,
        Font = Enum.Font.GothamMedium,

        TextWrapped = true,

        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top,

        ZIndex = 24,
    })

    return card
end

--========================================================
-- BUTTON
--========================================================

local function CreateButton(parent, title, description, callback)
    local button = New("TextButton", {
        Parent = parent,

        Size = UDim2.new(1, 0, 0, 58),

        BackgroundColor3 = Colors.Panel,

        Text = "",

        AutoButtonColor = false,

        ZIndex = 24,
    })

    Corner(button, 11)
    Stroke(button, Colors.Stroke, 1, 0.25)

    local titleLabel = New("TextLabel", {
        Parent = button,

        Position = UDim2.fromOffset(14, 8),

        Size = UDim2.new(1, -70, 0, 20),

        BackgroundTransparency = 1,

        Text = title,

        TextColor3 = Colors.Text,

        TextSize = 12,
        Font = Enum.Font.GothamBold,

        TextXAlignment = Enum.TextXAlignment.Left,

        ZIndex = 25,
    })

    if description then
        New("TextLabel", {
            Parent = button,

            Position = UDim2.fromOffset(14, 29),

            Size = UDim2.new(1, -70, 0, 18),

            BackgroundTransparency = 1,

            Text = description,

            TextColor3 = Colors.TextMuted,

            TextSize = 9,
            Font = Enum.Font.GothamMedium,

            TextXAlignment = Enum.TextXAlignment.Left,

            ZIndex = 25,
        })
    end

    local arrow = New("TextLabel", {
        Parent = button,

        AnchorPoint = Vector2.new(1, 0.5),

        Position = UDim2.new(1, -15, 0.5, 0),

        Size = UDim2.fromOffset(22, 22),

        BackgroundTransparency = 1,

        Text = "›",

        TextColor3 = Colors.TextMuted,

        TextSize = 20,
        Font = Enum.Font.GothamBold,

        ZIndex = 25,
    })

    RegisterConnection(button.MouseEnter:Connect(function()
        if IsDead() then
            return
        end

        Tween(button, {
            BackgroundColor3 = Colors.PanelLight,
        }, 0.15)

        Tween(arrow, {
            TextColor3 = Colors.Accent,
            Position = UDim2.new(1, -12, 0.5, 0),
        }, 0.15)
    end))

    RegisterConnection(button.MouseLeave:Connect(function()
        if IsDead() then
            return
        end

        Tween(button, {
            BackgroundColor3 = Colors.Panel,
        }, 0.15)

        Tween(arrow, {
            TextColor3 = Colors.TextMuted,
            Position = UDim2.new(1, -15, 0.5, 0),
        }, 0.15)
    end))

    RegisterConnection(button.MouseButton1Click:Connect(function()
        if IsDead() then
            return
        end

        if typeof(callback) == "function" then
            task.spawn(function()
                pcall(callback)
            end)
        end
    end))

    return button
end

--========================================================
-- TOGGLE
--========================================================

local function CreateToggle(parent, title, description, default, callback)
    local state = default == true

    local card = New("TextButton", {
        Parent = parent,

        Size = UDim2.new(1, 0, 0, 64),

        BackgroundColor3 = Colors.Panel,

        Text = "",

        AutoButtonColor = false,

        ZIndex = 24,
    })

    Corner(card, 11)
    Stroke(card, Colors.Stroke, 1, 0.25)

    New("TextLabel", {
        Parent = card,

        Position = UDim2.fromOffset(14, 9),

        Size = UDim2.new(1, -100, 0, 20),

        BackgroundTransparency = 1,

        Text = title,

        TextColor3 = Colors.Text,

        TextSize = 12,
        Font = Enum.Font.GothamBold,

        TextXAlignment = Enum.TextXAlignment.Left,

        ZIndex = 25,
    })

    New("TextLabel", {
        Parent = card,

        Position = UDim2.fromOffset(14, 31),

        Size = UDim2.new(1, -100, 0, 18),

        BackgroundTransparency = 1,

        Text = description or "",

        TextColor3 = Colors.TextMuted,

        TextSize = 9,
        Font = Enum.Font.GothamMedium,

        TextXAlignment = Enum.TextXAlignment.Left,

        ZIndex = 25,
    })

    local switch = New("Frame", {
        Parent = card,

        AnchorPoint = Vector2.new(1, 0.5),

        Position = UDim2.new(1, -15, 0.5, 0),

        Size = UDim2.fromOffset(48, 26),

        BackgroundColor3 = Colors.PanelLight,

        ZIndex = 26,
    })

    Corner(switch, 20)

    local switchStroke = Stroke(
        switch,
        Colors.Stroke,
        1,
        0.2
    )

    local knob = New("Frame", {
        Parent = switch,

        Position = UDim2.fromOffset(3, 3),

        Size = UDim2.fromOffset(20, 20),

        BackgroundColor3 = Colors.TextMuted,

        ZIndex = 27,
    })

    Corner(knob, 20)

    local function RenderToggle()
        if state then
            Tween(switch, {
                BackgroundColor3 = Colors.Accent,
            }, 0.18)

            Tween(knob, {
                Position = UDim2.new(1, -23, 0, 3),
                BackgroundColor3 = Colors.Text,
            }, 0.18)

            switchStroke.Color = Colors.Accent
        else
            Tween(switch, {
                BackgroundColor3 = Colors.PanelLight,
            }, 0.18)

            Tween(knob, {
                Position = UDim2.fromOffset(3, 3),
                BackgroundColor3 = Colors.TextMuted,
            }, 0.18)

            switchStroke.Color = Colors.Stroke
        end
    end

    RenderToggle()

    RegisterConnection(card.MouseButton1Click:Connect(function()
        if IsDead() then
            return
        end

        state = not state

        RenderToggle()

        if typeof(callback) == "function" then
            task.spawn(function()
                pcall(callback, state)
            end)
        end
    end))

    RegisterConnection(card.MouseEnter:Connect(function()
        if IsDead() then
            return
        end

        Tween(card, {
            BackgroundColor3 = Colors.PanelLight,
        }, 0.15)
    end))

    RegisterConnection(card.MouseLeave:Connect(function()
        if IsDead() then
            return
        end

        Tween(card, {
            BackgroundColor3 = Colors.Panel,
        }, 0.15)
    end))

    return {
        Object = card,

        Get = function()
            return state
        end,

        Set = function(value)
            if IsDead() then
                return
            end

            state = value == true
            RenderToggle()

            if typeof(callback) == "function" then
                task.spawn(function()
                    pcall(callback, state)
                end)
            end
        end,
    }
end

--========================================================
-- TAB
--========================================================

local function CreateTab(name, icon, page)
    local tab = New("TextButton", {
        Name = name .. "Tab",
        Parent = SidebarScroll,

        Size = UDim2.new(1, -8, 0, 43),

        BackgroundColor3 = Colors.Sidebar,

        Text = "",

        AutoButtonColor = false,

        ZIndex = 25,
    })

    Corner(tab, 10)

    local accent = New("Frame", {
        Parent = tab,

        Position = UDim2.fromOffset(0, 8),

        Size = UDim2.fromOffset(3, 27),

        BackgroundColor3 = Colors.Accent,

        BackgroundTransparency = 1,

        ZIndex = 27,
    })

    Corner(accent, 5)

    local iconLabel = New("TextLabel", {
        Parent = tab,

        Position = UDim2.fromOffset(12, 0),

        Size = UDim2.fromOffset(28, 43),

        BackgroundTransparency = 1,

        Text = icon,

        TextColor3 = Colors.TextMuted,

        TextSize = 15,
        Font = Enum.Font.GothamBold,

        ZIndex = 27,
    })

    local textLabel = New("TextLabel", {
        Parent = tab,

        Position = UDim2.fromOffset(46, 0),

        Size = UDim2.new(1, -55, 1, 0),

        BackgroundTransparency = 1,

        Text = name,

        TextColor3 = Colors.TextMuted,

        TextSize = 11,
        Font = Enum.Font.GothamBold,

        TextXAlignment = Enum.TextXAlignment.Left,

        ZIndex = 27,
    })

    local function Select(selected)
        if selected then
            Tween(tab, {
                BackgroundColor3 = Colors.PanelLight,
            }, 0.18)

            Tween(iconLabel, {
                TextColor3 = Colors.Accent,
            }, 0.18)

            Tween(textLabel, {
                TextColor3 = Colors.Text,
            }, 0.18)

            Tween(accent, {
                BackgroundTransparency = 0,
            }, 0.18)
        else
            Tween(tab, {
                BackgroundColor3 = Colors.Sidebar,
            }, 0.18)

            Tween(iconLabel, {
                TextColor3 = Colors.TextMuted,
            }, 0.18)

            Tween(textLabel, {
                TextColor3 = Colors.TextMuted,
            }, 0.18)

            Tween(accent, {
                BackgroundTransparency = 1,
            }, 0.18)
        end
    end

    Tabs[name] = {
        Button = tab,
        Page = page,
        Select = Select,
    }

    RegisterConnection(tab.MouseButton1Click:Connect(function()
        if IsDead() then
            return
        end

        for tabName, data in pairs(Tabs) do
            data.Select(tabName == name)
            data.Page.Visible = tabName == name
        end

        CurrentPage = name

        -- Always reset page scroll when changing tab
        pcall(function()
            page.CanvasPosition = Vector2.zero
        end)
    end))

    RegisterConnection(tab.MouseEnter:Connect(function()
        if IsDead() then
            return
        end

        if CurrentPage ~= name then
            Tween(tab, {
                BackgroundColor3 = Colors.Panel,
            }, 0.12)
        end
    end))

    RegisterConnection(tab.MouseLeave:Connect(function()
        if IsDead() then
            return
        end

        if CurrentPage ~= name then
            Tween(tab, {
                BackgroundColor3 = Colors.Sidebar,
            }, 0.12)
        end
    end))

    return tab
end

--========================================================
-- CREATE PAGES
--========================================================

local Home = CreatePage("Home")
local PlayerPage = CreatePage("Player")
local VisualPage = CreatePage("Visual")
local WorldPage = CreatePage("World")
local MiscPage = CreatePage("Misc")
local ExtraPage = CreatePage("Extra")
local SettingsPage = CreatePage("Settings")

--========================================================
-- HOME
--========================================================

CreateSection(
    Home,
    "Welcome to VANZ",
    "Premium modular control center."
)

CreateInfo(
    Home,
    "SYSTEM STATUS",
    "Interface is running normally. All UI components are isolated."
)

CreateInfo(
    Home,
    "PERFORMANCE",
    "Animations use centralized connections so they can be fully stopped."
)

CreateButton(
    Home,
    "Refresh Interface",
    "Refresh visual components.",
    function()
        print("[VANZ] Interface refreshed.")
    end
)

--========================================================
-- PLAYER
--========================================================

CreateSection(
    PlayerPage,
    "Player",
    "Player-related controls."
)

CreateToggle(
    PlayerPage,
    "Feature Slot 01",
    "Placeholder for your player feature.",
    false,
    function(enabled)
        print("[VANZ] Player Feature 01:", enabled)
    end
)

CreateToggle(
    PlayerPage,
    "Feature Slot 02",
    "Placeholder for your player feature.",
    false,
    function(enabled)
        print("[VANZ] Player Feature 02:", enabled)
    end
)

--========================================================
-- VISUAL
--========================================================

CreateSection(
    VisualPage,
    "Visual",
    "Visual configuration."
)

CreateToggle(
    VisualPage,
    "Visual Feature 01",
    "Placeholder visual feature.",
    false,
    function(enabled)
        print("[VANZ] Visual Feature 01:", enabled)
    end
)

CreateToggle(
    VisualPage,
    "Visual Feature 02",
    "Placeholder visual feature.",
    false,
    function(enabled)
        print("[VANZ] Visual Feature 02:", enabled)
    end
)

--========================================================
-- WORLD
--========================================================

CreateSection(
    WorldPage,
    "World",
    "World-related controls."
)

CreateToggle(
    WorldPage,
    "World Feature 01",
    "Placeholder world feature.",
    false,
    function(enabled)
        print("[VANZ] World Feature 01:", enabled)
    end
)

CreateToggle(
    WorldPage,
    "World Feature 02",
    "Placeholder world feature.",
    false,
    function(enabled)
        print("[VANZ] World Feature 02:", enabled)
    end
)

--========================================================
-- MISC
--========================================================

CreateSection(
    MiscPage,
    "Miscellaneous",
    "Additional utilities."
)

CreateButton(
    MiscPage,
    "Utility Slot",
    "Placeholder utility.",
    function()
        print("[VANZ] Utility executed.")
    end
)

CreateToggle(
    MiscPage,
    "Misc Feature",
    "Placeholder miscellaneous feature.",
    false,
    function(enabled)
        print("[VANZ] Misc Feature:", enabled)
    end
)

--========================================================
-- EXTRA
--========================================================

CreateSection(
    ExtraPage,
    "Extra",
    "Extra configuration and tools."
)

CreateInfo(
    ExtraPage,
    "MODULAR SYSTEM",
    "You can add your own modules using the centralized cleanup system."
)

CreateButton(
    ExtraPage,
    "Test Cleanup",
    "Test a registered cleanup callback.",
    function()
        print("[VANZ] Cleanup system is active.")
    end
)

--========================================================
-- SETTINGS
--========================================================

CreateSection(
    SettingsPage,
    "Settings",
    "Interface configuration."
)

CreateInfo(
    SettingsPage,
    "DISPLAY SCALE",
    "Default scale is 100%. Choose another DPI if needed."
)

local DPIValues = {
    ["70%"] = 0.70,
    ["80%"] = 0.80,
    ["90%"] = 0.90,
    ["100%"] = 1.00,
    ["110%"] = 1.10,
    ["120%"] = 1.20,
}

for label, value in pairs(DPIValues) do
    CreateButton(
        SettingsPage,
        label,
        "Set interface scale to " .. label,
        function()
            if IsDead() then
                return
            end

            UIScale.Scale = value

            print("[VANZ] DPI:", label)
        end
    )
end

--========================================================
-- CREATE TABS
--========================================================

CreateTab("Home", "⌂", Home)
CreateTab("Player", "●", PlayerPage)
CreateTab("Visual", "◈", VisualPage)
CreateTab("World", "◆", WorldPage)
CreateTab("Misc", "✦", MiscPage)
CreateTab("Extra", "✚", ExtraPage)
CreateTab("Settings", "⚙", SettingsPage)

--========================================================
-- DEFAULT TAB
--========================================================

CurrentPage = "Home"

for name, data in pairs(Tabs) do
    data.Page.Visible = name == "Home"
    data.Select(name == "Home")
end

--========================================================
-- FLOATING RESTORE BUTTON
--========================================================

local FloatingButton = New("TextButton", {
    Name = "FloatingButton",
    Parent = ScreenGui,

    AnchorPoint = Vector2.new(0, 0),

    Position = UDim2.new(
        0,
        22,
        0.5,
        -25
    ),

    Size = UDim2.fromOffset(50, 50),

    BackgroundColor3 = Colors.Accent,

    Text = "V",

    TextColor3 = Colors.Text,

    TextSize = 20,
    Font = Enum.Font.GothamBold,

    AutoButtonColor = false,

    Visible = false,

    ZIndex = 100,
})

Corner(FloatingButton, 15)
Stroke(FloatingButton, Colors.Stroke, 1, 0.15)

local FloatingGlow = New("Frame", {
    Parent = ScreenGui,

    Position = UDim2.new(
        0,
        29,
        0.5,
        -18
    ),

    Size = UDim2.fromOffset(50, 50),

    BackgroundColor3 = Colors.Accent,

    BackgroundTransparency = 0.86,

    Visible = false,

    ZIndex = 99,
})

Corner(FloatingGlow, 17)

_G.vanz.UI.FloatingButton = FloatingButton
_G.vanz.UI.FloatingGlow = FloatingGlow

--========================================================
-- DRAG SYSTEM
--========================================================

local function MakeDraggable(object, dragTarget)
    local dragging = false
    local dragStart
    local startPosition

    RegisterConnection(object.InputBegan:Connect(function(input)
        if IsDead() then
            return
        end

        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then

            dragging = true

            dragStart = input.Position
            startPosition = dragTarget.Position
        end
    end))

    RegisterConnection(UserInputService.InputChanged:Connect(function(input)
        if IsDead() then
            return
        end

        if not dragging then
            return
        end

        if input.UserInputType ~= Enum.UserInputType.MouseMovement
            and input.UserInputType ~= Enum.UserInputType.Touch then
            return
        end

        local delta = input.Position - dragStart

        dragTarget.Position = UDim2.new(
            startPosition.X.Scale,
            startPosition.X.Offset + delta.X,
            startPosition.Y.Scale,
            startPosition.Y.Offset + delta.Y
        )
    end))

    RegisterConnection(UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then

            dragging = false
        end
    end))
end

MakeDraggable(Header, MainHolder)
MakeDraggable(FloatingButton, FloatingButton)

--========================================================
-- MINIMIZE STATE
--========================================================

local IsMinimized = false

local function HideEverything()
    if IsDead() then
        return
    end

    IsMinimized = true

    -- Hide main visual components
    Shadow.Visible = false
    OuterGlow.Visible = false

    -- Move + fade main
    Tween(
        MainHolder,
        {
            Size = UDim2.fromOffset(
                _G.vanz.Config.DefaultWidth,
                0
            ),
        },
        0.22,
        Enum.EasingStyle.Quint,
        Enum.EasingDirection.In
    )

    task.delay(0.18, function()
        if IsDead() then
            return
        end

        MainHolder.Visible = false
        FloatingButton.Visible = true
        FloatingGlow.Visible = true

        -- Reset size for restore
        MainHolder.Size = UDim2.fromOffset(
            _G.vanz.Config.DefaultWidth,
            _G.vanz.Config.DefaultHeight
        )
    end)
end

local function ShowEverything()
    if IsDead() then
        return
    end

    IsMinimized = false

    FloatingButton.Visible = false
    FloatingGlow.Visible = false

    MainHolder.Visible = true

    MainHolder.Size = UDim2.fromOffset(
        _G.vanz.Config.DefaultWidth,
        0
    )

    Shadow.Visible = true
    OuterGlow.Visible = true

    Tween(
        MainHolder,
        {
            Size = UDim2.fromOffset(
                _G.vanz.Config.DefaultWidth,
                _G.vanz.Config.DefaultHeight
            ),
        },
        0.28,
        Enum.EasingStyle.Quint,
        Enum.EasingDirection.Out
    )
end

--========================================================
-- MINIMIZE BUTTON EVENTS
--========================================================

RegisterConnection(MinimizeButton.MouseEnter:Connect(function()
    if IsDead() then
        return
    end

    Tween(
        MinimizeButton,
        {
            BackgroundColor3 = Colors.PanelLight,
            TextColor3 = Colors.Accent,
        },
        0.12
    )
end))

RegisterConnection(MinimizeButton.MouseLeave:Connect(function()
    if IsDead() then
        return
    end

    Tween(
        MinimizeButton,
        {
            BackgroundColor3 = Colors.PanelLight,
            TextColor3 = Colors.TextMuted,
        },
        0.12
    )
end))

RegisterConnection(MinimizeButton.MouseButton1Click:Connect(function()
    if IsDead() then
        return
    end

    HideEverything()
end))

--========================================================
-- FLOATING BUTTON
--========================================================

RegisterConnection(FloatingButton.MouseEnter:Connect(function()
    if IsDead() then
        return
    end

    Tween(
        FloatingButton,
        {
            Size = UDim2.fromOffset(54, 54),
        },
        0.15
    )
end))

RegisterConnection(FloatingButton.MouseLeave:Connect(function()
    if IsDead() then
        return
    end

    Tween(
        FloatingButton,
        {
            Size = UDim2.fromOffset(50, 50),
        },
        0.15
    )
end))

RegisterConnection(FloatingButton.MouseButton1Click:Connect(function()
    if IsDead() then
        return
    end

    ShowEverything()
end))

--========================================================
-- FORCE STOP / CLOSE
--========================================================

local function ForceStop()
    if _G.vanz.State.Destroyed then
        return
    end

    print("[VANZ] FORCE STOP initiated...")

    _G.vanz.State.Destroyed = true
    _G.vanz.State.Closed = true
    _G.vanz.State.Open = false

    --====================================================
    -- STEP 1
    -- Stop every registered connection
    --====================================================

    DisconnectAll()

    --====================================================
    -- STEP 2
    -- Run every registered feature cleanup
    --====================================================

    RunAllCleanups()

    --====================================================
    -- STEP 3
    -- Stop active tweens by destroying UI
    --====================================================

    if ScreenGui then
        pcall(function()
            ScreenGui.Enabled = false
        end)
    end

    --====================================================
    -- STEP 4
    -- Destroy GUI completely
    --====================================================

    if ScreenGui then
        pcall(function()
            ScreenGui:Destroy()
        end)
    end

    --====================================================
    -- STEP 5
    -- Remove references
    --====================================================

    _G.vanz.UI = {}
    _G.vanz.Connections = {}
    _G.vanz.Cleanups = {}

    print("[VANZ] FORCE STOP COMPLETE.")
end

_G.vanz.ForceStop = ForceStop
_G.vanz.Close = ForceStop

--========================================================
-- CLOSE BUTTON
--========================================================

RegisterConnection(CloseButton.MouseEnter:Connect(function()
    if IsDead() then
        return
    end

    Tween(
        CloseButton,
        {
            BackgroundColor3 = Colors.Danger,
            TextColor3 = Colors.Text,
        },
        0.12
    )
end))

RegisterConnection(CloseButton.MouseLeave:Connect(function()
    if IsDead() then
        return
    end

    Tween(
        CloseButton,
        {
            BackgroundColor3 = Colors.PanelLight,
            TextColor3 = Colors.TextMuted,
        },
        0.12
    )
end))

RegisterConnection(CloseButton.MouseButton1Click:Connect(function()
    if IsDead() then
        return
    end

    ForceStop()
end))

--========================================================
-- RESPONSIVE SYSTEM
--========================================================

local function UpdateResponsive()
    if IsDead() then
        return
    end

    local camera = workspace.CurrentCamera

    if not camera then
        return
    end

    local viewport = camera.ViewportSize

    local maxWidth = math.max(
        620,
        viewport.X - (_G.vanz.Config.ScreenMargin * 2)
    )

    local maxHeight = math.max(
        400,
        viewport.Y - (_G.vanz.Config.ScreenMargin * 2)
    )

    local width = math.min(
        _G.vanz.Config.DefaultWidth,
        maxWidth
    )

    local height = math.min(
        _G.vanz.Config.DefaultHeight,
        maxHeight
    )

    MainHolder.Size = UDim2.fromOffset(
        width,
        height
    )
end

if workspace.CurrentCamera then
    RegisterConnection(
        workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(
            UpdateResponsive
        )
    )
end

UpdateResponsive()

--========================================================
-- DYNAMIC ANIMATION ENGINE
--========================================================

local AnimationRunning = true

RegisterCleanup(function()
    AnimationRunning = false
end)

RegisterConnection(
    RunService.RenderStepped:Connect(function()
        if not AnimationRunning then
            return
        end

        if IsDead() then
            return
        end

        --================================================
        -- Dynamic accent
        --================================================

        if _G.vanz.Config.DynamicColors then
            local hue = (os.clock() * 0.035) % 1

            local dynamicColor = Color3.fromHSV(
                hue,
                0.55,
                1
            )

            OuterGlow.BackgroundColor3 = dynamicColor
            Logo.BackgroundColor3 = dynamicColor
            FloatingButton.BackgroundColor3 = dynamicColor
            FloatingGlow.BackgroundColor3 = dynamicColor
        end

        --================================================
        -- Logo breathing
        --================================================

        local pulse = 1 + math.sin(os.clock() * 2.2) * 0.035

        Logo.Size = UDim2.fromOffset(
            40 * pulse,
            40 * pulse
        )

        --================================================
        -- Floating glow breathing
        --================================================

        if FloatingGlow.Visible then
            FloatingGlow.BackgroundTransparency =
                0.84 + math.sin(os.clock() * 2) * 0.04
        end

        --================================================
        -- Outer glow breathing
        --================================================

        if MainHolder.Visible then
            OuterGlow.BackgroundTransparency =
                0.87 + math.sin(os.clock() * 1.6) * 0.025
        end
    end)
)

--========================================================
-- PUBLIC API
--========================================================

_G.vanz.Open = function()
    if IsDead() then
        return
    end

    if IsMinimized then
        ShowEverything()
    else
        MainHolder.Visible = true
    end
end

_G.vanz.Hide = function()
    if IsDead() then
        return
    end

    HideEverything()
end

_G.vanz.SetScale = function(scale)
    if IsDead() then
        return
    end

    scale = tonumber(scale)

    if not scale then
        return
    end

    scale = math.clamp(scale, 0.5, 1.5)

    UIScale.Scale = scale
    _G.vanz.Config.Scale = scale
end

_G.vanz.GetState = function()
    return {
        Open = _G.vanz.State.Open,
        Closed = _G.vanz.State.Closed,
        Destroyed = _G.vanz.State.Destroyed,
        Minimized = IsMinimized,
        Scale = UIScale.Scale,
    }
end

_G.vanz.SetState = function(state)
    if IsDead() or typeof(state) ~= "table" then
        return
    end

    if state.Scale then
        _G.vanz.SetScale(state.Scale)
    end

    if state.Minimized == true then
        HideEverything()
    elseif state.Minimized == false then
        ShowEverything()
    end
end

--========================================================
-- STARTUP ANIMATION
--========================================================

MainHolder.Size = UDim2.fromOffset(
    _G.vanz.Config.DefaultWidth * 0.94,
    _G.vanz.Config.DefaultHeight * 0.94
)

MainHolder.Visible = true
Shadow.Visible = true
OuterGlow.Visible = true

Tween(
    MainHolder,
    {
        Size = UDim2.fromOffset(
            _G.vanz.Config.DefaultWidth,
            _G.vanz.Config.DefaultHeight
        ),
    },
    0.38,
    Enum.EasingStyle.Quint,
    Enum.EasingDirection.Out
)

--========================================================
-- FINAL
--========================================================

print("========================================")
print(" VANZ // PREMIUM CONTROL CENTER")
print(" UI VERSION 4")
print(" Sidebar Fixed")
print(" Minimize Fixed")
print(" Close = FORCE STOP")
print(" Cleanup System Active")
print(" Default DPI = 100%")
print("========================================")