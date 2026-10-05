--// =========================================================
--// VANZ V6 — ROBOTIC LUXURY COMMAND CENTER
--// Futuristic / Robotic / Premium / Animated HUD
--// =========================================================

--// SERVICES
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

--// =========================================================
--// GLOBAL CONFIG
--// =========================================================

_G.vanz = _G.vanz or {}

_G.vanz.Config = {
	Title = "VANZ",
	Subtitle = "ROBOTIC CONTROL CENTER",

	DefaultScale = 0.70,

	Width = 900,
	Height = 560,

	SidebarWidth = 215,
	Margin = 22,

	DynamicColors = true,

	AnimationSpeed = 1,

	DisplayOrder = 999999999,

	Theme = {
		Background = Color3.fromRGB(5, 7, 13),
		Panel = Color3.fromRGB(9, 12, 20),
		Panel2 = Color3.fromRGB(13, 17, 27),

		Primary = Color3.fromRGB(0, 220, 255),
		Secondary = Color3.fromRGB(125, 80, 255),

		Text = Color3.fromRGB(235, 245, 255),
		Muted = Color3.fromRGB(120, 137, 158),

		Success = Color3.fromRGB(55, 255, 170),
		Warning = Color3.fromRGB(255, 190, 75),
		Danger = Color3.fromRGB(255, 75, 110),
	},
}

--// =========================================================
--// CLEAN OLD INSTANCE
--// =========================================================

local oldGui = PlayerGui:FindFirstChild("VANZ_ROBOTIC_GUI")

if oldGui then
	pcall(function()
		oldGui:Destroy()
	end)
end

if _G.vanz.Connections then
	for _, connection in pairs(_G.vanz.Connections) do
		pcall(function()
			connection:Disconnect()
		end)
	end
end

if _G.vanz.Cleanups then
	for _, cleanup in pairs(_G.vanz.Cleanups) do
		pcall(cleanup)
	end
end

_G.vanz.Connections = {}
_G.vanz.Cleanups = {}

--// =========================================================
--// STATE
--// =========================================================

local State = {
	Destroyed = false,

	Minimized = false,

	Animations = true,
	Glow = true,
	ClickFX = true,

	Scale = _G.vanz.Config.DefaultScale,

	Hue = 0,

	OpenedAt = os.clock(),
}

--// =========================================================
--// CONNECTION / CLEANUP
--// =========================================================

local function Connect(signal, callback)
	if State.Destroyed then
		return
	end

	local connection = signal:Connect(callback)

	table.insert(_G.vanz.Connections, connection)

	return connection
end

local function Cleanup(callback)
	table.insert(_G.vanz.Cleanups, callback)
end

--// =========================================================
--// COLORS
--// =========================================================

local Theme = _G.vanz.Config.Theme

local function AccentColor(offset)
	if not _G.vanz.Config.DynamicColors then
		return Theme.Primary
	end

	offset = offset or 0

	return Color3.fromHSV(
		(State.Hue + offset) % 1,
		0.82,
		1
	)
end

local function AccentColor2(offset)
	if not _G.vanz.Config.DynamicColors then
		return Theme.Secondary
	end

	offset = offset or 0.25

	return Color3.fromHSV(
		(State.Hue + offset) % 1,
		0.72,
		1
	)
end

--// =========================================================
--// UTILITY
--// =========================================================

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
		CornerRadius = UDim.new(0, radius or 10),
	})
end

local function Stroke(parent, color, thickness, transparency)
	return New("UIStroke", {
		Parent = parent,
		Color = color or AccentColor(),
		Thickness = thickness or 1,
		Transparency = transparency or 0,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
	})
end

local function Gradient(parent, color1, color2, rotation)
	local gradient = New("UIGradient", {
		Parent = parent,
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, color1),
			ColorSequenceKeypoint.new(1, color2),
		}),
		Rotation = rotation or 0,
	})

	return gradient
end

local function Tween(object, duration, properties, style, direction)
	if not object then
		return
	end

	local tween = TweenService:Create(
		object,
		TweenInfo.new(
			duration / _G.vanz.Config.AnimationSpeed,
			style or Enum.EasingStyle.Quart,
			direction or Enum.EasingDirection.Out
		),
		properties
	)

	tween:Play()

	return tween
end

local function Lerp(a, b, alpha)
	return a:Lerp(b, alpha)
end

--// =========================================================
--// SCREEN GUI
--// =========================================================

local ScreenGui = New("ScreenGui", {
	Name = "VANZ_ROBOTIC_GUI",
	Parent = PlayerGui,

	Enabled = true,

	DisplayOrder = _G.vanz.Config.DisplayOrder,

	IgnoreGuiInset = true,

	ResetOnSpawn = false,

	ZIndexBehavior = Enum.ZIndexBehavior.Global,
})

-- Attempt to stay above Roblox blur layers when supported.
pcall(function()
	ScreenGui.OnTopOfCoreBlur = true
end)

pcall(function()
	ScreenGui.ScreenInsets = Enum.ScreenInsets.None
end)

--// =========================================================
--// MASTER SCALE
--// =========================================================

local UIScale = New("UIScale", {
	Parent = ScreenGui,
	Scale = State.Scale,
})

--// =========================================================
--// MAIN HOLDER
--// =========================================================

local MainHolder = New("Frame", {
	Name = "MainHolder",

	Parent = ScreenGui,

	AnchorPoint = Vector2.new(0.5, 0.5),

	Position = UDim2.fromScale(0.5, 0.5),

	Size = UDim2.fromOffset(
		_G.vanz.Config.Width,
		_G.vanz.Config.Height
	),

	BackgroundTransparency = 1,

	ZIndex = 1000,
})

--// =========================================================
--// SHADOW
--// =========================================================

local Shadow = New("ImageLabel", {
	Name = "Shadow",

	Parent = MainHolder,

	AnchorPoint = Vector2.new(0.5, 0.5),

	Position = UDim2.fromScale(0.5, 0.53),

	Size = UDim2.new(1, 100, 1, 100),

	BackgroundTransparency = 1,

	Image = "rbxassetid://1316045217",

	ImageColor3 = Color3.fromRGB(0, 0, 0),

	ImageTransparency = 0.18,

	ScaleType = Enum.ScaleType.Slice,

	SliceCenter = Rect.new(10, 10, 118, 118),

	ZIndex = 990,
})

--// =========================================================
--// OUTER AURA
--// =========================================================

local Aura = New("Frame", {
	Name = "Aura",

	Parent = MainHolder,

	AnchorPoint = Vector2.new(0.5, 0.5),

	Position = UDim2.fromScale(0.5, 0.5),

	Size = UDim2.new(1, 24, 1, 24),

	BackgroundTransparency = 1,

	ZIndex = 995,
})

Corner(Aura, 24)

local AuraStroke = Stroke(
	Aura,
	AccentColor(),
	2,
	0.55
)

local AuraGradient = Gradient(
	Aura,
	AccentColor(),
	AccentColor2(),
	45
)

--// =========================================================
--// MAIN PANEL
--// =========================================================

local MainPanel = New("Frame", {
	Name = "MainPanel",

	Parent = MainHolder,

	Size = UDim2.fromScale(1, 1),

	BackgroundColor3 = Theme.Background,

	BorderSizePixel = 0,

	ClipsDescendants = true,

	ZIndex = 1000,
})

Corner(MainPanel, 20)

local MainStroke = Stroke(
	MainPanel,
	AccentColor(),
	1.4,
	0.2
)

--// =========================================================
--// TOP LASER LINE
--// =========================================================

local TopLaser = New("Frame", {
	Name = "TopLaser",

	Parent = MainPanel,

	Position = UDim2.new(0, 24, 0, 0),

	Size = UDim2.new(0, 180, 0, 2),

	BackgroundColor3 = AccentColor(),

	BorderSizePixel = 0,

	ZIndex = 1200,
})

Corner(TopLaser, 2)

local TopLaserGlow = New("Frame", {
	Name = "Glow",

	Parent = TopLaser,

	Position = UDim2.new(-0.2, 0, -4, 0),

	Size = UDim2.new(1.4, 0, 9, 0),

	BackgroundColor3 = AccentColor(),

	BackgroundTransparency = 0.75,

	BorderSizePixel = 0,

	ZIndex = 1199,
})

Corner(TopLaserGlow, 8)

--// =========================================================
--// HEADER
--// =========================================================

local Header = New("Frame", {
	Name = "Header",

	Parent = MainPanel,

	Position = UDim2.fromOffset(0, 0),

	Size = UDim2.new(1, 0, 0, 92),

	BackgroundColor3 = Theme.Panel,

	BorderSizePixel = 0,

	ZIndex = 1100,
})

local HeaderGradient = Gradient(
	Header,
	Color3.fromRGB(12, 17, 29),
	Color3.fromRGB(6, 9, 16),
	90
)

--// =========================================================
--// HEADER GRID
--// =========================================================

local HeaderGrid = New("ImageLabel", {
	Name = "Grid",

	Parent = Header,

	Size = UDim2.fromScale(1, 1),

	BackgroundTransparency = 1,

	Image = "rbxassetid://9968344105",

	ImageTransparency = 0.92,

	ImageColor3 = AccentColor(),

	ScaleType = Enum.ScaleType.Tile,

	TileSize = UDim2.fromOffset(40, 40),

	ZIndex = 1101,
})

--// =========================================================
--// LOGO AREA
--// =========================================================

local LogoContainer = New("Frame", {
	Name = "LogoContainer",

	Parent = Header,

	Position = UDim2.fromOffset(22, 15),

	Size = UDim2.fromOffset(64, 64),

	BackgroundTransparency = 1,

	ZIndex = 1200,
})

-- outer ring
local LogoRing = New("Frame", {
	Name = "Ring",

	Parent = LogoContainer,

	AnchorPoint = Vector2.new(0.5, 0.5),

	Position = UDim2.fromScale(0.5, 0.5),

	Size = UDim2.fromOffset(58, 58),

	BackgroundTransparency = 1,

	ZIndex = 1201,
})

Corner(LogoRing, 100)

local LogoRingStroke = Stroke(
	LogoRing,
	AccentColor(),
	2,
	0.05
)

-- second ring
local LogoRing2 = New("Frame", {
	Name = "Ring2",

	Parent = LogoContainer,

	AnchorPoint = Vector2.new(0.5, 0.5),

	Position = UDim2.fromScale(0.5, 0.5),

	Size = UDim2.fromOffset(46, 46),

	BackgroundTransparency = 1,

	ZIndex = 1202,
})

Corner(LogoRing2, 100)

local LogoRing2Stroke = Stroke(
	LogoRing2,
	AccentColor2(),
	1,
	0.15
)

-- logo core
local LogoCore = New("Frame", {
	Name = "Core",

	Parent = LogoContainer,

	AnchorPoint = Vector2.new(0.5, 0.5),

	Position = UDim2.fromScale(0.5, 0.5),

	Size = UDim2.fromOffset(34, 34),

	BackgroundColor3 = Color3.fromRGB(7, 12, 20),

	BorderSizePixel = 0,

	ZIndex = 1203,
})

Corner(LogoCore, 12)

local LogoCoreStroke = Stroke(
	LogoCore,
	AccentColor(),
	1.5,
	0
)

local LogoGradient = Gradient(
	LogoCore,
	AccentColor(),
	AccentColor2(),
	135
)

local LogoText = New("TextLabel", {
	Name = "LogoText",

	Parent = LogoCore,

	Size = UDim2.fromScale(1, 1),

	BackgroundTransparency = 1,

	Text = "V",

	TextColor3 = Color3.fromRGB(240, 250, 255),

	TextSize = 22,

	Font = Enum.Font.GothamBlack,

	TextStrokeTransparency = 0.75,

	ZIndex = 1204,
})

-- rotating ticks
for i = 1, 8 do
	local angle = math.rad((i - 1) * 45)

	local tick = New("Frame", {
		Name = "Tick" .. i,

		Parent = LogoContainer,

		AnchorPoint = Vector2.new(0.5, 1),

		Position = UDim2.new(
			0.5 + math.cos(angle) * 0.43,
			0,
			0.5 + math.sin(angle) * 0.43,
			0
		),

		Size = UDim2.fromOffset(2, 7),

		BackgroundColor3 = AccentColor(),

		BorderSizePixel = 0,

		Rotation = math.deg(angle) + 90,

		ZIndex = 1205,
	})

	Corner(tick, 2)
end

--// =========================================================
--// TITLE
--// =========================================================

local Title = New("TextLabel", {
	Name = "Title",

	Parent = Header,

	Position = UDim2.fromOffset(98, 17),

	Size = UDim2.new(0, 360, 0, 28),

	BackgroundTransparency = 1,

	Text = _G.vanz.Config.Title,

	TextColor3 = Theme.Text,

	TextSize = 24,

	Font = Enum.Font.GothamBlack,

	TextXAlignment = Enum.TextXAlignment.Left,

	ZIndex = 1200,
})

local Subtitle = New("TextLabel", {
	Name = "Subtitle",

	Parent = Header,

	Position = UDim2.fromOffset(100, 46),

	Size = UDim2.new(0, 400, 0, 20),

	BackgroundTransparency = 1,

	Text = _G.vanz.Config.Subtitle,

	TextColor3 = AccentColor(),

	TextSize = 10,

	Font = Enum.Font.GothamBold,

	TextXAlignment = Enum.TextXAlignment.Left,

	LetterSpacing = 0.15,

	ZIndex = 1200,
})

--// =========================================================
--// TELEMETRY
--// =========================================================

local Telemetry = New("TextLabel", {
	Name = "Telemetry",

	Parent = Header,

	AnchorPoint = Vector2.new(1, 0),

	Position = UDim2.new(1, -155, 0, 17),

	Size = UDim2.fromOffset(170, 18),

	BackgroundTransparency = 1,

	Text = "SYS // VANZ-CORE",

	TextColor3 = Theme.Muted,

	TextSize = 9,

	Font = Enum.Font.Code,

	TextXAlignment = Enum.TextXAlignment.Right,

	ZIndex = 1200,
})

local Telemetry2 = New("TextLabel", {
	Name = "Telemetry2",

	Parent = Header,

	AnchorPoint = Vector2.new(1, 0),

	Position = UDim2.new(1, -155, 0, 37),

	Size = UDim2.fromOffset(170, 18),

	BackgroundTransparency = 1,

	Text = "SECURE CONNECTION",

	TextColor3 = AccentColor(),

	TextSize = 9,

	Font = Enum.Font.Code,

	TextXAlignment = Enum.TextXAlignment.Right,

	ZIndex = 1200,
})

--// =========================================================
--// ONLINE PILL
--// =========================================================

local OnlinePill = New("Frame", {
	Name = "OnlinePill",

	Parent = Header,

	AnchorPoint = Vector2.new(1, 0),

	Position = UDim2.new(1, -72, 0, 62),

	Size = UDim2.fromOffset(90, 22),

	BackgroundColor3 = Color3.fromRGB(10, 25, 24),

	BorderSizePixel = 0,

	ZIndex = 1200,
})

Corner(OnlinePill, 8)

local OnlineStroke = Stroke(
	OnlinePill,
	Theme.Success,
	1,
	0.35
)

local OnlineDot = New("Frame", {
	Name = "Dot",

	Parent = OnlinePill,

	Position = UDim2.fromOffset(9, 8),

	Size = UDim2.fromOffset(6, 6),

	BackgroundColor3 = Theme.Success,

	BorderSizePixel = 0,

	ZIndex = 1202,
})

Corner(OnlineDot, 10)

local OnlineText = New("TextLabel", {
	Name = "Text",

	Parent = OnlinePill,

	Position = UDim2.fromOffset(21, 2),

	Size = UDim2.new(1, -25, 1, -4),

	BackgroundTransparency = 1,

	Text = "ONLINE",

	TextColor3 = Theme.Success,

	TextSize = 9,

	Font = Enum.Font.GothamBold,

	TextXAlignment = Enum.TextXAlignment.Left,

	ZIndex = 1202,
})

--// =========================================================
--// WINDOW BUTTONS
--// =========================================================

local function CreateWindowButton(text, position, color)
	local button = New("TextButton", {
		Parent = Header,

		AnchorPoint = Vector2.new(1, 0),

		Position = position,

		Size = UDim2.fromOffset(32, 32),

		BackgroundColor3 = Color3.fromRGB(12, 16, 25),

		AutoButtonColor = false,

		Text = text,

		TextColor3 = Theme.Muted,

		TextSize = 15,

		Font = Enum.Font.GothamBold,

		BorderSizePixel = 0,

		ZIndex = 1300,
	})

	Corner(button, 9)

	local stroke = Stroke(
		button,
		color,
		1,
		0.65
	)

	Connect(button.MouseEnter, function()
		Tween(button, 0.18, {
			BackgroundColor3 = color:Lerp(Color3.new(1,1,1), 0.1),
		})

		Tween(stroke, 0.18, {
			Transparency = 0.15,
		})

		Tween(button, 0.18, {
			TextColor3 = Color3.new(1,1,1),
		})
	end)

	Connect(button.MouseLeave, function()
		Tween(button, 0.18, {
			BackgroundColor3 = Color3.fromRGB(12, 16, 25),
			TextColor3 = Theme.Muted,
		})

		Tween(stroke, 0.18, {
			Transparency = 0.65,
		})
	end)

	return button
end

local MinimizeButton = CreateWindowButton(
	"—",
	UDim2.new(1, -116, 0, 16),
	AccentColor()
)

local CloseButton = CreateWindowButton(
	"×",
	UDim2.new(1, -76, 0, 16),
	Theme.Danger
)

--// =========================================================
--// HEADER SEPARATOR
--// =========================================================

local HeaderSeparator = New("Frame", {
	Name = "Separator",

	Parent = Header,

	Position = UDim2.new(0, 20, 1, -1),

	Size = UDim2.new(1, -40, 0, 1),

	BackgroundColor3 = AccentColor(),

	BackgroundTransparency = 0.45,

	BorderSizePixel = 0,

	ZIndex = 1200,
})

--// =========================================================
--// BODY
--// =========================================================

local Body = New("Frame", {
	Name = "Body",

	Parent = MainPanel,

	Position = UDim2.fromOffset(0, 92),

	Size = UDim2.new(1, 0, 1, -92),

	BackgroundTransparency = 1,

	ZIndex = 1050,
})

--// =========================================================
--// SIDEBAR
--// =========================================================

local Sidebar = New("Frame", {
	Name = "Sidebar",

	Parent = Body,

	Position = UDim2.fromOffset(14, 14),

	Size = UDim2.new(
		0,
		_G.vanz.Config.SidebarWidth,
		1,
		-28
	),

	BackgroundColor3 = Theme.Panel,

	BorderSizePixel = 0,

	ZIndex = 1100,
})

Corner(Sidebar, 15)

local SidebarStroke = Stroke(
	Sidebar,
	Color3.fromRGB(35, 55, 75),
	1,
	0.25
)

-- sidebar grid
local SidebarGrid = New("ImageLabel", {
	Name = "Grid",

	Parent = Sidebar,

	Size = UDim2.fromScale(1, 1),

	BackgroundTransparency = 1,

	Image = "rbxassetid://9968344105",

	ImageTransparency = 0.94,

	ImageColor3 = AccentColor(),

	ScaleType = Enum.ScaleType.Tile,

	TileSize = UDim2.fromOffset(32, 32),

	ZIndex = 1101,
})

-- sidebar title
local NavHeader = New("TextLabel", {
	Name = "Header",

	Parent = Sidebar,

	Position = UDim2.fromOffset(18, 17),

	Size = UDim2.new(1, -36, 0, 18),

	BackgroundTransparency = 1,

	Text = "NAVIGATION",

	TextColor3 = AccentColor(),

	TextSize = 10,

	Font = Enum.Font.GothamBold,

	TextXAlignment = Enum.TextXAlignment.Left,

	ZIndex = 1200,
})

local NavLine = New("Frame", {
	Name = "Line",

	Parent = Sidebar,

	Position = UDim2.fromOffset(18, 40),

	Size = UDim2.new(1, -36, 0, 1),

	BackgroundColor3 = AccentColor(),

	BackgroundTransparency = 0.75,

	BorderSizePixel = 0,

	ZIndex = 1200,
})

--// =========================================================
--// NAV BUTTON
--// =========================================================

local NavButtons = {}

local function CreateNavButton(name, icon, y)
	local button = New("TextButton", {
		Name = name,

		Parent = Sidebar,

		Position = UDim2.fromOffset(12, y),

		Size = UDim2.new(1, -24, 0, 50),

		BackgroundColor3 = Color3.fromRGB(11, 16, 25),

		BackgroundTransparency = 1,

		AutoButtonColor = false,

		Text = "",

		BorderSizePixel = 0,

		ZIndex = 1200,
	})

	Corner(button, 11)

	local active = New("Frame", {
		Name = "Active",

		Parent = button,

		Position = UDim2.fromOffset(0, 5),

		Size = UDim2.fromOffset(3, 40),

		BackgroundColor3 = AccentColor(),

		BackgroundTransparency = 0,

		BorderSizePixel = 0,

		ZIndex = 1203,
	})

	Corner(active, 3)

	local iconLabel = New("TextLabel", {
		Name = "Icon",

		Parent = button,

		Position = UDim2.fromOffset(14, 0),

		Size = UDim2.fromOffset(32, 50),

		BackgroundTransparency = 1,

		Text = icon,

		TextColor3 = AccentColor(),

		TextSize = 16,

		Font = Enum.Font.GothamBold,

		ZIndex = 1202,
	})

	local label = New("TextLabel", {
		Name = "Label",

		Parent = button,

		Position = UDim2.fromOffset(52, 0),

		Size = UDim2.new(1, -72, 1, 0),

		BackgroundTransparency = 1,

		Text = name,

		TextColor3 = Theme.Text,

		TextSize = 12,

		Font = Enum.Font.GothamBold,

		TextXAlignment = Enum.TextXAlignment.Left,

		ZIndex = 1202,
	})

	local arrow = New("TextLabel", {
		Name = "Arrow",

		Parent = button,

		AnchorPoint = Vector2.new(1, 0.5),

		Position = UDim2.new(1, -12, 0.5, 0),

		Size = UDim2.fromOffset(16, 20),

		BackgroundTransparency = 1,

		Text = "›",

		TextColor3 = Theme.Muted,

		TextSize = 17,

		Font = Enum.Font.GothamBold,

		ZIndex = 1202,
	})

	local buttonStroke = Stroke(
		button,
		AccentColor(),
		1,
		1
	)

	NavButtons[name] = {
		Button = button,
		Active = active,
		Icon = iconLabel,
		Label = label,
		Arrow = arrow,
		Stroke = buttonStroke,
	}

	Connect(button.MouseEnter, function()
		Tween(button, 0.2, {
			BackgroundTransparency = 0.82,
		})

		Tween(buttonStroke, 0.2, {
			Transparency = 0.55,
		})

		Tween(iconLabel, 0.2, {
			TextColor3 = Color3.new(1,1,1),
		})

		Tween(arrow, 0.2, {
			TextColor3 = AccentColor(),
			Position = UDim2.new(1, -9, 0.5, 0),
		})
	end)

	Connect(button.MouseLeave, function()
		Tween(button, 0.2, {
			BackgroundTransparency = 1,
		})

		Tween(buttonStroke, 0.2, {
			Transparency = 1,
		})

		Tween(iconLabel, 0.2, {
			TextColor3 = AccentColor(),
		})

		Tween(arrow, 0.2, {
			TextColor3 = Theme.Muted,
			Position = UDim2.new(1, -12, 0.5, 0),
		})
	end)

	return button
end

local HomeButton = CreateNavButton(
	"COMMAND CENTER",
	"◆",
	58
)

--// =========================================================
--// SIDEBAR SYSTEM STATUS
--// =========================================================

local SystemBox = New("Frame", {
	Name = "SystemBox",

	Parent = Sidebar,

	AnchorPoint = Vector2.new(0, 1),

	Position = UDim2.new(0, 12, 1, -12),

	Size = UDim2.new(1, -24, 0, 115),

	BackgroundColor3 = Color3.fromRGB(7, 11, 18),

	BorderSizePixel = 0,

	ZIndex = 1200,
})

Corner(SystemBox, 11)

local SystemStroke = Stroke(
	SystemBox,
	AccentColor(),
	1,
	0.65
)

local SystemTitle = New("TextLabel", {
	Parent = SystemBox,

	Position = UDim2.fromOffset(12, 10),

	Size = UDim2.new(1, -24, 0, 16),

	BackgroundTransparency = 1,

	Text = "SYSTEM STATUS",

	TextColor3 = Theme.Muted,

	TextSize = 8,

	Font = Enum.Font.GothamBold,

	TextXAlignment = Enum.TextXAlignment.Left,

	ZIndex = 1202,
})

local function StatusRow(parent, y, labelText)
	local dot = New("Frame", {
		Parent = parent,

		Position = UDim2.fromOffset(13, y + 4),

		Size = UDim2.fromOffset(5, 5),

		BackgroundColor3 = Theme.Success,

		BorderSizePixel = 0,

		ZIndex = 1203,
	})

	Corner(dot, 5)

	local label = New("TextLabel", {
		Parent = parent,

		Position = UDim2.fromOffset(25, y),

		Size = UDim2.new(1, -32, 0, 14),

		BackgroundTransparency = 1,

		Text = labelText,

		TextColor3 = Theme.Text,

		TextSize = 8,

		Font = Enum.Font.Code,

		TextXAlignment = Enum.TextXAlignment.Left,

		ZIndex = 1203,
	})

	return dot
end

local StatusCore = StatusRow(SystemBox, 33, "CORE.............. READY")
local StatusRender = StatusRow(SystemBox, 51, "RENDER............ ACTIVE")
local StatusLink = StatusRow(SystemBox, 69, "LINK.............. SECURE")
local StatusAnim = StatusRow(SystemBox, 87, "ANIMATION......... ONLINE")

--// =========================================================
--// CONTENT
--// =========================================================

local Content = New("Frame", {
	Name = "Content",

	Parent = Body,

	Position = UDim2.fromOffset(
		_G.vanz.Config.SidebarWidth + 28,
		14
	),

	Size = UDim2.new(
		1,
		-_G.vanz.Config.SidebarWidth - 42,
		1,
		-28
	),

	BackgroundTransparency = 1,

	ZIndex = 1100,
})

--// =========================================================
--// PAGE
--// =========================================================

local HomePage = New("ScrollingFrame", {
	Name = "HomePage",

	Parent = Content,

	Size = UDim2.fromScale(1, 1),

	BackgroundTransparency = 1,

	BorderSizePixel = 0,

	ScrollBarThickness = 2,

	ScrollBarImageColor3 = AccentColor(),

	CanvasSize = UDim2.new(0, 0, 0, 790),

	AutomaticCanvasSize = Enum.AutomaticSize.None,

	ScrollingDirection = Enum.ScrollingDirection.Y,

	ZIndex = 1101,
})

--// =========================================================
--// HERO
--// =========================================================

local Hero = New("Frame", {
	Name = "Hero",

	Parent = HomePage,

	Position = UDim2.fromOffset(0, 0),

	Size = UDim2.new(1, -6, 0, 178),

	BackgroundColor3 = Theme.Panel2,

	BorderSizePixel = 0,

	ClipsDescendants = true,

	ZIndex = 1150,
})

Corner(Hero, 16)

local HeroStroke = Stroke(
	Hero,
	AccentColor(),
	1,
	0.35
)

local HeroGradient = Gradient(
	Hero,
	Color3.fromRGB(12, 23, 34),
	Color3.fromRGB(10, 12, 22),
	25
)

-- decorative grid
local HeroGrid = New("ImageLabel", {
	Name = "Grid",

	Parent = Hero,

	Size = UDim2.fromScale(1, 1),

	BackgroundTransparency = 1,

	Image = "rbxassetid://9968344105",

	ImageTransparency = 0.91,

	ImageColor3 = AccentColor(),

	ScaleType = Enum.ScaleType.Tile,

	TileSize = UDim2.fromOffset(42, 42),

	ZIndex = 1151,
})

-- glow orb
local HeroGlow = New("Frame", {
	Name = "Glow",

	Parent = Hero,

	AnchorPoint = Vector2.new(1, 0.5),

	Position = UDim2.new(1, 50, 0.5, 0),

	Size = UDim2.fromOffset(240, 240),

	BackgroundColor3 = AccentColor(),

	BackgroundTransparency = 0.92,

	BorderSizePixel = 0,

	ZIndex = 1151,
})

Corner(HeroGlow, 200)

local HeroGlow2 = New("Frame", {
	Name = "Glow2",

	Parent = Hero,

	AnchorPoint = Vector2.new(1, 0.5),

	Position = UDim2.new(1, 10, 0.5, 0),

	Size = UDim2.fromOffset(120, 120),

	BackgroundColor3 = AccentColor2(),

	BackgroundTransparency = 0.88,

	BorderSizePixel = 0,

	ZIndex = 1152,
})

Corner(HeroGlow2, 200)

-- hero eyebrow
local HeroEyebrow = New("TextLabel", {
	Parent = Hero,

	Position = UDim2.fromOffset(24, 22),

	Size = UDim2.new(1, -48, 0, 18),

	BackgroundTransparency = 1,

	Text = "VANZ // NEURAL COMMAND INTERFACE",

	TextColor3 = AccentColor(),

	TextSize = 9,

	Font = Enum.Font.Code,

	TextXAlignment = Enum.TextXAlignment.Left,

	ZIndex = 1160,
})

local HeroTitle = New("TextLabel", {
	Parent = Hero,

	Position = UDim2.fromOffset(22, 46),

	Size = UDim2.new(1, -44, 0, 42),

	BackgroundTransparency = 1,

	Text = "CONTROL\nTHE EXPERIENCE.",

	TextColor3 = Theme.Text,

	TextSize = 25,

	Font = Enum.Font.GothamBlack,

	TextXAlignment = Enum.TextXAlignment.Left,

	TextYAlignment = Enum.TextYAlignment.Top,

	ZIndex = 1160,
})

local HeroDescription = New("TextLabel", {
	Parent = Hero,

	Position = UDim2.fromOffset(24, 125),

	Size = UDim2.new(1, -280, 0, 28),

	BackgroundTransparency = 1,

	Text = "Premium robotic interface • real-time visual telemetry • responsive control system",

	TextColor3 = Theme.Muted,

	TextSize = 9,

	Font = Enum.Font.GothamMedium,

	TextXAlignment = Enum.TextXAlignment.Left,

	ZIndex = 1160,
})

--// radar
local Radar = New("Frame", {
	Name = "Radar",

	Parent = Hero,

	AnchorPoint = Vector2.new(1, 0.5),

	Position = UDim2.new(1, -42, 0.5, 0),

	Size = UDim2.fromOffset(110, 110),

	BackgroundTransparency = 1,

	ZIndex = 1160,
})

local RadarOuter = New("Frame", {
	Parent = Radar,

	AnchorPoint = Vector2.new(0.5, 0.5),

	Position = UDim2.fromScale(0.5, 0.5),

	Size = UDim2.fromScale(1, 1),

	BackgroundTransparency = 1,

	ZIndex = 1161,
})

Corner(RadarOuter, 100)

local RadarStroke = Stroke(
	RadarOuter,
	AccentColor(),
	1,
	0.35
)

local RadarMid = New("Frame", {
	Parent = Radar,

	AnchorPoint = Vector2.new(0.5, 0.5),

	Position = UDim2.fromScale(0.5, 0.5),

	Size = UDim2.fromScale(0.70, 0.70),

	BackgroundTransparency = 1,

	ZIndex = 1161,
})

Corner(RadarMid, 100)

local RadarMidStroke = Stroke(
	RadarMid,
	AccentColor2(),
	1,
	0.55
)

local RadarCore = New("Frame", {
	Parent = Radar,

	AnchorPoint = Vector2.new(0.5, 0.5),

	Position = UDim2.fromScale(0.5, 0.5),

	Size = UDim2.fromOffset(8, 8),

	BackgroundColor3 = AccentColor(),

	BorderSizePixel = 0,

	ZIndex = 1164,
})

Corner(RadarCore, 20)

local RadarLine = New("Frame", {
	Name = "Sweep",

	Parent = Radar,

	AnchorPoint = Vector2.new(0.5, 1),

	Position = UDim2.fromScale(0.5, 0.5),

	Size = UDim2.fromOffset(1, 52),

	BackgroundColor3 = AccentColor(),

	BorderSizePixel = 0,

	ZIndex = 1163,
})

--// =========================================================
--// SECTION LABEL
--// =========================================================

local SectionLabel = New("TextLabel", {
	Parent = HomePage,

	Position = UDim2.fromOffset(2, 193),

	Size = UDim2.new(1, -10, 0, 20),

	BackgroundTransparency = 1,

	Text = "SYSTEM PARAMETERS",

	TextColor3 = Theme.Muted,

	TextSize = 9,

	Font = Enum.Font.GothamBold,

	TextXAlignment = Enum.TextXAlignment.Left,

	ZIndex = 1160,
})

--// =========================================================
--// SETTINGS PANEL
--// =========================================================

local SettingsPanel = New("Frame", {
	Name = "Settings",

	Parent = HomePage,

	Position = UDim2.fromOffset(0, 220),

	Size = UDim2.new(1, -6, 0, 355),

	BackgroundColor3 = Theme.Panel,

	BorderSizePixel = 0,

	ZIndex = 1150,
})

Corner(SettingsPanel, 15)

local SettingsStroke = Stroke(
	SettingsPanel,
	Color3.fromRGB(35, 48, 68),
	1,
	0.25
)

local SettingsTitle = New("TextLabel", {
	Parent = SettingsPanel,

	Position = UDim2.fromOffset(20, 17),

	Size = UDim2.new(1, -40, 0, 20),

	BackgroundTransparency = 1,

	Text = "DISPLAY & BEHAVIOR",

	TextColor3 = Theme.Text,

	TextSize = 12,

	Font = Enum.Font.GothamBold,

	TextXAlignment = Enum.TextXAlignment.Left,

	ZIndex = 1160,
})

local SettingsSubtitle = New("TextLabel", {
	Parent = SettingsPanel,

	Position = UDim2.fromOffset(20, 38),

	Size = UDim2.new(1, -40, 0, 18),

	BackgroundTransparency = 1,

	Text = "Tune the command center to your preferred operating profile.",

	TextColor3 = Theme.Muted,

	TextSize = 8,

	Font = Enum.Font.GothamMedium,

	TextXAlignment = Enum.TextXAlignment.Left,

	ZIndex = 1160,
})

--// =========================================================
--// DPI
--// =========================================================

local DPISection = New("Frame", {
	Parent = SettingsPanel,

	Position = UDim2.fromOffset(18, 72),

	Size = UDim2.new(1, -36, 0, 65),

	BackgroundColor3 = Color3.fromRGB(7, 11, 18),

	BorderSizePixel = 0,

	ZIndex = 1160,
})

Corner(DPISection, 11)

local DPIStroke = Stroke(
	DPISection,
	AccentColor(),
	1,
	0.72
)

local DPILabel = New("TextLabel", {
	Parent = DPISection,

	Position = UDim2.fromOffset(13, 8),

	Size = UDim2.fromOffset(90, 18),

	BackgroundTransparency = 1,

	Text = "INTERFACE SCALE",

	TextColor3 = Theme.Muted,

	TextSize = 8,

	Font = Enum.Font.GothamBold,

	TextXAlignment = Enum.TextXAlignment.Left,

	ZIndex = 1165,
})

local DPIValue = New("TextLabel", {
	Parent = DPISection,

	AnchorPoint = Vector2.new(1, 0),

	Position = UDim2.new(1, -13, 0, 8),

	Size = UDim2.fromOffset(70, 18),

	BackgroundTransparency = 1,

	Text = tostring(math.floor(State.Scale * 100)) .. "%",

	TextColor3 = AccentColor(),

	TextSize = 9,

	Font = Enum.Font.GothamBold,

	TextXAlignment = Enum.TextXAlignment.Right,

	ZIndex = 1165,
})

local DPIValues = {
	0.50,
	0.60,
	0.70,
	0.80,
	0.90,
	1.00,
}

local DPIButtons = {}

for index, scaleValue in ipairs(DPIValues) do
	local button = New("TextButton", {
		Parent = DPISection,

		Position = UDim2.fromOffset(
			11 + ((index - 1) * 50),
			33
		),

		Size = UDim2.fromOffset(43, 23),

		BackgroundColor3 = Color3.fromRGB(13, 18, 28),

		AutoButtonColor = false,

		Text = tostring(math.floor(scaleValue * 100)) .. "%",

		TextColor3 = Theme.Muted,

		TextSize = 8,

		Font = Enum.Font.GothamBold,

		BorderSizePixel = 0,

		ZIndex = 1170,
	})

	Corner(button, 7)

	local buttonStroke = Stroke(
		button,
		AccentColor(),
		1,
		0.8
	)

	DPIButtons[scaleValue] = {
		Button = button,
		Stroke = buttonStroke,
	}

	Connect(button.MouseEnter, function()
		Tween(button, 0.15, {
			BackgroundColor3 = Color3.fromRGB(18, 28, 40),
			TextColor3 = Color3.new(1,1,1),
		})

		Tween(buttonStroke, 0.15, {
			Transparency = 0.35,
		})
	end)

	Connect(button.MouseLeave, function()
		if math.abs(State.Scale - scaleValue) > 0.001 then
			Tween(button, 0.15, {
				BackgroundColor3 = Color3.fromRGB(13, 18, 28),
				TextColor3 = Theme.Muted,
			})

			Tween(buttonStroke, 0.15, {
				Transparency = 0.8,
			})
		end
	end)

	Connect(button.MouseButton1Click, function()
		State.Scale = scaleValue
		UIScale.Scale = scaleValue

		DPIValue.Text = tostring(math.floor(scaleValue * 100)) .. "%"

		if State.ClickFX then
			Tween(button, 0.08, {
				Size = UDim2.fromOffset(39, 21),
			})

			task.delay(0.08, function()
				if button and button.Parent then
					Tween(button, 0.12, {
						Size = UDim2.fromOffset(43, 23),
					})
				end
			end)
		end
	end)
end

local function UpdateDPI()
	for scaleValue, data in pairs(DPIButtons) do
		local selected = math.abs(State.Scale - scaleValue) < 0.001

		Tween(data.Button, 0.15, {
			BackgroundColor3 = selected
				and Color3.fromRGB(16, 38, 48)
				or Color3.fromRGB(13, 18, 28),

			TextColor3 = selected
				and Color3.new(1,1,1)
				or Theme.Muted,
		})

		Tween(data.Stroke, 0.15, {
			Color = AccentColor(),
			Transparency = selected and 0.2 or 0.8,
		})
	end

	DPIValue.Text = tostring(math.floor(State.Scale * 100)) .. "%"
end

UpdateDPI()

--// =========================================================
--// TOGGLE FACTORY
--// =========================================================

local ToggleObjects = {}

local function CreateToggle(title, description, y, defaultValue, callback)
	local row = New("Frame", {
		Parent = SettingsPanel,

		Position = UDim2.fromOffset(18, y),

		Size = UDim2.new(1, -36, 0, 62),

		BackgroundColor3 = Color3.fromRGB(7, 11, 18),

		BorderSizePixel = 0,

		ZIndex = 1160,
	})

	Corner(row, 11)

	local rowStroke = Stroke(
		row,
		Color3.fromRGB(35, 48, 68),
		1,
		0.55
	)

	local titleLabel = New("TextLabel", {
		Parent = row,

		Position = UDim2.fromOffset(14, 10),

		Size = UDim2.new(1, -100, 0, 17),

		BackgroundTransparency = 1,

		Text = title,

		TextColor3 = Theme.Text,

		TextSize = 9,

		Font = Enum.Font.GothamBold,

		TextXAlignment = Enum.TextXAlignment.Left,

		ZIndex = 1170,
	})

	local descLabel = New("TextLabel", {
		Parent = row,

		Position = UDim2.fromOffset(14, 29),

		Size = UDim2.new(1, -110, 0, 20),

		BackgroundTransparency = 1,

		Text = description,

		TextColor3 = Theme.Muted,

		TextSize = 7,

		Font = Enum.Font.GothamMedium,

		TextXAlignment = Enum.TextXAlignment.Left,

		ZIndex = 1170,
	})

	local toggle = New("TextButton", {
		Parent = row,

		AnchorPoint = Vector2.new(1, 0.5),

		Position = UDim2.new(1, -14, 0.5, 0),

		Size = UDim2.fromOffset(48, 25),

		BackgroundColor3 = Color3.fromRGB(22, 27, 36),

		AutoButtonColor = false,

		Text = "",

		BorderSizePixel = 0,

		ZIndex = 1175,
	})

	Corner(toggle, 14)

	local toggleStroke = Stroke(
		toggle,
		AccentColor(),
		1,
		0.5
	)

	local knob = New("Frame", {
		Parent = toggle,

		AnchorPoint = Vector2.new(0, 0.5),

		Position = UDim2.new(
			defaultValue and 1 or 0,
			defaultValue and -22 or 3,
			0.5,
			0
		),

		Size = UDim2.fromOffset(19, 19),

		BackgroundColor3 = defaultValue
			and AccentColor()
			or Color3.fromRGB(100, 110, 125),

		BorderSizePixel = 0,

		ZIndex = 1176,
	})

	Corner(knob, 20)

	local glow = New("Frame", {
		Parent = toggle,

		AnchorPoint = Vector2.new(0.5, 0.5),

		Position = UDim2.fromScale(0.5, 0.5),

		Size = UDim2.fromScale(1, 1),

		BackgroundColor3 = AccentColor(),

		BackgroundTransparency = defaultValue and 0.92 or 1,

		BorderSizePixel = 0,

		ZIndex = 1174,
	})

	Corner(glow, 15)

	local value = defaultValue

	local function SetValue(newValue, instant)
		value = newValue

		local knobPosition

		if value then
			knobPosition = UDim2.new(1, -22, 0.5, 0)
		else
			knobPosition = UDim2.new(0, 3, 0.5, 0)
		end

		local duration = instant and 0 or 0.22

		Tween(knob, duration, {
			Position = knobPosition,
			BackgroundColor3 = value
				and AccentColor()
				or Color3.fromRGB(100, 110, 125),
		})

		Tween(toggle, duration, {
			BackgroundColor3 = value
				and Color3.fromRGB(12, 38, 46)
				or Color3.fromRGB(22, 27, 36),
		})

		Tween(glow, duration, {
			BackgroundTransparency = value and 0.90 or 1,
		})

		Tween(toggleStroke, duration, {
			Color = AccentColor(),
			Transparency = value and 0.20 or 0.65,
		})

		if callback then
			callback(value)
		end
	end

	ToggleObjects[title] = {
		Set = SetValue,
		Get = function()
			return value
		end,
	}

	Connect(toggle.MouseEnter, function()
		Tween(toggle, 0.15, {
			Size = UDim2.fromOffset(51, 27),
		})
	end)

	Connect(toggle.MouseLeave, function()
		Tween(toggle, 0.15, {
			Size = UDim2.fromOffset(48, 25),
		})
	end)

	Connect(toggle.MouseButton1Click, function()
		SetValue(not value)

		if State.ClickFX then
			Tween(row, 0.08, {
				BackgroundColor3 = Color3.fromRGB(15, 23, 34),
			})

			task.delay(0.08, function()
				if row and row.Parent then
					Tween(row, 0.15, {
						BackgroundColor3 = Color3.fromRGB(7, 11, 18),
					})
				end
			end)
		end
	end)

	SetValue(defaultValue, true)

	return row
end

CreateToggle(
	"SMART ANIMATIONS",
	"Enable the dynamic motion engine and live interface feedback.",
	145,
	true,
	function(value)
		State.Animations = value
	end
)

CreateToggle(
	"NEON AMBIENCE",
	"Enable aura, glow layers and futuristic edge lighting.",
	215,
	true,
	function(value)
		State.Glow = value
	end
)

CreateToggle(
	"INTERACTION FX",
	"Enable click compression, hover feedback and tactile effects.",
	285,
	true,
	function(value)
		State.ClickFX = value
	end
)

--// =========================================================
--// SCANLINES
--// =========================================================

local Scanlines = {}

for i = 1, 10 do
	local line = New("Frame", {
		Parent = MainPanel,

		Position = UDim2.new(
			0,
			0,
			0,
			i * 62
		),

		Size = UDim2.new(1, 0, 0, 1),

		BackgroundColor3 = AccentColor(),

		BackgroundTransparency = 0.96,

		BorderSizePixel = 0,

		ZIndex = 1800,
	})

	table.insert(Scanlines, line)
end

--// =========================================================
--// FLOATING RESTORE BUTTON
--// =========================================================

local FloatingButton = New("TextButton", {
	Name = "FloatingRestore",

	Parent = ScreenGui,

	AnchorPoint = Vector2.new(1, 1),

	Position = UDim2.new(1, -24, 1, -24),

	Size = UDim2.fromOffset(58, 58),

	BackgroundColor3 = Color3.fromRGB(8, 15, 24),

	AutoButtonColor = false,

	Text = "V",

	TextColor3 = Color3.new(1,1,1),

	TextSize = 20,

	Font = Enum.Font.GothamBlack,

	BorderSizePixel = 0,

	Visible = false,

	ZIndex = 3000,
})

Corner(FloatingButton, 18)

local FloatingStroke = Stroke(
	FloatingButton,
	AccentColor(),
	1.5,
	0.15
)

local FloatingGradient = Gradient(
	FloatingButton,
	AccentColor(),
	AccentColor2(),
	135
)

local FloatingRing = New("Frame", {
	Parent = FloatingButton,

	AnchorPoint = Vector2.new(0.5, 0.5),

	Position = UDim2.fromScale(0.5, 0.5),

	Size = UDim2.new(1, -10, 1, -10),

	BackgroundTransparency = 1,

	ZIndex = 3001,
})

Corner(FloatingRing, 16)

local FloatingRingStroke = Stroke(
	FloatingRing,
	AccentColor(),
	1,
	0.55
)

Connect(FloatingButton.MouseEnter, function()
	Tween(FloatingButton, 0.2, {
		Size = UDim2.fromOffset(64, 64),
	})

	Tween(FloatingStroke, 0.2, {
		Transparency = 0,
	})

	Tween(FloatingButton, 0.2, {
		TextColor3 = Color3.new(1,1,1),
	})
end)

Connect(FloatingButton.MouseLeave, function()
	Tween(FloatingButton, 0.2, {
		Size = UDim2.fromOffset(58, 58),
	})

	Tween(FloatingStroke, 0.2, {
		Transparency = 0.15,
	})
end)

--// =========================================================
--// DRAG SYSTEM
--// =========================================================

local function MakeDraggable(handle, target)
	local dragging = false
	local dragStart
	local startPosition

	Connect(handle.InputBegan, function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then

			dragging = true

			dragStart = input.Position
			startPosition = target.Position

			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragging = false
				end
			end)
		end
	end)

	Connect(UserInputService.InputChanged, function(input)
		if not dragging then
			return
		end

		if input.UserInputType == Enum.UserInputType.MouseMovement
			or input.UserInputType == Enum.UserInputType.Touch then

			local delta = input.Position - dragStart

			target.Position = UDim2.new(
				startPosition.X.Scale,
				startPosition.X.Offset + delta.X,
				startPosition.Y.Scale,
				startPosition.Y.Offset + delta.Y
			)
		end
	end)
end

MakeDraggable(Header, MainHolder)
MakeDraggable(FloatingButton, FloatingButton)

--// =========================================================
--// MINIMIZE / RESTORE
--// =========================================================

local function ShowMain()
	if State.Destroyed then
		return
	end

	State.Minimized = false

	FloatingButton.Visible = false

	MainHolder.Visible = true

	MainHolder.Size = UDim2.fromOffset(
		_G.vanz.Config.Width - 30,
		_G.vanz.Config.Height - 30
	)

	Tween(MainHolder, 0.42, {
		Size = UDim2.fromOffset(
			_G.vanz.Config.Width,
			_G.vanz.Config.Height
		),
	})

	Tween(MainPanel, 0.35, {
		BackgroundTransparency = 0,
	})
end

local function HideMain()
	if State.Destroyed then
		return
	end

	State.Minimized = true

	Tween(MainHolder, 0.32, {
		Size = UDim2.fromOffset(
			_G.vanz.Config.Width - 40,
			_G.vanz.Config.Height - 40
		),
	})

	task.delay(0.28, function()
		if State.Destroyed or not State.Minimized then
			return
		end

		MainHolder.Visible = false

		FloatingButton.Visible = true

		FloatingButton.Size = UDim2.fromOffset(30, 30)

		Tween(FloatingButton, 0.35, {
			Size = UDim2.fromOffset(58, 58),
		})
	end)
end

Connect(MinimizeButton.MouseButton1Click, HideMain)

Connect(FloatingButton.MouseButton1Click, ShowMain)

--// =========================================================
--// FORCE STOP
--// =========================================================

local function ForceStop()
	if State.Destroyed then
		return
	end

	State.Destroyed = true

	for _, connection in ipairs(_G.vanz.Connections) do
		pcall(function()
			connection:Disconnect()
		end)
	end

	for _, cleanup in ipairs(_G.vanz.Cleanups) do
		pcall(cleanup)
	end

	table.clear(_G.vanz.Connections)
	table.clear(_G.vanz.Cleanups)

	if ScreenGui then
		pcall(function()
			ScreenGui:Destroy()
		end)
	end

	_G.vanz.Open = nil
	_G.vanz.Hide = nil
	_G.vanz.SetScale = nil
	_G.vanz.GetState = nil
	_G.vanz.ForceStop = nil
end

Connect(CloseButton.MouseButton1Click, ForceStop)

--// =========================================================
--// PUBLIC API
--// =========================================================

_G.vanz.Open = function()
	if State.Destroyed then
		return
	end

	ShowMain()
end

_G.vanz.Hide = function()
	if State.Destroyed then
		return
	end

	HideMain()
end

_G.vanz.SetScale = function(scale)
	if State.Destroyed then
		return
	end

	scale = math.clamp(
		tonumber(scale) or 0.70,
		0.50,
		1.00
	)

	State.Scale = scale

	UIScale.Scale = scale

	UpdateDPI()
end

_G.vanz.GetState = function()
	return {
		Destroyed = State.Destroyed,

		Minimized = State.Minimized,

		Animations = State.Animations,

		Glow = State.Glow,

		ClickFX = State.ClickFX,

		Scale = State.Scale,

		Uptime = os.clock() - State.OpenedAt,
	}
end

_G.vanz.ForceStop = ForceStop

--// =========================================================
--// RESPONSIVE
--// =========================================================

local function UpdateResponsive()
	if State.Destroyed then
		return
	end

	local camera = workspace.CurrentCamera

	if not camera then
		return
	end

	local viewport = camera.ViewportSize

	local availableWidth = viewport.X - 30
	local availableHeight = viewport.Y - 30

	local width = math.min(
		_G.vanz.Config.Width,
		math.max(520, availableWidth / math.max(State.Scale, 0.5))
	)

	local height = math.min(
		_G.vanz.Config.Height,
		math.max(420, availableHeight / math.max(State.Scale, 0.5))
	)

	MainHolder.Size = UDim2.fromOffset(
		width,
		height
	)
end

if workspace.CurrentCamera then
	Connect(
		workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"),
		UpdateResponsive
	)
end

UpdateResponsive()

--// =========================================================
--// TOPMOST WATCHDOG
--// =========================================================

Connect(RunService.RenderStepped, function()
	if State.Destroyed then
		return
	end

	-- Reassert PlayerGui priority.
	if ScreenGui.Parent ~= PlayerGui then
		pcall(function()
			ScreenGui.Parent = PlayerGui
		end)
	end

	ScreenGui.DisplayOrder = _G.vanz.Config.DisplayOrder
	ScreenGui.Enabled = true

	-- Keep the window visually above our own layers.
	MainHolder.ZIndex = 1000
	MainPanel.ZIndex = 1000

	if State.Minimized then
		FloatingButton.ZIndex = 3000
	end
end)

--// =========================================================
--// MAIN ANIMATION ENGINE
--// =========================================================

local AnimationTime = 0

Connect(RunService.RenderStepped, function(deltaTime)
	if State.Destroyed then
		return
	end

	AnimationTime += deltaTime * _G.vanz.Config.AnimationSpeed

	if State.Animations then

		-- Dynamic hue
		State.Hue = (State.Hue + deltaTime * 0.025) % 1

		local primary = AccentColor()
		local secondary = AccentColor2()

		-- Main strokes
		MainStroke.Color = primary
		AuraStroke.Color = primary
		LogoRingStroke.Color = primary
		LogoRing2Stroke.Color = secondary
		LogoCoreStroke.Color = primary
		TopLaser.BackgroundColor3 = primary
		TopLaserGlow.BackgroundColor3 = primary
		Subtitle.TextColor3 = primary
		OnlineStroke.Color = Theme.Success
		HeaderSeparator.BackgroundColor3 = primary

		-- gradients
		AuraGradient.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, primary),
			ColorSequenceKeypoint.new(1, secondary),
		})

		LogoGradient.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, primary),
			ColorSequenceKeypoint.new(1, secondary),
		})

		HeroGradient.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, primary:Lerp(Color3.fromRGB(8,15,25), 0.82)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(8,11,19)),
		})

		-- logo breathing
		local breathe = 1 + math.sin(AnimationTime * 2.3) * 0.055

		LogoCore.Size = UDim2.fromOffset(
			34 * breathe,
			34 * breathe
		)

		LogoRing.Rotation += deltaTime * 16
		LogoRing2.Rotation -= deltaTime * 23

		-- logo ring pulse
		local ringPulse = 0.20 + math.sin(AnimationTime * 2) * 0.12

		LogoRingStroke.Transparency = ringPulse

		-- aura pulse
		if State.Glow then
			local pulse = 0.5 + math.sin(AnimationTime * 1.8) * 0.2

			AuraStroke.Transparency = 0.35 + pulse * 0.35

			HeroGlow.BackgroundTransparency =
				0.94 - math.sin(AnimationTime * 1.4) * 0.025

			HeroGlow2.BackgroundTransparency =
				0.90 - math.sin(AnimationTime * 1.8) * 0.035
		else
			AuraStroke.Transparency = 1
			HeroGlow.BackgroundTransparency = 1
			HeroGlow2.BackgroundTransparency = 1
		end

		-- radar
		Radar.Rotation += deltaTime * 22
		RadarLine.Rotation = math.sin(AnimationTime * 0.8) * 20

		-- online pulse
		local onlinePulse =
			0.55 + math.sin(AnimationTime * 3.5) * 0.35

		OnlineDot.BackgroundTransparency =
			math.clamp(1 - onlinePulse, 0, 0.5)

		-- top laser movement
		local laserX =
			(AnimationTime * 80) % 700

		TopLaser.Position = UDim2.new(
			0,
			24 + laserX,
			0,
			0
		)

		-- scanlines
		for index, line in ipairs(Scanlines) do
			local wave =
				(math.sin(AnimationTime * 1.3 + index) + 1) / 2

			line.BackgroundTransparency =
				0.985 - wave * 0.02
		end

		-- floating button
		if FloatingButton.Visible then
			local scalePulse =
				1 + math.sin(AnimationTime * 2) * 0.035

			FloatingButton.Size = UDim2.fromOffset(
				58 * scalePulse,
				58 * scalePulse
			)

			FloatingStroke.Color = primary
			FloatingRingStroke.Color = secondary
		end

		-- status animation
		if State.Animations then
			StatusCore.BackgroundColor3 = primary
			StatusRender.BackgroundColor3 = secondary
			StatusLink.BackgroundColor3 = Theme.Success
			StatusAnim.BackgroundColor3 = primary
		end

	else
		-- Static mode
		MainStroke.Color = Theme.Primary
		AuraStroke.Transparency = 1

		LogoRing.Rotation = 0
		LogoRing2.Rotation = 0
	end
end)

--// =========================================================
--// HOVER HERO
--// =========================================================

Connect(Hero.MouseEnter, function()
	if not State.ClickFX then
		return
	end

	Tween(HeroStroke, 0.25, {
		Transparency = 0.05,
		Thickness = 1.5,
	})

	Tween(HeroGlow, 0.3, {
		BackgroundTransparency = 0.89,
	})
end)

Connect(Hero.MouseLeave, function()
	Tween(HeroStroke, 0.25, {
		Transparency = 0.35,
		Thickness = 1,
	})

	if State.Glow then
		Tween(HeroGlow, 0.3, {
			BackgroundTransparency = 0.93,
		})
	end
end)

--// =========================================================
--// STARTUP ANIMATION
--// =========================================================

MainHolder.Visible = true

MainHolder.Size = UDim2.fromOffset(
	_G.vanz.Config.Width - 90,
	_G.vanz.Config.Height - 90
)

MainPanel.BackgroundTransparency = 1

Header.Position = UDim2.fromOffset(0, -12)

Body.Position = UDim2.fromOffset(0, 104)

AuraStroke.Transparency = 1

Tween(
	MainHolder,
	0.55,
	{
		Size = UDim2.fromOffset(
			_G.vanz.Config.Width,
			_G.vanz.Config.Height
		),
	}
)

Tween(
	MainPanel,
	0.55,
	{
		BackgroundTransparency = 0,
	}
)

Tween(
	Header,
	0.55,
	{
		Position = UDim2.fromOffset(0, 0),
	}
)

Tween(
	Body,
	0.55,
	{
		Position = UDim2.fromOffset(0, 92),
	}
)

Tween(
	AuraStroke,
	0.75,
	{
		Transparency = 0.35,
	}
)

--// =========================================================
--// INITIAL TELEMETRY
--// =========================================================

task.spawn(function()
	local messages = {
		"SYS // VANZ-CORE",
		"SYS // NEURAL LINK",
		"SYS // RENDER NODE",
		"SYS // CONTROL HUB",
	}

	local index = 1

	while not State.Destroyed do
		Telemetry.Text = messages[index]

		index += 1

		if index > #messages then
			index = 1
		end

		task.wait(2.5)
	end
end)

--// =========================================================
--// FINAL STATE
--// =========================================================

print("[VANZ] Robotic Command Center initialized.")
print("[VANZ] DisplayOrder:", ScreenGui.DisplayOrder)
print("[VANZ] Scale:", State.Scale)
print("[VANZ] Animation Engine: ONLINE")
print("[VANZ] Neural Interface: READY")