--[[
╔══════════════════════════════════════════════════════════════════════╗
║                                                                      ║
║              VANZ NEXUS // ROBOTIC ANIME INTERFACE                 ║
║                     FULL REBUILD // V10                            ║
║                                                                      ║
║  ARCHITECTURE                                                        ║
║  ├─ Mobile-first responsive window                                  ║
║  ├─ Exclusive header control zone                                   ║
║  ├─ Draggable main window                                           ║
║  ├─ Draggable minimized NEXUS core                                  ║
║  ├─ Touch + mouse input                                             ║
║  ├─ Large touch targets                                             ║
║  ├─ Bottom navigation on mobile                                     ║
║  ├─ Robotic / Anime holographic visual system                       ║
║  ├─ Animated core                                                   ║
║  ├─ Scanlines                                                       ║
║  ├─ Circuit decorations                                             ║
║  ├─ Radar                                                            ║
║  ├─ Telemetry                                                       ║
║  ├─ Particle ambience                                               ║
║  ├─ Hue cycling                                                      ║
║  └─ Clean public API                                                ║
║                                                                      ║
║  NOTE                                                                 ║
║  Roblox system/CoreGui elements can still supersede player GUI.      ║
║  This script maximizes its own DisplayOrder/ZIndex safely.           ║
║                                                                      ║
╚══════════════════════════════════════════════════════════════════════╝
]]

----------------------------------------------------------------------
-- SERVICES
----------------------------------------------------------------------

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Stats = game:GetService("Stats")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

----------------------------------------------------------------------
-- CONFIG
----------------------------------------------------------------------

local CONFIG = {
	Name = "VANZ_NEXUS_GUI",

	DisplayOrder = 999999999,

	DesktopWidth = 1020,
	DesktopHeight = 650,

	MobileMargin = 7,

	HeaderDesktop = 92,
	HeaderMobile = 78,

	ControlZoneDesktop = 120,
	ControlZoneMobile = 112,

	SidebarDesktop = 205,
	BottomNavMobile = 72,

	AnimationSpeed = 1,

	ParticleCount = 18,

	DefaultScale = 1,

	DestroyOldVersions = true,
}

----------------------------------------------------------------------
-- CLEANUP OLD INSTANCES
----------------------------------------------------------------------

if CONFIG.DestroyOldVersions then
	for _, name in ipairs({
		"VANZ_ROBOTIC_GUI",
		"VANZ_PREMIUM_GUI",
		"VANZ_SOFT_ROBOTIC_GUI",
		"VANZ_NEXUS_GUI",
		"VANZ_NEXUS_INTERFACE",
	}) do
		local old = PlayerGui:FindFirstChild(name)

		if old then
			old:Destroy()
		end
	end
end

----------------------------------------------------------------------
-- STATE
----------------------------------------------------------------------

local State = {
	Destroyed = false,
	Minimized = false,

	Mobile = false,
	Tiny = false,

	CurrentPage = "HOME",

	Animations = true,
	Neon = true,
	InteractionFX = true,
	Particles = true,
	Scanlines = true,
	HueCycle = true,

	DraggingWindow = false,
	DraggingCore = false,

	WindowDragged = false,

	WindowOffset = Vector2.zero,

	DragStart = Vector2.zero,
	DragOrigin = Vector2.zero,

	CoreDragStart = Vector2.zero,
	CoreOrigin = Vector2.zero,

	OpenedAt = os.clock(),

	Hue = 0,
	Pulse = 0,

	CurrentScale = CONFIG.DefaultScale,

	CoreIntensity = 1,

	Connections = {},
	Tweens = {},
	Particles = {},
}

----------------------------------------------------------------------
-- CONNECTION MANAGEMENT
----------------------------------------------------------------------

local function Connect(signal, callback)
	local connection = signal:Connect(callback)

	table.insert(State.Connections, connection)

	return connection
end

local function DisconnectAll()
	for _, connection in ipairs(State.Connections) do
		pcall(function()
			connection:Disconnect()
		end)
	end

	table.clear(State.Connections)
end

----------------------------------------------------------------------
-- UTILITY
----------------------------------------------------------------------

local function Clamp(value, minimum, maximum)
	return math.clamp(value, minimum, maximum)
end

local function Lerp(a, b, alpha)
	return a + (b - a) * alpha
end

local function Tween(object, duration, properties, style, direction)
	if not object or not object.Parent then
		return nil
	end

	local info = TweenInfo.new(
		duration / math.max(CONFIG.AnimationSpeed, 0.05),
		style or Enum.EasingStyle.Quint,
		direction or Enum.EasingDirection.Out
	)

	local tween = TweenService:Create(object, info, properties)

	table.insert(State.Tweens, tween)

	tween:Play()

	return tween
end

local function ColorFromHSV(h, s, v)
	return Color3.fromHSV(
		h % 1,
		Clamp(s, 0, 1),
		Clamp(v, 0, 1)
	)
end

----------------------------------------------------------------------
-- COLOR SYSTEM
----------------------------------------------------------------------

local COLORS = {
	Background = Color3.fromRGB(5, 7, 16),
	Panel = Color3.fromRGB(9, 12, 25),
	Panel2 = Color3.fromRGB(12, 16, 32),

	Cyan = Color3.fromRGB(67, 232, 255),
	Blue = Color3.fromRGB(81, 125, 255),
	Violet = Color3.fromRGB(157, 93, 255),
	Pink = Color3.fromRGB(255, 82, 183),

	White = Color3.fromRGB(239, 248, 255),
	Muted = Color3.fromRGB(133, 151, 177),

	Good = Color3.fromRGB(83, 255, 174),
	Warning = Color3.fromRGB(255, 211, 88),
	Danger = Color3.fromRGB(255, 82, 112),

	Line = Color3.fromRGB(35, 55, 88),
	LineBright = Color3.fromRGB(66, 115, 155),
}

----------------------------------------------------------------------
-- FACTORY
----------------------------------------------------------------------

local function New(className, properties, parent)
	local object = Instance.new(className)

	for property, value in pairs(properties or {}) do
		pcall(function()
			object[property] = value
		end)
	end

	if parent then
		object.Parent = parent
	end

	return object
end

local function Corner(parent, radius)
	return New("UICorner", {
		CornerRadius = UDim.new(0, radius or 10),
	}, parent)
end

local function Stroke(parent, color, thickness, transparency)
	return New("UIStroke", {
		Color = color,
		Thickness = thickness or 1,
		Transparency = transparency or 0,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
	}, parent)
end

local function Gradient(parent, colors, rotation)
	local gradient = New("UIGradient", {
		Rotation = rotation or 0,
		Color = ColorSequence.new(colors),
	}, parent)

	return gradient
end

local function Padding(parent, left, right, top, bottom)
	return New("UIPadding", {
		PaddingLeft = UDim.new(0, left or 0),
		PaddingRight = UDim.new(0, right or 0),
		PaddingTop = UDim.new(0, top or 0),
		PaddingBottom = UDim.new(0, bottom or 0),
	}, parent)
end

local function Text(parent, properties)
	properties = properties or {}

	properties.BackgroundTransparency = 1
	properties.Font = properties.Font or Enum.Font.GothamMedium
	properties.TextColor3 = properties.TextColor3 or COLORS.White
	properties.TextSize = properties.TextSize or 16
	properties.TextXAlignment = properties.TextXAlignment or Enum.TextXAlignment.Left
	properties.TextYAlignment = properties.TextYAlignment or Enum.TextYAlignment.Center

	return New("TextLabel", properties, parent)
end

local function Button(parent, properties)
	properties = properties or {}

	properties.AutoButtonColor = false
	properties.BackgroundColor3 = properties.BackgroundColor3 or COLORS.Panel2
	properties.BorderSizePixel = 0
	properties.Font = properties.Font or Enum.Font.GothamBold
	properties.TextColor3 = properties.TextColor3 or COLORS.White
	properties.TextSize = properties.TextSize or 16

	local button = New("TextButton", properties, parent)

	Corner(button, properties.CornerRadius or 10)

	return button
end

----------------------------------------------------------------------
-- SCREEN GUI
----------------------------------------------------------------------

local ScreenGui = New("ScreenGui", {
	Name = CONFIG.Name,

	DisplayOrder = CONFIG.DisplayOrder,

	IgnoreGuiInset = true,
	ResetOnSpawn = false,

	ZIndexBehavior = Enum.ZIndexBehavior.Global,

	Enabled = true,
}, PlayerGui)

pcall(function()
	ScreenGui.ScreenInsets = Enum.ScreenInsets.None
end)

pcall(function()
	ScreenGui.OnTopOfCoreBlur = true
end)

----------------------------------------------------------------------
-- ROOT
----------------------------------------------------------------------

local Root = New("Frame", {
	Name = "Root",

	BackgroundTransparency = 1,

	Size = UDim2.fromScale(1, 1),

	Position = UDim2.fromScale(0.5, 0.5),
	AnchorPoint = Vector2.new(0.5, 0.5),

	ZIndex = 1,
}, ScreenGui)

----------------------------------------------------------------------
-- MAIN WINDOW
----------------------------------------------------------------------

local MainHolder = New("Frame", {
	Name = "MainHolder",

	BackgroundColor3 = COLORS.Background,

	Position = UDim2.fromScale(0.5, 0.5),
	AnchorPoint = Vector2.new(0.5, 0.5),

	Size = UDim2.fromOffset(
		CONFIG.DesktopWidth,
		CONFIG.DesktopHeight
	),

	BorderSizePixel = 0,

	ClipsDescendants = true,

	ZIndex = 20,
}, Root)

Corner(MainHolder, 18)

local MainStroke = Stroke(
	MainHolder,
	COLORS.LineBright,
	1,
	0.15
)

local MainGradient = Gradient(
	MainHolder,
	{
		ColorSequenceKeypoint.new(0, Color3.fromRGB(8, 12, 27)),
		ColorSequenceKeypoint.new(0.45, Color3.fromRGB(5, 9, 20)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(12, 7, 25)),
	},
	135
)

----------------------------------------------------------------------
-- OUTER GLOW
----------------------------------------------------------------------

local OuterGlow = New("Frame", {
	Name = "OuterGlow",

	BackgroundColor3 = COLORS.Cyan,
	BackgroundTransparency = 0.96,

	Position = UDim2.fromScale(0.5, 0.5),
	AnchorPoint = Vector2.new(0.5, 0.5),

	Size = UDim2.new(1, 18, 1, 18),

	BorderSizePixel = 0,

	ZIndex = 10,

	Active = false,
}, Root)

Corner(OuterGlow, 24)

----------------------------------------------------------------------
-- HEADER
----------------------------------------------------------------------

local Header = New("Frame", {
	Name = "Header",

	BackgroundColor3 = Color3.fromRGB(7, 11, 24),

	Size = UDim2.new(1, 0, 0, CONFIG.HeaderDesktop),

	BorderSizePixel = 0,

	ZIndex = 50,
}, MainHolder)

local HeaderGradient = Gradient(
	Header,
	{
		ColorSequenceKeypoint.new(0, Color3.fromRGB(11, 17, 36)),
		ColorSequenceKeypoint.new(0.5, Color3.fromRGB(7, 11, 25)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(18, 8, 32)),
	},
	0
)

----------------------------------------------------------------------
-- HEADER BOTTOM LINE
----------------------------------------------------------------------

local HeaderLine = New("Frame", {
	Name = "HeaderLine",

	BackgroundColor3 = COLORS.Cyan,

	BackgroundTransparency = 0.25,

	Position = UDim2.new(0, 0, 1, -2),

	Size = UDim2.new(1, 0, 0, 2),

	BorderSizePixel = 0,

	ZIndex = 70,
}, Header)

----------------------------------------------------------------------
-- HEADER LEFT ZONE
----------------------------------------------------------------------

local HeaderLogoZone = New("Frame", {
	Name = "HeaderLogoZone",

	BackgroundTransparency = 1,

	Position = UDim2.fromOffset(12, 0),

	Size = UDim2.fromOffset(70, CONFIG.HeaderDesktop),

	ZIndex = 60,
}, Header)

----------------------------------------------------------------------
-- ROBOTIC LOGO
----------------------------------------------------------------------

local Logo = New("Frame", {
	Name = "Logo",

	BackgroundColor3 = Color3.fromRGB(8, 16, 31),

	Position = UDim2.fromScale(0.5, 0.5),

	AnchorPoint = Vector2.new(0.5, 0.5),

	Size = UDim2.fromOffset(58, 58),

	BorderSizePixel = 0,

	ZIndex = 65,
}, HeaderLogoZone)

Corner(Logo, 16)

Stroke(Logo, COLORS.Cyan, 1.5, 0.1)

local LogoGradient = Gradient(
	Logo,
	{
		ColorSequenceKeypoint.new(0, Color3.fromRGB(15, 31, 58)),
		ColorSequenceKeypoint.new(0.5, Color3.fromRGB(9, 18, 38)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(30, 10, 49)),
	},
	135
)

----------------------------------------------------------------------
-- LOGO OUTER RINGS
----------------------------------------------------------------------

local LogoRingOuter = New("Frame", {
	BackgroundTransparency = 1,

	Position = UDim2.fromScale(0.5, 0.5),
	AnchorPoint = Vector2.new(0.5, 0.5),

	Size = UDim2.fromOffset(48, 48),

	ZIndex = 66,
}, Logo)

Corner(LogoRingOuter, 99)
Stroke(LogoRingOuter, COLORS.Cyan, 1, 0.35)

local LogoRingInner = New("Frame", {
	BackgroundTransparency = 1,

	Position = UDim2.fromScale(0.5, 0.5),
	AnchorPoint = Vector2.new(0.5, 0.5),

	Size = UDim2.fromOffset(36, 36),

	ZIndex = 67,
}, Logo)

Corner(LogoRingInner, 99)
Stroke(LogoRingInner, COLORS.Violet, 1.5, 0.2)

----------------------------------------------------------------------
-- LOGO CORE
----------------------------------------------------------------------

local LogoCore = New("Frame", {
	BackgroundColor3 = COLORS.Cyan,

	BackgroundTransparency = 0.08,

	Position = UDim2.fromScale(0.5, 0.5),
	AnchorPoint = Vector2.new(0.5, 0.5),

	Size = UDim2.fromOffset(18, 18),

	BorderSizePixel = 0,

	ZIndex = 69,
}, Logo)

Corner(LogoCore, 7)

local LogoCoreGradient = Gradient(
	LogoCore,
	{
		ColorSequenceKeypoint.new(0, COLORS.Cyan),
		ColorSequenceKeypoint.new(0.5, COLORS.Blue),
		ColorSequenceKeypoint.new(1, COLORS.Pink),
	},
	45
)

----------------------------------------------------------------------
-- ANIME EYES
----------------------------------------------------------------------

local EyeLeft = New("Frame", {
	BackgroundColor3 = COLORS.White,

	Position = UDim2.new(0.5, -13, 0.5, -3),

	AnchorPoint = Vector2.new(0.5, 0.5),

	Size = UDim2.fromOffset(6, 3),

	BorderSizePixel = 0,

	Rotation = -12,

	ZIndex = 71,
}, Logo)

Corner(EyeLeft, 4)

local EyeRight = New("Frame", {
	BackgroundColor3 = COLORS.White,

	Position = UDim2.new(0.5, 13, 0.5, -3),

	AnchorPoint = Vector2.new(0.5, 0.5),

	Size = UDim2.fromOffset(6, 3),

	BorderSizePixel = 0,

	Rotation = 12,

	ZIndex = 71,
}, Logo)

Corner(EyeRight, 4)

----------------------------------------------------------------------
-- HEADER TITLE ZONE
-- IMPORTANT:
-- THIS ZONE NEVER ENTERS THE CONTROL ZONE.
----------------------------------------------------------------------

local HeaderTitleZone = New("Frame", {
	Name = "HeaderTitleZone",

	BackgroundTransparency = 1,

	Position = UDim2.fromOffset(88, 0),

	Size = UDim2.new(
		1,
		-(88 + CONFIG.ControlZoneDesktop + 10),
		1,
		0
	),

	ZIndex = 55,

	ClipsDescendants = true,
}, Header)

local Title = Text(HeaderTitleZone, {
	Name = "Title",

	Text = "VANZ NEXUS",

	Position = UDim2.fromOffset(2, 10),

	Size = UDim2.new(1, -4, 0, 30),

	Font = Enum.Font.GothamBlack,

	TextSize = 26,

	TextColor3 = COLORS.White,

	TextTruncate = Enum.TextTruncate.AtEnd,

	ZIndex = 57,
})

local TitleGradient = Gradient(
	Title,
	{
		ColorSequenceKeypoint.new(0, COLORS.White),
		ColorSequenceKeypoint.new(0.45, COLORS.Cyan),
		ColorSequenceKeypoint.new(1, COLORS.Violet),
	},
	0
)

local Subtitle = Text(HeaderTitleZone, {
	Name = "Subtitle",

	Text = "ROBOTIC ANIME COMMAND INTERFACE  //  NEXUS ONLINE",

	Position = UDim2.fromOffset(3, 43),

	Size = UDim2.new(1, -6, 0, 20),

	Font = Enum.Font.GothamMedium,

	TextSize = 12,

	TextColor3 = COLORS.Muted,

	TextTruncate = Enum.TextTruncate.AtEnd,

	ZIndex = 57,
})

----------------------------------------------------------------------
-- HEADER CONTROL ZONE
-- ABSOLUTELY RESERVED FOR MINIMIZE + CLOSE.
----------------------------------------------------------------------

local HeaderControls = New("Frame", {
	Name = "HeaderControls",

	BackgroundTransparency = 1,

	Position = UDim2.new(
		1,
		-CONFIG.ControlZoneDesktop,
		0,
		0
	),

	Size = UDim2.fromOffset(
		CONFIG.ControlZoneDesktop,
		CONFIG.HeaderDesktop
	),

	ZIndex = 100,

	ClipsDescendants = false,
}, Header)

local ControlLayout = New("UIListLayout", {
	FillDirection = Enum.FillDirection.Horizontal,

	HorizontalAlignment = Enum.HorizontalAlignment.Center,

	VerticalAlignment = Enum.VerticalAlignment.Center,

	Padding = UDim.new(0, 8),

	SortOrder = Enum.SortOrder.LayoutOrder,
}, HeaderControls)

----------------------------------------------------------------------
-- CONTROL BUTTONS
----------------------------------------------------------------------

local MinimizeButton = Button(HeaderControls, {
	Name = "Minimize",

	LayoutOrder = 1,

	Size = UDim2.fromOffset(50, 50),

	Text = "—",

	TextSize = 27,

	TextColor3 = COLORS.Cyan,

	BackgroundColor3 = Color3.fromRGB(10, 19, 36),

	ZIndex = 110,

	CornerRadius = 13,
})

local MinimizeStroke = Stroke(
	MinimizeButton,
	COLORS.Cyan,
	1.3,
	0.25
)

local CloseButton = Button(HeaderControls, {
	Name = "Close",

	LayoutOrder = 2,

	Size = UDim2.fromOffset(50, 50),

	Text = "×",

	TextSize = 29,

	TextColor3 = COLORS.Pink,

	BackgroundColor3 = Color3.fromRGB(22, 10, 29),

	ZIndex = 110,

	CornerRadius = 13,
})

local CloseStroke = Stroke(
	CloseButton,
	COLORS.Pink,
	1.3,
	0.25
)

----------------------------------------------------------------------
-- BODY
----------------------------------------------------------------------

local Body = New("Frame", {
	Name = "Body",

	BackgroundTransparency = 1,

	Position = UDim2.fromOffset(
		0,
		CONFIG.HeaderDesktop
	),

	Size = UDim2.new(
		1,
		0,
		1,
		-CONFIG.HeaderDesktop
	),

	ZIndex = 30,
}, MainHolder)

----------------------------------------------------------------------
-- SIDEBAR
----------------------------------------------------------------------

local Sidebar = New("Frame", {
	Name = "Sidebar",

	BackgroundColor3 = Color3.fromRGB(7, 11, 23),

	Position = UDim2.fromOffset(0, 0),

	Size = UDim2.fromOffset(
		CONFIG.SidebarDesktop,
		Body.AbsoluteSize.Y
	),

	BorderSizePixel = 0,

	ZIndex = 35,
}, Body)

local SidebarStroke = Stroke(
	Sidebar,
	COLORS.Line,
	1,
	0.35
)

Padding(Sidebar, 12, 12, 18, 12)

----------------------------------------------------------------------
-- SIDEBAR HEADER
----------------------------------------------------------------------

local SideHeader = Text(Sidebar, {
	Text = "NEXUS MENU",

	Size = UDim2.new(1, 0, 0, 24),

	TextSize = 12,

	Font = Enum.Font.GothamBold,

	TextColor3 = COLORS.Cyan,

	ZIndex = 40,
})

----------------------------------------------------------------------
-- SIDEBAR LINE
----------------------------------------------------------------------

local SideLine = New("Frame", {
	BackgroundColor3 = COLORS.Cyan,

	BackgroundTransparency = 0.55,

	Position = UDim2.fromOffset(0, 38),

	Size = UDim2.new(1, 0, 0, 1),

	BorderSizePixel = 0,

	ZIndex = 40,
}, Sidebar)

----------------------------------------------------------------------
-- NAVIGATION
----------------------------------------------------------------------

local NavContainer = New("Frame", {
	BackgroundTransparency = 1,

	Position = UDim2.fromOffset(0, 55),

	Size = UDim2.new(1, 0, 1, -130),

	ZIndex = 40,
}, Sidebar)

local NavLayout = New("UIListLayout", {
	FillDirection = Enum.FillDirection.Vertical,

	HorizontalAlignment = Enum.HorizontalAlignment.Center,

	VerticalAlignment = Enum.VerticalAlignment.Top,

	Padding = UDim.new(0, 9),

	SortOrder = Enum.SortOrder.LayoutOrder,
}, NavContainer)

local NAV_ITEMS = {
	{
		Id = "HOME",
		Label = "HOME",
		Icon = "⌂",
		Accent = COLORS.Cyan,
	},
	{
		Id = "NEXUS",
		Label = "NEXUS CORE",
		Icon = "◈",
		Accent = COLORS.Violet,
	},
	{
		Id = "VISUALS",
		Label = "VISUALS",
		Icon = "◉",
		Accent = COLORS.Pink,
	},
	{
		Id = "TELEMETRY",
		Label = "TELEMETRY",
		Icon = "⌁",
		Accent = COLORS.Blue,
	},
	{
		Id = "ABOUT",
		Label = "ABOUT",
		Icon = "?",
		Accent = COLORS.Good,
	},
}

local NavButtons = {}

----------------------------------------------------------------------
-- CONTENT
----------------------------------------------------------------------

local Content = New("Frame", {
	Name = "Content",

	BackgroundTransparency = 1,

	Position = UDim2.fromOffset(
		CONFIG.SidebarDesktop,
		0
	),

	Size = UDim2.new(
		1,
		-CONFIG.SidebarDesktop,
		1,
		0
	),

	ZIndex = 40,

	ClipsDescendants = true,
}, Body)

local PageContainer = New("Frame", {
	Name = "PageContainer",

	BackgroundTransparency = 1,

	Position = UDim2.fromOffset(16, 16),

	Size = UDim2.new(
		1,
		-32,
		1,
		-32
	),

	ZIndex = 45,

	ClipsDescendants = true,
}, Content)

----------------------------------------------------------------------
-- MOBILE NAV
----------------------------------------------------------------------

local MobileNav = New("Frame", {
	Name = "MobileNav",

	BackgroundColor3 = Color3.fromRGB(7, 10, 22),

	Position = UDim2.new(
		0,
		0,
		1,
		-CONFIG.BottomNavMobile
	),

	Size = UDim2.new(
		1,
		0,
		0,
		CONFIG.BottomNavMobile
	),

	BorderSizePixel = 0,

	Visible = false,

	ZIndex = 200,
}, MainHolder)

Stroke(
	MobileNav,
	COLORS.LineBright,
	1,
	0.35
)

local MobileNavLayout = New("UIListLayout", {
	FillDirection = Enum.FillDirection.Horizontal,

	HorizontalAlignment = Enum.HorizontalAlignment.Center,

	VerticalAlignment = Enum.VerticalAlignment.Center,

	Padding = UDim.new(0, 5),

	SortOrder = Enum.SortOrder.LayoutOrder,
}, MobileNav)

----------------------------------------------------------------------
-- PAGE SYSTEM
----------------------------------------------------------------------

local Pages = {}

local function CreatePage(id)
	local page = New("ScrollingFrame", {
		Name = id,

		BackgroundTransparency = 1,

		Size = UDim2.fromScale(1, 1),

		CanvasSize = UDim2.new(0, 0, 0, 0),

		AutomaticCanvasSize = Enum.AutomaticSize.Y,

		ScrollBarThickness = 3,

		ScrollBarImageColor3 = COLORS.Cyan,

		BorderSizePixel = 0,

		Visible = false,

		ZIndex = 46,

		ClipsDescendants = true,
	}, PageContainer)

	Padding(page, 4, 8, 4, 12)

	Pages[id] = page

	return page
end

----------------------------------------------------------------------
-- CARD
----------------------------------------------------------------------

local function CreateCard(parent, height, accent)
	local card = New("Frame", {
		BackgroundColor3 = Color3.fromRGB(10, 15, 30),

		Size = UDim2.new(1, 0, 0, height),

		BorderSizePixel = 0,

		ZIndex = 50,
	}, parent)

	Corner(card, 14)

	Stroke(
		card,
		accent or COLORS.Line,
		1,
		0.35
	)

	local accentLine = New("Frame", {
		BackgroundColor3 = accent or COLORS.Cyan,

		BackgroundTransparency = 0.25,

		Position = UDim2.fromOffset(0, 0),

		Size = UDim2.fromOffset(3, height),

		BorderSizePixel = 0,

		ZIndex = 52,
	}, card)

	Corner(accentLine, 4)

	return card
end

----------------------------------------------------------------------
-- CARD TITLE
----------------------------------------------------------------------

local function CardTitle(parent, title, subtitle, accent)
	Text(parent, {
		Text = title,

		Position = UDim2.fromOffset(20, 12),

		Size = UDim2.new(1, -40, 0, 25),

		TextSize = 17,

		Font = Enum.Font.GothamBold,

		TextColor3 = COLORS.White,

		ZIndex = 55,
	})

	Text(parent, {
		Text = subtitle or "",

		Position = UDim2.fromOffset(20, 38),

		Size = UDim2.new(1, -40, 0, 20),

		TextSize = 11,

		TextColor3 = COLORS.Muted,

		ZIndex = 55,
	})

	New("Frame", {
		BackgroundColor3 = accent or COLORS.Cyan,

		BackgroundTransparency = 0.55,

		Position = UDim2.fromOffset(20, 62),

		Size = UDim2.new(1, -40, 0, 1),

		BorderSizePixel = 0,

		ZIndex = 55,
	}, parent)
end

----------------------------------------------------------------------
-- HOME PAGE
----------------------------------------------------------------------

local Home = CreatePage("HOME")

local HomeLayout = New("UIListLayout", {
	FillDirection = Enum.FillDirection.Vertical,

	Padding = UDim.new(0, 12),

	SortOrder = Enum.SortOrder.LayoutOrder,
}, Home)

----------------------------------------------------------------------
-- HOME HERO
----------------------------------------------------------------------

local Hero = CreateCard(Home, 160, COLORS.Cyan)

local HeroTitle = Text(Hero, {
	Text = "WELCOME TO THE NEXUS",

	Position = UDim2.fromOffset(24, 18),

	Size = UDim2.new(1, -48, 0, 36),

	TextSize = 27,

	Font = Enum.Font.GothamBlack,

	TextColor3 = COLORS.White,

	ZIndex = 60,
})

Gradient(
	HeroTitle,
	{
		ColorSequenceKeypoint.new(0, COLORS.White),
		ColorSequenceKeypoint.new(0.4, COLORS.Cyan),
		ColorSequenceKeypoint.new(1, COLORS.Violet),
	},
	0
)

Text(Hero, {
	Text = "Robotic anime command layer initialized.",

	Position = UDim2.fromOffset(25, 57),

	Size = UDim2.new(1, -50, 0, 25),

	TextSize = 14,

	TextColor3 = COLORS.Muted,

	ZIndex = 60,
})

local HeroStatus = New("Frame", {
	BackgroundColor3 = Color3.fromRGB(8, 26, 27),

	Position = UDim2.fromOffset(24, 96),

	Size = UDim2.fromOffset(160, 40),

	BorderSizePixel = 0,

	ZIndex = 60,
}, Hero)

Corner(HeroStatus, 10)
Stroke(HeroStatus, COLORS.Good, 1, 0.35)

local StatusDot = New("Frame", {
	BackgroundColor3 = COLORS.Good,

	Position = UDim2.fromOffset(14, 12),

	Size = UDim2.fromOffset(15, 15),

	BorderSizePixel = 0,

	ZIndex = 62,
}, HeroStatus)

Corner(StatusDot, 99)

Text(HeroStatus, {
	Text = "SYSTEM ONLINE",

	Position = UDim2.fromOffset(38, 0),

	Size = UDim2.new(1, -42, 1, 0),

	TextSize = 11,

	Font = Enum.Font.GothamBold,

	TextColor3 = COLORS.Good,

	ZIndex = 62,
})

----------------------------------------------------------------------
-- HOME STATUS GRID
----------------------------------------------------------------------

local StatusGrid = New("Frame", {
	BackgroundTransparency = 1,

	Size = UDim2.new(1, 0, 0, 110),

	ZIndex = 50,
}, Home)

StatusGrid.LayoutOrder = 2

local GridLayout = New("UIGridLayout", {
	CellPadding = UDim2.fromOffset(10, 10),

	CellSize = UDim2.new(0.333, -7, 1, 0),

	SortOrder = Enum.SortOrder.LayoutOrder,
}, StatusGrid)

local function CreateMetric(parent, title, value, accent)
	local card = New("Frame", {
		BackgroundColor3 = Color3.fromRGB(9, 14, 28),

		BorderSizePixel = 0,

		ZIndex = 52,
	}, parent)

	Corner(card, 13)
	Stroke(card, accent, 1, 0.4)

	Text(card, {
		Text = title,

		Position = UDim2.fromOffset(15, 13),

		Size = UDim2.new(1, -30, 0, 20),

		TextSize = 11,

		TextColor3 = COLORS.Muted,

		ZIndex = 55,
	})

	local label = Text(card, {
		Text = value,

		Position = UDim2.fromOffset(15, 37),

		Size = UDim2.new(1, -30, 0, 35),

		TextSize = 23,

		Font = Enum.Font.GothamBlack,

		TextColor3 = accent,

		ZIndex = 55,
	})

	return label
end

local FPSValue = CreateMetric(
	StatusGrid,
	"FRAME RATE",
	"-- FPS",
	COLORS.Cyan
)

local PingValue = CreateMetric(
	StatusGrid,
	"NETWORK",
	"-- MS",
	COLORS.Violet
)

local UptimeValue = CreateMetric(
	StatusGrid,
	"UPTIME",
	"00:00",
	COLORS.Good
)

----------------------------------------------------------------------
-- RADAR
----------------------------------------------------------------------

local RadarCard = CreateCard(Home, 260, COLORS.Violet)
RadarCard.LayoutOrder = 3

CardTitle(
	RadarCard,
	"NEURAL RADAR",
	"LIVE NEXUS ACTIVITY MONITOR",
	COLORS.Violet
)

local Radar = New("Frame", {
	BackgroundColor3 = Color3.fromRGB(4, 12, 22),

	Position = UDim2.fromOffset(24, 78),

	Size = UDim2.fromOffset(170, 170),

	BorderSizePixel = 0,

	ZIndex = 55,
}, RadarCard)

Corner(Radar, 99)
Stroke(Radar, COLORS.Cyan, 1, 0.25)

for i = 1, 3 do
	local ring = New("Frame", {
		BackgroundTransparency = 1,

		Position = UDim2.fromScale(0.5, 0.5),

		AnchorPoint = Vector2.new(0.5, 0.5),

		Size = UDim2.fromOffset(
			45 + i * 40,
			45 + i * 40
		),

		ZIndex = 56,
	}, Radar)

	Corner(ring, 99)
	Stroke(ring, COLORS.Cyan, 1, 0.7)
end

local RadarCrossX = New("Frame", {
	BackgroundColor3 = COLORS.Cyan,

	BackgroundTransparency = 0.75,

	Position = UDim2.new(0, 0, 0.5, 0),

	AnchorPoint = Vector2.new(0, 0.5),

	Size = UDim2.new(1, 0, 0, 1),

	BorderSizePixel = 0,

	ZIndex = 57,
}, Radar)

local RadarCrossY = New("Frame", {
	BackgroundColor3 = COLORS.Cyan,

	BackgroundTransparency = 0.75,

	Position = UDim2.new(0.5, 0, 0, 0),

	AnchorPoint = Vector2.new(0.5, 0),

	Size = UDim2.new(0, 1, 1, 0),

	BorderSizePixel = 0,

	ZIndex = 57,
}, Radar)

local RadarSweep = New("Frame", {
	BackgroundColor3 = COLORS.Cyan,

	BackgroundTransparency = 0.55,

	Position = UDim2.fromScale(0.5, 0.5),

	AnchorPoint = Vector2.new(0, 0.5),

	Size = UDim2.fromOffset(75, 2),

	Rotation = 0,

	BorderSizePixel = 0,

	ZIndex = 59,
}, Radar)

local RadarCore = New("Frame", {
	BackgroundColor3 = COLORS.Cyan,

	Position = UDim2.fromScale(0.5, 0.5),

	AnchorPoint = Vector2.new(0.5, 0.5),

	Size = UDim2.fromOffset(8, 8),

	BorderSizePixel = 0,

	ZIndex = 60,
}, Radar)

Corner(RadarCore, 99)

----------------------------------------------------------------------
-- RADAR INFO
----------------------------------------------------------------------

Text(RadarCard, {
	Text = "CORE SIGNAL",

	Position = UDim2.fromOffset(220, 88),

	Size = UDim2.new(1, -245, 0, 20),

	TextSize = 11,

	TextColor3 = COLORS.Muted,

	ZIndex = 60,
})

local RadarSignal = Text(RadarCard, {
	Text = "STABLE",

	Position = UDim2.fromOffset(220, 108),

	Size = UDim2.new(1, -245, 0, 40),

	TextSize = 24,

	Font = Enum.Font.GothamBlack,

	TextColor3 = COLORS.Good,

	ZIndex = 60,
})

Text(RadarCard, {
	Text = "The NEXUS core is synchronized and ready for interaction.",

	Position = UDim2.fromOffset(220, 153),

	Size = UDim2.new(1, -245, 0, 65),

	TextSize = 13,

	TextWrapped = true,

	TextColor3 = COLORS.Muted,

	ZIndex = 60,
})

----------------------------------------------------------------------
-- NEXUS PAGE
----------------------------------------------------------------------

local Nexus = CreatePage("NEXUS")

local NexusLayout = New("UIListLayout", {
	FillDirection = Enum.FillDirection.Vertical,

	Padding = UDim.new(0, 12),

	SortOrder = Enum.SortOrder.LayoutOrder,
}, Nexus)

local CoreCard = CreateCard(Nexus, 250, COLORS.Violet)
CoreCard.LayoutOrder = 1

CardTitle(
	CoreCard,
	"NEURAL CORE",
	"ROBOTIC ANIME VISUAL PROCESSOR",
	COLORS.Violet
)

local BigCore = New("Frame", {
	BackgroundColor3 = Color3.fromRGB(8, 14, 29),

	Position = UDim2.fromOffset(25, 82),

	Size = UDim2.fromOffset(150, 150),

	BorderSizePixel = 0,

	ZIndex = 60,
}, CoreCard)

Corner(BigCore, 99)
Stroke(BigCore, COLORS.Violet, 1.5, 0.15)

local BigRing1 = New("Frame", {
	BackgroundTransparency = 1,

	Position = UDim2.fromScale(0.5, 0.5),

	AnchorPoint = Vector2.new(0.5, 0.5),

	Size = UDim2.fromOffset(125, 125),

	ZIndex = 61,
}, BigCore)

Corner(BigRing1, 99)
Stroke(BigRing1, COLORS.Cyan, 1, 0.4)

local BigRing2 = New("Frame", {
	BackgroundTransparency = 1,

	Position = UDim2.fromScale(0.5, 0.5),

	AnchorPoint = Vector2.new(0.5, 0.5),

	Size = UDim2.fromOffset(90, 90),

	ZIndex = 62,
}, BigCore)

Corner(BigRing2, 99)
Stroke(BigRing2, COLORS.Pink, 1, 0.4)

local BigCoreCenter = New("Frame", {
	BackgroundColor3 = COLORS.Cyan,

	Position = UDim2.fromScale(0.5, 0.5),

	AnchorPoint = Vector2.new(0.5, 0.5),

	Size = UDim2.fromOffset(42, 42),

	BorderSizePixel = 0,

	ZIndex = 64,
}, BigCore)

Corner(BigCoreCenter, 15)

Gradient(
	BigCoreCenter,
	{
		ColorSequenceKeypoint.new(0, COLORS.Cyan),
		ColorSequenceKeypoint.new(0.5, COLORS.Blue),
		ColorSequenceKeypoint.new(1, COLORS.Pink),
	},
	45
)

Text(CoreCard, {
	Text = "CORE INTENSITY",

	Position = UDim2.fromOffset(205, 94),

	Size = UDim2.new(1, -230, 0, 20),

	TextSize = 11,

	TextColor3 = COLORS.Muted,

	ZIndex = 65,
})

local IntensityValue = Text(CoreCard, {
	Text = "100%",

	Position = UDim2.fromOffset(205, 117),

	Size = UDim2.new(1, -230, 0, 34),

	TextSize = 25,

	Font = Enum.Font.GothamBlack,

	TextColor3 = COLORS.Cyan,

	ZIndex = 65,
})

Text(CoreCard, {
	Text = "The visual core controls the breathing glow, orbital motion, scan intensity and holographic ambience.",

	Position = UDim2.fromOffset(205, 157),

	Size = UDim2.new(1, -230, 0, 55),

	TextSize = 12,

	TextWrapped = true,

	TextColor3 = COLORS.Muted,

	ZIndex = 65,
})

----------------------------------------------------------------------
-- VISUALS PAGE
----------------------------------------------------------------------

local Visuals = CreatePage("VISUALS")

local VisualLayout = New("UIListLayout", {
	FillDirection = Enum.FillDirection.Vertical,

	Padding = UDim.new(0, 12),

	SortOrder = Enum.SortOrder.LayoutOrder,
}, Visuals)

local VisualCard = CreateCard(Visuals, 350, COLORS.Pink)
VisualCard.LayoutOrder = 1

CardTitle(
	VisualCard,
	"VISUAL MATRIX",
	"CONTROL THE NEXUS ATMOSPHERE",
	COLORS.Pink
)

local ToggleContainer = New("Frame", {
	BackgroundTransparency = 1,

	Position = UDim2.fromOffset(20, 76),

	Size = UDim2.new(1, -40, 1, -88),

	ZIndex = 60,
}, VisualCard)

local ToggleLayout = New("UIListLayout", {
	FillDirection = Enum.FillDirection.Vertical,

	Padding = UDim.new(0, 8),

	SortOrder = Enum.SortOrder.LayoutOrder,
}, ToggleContainer)

local function CreateToggle(parent, label, description, initial, callback)
	local row = New("Frame", {
		BackgroundColor3 = Color3.fromRGB(12, 18, 34),

		Size = UDim2.new(1, 0, 0, 50),

		BorderSizePixel = 0,

		ZIndex = 65,
	}, parent)

	Corner(row, 10)

	Stroke(row, COLORS.Line, 1, 0.5)

	Text(row, {
		Text = label,

		Position = UDim2.fromOffset(14, 5),

		Size = UDim2.new(1, -100, 0, 20),

		TextSize = 13,

		Font = Enum.Font.GothamBold,

		ZIndex = 68,
	})

	Text(row, {
		Text = description,

		Position = UDim2.fromOffset(14, 25),

		Size = UDim2.new(1, -100, 0, 17),

		TextSize = 10,

		TextColor3 = COLORS.Muted,

		ZIndex = 68,
	})

	local toggle = Button(row, {
		Position = UDim2.new(1, -70, 0.5, 0),

		AnchorPoint = Vector2.new(0, 0.5),

		Size = UDim2.fromOffset(54, 28),

		Text = "",

		BackgroundColor3 = initial
			and Color3.fromRGB(10, 55, 59)
			or Color3.fromRGB(26, 30, 42),

		ZIndex = 70,

		CornerRadius = 14,
	})

	local knob = New("Frame", {
		BackgroundColor3 = initial
			and COLORS.Cyan
			or COLORS.Muted,

		Position = initial
			and UDim2.new(1, -24, 0.5, 0)
			or UDim2.fromOffset(14, 14),

		AnchorPoint = Vector2.new(0.5, 0.5),

		Size = UDim2.fromOffset(20, 20),

		BorderSizePixel = 0,

		ZIndex = 72,
	}, toggle)

	Corner(knob, 99)

	local enabled = initial

	Connect(toggle.Activated, function()
		enabled = not enabled

		Tween(toggle, 0.18, {
			BackgroundColor3 = enabled
				and Color3.fromRGB(10, 55, 59)
				or Color3.fromRGB(26, 30, 42),
		})

		Tween(knob, 0.18, {
			Position = enabled
				and UDim2.new(1, -24, 0.5, 0)
				or UDim2.fromOffset(14, 14),

			BackgroundColor3 = enabled
				and COLORS.Cyan
				or COLORS.Muted,
		})

		callback(enabled)
	end)

	return row
end

CreateToggle(
	ToggleContainer,
	"SOFT ANIMATIONS",
	"Smooth breathing and micro-motion.",
	true,
	function(value)
		State.Animations = value
	end
)

CreateToggle(
	ToggleContainer,
	"NEON AMBIENCE",
	"Animated cyan / violet atmosphere.",
	true,
	function(value)
		State.Neon = value
	end
)

CreateToggle(
	ToggleContainer,
	"INTERACTION FX",
	"Button glow and hover feedback.",
	true,
	function(value)
		State.InteractionFX = value
	end
)

CreateToggle(
	ToggleContainer,
	"SCANLINES",
	"Holographic scanning overlay.",
	true,
	function(value)
		State.Scanlines = value
	end
)

CreateToggle(
	ToggleContainer,
	"PARTICLES",
	"Floating robotic particles.",
	true,
	function(value)
		State.Particles = value
	end
)

----------------------------------------------------------------------
-- TELEMETRY PAGE
----------------------------------------------------------------------

local Telemetry = CreatePage("TELEMETRY")

local TelemetryLayout = New("UIListLayout", {
	FillDirection = Enum.FillDirection.Vertical,

	Padding = UDim.new(0, 12),

	SortOrder = Enum.SortOrder.LayoutOrder,
}, Telemetry)

local TelemetryCard = CreateCard(Telemetry, 320, COLORS.Blue)
TelemetryCard.LayoutOrder = 1

CardTitle(
	TelemetryCard,
	"SYSTEM TELEMETRY",
	"REAL-TIME CLIENT DIAGNOSTICS",
	COLORS.Blue
)

local TelemetryGrid = New("Frame", {
	BackgroundTransparency = 1,

	Position = UDim2.fromOffset(20, 78),

	Size = UDim2.new(1, -40, 1, -90),

	ZIndex = 60,
}, TelemetryCard)

local TelemetryLayout = New("UIGridLayout", {
	CellPadding = UDim2.fromOffset(10, 10),

	CellSize = UDim2.new(0.5, -5, 0, 95),

	SortOrder = Enum.SortOrder.LayoutOrder,
}, TelemetryGrid)

local T_FPS = CreateMetric(
	TelemetryGrid,
	"FPS",
	"--",
	COLORS.Cyan
)

local T_Ping = CreateMetric(
	TelemetryGrid,
	"PING",
	"--",
	COLORS.Violet
)

local T_Memory = CreateMetric(
	TelemetryGrid,
	"MEMORY",
	"--",
	COLORS.Pink
)

local T_Uptime = CreateMetric(
	TelemetryGrid,
	"UPTIME",
	"--",
	COLORS.Good
)

----------------------------------------------------------------------
-- ABOUT PAGE
----------------------------------------------------------------------

local About = CreatePage("ABOUT")

local AboutLayout = New("UIListLayout", {
	FillDirection = Enum.FillDirection.Vertical,

	Padding = UDim.new(0, 12),

	SortOrder = Enum.SortOrder.LayoutOrder,
}, About)

local AboutCard = CreateCard(About, 310, COLORS.Good)
AboutCard.LayoutOrder = 1

CardTitle(
	AboutCard,
	"VANZ NEXUS",
	"ROBOTIC ANIME INTERFACE",
	COLORS.Good
)

Text(AboutCard, {
	Text = "V10 // NEXUS ARCHITECTURE",

	Position = UDim2.fromOffset(22, 82),

	Size = UDim2.new(1, -44, 0, 30),

	TextSize = 20,

	Font = Enum.Font.GothamBlack,

	TextColor3 = COLORS.Cyan,

	ZIndex = 60,
})

Text(AboutCard, {
	Text = "Built around a clean responsive hierarchy. The header control zone is isolated from the title system, while mobile navigation moves below the content instead of fighting for header space.",

	Position = UDim2.fromOffset(22, 120),

	Size = UDim2.new(1, -44, 0, 70),

	TextSize = 13,

	TextWrapped = true,

	TextColor3 = COLORS.Muted,

	ZIndex = 60,
})

local AboutStatus = New("Frame", {
	BackgroundColor3 = Color3.fromRGB(8, 27, 24),

	Position = UDim2.fromOffset(22, 210),

	Size = UDim2.new(1, -44, 0, 55),

	BorderSizePixel = 0,

	ZIndex = 60,
}, About)

Corner(AboutStatus, 12)
Stroke(AboutStatus, COLORS.Good, 1, 0.4)

Text(AboutStatus, {
	Text = "ARCHITECTURE STATUS",

	Position = UDim2.fromOffset(16, 4),

	Size = UDim2.new(1, -32, 0, 20),

	TextSize = 10,

	TextColor3 = COLORS.Muted,

	ZIndex = 65,
})

Text(AboutStatus, {
	Text = "STABLE // RESPONSIVE // TOUCH READY",

	Position = UDim2.fromOffset(16, 24),

	Size = UDim2.new(1, -32, 0, 22),

	TextSize = 12,

	Font = Enum.Font.GothamBold,

	TextColor3 = COLORS.Good,

	ZIndex = 65,
})

----------------------------------------------------------------------
-- NAVIGATION BUTTONS
----------------------------------------------------------------------

local function CreateNavButton(parent, item, mobile)
	local button = Button(parent, {
		Name = item.Id,

		Size = mobile
			and UDim2.fromOffset(60, 60)
			or UDim2.new(1, 0, 0, 52),

		Text = "",

		BackgroundColor3 = Color3.fromRGB(9, 14, 28),

		ZIndex = mobile and 210 or 45,

		CornerRadius = 12,
	})

	local icon = Text(button, {
		Text = item.Icon,

		Position = mobile
			and UDim2.fromScale(0.5, 0)
			or UDim2.fromOffset(13, 0),

		AnchorPoint = mobile
			and Vector2.new(0.5, 0)
			or Vector2.new(0, 0),

		Size = mobile
			and UDim2.fromOffset(60, 32)
			or UDim2.fromOffset(30, 52),

		TextSize = mobile and 21 or 19,

		Font = Enum.Font.GothamBlack,

		TextColor3 = item.Accent,

		TextXAlignment = Enum.TextXAlignment.Center,

		ZIndex = mobile and 215 or 48,
	})

	if mobile then
		Text(button, {
			Text = item.Id == "TELEMETRY"
				and "DATA"
				or item.Label,

			Position = UDim2.new(0, 0, 1, -23),

			Size = UDim2.new(1, 0, 0, 20),

			TextSize = 8,

			Font = Enum.Font.GothamBold,

			TextColor3 = COLORS.Muted,

			TextXAlignment = Enum.TextXAlignment.Center,

			ZIndex = 216,
		})
	else
		Text(button, {
			Text = item.Label,

			Position = UDim2.fromOffset(45, 0),

			Size = UDim2.new(1, -55, 1, 0),

			TextSize = 12,

			Font = Enum.Font.GothamBold,

			TextColor3 = COLORS.Muted,

			ZIndex = 48,
		})
	end

	local activeBar = New("Frame", {
		BackgroundColor3 = item.Accent,

		Position = mobile
			and UDim2.new(0.5, -16, 0, 0)
			or UDim2.fromOffset(0, 9),

		Size = mobile
			and UDim2.fromOffset(32, 2)
			or UDim2.fromOffset(3, 34),

		BorderSizePixel = 0,

		Visible = false,

		ZIndex = mobile and 220 or 50,
	}, button)

	Corner(activeBar, 4)

	NavButtons[item.Id] = {
		Button = button,
		Accent = item.Accent,
		Bar = activeBar,
	}

	Connect(button.Activated, function()
		if State.InteractionFX then
			Tween(button, 0.12, {
				Size = mobile
					and UDim2.fromOffset(54, 54)
					or UDim2.new(1, -4, 0, 50),
			})

			task.delay(0.12, function()
				if button.Parent then
					Tween(button, 0.15, {
						Size = mobile
							and UDim2.fromOffset(60, 60)
							or UDim2.new(1, 0, 0, 52),
					})
				end
			end)
		end

		if State.CurrentPage ~= item.Id then
			State.CurrentPage = item.Id

			for pageId, page in pairs(Pages) do
				page.Visible = pageId == item.Id
			end

			for id, info in pairs(NavButtons) do
				local selected = id == item.Id

				info.Bar.Visible = selected

				Tween(
					info.Button,
					0.2,
					{
						BackgroundColor3 = selected
							and Color3.fromRGB(14, 24, 42)
							or Color3.fromRGB(9, 14, 28),
					}
				)
			end
		end
	end)

	return button
end

for _, item in ipairs(NAV_ITEMS) do
	CreateNavButton(NavContainer, item, false)
end

for _, item in ipairs(NAV_ITEMS) do
	CreateNavButton(MobileNav, item, true)
end

----------------------------------------------------------------------
-- SIDEBAR SYSTEM FOOTER
----------------------------------------------------------------------

local SideFooter = New("Frame", {
	BackgroundColor3 = Color3.fromRGB(8, 17, 29),

	Position = UDim2.new(0, 0, 1, -76),

	Size = UDim2.new(1, 0, 0, 64),

	BorderSizePixel = 0,

	ZIndex = 45,
}, Sidebar)

Corner(SideFooter, 10)
Stroke(SideFooter, COLORS.Line, 1, 0.45)

Text(SideFooter, {
	Text = "NEXUS LINK",

	Position = UDim2.fromOffset(12, 7),

	Size = UDim2.new(1, -24, 0, 18),

	TextSize = 10,

	TextColor3 = COLORS.Muted,

	ZIndex = 48,
})

Text(SideFooter, {
	Text = "● CONNECTED",

	Position = UDim2.fromOffset(12, 27),

	Size = UDim2.new(1, -24, 0, 25),

	TextSize = 12,

	Font = Enum.Font.GothamBold,

	TextColor3 = COLORS.Good,

	ZIndex = 48,
})

----------------------------------------------------------------------
-- SCANLINE SYSTEM
----------------------------------------------------------------------

local ScanContainer = New("Frame", {
	Name = "Scanlines",

	BackgroundTransparency = 1,

	Position = UDim2.fromScale(0, 0),

	Size = UDim2.fromScale(1, 1),

	Visible = true,

	ClipsDescendants = true,

	ZIndex = 300,
}, MainHolder)

for i = 1, 8 do
	New("Frame", {
		BackgroundColor3 = COLORS.Cyan,

		BackgroundTransparency = 0.96,

		Position = UDim2.new(
			0,
			0,
			0,
			i * 80
		),

		Size = UDim2.new(1, 0, 0, 1),

		BorderSizePixel = 0,

		ZIndex = 301,
	}, ScanContainer)
end

----------------------------------------------------------------------
-- CIRCUIT DECORATIONS
----------------------------------------------------------------------

local CircuitLayer = New("Frame", {
	Name = "CircuitLayer",

	BackgroundTransparency = 1,

	Size = UDim2.fromScale(1, 1),

	ZIndex = 302,
}, MainHolder)

local function CircuitLine(x, y, width, height, rotation, color)
	local line = New("Frame", {
		BackgroundColor3 = color,

		BackgroundTransparency = 0.55,

		Position = UDim2.new(x, 0, y, 0),

		Size = UDim2.fromOffset(width, height),

		Rotation = rotation or 0,

		BorderSizePixel = 0,

		ZIndex = 303,
	}, CircuitLayer)

	return line
end

CircuitLine(0.03, 0.14, 90, 1, 0, COLORS.Cyan)
CircuitLine(0.04, 0.14, 1, 42, 0, COLORS.Cyan)
CircuitLine(0.04, 0.205, 45, 1, 0, COLORS.Violet)

CircuitLine(0.92, 0.82, 65, 1, 0, COLORS.Pink)
CircuitLine(0.94, 0.74, 1, 52, 0, COLORS.Pink)
CircuitLine(0.89, 0.82, 1, 1, 0, COLORS.Cyan)

----------------------------------------------------------------------
-- FLOATING PARTICLES
----------------------------------------------------------------------

local ParticleLayer = New("Frame", {
	Name = "Particles",

	BackgroundTransparency = 1,

	Size = UDim2.fromScale(1, 1),

	ClipsDescendants = true,

	ZIndex = 304,
}, MainHolder)

local RandomGenerator = Random.new()

for i = 1, CONFIG.ParticleCount do
	local particle = New("Frame", {
		BackgroundColor3 = COLORS.Cyan,

		BackgroundTransparency = RandomGenerator:NextNumber(0.35, 0.8),

		Position = UDim2.fromScale(
			RandomGenerator:NextNumber(0.02, 0.98),
			RandomGenerator:NextNumber(0.08, 0.95)
		),

		Size = UDim2.fromOffset(
			RandomGenerator:NextInteger(1, 3),
			RandomGenerator:NextInteger(1, 3)
		),

		BorderSizePixel = 0,

		ZIndex = 305,
	}, ParticleLayer)

	Corner(particle, 99)

	table.insert(State.Particles, {
		Object = particle,

		BaseX = particle.Position.X.Scale,

		BaseY = particle.Position.Y.Scale,

		Phase = RandomGenerator:NextNumber(0, math.pi * 2),

		Speed = RandomGenerator:NextNumber(0.25, 0.8),
	})
end

----------------------------------------------------------------------
-- MINIMIZED CORE
----------------------------------------------------------------------

local MinimizedLayer = New("Frame", {
	Name = "MinimizedLayer",

	BackgroundTransparency = 1,

	Size = UDim2.fromScale(1, 1),

	Visible = false,

	ZIndex = 900,
}, Root)

local CoreGlow = New("Frame", {
	BackgroundColor3 = COLORS.Cyan,

	BackgroundTransparency = 0.9,

	Position = UDim2.fromScale(0.5, 0.5),

	AnchorPoint = Vector2.new(0.5, 0.5),

	Size = UDim2.fromOffset(145, 145),

	BorderSizePixel = 0,

	ZIndex = 900,
}, MinimizedLayer)

Corner(CoreGlow, 99)

local MinimizedCore = New("Frame", {
	Name = "MinimizedCore",

	BackgroundColor3 = Color3.fromRGB(7, 14, 28),

	Position = UDim2.fromScale(0.5, 0.5),

	AnchorPoint = Vector2.new(0.5, 0.5),

	Size = UDim2.fromOffset(96, 96),

	BorderSizePixel = 0,

	ZIndex = 910,
}, MinimizedLayer)

Corner(MinimizedCore, 99)

Stroke(
	MinimizedCore,
	COLORS.Cyan,
	2,
	0.1
)

local MiniRingA = New("Frame", {
	BackgroundTransparency = 1,

	Position = UDim2.fromScale(0.5, 0.5),

	AnchorPoint = Vector2.new(0.5, 0.5),

	Size = UDim2.fromOffset(82, 82),

	ZIndex = 911,
}, MinimizedCore)

Corner(MiniRingA, 99)
Stroke(MiniRingA, COLORS.Violet, 1, 0.25)

local MiniRingB = New("Frame", {
	BackgroundTransparency = 1,

	Position = UDim2.fromScale(0.5, 0.5),

	AnchorPoint = Vector2.new(0.5, 0.5),

	Size = UDim2.fromOffset(60, 60),

	ZIndex = 912,
}, MinimizedCore)

Corner(MiniRingB, 99)
Stroke(MiniRingB, COLORS.Pink, 1, 0.3)

local MiniCore = New("Frame", {
	BackgroundColor3 = COLORS.Cyan,

	Position = UDim2.fromScale(0.5, 0.5),

	AnchorPoint = Vector2.new(0.5, 0.5),

	Size = UDim2.fromOffset(31, 31),

	BorderSizePixel = 0,

	ZIndex = 914,
}, MinimizedCore)

Corner(MiniCore, 11)

Gradient(
	MiniCore,
	{
		ColorSequenceKeypoint.new(0, COLORS.Cyan),
		ColorSequenceKeypoint.new(0.5, COLORS.Blue),
		ColorSequenceKeypoint.new(1, COLORS.Pink),
	},
	45
)

Text(MinimizedLayer, {
	Text = "NEXUS",

	Position = UDim2.new(0.5, -100, 0.5, 62),

	Size = UDim2.fromOffset(200, 25),

	TextSize = 11,

	Font = Enum.Font.GothamBold,

	TextColor3 = COLORS.Cyan,

	TextXAlignment = Enum.TextXAlignment.Center,

	ZIndex = 920,
})

----------------------------------------------------------------------
-- DRAG SYSTEM
----------------------------------------------------------------------

local function BeginWindowDrag(input)
	if State.Minimized then
		return
	end

	if input.UserInputType ~= Enum.UserInputType.MouseButton1
		and input.UserInputType ~= Enum.UserInputType.Touch then
		return
	end

	State.DraggingWindow = true
	State.DragStart = input.Position

	local current = MainHolder.Position

	State.DragOrigin = Vector2.new(
		current.X.Offset,
		current.Y.Offset
	)
end

local function UpdateWindowDrag(input)
	if not State.DraggingWindow then
		return
	end

	local delta = input.Position - State.DragStart

	if delta.Magnitude > 5 then
		State.WindowDragged = true
	end

	State.WindowOffset = State.DragOrigin + delta
end

local function EndWindowDrag()
	State.DraggingWindow = false
end

----------------------------------------------------------------------
-- HEADER DRAG AREA
----------------------------------------------------------------------

local HeaderDragArea = New("TextButton", {
	Name = "HeaderDragArea",

	BackgroundTransparency = 1,

	Text = "",

	AutoButtonColor = false,

	Position = UDim2.fromOffset(82, 0),

	Size = UDim2.new(
		1,
		-(82 + CONFIG.ControlZoneDesktop),
		1,
		0
	),

	ZIndex = 52,
}, Header)

Connect(HeaderDragArea.InputBegan, function(input)
	BeginWindowDrag(input)
end)

Connect(UserInputService.InputChanged, function(input)
	if input.UserInputType == Enum.UserInputType.MouseMovement
		or input.UserInputType == Enum.UserInputType.Touch then

		UpdateWindowDrag(input)
	end
end)

Connect(UserInputService.InputEnded, function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1
		or input.UserInputType == Enum.UserInputType.Touch then

		EndWindowDrag()
	end
end)

----------------------------------------------------------------------
-- MINIMIZED CORE DRAG
----------------------------------------------------------------------

Connect(MinimizedCore.InputBegan, function(input)
	if input.UserInputType ~= Enum.UserInputType.MouseButton1
		and input.UserInputType ~= Enum.UserInputType.Touch then
		return
	end

	State.DraggingCore = true
	State.CoreDragStart = input.Position

	local position = MinimizedCore.Position

	State.CoreOrigin = Vector2.new(
		position.X.Offset,
		position.Y.Offset
	)
end)

Connect(UserInputService.InputChanged, function(input)
	if not State.DraggingCore then
		return
	end

	if input.UserInputType ~= Enum.UserInputType.MouseMovement
		and input.UserInputType ~= Enum.UserInputType.Touch then
		return
	end

	local delta = input.Position - State.CoreDragStart

	local camera = workspace.CurrentCamera

	if not camera then
		return
	end

	local viewport = camera.ViewportSize

	local coreSize = MinimizedCore.AbsoluteSize

	local x = State.CoreOrigin.X + delta.X
	local y = State.CoreOrigin.Y + delta.Y

	local halfW = viewport.X / 2
	local halfH = viewport.Y / 2

	local maxX = halfW - coreSize.X / 2
	local maxY = halfH - coreSize.Y / 2

	local minX = -halfW + coreSize.X / 2
	local minY = -halfH + coreSize.Y / 2

	MinimizedCore.Position = UDim2.fromOffset(
		Clamp(x, minX, maxX),
		Clamp(y, minY, maxY)
	)

	CoreGlow.Position = MinimizedCore.Position
end)

Connect(UserInputService.InputEnded, function(input)
	if input.UserInputType ~= Enum.UserInputType.MouseButton1
		and input.UserInputType ~= Enum.UserInputType.Touch then
		return
	end

	if State.DraggingCore then
		State.DraggingCore = false
	end
end)

----------------------------------------------------------------------
-- RESPONSIVE SYSTEM
----------------------------------------------------------------------

local function GetViewport()
	local camera = workspace.CurrentCamera

	if not camera then
		return Vector2.new(1280, 720)
	end

	return camera.ViewportSize
end

local function RecenterWindow()
	State.WindowOffset = Vector2.zero

	MainHolder.Position = UDim2.fromScale(0.5, 0.5)
end

local function ApplyWindowOffset()
	if not State.WindowDragged then
		MainHolder.Position = UDim2.fromScale(0.5, 0.5)
		return
	end

	local viewport = GetViewport()

	local windowSize = MainHolder.AbsoluteSize

	local halfW = viewport.X / 2
	local halfH = viewport.Y / 2

	local maxX = halfW - windowSize.X / 2 - 4
	local maxY = halfH - windowSize.Y / 2 - 4

	local minX = -maxX
	local minY = -maxY

	local x = Clamp(
		State.WindowOffset.X,
		minX,
		maxX
	)

	local y = Clamp(
		State.WindowOffset.Y,
		minY,
		maxY
	)

	MainHolder.Position = UDim2.new(
		0.5,
		x,
		0.5,
		y
	)
end

local function UpdateResponsive()
	local viewport = GetViewport()

	State.Mobile =
		viewport.X <= 760
		or viewport.Y <= 540

	State.Tiny =
		viewport.X <= 380

	local mobile = State.Mobile
	local tiny = State.Tiny

	local headerHeight = mobile
		and CONFIG.HeaderMobile
		or CONFIG.HeaderDesktop

	local controlWidth = mobile
		and CONFIG.ControlZoneMobile
		or CONFIG.ControlZoneDesktop

	------------------------------------------------------------------
	-- MAIN SIZE
	------------------------------------------------------------------

	if mobile then
		local width = math.max(
			1,
			viewport.X - CONFIG.MobileMargin * 2
		)

		local height = math.max(
			1,
			viewport.Y - CONFIG.MobileMargin * 2
		)

		MainHolder.Size = UDim2.fromOffset(
			width,
			height
		)

		State.CurrentScale = 1
	else
		MainHolder.Size = UDim2.fromOffset(
			CONFIG.DesktopWidth,
			CONFIG.DesktopHeight
		)
	end

	------------------------------------------------------------------
	-- HEADER
	------------------------------------------------------------------

	Header.Size = UDim2.new(
		1,
		0,
		0,
		headerHeight
	)

	HeaderLogoZone.Size = UDim2.fromOffset(
		mobile and 58 or 70,
		headerHeight
	)

	Logo.Size = UDim2.fromOffset(
		mobile and 48 or 58,
		mobile and 48 or 58
	)

	HeaderControls.Position = UDim2.new(
		1,
		-controlWidth,
		0,
		0
	)

	HeaderControls.Size = UDim2.fromOffset(
		controlWidth,
		headerHeight
	)

	MinimizeButton.Size = UDim2.fromOffset(
		mobile and 46 or 50,
		mobile and 46 or 50
	)

	CloseButton.Size = UDim2.fromOffset(
		mobile and 46 or 50,
		mobile and 46 or 50
	)

	------------------------------------------------------------------
	-- TITLE ZONE
	------------------------------------------------------------------

	local logoZoneWidth = mobile and 66 or 88

	HeaderTitleZone.Position = UDim2.fromOffset(
		logoZoneWidth,
		0
	)

	HeaderTitleZone.Size = UDim2.new(
		1,
		-(logoZoneWidth + controlWidth + 10),
		1,
		0
	)

	Title.TextSize =
		tiny and 17
		or mobile and 20
		or 26

	Title.Position = UDim2.fromOffset(
		2,
		mobile and 8 or 10
	)

	Title.Size = UDim2.new(
		1,
		-4,
		0,
		mobile and 27 or 30
	)

	Subtitle.Visible = not tiny

	Subtitle.TextSize = mobile and 9 or 12

	Subtitle.Position = UDim2.fromOffset(
		3,
		mobile and 39 or 43
	)

	------------------------------------------------------------------
	-- BODY
	------------------------------------------------------------------

	Body.Position = UDim2.fromOffset(
		0,
		headerHeight
	)

	Body.Size = UDim2.new(
		1,
		0,
		1,
		-headerHeight
	)

	------------------------------------------------------------------
	-- DESKTOP SIDEBAR / MOBILE BOTTOM NAV
	------------------------------------------------------------------

	if mobile then
		Sidebar.Visible = false
		MobileNav.Visible = true

		Content.Position = UDim2.fromOffset(
			0,
			0
		)

		Content.Size = UDim2.new(
			1,
			0,
			1,
			-CONFIG.BottomNavMobile
		)

		MobileNav.Size = UDim2.new(
			1,
			0,
			0,
			CONFIG.BottomNavMobile
		)

		MobileNav.Position = UDim2.new(
			0,
			0,
			1,
			-CONFIG.BottomNavMobile
		)

		PageContainer.Position = UDim2.fromOffset(
			10,
			8
		)

		PageContainer.Size = UDim2.new(
			1,
			-20,
			1,
			-16
		)

		if tiny then
			MobileNavLayout.Padding = UDim.new(0, 1)
		else
			MobileNavLayout.Padding = UDim.new(0, 5)
		end
	else
		Sidebar.Visible = true
		MobileNav.Visible = false

		Sidebar.Size = UDim2.new(
			0,
			CONFIG.SidebarDesktop,
			1,
			0
		)

		Content.Position = UDim2.fromOffset(
			CONFIG.SidebarDesktop,
			0
		)

		Content.Size = UDim2.new(
			1,
			-CONFIG.SidebarDesktop,
			1,
			0
		)

		PageContainer.Position = UDim2.fromOffset(
			16,
			16
		)

		PageContainer.Size = UDim2.new(
			1,
			-32,
			1,
			-32
		)
	end

	------------------------------------------------------------------
	-- HEADER DRAG AREA
	------------------------------------------------------------------

	HeaderDragArea.Position = UDim2.fromOffset(
		logoZoneWidth,
		0
	)

	HeaderDragArea.Size = UDim2.new(
		1,
		-(logoZoneWidth + controlWidth),
		1,
		0
	)

	ApplyWindowOffset()
end

----------------------------------------------------------------------
-- INITIAL PAGE
----------------------------------------------------------------------

for id, page in pairs(Pages) do
	page.Visible = id == "HOME"
end

for id, info in pairs(NavButtons) do
	local active = id == "HOME"

	info.Bar.Visible = active

	info.Button.BackgroundColor3 = active
		and Color3.fromRGB(14, 24, 42)
		or Color3.fromRGB(9, 14, 28)
end

----------------------------------------------------------------------
-- BUTTON FX
----------------------------------------------------------------------

local function AddButtonFX(button, accent)
	if not button then
		return
	end

	Connect(button.MouseEnter, function()
		if not State.InteractionFX then
			return
		end

		Tween(button, 0.15, {
			BackgroundColor3 = Color3.fromRGB(16, 27, 46),
		})

		Tween(
			button,
			0.15,
			{
				Rotation = 0,
			},
			Enum.EasingStyle.Sine
		)
	end)

	Connect(button.MouseLeave, function()
		if not State.InteractionFX then
			return
		end

		Tween(button, 0.2, {
			BackgroundColor3 = Color3.fromRGB(9, 14, 28),
		})
	end)

	Connect(button.Activated, function()
		if not State.InteractionFX then
			return
		end

		Tween(button, 0.08, {
			BackgroundColor3 = accent,
		})

		task.delay(0.1, function()
			if button.Parent then
				Tween(button, 0.2, {
					BackgroundColor3 = Color3.fromRGB(9, 14, 28),
				})
			end
		end)
	end)
end

AddButtonFX(MinimizeButton, COLORS.Cyan)
AddButtonFX(CloseButton, COLORS.Pink)

----------------------------------------------------------------------
-- MINIMIZE
----------------------------------------------------------------------

local function Minimize()
	if State.Minimized then
		return
	end

	State.Minimized = true

	MinimizedLayer.Visible = true

	MinimizedCore.Position = UDim2.fromScale(
		0.5,
		0.5
	)

	CoreGlow.Position = MinimizedCore.Position

	MainHolder.AnchorPoint = Vector2.new(0.5, 0.5)

	Tween(MainHolder, 0.28, {
		Size = UDim2.fromOffset(20, 20),

		BackgroundTransparency = 1,
	}, Enum.EasingStyle.Back, Enum.EasingDirection.In)

	Tween(OuterGlow, 0.22, {
		BackgroundTransparency = 1,
	})

	task.delay(0.25, function()
		if not State.Minimized then
			return
		end

		MainHolder.Visible = false

		Tween(MinimizedCore, 0.4, {
			Size = UDim2.fromOffset(96, 96),
		}, Enum.EasingStyle.Back)

		Tween(CoreGlow, 0.4, {
			Size = UDim2.fromOffset(145, 145),
		}, Enum.EasingStyle.Back)
	end)
end

----------------------------------------------------------------------
-- RESTORE
----------------------------------------------------------------------

local function Restore()
	if not State.Minimized then
		return
	end

	State.Minimized = false

	MainHolder.Visible = true

	MainHolder.Size = UDim2.fromOffset(20, 20)

	MainHolder.BackgroundTransparency = 1

	Tween(
		MainHolder,
		0.42,
		{
			Size = State.Mobile
				and UDim2.fromOffset(
					math.max(1, GetViewport().X - 14),
					math.max(1, GetViewport().Y - 14)
				)
				or UDim2.fromOffset(
					CONFIG.DesktopWidth,
					CONFIG.DesktopHeight
				),

			BackgroundTransparency = 0,
		},
		Enum.EasingStyle.Back,
		Enum.EasingDirection.Out
	)

	Tween(OuterGlow, 0.35, {
		BackgroundTransparency = 0.96,
	})

	Tween(MinimizedCore, 0.2, {
		Size = UDim2.fromOffset(15, 15),
	})

	task.delay(0.2, function()
		if not State.Minimized then
			MinimizedLayer.Visible = false
		end
	end)

	ApplyWindowOffset()
end

Connect(MinimizeButton.Activated, function()
	Minimize()
end)

Connect(MinimizedCore.InputEnded, function(input)
	if input.UserInputType ~= Enum.UserInputType.MouseButton1
		and input.UserInputType ~= Enum.UserInputType.Touch then
		return
	end

	-- If it was only a tap, restore.
	-- Dragging is handled by the movement system.
	if not State.DraggingCore then
		Restore()
	end
end)

----------------------------------------------------------------------
-- CLOSE
----------------------------------------------------------------------

Connect(CloseButton.Activated, function()
	if State.Destroyed then
		return
	end

	State.Destroyed = true

	Tween(MainHolder, 0.22, {
		Size = UDim2.fromOffset(20, 20),

		BackgroundTransparency = 1,
	})

	Tween(OuterGlow, 0.2, {
		BackgroundTransparency = 1,
	})

	task.delay(0.24, function()
		DisconnectAll()

		for _, tween in ipairs(State.Tweens) do
			pcall(function()
				tween:Cancel()
			end)
		end

		if ScreenGui then
			ScreenGui:Destroy()
		end

		if _G.vanz then
			_G.vanz = nil
		end
	end)
end)

----------------------------------------------------------------------
-- RESPONSIVE WATCH
----------------------------------------------------------------------

local lastViewport = Vector2.zero

Connect(RunService.RenderStepped, function(delta)
	if State.Destroyed then
		return
	end

	local viewport = GetViewport()

	if viewport ~= lastViewport then
		lastViewport = viewport

		UpdateResponsive()
	end
end)

----------------------------------------------------------------------
-- ANIMATION ENGINE
----------------------------------------------------------------------

local animationClock = 0
local telemetryClock = 0

local frameCounter = 0
local frameTimer = 0
local currentFPS = 60

Connect(RunService.RenderStepped, function(delta)
	if State.Destroyed then
		return
	end

	animationClock += delta
	telemetryClock += delta

	frameCounter += 1
	frameTimer += delta

	if frameTimer >= 0.5 then
		currentFPS = math.floor(
			frameCounter / frameTimer + 0.5
		)

		frameCounter = 0
		frameTimer = 0
	end

	------------------------------------------------------------------
	-- HUE
	------------------------------------------------------------------

	if State.HueCycle then
		State.Hue = (
			State.Hue + delta * 0.018
		) % 1
	end

	------------------------------------------------------------------
	-- BREATH
	------------------------------------------------------------------

	local breathe =
		(math.sin(animationClock * 1.7) + 1) / 2

	local pulse =
		(math.sin(animationClock * 2.4) + 1) / 2

	State.Pulse = pulse

	------------------------------------------------------------------
	-- DYNAMIC COLORS
	------------------------------------------------------------------

	local dynamicCyan = State.HueCycle
		and ColorFromHSV(
			0.52 + State.Hue * 0.15,
			0.72,
			1
		)
		or COLORS.Cyan

	local dynamicAccent = State.HueCycle
		and ColorFromHSV(
			0.76 + State.Hue * 0.15,
			0.68,
			1
		)
		or COLORS.Violet

	------------------------------------------------------------------
	-- LOGO
	------------------------------------------------------------------

	if State.Animations then
		LogoRingOuter.Rotation =
			animationClock * 18

		LogoRingInner.Rotation =
			-animationClock * 27

		BigRing1.Rotation =
			animationClock * 22

		BigRing2.Rotation =
			-animationClock * 35

		MiniRingA.Rotation =
			animationClock * 28

		MiniRingB.Rotation =
			-animationClock * 40
	end

	local logoScale =
		1 + breathe * 0.035

	LogoCore.Size = UDim2.fromOffset(
		18 * logoScale,
		18 * logoScale
	)

	LogoCore.BackgroundColor3 = dynamicCyan

	MiniCore.BackgroundColor3 = dynamicCyan

	BigCoreCenter.BackgroundColor3 = dynamicCyan

	------------------------------------------------------------------
	-- GLOW
	------------------------------------------------------------------

	if State.Neon then
		OuterGlow.BackgroundColor3 = dynamicCyan

		OuterGlow.BackgroundTransparency =
			0.965 - breathe * 0.015

		CoreGlow.BackgroundColor3 = dynamicCyan

		CoreGlow.BackgroundTransparency =
			0.92 - pulse * 0.035
	else
		OuterGlow.BackgroundTransparency = 1
		CoreGlow.BackgroundTransparency = 1
	end

	------------------------------------------------------------------
	-- HEADER LINE
	------------------------------------------------------------------

	HeaderLine.BackgroundColor3 = dynamicCyan

	HeaderLine.BackgroundTransparency =
		0.25 + (1 - pulse) * 0.2

	------------------------------------------------------------------
	-- RADAR
	------------------------------------------------------------------

	RadarSweep.Rotation =
		(animationClock * 72) % 360

	RadarCore.BackgroundColor3 = dynamicCyan

	RadarSignal.TextColor3 =
		ColorFromHSV(
			0.42 + pulse * 0.04,
			0.7,
			1
		)

	------------------------------------------------------------------
	-- SCANLINES
	------------------------------------------------------------------

	ScanContainer.Visible = State.Scanlines

	if State.Scanlines then
		local scanOffset =
			(animationClock * 35) % 80

		for index, child in ipairs(ScanContainer:GetChildren()) do
			if child:IsA("Frame") then
				child.Position = UDim2.new(
					0,
					0,
					0,
					index * 80 + scanOffset
				)
			end
		end
	end

	------------------------------------------------------------------
	-- PARTICLES
	------------------------------------------------------------------

	ParticleLayer.Visible = State.Particles

	if State.Particles then
		for _, particleData in ipairs(State.Particles) do
			local particle = particleData.Object

			if particle and particle.Parent then
				local x =
					particleData.BaseX
					+ math.sin(
						animationClock
							* particleData.Speed
							+ particleData.Phase
					) * 0.008

				local y =
					particleData.BaseY
					+ math.cos(
						animationClock
							* particleData.Speed
							+ particleData.Phase
					) * 0.012

				particle.Position =
					UDim2.fromScale(x, y)

				particle.BackgroundColor3 =
					(particleData.Phase % 2 > 1)
					and dynamicCyan
					or dynamicAccent
			end
		end
	end

	------------------------------------------------------------------
	-- MINIMIZED CORE
	------------------------------------------------------------------

	if State.Minimized then
		local miniScale =
			1 + pulse * 0.08

		MinimizedCore.Size = UDim2.fromOffset(
			96 * miniScale,
			96 * miniScale
		)

		CoreGlow.Size = UDim2.fromOffset(
			145 + pulse * 16,
			145 + pulse * 16
		)

		MiniCore.BackgroundColor3 = dynamicCyan
	end

	------------------------------------------------------------------
	-- TELEMETRY
	------------------------------------------------------------------

	if telemetryClock >= 0.5 then
		telemetryClock = 0

		local uptime =
			math.floor(
				os.clock() - State.OpenedAt
			)

		local minutes =
			math.floor(uptime / 60)

		local seconds =
			uptime % 60

		local uptimeText = string.format(
			"%02d:%02d",
			minutes,
			seconds
		)

		FPSValue.Text =
			tostring(currentFPS) .. " FPS"

		T_FPS.Text =
			tostring(currentFPS)

		UptimeValue.Text =
			uptimeText

		T_Uptime.Text =
			uptimeText

		------------------------------------------------------------------
		-- MEMORY
		------------------------------------------------------------------

		local memory = nil

		pcall(function()
			memory =
				Stats:GetTotalMemoryUsageMb()
		end)

		if memory then
			local memoryText =
				string.format(
					"%.0f MB",
					memory
				)

			T_Memory.Text =
				memoryText
		else
			T_Memory.Text =
				"--"
		end

		------------------------------------------------------------------
		-- PING
		------------------------------------------------------------------

		local pingValue = nil

		pcall(function()
			local network =
				Stats.Network

			if network then
				local serverStats =
					network.ServerStatsItem

				if serverStats then
					local dataPing =
						serverStats
						:FindFirstChild(
							"Data Ping"
						)

					if dataPing then
						pingValue =
							math.floor(
								dataPing:GetValue()
							)
					end
				end
			end
		end)

		if pingValue then
			local pingText =
				tostring(pingValue) .. " ms"

			PingValue.Text =
				pingText

			T_Ping.Text =
				tostring(pingValue)
		else
			PingValue.Text =
				"-- MS"

			T_Ping.Text =
				"--"
		end
	end
end)

----------------------------------------------------------------------
-- TOPMOST WATCHDOG
----------------------------------------------------------------------

local watchdogClock = 0

Connect(RunService.RenderStepped, function(delta)
	watchdogClock += delta

	if watchdogClock < 1 then
		return
	end

	watchdogClock = 0

	if not ScreenGui.Parent then
		return
	end

	ScreenGui.DisplayOrder =
		CONFIG.DisplayOrder

	ScreenGui.ZIndexBehavior =
		Enum.ZIndexBehavior.Global

	MainHolder.ZIndex = 20
	Header.ZIndex = 50
	HeaderControls.ZIndex = 100

	MinimizeButton.ZIndex = 110
	CloseButton.ZIndex = 110
end)

----------------------------------------------------------------------
-- WINDOW DRAG VISUAL
----------------------------------------------------------------------

Connect(RunService.RenderStepped, function()
	if State.Destroyed then
		return
	end

	if State.DraggingWindow then
		local offset =
			State.WindowOffset

		local current =
			State.DragOrigin

		local delta =
			offset - current

		local camera =
			workspace.CurrentCamera

		if camera then
			local viewport =
				camera.ViewportSize

			local size =
				MainHolder.AbsoluteSize

			local maxX =
				math.max(
					0,
					viewport.X / 2
						- size.X / 2
						- 4
				)

			local maxY =
				math.max(
					0,
					viewport.Y / 2
						- size.Y / 2
						- 4
				)

			local x =
				Clamp(
					State.DragOrigin.X + delta.X,
					-maxX,
					maxX
				)

			local y =
				Clamp(
					State.DragOrigin.Y + delta.Y,
					-maxY,
					maxY
				)

			State.WindowOffset =
				Vector2.new(x, y)

			MainHolder.Position =
				UDim2.new(
					0.5,
					x,
					0.5,
					y
				)
		end
	end
end)

----------------------------------------------------------------------
-- TOUCH / MOUSE HOVER FX FOR HEADER
----------------------------------------------------------------------

local function HeaderButtonHover(button, normalColor, hoverColor)
	Connect(button.MouseEnter, function()
		if State.InteractionFX then
			Tween(button, 0.15, {
				BackgroundColor3 = hoverColor,
			})
		end
	end)

	Connect(button.MouseLeave, function()
		if State.InteractionFX then
			Tween(button, 0.18, {
				BackgroundColor3 = normalColor,
			})
		end
	end)
end

HeaderButtonHover(
	MinimizeButton,
	Color3.fromRGB(10, 19, 36),
	Color3.fromRGB(13, 43, 57)
)

HeaderButtonHover(
	CloseButton,
	Color3.fromRGB(22, 10, 29),
	Color3.fromRGB(55, 15, 38)
)

----------------------------------------------------------------------
-- CORE TAP FEEDBACK
----------------------------------------------------------------------

Connect(MinimizedCore.MouseEnter, function()
	if State.InteractionFX then
		Tween(MinimizedCore, 0.18, {
			Size = UDim2.fromOffset(104, 104),
		})

		Tween(CoreGlow, 0.2, {
			Size = UDim2.fromOffset(165, 165),
			BackgroundTransparency = 0.87,
		})
	end
end)

Connect(MinimizedCore.MouseLeave, function()
	if State.InteractionFX then
		Tween(MinimizedCore, 0.18, {
			Size = UDim2.fromOffset(96, 96),
		})

		Tween(CoreGlow, 0.2, {
			Size = UDim2.fromOffset(145, 145),
			BackgroundTransparency = 0.92,
		})
	end
end)

----------------------------------------------------------------------
-- CHARACTER RESPAWN SAFETY
----------------------------------------------------------------------

Connect(LocalPlayer.CharacterAdded, function()
	task.wait(0.5)

	if State.Destroyed then
		return
	end

	ScreenGui.Enabled = true
end)

----------------------------------------------------------------------
-- PUBLIC API
----------------------------------------------------------------------

_G.vanz = {
	Config = CONFIG,

	State = State,

	Open = function()
		if State.Destroyed then
			return
		end

		if State.Minimized then
			Restore()
		else
			MainHolder.Visible = true
			ScreenGui.Enabled = true
		end
	end,

	Hide = function()
		if State.Destroyed then
			return
		end

		MainHolder.Visible = false
		MinimizedLayer.Visible = false
	end,

	Minimize = function()
		if not State.Destroyed then
			Minimize()
		end
	end,

	Restore = function()
		if not State.Destroyed then
			Restore()
		end
	end,

	Close = function()
		if CloseButton and CloseButton.Parent then
			CloseButton:Activate()
		end
	end,

	SetScale = function(scale)
		if State.Destroyed then
			return
		end

		if State.Mobile then
			State.CurrentScale = 1
			return
		end

		State.CurrentScale =
			Clamp(
				tonumber(scale) or 1,
				0.75,
				1.15
			)
	end,

	SetPage = function(pageName)
		if State.Destroyed then
			return
		end

		pageName =
			string.upper(
				tostring(pageName)
			)

		local page =
			Pages[pageName]

		local navigation =
			NavButtons[pageName]

		if not page or not navigation then
			return
		end

		State.CurrentPage =
			pageName

		for id, targetPage in pairs(Pages) do
			targetPage.Visible =
				id == pageName
		end

		for id, info in pairs(NavButtons) do
			local selected =
				id == pageName

			info.Bar.Visible =
				selected

			info.Button.BackgroundColor3 =
				selected
				and Color3.fromRGB(14, 24, 42)
				or Color3.fromRGB(9, 14, 28)
		end
	end,

	GetState = function()
		return {
			Destroyed = State.Destroyed,
			Minimized = State.Minimized,
			Mobile = State.Mobile,
			CurrentPage = State.CurrentPage,
			Animations = State.Animations,
			Neon = State.Neon,
			Particles = State.Particles,
			Scanlines = State.Scanlines,
		}
	end,

	ForceStop = function()
		State.Destroyed = true

		DisconnectAll()

		if ScreenGui then
			ScreenGui:Destroy()
		end

		_G.vanz = nil
	end,
}

----------------------------------------------------------------------
-- INITIALIZE
----------------------------------------------------------------------

UpdateResponsive()

task.defer(function()
	task.wait(0.05)

	UpdateResponsive()

	Tween(MainHolder, 0.5, {
		BackgroundTransparency = 0,
		Size = State.Mobile
			and UDim2.fromOffset(
				math.max(
					1,
					GetViewport().X
						- CONFIG.MobileMargin * 2
				),
				math.max(
					1,
					GetViewport().Y
						- CONFIG.MobileMargin * 2
				)
			)
			or UDim2.fromOffset(
				CONFIG.DesktopWidth,
				CONFIG.DesktopHeight
			),
	}, Enum.EasingStyle.Quint)

	Tween(OuterGlow, 0.7, {
		BackgroundTransparency = 0.96,
	})

	Tween(LogoCore, 0.5, {
		Size = UDim2.fromOffset(18, 18),
	}, Enum.EasingStyle.Back)

	Tween(StatusDot, 0.5, {
		Size = UDim2.fromOffset(15, 15),
	}, Enum.EasingStyle.Back)
end)

----------------------------------------------------------------------
-- FINAL SAFETY
----------------------------------------------------------------------

task.spawn(function()
	while not State.Destroyed do
		task.wait(3)

		if not ScreenGui.Parent then
			break
		end

		pcall(function()
			ScreenGui.DisplayOrder =
				CONFIG.DisplayOrder

			ScreenGui.Enabled = true
		end)
	end
end)

-- END OF VANZ NEXUS