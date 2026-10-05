--//==============================================================\\
--// VANZ V8 — MOBILE SOFT ROBOTIC COMMAND CENTER
--// Full Standalone Roblox Luau
--//
--// FEATURES
--// • Mobile-first responsive layout
--// • Large readable typography
--// • Large touch-friendly buttons
--// • Full-screen adaptive panel
--// • Safe header area for Minimize / Close
--// • Main GUI draggable from header
--// • Minimized VANZ logo appears at center
--// • Minimized logo is draggable
--// • Smooth / soft / living animations
--// • Dynamic accent hue
--// • Soft glow
--// • Radar animation
--// • Floating particles
--// • Multiple pages
--// • DPI / scale control
--// • Animation / glow / FX toggles
--// • High DisplayOrder + watchdog
--// • Public API
--//==============================================================\\

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
-- GLOBAL CLEANUP
--==============================================================

if _G.vanz and _G.vanz.ForceStop then
	pcall(_G.vanz.ForceStop)
end

_G.vanz = {}

--==============================================================
-- CONFIG
--==============================================================

local Config = {

	Title = "VANZ",

	Subtitle = "SOFT ROBOTIC COMMAND CENTER",

	DisplayOrder = 999999999,

	DesktopWidth = 940,

	DesktopHeight = 590,

	MobileMargin = 10,

	HeaderHeight = 88,

	SidebarWidth = 220,

	AnimationSpeed = 1,

	DefaultScale = 1,

	MinScale = 0.78,

	MaxScale = 1.05,

	EnableParticles = true,

	EnableGlow = true,

	EnableAnimations = true,

	Responsive = true,
}

_G.vanz.Config = Config

--==============================================================
-- STATE
--==============================================================

local State = {

	Destroyed = false,

	Minimized = false,

	Animations = true,

	Glow = true,

	ClickFX = true,

	Scale = Config.DefaultScale,

	Hue = 0,

	Time = 0,

	CurrentPage = "Home",

	DraggingWindow = false,

	DraggingLogo = false,
}

_G.vanz.State = State

--==============================================================
-- CONNECTION MANAGEMENT
--==============================================================

local Connections = {}
local Cleanups = {}

local function Connect(signal, callback)

	if State.Destroyed then
		return
	end

	local connection = signal:Connect(callback)

	table.insert(Connections, connection)

	return connection
end

local function Cleanup(callback)

	table.insert(Cleanups, callback)

	return callback
end

--==============================================================
-- UTILITY
--==============================================================

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

local function Corner(object, radius)

	local corner = Instance.new("UICorner")

	corner.CornerRadius = UDim.new(
		0,
		radius or 10
	)

	corner.Parent = object

	return corner
end

local function Stroke(
	object,
	color,
	transparency,
	thickness
)

	local stroke = Instance.new("UIStroke")

	stroke.Color =
		color or Color3.new(1, 1, 1)

	stroke.Transparency =
		transparency or 0

	stroke.Thickness =
		thickness or 1

	stroke.ApplyStrokeMode =
		Enum.ApplyStrokeMode.Border

	stroke.Parent = object

	return stroke
end

local function Gradient(
	object,
	color1,
	color2,
	rotation
)

	local gradient = Instance.new("UIGradient")

	gradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(
			0,
			color1
		),

		ColorSequenceKeypoint.new(
			1,
			color2
		),
	})

	gradient.Rotation =
		rotation or 0

	gradient.Parent = object

	return gradient
end

local function Tween(
	object,
	duration,
	properties,
	style,
	direction
)

	if not object
		or not object.Parent then
		return
	end

	local tween = TweenService:Create(

		object,

		TweenInfo.new(

			duration,

			style
				or Enum.EasingStyle.Quint,

			direction
				or Enum.EasingDirection.Out
		),

		properties
	)

	tween:Play()

	return tween
end

local function Clamp(
	value,
	minimum,
	maximum
)

	return math.clamp(
		value,
		minimum,
		maximum
	)
end

--==============================================================
-- COLORS
--==============================================================

local Colors = {

	Background =
		Color3.fromRGB(6, 8, 13),

	Panel =
		Color3.fromRGB(12, 16, 24),

	Panel2 =
		Color3.fromRGB(17, 22, 32),

	Panel3 =
		Color3.fromRGB(23, 29, 42),

	Panel4 =
		Color3.fromRGB(28, 35, 50),

	Border =
		Color3.fromRGB(65, 76, 96),

	Text =
		Color3.fromRGB(245, 248, 255),

	Muted =
		Color3.fromRGB(158, 169, 190),

	Soft =
		Color3.fromRGB(103, 115, 139),

	Success =
		Color3.fromRGB(103, 235, 179),

	Warning =
		Color3.fromRGB(255, 204, 110),

	Danger =
		Color3.fromRGB(255, 105, 126),

	White =
		Color3.fromRGB(255, 255, 255),
}

local function Accent(offset)

	local hue =
		(State.Hue + (offset or 0))
		% 1

	return Color3.fromHSV(
		hue,
		0.58,
		1
	)
end

local function AccentSoft(offset)

	local hue =
		(State.Hue + (offset or 0))
		% 1

	return Color3.fromHSV(
		hue,
		0.25,
		1
	)
end

--==============================================================
-- SCREEN GUI
--==============================================================

local ScreenGui = New(
	"ScreenGui",
	{
		Name = "VANZ_MOBILE_SOFT_GUI",

		Enabled = true,

		DisplayOrder =
			Config.DisplayOrder,

		IgnoreGuiInset = true,

		ResetOnSpawn = false,

		ZIndexBehavior =
			Enum.ZIndexBehavior.Global,
	},
	PlayerGui
)

pcall(function()
	ScreenGui.ScreenInsets =
		Enum.ScreenInsets.None
end)

pcall(function()
	ScreenGui.OnTopOfCoreBlur = true
end)

_G.vanz.Gui = ScreenGui

--==============================================================
-- SCALE
--==============================================================

local UIScale = New(
	"UIScale",
	{
		Scale = Config.DefaultScale,
	},
	ScreenGui
)

--==============================================================
-- MAIN HOLDER
--==============================================================

local MainHolder = New(
	"Frame",
	{
		Name = "MainHolder",

		AnchorPoint =
			Vector2.new(0.5, 0.5),

		Position =
			UDim2.fromScale(
				0.5,
				0.5
			),

		Size =
			UDim2.fromOffset(
				Config.DesktopWidth,
				Config.DesktopHeight
			),

		BackgroundTransparency = 1,

		ZIndex = 100,
	},
	ScreenGui
)

--==============================================================
-- SHADOW
--==============================================================

local Shadow = New(
	"Frame",
	{
		Position =
			UDim2.fromOffset(
				7,
				9
			),

		Size =
			UDim2.new(
				1,
				0,
				1,
				0
			),

		BackgroundColor3 =
			Color3.new(0, 0, 0),

		BackgroundTransparency =
			0.48,

		ZIndex = 98,
	},
	MainHolder
)

Corner(
	Shadow,
	22
)

--==============================================================
-- SOFT AURA
--==============================================================

local Aura = New(
	"Frame",
	{
		Position =
			UDim2.fromOffset(
				-8,
				-8
			),

		Size =
			UDim2.new(
				1,
				16,
				1,
				16
			),

		BackgroundColor3 =
			Accent(),

		BackgroundTransparency =
			0.92,

		ZIndex = 97,
	},
	MainHolder
)

Corner(
	Aura,
	26
)

--==============================================================
-- MAIN PANEL
--==============================================================

local MainPanel = New(
	"Frame",
	{
		Name = "MainPanel",

		Size =
			UDim2.fromScale(
				1,
				1
			),

		BackgroundColor3 =
			Colors.Background,

		BackgroundTransparency =
			0.02,

		ClipsDescendants =
			true,

		ZIndex = 100,
	},
	MainHolder
)

Corner(
	MainPanel,
	20
)

local MainStroke = Stroke(
	MainPanel,
	Colors.Border,
	0.22,
	1
)

--==============================================================
-- HEADER
--==============================================================

local Header = New(
	"Frame",
	{
		Position =
			UDim2.fromOffset(
				0,
				0
			),

		Size =
			UDim2.new(
				1,
				0,
				0,
				Config.HeaderHeight
			),

		BackgroundColor3 =
			Colors.Panel,

		ZIndex = 200,
	},
	MainPanel
)

Corner(
	Header,
	20
)

-- Header lower cover
local HeaderCover = New(
	"Frame",
	{
		Position =
			UDim2.new(
				0,
				0,
				1,
				-20
			),

		Size =
			UDim2.new(
				1,
				0,
				0,
				20
			),

		BackgroundColor3 =
			Colors.Panel,

		BorderSizePixel = 0,

		ZIndex = 200,
	},
	Header
)

--==============================================================
-- HEADER SAFE AREA
--==============================================================

local HeaderDivider = New(
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
			Accent(),

		BackgroundTransparency =
			0.55,

		BorderSizePixel = 0,

		ZIndex = 230,
	},
	Header
)

--==============================================================
-- LOGO
--==============================================================

local LogoButton = New(
	"TextButton",
	{
		Name = "LogoDragArea",

		Position =
			UDim2.fromOffset(
				14,
				12
			),

		Size =
			UDim2.fromOffset(
				64,
				64
			),

		BackgroundTransparency = 1,

		Text = "",

		AutoButtonColor = false,

		ZIndex = 250,
	},
	Header
)

local LogoOuter = New(
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
			UDim2.fromOffset(
				54,
				54
			),

		BackgroundTransparency = 1,

		ZIndex = 251,
	},
	LogoButton
)

Corner(
	LogoOuter,
	50
)

local LogoOuterStroke = Stroke(
	LogoOuter,
	Accent(),
	0.18,
	1.5
)

local LogoInner = New(
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
			UDim2.fromOffset(
				38,
				38
			),

		BackgroundTransparency = 1,

		ZIndex = 252,
	},
	LogoButton
)

Corner(
	LogoInner,
	50
)

local LogoInnerStroke = Stroke(
	LogoInner,
	AccentSoft(),
	0.30,
	1
)

local LogoCore = New(
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
			UDim2.fromOffset(
				18,
				18
			),

		BackgroundColor3 =
			Accent(),

		BorderSizePixel = 0,

		ZIndex = 254,
	},
	LogoButton
)

Corner(
	LogoCore,
	50
)

Stroke(
	LogoCore,
	Colors.White,
	0.70,
	1
)

--==============================================================
-- TITLE
--==============================================================

local Title = New(
	"TextLabel",
	{
		Position =
			UDim2.fromOffset(
				88,
				13
			),

		Size =
			UDim2.new(
				1,
				-390,
				0,
				34
			),

		BackgroundTransparency = 1,

		Text =
			Config.Title,

		TextColor3 =
			Colors.Text,

		TextSize = 24,

		Font =
			Enum.Font.GothamBold,

		TextXAlignment =
			Enum.TextXAlignment.Left,

		ZIndex = 240,
	},
	Header
)

local Subtitle = New(
	"TextLabel",
	{
		Position =
			UDim2.fromOffset(
				90,
				47
			),

		Size =
			UDim2.new(
				1,
				-390,
				0,
				20
			),

		BackgroundTransparency = 1,

		Text =
			Config.Subtitle,

		TextColor3 =
			Colors.Muted,

		TextSize = 11,

		Font =
			Enum.Font.GothamMedium,

		TextXAlignment =
			Enum.TextXAlignment.Left,

		ZIndex = 240,
	},
	Header
)

--==============================================================
-- HEADER BUTTON AREA
--==============================================================

local HeaderButtons = New(
	"Frame",
	{
		AnchorPoint =
			Vector2.new(
				1,
				0
			),

		Position =
			UDim2.new(
				1,
				-12,
				0,
				12
			),

		Size =
			UDim2.fromOffset(
				172,
				64
			),

		BackgroundTransparency = 1,

		ZIndex = 300,
	},
	Header
)

--==============================================================
-- MINIMIZE BUTTON
--==============================================================

local MinimizeButton = New(
	"TextButton",
	{
		Position =
			UDim2.fromOffset(
				0,
				0
			),

		Size =
			UDim2.fromOffset(
				76,
				60
			),

		BackgroundColor3 =
			Colors.Panel3,

		BackgroundTransparency =
			0.10,

		Text = "−",

		TextColor3 =
			Colors.Text,

		TextSize = 27,

		Font =
			Enum.Font.GothamBold,

		AutoButtonColor = false,

		ZIndex = 310,
	},
	HeaderButtons
)

Corner(
	MinimizeButton,
	12
)

Stroke(
	MinimizeButton,
	Colors.Border,
	0.35,
	1
)

--==============================================================
-- CLOSE BUTTON
--==============================================================

local CloseButton = New(
	"TextButton",
	{
		Position =
			UDim2.fromOffset(
				84,
				0
			),

		Size =
			UDim2.fromOffset(
				76,
				60
			),

		BackgroundColor3 =
			Colors.Panel3,

		BackgroundTransparency =
			0.10,

		Text = "×",

		TextColor3 =
			Colors.Text,

		TextSize = 30,

		Font =
			Enum.Font.GothamBold,

		AutoButtonColor = false,

		ZIndex = 310,
	},
	HeaderButtons
)

Corner(
	CloseButton,
	12
)

Stroke(
	CloseButton,
	Colors.Border,
	0.35,
	1
)

--==============================================================
-- ONLINE STATUS
--==============================================================

local StatusPill = New(
	"Frame",
	{
		Position =
			UDim2.fromOffset(
				88,
				69
			),

		Size =
			UDim2.fromOffset(
				135,
				25
			),

		BackgroundColor3 =
			Colors.Panel3,

		BackgroundTransparency =
			0.18,

		ZIndex = 260,
	},
	Header
)

Corner(
	StatusPill,
	8
)

local StatusDot = New(
	"Frame",
	{
		Position =
			UDim2.fromOffset(
				10,
				9
			),

		Size =
			UDim2.fromOffset(
				7,
				7
			),

		BackgroundColor3 =
			Colors.Success,

		BorderSizePixel = 0,

		ZIndex = 261,
	},
	StatusPill
)

Corner(
	StatusDot,
	50
)

local StatusText = New(
	"TextLabel",
	{
		Position =
			UDim2.fromOffset(
				25,
				0
			),

		Size =
			UDim2.new(
				1,
				-28,
				1,
				0
			),

		BackgroundTransparency = 1,

		Text = "SYSTEM ONLINE",

		TextColor3 =
			Colors.Success,

		TextSize = 9,

		Font =
			Enum.Font.GothamBold,

		TextXAlignment =
			Enum.TextXAlignment.Left,

		ZIndex = 261,
	},
	StatusPill
)

--==============================================================
-- BODY
--==============================================================

local Body = New(
	"Frame",
	{
		Position =
			UDim2.fromOffset(
				0,
				Config.HeaderHeight
			),

		Size =
			UDim2.new(
				1,
				0,
				1,
				-Config.HeaderHeight
			),

		BackgroundTransparency = 1,

		ClipsDescendants = true,

		ZIndex = 120,
	},
	MainPanel
)

--==============================================================
-- SIDEBAR
--==============================================================

local Sidebar = New(
	"Frame",
	{
		Position =
			UDim2.fromOffset(
				0,
				0
			),

		Size =
			UDim2.new(
				0,
				Config.SidebarWidth,
				1,
				0
			),

		BackgroundColor3 =
			Colors.Panel,

		ZIndex = 150,
	},
	Body
)

local SidebarStroke = New(
	"Frame",
	{
		AnchorPoint =
			Vector2.new(
				1,
				0
			),

		Position =
			UDim2.new(
				1,
				0,
				0,
				0
			),

		Size =
			UDim2.fromOffset(
				1,
				999
			),

		BackgroundColor3 =
			Colors.Border,

		BackgroundTransparency =
			0.45,

		BorderSizePixel = 0,

		ZIndex = 160,
	},
	Sidebar
)

local NavigationTitle = New(
	"TextLabel",
	{
		Position =
			UDim2.fromOffset(
				20,
				18
			),

		Size =
			UDim2.new(
				1,
				-40,
				0,
				25
			),

		BackgroundTransparency = 1,

		Text = "NAVIGATION",

		TextColor3 =
			Colors.Soft,

		TextSize = 11,

		Font =
			Enum.Font.GothamBold,

		TextXAlignment =
			Enum.TextXAlignment.Left,

		ZIndex = 170,
	},
	Sidebar
)

--==============================================================
-- NAVIGATION
--==============================================================

local NavHolder = New(
	"Frame",
	{
		Position =
			UDim2.fromOffset(
				12,
				55
			),

		Size =
			UDim2.new(
				1,
				-24,
				0,
				250
			),

		BackgroundTransparency = 1,

		ZIndex = 170,
	},
	Sidebar
)

local NavLayout = Instance.new(
	"UIListLayout"
)

NavLayout.Padding =
	UDim.new(
		0,
		8
	)

NavLayout.SortOrder =
	Enum.SortOrder.LayoutOrder

NavLayout.Parent =
	NavHolder

--==============================================================
-- CONTENT
--==============================================================

local Content = New(
	"Frame",
	{
		Position =
			UDim2.fromOffset(
				Config.SidebarWidth,
				0
			),

		Size =
			UDim2.new(
				1,
				-Config.SidebarWidth,
				1,
				0
			),

		BackgroundTransparency = 1,

		ClipsDescendants = true,

		ZIndex = 180,
	},
	Body
)

--==============================================================
-- PAGE SYSTEM
--==============================================================

local Pages = {}
local NavButtons = {}

local function CreatePage(name)

	local page = New(
		"ScrollingFrame",
		{
			Name =
				name .. "Page",

			Position =
				UDim2.fromOffset(
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

			ScrollBarThickness = 3,

			ScrollBarImageColor3 =
				Accent(),

			CanvasSize =
				UDim2.new(
					0,
					0,
					0,
					0
				),

			AutomaticCanvasSize =
				Enum.AutomaticSize.Y,

			Visible = false,

			ZIndex = 190,
		},
		Content
	)

	local padding = Instance.new(
		"UIPadding"
	)

	padding.PaddingTop =
		UDim.new(
			0,
			18
		)

	padding.PaddingBottom =
		UDim.new(
			0,
			25
		)

	padding.PaddingLeft =
		UDim.new(
			0,
			18
		)

	padding.PaddingRight =
		UDim.new(
			0,
			18
		)

	padding.Parent =
		page

	Pages[name] = page

	return page
end

--==============================================================
-- HOME
--==============================================================

local HomePage =
	CreatePage("Home")

local Hero = New(
	"Frame",
	{
		Position =
			UDim2.fromOffset(
				0,
				0
			),

		Size =
			UDim2.new(
				1,
				0,
				0,
				205
			),

		BackgroundColor3 =
			Colors.Panel,

		ZIndex = 200,
	},
	HomePage
)

Corner(
	Hero,
	15
)

Stroke(
	Hero,
	Colors.Border,
	0.35,
	1
)

local HeroTitle = New(
	"TextLabel",
	{
		Position =
			UDim2.fromOffset(
				24,
				25
			),

		Size =
			UDim2.new(
				0.70,
				0,
				0,
				40
			),

		BackgroundTransparency = 1,

		Text = "WELCOME BACK",

		TextColor3 =
			Colors.Text,

		TextSize = 27,

		Font =
			Enum.Font.GothamBold,

		TextXAlignment =
			Enum.TextXAlignment.Left,

		ZIndex = 220,
	},
	Hero
)

local HeroDesc = New(
	"TextLabel",
	{
		Position =
			UDim2.fromOffset(
				26,
				70
			),

		Size =
			UDim2.new(
				0.66,
				0,
				0,
				70
			),

		BackgroundTransparency = 1,

		Text =
			"VANZ control center is ready.\nSmooth controls. Clear visuals. Soft robotic atmosphere.",

		TextColor3 =
			Colors.Muted,

		TextSize = 13,

		Font =
			Enum.Font.GothamMedium,

		TextWrapped = true,

		TextXAlignment =
			Enum.TextXAlignment.Left,

		TextYAlignment =
			Enum.TextYAlignment.Top,

		ZIndex = 220,
	},
	Hero
)

--==============================================================
-- RADAR
--==============================================================

local Radar = New(
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
				-40,
				0.5,
				0
			),

		Size =
			UDim2.fromOffset(
				135,
				135
			),

		BackgroundTransparency = 1,

		ZIndex = 220,
	},
	Hero
)

local RadarOuter = New(
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
			UDim2.fromScale(
				1,
				1
			),

		BackgroundTransparency = 1,

		ZIndex = 221,
	},
	Radar
)

Corner(
	RadarOuter,
	100
)

Stroke(
	RadarOuter,
	Accent(),
	0.45,
	1
)

local RadarInner = New(
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
			UDim2.fromScale(
				0.64,
				0.64
			),

		BackgroundTransparency = 1,

		ZIndex = 222,
	},
	Radar
)

Corner(
	RadarInner,
	100
)

Stroke(
	RadarInner,
	AccentSoft(),
	0.65,
	1
)

local RadarCore = New(
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
			UDim2.fromOffset(
				10,
				10
			),

		BackgroundColor3 =
			Accent(),

		BorderSizePixel = 0,

		ZIndex = 224,
	},
	Radar
)

Corner(
	RadarCore,
	50
)

local RadarSweep = New(
	"Frame",
	{
		AnchorPoint =
			Vector2.new(
				0.5,
				1
			),

		Position =
			UDim2.fromScale(
				0.5,
				0.5
			),

		Size =
			UDim2.fromOffset(
				2,
				66
			),

		BackgroundColor3 =
			Accent(),

		BackgroundTransparency =
			0.35,

		BorderSizePixel = 0,

		ZIndex = 223,
	},
	Radar
)

--==============================================================
-- DPI PANEL
--==============================================================

local DPIBox = New(
	"Frame",
	{
		Position =
			UDim2.fromOffset(
				0,
				220
			),

		Size =
			UDim2.new(
				1,
				0,
				0,
				170
			),

		BackgroundColor3 =
			Colors.Panel,

		ZIndex = 200,
	},
	HomePage
)

Corner(
	DPIBox,
	15
)

Stroke(
	DPIBox,
	Colors.Border,
	0.45,
	1
)

local DPITitle = New(
	"TextLabel",
	{
		Position =
			UDim2.fromOffset(
				20,
				18
			),

		Size =
			UDim2.new(
				1,
				-40,
				0,
				28
			),

		BackgroundTransparency = 1,

		Text = "DISPLAY SIZE",

		TextColor3 =
			Colors.Text,

		TextSize = 15,

		Font =
			Enum.Font.GothamBold,

		TextXAlignment =
			Enum.TextXAlignment.Left,

		ZIndex = 220,
	},
	DPIBox
)

local DPISub = New(
	"TextLabel",
	{
		Position =
			UDim2.fromOffset(
				20,
				47
			),

		Size =
			UDim2.new(
				1,
				-40,
				0,
				20
			),

		BackgroundTransparency = 1,

		Text =
			"Large enough for touch, compact enough for smaller phones.",

		TextColor3 =
			Colors.Muted,

		TextSize = 10,

		Font =
			Enum.Font.GothamMedium,

		TextXAlignment =
			Enum.TextXAlignment.Left,

		ZIndex = 220,
	},
	DPIBox
)

local DPIHolder = New(
	"Frame",
	{
		Position =
			UDim2.fromOffset(
				20,
				82
			),

		Size =
			UDim2.new(
				1,
				-40,
				0,
				60
			),

		BackgroundTransparency = 1,

		ZIndex = 220,
	},
	DPIBox
)

local DPIValues = {
	80,
	90,
	100,
}

local DPIButtons = {}

for index, value in ipairs(DPIValues) do

	local button = New(
		"TextButton",
		{
			Position =
				UDim2.new(
					(index - 1) / 3,
					6,
					0,
					0
				),

			Size =
				UDim2.new(
					1 / 3,
					-12,
					0,
					52
				),

			BackgroundColor3 =
				Colors.Panel3,

			Text =
				tostring(value) .. "%",

			TextColor3 =
				value == 100
				and Colors.Text
				or Colors.Muted,

			TextSize = 13,

			Font =
				Enum.Font.GothamBold,

			AutoButtonColor = false,

			ZIndex = 230,
		},
		DPIHolder
	)

	Corner(
		button,
		10
	)

	local stroke = Stroke(
		button,
		value == 100
			and Accent()
			or Colors.Border,
		value == 100
			and 0.25
			or 0.65,
		1
	)

	DPIButtons[value] = {
		Button = button,
		Stroke = stroke,
	}

	Connect(
		button.MouseButton1Click,
		function()

			State.Scale =
				value / 100

			UIScale.Scale =
				State.Scale

			for dpi, data
				in pairs(DPIButtons) do

				local selected =
					dpi == value

				data.Button.TextColor3 =
					selected
					and Colors.Text
					or Colors.Muted

				data.Stroke.Color =
					selected
					and Accent()
					or Colors.Border

				data.Stroke.Transparency =
					selected
					and 0.25
					or 0.65

			end

		end
	)

end

--==============================================================
-- VISUAL PAGE
--==============================================================

local VisualPage =
	CreatePage("Visuals")

local VisualTitle = New(
	"TextLabel",
	{
		Position =
			UDim2.fromOffset(
				0,
				0
			),

		Size =
			UDim2.new(
				1,
				0,
				0,
				40
			),

		BackgroundTransparency = 1,

		Text = "VISUAL SYSTEM",

		TextColor3 =
			Colors.Text,

		TextSize = 25,

		Font =
			Enum.Font.GothamBold,

		TextXAlignment =
			Enum.TextXAlignment.Left,

		ZIndex = 220,
	},
	VisualPage
)

local VisualSub = New(
	"TextLabel",
	{
		Position =
			UDim2.fromOffset(
				2,
				43
			),

		Size =
			UDim2.new(
				1,
				-4,
				0,
				35
			),

		BackgroundTransparency = 1,

		Text =
			"Customize the atmosphere and interaction behavior.",

		TextColor3 =
			Colors.Muted,

		TextSize = 12,

		Font =
			Enum.Font.GothamMedium,

		TextXAlignment =
			Enum.TextXAlignment.Left,

		ZIndex = 220,
	},
	VisualPage
)

--==============================================================
-- TOGGLE FACTORY
--==============================================================

local function CreateToggle(
	parent,
	title,
	description,
	initial,
	callback,
	y
)

	local holder = New(
		"Frame",
		{
			Position =
				UDim2.fromOffset(
					0,
					y
				),

			Size =
				UDim2.new(
					1,
					0,
					0,
					88
				),

			BackgroundColor3 =
				Colors.Panel,

			ZIndex = 210,
		},
		parent
	)

	Corner(
		holder,
		13
	)

	Stroke(
		holder,
		Colors.Border,
		0.50,
		1
	)

	local titleLabel = New(
		"TextLabel",
		{
			Position =
				UDim2.fromOffset(
					18,
					14
				),

			Size =
				UDim2.new(
					1,
					-115,
					0,
					27
				),

			BackgroundTransparency = 1,

			Text = title,

			TextColor3 =
				Colors.Text,

			TextSize = 14,

			Font =
				Enum.Font.GothamBold,

			TextXAlignment =
				Enum.TextXAlignment.Left,

			ZIndex = 230,
		},
		holder
	)

	local descriptionLabel = New(
		"TextLabel",
		{
			Position =
				UDim2.fromOffset(
					18,
					43
				),

			Size =
				UDim2.new(
					1,
					-115,
					0,
					30
				),

			BackgroundTransparency = 1,

			Text = description,

			TextColor3 =
				Colors.Muted,

			TextSize = 10,

			Font =
				Enum.Font.GothamMedium,

			TextWrapped = true,

			TextXAlignment =
				Enum.TextXAlignment.Left,

			ZIndex = 230,
		},
		holder
	)

	local button = New(
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
					-18,
					0.5,
					0
				),

			Size =
				UDim2.fromOffset(
					62,
					34
				),

			BackgroundColor3 =
				initial
				and Accent()
				or Colors.Panel3,

			Text = "",

			AutoButtonColor = false,

			ZIndex = 240,
		},
		holder
	)

	Corner(
		button,
		18
	)

	local buttonStroke =
		Stroke(
			button,
			initial
			and Accent()
			or Colors.Border,
			0.30,
			1
		)

	local knob = New(
		"Frame",
		{
			AnchorPoint =
				Vector2.new(
					0,
					0.5
				),

			Position =
				initial
				and UDim2.new(
					1,
					-29,
					0.5,
					0
				)
				or UDim2.new(
					0,
					5,
					0.5,
					0
				),

			Size =
				UDim2.fromOffset(
					24,
					24
				),

			BackgroundColor3 =
				Colors.White,

			BorderSizePixel = 0,

			ZIndex = 241,
		},
		button
	)

	Corner(
		knob,
		50
	)

	local current =
		initial

	Connect(
		button.MouseButton1Click,
		function()

			current =
				not current

			Tween(
				button,
				0.30,
				{
					BackgroundColor3 =
						current
						and Accent()
						or Colors.Panel3,
				},
				Enum.EasingStyle.Quint
			)

			Tween(
				knob,
				0.32,
				{
					Position =
						current
						and UDim2.new(
							1,
							-29,
							0.5,
							0
						)
						or UDim2.new(
							0,
							5,
							0.5,
							0
						),
				},
				Enum.EasingStyle.Quint
			)

			buttonStroke.Color =
				current
				and Accent()
				or Colors.Border

			callback(current)

		end
	)

	return holder
end

CreateToggle(
	VisualPage,
	"SOFT ANIMATIONS",
	"Smooth movement and subtle interface motion.",
	State.Animations,
	function(value)
		State.Animations = value
	end,
	88
)

CreateToggle(
	VisualPage,
	"NEON AMBIENCE",
	"Soft hue and atmospheric glow around the interface.",
	State.Glow,
	function(value)
		State.Glow = value
	end,
	184
)

CreateToggle(
	VisualPage,
	"INTERACTION FX",
	"Smooth feedback when touching or clicking controls.",
	State.ClickFX,
	function(value)
		State.ClickFX = value
	end,
	280
)

--==============================================================
-- TELEMETRY PAGE
--==============================================================

local TelemetryPage =
	CreatePage("Telemetry")

local TelemetryTitle = New(
	"TextLabel",
	{
		Position =
			UDim2.fromOffset(
				0,
				0
			),

		Size =
			UDim2.new(
				1,
				0,
				0,
				40
			),

		BackgroundTransparency = 1,

		Text = "SYSTEM TELEMETRY",

		TextColor3 =
			Colors.Text,

		TextSize = 25,

		Font =
			Enum.Font.GothamBold,

		TextXAlignment =
			Enum.TextXAlignment.Left,

		ZIndex = 220,
	},
	TelemetryPage
)

local FPSCard = New(
	"Frame",
	{
		Position =
			UDim2.fromOffset(
				0,
				65
			),

		Size =
			UDim2.new(
				0.48,
				0,
				0,
				125
			),

		BackgroundColor3 =
			Colors.Panel,

		ZIndex = 210,
	},
	TelemetryPage
)

Corner(
	FPSCard,
	14
)

Stroke(
	FPSCard,
	Colors.Border,
	0.50,
	1
)

local FPSLabel = New(
	"TextLabel",
	{
		Position =
			UDim2.fromOffset(
				18,
				15
			),

		Size =
			UDim2.new(
				1,
				-36,
				0,
				22
			),

		BackgroundTransparency = 1,

		Text = "FRAME RATE",

		TextColor3 =
			Colors.Muted,

		TextSize = 10,

		Font =
			Enum.Font.GothamBold,

		TextXAlignment =
			Enum.TextXAlignment.Left,

		ZIndex = 220,
	},
	FPSCard
)

local FPSValue = New(
	"TextLabel",
	{
		Position =
			UDim2.fromOffset(
				18,
				42
			),

		Size =
			UDim2.new(
				1,
				-36,
				0,
				55
			),

		BackgroundTransparency = 1,

		Text = "60",

		TextColor3 =
			Colors.Text,

		TextSize = 34,

		Font =
			Enum.Font.GothamBold,

		TextXAlignment =
			Enum.TextXAlignment.Left,

		ZIndex = 220,
	},
	FPSCard
)

local RuntimeCard = New(
	"Frame",
	{
		AnchorPoint =
			Vector2.new(
				1,
				0
			),

		Position =
			UDim2.new(
				1,
				0,
				0,
				65
			),

		Size =
			UDim2.new(
				0.48,
				0,
				0,
				125
			),

		BackgroundColor3 =
			Colors.Panel,

		ZIndex = 210,
	},
	TelemetryPage
)

Corner(
	RuntimeCard,
	14
)

Stroke(
	RuntimeCard,
	Colors.Border,
	0.50,
	1
)

local RuntimeLabel = New(
	"TextLabel",
	{
		Position =
			UDim2.fromOffset(
				18,
				15
			),

		Size =
			UDim2.new(
				1,
				-36,
				0,
				22
			),

		BackgroundTransparency = 1,

		Text = "RUNTIME",

		TextColor3 =
			Colors.Muted,

		TextSize = 10,

		Font =
			Enum.Font.GothamBold,

		TextXAlignment =
			Enum.TextXAlignment.Left,

		ZIndex = 220,
	},
	RuntimeCard
)

local RuntimeValue = New(
	"TextLabel",
	{
		Position =
			UDim2.fromOffset(
				18,
				42
			),

		Size =
			UDim2.new(
				1,
				-36,
				0,
				55
			),

		BackgroundTransparency = 1,

		Text = "0s",

		TextColor3 =
			Colors.Text,

		TextSize = 34,

		Font =
			Enum.Font.GothamBold,

		TextXAlignment =
			Enum.TextXAlignment.Left,

		ZIndex = 220,
	},
	RuntimeCard
)

--==============================================================
-- ABOUT PAGE
--==============================================================

local AboutPage =
	CreatePage("About")

local AboutCard = New(
	"Frame",
	{
		Position =
			UDim2.fromOffset(
				0,
				0
			),

		Size =
			UDim2.new(
				1,
				0,
				0,
				300
			),

		BackgroundColor3 =
			Colors.Panel,

		ZIndex = 210,
	},
	AboutPage
)

Corner(
	AboutCard,
	15
)

Stroke(
	AboutCard,
	Colors.Border,
	0.45,
	1
)

local AboutTitle = New(
	"TextLabel",
	{
		Position =
			UDim2.fromOffset(
				25,
				25
			),

		Size =
			UDim2.new(
				1,
				-50,
				0,
				40
			),

		BackgroundTransparency = 1,

		Text = "VANZ V8",

		TextColor3 =
			Colors.Text,

		TextSize = 29,

		Font =
			Enum.Font.GothamBold,

		TextXAlignment =
			Enum.TextXAlignment.Left,

		ZIndex = 220,
	},
	AboutCard
)

local AboutDescription = New(
	"TextLabel",
	{
		Position =
			UDim2.fromOffset(
				27,
				75
			),

		Size =
			UDim2.new(
				1,
				-54,
				0,
				120
			),

		BackgroundTransparency = 1,

		Text =
			"SOFT ROBOTIC MOBILE COMMAND CENTER\n\nLarge readable controls, touch-friendly buttons,\nresponsive sizing and smooth ambient animation.",

		TextColor3 =
			Colors.Muted,

		TextSize = 13,

		Font =
			Enum.Font.GothamMedium,

		TextWrapped = true,

		TextXAlignment =
			Enum.TextXAlignment.Left,

		TextYAlignment =
			Enum.TextYAlignment.Top,

		ZIndex = 220,
	},
	AboutCard
)

local BuildText = New(
	"TextLabel",
	{
		Position =
			UDim2.fromOffset(
				27,
				235
			),

		Size =
			UDim2.new(
				1,
				-54,
				0,
				25
			),

		BackgroundTransparency = 1,

		Text =
			"BUILD // V8.00 • MOBILE READY",

		TextColor3 =
			Accent(),

		TextSize = 10,

		Font =
			Enum.Font.Code,

		TextXAlignment =
			Enum.TextXAlignment.Left,

		ZIndex = 220,
	},
	AboutCard
)

--==============================================================
-- NAV BUTTON CREATOR
--==============================================================

local function CreateNav(
	name,
	label,
	icon,
	order
)

	local button = New(
		"TextButton",
		{
			Name =
				name .. "Button",

			LayoutOrder =
				order,

			Size =
				UDim2.new(
					1,
					0,
					0,
					52
				),

			BackgroundColor3 =
				Colors.Panel2,

			BackgroundTransparency = 1,

			Text = "",

			AutoButtonColor = false,

			ZIndex = 200,
		},
		NavHolder
	)

	Corner(
		button,
		11
	)

	local iconLabel = New(
		"TextLabel",
		{
			Position =
				UDim2.fromOffset(
					15,
					0
				),

			Size =
				UDim2.fromOffset(
					30,
					52
				),

			BackgroundTransparency = 1,

			Text = icon,

			TextColor3 =
				Colors.Muted,

			TextSize = 17,

			Font =
				Enum.Font.GothamBold,

			ZIndex = 220,
		},
		button
	)

	local textLabel = New(
		"TextLabel",
		{
			Position =
				UDim2.fromOffset(
					55,
					0
				),

			Size =
				UDim2.new(
					1,
					-65,
					1,
					0
				),

			BackgroundTransparency = 1,

			Text = label,

			TextColor3 =
				Colors.Muted,

			TextSize = 12,

			Font =
				Enum.Font.GothamBold,

			TextXAlignment =
				Enum.TextXAlignment.Left,

			ZIndex = 220,
		},
		button
	)

	local activeBar = New(
		"Frame",
		{
			Position =
				UDim2.fromOffset(
					0,
					10
				),

			Size =
				UDim2.fromOffset(
					3,
					32
				),

			BackgroundColor3 =
				Accent(),

			BackgroundTransparency =
				1,

			BorderSizePixel = 0,

			ZIndex = 225,
		},
		button
	)

	Corner(
		activeBar,
		3
	)

	local function SetActive(active)

		Tween(
			button,
			0.25,
			{
				BackgroundTransparency =
					active
					and 0.08
					or 1,
			},
			Enum.EasingStyle.Sine
		)

		Tween(
			activeBar,
			0.25,
			{
				BackgroundTransparency =
					active
					and 0
					or 1,
			},
			Enum.EasingStyle.Sine
		)

		iconLabel.TextColor3 =
			active
			and Colors.Text
			or Colors.Muted

		textLabel.TextColor3 =
			active
			and Colors.Text
			or Colors.Muted
	end

	NavButtons[name] = {
		Button = button,
		SetActive = SetActive,
	}

	Connect(
		button.MouseEnter,
		function()

			if not State.ClickFX
				or State.CurrentPage == name then
				return
			end

			Tween(
				button,
				0.18,
				{
					BackgroundTransparency =
						0.72,
				},
				Enum.EasingStyle.Sine
			)

		end
	)

	Connect(
		button.MouseLeave,
		function()

			if State.CurrentPage ~= name then

				Tween(
					button,
					0.18,
					{
						BackgroundTransparency =
							1,
					},
					Enum.EasingStyle.Sine
				)

			end

		end
	)

	Connect(
		button.MouseButton1Click,
		function()

			if State.CurrentPage == name then
				return
			end

			State.CurrentPage = name

			for pageName, page
				in pairs(Pages) do

				if pageName == name then

					page.Visible = true

					page.Position =
						UDim2.new(
							0,
							20,
							0,
							0
						)

					Tween(
						page,
						0.35,
						{
							Position =
								UDim2.fromOffset(
									0,
									0
								),
						},
						Enum.EasingStyle.Quint
					)

				else

					page.Visible = false

				end

			end

			for navName, nav
				in pairs(NavButtons) do

				nav.SetActive(
					navName == name
				)

			end

		end
	)

end

CreateNav(
	"Home",
	"OVERVIEW",
	"◈",
	1
)

CreateNav(
	"Visuals",
	"VISUAL SYSTEM",
	"✦",
	2
)

CreateNav(
	"Telemetry",
	"TELEMETRY",
	"⌁",
	3
)

CreateNav(
	"About",
	"ABOUT VANZ",
	"◇",
	4
)

HomePage.Visible = true

NavButtons.Home.SetActive(true)

--==============================================================
-- SIDEBAR STATUS
--==============================================================

local SidebarStatus = New(
	"Frame",
	{
		AnchorPoint =
			Vector2.new(
				0,
				1
			),

		Position =
			UDim2.new(
				0,
				12,
				1,
				-14
			),

		Size =
			UDim2.new(
				1,
				-24,
				0,
				90
			),

		BackgroundColor3 =
			Colors.Panel2,

		ZIndex = 210,
	},
	Sidebar
)

Corner(
	SidebarStatus,
	12
)

Stroke(
	SidebarStatus,
	Colors.Border,
	0.60,
	1
)

local SidebarStatusTitle = New(
	"TextLabel",
	{
		Position =
			UDim2.fromOffset(
				13,
				11
			),

		Size =
			UDim2.new(
				1,
				-26,
				0,
				20
			),

		BackgroundTransparency = 1,

		Text = "CORE STATUS",

		TextColor3 =
			Colors.Soft,

		TextSize = 9,

		Font =
			Enum.Font.GothamBold,

		TextXAlignment =
			Enum.TextXAlignment.Left,

		ZIndex = 220,
	},
	SidebarStatus
)

local SidebarStatusValue = New(
	"TextLabel",
	{
		Position =
			UDim2.fromOffset(
				13,
				31
			),

		Size =
			UDim2.new(
				1,
				-26,
				0,
				20
			),

		BackgroundTransparency = 1,

		Text = "STABLE / ONLINE",

		TextColor3 =
			Colors.Success,

		TextSize = 10,

		Font =
			Enum.Font.GothamBold,

		TextXAlignment =
			Enum.TextXAlignment.Left,

		ZIndex = 220,
	},
	SidebarStatus
)

--==============================================================
-- MINIMIZED LOGO
--==============================================================

local MiniLogo = New(
	"TextButton",
	{
		Name = "VANZ_Minimized_Logo",

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
			UDim2.fromOffset(
				92,
				92
			),

		BackgroundColor3 =
			Colors.Panel,

		BackgroundTransparency =
			0.04,

		Text = "V",

		TextColor3 =
			Colors.Text,

		TextSize = 34,

		Font =
			Enum.Font.GothamBold,

		AutoButtonColor = false,

		Visible = false,

		ZIndex = 1000,
	},
	ScreenGui
)

Corner(
	MiniLogo,
	50
)

local MiniStroke = Stroke(
	MiniLogo,
	Accent(),
	0.12,
	2
)

local MiniGlow = New(
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
				18,
				1,
				18
			),

		BackgroundColor3 =
			Accent(),

		BackgroundTransparency =
			0.93,

		ZIndex = 999,
	},
	ScreenGui
)

Corner(
	MiniGlow,
	60
)

MiniGlow.Visible = false

local MiniScale = New(
	"UIScale",
	{
		Scale = 1,
	},
	MiniLogo
)

--==============================================================
-- DRAG MAIN WINDOW
--==============================================================

local WindowDragging = false
local WindowDragStart
local WindowStartPosition

Connect(
	Header.InputBegan,
	function(input)

		if input.UserInputType ==
			Enum.UserInputType.MouseButton1
			or input.UserInputType ==
			Enum.UserInputType.Touch then

			WindowDragging = true

			State.DraggingWindow = true

			WindowDragStart =
				input.Position

			WindowStartPosition =
				MainHolder.Position

		end

	end
)

Connect(
	UserInputService.InputChanged,
	function(input)

		if not WindowDragging then
			return
		end

		if input.UserInputType ~=
			Enum.UserInputType.MouseMovement
			and input.UserInputType ~=
			Enum.UserInputType.Touch then

			return
		end

		local delta =
			input.Position
			- WindowDragStart

		local camera =
			workspace.CurrentCamera

		if not camera then
			return
		end

		local viewport =
			camera.ViewportSize

		local x =
			delta.X
			/ viewport.X

		local y =
			delta.Y
			/ viewport.Y

		MainHolder.Position =
			UDim2.new(
				WindowStartPosition.X.Scale + x,
				WindowStartPosition.X.Offset,
				WindowStartPosition.Y.Scale + y,
				WindowStartPosition.Y.Offset
			)

	end
)

Connect(
	UserInputService.InputEnded,
	function(input)

		if input.UserInputType ==
			Enum.UserInputType.MouseButton1
			or input.UserInputType ==
			Enum.UserInputType.Touch then

			WindowDragging = false

			State.DraggingWindow = false

		end

	end
)

--==============================================================
-- DRAG MINIMIZED LOGO
--==============================================================

local LogoDragging = false
local LogoDragStart
local LogoStartPosition

Connect(
	MiniLogo.InputBegan,
	function(input)

		if input.UserInputType ==
			Enum.UserInputType.MouseButton1
			or input.UserInputType ==
			Enum.UserInputType.Touch then

			LogoDragging = true

			State.DraggingLogo = true

			LogoDragStart =
				input.Position

			LogoStartPosition =
				MiniLogo.Position

		end

	end
)

Connect(
	UserInputService.InputChanged,
	function(input)

		if not LogoDragging then
			return
		end

		if input.UserInputType ~=
			Enum.UserInputType.MouseMovement
			and input.UserInputType ~=
			Enum.UserInputType.Touch then

			return
		end

		local camera =
			workspace.CurrentCamera

		if not camera then
			return
		end

		local viewport =
			camera.ViewportSize

		local delta =
			input.Position
			- LogoDragStart

		local x =
			delta.X
			/ viewport.X

		local y =
			delta.Y
			/ viewport.Y

		MiniLogo.Position =
			UDim2.new(
				LogoStartPosition.X.Scale + x,
				LogoStartPosition.X.Offset,
				LogoStartPosition.Y.Scale + y,
				LogoStartPosition.Y.Offset
			)

		MiniGlow.Position =
			MiniLogo.Position

	end
)

Connect(
	UserInputService.InputEnded,
	function(input)

		if input.UserInputType ==
			Enum.UserInputType.MouseButton1
			or input.UserInputType ==
			Enum.UserInputType.Touch then

			LogoDragging = false

			State.DraggingLogo = false

		end

	end
)

--==============================================================
-- MINIMIZE
--==============================================================

local function Minimize()

	if State.Minimized
		or State.Destroyed then

		return
	end

	State.Minimized = true

	Tween(
		MainHolder,
		0.42,
		{
			Size =
				UDim2.fromOffset(
					180,
					120
				),

			Position =
				UDim2.fromScale(
					0.5,
					0.5
				),
		},
		Enum.EasingStyle.Quint
	)

	task.delay(
		0.28,
		function()

			if State.Destroyed then
				return
			end

			MainHolder.Visible = false

			-- Always spawn minimized logo at center
			MiniLogo.Position =
				UDim2.fromScale(
					0.5,
					0.5
				)

			MiniGlow.Position =
				MiniLogo.Position

			MiniLogo.Visible = true

			MiniGlow.Visible = true

			MiniScale.Scale = 0.75

			Tween(
				MiniScale,
				0.40,
				{
					Scale = 1,
				},
				Enum.EasingStyle.Back
			)

		end
	)
end

Connect(
	MinimizeButton.MouseButton1Click,
	Minimize
)

--==============================================================
-- RESTORE FROM MINI LOGO
--==============================================================

local MiniPressStart

Connect(
	MiniLogo.MouseButton1Click,
	function()

		if State.DraggingLogo then
			return
		end

		State.Minimized = false

		MiniLogo.Visible = false
		MiniGlow.Visible = false

		MainHolder.Visible = true

		MainHolder.Position =
			UDim2.fromScale(
				0.5,
				0.52
			)

		MainHolder.Size =
			UDim2.fromOffset(
				700,
				430
			)

		Tween(
			MainHolder,
			0.48,
			{
				Position =
					UDim2.fromScale(
						0.5,
						0.5
					),
			},
			Enum.EasingStyle.Quint
		)

	end
)

--==============================================================
-- CLOSE / FORCE STOP
--==============================================================

local function ForceStop()

	if State.Destroyed then
		return
	end

	State.Destroyed = true

	for _, connection
		in ipairs(Connections) do

		pcall(function()
			connection:Disconnect()
		end)

	end

	table.clear(Connections)

	for _, cleanup
		in ipairs(Cleanups) do

		pcall(cleanup)

	end

	table.clear(Cleanups)

	if ScreenGui then
		ScreenGui:Destroy()
	end

end

_G.vanz.ForceStop =
	ForceStop

Connect(
	CloseButton.MouseButton1Click,
	ForceStop
)

--==============================================================
-- BUTTON HOVER / TOUCH FEEDBACK
--==============================================================

local function SetupHeaderButton(button)

	local originalColor =
		button.BackgroundColor3

	Connect(
		button.MouseEnter,
		function()

			if not State.ClickFX then
				return
			end

			Tween(
				button,
				0.20,
				{
					BackgroundColor3 =
						AccentSoft(),
				},
				Enum.EasingStyle.Sine
			)

		end
	)

	Connect(
		button.MouseLeave,
		function()

			Tween(
				button,
				0.20,
				{
					BackgroundColor3 =
						originalColor,
				},
				Enum.EasingStyle.Sine
			)

		end
	)

end

SetupHeaderButton(
	MinimizeButton
)

SetupHeaderButton(
	CloseButton
)

--==============================================================
-- RESPONSIVE LAYOUT
--==============================================================

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
		viewport.X

	local height =
		viewport.Y

	--==========================================================
	-- MOBILE
	--==========================================================

	if width <= 800 then

		Sidebar.Visible = false

		Content.Position =
			UDim2.fromOffset(
				0,
				0
			)

		Content.Size =
			UDim2.fromScale(
				1,
				1
			)

		Title.Size =
			UDim2.new(
				1,
				-350,
				0,
				34
			)

		Subtitle.Visible = false

		StatusPill.Visible = false

		-- More compact header controls
		HeaderButtons.Position =
			UDim2.new(
				1,
				-8,
				0,
				10
			)

		HeaderButtons.Size =
			UDim2.fromOffset(
				154,
				64
			)

		MinimizeButton.Size =
			UDim2.fromOffset(
				68,
				60
			)

		CloseButton.Position =
			UDim2.fromOffset(
				76,
				0
			)

		CloseButton.Size =
			UDim2.fromOffset(
				68,
				60
			)

		Title.Position =
			UDim2.fromOffset(
				80,
				15
			)

		-- Header remains safe
		-- Logo left, buttons right

		local availableWidth =
			width
			- (
				Config.MobileMargin
				* 2
			)

		local availableHeight =
			height
			- (
				Config.MobileMargin
				* 2
			)

		MainHolder.Size =
			UDim2.fromOffset(
				math.max(
					300,
					availableWidth
				),

				math.max(
					340,
					availableHeight
				)
			)

		-- Larger touch targets
		HeroTitle.TextSize = 25

		HeroDesc.TextSize = 13

	else

	--==========================================================
	-- DESKTOP
	--==========================================================

		Sidebar.Visible = true

		Content.Position =
			UDim2.fromOffset(
				Config.SidebarWidth,
				0
			)

		Content.Size =
			UDim2.new(
				1,
				-Config.SidebarWidth,
				1,
				0
			)

		Subtitle.Visible = true
		StatusPill.Visible = true

		MainHolder.Size =
			UDim2.fromOffset(
				Config.DesktopWidth,
				Config.DesktopHeight
			)

		Title.Position =
			UDim2.fromOffset(
				88,
				13
			)

		HeaderButtons.Size =
			UDim2.fromOffset(
				172,
				64
			)

		MinimizeButton.Size =
			UDim2.fromOffset(
				76,
				60
			)

		CloseButton.Position =
			UDim2.fromOffset(
				84,
				0
			)

		CloseButton.Size =
			UDim2.fromOffset(
				76,
				60
			)

	end

end

if workspace.CurrentCamera then

	Connect(
		workspace.CurrentCamera:GetPropertyChangedSignal(
			"ViewportSize"
		),
		UpdateResponsive
	)

end

UpdateResponsive()

--==============================================================
-- ANIMATION ENGINE
--==============================================================

local FPS = 60
local FPSCounter = 0
local FPSTime = 0

Connect(
	RunService.RenderStepped,
	function(deltaTime)

		if State.Destroyed then
			return
		end

		State.Time += deltaTime

		FPSCounter += 1
		FPSTime += deltaTime

		if FPSTime >= 0.5 then

			FPS =
				math.floor(
					FPSCounter
					/ FPSTime
				)

			FPSCounter = 0
			FPSTime = 0

		end

		--======================================================
		-- TOPMOST WATCHDOG
		--======================================================

		if ScreenGui.Parent ~=
			PlayerGui then

			ScreenGui.Parent =
				PlayerGui

		end

		if ScreenGui.DisplayOrder ~=
			Config.DisplayOrder then

			ScreenGui.DisplayOrder =
				Config.DisplayOrder

		end

		--======================================================
		-- ANIMATION
		--======================================================

		if State.Animations then

			State.Hue =
				(
					State.Hue
					+ deltaTime
						* 0.012
				)
				% 1

			local primary =
				Accent()

			local secondary =
				AccentSoft(
					0.08
				)

			-- Main border
			MainStroke.Color =
				primary

			-- Logo
			LogoOuter.Rotation =
				LogoOuter.Rotation
				+ deltaTime * 4

			LogoInner.Rotation =
				LogoInner.Rotation
				- deltaTime * 6

			LogoCore.BackgroundColor3 =
				primary

			LogoOuterStroke.Color =
				primary

			LogoInnerStroke.Color =
				secondary

			-- Logo breathing
			local breathe =
				1
				+ math.sin(
					State.Time * 1.35
				)
				* 0.06

			LogoCore.Size =
				UDim2.fromOffset(
					18 * breathe,
					18 * breathe
				)

			-- Radar
			RadarOuter.Rotation =
				RadarOuter.Rotation
				+ deltaTime * 2.5

			RadarInner.Rotation =
				RadarInner.Rotation
				- deltaTime * 3.5

			RadarSweep.Rotation =
				RadarSweep.Rotation
				+ deltaTime * 28

			RadarCore.BackgroundColor3 =
				primary

			-- Glow
			if State.Glow then

				local pulse =
					0.915
					+ math.sin(
						State.Time * 1.2
					)
					* 0.025

				Aura.BackgroundTransparency =
					pulse

				MiniGlow.BackgroundTransparency =
					0.92
					+ math.sin(
						State.Time * 1.5
					)
					* 0.025

				MiniStroke.Color =
					primary

			else

				Aura.BackgroundTransparency =
					1

				MiniGlow.BackgroundTransparency =
					1

			end

			-- Status pulse
			StatusDot.BackgroundTransparency =
				0.20
				+ math.sin(
					State.Time * 2
				)
				* 0.18

			-- Header line
			HeaderDivider.BackgroundColor3 =
				primary

			-- Build accent
			BuildText.TextColor3 =
				primary

		end

		--======================================================
		-- TELEMETRY
		--======================================================

		RuntimeValue.Text =
			string.format(
				"%ds",
				math.floor(
					State.Time
				)
			)

		FPSValue.Text =
			tostring(
				math.clamp(
					FPS,
					1,
					240
				)
			)

	end
)

--==============================================================
-- STARTUP
--==============================================================

MainHolder.Visible = true

MainHolder.Position =
	UDim2.fromScale(
		0.5,
		0.53
	)

MainHolder.Size =
	UDim2.fromOffset(
		Config.DesktopWidth * 0.94,
		Config.DesktopHeight * 0.94
	)

Tween(
	MainHolder,
	0.55,
	{
		Position =
			UDim2.fromScale(
				0.5,
				0.5
			),

		Size =
			UDim2.fromOffset(
				Config.DesktopWidth,
				Config.DesktopHeight
			),
	},
	Enum.EasingStyle.Quint
)

--==============================================================
-- PUBLIC API
--==============================================================

function _G.vanz.Open()

	if State.Destroyed then
		return
	end

	State.Minimized = false

	MiniLogo.Visible = false
	MiniGlow.Visible = false

	MainHolder.Visible = true

	UpdateResponsive()

	MainHolder.Position =
		UDim2.fromScale(
			0.5,
			0.52
		)

	Tween(
		MainHolder,
		0.45,
		{
			Position =
				UDim2.fromScale(
					0.5,
					0.5
				),
		},
		Enum.EasingStyle.Quint
	)

end

function _G.vanz.Hide()

	if State.Destroyed then
		return
	end

	Tween(
		MainHolder,
		0.35,
		{
			Position =
				UDim2.fromScale(
					0.5,
					0.53
				),
		},
		Enum.EasingStyle.Quint
	)

	task.delay(
		0.30,
		function()

			if not State.Destroyed then

				MainHolder.Visible =
					false

			end

		end
	)

end

function _G.vanz.SetScale(value)

	if State.Destroyed then
		return
	end

	value =
		Clamp(
			tonumber(value)
				or State.Scale,
			Config.MinScale,
			Config.MaxScale
		)

	State.Scale =
		value

	Tween(
		UIScale,
		0.30,
		{
			Scale = value,
		},
		Enum.EasingStyle.Quint
	)

end

function _G.vanz.GetState()

	return State
end

--==============================================================
-- FINAL REFERENCES
--==============================================================

_G.vanz.Gui =
	ScreenGui

_G.vanz.ForceStop =
	ForceStop

_G.vanz.Open =
	_G.vanz.Open

_G.vanz.Hide =
	_G.vanz.Hide

_G.vanz.SetScale =
	_G.vanz.SetScale

_G.vanz.GetState =
	_G.vanz.GetState

--==============================================================
-- DONE
--==============================================================

print(
	"[VANZ V8] Mobile Soft Robotic Command Center ONLINE"
)

print(
	"[VANZ V8] Touch-friendly layout enabled"
)

print(
	"[VANZ V8] Draggable window + draggable minimized logo enabled"
)

--//==============================================================\\
--// END VANZ V8
--//==============================================================\\