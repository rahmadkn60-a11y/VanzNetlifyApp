--//==============================================================\\
--// VANZ V7 — SOFT ROBOTIC LUXURY COMMAND CENTER
--// Full Code / Standalone Roblox Luau
--// Smooth • Soft • Responsive • Premium • Robotic
--//==============================================================\\

--//==============================================================
--// SERVICES
--//==============================================================

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")

local LocalPlayer = Players.LocalPlayer

--//==============================================================
--// GLOBAL ROOT
--//==============================================================

_G.vanz = _G.vanz or {}

-- Destroy previous VANZ instance
if _G.vanz.ForceStop then
	pcall(_G.vanz.ForceStop)
end

_G.vanz = {}

--//==============================================================
--// CONFIG
--//==============================================================

_G.vanz.Config = {

	Title = "VANZ",
	Subtitle = "SOFT ROBOTIC COMMAND CENTER",

	Width = 920,
	Height = 570,

	SidebarWidth = 215,
	Margin = 22,

	DefaultScale = 0.70,

	DisplayOrder = 999999999,

	AnimationSpeed = 1,

	EnableSoftGlow = true,
	EnableParticles = true,
	EnableScanner = true,
	EnableTelemetry = true,

	Responsive = true,
}

--//==============================================================
--// STATE
--//==============================================================

local State = {

	Destroyed = false,

	Minimized = false,

	Animations = true,
	Glow = true,
	ClickFX = true,

	Scale = _G.vanz.Config.DefaultScale,

	Hue = 0,

	Time = 0,

	OpenedAt = os.clock(),

	CurrentPage = "Home",

	Dragging = false,

	Transitioning = false,
}

_G.vanz.State = State

--//==============================================================
--// CONNECTION MANAGEMENT
--//==============================================================

local Connections = {}
local Cleanups = {}

_G.vanz.Connections = Connections
_G.vanz.Cleanups = Cleanups

local function Connect(signal, callback)

	if State.Destroyed then
		return nil
	end

	local connection = signal:Connect(callback)

	table.insert(Connections, connection)

	return connection
end

local function Cleanup(callback)

	table.insert(Cleanups, callback)

	return callback
end

--//==============================================================
--// UTILITY
--//==============================================================

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
	corner.CornerRadius = UDim.new(0, radius or 8)
	corner.Parent = object

	return corner
end

local function Stroke(object, color, transparency, thickness)

	local stroke = Instance.new("UIStroke")

	stroke.Color = color or Color3.new(1, 1, 1)
	stroke.Transparency = transparency or 0
	stroke.Thickness = thickness or 1

	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Parent = object

	return stroke
end

local function Gradient(object, color1, color2, rotation)

	local gradient = Instance.new("UIGradient")

	gradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, color1),
		ColorSequenceKeypoint.new(1, color2),
	})

	gradient.Rotation = rotation or 0

	gradient.Parent = object

	return gradient
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

local function Lerp(a, b, alpha)

	return a + (b - a) * alpha
end

local function LerpColor(a, b, alpha)

	return Color3.new(
		Lerp(a.R, b.R, alpha),
		Lerp(a.G, b.G, alpha),
		Lerp(a.B, b.B, alpha)
	)
end

local function AccentColor(offset)

	local hue = (State.Hue + (offset or 0)) % 1

	return Color3.fromHSV(
		hue,
		0.55,
		1
	)
end

local function AccentSoft(offset)

	local hue = (State.Hue + (offset or 0)) % 1

	return Color3.fromHSV(
		hue,
		0.28,
		1
	)
end

--//==============================================================
--// PALETTE
--//==============================================================

local Colors = {

	Background = Color3.fromRGB(7, 9, 14),

	Panel = Color3.fromRGB(12, 15, 23),

	Panel2 = Color3.fromRGB(16, 20, 30),

	Panel3 = Color3.fromRGB(21, 26, 38),

	Border = Color3.fromRGB(48, 58, 76),

	Text = Color3.fromRGB(240, 244, 255),

	Muted = Color3.fromRGB(135, 146, 168),

	Soft = Color3.fromRGB(85, 96, 119),

	Success = Color3.fromRGB(104, 235, 181),

	Warning = Color3.fromRGB(255, 202, 105),

	Danger = Color3.fromRGB(255, 110, 125),

	White = Color3.fromRGB(255, 255, 255),
}

--//==============================================================
--// CLEAN OLD GUI
--//==============================================================

pcall(function()

	local playerGui = LocalPlayer:FindFirstChildOfClass("PlayerGui")

	if playerGui then

		for _, child in ipairs(playerGui:GetChildren()) do

			if child.Name == "VANZ_ROBOTIC_GUI"
				or child.Name == "VANZ_PREMIUM_GUI"
				or child.Name == "VANZ_SOFT_ROBOTIC_GUI" then

				child:Destroy()
			end

		end

	end

end)

--//==============================================================
--// SCREEN GUI
--//==============================================================

local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local ScreenGui = New(
	"ScreenGui",
	{
		Name = "VANZ_SOFT_ROBOTIC_GUI",

		Enabled = true,

		DisplayOrder = _G.vanz.Config.DisplayOrder,

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

--//==============================================================
--// SCALE
--//==============================================================

local UIScale = New(
	"UIScale",
	{
		Scale = State.Scale,
	},
	ScreenGui
)

--//==============================================================
--// MAIN HOLDER
--//==============================================================

local MainHolder = New(
	"Frame",
	{
		Name = "MainHolder",

		AnchorPoint = Vector2.new(0.5, 0.5),

		Position = UDim2.fromScale(0.5, 0.5),

		Size = UDim2.fromOffset(
			_G.vanz.Config.Width,
			_G.vanz.Config.Height
		),

		BackgroundTransparency = 1,

		ZIndex = 10,
	},
	ScreenGui
)

--//==============================================================
--// SHADOW
--//==============================================================

local Shadow = New(
	"Frame",
	{
		Name = "Shadow",

		Position = UDim2.fromOffset(8, 10),

		Size = UDim2.new(1, 0, 1, 0),

		BackgroundColor3 = Color3.new(0, 0, 0),

		BackgroundTransparency = 0.48,

		ZIndex = 9,
	},
	MainHolder
)

Corner(Shadow, 20)

local ShadowGradient = Gradient(
	Shadow,
	Color3.new(0, 0, 0),
	Color3.new(0, 0, 0),
	90
)

--//==============================================================
--// SOFT AURA
--//==============================================================

local Aura = New(
	"Frame",
	{
		Name = "SoftAura",

		Position = UDim2.fromOffset(-8, -8),

		Size = UDim2.new(1, 16, 1, 16),

		BackgroundColor3 = AccentColor(),

		BackgroundTransparency = 0.91,

		ZIndex = 8,
	},
	MainHolder
)

Corner(Aura, 24)

--//==============================================================
--// MAIN PANEL
--//==============================================================

local MainPanel = New(
	"Frame",
	{
		Name = "MainPanel",

		Size = UDim2.fromScale(1, 1),

		BackgroundColor3 = Colors.Background,

		BackgroundTransparency = 0.02,

		ClipsDescendants = true,

		ZIndex = 11,
	},
	MainHolder
)

Corner(MainPanel, 18)

local MainStroke = Stroke(
	MainPanel,
	Colors.Border,
	0.25,
	1
)

--//==============================================================
--// SOFT INNER BORDER
--//==============================================================

local InnerBorder = New(
	"Frame",
	{
		Name = "InnerBorder",

		Position = UDim2.fromOffset(1, 1),

		Size = UDim2.new(1, -2, 1, -2),

		BackgroundTransparency = 1,

		ZIndex = 12,
	},
	MainPanel
)

Corner(InnerBorder, 17)

Stroke(
	InnerBorder,
	AccentSoft(),
	0.90,
	1
)

--//==============================================================
--// TOP LASER / LIGHT
--//==============================================================

local TopLaser = New(
	"Frame",
	{
		Name = "TopLaser",

		Position = UDim2.new(0, -200, 0, 0),

		Size = UDim2.fromOffset(200, 2),

		BackgroundColor3 = AccentColor(),

		BorderSizePixel = 0,

		ZIndex = 50,
	},
	MainPanel
)

Corner(TopLaser, 2)

--//==============================================================
--// HEADER
--//==============================================================

local Header = New(
	"Frame",
	{
		Name = "Header",

		Position = UDim2.fromOffset(0, 0),

		Size = UDim2.new(1, 0, 0, 82),

		BackgroundColor3 = Colors.Panel,

		BackgroundTransparency = 0.04,

		ZIndex = 20,
	},
	MainPanel
)

-- Header gradient
local HeaderGradient = Gradient(
	Header,
	Colors.Panel2,
	Colors.Panel,
	0
)

-- Header line
local HeaderLine = New(
	"Frame",
	{
		Position = UDim2.new(0, 0, 1, -1),

		Size = UDim2.new(1, 0, 0, 1),

		BackgroundColor3 = AccentColor(),

		BackgroundTransparency = 0.50,

		BorderSizePixel = 0,

		ZIndex = 30,
	},
	Header
)

--//==============================================================
--// HEADER GRID
--//==============================================================

local HeaderGrid = New(
	"Frame",
	{
		Position = UDim2.fromOffset(0, 0),

		Size = UDim2.new(1, 0, 1, 0),

		BackgroundTransparency = 1,

		ZIndex = 21,
	},
	Header
)

for x = 0, 18 do

	local line = New(
		"Frame",
		{
			Position = UDim2.new(x / 18, 0, 0, 0),

			Size = UDim2.fromOffset(1, 82),

			BackgroundColor3 = Colors.Border,

			BackgroundTransparency = 0.94,

			BorderSizePixel = 0,

			ZIndex = 21,
		},
		HeaderGrid
	)

end

for y = 0, 4 do

	local line = New(
		"Frame",
		{
			Position = UDim2.new(0, 0, y / 4, 0),

			Size = UDim2.new(1, 0, 0, 1),

			BackgroundColor3 = Colors.Border,

			BackgroundTransparency = 0.95,

			BorderSizePixel = 0,

			ZIndex = 21,
		},
		HeaderGrid
	)

end

--//==============================================================
--// LOGO
--//==============================================================

local LogoContainer = New(
	"Frame",
	{
		Name = "LogoContainer",

		Position = UDim2.fromOffset(20, 17),

		Size = UDim2.fromOffset(48, 48),

		BackgroundTransparency = 1,

		ZIndex = 40,
	},
	Header
)

local LogoOuter = New(
	"Frame",
	{
		AnchorPoint = Vector2.new(0.5, 0.5),

		Position = UDim2.fromScale(0.5, 0.5),

		Size = UDim2.fromOffset(42, 42),

		BackgroundTransparency = 1,

		ZIndex = 41,
	},
	LogoContainer
)

Corner(LogoOuter, 50)

local LogoOuterStroke = Stroke(
	LogoOuter,
	AccentColor(),
	0.20,
	1
)

local LogoMiddle = New(
	"Frame",
	{
		AnchorPoint = Vector2.new(0.5, 0.5),

		Position = UDim2.fromScale(0.5, 0.5),

		Size = UDim2.fromOffset(30, 30),

		BackgroundTransparency = 1,

		ZIndex = 42,
	},
	LogoContainer
)

Corner(LogoMiddle, 50)

local LogoMiddleStroke = Stroke(
	LogoMiddle,
	AccentSoft(0.08),
	0.30,
	1
)

local LogoCore = New(
	"Frame",
	{
		AnchorPoint = Vector2.new(0.5, 0.5),

		Position = UDim2.fromScale(0.5, 0.5),

		Size = UDim2.fromOffset(15, 15),

		BackgroundColor3 = AccentColor(),

		BackgroundTransparency = 0.05,

		ZIndex = 44,
	},
	LogoContainer
)

Corner(LogoCore, 50)

local LogoCoreGradient = Gradient(
	LogoCore,
	Colors.White,
	AccentColor(),
	45
)

local LogoCoreStroke = Stroke(
	LogoCore,
	Colors.White,
	0.70,
	1
)

-- Logo ticks
for i = 0, 7 do

	local tick = New(
		"Frame",
		{
			AnchorPoint = Vector2.new(0.5, 0.5),

			Position = UDim2.fromScale(0.5, 0.5),

			Size = UDim2.fromOffset(2, 6),

			BackgroundColor3 = AccentColor(i / 12),

			BorderSizePixel = 0,

			ZIndex = 43,
		},
		LogoContainer
	)

	tick.Rotation = i * 45

end

--//==============================================================
--// TITLE
--//==============================================================

local Title = New(
	"TextLabel",
	{
		Name = "Title",

		Position = UDim2.fromOffset(82, 17),

		Size = UDim2.new(0, 350, 0, 28),

		BackgroundTransparency = 1,

		Text = _G.vanz.Config.Title,

		TextColor3 = Colors.Text,

		TextSize = 22,

		Font = Enum.Font.GothamBold,

		TextXAlignment = Enum.TextXAlignment.Left,

		ZIndex = 40,
	},
	Header
)

local Subtitle = New(
	"TextLabel",
	{
		Name = "Subtitle",

		Position = UDim2.fromOffset(83, 45),

		Size = UDim2.new(0, 360, 0, 18),

		BackgroundTransparency = 1,

		Text = _G.vanz.Config.Subtitle,

		TextColor3 = Colors.Muted,

		TextSize = 10,

		Font = Enum.Font.GothamMedium,

		TextXAlignment = Enum.TextXAlignment.Left,

		ZIndex = 40,
	},
	Header
)

--//==============================================================
--// TELEMETRY
--//==============================================================

local Telemetry = New(
	"TextLabel",
	{
		Name = "Telemetry",

		AnchorPoint = Vector2.new(1, 0),

		Position = UDim2.new(1, -165, 0, 17),

		Size = UDim2.fromOffset(155, 20),

		BackgroundTransparency = 1,

		Text = "SYS // 00.00ms",

		TextColor3 = Colors.Soft,

		TextSize = 9,

		Font = Enum.Font.Code,

		TextXAlignment = Enum.TextXAlignment.Right,

		ZIndex = 40,
	},
	Header
)

--//==============================================================
--// ONLINE PILL
--//==============================================================

local Online = New(
	"Frame",
	{
		Name = "Online",

		AnchorPoint = Vector2.new(1, 0),

		Position = UDim2.new(1, -25, 0, 43),

		Size = UDim2.fromOffset(115, 25),

		BackgroundColor3 = Colors.Panel3,

		BackgroundTransparency = 0.12,

		ZIndex = 41,
	},
	Header
)

Corner(Online, 8)

local OnlineStroke = Stroke(
	Online,
	Colors.Success,
	0.60,
	1
)

local OnlineDot = New(
	"Frame",
	{
		Position = UDim2.fromOffset(10, 9),

		Size = UDim2.fromOffset(7, 7),

		BackgroundColor3 = Colors.Success,

		BorderSizePixel = 0,

		ZIndex = 42,
	},
	Online
)

Corner(OnlineDot, 50)

local OnlineText = New(
	"TextLabel",
	{
		Position = UDim2.fromOffset(24, 0),

		Size = UDim2.new(1, -28, 1, 0),

		BackgroundTransparency = 1,

		Text = "SYSTEM ONLINE",

		TextColor3 = Colors.Success,

		TextSize = 9,

		Font = Enum.Font.GothamBold,

		TextXAlignment = Enum.TextXAlignment.Left,

		ZIndex = 42,
	},
	Online
)

--//==============================================================
--// HEADER BUTTONS
--//==============================================================

local MinimizeButton = New(
	"TextButton",
	{
		Name = "Minimize",

		AnchorPoint = Vector2.new(1, 0),

		Position = UDim2.new(1, -145, 0, 13),

		Size = UDim2.fromOffset(28, 28),

		BackgroundColor3 = Colors.Panel3,

		BackgroundTransparency = 0.20,

		Text = "—",

		TextColor3 = Colors.Muted,

		TextSize = 15,

		Font = Enum.Font.GothamBold,

		AutoButtonColor = false,

		ZIndex = 50,
	},
	Header
)

Corner(MinimizeButton, 8)

local MinStroke = Stroke(
	MinimizeButton,
	Colors.Border,
	0.45,
	1
)

local CloseButton = New(
	"TextButton",
	{
		Name = "Close",

		AnchorPoint = Vector2.new(1, 0),

		Position = UDim2.new(1, -110, 0, 13),

		Size = UDim2.fromOffset(28, 28),

		BackgroundColor3 = Colors.Panel3,

		BackgroundTransparency = 0.20,

		Text = "×",

		TextColor3 = Colors.Muted,

		TextSize = 17,

		Font = Enum.Font.GothamBold,

		AutoButtonColor = false,

		ZIndex = 50,
	},
	Header
)

Corner(CloseButton, 8)

local CloseStroke = Stroke(
	CloseButton,
	Colors.Border,
	0.45,
	1
)

--//==============================================================
--// BODY
--//==============================================================

local Body = New(
	"Frame",
	{
		Name = "Body",

		Position = UDim2.fromOffset(0, 82),

		Size = UDim2.new(1, 0, 1, -82),

		BackgroundTransparency = 1,

		ZIndex = 20,
	},
	MainPanel
)

--//==============================================================
--// SIDEBAR
--//==============================================================

local Sidebar = New(
	"Frame",
	{
		Name = "Sidebar",

		Position = UDim2.fromOffset(0, 0),

		Size = UDim2.new(
			0,
			_G.vanz.Config.SidebarWidth,
			1,
			0
		),

		BackgroundColor3 = Colors.Panel,

		BackgroundTransparency = 0.10,

		ZIndex = 25,
	},
	Body
)

local SidebarLine = New(
	"Frame",
	{
		AnchorPoint = Vector2.new(1, 0),

		Position = UDim2.new(1, 0, 0, 0),

		Size = UDim2.fromOffset(1, 999),

		BackgroundColor3 = Colors.Border,

		BackgroundTransparency = 0.45,

		BorderSizePixel = 0,

		ZIndex = 30,
	},
	Sidebar
)

--//==============================================================
--// SIDEBAR HEADER
--//==============================================================

local SideHeader = New(
	"TextLabel",
	{
		Position = UDim2.fromOffset(20, 20),

		Size = UDim2.new(1, -40, 0, 18),

		BackgroundTransparency = 1,

		Text = "NAVIGATION",

		TextColor3 = Colors.Soft,

		TextSize = 9,

		Font = Enum.Font.GothamBold,

		TextXAlignment = Enum.TextXAlignment.Left,

		ZIndex = 35,
	},
	Sidebar
)

--//==============================================================
--// NAVIGATION HOLDER
--//==============================================================

local NavHolder = New(
	"Frame",
	{
		Position = UDim2.fromOffset(12, 48),

		Size = UDim2.new(1, -24, 0, 220),

		BackgroundTransparency = 1,

		ZIndex = 35,
	},
	Sidebar
)

local NavLayout = Instance.new("UIListLayout")
NavLayout.Padding = UDim.new(0, 7)
NavLayout.SortOrder = Enum.SortOrder.LayoutOrder
NavLayout.Parent = NavHolder

--//==============================================================
--// PAGE CONTAINER
--//==============================================================

local Content = New(
	"Frame",
	{
		Name = "Content",

		Position = UDim2.fromOffset(
			_G.vanz.Config.SidebarWidth,
			0
		),

		Size = UDim2.new(
			1,
			-_G.vanz.Config.SidebarWidth,
			1,
			0
		),

		BackgroundTransparency = 1,

		ClipsDescendants = true,

		ZIndex = 30,
	},
	Body
)

--//==============================================================
--// PAGE CREATION
--//==============================================================

local Pages = {}
local NavButtons = {}

local function CreatePage(name)

	local page = New(
		"ScrollingFrame",
		{
			Name = name .. "Page",

			Position = UDim2.fromOffset(0, 0),

			Size = UDim2.fromScale(1, 1),

			BackgroundTransparency = 1,

			BorderSizePixel = 0,

			ScrollBarThickness = 2,

			ScrollBarImageColor3 = AccentColor(),

			CanvasSize = UDim2.new(0, 0, 0, 0),

			AutomaticCanvasSize = Enum.AutomaticSize.Y,

			ScrollingDirection = Enum.ScrollingDirection.Y,

			Visible = false,

			ZIndex = 31,
		},
		Content
	)

	local padding = Instance.new("UIPadding")

	padding.PaddingTop = UDim.new(0, 20)
	padding.PaddingBottom = UDim.new(0, 20)
	padding.PaddingLeft = UDim.new(0, 20)
	padding.PaddingRight = UDim.new(0, 20)

	padding.Parent = page

	Pages[name] = page

	return page
end

--//==============================================================
--// HOME PAGE
--//==============================================================

local HomePage = CreatePage("Home")

-- HERO
local Hero = New(
	"Frame",
	{
		Position = UDim2.fromOffset(0, 0),

		Size = UDim2.new(1, 0, 0, 185),

		BackgroundColor3 = Colors.Panel,

		BackgroundTransparency = 0.05,

		ZIndex = 35,
	},
	HomePage
)

Corner(Hero, 14)

local HeroStroke = Stroke(
	Hero,
	Colors.Border,
	0.35,
	1
)

local HeroGradient = Gradient(
	Hero,
	Colors.Panel2,
	Colors.Panel,
	25
)

-- Hero glow
local HeroGlow = New(
	"Frame",
	{
		AnchorPoint = Vector2.new(1, 0.5),

		Position = UDim2.new(1, 50, 0.5, 0),

		Size = UDim2.fromOffset(220, 220),

		BackgroundColor3 = AccentColor(),

		BackgroundTransparency = 0.93,

		ZIndex = 34,
	},
	Hero
)

Corner(HeroGlow, 110)

-- Hero title
local HeroTitle = New(
	"TextLabel",
	{
		Position = UDim2.fromOffset(25, 25),

		Size = UDim2.new(1, -50, 0, 35),

		BackgroundTransparency = 1,

		Text = "WELCOME BACK, OPERATOR.",

		TextColor3 = Colors.Text,

		TextSize = 24,

		Font = Enum.Font.GothamBold,

		TextXAlignment = Enum.TextXAlignment.Left,

		ZIndex = 40,
	},
	Hero
)

local HeroDesc = New(
	"TextLabel",
	{
		Position = UDim2.fromOffset(27, 64),

		Size = UDim2.new(0.68, 0, 0, 40),

		BackgroundTransparency = 1,

		Text = "A soft robotic control environment designed for clean\ninteraction, smooth motion and premium visual feedback.",

		TextColor3 = Colors.Muted,

		TextSize = 11,

		Font = Enum.Font.GothamMedium,

		TextWrapped = true,

		TextXAlignment = Enum.TextXAlignment.Left,

		TextYAlignment = Enum.TextYAlignment.Top,

		ZIndex = 40,
	},
	Hero
)

-- Hero status
local HeroStatus = New(
	"Frame",
	{
		Position = UDim2.fromOffset(25, 128),

		Size = UDim2.fromOffset(150, 32),

		BackgroundColor3 = Colors.Panel3,

		BackgroundTransparency = 0.15,

		ZIndex = 40,
	},
	Hero
)

Corner(HeroStatus, 9)

local HeroStatusDot = New(
	"Frame",
	{
		Position = UDim2.fromOffset(12, 12),

		Size = UDim2.fromOffset(7, 7),

		BackgroundColor3 = Colors.Success,

		BorderSizePixel = 0,

		ZIndex = 41,
	},
	HeroStatus
)

Corner(HeroStatusDot, 50)

local HeroStatusText = New(
	"TextLabel",
	{
		Position = UDim2.fromOffset(27, 0),

		Size = UDim2.new(1, -30, 1, 0),

		BackgroundTransparency = 1,

		Text = "CORE STABLE",

		TextColor3 = Colors.Success,

		TextSize = 9,

		Font = Enum.Font.GothamBold,

		TextXAlignment = Enum.TextXAlignment.Left,

		ZIndex = 41,
	},
	HeroStatus
)

--//==============================================================
--// HERO RADAR
--//==============================================================

local Radar = New(
	"Frame",
	{
		AnchorPoint = Vector2.new(1, 0.5),

		Position = UDim2.new(1, -45, 0.5, 0),

		Size = UDim2.fromOffset(120, 120),

		BackgroundTransparency = 1,

		ZIndex = 40,
	},
	Hero
)

local RadarOuter = New(
	"Frame",
	{
		AnchorPoint = Vector2.new(0.5, 0.5),

		Position = UDim2.fromScale(0.5, 0.5),

		Size = UDim2.fromScale(1, 1),

		BackgroundTransparency = 1,

		ZIndex = 40,
	},
	Radar
)

Corner(RadarOuter, 100)

local RadarStroke = Stroke(
	RadarOuter,
	AccentColor(),
	0.55,
	1
)

local RadarMiddle = New(
	"Frame",
	{
		AnchorPoint = Vector2.new(0.5, 0.5),

		Position = UDim2.fromScale(0.5, 0.5),

		Size = UDim2.fromScale(0.66, 0.66),

		BackgroundTransparency = 1,

		ZIndex = 41,
	},
	Radar
)

Corner(RadarMiddle, 100)

Stroke(
	RadarMiddle,
	AccentSoft(),
	0.70,
	1
)

local RadarCore = New(
	"Frame",
	{
		AnchorPoint = Vector2.new(0.5, 0.5),

		Position = UDim2.fromScale(0.5, 0.5),

		Size = UDim2.fromOffset(8, 8),

		BackgroundColor3 = AccentColor(),

		BorderSizePixel = 0,

		ZIndex = 43,
	},
	Radar
)

Corner(RadarCore, 50)

local RadarSweep = New(
	"Frame",
	{
		AnchorPoint = Vector2.new(0.5, 1),

		Position = UDim2.fromScale(0.5, 0.5),

		Size = UDim2.fromOffset(1, 58),

		BackgroundColor3 = AccentColor(),

		BackgroundTransparency = 0.35,

		BorderSizePixel = 0,

		ZIndex = 42,
	},
	Radar
)

--//==============================================================
--// SETTINGS PANEL
--//==============================================================

local SettingsPanel = New(
	"Frame",
	{
		Position = UDim2.fromOffset(0, 198),

		Size = UDim2.new(1, 0, 0, 180),

		BackgroundColor3 = Colors.Panel,

		BackgroundTransparency = 0.05,

		ZIndex = 35,
	},
	HomePage
)

Corner(SettingsPanel, 14)

Stroke(
	SettingsPanel,
	Colors.Border,
	0.45,
	1
)

local SettingsTitle = New(
	"TextLabel",
	{
		Position = UDim2.fromOffset(20, 18),

		Size = UDim2.new(1, -40, 0, 20),

		BackgroundTransparency = 1,

		Text = "DISPLAY PROFILE",

		TextColor3 = Colors.Text,

		TextSize = 11,

		Font = Enum.Font.GothamBold,

		TextXAlignment = Enum.TextXAlignment.Left,

		ZIndex = 40,
	},
	SettingsPanel
)

local SettingsSub = New(
	"TextLabel",
	{
		Position = UDim2.fromOffset(20, 39),

		Size = UDim2.new(1, -40, 0, 20),

		BackgroundTransparency = 1,

		Text = "Choose a comfortable interface scale.",

		TextColor3 = Colors.Muted,

		TextSize = 9,

		Font = Enum.Font.GothamMedium,

		TextXAlignment = Enum.TextXAlignment.Left,

		ZIndex = 40,
	},
	SettingsPanel
)

local DPIHolder = New(
	"Frame",
	{
		Position = UDim2.fromOffset(20, 76),

		Size = UDim2.new(1, -40, 0, 55),

		BackgroundTransparency = 1,

		ZIndex = 40,
	},
	SettingsPanel
)

local DPIValues = {
	50,
	60,
	70,
	80,
	90,
	100,
}

local DPIButtons = {}

for index, value in ipairs(DPIValues) do

	local button = New(
		"TextButton",
		{
			Position = UDim2.new(
				(index - 1) / #DPIValues,
				(index == 1 and 0 or 4),
				0,
				0
			),

			Size = UDim2.new(
				1 / #DPIValues,
				-6,
				0,
				42
			),

			BackgroundColor3 = Colors.Panel3,

			BackgroundTransparency = 0.10,

			Text = tostring(value) .. "%",

			TextColor3 = value == 70 and Colors.Text or Colors.Muted,

			TextSize = 10,

			Font = Enum.Font.GothamBold,

			AutoButtonColor = false,

			ZIndex = 42,
		},
		DPIHolder
	)

	Corner(button, 9)

	local stroke = Stroke(
		button,
		value == 70 and AccentColor() or Colors.Border,
		value == 70 and 0.25 or 0.70,
		1
	)

	DPIButtons[value] = {
		Button = button,
		Stroke = stroke,
	}

	Connect(button.MouseEnter, function()

		if State.ClickFX then

			Tween(
				button,
				0.22,
				{
					BackgroundTransparency = 0,
				},
				Enum.EasingStyle.Sine
			)

		end

	end)

	Connect(button.MouseLeave, function()

		if State.ClickFX then

			Tween(
				button,
				0.22,
				{
					BackgroundTransparency = 0.10,
				},
				Enum.EasingStyle.Sine
			)

		end

	end)

	Connect(button.MouseButton1Click, function()

		State.Scale = value / 100
		UIScale.Scale = State.Scale

		for dpi, data in pairs(DPIButtons) do

			local selected = dpi == value

			Tween(
				data.Button,
				0.25,
				{
					BackgroundColor3 = selected
						and Colors.Panel3
						or Colors.Panel3,
				},
				Enum.EasingStyle.Quint
			)

			data.Button.TextColor3 =
				selected
				and Colors.Text
				or Colors.Muted

			data.Stroke.Color =
				selected
				and AccentColor()
				or Colors.Border

			data.Stroke.Transparency =
				selected
				and 0.25
				or 0.70
		end

	end)

end

--//==============================================================
--// VISUALS PAGE
--//==============================================================

local VisualsPage = CreatePage("Visuals")

local VisualTitle = New(
	"TextLabel",
	{
		Position = UDim2.fromOffset(0, 0),

		Size = UDim2.new(1, 0, 0, 30),

		BackgroundTransparency = 1,

		Text = "VISUAL SYSTEM",

		TextColor3 = Colors.Text,

		TextSize = 22,

		Font = Enum.Font.GothamBold,

		TextXAlignment = Enum.TextXAlignment.Left,

		ZIndex = 40,
	},
	VisualsPage
)

local VisualSub = New(
	"TextLabel",
	{
		Position = UDim2.fromOffset(2, 32),

		Size = UDim2.new(1, -4, 0, 30),

		BackgroundTransparency = 1,

		Text = "Control the visual atmosphere and interaction response.",

		TextColor3 = Colors.Muted,

		TextSize = 10,

		Font = Enum.Font.GothamMedium,

		TextXAlignment = Enum.TextXAlignment.Left,

		ZIndex = 40,
	},
	VisualsPage
)

--//==============================================================
--// TOGGLE FACTORY
--//==============================================================

local ToggleObjects = {}

local function CreateToggle(parent, title, description, initial, callback, y)

	local holder = New(
		"Frame",
		{
			Position = UDim2.fromOffset(0, y),

			Size = UDim2.new(1, 0, 0, 78),

			BackgroundColor3 = Colors.Panel,

			BackgroundTransparency = 0.05,

			ZIndex = 35,
		},
		parent
	)

	Corner(holder, 12)

	Stroke(
		holder,
		Colors.Border,
		0.55,
		1
	)

	local titleLabel = New(
		"TextLabel",
		{
			Position = UDim2.fromOffset(18, 15),

			Size = UDim2.new(1, -100, 0, 20),

			BackgroundTransparency = 1,

			Text = title,

			TextColor3 = Colors.Text,

			TextSize = 11,

			Font = Enum.Font.GothamBold,

			TextXAlignment = Enum.TextXAlignment.Left,

			ZIndex = 40,
		},
		holder
	)

	local descLabel = New(
		"TextLabel",
		{
			Position = UDim2.fromOffset(18, 37),

			Size = UDim2.new(1, -100, 0, 25),

			BackgroundTransparency = 1,

			Text = description,

			TextColor3 = Colors.Muted,

			TextSize = 9,

			Font = Enum.Font.GothamMedium,

			TextWrapped = true,

			TextXAlignment = Enum.TextXAlignment.Left,

			ZIndex = 40,
		},
		holder
	)

	local button = New(
		"TextButton",
		{
			AnchorPoint = Vector2.new(1, 0.5),

			Position = UDim2.new(1, -18, 0.5, 0),

			Size = UDim2.fromOffset(48, 25),

			BackgroundColor3 = initial
				and AccentColor()
				or Colors.Panel3,

			BackgroundTransparency = initial and 0.10 or 0.15,

			Text = "",

			AutoButtonColor = false,

			ZIndex = 42,
		},
		holder
	)

	Corner(button, 14)

	local buttonStroke = Stroke(
		button,
		initial and AccentColor() or Colors.Border,
		0.35,
		1
	)

	local knob = New(
		"Frame",
		{
			AnchorPoint = Vector2.new(0, 0.5),

			Position = initial
				and UDim2.new(1, -21, 0.5, 0)
				or UDim2.new(0, 4, 0.5, 0),

			Size = UDim2.fromOffset(17, 17),

			BackgroundColor3 = Colors.White,

			BorderSizePixel = 0,

			ZIndex = 43,
		},
		button
	)

	Corner(knob, 50)

	local current = initial

	local data = {
		Holder = holder,
		Button = button,
		Knob = knob,
		Stroke = buttonStroke,
	}

	table.insert(ToggleObjects, data)

	Connect(button.MouseButton1Click, function()

		current = not current

		Tween(
			button,
			0.28,
			{
				BackgroundColor3 = current
					and AccentColor()
					or Colors.Panel3,
			},
			Enum.EasingStyle.Quint
		)

		Tween(
			knob,
			0.30,
			{
				Position = current
					and UDim2.new(1, -21, 0.5, 0)
					or UDim2.new(0, 4, 0.5, 0),
			},
			Enum.EasingStyle.Quint
		)

		buttonStroke.Color =
			current
			and AccentColor()
			or Colors.Border

		callback(current)

	end)

	return data
end

CreateToggle(
	VisualsPage,
	"SOFT ANIMATIONS",
	"Enables smooth ambient movement and micro transitions.",
	State.Animations,
	function(value)

		State.Animations = value

	end,
	72
)

CreateToggle(
	VisualsPage,
	"NEON AMBIENCE",
	"Adds subtle hue, glow and atmospheric lighting.",
	State.Glow,
	function(value)

		State.Glow = value

	end,
	160
)

CreateToggle(
	VisualsPage,
	"INTERACTION FX",
	"Enables gentle hover and click feedback.",
	State.ClickFX,
	function(value)

		State.ClickFX = value

	end,
	248
)

--//==============================================================
--// PERFORMANCE PAGE
--//==============================================================

local PerformancePage = CreatePage("Performance")

local PerformanceTitle = New(
	"TextLabel",
	{
		Position = UDim2.fromOffset(0, 0),

		Size = UDim2.new(1, 0, 0, 30),

		BackgroundTransparency = 1,

		Text = "SYSTEM TELEMETRY",

		TextColor3 = Colors.Text,

		TextSize = 22,

		Font = Enum.Font.GothamBold,

		TextXAlignment = Enum.TextXAlignment.Left,

		ZIndex = 40,
	},
	PerformancePage
)

local PerformanceSub = New(
	"TextLabel",
	{
		Position = UDim2.fromOffset(2, 32),

		Size = UDim2.new(1, -4, 0, 30),

		BackgroundTransparency = 1,

		Text = "Live interface telemetry and runtime information.",

		TextColor3 = Colors.Muted,

		TextSize = 10,

		Font = Enum.Font.GothamMedium,

		TextXAlignment = Enum.TextXAlignment.Left,

		ZIndex = 40,
	},
	PerformancePage
)

local StatsHolder = New(
	"Frame",
	{
		Position = UDim2.fromOffset(0, 72),

		Size = UDim2.new(1, 0, 0, 240),

		BackgroundTransparency = 1,

		ZIndex = 35,
	},
	PerformancePage
)

local FPSCard = New(
	"Frame",
	{
		Position = UDim2.fromOffset(0, 0),

		Size = UDim2.new(0.48, 0, 0, 100),

		BackgroundColor3 = Colors.Panel,

		BackgroundTransparency = 0.05,

		ZIndex = 35,
	},
	StatsHolder
)

Corner(FPSCard, 12)
Stroke(FPSCard, Colors.Border, 0.55, 1)

local FPSLabel = New(
	"TextLabel",
	{
		Position = UDim2.fromOffset(18, 14),

		Size = UDim2.new(1, -36, 0, 18),

		BackgroundTransparency = 1,

		Text = "FRAME RATE",

		TextColor3 = Colors.Muted,

		TextSize = 9,

		Font = Enum.Font.GothamBold,

		TextXAlignment = Enum.TextXAlignment.Left,

		ZIndex = 40,
	},
	FPSCard
)

local FPSValue = New(
	"TextLabel",
	{
		Position = UDim2.fromOffset(18, 35),

		Size = UDim2.new(1, -36, 0, 40),

		BackgroundTransparency = 1,

		Text = "60",

		TextColor3 = Colors.Text,

		TextSize = 27,

		Font = Enum.Font.GothamBold,

		TextXAlignment = Enum.TextXAlignment.Left,

		ZIndex = 40,
	},
	FPSCard
)

local PingCard = New(
	"Frame",
	{
		AnchorPoint = Vector2.new(1, 0),

		Position = UDim2.new(1, 0, 0, 0),

		Size = UDim2.new(0.48, 0, 0, 100),

		BackgroundColor3 = Colors.Panel,

		BackgroundTransparency = 0.05,

		ZIndex = 35,
	},
	StatsHolder
)

Corner(PingCard, 12)
Stroke(PingCard, Colors.Border, 0.55, 1)

local PingLabel = New(
	"TextLabel",
	{
		Position = UDim2.fromOffset(18, 14),

		Size = UDim2.new(1, -36, 0, 18),

		BackgroundTransparency = 1,

		Text = "RUNTIME",

		TextColor3 = Colors.Muted,

		TextSize = 9,

		Font = Enum.Font.GothamBold,

		TextXAlignment = Enum.TextXAlignment.Left,

		ZIndex = 40,
	},
	PingCard
)

local PingValue = New(
	"TextLabel",
	{
		Position = UDim2.fromOffset(18, 35),

		Size = UDim2.new(1, -36, 0, 40),

		BackgroundTransparency = 1,

		Text = "0s",

		TextColor3 = Colors.Text,

		TextSize = 27,

		Font = Enum.Font.GothamBold,

		TextXAlignment = Enum.TextXAlignment.Left,

		ZIndex = 40,
	},
	PingCard
)

--//==============================================================
--// ABOUT PAGE
--//==============================================================

local AboutPage = CreatePage("About")

local AboutCard = New(
	"Frame",
	{
		Position = UDim2.fromOffset(0, 0),

		Size = UDim2.new(1, 0, 0, 260),

		BackgroundColor3 = Colors.Panel,

		BackgroundTransparency = 0.05,

		ZIndex = 35,
	},
	AboutPage
)

Corner(AboutCard, 14)

Stroke(
	AboutCard,
	Colors.Border,
	0.45,
	1
)

local AboutTitle = New(
	"TextLabel",
	{
		Position = UDim2.fromOffset(25, 25),

		Size = UDim2.new(1, -50, 0, 30),

		BackgroundTransparency = 1,

		Text = "VANZ V7",

		TextColor3 = Colors.Text,

		TextSize = 25,

		Font = Enum.Font.GothamBold,

		TextXAlignment = Enum.TextXAlignment.Left,

		ZIndex = 40,
	},
	AboutCard
)

local AboutDesc = New(
	"TextLabel",
	{
		Position = UDim2.fromOffset(27, 65),

		Size = UDim2.new(1, -54, 0, 100),

		BackgroundTransparency = 1,

		Text = "SOFT ROBOTIC LUXURY COMMAND CENTER\n\nDesigned around smooth motion, restrained glow,\nresponsive controls and a clean robotic interface.",

		TextColor3 = Colors.Muted,

		TextSize = 11,

		Font = Enum.Font.GothamMedium,

		TextWrapped = true,

		TextXAlignment = Enum.TextXAlignment.Left,

		TextYAlignment = Enum.TextYAlignment.Top,

		ZIndex = 40,
	},
	AboutCard
)

local VersionText = New(
	"TextLabel",
	{
		Position = UDim2.fromOffset(27, 205),

		Size = UDim2.new(1, -54, 0, 25),

		BackgroundTransparency = 1,

		Text = "BUILD // 07.00 • STATUS // STABLE",

		TextColor3 = AccentColor(),

		TextSize = 9,

		Font = Enum.Font.Code,

		TextXAlignment = Enum.TextXAlignment.Left,

		ZIndex = 40,
	},
	AboutCard
)

--//==============================================================
--// NAVIGATION BUTTON
--//==============================================================

local function CreateNav(name, label, icon, order)

	local button = New(
		"TextButton",
		{
			Name = name .. "Button",

			LayoutOrder = order,

			Size = UDim2.new(1, 0, 0, 42),

			BackgroundColor3 = Colors.Panel2,

			BackgroundTransparency = 1,

			Text = "",

			AutoButtonColor = false,

			ZIndex = 40,
		},
		NavHolder
	)

	Corner(button, 9)

	local activeBar = New(
		"Frame",
		{
			Position = UDim2.fromOffset(0, 8),

			Size = UDim2.fromOffset(2, 26),

			BackgroundColor3 = AccentColor(),

			BackgroundTransparency = 1,

			BorderSizePixel = 0,

			ZIndex = 45,
		},
		button
	)

	Corner(activeBar, 3)

	local iconLabel = New(
		"TextLabel",
		{
			Position = UDim2.fromOffset(14, 0),

			Size = UDim2.fromOffset(25, 42),

			BackgroundTransparency = 1,

			Text = icon,

			TextColor3 = Colors.Muted,

			TextSize = 13,

			Font = Enum.Font.GothamBold,

			ZIndex = 42,
		},
		button
	)

	local textLabel = New(
		"TextLabel",
		{
			Position = UDim2.fromOffset(43, 0),

			Size = UDim2.new(1, -52, 1, 0),

			BackgroundTransparency = 1,

			Text = label,

			TextColor3 = Colors.Muted,

			TextSize = 10,

			Font = Enum.Font.GothamBold,

			TextXAlignment = Enum.TextXAlignment.Left,

			ZIndex = 42,
		},
		button
	)

	local function SetActive(active)

		Tween(
			button,
			0.30,
			{
				BackgroundTransparency = active and 0.15 or 1,
			},
			Enum.EasingStyle.Quint
		)

		Tween(
			activeBar,
			0.30,
			{
				BackgroundTransparency = active and 0 or 1,
			},
			Enum.EasingStyle.Quint
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

	Connect(button.MouseEnter, function()

		if State.ClickFX and State.CurrentPage ~= name then

			Tween(
				button,
				0.20,
				{
					BackgroundTransparency = 0.72,
				},
				Enum.EasingStyle.Sine
			)

		end

	end)

	Connect(button.MouseLeave, function()

		if State.CurrentPage ~= name then

			Tween(
				button,
				0.20,
				{
					BackgroundTransparency = 1,
				},
				Enum.EasingStyle.Sine
			)

		end

	end)

	Connect(button.MouseButton1Click, function()

		if State.CurrentPage == name then
			return
		end

		State.CurrentPage = name

		for pageName, page in pairs(Pages) do

			if pageName == name then

				page.Visible = true
				page.Position = UDim2.new(0, 18, 0, 0)

				Tween(
					page,
					0.35,
					{
						Position = UDim2.fromOffset(0, 0),
					},
					Enum.EasingStyle.Quint
				)

			else

				page.Visible = false

			end

		end

		for navName, nav in pairs(NavButtons) do
			nav.SetActive(navName == name)
		end

	end)

	return button
end

CreateNav("Home", "OVERVIEW", "◈", 1)
CreateNav("Visuals", "VISUAL SYSTEM", "✦", 2)
CreateNav("Performance", "TELEMETRY", "⌁", 3)
CreateNav("About", "ABOUT VANZ", "◇", 4)

-- Initial page
HomePage.Visible = true
NavButtons.Home.SetActive(true)

--//==============================================================
--// SIDEBAR SYSTEM STATUS
--//==============================================================

local SystemBox = New(
	"Frame",
	{
		AnchorPoint = Vector2.new(0, 1),

		Position = UDim2.new(0, 12, 1, -14),

		Size = UDim2.new(1, -24, 0, 90),

		BackgroundColor3 = Colors.Panel2,

		BackgroundTransparency = 0.10,

		ZIndex = 35,
	},
	Sidebar
)

Corner(SystemBox, 11)

Stroke(
	SystemBox,
	Colors.Border,
	0.65,
	1
)

local SystemLabel = New(
	"TextLabel",
	{
		Position = UDim2.fromOffset(13, 12),

		Size = UDim2.new(1, -26, 0, 16),

		BackgroundTransparency = 1,

		Text = "CORE STATUS",

		TextColor3 = Colors.Soft,

		TextSize = 8,

		Font = Enum.Font.GothamBold,

		TextXAlignment = Enum.TextXAlignment.Left,

		ZIndex = 40,
	},
	SystemBox
)

local SystemValue = New(
	"TextLabel",
	{
		Position = UDim2.fromOffset(13, 30),

		Size = UDim2.new(1, -26, 0, 18),

		BackgroundTransparency = 1,

		Text = "STABLE / ONLINE",

		TextColor3 = Colors.Success,

		TextSize = 9,

		Font = Enum.Font.GothamBold,

		TextXAlignment = Enum.TextXAlignment.Left,

		ZIndex = 40,
	},
	SystemBox
)

local SystemBar = New(
	"Frame",
	{
		Position = UDim2.fromOffset(13, 57),

		Size = UDim2.new(1, -26, 0, 4),

		BackgroundColor3 = Colors.Panel3,

		BorderSizePixel = 0,

		ZIndex = 40,
	},
	SystemBox
)

Corner(SystemBar, 3)

local SystemFill = New(
	"Frame",
	{
		Size = UDim2.new(0.92, 0, 1, 0),

		BackgroundColor3 = AccentColor(),

		BorderSizePixel = 0,

		ZIndex = 41,
	},
	SystemBar
)

Corner(SystemFill, 3)

--//==============================================================
--// FLOATING RESTORE BUTTON
--//==============================================================

local FloatingButton = New(
	"TextButton",
	{
		Name = "FloatingRestore",

		AnchorPoint = Vector2.new(1, 1),

		Position = UDim2.new(1, -25, 1, -25),

		Size = UDim2.fromOffset(54, 54),

		BackgroundColor3 = Colors.Panel,

		BackgroundTransparency = 0.05,

		Text = "V",

		TextColor3 = Colors.Text,

		TextSize = 18,

		Font = Enum.Font.GothamBold,

		AutoButtonColor = false,

		Visible = false,

		ZIndex = 100,
	},
	ScreenGui
)

Corner(FloatingButton, 50)

local FloatingStroke = Stroke(
	FloatingButton,
	AccentColor(),
	0.25,
	1
)

local FloatingScale = New(
	"UIScale",
	{
		Scale = 1,
	},
	FloatingButton
)

Connect(FloatingButton.MouseButton1Click, function()

	State.Minimized = false

	FloatingButton.Visible = false

	MainHolder.Visible = true

	MainHolder.Position = UDim2.fromScale(0.5, 0.53)

	Tween(
		MainHolder,
		0.45,
		{
			Position = UDim2.fromScale(0.5, 0.5),
		},
		Enum.EasingStyle.Quint
	)

end)

--//==============================================================
--// DRAG SYSTEM
--//==============================================================

local Dragging = false
local DragStart
local StartPosition

Connect(Header.InputBegan, function(input)

	if input.UserInputType == Enum.UserInputType.MouseButton1
		or input.UserInputType == Enum.UserInputType.Touch then

		Dragging = true

		DragStart = input.Position
		StartPosition = MainHolder.Position

	end

end)

Connect(UserInputService.InputChanged, function(input)

	if not Dragging then
		return
	end

	if input.UserInputType ~= Enum.UserInputType.MouseMovement
		and input.UserInputType ~= Enum.UserInputType.Touch then

		return
	end

	local delta = input.Position - DragStart

	local viewport = workspace.CurrentCamera
		and viewport.ViewportSize
		or Vector2.new(1920, 1080)

	local scale = UIScale.Scale

	local offsetX = delta.X / viewport.X
	local offsetY = delta.Y / viewport.Y

	MainHolder.Position = UDim2.new(
		StartPosition.X.Scale + offsetX,
		StartPosition.X.Offset,
		StartPosition.Y.Scale + offsetY,
		StartPosition.Y.Offset
	)

end)

Connect(UserInputService.InputEnded, function(input)

	if input.UserInputType == Enum.UserInputType.MouseButton1
		or input.UserInputType == Enum.UserInputType.Touch then

		Dragging = false

	end

end)

--//==============================================================
--// MINIMIZE
--//==============================================================

local function Minimize()

	if State.Minimized then
		return
	end

	State.Minimized = true

	Tween(
		MainHolder,
		0.38,
		{
			Size = UDim2.fromOffset(
				_G.vanz.Config.Width * 0.55,
				_G.vanz.Config.Height * 0.55
			),

			Position = UDim2.fromScale(
				0.5,
				0.54
			),
		},
		Enum.EasingStyle.Quint
	)

	task.delay(0.28, function()

		if State.Destroyed then
			return
		end

		MainHolder.Visible = false

		FloatingButton.Visible = true

	end)

end

Connect(MinimizeButton.MouseButton1Click, Minimize)

--//==============================================================
--// CLOSE
--//==============================================================

local function ForceStop()

	if State.Destroyed then
		return
	end

	State.Destroyed = true

	for _, connection in ipairs(Connections) do

		if connection then
			pcall(function()
				connection:Disconnect()
			end)
		end

	end

	table.clear(Connections)

	for _, cleanup in ipairs(Cleanups) do

		pcall(cleanup)

	end

	table.clear(Cleanups)

	if ScreenGui then
		ScreenGui:Destroy()
	end

	_G.vanz.Gui = nil

end

_G.vanz.ForceStop = ForceStop

Connect(CloseButton.MouseButton1Click, ForceStop)

--//==============================================================
--// BUTTON HOVER
--//==============================================================

local function SetupButtonHover(button, normalColor, hoverColor)

	Connect(button.MouseEnter, function()

		if not State.ClickFX then
			return
		end

		Tween(
			button,
			0.22,
			{
				BackgroundColor3 = hoverColor,
			},
			Enum.EasingStyle.Sine
		)

	end)

	Connect(button.MouseLeave, function()

		Tween(
			button,
			0.22,
			{
				BackgroundColor3 = normalColor,
			},
			Enum.EasingStyle.Sine
		)

	end)

end

SetupButtonHover(
	MinimizeButton,
	Colors.Panel3,
	AccentSoft()
)

SetupButtonHover(
	CloseButton,
	Colors.Panel3,
	Color3.fromRGB(75, 28, 40)
)

--//==============================================================
--// RESPONSIVE
--//==============================================================

local function UpdateResponsive()

	if not _G.vanz.Config.Responsive then
		return
	end

	local camera = workspace.CurrentCamera

	if not camera then
		return
	end

	local viewport = camera.ViewportSize

	local baseWidth = _G.vanz.Config.Width
	local baseHeight = _G.vanz.Config.Height

	local maxWidth = viewport.X - 28
	local maxHeight = viewport.Y - 28

	local width = math.min(baseWidth, maxWidth)
	local height = math.min(baseHeight, maxHeight)

	if viewport.X < 700 then

		width = math.min(baseWidth, maxWidth)
		height = math.min(baseHeight, maxHeight)

	end

	if width < 400 then
		width = math.max(300, maxWidth)
	end

	if height < 350 then
		height = math.max(300, maxHeight)
	end

	MainHolder.Size = UDim2.fromOffset(
		width,
		height
	)

end

Connect(workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"), UpdateResponsive)

UpdateResponsive()

--//==============================================================
--// PUBLIC API
--//==============================================================

function _G.vanz.Open()

	if State.Destroyed then
		return
	end

	State.Minimized = false

	MainHolder.Visible = true
	FloatingButton.Visible = false

	MainHolder.Position = UDim2.fromScale(
		0.5,
		0.53
	)

	MainHolder.Size = UDim2.fromOffset(
		_G.vanz.Config.Width * 0.94,
		_G.vanz.Config.Height * 0.94
	)

	Tween(
		MainHolder,
		0.48,
		{
			Position = UDim2.fromScale(0.5, 0.5),

			Size = UDim2.fromOffset(
				_G.vanz.Config.Width,
				_G.vanz.Config.Height
			),
		},
		Enum.EasingStyle.Quint,
		Enum.EasingDirection.Out
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
			Position = UDim2.fromScale(
				0.5,
				0.54
			),
		},
		Enum.EasingStyle.Quint
	)

	task.delay(0.32, function()

		if not State.Destroyed then
			MainHolder.Visible = false
		end

	end)

end

function _G.vanz.SetScale(value)

	if State.Destroyed then
		return
	end

	value = math.clamp(
		tonumber(value) or State.Scale,
		0.5,
		1
	)

	State.Scale = value

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

--//==============================================================
--// SOFT PARTICLES
--//==============================================================

local Particles = {}

if _G.vanz.Config.EnableParticles then

	for i = 1, 12 do

		local particle = New(
			"Frame",
			{
				Name = "SoftParticle_" .. i,

				Size = UDim2.fromOffset(
					math.random(1, 3),
					math.random(1, 3)
				),

				BackgroundColor3 = AccentColor(
					math.random()
				),

				BackgroundTransparency = math.random(
					60,
					85
				) / 100,

				BorderSizePixel = 0,

				ZIndex = 18,
			},
			MainPanel
		)

		Corner(particle, 50)

		particle.Position = UDim2.new(
			math.random(),
			0,
			math.random(),
			0
		)

		table.insert(
			Particles,
			{
				Object = particle,

				X = math.random(),

				Y = math.random(),

				Speed = math.random(5, 14) / 10000,

				Offset = math.random() * 10,
			}
		)

	end

end

--//==============================================================
--// ANIMATION ENGINE
--//==============================================================

local RuntimeFrames = 0
local RuntimeAccumulator = 0

local FPSAccumulator = 0
local FPSFrames = 0
local FPS = 60

Connect(RunService.RenderStepped, function(deltaTime)

	if State.Destroyed then
		return
	end

	State.Time += deltaTime

	RuntimeAccumulator += deltaTime
	FPSAccumulator += deltaTime
	FPSFrames += 1

	if FPSAccumulator >= 0.5 then

		FPS = math.floor(
			FPSFrames / FPSAccumulator
		)

		FPSAccumulator = 0
		FPSFrames = 0

	end

	--==========================================================
	-- TOPMOST WATCHDOG
	--==========================================================

	if ScreenGui.Parent ~= PlayerGui then
		ScreenGui.Parent = PlayerGui
	end

	if ScreenGui.DisplayOrder ~= _G.vanz.Config.DisplayOrder then
		ScreenGui.DisplayOrder = _G.vanz.Config.DisplayOrder
	end

	--==========================================================
	-- SOFT ANIMATION
	--==========================================================

	if State.Animations then

		State.Hue = (
			State.Hue
			+ deltaTime * 0.012
		) % 1

		local primary = AccentColor()
		local secondary = AccentSoft(0.08)

		-- Main border
		MainStroke.Color = LerpColor(
			MainStroke.Color,
			primary,
			math.clamp(deltaTime * 3, 0, 1)
		)

		-- Logo
		LogoOuter.Rotation =
			LogoOuter.Rotation
			+ deltaTime * 4

		LogoMiddle.Rotation =
			LogoMiddle.Rotation
			- deltaTime * 7

		local breathe =
			0.5
			+ math.sin(
				State.Time * 1.4
			) * 0.5

		local logoSize =
			14
			+ breathe * 3

		LogoCore.Size = UDim2.fromOffset(
			logoSize,
			logoSize
		)

		LogoCore.BackgroundColor3 = primary
		LogoOuterStroke.Color = primary
		LogoMiddleStroke.Color = secondary

		-- Radar
		RadarOuter.Rotation =
			RadarOuter.Rotation
			+ deltaTime * 3

		RadarMiddle.Rotation =
			RadarMiddle.Rotation
			- deltaTime * 4

		RadarSweep.Rotation =
			RadarSweep.Rotation
			+ deltaTime * 30

		RadarCore.BackgroundColor3 = primary

		-- Aura
		if State.Glow then

			local glowWave =
				0.90
				+ math.sin(
					State.Time * 1.25
				) * 0.025

			Aura.BackgroundTransparency =
				glowWave

			HeroGlow.BackgroundTransparency =
				0.93
				+ math.sin(
					State.Time * 1.1
				) * 0.015

		else

			Aura.BackgroundTransparency = 1
			HeroGlow.BackgroundTransparency = 1

		end

		-- Online pulse
		local onlinePulse =
			0.45
			+ math.sin(
				State.Time * 2.1
			) * 0.20

		OnlineDot.BackgroundTransparency =
			math.clamp(
				onlinePulse,
				0.15,
				0.70
			)

		OnlineStroke.Color = Colors.Success

		-- Hero status
		HeroStatusDot.BackgroundTransparency =
			0.35
			+ math.sin(
				State.Time * 2
			) * 0.15

		-- Top laser
		local laserTime =
			(State.Time * 0.16) % 1.2

		TopLaser.Position =
			UDim2.new(
				laserTime - 0.2,
				0,
				0,
				0
			)

		TopLaser.BackgroundColor3 = primary

		-- System fill
		SystemFill.BackgroundColor3 = primary

		-- Floating button
		if FloatingButton.Visible then

			local pulse =
				1
				+ math.sin(
					State.Time * 1.8
				) * 0.035

			FloatingScale.Scale = pulse

			FloatingStroke.Color = primary

		end

		-- Soft particles
		for _, data in ipairs(Particles) do

			local object = data.Object

			if object and object.Parent then

				data.Y =
					(data.Y + data.Speed)
					% 1.05

				local wave =
					math.sin(
						State.Time * 0.45
						+ data.Offset
					) * 0.025

				object.Position = UDim2.new(
					data.X + wave,
					0,
					data.Y,
					0
				)

				object.BackgroundColor3 =
					AccentColor(
						data.Offset / 20
					)

			end

		end

		-- Version accent
		VersionText.TextColor3 = primary

	end

	--==========================================================
	-- TELEMETRY
	--==========================================================

	if State.Time > 0 then

		PingValue.Text =
			string.format(
				"%ds",
				math.floor(State.Time)
			)

		FPSValue.Text =
			tostring(
				math.clamp(FPS, 1, 240)
			)

		Telemetry.Text =
			string.format(
				"SYS // %02d FPS",
				math.clamp(FPS, 1, 99)
			)

	end

end)

--//==============================================================
--// STARTUP ANIMATION
--//==============================================================

MainHolder.Visible = true

MainHolder.Position =
	UDim2.fromScale(
		0.5,
		0.54
	)

MainHolder.Size =
	UDim2.fromOffset(
		_G.vanz.Config.Width * 0.92,
		_G.vanz.Config.Height * 0.92
	)

MainPanel.BackgroundTransparency = 1

Tween(
	MainHolder,
	0.65,
	{
		Position = UDim2.fromScale(
			0.5,
			0.5
		),

		Size = UDim2.fromOffset(
			_G.vanz.Config.Width,
			_G.vanz.Config.Height
		),
	},
	Enum.EasingStyle.Quint,
	Enum.EasingDirection.Out
)

Tween(
	MainPanel,
	0.55,
	{
		BackgroundTransparency = 0.02,
	},
	Enum.EasingStyle.Sine
)

--//==============================================================
--// INITIAL FADE-IN ELEMENTS
--//==============================================================

local InitialObjects = {
	LogoContainer,
	Title,
	Subtitle,
	Telemetry,
	Online,
	Body,
}

for _, object in ipairs(InitialObjects) do

	local original = object.BackgroundTransparency

	if object:IsA("GuiObject") then

		if object == Body
			or object == LogoContainer then

			object.BackgroundTransparency = 1

		end

	end

end

--//==============================================================
--// CLEANUP ON PLAYER LEAVE
--//==============================================================

Connect(
	Players.PlayerRemoving,
	function(player)

		if player == LocalPlayer then
			ForceStop()
		end

	end
)

--//==============================================================
--// FINAL PUBLIC STATE
--//==============================================================

_G.vanz.State = State
_G.vanz.Gui = ScreenGui

print(
	"[VANZ V7] Soft Robotic Luxury Command Center loaded."
)

print(
	"[VANZ V7] Smooth animation engine: ONLINE"
)

print(
	"[VANZ V7] Display priority: " ..
	tostring(_G.vanz.Config.DisplayOrder)
)

--//==============================================================
--// END OF VANZ V7
--//==============================================================