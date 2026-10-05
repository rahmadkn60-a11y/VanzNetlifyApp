--//==============================================================\\
--// VANZ // NEURAL CYBER ANIME COMMAND CENTER
--// VERSION 10
--// MOBILE SAFE / ROBOTIC / ANIME HUD / DRAGGABLE
--//==============================================================\\
--
--  CORE DESIGN
--
--  HEADER
--  ┌──────────────────────────────────────────────────────────┐
--  │ LOGO │       SAFE TITLE ZONE       │ MINIMIZE │ CLOSE   │
--  └──────────────────────────────────────────────────────────┘
--
--  MOBILE
--
--  ┌──────────────────────────────────────────────────────────┐
--  │ LOGO │        TITLE OR NOTHING       │  MIN  │  X       │
--  ├──────────────────────────────────────────────────────────┤
--  │                                                          │
--  │                    CONTENT                               │
--  │                                                          │
--  ├──────────────────────────────────────────────────────────┤
--  │       HOME       VISUAL       DATA       CORE             │
--  └──────────────────────────────────────────────────────────┘
--
--  IMPORTANT:
--  The control zone is structurally independent.
--  No title, subtitle, status pill or decorative object is
--  allowed to occupy the control zone.
--
--==============================================================\\

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
-- GLOBAL CONFIG
--==============================================================

local CONFIG = {

	Name = "VANZ_NEURAL_CYBER_GUI",

	Title = "VANZ",

	Subtitle = "NEURAL COMMAND SYSTEM",

	DisplayOrder = 2147483647,

	DesktopWidth = 1000,

	DesktopHeight = 640,

	MobileMargin = 6,

	HeaderDesktop = 86,

	HeaderMobile = 82,

	ControlWidthDesktop = 196,

	ControlWidthMobile = 116,

	ControlButtonDesktop = 92,

	ControlButtonMobile = 52,

	AnimationSpeed = 1,

	Particles = true,

	Scanlines = true,

	Glow = true,

	HUD = true,

	Responsive = true,

}

--==============================================================
-- STATE
--==============================================================

local STATE = {

	Destroyed = false,

	Mobile = false,

	Minimized = false,

	CurrentPage = "HOME",

	DraggingWindow = false,

	DraggingMini = false,

	MovedMini = false,

	Animations = true,

	Glow = true,

	Particles = true,

	HUD = true,

	Hue = 0,

	Time = 0,

	FPS = 60,

	WindowDragged = false,

}

_G.vanz = {}

_G.vanz.Config = CONFIG

_G.vanz.State = STATE

--==============================================================
-- CLEANUP
--==============================================================

local Connections = {}

local function Connect(signal, callback)

	if STATE.Destroyed then
		return
	end

	local connection = signal:Connect(callback)

	table.insert(Connections, connection)

	return connection

end

local function Cleanup()

	for _, connection in ipairs(Connections) do

		pcall(function()
			connection:Disconnect()
		end)

	end

	table.clear(Connections)

end

--==============================================================
-- HELPERS
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

local function Border(object, color, transparency, thickness)

	local stroke = Instance.new("UIStroke")

	stroke.Color = color

	stroke.Transparency = transparency or 0

	stroke.Thickness = thickness or 1

	stroke.Parent = object

	return stroke

end

local function Tween(
	object,
	duration,
	properties,
	style,
	direction
)

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

local function Clamp(v, min, max)

	return math.clamp(v, min, max)

end

--==============================================================
-- COLOR SYSTEM
--==============================================================

local COLOR = {

	Black = Color3.fromRGB(
		3,
		5,
		9
	),

	Background = Color3.fromRGB(
		7,
		10,
		17
	),

	Panel = Color3.fromRGB(
		11,
		16,
		26
	),

	Panel2 = Color3.fromRGB(
		16,
		22,
		35
	),

	Panel3 = Color3.fromRGB(
		22,
		29,
		45
	),

	White = Color3.fromRGB(
		245,
		248,
		255
	),

	Text = Color3.fromRGB(
		232,
		238,
		250
	),

	Muted = Color3.fromRGB(
		139,
		153,
		180
	),

	Dim = Color3.fromRGB(
		78,
		91,
		119
	),

	Success = Color3.fromRGB(
		102,
		240,
		180
	),

	Danger = Color3.fromRGB(
		255,
		92,
		120
	),

	Warning = Color3.fromRGB(
		255,
		200,
		100
	),

	Cyan = Color3.fromRGB(
		80,
		220,
		255
	),

	Pink = Color3.fromRGB(
		255,
		105,
		220
	),

	Purple = Color3.fromRGB(
		150,
		100,
		255
	),

}

local function Accent(offset)

	offset = offset or 0

	local hue =
		(
			STATE.Hue
			+ offset
		)
		% 1

	return Color3.fromHSV(
		hue,
		0.65,
		1
	)

end

local function AccentSoft(offset)

	offset = offset or 0

	local hue =
		(
			STATE.Hue
			+ offset
		)
		% 1

	return Color3.fromHSV(
		hue,
		0.35,
		1
	)

end

--==============================================================
-- REMOVE OLD GUI
--==============================================================

local OLD_NAMES = {

	"VANZ_ROBOTIC_GUI",

	"VANZ_PREMIUM_GUI",

	"VANZ_SOFT_ROBOTIC_GUI",

	"VANZ_MOBILE_SOFT_GUI",

	"VANZ_V9_GUI",

	"VANZ_NEURAL_CYBER_GUI",

}

for _, name in ipairs(OLD_NAMES) do

	local old =
		PlayerGui:FindFirstChild(name)

	if old then

		pcall(function()
			old:Destroy()
		end)

	end

end

--==============================================================
-- SCREEN GUI
--==============================================================

local ScreenGui = New(

	"ScreenGui",

	{

		Name = CONFIG.Name,

		ResetOnSpawn = false,

		IgnoreGuiInset = true,

		DisplayOrder = CONFIG.DisplayOrder,

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
-- MASTER SCALE
--==============================================================

local MasterScale = New(

	"UIScale",

	{

		Scale = 1,

	},

	ScreenGui

)

--==============================================================
-- WINDOW ROOT
--==============================================================

local Window = New(

	"Frame",

	{

		Name = "Window",

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
				CONFIG.DesktopWidth,
				CONFIG.DesktopHeight
			),

		BackgroundTransparency = 1,

		ZIndex = 100,

	},

	ScreenGui

)

--==============================================================
-- WINDOW SHADOW
--==============================================================

local Shadow = New(

	"Frame",

	{

		Position =
			UDim2.fromOffset(
				8,
				10
			),

		Size =
			UDim2.fromScale(
				1,
				1
			),

		BackgroundColor3 =
			Color3.new(
				0,
				0,
				0
			),

		BackgroundTransparency =
			0.35,

		ZIndex = 90,

	},

	Window

)

Corner(
	Shadow,
	24
)

--==============================================================
-- OUTER AURA
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
			0.94,

		ZIndex = 91,

	},

	Window

)

Corner(
	Aura,
	27
)

--==============================================================
-- MAIN PANEL
--==============================================================

local Panel = New(

	"Frame",

	{

		Name = "Panel",

		Size =
			UDim2.fromScale(
				1,
				1
			),

		BackgroundColor3 =
			COLOR.Background,

		BorderSizePixel = 0,

		ClipsDescendants = true,

		ZIndex = 100,

	},

	Window

)

Corner(
	Panel,
	22
)

local PanelStroke =
	Border(
		Panel,
		Accent(),
		0.2,
		1
	)

--==============================================================
-- BACKGROUND HUD GRID
--==============================================================

local Grid = New(

	"Frame",

	{

		Name = "HUDGrid",

		Size =
			UDim2.fromScale(
				1,
				1
			),

		BackgroundTransparency = 1,

		ClipsDescendants = true,

		ZIndex = 105,

	},

	Panel

)

for i = 0, 18 do

	local line = New(

		"Frame",

		{

			Position =
				UDim2.new(
					i / 18,
					0,
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
				Accent(),

			BackgroundTransparency =
				0.965,

			BorderSizePixel = 0,

			ZIndex = 106,

		},

		Grid

	)

end

for i = 0, 12 do

	local line = New(

		"Frame",

		{

			Position =
				UDim2.new(
					0,
					0,
					i / 12,
					0
				),

			Size =
				UDim2.new(
					1,
					0,
					0,
					1
				),

			BackgroundColor3 =
				Accent(0.1),

			BackgroundTransparency =
				0.97,

			BorderSizePixel = 0,

			ZIndex = 106,

		},

		Grid

	)

end

--==============================================================
-- HEADER
--==============================================================

local Header = New(

	"Frame",

	{

		Name = "Header",

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
				CONFIG.HeaderDesktop
			),

		BackgroundColor3 =
			COLOR.Panel,

		BorderSizePixel = 0,

		ZIndex = 300,

	},

	Panel

)

Corner(
	Header,
	22
)

local HeaderBottom = New(

	"Frame",

	{

		Position =
			UDim2.new(
				0,
				0,
				1,
				-22
			),

		Size =
			UDim2.new(
				1,
				0,
				0,
				22
			),

		BackgroundColor3 =
			COLOR.Panel,

		BorderSizePixel = 0,

		ZIndex = 300,

	},

	Header

)

--==============================================================
-- HEADER ENERGY LINE
--==============================================================

local HeaderEnergy = New(

	"Frame",

	{

		Position =
			UDim2.new(
				0,
				0,
				1,
				-2
			),

		Size =
			UDim2.new(
				1,
				0,
				0,
				2
			),

		BackgroundColor3 =
			Accent(),

		BorderSizePixel = 0,

		ZIndex = 350,

	},

	Header

)

--==============================================================
-- LOGO AREA
--==============================================================

local LogoArea = New(

	"Frame",

	{

		Position =
			UDim2.fromOffset(
				10,
				10
			),

		Size =
			UDim2.fromOffset(
				64,
				64
			),

		BackgroundTransparency = 1,

		ZIndex = 350,

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
				58,
				58
			),

		BackgroundTransparency = 1,

		ZIndex = 351,

	},

	LogoArea

)

Corner(
	LogoOuter,
	50
)

local LogoOuterStroke =
	Border(
		LogoOuter,
		Accent(),
		0.15,
		2
	)

local LogoMiddle = New(

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
				43,
				43
			),

		BackgroundTransparency = 1,

		ZIndex = 352,

	},

	LogoArea

)

Corner(
	LogoMiddle,
	50
)

local LogoMiddleStroke =
	Border(
		LogoMiddle,
		AccentSoft(0.1),
		0.25,
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

		ZIndex = 355,

	},

	LogoArea

)

Corner(
	LogoCore,
	50
)

--==============================================================
-- LOGO DRAG BUTTON
--==============================================================

local LogoDragButton = New(

	"TextButton",

	{

		Size =
			UDim2.fromScale(
				1,
				1
			),

		BackgroundTransparency = 1,

		Text = "",

		AutoButtonColor = false,

		ZIndex = 370,

	},

	LogoArea

)

--==============================================================
-- TITLE ZONE
--
-- THIS IS THE IMPORTANT FIX.
--
-- It is not positioned using a magic negative width.
-- It occupies the space between logo and CONTROL DOCK.
--==============================================================

local TitleZone = New(

	"Frame",

	{

		Name = "TitleZone",

		Position =
			UDim2.fromOffset(
				82,
				8
			),

		Size =
			UDim2.new(
				1,
				-296,
				1,
				-16
			),

		BackgroundTransparency = 1,

		ClipsDescendants = true,

		ZIndex = 330,

	},

	Header

)

local Title = New(

	"TextLabel",

	{

		Position =
			UDim2.fromOffset(
				0,
				5
			),

		Size =
			UDim2.new(
				1,
				0,
				0,
				32
			),

		BackgroundTransparency = 1,

		Text =
			CONFIG.Title,

		TextColor3 =
			COLOR.Text,

		TextSize = 25,

		Font =
			Enum.Font.GothamBold,

		TextTruncate =
			Enum.TextTruncate.AtEnd,

		TextXAlignment =
			Enum.TextXAlignment.Left,

		ZIndex = 340,

	},

	TitleZone

)

local Subtitle = New(

	"TextLabel",

	{

		Position =
			UDim2.fromOffset(
				0,
				40
			),

		Size =
			UDim2.new(
				1,
				0,
				0,
				20
			),

		BackgroundTransparency = 1,

		Text =
			CONFIG.Subtitle,

		TextColor3 =
			COLOR.Muted,

		TextSize = 10,

		Font =
			Enum.Font.GothamMedium,

		TextTruncate =
			Enum.TextTruncate.AtEnd,

		TextXAlignment =
			Enum.TextXAlignment.Left,

		ZIndex = 340,

	},

	TitleZone

)

--==============================================================
-- CONTROL DOCK
--
-- ABSOLUTELY INDEPENDENT.
--==============================================================

local ControlDock = New(

	"Frame",

	{

		Name = "ProtectedControlDock",

		AnchorPoint =
			Vector2.new(
				1,
				0
			),

		Position =
			UDim2.new(
				1,
				-7,
				0,
				8
			),

		Size =
			UDim2.fromOffset(
				CONFIG.ControlWidthDesktop,
				70
			),

		BackgroundTransparency = 1,

		ZIndex = 500,

	},

	Header

)

--==============================================================
-- MINIMIZE BUTTON
--==============================================================

local Minimize = New(

	"TextButton",

	{

		Name = "Minimize",

		Position =
			UDim2.fromOffset(
				0,
				0
			),

		Size =
			UDim2.fromOffset(
				CONFIG.ControlButtonDesktop,
				64
			),

		BackgroundColor3 =
			COLOR.Panel3,

		BackgroundTransparency = 0.03,

		Text = "—",

		TextColor3 =
			COLOR.Text,

		TextSize = 25,

		Font =
			Enum.Font.GothamBold,

		AutoButtonColor = false,

		ZIndex = 520,

	},

	ControlDock

)

Corner(
	Minimize,
	14
)

local MinStroke =
	Border(
		Minimize,
		COLOR.Dim,
		0.35,
		1
	)

--==============================================================
-- CLOSE BUTTON
--==============================================================

local Close = New(

	"TextButton",

	{

		Name = "Close",

		Position =
			UDim2.fromOffset(
				104,
				0
			),

		Size =
			UDim2.fromOffset(
				CONFIG.ControlButtonDesktop,
				64
			),

		BackgroundColor3 =
			COLOR.Panel3,

		BackgroundTransparency = 0.03,

		Text = "×",

		TextColor3 =
			COLOR.Text,

		TextSize = 29,

		Font =
			Enum.Font.GothamBold,

		AutoButtonColor = false,

		ZIndex = 520,

	},

	ControlDock

)

Corner(
	Close,
	14
)

local CloseStroke =
	Border(
		Close,
		COLOR.Dim,
		0.35,
		1
	)

--==============================================================
-- HEADER DRAG ZONE
--
-- Starts AFTER LOGO.
-- Ends BEFORE CONTROL DOCK.
--==============================================================

local HeaderDrag = New(

	"TextButton",

	{

		Name = "HeaderDrag",

		Position =
			UDim2.fromOffset(
				76,
				0
			),

		Size =
			UDim2.new(
				1,
				-292,
				1,
				0
			),

		BackgroundTransparency = 1,

		Text = "",

		AutoButtonColor = false,

		ZIndex = 325,

	},

	Header

)

--==============================================================
-- BODY
--==============================================================

local Body = New(

	"Frame",

	{

		Name = "Body",

		Position =
			UDim2.fromOffset(
				0,
				CONFIG.HeaderDesktop
			),

		Size =
			UDim2.new(
				1,
				0,
				1,
				-CONFIG.HeaderDesktop
			),

		BackgroundTransparency = 1,

		ClipsDescendants = true,

		ZIndex = 200,

	},

	Panel

)

--==============================================================
-- DESKTOP SIDEBAR
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
				214,
				1,
				0
			),

		BackgroundColor3 =
			COLOR.Panel,

		BorderSizePixel = 0,

		ZIndex = 220,

	},

	Body

)

local SidebarLine = New(

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
			UDim2.new(
				0,
				1,
				1,
				0
			),

		BackgroundColor3 =
			Accent(),

		BackgroundTransparency =
			0.65,

		BorderSizePixel = 0,

		ZIndex = 250,

	},

	Sidebar

)

--==============================================================
-- SIDEBAR HEADER
--==============================================================

local SideTitle = New(

	"TextLabel",

	{

		Position =
			UDim2.fromOffset(
				19,
				18
			),

		Size =
			UDim2.new(
				1,
				-38,
				0,
				20
			),

		BackgroundTransparency = 1,

		Text =
			"NEURAL MENU",

		TextColor3 =
			COLOR.Dim,

		TextSize = 10,

		Font =
			Enum.Font.GothamBold,

		TextXAlignment =
			Enum.TextXAlignment.Left,

		ZIndex = 240,

	},

	Sidebar

)

--==============================================================
-- DESKTOP NAV
--==============================================================

local DesktopNav = New(

	"Frame",

	{

		Position =
			UDim2.fromOffset(
				11,
				50
			),

		Size =
			UDim2.new(
				1,
				-22,
				0,
				260
			),

		BackgroundTransparency = 1,

		ZIndex = 250,

	},

	Sidebar

)

local DesktopLayout =
	Instance.new("UIListLayout")

DesktopLayout.Padding =
	UDim.new(
		0,
		8
	)

DesktopLayout.SortOrder =
	Enum.SortOrder.LayoutOrder

DesktopLayout.Parent =
	DesktopNav

--==============================================================
-- CONTENT
--==============================================================

local Content = New(

	"Frame",

	{

		Position =
			UDim2.fromOffset(
				214,
				0
			),

		Size =
			UDim2.new(
				1,
				-214,
				1,
				0
			),

		BackgroundTransparency = 1,

		ClipsDescendants = true,

		ZIndex = 230,

	},

	Body

)

--==============================================================
-- PAGE SCROLLING
--==============================================================

local Pages = {}

local Navigation = {}

local function CreatePage(name)

	local page = New(

		"ScrollingFrame",

		{

			Name =
				name .. "Page",

			Position =
				UDim2.fromScale(
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

			ZIndex = 240,

		},

		Content

	)

	local padding =
		Instance.new(
			"UIPadding"
		)

	padding.PaddingTop =
		UDim.new(
			0,
			20
		)

	padding.PaddingBottom =
		UDim.new(
			0,
			28
		)

	padding.PaddingLeft =
		UDim.new(
			0,
			20
		)

	padding.PaddingRight =
		UDim.new(
			0,
			20
		)

	padding.Parent =
		page

	Pages[name] =
		page

	return page

end

--==============================================================
-- HOME PAGE
--==============================================================

local Home =
	CreatePage(
		"HOME"
	)

local Hero =
	New(

		"Frame",

		{

			Size =
				UDim2.new(
					1,
					0,
					0,
					205
				),

			BackgroundColor3 =
				COLOR.Panel,

			ZIndex = 250,

		},

		Home

	)

Corner(
	Hero,
	18
)

Border(
	Hero,
	COLOR.Dim,
	0.55,
	1
)

--==============================================================
-- HERO DECORATION
--==============================================================

local HeroGlow =
	New(

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
					-20,
					0,
					20
				),

			Size =
				UDim2.fromOffset(
					160,
					160
				),

			BackgroundColor3 =
				Accent(),

			BackgroundTransparency =
				0.93,

			ZIndex = 251,

		},

		Hero

	)

Corner(
	HeroGlow,
	100
)

local HeroTitle =
	New(

		"TextLabel",

		{

			Position =
				UDim2.fromOffset(
					22,
					20
				),

			Size =
				UDim2.new(
					1,
					-44,
					0,
					38
				),

			BackgroundTransparency = 1,

			Text =
				"NEURAL ONLINE",

			TextColor3 =
				COLOR.Text,

			TextSize = 28,

			Font =
				Enum.Font.GothamBold,

			TextXAlignment =
				Enum.TextXAlignment.Left,

			ZIndex = 270,

		},

		Hero

	)

local HeroSub =
	New(

		"TextLabel",

		{

			Position =
				UDim2.fromOffset(
					23,
					61
				),

			Size =
				UDim2.new(
					1,
					-46,
					0,
					52
				),

			BackgroundTransparency = 1,

			Text =
				"Cybernetic command interface\nsynchronized with your current session.",

			TextColor3 =
				COLOR.Muted,

			TextSize = 13,

			Font =
				Enum.Font.GothamMedium,

			TextWrapped = true,

			TextXAlignment =
				Enum.TextXAlignment.Left,

			TextYAlignment =
				Enum.TextYAlignment.Top,

			ZIndex = 270,

		},

		Hero

	)

--==============================================================
-- ONLINE CHIP
--==============================================================

local OnlineChip =
	New(

		"Frame",

		{

			Position =
				UDim2.fromOffset(
					22,
					143
				),

			Size =
				UDim2.fromOffset(
					174,
					37
				),

			BackgroundColor3 =
				COLOR.Panel3,

			ZIndex = 270,

		},

		Hero

	)

Corner(
	OnlineChip,
	11
)

local OnlineDot =
	New(

		"Frame",

		{

			Position =
				UDim2.fromOffset(
					12,
					14
				),

			Size =
				UDim2.fromOffset(
					9,
					9
				),

			BackgroundColor3 =
				COLOR.Success,

			BorderSizePixel = 0,

			ZIndex = 275,

		},

		OnlineChip

	)

Corner(
	OnlineDot,
	50
)

local OnlineText =
	New(

		"TextLabel",

		{

			Position =
				UDim2.fromOffset(
					29,
					0
				),

			Size =
				UDim2.new(
					1,
					-35,
					1,
					0
				),

			BackgroundTransparency = 1,

			Text =
				"NEURAL LINK ACTIVE",

			TextColor3 =
				COLOR.Success,

			TextSize = 10,

			Font =
				Enum.Font.GothamBold,

			TextXAlignment =
				Enum.TextXAlignment.Left,

			ZIndex = 275,

		},

		OnlineChip

	)

--==============================================================
-- QUICK CARDS
--==============================================================

local QuickContainer =
	New(

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
					145
				),

			BackgroundTransparency = 1,

			ZIndex = 250,

		},

		Home

	)

local QuickLayout =
	Instance.new(
		"UIGridLayout"
	)

QuickLayout.CellPadding =
	UDim2.fromOffset(
		10,
		10
	)

QuickLayout.CellSize =
	UDim2.new(
		0.333,
		-8,
		0,
		135
	)

QuickLayout.Parent =
	QuickContainer

local function CreateQuickCard(
	title,
	value,
	accentOffset
)

	local card =
		New(

			"Frame",

			{

				BackgroundColor3 =
					COLOR.Panel,

				ZIndex = 260,

			},

			QuickContainer

		)

	Corner(
		card,
		15
	)

	local stroke =
		Border(
			card,
			COLOR.Dim,
			0.55,
			1
		)

	local titleLabel =
		New(

			"TextLabel",

			{

				Position =
					UDim2.fromOffset(
						15,
						13
					),

				Size =
					UDim2.new(
						1,
						-30,
						0,
						20
					),

				BackgroundTransparency = 1,

				Text =
					title,

				TextColor3 =
					COLOR.Muted,

				TextSize = 9,

				Font =
					Enum.Font.GothamBold,

				TextXAlignment =
					Enum.TextXAlignment.Left,

				ZIndex = 270,

			},

			card

		)

	local valueLabel =
		New(

			"TextLabel",

			{

				Position =
					UDim2.fromOffset(
						15,
						38
					),

				Size =
					UDim2.new(
						1,
						-30,
						0,
						48
					),

				BackgroundTransparency = 1,

				Text =
					value,

				TextColor3 =
					Accent(
						accentOffset
					),

				TextSize = 25,

				Font =
					Enum.Font.GothamBold,

				TextXAlignment =
					Enum.TextXAlignment.Left,

				ZIndex = 270,

			},

			card

		)

	return card

end

CreateQuickCard(
	"CORE",
	"ONLINE",
	0
)

CreateQuickCard(
	"MODE",
	"NEURAL",
	0.08
)

CreateQuickCard(
	"STATE",
	"STABLE",
	0.16
)

--==============================================================
-- VISUAL PAGE
--==============================================================

local Visual =
	CreatePage(
		"VISUAL"
	)

local VisualHeader =
	New(

		"TextLabel",

		{

			Size =
				UDim2.new(
					1,
					0,
					0,
					42
				),

			BackgroundTransparency = 1,

			Text =
				"VISUAL CORE",

			TextColor3 =
				COLOR.Text,

			TextSize = 28,

			Font =
				Enum.Font.GothamBold,

			TextXAlignment =
				Enum.TextXAlignment.Left,

			ZIndex = 250,

		},

		Visual

	)

local VisualDescription =
	New(

		"TextLabel",

		{

			Position =
				UDim2.fromOffset(
					1,
					40
				),

			Size =
				UDim2.new(
					1,
					-2,
					0,
					35
				),

			BackgroundTransparency = 1,

			Text =
				"Configure the robotic atmosphere.",

			TextColor3 =
				COLOR.Muted,

			TextSize = 12,

			Font =
				Enum.Font.GothamMedium,

			TextXAlignment =
				Enum.TextXAlignment.Left,

			ZIndex = 250,

		},

		Visual

	)

--==============================================================
-- TOGGLE CREATOR
--==============================================================

local function CreateToggle(
	parent,
	y,
	title,
	description,
	default,
	callback
)

	local holder =
		New(

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
						90
					),

				BackgroundColor3 =
					COLOR.Panel,

				ZIndex = 260,

			},

			parent

		)

	Corner(
		holder,
		15
	)

	Border(
		holder,
		COLOR.Dim,
		0.55,
		1
	)

	local titleLabel =
		New(

			"TextLabel",

			{

				Position =
					UDim2.fromOffset(
						18,
						13
					),

				Size =
					UDim2.new(
						1,
						-105,
						0,
						25
					),

				BackgroundTransparency = 1,

				Text =
					title,

				TextColor3 =
					COLOR.Text,

				TextSize = 14,

				Font =
					Enum.Font.GothamBold,

				TextXAlignment =
					Enum.TextXAlignment.Left,

				ZIndex = 270,

			},

			holder

		)

	local descLabel =
		New(

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
						-115,
						0,
						35
					),

				BackgroundTransparency = 1,

				Text =
					description,

				TextColor3 =
					COLOR.Muted,

				TextSize = 10,

				Font =
					Enum.Font.GothamMedium,

				TextWrapped = true,

				TextXAlignment =
					Enum.TextXAlignment.Left,

				TextYAlignment =
					Enum.TextYAlignment.Top,

				ZIndex = 270,

			},

			holder

		)

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
						-17,
						0.5,
						0
					),

				Size =
					UDim2.fromOffset(
						64,
						38
					),

				BackgroundColor3 =
					default
					and Accent()
					or COLOR.Panel3,

				Text = "",

				AutoButtonColor = false,

				ZIndex = 280,

			},

			holder

		)

	Corner(
		toggle,
		22
	)

	local toggleStroke =
		Border(
			toggle,
			default
			and Accent()
			or COLOR.Dim,
			0.35,
			1
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
					default
					and UDim2.new(
						1,
						-31,
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
						27,
						27
					),

				BackgroundColor3 =
					COLOR.White,

				BorderSizePixel = 0,

				ZIndex = 290,

			},

			toggle

		)

	Corner(
		knob,
		50
	)

	local current =
		default

	Connect(

		toggle.MouseButton1Click,

		function()

			current =
				not current

			Tween(

				toggle,

				0.24,

				{

					BackgroundColor3 =
						current
						and Accent()
						or COLOR.Panel3,

				},

				Enum.EasingStyle.Quint

			)

			Tween(

				knob,

				0.28,

				{

					Position =
						current
						and UDim2.new(
							1,
							-31,
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

			toggleStroke.Color =
				current
				and Accent()
				or COLOR.Dim

			callback(
				current
			)

		end

	)

end

CreateToggle(

	Visual,

	90,

	"NEURAL MOTION",

	"Enable smooth robotic animation.",

	true,

	function(value)

		STATE.Animations =
			value

	end

)

CreateToggle(

	Visual,

	188,

	"CYBER GLOW",

	"Enable atmospheric accent lighting.",

	true,

	function(value)

		STATE.Glow =
			value

	end

)

CreateToggle(

	Visual,

	286,

	"HUD PARTICLES",

	"Enable small floating interface particles.",

	true,

	function(value)

		STATE.Particles =
			value

	end

)

--==============================================================
-- DATA PAGE
--==============================================================

local Data =
	CreatePage(
		"DATA"
	)

local DataTitle =
	New(

		"TextLabel",

		{

			Size =
				UDim2.new(
					1,
					0,
					0,
					42
				),

			BackgroundTransparency = 1,

			Text =
				"NEURAL TELEMETRY",

			TextColor3 =
				COLOR.Text,

			TextSize = 28,

			Font =
				Enum.Font.GothamBold,

			TextXAlignment =
				Enum.TextXAlignment.Left,

			ZIndex = 250,

		},

		Data

	)

--==============================================================
-- DATA CARDS
--==============================================================

local DataGrid =
	New(

		"Frame",

		{

			Position =
				UDim2.fromOffset(
					0,
					58
				),

			Size =
				UDim2.new(
					1,
					0,
					0,
					280
				),

			BackgroundTransparency = 1,

			ZIndex = 250,

		},

		Data

	)

local DataLayout =
	Instance.new(
		"UIGridLayout"
	)

DataLayout.CellPadding =
	UDim2.fromOffset(
		10,
		10
	)

DataLayout.CellSize =
	UDim2.new(
		0.5,
		-5,
		0,
		130
	)

DataLayout.Parent =
	DataGrid

local FPSCard =
	New(

		"Frame",

		{

			BackgroundColor3 =
				COLOR.Panel,

			ZIndex = 260,

		},

		DataGrid

	)

Corner(
	FPSCard,
	15
)

Border(
	FPSCard,
	COLOR.Dim,
	0.5,
	1
)

local FPSName =
	New(

		"TextLabel",

		{

			Position =
				UDim2.fromOffset(
					16,
					14
				),

			Size =
				UDim2.new(
					1,
					-32,
					0,
					20
				),

			BackgroundTransparency = 1,

			Text =
				"FRAME RATE",

			TextColor3 =
				COLOR.Muted,

			TextSize = 9,

			Font =
				Enum.Font.GothamBold,

			TextXAlignment =
				Enum.TextXAlignment.Left,

			ZIndex = 270,

		},

		FPSCard

	)

local FPSValue =
	New(

		"TextLabel",

		{

			Position =
				UDim2.fromOffset(
					16,
					36
				),

			Size =
				UDim2.new(
					1,
					-32,
					0,
					60
				),

			BackgroundTransparency = 1,

			Text =
				"60",

			TextColor3 =
				Accent(),

			TextSize = 34,

			Font =
				Enum.Font.GothamBold,

			TextXAlignment =
				Enum.TextXAlignment.Left,

			ZIndex = 270,

		},

		FPSCard

	)

local RuntimeCard =
	New(

		"Frame",

		{

			BackgroundColor3 =
				COLOR.Panel,

			ZIndex = 260,

		},

		DataGrid

	)

Corner(
	RuntimeCard,
	15
)

Border(
	RuntimeCard,
	COLOR.Dim,
	0.5,
	1
)

local RuntimeName =
	New(

		"TextLabel",

		{

			Position =
				UDim2.fromOffset(
					16,
					14
				),

			Size =
				UDim2.new(
					1,
					-32,
					0,
					20
				),

			BackgroundTransparency = 1,

			Text =
				"RUNTIME",

			TextColor3 =
				COLOR.Muted,

			TextSize = 9,

			Font =
				Enum.Font.GothamBold,

			TextXAlignment =
				Enum.TextXAlignment.Left,

			ZIndex = 270,

		},

		RuntimeCard

	)

local RuntimeValue =
	New(

		"TextLabel",

		{

			Position =
				UDim2.fromOffset(
					16,
					36
				),

			Size =
				UDim2.new(
					1,
					-32,
					0,
					60
				),

			BackgroundTransparency = 1,

			Text =
				"0s",

			TextColor3 =
				COLOR.Pink,

			TextSize = 34,

			Font =
				Enum.Font.GothamBold,

			TextXAlignment =
				Enum.TextXAlignment.Left,

			ZIndex = 270,

		},

		RuntimeCard

	)

--==============================================================
-- ABOUT / CORE PAGE
--==============================================================

local Core =
	CreatePage(
		"CORE"
	)

local CoreCard =
	New(

		"Frame",

		{

			Size =
				UDim2.new(
					1,
					0,
					0,
					310
				),

			BackgroundColor3 =
				COLOR.Panel,

			ZIndex = 250,

		},

		Core

	)

Corner(
	CoreCard,
	18
)

Border(
	CoreCard,
	COLOR.Dim,
	0.5,
	1
)

local CoreTitle =
	New(

		"TextLabel",

		{

			Position =
				UDim2.fromOffset(
					22,
					22
				),

			Size =
				UDim2.new(
					1,
					-44,
					0,
					42
				),

			BackgroundTransparency = 1,

			Text =
				"VANZ // NEURAL",

			TextColor3 =
				COLOR.Text,

			TextSize = 29,

			Font =
				Enum.Font.GothamBold,

			TextXAlignment =
				Enum.TextXAlignment.Left,

			ZIndex = 270,

		},

		CoreCard

	)

local CoreText =
	New(

		"TextLabel",

		{

			Position =
				UDim2.fromOffset(
					24,
					75
				),

			Size =
				UDim2.new(
					1,
					-48,
					0,
					150
				),

			BackgroundTransparency = 1,

			Text =
				"ROBOTIC COMMAND INTERFACE\n\n"
				.. "Designed around mobile interaction,\n"
				.. "large touch targets and protected controls.\n\n"
				.. "The interface uses a cyber-anime HUD aesthetic\n"
				.. "with restrained motion for smooth performance.",

			TextColor3 =
				COLOR.Muted,

			TextSize = 13,

			Font =
				Enum.Font.GothamMedium,

			TextWrapped = true,

			TextXAlignment =
				Enum.TextXAlignment.Left,

			TextYAlignment =
				Enum.TextYAlignment.Top,

			ZIndex = 270,

		},

		CoreCard

	)

local BuildLabel =
	New(

		"TextLabel",

		{

			Position =
				UDim2.fromOffset(
					24,
					255
				),

			Size =
				UDim2.new(
					1,
					-48,
					0,
					25
				),

			BackgroundTransparency = 1,

			Text =
				"V10 // NEURAL CYBER CORE",

			TextColor3 =
				Accent(),

			TextSize = 10,

			Font =
				Enum.Font.Code,

			TextXAlignment =
				Enum.TextXAlignment.Left,

			ZIndex = 270,

		},

		CoreCard

	)

--==============================================================
-- NAVIGATION FACTORY
--==============================================================

local MobileDock =
	New(

		"Frame",

		{

			Name =
				"MobileDock",

			AnchorPoint =
				Vector2.new(
					0.5,
					1
				),

			Position =
				UDim2.new(
					0.5,
					0,
					1,
					-6
				),

			Size =
				UDim2.new(
					1,
					-12,
					0,
					66
				),

			BackgroundColor3 =
				COLOR.Panel,

			ZIndex = 700,

			Visible = false,

		},

		Body

	)

Corner(
	MobileDock,
	17
)

Border(
	MobileDock,
	COLOR.Dim,
	0.35,
	1
)

local MobileLayout =
	Instance.new(
		"UIListLayout"
	)

MobileLayout.FillDirection =
	Enum.FillDirection.Horizontal

MobileLayout.HorizontalAlignment =
	Enum.HorizontalAlignment.Center

MobileLayout.VerticalAlignment =
	Enum.VerticalAlignment.Center

MobileLayout.Padding =
	UDim.new(
		0,
		5
	)

MobileLayout.Parent =
	MobileDock

local function CreateNavigation(
	name,
	label,
	icon,
	order
)

	--==========================================================
	-- DESKTOP
	--==========================================================

	local desktop =
		New(

			"TextButton",

			{

				LayoutOrder =
					order,

				Size =
					UDim2.new(
						1,
						0,
						0,
						55
					),

				BackgroundColor3 =
					COLOR.Panel2,

				BackgroundTransparency = 1,

				Text = "",

				AutoButtonColor = false,

				ZIndex = 280,

			},

			DesktopNav

		)

	Corner(
		desktop,
		12
	)

	local dIcon =
		New(

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
						55
					),

				BackgroundTransparency = 1,

				Text =
					icon,

				TextColor3 =
					COLOR.Muted,

				TextSize = 18,

				Font =
					Enum.Font.GothamBold,

				ZIndex = 290,

			},

			desktop

		)

	local dText =
		New(

			"TextLabel",

			{

				Position =
					UDim2.fromOffset(
						53,
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

				Text =
					label,

				TextColor3 =
					COLOR.Muted,

				TextSize = 11,

				Font =
					Enum.Font.GothamBold,

				TextXAlignment =
					Enum.TextXAlignment.Left,

				ZIndex = 290,

			},

			desktop

		)

	local dBar =
		New(

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
						35
					),

				BackgroundColor3 =
					Accent(),

				BackgroundTransparency = 1,

				BorderSizePixel = 0,

				ZIndex = 295,

			},

			desktop

		)

	Corner(
		dBar,
		4
	)

	--==========================================================
	-- MOBILE
	--==========================================================

	local mobile =
		New(

			"TextButton",

			{

				LayoutOrder =
					order,

				Size =
					UDim2.new(
						0.25,
						-4,
						1,
						-8
					),

				BackgroundColor3 =
					COLOR.Panel2,

				BackgroundTransparency = 1,

				Text = "",

				AutoButtonColor = false,

				ZIndex = 720,

			},

			MobileDock

		)

	Corner(
		mobile,
		12
	)

	local mIcon =
		New(

			"TextLabel",

			{

				Position =
					UDim2.new(
						0,
						0,
						0,
						4
					),

				Size =
					UDim2.new(
						1,
						0,
						0,
						25
					),

				BackgroundTransparency = 1,

				Text =
					icon,

				TextColor3 =
					COLOR.Muted,

				TextSize = 17,

				Font =
					Enum.Font.GothamBold,

				ZIndex = 730,

			},

			mobile

		)

	local mText =
		New(

			"TextLabel",

			{

				Position =
					UDim2.new(
						0,
						0,
						0,
						29
					),

				Size =
					UDim2.new(
						1,
						0,
						0,
						18
					),

				BackgroundTransparency = 1,

				Text =
					label,

				TextColor3 =
					COLOR.Muted,

				TextSize = 8,

				Font =
					Enum.Font.GothamBold,

				TextTruncate =
					Enum.TextTruncate.AtEnd,

				ZIndex = 730,

			},

			mobile

		)

	local function SetActive(active)

		desktop.BackgroundTransparency =
			active
			and 0.06
			or 1

		mobile.BackgroundTransparency =
			active
			and 0.06
			or 1

		dIcon.TextColor3 =
			active
			and COLOR.Text
			or COLOR.Muted

		dText.TextColor3 =
			active
			and COLOR.Text
			or COLOR.Muted

		mIcon.TextColor3 =
			active
			and COLOR.Text
			or COLOR.Muted

		mText.TextColor3 =
			active
			and COLOR.Text
			or COLOR.Muted

		dBar.BackgroundTransparency =
			active
			and 0
			or 1

	end

	local function Activate()

		if STATE.CurrentPage ==
			name then

			return

		end

		STATE.CurrentPage =
			name

		for pageName, page in
			pairs(Pages) do

			page.Visible =
				pageName == name

		end

		for navName, data in
			pairs(Navigation) do

			data.SetActive(
				navName == name
			)

		end

	end

	Connect(
		desktop.MouseButton1Click,
		Activate
	)

	Connect(
		mobile.MouseButton1Click,
		Activate
	)

	Navigation[name] = {

		SetActive =
			SetActive,

	}

end

CreateNavigation(
	"HOME",
	"HOME",
	"⌂",
	1
)

CreateNavigation(
	"VISUAL",
	"VISUAL",
	"✦",
	2
)

CreateNavigation(
	"DATA",
	"DATA",
	"⌁",
	3
)

CreateNavigation(
	"CORE",
	"CORE",
	"◇",
	4
)

Pages.HOME.Visible = true

Navigation.HOME.SetActive(
	true
)

--==============================================================
-- MINI LOGO
--==============================================================

local MiniLogo =
	New(

		"TextButton",

		{

			Name =
				"CenterMiniLogo",

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
					100,
					100
				),

			BackgroundColor3 =
				COLOR.Panel,

			Text =
				"V",

			TextColor3 =
				COLOR.Text,

			TextSize = 40,

			Font =
				Enum.Font.GothamBold,

			AutoButtonColor = false,

			Visible = false,

			ZIndex = 2000,

		},

		ScreenGui

	)

Corner(
	MiniLogo,
	100
)

local MiniStroke =
	Border(
		MiniLogo,
		Accent(),
		0.08,
		2
	)

local MiniInner =
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
				UDim2.fromOffset(
					76,
					76
				),

			BackgroundTransparency = 1,

			ZIndex = 1995,

		},

		ScreenGui

	)

Corner(
	MiniInner,
	100
)

local MiniInnerStroke =
	Border(
		MiniInner,
		AccentSoft(),
		0.3,
		1
	)

local MiniScale =
	New(

		"UIScale",

		{

			Scale = 1,

		},

		MiniLogo

	)

--==============================================================
-- MAIN WINDOW DRAG
--==============================================================

local WindowDragActive = false

local WindowDragStart =
	Vector2.zero

local WindowStartPos =
	UDim2.fromScale(
		0.5,
		0.5
	)

Connect(

	HeaderDrag.InputBegan,

	function(input)

		if

			input.UserInputType ==
				Enum.UserInputType.MouseButton1

			or

			input.UserInputType ==
				Enum.UserInputType.Touch

		then

			WindowDragActive =
				true

			STATE.DraggingWindow =
				true

			STATE.WindowDragged =
				true

			WindowDragStart =
				input.Position

			WindowStartPos =
				Window.Position

		end

	end

)

Connect(

	UserInputService.InputChanged,

	function(input)

		if not WindowDragActive then
			return
		end

		if

			input.UserInputType ~=
				Enum.UserInputType.MouseMovement

			and

			input.UserInputType ~=
				Enum.UserInputType.Touch

		then

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
			- WindowDragStart

		local dx =
			delta.X / viewport.X

		local dy =
			delta.Y / viewport.Y

		Window.Position =
			UDim2.new(

				WindowStartPos.X.Scale
					+ dx,

				WindowStartPos.X.Offset,

				WindowStartPos.Y.Scale
					+ dy,

				WindowStartPos.Y.Offset

			)

	end

)

Connect(

	UserInputService.InputEnded,

	function(input)

		if

			input.UserInputType ==
				Enum.UserInputType.MouseButton1

			or

			input.UserInputType ==
				Enum.UserInputType.Touch

		then

			WindowDragActive =
				false

			STATE.DraggingWindow =
				false

		end

	end

)

--==============================================================
-- LOGO DRAG
--==============================================================

local LogoDragging =
	false

local LogoMoved =
	false

local LogoStart =
	Vector2.zero

local LogoPosition =
	UDim2.fromScale(
		0.5,
		0.5
	)

Connect(

	LogoDragButton.InputBegan,

	function(input)

		if

			input.UserInputType ==
				Enum.UserInputType.MouseButton1

			or

			input.UserInputType ==
				Enum.UserInputType.Touch

		then

			LogoDragging =
				true

			LogoMoved =
				false

			LogoStart =
				input.Position

			LogoPosition =
				LogoArea.Position

		end

	end

)

--==============================================================
-- MINI LOGO DRAG
--==============================================================

local MiniDragStart =
	Vector2.zero

local MiniStartPosition =
	UDim2.fromScale(
		0.5,
		0.5
	)

Connect(

	MiniLogo.InputBegan,

	function(input)

		if

			input.UserInputType ==
				Enum.UserInputType.MouseButton1

			or

			input.UserInputType ==
				Enum.UserInputType.Touch

		then

			STATE.DraggingMini =
				true

			STATE.MovedMini =
				false

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

		--========================================================
		-- HEADER LOGO
		--========================================================

		if LogoDragging then

			if

				input.UserInputType ==
					Enum.UserInputType.MouseMovement

				or

				input.UserInputType ==
					Enum.UserInputType.Touch

			then

				local delta =
					input.Position
					- LogoStart

				if delta.Magnitude > 8 then
					LogoMoved = true
				end

				local camera =
					workspace.CurrentCamera

				if camera then

					local viewport =
						camera.ViewportSize

					LogoArea.Position =
						UDim2.fromOffset(

							Clamp(
								LogoPosition.X.Offset
									+ delta.X,

								0,

								math.max(
									0,
									viewport.X
									- 74
								)

							),

							Clamp(
								LogoPosition.Y.Offset
									+ delta.Y,

								0,

								math.max(
									0,
									viewport.Y
									- 74
								)

							)

						)

				end

			end

		end

		--========================================================
		-- MINI LOGO
		--========================================================

		if STATE.DraggingMini then

			if

				input.UserInputType ==
					Enum.UserInputType.MouseMovement

				or

				input.UserInputType ==
					Enum.UserInputType.Touch

			then

				local delta =
					input.Position
					- MiniDragStart

				if delta.Magnitude > 8 then
					STATE.MovedMini = true
				end

				local camera =
					workspace.CurrentCamera

				if camera then

					local viewport =
						camera.ViewportSize

					local x =
						MiniStartPosition.X.Offset
						+ delta.X

					local y =
						MiniStartPosition.Y.Offset
						+ delta.Y

					MiniLogo.Position =
						UDim2.new(
							0.5,
							Clamp(
								x,
								-(viewport.X / 2) + 55,
								(viewport.X / 2) - 55
							),
							0.5,
							Clamp(
								y,
								-(viewport.Y / 2) + 55,
								(viewport.Y / 2) - 55
							)
						)

					MiniInner.Position =
						MiniLogo.Position

				end

			end

		end

	end

)

Connect(

	UserInputService.InputEnded,

	function(input)

		if

			input.UserInputType ==
				Enum.UserInputType.MouseButton1

			or

			input.UserInputType ==
				Enum.UserInputType.Touch

		then

			--====================================================
			-- HEADER LOGO
			--====================================================

			if LogoDragging then

				LogoDragging =
					false

			end

			--====================================================
			-- MINI LOGO
			--====================================================

			if STATE.DraggingMini then

				STATE.DraggingMini =
					false

				if not STATE.MovedMini then

					-- RESTORE

					STATE.Minimized =
						false

					MiniLogo.Visible =
						false

					MiniInner.Visible =
						false

					Window.Visible =
						true

					Window.Position =
						UDim2.fromScale(
							0.5,
							0.53
						)

					Tween(

						Window,

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

	end

)

--==============================================================
-- MINIMIZE FUNCTION
--==============================================================

local function MinimizeWindow()

	if STATE.Minimized then
		return
	end

	STATE.Minimized =
		true

	Tween(

		Window,

		0.32,

		{

			Position =
				UDim2.fromScale(
					0.5,
					0.5
				),

		},

		Enum.EasingStyle.Quint

	)

	task.delay(

		0.24,

		function()

			if STATE.Destroyed then
				return
			end

			Window.Visible =
				false

			-- ALWAYS CENTER
			MiniLogo.Position =
				UDim2.fromScale(
					0.5,
					0.5
				)

			MiniInner.Position =
				MiniLogo.Position

			MiniLogo.Visible =
				true

			MiniInner.Visible =
				true

			MiniScale.Scale =
				0.6

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

	Minimize.MouseButton1Click,

	MinimizeWindow

)

--==============================================================
-- CLOSE
--==============================================================

local function DestroyVanz()

	if STATE.Destroyed then
		return
	end

	STATE.Destroyed =
		true

	Cleanup()

	pcall(function()
		ScreenGui:Destroy()
	end)

end

Connect(
	Close.MouseButton1Click,
	DestroyVanz
)

_G.vanz.ForceStop =
	DestroyVanz

--==============================================================
-- BUTTON HOVER
--==============================================================

local function ButtonFX(
	button,
	stroke,
	base
)

	Connect(

		button.MouseEnter,

		function()

			if not STATE.Animations then
				return
			end

			Tween(

				button,

				0.16,

				{

					BackgroundColor3 =
						AccentSoft(),

				},

				Enum.EasingStyle.Sine

			)

			stroke.Color =
				Accent()

		end

	)

	Connect(

		button.MouseLeave,

		function()

			Tween(

				button,

				0.16,

				{

					BackgroundColor3 =
						base,

				},

				Enum.EasingStyle.Sine

			)

			stroke.Color =
				COLOR.Dim

		end

	)

end

ButtonFX(
	Minimize,
	MinStroke,
	COLOR.Panel3
)

ButtonFX(
	Close,
	CloseStroke,
	COLOR.Panel3
)

--==============================================================
-- RESPONSIVE ENGINE
--==============================================================

local function Responsive()

	if STATE.Destroyed then
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

	if width <= 720 then

		STATE.Mobile =
			true

		MasterScale.Scale =
			1

		local safeWidth =
			math.max(
				300,
				width
				- CONFIG.MobileMargin * 2
			)

		local safeHeight =
			math.max(
				360,
				height
				- CONFIG.MobileMargin * 2
			)

		Window.Size =
			UDim2.fromOffset(
				safeWidth,
				safeHeight
			)

		Header.Size =
			UDim2.new(
				1,
				0,
				0,
				CONFIG.HeaderMobile
			)

		Body.Position =
			UDim2.fromOffset(
				0,
				CONFIG.HeaderMobile
			)

		Body.Size =
			UDim2.new(
				1,
				0,
				1,
				-CONFIG.HeaderMobile
			)

		Sidebar.Visible =
			false

		MobileDock.Visible =
			true

		--======================================================
		-- CRITICAL MOBILE HEADER
		--======================================================

		LogoArea.Position =
			UDim2.fromOffset(
				8,
				9
			)

		-- On narrow phones:
		-- title zone becomes smaller.
		-- controls NEVER shrink below 52px.
		TitleZone.Position =
			UDim2.fromOffset(
				78,
				7
			)

		TitleZone.Size =
			UDim2.new(
				1,
				-(CONFIG.ControlWidthMobile + 86),
				1,
				-14
			)

		ControlDock.Size =
			UDim2.fromOffset(
				CONFIG.ControlWidthMobile,
				64
			)

		ControlDock.Position =
			UDim2.new(
				1,
				-5,
				0,
				9
			)

		Minimize.Size =
			UDim2.fromOffset(
				52,
				60
			)

		Minimize.Position =
			UDim2.fromOffset(
				0,
				0
			)

		Minimize.Text =
			"—"

		Minimize.TextSize =
			22

		Close.Size =
			UDim2.fromOffset(
				52,
				60
			)

		Close.Position =
			UDim2.fromOffset(
				58,
				0
			)

		Close.Text =
			"×"

		Close.TextSize =
			27

		--======================================================
		-- VERY NARROW SCREEN
		--======================================================

		if width <= 360 then

			Title.Visible =
				false

			Subtitle.Visible =
				false

			-- The logo itself becomes the visual title.

		else

			Title.Visible =
				true

			Subtitle.Visible =
				false

			Title.Text =
				"VANZ"

			Title.TextSize =
				20

		end

		--======================================================
		-- CONTENT
		--======================================================

		Content.Position =
			UDim2.fromOffset(
				0,
				0
			)

		Content.Size =
			UDim2.new(
				1,
				0,
				1,
				-72
			)

		--======================================================
		-- HOME MOBILE
		--======================================================

		HeroTitle.TextSize =
			24

		HeroSub.TextSize =
			11

		--======================================================
		-- QUICK CARDS
		--======================================================

		QuickLayout.CellSize =
			UDim2.new(
				1,
				0,
				0,
				92
			)

		QuickContainer.Size =
			UDim2.new(
				1,
				0,
				0,
				295
			)

		--======================================================
		-- MOBILE NAV
		--======================================================

		MobileDock.Size =
			UDim2.new(
				1,
				-12,
				0,
				66
			)

	else

	--==========================================================
	-- DESKTOP
	--==========================================================

		STATE.Mobile =
			false

		MasterScale.Scale =
			0.92

		Window.Size =
			UDim2.fromOffset(
				CONFIG.DesktopWidth,
				CONFIG.DesktopHeight
			)

		Header.Size =
			UDim2.new(
				1,
				0,
				0,
				CONFIG.HeaderDesktop
			)

		Body.Position =
			UDim2.fromOffset(
				0,
				CONFIG.HeaderDesktop
			)

		Body.Size =
			UDim2.new(
				1,
				0,
				1,
				-CONFIG.HeaderDesktop
			)

		Sidebar.Visible =
			true

		MobileDock.Visible =
			false

		Content.Position =
			UDim2.fromOffset(
				214,
				0
			)

		Content.Size =
			UDim2.new(
				1,
				-214,
				1,
				0
			)

		LogoArea.Position =
			UDim2.fromOffset(
				10,
				10
			)

		Title.Visible =
			true

		Subtitle.Visible =
			true

		Title.Text =
			CONFIG.Title

		Title.TextSize =
			25

		TitleZone.Position =
			UDim2.fromOffset(
				82,
				8
			)

		TitleZone.Size =
			UDim2.new(
				1,
				-296,
				1,
				-16
			)

		ControlDock.Size =
			UDim2.fromOffset(
				CONFIG.ControlWidthDesktop,
				70
			)

		Minimize.Size =
			UDim2.fromOffset(
				CONFIG.ControlButtonDesktop,
				64
			)

		Minimize.Text =
			"—"

		Close.Size =
			UDim2.fromOffset(
				CONFIG.ControlButtonDesktop,
				64
			)

		Close.Position =
			UDim2.fromOffset(
				104,
				0
			)

		Close.Text =
			"×"

		-- Desktop quick cards
		QuickLayout.CellSize =
			UDim2.new(
				0.333,
				-8,
				0,
				135
			)

		QuickContainer.Size =
			UDim2.new(
				1,
				0,
				0,
				145
			)

	end

end

--==============================================================
-- CAMERA RESPONSIVE LISTENER
--==============================================================

local function BindCamera()

	local camera =
		workspace.CurrentCamera

	if not camera then
		return
	end

	Connect(

		camera:GetPropertyChangedSignal(
			"ViewportSize"
		),

		Responsive

	)

end

BindCamera()

Responsive()

--==============================================================
-- FPS ENGINE
--==============================================================

local frameCount =
	0

local frameTimer =
	0

--==============================================================
-- PARTICLE SYSTEM
--==============================================================

local ParticleLayer =
	New(

		"Frame",

		{

			Name =
				"CyberParticles",

			Size =
				UDim2.fromScale(
					1,
					1
				),

			BackgroundTransparency = 1,

			ClipsDescendants = true,

			ZIndex = 115,

		},

		Panel

	)

local ParticleObjects = {}

local function CreateParticle(index)

	local particle =
		New(

			"Frame",

			{

				Size =
					UDim2.fromOffset(
						2 + (index % 3),
						2 + (index % 3)
					),

				Position =
					UDim2.fromScale(
						(index * 0.137)
						% 1,

						(index * 0.071)
						% 1
					),

				BackgroundColor3 =
					Accent(
						index * 0.02
					),

				BackgroundTransparency =
					0.45,

				BorderSizePixel = 0,

				ZIndex = 116,

			},

			ParticleLayer

		)

	Corner(
		particle,
		50
	)

	table.insert(
		ParticleObjects,
		{
			Object = particle,
			Offset = index * 0.37,
			Speed =
				0.03
				+ (
					index % 5
				) * 0.006,
		}
	)

end

for i = 1, 22 do
	CreateParticle(i)
end

--==============================================================
-- SCAN LINE
--==============================================================

local Scanner =
	New(

		"Frame",

		{

			Name =
				"NeuralScanner",

			Position =
				UDim2.new(
					0,
					0,
					-0.15,
					0
				),

			Size =
				UDim2.new(
					1,
					0,
					0,
					2
				),

			BackgroundColor3 =
				Accent(),

			BackgroundTransparency =
				0.65,

			BorderSizePixel = 0,

			ZIndex = 125,

		},

		Panel

	)

--==============================================================
-- ANIMATION LOOP
--==============================================================

Connect(

	RunService.RenderStepped,

	function(dt)

		if STATE.Destroyed then
			return
		end

		STATE.Time += dt

		frameCount += 1

		frameTimer += dt

		if frameTimer >= 0.5 then

			STATE.FPS =
				math.floor(
					frameCount
					/ frameTimer
				)

			frameCount =
				0

			frameTimer =
				0

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
			CONFIG.DisplayOrder then

			ScreenGui.DisplayOrder =
				CONFIG.DisplayOrder

		end

		--======================================================
		-- HUE
		--======================================================

		if STATE.Animations then

			STATE.Hue =
				(
					STATE.Hue
					+ dt * 0.012
				)
				% 1

		end

		local accent =
			Accent()

		local soft =
			AccentSoft(
				0.08
			)

		--======================================================
		-- BORDER
		--======================================================

		PanelStroke.Color =
			accent

		HeaderEnergy.BackgroundColor3 =
			accent

		LogoOuterStroke.Color =
			accent

		LogoMiddleStroke.Color =
			soft

		LogoCore.BackgroundColor3 =
			accent

		MiniStroke.Color =
			accent

		MiniInnerStroke.Color =
			soft

		BuildLabel.TextColor3 =
			accent

		--======================================================
		-- LOGO ROTATION
		--======================================================

		if STATE.Animations then

			LogoOuter.Rotation =
				LogoOuter.Rotation
				+ dt * 7

			LogoMiddle.Rotation =
				LogoMiddle.Rotation
				- dt * 11

			MiniInner.Rotation =
				MiniInner.Rotation
				+ dt * 6

		end

		--======================================================
		-- LOGO BREATHING
		--======================================================

		local breathe =
			1
			+ math.sin(
				STATE.Time * 1.7
			) * 0.08

		LogoCore.Size =
			UDim2.fromOffset(
				18 * breathe,
				18 * breathe
			)

		--======================================================
		-- AURA
		--======================================================

		if STATE.Glow then

			Aura.BackgroundTransparency =
				0.94
				+
				math.sin(
					STATE.Time * 1.1
				)
				* 0.015

		else

			Aura.BackgroundTransparency =
				1

		end

		--======================================================
		-- ONLINE PULSE
		--======================================================

		OnlineDot.BackgroundTransparency =
			0.08
			+
			(
				math.sin(
					STATE.Time * 2.5
				)
				+ 1
			)
			* 0.15

		--======================================================
		-- SCANNER
		--======================================================

		if CONFIG.Scanlines then

			local scan =
				(
					STATE.Time
					* 0.08
				)
				% 1.2

			Scanner.Position =
				UDim2.new(
					0,
					0,
					scan - 0.15,
					0
				)

			Scanner.BackgroundColor3 =
				accent

		end

		--======================================================
		-- PARTICLES
		--======================================================

		for _, data in
			ipairs(
				ParticleObjects
			) do

			local particle =
				data.Object

			if STATE.Particles then

				particle.Visible =
					true

				local y =
					(
						particle.Position.Y.Scale
						- dt * data.Speed
					)

				if y < -0.05 then
					y = 1.05
				end

				particle.Position =
					UDim2.new(
						particle.Position.X.Scale,
						0,
						y,
						0
					)

				particle.BackgroundColor3 =
					Accent(
						data.Offset * 0.01
					)

			else

				particle.Visible =
					false

			end

		end

		--======================================================
		-- MINI LOGO PULSE
		--======================================================

		if MiniLogo.Visible then

			local pulse =
				1
				+
				math.sin(
					STATE.Time * 2
				)
				* 0.04

			MiniLogo.Size =
				UDim2.fromOffset(
					100 * pulse,
					100 * pulse
				)

		end

	end

)

--==============================================================
-- PUBLIC API
--==============================================================

function _G.vanz.Open()

	if STATE.Destroyed then
		return
	end

	STATE.Minimized =
		false

	MiniLogo.Visible =
		false

	MiniInner.Visible =
		false

	Window.Visible =
		true

	Responsive()

	Window.Position =
		UDim2.fromScale(
			0.5,
			0.53
		)

	Tween(

		Window,

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

	if STATE.Destroyed then
		return
	end

	Tween(

		Window,

		0.3,

		{

			Position =
				UDim2.fromScale(
					0.5,
					0.54
				),

		},

		Enum.EasingStyle.Quint

	)

	task.delay(

		0.28,

		function()

			if not STATE.Destroyed then

				Window.Visible =
					false

			end

		end

	)

end

function _G.vanz.SetScale(value)

	if STATE.Mobile then
		return
	end

	value =
		Clamp(
			tonumber(value)
				or 0.92,

			0.75,

			1.05
		)

	Tween(

		MasterScale,

		0.3,

		{

			Scale =
				value,

		},

		Enum.EasingStyle.Quint

	)

end

function _G.vanz.GetState()

	return STATE

end

--==============================================================
-- STARTUP
--==============================================================

Window.Position =
	UDim2.fromScale(
		0.5,
		0.54
	)

Tween(

	Window,

	0.65,

	{

		Position =
			UDim2.fromScale(
				0.5,
				0.5
			),

	},

	Enum.EasingStyle.Quint

)

--==============================================================
-- FINAL
--==============================================================

print(
	"[VANZ V10] NEURAL CYBER COMMAND CENTER ONLINE"
)

print(
	"[VANZ V10] MOBILE SAFE HEADER ENABLED"
)

print(
	"[VANZ V10] PROTECTED MIN/CLOSE DOCK ENABLED"
)

print(
	"[VANZ V10] ROBOTIC + CYBER ANIME HUD ENABLED"
)

print(
	"[VANZ V10] MAIN WINDOW DRAG ENABLED"
)

print(
	"[VANZ V10] LOGO DRAG ENABLED"
)

print(
	"[VANZ V10] CENTER MINI LOGO ENABLED"
)

--//==============================================================\\
--// VANZ V10 // END
--//==============================================================\\