--==============================================================
-- VANZ // ULTRA PREMIUM MODULAR GUI
--==============================================================
-- GUI ONLY
--
-- FEATURES
-- • Premium VANZ dashboard
-- • Default DPI 100%
-- • Animated RGB / neon accent
-- • Animated header gradient
-- • Pulsing glow
-- • Smooth open / minimize animation
-- • Floating V restore button
-- • Draggable floating logo
-- • Responsive mobile layout
-- • DPI presets: 50 / 75 / 100 / 150 / 175 / 200
-- • Multiple tabs
-- • Scrollable pages
-- • Modern sidebar
-- • Toggle system
-- • Button system
-- • Section system
-- • Info cards
-- • Hover / press animations
-- • Shared state through _G.vanz
-- • xpcall error handling
--==============================================================


--==============================================================
-- VANZ GLOBAL CORE
--==============================================================

_G.vanz = _G.vanz or {}

_G.vanz.Config = _G.vanz.Config or {

    Title = "VANZ",

    Version = "3.0.0",

    -- DEFAULT DPI
    Scale = 1.00,

    Minimized = false,

    Animations = true,

    FloatingLogo = true,

    TouchFriendly = true,

    DynamicColors = true,

    Glow = true,
}


_G.vanz.State =
    _G.vanz.State or {}

_G.vanz.UI =
    _G.vanz.UI or {}

_G.vanz.Tabs =
    {}

_G.vanz.Components =
    _G.vanz.Components or {}

_G.vanz.Connections =
    _G.vanz.Connections or {}


--==============================================================
-- SERVICES
--==============================================================

local Players =
    game:GetService("Players")

local TweenService =
    game:GetService("TweenService")

local UserInputService =
    game:GetService("UserInputService")

local RunService =
    game:GetService("RunService")

local LocalPlayer =
    Players.LocalPlayer

local PlayerGui =
    LocalPlayer:WaitForChild("PlayerGui")


--==============================================================
-- ERROR SYSTEM
--==============================================================

local function VanzError(
    blockName,
    err
)

    local errorText =
        tostring(err)

    local trace =
        debug.traceback(
            "",
            2
        )

    warn(
        "\n[VANZ ERROR][" ..
        tostring(blockName) ..
        "] " ..
        errorText ..
        "\n" ..
        trace ..
        "\n"
    )

    return errorText
end


local function VanzBlock(
    blockName,
    callback
)

    return xpcall(
        callback,

        function(err)

            return VanzError(
                blockName,
                err
            )

        end
    )

end


--==============================================================
-- 1_INIT_GUI
--==============================================================

VanzBlock(
    "1_INIT_GUI",

    function()

        --======================================================
        -- CLEAN OLD GUI
        --======================================================

        local oldGui =
            PlayerGui:FindFirstChild(
                "VANZ_GUI"
            )

        if oldGui then
            oldGui:Destroy()
        end


        --======================================================
        -- RESET TAB CACHE
        --======================================================

        _G.vanz.Tabs = {}


        --======================================================
        -- HELPERS
        --======================================================

        local function New(
            className,
            properties,
            parent
        )

            local object =
                Instance.new(
                    className
                )

            for property, value in pairs(
                properties or {}
            ) do

                object[property] =
                    value

            end

            object.Parent =
                parent

            return object

        end


        local function Corner(
            object,
            radius
        )

            local corner =
                Instance.new(
                    "UICorner"
                )

            corner.CornerRadius =
                UDim.new(
                    0,
                    radius or 8
                )

            corner.Parent =
                object

            return corner

        end


        local function Stroke(
            object,
            color,
            thickness,
            transparency
        )

            local stroke =
                Instance.new(
                    "UIStroke"
                )

            stroke.Color =
                color or
                Color3.fromRGB(
                    70,
                    70,
                    90
                )

            stroke.Thickness =
                thickness or 1

            stroke.Transparency =
                transparency or 0

            stroke.Parent =
                object

            return stroke

        end


        local function Gradient(
            object,
            colorA,
            colorB,
            rotation
        )

            local gradient =
                Instance.new(
                    "UIGradient"
                )

            gradient.Color =
                ColorSequence.new({

                    ColorSequenceKeypoint.new(
                        0,
                        colorA
                    ),

                    ColorSequenceKeypoint.new(
                        1,
                        colorB
                    )

                })

            gradient.Rotation =
                rotation or 0

            gradient.Parent =
                object

            return gradient

        end


        --======================================================
        -- COLOR PALETTE
        --======================================================

        local Colors = {

            Background =
                Color3.fromRGB(
                    5,
                    6,
                    11
                ),

            Background2 =
                Color3.fromRGB(
                    9,
                    10,
                    17
                ),

            Panel =
                Color3.fromRGB(
                    13,
                    15,
                    24
                ),

            Panel2 =
                Color3.fromRGB(
                    18,
                    20,
                    31
                ),

            Panel3 =
                Color3.fromRGB(
                    25,
                    28,
                    42
                ),

            Sidebar =
                Color3.fromRGB(
                    8,
                    9,
                    16
                ),

            Text =
                Color3.fromRGB(
                    245,
                    247,
                    255
                ),

            TextSecondary =
                Color3.fromRGB(
                    157,
                    161,
                    185
                ),

            TextMuted =
                Color3.fromRGB(
                    91,
                    95,
                    118
                ),

            Border =
                Color3.fromRGB(
                    38,
                    41,
                    60
                ),

            ToggleOff =
                Color3.fromRGB(
                    45,
                    48,
                    63
                ),

            Accent =
                Color3.fromRGB(
                    130,
                    75,
                    255
                ),

            Accent2 =
                Color3.fromRGB(
                    40,
                    190,
                    255
                ),

            Accent3 =
                Color3.fromRGB(
                    255,
                    70,
                    190
                ),

            Success =
                Color3.fromRGB(
                    65,
                    220,
                    145
                ),

            Danger =
                Color3.fromRGB(
                    255,
                    75,
                    105
                ),
        }


        _G.vanz.Colors =
            Colors


        --======================================================
        -- SCREEN GUI
        --======================================================

        local ScreenGui =
            New(
                "ScreenGui",
                {
                    Name =
                        "VANZ_GUI",

                    ResetOnSpawn =
                        false,

                    IgnoreGuiInset =
                        true,

                    ZIndexBehavior =
                        Enum.ZIndexBehavior.Sibling,

                    DisplayOrder =
                        999,

                    Enabled =
                        true,
                },

                PlayerGui
            )


        _G.vanz.UI.ScreenGui =
            ScreenGui


        --======================================================
        -- GLOBAL SCALE
        --======================================================

        local GlobalScale =
            New(
                "UIScale",
                {
                    Scale =
                        _G.vanz.Config.Scale
                        or 1.00,
                },

                ScreenGui
            )


        _G.vanz.UI.Scale =
            GlobalScale


        --======================================================
        -- BACKGROUND SHADOW
        --======================================================

        local Shadow =
            New(
                "ImageLabel",
                {
                    Name =
                        "Shadow",

                    AnchorPoint =
                        Vector2.new(
                            0.5,
                            0.5
                        ),

                    Position =
                        UDim2.fromScale(
                            0.5,
                            0.5
                        ),

                    Size =
                        UDim2.new(
                            0,
                            315,
                            0.88,
                            55
                        ),

                    BackgroundTransparency =
                        1,

                    Image =
                        "rbxassetid://1316045217",

                    ImageColor3 =
                        Color3.new(
                            0,
                            0,
                            0
                        ),

                    ImageTransparency =
                        0.18,

                    ScaleType =
                        Enum.ScaleType.Slice,

                    SliceCenter =
                        Rect.new(
                            10,
                            10,
                            118,
                            118
                        ),

                    ZIndex =
                        0,

                    Visible =
                        true,
                },

                ScreenGui
            )


        _G.vanz.UI.Shadow =
            Shadow


        --======================================================
        -- OUTER NEON GLOW
        --======================================================

        local OuterGlow =
            New(
                "Frame",
                {
                    Name =
                        "OuterGlow",

                    AnchorPoint =
                        Vector2.new(
                            0.5,
                            0.5
                        ),

                    Position =
                        UDim2.fromScale(
                            0.5,
                            0.5
                        ),

                    Size =
                        UDim2.new(
                            0,
                            282,
                            0.86,
                            18
                        ),

                    BackgroundColor3 =
                        Colors.Accent,

                    BackgroundTransparency =
                        0.92,

                    BorderSizePixel =
                        0,

                    ZIndex =
                        1,
                },

                ScreenGui
            )


        Corner(
            OuterGlow,
            20
        )


        local OuterGlowGradient =
            Gradient(
                OuterGlow,
                Colors.Accent,
                Colors.Accent2,
                0
            )


        _G.vanz.UI.OuterGlow =
            OuterGlow

        _G.vanz.UI.OuterGlowGradient =
            OuterGlowGradient


        --======================================================
        -- MAIN WINDOW
        --======================================================

        local Main =
            New(
                "Frame",
                {
                    Name =
                        "MainWindow",

                    AnchorPoint =
                        Vector2.new(
                            0.5,
                            0.5
                        ),

                    Position =
                        UDim2.fromScale(
                            0.5,
                            0.5
                        ),

                    Size =
                        UDim2.new(
                            0,
                            270,
                            0.84,
                            0
                        ),

                    BackgroundColor3 =
                        Colors.Background,

                    BorderSizePixel =
                        0,

                    ClipsDescendants =
                        true,

                    ZIndex =
                        5,
                },

                ScreenGui
            )


        Corner(
            Main,
            17
        )


        local MainStroke =
            Stroke(
                Main,
                Colors.Border,
                1
            )


        _G.vanz.UI.Main =
            Main

        _G.vanz.UI.MainStroke =
            MainStroke


        --======================================================
        -- TOP NEON BAR
        --======================================================

        local TopGlow =
            New(
                "Frame",
                {
                    Name =
                        "TopGlow",

                    Position =
                        UDim2.new(
                            0,
                            0,
                            0,
                            0
                        ),

                    Size =
                        UDim2.new(
                            1,
                            0,
                            0,
                            3
                        ),

                    BackgroundColor3 =
                        Colors.Accent,

                    BorderSizePixel =
                        0,

                    ZIndex =
                        30,
                },

                Main
            )


        local TopGradient =
            Gradient(
                TopGlow,
                Colors.Accent,
                Colors.Accent2,
                0
            )


        _G.vanz.UI.TopGradient =
            TopGradient


        --======================================================
        -- HEADER
        --======================================================

        local Header =
            New(
                "Frame",
                {
                    Name =
                        "Header",

                    Position =
                        UDim2.new(
                            0,
                            0,
                            0,
                            3
                        ),

                    Size =
                        UDim2.new(
                            1,
                            0,
                            0,
                            62
                        ),

                    BackgroundColor3 =
                        Colors.Panel,

                    BorderSizePixel =
                        0,

                    ZIndex =
                        10,
                },

                Main
            )


        --======================================================
        -- HEADER GRADIENT
        --======================================================

        local HeaderGradient =
            Gradient(
                Header,
                Colors.Panel,
                Colors.Background2,
                90
            )


        _G.vanz.UI.HeaderGradient =
            HeaderGradient


        --======================================================
        -- LOGO HOLDER
        --======================================================

        local LogoHolder =
            New(
                "Frame",
                {
                    Name =
                        "LogoHolder",

                    Position =
                        UDim2.new(
                            0,
                            11,
                            0,
                            10
                        ),

                    Size =
                        UDim2.new(
                            0,
                            41,
                            0,
                            41
                        ),

                    BackgroundColor3 =
                        Colors.Background2,

                    BorderSizePixel =
                        0,

                    ZIndex =
                        14,
                },

                Header
            )


        Corner(
            LogoHolder,
            12
        )


        local LogoStroke =
            Stroke(
                LogoHolder,
                Colors.Accent,
                1.5
            )


        _G.vanz.UI.LogoStroke =
            LogoStroke


        --======================================================
        -- LOGO INNER GLOW
        --======================================================

        local LogoGlow =
            New(
                "Frame",
                {
                    Name =
                        "LogoGlow",

                    AnchorPoint =
                        Vector2.new(
                            0.5,
                            0.5
                        ),

                    Position =
                        UDim2.fromScale(
                            0.5,
                            0.5
                        ),

                    Size =
                        UDim2.new(
                            0,
                            28,
                            0,
                            28
                        ),

                    BackgroundColor3 =
                        Colors.Accent,

                    BackgroundTransparency =
                        0.88,

                    BorderSizePixel =
                        0,

                    ZIndex =
                        14,
                },

                LogoHolder
            )


        Corner(
            LogoGlow,
            20
        )


        _G.vanz.UI.LogoGlow =
            LogoGlow


        --======================================================
        -- V LOGO
        --======================================================

        local Logo =
            New(
                "TextLabel",
                {
                    Name =
                        "VLogo",

                    AnchorPoint =
                        Vector2.new(
                            0.5,
                            0.5
                        ),

                    Position =
                        UDim2.fromScale(
                            0.5,
                            0.48
                        ),

                    Size =
                        UDim2.fromScale(
                            0.9,
                            0.9
                        ),

                    BackgroundTransparency =
                        1,

                    Text =
                        "V",

                    Font =
                        Enum.Font.GothamBlack,

                    TextSize =
                        27,

                    TextColor3 =
                        Colors.Accent,

                    TextStrokeTransparency =
                        0.55,

                    TextStrokeColor3 =
                        Colors.Accent2,

                    ZIndex =
                        16,
                },

                LogoHolder
            )


        _G.vanz.UI.Logo =
            Logo


        --======================================================
        -- TITLE
        --======================================================

        local Title =
            New(
                "TextLabel",
                {
                    Position =
                        UDim2.new(
                            0,
                            61,
                            0,
                            11
                        ),

                    Size =
                        UDim2.new(
                            0,
                            130,
                            0,
                            22
                        ),

                    BackgroundTransparency =
                        1,

                    Text =
                        "VANZ",

                    Font =
                        Enum.Font.GothamBlack,

                    TextSize =
                        17,

                    TextColor3 =
                        Colors.Text,

                    TextXAlignment =
                        Enum.TextXAlignment.Left,

                    ZIndex =
                        14,
                },

                Header
            )


        _G.vanz.UI.Title =
            Title


        local Subtitle =
            New(
                "TextLabel",
                {
                    Position =
                        UDim2.new(
                            0,
                            62,
                            0,
                            32
                        ),

                    Size =
                        UDim2.new(
                            0,
                            150,
                            0,
                            14
                        ),

                    BackgroundTransparency =
                        1,

                    Text =
                        "ULTRA PREMIUM INTERFACE",

                    Font =
                        Enum.Font.GothamMedium,

                    TextSize =
                        7,

                    TextColor3 =
                        Colors.TextSecondary,

                    TextXAlignment =
                        Enum.TextXAlignment.Left,

                    ZIndex =
                        14,
                },

                Header
            )


        --======================================================
        -- STATUS DOT
        --======================================================

        local StatusDot =
            New(
                "Frame",
                {
                    AnchorPoint =
                        Vector2.new(
                            1,
                            0.5
                        ),

                    Position =
                        UDim2.new(
                            1,
                            -51,
                            0,
                            18
                        ),

                    Size =
                        UDim2.new(
                            0,
                            6,
                            0,
                            6
                        ),

                    BackgroundColor3 =
                        Colors.Success,

                    BorderSizePixel =
                        0,

                    ZIndex =
                        15,
                },

                Header
            )


        Corner(
            StatusDot,
            10
        )


        _G.vanz.UI.StatusDot =
            StatusDot


        --======================================================
        -- MINIMIZE
        --======================================================

        local Minimize =
            New(
                "TextButton",
                {
                    Name =
                        "Minimize",

                    AnchorPoint =
                        Vector2.new(
                            1,
                            0.5
                        ),

                    Position =
                        UDim2.new(
                            1,
                            -11,
                            0.5,
                            0
                        ),

                    Size =
                        UDim2.new(
                            0,
                            31,
                            0,
                            31
                        ),

                    BackgroundColor3 =
                        Colors.Panel2,

                    AutoButtonColor =
                        false,

                    Text =
                        "−",

                    Font =
                        Enum.Font.GothamBold,

                    TextSize =
                        18,

                    TextColor3 =
                        Colors.TextSecondary,

                    ZIndex =
                        20,
                },

                Header
            )


        Corner(
            Minimize,
            9
        )


        local MinimizeStroke =
            Stroke(
                Minimize,
                Colors.Border,
                1
            )


        _G.vanz.UI.MinimizeButton =
            Minimize

        _G.vanz.UI.MinimizeStroke =
            MinimizeStroke


        --======================================================
        -- HEADER LINE
        --======================================================

        local HeaderLine =
            New(
                "Frame",
                {
                    Position =
                        UDim2.new(
                            0,
                            0,
                            1,
                            -1
                        ),

                    Size =
                        UDim2.new(
                            1,
                            0,
                            0,
                            1
                        ),

                    BackgroundColor3 =
                        Colors.Border,

                    BorderSizePixel =
                        0,

                    ZIndex =
                        20,
                },

                Header
            )


        --======================================================
        -- CONTENT
        --======================================================

        local Content =
            New(
                "Frame",
                {
                    Name =
                        "Content",

                    Position =
                        UDim2.new(
                            0,
                            0,
                            0,
                            65
                        ),

                    Size =
                        UDim2.new(
                            1,
                            0,
                            1,
                            -65
                        ),

                    BackgroundTransparency =
                        1,

                    ZIndex =
                        6,
                },

                Main
            )


        _G.vanz.UI.Content =
            Content


        --======================================================
        -- SIDEBAR
        --======================================================

        local Sidebar =
            New(
                "Frame",
                {
                    Name =
                        "Sidebar",

                    Size =
                        UDim2.new(
                            0,
                            58,
                            1,
                            0
                        ),

                    BackgroundColor3 =
                        Colors.Sidebar,

                    BorderSizePixel =
                        0,

                    ZIndex =
                        8,
                },

                Content
            )


        _G.vanz.UI.Sidebar =
            Sidebar


        --======================================================
        -- SIDEBAR GLOW
        --======================================================

        local SidebarGlow =
            New(
                "Frame",
                {
                    Position =
                        UDim2.new(
                            1,
                            -1,
                            0,
                            0
                        ),

                    Size =
                        UDim2.new(
                            0,
                            1,
                            1,
                            0
                        ),

                    BackgroundColor3 =
                        Colors.Accent,

                    BackgroundTransparency =
                        0.45,

                    BorderSizePixel =
                        0,

                    ZIndex =
                        25,
                },

                Sidebar
            )


        _G.vanz.UI.SidebarGlow =
            SidebarGlow


        --======================================================
        -- PAGE CONTAINER
        --======================================================

        local Pages =
            New(
                "Frame",
                {
                    Name =
                        "Pages",

                    Position =
                        UDim2.new(
                            0,
                            58,
                            0,
                            0
                        ),

                    Size =
                        UDim2.new(
                            1,
                            -58,
                            1,
                            0
                        ),

                    BackgroundTransparency =
                        1,

                    ClipsDescendants =
                        true,

                    ZIndex =
                        7,
                },

                Content
            )


        _G.vanz.UI.Pages =
            Pages


        --======================================================
        -- RESPONSIVE
        --======================================================

        local Camera =
            workspace.CurrentCamera


        local function UpdateResponsive()

            if not Camera then
                return
            end


            local viewport =
                Camera.ViewportSize


            if viewport.X <= 320 then

                Main.Size =
                    UDim2.new(
                        0,
                        245,
                        0.84,
                        0
                    )

            elseif viewport.X <= 500 then

                Main.Size =
                    UDim2.new(
                        0,
                        260,
                        0.85,
                        0
                    )

            else

                Main.Size =
                    UDim2.new(
                        0,
                        270,
                        0.84,
                        0
                    )

            end


            local configured =
                _G.vanz.Config.Scale
                or 1.00


            if viewport.X < 300 then

                configured =
                    math.min(
                        configured,
                        0.65
                    )

            end


            if not _G.vanz.Config.Minimized then

                GlobalScale.Scale =
                    configured

            end

        end


        if Camera then

            Camera:GetPropertyChangedSignal(
                "ViewportSize"
            ):Connect(
                UpdateResponsive
            )

        end


        UpdateResponsive()


        --======================================================
        -- FLOATING V
        --======================================================

        local FloatingLogo =
            New(
                "TextButton",
                {
                    Name =
                        "FloatingV",

                    AnchorPoint =
                        Vector2.new(
                            0.5,
                            0.5
                        ),

                    Position =
                        UDim2.fromScale(
                            0.5,
                            0.5
                        ),

                    Size =
                        UDim2.new(
                            0,
                            60,
                            0,
                            60
                        ),

                    BackgroundColor3 =
                        Colors.Background2,

                    BorderSizePixel =
                        0,

                    AutoButtonColor =
                        false,

                    Text =
                        "V",

                    Font =
                        Enum.Font.GothamBlack,

                    TextSize =
                        27,

                    TextColor3 =
                        Colors.Accent,

                    Visible =
                        false,

                    Active =
                        true,

                    ZIndex =
                        100,
                },

                ScreenGui
            )


        Corner(
            FloatingLogo,
            20
        )


        local FloatingStroke =
            Stroke(
                FloatingLogo,
                Colors.Accent,
                2
            )


        local FloatingGradient =
            New(
                "UIGradient",
                {
                    Rotation =
                        45,

                    Color =
                        ColorSequence.new({

                            ColorSequenceKeypoint.new(
                                0,
                                Colors.Accent
                            ),

                            ColorSequenceKeypoint.new(
                                0.5,
                                Colors.Accent2
                            ),

                            ColorSequenceKeypoint.new(
                                1,
                                Colors.Accent3
                            )

                        }),
                },

                FloatingLogo
            )


        _G.vanz.UI.FloatingLogo =
            FloatingLogo

        _G.vanz.UI.FloatingGradient =
            FloatingGradient

        _G.vanz.UI.FloatingStroke =
            FloatingStroke


        --======================================================
        -- FLOATING GLOW
        --======================================================

        local FloatingGlow =
            New(
                "Frame",
                {
                    Name =
                        "FloatingGlow",

                    AnchorPoint =
                        Vector2.new(
                            0.5,
                            0.5
                        ),

                    Position =
                        UDim2.fromScale(
                            0.5,
                            0.5
                        ),

                    Size =
                        UDim2.new(
                            0,
                            76,
                            0,
                            76
                        ),

                    BackgroundColor3 =
                        Colors.Accent,

                    BackgroundTransparency =
                        0.91,

                    BorderSizePixel =
                        0,

                    Visible =
                        false,

                    ZIndex =
                        98,
                },

                ScreenGui
            )


        Corner(
            FloatingGlow,
            30
        )


        _G.vanz.UI.FloatingGlow =
            FloatingGlow


        --======================================================
        -- MINIMIZE
        --======================================================

        local function MinimizeGUI()

            if _G.vanz.Config.Minimized then
                return
            end


            _G.vanz.Config.Minimized =
                true


            -- IMPORTANT:
            -- hide all remnants

            if Shadow then
                Shadow.Visible =
                    false
            end


            if OuterGlow then
                OuterGlow.Visible =
                    false
            end


            if _G.vanz.Config.Animations then

                local tween =
                    TweenService:Create(

                        Main,

                        TweenInfo.new(
                            0.34,
                            Enum.EasingStyle.Quint,
                            Enum.EasingDirection.In
                        ),

                        {
                            Size =
                                UDim2.new(
                                    0,
                                    270,
                                    0,
                                    0
                                ),

                            BackgroundTransparency =
                                1,

                            Rotation =
                                2,
                        }
                    )


                tween:Play()


                task.delay(
                    0.24,

                    function()

                        Main.Visible =
                            false

                        Main.Rotation =
                            0


                        if _G.vanz.Config.FloatingLogo then

                            FloatingLogo.Visible =
                                true

                            FloatingGlow.Visible =
                                true


                            FloatingLogo.Size =
                                UDim2.new(
                                    0,
                                    8,
                                    0,
                                    8
                                )


                            FloatingGlow.Size =
                                UDim2.new(
                                    0,
                                    10,
                                    0,
                                    10
                                )


                            TweenService:Create(

                                FloatingLogo,

                                TweenInfo.new(
                                    0.48,
                                    Enum.EasingStyle.Back,
                                    Enum.EasingDirection.Out
                                ),

                                {
                                    Size =
                                        UDim2.new(
                                            0,
                                            60,
                                            0,
                                            60
                                        )
                                }

                            ):Play()


                            TweenService:Create(

                                FloatingGlow,

                                TweenInfo.new(
                                    0.55,
                                    Enum.EasingStyle.Back,
                                    Enum.EasingDirection.Out
                                ),

                                {
                                    Size =
                                        UDim2.new(
                                            0,
                                            78,
                                            0,
                                            78
                                        )
                                }

                            ):Play()

                        end

                    end
                )

            else

                Main.Visible =
                    false

                if _G.vanz.Config.FloatingLogo then

                    FloatingLogo.Visible =
                        true

                    FloatingGlow.Visible =
                        true

                end

            end

        end


        --======================================================
        -- RESTORE
        --======================================================

        local function RestoreGUI()

            if not _G.vanz.Config.Minimized then
                return
            end


            _G.vanz.Config.Minimized =
                false


            FloatingLogo.Visible =
                false

            FloatingGlow.Visible =
                false


            Main.Visible =
                true


            Main.Size =
                UDim2.new(
                    0,
                    270,
                    0,
                    0
                )

            Main.BackgroundTransparency =
                1

            Main.Rotation =
                -2


            Shadow.Visible =
                true

            OuterGlow.Visible =
                true


            if _G.vanz.Config.Animations then

                TweenService:Create(

                    Main,

                    TweenInfo.new(
                        0.55,
                        Enum.EasingStyle.Back,
                        Enum.EasingDirection.Out
                    ),

                    {
                        Size =
                            UDim2.new(
                                0,
                                270,
                                0.84,
                                0
                            ),

                        BackgroundTransparency =
                            0,

                        Rotation =
                            0,
                    }

                ):Play()

            else

                Main.Size =
                    UDim2.new(
                        0,
                        270,
                        0.84,
                        0
                    )

                Main.BackgroundTransparency =
                    0

                Main.Rotation =
                    0

            end

        end


        Minimize.MouseButton1Click:Connect(
            MinimizeGUI
        )


        --======================================================
        -- DRAG FLOATING LOGO
        --======================================================

        local dragging =
            false

        local dragStart =
            nil

        local startPosition =
            nil

        local moved =
            false


        FloatingLogo.InputBegan:Connect(

            function(input)

                if
                    input.UserInputType
                        == Enum.UserInputType.MouseButton1
                    or
                    input.UserInputType
                        == Enum.UserInputType.Touch
                then

                    dragging =
                        true

                    moved =
                        false

                    dragStart =
                        input.Position

                    startPosition =
                        FloatingLogo.Position


                    input.Changed:Connect(

                        function()

                            if
                                input.UserInputState
                                    == Enum.UserInputState.End
                            then

                                dragging =
                                    false

                            end

                        end
                    )

                end

            end
        )


        UserInputService.InputChanged:Connect(

            function(input)

                if not dragging then
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


                if delta.Magnitude > 5 then
                    moved = true
                end


                FloatingLogo.Position =
                    UDim2.new(

                        startPosition.X.Scale,

                        startPosition.X.Offset
                            + delta.X,

                        startPosition.Y.Scale,

                        startPosition.Y.Offset
                            + delta.Y

                    )


                FloatingGlow.Position =
                    FloatingLogo.Position

            end
        )


        FloatingLogo.MouseButton1Click:Connect(

            function()

                if not moved then
                    RestoreGUI()
                end

            end
        )


        _G.vanz.UI.Minimize =
            MinimizeGUI

        _G.vanz.UI.Restore =
            RestoreGUI


        --======================================================
        -- INITIAL OPEN
        --======================================================

        Main.Size =
            UDim2.new(
                0,
                245,
                0,
                0
            )

        Main.BackgroundTransparency =
            1

        Main.Rotation =
            -3


        task.defer(

            function()

                task.wait(
                    0.08
                )


                TweenService:Create(

                    Main,

                    TweenInfo.new(
                        0.7,
                        Enum.EasingStyle.Back,
                        Enum.EasingDirection.Out
                    ),

                    {
                        Size =
                            UDim2.new(
                                0,
                                270,
                                0.84,
                                0
                            ),

                        BackgroundTransparency =
                            0,

                        Rotation =
                            0,
                    }

                ):Play()

            end
        )

    end
)


--==============================================================
-- 2_COMPONENT_LIBRARY
--==============================================================

VanzBlock(
    "2_COMPONENT_LIBRARY",

    function()

        local UI =
            _G.vanz.UI

        local Colors =
            _G.vanz.Colors


        local function New(
            className,
            properties,
            parent
        )

            local object =
                Instance.new(
                    className
                )

            for property, value in pairs(
                properties or {}
            ) do

                object[property] =
                    value

            end

            object.Parent =
                parent

            return object

        end


        local function Corner(
            object,
            radius
        )

            local corner =
                Instance.new(
                    "UICorner"
                )

            corner.CornerRadius =
                UDim.new(
                    0,
                    radius or 8
                )

            corner.Parent =
                object

            return corner

        end


        local function Stroke(
            object,
            color,
            thickness,
            transparency
        )

            local stroke =
                Instance.new(
                    "UIStroke"
                )

            stroke.Color =
                color or Colors.Border

            stroke.Thickness =
                thickness or 1

            stroke.Transparency =
                transparency or 0

            stroke.Parent =
                object

            return stroke

        end


        --======================================================
        -- TOGGLE
        --======================================================

        function _G.vanz.CreateToggle(
            parent,
            title,
            description,
            default,
            callback
        )

            local holder =
                New(
                    "Frame",
                    {
                        Size =
                            UDim2.new(
                                1,
                                -14,
                                0,
                                59
                            ),

                        BackgroundColor3 =
                            Colors.Panel2,

                        BorderSizePixel =
                            0,

                        ClipsDescendants =
                            true,
                    },

                    parent
                )


            Corner(
                holder,
                11
            )


            local holderStroke =
                Stroke(
                    holder,
                    Colors.Border,
                    1
                )


            -- LEFT NEON BAR

            local accent =
                New(
                    "Frame",
                    {
                        Position =
                            UDim2.new(
                                0,
                                0,
                                0,
                                8
                            ),

                        Size =
                            UDim2.new(
                                0,
                                2,
                                0,
                                43
                            ),

                        BackgroundColor3 =
                            Colors.Accent,

                        BorderSizePixel =
                            0,

                        BackgroundTransparency =
                            0.55,
                    },

                    holder
                )


            Corner(
                accent,
                3
            )


            -- TITLE

            local label =
                New(
                    "TextLabel",
                    {
                        Position =
                            UDim2.new(
                                0,
                                13,
                                0,
                                8
                            ),

                        Size =
                            UDim2.new(
                                1,
                                -76,
                                0,
                                18
                            ),

                        BackgroundTransparency =
                            1,

                        Text =
                            title or "Feature",

                        Font =
                            Enum.Font.GothamSemibold,

                        TextSize =
                            9,

                        TextColor3 =
                            Colors.Text,

                        TextXAlignment =
                            Enum.TextXAlignment.Left,

                        TextTruncate =
                            Enum.TextTruncate.AtEnd,
                    },

                    holder
                )


            -- DESCRIPTION

            local desc =
                New(
                    "TextLabel",
                    {
                        Position =
                            UDim2.new(
                                0,
                                13,
                                0,
                                29
                            ),

                        Size =
                            UDim2.new(
                                1,
                                -76,
                                0,
                                17
                            ),

                        BackgroundTransparency =
                            1,

                        Text =
                            description
                            or
                            "Feature description",

                        Font =
                            Enum.Font.Gotham,

                        TextSize =
                            7,

                        TextColor3 =
                            Colors.TextSecondary,

                        TextXAlignment =
                            Enum.TextXAlignment.Left,

                        TextTruncate =
                            Enum.TextTruncate.AtEnd,
                    },

                    holder
                )


            -- TOGGLE

            local toggle =
                New(
                    "TextButton",
                    {
                        AnchorPoint =
                            Vector2.new(
                                1,
                                0.5
                            ),

                        Position =
                            UDim2.new(
                                1,
                                -10,
                                0.5,
                                0
                            ),

                        Size =
                            UDim2.new(
                                0,
                                36,
                                0,
                                21
                            ),

                        BackgroundColor3 =
                            Colors.ToggleOff,

                        AutoButtonColor =
                            false,

                        Text =
                            "",
                    },

                    holder
                )


            Corner(
                toggle,
                20
            )


            local knob =
                New(
                    "Frame",
                    {
                        AnchorPoint =
                            Vector2.new(
                                0,
                                0.5
                            ),

                        Position =
                            UDim2.new(
                                0,
                                2,
                                0.5,
                                0
                            ),

                        Size =
                            UDim2.new(
                                0,
                                17,
                                0,
                                17
                            ),

                        BackgroundColor3 =
                            Color3.fromRGB(
                                235,
                                237,
                                245
                            ),

                        BorderSizePixel =
                            0,
                    },

                    toggle
                )


            Corner(
                knob,
                20
            )


            local knobGlow =
                New(
                    "Frame",
                    {
                        AnchorPoint =
                            Vector2.new(
                                0.5,
                                0.5
                            ),

                        Position =
                            UDim2.fromScale(
                                0.5,
                                0.5
                            ),

                        Size =
                            UDim2.new(
                                0,
                                25,
                                0,
                                25
                            ),

                        BackgroundColor3 =
                            Colors.Accent,

                        BackgroundTransparency =
                            1,

                        BorderSizePixel =
                            0,
                    },

                    knob
                )


            Corner(
                knobGlow,
                20
            )


            local state =
                default == true


            local function Set(
                value,
                fireCallback
            )

                state =
                    value == true


                local targetColor
                local targetPosition


                if state then

                    targetColor =
                        Colors.Accent

                    targetPosition =
                        UDim2.new(
                            1,
                            -19,
                            0.5,
                            0
                        )

                else

                    targetColor =
                        Colors.ToggleOff

                    targetPosition =
                        UDim2.new(
                            0,
                            2,
                            0.5,
                            0
                        )

                end


                TweenService:Create(

                    toggle,

                    TweenInfo.new(
                        0.2,
                        Enum.EasingStyle.Quart,
                        Enum.EasingDirection.Out
                    ),

                    {
                        BackgroundColor3 =
                            targetColor
                    }

                ):Play()


                TweenService:Create(

                    knob,

                    TweenInfo.new(
                        0.32,
                        Enum.EasingStyle.Back,
                        Enum.EasingDirection.Out
                    ),

                    {
                        Position =
                            targetPosition
                    }

                ):Play()


                TweenService:Create(

                    accent,

                    TweenInfo.new(
                        0.2
                    ),

                    {
                        BackgroundTransparency =
                            state
                            and 0
                            or 0.55
                    }

                ):Play()


                TweenService:Create(

                    knobGlow,

                    TweenInfo.new(
                        0.2
                    ),

                    {
                        BackgroundTransparency =
                            state
                            and 0.72
                            or 1
                    }

                ):Play()


                if fireCallback ~= false
                    and callback then

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


            toggle.MouseButton1Click:Connect(

                function()

                    Set(
                        not state,
                        true
                    )

                end
            )


            toggle.MouseEnter:Connect(

                function()

                    TweenService:Create(
                        holder,
                        TweenInfo.new(
                            0.15
                        ),
                        {
                            BackgroundColor3 =
                                Colors.Panel3
                        }
                    ):Play()

                end
            )


            toggle.MouseLeave:Connect(

                function()

                    TweenService:Create(
                        holder,
                        TweenInfo.new(
                            0.15
                        ),
                        {
                            BackgroundColor3 =
                                Colors.Panel2
                        }
                    ):Play()

                end
            )


            Set(
                state,
                true
            )


            return {

                Frame =
                    holder,

                Button =
                    toggle,

                Set =
                    function(value)

                        Set(
                            value,
                            true
                        )

                    end,

                Get =
                    function()

                        return state

                    end,
            }

        end


        --======================================================
        -- BUTTON
        --======================================================

        function _G.vanz.CreateButton(
            parent,
            title,
            callback
        )

            local button =
                New(
                    "TextButton",
                    {
                        Size =
                            UDim2.new(
                                1,
                                -14,
                                0,
                                41
                            ),

                        BackgroundColor3 =
                            Colors.Panel2,

                        BorderSizePixel =
                            0,

                        AutoButtonColor =
                            false,

                        Text =
                            title or "Button",

                        Font =
                            Enum.Font.GothamSemibold,

                        TextSize =
                            9,

                        TextColor3 =
                            Colors.Text,
                    },

                    parent
                )


            Corner(
                button,
                10
            )


            local stroke =
                Stroke(
                    button,
                    Colors.Border,
                    1
                )


            local leftGlow =
                New(
                    "Frame",
                    {
                        Position =
                            UDim2.new(
                                0,
                                0,
                                0,
                                8
                            ),

                        Size =
                            UDim2.new(
                                0,
                                2,
                                0,
                                25
                            ),

                        BackgroundColor3 =
                            Colors.Accent,

                        BackgroundTransparency =
                            0.7,

                        BorderSizePixel =
                            0,
                    },

                    button
                )


            Corner(
                leftGlow,
                3
            )


            button.MouseEnter:Connect(

                function()

                    TweenService:Create(
                        button,
                        TweenInfo.new(
                            0.18,
                            Enum.EasingStyle.Quart
                        ),
                        {
                            BackgroundColor3 =
                                Colors.Panel3
                        }
                    ):Play()


                    TweenService:Create(
                        stroke,
                        TweenInfo.new(
                            0.18
                        ),
                        {
                            Color =
                                Colors.Accent,

                            Transparency =
                                0.25
                        }
                    ):Play()


                    TweenService:Create(
                        leftGlow,
                        TweenInfo.new(
                            0.18
                        ),
                        {
                            BackgroundTransparency =
                                0
                        }
                    ):Play()

                end
            )


            button.MouseLeave:Connect(

                function()

                    TweenService:Create(
                        button,
                        TweenInfo.new(
                            0.18
                        ),
                        {
                            BackgroundColor3 =
                                Colors.Panel2
                        }
                    ):Play()


                    TweenService:Create(
                        stroke,
                        TweenInfo.new(
                            0.18
                        ),
                        {
                            Color =
                                Colors.Border,

                            Transparency =
                                0
                        }
                    ):Play()


                    TweenService:Create(
                        leftGlow,
                        TweenInfo.new(
                            0.18
                        ),
                        {
                            BackgroundTransparency =
                                0.7
                        }
                    ):Play()

                end
            )


            button.MouseButton1Down:Connect(

                function()

                    TweenService:Create(
                        button,
                        TweenInfo.new(
                            0.08
                        ),
                        {
                            Size =
                                UDim2.new(
                                    1,
                                    -18,
                                    0,
                                    38
                                )
                        }
                    ):Play()

                end
            )


            button.MouseButton1Up:Connect(

                function()

                    TweenService:Create(
                        button,
                        TweenInfo.new(
                            0.12,
                            Enum.EasingStyle.Back
                        ),
                        {
                            Size =
                                UDim2.new(
                                    1,
                                    -14,
                                    0,
                                    41
                                )
                        }
                    ):Play()

                end
            )


            button.MouseButton1Click:Connect(

                function()

                    if callback then

                        task.spawn(
                            function()

                                pcall(
                                    callback
                                )

                            end
                        )

                    end

                end
            )


            return button

        end


        --======================================================
        -- SECTION
        --======================================================

        function _G.vanz.CreateSection(
            parent,
            title
        )

            local holder =
                New(
                    "Frame",
                    {
                        Size =
                            UDim2.new(
                                1,
                                -14,
                                0,
                                29
                            ),

                        BackgroundTransparency =
                            1,
                    },

                    parent
                )


            local line =
                New(
                    "Frame",
                    {
                        Position =
                            UDim2.new(
                                0,
                                0,
                                0.5,
                                3
                            ),

                        Size =
                            UDim2.new(
                                1,
                                0,
                                0,
                                1
                            ),

                        BackgroundColor3 =
                            Colors.Border,

                        BorderSizePixel =
                            0,
                    },

                    holder
                )


            local label =
                New(
                    "TextLabel",
                    {
                        Position =
                            UDim2.new(
                                0,
                                5,
                                0,
                                0
                            ),

                        Size =
                            UDim2.new(
                                0,
                                125,
                                1,
                                0
                            ),

                        BackgroundColor3 =
                            Colors.Background,

                        Text =
                            string.upper(
                                title
                                or
                                "SECTION"
                            ),

                        Font =
                            Enum.Font.GothamBold,

                        TextSize =
                            7,

                        TextColor3 =
                            Colors.TextSecondary,

                        TextXAlignment =
                            Enum.TextXAlignment.Left,
                    },

                    holder
                )


            local sectionAccent =
                New(
                    "Frame",
                    {
                        Position =
                            UDim2.new(
                                0,
                                0,
                                0,
                                9
                            ),

                        Size =
                            UDim2.new(
                                0,
                                2,
                                0,
                                11
                            ),

                        BackgroundColor3 =
                            Colors.Accent,

                        BorderSizePixel =
                            0,
                    },

                    holder
                )


            Corner(
                sectionAccent,
                2
            )


            return holder

        end


        --======================================================
        -- INFO CARD
        --======================================================

        function _G.vanz.CreateInfo(
            parent,
            title,
            description
        )

            local card =
                New(
                    "Frame",
                    {
                        Size =
                            UDim2.new(
                                1,
                                -14,
                                0,
                                79
                            ),

                        BackgroundColor3 =
                            Colors.Panel,

                        BorderSizePixel =
                            0,

                        ClipsDescendants =
                            true,
                    },

                    parent
                )


            Corner(
                card,
                12
            )


            local stroke =
                Stroke(
                    card,
                    Colors.Border,
                    1
                )


            local glow =
                New(
                    "Frame",
                    {
                        Position =
                            UDim2.new(
                                0,
                                0,
                                0,
                                0
                            ),

                        Size =
                            UDim2.new(
                                0,
                                3,
                                1,
                                0
                            ),

                        BackgroundColor3 =
                            Colors.Accent,

                        BorderSizePixel =
                            0,
                    },

                    card
                )


            Corner(
                glow,
                4
            )


            local titleLabel =
                New(
                    "TextLabel",
                    {
                        Position =
                            UDim2.new(
                                0,
                                14,
                                0,
                                10
                            ),

                        Size =
                            UDim2.new(
                                1,
                                -25,
                                0,
                                19
                            ),

                        BackgroundTransparency =
                            1,

                        Text =
                            title or "VANZ",

                        Font =
                            Enum.Font.GothamBold,

                        TextSize =
                            10,

                        TextColor3 =
                            Colors.Text,

                        TextXAlignment =
                            Enum.TextXAlignment.Left,
                    },

                    card
                )


            local descLabel =
                New(
                    "TextLabel",
                    {
                        Position =
                            UDim2.new(
                                0,
                                14,
                                0,
                                33
                            ),

                        Size =
                            UDim2.new(
                                1,
                                -25,
                                0,
                                35
                            ),

                        BackgroundTransparency =
                            1,

                        Text =
                            description or "",

                        Font =
                            Enum.Font.Gotham,

                        TextSize =
                            7,

                        TextColor3 =
                            Colors.TextSecondary,

                        TextWrapped =
                            true,

                        TextXAlignment =
                            Enum.TextXAlignment.Left,

                        TextYAlignment =
                            Enum.TextYAlignment.Top,
                    },

                    card
                )


            return card

        end

    end
)


--==============================================================
-- 3_TAB_SYSTEM
--==============================================================

VanzBlock(
    "3_TAB_SYSTEM",

    function()

        local UI =
            _G.vanz.UI

        local Colors =
            _G.vanz.Colors


        local function New(
            className,
            properties,
            parent
        )

            local object =
                Instance.new(
                    className
                )

            for property, value in pairs(
                properties or {}
            ) do

                object[property] =
                    value

            end

            object.Parent =
                parent

            return object

        end


        local function Corner(
            object,
            radius
        )

            local corner =
                Instance.new(
                    "UICorner"
                )

            corner.CornerRadius =
                UDim.new(
                    0,
                    radius or 8
                )

            corner.Parent =
                object

        end


        local layout =
            New(
                "UIListLayout",
                {
                    Padding =
                        UDim.new(
                            0,
                            7
                        ),

                    SortOrder =
                        Enum.SortOrder.LayoutOrder,

                    HorizontalAlignment =
                        Enum.HorizontalAlignment.Center,

                    VerticalAlignment =
                        Enum.VerticalAlignment.Top,
                },

                UI.Sidebar
            )


        local topPadding =
            New(
                "UIPadding",
                {
                    PaddingTop =
                        UDim.new(
                            0,
                            11
                        ),

                    PaddingLeft =
                        UDim.new(
                            0,
                            7
                        ),

                    PaddingRight =
                        UDim.new(
                            0,
                            7
                        ),
                },

                UI.Sidebar
            )


        local ActiveTab =
            nil


        function _G.vanz.CreateTab(
            name,
            icon
        )

            local button =
                New(
                    "TextButton",
                    {
                        Size =
                            UDim2.new(
                                0,
                                44,
                                0,
                                43
                            ),

                        BackgroundColor3 =
                            Colors.Panel2,

                        BackgroundTransparency =
                            1,

                        BorderSizePixel =
                            0,

                        AutoButtonColor =
                            false,

                        Text =
                            icon or "•",

                        Font =
                            Enum.Font.GothamBold,

                        TextSize =
                            12,

                        TextColor3 =
                            Colors.TextMuted,

                        LayoutOrder =
                            #_G.vanz.Tabs
                            + 1,
                    },

                    UI.Sidebar
                )


            Corner(
                button,
                12
            )


            local indicator =
                New(
                    "Frame",
                    {
                        Position =
                            UDim2.new(
                                0,
                                -1,
                                0.5,
                                -10
                            ),

                        Size =
                            UDim2.new(
                                0,
                                2,
                                0,
                                20
                            ),

                        BackgroundColor3 =
                            Colors.Accent,

                        BorderSizePixel =
                            0,

                        BackgroundTransparency =
                            1,
                    },

                    button
                )


            Corner(
                indicator,
                3
            )


            local tabGlow =
                New(
                    "Frame",
                    {
                        AnchorPoint =
                            Vector2.new(
                                0.5,
                                0.5
                            ),

                        Position =
                            UDim2.fromScale(
                                0.5,
                                0.5
                            ),

                        Size =
                            UDim2.new(
                                1,
                                5,
                                1,
                                5
                            ),

                        BackgroundColor3 =
                            Colors.Accent,

                        BackgroundTransparency =
                            1,

                        BorderSizePixel =
                            0,

                        ZIndex =
                            button.ZIndex - 1,
                    },

                    button
                )


            Corner(
                tabGlow,
                14
            )


            local page =
                New(
                    "ScrollingFrame",
                    {
                        Name =
                            name .. "_Page",

                        Size =
                            UDim2.fromScale(
                                1,
                                1
                            ),

                        BackgroundTransparency =
                            1,

                        BorderSizePixel =
                            0,

                        ScrollBarThickness =
                            2,

                        ScrollBarImageColor3 =
                            Colors.Accent,

                        CanvasSize =
                            UDim2.new(
                                0,
                                0,
                                0,
                                0
                            ),

                        AutomaticCanvasSize =
                            Enum.AutomaticSize.Y,

                        ScrollingDirection =
                            Enum.ScrollingDirection.Y,

                        Visible =
                            false,

                        ZIndex =
                            8,
                    },

                    UI.Pages
                )


            local padding =
                New(
                    "UIPadding",
                    {
                        PaddingTop =
                            UDim.new(
                                0,
                                10
                            ),

                        PaddingBottom =
                            UDim.new(
                                0,
                                18
                            ),

                        PaddingLeft =
                            UDim.new(
                                0,
                                7
                            ),

                        PaddingRight =
                            UDim.new(
                                0,
                                7
                            ),
                    },

                    page
                )


            local pageLayout =
                New(
                    "UIListLayout",
                    {
                        Padding =
                            UDim.new(
                                0,
                                6
                            ),

                        SortOrder =
                            Enum.SortOrder.LayoutOrder,
                    },

                    page
                )


            local tab = {

                Name =
                    name,

                Icon =
                    icon,

                Button =
                    button,

                Page =
                    page,

                Indicator =
                    indicator,

                Glow =
                    tabGlow,

            }


            table.insert(
                _G.vanz.Tabs,
                tab
            )


            local function Activate()

                if ActiveTab == tab then
                    return
                end


                for _, other in ipairs(
                    _G.vanz.Tabs
                ) do

                    other.Page.Visible =
                        false


                    TweenService:Create(

                        other.Button,

                        TweenInfo.new(
                            0.18
                        ),

                        {
                            BackgroundTransparency =
                                1,

                            TextColor3 =
                                Colors.TextMuted,
                        }

                    ):Play()


                    TweenService:Create(

                        other.Indicator,

                        TweenInfo.new(
                            0.18
                        ),

                        {
                            BackgroundTransparency =
                                1,
                        }

                    ):Play()


                    TweenService:Create(

                        other.Glow,

                        TweenInfo.new(
                            0.18
                        ),

                        {
                            BackgroundTransparency =
                                1,
                        }

                    ):Play()

                end


                ActiveTab =
                    tab


                page.Visible =
                    true


                page.Position =
                    UDim2.new(
                        0,
                        14,
                        0,
                        0
                    )


                TweenService:Create(

                    button,

                    TweenInfo.new(
                        0.2,
                        Enum.EasingStyle.Quart,
                        Enum.EasingDirection.Out
                    ),

                    {
                        BackgroundTransparency =
                            0,

                        BackgroundColor3 =
                            Colors.Panel2,

                        TextColor3 =
                            Colors.Text,
                    }

                ):Play()


                TweenService:Create(

                    indicator,

                    TweenInfo.new(
                        0.25,
                        Enum.EasingStyle.Back,
                        Enum.EasingDirection.Out
                    ),

                    {
                        BackgroundTransparency =
                            0,
                    }

                ):Play()


                TweenService:Create(

                    tabGlow,

                    TweenInfo.new(
                        0.25
                    ),

                    {
                        BackgroundTransparency =
                            0.9,
                    }

                ):Play()


                if _G.vanz.Config.Animations then

                    TweenService:Create(

                        page,

                        TweenInfo.new(
                            0.3,
                            Enum.EasingStyle.Quart,
                            Enum.EasingDirection.Out
                        ),

                        {
                            Position =
                                UDim2.new(
                                    0,
                                    0,
                                    0,
                                    0
                                ),
                        }

                    ):Play()

                else

                    page.Position =
                        UDim2.new(
                            0,
                            0,
                            0,
                            0
                        )

                end

            end


            button.MouseButton1Click:Connect(
                Activate
            )


            button.MouseEnter:Connect(

                function()

                    if ActiveTab ~= tab then

                        TweenService:Create(

                            button,

                            TweenInfo.new(
                                0.15
                            ),

                            {
                                BackgroundTransparency =
                                    0.7,

                                TextColor3 =
                                    Colors.TextSecondary,
                            }

                        ):Play()

                    end

                end
            )


            button.MouseLeave:Connect(

                function()

                    if ActiveTab ~= tab then

                        TweenService:Create(

                            button,

                            TweenInfo.new(
                                0.15
                            ),

                            {
                                BackgroundTransparency =
                                    1,

                                TextColor3 =
                                    Colors.TextMuted,
                            }

                        ):Play()

                    end

                end
            )


            if #_G.vanz.Tabs == 1 then

                task.defer(
                    Activate
                )

            end


            return tab

        end

    end
)


--==============================================================
-- 4_HOME
--==============================================================

VanzBlock(
    "4_HOME",

    function()

        local tab =
            _G.vanz.CreateTab(
                "Home",
                "⌂"
            )

        local page =
            tab.Page


        _G.vanz.CreateInfo(

            page,

            "VANZ CONTROL CENTER",

            "Ultra premium modular interface dengan animated neon system, smooth transitions, responsive scaling, dan feature architecture."
        )


        _G.vanz.CreateSection(
            page,
            "MASTER CONTROL"
        )


        _G.vanz.CreateToggle(

            page,

            "Master Switch",

            "Main controller untuk feature system.",

            false,

            function(value)

                _G.vanz.State.MasterSwitch =
                    value

            end
        )


        _G.vanz.CreateToggle(

            page,

            "Interface Effects",

            "Aktifkan efek visual interface.",

            true,

            function(value)

                _G.vanz.State.InterfaceEffects =
                    value

            end
        )


        _G.vanz.CreateToggle(

            page,

            "Animations",

            "Aktifkan animasi UI.",

            true,

            function(value)

                _G.vanz.Config.Animations =
                    value

            end
        )


        _G.vanz.CreateSection(
            page,
            "QUICK SETTINGS"
        )


        _G.vanz.CreateToggle(

            page,

            "Compact Interface",

            "Gunakan spacing interface yang lebih kecil.",

            false,

            function(value)

                _G.vanz.State.Compact =
                    value

            end
        )


        _G.vanz.CreateToggle(

            page,

            "Dynamic Colors",

            "Aktifkan RGB accent animation.",

            true,

            function(value)

                _G.vanz.Config.DynamicColors =
                    value

            end
        )


        _G.vanz.CreateToggle(

            page,

            "Glow Effects",

            "Aktifkan animated neon glow.",

            true,

            function(value)

                _G.vanz.Config.Glow =
                    value

            end
        )

    end
)


--==============================================================
-- 5_PLAYER
--==============================================================

VanzBlock(
    "5_PLAYER",

    function()

        local tab =
            _G.vanz.CreateTab(
                "Player",
                "P"
            )

        local page =
            tab.Page


        _G.vanz.CreateSection(
            page,
            "PLAYER FEATURES"
        )


        for index = 1, 10 do

            _G.vanz.CreateToggle(

                page,

                "Player Feature " ..
                    string.format(
                        "%02d",
                        index
                    ),

                "Empty configurable feature slot.",

                false,

                function(value)

                    _G.vanz.State[
                        "PlayerFeature" ..
                        index
                    ] =
                        value

                end
            )

        end

    end
)


--==============================================================
-- 6_VISUAL
--==============================================================

VanzBlock(
    "6_VISUAL",

    function()

        local tab =
            _G.vanz.CreateTab(
                "Visual",
                "V"
            )

        local page =
            tab.Page


        _G.vanz.CreateSection(
            page,
            "VISUAL FEATURES"
        )


        for index = 1, 10 do

            _G.vanz.CreateToggle(

                page,

                "Visual Feature " ..
                    string.format(
                        "%02d",
                        index
                    ),

                "Empty configurable visual slot.",

                false,

                function(value)

                    _G.vanz.State[
                        "VisualFeature" ..
                        index
                    ] =
                        value

                end
            )

        end

    end
)


--==============================================================
-- 7_WORLD
--==============================================================

VanzBlock(
    "7_WORLD",

    function()

        local tab =
            _G.vanz.CreateTab(
                "World",
                "W"
            )

        local page =
            tab.Page


        _G.vanz.CreateSection(
            page,
            "WORLD FEATURES"
        )


        for index = 1, 10 do

            _G.vanz.CreateToggle(

                page,

                "World Feature " ..
                    string.format(
                        "%02d",
                        index
                    ),

                "Empty configurable world slot.",

                false,

                function(value)

                    _G.vanz.State[
                        "WorldFeature" ..
                        index
                    ] =
                        value

                end
            )

        end

    end
)


--==============================================================
-- 8_MISC
--==============================================================

VanzBlock(
    "8_MISC",

    function()

        local tab =
            _G.vanz.CreateTab(
                "Misc",
                "M"
            )

        local page =
            tab.Page


        _G.vanz.CreateSection(
            page,
            "MISC FEATURES"
        )


        for index = 1, 10 do

            _G.vanz.CreateToggle(

                page,

                "Misc Feature " ..
                    string.format(
                        "%02d",
                        index
                    ),

                "Empty configurable miscellaneous slot.",

                false,

                function(value)

                    _G.vanz.State[
                        "MiscFeature" ..
                        index
                    ] =
                        value

                end
            )

        end

    end
)


--==============================================================
-- 9_EXTRA
--==============================================================

VanzBlock(
    "9_EXTRA",

    function()

        local tab =
            _G.vanz.CreateTab(
                "Extra",
                "★"
            )

        local page =
            tab.Page


        _G.vanz.CreateSection(
            page,
            "EXTRA FEATURES"
        )


        for index = 1, 8 do

            _G.vanz.CreateToggle(

                page,

                "Extra Feature " ..
                    string.format(
                        "%02d",
                        index
                    ),

                "Empty configurable extra slot.",

                false,

                function(value)

                    _G.vanz.State[
                        "ExtraFeature" ..
                        index
                    ] =
                        value

                end
            )

        end


        _G.vanz.CreateSection(
            page,
            "ACTIONS"
        )


        _G.vanz.CreateButton(

            page,

            "Action Slot 01",

            function()

                _G.vanz.State.LastAction =
                    "Action01"

            end
        )


        _G.vanz.CreateButton(

            page,

            "Action Slot 02",

            function()

                _G.vanz.State.LastAction =
                    "Action02"

            end
        )


        _G.vanz.CreateButton(

            page,

            "Action Slot 03",

            function()

                _G.vanz.State.LastAction =
                    "Action03"

            end
        )

    end
)


--==============================================================
-- 10_SETTINGS
--==============================================================

VanzBlock(
    "10_SETTINGS",

    function()

        local tab =
            _G.vanz.CreateTab(
                "Settings",
                "⚙"
            )

        local page =
            tab.Page


        _G.vanz.CreateSection(
            page,
            "GENERAL"
        )


        _G.vanz.CreateToggle(

            page,

            "Animations",

            "Enable / disable menu animations.",

            true,

            function(value)

                _G.vanz.Config.Animations =
                    value

            end
        )


        _G.vanz.CreateToggle(

            page,

            "Floating Logo",

            "Show V logo when menu is minimized.",

            true,

            function(value)

                _G.vanz.Config.FloatingLogo =
                    value


                if
                    _G.vanz.UI.FloatingLogo
                then

                    _G.vanz.UI.FloatingLogo.Visible =
                        value
                        and
                        _G.vanz.Config.Minimized

                end


                if
                    _G.vanz.UI.FloatingGlow
                then

                    _G.vanz.UI.FloatingGlow.Visible =
                        value
                        and
                        _G.vanz.Config.Minimized

                end

            end
        )


        _G.vanz.CreateToggle(

            page,

            "Dynamic Accent",

            "Animated RGB accent throughout interface.",

            true,

            function(value)

                _G.vanz.Config.DynamicColors =
                    value

            end
        )


        _G.vanz.CreateSection(
            page,
            "DPI / GUI SCALE"
        )


        --======================================================
        -- DPI HOLDER
        --======================================================

        local dpiHolder =
            Instance.new(
                "Frame"
            )

        dpiHolder.Size =
            UDim2.new(
                1,
                -14,
                0,
                121
            )

        dpiHolder.BackgroundColor3 =
            Colors.Panel2

        dpiHolder.BorderSizePixel =
            0

        dpiHolder.Parent =
            page


        Corner(
            dpiHolder,
            11
        )


        Stroke(
            dpiHolder,
            Colors.Border,
            1
        )


        local dpiTitle =
            Instance.new(
                "TextLabel"
            )

        dpiTitle.Position =
            UDim2.new(
                0,
                12,
                0,
                8
            )

        dpiTitle.Size =
            UDim2.new(
                1,
                -24,
                0,
                18
            )

        dpiTitle.BackgroundTransparency =
            1

        dpiTitle.Text =
            "DPI SCALE"

        dpiTitle.Font =
            Enum.Font.GothamBold

        dpiTitle.TextSize =
            9

        dpiTitle.TextColor3 =
            Colors.Text

        dpiTitle.TextXAlignment =
            Enum.TextXAlignment.Left

        dpiTitle.Parent =
            dpiHolder


        local dpiDescription =
            Instance.new(
                "TextLabel"
            )

        dpiDescription.Position =
            UDim2.new(
                0,
                12,
                0,
                27
            )

        dpiDescription.Size =
            UDim2.new(
                1,
                -24,
                0,
                14
            )

        dpiDescription.BackgroundTransparency =
            1

        dpiDescription.Text =
            "Pilih ukuran interface."

        dpiDescription.Font =
            Enum.Font.Gotham

        dpiDescription.TextSize =
            7

        dpiDescription.TextColor3 =
            Colors.TextSecondary

        dpiDescription.TextXAlignment =
            Enum.TextXAlignment.Left

        dpiDescription.Parent =
            dpiHolder


        --======================================================
        -- DPI BUTTON CONTAINER
        --======================================================

        local dpiButtonsHolder =
            Instance.new(
                "Frame"
            )

        dpiButtonsHolder.Position =
            UDim2.new(
                0,
                10,
                0,
                49
            )

        dpiButtonsHolder.Size =
            UDim2.new(
                1,
                -20,
                0,
                62
            )

        dpiButtonsHolder.BackgroundTransparency =
            1

        dpiButtonsHolder.Parent =
            dpiHolder


        local dpiLayout =
            Instance.new(
                "UIGridLayout"
            )

        dpiLayout.CellSize =
            UDim2.new(
                0,
                34,
                0,
                26
            )

        dpiLayout.CellPadding =
            UDim2.new(
                0,
                5,
                0,
                5
            )

        dpiLayout.FillDirection =
            Enum.FillDirection.Horizontal

        dpiLayout.StartCorner =
            Enum.StartCorner.TopLeft

        dpiLayout.SortOrder =
            Enum.SortOrder.LayoutOrder

        dpiLayout.Parent =
            dpiButtonsHolder


        local DPIValues = {

            0.50,
            0.75,
            1.00,
            1.50,
            1.75,
            2.00,

        }


        local DPILabels = {

            "50%",
            "75%",
            "100%",
            "150%",
            "175%",
            "200%",

        }


        local dpiButtons = {}


        local function ApplyDPI(
            value
        )

            value =
                math.clamp(
                    value,
                    0.5,
                    2
                )


            _G.vanz.Config.Scale =
                value


            if _G.vanz.UI.Scale then

                TweenService:Create(

                    _G.vanz.UI.Scale,

                    TweenInfo.new(
                        0.3,
                        Enum.EasingStyle.Quart,
                        Enum.EasingDirection.Out
                    ),

                    {
                        Scale =
                            value
                    }

                ):Play()

            end


            for index, button in pairs(
                dpiButtons
            ) do

                if
                    DPIValues[index]
                        == value
                then

                    TweenService:Create(

                        button,

                        TweenInfo.new(
                            0.16,
                            Enum.EasingStyle.Quart
                        ),

                        {
                            BackgroundColor3 =
                                Colors.Accent,

                            TextColor3 =
                                Color3.new(
                                    1,
                                    1,
                                    1
                                ),
                        }

                    ):Play()

                else

                    TweenService:Create(

                        button,

                        TweenInfo.new(
                            0.16
                        ),

                        {
                            BackgroundColor3 =
                                Colors.Panel3,

                            TextColor3 =
                                Colors.TextSecondary,
                        }

                    ):Play()

                end

            end

        end


        for index, value in ipairs(
            DPIValues
        ) do

            local button =
                Instance.new(
                    "TextButton"
                )


            button.Size =
                UDim2.new(
                    0,
                    34,
                    0,
                    26
                )


            button.BackgroundColor3 =
                Colors.Panel3


            button.BorderSizePixel =
                0


            button.AutoButtonColor =
                false


            button.Text =
                DPILabels[index]


            button.Font =
                Enum.Font.GothamBold


            button.TextSize =
                7


            button.TextColor3 =
                Colors.TextSecondary


            button.LayoutOrder =
                index


            button.Parent =
                dpiButtonsHolder


            Corner(
                button,
                7
            )


            dpiButtons[index] =
                button


            button.MouseEnter:Connect(

                function()

                    if
                        DPIValues[index]
                            ~= _G.vanz.Config.Scale
                    then

                        TweenService:Create(

                            button,

                            TweenInfo.new(
                                0.12
                            ),

                            {
                                BackgroundColor3 =
                                    Colors.Panel2,

                                TextColor3 =
                                    Colors.Text,
                            }

                        ):Play()

                    end

                end
            )


            button.MouseLeave:Connect(

                function()

                    if
                        DPIValues[index]
                            ~= _G.vanz.Config.Scale
                    then

                        TweenService:Create(

                            button,

                            TweenInfo.new(
                                0.12
                            ),

                            {
                                BackgroundColor3 =
                                    Colors.Panel3,

                                TextColor3 =
                                    Colors.TextSecondary,
                            }

                        ):Play()

                    end

                end
            )


            button.MouseButton1Click:Connect(

                function()

                    ApplyDPI(
                        value
                    )

                end
            )

        end


        -- DEFAULT 100%

        ApplyDPI(
            1.00
        )


        --======================================================
        -- SYSTEM
        --======================================================

        _G.vanz.CreateSection(
            page,
            "SYSTEM"
        )


        _G.vanz.CreateButton(

            page,

            "Reset Floating Logo",

            function()

                if
                    _G.vanz.UI.FloatingLogo
                then

                    _G.vanz.UI.FloatingLogo.Position =
                        UDim2.fromScale(
                            0.5,
                            0.5
                        )

                end


                if
                    _G.vanz.UI.FloatingGlow
                then

                    _G.vanz.UI.FloatingGlow.Position =
                        UDim2.fromScale(
                            0.5,
                            0.5
                        )

                end

            end
        )


        _G.vanz.CreateButton(

            page,

            "Minimize GUI",

            function()

                if
                    _G.vanz.UI.Minimize
                then

                    _G.vanz.UI.Minimize()

                end

            end
        )

    end
)


--==============================================================
-- 11_ANIMATION ENGINE
--==============================================================

VanzBlock(
    "11_ANIMATION_ENGINE",

    function()

        local UI =
            _G.vanz.UI

        local Colors =
            _G.vanz.Colors


        local hue =
            0


        local gradientOffset =
            0


        local pulseTime =
            0


        local connection


        connection =
            RunService.RenderStepped:Connect(

                function(deltaTime)

                    if
                        not UI.ScreenGui
                        or
                        not UI.ScreenGui.Parent
                    then

                        if connection then
                            connection:Disconnect()
                        end

                        return

                    end


                    pulseTime =
                        pulseTime
                        + deltaTime


                    --================================================
                    -- RGB COLOR ENGINE
                    --================================================

                    if
                        _G.vanz.Config.DynamicColors
                    then

                        hue =
                            (
                                hue
                                + deltaTime * 0.09
                            ) % 1


                        local colorA =
                            Color3.fromHSV(
                                hue,
                                0.72,
                                1
                            )


                        local colorB =
                            Color3.fromHSV(
                                (
                                    hue
                                    + 0.12
                                ) % 1,
                                0.72,
                                1
                            )


                        local colorC =
                            Color3.fromHSV(
                                (
                                    hue
                                    + 0.24
                                ) % 1,
                                0.72,
                                1
                            )


                        Colors.Accent =
                            colorA

                        Colors.Accent2 =
                            colorB

                        Colors.Accent3 =
                            colorC


                        --================================================
                        -- LOGO
                        --================================================

                        if UI.Logo then

                            UI.Logo.TextColor3 =
                                colorA

                            UI.Logo.TextStrokeColor3 =
                                colorB

                        end


                        --================================================
                        -- LOGO STROKE
                        --================================================

                        if UI.LogoStroke then

                            UI.LogoStroke.Color =
                                colorA

                        end


                        --================================================
                        -- LOGO GLOW
                        --================================================

                        if UI.LogoGlow then

                            UI.LogoGlow.BackgroundColor3 =
                                colorA

                        end


                        --================================================
                        -- TOP GRADIENT
                        --================================================

                        if UI.TopGradient then

                            UI.TopGradient.Color =
                                ColorSequence.new({

                                    ColorSequenceKeypoint.new(
                                        0,
                                        colorA
                                    ),

                                    ColorSequenceKeypoint.new(
                                        0.5,
                                        colorB
                                    ),

                                    ColorSequenceKeypoint.new(
                                        1,
                                        colorC
                                    ),

                                })

                        end


                        --================================================
                        -- FLOATING LOGO
                        --================================================

                        if UI.FloatingLogo then

                            UI.FloatingLogo.TextColor3 =
                                colorA

                        end


                        if UI.FloatingStroke then

                            UI.FloatingStroke.Color =
                                colorB

                        end


                        if UI.FloatingGlow then

                            UI.FloatingGlow.BackgroundColor3 =
                                colorA

                        end


                        if UI.FloatingGradient then

                            UI.FloatingGradient.Color =
                                ColorSequence.new({

                                    ColorSequenceKeypoint.new(
                                        0,
                                        colorA
                                    ),

                                    ColorSequenceKeypoint.new(
                                        0.5,
                                        colorB
                                    ),

                                    ColorSequenceKeypoint.new(
                                        1,
                                        colorC
                                    ),

                                })

                        end


                        if UI.OuterGlowGradient then

                            UI.OuterGlowGradient.Color =
                                ColorSequence.new({

                                    ColorSequenceKeypoint.new(
                                        0,
                                        colorA
                                    ),

                                    ColorSequenceKeypoint.new(
                                        1,
                                        colorB
                                    ),

                                })

                        end


                        if UI.SidebarGlow then

                            UI.SidebarGlow.BackgroundColor3 =
                                colorA

                        end

                    end


                    --================================================
                    -- PULSE GLOW
                    --================================================

                    if
                        _G.vanz.Config.Glow
                        and
                        _G.vanz.Config.Animations
                    then

                        local pulse =
                            (
                                math.sin(
                                    pulseTime * 2.3
                                )
                                + 1
                            )
                            / 2


                        if UI.OuterGlow then

                            UI.OuterGlow.BackgroundTransparency =
                                0.94
                                - (
                                    pulse
                                    * 0.035
                                )

                        end


                        if UI.LogoGlow then

                            UI.LogoGlow.BackgroundTransparency =
                                0.88
                                - (
                                    pulse
                                    * 0.1
                                )

                        end


                        if UI.FloatingGlow then

                            UI.FloatingGlow.BackgroundTransparency =
                                0.93
                                - (
                                    pulse
                                    * 0.08
                                )

                        end

                    else

                        if UI.OuterGlow then
                            UI.OuterGlow.BackgroundTransparency =
                                1
                        end

                    end


                    --================================================
                    -- MOVING GRADIENT
                    --================================================

                    if
                        _G.vanz.Config.Animations
                    then

                        gradientOffset =
                            (
                                gradientOffset
                                + deltaTime * 0.08
                            ) % 1


                        if UI.TopGradient then

                            UI.TopGradient.Offset =
                                Vector2.new(
                                    gradientOffset,
                                    0
                                )

                        end


                        if UI.FloatingGradient then

                            UI.FloatingGradient.Offset =
                                Vector2.new(
                                    -gradientOffset,
                                    0
                                )

                        end

                    end

                end
            )


        table.insert(
            _G.vanz.Connections,
            connection
        )


        --==========================================================
        -- FLOATING LOGO BREATHING
        --==========================================================

        task.spawn(

            function()

                while
                    UI.ScreenGui
                    and
                    UI.ScreenGui.Parent
                do

                    if
                        UI.FloatingLogo
                        and
                        UI.FloatingLogo.Visible
                        and
                        _G.vanz.Config.Animations
                    then

                        local first =
                            TweenService:Create(

                                UI.FloatingLogo,

                                TweenInfo.new(
                                    1.1,
                                    Enum.EasingStyle.Sine,
                                    Enum.EasingDirection.InOut
                                ),

                                {
                                    Rotation =
                                        6
                                }
                            )


                        first:Play()

                        first.Completed:Wait()


                        if
                            not UI.FloatingLogo
                            or
                            not UI.FloatingLogo.Parent
                        then

                            break

                        end


                        local second =
                            TweenService:Create(

                                UI.FloatingLogo,

                                TweenInfo.new(
                                    1.1,
                                    Enum.EasingStyle.Sine,
                                    Enum.EasingDirection.InOut
                                ),

                                {
                                    Rotation =
                                        -6
                                }
                            )


                        second:Play()

                        second.Completed:Wait()

                    else

                        task.wait(
                            0.25
                        )

                    end

                end

            end
        )

    end
)


--==============================================================
-- 12_EXTRA_VISUALS
--==============================================================

VanzBlock(
    "12_EXTRA_VISUALS",

    function()

        local UI =
            _G.vanz.UI


        --======================================================
        -- LOGO HOVER
        --======================================================

        if UI.Logo then

            UI.Logo.MouseEnter:Connect(

                function()

                    TweenService:Create(

                        UI.Logo,

                        TweenInfo.new(
                            0.2,
                            Enum.EasingStyle.Back,
                            Enum.EasingDirection.Out
                        ),

                        {
                            Rotation =
                                -8,

                            TextSize =
                                29,
                        }

                    ):Play()

                end
            )


            UI.Logo.MouseLeave:Connect(

                function()

                    TweenService:Create(

                        UI.Logo,

                        TweenInfo.new(
                            0.2,
                            Enum.EasingStyle.Back,
                            Enum.EasingDirection.Out
                        ),

                        {
                            Rotation =
                                0,

                            TextSize =
                                27,
                        }

                    ):Play()

                end
            )

        end


        --======================================================
        -- MINIMIZE HOVER
        --======================================================

        if UI.MinimizeButton then

            UI.MinimizeButton.MouseEnter:Connect(

                function()

                    TweenService:Create(

                        UI.MinimizeButton,

                        TweenInfo.new(
                            0.15
                        ),

                        {
                            BackgroundColor3 =
                                _G.vanz.Colors.Panel3,

                            TextColor3 =
                                Color3.new(
                                    1,
                                    1,
                                    1
                                ),

                            Rotation =
                                3,
                        }

                    ):Play()

                end
            )


            UI.MinimizeButton.MouseLeave:Connect(

                function()

                    TweenService:Create(

                        UI.MinimizeButton,

                        TweenInfo.new(
                            0.15
                        ),

                        {
                            BackgroundColor3 =
                                _G.vanz.Colors.Panel2,

                            TextColor3 =
                                _G.vanz.Colors.TextSecondary,

                            Rotation =
                                0,
                        }

                    ):Play()

                end
            )

        end


        --======================================================
        -- STATUS DOT PULSE
        --======================================================

        if UI.StatusDot then

            task.spawn(

                function()

                    while
                        UI.StatusDot
                        and
                        UI.StatusDot.Parent
                    do

                        if
                            _G.vanz.Config.Animations
                        then

                            TweenService:Create(

                                UI.StatusDot,

                                TweenInfo.new(
                                    0.75,
                                    Enum.EasingStyle.Sine,
                                    Enum.EasingDirection.InOut
                                ),

                                {
                                    Size =
                                        UDim2.new(
                                            0,
                                            8,
                                            0,
                                            8
                                        ),

                                    BackgroundTransparency =
                                        0.25,
                                }

                            ):Play()


                            task.wait(
                                0.75
                            )


                            TweenService:Create(

                                UI.StatusDot,

                                TweenInfo.new(
                                    0.75,
                                    Enum.EasingStyle.Sine,
                                    Enum.EasingDirection.InOut
                                ),

                                {
                                    Size =
                                        UDim2.new(
                                            0,
                                            6,
                                            0,
                                            6
                                        ),

                                    BackgroundTransparency =
                                        0,
                                }

                            ):Play()


                            task.wait(
                                0.75
                            )

                        else

                            task.wait(
                                0.3
                            )

                        end

                    end

                end
            )

        end

    end
)


--==============================================================
-- 13_GLOBAL_API
--==============================================================

VanzBlock(
    "13_GLOBAL_API",

    function()

        --======================================================
        -- OPEN
        --======================================================

        _G.vanz.Open =
            function()

                if
                    _G.vanz.UI.Restore
                then

                    _G.vanz.UI.Restore()

                end

            end


        --======================================================
        -- CLOSE
        --======================================================

        _G.vanz.Close =
            function()

                if
                    _G.vanz.UI.Minimize
                then

                    _G.vanz.UI.Minimize()

                end

            end


        --======================================================
        -- SCALE
        --======================================================

        _G.vanz.SetScale =
            function(value)

                local allowed = {

                    [0.50] =
                        true,

                    [0.75] =
                        true,

                    [1.00] =
                        true,

                    [1.50] =
                        true,

                    [1.75] =
                        true,

                    [2.00] =
                        true,

                }


                if not allowed[value] then

                    warn(
                        "[VANZ] Invalid DPI. Allowed: 50, 75, 100, 150, 175, 200"
                    )

                    return

                end


                _G.vanz.Config.Scale =
                    value


                if
                    _G.vanz.UI.Scale
                then

                    _G.vanz.UI.Scale.Scale =
                        value

                end

            end


        --======================================================
        -- STATE
        --======================================================

        _G.vanz.GetState =
            function(name)

                return
                    _G.vanz.State[name]

            end


        _G.vanz.SetState =
            function(
                name,
                value
            )

                _G.vanz.State[name] =
                    value

            end

    end
)


--==============================================================
-- 14_FINALIZE
--==============================================================

VanzBlock(
    "14_FINALIZE",

    function()

        _G.vanz.State.GUIReady =
            true


        _G.vanz.State.Version =
            _G.vanz.Config.Version


        print(
            "================================================"
        )

        print(
            "[VANZ] ULTRA PREMIUM GUI INITIALIZED"
        )

        print(
            "[VANZ] Version: " ..
            tostring(
                _G.vanz.Config.Version
            )
        )

        print(
            "[VANZ] Tabs: " ..
            tostring(
                #_G.vanz.Tabs
            )
        )

        print(
            "[VANZ] Default DPI: 100%"
        )

        print(
            "[VANZ] DPI: 50 / 75 / 100 / 150 / 175 / 200"
        )

        print(
            "[VANZ] RGB NEON ENGINE: ON"
        )

        print(
            "[VANZ] GLOW ENGINE: ON"
        )

        print(
            "[VANZ] GUI ONLY / PREMIUM BASE"
        )

        print(
            "================================================"
        )

    end
)