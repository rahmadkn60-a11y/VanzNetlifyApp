--[[
================================================================================
 VANZ // ROBOTIC ANIME CONTROL CENTER
 BRIGHT GLASS EDITION
================================================================================

[01] SERVICES
[02] CONFIGURATION
[03] COLOR SYSTEM
[04] UTILITY FUNCTIONS
[05] CLEAN OLD GUI
[06] SCREEN GUI
[07] MAIN WINDOW
[08] HEADER
[09] HEADER CONTROLS
[10] HOME DASHBOARD
[11] USER IDENTITY
[12] LIVE STATUS GRID
[13] SETTINGS PAGE
[14] PLAYER SETTINGS
[15] SAFE WINDOW DRAG
[16] MINIMIZED LOGO
[17] MINIMIZED LOGO DRAG
[18] MINIMIZE / RESTORE
[19] BUTTON EFFECTS
[20] RESPONSIVE MOBILE
[21] DECORATIVE ANIMATION
[22] LIVE TELEMETRY
[23] AVATAR
[24] PUBLIC API
[25] INITIALIZATION

================================================================================
]]

--==============================================================================
-- [01] SERVICES
--==============================================================================

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Stats = game:GetService("Stats")

local LocalPlayer = Players.LocalPlayer

if not LocalPlayer then
	return
end


--==============================================================================
-- [02] CONFIGURATION
--==============================================================================

local Config = {
	Name = "VANZ_BRIGHT_ROBOTIC_GUI",

	DisplayOrder = 999999999,

	DesktopWidth = 1000,
	DesktopHeight = 650,

	MobileMargin = 7,

	HeaderHeightDesktop = 78,
	HeaderHeightMobile = 70,

	MinimizedSize = 70,

	Scale = 1,

	ThemeName = "CYAN",

	Animations = true,
	Particles = true,
	Scanline = true,
	InteractionFX = true,

	WindowTransparency = 0,

	OpenedAt = os.clock(),
}


local State = {
	Destroyed = false,

	Minimized = false,

	SettingsOpen = false,

	Character = nil,
	Humanoid = nil,
	RootPart = nil,

	FPS = 60,
	Ping = 0,
	Memory = 0,

	Elapsed = 0,
}


--==============================================================================
-- [03] COLOR SYSTEM
--==============================================================================

-- Semua warna sengaja dibuat lebih terang.
-- Tujuannya supaya GUI tetap jelas di layar HP dengan brightness rendah.

local Themes = {

	CYAN = {
		Accent = Color3.fromRGB(55, 225, 255),
		Accent2 = Color3.fromRGB(35, 150, 255),
		AccentSoft = Color3.fromRGB(130, 245, 255),
	},

	VIOLET = {
		Accent = Color3.fromRGB(190, 125, 255),
		Accent2 = Color3.fromRGB(125, 80, 255),
		AccentSoft = Color3.fromRGB(225, 180, 255),
	},

	MAGENTA = {
		Accent = Color3.fromRGB(255, 105, 205),
		Accent2 = Color3.fromRGB(210, 65, 255),
		AccentSoft = Color3.fromRGB(255, 175, 230),
	},

	BLUE = {
		Accent = Color3.fromRGB(80, 165, 255),
		Accent2 = Color3.fromRGB(40, 100, 240),
		AccentSoft = Color3.fromRGB(150, 210, 255),
	},

	GREEN = {
		Accent = Color3.fromRGB(75, 255, 185),
		Accent2 = Color3.fromRGB(25, 180, 125),
		AccentSoft = Color3.fromRGB(155, 255, 215),
	},

}


local Theme =
	Themes[Config.ThemeName]
	or Themes.CYAN


local Colors = {

	-- Main background tidak lagi hitam pekat.
	Background = Color3.fromRGB(11, 20, 34),

	-- Header sedikit lebih terang.
	Header = Color3.fromRGB(20, 37, 58),

	-- Panel body.
	Panel = Color3.fromRGB(17, 31, 50),

	-- Panel kedua.
	Panel2 = Color3.fromRGB(23, 42, 65),

	-- Card status.
	Card = Color3.fromRGB(27, 49, 75),

	-- Card saat hover.
	CardHover = Color3.fromRGB(34, 61, 91),

	-- Border normal.
	Border = Color3.fromRGB(64, 96, 128),

	-- Border terang.
	BorderBright = Color3.fromRGB(88, 130, 165),

	-- Text.
	Text = Color3.fromRGB(245, 250, 255),

	-- Secondary text.
	SubText = Color3.fromRGB(181, 204, 225),

	-- Muted.
	Muted = Color3.fromRGB(120, 151, 178),

	-- Success.
	Success = Color3.fromRGB(80, 255, 175),

	-- Warning.
	Warning = Color3.fromRGB(255, 205, 90),

	-- Danger.
	Danger = Color3.fromRGB(255, 90, 105),

}


local function Accent()
	return Theme.Accent
end


local function Accent2()
	return Theme.Accent2
end


local function AccentSoft()
	return Theme.AccentSoft
end


--==============================================================================
-- [04] UTILITY FUNCTIONS
--==============================================================================

local Connections = {}


local function Connect(signal, callback)

	if not signal then
		return nil
	end

	local success, connection = pcall(function()
		return signal:Connect(callback)
	end)

	if success and connection then
		table.insert(Connections, connection)
		return connection
	end

	return nil
end


local function Create(className, properties, parent)

	local object = Instance.new(className)

	if properties then

		for property, value in pairs(properties) do

			pcall(function()
				object[property] = value
			end)

		end

	end

	if parent then
		object.Parent = parent
	end

	return object
end


local function Corner(object, radius)

	return Create(
		"UICorner",
		{
			CornerRadius = UDim.new(0, radius),
		},
		object
	)

end


local function Stroke(object, color, thickness, transparency)

	return Create(
		"UIStroke",
		{
			Color = color,
			Thickness = thickness or 1,
			Transparency = transparency or 0,
		},
		object
	)

end


local function Padding(object, left, top, right, bottom)

	return Create(
		"UIPadding",
		{
			PaddingLeft = UDim.new(0, left or 0),
			PaddingTop = UDim.new(0, top or 0),
			PaddingRight = UDim.new(0, right or 0),
			PaddingBottom = UDim.new(0, bottom or 0),
		},
		object
	)

end


local function Tween(object, duration, properties)

	if not object then
		return
	end

	local success, tween = pcall(function()

		return TweenService:Create(
			object,
			TweenInfo.new(
				duration,
				Enum.EasingStyle.Quint,
				Enum.EasingDirection.Out
			),
			properties
		)

	end)

	if success and tween then
		tween:Play()
	end

end


local function DisconnectAll()

	for _, connection in ipairs(Connections) do

		pcall(function()
			connection:Disconnect()
		end)

	end

	table.clear(Connections)

end


--==============================================================================
-- [05] CLEAN OLD GUI
--==============================================================================

local PlayerGui =
	LocalPlayer:WaitForChild("PlayerGui")


local Old =
	PlayerGui:FindFirstChild(Config.Name)


if Old then

	pcall(function()
		Old:Destroy()
	end)

end


--==============================================================================
-- [06] SCREEN GUI
--==============================================================================

local ScreenGui = Create(
	"ScreenGui",
	{
		Name = Config.Name,

		IgnoreGuiInset = true,

		ResetOnSpawn = false,

		DisplayOrder = Config.DisplayOrder,

		ZIndexBehavior = Enum.ZIndexBehavior.Global,

		Enabled = true,
	},
	PlayerGui
)


-- UIScale hanya dipakai untuk setting scale.
-- Tidak dipakai untuk perhitungan drag.
local UIScale = Create(
	"UIScale",
	{
		Scale = Config.Scale,
	},
	ScreenGui
)


--==============================================================================
-- [07] MAIN WINDOW
--==============================================================================

local Main = Create(
	"Frame",
	{
		Name = "Main",

		AnchorPoint = Vector2.new(0.5, 0.5),

		Position = UDim2.fromScale(
			0.5,
			0.5
		),

		Size = UDim2.fromOffset(
			Config.DesktopWidth,
			Config.DesktopHeight
		),

		BackgroundColor3 =
			Colors.Background,

		BackgroundTransparency = 0,

		BorderSizePixel = 0,

		ClipsDescendants = true,

		ZIndex = 10,
	},
	ScreenGui
)

Corner(Main, 20)


local MainStroke =
	Stroke(
		Main,
		Accent(),
		1.5,
		0.12
	)


-- Inner highlight.
local MainHighlight = Create(
	"Frame",
	{
		Name = "MainHighlight",

		Position = UDim2.fromOffset(
			1,
			1
		),

		Size = UDim2.new(
			1,
			-2,
			1,
			-2
		),

		BackgroundTransparency = 1,

		BorderSizePixel = 0,

		ZIndex = 11,
	},
	Main
)

Corner(MainHighlight, 19)

Stroke(
	MainHighlight,
	Color3.fromRGB(110, 150, 185),
	1,
	0.72
)


--==============================================================================
-- [08] HEADER
--==============================================================================

local Header = Create(
	"Frame",
	{
		Name = "Header",

		Size = UDim2.new(
			1,
			0,
			0,
			Config.HeaderHeightDesktop
		),

		BackgroundColor3 =
			Colors.Header,

		BorderSizePixel = 0,

		ZIndex = 20,
	},
	Main
)

Corner(Header, 19)


-- Header bottom separator.
local HeaderSeparator = Create(
	"Frame",
	{
		Position = UDim2.new(
			0,
			0,
			1,
			-1
		),

		Size = UDim2.new(
			1,
			0,
			0,
			1
		),

		BackgroundColor3 =
			Accent(),

		BackgroundTransparency = 0.55,

		BorderSizePixel = 0,

		ZIndex = 24,
	},
	Header
)


--==============================================================================
-- HEADER LOGO
--==============================================================================

local HeaderLogo = Create(
	"Frame",
	{
		Position = UDim2.fromOffset(
			12,
			10
		),

		Size = UDim2.fromOffset(
			58,
			58
		),

		BackgroundColor3 =
			Colors.Panel2,

		BorderSizePixel = 0,

		Active = true,

		ZIndex = 30,
	},
	Header
)

Corner(HeaderLogo, 15)

local HeaderLogoStroke =
	Stroke(
		HeaderLogo,
		Accent(),
		1.5,
		0.15
	)


local LogoInner = Create(
	"Frame",
	{
		AnchorPoint = Vector2.new(
			0.5,
			0.5
		),

		Position = UDim2.fromScale(
			0.5,
			0.5
		),

		Size = UDim2.fromOffset(
			43,
			43
		),

		BackgroundTransparency = 1,

		ZIndex = 31,
	},
	HeaderLogo
)

Corner(LogoInner, 100)


local LogoRingStroke =
	Stroke(
		LogoInner,
		Accent(),
		2,
		0.05
	)


local LogoV = Create(
	"TextLabel",
	{
		AnchorPoint = Vector2.new(
			0.5,
			0.5
		),

		Position = UDim2.fromScale(
			0.5,
			0.5
		),

		Size = UDim2.fromOffset(
			42,
			42
		),

		BackgroundTransparency = 1,

		Font = Enum.Font.GothamBlack,

		Text = "V",

		TextColor3 =
			AccentSoft(),

		TextSize = 28,

		ZIndex = 32,
	},
	HeaderLogo
)


--==============================================================================
-- HEADER TITLE
--==============================================================================

local Title = Create(
	"TextLabel",
	{
		Position = UDim2.fromOffset(
			82,
			10
		),

		Size = UDim2.new(
			1,
			-375,
			0,
			31
		),

		BackgroundTransparency = 1,

		Font = Enum.Font.GothamBlack,

		Text = "VANZ CONTROL CENTER",

		TextColor3 =
			Colors.Text,

		TextSize = 21,

		TextXAlignment =
			Enum.TextXAlignment.Left,

		TextTruncate =
			Enum.TextTruncate.AtEnd,

		ZIndex = 30,
	},
	Header
)


local Subtitle = Create(
	"TextLabel",
	{
		Position = UDim2.fromOffset(
			83,
			42
		),

		Size = UDim2.new(
			1,
			-375,
			0,
			20
		),

		BackgroundTransparency = 1,

		Font = Enum.Font.GothamBold,

		Text =
			"ROBOTIC • ANIME • LIVE USER SYSTEM",

		TextColor3 =
			AccentSoft(),

		TextSize = 10,

		TextXAlignment =
			Enum.TextXAlignment.Left,

		TextTruncate =
			Enum.TextTruncate.AtEnd,

		ZIndex = 30,
	},
	Header
)


-- Online indicator.
local Online = Create(
	"TextLabel",
	{
		Position = UDim2.fromOffset(
			83,
			59
		),

		Size = UDim2.new(
			1,
			-375,
			0,
			15
		),

		BackgroundTransparency = 1,

		Font = Enum.Font.GothamBold,

		Text = "● SYSTEM ONLINE",

		TextColor3 =
			Colors.Success,

		TextSize = 9,

		TextXAlignment =
			Enum.TextXAlignment.Left,

		ZIndex = 30,
	},
	Header
)


--==============================================================================
-- [09] HEADER CONTROLS
--==============================================================================

local Controls = Create(
	"Frame",
	{
		Name = "Controls",

		AnchorPoint = Vector2.new(
			1,
			0.5
		),

		Position = UDim2.new(
			1,
			-9,
			0.5,
			0
		),

		Size = UDim2.fromOffset(
			204,
			56
		),

		BackgroundTransparency = 1,

		ZIndex = 80,
	},
	Header
)


local ControlsLayout = Create(
	"UIListLayout",
	{
		FillDirection =
			Enum.FillDirection.Horizontal,

		HorizontalAlignment =
			Enum.HorizontalAlignment.Right,

		VerticalAlignment =
			Enum.VerticalAlignment.Center,

		Padding = UDim.new(
			0,
			6
		),
	},
	Controls
)


local function CreateHeaderButton(
	text,
	color
)

	local button = Create(
		"TextButton",
		{
			Size = UDim2.fromOffset(
				54,
				50
			),

			BackgroundColor3 =
				Colors.Panel2,

			BorderSizePixel = 0,

			AutoButtonColor = false,

			Font = Enum.Font.GothamBlack,

			Text = text,

			TextColor3 =
				color or Colors.Text,

			TextSize = 24,

			ZIndex = 85,
		},
		Controls
	)

	Corner(button, 13)

	Stroke(
		button,
		Colors.BorderBright,
		1,
		0.2
	)

	return button
end


local SettingsButton =
	CreateHeaderButton(
		"⚙",
		AccentSoft()
	)


local MinimizeButton =
	CreateHeaderButton(
		"—",
		Colors.Text
	)


local CloseButton =
	CreateHeaderButton(
		"×",
		Colors.Danger
	)


--==============================================================================
-- HEADER DRAG AREA
--==============================================================================

local DragArea = Create(
	"Frame",
	{
		Name = "DragArea",

		Position = UDim2.fromOffset(
			74,
			0
		),

		Size = UDim2.new(
			1,
			-292,
			1,
			0
		),

		BackgroundTransparency = 1,

		Active = true,

		ZIndex = 25,
	},
	Header
)


--==============================================================================
-- [10] HOME DASHBOARD
--==============================================================================

local Body = Create(
	"Frame",
	{
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

		BackgroundColor3 =
			Colors.Background,

		BorderSizePixel = 0,

		ZIndex = 15,
	},
	Main
)


local Home = Create(
	"ScrollingFrame",
	{
		Name = "Home",

		Size = UDim2.fromScale(
			1,
			1
		),

		BackgroundTransparency = 1,

		BorderSizePixel = 0,

		CanvasSize =
			UDim2.fromOffset(
				0,
				0
			),

		AutomaticCanvasSize =
			Enum.AutomaticSize.Y,

		ScrollingDirection =
			Enum.ScrollingDirection.Y,

		ScrollBarThickness = 6,

		ScrollBarImageColor3 =
			Accent(),

		ScrollBarImageTransparency =
			0.12,

		Active = true,

		Visible = true,

		ZIndex = 16,
	},
	Body
)

Padding(
	Home,
	15,
	15,
	15,
	22
)


local HomeLayout = Create(
	"UIListLayout",
	{
		FillDirection =
			Enum.FillDirection.Vertical,

		HorizontalAlignment =
			Enum.HorizontalAlignment.Center,

		Padding = UDim.new(
			0,
			12
		),
	},
	Home
)


--==============================================================================
-- [11] USER IDENTITY
--==============================================================================

local Identity = Create(
	"Frame",
	{
		Size = UDim2.new(
			1,
			0,
			0,
			122
		),

		BackgroundColor3 =
			Colors.Panel2,

		BorderSizePixel = 0,

		LayoutOrder = 1,

		ZIndex = 18,
	},
	Home
)

Corner(Identity, 17)

Stroke(
	Identity,
	Accent(),
	1.5,
	0.16
)


-- Avatar background.
local AvatarBack = Create(
	"Frame",
	{
		Position = UDim2.fromOffset(
			13,
			13
		),

		Size = UDim2.fromOffset(
			96,
			96
		),

		BackgroundColor3 =
			Colors.Card,

		BorderSizePixel = 0,

		ZIndex = 19,
	},
	Identity
)

Corner(AvatarBack, 15)

Stroke(
	AvatarBack,
	Accent2(),
	1,
	0.15
)


local Avatar = Create(
	"ImageLabel",
	{
		Position = UDim2.fromOffset(
			4,
			4
		),

		Size = UDim2.fromOffset(
			88,
			88
		),

		BackgroundColor3 =
			Colors.Panel,

		BorderSizePixel = 0,

		Image = "",

		ZIndex = 20,
	},
	AvatarBack
)

Corner(Avatar, 12)


local DisplayName = Create(
	"TextLabel",
	{
		Position = UDim2.fromOffset(
			124,
			16
		),

		Size = UDim2.new(
			1,
			-145,
			0,
			31
		),

		BackgroundTransparency = 1,

		Font = Enum.Font.GothamBlack,

		Text = LocalPlayer.DisplayName,

		TextColor3 =
			Colors.Text,

		TextSize = 23,

		TextXAlignment =
			Enum.TextXAlignment.Left,

		TextTruncate =
			Enum.TextTruncate.AtEnd,

		ZIndex = 20,
	},
	Identity
)


local Username = Create(
	"TextLabel",
	{
		Position = UDim2.fromOffset(
			125,
			49
		),

		Size = UDim2.new(
			1,
			-146,
			0,
			20
		),

		BackgroundTransparency = 1,

		Font = Enum.Font.GothamBold,

		Text =
			"@" .. LocalPlayer.Name,

		TextColor3 =
			AccentSoft(),

		TextSize = 13,

		TextXAlignment =
			Enum.TextXAlignment.Left,

		TextTruncate =
			Enum.TextTruncate.AtEnd,

		ZIndex = 20,
	},
	Identity
)


local UserStatus = Create(
	"TextLabel",
	{
		Position = UDim2.fromOffset(
			125,
			75
		),

		Size = UDim2.new(
			1,
			-146,
			0,
			25
		),

		BackgroundTransparency = 1,

		Font = Enum.Font.GothamBold,

		Text =
			"● USER LINK ONLINE",

		TextColor3 =
			Colors.Success,

		TextSize = 10,

		TextXAlignment =
			Enum.TextXAlignment.Left,

		ZIndex = 20,
	},
	Identity
)


--==============================================================================
-- [12] LIVE STATUS GRID
--==============================================================================

local StatusContainer = Create(
	"Frame",
	{
		Name = "StatusContainer",

		Size = UDim2.new(
			1,
			0,
			0,
			720
		),

		BackgroundTransparency = 1,

		LayoutOrder = 2,

		ZIndex = 17,
	},
	Home
)


local StatusGrid = Create(
	"UIGridLayout",
	{
		CellPadding =
			UDim2.fromOffset(
				9,
				9
			),

		CellSize =
			UDim2.new(
				0.5,
				-5,
				0,
				72
			),

		SortOrder =
			Enum.SortOrder.LayoutOrder,
	},
	StatusContainer
)


local StatusLabels = {}


local function CreateStatusCard(
	label,
	value
)

	local card = Create(
		"Frame",
		{
			BackgroundColor3 =
				Colors.Card,

			BorderSizePixel = 0,

			ZIndex = 18,
		},
		StatusContainer
	)

	Corner(card, 13)

	Stroke(
		card,
		Colors.BorderBright,
		1,
		0.28
	)


	local accentBar = Create(
		"Frame",
		{
			Position =
				UDim2.fromOffset(
					0,
					10
				),

			Size =
				UDim2.fromOffset(
					4,
					52
				),

			BackgroundColor3 =
				Accent(),

			BorderSizePixel = 0,

			ZIndex = 20,
		},
		card
	)

	Corner(accentBar, 4)


	Create(
		"TextLabel",
		{
			Position =
				UDim2.fromOffset(
					15,
					9
				),

			Size =
				UDim2.new(
					1,
					-25,
					0,
					17
				),

			BackgroundTransparency = 1,

			Font = Enum.Font.GothamBold,

			Text = label,

			TextColor3 =
				Colors.SubText,

			TextSize = 9,

			TextXAlignment =
				Enum.TextXAlignment.Left,

			ZIndex = 20,
		},
		card
	)


	local valueLabel = Create(
		"TextLabel",
		{
			Position =
				UDim2.fromOffset(
					15,
					29
				),

			Size =
				UDim2.new(
					1,
					-25,
					0,
					29
				),

			BackgroundTransparency = 1,

			Font = Enum.Font.GothamBlack,

			Text = tostring(value),

			TextColor3 =
				Colors.Text,

			TextSize = 15,

			TextXAlignment =
				Enum.TextXAlignment.Left,

			TextTruncate =
				Enum.TextTruncate.AtEnd,

			ZIndex = 20,
		},
		card
	)


	StatusLabels[label] =
		valueLabel


	return card
end


CreateStatusCard(
	"WALK SPEED",
	"16"
)

CreateStatusCard(
	"JUMP POWER",
	"50"
)

CreateStatusCard(
	"HEALTH",
	"100 / 100"
)

CreateStatusCard(
	"MAX HEALTH",
	"100"
)

CreateStatusCard(
	"RIG TYPE",
	"Unknown"
)

CreateStatusCard(
	"CHARACTER STATE",
	"Loading"
)

CreateStatusCard(
	"HIP HEIGHT",
	"2.00"
)

CreateStatusCard(
	"AUTO ROTATE",
	"ON"
)

CreateStatusCard(
	"PLATFORM STAND",
	"OFF"
)

CreateStatusCard(
	"MOVE VECTOR",
	"0, 0, 0"
)

CreateStatusCard(
	"POSITION",
	"0, 0, 0"
)

CreateStatusCard(
	"TEAM",
	"None"
)

CreateStatusCard(
	"ACCOUNT AGE",
	"0 DAYS"
)

CreateStatusCard(
	"USER ID",
	tostring(LocalPlayer.UserId)
)

CreateStatusCard(
	"FPS",
	"60"
)

CreateStatusCard(
	"PING",
	"0 ms"
)

CreateStatusCard(
	"MEMORY",
	"0 MB"
)

CreateStatusCard(
	"SESSION",
	"00:00"
)

CreateStatusCard(
	"DEVICE",
	"UNKNOWN"
)

CreateStatusCard(
	"CHARACTER",
	"Loading"
)

CreateStatusCard(
	"SIT",
	"NO"
)

CreateStatusCard(
	"JUMPING",
	"NO"
)


--==============================================================================
-- [13] SETTINGS PAGE
--==============================================================================

local SettingsPage = Create(
	"ScrollingFrame",
	{
		Name = "SettingsPage",

		Size = UDim2.fromScale(
			1,
			1
		),

		BackgroundTransparency = 1,

		BorderSizePixel = 0,

		CanvasSize =
			UDim2.fromOffset(
				0,
				0
			),

		AutomaticCanvasSize =
			Enum.AutomaticSize.Y,

		ScrollingDirection =
			Enum.ScrollingDirection.Y,

		ScrollBarThickness = 6,

		ScrollBarImageColor3 =
			Accent(),

		ScrollBarImageTransparency =
			0.12,

		Visible = false,

		ZIndex = 35,
	},
	Body
)

Padding(
	SettingsPage,
	15,
	15,
	15,
	22
)


local SettingsLayout = Create(
	"UIListLayout",
	{
		FillDirection =
			Enum.FillDirection.Vertical,

		HorizontalAlignment =
			Enum.HorizontalAlignment.Center,

		Padding = UDim.new(
			0,
			12
		),
	},
	SettingsPage
)


--==============================================================================
-- SETTINGS HEADER
--==============================================================================

local SettingsHeader = Create(
	"Frame",
	{
		Size = UDim2.new(
			1,
			0,
			0,
			98
		),

		BackgroundColor3 =
			Colors.Panel2,

		BorderSizePixel = 0,

		LayoutOrder = 1,

		ZIndex = 36,
	},
	SettingsPage
)

Corner(SettingsHeader, 16)

Stroke(
	SettingsHeader,
	Accent(),
	1.5,
	0.18
)


Create(
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
				-36,
				0,
				31
			),

		BackgroundTransparency = 1,

		Font = Enum.Font.GothamBlack,

		Text = "⚙  SYSTEM SETTINGS",

		TextColor3 =
			Colors.Text,

		TextSize = 21,

		TextXAlignment =
			Enum.TextXAlignment.Left,

		ZIndex = 37,
	},
	SettingsHeader
)


Create(
	"TextLabel",
	{
		Position =
			UDim2.fromOffset(
				19,
				51
			),

		Size =
			UDim2.new(
				1,
				-38,
				0,
				23
			),

		BackgroundTransparency = 1,

		Font = Enum.Font.GothamMedium,

		Text =
			"CONTROL EVERY VISUAL AND PLAYER OPTION FROM ONE PLACE",

		TextColor3 =
			AccentSoft(),

		TextSize = 10,

		TextXAlignment =
			Enum.TextXAlignment.Left,

		TextTruncate =
			Enum.TextTruncate.AtEnd,

		ZIndex = 37,
	},
	SettingsHeader
)


--==============================================================================
-- SETTINGS HELPER
--==============================================================================

local SettingsOrder = 2


local function CreateSettingsSection(
	title,
	description,
	height
)

	local section = Create(
		"Frame",
		{
			Size = UDim2.new(
				1,
				0,
				0,
				height
			),

			BackgroundColor3 =
				Colors.Card,

			BorderSizePixel = 0,

			LayoutOrder =
				SettingsOrder,

			ZIndex = 36,
		},
		SettingsPage
	)

	SettingsOrder += 1

	Corner(section, 15)

	Stroke(
		section,
		Colors.BorderBright,
		1,
		0.28
	)


	Create(
		"TextLabel",
		{
			Position =
				UDim2.fromOffset(
					16,
					10
				),

			Size =
				UDim2.new(
					1,
					-32,
					0,
					24
				),

			BackgroundTransparency = 1,

			Font = Enum.Font.GothamBlack,

			Text = title,

			TextColor3 =
				Colors.Text,

			TextSize = 16,

			TextXAlignment =
				Enum.TextXAlignment.Left,

			ZIndex = 38,
		},
		section
	)


	Create(
		"TextLabel",
		{
			Position =
				UDim2.fromOffset(
					17,
					34
				),

			Size =
				UDim2.new(
					1,
					-34,
					0,
					18
				),

			BackgroundTransparency = 1,

			Font = Enum.Font.GothamMedium,

			Text = description,

			TextColor3 =
				Colors.SubText,

			TextSize = 9,

			TextXAlignment =
				Enum.TextXAlignment.Left,

			TextTruncate =
				Enum.TextTruncate.AtEnd,

			ZIndex = 38,
		},
		section
	)


	return section
end


local function CreateSettingsButton(
	parent,
	text,
	y
)

	local button = Create(
		"TextButton",
		{
			Position =
				UDim2.fromOffset(
					15,
					y
				),

			Size =
				UDim2.new(
					1,
					-30,
					0,
					41
				),

			BackgroundColor3 =
				Colors.Panel2,

			BorderSizePixel = 0,

			AutoButtonColor = false,

			Font = Enum.Font.GothamBold,

			Text = text,

			TextColor3 =
				Colors.Text,

			TextSize = 11,

			TextXAlignment =
				Enum.TextXAlignment.Left,

			ZIndex = 40,
		},
		parent
	)

	Corner(button, 10)

	Stroke(
		button,
		Colors.BorderBright,
		1,
		0.3
	)

	Padding(
		button,
		15,
		0,
		15,
		0
	)

	return button
end


--==============================================================================
-- APPEARANCE SETTINGS
--==============================================================================

local Appearance =
	CreateSettingsSection(
		"APPEARANCE",
		"Theme, scale and window visibility",
		230
	)


local ThemeButton =
	CreateSettingsButton(
		Appearance,
		"THEME : CYAN",
		66
	)


local ScaleButton =
	CreateSettingsButton(
		Appearance,
		"GUI SCALE : 100%",
		112
	)


local TransparencyButton =
	CreateSettingsButton(
		Appearance,
		"WINDOW STYLE : SOLID",
		158
	)


--==============================================================================
-- ANIMATION SETTINGS
--==============================================================================

local AnimationSection =
	CreateSettingsSection(
		"ANIMATION CORE",
		"Robotic motion and visual effects",
		230
	)


local AnimationButton =
	CreateSettingsButton(
		AnimationSection,
		"ANIMATIONS : ON",
		66
	)


local ParticleButton =
	CreateSettingsButton(
		AnimationSection,
		"PARTICLES : ON",
		112
	)


local ScanlineButton =
	CreateSettingsButton(
		AnimationSection,
		"SCANLINE : ON",
		158
	)


--==============================================================================
-- PLAYER SETTINGS
--==============================================================================

local PlayerSection =
	CreateSettingsSection(
		"PLAYER CONTROL",
		"Live movement values are reflected on Home",
		276
	)


local SpeedButton =
	CreateSettingsButton(
		PlayerSection,
		"WALK SPEED : 16",
		66
	)


local JumpButton =
	CreateSettingsButton(
		PlayerSection,
		"JUMP POWER : 50",
		112
	)


local ResetPlayerButton =
	CreateSettingsButton(
		PlayerSection,
		"RESET PLAYER VALUES",
		158
	)


local ResetWindowButton =
	CreateSettingsButton(
		PlayerSection,
		"RESET WINDOW POSITION",
		204
	)


--==============================================================================
-- [14] PLAYER SETTINGS
--==============================================================================

local CurrentSpeed = 16
local CurrentJump = 50


local function RefreshCharacter()

	State.Character =
		LocalPlayer.Character


	if State.Character then

		State.Humanoid =
			State.Character:FindFirstChildOfClass(
				"Humanoid"
			)

		State.RootPart =
			State.Character:FindFirstChild(
				"HumanoidRootPart"
			)

	else

		State.Humanoid = nil
		State.RootPart = nil

	end

end


RefreshCharacter()


Connect(
	LocalPlayer.CharacterAdded,
	function(character)

		State.Character =
			character

		State.Humanoid =
			character:WaitForChild(
				"Humanoid",
				10
			)

		State.RootPart =
			character:WaitForChild(
				"HumanoidRootPart",
				10
			)

	end
)


local function ApplySpeed(value)

	CurrentSpeed =
		math.clamp(
			value,
			1,
			100
		)


	RefreshCharacter()


	if State.Humanoid then

		pcall(function()

			State.Humanoid.WalkSpeed =
				CurrentSpeed

		end)

	end


	SpeedButton.Text =
		"WALK SPEED : "
		.. tostring(CurrentSpeed)

end


local function ApplyJump(value)

	CurrentJump =
		math.clamp(
			value,
			1,
			150
		)


	RefreshCharacter()


	if State.Humanoid then

		pcall(function()

			State.Humanoid.UseJumpPower =
				true

			State.Humanoid.JumpPower =
				CurrentJump

		end)

	end


	JumpButton.Text =
		"JUMP POWER : "
		.. tostring(CurrentJump)

end


Connect(
	SpeedButton.MouseButton1Click,
	function()

		local nextSpeed =
			CurrentSpeed + 4

		if nextSpeed > 40 then
			nextSpeed = 16
		end

		ApplySpeed(nextSpeed)

	end
)


Connect(
	JumpButton.MouseButton1Click,
	function()

		local nextJump =
			CurrentJump + 10

		if nextJump > 100 then
			nextJump = 50
		end

		ApplyJump(nextJump)

	end
)


Connect(
	ResetPlayerButton.MouseButton1Click,
	function()

		ApplySpeed(16)
		ApplyJump(50)

	end
)


--==============================================================================
-- [15] SAFE WINDOW DRAG
--==============================================================================

local WindowDrag = {
	Active = false,

	StartPointer = nil,

	StartCenter = nil,
}


local function GetViewport()

	local camera =
		workspace.CurrentCamera

	if camera then
		return camera.ViewportSize
	end

	return Vector2.new(
		ScreenGui.AbsoluteSize.X,
		ScreenGui.AbsoluteSize.Y
	)
end


local function GetMainCenter()

	local viewport =
		GetViewport()


	local position =
		Main.Position


	local x =
		position.X.Scale
		* viewport.X
		+ position.X.Offset


	local y =
		position.Y.Scale
		* viewport.Y
		+ position.Y.Offset


	return Vector2.new(
		x,
		y
	)
end


local function ClampMainCenter(center)

	local viewport =
		GetViewport()


	local halfWidth =
		Main.AbsoluteSize.X / 2


	local halfHeight =
		Main.AbsoluteSize.Y / 2


	local x =
		math.clamp(
			center.X,
			halfWidth + 4,
			viewport.X - halfWidth - 4
		)


	local y =
		math.clamp(
			center.Y,
			halfHeight + 4,
			viewport.Y - halfHeight - 4
		)


	return Vector2.new(
		x,
		y
	)
end


local function BeginWindowDrag(input)

	if State.Minimized then
		return
	end


	if WindowDrag.Active then
		return
	end


	WindowDrag.Active = true


	WindowDrag.StartPointer =
		Vector2.new(
			input.Position.X,
			input.Position.Y
		)


	WindowDrag.StartCenter =
		GetMainCenter()

end


Connect(
	DragArea.InputBegan,
	function(input)

		if
			input.UserInputType
			== Enum.UserInputType.MouseButton1
			or
			input.UserInputType
			== Enum.UserInputType.Touch
		then

			BeginWindowDrag(input)

		end

	end
)


-- Logo header juga bisa digunakan untuk drag.
Connect(
	HeaderLogo.InputBegan,
	function(input)

		if
			input.UserInputType
			== Enum.UserInputType.MouseButton1
			or
			input.UserInputType
			== Enum.UserInputType.Touch
		then

			BeginWindowDrag(input)

		end

	end
)


Connect(
	UserInputService.InputChanged,
	function(input)

		if not WindowDrag.Active then
			return
		end


		if
			input.UserInputType
			== Enum.UserInputType.MouseMovement
			or
			input.UserInputType
			== Enum.UserInputType.Touch
		then

			local pointer =
				Vector2.new(
					input.Position.X,
					input.Position.Y
				)


			local delta =
				pointer
				- WindowDrag.StartPointer


			local center =
				WindowDrag.StartCenter
				+ delta


			center =
				ClampMainCenter(
					center
				)


			Main.AnchorPoint =
				Vector2.new(
					0.5,
					0.5
				)


			Main.Position =
				UDim2.fromOffset(
					center.X,
					center.Y
				)

		end

	end
)


Connect(
	UserInputService.InputEnded,
	function(input)

		if
			input.UserInputType
			== Enum.UserInputType.MouseButton1
			or
			input.UserInputType
			== Enum.UserInputType.Touch
		then

			WindowDrag.Active =
				false

			WindowDrag.StartPointer =
				nil

			WindowDrag.StartCenter =
				nil

		end

	end
)


Connect(
	ResetWindowButton.MouseButton1Click,
	function()

		Main.AnchorPoint =
			Vector2.new(
				0.5,
				0.5
			)

		Main.Position =
			UDim2.fromScale(
				0.5,
				0.5
			)

	end
)


--==============================================================================
-- [16] MINIMIZED LOGO
--==============================================================================

local MiniLogo = Create(
	"Frame",
	{
		Name = "MiniLogo",

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
				Config.MinimizedSize,
				Config.MinimizedSize
			),

		BackgroundColor3 =
			Colors.Panel2,

		BorderSizePixel = 0,

		Visible = false,

		Active = true,

		ZIndex = 500,
	},
	ScreenGui
)

Corner(
	MiniLogo,
	18
)


local MiniStroke =
	Stroke(
		MiniLogo,
		Accent(),
		1.5,
		0.08
	)


local MiniRing = Create(
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
				48,
				48
			),

		BackgroundTransparency = 1,

		ZIndex = 501,
	},
	MiniLogo
)

Corner(
	MiniRing,
	100
)


local MiniRingStroke =
	Stroke(
		MiniRing,
		AccentSoft(),
		2,
		0.04
	)


local MiniV = Create(
	"TextLabel",
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
				42,
				42
			),

		BackgroundTransparency = 1,

		Font =
			Enum.Font.GothamBlack,

		Text = "V",

		TextColor3 =
			AccentSoft(),

		TextSize = 29,

		ZIndex = 503,
	},
	MiniLogo
)


--==============================================================================
-- [17] MINIMIZED LOGO DRAG
--==============================================================================

local MiniDrag = {
	Active = false,

	Moved = false,

	StartPointer = nil,

	StartCenter = nil,
}


local function GetMiniCenter()

	local viewport =
		GetViewport()


	local position =
		MiniLogo.Position


	local x =
		position.X.Scale
		* viewport.X
		+ position.X.Offset


	local y =
		position.Y.Scale
		* viewport.Y
		+ position.Y.Offset


	return Vector2.new(
		x,
		y
	)
end


local function ClampMiniCenter(center)

	local viewport =
		GetViewport()


	local half =
		MiniLogo.AbsoluteSize.X / 2


	return Vector2.new(

		math.clamp(
			center.X,
			half + 4,
			viewport.X - half - 4
		),

		math.clamp(
			center.Y,
			half + 4,
			viewport.Y - half - 4
		)

	)
end


Connect(
	MiniLogo.InputBegan,
	function(input)

		if
			input.UserInputType
			== Enum.UserInputType.MouseButton1
			or
			input.UserInputType
			== Enum.UserInputType.Touch
		then

			MiniDrag.Active = true

			MiniDrag.Moved = false

			MiniDrag.StartPointer =
				Vector2.new(
					input.Position.X,
					input.Position.Y
				)


			MiniDrag.StartCenter =
				GetMiniCenter()

		end

	end
)


Connect(
	UserInputService.InputChanged,
	function(input)

		if not MiniDrag.Active then
			return
		end


		if
			input.UserInputType
			== Enum.UserInputType.MouseMovement
			or
			input.UserInputType
			== Enum.UserInputType.Touch
		then

			local pointer =
				Vector2.new(
					input.Position.X,
					input.Position.Y
				)


			local delta =
				pointer
				- MiniDrag.StartPointer


			if delta.Magnitude > 7 then
				MiniDrag.Moved = true
			end


			local center =
				MiniDrag.StartCenter
				+ delta


			center =
				ClampMiniCenter(
					center
				)


			MiniLogo.AnchorPoint =
				Vector2.new(
					0.5,
					0.5
				)


			MiniLogo.Position =
				UDim2.fromOffset(
					center.X,
					center.Y
				)

		end

	end
)


--==============================================================================
-- [18] MINIMIZE / RESTORE
--==============================================================================

local function Minimize()

	State.Minimized = true

	State.SettingsOpen = false

	Home.Visible = true

	SettingsPage.Visible = false

	Main.Visible = false

	MiniLogo.Visible = true

	MiniLogo.AnchorPoint =
		Vector2.new(
			0.5,
			0.5
		)

	-- Initial position selalu center.
	MiniLogo.Position =
		UDim2.fromScale(
			0.5,
			0.5
		)

end


local function Restore()

	State.Minimized = false

	MiniLogo.Visible = false

	Main.Visible = true

end


Connect(
	MinimizeButton.MouseButton1Click,
	function()
		Minimize()
	end
)


--==============================================================================
-- SETTINGS TOGGLE
--==============================================================================

Connect(
	SettingsButton.MouseButton1Click,
	function()

		State.SettingsOpen =
			not State.SettingsOpen


		Home.Visible =
			not State.SettingsOpen


		SettingsPage.Visible =
			State.SettingsOpen

	end
)


--==============================================================================
-- CLOSE
--==============================================================================

local function Close()

	if State.Destroyed then
		return
	end


	State.Destroyed = true


	DisconnectAll()


	pcall(function()
		ScreenGui:Destroy()
	end)


	_G.vanz = nil

end


Connect(
	CloseButton.MouseButton1Click,
	Close
)


--==============================================================================
-- [19] BUTTON EFFECTS
--==============================================================================

local function ButtonFX(button)

	if not button then
		return
	end


	local normal =
		button.BackgroundColor3


	Connect(
		button.MouseEnter,
		function()

			if not Config.InteractionFX then
				return
			end


			Tween(
				button,
				0.12,
				{
					BackgroundColor3 =
						Colors.CardHover,
				}
			)

		end
	)


	Connect(
		button.MouseLeave,
		function()

			if not Config.InteractionFX then
				return
			end


			Tween(
				button,
				0.16,
				{
					BackgroundColor3 =
						normal,
				}
			)

		end
	)

end


ButtonFX(SettingsButton)
ButtonFX(MinimizeButton)
ButtonFX(CloseButton)

ButtonFX(ThemeButton)
ButtonFX(ScaleButton)
ButtonFX(TransparencyButton)

ButtonFX(AnimationButton)
ButtonFX(ParticleButton)
ButtonFX(ScanlineButton)

ButtonFX(SpeedButton)
ButtonFX(JumpButton)
ButtonFX(ResetPlayerButton)
ButtonFX(ResetWindowButton)


--==============================================================================
-- [20] RESPONSIVE MOBILE
--==============================================================================

local function UpdateResponsive()

	local camera =
		workspace.CurrentCamera

	if not camera then
		return
	end


	local viewport =
		camera.ViewportSize


	local isMobile =
		viewport.X <= 720


	if isMobile then

		local width =
			math.max(
				290,
				viewport.X
				- Config.MobileMargin * 2
			)


		local height =
			math.max(
				300,
				viewport.Y
				- Config.MobileMargin * 2
			)


		Main.Size =
			UDim2.fromOffset(
				width,
				height
			)


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


		Title.Position =
			UDim2.fromOffset(
				76,
				9
			)


		Title.Size =
			UDim2.new(
				1,
				-263,
				0,
				27
			)


		Title.Text =
			"VANZ CONTROL"


		Title.TextSize = 17


		Subtitle.Visible = false

		Online.Visible = false


		Controls.Size =
			UDim2.fromOffset(
				166,
				52
			)


		for _, object in ipairs(
			Controls:GetChildren()
		) do

			if object:IsA(
				"TextButton"
			) then

				object.Size =
					UDim2.fromOffset(
						48,
						48
					)

			end

		end


		DragArea.Position =
			UDim2.fromOffset(
				72,
				0
			)


		DragArea.Size =
			UDim2.new(
				1,
				-244,
				1,
				0
			)


		StatusGrid.CellSize =
			UDim2.new(
				1,
				0,
				0,
				72
			)


	else

		Main.Size =
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


		Title.Position =
			UDim2.fromOffset(
				82,
				10
			)


		Title.Size =
			UDim2.new(
				1,
				-375,
				0,
				31
			)


		Title.Text =
			"VANZ CONTROL CENTER"


		Title.TextSize = 21


		Subtitle.Visible = true

		Online.Visible = true


		Controls.Size =
			UDim2.fromOffset(
				204,
				56
			)


		for _, object in ipairs(
			Controls:GetChildren()
		) do

			if object:IsA(
				"TextButton"
			) then

				object.Size =
					UDim2.fromOffset(
						54,
						50
					)

			end

		end


		DragArea.Position =
			UDim2.fromOffset(
				74,
				0
			)


		DragArea.Size =
			UDim2.new(
				1,
				-292,
				1,
				0
			)


		StatusGrid.CellSize =
			UDim2.new(
				0.5,
				-5,
				0,
				72
			)

	end

end


UpdateResponsive()


local camera =
	workspace.CurrentCamera


if camera then

	Connect(
		camera:GetPropertyChangedSignal(
			"ViewportSize"
		),
		UpdateResponsive
	)

end


--==============================================================================
-- [21] DECORATIVE ANIMATION
--==============================================================================

local ParticleContainer = Create(
	"Frame",
	{
		Name = "ParticleContainer",

		Size = UDim2.fromScale(
			1,
			1
		),

		BackgroundTransparency = 1,

		ClipsDescendants = true,

		ZIndex = 12,
	},
	Main
)


local Particles = {}


for index = 1, 16 do

	local particle = Create(
		"Frame",
		{
			Size =
				UDim2.fromOffset(
					math.random(2, 4),
					math.random(2, 4)
				),

			Position =
				UDim2.fromScale(
					math.random(),
					math.random()
				),

			BackgroundColor3 =
				Accent(),

			BackgroundTransparency =
				math.random(35, 70) / 100,

			BorderSizePixel = 0,

			ZIndex = 13,
		},
		ParticleContainer
	)

	Corner(
		particle,
		20
	)

	table.insert(
		Particles,
		particle
	)

end


-- Scanline tipis.
local Scanline = Create(
	"Frame",
	{
		Size =
			UDim2.new(
				1,
				0,
				0,
				2
			),

		Position =
			UDim2.fromOffset(
				0,
				0
			),

		BackgroundColor3 =
			Accent(),

		BackgroundTransparency =
			0.82,

		BorderSizePixel = 0,

		ZIndex = 300,
	},
	Main
)


--==============================================================================
-- [22] LIVE TELEMETRY
--==============================================================================

local function SetStatus(
	name,
	value
)

	local label =
		StatusLabels[name]

	if label then
		label.Text =
			tostring(value)
	end

end


local function VectorString(vector)

	if not vector then
		return "0, 0, 0"
	end


	return string.format(
		"%.1f, %.1f, %.1f",
		vector.X,
		vector.Y,
		vector.Z
	)

end


local function FormatSession(seconds)

	seconds =
		math.floor(seconds)


	local minutes =
		math.floor(
			seconds / 60
		)


	local secondsOnly =
		seconds % 60


	if minutes >= 60 then

		local hours =
			math.floor(
				minutes / 60
			)

		minutes =
			minutes % 60


		return string.format(
			"%02d:%02d:%02d",
			hours,
			minutes,
			secondsOnly
		)

	end


	return string.format(
		"%02d:%02d",
		minutes,
		secondsOnly
	)

end


local function DeviceName()

	if
		UserInputService.TouchEnabled
		and
		not UserInputService.KeyboardEnabled
	then

		return "MOBILE"

	end


	if
		UserInputService.GamepadEnabled
		and
		not UserInputService.KeyboardEnabled
	then

		return "GAMEPAD"

	end


	if UserInputService.KeyboardEnabled then
		return "PC"
	end


	return "UNKNOWN"
end


local function GetPing()

	local success, result =
		pcall(function()

			local network =
				Stats:FindFirstChild(
					"Network"
				)

			if not network then
				return 0
			end


			local serverStats =
				network:FindFirstChild(
					"ServerStatsItem"
				)

			if not serverStats then
				return 0
			end


			local dataPing =
				serverStats:FindFirstChild(
					"Data Ping"
				)

			if not dataPing then
				return 0
			end


			return tonumber(
				dataPing:GetValue()
			) or 0

		end)


	if success then
		return math.floor(result)
	end


	return 0
end


local function GetMemory()

	local success, result =
		pcall(function()

			return Stats:GetTotalMemoryUsageMb()

		end)


	if success then
		return math.floor(result)
	end


	return 0
end


local function UpdateLiveStatus()

	RefreshCharacter()


	local humanoid =
		State.Humanoid


	local root =
		State.RootPart


	if humanoid then

		SetStatus(
			"WALK SPEED",
			string.format(
				"%.1f",
				humanoid.WalkSpeed
			)
		)


		SetStatus(
			"JUMP POWER",
			string.format(
				"%.1f",
				humanoid.JumpPower
			)
		)


		SetStatus(
			"HEALTH",
			string.format(
				"%.0f / %.0f",
				humanoid.Health,
				humanoid.MaxHealth
			)
		)


		SetStatus(
			"MAX HEALTH",
			string.format(
				"%.0f",
				humanoid.MaxHealth
			)
		)


		SetStatus(
			"RIG TYPE",
			humanoid.RigType.Name
		)


		local currentState =
			humanoid:GetState()


		SetStatus(
			"CHARACTER STATE",
			currentState.Name
		)


		SetStatus(
			"HIP HEIGHT",
			string.format(
				"%.2f",
				humanoid.HipHeight
			)
		)


		SetStatus(
			"AUTO ROTATE",
			humanoid.AutoRotate
				and "ON"
				or "OFF"
		)


		SetStatus(
			"PLATFORM STAND",
			humanoid.PlatformStand
				and "ON"
				or "OFF"
		)


		SetStatus(
			"MOVE VECTOR",
			VectorString(
				humanoid.MoveDirection
			)
		)


		SetStatus(
			"SIT",
			humanoid.Sit
				and "YES"
				or "NO"
		)


		SetStatus(
			"JUMPING",
			currentState
				== Enum.HumanoidStateType.Jumping
				and "YES"
				or "NO"
		)

	end


	if root then

		SetStatus(
			"POSITION",
			VectorString(
				root.Position
			)
		)

	end


	SetStatus(
		"TEAM",
		LocalPlayer.Team
			and LocalPlayer.Team.Name
			or "None"
	)


	SetStatus(
		"ACCOUNT AGE",
		tostring(
			LocalPlayer.AccountAge
		)
		.. " DAYS"
	)


	SetStatus(
		"USER ID",
		LocalPlayer.UserId
	)


	SetStatus(
		"FPS",
		math.floor(
			State.FPS
		)
	)


	SetStatus(
		"PING",
		tostring(
			State.Ping
		)
		.. " ms"
	)


	SetStatus(
		"MEMORY",
		tostring(
			State.Memory
		)
		.. " MB"
	)


	SetStatus(
		"SESSION",
		FormatSession(
			os.clock()
			- Config.OpenedAt
		)
	)


	SetStatus(
		"DEVICE",
		DeviceName()
	)


	SetStatus(
		"CHARACTER",
		State.Character
			and State.Character.Name
			or "None"
	)

end


--==============================================================================
-- ANIMATION LOOP
--==============================================================================

Connect(
	RunService.RenderStepped,
	function(delta)

		if State.Destroyed then
			return
		end


		State.Elapsed += delta


		-- FPS smoothing.
		if delta > 0 then

			local instant =
				1 / delta


			State.FPS =
				State.FPS * 0.90
				+
				instant * 0.10

		end


		-- Update telemetry dua kali per detik.
		local currentHalf =
			math.floor(
				State.Elapsed * 2
			)


		local previousHalf =
			math.floor(
				(State.Elapsed - delta) * 2
			)


		if currentHalf ~= previousHalf then

			State.Ping =
				GetPing()

			State.Memory =
				GetMemory()

			UpdateLiveStatus()

		end


		if Config.Animations then

			local rotation =
				(State.Elapsed * 30)
				% 360


			LogoInner.Rotation =
				rotation


			MiniRing.Rotation =
				-rotation


			local pulse =
				(
					math.sin(
						State.Elapsed * 2.2
					)
					+ 1
				) / 2


			LogoRingStroke.Transparency =
				0.08
				+
				pulse * 0.18


			MiniRingStroke.Transparency =
				0.08
				+
				pulse * 0.18


			MainStroke.Transparency =
				0.08
				+
				pulse * 0.12


			local scale =
				1
				+
				math.sin(
					State.Elapsed * 2
				)
				* 0.025


			LogoV.Size =
				UDim2.fromOffset(
					42 * scale,
					42 * scale
				)


			MiniV.Size =
				UDim2.fromOffset(
					42 * scale,
					42 * scale
				)

		end


		if Config.Particles
			and Config.Animations then

			ParticleContainer.Visible =
				true


			for index, particle in
				ipairs(Particles) do

				local current =
					particle.Position


				local speed =
					0.008
					+
					index * 0.0002


				local y =
					current.Y.Scale
					+
					delta * speed


				if y > 1 then
					y = 0
				end


				particle.Position =
					UDim2.fromScale(
						current.X.Scale,
						y
					)

			end

		else

			ParticleContainer.Visible =
				false

		end


		if Config.Scanline
			and Config.Animations then

			Scanline.Visible =
				true


			local height =
				math.max(
					1,
					Main.AbsoluteSize.Y
				)


			local y =
				(State.Elapsed * 35)
				% height


			Scanline.Position =
				UDim2.fromOffset(
					0,
					y
				)

		else

			Scanline.Visible =
				false

		end

	end
)


--==============================================================================
-- [23] AVATAR
--==============================================================================

task.spawn(function()

	local success, image =
		pcall(function()

			return Players:GetUserThumbnailAsync(

				LocalPlayer.UserId,

				Enum.ThumbnailType.HeadShot,

				Enum.ThumbnailSize.Size150x150

			)

		end)


	if success and image then
		Avatar.Image = image
	end

end)


--==============================================================================
-- SETTINGS EVENTS
--==============================================================================

local ThemeNames = {
	"CYAN",
	"VIOLET",
	"MAGENTA",
	"BLUE",
	"GREEN",
}


local ThemeIndex = 1


local function RefreshTheme()

	Theme =
		Themes[
			Config.ThemeName
		]
		or
		Themes.CYAN


	MainStroke.Color =
		Accent()


	MainHighlight:FindFirstChildOfClass(
		"UIStroke"
	).Color =
		Color3.fromRGB(
			110,
			150,
			185
		)


	HeaderSeparator.BackgroundColor3 =
		Accent()


	HeaderLogoStroke.Color =
		Accent()


	LogoRingStroke.Color =
		Accent()


	LogoV.TextColor3 =
		AccentSoft()


	Subtitle.TextColor3 =
		AccentSoft()


	SettingsHeader:FindFirstChildOfClass(
		"UIStroke"
	).Color =
		Accent()


	SettingsButton.TextColor3 =
		AccentSoft()


	MiniStroke.Color =
		Accent()


	MiniRingStroke.Color =
		AccentSoft()


	MiniV.TextColor3 =
		AccentSoft()


	Scanline.BackgroundColor3 =
		Accent()


	for _, particle in
		ipairs(Particles) do

		particle.BackgroundColor3 =
			Accent()

	end


	StatusGrid.Parent =
		StatusContainer

end


Connect(
	ThemeButton.MouseButton1Click,
	function()

		ThemeIndex += 1


		if ThemeIndex >
			#ThemeNames then

			ThemeIndex = 1

		end


		Config.ThemeName =
			ThemeNames[ThemeIndex]


		ThemeButton.Text =
			"THEME : "
			.. Config.ThemeName


		RefreshTheme()

	end
)


local TransparencyMode = false


Connect(
	TransparencyButton.MouseButton1Click,
	function()

		TransparencyMode =
			not TransparencyMode


		if TransparencyMode then

			Main.BackgroundTransparency =
				0.12

			TransparencyButton.Text =
				"WINDOW STYLE : GLASS"

		else

			Main.BackgroundTransparency =
				0

			TransparencyButton.Text =
				"WINDOW STYLE : SOLID"

		end

	end
)


Connect(
	ScaleButton.MouseButton1Click,
	function()

		Config.Scale += 0.05


		if Config.Scale > 1.15 then
			Config.Scale = 0.80
		end


		UIScale.Scale =
			Config.Scale


		ScaleButton.Text =
			"GUI SCALE : "
			.. math.floor(
				Config.Scale * 100
			)
			.. "%"

	end
)


Connect(
	AnimationButton.MouseButton1Click,
	function()

		Config.Animations =
			not Config.Animations


		AnimationButton.Text =
			"ANIMATIONS : "
			.. (
				Config.Animations
				and "ON"
				or "OFF"
			)

	end
)


Connect(
	ParticleButton.MouseButton1Click,
	function()

		Config.Particles =
			not Config.Particles


		ParticleButton.Text =
			"PARTICLES : "
			.. (
				Config.Particles
				and "ON"
				or "OFF"
			)

	end
)


Connect(
	ScanlineButton.MouseButton1Click,
	function()

		Config.Scanline =
			not Config.Scanline


		ScanlineButton.Text =
			"SCANLINE : "
			.. (
				Config.Scanline
				and "ON"
				or "OFF"
			)

	end
)


--==============================================================================
-- [24] PUBLIC API
--==============================================================================

_G.vanz = {}


_G.vanz.Open = function()

	if State.Destroyed then
		return
	end


	ScreenGui.Enabled =
		true


	if not State.Minimized then
		Main.Visible = true
	end

end


_G.vanz.Minimize = function()

	if State.Destroyed then
		return
	end


	Minimize()

end


_G.vanz.Restore = function()

	if State.Destroyed then
		return
	end


	Restore()

end


_G.vanz.Close = function()

	Close()

end


_G.vanz.SetScale = function(value)

	value =
		tonumber(value)


	if not value then
		return
	end


	Config.Scale =
		math.clamp(
			value,
			0.70,
			1.20
		)


	UIScale.Scale =
		Config.Scale

end


_G.vanz.SetWalkSpeed = function(value)

	value =
		tonumber(value)


	if not value then
		return
	end


	ApplySpeed(value)

end


_G.vanz.SetJumpPower = function(value)

	value =
		tonumber(value)


	if not value then
		return
	end


	ApplyJump(value)

end


_G.vanz.GetState = function()

	return {
		Minimized =
			State.Minimized,

		SettingsOpen =
			State.SettingsOpen,

		FPS =
			State.FPS,

		Ping =
			State.Ping,

		Memory =
			State.Memory,

		WalkSpeed =
			State.Humanoid
			and State.Humanoid.WalkSpeed
			or 0,

		JumpPower =
			State.Humanoid
			and State.Humanoid.JumpPower
			or 0,

		Destroyed =
			State.Destroyed,
	}

end


--==============================================================================
-- [25] INITIALIZATION
--==============================================================================

RefreshCharacter()

UpdateLiveStatus()

UpdateResponsive()


Main.AnchorPoint =
	Vector2.new(
		0.5,
		0.5
	)


Main.Position =
	UDim2.fromScale(
		0.5,
		0.5
	)


print(
	"[VANZ] BRIGHT ROBOTIC GUI LOADED"
)

print(
	"[VANZ] HOME STATUS SYSTEM ONLINE"
)

print(
	"[VANZ] SETTINGS SYSTEM ONLINE"
)

print(
	"[VANZ] SAFE DRAG SYSTEM ONLINE"
)