--[[
============================================================
 VANZ // PREMIUM CONTROL CENTER
 GUI VERSION 5
============================================================

 FITUR UTAMA:
 - Hanya 1 TAB: HOME
 - Home berisi pengaturan GUI
 - Default DPI = 70%
 - Premium animated logo
 - Animated gradient / glow
 - Premium buttons
 - Premium toggles
 - Click / hover animations
 - Sidebar tidak ketutup Content
 - Sidebar tidak perlu scroll karena hanya 1 tab
 - Minimize benar-benar menghilangkan GUI
 - Restore floating button
 - CLOSE = FORCE STOP
 - Semua registered connections diputus
 - Semua cleanup dijalankan
 - GUI dihancurkan total
 - Komentar blok untuk memudahkan upgrade

============================================================
]]

--============================================================
-- BLOK 1: SERVICES
-- TEMPAT SERVICE ROBLOX
-- Tambahkan service baru di sini kalau nanti diperlukan.
--============================================================

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")


--============================================================
-- BLOK 2: CONFIG UTAMA
-- TEMPAT PENGATURAN GLOBAL MENU
--
-- DPI DEFAULT ADA DI SINI.
-- Kalau mau default 80%, ubah Scale = 0.80
-- Kalau mau default 100%, ubah Scale = 1.00
--============================================================

_G.vanz = _G.vanz or {}

_G.vanz.Config = {

    Title = "VANZ",
    Subtitle = "PREMIUM CONTROL CENTER",

    -- DEFAULT DPI
    Scale = 0.70,

    -- Ukuran dasar GUI sebelum DPI
    Width = 820,
    Height = 520,

    -- Lebar sidebar
    SidebarWidth = 205,

    -- Margin dari layar
    ScreenMargin = 22,

    -- Dynamic color animation
    DynamicColors = true,

    -- Kecepatan animasi
    AnimationSpeed = 1,
}


--============================================================
-- BLOK 3: CLEANUP SCRIPT LAMA
-- Kalau script dijalankan ulang, GUI lama dan connection lama
-- dibersihkan terlebih dahulu.
--============================================================

do

    local oldVanz = _G.vanz

    if oldVanz then

        -- Putuskan semua connection lama
        if oldVanz.Connections then

            for _, connection in pairs(oldVanz.Connections) do

                if typeof(connection) == "RBXScriptConnection" then

                    pcall(function()
                        connection:Disconnect()
                    end)

                end

            end

        end


        -- Jalankan cleanup lama
        if oldVanz.Cleanups then

            for _, cleanup in pairs(oldVanz.Cleanups) do

                if typeof(cleanup) == "function" then

                    pcall(cleanup)

                end

            end

        end


        -- Hancurkan GUI lama
        if oldVanz.UI and oldVanz.UI.Gui then

            pcall(function()
                oldVanz.UI.Gui:Destroy()
            end)

        end

    end


    -- Backup cleanup jika masih ada GUI lama
    local oldGui = PlayerGui:FindFirstChild("VANZ_PREMIUM_GUI")

    if oldGui then

        pcall(function()
            oldGui:Destroy()
        end)

    end

end


--============================================================
-- BLOK 4: RUNTIME STATE
-- TEMPAT STATUS INTERNAL MENU
--============================================================

_G.vanz.Connections = {}
_G.vanz.Cleanups = {}

_G.vanz.UI = {}

_G.vanz.State = {

    Open = true,
    Closed = false,
    Destroyed = false,

}


local Connections = _G.vanz.Connections
local Cleanups = _G.vanz.Cleanups


--============================================================
-- BLOK 5: CONNECTION MANAGER
-- SEMUA CONNECTION FITUR SEBAIKNYA DIDAFTER DI SINI.
--
-- Contoh upgrade:
--
-- RegisterConnection(
--     SomeButton.MouseButton1Click:Connect(function()
--         ...
--     end)
-- )
--
-- Nanti tombol CLOSE akan memutus semuanya.
--============================================================

local function RegisterConnection(connection)

    if connection then

        table.insert(
            Connections,
            connection
        )

    end

    return connection

end


--============================================================
-- BLOK 6: CLEANUP MANAGER
-- TEMPAT MENDAFTARKAN CLEANUP FITUR.
--
-- Kalau nanti ada fitur yang membuat:
-- - loop
-- - connection
-- - object sementara
-- - effect
--
-- masukkan cleanup-nya ke sini.
--============================================================

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


--============================================================
-- BLOK 7: WARNA PREMIUM
-- TEMPAT GANTI TEMA WARNA MENU.
--============================================================

local Colors = {

    Background = Color3.fromRGB(7, 9, 14),

    Sidebar = Color3.fromRGB(10, 12, 18),

    Panel = Color3.fromRGB(14, 17, 25),

    Panel2 = Color3.fromRGB(18, 21, 31),

    Panel3 = Color3.fromRGB(23, 27, 39),

    Text = Color3.fromRGB(242, 245, 255),

    Muted = Color3.fromRGB(133, 141, 158),

    Soft = Color3.fromRGB(87, 96, 117),

    Accent = Color3.fromRGB(104, 126, 255),

    Accent2 = Color3.fromRGB(174, 92, 255),

    Success = Color3.fromRGB(80, 225, 155),

    Danger = Color3.fromRGB(255, 85, 105),

    White = Color3.fromRGB(255, 255, 255),

    Black = Color3.fromRGB(0, 0, 0),

    Stroke = Color3.fromRGB(39, 44, 60),

}


_G.vanz.UI.Colors = Colors


--============================================================
-- BLOK 8: UTILITY FUNCTIONS
-- Fungsi dasar untuk membuat object UI.
--============================================================

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

        CornerRadius = UDim.new(
            0,
            radius or 10
        ),

    })

end


local function AddStroke(
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

    })

end


local function AddGradient(
    parent,
    color1,
    color2,
    rotation
)

    local gradient = New("UIGradient", {

        Parent = parent,

        Color = ColorSequence.new({

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

    return gradient

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

    local tween = TweenService:Create(

        object,

        TweenInfo.new(

            duration or 0.22,

            style or Enum.EasingStyle.Quint,

            direction or Enum.EasingDirection.Out

        ),

        properties

    )

    tween:Play()

    return tween

end


--============================================================
-- BLOK 9: SCREEN GUI
-- ROOT UTAMA SEMUA UI.
--============================================================

local ScreenGui = New("ScreenGui", {

    Name = "VANZ_PREMIUM_GUI",

    Parent = PlayerGui,

    ResetOnSpawn = false,

    IgnoreGuiInset = true,

    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,

})

_G.vanz.UI.Gui = ScreenGui


--============================================================
-- BLOK 10: UI SCALE
-- SEMUA UI MENGIKUTI DPI DARI SINI.
--============================================================

local UIScale = New("UIScale", {

    Parent = ScreenGui,

    Scale = _G.vanz.Config.Scale,

})

_G.vanz.UI.UIScale = UIScale


--============================================================
-- BLOK 11: MAIN HOLDER
-- CONTAINER UTAMA MENU.
--============================================================

local MainHolder = New("Frame", {

    Name = "MainHolder",

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

        _G.vanz.Config.Width,

        _G.vanz.Config.Height

    ),

    BackgroundTransparency = 1,

    ZIndex = 10,

})

_G.vanz.UI.Main = MainHolder


--============================================================
-- BLOK 12: PREMIUM SHADOW
-- BAYANGAN LUAR MENU.
--============================================================

local Shadow = New("ImageLabel", {

    Name = "Shadow",

    Parent = MainHolder,

    AnchorPoint = Vector2.new(
        0.5,
        0.5
    ),

    Position = UDim2.new(
        0.5,
        0,
        0.5,
        8
    ),

    Size = UDim2.new(
        1,
        65,
        1,
        65
    ),

    BackgroundTransparency = 1,

    Image = "rbxassetid://1316045217",

    ImageColor3 = Colors.Black,

    ImageTransparency = 0.38,

    ScaleType = Enum.ScaleType.Slice,

    SliceCenter = Rect.new(
        10,
        10,
        118,
        118
    ),

    ZIndex = 7,

})

_G.vanz.UI.Shadow = Shadow


--============================================================
-- BLOK 13: OUTER AURA
-- GLOW LUAR MENU.
--============================================================

local OuterAura = New("Frame", {

    Name = "OuterAura",

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
        12,
        1,
        12
    ),

    BackgroundColor3 = Colors.Accent,

    BackgroundTransparency = 0.88,

    ZIndex = 8,

})

Corner(
    OuterAura,
    20
)


--============================================================
-- BLOK 14: MAIN PANEL
-- PANEL UTAMA MENU.
--============================================================

local MainPanel = New("Frame", {

    Name = "MainPanel",

    Parent = MainHolder,

    Size = UDim2.fromScale(
        1,
        1
    ),

    BackgroundColor3 = Colors.Background,

    ClipsDescendants = true,

    ZIndex = 10,

})

Corner(
    MainPanel,
    18
)

AddStroke(
    MainPanel,
    Colors.Stroke,
    1,
    0.08
)

_G.vanz.UI.MainPanel = MainPanel


--============================================================
-- BLOK 15: HEADER
-- HEADER ATAS MENU.
--============================================================

local Header = New("Frame", {

    Name = "Header",

    Parent = MainPanel,

    Size = UDim2.new(
        1,
        0,
        0,
        78
    ),

    BackgroundColor3 = Colors.Panel,

    ZIndex = 30,

})

Corner(
    Header,
    18
)


local HeaderCover = New("Frame", {

    Parent = Header,

    Position = UDim2.fromOffset(
        0,
        36
    ),

    Size = UDim2.new(
        1,
        0,
        0,
        45
    ),

    BackgroundColor3 = Colors.Panel,

    BorderSizePixel = 0,

    ZIndex = 30,

})


--============================================================
-- BLOK 16: HEADER GLOW LINE
-- Garis premium di bawah header.
--============================================================

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
        0
    ),

    Size = UDim2.new(
        1,
        0,
        0,
        1
    ),

    BackgroundColor3 = Colors.Accent,

    BackgroundTransparency = 0.5,

    BorderSizePixel = 0,

    ZIndex = 35,

})

AddGradient(

    HeaderLine,

    Colors.Accent,

    Colors.Accent2,

    0

)


--============================================================
-- BLOK 17: PREMIUM LOGO
-- LOGO BUKAN CUMA "V".
--
-- Ada:
-- - outer aura
-- - rotating ring
-- - gradient
-- - V monogram
-- - highlight
--
-- Kalau mau upgrade logo, bagian ini yang diubah.
--============================================================

local LogoHolder = New("Frame", {

    Parent = Header,

    Position = UDim2.fromOffset(
        18,
        15
    ),

    Size = UDim2.fromOffset(
        48,
        48
    ),

    BackgroundTransparency = 1,

    ZIndex = 40,

})


local LogoAura = New("Frame", {

    Parent = LogoHolder,

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
        8,
        1,
        8
    ),

    BackgroundColor3 = Colors.Accent,

    BackgroundTransparency = 0.72,

    ZIndex = 39,

})

Corner(
    LogoAura,
    18
)


local LogoBase = New("Frame", {

    Parent = LogoHolder,

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

    ZIndex = 41,

})

Corner(
    LogoBase,
    15
)

AddStroke(
    LogoBase,
    Colors.Accent,
    1,
    0.25
)

AddGradient(
    LogoBase,
    Color3.fromRGB(38, 45, 78),
    Color3.fromRGB(24, 19, 40),
    135
)


-- Ring logo
local LogoRing = New("Frame", {

    Parent = LogoHolder,

    AnchorPoint = Vector2.new(
        0.5,
        0.5
    ),

    Position = UDim2.fromScale(
        0.5,
        0.5
    ),

    Size = UDim2.fromOffset(
        38,
        38
    ),

    BackgroundTransparency = 1,

    ZIndex = 43,

})

Corner(
    LogoRing,
    20
)

local LogoRingStroke = AddStroke(
    LogoRing,
    Colors.Accent,
    1.5,
    0.1
)


-- Main V
local LogoText = New("TextLabel", {

    Parent = LogoHolder,

    AnchorPoint = Vector2.new(
        0.5,
        0.5
    ),

    Position = UDim2.fromScale(
        0.5,
        0.5
    ),

    Size = UDim2.fromScale(
        0.8,
        0.8
    ),

    BackgroundTransparency = 1,

    Text = "V",

    TextColor3 = Colors.White,

    TextSize = 25,

    Font = Enum.Font.GothamBlack,

    ZIndex = 45,

})

local LogoGradient = AddGradient(

    LogoText,

    Color3.fromRGB(
        255,
        255,
        255
    ),

    Color3.fromRGB(
        145,
        160,
        255
    ),

    90

)


-- Small shine
local LogoShine = New("Frame", {

    Parent = LogoHolder,

    Position = UDim2.fromOffset(
        10,
        8
    ),

    Size = UDim2.fromOffset(
        10,
        2
    ),

    BackgroundColor3 = Colors.White,

    BackgroundTransparency = 0.35,

    Rotation = -35,

    ZIndex = 46,

})

Corner(
    LogoShine,
    5
)


--============================================================
-- BLOK 18: TITLE
-- JUDUL MENU.
--============================================================

local Title = New("TextLabel", {

    Parent = Header,

    Position = UDim2.fromOffset(
        80,
        14
    ),

    Size = UDim2.new(
        0.5,
        0,
        0,
        26
    ),

    BackgroundTransparency = 1,

    Text = _G.vanz.Config.Title,

    TextColor3 = Colors.Text,

    TextSize = 20,

    Font = Enum.Font.GothamBlack,

    TextXAlignment = Enum.TextXAlignment.Left,

    ZIndex = 40,

})


local Subtitle = New("TextLabel", {

    Parent = Header,

    Position = UDim2.fromOffset(
        81,
        38
    ),

    Size = UDim2.new(
        0.5,
        0,
        0,
        17
    ),

    BackgroundTransparency = 1,

    Text = _G.vanz.Config.Subtitle,

    TextColor3 = Colors.Muted,

    TextSize = 9,

    Font = Enum.Font.GothamMedium,

    TextXAlignment = Enum.TextXAlignment.Left,

    ZIndex = 40,

})


--============================================================
-- BLOK 19: ONLINE STATUS
-- Status pill kanan atas.
--============================================================

local Status = New("Frame", {

    Parent = Header,

    AnchorPoint = Vector2.new(
        1,
        0.5
    ),

    Position = UDim2.new(
        1,
        -92,
        0.5,
        0
    ),

    Size = UDim2.fromOffset(
        82,
        30
    ),

    BackgroundColor3 = Colors.Panel3,

    ZIndex = 40,

})

Corner(
    Status,
    10
)

AddStroke(
    Status,
    Colors.Success,
    1,
    0.55
)


local StatusDot = New("Frame", {

    Parent = Status,

    Position = UDim2.fromOffset(
        10,
        11
    ),

    Size = UDim2.fromOffset(
        8,
        8
    ),

    BackgroundColor3 = Colors.Success,

    ZIndex = 42,

})

Corner(
    StatusDot,
    10
)


local StatusText = New("TextLabel", {

    Parent = Status,

    Position = UDim2.fromOffset(
        24,
        0
    ),

    Size = UDim2.new(
        1,
        -27,
        1,
        0
    ),

    BackgroundTransparency = 1,

    Text = "ONLINE",

    TextColor3 = Colors.Text,

    TextSize = 9,

    Font = Enum.Font.GothamBold,

    TextXAlignment = Enum.TextXAlignment.Left,

    ZIndex = 42,

})


--============================================================
-- BLOK 20: MINIMIZE BUTTON
-- Tombol minimize.
--============================================================

local MinimizeButton = New("TextButton", {

    Parent = Header,

    AnchorPoint = Vector2.new(
        1,
        0.5
    ),

    Position = UDim2.new(
        1,
        -52,
        0.5,
        0
    ),

    Size = UDim2.fromOffset(
        34,
        34
    ),

    BackgroundColor3 = Colors.Panel3,

    Text = "−",

    TextColor3 = Colors.Muted,

    TextSize = 18,

    Font = Enum.Font.GothamBold,

    AutoButtonColor = false,

    ZIndex = 45,

})

Corner(
    MinimizeButton,
    10
)

AddStroke(
    MinimizeButton,
    Colors.Stroke,
    1,
    0.15
)


--============================================================
-- BLOK 21: CLOSE BUTTON
-- Close = FORCE STOP.
--============================================================

local CloseButton = New("TextButton", {

    Parent = Header,

    AnchorPoint = Vector2.new(
        1,
        0.5
    ),

    Position = UDim2.new(
        1,
        -11,
        0.5,
        0
    ),

    Size = UDim2.fromOffset(
        34,
        34
    ),

    BackgroundColor3 = Colors.Panel3,

    Text = "×",

    TextColor3 = Colors.Muted,

    TextSize = 20,

    Font = Enum.Font.GothamBold,

    AutoButtonColor = false,

    ZIndex = 45,

})

Corner(
    CloseButton,
    10
)

AddStroke(
    CloseButton,
    Colors.Stroke,
    1,
    0.15
)


--============================================================
-- BLOK 22: BODY
-- Area sidebar + content.
--============================================================

local Body = New("Frame", {

    Parent = MainPanel,

    Position = UDim2.fromOffset(
        0,
        78
    ),

    Size = UDim2.new(
        1,
        0,
        1,
        -78
    ),

    BackgroundTransparency = 1,

    ClipsDescendants = true,

    ZIndex = 20,

})


--============================================================
-- BLOK 23: SIDEBAR
-- Hanya satu tab Home.
--============================================================

local Sidebar = New("Frame", {

    Parent = Body,

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


--============================================================
-- BLOK 24: SIDEBAR HEADER
--============================================================

local NavigationTitle = New("TextLabel", {

    Parent = Sidebar,

    Position = UDim2.fromOffset(
        17,
        16
    ),

    Size = UDim2.new(
        1,
        -34,
        0,
        20
    ),

    BackgroundTransparency = 1,

    Text = "NAVIGATION",

    TextColor3 = Colors.Muted,

    TextSize = 9,

    Font = Enum.Font.GothamBold,

    TextXAlignment = Enum.TextXAlignment.Left,

    ZIndex = 25,

})


--============================================================
-- BLOK 25: SIDEBAR TAB AREA
-- Tempat semua tab.
--
-- Sekarang cuma HOME.
-- Kalau nanti mau tambah tab:
--
-- 1. Buat page
-- 2. Buat button
-- 3. Masukkan ke sini
--============================================================

local TabArea = New("Frame", {

    Parent = Sidebar,

    Position = UDim2.fromOffset(
        10,
        48
    ),

    Size = UDim2.new(
        1,
        -20,
        0,
        52
    ),

    BackgroundTransparency = 1,

    ZIndex = 22,

})


--============================================================
-- BLOK 26: SIDEBAR TAB HOME
--============================================================

local HomeTab = New("TextButton", {

    Parent = TabArea,

    Size = UDim2.new(
        1,
        0,
        0,
        46
    ),

    BackgroundColor3 = Colors.Panel2,

    Text = "",

    AutoButtonColor = false,

    ZIndex = 25,

})

Corner(
    HomeTab,
    11
)

AddStroke(
    HomeTab,
    Colors.Accent,
    1,
    0.45
)


local HomeAccent = New("Frame", {

    Parent = HomeTab,

    Position = UDim2.fromOffset(
        0,
        8
    ),

    Size = UDim2.fromOffset(
        3,
        30
    ),

    BackgroundColor3 = Colors.Accent,

    ZIndex = 27,

})

Corner(
    HomeAccent,
    5
)


-- Home icon container
local HomeIcon = New("Frame", {

    Parent = HomeTab,

    Position = UDim2.fromOffset(
        11,
        8
    ),

    Size = UDim2.fromOffset(
        30,
        30
    ),

    BackgroundColor3 = Colors.Panel3,

    ZIndex = 27,

})

Corner(
    HomeIcon,
    9
)


local HomeIconText = New("TextLabel", {

    Parent = HomeIcon,

    Size = UDim2.fromScale(
        1,
        1
    ),

    BackgroundTransparency = 1,

    Text = "⌂",

    TextColor3 = Colors.Accent,

    TextSize = 16,

    Font = Enum.Font.GothamBold,

    ZIndex = 28,

})


local HomeText = New("TextLabel", {

    Parent = HomeTab,

    Position = UDim2.fromOffset(
        51,
        0
    ),

    Size = UDim2.new(
        1,
        -60,
        1,
        0
    ),

    BackgroundTransparency = 1,

    Text = "Home",

    TextColor3 = Colors.Text,

    TextSize = 11,

    Font = Enum.Font.GothamBold,

    TextXAlignment = Enum.TextXAlignment.Left,

    ZIndex = 27,

})


--============================================================
-- BLOK 27: SIDEBAR DIVIDER
--============================================================

local SidebarDivider = New("Frame", {

    Parent = Body,

    Position = UDim2.new(
        0,
        _G.vanz.Config.SidebarWidth,
        0,
        0
    ),

    Size = UDim2.new(
        0,
        1,
        1,
        0
    ),

    BackgroundColor3 = Colors.Stroke,

    BackgroundTransparency = 0.4,

    BorderSizePixel = 0,

    ZIndex = 28,

})


--============================================================
-- BLOK 28: CONTENT AREA
-- SEMUA ISI HOME ADA DI SINI.
--============================================================

local Content = New("Frame", {

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

    ClipsDescendants = true,

    ZIndex = 20,

})

_G.vanz.UI.Content = Content


--============================================================
-- BLOK 29: HOME PAGE
-- SATU-SATUNYA PAGE.
--
-- Kalau nanti mau tambah fitur GUI:
-- tambahkan section di bawah ini.
--============================================================

local HomePage = New("ScrollingFrame", {

    Name = "HomePage",

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

    ScrollBarThickness = 4,

    ScrollBarImageColor3 = Colors.Accent,

    ScrollBarImageTransparency = 0.3,

    ZIndex = 22,

})

local HomePadding = New("UIPadding", {

    Parent = HomePage,

    PaddingLeft = UDim.new(
        0,
        20
    ),

    PaddingRight = UDim.new(
        0,
        20
    ),

    PaddingTop = UDim.new(
        0,
        20
    ),

    PaddingBottom = UDim.new(
        0,
        25
    ),

})


local HomeLayout = New("UIListLayout", {

    Parent = HomePage,

    Padding = UDim.new(
        0,
        13
    ),

    SortOrder = Enum.SortOrder.LayoutOrder,

})


--============================================================
-- BLOK 30: HOME HERO CARD
-- Bagian welcome premium.
--============================================================

local Hero = New("Frame", {

    Parent = HomePage,

    Size = UDim2.new(
        1,
        0,
        0,
        112
    ),

    BackgroundColor3 = Colors.Panel,

    ZIndex = 23,

})

Corner(
    Hero,
    14
)

AddStroke(
    Hero,
    Colors.Stroke,
    1,
    0.15
)


local HeroGradient = AddGradient(

    Hero,

    Color3.fromRGB(
        19,
        23,
        38
    ),

    Color3.fromRGB(
        20,
        15,
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
        10,
        0.5,
        0
    ),

    Size = UDim2.fromOffset(
        150,
        150
    ),

    BackgroundColor3 = Colors.Accent,

    BackgroundTransparency = 0.93,

    ZIndex = 23,

})

Corner(
    HeroGlow,
    80
)


local HeroTitle = New("TextLabel", {

    Parent = Hero,

    Position = UDim2.fromOffset(
        18,
        17
    ),

    Size = UDim2.new(
        1,
        -36,
        0,
        28
    ),

    BackgroundTransparency = 1,

    Text = "Welcome back.",

    TextColor3 = Colors.Text,

    TextSize = 20,

    Font = Enum.Font.GothamBlack,

    TextXAlignment = Enum.TextXAlignment.Left,

    ZIndex = 26,

})


local HeroText = New("TextLabel", {

    Parent = Hero,

    Position = UDim2.fromOffset(
        19,
        47
    ),

    Size = UDim2.new(
        1,
        -38,
        0,
        40
    ),

    BackgroundTransparency = 1,

    Text = "Control your VANZ interface from one clean premium panel.",

    TextColor3 = Colors.Muted,

    TextSize = 10,

    Font = Enum.Font.GothamMedium,

    TextWrapped = true,

    TextXAlignment = Enum.TextXAlignment.Left,

    TextYAlignment = Enum.TextYAlignment.Top,

    ZIndex = 26,

})


--============================================================
-- BLOK 31: SECTION TITLE
--============================================================

local SettingsTitle = New("TextLabel", {

    Parent = HomePage,

    Size = UDim2.new(
        1,
        0,
        0,
        25
    ),

    BackgroundTransparency = 1,

    Text = "INTERFACE SETTINGS",

    TextColor3 = Colors.Text,

    TextSize = 13,

    Font = Enum.Font.GothamBold,

    TextXAlignment = Enum.TextXAlignment.Left,

    ZIndex = 24,

})


--============================================================
-- BLOK 32: DPI CARD
-- TEMPAT PENGATURAN DPI.
--
-- DEFAULT = 70%
--============================================================

local DPICard = New("Frame", {

    Parent = HomePage,

    Size = UDim2.new(
        1,
        0,
        0,
        88
    ),

    BackgroundColor3 = Colors.Panel,

    ZIndex = 23,

})

Corner(
    DPICard,
    13
)

AddStroke(
    DPICard,
    Colors.Stroke,
    1,
    0.22
)


local DPIIcon = New("Frame", {

    Parent = DPICard,

    Position = UDim2.fromOffset(
        14,
        20
    ),

    Size = UDim2.fromOffset(
        45,
        45
    ),

    BackgroundColor3 = Colors.Panel3,

    ZIndex = 25,

})

Corner(
    DPIIcon,
    12
)

AddStroke(
    DPIIcon,
    Colors.Accent,
    1,
    0.55
)


local DPIIconText = New("TextLabel", {

    Parent = DPIIcon,

    Size = UDim2.fromScale(
        1,
        1
    ),

    BackgroundTransparency = 1,

    Text = "A",

    TextColor3 = Colors.Accent,

    TextSize = 18,

    Font = Enum.Font.GothamBlack,

    ZIndex = 26,

})


local DPITitle = New("TextLabel", {

    Parent = DPICard,

    Position = UDim2.fromOffset(
        73,
        16
    ),

    Size = UDim2.new(
        0.45,
        0,
        0,
        20
    ),

    BackgroundTransparency = 1,

    Text = "Interface Scale",

    TextColor3 = Colors.Text,

    TextSize = 12,

    Font = Enum.Font.GothamBold,

    TextXAlignment = Enum.TextXAlignment.Left,

    ZIndex = 25,

})


local DPISubtitle = New("TextLabel", {

    Parent = DPICard,

    Position = UDim2.fromOffset(
        73,
        38
    ),

    Size = UDim2.new(
        0.45,
        0,
        0,
        25
    ),

    BackgroundTransparency = 1,

    Text = "Adjust the entire interface size.",

    TextColor3 = Colors.Muted,

    TextSize = 9,

    Font = Enum.Font.GothamMedium,

    TextXAlignment = Enum.TextXAlignment.Left,

    ZIndex = 25,

})


local DPIValue = New("TextLabel", {

    Parent = DPICard,

    AnchorPoint = Vector2.new(
        1,
        0
    ),

    Position = UDim2.new(
        1,
        -16,
        0,
        17
    ),

    Size = UDim2.fromOffset(
        70,
        23
    ),

    BackgroundTransparency = 1,

    Text = "70%",

    TextColor3 = Colors.Accent,

    TextSize = 13,

    Font = Enum.Font.GothamBlack,

    TextXAlignment = Enum.TextXAlignment.Right,

    ZIndex = 25,

})


--============================================================
-- BLOK 33: DPI BUTTONS
-- Klik untuk ganti scale.
--============================================================

local DPIButtonHolder = New("Frame", {

    Parent = DPICard,

    AnchorPoint = Vector2.new(
        1,
        1
    ),

    Position = UDim2.new(
        1,
        -14,
        1,
        -12
    ),

    Size = UDim2.fromOffset(
        270,
        28
    ),

    BackgroundTransparency = 1,

    ZIndex = 25,

})


local DPIList = New("UIListLayout", {

    Parent = DPIButtonHolder,

    FillDirection = Enum.FillDirection.Horizontal,

    HorizontalAlignment = Enum.HorizontalAlignment.Right,

    VerticalAlignment = Enum.VerticalAlignment.Center,

    Padding = UDim.new(
        0,
        5
    ),

})


--============================================================
-- BLOK 34: DPI OPTIONS
-- Tambahkan pilihan DPI di tabel ini.
--============================================================

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


local function UpdateDPIVisual(selectedButton, text)

    DPIValue.Text = text

    for _, data in pairs(DPIButtons) do

        if data.Button == selectedButton then

            Tween(
                data.Button,
                {
                    BackgroundColor3 = Colors.Accent,
                },
                0.16
            )

            Tween(
                data.Label,
                {
                    TextColor3 = Colors.White,
                },
                0.16
            )

        else

            Tween(
                data.Button,
                {
                    BackgroundColor3 = Colors.Panel3,
                },
                0.16
            )

            Tween(
                data.Label,
                {
                    TextColor3 = Colors.Muted,
                },
                0.16
            )

        end

    end

end


for _, option in ipairs(DPIOptions) do

    local button = New("TextButton", {

        Parent = DPIButtonHolder,

        Size = UDim2.fromOffset(
            40,
            26
        ),

        BackgroundColor3 = Colors.Panel3,

        Text = "",

        AutoButtonColor = false,

        ZIndex = 27,

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

        TextSize = 8,

        Font = Enum.Font.GothamBold,

        ZIndex = 28,

    })


    local data = {

        Button = button,
        Label = label,

    }

    table.insert(
        DPIButtons,
        data
    )


    RegisterConnection(
        button.MouseButton1Click:Connect(
            function()

                if _G.vanz.State.Destroyed then
                    return
                end

                UIScale.Scale = option.Value

                _G.vanz.Config.Scale = option.Value

                UpdateDPIVisual(
                    button,
                    option.Name
                )

            end
        )
    )


    RegisterConnection(
        button.MouseEnter:Connect(
            function()

                if _G.vanz.State.Destroyed then
                    return
                end

                if UIScale.Scale ~= option.Value then

                    Tween(
                        button,
                        {
                            BackgroundColor3 = Colors.Panel2,
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

                if _G.vanz.State.Destroyed then
                    return
                end

                if UIScale.Scale ~= option.Value then

                    Tween(
                        button,
                        {
                            BackgroundColor3 = Colors.Panel3,
                        },
                        0.12
                    )

                end

            end
        )
    )

end


-- Default 70%
UpdateDPIVisual(
    DPIButtons[3].Button,
    "70%"
)


--============================================================
-- BLOK 35: PREMIUM TOGGLE
-- Contoh toggle GUI.
--
-- Default ON sesuai request.
--============================================================

local ToggleTitle = New("TextLabel", {

    Parent = HomePage,

    Size = UDim2.new(
        1,
        0,
        0,
        25
    ),

    BackgroundTransparency = 1,

    Text = "INTERFACE FEATURES",

    TextColor3 = Colors.Text,

    TextSize = 13,

    Font = Enum.Font.GothamBold,

    TextXAlignment = Enum.TextXAlignment.Left,

    ZIndex = 24,

})


--============================================================
-- BLOK 36: TOGGLE FACTORY
-- Tempat upgrade behavior toggle.
--============================================================

local function CreatePremiumToggle(

    parent,

    title,

    description,

    defaultState,

    callback

)

    local state = defaultState == true


    local card = New("TextButton", {

        Parent = parent,

        Size = UDim2.new(
            1,
            0,
            0,
            72
        ),

        BackgroundColor3 = Colors.Panel,

        Text = "",

        AutoButtonColor = false,

        ZIndex = 24,

    })

    Corner(
        card,
        13
    )

    AddStroke(
        card,
        Colors.Stroke,
        1,
        0.22
    )


    local indicator = New("Frame", {

        Parent = card,

        Position = UDim2.fromOffset(
            14,
            18
        ),

        Size = UDim2.fromOffset(
            5,
            36
        ),

        BackgroundColor3 = Colors.Accent,

        ZIndex = 26,

    })

    Corner(
        indicator,
        5
    )


    local titleLabel = New("TextLabel", {

        Parent = card,

        Position = UDim2.fromOffset(
            31,
            13
        ),

        Size = UDim2.new(
            1,
            -130,
            0,
            21
        ),

        BackgroundTransparency = 1,

        Text = title,

        TextColor3 = Colors.Text,

        TextSize = 11,

        Font = Enum.Font.GothamBold,

        TextXAlignment = Enum.TextXAlignment.Left,

        ZIndex = 26,

    })


    local descLabel = New("TextLabel", {

        Parent = card,

        Position = UDim2.fromOffset(
            31,
            35
        ),

        Size = UDim2.new(
            1,
            -130,
            0,
            22
        ),

        BackgroundTransparency = 1,

        Text = description,

        TextColor3 = Colors.Muted,

        TextSize = 9,

        Font = Enum.Font.GothamMedium,

        TextXAlignment = Enum.TextXAlignment.Left,

        ZIndex = 26,

    })


    -- Toggle outer
    local toggle = New("Frame", {

        Parent = card,

        AnchorPoint = Vector2.new(
            1,
            0.5
        ),

        Position = UDim2.new(
            1,
            -16,
            0.5,
            0
        ),

        Size = UDim2.fromOffset(
            54,
            30
        ),

        BackgroundColor3 = Colors.Panel3,

        ZIndex = 28,

    })

    Corner(
        toggle,
        20
    )

    local toggleStroke = AddStroke(
        toggle,
        Colors.Stroke,
        1,
        0.1
    )


    -- Toggle knob
    local knob = New("Frame", {

        Parent = toggle,

        Position = UDim2.fromOffset(
            4,
            4
        ),

        Size = UDim2.fromOffset(
            22,
            22
        ),

        BackgroundColor3 = Colors.Muted,

        ZIndex = 30,

    })

    Corner(
        knob,
        20
    )


    -- Tiny shine on knob
    local knobShine = New("Frame", {

        Parent = knob,

        Position = UDim2.fromOffset(
            5,
            4
        ),

        Size = UDim2.fromOffset(
            7,
            3
        ),

        BackgroundColor3 = Colors.White,

        BackgroundTransparency = 0.5,

        Rotation = -25,

        ZIndex = 31,

    })

    Corner(
        knobShine,
        5
    )


    -- Status text
    local status = New("TextLabel", {

        Parent = card,

        AnchorPoint = Vector2.new(
            1,
            0
        ),

        Position = UDim2.new(
            1,
            -80,
            0,
            9
        ),

        Size = UDim2.fromOffset(
            35,
            14
        ),

        BackgroundTransparency = 1,

        Text = "ON",

        TextColor3 = Colors.Success,

        TextSize = 7,

        Font = Enum.Font.GothamBold,

        TextXAlignment = Enum.TextXAlignment.Right,

        ZIndex = 30,

    })


    local function Render()

        if state then

            Tween(
                toggle,
                {
                    BackgroundColor3 = Colors.Accent,
                },
                0.2
            )

            Tween(
                knob,
                {
                    Position = UDim2.new(
                        1,
                        -26,
                        0,
                        4
                    ),

                    BackgroundColor3 = Colors.White,
                },
                0.24,
                Enum.EasingStyle.Back
            )

            Tween(
                indicator,
                {
                    BackgroundColor3 = Colors.Accent,
                },
                0.2
            )

            Tween(
                status,
                {
                    TextColor3 = Colors.Success,
                },
                0.2
            )

            status.Text = "ON"

            toggleStroke.Color = Colors.Accent

        else

            Tween(
                toggle,
                {
                    BackgroundColor3 = Colors.Panel3,
                },
                0.2
            )

            Tween(
                knob,
                {
                    Position = UDim2.fromOffset(
                        4,
                        4
                    ),

                    BackgroundColor3 = Colors.Muted,
                },
                0.22,
                Enum.EasingStyle.Back
            )

            Tween(
                indicator,
                {
                    BackgroundColor3 = Colors.Soft,
                },
                0.2
            )

            Tween(
                status,
                {
                    TextColor3 = Colors.Muted,
                },
                0.2
            )

            status.Text = "OFF"

            toggleStroke.Color = Colors.Stroke

        end

    end


    Render()


    -- Hover
    RegisterConnection(
        card.MouseEnter:Connect(
            function()

                if _G.vanz.State.Destroyed then
                    return
                end

                Tween(
                    card,
                    {
                        BackgroundColor3 = Colors.Panel2,
                    },
                    0.14
                )

                Tween(
                    card,
                    {
                        Size = UDim2.new(
                            1,
                            2,
                            0,
                            72
                        ),
                    },
                    0.14
                )

            end
        )
    )


    RegisterConnection(
        card.MouseLeave:Connect(
            function()

                if _G.vanz.State.Destroyed then
                    return
                end

                Tween(
                    card,
                    {
                        BackgroundColor3 = Colors.Panel,
                    },
                    0.14
                )

                Tween(
                    card,
                    {
                        Size = UDim2.new(
                            1,
                            0,
                            0,
                            72
                        ),
                    },
                    0.14
                )

            end
        )
    )


    -- Click
    RegisterConnection(
        card.MouseButton1Click:Connect(
            function()

                if _G.vanz.State.Destroyed then
                    return
                end

                state = not state

                -- Click bounce
                Tween(
                    knob,
                    {
                        Size = UDim2.fromOffset(
                            25,
                            25
                        ),
                    },
                    0.08
                )

                task.delay(
                    0.08,
                    function()

                        if _G.vanz.State.Destroyed then
                            return
                        end

                        Tween(
                            knob,
                            {
                                Size = UDim2.fromOffset(
                                    22,
                                    22
                                ),
                            },
                            0.12,
                            Enum.EasingStyle.Back
                        )

                    end
                )

                Render()


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

            if _G.vanz.State.Destroyed then
                return
            end

            state = value == true

            Render()

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


--============================================================
-- BLOK 37: DEFAULT GUI TOGGLES
-- Semua default ON.
--
-- Ini tempat paling gampang untuk menambah setting GUI.
--============================================================

local ToggleAnimations = CreatePremiumToggle(

    HomePage,

    "Premium Animations",

    "Enable menu transitions and visual effects.",

    true,

    function(enabled)

        print(
            "[VANZ] Premium Animations:",
            enabled
        )

    end

)


local ToggleGlow = CreatePremiumToggle(

    HomePage,

    "Dynamic Glow",

    "Enable the animated accent glow around the interface.",

    true,

    function(enabled)

        print(
            "[VANZ] Dynamic Glow:",
            enabled
        )

    end

)


local ToggleClickFX = CreatePremiumToggle(

    HomePage,

    "Click Feedback",

    "Enable button click bounce and interaction feedback.",

    true,

    function(enabled)

        print(
            "[VANZ] Click Feedback:",
            enabled
        )

    end

)


--============================================================
-- BLOK 38: HOME TAB INTERACTION
--============================================================

RegisterConnection(

    HomeTab.MouseEnter:Connect(
        function()

            if _G.vanz.State.Destroyed then
                return
            end

            Tween(
                HomeTab,
                {
                    BackgroundColor3 = Colors.Panel3,
                },
                0.14
            )

        end
    )

)


RegisterConnection(

    HomeTab.MouseLeave:Connect(
        function()

            if _G.vanz.State.Destroyed then
                return
            end

            Tween(
                HomeTab,
                {
                    BackgroundColor3 = Colors.Panel2,
                },
                0.14
            )

        end
    )

)


--============================================================
-- BLOK 39: DRAG SYSTEM
-- Header bisa dipakai untuk memindahkan menu.
--============================================================

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

                if _G.vanz.State.Destroyed then
                    return
                end

                if input.UserInputType
                    == Enum.UserInputType.MouseButton1

                    or input.UserInputType
                    == Enum.UserInputType.Touch then

                    dragging = true

                    dragStart = input.Position

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

                if _G.vanz.State.Destroyed then
                    return
                end

                if input.UserInputType
                    ~= Enum.UserInputType.MouseMovement

                    and input.UserInputType
                    ~= Enum.UserInputType.Touch then

                    return

                end


                local delta =
                    input.Position - dragStart


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

                if input.UserInputType
                    == Enum.UserInputType.MouseButton1

                    or input.UserInputType
                    == Enum.UserInputType.Touch then

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


--============================================================
-- BLOK 40: FLOATING RESTORE BUTTON
-- Muncul ketika menu di-minimize.
--============================================================

local FloatingButton = New("TextButton", {

    Name = "FloatingButton",

    Parent = ScreenGui,

    Position = UDim2.new(
        0,
        22,
        0.5,
        -27
    ),

    Size = UDim2.fromOffset(
        54,
        54
    ),

    BackgroundColor3 = Colors.Panel3,

    Text = "",

    AutoButtonColor = false,

    Visible = false,

    ZIndex = 100,

})

Corner(
    FloatingButton,
    17
)

AddStroke(
    FloatingButton,
    Colors.Accent,
    1,
    0.1
)


local FloatingGradient = AddGradient(

    FloatingButton,

    Color3.fromRGB(
        40,
        48,
        88
    ),

    Color3.fromRGB(
        29,
        20,
        55
    ),

    135

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

    TextSize = 22,

    Font = Enum.Font.GothamBlack,

    ZIndex = 103,

})


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
        38,
        38
    ),

    BackgroundTransparency = 1,

    ZIndex = 104,

})

Corner(
    FloatingRing,
    20
)

AddStroke(
    FloatingRing,
    Colors.Accent,
    1,
    0.15
)


--============================================================
-- BLOK 41: MINIMIZE / RESTORE
--============================================================

local IsMinimized = false


local function Minimize()

    if _G.vanz.State.Destroyed then
        return
    end

    if IsMinimized then
        return
    end

    IsMinimized = true


    -- Hilangkan shadow supaya tidak meninggalkan bekas
    Shadow.Visible = false

    OuterAura.Visible = false


    -- Shrink animation
    Tween(

        MainHolder,

        {

            Size = UDim2.fromOffset(
                _G.vanz.Config.Width,
                0
            ),

            BackgroundTransparency = 1,

        },

        0.24,

        Enum.EasingStyle.Quint,

        Enum.EasingDirection.In

    )


    task.delay(

        0.19,

        function()

            if _G.vanz.State.Destroyed then
                return
            end

            MainHolder.Visible = false

            FloatingButton.Visible = true

            -- Reset size untuk restore
            MainHolder.Size = UDim2.fromOffset(

                _G.vanz.Config.Width,

                _G.vanz.Config.Height

            )

        end

    )

end


local function Restore()

    if _G.vanz.State.Destroyed then
        return
    end

    if not IsMinimized then
        return
    end

    IsMinimized = false


    FloatingButton.Visible = false

    MainHolder.Visible = true

    Shadow.Visible = true

    OuterAura.Visible = true


    MainHolder.Size = UDim2.fromOffset(

        _G.vanz.Config.Width,

        0

    )


    Tween(

        MainHolder,

        {

            Size = UDim2.fromOffset(

                _G.vanz.Config.Width,

                _G.vanz.Config.Height

            ),

            BackgroundTransparency = 0,

        },

        0.3,

        Enum.EasingStyle.Quint,

        Enum.EasingDirection.Out

    )

end


--============================================================
-- BLOK 42: MINIMIZE BUTTON EFFECT
--============================================================

RegisterConnection(

    MinimizeButton.MouseEnter:Connect(

        function()

            if _G.vanz.State.Destroyed then
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

                0.14

            )

        end

    )

)


RegisterConnection(

    MinimizeButton.MouseLeave:Connect(

        function()

            if _G.vanz.State.Destroyed then
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

                0.14

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


--============================================================
-- BLOK 43: FLOATING BUTTON EFFECT
--============================================================

RegisterConnection(

    FloatingButton.MouseEnter:Connect(

        function()

            if _G.vanz.State.Destroyed then
                return
            end

            Tween(

                FloatingButton,

                {

                    Size = UDim2.fromOffset(
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

    FloatingButton.MouseLeave:Connect(

        function()

            if _G.vanz.State.Destroyed then
                return
            end

            Tween(

                FloatingButton,

                {

                    Size = UDim2.fromOffset(
                        54,
                        54
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


--============================================================
-- BLOK 44: FORCE STOP
--
-- CLOSE TIDAK SEKADAR HIDE GUI.
--
-- URUTANNYA:
-- 1. Mark destroyed
-- 2. Stop connections
-- 3. Run cleanup
-- 4. Disable GUI
-- 5. Destroy GUI
-- 6. Clear references
--
-- Jadi menu benar-benar unload.
--============================================================

local function ForceStop()

    if _G.vanz.State.Destroyed then
        return
    end


    print(
        "[VANZ] FORCE STOP..."
    )


    -- Mark state
    _G.vanz.State.Destroyed = true

    _G.vanz.State.Closed = true

    _G.vanz.State.Open = false


    --========================================================
    -- STEP 1: DISCONNECT
    --========================================================

    for index = #Connections, 1, -1 do

        local connection =
            Connections[index]


        if typeof(connection)
            == "RBXScriptConnection" then

            pcall(

                function()

                    connection:Disconnect()

                end

            )

        end


        Connections[index] = nil

    end


    --========================================================
    -- STEP 2: CLEANUP
    --========================================================

    for index = #Cleanups, 1, -1 do

        local cleanup =
            Cleanups[index]


        if typeof(cleanup)
            == "function" then

            pcall(cleanup)

        end


        Cleanups[index] = nil

    end


    --========================================================
    -- STEP 3: DISABLE GUI
    --========================================================

    pcall(

        function()

            ScreenGui.Enabled = false

        end

    )


    --========================================================
    -- STEP 4: DESTROY GUI
    --========================================================

    pcall(

        function()

            ScreenGui:Destroy()

        end

    )


    --========================================================
    -- STEP 5: CLEAR REFERENCES
    --========================================================

    _G.vanz.UI = {}

    _G.vanz.Connections = {}

    _G.vanz.Cleanups = {}


    print(
        "[VANZ] FORCE STOP COMPLETE."
    )

end


_G.vanz.ForceStop = ForceStop
_G.vanz.Close = ForceStop


--============================================================
-- BLOK 45: CLOSE BUTTON EFFECT
--============================================================

RegisterConnection(

    CloseButton.MouseEnter:Connect(

        function()

            if _G.vanz.State.Destroyed then
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

                0.14

            )

        end

    )

)


RegisterConnection(

    CloseButton.MouseLeave:Connect(

        function()

            if _G.vanz.State.Destroyed then
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

                0.14

            )

        end

    )

)


RegisterConnection(

    CloseButton.MouseButton1Click:Connect(

        function()

            ForceStop()

        end

    )

)


--============================================================
-- BLOK 46: RESPONSIVE SYSTEM
-- Menyesuaikan ukuran dengan layar.
--============================================================

local function UpdateResponsive()

    if _G.vanz.State.Destroyed then
        return
    end


    local camera =
        workspace.CurrentCamera


    if not camera then
        return
    end


    local viewport =
        camera.ViewportSize


    local width = math.min(

        _G.vanz.Config.Width,

        math.max(

            620,

            viewport.X
                - (
                    _G.vanz.Config.ScreenMargin
                    * 2
                )

        )

    )


    local height = math.min(

        _G.vanz.Config.Height,

        math.max(

            400,

            viewport.Y
                - (
                    _G.vanz.Config.ScreenMargin
                    * 2
                )

        )

    )


    MainHolder.Size =
        UDim2.fromOffset(
            width,
            height
        )

end


if workspace.CurrentCamera then

    RegisterConnection(

        workspace.CurrentCamera
            :GetPropertyChangedSignal(
                "ViewportSize"
            )
            :Connect(
                UpdateResponsive
            )

    )

end


UpdateResponsive()


--============================================================
-- BLOK 47: PREMIUM ANIMATION ENGINE
--
-- Semua animasi global ada di sini.
--
-- Kalau nanti mau menambah:
-- - rotating logo
-- - glow
-- - gradient
-- - pulse
--
-- bagian ini tempatnya.
--============================================================

local AnimationRunning = true


RegisterCleanup(

    function()

        AnimationRunning = false

    end

)


RegisterConnection(

    RunService.RenderStepped:Connect(

        function()

            if not AnimationRunning then
                return
            end


            if _G.vanz.State.Destroyed then
                return
            end


            local time =
                os.clock()


            --================================================
            -- Dynamic color
            --================================================

            if _G.vanz.Config.DynamicColors then

                local hue =
                    (
                        time * 0.025
                    ) % 1


                local dynamic =
                    Color3.fromHSV(

                        hue,

                        0.48,

                        1

                    )


                OuterAura.BackgroundColor3 =
                    dynamic

                LogoAura.BackgroundColor3 =
                    dynamic

                LogoRingStroke.Color =
                    dynamic

                HeaderLine.BackgroundColor3 =
                    dynamic

            end


            --================================================
            -- Logo breathing
            --================================================

            local pulse =
                1
                + math.sin(
                    time * 2.2
                ) * 0.025


            LogoHolder.Size =
                UDim2.fromOffset(

                    48 * pulse,

                    48 * pulse

                )


            --================================================
            -- Logo ring rotation
            --================================================

            LogoRing.Rotation =
                (time * 20) % 360


            FloatingRing.Rotation =
                (time * -20) % 360


            --================================================
            -- Outer aura pulse
            --================================================

            if MainHolder.Visible then

                OuterAura.BackgroundTransparency =
                    0.87
                    + math.sin(
                        time * 1.6
                    ) * 0.025

            end


            --================================================
            -- Status dot pulse
            --================================================

            local statusPulse =
                0.75
                + (
                    math.sin(
                        time * 3
                    ) * 0.15
                )


            StatusDot.BackgroundTransparency =
                1 - statusPulse


            --================================================
            -- Floating button pulse
            --================================================

            if FloatingButton.Visible then

                local floatingPulse =
                    1
                    + math.sin(
                        time * 2
                    ) * 0.025


                FloatingButton.Size =
                    UDim2.fromOffset(

                        54 * floatingPulse,

                        54 * floatingPulse

                    )

            end

        end

    )

)


--============================================================
-- BLOK 48: PUBLIC API
-- API yang bisa dipanggil dari script lain.
--============================================================

_G.vanz.Open = function()

    if _G.vanz.State.Destroyed then
        return
    end

    if IsMinimized then

        Restore()

    else

        MainHolder.Visible = true

    end

end


_G.vanz.Hide = function()

    if _G.vanz.State.Destroyed then
        return
    end

    Minimize()

end


_G.vanz.SetScale = function(scale)

    if _G.vanz.State.Destroyed then
        return
    end


    scale = tonumber(scale)


    if not scale then
        return
    end


    scale = math.clamp(

        scale,

        0.5,

        1.5

    )


    UIScale.Scale =
        scale


    _G.vanz.Config.Scale =
        scale

end


_G.vanz.GetState = function()

    return {

        Open =
            _G.vanz.State.Open,

        Closed =
            _G.vanz.State.Closed,

        Destroyed =
            _G.vanz.State.Destroyed,

        Minimized =
            IsMinimized,

        Scale =
            UIScale.Scale,

    }

end


--============================================================
-- BLOK 49: STARTUP ANIMATION
-- Animasi ketika menu pertama kali muncul.
--============================================================

MainHolder.Size =
    UDim2.fromOffset(

        _G.vanz.Config.Width * 0.94,

        _G.vanz.Config.Height * 0.94

    )


Shadow.Visible = true
OuterAura.Visible = true
MainHolder.Visible = true


Tween(

    MainHolder,

    {

        Size = UDim2.fromOffset(

            _G.vanz.Config.Width,

            _G.vanz.Config.Height

        ),

    },

    0.4,

    Enum.EasingStyle.Quint,

    Enum.EasingDirection.Out

)


--============================================================
-- BLOK 50: FINAL STATUS
--============================================================

print("==============================================")
print(" VANZ // PREMIUM CONTROL CENTER")
print(" GUI VERSION 5")
print("----------------------------------------------")
print(" TAB        : HOME")
print(" DEFAULT DPI: 70%")
print(" ANIMATION  : ON")
print(" GLOW       : ON")
print(" CLICK FX   : ON")
print(" CLOSE      : FORCE STOP")
print(" CLEANUP    : ACTIVE")
print("==============================================")