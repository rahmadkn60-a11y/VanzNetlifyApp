--//==============================================================\\
--// VANZ V9 — MOBILE-FIRST ROBOTIC COMMAND CENTER
--//==============================================================\\
--//
--// MOBILE DESIGN:
--// • Safe header zone
--// • Minimize / Close NEVER share space with title
--// • Responsive full-screen panel
--// • Large touch targets
--// • Main window draggable
--// • Minimized logo draggable
--// • Minimized logo starts at center
--// • Smooth soft animations
--// • No crowded mobile header
--// • Sidebar automatically converts to bottom navigation
--// • Large readable content
--// • High DisplayOrder watchdog
--//
--//==============================================================\\

--==============================================================
-- SERVICES
--==============================================================

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

--==============================================================
-- CLEAN OLD VANZ
--==============================================================

if _G.vanz and _G.vanz.ForceStop then
	pcall(_G.vanz.ForceStop)
end

for _, name in ipairs({
	"VANZ_ROBOTIC_GUI",
	"VANZ_PREMIUM_GUI",
	"VANZ_SOFT_ROBOTIC_GUI",
	"VANZ_MOBILE_SOFT_GUI",
	"VANZ_V9_GUI",
}) do
	local old = PlayerGui:FindFirstChild(name)

	if old then
		pcall(function()
			old:Destroy()
		end)
	end
end

--==============================================================
-- GLOBAL
--==============================================================

_G.vanz = {}

--==============================================================
-- CONFIG
--==============================================================

local Config = {
	Title = "VANZ",
	Subtitle = "ROBOTIC COMMAND CENTER",

	DisplayOrder = 999999999,

	DesktopWidth = 920,
	DesktopHeight = 570,

	DesktopScale = 0.92,

	MobileMargin = 8,

	HeaderHeightDesktop = 82,
	HeaderHeightMobile = 82,

	AnimationSpeed = 1,

	MinScale = 0.75,
	MaxScale = 1.05,

	EnableAnimations = true,
	EnableGlow = true,
	EnableParticles = true,
	EnableInteractionFX = true,
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

	InteractionFX = true,

	Scale = Config.DesktopScale,

	Hue = 0,

	Time = 0,

	CurrentPage = "Home",

	IsMobile = false,

	DraggingWindow = false,

	DraggingMiniLogo = false,
}

_G.vanz.State = State

--==============================================================
-- CONNECTIONS
--==============================================================

local Connections = {}

local function Connect(signal, callback)
	if State.Destroyed then
		return
	end

	local connection = signal:Connect(callback)
	table.insert(Connections, connection)

	return connection
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

	object.Parent = parent

	return object
end

local function Corner(object, radius)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, radius)
	corner.Parent = object

	return corner
end

local function Stroke(object, color, transparency, thickness)
	local stroke = Instance.new("UIStroke")

	stroke.Color = color
	stroke.Transparency = transparency or 0
	stroke.Thickness = thickness or 1

	stroke.ApplyStrokeMode =
		Enum.ApplyStrokeMode.Border

	stroke.Parent = object

	return stroke
end

local function Tween(object, duration, properties, style, direction)
	if not object or not object.Parent then
		return
	end

	local tween = TweenService:Create(
		object,
		TweenInfo.new(
			duration,
			style or Enum.EasingStyle.Quint,
			direction or Enum.EasingDirection.Out
		),
		properties
	)

	tween:Play()

	return tween
end

local function Clamp(value, minimum, maximum)
	return math.clamp(value, minimum, maximum)
end

--==============================================================
-- COLORS
--==============================================================

local Colors = {
	Background = Color3.fromRGB(6, 8, 13),

	Panel = Color3.fromRGB(12, 16, 24),

	Panel2 = Color3.fromRGB(17, 22, 32),

	Panel3 = Color3.fromRGB(24, 30, 43),

	Border = Color3.fromRGB(71, 82, 103),

	Text = Color3.fromRGB(244, 247, 255),

	Muted = Color3.fromRGB(157, 169, 191),

	Soft = Color3.fromRGB(101, 114, 139),

	Success = Color3.fromRGB(103, 235, 179),

	Warning = Color3.fromRGB(255, 203, 110),

	Danger = Color3.fromRGB(255, 105, 125),

	White = Color3.fromRGB(255, 255, 255),
}

local function Accent(offset)
	local hue =
		(State.Hue + (offset or 0)) % 1

	return Color3.fromHSV(
		hue,
		0.58,
		1
	)
end

local function AccentSoft(offset)
	local hue =
		(State.Hue + (offset or 0)) % 1

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
		Name = "VANZ_V9_GUI",

		Enabled = true,

		DisplayOrder = Config.DisplayOrder,

		IgnoreGuiInset = true,

		ResetOnSpawn = false,

		ZIndexBehavior = Enum.ZIndexBehavior.Global,
	},
	PlayerGui
)

pcall(function()
	ScreenGui.ScreenInsets = Enum.ScreenInsets.None
end)

pcall(function()
	ScreenGui.OnTopOfCoreBlur = true
end)

_G.vanz.Gui = ScreenGui

--==============================================================
-- MAIN SCALE
--==============================================================

local MainScale = New(
	"UIScale",
	{
		Scale = Config.DesktopScale,
	},
	ScreenGui
)

--==============================================================
-- MAIN WINDOW
--==============================================================

local MainHolder = New(
	"Frame",
	{
		Name = "MainHolder",

		AnchorPoint = Vector2.new(0.5, 0.5),

		Position = UDim2.fromScale(0.5, 0.5),

		Size = UDim2.fromOffset(
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
		Position = UDim2.fromOffset(7, 9),

		Size = UDim2.fromScale(1, 1),

		BackgroundColor3 = Color3.new(0, 0, 0),

		BackgroundTransparency = 0.48,

		ZIndex = 95,
	},
	MainHolder
)

Corner(Shadow, 22)

--==============================================================
-- AURA
--==============================================================

local Aura = New(
	"Frame",
	{
		Position = UDim2.fromOffset(-7, -7),

		Size = UDim2.new(1, 14, 1, 14),

		BackgroundColor3 = Accent(),

		BackgroundTransparency = 0.94,

		ZIndex = 96,
	},
	MainHolder
)

Corner(Aura, 25)

--==============================================================
-- PANEL
--==============================================================

local MainPanel = New(
	"Frame",
	{
		Name = "MainPanel",

		Size = UDim2.fromScale(1, 1),

		BackgroundColor3 = Colors.Background,

		BorderSizePixel = 0,

		ClipsDescendants = true,

		ZIndex = 100,
	},
	MainHolder
)

Corner(MainPanel, 19)

local MainStroke = Stroke(
	MainPanel,
	Colors.Border,
	0.28,
	1
)

--==============================================================
-- HEADER
--==============================================================

local Header = New(
	"Frame",
	{
		Name = "SafeHeader",

		Position = UDim2.fromOffset(0, 0),

		Size = UDim2.new(
			1,
			0,
			0,
			Config.HeaderHeightDesktop
		),

		BackgroundColor3 = Colors.Panel,

		BorderSizePixel = 0,

		ZIndex = 200,
	},
	MainPanel
)

Corner(Header, 19)

-- bottom cover so rounded header does not affect body
local HeaderBottom = New(
	"Frame",
	{
		Position = UDim2.new(0, 0, 1, -18),

		Size = UDim2.new(1, 0, 0, 18),

		BackgroundColor3 = Colors.Panel,

		BorderSizePixel = 0,

		ZIndex = 200,
	},
	Header
)

--==============================================================
-- HEADER DIVIDER
--==============================================================

local HeaderLine = New(
	"Frame",
	{
		Position = UDim2.new(0, 0, 1, -1),

		Size = UDim2.new(1, 0, 0, 1),

		BackgroundColor3 = Accent(),

		BackgroundTransparency = 0.5,

		BorderSizePixel = 0,

		ZIndex = 260,
	},
	Header
)

--==============================================================
-- HEADER DRAG AREA
-- IMPORTANT:
-- This NEVER covers the right-side controls.
--==============================================================

local HeaderDragArea = New(
	"TextButton",
	{
		Name = "HeaderDragArea",

		Position = UDim2.fromOffset(0, 0),

		Size = UDim2.new(
			1,
			-220,
			1,
			0
		),

		BackgroundTransparency = 1,

		Text = "",

		AutoButtonColor = false,

		ZIndex = 205,
	},
	Header
)

--==============================================================
-- LOGO
--==============================================================

local HeaderLogo = New(
	"Frame",
	{
		Position = UDim2.fromOffset(13, 12),

		Size = UDim2.fromOffset(56, 56),

		BackgroundTransparency = 1,

		ZIndex = 230,
	},
	Header
)

local LogoRing1 = New(
	"Frame",
	{
		AnchorPoint = Vector2.new(0.5, 0.5),

		Position = UDim2.fromScale(0.5, 0.5),

		Size = UDim2.fromOffset(52, 52),

		BackgroundTransparency = 1,

		ZIndex = 231,
	},
	HeaderLogo
)

Corner(LogoRing1, 50)

local LogoStroke1 = Stroke(
	LogoRing1,
	Accent(),
	0.18,
	1.5
)

local LogoRing2 = New(
	"Frame",
	{
		AnchorPoint = Vector2.new(0.5, 0.5),

		Position = UDim2.fromScale(0.5, 0.5),

		Size = UDim2.fromOffset(38, 38),

		BackgroundTransparency = 1,

		ZIndex = 232,
	},
	HeaderLogo
)

Corner(LogoRing2, 50)

local LogoStroke2 = Stroke(
	LogoRing2,
	AccentSoft(),
	0.25,
	1
)

local LogoCore = New(
	"Frame",
	{
		AnchorPoint = Vector2.new(0.5, 0.5),

		Position = UDim2.fromScale(0.5, 0.5),

		Size = UDim2.fromOffset(17, 17),

		BackgroundColor3 = Accent(),

		BorderSizePixel = 0,

		ZIndex = 234,
	},
	HeaderLogo
)

Corner(LogoCore, 50)

--==============================================================
-- TITLE ZONE
-- This is deliberately bounded.
--==============================================================

local TitleZone = New(
	"Frame",
	{
		Position = UDim2.fromOffset(78, 9),

		Size = UDim2.new(
			1,
			-310,
			1,
			-18
		),

		BackgroundTransparency = 1,

		ClipsDescendants = true,

		ZIndex = 210,
	},
	Header
)

local Title = New(
	"TextLabel",
	{
		Position = UDim2.fromOffset(0, 6),

		Size = UDim2.new(
			1,
			0,
			0,
			30
		),

		BackgroundTransparency = 1,

		Text = Config.Title,

		TextColor3 = Colors.Text,

		TextSize = 24,

		Font = Enum.Font.GothamBold,

		TextTruncate = Enum.TextTruncate.AtEnd,

		TextXAlignment = Enum.TextXAlignment.Left,

		ZIndex = 220,
	},
	TitleZone
)

local Subtitle = New(
	"TextLabel",
	{
		Position = UDim2.fromOffset(1, 39),

		Size = UDim2.new(
			1,
			0,
			0,
			20
		),

		BackgroundTransparency = 1,

		Text = Config.Subtitle,

		TextColor3 = Colors.Muted,

		TextSize = 10,

		Font = Enum.Font.GothamMedium,

		TextTruncate = Enum.TextTruncate.AtEnd,

		TextXAlignment = Enum.TextXAlignment.Left,

		ZIndex = 220,
	},
	TitleZone
)

--==============================================================
-- HEADER CONTROL ZONE
-- FIXED, NEVER SHARED WITH TITLE
--==============================================================

local HeaderControls = New(
	"Frame",
	{
		Name = "HeaderControls",

		AnchorPoint = Vector2.new(1, 0),

		Position = UDim2.new(
			1,
			-8,
			0,
			8
		),

		Size = UDim2.fromOffset(
			194,
			66
		),

		BackgroundTransparency = 1,

		ZIndex = 300,
	},
	Header
)

--==============================================================
-- MINIMIZE
--==============================================================

local MinimizeButton = New(
	"TextButton",
	{
		Position = UDim2.fromOffset(0, 0),

		Size = UDim2.fromOffset(91, 62),

		BackgroundColor3 = Colors.Panel3,

		BackgroundTransparency = 0.05,

		Text = "MIN",

		TextColor3 = Colors.Text,

		TextSize = 13,

		Font = Enum.Font.GothamBold,

		AutoButtonColor = false,

		ZIndex = 310,
	},
	HeaderControls
)

Corner(MinimizeButton, 13)

local MinimizeStroke = Stroke(
	MinimizeButton,
	Colors.Border,
	0.35,
	1
)

--==============================================================
-- CLOSE
--==============================================================

local CloseButton = New(
	"TextButton",
	{
		Position = UDim2.fromOffset(101, 0),

		Size = UDim2.fromOffset(91, 62),

		BackgroundColor3 = Colors.Panel3,

		BackgroundTransparency = 0.05,

		Text = "CLOSE",

		TextColor3 = Colors.Text,

		TextSize = 13,

		Font = Enum.Font.GothamBold,

		AutoButtonColor = false,

		ZIndex = 310,
	},
	HeaderControls
)

Corner(CloseButton, 13)

local CloseStroke = Stroke(
	CloseButton,
	Colors.Border,
	0.35,
	1
)

--==============================================================
-- BODY
--==============================================================

local Body = New(
	"Frame",
	{
		Name = "Body",

		Position = UDim2.fromOffset(
			0,
			Config.HeaderHeightDesktop
		),

		Size = UDim2.new(
			1,
			0,
			1,
			-Config.HeaderHeightDesktop
		),

		BackgroundTransparency = 1,

		ClipsDescendants = true,

		ZIndex = 120,
	},
	MainPanel
)

--==============================================================
-- DESKTOP SIDEBAR
--==============================================================

local Sidebar = New(
	"Frame",
	{
		Name = "DesktopSidebar",

		Position = UDim2.fromOffset(0, 0),

		Size = UDim2.new(
			0,
			210,
			1,
			0
		),

		BackgroundColor3 = Colors.Panel,

		BorderSizePixel = 0,

		ZIndex = 140,
	},
	Body
)

local SidebarLine = New(
	"Frame",
	{
		Position = UDim2.new(1, -1, 0, 0),

		Size = UDim2.new(0, 1, 1, 0),

		BackgroundColor3 = Colors.Border,

		BackgroundTransparency = 0.5,

		BorderSizePixel = 0,

		ZIndex = 160,
	},
	Sidebar
)

local SidebarTitle = New(
	"TextLabel",
	{
		Position = UDim2.fromOffset(20, 18),

		Size = UDim2.new(1, -40, 0, 25),

		BackgroundTransparency = 1,

		Text = "SYSTEM NAVIGATION",

		TextColor3 = Colors.Soft,

		TextSize = 10,

		Font = Enum.Font.GothamBold,

		TextXAlignment = Enum.TextXAlignment.Left,

		ZIndex = 170,
	},
	Sidebar
)

local DesktopNav = New(
	"Frame",
	{
		Position = UDim2.fromOffset(12, 53),

		Size = UDim2.new(1, -24, 0, 235),

		BackgroundTransparency = 1,

		ZIndex = 170,
	},
	Sidebar
)

local DesktopNavLayout = Instance.new("UIListLayout")
DesktopNavLayout.Padding = UDim.new(0, 8)
DesktopNavLayout.SortOrder = Enum.SortOrder.LayoutOrder
DesktopNavLayout.Parent = DesktopNav

--==============================================================
-- MOBILE BOTTOM NAV
--==============================================================

local MobileNav = New(
	"Frame",
	{
		Name = "MobileBottomNav",

		AnchorPoint = Vector2.new(0.5, 1),

		Position = UDim2.new(
			0.5,
			0,
			1,
			-7
		),

		Size = UDim2.new(
			1,
			-14,
			0,
			65
		),

		BackgroundColor3 = Colors.Panel,

		BackgroundTransparency = 0.02,

		ZIndex = 600,

		Visible = false,
	},
	Body
)

Corner(MobileNav, 16)

Stroke(
	MobileNav,
	Colors.Border,
	0.3,
	1
)

--==============================================================
-- CONTENT
--==============================================================

local Content = New(
	"Frame",
	{
		Name = "Content",

		Position = UDim2.fromOffset(
			210,
			0
		),

		Size = UDim2.new(
			1,
			-210,
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
local Navigation = {}

local function CreatePage(name)
	local page = New(
		"ScrollingFrame",
		{
			Name = name .. "Page",

			Position = UDim2.fromOffset(0, 0),

			Size = UDim2.fromScale(1, 1),

			BackgroundTransparency = 1,

			BorderSizePixel = 0,

			ScrollBarThickness = 3,

			ScrollBarImageColor3 = Accent(),

			AutomaticCanvasSize = Enum.AutomaticSize.Y,

			CanvasSize = UDim2.new(0, 0, 0, 0),

			Visible = false,

			ZIndex = 190,
		},
		Content
	)

	local padding = Instance.new("UIPadding")

	padding.PaddingTop = UDim.new(0, 18)
	padding.PaddingBottom = UDim.new(0, 24)
	padding.PaddingLeft = UDim.new(0, 18)
	padding.PaddingRight = UDim.new(0, 18)

	padding.Parent = page

	Pages[name] = page

	return page
end

--==============================================================
-- HOME
--==============================================================

local HomePage = CreatePage("Home")

local Hero = New(
	"Frame",
	{
		Size = UDim2.new(1, 0, 0, 185),

		BackgroundColor3 = Colors.Panel,

		ZIndex = 200,
	},
	HomePage
)

Corner(Hero, 15)

Stroke(
	Hero,
	Colors.Border,
	0.4,
	1
)

local HeroTitle = New(
	"TextLabel",
	{
		Position = UDim2.fromOffset(22, 20),

		Size = UDim2.new(
			1,
			-44,
			0,
			35
		),

		BackgroundTransparency = 1,

		Text = "WELCOME BACK",

		TextColor3 = Colors.Text,

		TextSize = 26,

		Font = Enum.Font.GothamBold,

		TextXAlignment = Enum.TextXAlignment.Left,

		ZIndex = 220,
	},
	Hero
)

local HeroDescription = New(
	"TextLabel",
	{
		Position = UDim2.fromOffset(23, 62),

		Size = UDim2.new(
			1,
			-46,
			0,
			62
		),

		BackgroundTransparency = 1,

		Text = "VANZ is ready.\nSmooth controls • clear information • soft robotic motion.",

		TextColor3 = Colors.Muted,

		TextSize = 13,

		Font = Enum.Font.GothamMedium,

		TextWrapped = true,

		TextXAlignment = Enum.TextXAlignment.Left,

		TextYAlignment = Enum.TextYAlignment.Top,

		ZIndex = 220,
	},
	Hero
)

local HeroStatus = New(
	"Frame",
	{
		Position = UDim2.fromOffset(22, 137),

		Size = UDim2.fromOffset(170, 31),

		BackgroundColor3 = Colors.Panel3,

		ZIndex = 220,
	},
	Hero
)

Corner(HeroStatus, 9)

local HeroStatusDot = New(
	"Frame",
	{
		Position = UDim2.fromOffset(11, 12),

		Size = UDim2.fromOffset(7, 7),

		BackgroundColor3 = Colors.Success,

		BorderSizePixel = 0,

		ZIndex = 225,
	},
	HeroStatus
)

Corner(HeroStatusDot, 50)

local HeroStatusText = New(
	"TextLabel",
	{
		Position = UDim2.fromOffset(25, 0),

		Size = UDim2.new(1, -30, 1, 0),

		BackgroundTransparency = 1,

		Text = "SYSTEM READY",

		TextColor3 = Colors.Success,

		TextSize = 10,

		Font = Enum.Font.GothamBold,

		TextXAlignment = Enum.TextXAlignment.Left,

		ZIndex = 225,
	},
	HeroStatus
)

--==============================================================
-- HOME CONTROL CARD
--==============================================================

local ControlCard = New(
	"Frame",
	{
		Position = UDim2.fromOffset(0, 200),

		Size = UDim2.new(1, 0, 0, 150),

		BackgroundColor3 = Colors.Panel,

		ZIndex = 200,
	},
	HomePage
)

Corner(ControlCard, 15)

Stroke(
	ControlCard,
	Colors.Border,
	0.45,
	1
)

local ControlTitle = New(
	"TextLabel",
	{
		Position = UDim2.fromOffset(20, 17),

		Size = UDim2.new(1, -40, 0, 25),

		BackgroundTransparency = 1,

		Text = "DISPLAY SCALE",

		TextColor3 = Colors.Text,

		TextSize = 15,

		Font = Enum.Font.GothamBold,

		TextXAlignment = Enum.TextXAlignment.Left,

		ZIndex = 220,
	},
	ControlCard
)

local ControlSub = New(
	"TextLabel",
	{
		Position = UDim2.fromOffset(20, 43),

		Size = UDim2.new(1, -40, 0, 20),

		BackgroundTransparency = 1,

		Text = "Choose a comfortable size for your device.",

		TextColor3 = Colors.Muted,

		TextSize = 10,

		Font = Enum.Font.GothamMedium,

		TextXAlignment = Enum.TextXAlignment.Left,

		ZIndex = 220,
	},
	ControlCard
)

local ScaleHolder = New(
	"Frame",
	{
		Position = UDim2.fromOffset(20, 78),

		Size = UDim2.new(1, -40, 0, 55),

		BackgroundTransparency = 1,

		ZIndex = 220,
	},
	ControlCard
)

local ScaleValues = {80, 90, 100}

local ScaleButtons = {}

for index, value in ipairs(ScaleValues) do
	local button = New(
		"TextButton",
		{
			Position = UDim2.new(
				(index - 1) / 3,
				5,
				0,
				0
			),

			Size = UDim2.new(
				1 / 3,
				-10,
				0,
				50
			),

			BackgroundColor3 = Colors.Panel3,

			Text = tostring(value) .. "%",

			TextColor3 =
				value == 90
				and Colors.Text
				or Colors.Muted,

			TextSize = 13,

			Font = Enum.Font.GothamBold,

			AutoButtonColor = false,

			ZIndex = 230,
		},
		ScaleHolder
	)

	Corner(button, 11)

	local stroke = Stroke(
		button,
		value == 90
		and Accent()
		or Colors.Border,
		0.35,
		1
	)

	ScaleButtons[value] = {
		Button = button,
		Stroke = stroke,
	}

	Connect(
		button.MouseButton1Click,
		function()
			State.Scale = value / 100

			Tween(
				MainScale,
				0.3,
				{
					Scale = State.Scale,
				},
				Enum.EasingStyle.Quint
			)

			for scale, data in pairs(ScaleButtons) do
				local selected =
					scale == value

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
-- VISUALS
--==============================================================

local VisualPage = CreatePage("Visuals")

local VisualTitle = New(
	"TextLabel",
	{
		Size = UDim2.new(1, 0, 0, 38),

		BackgroundTransparency = 1,

		Text = "VISUAL SYSTEM",

		TextColor3 = Colors.Text,

		TextSize = 25,

		Font = Enum.Font.GothamBold,

		TextXAlignment = Enum.TextXAlignment.Left,

		ZIndex = 220,
	},
	VisualPage
)

local VisualSub = New(
	"TextLabel",
	{
		Position = UDim2.fromOffset(1, 40),

		Size = UDim2.new(1, -2, 0, 28),

		BackgroundTransparency = 1,

		Text = "Soft animation and interaction settings.",

		TextColor3 = Colors.Muted,

		TextSize = 12,

		Font = Enum.Font.GothamMedium,

		TextXAlignment = Enum.TextXAlignment.Left,

		ZIndex = 220,
	},
	VisualPage
)

--==============================================================
-- TOGGLE FUNCTION
--==============================================================

local function CreateToggle(
	parent,
	y,
	title,
	description,
	defaultValue,
	callback
)

	local holder = New(
		"Frame",
		{
			Position = UDim2.fromOffset(0, y),

			Size = UDim2.new(1, 0, 0, 84),

			BackgroundColor3 = Colors.Panel,

			ZIndex = 210,
		},
		parent
	)

	Corner(holder, 13)

	Stroke(
		holder,
		Colors.Border,
		0.5,
		1
	)

	local titleLabel = New(
		"TextLabel",
		{
			Position = UDim2.fromOffset(18, 11),

			Size = UDim2.new(
				1,
				-110,
				0,
				27
			),

			BackgroundTransparency = 1,

			Text = title,

			TextColor3 = Colors.Text,

			TextSize = 14,

			Font = Enum.Font.GothamBold,

			TextXAlignment = Enum.TextXAlignment.Left,

			ZIndex = 220,
		},
		holder
	)

	local descLabel = New(
		"TextLabel",
		{
			Position = UDim2.fromOffset(18, 40),

			Size = UDim2.new(
				1,
				-115,
				0,
				28
			),

			BackgroundTransparency = 1,

			Text = description,

			TextColor3 = Colors.Muted,

			TextSize = 10,

			Font = Enum.Font.GothamMedium,

			TextWrapped = true,

			TextXAlignment = Enum.TextXAlignment.Left,

			ZIndex = 220,
		},
		holder
	)

	local button = New(
		"TextButton",
		{
			AnchorPoint = Vector2.new(1, 0.5),

			Position = UDim2.new(
				1,
				-16,
				0.5,
				0
			),

			Size = UDim2.fromOffset(62, 36),

			BackgroundColor3 =
				defaultValue
				and Accent()
				or Colors.Panel3,

			Text = "",

			AutoButtonColor = false,

			ZIndex = 230,
		},
		holder
	)

	Corner(button, 20)

	local buttonStroke = Stroke(
		button,
		defaultValue
		and Accent()
		or Colors.Border,
		0.35,
		1
	)

	local knob = New(
		"Frame",
		{
			AnchorPoint = Vector2.new(0, 0.5),

			Position =
				defaultValue
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

			Size = UDim2.fromOffset(26, 26),

			BackgroundColor3 = Colors.White,

			BorderSizePixel = 0,

			ZIndex = 235,
		},
		button
	)

	Corner(knob, 50)

	local current = defaultValue

	Connect(
		button.MouseButton1Click,
		function()
			current = not current

			Tween(
				button,
				0.28,
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
				0.3,
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
	78,
	"SOFT ANIMATIONS",
	"Smooth motion throughout the interface.",
	true,
	function(value)
		State.Animations = value
	end
)

CreateToggle(
	VisualPage,
	172,
	"NEON AMBIENCE",
	"Soft dynamic accent and atmospheric glow.",
	true,
	function(value)
		State.Glow = value
	end
)

CreateToggle(
	VisualPage,
	266,
	"INTERACTION FX",
	"Smooth feedback when touching buttons.",
	true,
	function(value)
		State.InteractionFX = value
	end
)

--==============================================================
-- TELEMETRY
--==============================================================

local TelemetryPage = CreatePage("Telemetry")

local TelemetryTitle = New(
	"TextLabel",
	{
		Size = UDim2.new(1, 0, 0, 38),

		BackgroundTransparency = 1,

		Text = "SYSTEM TELEMETRY",

		TextColor3 = Colors.Text,

		TextSize = 25,

		Font = Enum.Font.GothamBold,

		TextXAlignment = Enum.TextXAlignment.Left,

		ZIndex = 220,
	},
	TelemetryPage
)

local FPSCard = New(
	"Frame",
	{
		Position = UDim2.fromOffset(0, 55),

		Size = UDim2.new(0.49, -5, 0, 135),

		BackgroundColor3 = Colors.Panel,

		ZIndex = 210,
	},
	TelemetryPage
)

Corner(FPSCard, 14)

Stroke(
	FPSCard,
	Colors.Border,
	0.5,
	1
)

local FPSLabel = New(
	"TextLabel",
	{
		Position = UDim2.fromOffset(18, 16),

		Size = UDim2.new(1, -36, 0, 20),

		BackgroundTransparency = 1,

		Text = "FRAME RATE",

		TextColor3 = Colors.Muted,

		TextSize = 10,

		Font = Enum.Font.GothamBold,

		TextXAlignment = Enum.TextXAlignment.Left,

		ZIndex = 220,
	},
	FPSCard
)

local FPSValue = New(
	"TextLabel",
	{
		Position = UDim2.fromOffset(18, 39),

		Size = UDim2.new(1, -36, 0, 65),

		BackgroundTransparency = 1,

		Text = "60",

		TextColor3 = Colors.Text,

		TextSize = 36,

		Font = Enum.Font.GothamBold,

		TextXAlignment = Enum.TextXAlignment.Left,

		ZIndex = 220,
	},
	FPSCard
)

local RuntimeCard = New(
	"Frame",
	{
		AnchorPoint = Vector2.new(1, 0),

		Position = UDim2.new(1, 0, 0, 55),

		Size = UDim2.new(0.49, -5, 0, 135),

		BackgroundColor3 = Colors.Panel,

		ZIndex = 210,
	},
	TelemetryPage
)

Corner(RuntimeCard, 14)

Stroke(
	RuntimeCard,
	Colors.Border,
	0.5,
	1
)

local RuntimeLabel = New(
	"TextLabel",
	{
		Position = UDim2.fromOffset(18, 16),

		Size = UDim2.new(1, -36, 0, 20),

		BackgroundTransparency = 1,

		Text = "RUNTIME",

		TextColor3 = Colors.Muted,

		TextSize = 10,

		Font = Enum.Font.GothamBold,

		TextXAlignment = Enum.TextXAlignment.Left,

		ZIndex = 220,
	},
	RuntimeCard
)

local RuntimeValue = New(
	"TextLabel",
	{
		Position = UDim2.fromOffset(18, 39),

		Size = UDim2.new(1, -36, 0, 65),

		BackgroundTransparency = 1,

		Text = "0s",

		TextColor3 = Colors.Text,

		TextSize = 36,

		Font = Enum.Font.GothamBold,

		TextXAlignment = Enum.TextXAlignment.Left,

		ZIndex = 220,
	},
	RuntimeCard
)

--==============================================================
-- ABOUT
--==============================================================

local AboutPage = CreatePage("About")

local AboutCard = New(
	"Frame",
	{
		Size = UDim2.new(1, 0, 0, 300),

		BackgroundColor3 = Colors.Panel,

		ZIndex = 210,
	},
	AboutPage
)

Corner(AboutCard, 15)

Stroke(
	AboutCard,
	Colors.Border,
	0.45,
	1
)

local AboutTitle = New(
	"TextLabel",
	{
		Position = UDim2.fromOffset(23, 23),

		Size = UDim2.new(1, -46, 0, 40),

		BackgroundTransparency = 1,

		Text = "VANZ V9",

		TextColor3 = Colors.Text,

		TextSize = 29,

		Font = Enum.Font.GothamBold,

		TextXAlignment = Enum.TextXAlignment.Left,

		ZIndex = 220,
	},
	AboutCard
)

local AboutText = New(
	"TextLabel",
	{
		Position = UDim2.fromOffset(25, 72),

		Size = UDim2.new(1, -50, 0, 125),

		BackgroundTransparency = 1,

		Text = "MOBILE-FIRST ROBOTIC COMMAND CENTER\n\nV9 was redesigned around small screens.\nThe header controls have their own protected area,\nwhile the content adapts around them.",

		TextColor3 = Colors.Muted,

		TextSize = 13,

		Font = Enum.Font.GothamMedium,

		TextWrapped = true,

		TextXAlignment = Enum.TextXAlignment.Left,

		TextYAlignment = Enum.TextYAlignment.Top,

		ZIndex = 220,
	},
	AboutCard
)

local AboutBuild = New(
	"TextLabel",
	{
		Position = UDim2.fromOffset(25, 245),

		Size = UDim2.new(1, -50, 0, 25),

		BackgroundTransparency = 1,

		Text = "BUILD // V9.00 • MOBILE FIRST",

		TextColor3 = Accent(),

		TextSize = 10,

		Font = Enum.Font.Code,

		TextXAlignment = Enum.TextXAlignment.Left,

		ZIndex = 220,
	},
	AboutCard
)

--==============================================================
-- NAVIGATION BUTTON FACTORY
--==============================================================

local function CreateNavigation(
	name,
	label,
	icon,
	order
)

	-- Desktop
	local desktopButton = New(
		"TextButton",
		{
			LayoutOrder = order,

			Size = UDim2.new(1, 0, 0, 52),

			BackgroundColor3 = Colors.Panel2,

			BackgroundTransparency = 1,

			Text = "",

			AutoButtonColor = false,

			ZIndex = 180,
		},
		DesktopNav
	)

	Corner(desktopButton, 11)

	local desktopIcon = New(
		"TextLabel",
		{
			Position = UDim2.fromOffset(14, 0),

			Size = UDim2.fromOffset(30, 52),

			BackgroundTransparency = 1,

			Text = icon,

			TextColor3 = Colors.Muted,

			TextSize = 17,

			Font = Enum.Font.GothamBold,

			ZIndex = 190,
		},
		desktopButton
	)

	local desktopText = New(
		"TextLabel",
		{
			Position = UDim2.fromOffset(54, 0),

			Size = UDim2.new(1, -65, 1, 0),

			BackgroundTransparency = 1,

			Text = label,

			TextColor3 = Colors.Muted,

			TextSize = 11,

			Font = Enum.Font.GothamBold,

			TextXAlignment = Enum.TextXAlignment.Left,

			ZIndex = 190,
		},
		desktopButton
	)

	local desktopBar = New(
		"Frame",
		{
			Position = UDim2.fromOffset(0, 10),

			Size = UDim2.fromOffset(3, 32),

			BackgroundColor3 = Accent(),

			BackgroundTransparency = 1,

			BorderSizePixel = 0,

			ZIndex = 195,
		},
		desktopButton
	)

	Corner(desktopBar, 3)

	-- Mobile
	local mobileButton = New(
		"TextButton",
		{
			LayoutOrder = order,

			Size = UDim2.new(
				0.25,
				-6,
				1,
				-10
			),

			BackgroundColor3 = Colors.Panel2,

			BackgroundTransparency = 1,

			Text = "",

			AutoButtonColor = false,

			ZIndex = 620,
		},
		MobileNav
	)

	Corner(mobileButton, 11)

	local mobileIcon = New(
		"TextLabel",
		{
			Position = UDim2.new(0, 0, 0, 4),

			Size = UDim2.new(1, 0, 0, 24),

			BackgroundTransparency = 1,

			Text = icon,

			TextColor3 = Colors.Muted,

			TextSize = 16,

			Font = Enum.Font.GothamBold,

			ZIndex = 630,
		},
		mobileButton
	)

	local mobileText = New(
		"TextLabel",
		{
			Position = UDim2.new(0, 0, 0, 28),

			Size = UDim2.new(1, 0, 0, 18),

			BackgroundTransparency = 1,

			Text = label,

			TextColor3 = Colors.Muted,

			TextSize = 8,

			Font = Enum.Font.GothamBold,

			TextTruncate = Enum.TextTruncate.AtEnd,

			ZIndex = 630,
		},
		mobileButton
	)

	local function SetActive(active)

		local background =
			active
			and 0.08
			or 1

		Tween(
			desktopButton,
			0.22,
			{
				BackgroundTransparency = background,
			},
			Enum.EasingStyle.Sine
		)

		Tween(
			mobileButton,
			0.22,
			{
				BackgroundTransparency = background,
			},
			Enum.EasingStyle.Sine
		)

		desktopIcon.TextColor3 =
			active
			and Colors.Text
			or Colors.Muted

		desktopText.TextColor3 =
			active
			and Colors.Text
			or Colors.Muted

		mobileIcon.TextColor3 =
			active
			and Colors.Text
			or Colors.Muted

		mobileText.TextColor3 =
			active
			and Colors.Text
			or Colors.Muted

		desktopBar.BackgroundTransparency =
			active
			and 0
			or 1
	end

	local function Activate()

		if State.CurrentPage == name then
			return
		end

		State.CurrentPage = name

		for pageName, page in pairs(Pages) do
			page.Visible =
				pageName == name
		end

		for navName, nav in pairs(Navigation) do
			nav.SetActive(
				navName == name
			)
		end
	end

	Connect(
		desktopButton.MouseButton1Click,
		Activate
	)

	Connect(
		mobileButton.MouseButton1Click,
		Activate
	)

	Navigation[name] = {
		SetActive = SetActive,
	}

	return Navigation[name]
end

CreateNavigation(
	"Home",
	"HOME",
	"⌂",
	1
)

CreateNavigation(
	"Visuals",
	"VISUALS",
	"✦",
	2
)

CreateNavigation(
	"Telemetry",
	"STATS",
	"⌁",
	3
)

CreateNavigation(
	"About",
	"ABOUT",
	"◇",
	4
)

Pages.Home.Visible = true
Navigation.Home.SetActive(true)

--==============================================================
-- DESKTOP STATUS
--==============================================================

local DesktopStatus = New(
	"Frame",
	{
		AnchorPoint = Vector2.new(0, 1),

		Position = UDim2.new(
			0,
			12,
			1,
			-13
		),

		Size = UDim2.new(
			1,
			-24,
			0,
			78
		),

		BackgroundColor3 = Colors.Panel2,

		ZIndex = 200,
	},
	Sidebar
)

Corner(DesktopStatus, 12)

Stroke(
	DesktopStatus,
	Colors.Border,
	0.55,
	1
)

local DesktopStatusTitle = New(
	"TextLabel",
	{
		Position = UDim2.fromOffset(12, 10),

		Size = UDim2.new(1, -24, 0, 18),

		BackgroundTransparency = 1,

		Text = "CORE STATUS",

		TextColor3 = Colors.Soft,

		TextSize = 9,

		Font = Enum.Font.GothamBold,

		TextXAlignment = Enum.TextXAlignment.Left,

		ZIndex = 210,
	},
	DesktopStatus
)

local DesktopStatusValue = New(
	"TextLabel",
	{
		Position = UDim2.fromOffset(12, 30),

		Size = UDim2.new(1, -24, 0, 22),

		BackgroundTransparency = 1,

		Text = "STABLE / ONLINE",

		TextColor3 = Colors.Success,

		TextSize = 10,

		Font = Enum.Font.GothamBold,

		TextXAlignment = Enum.TextXAlignment.Left,

		ZIndex = 210,
	},
	DesktopStatus
)

--==============================================================
-- MINIMIZED LOGO
--==============================================================

local MiniLogo = New(
	"TextButton",
	{
		Name = "VANZ_Minimized",

		AnchorPoint = Vector2.new(0.5, 0.5),

		Position = UDim2.fromScale(0.5, 0.5),

		Size = UDim2.fromOffset(92, 92),

		BackgroundColor3 = Colors.Panel,

		BackgroundTransparency = 0.03,

		Text = "V",

		TextColor3 = Colors.Text,

		TextSize = 35,

		Font = Enum.Font.GothamBold,

		AutoButtonColor = false,

		Visible = false,

		ZIndex = 1000,
	},
	ScreenGui
)

Corner(MiniLogo, 50)

local MiniStroke = Stroke(
	MiniLogo,
	Accent(),
	0.12,
	2
)

local MiniRing = New(
	"Frame",
	{
		AnchorPoint = Vector2.new(0.5, 0.5),

		Position = UDim2.fromScale(0.5, 0.5),

		Size = UDim2.new(1, 14, 1, 14),

		BackgroundTransparency = 1,

		ZIndex = 999,
	},
	ScreenGui
)

Corner(MiniRing, 60)

local MiniRingStroke = Stroke(
	MiniRing,
	AccentSoft(),
	0.5,
	1
)

MiniRing.Visible = false

local MiniScale = New(
	"UIScale",
	{
		Scale = 1,
	},
	MiniLogo
)

--==============================================================
-- MAIN WINDOW DRAG
--==============================================================

local WindowDragging = false
local WindowDragStart = nil
local WindowStartPosition = nil

local function BeginWindowDrag(input)

	WindowDragging = true

	State.DraggingWindow = true

	WindowDragStart = input.Position

	WindowStartPosition = MainHolder.Position
end

Connect(
	HeaderDragArea.InputBegan,
	function(input)

		if input.UserInputType ==
			Enum.UserInputType.MouseButton1
			or input.UserInputType ==
			Enum.UserInputType.Touch then

			BeginWindowDrag(input)
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

		local camera = workspace.CurrentCamera

		if not camera then
			return
		end

		local viewport = camera.ViewportSize

		local delta =
			input.Position
			- WindowDragStart

		local x =
			delta.X / viewport.X

		local y =
			delta.Y / viewport.Y

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
-- MINIMIZED LOGO DRAG
--==============================================================

local MiniDragging = false
local MiniDragStart = nil
local MiniStartPosition = nil
local MiniMoved = false

Connect(
	MiniLogo.InputBegan,
	function(input)

		if input.UserInputType ==
			Enum.UserInputType.MouseButton1
			or input.UserInputType ==
			Enum.UserInputType.Touch then

			MiniDragging = true
			MiniMoved = false

			State.DraggingMiniLogo = true

			MiniDragStart =
				input.Position

			MiniStartPosition =
				MiniLogo.Position
		end
	end
)

Connect(
	UserInputService.InputChanged,
	function(input)

		if not MiniDragging then
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
			- MiniDragStart

		if delta.Magnitude > 8 then
			MiniMoved = true
		end

		local camera = workspace.CurrentCamera

		if not camera then
			return
		end

		local viewport = camera.ViewportSize

		local x =
			delta.X / viewport.X

		local y =
			delta.Y / viewport.Y

		MiniLogo.Position =
			UDim2.new(
				MiniStartPosition.X.Scale + x,
				MiniStartPosition.X.Offset,
				MiniStartPosition.Y.Scale + y,
				MiniStartPosition.Y.Offset
			)

		MiniRing.Position =
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

			MiniDragging = false
			State.DraggingMiniLogo = false

			if not MiniMoved then

				State.Minimized = false

				MiniLogo.Visible = false
				MiniRing.Visible = false

				MainHolder.Visible = true

				MainHolder.Position =
					UDim2.fromScale(
						0.5,
						0.52
					)

				Tween(
					MainHolder,
					0.42,
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
		end
	end
)

--==============================================================
-- MINIMIZE
--==============================================================

local function Minimize()

	if State.Destroyed
		or State.Minimized then

		return
	end

	State.Minimized = true

	local oldPosition =
		MainHolder.Position

	Tween(
		MainHolder,
		0.4,
		{
			Size = UDim2.fromOffset(180, 110),

			Position = UDim2.fromScale(
				0.5,
				0.5
			),
		},
		Enum.EasingStyle.Quint
	)

	task.delay(
		0.3,
		function()

			if State.Destroyed then
				return
			end

			MainHolder.Visible = false

			-- ALWAYS START CENTER
			MiniLogo.Position =
				UDim2.fromScale(
					0.5,
					0.5
				)

			MiniRing.Position =
				MiniLogo.Position

			MiniLogo.Visible = true
			MiniRing.Visible = true

			MiniScale.Scale = 0.65

			Tween(
				MiniScale,
				0.45,
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
-- CLOSE
--==============================================================

local function ForceStop()

	if State.Destroyed then
		return
	end

	State.Destroyed = true

	for _, connection in ipairs(Connections) do
		pcall(function()
			connection:Disconnect()
		end)
	end

	table.clear(Connections)

	if ScreenGui then
		pcall(function()
			ScreenGui:Destroy()
		end)
	end
end

_G.vanz.ForceStop = ForceStop

Connect(
	CloseButton.MouseButton1Click,
	ForceStop
)

--==============================================================
-- BUTTON FEEDBACK
--==============================================================

local function SetupButtonFX(button, normalColor)

	Connect(
		button.MouseEnter,
		function()

			if not State.InteractionFX then
				return
			end

			Tween(
				button,
				0.18,
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
				0.18,
				{
					BackgroundColor3 =
						normalColor,
				},
				Enum.EasingStyle.Sine
			)
		end
	)
end

SetupButtonFX(
	MinimizeButton,
	Colors.Panel3
)

SetupButtonFX(
	CloseButton,
	Colors.Panel3
)

--==============================================================
-- RESPONSIVE SYSTEM
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
	-- SMALL MOBILE
	--==========================================================

	if width <= 700 then

		State.IsMobile = true

		-- FULL SCREEN WITH SAFE MARGIN
		MainScale.Scale = 1

		State.Scale = 1

		local panelWidth =
			math.max(
				300,
				width - Config.MobileMargin * 2
			)

		local panelHeight =
			math.max(
				360,
				height - Config.MobileMargin * 2
			)

		MainHolder.Size =
			UDim2.fromOffset(
				panelWidth,
				panelHeight
			)

		-- HEADER
		Header.Size =
			UDim2.new(
				1,
				0,
				0,
				Config.HeaderHeightMobile
			)

		Body.Position =
			UDim2.fromOffset(
				0,
				Config.HeaderHeightMobile
			)

		Body.Size =
			UDim2.new(
				1,
				0,
				1,
				-Config.HeaderHeightMobile
			)

		-- HIDE DESKTOP SIDEBAR
		Sidebar.Visible = false

		-- CONTENT FULL WIDTH
		Content.Position =
			UDim2.fromOffset(0, 0)

		-- Reserve bottom navigation
		Content.Size =
			UDim2.new(
				1,
				0,
				1,
				-72
			)

		-- MOBILE NAV
		MobileNav.Visible = true

		-- TITLE ZONE
		TitleZone.Position =
			UDim2.fromOffset(
				74,
				8
			)

		-- CRITICAL:
		-- title gets a fixed safe width
		-- and NEVER reaches buttons
		TitleZone.Size =
			UDim2.new(
				1,
				-290,
				0,
				66
			)

		Title.TextSize = 20

		Title.Text = "VANZ"

		Subtitle.Visible = false

		-- CONTROLS HAVE THEIR OWN SPACE
		HeaderControls.Position =
			UDim2.new(
				1,
				-7,
				0,
				9
			)

		HeaderControls.Size =
			UDim2.fromOffset(
				188,
				62
			)

		MinimizeButton.Position =
			UDim2.fromOffset(0, 0)

		MinimizeButton.Size =
			UDim2.fromOffset(
				89,
				60
			)

		MinimizeButton.Text = "MIN"

		CloseButton.Position =
			UDim2.fromOffset(
				99,
				0
			)

		CloseButton.Size =
			UDim2.fromOffset(
				89,
				60
			)

		CloseButton.Text = "CLOSE"

		-- Larger mobile logo
		HeaderLogo.Position =
			UDim2.fromOffset(
				10,
				13
			)

		-- Hero
		Hero.Size =
			UDim2.new(
				1,
				0,
				0,
				185
			)

		HeroTitle.TextSize = 24

		HeroDescription.TextSize = 12

		-- Mobile content spacing
		HomePage.CanvasSize =
			UDim2.new(
				0,
				0,
				0,
				390
			)

	else

	--==========================================================
	-- DESKTOP / TABLET
	--==========================================================

		State.IsMobile = false

		MainScale.Scale =
			Config.DesktopScale

		State.Scale =
			Config.DesktopScale

		MainHolder.Size =
			UDim2.fromOffset(
				Config.DesktopWidth,
				Config.DesktopHeight
			)

		Header.Size =
			UDim2.new(
				1,
				0,
				0,
				Config.HeaderHeightDesktop
			)

		Body.Position =
			UDim2.fromOffset(
				0,
				Config.HeaderHeightDesktop
			)

		Body.Size =
			UDim2.new(
				1,
				0,
				1,
				-Config.HeaderHeightDesktop
			)

		Sidebar.Visible = true

		MobileNav.Visible = false

		Content.Position =
			UDim2.fromOffset(
				210,
				0
			)

		Content.Size =
			UDim2.new(
				1,
				-210,
				1,
				0
			)

		TitleZone.Position =
			UDim2.fromOffset(
				78,
				8
			)

		TitleZone.Size =
			UDim2.new(
				1,
				-310,
				0,
				66
			)

		Title.TextSize = 24

		Title.Text = Config.Title

		Subtitle.Visible = true

		HeaderControls.Position =
			UDim2.new(
				1,
				-8,
				0,
				8
			)

		HeaderControls.Size =
			UDim2.fromOffset(
				194,
				66
			)

		MinimizeButton.Size =
			UDim2.fromOffset(
				91,
				62
			)

		CloseButton.Position =
			UDim2.fromOffset(
				101,
				0
			)

		CloseButton.Size =
			UDim2.fromOffset(
				91,
				62
			)

		MinimizeButton.Text = "MINIMIZE"

		CloseButton.Text = "CLOSE"
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
local FPSTicks = 0
local FPSTime = 0

Connect(
	RunService.RenderStepped,
	function(deltaTime)

		if State.Destroyed then
			return
		end

		State.Time += deltaTime

		FPSTicks += 1
		FPSTime += deltaTime

		if FPSTime >= 0.5 then

			FPS =
				math.floor(
					FPSTicks / FPSTime
				)

			FPSTicks = 0
			FPSTime = 0
		end

		--======================================================
		-- TOPMOST WATCHDOG
		--======================================================

		if ScreenGui.Parent ~= PlayerGui then
			ScreenGui.Parent = PlayerGui
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
					+ deltaTime * 0.012
				) % 1

			local accent =
				Accent()

			local accentSoft =
				AccentSoft(0.08)

			-- Main border
			MainStroke.Color =
				accent

			HeaderLine.BackgroundColor3 =
				accent

			-- Header logo
			LogoRing1.Rotation =
				LogoRing1.Rotation
				+ deltaTime * 4

			LogoRing2.Rotation =
				LogoRing2.Rotation
				- deltaTime * 6

			LogoStroke1.Color =
				accent

			LogoStroke2.Color =
				accentSoft

			LogoCore.BackgroundColor3 =
				accent

			-- breathing
			local breathing =
				1
				+ math.sin(
					State.Time * 1.5
				) * 0.06

			LogoCore.Size =
				UDim2.fromOffset(
					17 * breathing,
					17 * breathing
				)

			-- aura
			if State.Glow then

				Aura.BackgroundTransparency =
					0.935
					+ math.sin(
						State.Time * 1.15
					) * 0.018

				MiniStroke.Color =
					accent

				MiniRingStroke.Color =
					accentSoft

			else

				Aura.BackgroundTransparency = 1

			end

			-- status pulse
			HeroStatusDot.BackgroundTransparency =
				0.15
				+ math.sin(
					State.Time * 2
				) * 0.12

			-- minimized logo
			MiniLogo.TextColor3 =
				Colors.Text

			MiniStroke.Color =
				accent

			-- about accent
			AboutBuild.TextColor3 =
				accent
		end

		--======================================================
		-- TELEMETRY
		--======================================================

		FPSValue.Text =
			tostring(
				Clamp(
					FPS,
					1,
					240
				)
			)

		RuntimeValue.Text =
			string.format(
				"%ds",
				math.floor(
					State.Time
				)
			)
	end
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
	MiniRing.Visible = false

	MainHolder.Visible = true

	UpdateResponsive()

	MainHolder.Position =
		UDim2.fromScale(
			0.5,
			0.52
		)

	Tween(
		MainHolder,
		0.4,
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
		0.3,
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
		0.28,
		function()

			if not State.Destroyed then
				MainHolder.Visible = false
			end
		end
	)
end

function _G.vanz.SetScale(value)

	if State.Destroyed then
		return
	end

	if State.IsMobile then
		return
	end

	value =
		Clamp(
			tonumber(value) or 0.92,
			Config.MinScale,
			Config.MaxScale
		)

	State.Scale = value

	Tween(
		MainScale,
		0.3,
		{
			Scale = value,
		},
		Enum.EasingStyle.Quint
	)
end

function _G.vanz.GetState()
	return State
end

_G.vanz.ForceStop = ForceStop

--==============================================================
-- STARTUP
--==============================================================

UpdateResponsive()

if not State.IsMobile then

	MainHolder.Position =
		UDim2.fromScale(
			0.5,
			0.53
		)

	Tween(
		MainHolder,
		0.5,
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

print(
	"[VANZ V9] MOBILE-FIRST COMMAND CENTER ONLINE"
)

print(
	"[VANZ V9] Protected header controls enabled"
)

print(
	"[VANZ V9] Main window draggable"
)

print(
	"[VANZ V9] Center minimized logo draggable"
)

--//==============================================================\\
--// END VANZ V9
--//==============================================================\\