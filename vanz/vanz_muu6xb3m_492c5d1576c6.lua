--[[
╔══════════════════════════════════════════════════════════════════════════════╗
║                                                                            ║
║                    V A N Z   //   N E X U S                                ║
║                  ROBOTIC PREMIUM CONTROL CENTER                            ║
║                                                                            ║
║                         UI SYSTEM // V6                                    ║
║                                                                            ║
║  DESIGN                                                                    ║
║  ├─ Futuristic / Robotic                                                   ║
║  ├─ Glass / Dark Premium                                                    ║
║  ├─ Neon Dynamic Accent                                                     ║
║  ├─ Animated Scanline                                                       ║
║  ├─ Telemetry HUD                                                           ║
║  ├─ Soft Glow                                                               ║
║  ├─ Micro Interactions                                                      ║
║  └─ Responsive Layout                                                       ║
║                                                                            ║
║  CORE                                                                       ║
║  ├─ HOME only                                                               ║
║  ├─ DPI controller                                                          ║
║  ├─ Premium toggles                                                         ║
║  ├─ Minimize / Restore                                                      ║
║  ├─ Drag system                                                             ║
║  ├─ Cleanup manager                                                         ║
║  ├─ Connection manager                                                      ║
║  ├─ Public API                                                              ║
║  └─ Force Stop                                                              ║
║                                                                            ║
║  IMPORTANT                                                                  ║
║  ScreenGui menggunakan DisplayOrder tinggi dan Global ZIndex.              ║
║  Ini memprioritaskan VANZ di atas UI game biasa, tetapi tidak dapat         ║
║  menjamin berada di atas CoreGui / UI sistem Roblox.                       ║
║                                                                            ║
╚══════════════════════════════════════════════════════════════════════════════╝
]]


--==========================================================================--
-- BLOK 01 // SERVICES
--==========================================================================--

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")


--==========================================================================--
-- BLOK 02 // GLOBAL RUNTIME
--==========================================================================--

_G.vanz = _G.vanz or {}

local PreviousVanz = _G.vanz


--==========================================================================--
-- BLOK 03 // DESTROY PREVIOUS INSTANCE
--==========================================================================--

do

    if PreviousVanz.Connections then

        for _, connection in pairs(PreviousVanz.Connections) do

            if typeof(connection) == "RBXScriptConnection" then

                pcall(function()
                    connection:Disconnect()
                end)

            end

        end

    end


    if PreviousVanz.Cleanups then

        for _, cleanup in pairs(PreviousVanz.Cleanups) do

            if typeof(cleanup) == "function" then

                pcall(cleanup)

            end

        end

    end


    if PreviousVanz.UI then

        if PreviousVanz.UI.Gui then

            pcall(function()
                PreviousVanz.UI.Gui:Destroy()
            end)

        end

    end


    local oldGui =
        PlayerGui:FindFirstChild("VANZ_NEXUS_GUI")

        or PlayerGui:FindFirstChild("VANZ_PREMIUM_GUI")

        or PlayerGui:FindFirstChild("VANZ_ROBOTIC_GUI")


    if oldGui then

        pcall(function()
            oldGui:Destroy()
        end)

    end

end


_G.vanz = {

    Version = "6.0.0",

    Connections = {},

    Cleanups = {},

    UI = {},

    State = {

        Open = true,

        Closed = false,

        Destroyed = false,

        Minimized = false,

    },

}


local Connections = _G.vanz.Connections
local Cleanups = _G.vanz.Cleanups
local State = _G.vanz.State


--==========================================================================--
-- BLOK 04 // CONFIG
--==========================================================================--

local Config = {

    Title = "VANZ",

    Subtitle = "NEXUS CONTROL SYSTEM",

    VersionText = "NEXUS // 06",

    Scale = 0.70,

    Width = 920,

    Height = 590,

    MinimumWidth = 680,

    MinimumHeight = 430,

    ScreenMargin = 24,

    SidebarWidth = 220,

    HeaderHeight = 86,

    DynamicColors = true,

    EnableGlow = true,

    EnableAnimations = true,

    EnableClickFX = true,

    EnableScanline = true,

    EnableTelemetry = true,

    AccentSpeed = 0.035,

    AnimationSpeed = 1,

    DisplayOrder = 999999,

}


_G.vanz.Config = Config


--==========================================================================--
-- BLOK 05 // COLORS
--==========================================================================--

local Colors = {

    Black = Color3.fromRGB(0, 0, 0),

    White = Color3.fromRGB(255, 255, 255),

    Background = Color3.fromRGB(4, 6, 10),

    Background2 = Color3.fromRGB(6, 9, 15),

    Sidebar = Color3.fromRGB(7, 10, 16),

    Panel = Color3.fromRGB(10, 14, 22),

    Panel2 = Color3.fromRGB(13, 18, 28),

    Panel3 = Color3.fromRGB(18, 24, 37),

    Panel4 = Color3.fromRGB(23, 31, 46),

    Text = Color3.fromRGB(239, 244, 255),

    Muted = Color3.fromRGB(126, 139, 161),

    Soft = Color3.fromRGB(76, 89, 113),

    Stroke = Color3.fromRGB(40, 53, 74),

    Accent = Color3.fromRGB(77, 158, 255),

    Accent2 = Color3.fromRGB(157, 86, 255),

    Cyan = Color3.fromRGB(69, 230, 255),

    Success = Color3.fromRGB(77, 238, 163),

    Warning = Color3.fromRGB(255, 190, 75),

    Danger = Color3.fromRGB(255, 79, 108),

}


_G.vanz.UI.Colors = Colors


--==========================================================================--
-- BLOK 06 // MANAGERS
--==========================================================================--

local function RegisterConnection(connection)

    if connection then

        table.insert(
            Connections,
            connection
        )

    end

    return connection

end


local function RegisterCleanup(callback)

    if typeof(callback) == "function" then

        table.insert(
            Cleanups,
            callback
        )

    end

    return callback

end


_G.vanz.RegisterConnection = RegisterConnection
_G.vanz.RegisterCleanup = RegisterCleanup


--==========================================================================--
-- BLOK 07 // UTILITY
--==========================================================================--

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

        CornerRadius =
            UDim.new(
                0,
                radius or 10
            ),

    })

end


local function Stroke(
    parent,
    color,
    thickness,
    transparency
)

    return New("UIStroke", {

        Parent = parent,

        Color = color or Colors.Stroke,

        Thickness = thickness or 1,

        Transparency = transparency or 0,

        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,

    })

end


local function Gradient(
    parent,
    color1,
    color2,
    rotation
)

    return New("UIGradient", {

        Parent = parent,

        Color =
            ColorSequence.new({

                ColorSequenceKeypoint.new(
                    0,
                    color1
                ),

                ColorSequenceKeypoint.new(
                    1,
                    color2
                ),

            }),

        Rotation = rotation or 0,

    })

end


local function Tween(
    object,
    properties,
    duration,
    style,
    direction
)

    if not object or not object.Parent then
        return
    end

    if not Config.EnableAnimations then

        for property, value in pairs(properties) do

            pcall(function()
                object[property] = value
            end)

        end

        return

    end


    local info = TweenInfo.new(

        duration or 0.2,

        style or Enum.EasingStyle.Quint,

        direction or Enum.EasingDirection.Out

    )


    local tween =
        TweenService:Create(
            object,
            info,
            properties
        )


    tween:Play()

    return tween

end


local function SetTextColor(object, color)

    if object and object.Parent then

        object.TextColor3 = color

    end

end


--==========================================================================--
-- BLOK 08 // SCREEN GUI
--==========================================================================--

local ScreenGui = New("ScreenGui", {

    Name = "VANZ_NEXUS_GUI",

    Parent = PlayerGui,

    ResetOnSpawn = false,

    IgnoreGuiInset = true,

    ZIndexBehavior = Enum.ZIndexBehavior.Global,

    DisplayOrder = Config.DisplayOrder,

})


_G.vanz.UI.Gui = ScreenGui


--==========================================================================--
-- BLOK 09 // UISCALE
--==========================================================================--

local UIScale = New("UIScale", {

    Parent = ScreenGui,

    Scale = Config.Scale,

})


_G.vanz.UI.UIScale = UIScale


--==========================================================================--
-- BLOK 10 // FULLSCREEN BACKDROP
--==========================================================================--

local Backdrop = New("Frame", {

    Name = "Backdrop",

    Parent = ScreenGui,

    Size = UDim2.fromScale(
        1,
        1
    ),

    BackgroundTransparency = 1,

    ZIndex = 1,

})


-- Subtle dark overlay.
-- Tidak menutup gameplay karena transparansi penuh.
local BackdropGradient = Gradient(

    Backdrop,

    Color3.fromRGB(
        8,
        13,
        24
    ),

    Color3.fromRGB(
        3,
        5,
        9
    ),

    90

)

BackdropGradient.Transparency =
    NumberSequence.new({

        NumberSequenceKeypoint.new(
            0,
            0.92
        ),

        NumberSequenceKeypoint.new(
            0.5,
            0.96
        ),

        NumberSequenceKeypoint.new(
            1,
            0.92
        ),

    })


--==========================================================================--
-- BLOK 11 // MAIN HOLDER
--==========================================================================--

local MainHolder = New("Frame", {

    Name = "Nexus",

    Parent = ScreenGui,

    AnchorPoint = Vector2.new(
        0.5,
        0.5
    ),

    Position = UDim2.fromScale(
        0.5,
        0.5
    ),

    Size = UDim2.fromOffset(
        Config.Width,
        Config.Height
    ),

    BackgroundTransparency = 1,

    ZIndex = 100,

})


_G.vanz.UI.Main = MainHolder


--==========================================================================--
-- BLOK 12 // DEEP SHADOW
--==========================================================================--

local Shadow = New("ImageLabel", {

    Name = "DeepShadow",

    Parent = MainHolder,

    AnchorPoint = Vector2.new(
        0.5,
        0.5
    ),

    Position = UDim2.new(
        0.5,
        0,
        0.5,
        13
    ),

    Size = UDim2.new(
        1,
        100,
        1,
        100
    ),

    BackgroundTransparency = 1,

    Image = "rbxassetid://1316045217",

    ImageColor3 = Colors.Black,

    ImageTransparency = 0.20,

    ScaleType = Enum.ScaleType.Slice,

    SliceCenter = Rect.new(
        10,
        10,
        118,
        118
    ),

    ZIndex = 90,

})


--==========================================================================--
-- BLOK 13 // OUTER NEON FRAME
--==========================================================================--

local OuterGlow = New("Frame", {

    Parent = MainHolder,

    AnchorPoint = Vector2.new(
        0.5,
        0.5
    ),

    Position = UDim2.fromScale(
        0.5,
        0.5
    ),

    Size = UDim2.new(
        1,
        14,
        1,
        14
    ),

    BackgroundColor3 = Colors.Accent,

    BackgroundTransparency = 0.88,

    BorderSizePixel = 0,

    ZIndex = 92,

})

Corner(
    OuterGlow,
    24
)


-- Second glow ring.
local OuterGlow2 = New("Frame", {

    Parent = MainHolder,

    AnchorPoint = Vector2.new(
        0.5,
        0.5
    ),

    Position = UDim2.fromScale(
        0.5,
        0.5
    ),

    Size = UDim2.new(
        1,
        7,
        1,
        7
    ),

    BackgroundColor3 = Colors.Cyan,

    BackgroundTransparency = 0.94,

    BorderSizePixel = 0,

    ZIndex = 93,

})

Corner(
    OuterGlow2,
    21
)


--==========================================================================--
-- BLOK 14 // MAIN PANEL
--==========================================================================--

local MainPanel = New("Frame", {

    Name = "MainPanel",

    Parent = MainHolder,

    Size = UDim2.fromScale(
        1,
        1
    ),

    BackgroundColor3 = Colors.Background,

    BorderSizePixel = 0,

    ClipsDescendants = true,

    ZIndex = 100,

})


Corner(
    MainPanel,
    20
)


local MainStroke =
    Stroke(
        MainPanel,
        Colors.Stroke,
        1,
        0.05
    )


_G.vanz.UI.MainPanel = MainPanel


--==========================================================================--
-- BLOK 15 // TOP SCANLINE
--==========================================================================--

local TopScanline = New("Frame", {

    Parent = MainPanel,

    Position = UDim2.fromOffset(
        0,
        0
    ),

    Size = UDim2.new(
        1,
        0,
        0,
        2
    ),

    BackgroundColor3 = Colors.Cyan,

    BorderSizePixel = 0,

    ZIndex = 500,

})

Gradient(

    TopScanline,

    Colors.Cyan,

    Colors.Accent2,

    0

)


--==========================================================================--
-- BLOK 16 // HEADER
--==========================================================================--

local Header = New("Frame", {

    Parent = MainPanel,

    Size = UDim2.new(
        1,
        0,
        0,
        Config.HeaderHeight
    ),

    BackgroundColor3 = Colors.Panel,

    BorderSizePixel = 0,

    ZIndex = 200,

})


Corner(
    Header,
    20
)


local HeaderLower = New("Frame", {

    Parent = Header,

    Position = UDim2.fromOffset(
        0,
        42
    ),

    Size = UDim2.new(
        1,
        0,
        0,
        44
    ),

    BackgroundColor3 = Colors.Panel,

    BorderSizePixel = 0,

    ZIndex = 201,

})


--==========================================================================--
-- BLOK 17 // HEADER GRID
--==========================================================================--

local HeaderGrid = New("Frame", {

    Parent = Header,

    Size = UDim2.fromScale(
        1,
        1
    ),

    BackgroundTransparency = 1,

    ZIndex = 202,

})

for i = 1, 14 do

    local line = New("Frame", {

        Parent = HeaderGrid,

        Position = UDim2.new(
            i / 14,
            0,
            0,
            0
        ),

        Size = UDim2.fromOffset(
            1,
            Config.HeaderHeight
        ),

        BackgroundColor3 = Colors.Stroke,

        BackgroundTransparency = 0.94,

        BorderSizePixel = 0,

        ZIndex = 202,

    })

end


--==========================================================================--
-- BLOK 18 // LOGO SYSTEM
--==========================================================================--

local Logo = New("Frame", {

    Parent = Header,

    Position = UDim2.fromOffset(
        19,
        17
    ),

    Size = UDim2.fromOffset(
        52,
        52
    ),

    BackgroundTransparency = 1,

    ZIndex = 240,

})


local LogoAura = New("Frame", {

    Parent = Logo,

    AnchorPoint = Vector2.new(
        0.5,
        0.5
    ),

    Position = UDim2.fromScale(
        0.5,
        0.5
    ),

    Size = UDim2.new(
        1,
        10,
        1,
        10
    ),

    BackgroundColor3 = Colors.Accent,

    BackgroundTransparency = 0.76,

    BorderSizePixel = 0,

    ZIndex = 238,

})

Corner(
    LogoAura,
    22
)


local LogoBase = New("Frame", {

    Parent = Logo,

    AnchorPoint = Vector2.new(
        0.5,
        0.5
    ),

    Position = UDim2.fromScale(
        0.5,
        0.5
    ),

    Size = UDim2.fromScale(
        1,
        1
    ),

    BackgroundColor3 = Colors.Panel3,

    BorderSizePixel = 0,

    ZIndex = 241,

})

Corner(
    LogoBase,
    16
)

Gradient(

    LogoBase,

    Color3.fromRGB(
        24,
        42,
        72
    ),

    Color3.fromRGB(
        27,
        18,
        49
    ),

    135

)

Stroke(
    LogoBase,
    Colors.Accent,
    1,
    0.15
)


local LogoRing = New("Frame", {

    Parent = Logo,

    AnchorPoint = Vector2.new(
        0.5,
        0.5
    ),

    Position = UDim2.fromScale(
        0.5,
        0.5
    ),

    Size = UDim2.fromOffset(
        39,
        39
    ),

    BackgroundTransparency = 1,

    ZIndex = 243,

})

Corner(
    LogoRing,
    20
)


local LogoRingStroke =
    Stroke(
        LogoRing,
        Colors.Cyan,
        1.4,
        0.08
    )


local LogoText = New("TextLabel", {

    Parent = Logo,

    AnchorPoint = Vector2.new(
        0.5,
        0.5
    ),

    Position = UDim2.fromScale(
        0.5,
        0.5
    ),

    Size = UDim2.fromScale(
        0.85,
        0.85
    ),

    BackgroundTransparency = 1,

    Text = "V",

    TextColor3 = Colors.White,

    TextSize = 27,

    Font = Enum.Font.GothamBlack,

    ZIndex = 245,

})

Gradient(

    LogoText,

    Colors.White,

    Colors.Cyan,

    90

)


--==========================================================================--
-- BLOK 19 // BRAND TEXT
--==========================================================================--

local Brand = New("TextLabel", {

    Parent = Header,

    Position = UDim2.fromOffset(
        84,
        14
    ),

    Size = UDim2.fromOffset(
        260,
        29
    ),

    BackgroundTransparency = 1,

    Text = Config.Title,

    TextColor3 = Colors.Text,

    TextSize = 21,

    Font = Enum.Font.GothamBlack,

    TextXAlignment = Enum.TextXAlignment.Left,

    ZIndex = 250,

})


local BrandSubtitle = New("TextLabel", {

    Parent = Header,

    Position = UDim2.fromOffset(
        85,
        41
    ),

    Size = UDim2.fromOffset(
        280,
        18
    ),

    BackgroundTransparency = 1,

    Text = Config.Subtitle,

    TextColor3 = Colors.Muted,

    TextSize = 8,

    Font = Enum.Font.GothamBold,

    TextXAlignment = Enum.TextXAlignment.Left,

    ZIndex = 250,

})


local VersionBadge = New("TextLabel", {

    Parent = Header,

    Position = UDim2.fromOffset(
        350,
        22
    ),

    Size = UDim2.fromOffset(
        80,
        23
    ),

    BackgroundColor3 = Colors.Panel3,

    BackgroundTransparency = 0.15,

    Text = Config.VersionText,

    TextColor3 = Colors.Cyan,

    TextSize = 7,

    Font = Enum.Font.GothamBold,

    ZIndex = 250,

})

Corner(
    VersionBadge,
    7
)

Stroke(
    VersionBadge,
    Colors.Cyan,
    1,
    0.55
)


--==========================================================================--
-- BLOK 20 // TELEMETRY STATUS
--==========================================================================--

local Telemetry = New("Frame", {

    Parent = Header,

    AnchorPoint = Vector2.new(
        1,
        0.5
    ),

    Position = UDim2.new(
        1,
        -120,
        0.5,
        0
    ),

    Size = UDim2.fromOffset(
        145,
        39
    ),

    BackgroundColor3 = Colors.Panel2,

    BorderSizePixel = 0,

    ZIndex = 250,

})

Corner(
    Telemetry,
    11
)

Stroke(
    Telemetry,
    Colors.Stroke,
    1,
    0.20
)


local TelemetryDot = New("Frame", {

    Parent = Telemetry,

    Position = UDim2.fromOffset(
        12,
        15
    ),

    Size = UDim2.fromOffset(
        8,
        8
    ),

    BackgroundColor3 = Colors.Success,

    ZIndex = 252,

})

Corner(
    TelemetryDot,
    8
)


local TelemetryMain = New("TextLabel", {

    Parent = Telemetry,

    Position = UDim2.fromOffset(
        27,
        6
    ),

    Size = UDim2.new(
        1,
        -35,
        0,
        14
    ),

    BackgroundTransparency = 1,

    Text = "SYSTEM ONLINE",

    TextColor3 = Colors.Text,

    TextSize = 8,

    Font = Enum.Font.GothamBold,

    TextXAlignment = Enum.TextXAlignment.Left,

    ZIndex = 252,

})


local TelemetrySub = New("TextLabel", {

    Parent = Telemetry,

    Position = UDim2.fromOffset(
        27,
        20
    ),

    Size = UDim2.new(
        1,
        -35,
        0,
        12
    ),

    BackgroundTransparency = 1,

    Text = "SECURE // READY",

    TextColor3 = Colors.Success,

    TextSize = 6,

    Font = Enum.Font.GothamMedium,

    TextXAlignment = Enum.TextXAlignment.Left,

    ZIndex = 252,

})


--==========================================================================--
-- BLOK 21 // HEADER CONTROLS
--==========================================================================--

local MinimizeButton = New("TextButton", {

    Parent = Header,

    AnchorPoint = Vector2.new(
        1,
        0.5
    ),

    Position = UDim2.new(
        1,
        -65,
        0.5,
        0
    ),

    Size = UDim2.fromOffset(
        35,
        35
    ),

    BackgroundColor3 = Colors.Panel3,

    Text = "−",

    TextColor3 = Colors.Muted,

    TextSize = 17,

    Font = Enum.Font.GothamBold,

    AutoButtonColor = false,

    ZIndex = 260,

})

Corner(
    MinimizeButton,
    10
)

Stroke(
    MinimizeButton,
    Colors.Stroke,
    1,
    0.15
)


local CloseButton = New("TextButton", {

    Parent = Header,

    AnchorPoint = Vector2.new(
        1,
        0.5
    ),

    Position = UDim2.new(
        1,
        -18,
        0.5,
        0
    ),

    Size = UDim2.fromOffset(
        35,
        35
    ),

    BackgroundColor3 = Colors.Panel3,

    Text = "×",

    TextColor3 = Colors.Muted,

    TextSize = 19,

    Font = Enum.Font.GothamBold,

    AutoButtonColor = false,

    ZIndex = 260,

})

Corner(
    CloseButton,
    10
)

Stroke(
    CloseButton,
    Colors.Stroke,
    1,
    0.15
)


--==========================================================================--
-- BLOK 22 // HEADER STATUS LINE
--==========================================================================--

local HeaderLine = New("Frame", {

    Parent = Header,

    AnchorPoint = Vector2.new(
        0,
        1
    ),

    Position = UDim2.new(
        0,
        0,
        1,
        -1
    ),

    Size = UDim2.new(
        1,
        0,
        0,
        1
    ),

    BackgroundColor3 = Colors.Accent,

    BorderSizePixel = 0,

    ZIndex = 270,

})


--==========================================================================--
-- BLOK 23 // BODY
--==========================================================================--

local Body = New("Frame", {

    Parent = MainPanel,

    Position = UDim2.fromOffset(
        0,
        Config.HeaderHeight
    ),

    Size = UDim2.new(
        1,
        0,
        1,
        -Config.HeaderHeight
    ),

    BackgroundTransparency = 1,

    ClipsDescendants = true,

    ZIndex = 110,

})


--==========================================================================--
-- BLOK 24 // SIDEBAR
--==========================================================================--

local Sidebar = New("Frame", {

    Parent = Body,

    Size = UDim2.new(
        0,
        Config.SidebarWidth,
        1,
        0
    ),

    BackgroundColor3 = Colors.Sidebar,

    BorderSizePixel = 0,

    ZIndex = 120,

})


_G.vanz.UI.Sidebar = Sidebar


--==========================================================================--
-- BLOK 25 // SIDEBAR HEADER
--==========================================================================--

local NavLabel = New("TextLabel", {

    Parent = Sidebar,

    Position = UDim2.fromOffset(
        18,
        19
    ),

    Size = UDim2.new(
        1,
        -36,
        0,
        15
    ),

    BackgroundTransparency = 1,

    Text = "NAVIGATION // 01",

    TextColor3 = Colors.Soft,

    TextSize = 7,

    Font = Enum.Font.GothamBold,

    TextXAlignment = Enum.TextXAlignment.Left,

    ZIndex = 130,

})


local NavLine = New("Frame", {

    Parent = Sidebar,

    Position = UDim2.fromOffset(
        18,
        42
    ),

    Size = UDim2.new(
        1,
        -36,
        0,
        1
    ),

    BackgroundColor3 = Colors.Stroke,

    BackgroundTransparency = 0.4,

    BorderSizePixel = 0,

    ZIndex = 130,

})


--==========================================================================--
-- BLOK 26 // HOME TAB
--==========================================================================--

local HomeTab = New("TextButton", {

    Parent = Sidebar,

    Position = UDim2.fromOffset(
        12,
        60
    ),

    Size = UDim2.new(
        1,
        -24,
        0,
        55
    ),

    BackgroundColor3 = Colors.Panel2,

    Text = "",

    AutoButtonColor = false,

    ZIndex = 140,

})

Corner(
    HomeTab,
    13
)

Stroke(
    HomeTab,
    Colors.Accent,
    1,
    0.45
)


local HomeActiveBar = New("Frame", {

    Parent = HomeTab,

    Position = UDim2.fromOffset(
        0,
        9
    ),

    Size = UDim2.fromOffset(
        3,
        37
    ),

    BackgroundColor3 = Colors.Cyan,

    BorderSizePixel = 0,

    ZIndex = 145,

})

Corner(
    HomeActiveBar,
    4
)


local HomeIcon = New("Frame", {

    Parent = HomeTab,

    Position = UDim2.fromOffset(
        12,
        11
    ),

    Size = UDim2.fromOffset(
        33,
        33
    ),

    BackgroundColor3 = Colors.Panel3,

    BorderSizePixel = 0,

    ZIndex = 145,

})

Corner(
    HomeIcon,
    10
)

Stroke(
    HomeIcon,
    Colors.Accent,
    1,
    0.45
)


local HomeIconText = New("TextLabel", {

    Parent = HomeIcon,

    Size = UDim2.fromScale(
        1,
        1
    ),

    BackgroundTransparency = 1,

    Text = "⌂",

    TextColor3 = Colors.Cyan,

    TextSize = 17,

    Font = Enum.Font.GothamBold,

    ZIndex = 146,

})


local HomeName = New("TextLabel", {

    Parent = HomeTab,

    Position = UDim2.fromOffset(
        58,
        10
    ),

    Size = UDim2.new(
        1,
        -70,
        0,
        19
    ),

    BackgroundTransparency = 1,

    Text = "HOME",

    TextColor3 = Colors.Text,

    TextSize = 10,

    Font = Enum.Font.GothamBold,

    TextXAlignment = Enum.TextXAlignment.Left,

    ZIndex = 146,

})


local HomeDescription = New("TextLabel", {

    Parent = HomeTab,

    Position = UDim2.fromOffset(
        58,
        29
    ),

    Size = UDim2.new(
        1,
        -70,
        0,
        14
    ),

    BackgroundTransparency = 1,

    Text = "Interface control",

    TextColor3 = Colors.Muted,

    TextSize = 7,

    Font = Enum.Font.GothamMedium,

    TextXAlignment = Enum.TextXAlignment.Left,

    ZIndex = 146,

})


--==========================================================================--
-- BLOK 27 // SIDEBAR FOOTER
--==========================================================================--

local SidebarFooter = New("Frame", {

    Parent = Sidebar,

    AnchorPoint = Vector2.new(
        0,
        1
    ),

    Position = UDim2.new(
        0,
        0,
        1,
        -16
    ),

    Size = UDim2.new(
        1,
        0,
        0,
        60
    ),

    BackgroundTransparency = 1,

    ZIndex = 130,

})


local FooterLine = New("Frame", {

    Parent = SidebarFooter,

    Position = UDim2.fromOffset(
        18,
        0
    ),

    Size = UDim2.new(
        1,
        -36,
        0,
        1
    ),

    BackgroundColor3 = Colors.Stroke,

    BackgroundTransparency = 0.45,

    BorderSizePixel = 0,

    ZIndex = 131,

})


local FooterText = New("TextLabel", {

    Parent = SidebarFooter,

    Position = UDim2.fromOffset(
        18,
        13
    ),

    Size = UDim2.new(
        1,
        -36,
        0,
        14
    ),

    BackgroundTransparency = 1,

    Text = "VANZ NEXUS",

    TextColor3 = Colors.Soft,

    TextSize = 7,

    Font = Enum.Font.GothamBold,

    TextXAlignment = Enum.TextXAlignment.Left,

    ZIndex = 132,

})


local FooterVersion = New("TextLabel", {

    Parent = SidebarFooter,

    Position = UDim2.fromOffset(
        18,
        29
    ),

    Size = UDim2.new(
        1,
        -36,
        0,
        14
    ),

    BackgroundTransparency = 1,

    Text = "CORE / STABLE",

    TextColor3 = Colors.Success,

    TextSize = 6,

    Font = Enum.Font.GothamMedium,

    TextXAlignment = Enum.TextXAlignment.Left,

    ZIndex = 132,

})


--==========================================================================--
-- BLOK 28 // SIDEBAR DIVIDER
--==========================================================================--

local SidebarDivider = New("Frame", {

    Parent = Body,

    Position = UDim2.fromOffset(
        Config.SidebarWidth,
        0
    ),

    Size = UDim2.fromOffset(
        1,
        1000
    ),

    BackgroundColor3 = Colors.Stroke,

    BackgroundTransparency = 0.3,

    BorderSizePixel = 0,

    ZIndex = 170,

})


--==========================================================================--
-- BLOK 29 // CONTENT
--==========================================================================--

local Content = New("Frame", {

    Parent = Body,

    Position = UDim2.new(
        0,
        Config.SidebarWidth + 1,
        0,
        0
    ),

    Size = UDim2.new(
        1,
        -(Config.SidebarWidth + 1),
        1,
        0
    ),

    BackgroundColor3 = Colors.Background,

    BorderSizePixel = 0,

    ClipsDescendants = true,

    ZIndex = 115,

})


_G.vanz.UI.Content = Content


--==========================================================================--
-- BLOK 30 // CONTENT DECORATION
--==========================================================================--

local ContentGlow = New("Frame", {

    Parent = Content,

    AnchorPoint = Vector2.new(
        1,
        0
    ),

    Position = UDim2.new(
        1,
        80,
        0,
        -50
    ),

    Size = UDim2.fromOffset(
        230,
        230
    ),

    BackgroundColor3 = Colors.Accent,

    BackgroundTransparency = 0.96,

    BorderSizePixel = 0,

    ZIndex = 116,

})

Corner(
    ContentGlow,
    120
)


local ContentGrid = New("Frame", {

    Parent = Content,

    Size = UDim2.fromScale(
        1,
        1
    ),

    BackgroundTransparency = 1,

    ZIndex = 116,

})


-- Vertical grid.
for i = 1, 8 do

    New("Frame", {

        Parent = ContentGrid,

        Position = UDim2.new(
            i / 8,
            0,
            0,
            0
        ),

        Size = UDim2.fromOffset(
            1,
            1000
        ),

        BackgroundColor3 = Colors.Stroke,

        BackgroundTransparency = 0.975,

        BorderSizePixel = 0,

        ZIndex = 116,

    })

end


--==========================================================================--
-- BLOK 31 // HOME SCROLLER
--==========================================================================--

local HomePage = New("ScrollingFrame", {

    Name = "Home",

    Parent = Content,

    Position = UDim2.fromOffset(
        0,
        0
    ),

    Size = UDim2.fromScale(
        1,
        1
    ),

    BackgroundTransparency = 1,

    BorderSizePixel = 0,

    CanvasSize = UDim2.fromOffset(
        0,
        0
    ),

    AutomaticCanvasSize = Enum.AutomaticSize.Y,

    ScrollingDirection = Enum.ScrollingDirection.Y,

    ScrollBarThickness = 3,

    ScrollBarImageColor3 = Colors.Accent,

    ScrollBarImageTransparency = 0.25,

    ZIndex = 180,

})


New("UIPadding", {

    Parent = HomePage,

    PaddingLeft = UDim.new(
        0,
        24
    ),

    PaddingRight = UDim.new(
        0,
        24
    ),

    PaddingTop = UDim.new(
        0,
        23
    ),

    PaddingBottom = UDim.new(
        0,
        35
    ),

})


New("UIListLayout", {

    Parent = HomePage,

    Padding = UDim.new(
        0,
        14
    ),

    SortOrder = Enum.SortOrder.LayoutOrder,

})


--==========================================================================--
-- BLOK 32 // HERO
--==========================================================================--

local Hero = New("Frame", {

    Parent = HomePage,

    Size = UDim2.new(
        1,
        0,
        0,
        142
    ),

    BackgroundColor3 = Colors.Panel,

    BorderSizePixel = 0,

    LayoutOrder = 1,

    ZIndex = 190,

})

Corner(
    Hero,
    16
)

Stroke(
    Hero,
    Colors.Stroke,
    1,
    0.12
)


local HeroGradient =
    Gradient(

        Hero,

        Color3.fromRGB(
            12,
            23,
            39
        ),

        Color3.fromRGB(
            18,
            12,
            32
        ),

        20

    )


local HeroGlow = New("Frame", {

    Parent = Hero,

    AnchorPoint = Vector2.new(
        1,
        0.5
    ),

    Position = UDim2.new(
        1,
        30,
        0.5,
        0
    ),

    Size = UDim2.fromOffset(
        210,
        210
    ),

    BackgroundColor3 = Colors.Accent,

    BackgroundTransparency = 0.94,

    BorderSizePixel = 0,

    ZIndex = 191,

})

Corner(
    HeroGlow,
    110
)


local HeroTopTag = New("TextLabel", {

    Parent = Hero,

    Position = UDim2.fromOffset(
        20,
        17
    ),

    Size = UDim2.fromOffset(
        160,
        16
    ),

    BackgroundTransparency = 1,

    Text = "NEXUS // COMMAND DECK",

    TextColor3 = Colors.Cyan,

    TextSize = 7,

    Font = Enum.Font.GothamBold,

    TextXAlignment = Enum.TextXAlignment.Left,

    ZIndex = 200,

})


local HeroTitle = New("TextLabel", {

    Parent = Hero,

    Position = UDim2.fromOffset(
        19,
        38
    ),

    Size = UDim2.new(
        1,
        -38,
        0,
        30
    ),

    BackgroundTransparency = 1,

    Text = "WELCOME BACK.",

    TextColor3 = Colors.Text,

    TextSize = 22,

    Font = Enum.Font.GothamBlack,

    TextXAlignment = Enum.TextXAlignment.Left,

    ZIndex = 200,

})


local HeroDescription = New("TextLabel", {

    Parent = Hero,

    Position = UDim2.fromOffset(
        20,
        70
    ),

    Size = UDim2.new(
        0.68,
        0,
        0,
        34
    ),

    BackgroundTransparency = 1,

    Text = "Your interface is synchronized and ready.\nConfigure the visual control layer below.",

    TextColor3 = Colors.Muted,

    TextSize = 9,

    Font = Enum.Font.GothamMedium,

    TextWrapped = true,

    TextXAlignment = Enum.TextXAlignment.Left,

    TextYAlignment = Enum.TextYAlignment.Top,

    ZIndex = 200,

})


-- Hero telemetry bars.
local HeroBars = New("Frame", {

    Parent = Hero,

    AnchorPoint = Vector2.new(
        1,
        0.5
    ),

    Position = UDim2.new(
        1,
        -22,
        0.5,
        5
    ),

    Size = UDim2.fromOffset(
        170,
        65
    ),

    BackgroundTransparency = 1,

    ZIndex = 201,

})


for i = 1, 5 do

    local bar = New("Frame", {

        Parent = HeroBars,

        Position = UDim2.new(
            0,
            (i - 1) * 31,
            0.5,
            -18
        ),

        Size = UDim2.fromOffset(
            20,
            36
        ),

        BackgroundColor3 = Colors.Panel3,

        BorderSizePixel = 0,

        ZIndex = 202,

    })

    Corner(
        bar,
        5
    )

    local fill = New("Frame", {

        Parent = bar,

        AnchorPoint = Vector2.new(
            0,
            1
        ),

        Position = UDim2.fromScale(
            0,
            1
        ),

        Size = UDim2.new(
            1,
            0,
            0.4 + i * 0.1,
            0
        ),

        BackgroundColor3 = Colors.Accent,

        BorderSizePixel = 0,

        ZIndex = 203,

    })

    Corner(
        fill,
        5
    )

end


--==========================================================================--
-- BLOK 33 // SECTION LABEL
--==========================================================================--

local InterfaceLabel = New("TextLabel", {

    Parent = HomePage,

    Size = UDim2.new(
        1,
        0,
        0,
        22
    ),

    BackgroundTransparency = 1,

    Text = "INTERFACE // CONFIGURATION",

    TextColor3 = Colors.Text,

    TextSize = 11,

    Font = Enum.Font.GothamBold,

    TextXAlignment = Enum.TextXAlignment.Left,

    LayoutOrder = 2,

    ZIndex = 190,

})


--==========================================================================--
-- BLOK 34 // DPI CARD
--==========================================================================--

local DPICard = New("Frame", {

    Parent = HomePage,

    Size = UDim2.new(
        1,
        0,
        0,
        96
    ),

    BackgroundColor3 = Colors.Panel,

    BorderSizePixel = 0,

    LayoutOrder = 3,

    ZIndex = 190,

})

Corner(
    DPICard,
    14
)

Stroke(
    DPICard,
    Colors.Stroke,
    1,
    0.18
)


local DPIIcon = New("Frame", {

    Parent = DPICard,

    Position = UDim2.fromOffset(
        16,
        22
    ),

    Size = UDim2.fromOffset(
        50,
        50
    ),

    BackgroundColor3 = Colors.Panel3,

    BorderSizePixel = 0,

    ZIndex = 195,

})

Corner(
    DPIIcon,
    13
)

Stroke(
    DPIIcon,
    Colors.Accent,
    1,
    0.40
)


local DPIIconText = New("TextLabel", {

    Parent = DPIIcon,

    Size = UDim2.fromScale(
        1,
        1
    ),

    BackgroundTransparency = 1,

    Text = "DPI",

    TextColor3 = Colors.Cyan,

    TextSize = 10,

    Font = Enum.Font.GothamBlack,

    ZIndex = 196,

})


local DPITitle = New("TextLabel", {

    Parent = DPICard,

    Position = UDim2.fromOffset(
        80,
        17
    ),

    Size = UDim2.new(
        0.35,
        0,
        0,
        21
    ),

    BackgroundTransparency = 1,

    Text = "INTERFACE SCALE",

    TextColor3 = Colors.Text,

    TextSize = 10,

    Font = Enum.Font.GothamBold,

    TextXAlignment = Enum.TextXAlignment.Left,

    ZIndex = 195,

})


local DPISubtitle = New("TextLabel", {

    Parent = DPICard,

    Position = UDim2.fromOffset(
        80,
        40
    ),

    Size = UDim2.new(
        0.35,
        0,
        0,
        18
    ),

    BackgroundTransparency = 1,

    Text = "Global display density",

    TextColor3 = Colors.Muted,

    TextSize = 8,

    Font = Enum.Font.GothamMedium,

    TextXAlignment = Enum.TextXAlignment.Left,

    ZIndex = 195,

})


local DPIValue = New("TextLabel", {

    Parent = DPICard,

    AnchorPoint = Vector2.new(
        1,
        0
    ),

    Position = UDim2.new(
        1,
        -18,
        0,
        16
    ),

    Size = UDim2.fromOffset(
        70,
        22
    ),

    BackgroundTransparency = 1,

    Text = "70%",

    TextColor3 = Colors.Cyan,

    TextSize = 13,

    Font = Enum.Font.GothamBlack,

    TextXAlignment = Enum.TextXAlignment.Right,

    ZIndex = 195,

})


local DPIButtonHolder = New("Frame", {

    Parent = DPICard,

    AnchorPoint = Vector2.new(
        1,
        1
    ),

    Position = UDim2.new(
        1,
        -16,
        1,
        -14
    ),

    Size = UDim2.fromOffset(
        310,
        28
    ),

    BackgroundTransparency = 1,

    ZIndex = 195,

})


New("UIListLayout", {

    Parent = DPIButtonHolder,

    FillDirection = Enum.FillDirection.Horizontal,

    HorizontalAlignment = Enum.HorizontalAlignment.Right,

    VerticalAlignment = Enum.VerticalAlignment.Center,

    Padding = UDim.new(
        0,
        5
    ),

})


local DPIOptions = {

    {
        Name = "50%",
        Value = 0.50,
    },

    {
        Name = "60%",
        Value = 0.60,
    },

    {
        Name = "70%",
        Value = 0.70,
    },

    {
        Name = "80%",
        Value = 0.80,
    },

    {
        Name = "90%",
        Value = 0.90,
    },

    {
        Name = "100%",
        Value = 1.00,
    },

}


local DPIButtons = {}


local function UpdateDPIVisual(selected)

    for _, data in ipairs(DPIButtons) do

        local active =
            data.Button == selected

        Tween(

            data.Button,

            {

                BackgroundColor3 =
                    active
                    and Colors.Accent
                    or Colors.Panel3,

            },

            0.15

        )


        Tween(

            data.Label,

            {

                TextColor3 =
                    active
                    and Colors.White
                    or Colors.Muted,

            },

            0.15

        )

    end

end


for _, option in ipairs(DPIOptions) do

    local button = New("TextButton", {

        Parent = DPIButtonHolder,

        Size = UDim2.fromOffset(
            46,
            27
        ),

        BackgroundColor3 = Colors.Panel3,

        Text = "",

        AutoButtonColor = false,

        ZIndex = 200,

    })

    Corner(
        button,
        8
    )


    local label = New("TextLabel", {

        Parent = button,

        Size = UDim2.fromScale(
            1,
            1
        ),

        BackgroundTransparency = 1,

        Text = option.Name,

        TextColor3 = Colors.Muted,

        TextSize = 7,

        Font = Enum.Font.GothamBold,

        ZIndex = 201,

    })


    table.insert(

        DPIButtons,

        {

            Button = button,

            Label = label,

            Value = option.Value,

        }

    )


    RegisterConnection(

        button.MouseButton1Click:Connect(

            function()

                if State.Destroyed then
                    return
                end


                UIScale.Scale =
                    option.Value


                Config.Scale =
                    option.Value


                DPIValue.Text =
                    option.Name


                UpdateDPIVisual(button)

            end

        )

    )


    RegisterConnection(

        button.MouseEnter:Connect(

            function()

                if State.Destroyed then
                    return
                end

                if UIScale.Scale ~= option.Value then

                    Tween(

                        button,

                        {
                            BackgroundColor3 =
                                Colors.Panel4
                        },

                        0.12

                    )

                end

            end

        )

    )


    RegisterConnection(

        button.MouseLeave:Connect(

            function()

                if State.Destroyed then
                    return
                end

                if UIScale.Scale ~= option.Value then

                    Tween(

                        button,

                        {
                            BackgroundColor3 =
                                Colors.Panel3
                        },

                        0.12

                    )

                end

            end

        )

    )

end


UpdateDPIVisual(
    DPIButtons[3].Button
)


--==========================================================================--
-- BLOK 35 // FEATURES LABEL
--==========================================================================--

local FeaturesLabel = New("TextLabel", {

    Parent = HomePage,

    Size = UDim2.new(
        1,
        0,
        0,
        22
    ),

    BackgroundTransparency = 1,

    Text = "VISUAL CORE // MODULES",

    TextColor3 = Colors.Text,

    TextSize = 11,

    Font = Enum.Font.GothamBold,

    TextXAlignment = Enum.TextXAlignment.Left,

    LayoutOrder = 4,

    ZIndex = 190,

})


--==========================================================================--
-- BLOK 36 // PREMIUM TOGGLE FACTORY
--==========================================================================--

local function CreatePremiumToggle(

    parent,

    title,

    description,

    defaultState,

    callback

)

    local state =
        defaultState == true


    local card = New("TextButton", {

        Parent = parent,

        Size = UDim2.new(
            1,
            0,
            0,
            78
        ),

        BackgroundColor3 = Colors.Panel,

        Text = "",

        AutoButtonColor = false,

        LayoutOrder = 10,

        ZIndex = 190,

    })

    Corner(
        card,
        14
    )

    local cardStroke =
        Stroke(
            card,
            Colors.Stroke,
            1,
            0.18
        )


    local AccentBar = New("Frame", {

        Parent = card,

        Position = UDim2.fromOffset(
            14,
            19
        ),

        Size = UDim2.fromOffset(
            4,
            40
        ),

        BackgroundColor3 = Colors.Accent,

        BorderSizePixel = 0,

        ZIndex = 196,

    })

    Corner(
        AccentBar,
        4
    )


    local FeatureTitle = New("TextLabel", {

        Parent = card,

        Position = UDim2.fromOffset(
            31,
            13
        ),

        Size = UDim2.new(
            0.65,
            0,
            0,
            21
        ),

        BackgroundTransparency = 1,

        Text = title,

        TextColor3 = Colors.Text,

        TextSize = 10,

        Font = Enum.Font.GothamBold,

        TextXAlignment = Enum.TextXAlignment.Left,

        ZIndex = 197,

    })


    local FeatureDescription = New("TextLabel", {

        Parent = card,

        Position = UDim2.fromOffset(
            31,
            37
        ),

        Size = UDim2.new(
            0.65,
            0,
            0,
            18
        ),

        BackgroundTransparency = 1,

        Text = description,

        TextColor3 = Colors.Muted,

        TextSize = 8,

        Font = Enum.Font.GothamMedium,

        TextXAlignment = Enum.TextXAlignment.Left,

        ZIndex = 197,

    })


    local StatusText = New("TextLabel", {

        Parent = card,

        AnchorPoint = Vector2.new(
            1,
            0
        ),

        Position = UDim2.new(
            1,
            -86,
            0,
            9
        ),

        Size = UDim2.fromOffset(
            35,
            13
        ),

        BackgroundTransparency = 1,

        Text = "ON",

        TextColor3 = Colors.Success,

        TextSize = 6,

        Font = Enum.Font.GothamBold,

        TextXAlignment = Enum.TextXAlignment.Right,

        ZIndex = 201,

    })


    local Toggle = New("Frame", {

        Parent = card,

        AnchorPoint = Vector2.new(
            1,
            0.5
        ),

        Position = UDim2.new(
            1,
            -18,
            0.5,
            4
        ),

        Size = UDim2.fromOffset(
            54,
            30
        ),

        BackgroundColor3 = Colors.Panel3,

        BorderSizePixel = 0,

        ZIndex = 200,

    })

    Corner(
        Toggle,
        20
    )


    local ToggleStroke =
        Stroke(
            Toggle,
            Colors.Stroke,
            1,
            0.1
        )


    local Knob = New("Frame", {

        Parent = Toggle,

        Position = UDim2.fromOffset(
            4,
            4
        ),

        Size = UDim2.fromOffset(
            22,
            22
        ),

        BackgroundColor3 = Colors.Muted,

        BorderSizePixel = 0,

        ZIndex = 205,

    })

    Corner(
        Knob,
        20
    )


    local KnobGlow = New("Frame", {

        Parent = Knob,

        Position = UDim2.fromOffset(
            5,
            4
        ),

        Size = UDim2.fromOffset(
            7,
            3
        ),

        BackgroundColor3 = Colors.White,

        BackgroundTransparency = 0.45,

        Rotation = -25,

        BorderSizePixel = 0,

        ZIndex = 206,

    })

    Corner(
        KnobGlow,
        4
    )


    local function RenderToggle()

        if state then

            Tween(

                Toggle,

                {
                    BackgroundColor3 =
                        Colors.Accent
                },

                0.18

            )


            Tween(

                Knob,

                {

                    Position =
                        UDim2.new(
                            1,
                            -26,
                            0,
                            4
                        ),

                    BackgroundColor3 =
                        Colors.White,

                },

                0.22,

                Enum.EasingStyle.Back

            )


            Tween(

                AccentBar,

                {
                    BackgroundColor3 =
                        Colors.Cyan
                },

                0.18

            )


            StatusText.Text =
                "ON"


            StatusText.TextColor3 =
                Colors.Success


            ToggleStroke.Color =
                Colors.Accent

        else

            Tween(

                Toggle,

                {
                    BackgroundColor3 =
                        Colors.Panel3
                },

                0.18

            )


            Tween(

                Knob,

                {

                    Position =
                        UDim2.fromOffset(
                            4,
                            4
                        ),

                    BackgroundColor3 =
                        Colors.Muted,

                },

                0.20,

                Enum.EasingStyle.Back

            )


            Tween(

                AccentBar,

                {
                    BackgroundColor3 =
                        Colors.Soft
                },

                0.18

            )


            StatusText.Text =
                "OFF"


            StatusText.TextColor3 =
                Colors.Muted


            ToggleStroke.Color =
                Colors.Stroke

        end

    end


    RenderToggle()


    RegisterConnection(

        card.MouseEnter:Connect(

            function()

                if State.Destroyed then
                    return
                end


                Tween(

                    card,

                    {
                        BackgroundColor3 =
                            Colors.Panel2
                    },

                    0.12

                )


                Tween(

                    cardStroke,

                    {
                        Transparency =
                            0.02
                    },

                    0.12

                )

            end

        )

    )


    RegisterConnection(

        card.MouseLeave:Connect(

            function()

                if State.Destroyed then
                    return
                end


                Tween(

                    card,

                    {
                        BackgroundColor3 =
                            Colors.Panel
                    },

                    0.12

                )


                Tween(

                    cardStroke,

                    {
                        Transparency =
                            0.18
                    },

                    0.12

                )

            end

        )

    )


    RegisterConnection(

        card.MouseButton1Click:Connect(

            function()

                if State.Destroyed then
                    return
                end


                state =
                    not state


                if Config.EnableClickFX then

                    Tween(

                        Knob,

                        {
                            Size =
                                UDim2.fromOffset(
                                    26,
                                    26
                                )
                        },

                        0.07

                    )


                    task.delay(

                        0.07,

                        function()

                            if State.Destroyed then
                                return
                            end

                            Tween(

                                Knob,

                                {
                                    Size =
                                        UDim2.fromOffset(
                                            22,
                                            22
                                        )
                                },

                                0.12,

                                Enum.EasingStyle.Back

                            )

                        end

                    )

                end


                RenderToggle()


                if typeof(callback) == "function" then

                    task.spawn(

                        function()

                            pcall(
                                callback,
                                state
                            )

                        end

                    )

                end

            end

        )

    )


    return {

        Object = card,

        Get = function()

            return state

        end,

        Set = function(value)

            if State.Destroyed then
                return
            end

            state =
                value == true

            RenderToggle()


            if typeof(callback) == "function" then

                task.spawn(

                    function()

                        pcall(
                            callback,
                            state
                        )

                    end

                )

            end

        end,

    }

end


--==========================================================================--
-- BLOK 37 // DEFAULT FEATURES
--==========================================================================--

local ToggleAnimations =
    CreatePremiumToggle(

        HomePage,

        "Premium Motion Engine",

        "Smooth transitions, micro motion and interface easing.",

        true,

        function(enabled)

            Config.EnableAnimations =
                enabled

        end

    )


local ToggleGlow =
    CreatePremiumToggle(

        HomePage,

        "Dynamic Neon Glow",

        "Animated accent lighting around the Nexus interface.",

        true,

        function(enabled)

            Config.EnableGlow =
                enabled

        end

    )


local ToggleClick =
    CreatePremiumToggle(

        HomePage,

        "Interaction Feedback",

        "Button bounce, hover response and tactile visual feedback.",

        true,

        function(enabled)

            Config.EnableClickFX =
                enabled

        end

    )


local ToggleScanline =
    CreatePremiumToggle(

        HomePage,

        "Cyber Scanline",

        "Animated robotic scanline running through the command deck.",

        true,

        function(enabled)

            Config.EnableScanline =
                enabled

        end

    )


local ToggleTelemetry =
    CreatePremiumToggle(

        HomePage,

        "System Telemetry",

        "Live visual status indicators and system activity feedback.",

        true,

        function(enabled)

            Config.EnableTelemetry =
                enabled

        end

    )


--==========================================================================--
-- BLOK 38 // SYSTEM INFO CARD
--==========================================================================--

local SystemCard = New("Frame", {

    Parent = HomePage,

    Size = UDim2.new(
        1,
        0,
        0,
        74
    ),

    BackgroundColor3 = Colors.Panel,

    BorderSizePixel = 0,

    LayoutOrder = 20,

    ZIndex = 190,

})

Corner(
    SystemCard,
    13
)

Stroke(
    SystemCard,
    Colors.Stroke,
    1,
    0.20
)


local SystemLeft = New("TextLabel", {

    Parent = SystemCard,

    Position = UDim2.fromOffset(
        17,
        12
    ),

    Size = UDim2.new(
        0.5,
        0,
        0,
        19
    ),

    BackgroundTransparency = 1,

    Text = "NEXUS CORE",

    TextColor3 = Colors.Text,

    TextSize = 9,

    Font = Enum.Font.GothamBold,

    TextXAlignment = Enum.TextXAlignment.Left,

    ZIndex = 195,

})


local SystemSub = New("TextLabel", {

    Parent = SystemCard,

    Position = UDim2.fromOffset(
        17,
        33
    ),

    Size = UDim2.new(
        0.6,
        0,
        0,
        17
    ),

    BackgroundTransparency = 1,

    Text = "UI CHANNEL // STABLE",

    TextColor3 = Colors.Muted,

    TextSize = 7,

    Font = Enum.Font.GothamMedium,

    TextXAlignment = Enum.TextXAlignment.Left,

    ZIndex = 195,

})


local SystemStatus = New("TextLabel", {

    Parent = SystemCard,

    AnchorPoint = Vector2.new(
        1,
        0.5
    ),

    Position = UDim2.new(
        1,
        -18,
        0.5,
        0
    ),

    Size = UDim2.fromOffset(
        100,
        25
    ),

    BackgroundColor3 = Colors.Panel3,

    Text = "●  STABLE",

    TextColor3 = Colors.Success,

    TextSize = 7,

    Font = Enum.Font.GothamBold,

    ZIndex = 196,

})

Corner(
    SystemStatus,
    8
)

Stroke(
    SystemStatus,
    Colors.Success,
    1,
    0.65
)


--==========================================================================--
-- BLOK 39 // DRAG ENGINE
--==========================================================================--

local function MakeDraggable(

    dragObject,

    targetObject

)

    local dragging = false

    local dragStart

    local startPosition


    RegisterConnection(

        dragObject.InputBegan:Connect(

            function(input)

                if State.Destroyed then
                    return
                end


                if

                    input.UserInputType
                        == Enum.UserInputType.MouseButton1

                    or

                    input.UserInputType
                        == Enum.UserInputType.Touch

                then

                    dragging = true

                    dragStart =
                        input.Position

                    startPosition =
                        targetObject.Position

                end

            end

        )

    )


    RegisterConnection(

        UserInputService.InputChanged:Connect(

            function(input)

                if not dragging then
                    return
                end


                if State.Destroyed then
                    return
                end


                if

                    input.UserInputType
                        ~= Enum.UserInputType.MouseMovement

                    and

                    input.UserInputType
                        ~= Enum.UserInputType.Touch

                then

                    return

                end


                local delta =
                    input.Position
                    - dragStart


                targetObject.Position =
                    UDim2.new(

                        startPosition.X.Scale,

                        startPosition.X.Offset
                            + delta.X,

                        startPosition.Y.Scale,

                        startPosition.Y.Offset
                            + delta.Y

                    )

            end

        )

    )


    RegisterConnection(

        UserInputService.InputEnded:Connect(

            function(input)

                if

                    input.UserInputType
                        == Enum.UserInputType.MouseButton1

                    or

                    input.UserInputType
                        == Enum.UserInputType.Touch

                then

                    dragging = false

                end

            end

        )

    )

end


MakeDraggable(
    Header,
    MainHolder
)


--==========================================================================--
-- BLOK 40 // FLOATING RESTORE
--==========================================================================--

local FloatingButton = New("TextButton", {

    Name = "NexusRestore",

    Parent = ScreenGui,

    AnchorPoint = Vector2.new(
        0,
        0.5
    ),

    Position = UDim2.new(
        0,
        22,
        0.5,
        0
    ),

    Size = UDim2.fromOffset(
        58,
        58
    ),

    BackgroundColor3 = Colors.Panel3,

    Text = "",

    AutoButtonColor = false,

    Visible = false,

    ZIndex = 900,

})


Corner(
    FloatingButton,
    17
)

Stroke(
    FloatingButton,
    Colors.Accent,
    1,
    0.08
)


Gradient(

    FloatingButton,

    Color3.fromRGB(
        27,
        44,
        74
    ),

    Color3.fromRGB(
        29,
        18,
        52
    ),

    135

)


local FloatingRing = New("Frame", {

    Parent = FloatingButton,

    AnchorPoint = Vector2.new(
        0.5,
        0.5
    ),

    Position = UDim2.fromScale(
        0.5,
        0.5
    ),

    Size = UDim2.fromOffset(
        41,
        41
    ),

    BackgroundTransparency = 1,

    ZIndex = 902,

})

Corner(
    FloatingRing,
    22
)


local FloatingRingStroke =
    Stroke(
        FloatingRing,
        Colors.Cyan,
        1.2,
        0.12
    )


local FloatingV = New("TextLabel", {

    Parent = FloatingButton,

    Size = UDim2.fromScale(
        1,
        1
    ),

    BackgroundTransparency = 1,

    Text = "V",

    TextColor3 = Colors.White,

    TextSize = 23,

    Font = Enum.Font.GothamBlack,

    ZIndex = 905,

})


--==========================================================================--
-- BLOK 41 // MINIMIZE
--==========================================================================--

local function Minimize()

    if State.Destroyed then
        return
    end

    if State.Minimized then
        return
    end


    State.Minimized = true

    State.Open = false


    Shadow.Visible = false

    OuterGlow.Visible = false

    OuterGlow2.Visible = false


    Tween(

        MainHolder,

        {

            Size =
                UDim2.fromOffset(
                    Config.Width,
                    0
                ),

        },

        0.24,

        Enum.EasingStyle.Quint,

        Enum.EasingDirection.In

    )


    task.delay(

        0.20,

        function()

            if State.Destroyed then
                return
            end


            MainHolder.Visible = false

            FloatingButton.Visible = true


            MainHolder.Size =
                UDim2.fromOffset(
                    Config.Width,
                    Config.Height
                )

        end

    )

end


--==========================================================================--
-- BLOK 42 // RESTORE
--==========================================================================--

local function Restore()

    if State.Destroyed then
        return
    end

    if not State.Minimized then
        return
    end


    State.Minimized = false

    State.Open = true


    FloatingButton.Visible = false

    MainHolder.Visible = true

    Shadow.Visible = true

    OuterGlow.Visible = true

    OuterGlow2.Visible = true


    MainHolder.Size =
        UDim2.fromOffset(
            Config.Width,
            0
        )


    Tween(

        MainHolder,

        {

            Size =
                UDim2.fromOffset(
                    Config.Width,
                    Config.Height
                ),

        },

        0.32,

        Enum.EasingStyle.Quint,

        Enum.EasingDirection.Out

    )

end


--==========================================================================--
-- BLOK 43 // BUTTON INTERACTIONS
--==========================================================================--

RegisterConnection(

    MinimizeButton.MouseEnter:Connect(

        function()

            if State.Destroyed then
                return
            end


            Tween(

                MinimizeButton,

                {

                    BackgroundColor3 =
                        Colors.Accent,

                    TextColor3 =
                        Colors.White,

                },

                0.12

            )

        end

    )

)


RegisterConnection(

    MinimizeButton.MouseLeave:Connect(

        function()

            if State.Destroyed then
                return
            end


            Tween(

                MinimizeButton,

                {

                    BackgroundColor3 =
                        Colors.Panel3,

                    TextColor3 =
                        Colors.Muted,

                },

                0.12

            )

        end

    )

)


RegisterConnection(

    MinimizeButton.MouseButton1Click:Connect(

        function()

            Minimize()

        end

    )

)


RegisterConnection(

    CloseButton.MouseEnter:Connect(

        function()

            if State.Destroyed then
                return
            end


            Tween(

                CloseButton,

                {

                    BackgroundColor3 =
                        Colors.Danger,

                    TextColor3 =
                        Colors.White,

                },

                0.12

            )

        end

    )

)


RegisterConnection(

    CloseButton.MouseLeave:Connect(

        function()

            if State.Destroyed then
                return
            end


            Tween(

                CloseButton,

                {

                    BackgroundColor3 =
                        Colors.Panel3,

                    TextColor3 =
                        Colors.Muted,

                },

                0.12

            )

        end

    )

)


--==========================================================================--
-- BLOK 44 // CLOSE = FORCE STOP
--==========================================================================--

local function ForceStop()

    if State.Destroyed then
        return
    end


    print(
        "[VANZ NEXUS] FORCE STOP"
    )


    State.Destroyed = true

    State.Closed = true

    State.Open = false

    State.Minimized = false


    -- Disconnect everything.
    for i = #Connections, 1, -1 do

        local connection =
            Connections[i]


        if typeof(connection)
            == "RBXScriptConnection" then

            pcall(function()

                connection:Disconnect()

            end)

        end


        Connections[i] = nil

    end


    -- Run cleanup.
    for i = #Cleanups, 1, -1 do

        local cleanup =
            Cleanups[i]


        if typeof(cleanup) == "function" then

            pcall(cleanup)

        end


        Cleanups[i] = nil

    end


    -- Disable first.
    pcall(function()

        ScreenGui.Enabled = false

    end)


    -- Destroy.
    pcall(function()

        ScreenGui:Destroy()

    end)


    _G.vanz.UI = {}

    _G.vanz.Connections = {}

    _G.vanz.Cleanups = {}


    print(
        "[VANZ NEXUS] FORCE STOP COMPLETE"
    )

end


_G.vanz.ForceStop = ForceStop
_G.vanz.Close = ForceStop


RegisterConnection(

    CloseButton.MouseButton1Click:Connect(

        function()

            ForceStop()

        end

    )

)


--==========================================================================--
-- BLOK 45 // FLOATING BUTTON
--==========================================================================--

RegisterConnection(

    FloatingButton.MouseEnter:Connect(

        function()

            if State.Destroyed then
                return
            end


            Tween(

                FloatingButton,

                {

                    Size =
                        UDim2.fromOffset(
                            63,
                            63
                        ),

                },

                0.16,

                Enum.EasingStyle.Back

            )

        end

    )

)


RegisterConnection(

    FloatingButton.MouseLeave:Connect(

        function()

            if State.Destroyed then
                return
            end


            Tween(

                FloatingButton,

                {

                    Size =
                        UDim2.fromOffset(
                            58,
                            58
                        ),

                },

                0.16,

                Enum.EasingStyle.Back

            )

        end

    )

)


RegisterConnection(

    FloatingButton.MouseButton1Click:Connect(

        function()

            Restore()

        end

    )

)


MakeDraggable(
    FloatingButton,
    FloatingButton
)


--==========================================================================--
-- BLOK 46 // HOME TAB HOVER
--==========================================================================--

RegisterConnection(

    HomeTab.MouseEnter:Connect(

        function()

            if State.Destroyed then
                return
            end


            Tween(

                HomeTab,

                {

                    BackgroundColor3 =
                        Colors.Panel3,

                },

                0.12

            )

        end

    )

)


RegisterConnection(

    HomeTab.MouseLeave:Connect(

        function()

            if State.Destroyed then
                return
            end


            Tween(

                HomeTab,

                {

                    BackgroundColor3 =
                        Colors.Panel2,

                },

                0.12

            )

        end

    )

)


--==========================================================================--
-- BLOK 47 // RESPONSIVE SYSTEM
--==========================================================================--

local function UpdateResponsive()

    if State.Destroyed then
        return
    end


    local camera =
        workspace.CurrentCamera


    if not camera then
        return
    end


    local viewport =
        camera.ViewportSize


    local width =
        math.min(

            Config.Width,

            math.max(

                Config.MinimumWidth,

                viewport.X
                    - Config.ScreenMargin * 2

            )

        )


    local height =
        math.min(

            Config.Height,

            math.max(

                Config.MinimumHeight,

                viewport.Y
                    - Config.ScreenMargin * 2

            )

        )


    MainHolder.Size =
        UDim2.fromOffset(
            width,
            height
        )

end


local function BindCamera()

    local camera =
        workspace.CurrentCamera


    if not camera then
        return
    end


    RegisterConnection(

        camera:GetPropertyChangedSignal(
            "ViewportSize"
        ):Connect(

            UpdateResponsive

        )

    )

end


if workspace.CurrentCamera then

    BindCamera()

end


RegisterConnection(

    workspace:GetPropertyChangedSignal(
        "CurrentCamera"
    ):Connect(

        function()

            if workspace.CurrentCamera then

                BindCamera()

            end

        end

    )

)


UpdateResponsive()


--==========================================================================--
-- BLOK 48 // PREMIUM ANIMATION ENGINE
--==========================================================================--

local AnimationRunning = true


RegisterCleanup(

    function()

        AnimationRunning = false

    end

)


local AnimationConnection =
    RunService.RenderStepped:Connect(

        function()

            if not AnimationRunning then
                return
            end


            if State.Destroyed then
                return
            end


            local time =
                os.clock()


            --==============================================================
            -- DYNAMIC ACCENT
            --==============================================================

            if Config.DynamicColors then

                local hue =
                    (
                        time
                        * Config.AccentSpeed
                    ) % 1


                local dynamic =
                    Color3.fromHSV(

                        hue,

                        0.52,

                        1

                    )


                if Config.EnableGlow then

                    OuterGlow.BackgroundColor3 =
                        dynamic

                    OuterGlow2.BackgroundColor3 =
                        dynamic

                    LogoAura.BackgroundColor3 =
                        dynamic

                    LogoRingStroke.Color =
                        dynamic

                    HeaderLine.BackgroundColor3 =
                        dynamic

                    TopScanline.BackgroundColor3 =
                        dynamic

                end

            end


            --==============================================================
            -- LOGO BREATHING
            --==============================================================

            if Config.EnableAnimations then

                local pulse =
                    1
                    + math.sin(
                        time * 2.1
                    ) * 0.025


                Logo.Size =
                    UDim2.fromOffset(

                        52 * pulse,

                        52 * pulse

                    )


                LogoRing.Rotation =
                    (
                        time * 28
                    ) % 360


                FloatingRing.Rotation =
                    (
                        time * -30
                    ) % 360

            end


            --==============================================================
            -- OUTER GLOW PULSE
            --==============================================================

            if Config.EnableGlow
                and MainHolder.Visible then

                OuterGlow.BackgroundTransparency =
                    0.88
                    + math.sin(
                        time * 1.8
                    ) * 0.025


                OuterGlow2.BackgroundTransparency =
                    0.94
                    + math.sin(
                        time * 1.4
                    ) * 0.012

            end


            --==============================================================
            -- STATUS PULSE
            --==============================================================

            if Config.EnableTelemetry then

                local statusPulse =
                    0.68
                    + math.sin(
                        time * 3
                    ) * 0.18


                TelemetryDot.BackgroundTransparency =
                    1 - statusPulse

            end


            --==============================================================
            -- SCANLINE
            --==============================================================

            if Config.EnableScanline then

                local scan =
                    (
                        time * 0.12
                    ) % 1


                TopScanline.Position =
                    UDim2.new(
                        scan,
                        -200,
                        0,
                        0
                    )

            end


            --==============================================================
            -- FLOATING BUTTON
            --==============================================================

            if FloatingButton.Visible
                and Config.EnableAnimations then

                local pulse =
                    1
                    + math.sin(
                        time * 2
                    ) * 0.025


                FloatingButton.Size =
                    UDim2.fromOffset(

                        58 * pulse,

                        58 * pulse

                    )

            end


            --==============================================================
            -- HERO BARS
            --==============================================================

            if Config.EnableTelemetry then

                for index, bar in ipairs(
                    HeroBars:GetChildren()
                ) do

                    if bar:IsA("Frame") then

                        local fill =
                            bar:FindFirstChildOfClass(
                                "Frame"
                            )


                        if fill then

                            local value =
                                0.35
                                + (
                                    math.sin(
                                        time * 1.7
                                        + index
                                    ) * 0.25
                                )


                            Tween(

                                fill,

                                {

                                    Size =
                                        UDim2.new(
                                            1,
                                            0,
                                            math.clamp(
                                                value,
                                                0.15,
                                                0.95
                                            ),
                                            0
                                        )

                                },

                                0.12,

                                Enum.EasingStyle.Linear

                            )

                        end

                    end

                end

            end

        end

    )


RegisterConnection(
    AnimationConnection
)


--==========================================================================--
-- BLOK 49 // PUBLIC API
--==========================================================================--

_G.vanz.Open = function()

    if State.Destroyed then
        return
    end


    if State.Minimized then

        Restore()

    else

        MainHolder.Visible = true

        State.Open = true

    end

end


_G.vanz.Hide = function()

    if State.Destroyed then
        return
    end


    Minimize()

end


_G.vanz.Restore = function()

    if State.Destroyed then
        return
    end


    Restore()

end


_G.vanz.SetScale = function(scale)

    if State.Destroyed then
        return
    end


    scale =
        tonumber(scale)


    if not scale then
        return
    end


    scale =
        math.clamp(
            scale,
            0.5,
            1.5
        )


    UIScale.Scale =
        scale


    Config.Scale =
        scale


    DPIValue.Text =
        string.format(
            "%d%%",
            math.floor(
                scale * 100
                + 0.5
            )
        )

end


_G.vanz.GetState = function()

    return {

        Open =
            State.Open,

        Closed =
            State.Closed,

        Destroyed =
            State.Destroyed,

        Minimized =
            State.Minimized,

        Scale =
            UIScale.Scale,

        Version =
            _G.vanz.Version,

    }

end


--==========================================================================--
-- BLOK 50 // CLEANUP SAFETY
--==========================================================================--

RegisterCleanup(

    function()

        AnimationRunning = false

    end

)


--==========================================================================--
-- BLOK 51 // STARTUP ANIMATION
--==========================================================================--

MainHolder.Visible = true

Shadow.Visible = true

OuterGlow.Visible = true

OuterGlow2.Visible = true


local FinalWidth =
    Config.Width


local FinalHeight =
    Config.Height


MainHolder.Size =
    UDim2.fromOffset(

        FinalWidth * 0.90,

        FinalHeight * 0.90

    )


MainPanel.BackgroundTransparency =
    1


Tween(

    MainHolder,

    {

        Size =
            UDim2.fromOffset(
                FinalWidth,
                FinalHeight
            ),

    },

    0.46,

    Enum.EasingStyle.Quint,

    Enum.EasingDirection.Out

)


Tween(

    MainPanel,

    {

        BackgroundTransparency =
            0,

    },

    0.32,

    Enum.EasingStyle.Quint,

    Enum.EasingDirection.Out

)


--==========================================================================--
-- BLOK 52 // FINAL INITIAL STATE
--==========================================================================--

State.Open = true

State.Closed = false

State.Destroyed = false

State.Minimized = false


print("")
print("╔════════════════════════════════════════════════════════════╗")
print("║                                                            ║")
print("║              VANZ // NEXUS CONTROL CENTER                  ║")
print("║                                                            ║")
print("║  VERSION       : 6.0.0                                    ║")
print("║  ARCHITECTURE  : ROBOTIC PREMIUM                          ║")
print("║  DEFAULT DPI   : 70%                                      ║")
print("║  DISPLAY ORDER : 999999                                   ║")
print("║  ANIMATION     : ENABLED                                  ║")
print("║  NEON CORE     : ENABLED                                  ║")
print("║  TELEMETRY     : ENABLED                                  ║")
print("║  SCANLINE      : ENABLED                                  ║")
print("║  CLEANUP       : ACTIVE                                   ║")
print("║  FORCE STOP    : READY                                    ║")
print("║                                                            ║")
print("╚════════════════════════════════════════════════════════════╝")
print("")