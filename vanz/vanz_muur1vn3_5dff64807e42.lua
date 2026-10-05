--[[
====================================================================
                    VANZ NEXUS // V11
              ROBOTIC × ANIME COMMAND INTERFACE
====================================================================

PSEUDO-STRUCTURE / GAMBARAN BESAR:

VANZ_NEXUS_GUI
│
├── ROOT
│   │
│   ├── MAIN WINDOW
│   │   ├── HEADER
│   │   │   ├── LOGO
│   │   │   ├── TITLE
│   │   │   └── EXCLUSIVE CONTROL ZONE
│   │   │       ├── MINIMIZE
│   │   │       └── CLOSE
│   │   │
│   │   └── BODY
│   │       ├── DESKTOP SIDEBAR
│   │       ├── CONTENT
│   │       │   └── PAGES
│   │       │       ├── HOME
│   │       │       ├── NEXUS
│   │       │       ├── VISUALS
│   │       │       ├── TELEMETRY
│   │       │       └── ABOUT
│   │       │
│   │       └── MOBILE BOTTOM NAV
│   │
│   └── MINIMIZED CORE
│       └── DRAGGABLE ROBOTIC LOGO
│
├── VISUAL FX
│   ├── Scanlines
│   ├── Circuit Lines
│   ├── Particles
│   ├── Radar
│   └── Animated Core
│
└── SYSTEM
    ├── Responsive Layout
    ├── Drag Controller
    ├── Minimize / Restore
    ├── Telemetry
    └── Public API

====================================================================
IMPORTANT:

1. HEADER CONTROL ZONE TIDAK BOLEH DIPAKAI ELEMEN LAIN.
2. MOBILE TIDAK MENGGUNAKAN SIDEBAR.
3. MINIMIZED CORE TIDAK MENGGUNAKAN OUTER BLUE SHADOW.
4. DRAG MINIMIZED CORE MENGGUNAKAN ABSOLUTE POSITION,
   JADI DRAG PERTAMA TIDAK TELEPORT.
5. SEMUA BAGIAN DIBERI KOMENTAR AGAR MUDAH DIEDIT.
====================================================================
]]

--------------------------------------------------------------------
-- [SYSTEM: SERVICES]
-- Semua Roblox service yang dipakai GUI.
--------------------------------------------------------------------

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Stats = game:GetService("Stats")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

--------------------------------------------------------------------
-- [CONFIG: PENGATURAN UTAMA]
-- Kalau mau mengubah ukuran desktop/mobile, edit bagian ini.
--------------------------------------------------------------------

local CONFIG = {

	Name = "VANZ_NEXUS_GUI",

	DisplayOrder = 999999999,

	-- Ukuran desktop.
	DesktopWidth = 1020,
	DesktopHeight = 650,

	-- Jarak window dari tepi layar HP.
	MobileMargin = 7,

	-- Tinggi header.
	HeaderDesktop = 92,
	HeaderMobile = 78,

	-- Lebar area khusus tombol Minimize + Close.
	-- AREA INI TIDAK BOLEH DITIMPA TITLE.
	ControlZoneDesktop = 120,
	ControlZoneMobile = 112,

	-- Sidebar desktop.
	SidebarDesktop = 205,

	-- Bottom navigation mobile.
	BottomNavMobile = 72,

	-- Jumlah particle.
	ParticleCount = 18,

	-- Kecepatan animasi.
	AnimationSpeed = 1,
}

--------------------------------------------------------------------
-- [CLEANUP: HAPUS GUI LAMA]
-- Supaya script tidak membuat beberapa GUI menumpuk.
--------------------------------------------------------------------

for _, oldName in ipairs({
	"VANZ_ROBOTIC_GUI",
	"VANZ_PREMIUM_GUI",
	"VANZ_SOFT_ROBOTIC_GUI",
	"VANZ_NEXUS_GUI",
	"VANZ_NEXUS_INTERFACE",
}) do

	local oldGui = PlayerGui:FindFirstChild(oldName)

	if oldGui then
		oldGui:Destroy()
	end
end

--------------------------------------------------------------------
-- [STATE: DATA INTERNAL GUI]
-- Semua status GUI disimpan di sini.
--------------------------------------------------------------------

local State = {

	Destroyed = false,

	Minimized = false,

	Mobile = false,

	Tiny = false,

	CurrentPage = "HOME",

	Animations = true,

	Neon = true,

	Particles = true,

	Scanlines = true,

	InteractionFX = true,

	HueCycle = true,

	--------------------------------------------------------------
	-- Drag window utama.
	--------------------------------------------------------------

	DraggingWindow = false,

	WindowDragStart = Vector2.zero,

	WindowStartPosition = Vector2.zero,

	WindowOffset = Vector2.zero,

	WindowDragged = false,

	--------------------------------------------------------------
	-- Drag minimized logo.
	--------------------------------------------------------------

	DraggingCore = false,

	CoreDragStart = Vector2.zero,

	CoreStartAbsolute = Vector2.zero,

	CoreDragged = false,

	--------------------------------------------------------------
	-- Animation.
	--------------------------------------------------------------

	Time = 0,

	Hue = 0,

	OpenedAt = os.clock(),

	--------------------------------------------------------------
	-- Connections / Tweens.
	--------------------------------------------------------------

	Connections = {},

	Tweens = {},

	Particles = {},
}

--------------------------------------------------------------------
-- [UTILITY: CONNECTION MANAGER]
--------------------------------------------------------------------

local function Connect(signal, callback)

	local connection = signal:Connect(callback)

	table.insert(
		State.Connections,
		connection
	)

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

--------------------------------------------------------------------
-- [UTILITY: TWEEN]
--------------------------------------------------------------------

local function Tween(
	object,
	duration,
	properties,
	style,
	direction
)

	if not object then
		return
	end

	if not object.Parent then
		return
	end

	local tweenInfo = TweenInfo.new(
		duration / math.max(
			CONFIG.AnimationSpeed,
			0.05
		),

		style or Enum.EasingStyle.Quint,

		direction or Enum.EasingDirection.Out
	)

	local tween = TweenService:Create(
		object,
		tweenInfo,
		properties
	)

	table.insert(
		State.Tweens,
		tween
	)

	tween:Play()

	return tween
end

--------------------------------------------------------------------
-- [UTILITY: CLAMP]
--------------------------------------------------------------------

local function Clamp(value, minimum, maximum)

	return math.clamp(
		value,
		minimum,
		maximum
	)

end

--------------------------------------------------------------------
-- [UTILITY: COLOR]
--------------------------------------------------------------------

local function HSV(h, s, v)

	return Color3.fromHSV(
		h % 1,
		math.clamp(s, 0, 1),
		math.clamp(v, 0, 1)
	)

end

--------------------------------------------------------------------
-- [THEME: WARNA]
--------------------------------------------------------------------

local COLORS = {

	Background = Color3.fromRGB(
		5, 7, 16
	),

	Panel = Color3.fromRGB(
		9, 12, 25
	),

	Panel2 = Color3.fromRGB(
		12, 16, 32
	),

	Cyan = Color3.fromRGB(
		67, 232, 255
	),

	Blue = Color3.fromRGB(
		81, 125, 255
	),

	Violet = Color3.fromRGB(
		157, 93, 255
	),

	Pink = Color3.fromRGB(
		255, 82, 183
	),

	White = Color3.fromRGB(
		239, 248, 255
	),

	Muted = Color3.fromRGB(
		133, 151, 177
	),

	Good = Color3.fromRGB(
		83, 255, 174
	),

	Warning = Color3.fromRGB(
		255, 211, 88
	),

	Danger = Color3.fromRGB(
		255, 82, 112
	),

	Line = Color3.fromRGB(
		35, 55, 88
	),

	LineBright = Color3.fromRGB(
		66, 115, 155
	),
}

--------------------------------------------------------------------
-- [FACTORY: INSTANCE CREATOR]
-- Fungsi pendek untuk membuat UI object.
--------------------------------------------------------------------

local function New(
	className,
	properties,
	parent
)

	local object =
		Instance.new(className)

	for property, value in pairs(
		properties or {}
	) do

		pcall(function()

			object[property] =
				value

		end)

	end

	if parent then
		object.Parent = parent
	end

	return object
end

--------------------------------------------------------------------
-- [FACTORY: CORNER]
--------------------------------------------------------------------

local function Corner(
	parent,
	radius
)

	return New(
		"UICorner",
		{
			CornerRadius =
				UDim.new(
					0,
					radius or 10
				),
		},
		parent
	)

end

--------------------------------------------------------------------
-- [FACTORY: STROKE]
--------------------------------------------------------------------

local function Stroke(
	parent,
	color,
	thickness,
	transparency
)

	return New(
		"UIStroke",
		{
			Color = color,

			Thickness =
				thickness or 1,

			Transparency =
				transparency or 0,

			ApplyStrokeMode =
				Enum.ApplyStrokeMode.Border,
		},
		parent
	)

end

--------------------------------------------------------------------
-- [FACTORY: GRADIENT]
--------------------------------------------------------------------

local function Gradient(
	parent,
	colors,
	rotation
)

	return New(
		"UIGradient",
		{
			Rotation =
				rotation or 0,

			Color =
				ColorSequence.new(
					colors
				),
		},
		parent
	)

end

--------------------------------------------------------------------
-- [FACTORY: TEXT]
--------------------------------------------------------------------

local function Text(
	parent,
	properties
)

	properties =
		properties or {}

	properties.BackgroundTransparency = 1

	properties.Font =
		properties.Font
		or Enum.Font.GothamMedium

	properties.TextColor3 =
		properties.TextColor3
		or COLORS.White

	properties.TextSize =
		properties.TextSize
		or 16

	properties.TextXAlignment =
		properties.TextXAlignment
		or Enum.TextXAlignment.Left

	properties.TextYAlignment =
		properties.TextYAlignment
		or Enum.TextYAlignment.Center

	return New(
		"TextLabel",
		properties,
		parent
	)

end

--------------------------------------------------------------------
-- [FACTORY: BUTTON]
--------------------------------------------------------------------

local function Button(
	parent,
	properties
)

	properties =
		properties or {}

	properties.AutoButtonColor = false

	properties.BorderSizePixel = 0

	properties.Font =
		properties.Font
		or Enum.Font.GothamBold

	properties.TextColor3 =
		properties.TextColor3
		or COLORS.White

	properties.TextSize =
		properties.TextSize
		or 16

	local button =
		New(
			"TextButton",
			properties,
			parent
		)

	Corner(
		button,
		properties.CornerRadius or 10
	)

	return button
end

--------------------------------------------------------------------
-- [ROOT: SCREEN GUI]
--------------------------------------------------------------------

local ScreenGui = New(
	"ScreenGui",
	{
		Name = CONFIG.Name,

		DisplayOrder =
			CONFIG.DisplayOrder,

		IgnoreGuiInset = true,

		ResetOnSpawn = false,

		ZIndexBehavior =
			Enum.ZIndexBehavior.Global,

		Enabled = true,
	},
	PlayerGui
)

pcall(function()

	ScreenGui.ScreenInsets =
		Enum.ScreenInsets.None

end)

pcall(function()

	ScreenGui.OnTopOfCoreBlur =
		true

end)

--------------------------------------------------------------------
-- [ROOT: CONTAINER]
--------------------------------------------------------------------

local Root = New(
	"Frame",
	{
		BackgroundTransparency = 1,

		Size =
			UDim2.fromScale(
				1,
				1
			),

		Position =
			UDim2.fromScale(
				0.5,
				0.5
			),

		AnchorPoint =
			Vector2.new(
				0.5,
				0.5
			),

		ZIndex = 1,
	},
	ScreenGui
)

--------------------------------------------------------------------
-- [WINDOW: MAIN FRAME]
--------------------------------------------------------------------

local MainHolder = New(
	"Frame",
	{
		Name = "MainWindow",

		BackgroundColor3 =
			COLORS.Background,

		Position =
			UDim2.fromScale(
				0.5,
				0.5
			),

		AnchorPoint =
			Vector2.new(
				0.5,
				0.5
			),

		Size =
			UDim2.fromOffset(
				CONFIG.DesktopWidth,
				CONFIG.DesktopHeight
			),

		BorderSizePixel = 0,

		ClipsDescendants = true,

		ZIndex = 20,
	},
	Root
)

Corner(
	MainHolder,
	18
)

Stroke(
	MainHolder,
	COLORS.LineBright,
	1,
	0.15
)

Gradient(
	MainHolder,
	{
		ColorSequenceKeypoint.new(
			0,
			Color3.fromRGB(
				8,
				12,
				27
			)
		),

		ColorSequenceKeypoint.new(
			0.5,
			Color3.fromRGB(
				5,
				9,
				20
			)
		),

		ColorSequenceKeypoint.new(
			1,
			Color3.fromRGB(
				12,
				7,
				25
			)
		),
	},
	135
)

--------------------------------------------------------------------
-- [HEADER: AREA ATAS]
--------------------------------------------------------------------

local Header = New(
	"Frame",
	{
		BackgroundColor3 =
			Color3.fromRGB(
				7,
				11,
				24
			),

		Size =
			UDim2.new(
				1,
				0,
				0,
				CONFIG.HeaderDesktop
			),

		BorderSizePixel = 0,

		ZIndex = 50,
	},
	MainHolder
)

Gradient(
	Header,
	{
		ColorSequenceKeypoint.new(
			0,
			Color3.fromRGB(
				11,
				17,
				36
			)
		),

		ColorSequenceKeypoint.new(
			0.5,
			Color3.fromRGB(
				7,
				11,
				25
			)
		),

		ColorSequenceKeypoint.new(
			1,
			Color3.fromRGB(
				18,
				8,
				32
			)
		),
	},
	0
)

--------------------------------------------------------------------
-- [HEADER: LASER LINE]
--------------------------------------------------------------------

local HeaderLine = New(
	"Frame",
	{
		BackgroundColor3 =
			COLORS.Cyan,

		BackgroundTransparency =
			0.25,

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

		BorderSizePixel = 0,

		ZIndex = 75,
	},
	Header
)

--------------------------------------------------------------------
-- [HEADER: LOGO ZONE]
--------------------------------------------------------------------

local HeaderLogoZone = New(
	"Frame",
	{
		BackgroundTransparency = 1,

		Position =
			UDim2.fromOffset(
				10,
				0
			),

		Size =
			UDim2.fromOffset(
				70,
				CONFIG.HeaderDesktop
			),

		ZIndex = 60,
	},
	Header
)

--------------------------------------------------------------------
-- [HEADER: MAIN LOGO]
--------------------------------------------------------------------

local Logo = New(
	"Frame",
	{
		BackgroundColor3 =
			Color3.fromRGB(
				8,
				16,
				31
			),

		Position =
			UDim2.fromScale(
				0.5,
				0.5
			),

		AnchorPoint =
			Vector2.new(
				0.5,
				0.5
			),

		Size =
			UDim2.fromOffset(
				56,
				56
			),

		BorderSizePixel = 0,

		ZIndex = 65,
	},
	HeaderLogoZone
)

Corner(
	Logo,
	15
)

Stroke(
	Logo,
	COLORS.Cyan,
	1.5,
	0.1
)

Gradient(
	Logo,
	{
		ColorSequenceKeypoint.new(
			0,
			Color3.fromRGB(
				15,
				31,
				58
			)
		),

		ColorSequenceKeypoint.new(
			0.5,
			Color3.fromRGB(
				9,
				18,
				38
			)
		),

		ColorSequenceKeypoint.new(
			1,
			Color3.fromRGB(
				30,
				10,
				49
			)
		),
	},
	135
)

--------------------------------------------------------------------
-- [HEADER: LOGO RINGS]
--------------------------------------------------------------------

local LogoRingOuter = New(
	"Frame",
	{
		BackgroundTransparency = 1,

		Position =
			UDim2.fromScale(
				0.5,
				0.5
			),

		AnchorPoint =
			Vector2.new(
				0.5,
				0.5
			),

		Size =
			UDim2.fromOffset(
				46,
				46
			),

		ZIndex = 66,
	},
	Logo
)

Corner(
	LogoRingOuter,
	99
)

Stroke(
	LogoRingOuter,
	COLORS.Cyan,
	1,
	0.3
)

local LogoRingInner = New(
	"Frame",
	{
		BackgroundTransparency = 1,

		Position =
			UDim2.fromScale(
				0.5,
				0.5
			),

		AnchorPoint =
			Vector2.new(
				0.5,
				0.5
			),

		Size =
			UDim2.fromOffset(
				34,
				34
			),

		ZIndex = 67,
	},
	Logo
)

Corner(
	LogoRingInner,
	99
)

Stroke(
	LogoRingInner,
	COLORS.Violet,
	1.5,
	0.2
)

--------------------------------------------------------------------
-- [HEADER: LOGO CORE]
--------------------------------------------------------------------

local LogoCore = New(
	"Frame",
	{
		BackgroundColor3 =
			COLORS.Cyan,

		Position =
			UDim2.fromScale(
				0.5,
				0.5
			),

		AnchorPoint =
			Vector2.new(
				0.5,
				0.5
			),

		Size =
			UDim2.fromOffset(
				17,
				17
			),

		BorderSizePixel = 0,

		ZIndex = 69,
	},
	Logo
)

Corner(
	LogoCore,
	7
)

Gradient(
	LogoCore,
	{
		ColorSequenceKeypoint.new(
			0,
			COLORS.Cyan
		),

		ColorSequenceKeypoint.new(
			0.5,
			COLORS.Blue
		),

		ColorSequenceKeypoint.new(
			1,
			COLORS.Pink
		),
	},
	45
)

--------------------------------------------------------------------
-- [HEADER: ANIME EYES]
--------------------------------------------------------------------

local EyeLeft = New(
	"Frame",
	{
		BackgroundColor3 =
			COLORS.White,

		Position =
			UDim2.new(
				0.5,
				-12,
				0.5,
				-2
			),

		AnchorPoint =
			Vector2.new(
				0.5,
				0.5
			),

		Size =
			UDim2.fromOffset(
				6,
				3
			),

		Rotation = -12,

		BorderSizePixel = 0,

		ZIndex = 72,
	},
	Logo
)

Corner(
	EyeLeft,
	4
)

local EyeRight = New(
	"Frame",
	{
		BackgroundColor3 =
			COLORS.White,

		Position =
			UDim2.new(
				0.5,
				12,
				0.5,
				-2
			),

		AnchorPoint =
			Vector2.new(
				0.5,
				0.5
			),

		Size =
			UDim2.fromOffset(
				6,
				3
			),

		Rotation = 12,

		BorderSizePixel = 0,

		ZIndex = 72,
	},
	Logo
)

Corner(
	EyeRight,
	4
)

--------------------------------------------------------------------
-- [HEADER: TITLE ZONE]
-- Zona title selalu berhenti sebelum Control Zone.
--------------------------------------------------------------------

local HeaderTitleZone = New(
	"Frame",
	{
		BackgroundTransparency = 1,

		Position =
			UDim2.fromOffset(
				88,
				0
			),

		Size =
			UDim2.new(
				1,
				-(88 + CONFIG.ControlZoneDesktop + 10),
				1,
				0
			),

		ZIndex = 55,

		ClipsDescendants = true,
	},
	Header
)

local Title = Text(
	HeaderTitleZone,
	{
		Text = "VANZ NEXUS",

		Position =
			UDim2.fromOffset(
				2,
				10
			),

		Size =
			UDim2.new(
				1,
				-4,
				0,
				30
			),

		Font =
			Enum.Font.GothamBlack,

		TextSize = 26,

		TextTruncate =
			Enum.TextTruncate.AtEnd,

		ZIndex = 57,
	}
)

Gradient(
	Title,
	{
		ColorSequenceKeypoint.new(
			0,
			COLORS.White
		),

		ColorSequenceKeypoint.new(
			0.45,
			COLORS.Cyan
		),

		ColorSequenceKeypoint.new(
			1,
			COLORS.Violet
		),
	},
	0
)

local Subtitle = Text(
	HeaderTitleZone,
	{
		Text =
			"ROBOTIC ANIME COMMAND INTERFACE  //  NEXUS ONLINE",

		Position =
			UDim2.fromOffset(
				3,
				43
			),

		Size =
			UDim2.new(
				1,
				-6,
				0,
				20
			),

		TextSize = 12,

		TextColor3 =
			COLORS.Muted,

		TextTruncate =
			Enum.TextTruncate.AtEnd,

		ZIndex = 57,
	}
)

--------------------------------------------------------------------
-- [HEADER: EXCLUSIVE CONTROL ZONE]
--
-- HANYA:
-- 1. MINIMIZE
-- 2. CLOSE
--
-- Tidak ada title/status/logo yang boleh masuk sini.
--------------------------------------------------------------------

local HeaderControls = New(
	"Frame",
	{
		BackgroundTransparency = 1,

		Position =
			UDim2.new(
				1,
				-CONFIG.ControlZoneDesktop,
				0,
				0
			),

		Size =
			UDim2.fromOffset(
				CONFIG.ControlZoneDesktop,
				CONFIG.HeaderDesktop
			),

		ZIndex = 100,
	},
	Header
)

local ControlLayout = New(
	"UIListLayout",
	{
		FillDirection =
			Enum.FillDirection.Horizontal,

		HorizontalAlignment =
			Enum.HorizontalAlignment.Center,

		VerticalAlignment =
			Enum.VerticalAlignment.Center,

		Padding =
			UDim.new(
				0,
				8
			),

		SortOrder =
			Enum.SortOrder.LayoutOrder,
	},
	HeaderControls
)

--------------------------------------------------------------------
-- [HEADER: MINIMIZE BUTTON]
--------------------------------------------------------------------

local MinimizeButton = Button(
	HeaderControls,
	{
		Name = "Minimize",

		LayoutOrder = 1,

		Size =
			UDim2.fromOffset(
				50,
				50
			),

		Text = "—",

		TextSize = 27,

		TextColor3 =
			COLORS.Cyan,

		BackgroundColor3 =
			Color3.fromRGB(
				10,
				19,
				36
			),

		ZIndex = 110,

		CornerRadius = 13,
	}
)

Stroke(
	MinimizeButton,
	COLORS.Cyan,
	1.3,
	0.25
)

--------------------------------------------------------------------
-- [HEADER: CLOSE BUTTON]
--------------------------------------------------------------------

local CloseButton = Button(
	HeaderControls,
	{
		Name = "Close",

		LayoutOrder = 2,

		Size =
			UDim2.fromOffset(
				50,
				50
			),

		Text = "×",

		TextSize = 29,

		TextColor3 =
			COLORS.Pink,

		BackgroundColor3 =
			Color3.fromRGB(
				22,
				10,
				29
			),

		ZIndex = 110,

		CornerRadius = 13,
	}
)

Stroke(
	CloseButton,
	COLORS.Pink,
	1.3,
	0.25
)

--------------------------------------------------------------------
-- [BODY: CONTAINER]
--------------------------------------------------------------------

local Body = New(
	"Frame",
	{
		BackgroundTransparency = 1,

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

		ZIndex = 30,
	},
	MainHolder
)

--------------------------------------------------------------------
-- [DESKTOP: SIDEBAR]
--------------------------------------------------------------------

local Sidebar = New(
	"Frame",
	{
		BackgroundColor3 =
			Color3.fromRGB(
				7,
				11,
				23
			),

		Position =
			UDim2.fromOffset(
				0,
				0
			),

		Size =
			UDim2.new(
				0,
				CONFIG.SidebarDesktop,
				1,
				0
			),

		BorderSizePixel = 0,

		ZIndex = 35,
	},
	Body
)

Stroke(
	Sidebar,
	COLORS.Line,
	1,
	0.35
)

--------------------------------------------------------------------
-- [SIDEBAR: TITLE]
--------------------------------------------------------------------

Text(
	Sidebar,
	{
		Text = "NEXUS MENU",

		Position =
			UDim2.fromOffset(
				14,
				15
			),

		Size =
			UDim2.new(
				1,
				-28,
				0,
				24
			),

		TextSize = 12,

		Font =
			Enum.Font.GothamBold,

		TextColor3 =
			COLORS.Cyan,

		ZIndex = 40,
	}
)

--------------------------------------------------------------------
-- [SIDEBAR: NAV CONTAINER]
--------------------------------------------------------------------

local NavContainer = New(
	"Frame",
	{
		BackgroundTransparency = 1,

		Position =
			UDim2.fromOffset(
				12,
				55
			),

		Size =
			UDim2.new(
				1,
				-24,
				1,
				-135
			),

		ZIndex = 40,
	},
	Sidebar
)

New(
	"UIListLayout",
	{
		FillDirection =
			Enum.FillDirection.Vertical,

		Padding =
			UDim.new(
				0,
				9
			),

		SortOrder =
			Enum.SortOrder.LayoutOrder,
	},
	NavContainer
)

--------------------------------------------------------------------
-- [CONTENT: PAGE AREA]
--------------------------------------------------------------------

local Content = New(
	"Frame",
	{
		BackgroundTransparency = 1,

		Position =
			UDim2.fromOffset(
				CONFIG.SidebarDesktop,
				0
			),

		Size =
			UDim2.new(
				1,
				-CONFIG.SidebarDesktop,
				1,
				0
			),

		ZIndex = 40,

		ClipsDescendants = true,
	},
	Body
)

local PageContainer = New(
	"Frame",
	{
		BackgroundTransparency = 1,

		Position =
			UDim2.fromOffset(
				16,
				16
			),

		Size =
			UDim2.new(
				1,
				-32,
				1,
				-32
			),

		ZIndex = 45,

		ClipsDescendants = true,
	},
	Content
)

--------------------------------------------------------------------
-- [MOBILE: BOTTOM NAVIGATION]
--------------------------------------------------------------------

local MobileNav = New(
	"Frame",
	{
		BackgroundColor3 =
			Color3.fromRGB(
				7,
				10,
				22
			),

		Position =
			UDim2.new(
				0,
				0,
				1,
				-CONFIG.BottomNavMobile
			),

		Size =
			UDim2.new(
				1,
				0,
				0,
				CONFIG.BottomNavMobile
			),

		BorderSizePixel = 0,

		Visible = false,

		ZIndex = 200,
	},
	MainHolder
)

Stroke(
	MobileNav,
	COLORS.LineBright,
	1,
	0.35
)

New(
	"UIListLayout",
	{
		FillDirection =
			Enum.FillDirection.Horizontal,

		HorizontalAlignment =
			Enum.HorizontalAlignment.Center,

		VerticalAlignment =
			Enum.VerticalAlignment.Center,

		Padding =
			UDim.new(
				0,
				4
			),

		SortOrder =
			Enum.SortOrder.LayoutOrder,
	},
	MobileNav
)

--------------------------------------------------------------------
-- [PAGE SYSTEM]
--------------------------------------------------------------------

local Pages = {}

local function CreatePage(
	id
)

	local page = New(
		"ScrollingFrame",
		{
			Name = id,

			BackgroundTransparency = 1,

			Size =
				UDim2.fromScale(
					1,
					1
				),

			CanvasSize =
				UDim2.new(
					0,
					0,
					0,
					0
				),

			AutomaticCanvasSize =
				Enum.AutomaticSize.Y,

			ScrollBarThickness = 3,

			ScrollBarImageColor3 =
				COLORS.Cyan,

			BorderSizePixel = 0,

			Visible = false,

			ZIndex = 46,
		},
		PageContainer
	)

	Padding(
		page,
		4,
		8,
		4,
		12
	)

	New(
		"UIListLayout",
		{
			FillDirection =
				Enum.FillDirection.Vertical,

			Padding =
				UDim.new(
					0,
					12
				),

			SortOrder =
				Enum.SortOrder.LayoutOrder,
		},
		page
	)

	Pages[id] = page

	return page
end

--------------------------------------------------------------------
-- [COMPONENT: CARD]
--------------------------------------------------------------------

local function CreateCard(
	parent,
	height,
	accent
)

	local card = New(
		"Frame",
		{
			BackgroundColor3 =
				Color3.fromRGB(
					10,
					15,
					30
				),

			Size =
				UDim2.new(
					1,
					0,
					0,
					height
				),

			BorderSizePixel = 0,

			ZIndex = 50,
		},
		parent
	)

	Corner(
		card,
		14
	)

	Stroke(
		card,
		accent or COLORS.Line,
		1,
		0.35
	)

	New(
		"Frame",
		{
			BackgroundColor3 =
				accent or COLORS.Cyan,

			BackgroundTransparency =
				0.25,

			Position =
				UDim2.fromOffset(
					0,
					0
				),

			Size =
				UDim2.fromOffset(
					3,
					height
				),

			BorderSizePixel = 0,

			ZIndex = 52,
		},
		card
	)

	return card
end

--------------------------------------------------------------------
-- [COMPONENT: CARD TITLE]
--------------------------------------------------------------------

local function CardTitle(
	parent,
	title,
	subtitle,
	accent
)

	Text(
		parent,
		{
			Text = title,

			Position =
				UDim2.fromOffset(
					20,
					12
				),

			Size =
				UDim2.new(
					1,
					-40,
					0,
					25
				),

			TextSize = 17,

			Font =
				Enum.Font.GothamBold,

			ZIndex = 55,
		}
	)

	Text(
		parent,
		{
			Text = subtitle or "",

			Position =
				UDim2.fromOffset(
					20,
					38
				),

			Size =
				UDim2.new(
					1,
					-40,
					0,
					20
				),

			TextSize = 11,

			TextColor3 =
				COLORS.Muted,

			ZIndex = 55,
		}
	)

	New(
		"Frame",
		{
			BackgroundColor3 =
				accent or COLORS.Cyan,

			BackgroundTransparency =
				0.55,

			Position =
				UDim2.fromOffset(
					20,
					62
				),

			Size =
				UDim2.new(
					1,
					-40,
					0,
					1
				),

			BorderSizePixel = 0,

			ZIndex = 55,
		},
		parent
	)

end

--------------------------------------------------------------------
-- [TAB: HOME]
-- Halaman utama / dashboard.
--------------------------------------------------------------------

local Home =
	CreatePage("HOME")

--------------------------------------------------------------------
-- [HOME: HERO]
--------------------------------------------------------------------

local Hero =
	CreateCard(
		Home,
		160,
		COLORS.Cyan
	)

local HeroTitle =
	Text(
		Hero,
		{
			Text =
				"WELCOME TO THE NEXUS",

			Position =
				UDim2.fromOffset(
					24,
					18
				),

			Size =
				UDim2.new(
					1,
					-48,
					0,
					36
				),

			TextSize = 27,

			Font =
				Enum.Font.GothamBlack,

			ZIndex = 60,
		}
	)

Gradient(
	HeroTitle,
	{
		ColorSequenceKeypoint.new(
			0,
			COLORS.White
		),

		ColorSequenceKeypoint.new(
			0.4,
			COLORS.Cyan
		),

		ColorSequenceKeypoint.new(
			1,
			COLORS.Violet
		),
	},
	0
)

Text(
	Hero,
	{
		Text =
			"Robotic anime command layer initialized.",

		Position =
			UDim2.fromOffset(
				25,
				57
			),

		Size =
			UDim2.new(
				1,
				-50,
				0,
				25
			),

		TextSize = 14,

		TextColor3 =
			COLORS.Muted,

		ZIndex = 60,
	}
)

local HeroStatus =
	New(
		"Frame",
		{
			BackgroundColor3 =
				Color3.fromRGB(
					8,
					26,
					27
				),

			Position =
				UDim2.fromOffset(
					24,
					96
				),

			Size =
				UDim2.fromOffset(
					160,
					40
				),

			BorderSizePixel = 0,

			ZIndex = 60,
		},
		Hero
	)

Corner(
	HeroStatus,
	10
)

Stroke(
	HeroStatus,
	COLORS.Good,
	1,
	0.35
)

local StatusDot =
	New(
		"Frame",
		{
			BackgroundColor3 =
				COLORS.Good,

			Position =
				UDim2.fromOffset(
					14,
					12
				),

			Size =
				UDim2.fromOffset(
					15,
					15
				),

			BorderSizePixel = 0,

			ZIndex = 62,
		},
		HeroStatus
	)

Corner(
	StatusDot,
	99
)

Text(
	HeroStatus,
	{
		Text =
			"SYSTEM ONLINE",

		Position =
			UDim2.fromOffset(
				38,
				0
			),

		Size =
			UDim2.new(
				1,
				-42,
				1,
				0
			),

		TextSize = 11,

		Font =
			Enum.Font.GothamBold,

		TextColor3 =
			COLORS.Good,

		ZIndex = 62,
	}
)

--------------------------------------------------------------------
-- [HOME: METRICS]
--------------------------------------------------------------------

local StatusGrid =
	New(
		"Frame",
		{
			BackgroundTransparency = 1,

			Size =
				UDim2.new(
					1,
					0,
					0,
					110
				),

			ZIndex = 50,

			LayoutOrder = 2,
		},
		Home
	)

New(
	"UIGridLayout",
	{
		CellPadding =
			UDim2.fromOffset(
				10,
				10
			),

		CellSize =
			UDim2.new(
				0.333,
				-7,
				1,
				0
			),

		SortOrder =
			Enum.SortOrder.LayoutOrder,
	},
	StatusGrid
)

--------------------------------------------------------------------
-- [COMPONENT: METRIC]
--------------------------------------------------------------------

local function CreateMetric(
	parent,
	title,
	value,
	accent
)

	local card =
		New(
			"Frame",
			{
				BackgroundColor3 =
					Color3.fromRGB(
						9,
						14,
						28
					),

				BorderSizePixel = 0,

				ZIndex = 52,
			},
			parent
		)

	Corner(
		card,
		13
	)

	Stroke(
		card,
		accent,
		1,
		0.4
	)

	Text(
		card,
		{
			Text = title,

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

			TextSize = 11,

			TextColor3 =
				COLORS.Muted,

			ZIndex = 55,
		}
	)

	local valueLabel =
		Text(
			card,
			{
				Text = value,

				Position =
					UDim2.fromOffset(
						15,
						37
					),

				Size =
					UDim2.new(
						1,
						-30,
						0,
						35
					),

				TextSize = 23,

				Font =
					Enum.Font.GothamBlack,

				TextColor3 =
					accent,

				ZIndex = 55,
			}
		)

	return valueLabel
end

local FPSValue =
	CreateMetric(
		StatusGrid,
		"FRAME RATE",
		"-- FPS",
		COLORS.Cyan
	)

local PingValue =
	CreateMetric(
		StatusGrid,
		"NETWORK",
		"-- MS",
		COLORS.Violet
	)

local UptimeValue =
	CreateMetric(
		StatusGrid,
		"UPTIME",
		"00:00",
		COLORS.Good
	)

--------------------------------------------------------------------
-- [HOME: RADAR]
--------------------------------------------------------------------

local RadarCard =
	CreateCard(
		Home,
		260,
		COLORS.Violet
	)

RadarCard.LayoutOrder = 3

CardTitle(
	RadarCard,
	"NEURAL RADAR",
	"LIVE NEXUS ACTIVITY MONITOR",
	COLORS.Violet
)

local Radar =
	New(
		"Frame",
		{
			BackgroundColor3 =
				Color3.fromRGB(
					4,
					12,
					22
				),

			Position =
				UDim2.fromOffset(
					24,
					78
				),

			Size =
				UDim2.fromOffset(
					170,
					170
				),

			BorderSizePixel = 0,

			ZIndex = 55,
		},
		RadarCard
	)

Corner(
	Radar,
	99
)

Stroke(
	Radar,
	COLORS.Cyan,
	1,
	0.25
)

for i = 1, 3 do

	local ring =
		New(
			"Frame",
			{
				BackgroundTransparency = 1,

				Position =
					UDim2.fromScale(
						0.5,
						0.5
					),

				AnchorPoint =
					Vector2.new(
						0.5,
						0.5
					),

				Size =
					UDim2.fromOffset(
						45 + i * 40,
						45 + i * 40
					),

				ZIndex = 56,
			},
			Radar
		)

	Corner(
		ring,
		99
	)

	Stroke(
		ring,
		COLORS.Cyan,
		1,
		0.7
	)

end

local RadarSweep =
	New(
		"Frame",
		{
			BackgroundColor3 =
				COLORS.Cyan,

			BackgroundTransparency =
				0.55,

			Position =
				UDim2.fromScale(
					0.5,
					0.5
				),

			AnchorPoint =
				Vector2.new(
					0,
					0.5
				),

			Size =
				UDim2.fromOffset(
					75,
					2
				),

			BorderSizePixel = 0,

			ZIndex = 59,
		},
		Radar
	)

local RadarCore =
	New(
		"Frame",
		{
			BackgroundColor3 =
				COLORS.Cyan,

			Position =
				UDim2.fromScale(
					0.5,
					0.5
				),

			AnchorPoint =
				Vector2.new(
					0.5,
					0.5
				),

			Size =
				UDim2.fromOffset(
					8,
					8
				),

			BorderSizePixel = 0,

			ZIndex = 60,
		},
		Radar
	)

Corner(
	RadarCore,
	99
)

--------------------------------------------------------------------
-- [TAB: NEXUS]
-- Halaman inti robot / anime core.
--------------------------------------------------------------------

local Nexus =
	CreatePage("NEXUS")

local CoreCard =
	CreateCard(
		Nexus,
		250,
		COLORS.Violet
	)

CardTitle(
	CoreCard,
	"NEURAL CORE",
	"ROBOTIC ANIME VISUAL PROCESSOR",
	COLORS.Violet
)

local BigCore =
	New(
		"Frame",
		{
			BackgroundColor3 =
				Color3.fromRGB(
					8,
					14,
					29
				),

			Position =
				UDim2.fromOffset(
					25,
					82
				),

			Size =
				UDim2.fromOffset(
					150,
					150
				),

			BorderSizePixel = 0,

			ZIndex = 60,
		},
		CoreCard
	)

Corner(
	BigCore,
	99
)

Stroke(
	BigCore,
	COLORS.Violet,
	1.5,
	0.15
)

local BigRing1 =
	New(
		"Frame",
		{
			BackgroundTransparency = 1,

			Position =
				UDim2.fromScale(
					0.5,
					0.5
				),

			AnchorPoint =
				Vector2.new(
					0.5,
					0.5
				),

			Size =
				UDim2.fromOffset(
					125,
					125
				),

			ZIndex = 61,
		},
		BigCore
	)

Corner(
	BigRing1,
	99
)

Stroke(
	BigRing1,
	COLORS.Cyan,
	1,
	0.4
)

local BigRing2 =
	New(
		"Frame",
		{
			BackgroundTransparency = 1,

			Position =
				UDim2.fromScale(
					0.5,
					0.5
				),

			AnchorPoint =
				Vector2.new(
					0.5,
					0.5
				),

			Size =
				UDim2.fromOffset(
					90,
					90
				),

			ZIndex = 62,
		},
		BigCore
	)

Corner(
	BigRing2,
	99
)

Stroke(
	BigRing2,
	COLORS.Pink,
	1,
	0.4
)

local BigCoreCenter =
	New(
		"Frame",
		{
			BackgroundColor3 =
				COLORS.Cyan,

			Position =
				UDim2.fromScale(
					0.5,
					0.5
				),

			AnchorPoint =
				Vector2.new(
					0.5,
					0.5
				),

			Size =
				UDim2.fromOffset(
					42,
					42
				),

			BorderSizePixel = 0,

			ZIndex = 64,
		},
		BigCore
	)

Corner(
	BigCoreCenter,
	15
)

Gradient(
	BigCoreCenter,
	{
		ColorSequenceKeypoint.new(
			0,
			COLORS.Cyan
		),

		ColorSequenceKeypoint.new(
			0.5,
			COLORS.Blue
		),

		ColorSequenceKeypoint.new(
			1,
			COLORS.Pink
		),
	},
	45
)

--------------------------------------------------------------------
-- [TAB: VISUALS]
-- Pengaturan animasi dan efek visual.
--------------------------------------------------------------------

local Visuals =
	CreatePage("VISUALS")

local VisualCard =
	CreateCard(
		Visuals,
		350,
		COLORS.Pink
	)

CardTitle(
	VisualCard,
	"VISUAL MATRIX",
	"CONTROL THE NEXUS ATMOSPHERE",
	COLORS.Pink
)

local ToggleContainer =
	New(
		"Frame",
		{
			BackgroundTransparency = 1,

			Position =
				UDim2.fromOffset(
					20,
					76
				),

			Size =
				UDim2.new(
					1,
					-40,
					1,
					-88
				),

			ZIndex = 60,
		},
		VisualCard
	)

New(
	"UIListLayout",
	{
		FillDirection =
			Enum.FillDirection.Vertical,

		Padding =
			UDim.new(
				0,
				8
			),
	},
	ToggleContainer
)

--------------------------------------------------------------------
-- [COMPONENT: TOGGLE]
--------------------------------------------------------------------

local function CreateToggle(
	parent,
	label,
	description,
	initial,
	callback
)

	local row =
		New(
			"Frame",
			{
				BackgroundColor3 =
					Color3.fromRGB(
						12,
						18,
						34
					),

				Size =
					UDim2.new(
						1,
						0,
						0,
						50
					),

				BorderSizePixel = 0,

				ZIndex = 65,
			},
			parent
		)

	Corner(
		row,
		10
	)

	Stroke(
		row,
		COLORS.Line,
		1,
		0.5
	)

	Text(
		row,
		{
			Text = label,

			Position =
				UDim2.fromOffset(
					14,
					5
				),

			Size =
				UDim2.new(
					1,
					-100,
					0,
					20
				),

			TextSize = 13,

			Font =
				Enum.Font.GothamBold,

			ZIndex = 68,
		}
	)

	Text(
		row,
		{
			Text = description,

			Position =
				UDim2.fromOffset(
					14,
					25
				),

			Size =
				UDim2.new(
					1,
					-100,
					0,
					17
				),

			TextSize = 10,

			TextColor3 =
				COLORS.Muted,

			ZIndex = 68,
		}
	)

	local toggle =
		Button(
			row,
			{
				Position =
					UDim2.new(
						1,
						-70,
						0.5,
						0
					),

				AnchorPoint =
					Vector2.new(
						0,
						0.5
					),

				Size =
					UDim2.fromOffset(
						54,
						28
					),

				Text = "",

				BackgroundColor3 =
					initial
					and Color3.fromRGB(
						10,
						55,
						59
					)
					or Color3.fromRGB(
						26,
						30,
						42
					),

				ZIndex = 70,

				CornerRadius = 14,
			}
		)

	local knob =
		New(
			"Frame",
			{
				BackgroundColor3 =
					initial
					and COLORS.Cyan
					or COLORS.Muted,

				Position =
					initial
					and UDim2.new(
						1,
						-24,
						0.5,
						0
					)
					or UDim2.fromOffset(
						14,
						14
					),

				AnchorPoint =
					Vector2.new(
						0.5,
						0.5
					),

				Size =
					UDim2.fromOffset(
						20,
						20
					),

				BorderSizePixel = 0,

				ZIndex = 72,
			},
			toggle
		)

	Corner(
		knob,
		99
	)

	local enabled = initial

	Connect(
		toggle.Activated,
		function()

			enabled =
				not enabled

			Tween(
				toggle,
				0.18,
				{
					BackgroundColor3 =
						enabled
						and Color3.fromRGB(
							10,
							55,
							59
						)
						or Color3.fromRGB(
							26,
							30,
							42
						),
				}
			)

			Tween(
				knob,
				0.18,
				{
					Position =
						enabled
						and UDim2.new(
							1,
							-24,
							0.5,
							0
						)
						or UDim2.fromOffset(
							14,
							14
						),

					BackgroundColor3 =
						enabled
						and COLORS.Cyan
						or COLORS.Muted,
				}
			)

			callback(
				enabled
			)

		end
	)

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
	"Button feedback and touch response.",
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

--------------------------------------------------------------------
-- [TAB: TELEMETRY]
-- Data FPS, ping, memory dan uptime.
--------------------------------------------------------------------

local Telemetry =
	CreatePage("TELEMETRY")

local TelemetryCard =
	CreateCard(
		Telemetry,
		320,
		COLORS.Blue
	)

CardTitle(
	TelemetryCard,
	"SYSTEM TELEMETRY",
	"REAL-TIME CLIENT DIAGNOSTICS",
	COLORS.Blue
)

local TelemetryGrid =
	New(
		"Frame",
		{
			BackgroundTransparency = 1,

			Position =
				UDim2.fromOffset(
					20,
					78
				),

			Size =
				UDim2.new(
					1,
					-40,
					1,
					-90
				),

			ZIndex = 60,
		},
		TelemetryCard
	)

New(
	"UIGridLayout",
	{
		CellPadding =
			UDim2.fromOffset(
				10,
				10
			),

		CellSize =
			UDim2.new(
				0.5,
				-5,
				0,
				95
			),
	},
	TelemetryGrid
)

local T_FPS =
	CreateMetric(
		TelemetryGrid,
		"FPS",
		"--",
		COLORS.Cyan
	)

local T_Ping =
	CreateMetric(
		TelemetryGrid,
		"PING",
		"--",
		COLORS.Violet
	)

local T_Memory =
	CreateMetric(
		TelemetryGrid,
		"MEMORY",
		"--",
		COLORS.Pink
	)

local T_Uptime =
	CreateMetric(
		TelemetryGrid,
		"UPTIME",
		"--",
		COLORS.Good
	)

--------------------------------------------------------------------
-- [TAB: ABOUT]
--------------------------------------------------------------------

local About =
	CreatePage("ABOUT")

local AboutCard =
	CreateCard(
		About,
		310,
		COLORS.Good
	)

CardTitle(
	AboutCard,
	"VANZ NEXUS",
	"ROBOTIC ANIME INTERFACE",
	COLORS.Good
)

Text(
	AboutCard,
	{
		Text =
			"V11 // CLEAN RESPONSIVE ARCHITECTURE",

		Position =
			UDim2.fromOffset(
				22,
				82
			),

		Size =
			UDim2.new(
				1,
				-44,
				0,
				30
			),

		TextSize = 20,

		Font =
			Enum.Font.GothamBlack,

		TextColor3 =
			COLORS.Cyan,

		ZIndex = 60,
	}
)

Text(
	AboutCard,
	{
		Text =
			"This build separates the header controls, content system, mobile navigation and minimized core so each system has its own safe area.",

		Position =
			UDim2.fromOffset(
				22,
				120
			),

		Size =
			UDim2.new(
				1,
				-44,
				0,
				70
			),

		TextSize = 13,

		TextWrapped = true,

		TextColor3 =
			COLORS.Muted,

		ZIndex = 60,
	}
)

--------------------------------------------------------------------
-- [NAVIGATION: DATA]
--------------------------------------------------------------------

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

--------------------------------------------------------------------
-- [NAVIGATION: BUTTON CREATOR]
--------------------------------------------------------------------

local function CreateNavButton(
	parent,
	item,
	mobile
)

	local button =
		Button(
			parent,
			{
				Name = item.Id,

				Size =
					mobile
					and UDim2.fromOffset(
						60,
						60
					)
					or UDim2.new(
						1,
						0,
						0,
						52
					),

				Text = "",

				BackgroundColor3 =
					Color3.fromRGB(
						9,
						14,
						28
					),

				ZIndex =
					mobile
					and 210
					or 45,

				CornerRadius = 12,
			}
		)

	Text(
		button,
		{
			Text = item.Icon,

			Position =
				mobile
				and UDim2.fromScale(
					0.5,
					0
				)
				or UDim2.fromOffset(
					13,
					0
				),

			AnchorPoint =
				mobile
				and Vector2.new(
					0.5,
					0
				)
				or Vector2.new(
					0,
					0
				),

			Size =
				mobile
				and UDim2.fromOffset(
					60,
					32
				)
				or UDim2.fromOffset(
					30,
					52
				),

			TextSize =
				mobile
				and 21
				or 19,

			Font =
				Enum.Font.GothamBlack,

			TextColor3 =
				item.Accent,

			TextXAlignment =
				Enum.TextXAlignment.Center,

			ZIndex =
				mobile
				and 215
				or 48,
		}
	)

	if mobile then

		Text(
			button,
			{
				Text =
					item.Id
					== "TELEMETRY"
					and "DATA"
					or item.Label,

				Position =
					UDim2.new(
						0,
						0,
						1,
						-23
					),

				Size =
					UDim2.new(
						1,
						0,
						0,
						20
					),

				TextSize = 8,

				Font =
					Enum.Font.GothamBold,

				TextColor3 =
					COLORS.Muted,

				TextXAlignment =
					Enum.TextXAlignment.Center,

				ZIndex = 216,
			}
		)

	else

		Text(
			button,
			{
				Text = item.Label,

				Position =
					UDim2.fromOffset(
						45,
						0
					),

				Size =
					UDim2.new(
						1,
						-55,
						1,
						0
					),

				TextSize = 12,

				Font =
					Enum.Font.GothamBold,

				TextColor3 =
					COLORS.Muted,

				ZIndex = 48,
			}
		)

	end

	local activeBar =
		New(
			"Frame",
			{
				BackgroundColor3 =
					item.Accent,

				Position =
					mobile
					and UDim2.new(
						0.5,
						-16,
						0,
						0
					)
					or UDim2.fromOffset(
						0,
						9
					),

				Size =
					mobile
					and UDim2.fromOffset(
						32,
						2
					)
					or UDim2.fromOffset(
						3,
						34
					),

				Visible = false,

				BorderSizePixel = 0,

				ZIndex =
					mobile
					and 220
					or 50,
			},
			button
		)

	Corner(
		activeBar,
		4
	)

	NavButtons[item.Id] = {

		Button = button,

		Bar = activeBar,

		Accent = item.Accent,

		Mobile = mobile,
	}

	Connect(
		button.Activated,
		function()

			State.CurrentPage =
				item.Id

			for pageId, page in pairs(
				Pages
			) do

				page.Visible =
					pageId
					== item.Id

			end

			for id, info in pairs(
				NavButtons
			) do

				local selected =
					id
					== item.Id

				info.Bar.Visible =
					selected

				info.Button.BackgroundColor3 =
					selected
					and Color3.fromRGB(
						14,
						24,
						42
					)
					or Color3.fromRGB(
						9,
						14,
						28
					)

			end

		end
	)

end

--------------------------------------------------------------------
-- [NAVIGATION: DESKTOP]
--------------------------------------------------------------------

for _, item in ipairs(
	NAV_ITEMS
) do

	CreateNavButton(
		NavContainer,
		item,
		false
	)

end

--------------------------------------------------------------------
-- [NAVIGATION: MOBILE]
--------------------------------------------------------------------

for _, item in ipairs(
	NAV_ITEMS
) do

	CreateNavButton(
		MobileNav,
		item,
		true
	)

end

--------------------------------------------------------------------
-- [NAVIGATION: DEFAULT TAB]
--------------------------------------------------------------------

Pages.HOME.Visible = true

for id, info in pairs(
	NavButtons
) do

	if id == "HOME" then

		info.Bar.Visible = true

		info.Button.BackgroundColor3 =
			Color3.fromRGB(
				14,
				24,
				42
			)

	end

end

--------------------------------------------------------------------
-- [VISUAL FX: SCANLINES]
--------------------------------------------------------------------

local ScanContainer =
	New(
		"Frame",
		{
			Name = "Scanlines",

			BackgroundTransparency = 1,

			Size =
				UDim2.fromScale(
					1,
					1
				),

			ClipsDescendants = true,

			ZIndex = 300,
		},
		MainHolder
	)

for i = 1, 8 do

	New(
		"Frame",
		{
			BackgroundColor3 =
				COLORS.Cyan,

			BackgroundTransparency =
				0.96,

			Position =
				UDim2.new(
					0,
					0,
					0,
					i * 80
				),

			Size =
				UDim2.new(
					1,
					0,
					0,
					1
				),

			BorderSizePixel = 0,

			ZIndex = 301,
		},
		ScanContainer
	)

end

--------------------------------------------------------------------
-- [VISUAL FX: CIRCUIT LINES]
--------------------------------------------------------------------

local CircuitLayer =
	New(
		"Frame",
		{
			BackgroundTransparency = 1,

			Size =
				UDim2.fromScale(
					1,
					1
				),

			ZIndex = 302,
		},
		MainHolder
	)

local function Circuit(
	x,
	y,
	width,
	height,
	color
)

	return New(
		"Frame",
		{
			BackgroundColor3 =
				color,

			BackgroundTransparency =
				0.55,

			Position =
				UDim2.new(
					x,
					0,
					y,
					0
				),

			Size =
				UDim2.fromOffset(
					width,
					height
				),

			BorderSizePixel = 0,

			ZIndex = 303,
		},
		CircuitLayer
	)

end

Circuit(
	0.03,
	0.14,
	90,
	1,
	COLORS.Cyan
)

Circuit(
	0.04,
	0.14,
	1,
	42,
	COLORS.Cyan
)

Circuit(
	0.04,
	0.205,
	45,
	1,
	COLORS.Violet
)

Circuit(
	0.92,
	0.82,
	65,
	1,
	COLORS.Pink
)

Circuit(
	0.94,
	0.74,
	1,
	52,
	COLORS.Pink
)

--------------------------------------------------------------------
-- [VISUAL FX: PARTICLES]
--------------------------------------------------------------------

local ParticleLayer =
	New(
		"Frame",
		{
			Name = "Particles",

			BackgroundTransparency = 1,

			Size =
				UDim2.fromScale(
					1,
					1
				),

			ClipsDescendants = true,

			ZIndex = 304,
		},
		MainHolder
	)

local RandomGenerator =
	Random.new()

for i = 1, CONFIG.ParticleCount do

	local particle =
		New(
			"Frame",
			{
				BackgroundColor3 =
					COLORS.Cyan,

				BackgroundTransparency =
					RandomGenerator:NextNumber(
						0.35,
						0.8
					),

				Position =
					UDim2.fromScale(
						RandomGenerator:NextNumber(
							0.02,
							0.98
						),

						RandomGenerator:NextNumber(
							0.08,
							0.95
						)
					),

				Size =
					UDim2.fromOffset(
						RandomGenerator:NextInteger(
							1,
							3
						),

						RandomGenerator:NextInteger(
							1,
							3
						)
					),

				BorderSizePixel = 0,

				ZIndex = 305,
			},
			ParticleLayer
		)

	Corner(
		particle,
		99
	)

	table.insert(
		State.Particles,
		{
			Object = particle,

			BaseX =
				particle.Position.X.Scale,

			BaseY =
				particle.Position.Y.Scale,

			Phase =
				RandomGenerator:NextNumber(
					0,
					math.pi * 2
				),

			Speed =
				RandomGenerator:NextNumber(
					0.25,
					0.8
				),
		}
	)

end

--------------------------------------------------------------------
-- [MINIMIZED: CONTAINER]
--
-- BUG FIX:
-- Tidak ada glow/shadow lagi.
-- Yang hidup hanya LOGO + ring + core.
--------------------------------------------------------------------

local MinimizedLayer =
	New(
		"Frame",
		{
			Name = "MinimizedLayer",

			BackgroundTransparency = 1,

			Size =
				UDim2.fromScale(
					1,
					1
				),

			Visible = false,

			ZIndex = 900,
		},
		Root
	)

--------------------------------------------------------------------
-- [MINIMIZED: LOGO]
--
-- Logo sekarang lebih kecil.
-- Tidak menggunakan blue shadow.
--------------------------------------------------------------------

local MinimizedCore =
	New(
		"Frame",
		{
			Name = "MinimizedCore",

			BackgroundColor3 =
				Color3.fromRGB(
					7,
					14,
					28
				),

			Position =
				UDim2.fromScale(
					0.5,
					0.5
				),

			AnchorPoint =
				Vector2.new(
					0.5,
					0.5
				),

			Size =
				UDim2.fromOffset(
					72,
					72
				),

			BorderSizePixel = 0,

			Active = true,

			ZIndex = 910,
		},
		MinimizedLayer
	)

Corner(
	MinimizedCore,
	99
)

Stroke(
	MinimizedCore,
	COLORS.Cyan,
	1.5,
	0.12
)

--------------------------------------------------------------------
-- [MINIMIZED: OUTER RING]
--------------------------------------------------------------------

local MiniRingA =
	New(
		"Frame",
		{
			BackgroundTransparency = 1,

			Position =
				UDim2.fromScale(
					0.5,
					0.5
				),

			AnchorPoint =
				Vector2.new(
					0.5,
					0.5
				),

			Size =
				UDim2.fromOffset(
					61,
					61
				),

			ZIndex = 911,
		},
		MinimizedCore
	)

Corner(
	MiniRingA,
	99
)

Stroke(
	MiniRingA,
	COLORS.Violet,
	1,
	0.2
)

--------------------------------------------------------------------
-- [MINIMIZED: INNER RING]
--------------------------------------------------------------------

local MiniRingB =
	New(
		"Frame",
		{
			BackgroundTransparency = 1,

			Position =
				UDim2.fromScale(
					0.5,
					0.5
				),

			AnchorPoint =
				Vector2.new(
					0.5,
					0.5
				),

			Size =
				UDim2.fromOffset(
					43,
					43
				),

			ZIndex = 912,
		},
		MinimizedCore
	)

Corner(
	MiniRingB,
	99
)

Stroke(
	MiniRingB,
	COLORS.Pink,
	1,
	0.25
)

--------------------------------------------------------------------
-- [MINIMIZED: ANIME CORE]
--------------------------------------------------------------------

local MiniCore =
	New(
		"Frame",
		{
			BackgroundColor3 =
				COLORS.Cyan,

			Position =
				UDim2.fromScale(
					0.5,
					0.5
				),

			AnchorPoint =
				Vector2.new(
					0.5,
					0.5
				),

			Size =
				UDim2.fromOffset(
					24,
					24
				),

			BorderSizePixel = 0,

			ZIndex = 914,
		},
		MinimizedCore
	)

Corner(
	MiniCore,
	8
)

Gradient(
	MiniCore,
	{
		ColorSequenceKeypoint.new(
			0,
			COLORS.Cyan
		),

		ColorSequenceKeypoint.new(
			0.5,
			COLORS.Blue
		),

		ColorSequenceKeypoint.new(
			1,
			COLORS.Pink
		),
	},
	45
)

--------------------------------------------------------------------
-- [MINIMIZED: ANIME EYES]
--------------------------------------------------------------------

local MiniEyeL =
	New(
		"Frame",
		{
			BackgroundColor3 =
				COLORS.White,

			Position =
				UDim2.new(
					0.5,
					-9,
					0.5,
					-1
				),

			AnchorPoint =
				Vector2.new(
					0.5,
					0.5
				),

			Size =
				UDim2.fromOffset(
					5,
					2
				),

			Rotation = -10,

			BorderSizePixel = 0,

			ZIndex = 916,
		},
		MinimizedCore
	)

Corner(
	MiniEyeL,
	3
)

local MiniEyeR =
	New(
		"Frame",
		{
			BackgroundColor3 =
				COLORS.White,

			Position =
				UDim2.new(
					0.5,
					9,
					0.5,
					-1
				),

			AnchorPoint =
				Vector2.new(
					0.5,
					0.5
				),

			Size =
				UDim2.fromOffset(
					5,
					2
				),

			Rotation = 10,

			BorderSizePixel = 0,

			ZIndex = 916,
		},
		MinimizedCore
	)

Corner(
	MiniEyeR,
	3
)

--------------------------------------------------------------------
-- [MINIMIZED: LABEL]
--------------------------------------------------------------------

local MiniLabel =
	Text(
		MinimizedLayer,
		{
			Text = "NEXUS",

			Position =
				UDim2.new(
					0.5,
					-80,
					0.5,
					45
				),

			Size =
				UDim2.fromOffset(
					160,
					20
				),

			TextSize = 9,

			Font =
				Enum.Font.GothamBold,

			TextColor3 =
				COLORS.Cyan,

			TextXAlignment =
				Enum.TextXAlignment.Center,

			ZIndex = 920,
		}
	)

--------------------------------------------------------------------
-- [RESPONSIVE: VIEWPORT]
--------------------------------------------------------------------

local function GetViewport()

	local camera =
		workspace.CurrentCamera

	if not camera then
		return Vector2.new(
			1280,
			720
		)
	end

	return camera.ViewportSize
end

--------------------------------------------------------------------
-- [RESPONSIVE: WINDOW CLAMP]
--------------------------------------------------------------------

local function ApplyWindowOffset()

	if not State.WindowDragged then

		MainHolder.Position =
			UDim2.fromScale(
				0.5,
				0.5
			)

		return
	end

	local viewport =
		GetViewport()

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
			State.WindowOffset.X,
			-maxX,
			maxX
		)

	local y =
		Clamp(
			State.WindowOffset.Y,
			-maxY,
			maxY
		)

	State.WindowOffset =
		Vector2.new(
			x,
			y
		)

	MainHolder.Position =
		UDim2.new(
			0.5,
			x,
			0.5,
			y
		)

end

--------------------------------------------------------------------
-- [RESPONSIVE: MAIN LAYOUT]
--------------------------------------------------------------------

local function UpdateResponsive()

	local viewport =
		GetViewport()

	State.Mobile =
		viewport.X <= 760
		or viewport.Y <= 540

	State.Tiny =
		viewport.X <= 380

	local mobile =
		State.Mobile

	local tiny =
		State.Tiny

	local headerHeight =
		mobile
		and CONFIG.HeaderMobile
		or CONFIG.HeaderDesktop

	local controlWidth =
		mobile
		and CONFIG.ControlZoneMobile
		or CONFIG.ControlZoneDesktop

	----------------------------------------------------------------
	-- MAIN WINDOW SIZE
	----------------------------------------------------------------

	if mobile then

		MainHolder.Size =
			UDim2.fromOffset(
				math.max(
					1,
					viewport.X
						- CONFIG.MobileMargin * 2
				),

				math.max(
					1,
					viewport.Y
						- CONFIG.MobileMargin * 2
				)
			)

	else

		MainHolder.Size =
			UDim2.fromOffset(
				CONFIG.DesktopWidth,
				CONFIG.DesktopHeight
			)

	end

	----------------------------------------------------------------
	-- HEADER SIZE
	----------------------------------------------------------------

	Header.Size =
		UDim2.new(
			1,
			0,
			0,
			headerHeight
		)

	HeaderLogoZone.Size =
		UDim2.fromOffset(
			mobile
			and 62
			or 70,

			headerHeight
		)

	Logo.Size =
		UDim2.fromOffset(
			mobile
			and 48
			or 56,

			mobile
			and 48
			or 56
		)

	----------------------------------------------------------------
	-- CONTROL ZONE
	----------------------------------------------------------------

	HeaderControls.Position =
		UDim2.new(
			1,
			-controlWidth,
			0,
			0
		)

	HeaderControls.Size =
		UDim2.fromOffset(
			controlWidth,
			headerHeight
		)

	MinimizeButton.Size =
		UDim2.fromOffset(
			mobile
			and 46
			or 50,

			mobile
			and 46
			or 50
		)

	CloseButton.Size =
		UDim2.fromOffset(
			mobile
			and 46
			or 50,

			mobile
			and 46
			or 50
		)

	----------------------------------------------------------------
	-- TITLE ZONE
	----------------------------------------------------------------

	local logoZoneWidth =
		mobile
		and 70
		or 88

	HeaderTitleZone.Position =
		UDim2.fromOffset(
			logoZoneWidth,
			0
		)

	HeaderTitleZone.Size =
		UDim2.new(
			1,
			-(logoZoneWidth
				+ controlWidth
				+ 10),

			1,
			0
		)

	Title.TextSize =
		tiny
		and 17
		or mobile
		and 20
		or 26

	Subtitle.Visible =
		not tiny

	Subtitle.TextSize =
		mobile
		and 9
		or 12

	----------------------------------------------------------------
	-- BODY
	----------------------------------------------------------------

	Body.Position =
		UDim2.fromOffset(
			0,
			headerHeight
		)

	Body.Size =
		UDim2.new(
			1,
			0,
			1,
			-headerHeight
		)

	----------------------------------------------------------------
	-- MOBILE
	----------------------------------------------------------------

	if mobile then

		Sidebar.Visible = false

		MobileNav.Visible = true

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
				-CONFIG.BottomNavMobile
			)

		PageContainer.Position =
			UDim2.fromOffset(
				8,
				8
			)

		PageContainer.Size =
			UDim2.new(
				1,
				-16,
				1,
				-16
			)

	else

		Sidebar.Visible = true

		MobileNav.Visible = false

		Content.Position =
			UDim2.fromOffset(
				CONFIG.SidebarDesktop,
				0
			)

		Content.Size =
			UDim2.new(
				1,
				-CONFIG.SidebarDesktop,
				1,
				0
			)

		PageContainer.Position =
			UDim2.fromOffset(
				16,
				16
			)

		PageContainer.Size =
			UDim2.new(
				1,
				-32,
				1,
				-32
			)

	end

	----------------------------------------------------------------
	-- DRAG AREA
	----------------------------------------------------------------

	HeaderDragArea.Position =
		UDim2.fromOffset(
			logoZoneWidth,
			0
		)

	HeaderDragArea.Size =
		UDim2.new(
			1,
			-(logoZoneWidth
				+ controlWidth),

			1,
			0
		)

	ApplyWindowOffset()

end

--------------------------------------------------------------------
-- [DRAG SYSTEM: HEADER WINDOW]
--
-- Hanya HeaderDragArea yang bisa drag.
-- Minimize dan Close tidak termasuk area drag.
--------------------------------------------------------------------

local HeaderDragArea =
	New(
		"TextButton",
		{
			Name = "HeaderDragArea",

			BackgroundTransparency = 1,

			Text = "",

			AutoButtonColor = false,

			Position =
				UDim2.fromOffset(
					88,
					0
				),

			Size =
				UDim2.new(
					1,
					-(88
						+ CONFIG.ControlZoneDesktop),

					1,
					0
				),

			ZIndex = 52,
		},
		Header
	)

--------------------------------------------------------------------
-- [DRAG SYSTEM: BEGIN WINDOW DRAG]
--------------------------------------------------------------------

Connect(
	HeaderDragArea.InputBegan,
	function(input)

		if State.Minimized then
			return
		end

		if input.UserInputType
			~= Enum.UserInputType.MouseButton1
			and input.UserInputType
			~= Enum.UserInputType.Touch then

			return
		end

		State.DraggingWindow = true

		State.WindowDragged = false

		State.WindowDragStart =
			input.Position

		local current =
			MainHolder.Position

		State.WindowStartPosition =
			Vector2.new(
				current.X.Offset,
				current.Y.Offset
			)

	end
)

--------------------------------------------------------------------
-- [DRAG SYSTEM: UPDATE WINDOW]
--------------------------------------------------------------------

Connect(
	UserInputService.InputChanged,
	function(input)

		if not State.DraggingWindow then
			return
		end

		if input.UserInputType
			~= Enum.UserInputType.MouseMovement
			and input.UserInputType
			~= Enum.UserInputType.Touch then

			return
		end

		local delta =
			input.Position
			- State.WindowDragStart

		if delta.Magnitude > 5 then
			State.WindowDragged = true
		end

		local viewport =
			GetViewport()

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
				State.WindowStartPosition.X
					+ delta.X,

				-maxX,
				maxX
			)

		local y =
			Clamp(
				State.WindowStartPosition.Y
					+ delta.Y,

				-maxY,
				maxY
			)

		State.WindowOffset =
			Vector2.new(
				x,
				y
			)

		MainHolder.Position =
			UDim2.new(
				0.5,
				x,
				0.5,
				y
			)

	end
)

--------------------------------------------------------------------
-- [DRAG SYSTEM: END WINDOW DRAG]
--------------------------------------------------------------------

Connect(
	UserInputService.InputEnded,
	function(input)

		if input.UserInputType
			== Enum.UserInputType.MouseButton1
			or input.UserInputType
			== Enum.UserInputType.Touch then

			State.DraggingWindow = false

		end

	end
)

--------------------------------------------------------------------
-- [DRAG SYSTEM: MINIMIZED CORE]
--
-- BUG FIX UTAMA:
--
-- Sebelumnya posisi awal menggunakan Offset dari UDim2.
-- Sekarang kita ambil:
--
--     MinimizedCore.AbsolutePosition
--
-- lalu dikonversi menjadi posisi tengah layar.
--
-- Jadi drag pertama TIDAK TELEPORT.
--------------------------------------------------------------------

Connect(
	MinimizedCore.InputBegan,
	function(input)

		if input.UserInputType
			~= Enum.UserInputType.MouseButton1
			and input.UserInputType
			~= Enum.UserInputType.Touch then

			return
		end

		State.DraggingCore = true

		State.CoreDragged = false

		State.CoreDragStart =
			input.Position

		------------------------------------------------------------
		-- Ambil posisi visual sebenarnya.
		------------------------------------------------------------

		local absolutePosition =
			MinimizedCore.AbsolutePosition

		local absoluteSize =
			MinimizedCore.AbsoluteSize

		------------------------------------------------------------
		-- AbsolutePosition adalah TOP-LEFT.
		-- Kita ubah menjadi CENTER.
		------------------------------------------------------------

		local centerX =
			absolutePosition.X
			+ absoluteSize.X / 2

		local centerY =
			absolutePosition.Y
			+ absoluteSize.Y / 2

		------------------------------------------------------------
		-- Ubah dari koordinat layar menjadi koordinat
		-- relatif terhadap center ScreenGui.
		------------------------------------------------------------

		local viewport =
			GetViewport()

		State.CoreStartAbsolute =
			Vector2.new(
				centerX
					- viewport.X / 2,

				centerY
					- viewport.Y / 2
			)

	end
)

--------------------------------------------------------------------
-- [DRAG SYSTEM: UPDATE MINIMIZED CORE]
--------------------------------------------------------------------

Connect(
	UserInputService.InputChanged,
	function(input)

		if not State.DraggingCore then
			return
		end

		if input.UserInputType
			~= Enum.UserInputType.MouseMovement
			and input.UserInputType
			~= Enum.UserInputType.Touch then

			return
		end

		local delta =
			input.Position
			- State.CoreDragStart

		if delta.Magnitude > 6 then
			State.CoreDragged = true
		end

		local viewport =
			GetViewport()

		local coreSize =
			MinimizedCore.AbsoluteSize

		local halfWidth =
			viewport.X / 2

		local halfHeight =
			viewport.Y / 2

		local maxX =
			halfWidth
			- coreSize.X / 2
			- 5

		local maxY =
			halfHeight
			- coreSize.Y / 2
			- 5

		local minX =
			-halfWidth
			+ coreSize.X / 2
			+ 5

		local minY =
			-halfHeight
			+ coreSize.Y / 2
			+ 5

		local x =
			Clamp(
				State.CoreStartAbsolute.X
					+ delta.X,

				minX,
				maxX
			)

		local y =
			Clamp(
				State.CoreStartAbsolute.Y
					+ delta.Y,

				minY,
				maxY
			)

		------------------------------------------------------------
		-- Sekarang Position selalu memakai Offset.
		-- Tidak ada Scale yang tercampur ketika dragging.
		------------------------------------------------------------

		MinimizedCore.Position =
			UDim2.new(
				0.5,
				x,
				0.5,
				y
			)

	end
)

--------------------------------------------------------------------
-- [DRAG SYSTEM: END MINIMIZED CORE]
--------------------------------------------------------------------

Connect(
	UserInputService.InputEnded,
	function(input)

		if input.UserInputType
			~= Enum.UserInputType.MouseButton1
			and input.UserInputType
			~= Enum.UserInputType.Touch then

			return
		end

		if not State.DraggingCore then
			return
		end

		State.DraggingCore = false

	end
)

--------------------------------------------------------------------
-- [MINIMIZE: FUNCTION]
--------------------------------------------------------------------

local function Minimize()

	if State.Minimized then
		return
	end

	State.Minimized = true

	--------------------------------------------------------------
	-- Simpan posisi logo tetap di tengah.
	--------------------------------------------------------------

	MinimizedCore.Position =
		UDim2.fromScale(
			0.5,
			0.5
		)

	State.CoreDragged = false

	--------------------------------------------------------------
	-- Tampilkan minimized layer.
	--------------------------------------------------------------

	MinimizedLayer.Visible = true

	--------------------------------------------------------------
	-- Animasi window mengecil.
	--------------------------------------------------------------

	Tween(
		MainHolder,
		0.28,
		{
			Size =
				UDim2.fromOffset(
					20,
					20
				),

			BackgroundTransparency = 1,
		},
		Enum.EasingStyle.Back,
		Enum.EasingDirection.In
	)

	task.delay(
		0.24,
		function()

			if State.Minimized then

				MainHolder.Visible =
					false

			end

		end
	)

end

--------------------------------------------------------------------
-- [RESTORE: FUNCTION]
--------------------------------------------------------------------

local function Restore()

	if not State.Minimized then
		return
	end

	State.Minimized = false

	MainHolder.Visible = true

	MainHolder.BackgroundTransparency = 1

	MainHolder.Size =
		UDim2.fromOffset(
			20,
			20
		)

	local viewport =
		GetViewport()

	local targetSize

	if State.Mobile then

		targetSize =
			UDim2.fromOffset(
				math.max(
					1,
					viewport.X
						- CONFIG.MobileMargin * 2
				),

				math.max(
					1,
					viewport.Y
						- CONFIG.MobileMargin * 2
				)
			)

	else

		targetSize =
			UDim2.fromOffset(
				CONFIG.DesktopWidth,
				CONFIG.DesktopHeight
			)

	end

	Tween(
		MainHolder,
		0.42,
		{
			Size = targetSize,

			BackgroundTransparency = 0,
		},
		Enum.EasingStyle.Back,
		Enum.EasingDirection.Out
	)

	task.delay(
		0.25,
		function()

			if not State.Minimized then

				MinimizedLayer.Visible =
					false

			end

		end
	)

	ApplyWindowOffset()

end

--------------------------------------------------------------------
-- [MINIMIZE BUTTON]
--------------------------------------------------------------------

Connect(
	MinimizeButton.Activated,
	function()

		Minimize()

	end
)

--------------------------------------------------------------------
-- [MINIMIZED CORE: TAP TO RESTORE]
--
-- Kalau user cuma tap:
--     Restore
--
-- Kalau user drag:
--     Jangan restore.
--------------------------------------------------------------------

Connect(
	MinimizedCore.InputEnded,
	function(input)

		if input.UserInputType
			~= Enum.UserInputType.MouseButton1
			and input.UserInputType
			~= Enum.UserInputType.Touch then

			return
		end

		if State.CoreDragged then

			State.CoreDragged = false

			return

		end

		Restore()

	end
)

--------------------------------------------------------------------
-- [CLOSE: HAPUS GUI]
--------------------------------------------------------------------

Connect(
	CloseButton.Activated,
	function()

		if State.Destroyed then
			return
		end

		State.Destroyed = true

		Tween(
			MainHolder,
			0.22,
			{
				Size =
					UDim2.fromOffset(
						20,
						20
					),

				BackgroundTransparency = 1,
			}
		)

		task.delay(
			0.25,
			function()

				DisconnectAll()

				for _, tween in ipairs(
					State.Tweens
				) do

					pcall(function()

						tween:Cancel()

					end)

				end

				if ScreenGui then
					ScreenGui:Destroy()
				end

				_G.vanz = nil

			end
		)

	end
)

--------------------------------------------------------------------
-- [VISUAL: BUTTON HOVER]
--------------------------------------------------------------------

local function AddHover(
	button,
	normalColor,
	hoverColor
)

	Connect(
		button.MouseEnter,
		function()

			if not State.InteractionFX then
				return
			end

			Tween(
				button,
				0.15,
				{
					BackgroundColor3 =
						hoverColor,
				}
			)

		end
	)

	Connect(
		button.MouseLeave,
		function()

			if not State.InteractionFX then
				return
			end

			Tween(
				button,
				0.18,
				{
					BackgroundColor3 =
						normalColor,
				}
			)

		end
	)

end

AddHover(
	MinimizeButton,
	Color3.fromRGB(
		10,
		19,
		36
	),
	Color3.fromRGB(
		13,
		43,
		57
	)
)

AddHover(
	CloseButton,
	Color3.fromRGB(
		22,
		10,
		29
	),
	Color3.fromRGB(
		55,
		15,
		38
	)
)

--------------------------------------------------------------------
-- [RESPONSIVE: INITIALIZE]
--------------------------------------------------------------------

local LastViewport =
	Vector2.zero

UpdateResponsive()

--------------------------------------------------------------------
-- [ANIMATION ENGINE]
--
-- Semua efek hidup GUI diproses di sini:
--
-- 1. Ring rotation
-- 2. Core breathing
-- 3. Radar sweep
-- 4. Scanline
-- 5. Particle movement
-- 6. Hue cycling
-- 7. Telemetry
--
-- Tidak ada shadow besar pada minimized logo.
--------------------------------------------------------------------

local TelemetryTimer = 0

local FrameCounter = 0

local FrameTimer = 0

local CurrentFPS = 60

Connect(
	RunService.RenderStepped,
	function(delta)

		if State.Destroyed then
			return
		end

		State.Time += delta

		----------------------------------------------------------------
		-- RESPONSIVE CHECK
		----------------------------------------------------------------

		local viewport =
			GetViewport()

		if viewport ~= LastViewport then

			LastViewport =
				viewport

			UpdateResponsive()

		end

		----------------------------------------------------------------
		-- FPS COUNTER
		----------------------------------------------------------------

		FrameCounter += 1

		FrameTimer += delta

		if FrameTimer >= 0.5 then

			CurrentFPS =
				math.floor(
					FrameCounter
						/ FrameTimer
						+ 0.5
				)

			FrameCounter = 0

			FrameTimer = 0

		end

		----------------------------------------------------------------
		-- HUE
		----------------------------------------------------------------

		if State.HueCycle then

			State.Hue =
				(
					State.Hue
					+ delta * 0.018
				) % 1

		end

		----------------------------------------------------------------
		-- BREATHING VALUE
		----------------------------------------------------------------

		local breathe =
			(
				math.sin(
					State.Time * 1.7
				) + 1
			) / 2

		local pulse =
			(
				math.sin(
					State.Time * 2.4
				) + 1
			) / 2

		----------------------------------------------------------------
		-- DYNAMIC CYAN
		----------------------------------------------------------------

		local dynamicCyan

		if State.HueCycle then

			dynamicCyan =
				HSV(
					0.52
						+ State.Hue
						* 0.15,

					0.72,

					1
				)

		else

			dynamicCyan =
				COLORS.Cyan

		end

		----------------------------------------------------------------
		-- LOGO ROTATION
		----------------------------------------------------------------

		if State.Animations then

			LogoRingOuter.Rotation =
				State.Time * 18

			LogoRingInner.Rotation =
				-State.Time * 27

			BigRing1.Rotation =
				State.Time * 22

			BigRing2.Rotation =
				-State.Time * 35

			MiniRingA.Rotation =
				State.Time * 30

			MiniRingB.Rotation =
				-State.Time * 45

		end

		----------------------------------------------------------------
		-- LOGO BREATHING
		----------------------------------------------------------------

		local logoScale =
			1
			+ breathe * 0.08

		LogoCore.Size =
			UDim2.fromOffset(
				17 * logoScale,
				17 * logoScale
			)

		MiniCore.Size =
			UDim2.fromOffset(
				24
					+ pulse * 4,

				24
					+ pulse * 4
			)

		LogoCore.BackgroundColor3 =
			dynamicCyan

		MiniCore.BackgroundColor3 =
			dynamicCyan

		BigCoreCenter.BackgroundColor3 =
			dynamicCyan

		----------------------------------------------------------------
		-- HEADER LASER
		----------------------------------------------------------------

		HeaderLine.BackgroundColor3 =
			dynamicCyan

		HeaderLine.BackgroundTransparency =
			0.2
			+ (1 - pulse)
			* 0.25

		----------------------------------------------------------------
		-- RADAR
		----------------------------------------------------------------

		if State.Animations then

			RadarSweep.Rotation =
				(
					State.Time * 72
				) % 360

		end

		RadarCore.BackgroundColor3 =
			dynamicCyan

		----------------------------------------------------------------
		-- STATUS DOT
		----------------------------------------------------------------

		local dotScale =
			1
			+ pulse * 0.15

		StatusDot.Size =
			UDim2.fromOffset(
				15 * dotScale,
				15 * dotScale
			)

		----------------------------------------------------------------
		-- SCANLINES
		----------------------------------------------------------------

		ScanContainer.Visible =
			State.Scanlines

		if State.Scanlines then

			local offset =
				(
					State.Time * 35
				) % 80

			for index, child in ipairs(
				ScanContainer:GetChildren()
			) do

				if child:IsA("Frame") then

					child.Position =
						UDim2.new(
							0,
							0,
							0,
							index * 80
								+ offset
						)

				end

			end

		end

		----------------------------------------------------------------
		-- PARTICLES
		----------------------------------------------------------------

		ParticleLayer.Visible =
			State.Particles

		if State.Particles then

			for _, particleData in ipairs(
				State.Particles
			) do

				local particle =
					particleData.Object

				if particle
					and particle.Parent then

					local x =
						particleData.BaseX
						+ math.sin(
							State.Time
								* particleData.Speed
								+ particleData.Phase
						)
						* 0.008

					local y =
						particleData.BaseY
						+ math.cos(
							State.Time
								* particleData.Speed
								+ particleData.Phase
						)
						* 0.012

					particle.Position =
						UDim2.fromScale(
							x,
							y
						)

					particle.BackgroundColor3 =
						dynamicCyan

				end

			end

		end

		----------------------------------------------------------------
		-- MINIMIZED CORE ANIMATION
		--
		-- Tidak ada shadow.
		-- Hanya ring rotation + core breathing.
		----------------------------------------------------------------

		if State.Minimized then

			local coreScale =
				1
				+ pulse * 0.08

			MinimizedCore.Size =
				UDim2.fromOffset(
					72 * coreScale,
					72 * coreScale
				)

			MiniLabel.TextColor3 =
				dynamicCyan

		end

		----------------------------------------------------------------
		-- TELEMETRY
		----------------------------------------------------------------

		TelemetryTimer += delta

		if TelemetryTimer >= 0.5 then

			TelemetryTimer = 0

			local uptime =
				math.floor(
					os.clock()
						- State.OpenedAt
				)

			local minutes =
				math.floor(
					uptime / 60
				)

			local seconds =
				uptime % 60

			local uptimeText =
				string.format(
					"%02d:%02d",
					minutes,
					seconds
				)

			FPSValue.Text =
				tostring(
					CurrentFPS
				)
				.. " FPS"

			T_FPS.Text =
				tostring(
					CurrentFPS
				)

			UptimeValue.Text =
				uptimeText

			T_Uptime.Text =
				uptimeText

			----------------------------------------------------------------
			-- MEMORY
			----------------------------------------------------------------

			local memory

			pcall(function()

				memory =
					Stats:GetTotalMemoryUsageMb()

			end)

			if memory then

				T_Memory.Text =
					string.format(
						"%.0f MB",
						memory
					)

			else

				T_Memory.Text =
					"--"

			end

			----------------------------------------------------------------
			-- PING
			----------------------------------------------------------------

			local ping

			pcall(function()

				local network =
					Stats.Network

				if network then

					local serverStats =
						network.ServerStatsItem

					if serverStats then

						local dataPing =
							serverStats:
							FindFirstChild(
								"Data Ping"
							)

						if dataPing then

							ping =
								math.floor(
									dataPing:GetValue()
								)

						end

					end

				end

			end)

			if ping then

				PingValue.Text =
					tostring(
						ping
					)
					.. " MS"

				T_Ping.Text =
					tostring(
						ping
					)

			else

				PingValue.Text =
					"-- MS"

				T_Ping.Text =
					"--"

			end

		end

	end
)

--------------------------------------------------------------------
-- [SYSTEM: TOPMOST WATCHDOG]
--
-- Menjaga DisplayOrder/ZIndex milik GUI sendiri.
-- Tidak berarti GUI bisa mengalahkan CoreGui/system UI Roblox.
--------------------------------------------------------------------

local WatchdogTimer = 0

Connect(
	RunService.RenderStepped,
	function(delta)

		WatchdogTimer += delta

		if WatchdogTimer < 1 then
			return
		end

		WatchdogTimer = 0

		if not ScreenGui.Parent then
			return
		end

		pcall(function()

			ScreenGui.DisplayOrder =
				CONFIG.DisplayOrder

			ScreenGui.ZIndexBehavior =
				Enum.ZIndexBehavior.Global

		end)

	end
)

--------------------------------------------------------------------
-- [SYSTEM: CHARACTER RESPAWN]
--------------------------------------------------------------------

Connect(
	LocalPlayer.CharacterAdded,
	function()

		task.wait(
			0.5
		)

		if State.Destroyed then
			return
		end

		ScreenGui.Enabled = true

	end
)

--------------------------------------------------------------------
-- [PUBLIC API: _G.vanz]
--
-- Bisa dipakai dari script lain:
--
-- _G.vanz.Open()
-- _G.vanz.Minimize()
-- _G.vanz.Restore()
-- _G.vanz.Close()
-- _G.vanz.SetPage("VISUALS")
-- _G.vanz.GetState()
--------------------------------------------------------------------

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

			MainHolder.Visible =
				true

			ScreenGui.Enabled =
				true

		end

	end,

	Hide = function()

		if State.Destroyed then
			return
		end

		MainHolder.Visible =
			false

		MinimizedLayer.Visible =
			false

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

		if CloseButton
			and CloseButton.Parent then

			CloseButton:Activate()

		end

	end,

	SetPage = function(
		pageName
	)

		if State.Destroyed then
			return
		end

		pageName =
			string.upper(
				tostring(
					pageName
				)
			)

		if not Pages[pageName] then
			return
		end

		State.CurrentPage =
			pageName

		for id, page in pairs(
			Pages
		) do

			page.Visible =
				id == pageName

		end

		for id, info in pairs(
			NavButtons
		) do

			local selected =
				id == pageName

			info.Bar.Visible =
				selected

			info.Button.BackgroundColor3 =
				selected
				and Color3.fromRGB(
					14,
					24,
					42
				)
				or Color3.fromRGB(
					9,
					14,
					28
				)

		end

	end,

	GetState = function()

		return {

			Destroyed =
				State.Destroyed,

			Minimized =
				State.Minimized,

			Mobile =
				State.Mobile,

			Tiny =
				State.Tiny,

			CurrentPage =
				State.CurrentPage,

			Animations =
				State.Animations,

			Neon =
				State.Neon,

			Particles =
				State.Particles,

			Scanlines =
				State.Scanlines,

		}

	end,

	ForceStop = function()

		State.Destroyed =
			true

		DisconnectAll()

		if ScreenGui then
			ScreenGui:Destroy()
		end

		_G.vanz = nil

	end,
}

--------------------------------------------------------------------
-- [BOOT: STARTUP ANIMATION]
--------------------------------------------------------------------

task.defer(
	function()

		task.wait(
			0.05
		)

		UpdateResponsive()

		Tween(
			MainHolder,
			0.45,
			{
				BackgroundTransparency = 0,
			},
			Enum.EasingStyle.Quint,
			Enum.EasingDirection.Out
		)

		Tween(
			LogoCore,
			0.45,
			{
				Size =
					UDim2.fromOffset(
						17,
						17
					),
			},
			Enum.EasingStyle.Back,
			Enum.EasingDirection.Out
		)

	end
)

--------------------------------------------------------------------
-- [END]
-- VANZ NEXUS V11
--
-- Fokus perubahan:
--
-- ✓ Minimized logo lebih kecil.
-- ✓ Tidak ada blue shadow/glow besar.
-- ✓ Logo tetap hidup melalui ring/core animation.
-- ✓ Drag pertama minimized core sudah diperbaiki.
-- ✓ Tidak teleport ke kiri atas.
-- ✓ Posisi drag memakai AbsolutePosition.
-- ✓ Header control zone tetap eksklusif.
-- ✓ Komentar setiap bagian dibuat jelas.
-- ✓ Mobile bottom navigation.
-- ✓ Full code.
--------------------------------------------------------------------