--==============================================================
-- VANZ // PREMIUM MODULAR GUI BASE
--==============================================================
-- GUI ONLY
--
-- FEATURES
-- • Premium V logo
-- • Animated color system
-- • Animated accent / glow
-- • Responsive mobile layout
-- • DPI presets: 50 / 75 / 100 / 150 / 175 / 200
-- • Default DPI: 75%
-- • Draggable floating V logo
-- • Minimize / restore animation
-- • Multiple tabs
-- • Large feature capacity
-- • Toggle system
-- • Button system
-- • Section system
-- • Scrollable pages
-- • Shared state through _G.vanz
-- • xpcall per block
-- • Custom error traceback
--==============================================================


--==============================================================
-- VANZ GLOBAL CORE
--==============================================================

_G.vanz = _G.vanz or {}

_G.vanz.Config = _G.vanz.Config or {
    Title = "VANZ",
    Version = "2.0.0",

    -- DEFAULT DPI = 75%
    Scale = 0.75,

    Minimized = false,
    Animations = true,
    FloatingLogo = true,
    TouchFriendly = true,

    DynamicColors = true,
    Glow = true,
}

_G.vanz.State = _G.vanz.State or {}
_G.vanz.UI = _G.vanz.UI or {}
_G.vanz.Tabs = _G.vanz.Tabs or {}
_G.vanz.Components = _G.vanz.Components or {}
_G.vanz.Connections = _G.vanz.Connections or {}


--==============================================================
-- SERVICES
--==============================================================

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")


--==============================================================
-- ERROR HANDLER
--==============================================================

local function VanzError(blockName, err)

    local errorText = tostring(err)

    local trace = debug.traceback(
        "",
        2
    )

    warn(
        "\n[VANZ ERROR]["
        .. tostring(blockName)
        .. "] "
        .. errorText
        .. "\n"
        .. trace
        .. "\n"
    )

    return errorText

end


local function VanzBlock(blockName, callback)

    local success, result = xpcall(
        callback,
        function(err)

            return VanzError(
                blockName,
                err
            )

        end
    )

    return success, result

end


--==============================================================
-- 1_INIT_GUI
--==============================================================

VanzBlock("1_INIT_GUI", function()

    --==========================================================
    -- CLEAN OLD INSTANCE
    --==========================================================

    local oldGui = PlayerGui:FindFirstChild(
        "VANZ_GUI"
    )

    if oldGui then
        oldGui:Destroy()
    end


    --==========================================================
    -- HELPER
    --==========================================================

    local function New(
        className,
        properties,
        parent
    )

        local object = Instance.new(
            className
        )

        for property, value in pairs(
            properties or {}
        ) do

            object[property] = value

        end

        object.Parent = parent

        return object

    end


    local function Corner(
        object,
        radius
    )

        local corner = Instance.new(
            "UICorner"
        )

        corner.CornerRadius = UDim.new(
            0,
            radius or 8
        )

        corner.Parent = object

        return corner

    end


    local function Stroke(
        object,
        color,
        thickness,
        transparency
    )

        local stroke = Instance.new(
            "UIStroke"
        )

        stroke.Color =
            color
            or Color3.fromRGB(
                70,
                70,
                90
            )

        stroke.Thickness =
            thickness
            or 1

        stroke.Transparency =
            transparency
            or 0

        stroke.Parent = object

        return stroke

    end


    local function Gradient(
        object,
        colorA,
        colorB,
        rotation
    )

        local gradient = Instance.new(
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

        gradient.Parent = object

        return gradient

    end


    --==========================================================
    -- COLOR PALETTE
    --==========================================================

    local Colors = {

        Background =
            Color3.fromRGB(
                7,
                8,
                13
            ),

        Background2 =
            Color3.fromRGB(
                11,
                12,
                19
            ),

        Panel =
            Color3.fromRGB(
                15,
                17,
                26
            ),

        Panel2 =
            Color3.fromRGB(
                20,
                22,
                33
            ),

        Panel3 =
            Color3.fromRGB(
                25,
                27,
                40
            ),

        Sidebar =
            Color3.fromRGB(
                10,
                11,
                18
            ),

        Text =
            Color3.fromRGB(
                245,
                246,
                255
            ),

        TextSecondary =
            Color3.fromRGB(
                155,
                158,
                178
            ),

        TextMuted =
            Color3.fromRGB(
                100,
                104,
                125
            ),

        Border =
            Color3.fromRGB(
                40,
                43,
                61
            ),

        ToggleOff =
            Color3.fromRGB(
                48,
                50,
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
                55,
                185,
                255
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


    --==========================================================
    -- SCREEN GUI
    --==========================================================

    local ScreenGui = New(
        "ScreenGui",
        {
            Name = "VANZ_GUI",

            ResetOnSpawn = false,

            IgnoreGuiInset = true,

            ZIndexBehavior =
                Enum.ZIndexBehavior.Sibling,

            DisplayOrder = 999,
        },
        PlayerGui
    )


    _G.vanz.UI.ScreenGui =
        ScreenGui


    --==========================================================
    -- GLOBAL SCALE
    --==========================================================

    local GlobalScale = New(
        "UIScale",
        {
            Scale =
                _G.vanz.Config.Scale
                or 0.75
        },
        ScreenGui
    )


    _G.vanz.UI.Scale =
        GlobalScale


    --==========================================================
    -- MAIN SHADOW
    --==========================================================

    local Shadow = New(
        "ImageLabel",
        {
            Name = "Shadow",

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
                    305,
                    0.9,
                    35
                ),

            BackgroundTransparency = 1,

            Image =
                "rbxassetid://1316045217",

            ImageColor3 =
                Color3.new(
                    0,
                    0,
                    0
                ),

            ImageTransparency = 0.25,

            ScaleType =
                Enum.ScaleType.Slice,

            SliceCenter =
                Rect.new(
                    10,
                    10,
                    118,
                    118
                ),

            ZIndex = 0,
        },
        ScreenGui
    )


    --==========================================================
    -- MAIN WINDOW
    --==========================================================

    local Main = New(
        "Frame",
        {
            Name = "MainWindow",

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
                    260,
                    0.85,
                    0
                ),

            BackgroundColor3 =
                Colors.Background,

            BorderSizePixel = 0,

            ClipsDescendants = true,

            ZIndex = 5,
        },
        ScreenGui
    )


    Corner(
        Main,
        16
    )

    Stroke(
        Main,
        Colors.Border,
        1
    )


    _G.vanz.UI.Main =
        Main


    --==========================================================
    -- MAIN TOP GLOW
    --==========================================================

    local TopGlow = New(
        "Frame",
        {
            Name = "TopGlow",

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

            BorderSizePixel = 0,

            ZIndex = 20,
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


    --==========================================================
    -- HEADER
    --==========================================================

    local Header = New(
        "Frame",
        {
            Name = "Header",

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
                    60
                ),

            BackgroundColor3 =
                Colors.Panel,

            BorderSizePixel = 0,

            ZIndex = 10,
        },
        Main
    )


    --==========================================================
    -- LOGO BACKPLATE
    --==========================================================

    local LogoHolder = New(
        "Frame",
        {
            Name = "LogoHolder",

            Position =
                UDim2.new(
                    0,
                    10,
                    0,
                    9
                ),

            Size =
                UDim2.new(
                    0,
                    40,
                    0,
                    40
                ),

            BackgroundColor3 =
                Colors.Background2,

            BorderSizePixel = 0,

            ZIndex = 12,
        },
        Header
    )


    Corner(
        LogoHolder,
        12
    )

    Stroke(
        LogoHolder,
        Colors.Accent,
        1
    )


    --==========================================================
    -- V LOGO
    --==========================================================

    local Logo = New(
        "TextLabel",
        {
            Name = "VLogo",

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

            BackgroundTransparency = 1,

            Text = "V",

            Font =
                Enum.Font.GothamBlack,

            TextSize = 27,

            TextColor3 =
                Colors.Accent,

            TextStrokeTransparency = 0.65,

            TextStrokeColor3 =
                Colors.Accent2,

            ZIndex = 15,
        },
        LogoHolder
    )


    _G.vanz.UI.Logo =
        Logo


    --==========================================================
    -- TITLE
    --==========================================================

    local Title = New(
        "TextLabel",
        {
            Position =
                UDim2.new(
                    0,
                    58,
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

            BackgroundTransparency = 1,

            Text = "VANZ",

            Font =
                Enum.Font.GothamBlack,

            TextSize = 17,

            TextColor3 =
                Colors.Text,

            TextXAlignment =
                Enum.TextXAlignment.Left,

            ZIndex = 12,
        },
        Header
    )


    local Subtitle = New(
        "TextLabel",
        {
            Position =
                UDim2.new(
                    0,
                    59,
                    0,
                    32
                ),

            Size =
                UDim2.new(
                    0,
                    130,
                    0,
                    14
                ),

            BackgroundTransparency = 1,

            Text = "PREMIUM INTERFACE",

            Font =
                Enum.Font.GothamMedium,

            TextSize = 7,

            TextColor3 =
                Colors.TextSecondary,

            TextXAlignment =
                Enum.TextXAlignment.Left,

            ZIndex = 12,
        },
        Header
    )


    --==========================================================
    -- MINIMIZE BUTTON
    --==========================================================

    local Minimize =
        New(
            "TextButton",
            {
                Name = "Minimize",

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

                AutoButtonColor = false,

                Text = "−",

                Font =
                    Enum.Font.GothamBold,

                TextSize = 18,

                TextColor3 =
                    Colors.TextSecondary,

                ZIndex = 15,
            },
            Header
        )


    Corner(
        Minimize,
        9
    )

    Stroke(
        Minimize,
        Colors.Border,
        1
    )


    _G.vanz.UI.MinimizeButton =
        Minimize


    --==========================================================
    -- HEADER LINE
    --==========================================================

    local HeaderLine = New(
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

            BorderSizePixel = 0,

            ZIndex = 15,
        },
        Header
    )


    --==========================================================
    -- CONTENT
    --==========================================================

    local Content = New(
        "Frame",
        {
            Name = "Content",

            Position =
                UDim2.new(
                    0,
                    0,
                    0,
                    63
                ),

            Size =
                UDim2.new(
                    1,
                    0,
                    1,
                    -63
                ),

            BackgroundTransparency = 1,

            ZIndex = 6,
        },
        Main
    )


    --==========================================================
    -- SIDEBAR
    --==========================================================

    local Sidebar = New(
        "Frame",
        {
            Name = "Sidebar",

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
                    54,
                    1,
                    0
                ),

            BackgroundColor3 =
                Colors.Sidebar,

            BorderSizePixel = 0,

            ZIndex = 7,
        },
        Content
    )


    _G.vanz.UI.Sidebar =
        Sidebar


    --==========================================================
    -- SIDEBAR EDGE
    --==========================================================

    local SidebarEdge = New(
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
                Colors.Border,

            BorderSizePixel = 0,

            ZIndex = 20,
        },
        Sidebar
    )


    --==========================================================
    -- PAGE CONTAINER
    --==========================================================

    local Pages = New(
        "Frame",
        {
            Name = "Pages",

            Position =
                UDim2.new(
                    0,
                    54,
                    0,
                    0
                ),

            Size =
                UDim2.new(
                    1,
                    -54,
                    1,
                    0
                ),

            BackgroundTransparency = 1,

            ClipsDescendants = true,

            ZIndex = 7,
        },
        Content
    )


    _G.vanz.UI.Pages =
        Pages


    --==========================================================
    -- RESPONSIVE SYSTEM
    --==========================================================

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
                    260,
                    0.85,
                    0
                )

        end


        -- Keep default DPI while adapting to extremely
        -- small screens.

        local configured =
            _G.vanz.Config.Scale
            or 0.75


        if viewport.X < 300 then

            configured =
                math.min(
                    configured,
                    0.65
                )

        end


        GlobalScale.Scale =
            configured

    end


    if Camera then

        Camera:GetPropertyChangedSignal(
            "ViewportSize"
        ):Connect(
            UpdateResponsive
        )

    end


    UpdateResponsive()


    --==========================================================
    -- FLOATING V LOGO
    --==========================================================

    local FloatingLogo =
        New(
            "TextButton",
            {
                Name = "FloatingV",

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
                        57,
                        0,
                        57
                    ),

                BackgroundColor3 =
                    Colors.Background2,

                BorderSizePixel = 0,

                AutoButtonColor = false,

                Text = "V",

                Font =
                    Enum.Font.GothamBlack,

                TextSize = 26,

                TextColor3 =
                    Colors.Accent,

                Visible = false,

                Active = true,

                ZIndex = 100,
            },
            ScreenGui
        )


    Corner(
        FloatingLogo,
        19
    )

    Stroke(
        FloatingLogo,
        Colors.Accent,
        2
    )


    local FloatingGradient =
        New(
            "UIGradient",
            {
                Rotation = 45,

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
                            Colors.Accent
                        )
                    })
            },
            FloatingLogo
        )


    _G.vanz.UI.FloatingLogo =
        FloatingLogo

    _G.vanz.UI.FloatingGradient =
        FloatingGradient


    --==========================================================
    -- OPEN / CLOSE FUNCTIONS
    --==========================================================

    local function MinimizeGUI()

        if _G.vanz.Config.Minimized then
            return
        end


        _G.vanz.Config.Minimized =
            true


        if _G.vanz.Config.Animations then

            TweenService:Create(
                Main,
                TweenInfo.new(
                    0.32,
                    Enum.EasingStyle.Quint,
                    Enum.EasingDirection.In
                ),
                {
                    Size =
                        UDim2.new(
                            0,
                            260,
                            0,
                            0
                        ),

                    BackgroundTransparency = 1
                }
            ):Play()

            task.delay(
                0.24,
                function()

                    Main.Visible = false

                    FloatingLogo.Visible = true

                    FloatingLogo.Size =
                        UDim2.new(
                            0,
                            5,
                            0,
                            5
                        )

                    TweenService:Create(
                        FloatingLogo,
                        TweenInfo.new(
                            0.5,
                            Enum.EasingStyle.Back,
                            Enum.EasingDirection.Out
                        ),
                        {
                            Size =
                                UDim2.new(
                                    0,
                                    57,
                                    0,
                                    57
                                )
                        }
                    ):Play()

                end
            )

        else

            Main.Visible = false

            FloatingLogo.Visible = true

        end

    end


    local function RestoreGUI()

        if not _G.vanz.Config.Minimized then
            return
        end


        _G.vanz.Config.Minimized =
            false


        FloatingLogo.Visible = false

        Main.Visible = true

        Main.Size =
            UDim2.new(
                0,
                260,
                0,
                0
            )

        Main.BackgroundTransparency = 1


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
                            260,
                            0.85,
                            0
                        ),

                    BackgroundTransparency = 0
                }
            ):Play()

        else

            Main.Size =
                UDim2.new(
                    0,
                    260,
                    0.85,
                    0
                )

            Main.BackgroundTransparency = 0

        end

    end


    Minimize.MouseButton1Click:Connect(
        MinimizeGUI
    )


    --==========================================================
    -- DRAG FLOATING LOGO
    --==========================================================

    local dragging = false
    local dragStart = nil
    local startPosition = nil
    local moved = false


    FloatingLogo.InputBegan:Connect(
        function(input)

            if
                input.UserInputType
                    == Enum.UserInputType.MouseButton1
                or
                input.UserInputType
                    == Enum.UserInputType.Touch
            then

                dragging = true
                moved = false

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

                            dragging = false

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


    --==========================================================
    -- INITIAL OPEN ANIMATION
    --==========================================================

    Main.Size =
        UDim2.new(
            0,
            240,
            0,
            0
        )

    Main.BackgroundTransparency = 1


    task.defer(
        function()

            TweenService:Create(
                Main,
                TweenInfo.new(
                    0.65,
                    Enum.EasingStyle.Back,
                    Enum.EasingDirection.Out
                ),
                {
                    Size =
                        UDim2.new(
                            0,
                            260,
                            0.85,
                            0
                        ),

                    BackgroundTransparency = 0
                }
            ):Play()

        end
    )

end)


--==============================================================
-- 2_COMPONENT_LIBRARY
--==============================================================

VanzBlock("2_COMPONENT_LIBRARY", function()

    local UI =
        _G.vanz.UI

    local Colors =
        _G.vanz.Colors


    --==========================================================
    -- HELPERS
    --==========================================================

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

            object[property] = value

        end

        object.Parent = parent

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


    --==========================================================
    -- TOGGLE
    --==========================================================

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
                            58
                        ),

                    BackgroundColor3 =
                        Colors.Panel2,

                    BorderSizePixel = 0,

                    ClipsDescendants = true,
                },
                parent
            )


        Corner(
            holder,
            10
        )


        local holderStroke =
            Stroke(
                holder,
                Colors.Border,
                1
            )


        --======================================================
        -- LEFT ACCENT
        --======================================================

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
                            42
                        ),

                    BackgroundColor3 =
                        Colors.Accent,

                    BorderSizePixel = 0,

                    BackgroundTransparency = 0.6,
                },
                holder
            )


        Corner(
            accent,
            2
        )


        --======================================================
        -- TITLE
        --======================================================

        local label =
            New(
                "TextLabel",
                {
                    Position =
                        UDim2.new(
                            0,
                            12,
                            0,
                            8
                        ),

                    Size =
                        UDim2.new(
                            1,
                            -66,
                            0,
                            18
                        ),

                    BackgroundTransparency = 1,

                    Text =
                        title or "Feature",

                    Font =
                        Enum.Font.GothamSemibold,

                    TextSize = 9,

                    TextColor3 =
                        Colors.Text,

                    TextXAlignment =
                        Enum.TextXAlignment.Left,

                    TextTruncate =
                        Enum.TextTruncate.AtEnd,
                },
                holder
            )


        --======================================================
        -- DESCRIPTION
        --======================================================

        local desc =
            New(
                "TextLabel",
                {
                    Position =
                        UDim2.new(
                            0,
                            12,
                            0,
                            28
                        ),

                    Size =
                        UDim2.new(
                            1,
                            -68,
                            0,
                            17
                        ),

                    BackgroundTransparency = 1,

                    Text =
                        description
                        or
                        "Feature description",

                    Font =
                        Enum.Font.Gotham,

                    TextSize = 7,

                    TextColor3 =
                        Colors.TextSecondary,

                    TextXAlignment =
                        Enum.TextXAlignment.Left,

                    TextTruncate =
                        Enum.TextTruncate.AtEnd,
                },
                holder
            )


        --======================================================
        -- TOGGLE BUTTON
        --======================================================

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
                            35,
                            0,
                            20
                        ),

                    BackgroundColor3 =
                        Colors.ToggleOff,

                    AutoButtonColor = false,

                    Text = "",
                },
                holder
            )


        Corner(
            toggle,
            20
        )


        --======================================================
        -- TOGGLE KNOB
        --======================================================

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
                            16,
                            0,
                            16
                        ),

                    BackgroundColor3 =
                        Color3.fromRGB(
                            225,
                            227,
                            235
                        ),

                    BorderSizePixel = 0,
                },
                toggle
            )


        Corner(
            knob,
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
                        -18,
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
                    0.3,
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
                        or 0.6
                }
            ):Play()


            if fireCallback
                ~= false
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


        Set(
            state,
            true
        )


        local object = {

            Frame = holder,

            Button = toggle,

            Set = function(
                value
            )

                Set(
                    value,
                    true
                )

            end,

            Get = function()

                return state

            end,

        }


        return object

    end


    --==========================================================
    -- BUTTON
    --==========================================================

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
                            39
                        ),

                    BackgroundColor3 =
                        Colors.Panel2,

                    BorderSizePixel = 0,

                    AutoButtonColor = false,

                    Text =
                        title or "Button",

                    Font =
                        Enum.Font.GothamSemibold,

                    TextSize = 9,

                    TextColor3 =
                        Colors.Text,
                },
                parent
            )


        Corner(
            button,
            9
        )


        Stroke(
            button,
            Colors.Border,
            1
        )


        button.MouseEnter:Connect(
            function()

                TweenService:Create(
                    button,
                    TweenInfo.new(
                        0.18
                    ),
                    {
                        BackgroundColor3 =
                            Colors.Panel3
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
                                37
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
                        0.12
                    ),
                    {
                        Size =
                            UDim2.new(
                                1,
                                -14,
                                0,
                                39
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


    --==========================================================
    -- SECTION
    --==========================================================

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

                    BackgroundTransparency = 1,
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

                    BorderSizePixel = 0,
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
                            4,
                            0,
                            0
                        ),

                    Size =
                        UDim2.new(
                            0,
                            120,
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

                    TextSize = 7,

                    TextColor3 =
                        Colors.TextSecondary,

                    TextXAlignment =
                        Enum.TextXAlignment.Left,
                },
                holder
            )


        return holder

    end


    --==========================================================
    -- INFO CARD
    --==========================================================

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
                            68
                        ),

                    BackgroundColor3 =
                        Colors.Panel,

                    BorderSizePixel = 0,
                },
                parent
            )


        Corner(
            card,
            10
        )


        Stroke(
            card,
            Colors.Border,
            1
        )


        local titleLabel =
            New(
                "TextLabel",
                {
                    Position =
                        UDim2.new(
                            0,
                            12,
                            0,
                            9
                        ),

                    Size =
                        UDim2.new(
                            1,
                            -24,
                            0,
                            18
                        ),

                    BackgroundTransparency = 1,

                    Text =
                        title
                        or
                        "VANZ",

                    Font =
                        Enum.Font.GothamBold,

                    TextSize = 10,

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
                            12,
                            0,
                            30
                        ),

                    Size =
                        UDim2.new(
                            1,
                            -24,
                            0,
                            27
                        ),

                    BackgroundTransparency = 1,

                    Text =
                        description
                        or
                        "",

                    Font =
                        Enum.Font.Gotham,

                    TextSize = 7,

                    TextColor3 =
                        Colors.TextSecondary,

                    TextWrapped = true,

                    TextXAlignment =
                        Enum.TextXAlignment.Left,

                    TextYAlignment =
                        Enum.TextYAlignment.Top,
                },
                card
            )


        return card

    end


end)


--==============================================================
-- 3_TAB_SYSTEM
--==============================================================

VanzBlock("3_TAB_SYSTEM", function()

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

            object[property] = value

        end

        object.Parent = parent

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

        corner.Parent = object

    end


    --==========================================================
    -- SIDEBAR LAYOUT
    --==========================================================

    local layout =
        New(
            "UIListLayout",
            {
                Padding =
                    UDim.new(
                        0,
                        5
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


    layout.Padding =
        UDim.new(
            0,
            5
        )


    local topPadding =
        New(
            "UIPadding",
            {
                PaddingTop =
                    UDim.new(
                        0,
                        10
                    ),
            },
            UI.Sidebar
        )


    local ActiveTab = nil


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
                            43,
                            0,
                            41
                        ),

                    BackgroundColor3 =
                        Colors.Panel2,

                    BackgroundTransparency = 1,

                    BorderSizePixel = 0,

                    AutoButtonColor = false,

                    Text =
                        icon
                        or
                        "•",

                    Font =
                        Enum.Font.GothamBold,

                    TextSize = 12,

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
            10
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

                    BorderSizePixel = 0,

                    BackgroundTransparency = 1,
                },
                button
            )


        Corner(
            indicator,
            2
        )


        local page =
            New(
                "ScrollingFrame",
                {
                    Name =
                        name
                        .. "_Page",

                    Position =
                        UDim2.new(
                            0,
                            0,
                            0,
                            0
                        ),

                    Size =
                        UDim2.fromScale(
                            1,
                            1
                        ),

                    BackgroundTransparency = 1,

                    BorderSizePixel = 0,

                    ScrollBarThickness = 2,

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

                    Visible = false,

                    ZIndex = 8,
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
                            15
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

            Name = name,

            Icon = icon,

            Button = button,

            Page = page,

            Indicator = indicator,

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
                        BackgroundTransparency = 1,

                        TextColor3 =
                            Colors.TextMuted
                    }
                ):Play()


                TweenService:Create(
                    other.Indicator,
                    TweenInfo.new(
                        0.18
                    ),
                    {
                        BackgroundTransparency = 1
                    }
                ):Play()

            end


            ActiveTab =
                tab


            page.Visible = true

            page.Position =
                UDim2.new(
                    0,
                    10,
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
                    BackgroundTransparency = 0,

                    TextColor3 =
                        Colors.Text
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
                    BackgroundTransparency = 0
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
                            )
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


        if #_G.vanz.Tabs == 1 then
            task.defer(
                Activate
            )
        end


        return tab

    end

end)


--==============================================================
-- 4_HOME
--==============================================================

VanzBlock("4_HOME", function()

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
        "Premium modular GUI base. Semua feature slot sengaja dibuat kosong agar dapat digunakan sebagai fondasi."
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
        "Aktifkan perubahan warna otomatis.",
        true,
        function(value)

            _G.vanz.Config.DynamicColors =
                value

        end
    )


    _G.vanz.CreateToggle(
        page,
        "Glow Effects",
        "Aktifkan efek glow pada interface.",
        true,
        function(value)

            _G.vanz.Config.Glow =
                value

        end
    )

end)


--==============================================================
-- 5_PLAYER
--==============================================================

VanzBlock("5_PLAYER", function()

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

            "Player Feature "
                .. string.format(
                    "%02d",
                    index
                ),

            "Empty configurable feature slot.",

            false,

            function(value)

                _G.vanz.State[
                    "PlayerFeature"
                    .. index
                ] = value

            end
        )

    end

end)


--==============================================================
-- 6_VISUAL
--==============================================================

VanzBlock("6_VISUAL", function()

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

            "Visual Feature "
                .. string.format(
                    "%02d",
                    index
                ),

            "Empty configurable visual slot.",

            false,

            function(value)

                _G.vanz.State[
                    "VisualFeature"
                    .. index
                ] = value

            end
        )

    end

end)


--==============================================================
-- 7_WORLD
--==============================================================

VanzBlock("7_WORLD", function()

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

            "World Feature "
                .. string.format(
                    "%02d",
                    index
                ),

            "Empty configurable world slot.",

            false,

            function(value)

                _G.vanz.State[
                    "WorldFeature"
                    .. index
                ] = value

            end
        )

    end

end)


--==============================================================
-- 8_MISC
--==============================================================

VanzBlock("8_MISC", function()

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

            "Misc Feature "
                .. string.format(
                    "%02d",
                    index
                ),

            "Empty configurable miscellaneous slot.",

            false,

            function(value)

                _G.vanz.State[
                    "MiscFeature"
                    .. index
                ] = value

            end
        )

    end

end)


--==============================================================
-- 9_EXTRA
--==============================================================

VanzBlock("9_EXTRA", function()

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

            "Extra Feature "
                .. string.format(
                    "%02d",
                    index
                ),

            "Empty configurable extra slot.",

            false,

            function(value)

                _G.vanz.State[
                    "ExtraFeature"
                    .. index
                ] = value

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

end)


--==============================================================
-- 10_SETTINGS
--==============================================================

VanzBlock("10_SETTINGS", function()

    local tab =
        _G.vanz.CreateTab(
            "Settings",
            "⚙"
        )

    local page =
        tab.Page


    --==========================================================
    -- GENERAL
    --==========================================================

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

        end
    )


    _G.vanz.CreateToggle(
        page,
        "Dynamic Accent",
        "Animated colors throughout the interface.",
        true,
        function(value)

            _G.vanz.Config.DynamicColors =
                value

        end
    )


    --==========================================================
    -- DPI
    --==========================================================

    _G.vanz.CreateSection(
        page,
        "DPI / GUI SCALE"
    )


    local dpiHolder =
        Instance.new(
            "Frame"
        )

    dpiHolder.Size =
        UDim2.new(
            1,
            -14,
            0,
            118
        )

    dpiHolder.BackgroundColor3 =
        _G.vanz.Colors.Panel2

    dpiHolder.BorderSizePixel = 0

    dpiHolder.Parent = page


    local dpiCorner =
        Instance.new(
            "UICorner"
        )

    dpiCorner.CornerRadius =
        UDim.new(
            0,
            10
        )

    dpiCorner.Parent =
        dpiHolder


    local dpiStroke =
        Instance.new(
            "UIStroke"
        )

    dpiStroke.Color =
        _G.vanz.Colors.Border

    dpiStroke.Thickness = 1

    dpiStroke.Parent =
        dpiHolder


    local dpiTitle =
        Instance.new(
            "TextLabel"
        )

    dpiTitle.Position =
        UDim2.new(
            0,
            11,
            0,
            8
        )

    dpiTitle.Size =
        UDim2.new(
            1,
            -22,
            0,
            18
        )

    dpiTitle.BackgroundTransparency = 1

    dpiTitle.Text =
        "DPI SCALE"

    dpiTitle.Font =
        Enum.Font.GothamBold

    dpiTitle.TextSize = 9

    dpiTitle.TextColor3 =
        _G.vanz.Colors.Text

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
            11,
            0,
            27
        )

    dpiDescription.Size =
        UDim2.new(
            1,
            -22,
            0,
            14
        )

    dpiDescription.BackgroundTransparency = 1

    dpiDescription.Text =
        "Pilih ukuran interface secara langsung."

    dpiDescription.Font =
        Enum.Font.Gotham

    dpiDescription.TextSize = 7

    dpiDescription.TextColor3 =
        _G.vanz.Colors.TextSecondary

    dpiDescription.TextXAlignment =
        Enum.TextXAlignment.Left

    dpiDescription.Parent =
        dpiHolder


    --==========================================================
    -- DPI VALUES
    --==========================================================

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


    local dpiLayout =
        Instance.new(
            "UIGridLayout"
        )

    dpiLayout.CellSize =
        UDim2.new(
            0,
            31,
            0,
            27
        )

    dpiLayout.CellPadding =
        UDim2.new(
            0,
            5,
            0,
            5
        )

    dpiLayout.StartCorner =
        Enum.StartCorner.TopLeft

    dpiLayout.FillDirection =
        Enum.FillDirection.Horizontal

    dpiLayout.HorizontalAlignment =
        Enum.HorizontalAlignment.Left

    dpiLayout.SortOrder =
        Enum.SortOrder.LayoutOrder

    dpiLayout.Parent =
        dpiHolder


    local dpiPadding =
        Instance.new(
            "UIPadding"
        )

    dpiPadding.PaddingTop =
        UDim.new(
            0,
            49
        )

    dpiPadding.PaddingLeft =
        UDim.new(
            0,
            10
        )

    dpiPadding.Parent =
        dpiHolder


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
                    Scale = value
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
                        0.15
                    ),
                    {
                        BackgroundColor3 =
                            _G.vanz.Colors.Accent,

                        TextColor3 =
                            Color3.new(
                                1,
                                1,
                                1
                            )
                    }
                ):Play()

            else

                TweenService:Create(
                    button,
                    TweenInfo.new(
                        0.15
                    ),
                    {
                        BackgroundColor3 =
                            _G.vanz.Colors.Panel3,

                        TextColor3 =
                            _G.vanz.Colors.TextSecondary
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
                31,
                0,
                27
            )

        button.BackgroundColor3 =
            _G.vanz.Colors.Panel3

        button.BorderSizePixel = 0

        button.AutoButtonColor = false

        button.Text =
            DPILabels[index]

        button.Font =
            Enum.Font.GothamBold

        button.TextSize = 7

        button.TextColor3 =
            _G.vanz.Colors.TextSecondary

        button.LayoutOrder =
            index

        button.Parent =
            dpiHolder


        local corner =
            Instance.new(
                "UICorner"
            )

        corner.CornerRadius =
            UDim.new(
                0,
                7
            )

        corner.Parent =
            button


        dpiButtons[index] =
            button


        button.MouseButton1Click:Connect(
            function()

                ApplyDPI(
                    value
                )

            end
        )

    end


    -- DEFAULT = 75%
    ApplyDPI(
        0.75
    )


    --==========================================================
    -- SYSTEM
    --==========================================================

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

end)


--==============================================================
-- 11_ANIMATION_ENGINE
--==============================================================

VanzBlock("11_ANIMATION_ENGINE", function()

    local UI =
        _G.vanz.UI

    local Colors =
        _G.vanz.Colors


    --==========================================================
    -- ANIMATED COLOR ENGINE
    --==========================================================

    local hue =
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


                if
                    not _G.vanz.Config.DynamicColors
                then

                    return

                end


                hue =
                    (hue
                        + deltaTime * 0.08)
                    % 1


                local colorA =
                    Color3.fromHSV(
                        hue,
                        0.75,
                        1
                    )


                local colorB =
                    Color3.fromHSV(
                        (hue + 0.13)
                            % 1,
                        0.75,
                        1
                    )


                local colorC =
                    Color3.fromHSV(
                        (hue + 0.26)
                            % 1,
                        0.75,
                        1
                    )


                Colors.Accent =
                    colorA

                Colors.Accent2 =
                    colorB


                --==================================================
                -- MAIN LOGO
                --==================================================

                if UI.Logo then

                    UI.Logo.TextColor3 =
                        colorA

                    UI.Logo.TextStrokeColor3 =
                        colorB

                end


                --==================================================
                -- FLOATING LOGO
                --==================================================

                if UI.FloatingLogo then

                    UI.FloatingLogo.TextColor3 =
                        colorA

                    local stroke =
                        UI.FloatingLogo:FindFirstChildOfClass(
                            "UIStroke"
                        )

                    if stroke then

                        stroke.Color =
                            colorB

                    end

                end


                --==================================================
                -- TOP GRADIENT
                --==================================================

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
                            )
                        })

                end


                --==================================================
                -- FLOATING GRADIENT
                --==================================================

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
                            )
                        })

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
                                Rotation = 5
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
                                Rotation = -5
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

end)


--==============================================================
-- 12_EXTRA_VISUALS
--==============================================================

VanzBlock("12_EXTRA_VISUALS", function()

    local UI =
        _G.vanz.UI


    --==========================================================
    -- LOGO HOVER
    --==========================================================

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
                        Rotation = -8
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
                        Rotation = 0
                    }
                ):Play()

            end
        )

    end


    --==========================================================
    -- MINIMIZE HOVER
    --==========================================================

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
                            UI.Colors
                            and
                            UI.Colors.Panel3
                            or
                            Color3.fromRGB(
                                30,
                                32,
                                45
                            ),

                        TextColor3 =
                            Color3.new(
                                1,
                                1,
                                1
                            )
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
                            _G.vanz.Colors.TextSecondary
                    }
                ):Play()

            end
        )

    end

end)


--==============================================================
-- 13_GLOBAL_API
--==============================================================

VanzBlock("13_GLOBAL_API", function()

    --==========================================================
    -- GUI CONTROL API
    --==========================================================

    _G.vanz.Open =
        function()

            if
                _G.vanz.UI.Restore
            then

                _G.vanz.UI.Restore()

            end

        end


    _G.vanz.Close =
        function()

            if
                _G.vanz.UI.Minimize
            then

                _G.vanz.UI.Minimize()

            end

        end


    --==========================================================
    -- SCALE API
    --==========================================================

    _G.vanz.SetScale =
        function(value)

            local allowed = {
                [0.50] = true,
                [0.75] = true,
                [1.00] = true,
                [1.50] = true,
                [1.75] = true,
                [2.00] = true,
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


    --==========================================================
    -- STATE API
    --==========================================================

    _G.vanz.GetState =
        function(name)

            return _G.vanz.State[name]

        end


    _G.vanz.SetState =
        function(name, value)

            _G.vanz.State[name] =
                value

        end

end)


--==============================================================
-- 14_FINALIZE
--==============================================================

VanzBlock("14_FINALIZE", function()

    _G.vanz.State.GUIReady =
        true

    _G.vanz.State.Version =
        _G.vanz.Config.Version


    print(
        "================================================"
    )

    print(
        "[VANZ] PREMIUM GUI INITIALIZED"
    )

    print(
        "[VANZ] Version: "
        .. tostring(
            _G.vanz.Config.Version
        )
    )

    print(
        "[VANZ] Tabs: "
        .. tostring(
            #_G.vanz.Tabs
        )
    )

    print(
        "[VANZ] Default DPI: 75%"
    )

    print(
        "[VANZ] DPI: 50 / 75 / 100 / 150 / 175 / 200"
    )

    print(
        "[VANZ] GUI ONLY / BASE MODE"
    )

    print(
        "================================================"
    )

end)