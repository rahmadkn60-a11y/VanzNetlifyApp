--[[
================================================================================
 VANZ // ROBOTIC USER CONTROL CENTER
 FIXED FULL VERSION
================================================================================

[SECTION MAP]

01  Services
02  Configuration
03  Theme
04  Utility Functions
05  Cleanup
06  ScreenGui
07  Main Window
08  Header
09  Header Controls
10  Home Scrolling Page
11  User Identity
12  User Status Cards
13  Settings Page
14  Settings Controls
15  Character Tracking
16  Live Status
17  Safe Drag Engine
18  Minimized Logo
19  Minimize / Restore
20  Button FX
21  Responsive Mobile
22  Animation Engine
23  Public API
24  Startup

================================================================================
]]

--==============================================================================
-- [SECTION 01] SERVICES
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
-- [SECTION 02] CONFIGURATION
--==============================================================================

local Config = {
	Name = "VANZ_CONTROL_CENTER",

	DisplayOrder = 999999999,

	DesktopWidth = 980,
	DesktopHeight = 640,

	MobileMargin = 8,

	HeaderHeight = 76,

	MinimizedSize = 72,

	Scale = 1,

	Theme = "CYAN",

	Animations = true,
	Particles = true,
	Scanline = true,
	InteractionFX = true,

	WindowTransparency = 0.04,

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
-- [SECTION 03] THEME
--==============================================================================

local Themes = {

	CYAN = {
		Main = Color3.fromRGB(0, 220, 255),
		Secondary = Color3.fromRGB(0, 135, 255),
		Soft = Color3.fromRGB(70, 255, 235),
	},

	VIOLET = {
		Main = Color3.fromRGB(175, 100, 255),
		Secondary = Color3.fromRGB(100, 60, 255),
		Soft = Color3.fromRGB(225, 150, 255),
	},

	MAGENTA = {
		Main = Color3.fromRGB(255, 70, 190),
		Secondary = Color3.fromRGB(185, 50, 255),
		Soft = Color3.fromRGB(255, 140, 230),
	},

	BLUE = {
		Main = Color3.fromRGB(70, 150, 255),
		Secondary = Color3.fromRGB(30, 85, 220),
		Soft = Color3.fromRGB(125, 200, 255),
	},

	GREEN = {
		Main = Color3.fromRGB(60, 255, 170),
		Secondary = Color3.fromRGB(20, 170, 120),
		Soft = Color3.fromRGB(130, 255, 210),
	},

}


local Theme = Themes[Config.Theme] or Themes.CYAN


local function GetAccent()
	return Theme.Main
end


local function GetAccent2()
	return Theme.Secondary
end


local function GetAccent3()
	return Theme.Soft
end


local Colors = {

	Background = Color3.fromRGB(5, 8, 14),

	Panel = Color3.fromRGB(9, 14, 23),

	Panel2 = Color3.fromRGB(12, 19, 30),

	Card = Color3.fromRGB(14, 22, 34),

	Card2 = Color3.fromRGB(18, 28, 43),

	Border = Color3.fromRGB(40, 57, 77),

	Text = Color3.fromRGB(238, 247, 255),

	SubText = Color3.fromRGB(145, 166, 187),

	Muted = Color3.fromRGB(82, 103, 124),

	Success = Color3.fromRGB(70, 255, 160),

	Warning = Color3.fromRGB(255, 195, 70),

	Danger = Color3.fromRGB(255, 75, 95),

}


--==============================================================================
-- [SECTION 04] UTILITY FUNCTIONS
--==============================================================================

local Connections = {}


local function SafeConnect(signal, callback)

	if not signal then
		return nil
	end

	local ok, connection = pcall(function()
		return signal:Connect(callback)
	end)

	if ok and connection then
		table.insert(Connections, connection)
		return connection
	end

	return nil
end


local function SafeTween(object, duration, properties)

	if not object then
		return nil
	end

	local ok, tween = pcall(function()

		local info = TweenInfo.new(
			duration,
			Enum.EasingStyle.Quint,
			Enum.EasingDirection.Out
		)

		return TweenService:Create(
			object,
			info,
			properties
		)

	end)

	if ok and tween then

		tween:Play()

		return tween

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


local function AddCorner(object, radius)

	return Create(
		"UICorner",
		{
			CornerRadius = UDim.new(0, radius),
		},
		object
	)

end


local function AddStroke(object, color, thickness, transparency)

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


local function AddPadding(object, left, top, right, bottom)

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


local function DisconnectEverything()

	for _, connection in ipairs(Connections) do

		if connection then

			pcall(function()
				connection:Disconnect()
			end)

		end

	end

	table.clear(Connections)

end


--==============================================================================
-- [SECTION 05] CLEANUP OLD GUI
--==============================================================================

local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")


local oldGui = PlayerGui:FindFirstChild(Config.Name)

if oldGui then

	pcall(function()
		oldGui:Destroy()
	end)

end


--==============================================================================
-- [SECTION 06] SCREEN GUI
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


local GlobalScale = Create(
	"UIScale",
	{
		Scale = Config.Scale,
	},
	ScreenGui
)


--==============================================================================
-- [SECTION 07] MAIN WINDOW
--==============================================================================

local Main = Create(
	"Frame",
	{
		Name = "Main",

		AnchorPoint = Vector2.new(0.5, 0.5),

		Position = UDim2.fromScale(0.5, 0.5),

		Size = UDim2.fromOffset(
			Config.DesktopWidth,
			Config.DesktopHeight
		),

		BackgroundColor3 = Colors.Background,

		BackgroundTransparency = Config.WindowTransparency,

		BorderSizePixel = 0,

		ClipsDescendants = true,

		ZIndex = 10,
	},
	ScreenGui
)

AddCorner(Main, 18)

local MainStroke = AddStroke(
	Main,
	GetAccent(),
	1,
	0.2
)


--==============================================================================
-- [SECTION 08] HEADER
--==============================================================================

local Header = Create(
	"Frame",
	{
		Name = "Header",

		Size = UDim2.new(
			1,
			0,
			0,
			Config.HeaderHeight
		),

		BackgroundColor3 = Colors.Panel,

		BorderSizePixel = 0,

		ZIndex = 20,
	},
	Main
)


--------------------------------------------------------------------------------
-- HEADER DRAG AREA
--------------------------------------------------------------------------------

local DragArea = Create(
	"Frame",
	{
		Name = "DragArea",

		Position = UDim2.fromOffset(74, 0),

		Size = UDim2.new(
			1,
			-292,
			1,
			0
		),

		BackgroundTransparency = 1,

		Active = true,

		ZIndex = 21,
	},
	Header
)


--------------------------------------------------------------------------------
-- LOGO
--------------------------------------------------------------------------------

local HeaderLogo = Create(
	"Frame",
	{
		Position = UDim2.fromOffset(12, 9),

		Size = UDim2.fromOffset(58, 58),

		BackgroundColor3 = Colors.Card,

		BorderSizePixel = 0,

		ZIndex = 25,
	},
	Header
)

AddCorner(HeaderLogo, 15)

AddStroke(
	HeaderLogo,
	GetAccent(),
	1,
	0.2
)


local HeaderLogoRing = Create(
	"Frame",
	{
		AnchorPoint = Vector2.new(0.5, 0.5),

		Position = UDim2.fromScale(0.5, 0.5),

		Size = UDim2.fromOffset(43, 43),

		BackgroundTransparency = 1,

		BorderSizePixel = 0,

		ZIndex = 26,
	},
	HeaderLogo
)

AddCorner(HeaderLogoRing, 100)

local HeaderRingStroke = AddStroke(
	HeaderLogoRing,
	GetAccent(),
	2,
	0.15
)


local HeaderLogoText = Create(
	"TextLabel",
	{
		AnchorPoint = Vector2.new(0.5, 0.5),

		Position = UDim2.fromScale(0.5, 0.5),

		Size = UDim2.fromOffset(40, 40),

		BackgroundTransparency = 1,

		Font = Enum.Font.GothamBlack,

		Text = "V",

		TextColor3 = GetAccent(),

		TextSize = 27,

		ZIndex = 27,
	},
	HeaderLogo
)


--------------------------------------------------------------------------------
-- TITLE
--------------------------------------------------------------------------------

local Title = Create(
	"TextLabel",
	{
		Position = UDim2.fromOffset(82, 10),

		Size = UDim2.new(
			1,
			-370,
			0,
			30
		),

		BackgroundTransparency = 1,

		Font = Enum.Font.GothamBlack,

		Text = "VANZ",

		TextColor3 = Colors.Text,

		TextSize = 22,

		TextXAlignment = Enum.TextXAlignment.Left,

		TextTruncate = Enum.TextTruncate.AtEnd,

		ZIndex = 25,
	},
	Header
)


local Subtitle = Create(
	"TextLabel",
	{
		Position = UDim2.fromOffset(83, 40),

		Size = UDim2.new(
			1,
			-370,
			0,
			22
		),

		BackgroundTransparency = 1,

		Font = Enum.Font.GothamMedium,

		Text = "ROBOTIC USER CONTROL CENTER",

		TextColor3 = GetAccent(),

		TextSize = 10,

		TextXAlignment = Enum.TextXAlignment.Left,

		TextTruncate = Enum.TextTruncate.AtEnd,

		ZIndex = 25,
	},
	Header
)


--==============================================================================
-- [SECTION 09] HEADER CONTROLS
-- Settings / Minimize / Close punya zona sendiri
--==============================================================================

local Controls = Create(
	"Frame",
	{
		Name = "Controls",

		AnchorPoint = Vector2.new(1, 0.5),

		Position = UDim2.new(
			1,
			-8,
			0.5,
			0
		),

		Size = UDim2.fromOffset(
			204,
			54
		),

		BackgroundTransparency = 1,

		ZIndex = 60,
	},
	Header
)


local ControlsLayout = Create(
	"UIListLayout",
	{
		FillDirection = Enum.FillDirection.Horizontal,

		HorizontalAlignment = Enum.HorizontalAlignment.Right,

		VerticalAlignment = Enum.VerticalAlignment.Center,

		Padding = UDim.new(0, 6),
	},
	Controls
)


local function CreateControlButton(text)

	local button = Create(
		"TextButton",
		{
			Size = UDim2.fromOffset(54, 50),

			BackgroundColor3 = Colors.Card,

			BorderSizePixel = 0,

			AutoButtonColor = false,

			Font = Enum.Font.GothamBlack,

			Text = text,

			TextColor3 = Colors.Text,

			TextSize = 24,

			ZIndex = 65,
		},
		Controls
	)

	AddCorner(button, 12)

	AddStroke(
		button,
		Colors.Border,
		1,
		0.1
	)

	return button
end


local SettingsButton = CreateControlButton("⚙")

local MinimizeButton = CreateControlButton("—")

local CloseButton = CreateControlButton("×")

CloseButton.TextColor3 = Colors.Danger


--==============================================================================
-- [SECTION 10] HOME SCROLLING PAGE
--==============================================================================

local Body = Create(
	"Frame",
	{
		Name = "Body",

		Position = UDim2.fromOffset(
			0,
			Config.HeaderHeight
		),

		Size = UDim2.new(
			1,
			0,
			1,
			-Config.HeaderHeight
		),

		BackgroundTransparency = 1,

		ZIndex = 15,
	},
	Main
)


local Home = Create(
	"ScrollingFrame",
	{
		Name = "Home",

		Size = UDim2.fromScale(1, 1),

		BackgroundTransparency = 1,

		BorderSizePixel = 0,

		CanvasSize = UDim2.fromOffset(0, 0),

		AutomaticCanvasSize = Enum.AutomaticSize.Y,

		ScrollingDirection = Enum.ScrollingDirection.Y,

		ScrollBarThickness = 5,

		ScrollBarImageColor3 = GetAccent(),

		ScrollBarImageTransparency = 0.25,

		Active = true,

		Visible = true,

		ZIndex = 16,
	},
	Body
)

AddPadding(Home, 15, 15, 15, 20)


local HomeLayout = Create(
	"UIListLayout",
	{
		FillDirection = Enum.FillDirection.Vertical,

		HorizontalAlignment = Enum.HorizontalAlignment.Center,

		Padding = UDim.new(0, 11),
	},
	Home
)


--==============================================================================
-- [SECTION 11] USER IDENTITY
--==============================================================================

local Identity = Create(
	"Frame",
	{
		Size = UDim2.new(
			1,
			0,
			0,
			118
		),

		BackgroundColor3 = Colors.Card,

		BorderSizePixel = 0,

		LayoutOrder = 1,
	},
	Home
)

AddCorner(Identity, 16)

AddStroke(
	Identity,
	GetAccent(),
	1,
	0.22
)


local Avatar = Create(
	"ImageLabel",
	{
		Position = UDim2.fromOffset(14, 14),

		Size = UDim2.fromOffset(90, 90),

		BackgroundColor3 = Colors.Panel2,

		BorderSizePixel = 0,

		Image = "",
	},
	Identity
)

AddCorner(Avatar, 14)

AddStroke(
	Avatar,
	GetAccent(),
	2,
	0.1
)


local DisplayName = Create(
	"TextLabel",
	{
		Position = UDim2.fromOffset(120, 17),

		Size = UDim2.new(
			1,
			-135,
			0,
			30
		),

		BackgroundTransparency = 1,

		Font = Enum.Font.GothamBlack,

		Text = LocalPlayer.DisplayName,

		TextColor3 = Colors.Text,

		TextSize = 22,

		TextXAlignment = Enum.TextXAlignment.Left,

		TextTruncate = Enum.TextTruncate.AtEnd,
	},
	Identity
)


local Username = Create(
	"TextLabel",
	{
		Position = UDim2.fromOffset(121, 49),

		Size = UDim2.new(
			1,
			-136,
			0,
			20
		),

		BackgroundTransparency = 1,

		Font = Enum.Font.GothamBold,

		Text = "@" .. LocalPlayer.Name,

		TextColor3 = GetAccent(),

		TextSize = 13,

		TextXAlignment = Enum.TextXAlignment.Left,

		TextTruncate = Enum.TextTruncate.AtEnd,
	},
	Identity
)


local IdentityStatus = Create(
	"TextLabel",
	{
		Position = UDim2.fromOffset(121, 74),

		Size = UDim2.new(
			1,
			-136,
			0,
			25
		),

		BackgroundTransparency = 1,

		Font = Enum.Font.GothamMedium,

		Text = "● USER LINK ONLINE",

		TextColor3 = Colors.Success,

		TextSize = 11,

		TextXAlignment = Enum.TextXAlignment.Left,
	},
	Identity
)


--==============================================================================
-- [SECTION 12] STATUS CARDS
--==============================================================================

local StatusContainer = Create(
	"Frame",
	{
		Size = UDim2.new(
			1,
			0,
			0,
			700
		),

		BackgroundTransparency = 1,

		LayoutOrder = 2,
	},
	Home
)


local StatusGrid = Create(
	"UIGridLayout",
	{
		CellPadding = UDim2.fromOffset(9, 9),

		CellSize = UDim2.new(
			0.5,
			-5,
			0,
			70
		),

		SortOrder = Enum.SortOrder.LayoutOrder,
	},
	StatusContainer
)


local StatusValues = {}


local function CreateStatus(label, value)

	local card = Create(
		"Frame",
		{
			BackgroundColor3 = Colors.Card,

			BorderSizePixel = 0,
		},
		StatusContainer
	)

	AddCorner(card, 12)

	AddStroke(
		card,
		Colors.Border,
		1,
		0.2
	)


	local bar = Create(
		"Frame",
		{
			Position = UDim2.fromOffset(0, 9),

			Size = UDim2.fromOffset(3, 52),

			BackgroundColor3 = GetAccent(),

			BorderSizePixel = 0,
		},
		card
	)

	AddCorner(bar, 4)


	local nameLabel = Create(
		"TextLabel",
		{
			Position = UDim2.fromOffset(13, 9),

			Size = UDim2.new(
				1,
				-23,
				0,
				17
			),

			BackgroundTransparency = 1,

			Font = Enum.Font.GothamMedium,

			Text = label,

			TextColor3 = Colors.SubText,

			TextSize = 9,

			TextXAlignment = Enum.TextXAlignment.Left,
		},
		card
	)


	local valueLabel = Create(
		"TextLabel",
		{
			Position = UDim2.fromOffset(13, 28),

			Size = UDim2.new(
				1,
				-23,
				0,
				30
			),

			BackgroundTransparency = 1,

			Font = Enum.Font.GothamBold,

			Text = tostring(value),

			TextColor3 = Colors.Text,

			TextSize = 16,

			TextXAlignment = Enum.TextXAlignment.Left,

			TextTruncate = Enum.TextTruncate.AtEnd,
		},
		card
	)


	StatusValues[label] = valueLabel

	return card
end


CreateStatus("WALK SPEED", "16")
CreateStatus("JUMP POWER", "50")

CreateStatus("HEALTH", "100 / 100")
CreateStatus("MAX HEALTH", "100")

CreateStatus("RIG TYPE", "Unknown")
CreateStatus("CHARACTER STATE", "Loading")

CreateStatus("HIP HEIGHT", "2")
CreateStatus("AUTO ROTATE", "ON")

CreateStatus("PLATFORM STAND", "OFF")
CreateStatus("MOVE VECTOR", "0, 0, 0")

CreateStatus("POSITION", "0, 0, 0")
CreateStatus("TEAM", "None")

CreateStatus("ACCOUNT AGE", "0 DAYS")
CreateStatus("USER ID", tostring(LocalPlayer.UserId))

CreateStatus("FPS", "60")
CreateStatus("PING", "0 ms")

CreateStatus("MEMORY", "0 MB")
CreateStatus("SESSION", "00:00")

CreateStatus("DEVICE", "Unknown")
CreateStatus("CHARACTER", "Loading")

CreateStatus("SIT", "NO")
CreateStatus("JUMPING", "NO")


--==============================================================================
-- [SECTION 13] SETTINGS PAGE
--==============================================================================

local SettingsPage = Create(
	"ScrollingFrame",
	{
		Name = "Settings",

		Size = UDim2.fromScale(1, 1),

		BackgroundTransparency = 1,

		BorderSizePixel = 0,

		CanvasSize = UDim2.fromOffset(0, 0),

		AutomaticCanvasSize = Enum.AutomaticSize.Y,

		ScrollingDirection = Enum.ScrollingDirection.Y,

		ScrollBarThickness = 5,

		ScrollBarImageColor3 = GetAccent(),

		Visible = false,

		ZIndex = 30,
	},
	Body
)

AddPadding(SettingsPage, 15, 15, 15, 20)


local SettingsLayout = Create(
	"UIListLayout",
	{
		FillDirection = Enum.FillDirection.Vertical,

		HorizontalAlignment = Enum.HorizontalAlignment.Center,

		Padding = UDim.new(0, 11),
	},
	SettingsPage
)


--------------------------------------------------------------------------------
-- SETTINGS HEADER
--------------------------------------------------------------------------------

local SettingsHeader = Create(
	"Frame",
	{
		Size = UDim2.new(
			1,
			0,
			0,
			92
		),

		BackgroundColor3 = Colors.Panel,

		BorderSizePixel = 0,

		LayoutOrder = 1,
	},
	SettingsPage
)

AddCorner(SettingsHeader, 15)

AddStroke(
	SettingsHeader,
	GetAccent(),
	1,
	0.2
)


local SettingsTitle = Create(
	"TextLabel",
	{
		Position = UDim2.fromOffset(17, 13),

		Size = UDim2.new(
			1,
			-34,
			0,
			30
		),

		BackgroundTransparency = 1,

		Font = Enum.Font.GothamBlack,

		Text = "SYSTEM SETTINGS",

		TextColor3 = Colors.Text,

		TextSize = 22,

		TextXAlignment = Enum.TextXAlignment.Left,
	},
	SettingsHeader
)


local SettingsDescription = Create(
	"TextLabel",
	{
		Position = UDim2.fromOffset(18, 49),

		Size = UDim2.new(
			1,
			-36,
			0,
			22
		),

		BackgroundTransparency = 1,

		Font = Enum.Font.GothamMedium,

		Text = "CUSTOMIZE VANZ WITHOUT CHANGING THE DEFAULT STYLE",

		TextColor3 = GetAccent(),

		TextSize = 10,

		TextXAlignment = Enum.TextXAlignment.Left,

		TextTruncate = Enum.TextTruncate.AtEnd,
	},
	SettingsHeader
)


--==============================================================================
-- [SECTION 14] SETTINGS CONTROLS
--==============================================================================

local SettingsCounter = 2


local function SettingsSection(title, description, height)

	local section = Create(
		"Frame",
		{
			Size = UDim2.new(
				1,
				0,
				0,
				height
			),

			BackgroundColor3 = Colors.Card,

			BorderSizePixel = 0,

			LayoutOrder = SettingsCounter,
		},
		SettingsPage
	)

	SettingsCounter += 1

	AddCorner(section, 14)

	AddStroke(
		section,
		Colors.Border,
		1,
		0.2
	)


	Create(
		"TextLabel",
		{
			Position = UDim2.fromOffset(15, 10),

			Size = UDim2.new(
				1,
				-30,
				0,
				23
			),

			BackgroundTransparency = 1,

			Font = Enum.Font.GothamBlack,

			Text = title,

			TextColor3 = Colors.Text,

			TextSize = 16,

			TextXAlignment = Enum.TextXAlignment.Left,
		},
		section
	)


	Create(
		"TextLabel",
		{
			Position = UDim2.fromOffset(16, 34),

			Size = UDim2.new(
				1,
				-32,
				0,
				19
			),

			BackgroundTransparency = 1,

			Font = Enum.Font.GothamMedium,

			Text = description,

			TextColor3 = Colors.SubText,

			TextSize = 9,

			TextXAlignment = Enum.TextXAlignment.Left,

			TextTruncate = Enum.TextTruncate.AtEnd,
		},
		section
	)


	return section
end


local function SettingsButtonCreate(parent, text, y)

	local button = Create(
		"TextButton",
		{
			Position = UDim2.fromOffset(15, y),

			Size = UDim2.new(
				1,
				-30,
				0,
				40
			),

			BackgroundColor3 = Colors.Panel2,

			BorderSizePixel = 0,

			AutoButtonColor = false,

			Font = Enum.Font.GothamBold,

			Text = text,

			TextColor3 = Colors.Text,

			TextSize = 12,
		},
		parent
	)

	AddCorner(button, 9)

	AddStroke(
		button,
		Colors.Border,
		1,
		0.25
	)

	return button
end


--------------------------------------------------------------------------------
-- APPEARANCE
--------------------------------------------------------------------------------

local AppearanceSection = SettingsSection(
	"APPEARANCE",
	"Change theme, scale and transparency",
	225
)


local ThemeButton = SettingsButtonCreate(
	AppearanceSection,
	"THEME : CYAN",
	66
)


local ScaleButton = SettingsButtonCreate(
	AppearanceSection,
	"GUI SCALE : 100%",
	111
)


local OpacityButton = SettingsButtonCreate(
	AppearanceSection,
	"WINDOW TRANSPARENCY : 4%",
	156
)


--------------------------------------------------------------------------------
-- ANIMATION
--------------------------------------------------------------------------------

local AnimationSection = SettingsSection(
	"ANIMATION CORE",
	"Control the robotic visual system",
	225
)


local AnimationButton = SettingsButtonCreate(
	AnimationSection,
	"ANIMATIONS : ON",
	66
)


local ParticleButton = SettingsButtonCreate(
	AnimationSection,
	"PARTICLES : ON",
	111
)


local ScanlineButton = SettingsButtonCreate(
	AnimationSection,
	"SCANLINE : ON",
	156
)


--------------------------------------------------------------------------------
-- PLAYER
--------------------------------------------------------------------------------

local PlayerSection = SettingsSection(
	"PLAYER CONTROL",
	"Modify live character movement values",
	270
)


local SpeedButton = SettingsButtonCreate(
	PlayerSection,
	"WALK SPEED : 16",
	66
)


local JumpButton = SettingsButtonCreate(
	PlayerSection,
	"JUMP POWER : 50",
	111
)


local ResetPlayerButton = SettingsButtonCreate(
	PlayerSection,
	"RESET PLAYER VALUES",
	156
)


local ResetWindowButton = SettingsButtonCreate(
	PlayerSection,
	"RESET WINDOW POSITION",
	201
)


--==============================================================================
-- [SECTION 15] CHARACTER TRACKING
--==============================================================================

local function RefreshCharacter()

	local character = LocalPlayer.Character

	State.Character = character

	if not character then

		State.Humanoid = nil
		State.RootPart = nil

		return
	end


	local humanoid =
		character:FindFirstChildOfClass("Humanoid")


	local root =
		character:FindFirstChild("HumanoidRootPart")


	State.Humanoid = humanoid

	State.RootPart = root

end


RefreshCharacter()


SafeConnect(
	LocalPlayer.CharacterAdded,
	function(character)

		State.Character = character

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


--==============================================================================
-- [SECTION 16] LIVE STATUS
--==============================================================================

local function SetStatus(name, value)

	local label = StatusValues[name]

	if label then

		label.Text = tostring(value)

	end

end


local function FormatVector(vector)

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


local function FormatTime(seconds)

	seconds = math.floor(seconds)

	local minutes =
		math.floor(seconds / 60)

	local secs =
		seconds % 60

	if minutes >= 60 then

		local hours =
			math.floor(minutes / 60)

		minutes =
			minutes % 60

		return string.format(
			"%02d:%02d:%02d",
			hours,
			minutes,
			secs
		)

	end

	return string.format(
		"%02d:%02d",
		minutes,
		secs
	)
end


local function GetDevice()

	if UserInputService.TouchEnabled
		and not UserInputService.KeyboardEnabled then

		return "MOBILE"

	end


	if UserInputService.GamepadEnabled
		and not UserInputService.KeyboardEnabled then

		return "GAMEPAD"

	end


	if UserInputService.KeyboardEnabled then

		return "PC"

	end


	return "UNKNOWN"
end


local function GetPing()

	local success, result = pcall(function()

		local network =
			Stats:FindFirstChild("Network")

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


		local value =
			dataPing:GetValue()

		return tonumber(value) or 0

	end)

	if success then
		return math.floor(result)
	end

	return 0
end


local function GetMemory()

	local success, result = pcall(function()

		if Stats.GetTotalMemoryUsageMb then

			return Stats:GetTotalMemoryUsageMb()

		end

		return 0

	end)

	if success then
		return math.floor(result)
	end

	return 0
end


local function UpdateStatus()

	RefreshCharacter()

	local humanoid = State.Humanoid
	local root = State.RootPart


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


		SetStatus(
			"CHARACTER STATE",
			humanoid:GetState().Name
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
			FormatVector(
				humanoid.MoveDirection
			)
		)


		SetStatus(
			"SIT",
			humanoid.Sit
				and "YES"
				or "NO"
		)


		local state =
			humanoid:GetState()

		SetStatus(
			"JUMPING",
			state == Enum.HumanoidStateType.Jumping
				and "YES"
				or "NO"
		)

	end


	if root then

		SetStatus(
			"POSITION",
			FormatVector(
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
		math.floor(State.FPS)
	)


	SetStatus(
		"PING",
		tostring(State.Ping)
		.. " ms"
	)


	SetStatus(
		"MEMORY",
		tostring(State.Memory)
		.. " MB"
	)


	SetStatus(
		"SESSION",
		FormatTime(
			os.clock()
			- Config.OpenedAt
		)
	)


	SetStatus(
		"DEVICE",
		GetDevice()
	)


	SetStatus(
		"CHARACTER",
		State.Character
			and State.Character.Name
			or "None"
	)

end


--==============================================================================
-- [SECTION 17] SAFE DRAG ENGINE
--==============================================================================
-- Prinsip:
--
-- 1. Simpan pointer awal.
-- 2. Simpan posisi center awal dari UDim2.
-- 3. Hitung delta pointer.
-- 4. Center baru = center awal + delta.
--
-- Jadi tidak mengambil AbsolutePosition ketika first-touch.
--==============================================================================

local Drag = {
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


local function GetFrameCenter(frame)

	local viewport =
		GetViewport()

	local x =
		frame.Position.X.Scale
		* viewport.X
		+ frame.Position.X.Offset

	local y =
		frame.Position.Y.Scale
		* viewport.Y
		+ frame.Position.Y.Offset

	return Vector2.new(x, y)
end


local function ClampMain(center)

	local viewport =
		GetViewport()

	local halfX =
		Main.AbsoluteSize.X / 2

	local halfY =
		Main.AbsoluteSize.Y / 2

	local x =
		math.clamp(
			center.X,
			halfX + 3,
			viewport.X - halfX - 3
		)

	local y =
		math.clamp(
			center.Y,
			halfY + 3,
			viewport.Y - halfY - 3
		)

	return Vector2.new(x, y)
end


local function StartDrag(input)

	if State.Minimized then
		return
	end


	if Drag.Active then
		return
	end


	Drag.Active = true


	Drag.StartPointer =
		Vector2.new(
			input.Position.X,
			input.Position.Y
		)


	Drag.StartCenter =
		GetFrameCenter(Main)

end


SafeConnect(
	DragArea.InputBegan,
	function(input)

		if
			input.UserInputType
			== Enum.UserInputType.MouseButton1
			or
			input.UserInputType
			== Enum.UserInputType.Touch
		then

			StartDrag(input)

		end

	end
)


SafeConnect(
	UserInputService.InputChanged,
	function(input)

		if not Drag.Active then
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
				- Drag.StartPointer


			local newCenter =
				Drag.StartCenter
				+ delta


			newCenter =
				ClampMain(
					newCenter
				)


			Main.Position =
				UDim2.fromOffset(
					newCenter.X,
					newCenter.Y
				)


			Main.AnchorPoint =
				Vector2.new(
					0.5,
					0.5
				)

		end

	end
)


SafeConnect(
	UserInputService.InputEnded,
	function(input)

		if
			input.UserInputType
			== Enum.UserInputType.MouseButton1
			or
			input.UserInputType
			== Enum.UserInputType.Touch
		then

			Drag.Active = false

			Drag.StartPointer = nil

			Drag.StartCenter = nil

		end

	end
)


--==============================================================================
-- [SECTION 18] MINIMIZED LOGO
--==============================================================================

local MiniLogo = Create(
	"Frame",
	{
		Name = "MiniLogo",

		AnchorPoint = Vector2.new(0.5, 0.5),

		Position = UDim2.fromScale(
			0.5,
			0.5
		),

		Size = UDim2.fromOffset(
			Config.MinimizedSize,
			Config.MinimizedSize
		),

		BackgroundColor3 = Colors.Panel,

		BorderSizePixel = 0,

		Visible = false,

		Active = true,

		ZIndex = 500,
	},
	ScreenGui
)

AddCorner(MiniLogo, 18)

AddStroke(
	MiniLogo,
	GetAccent(),
	1,
	0.1
)


local MiniRing = Create(
	"Frame",
	{
		AnchorPoint = Vector2.new(0.5, 0.5),

		Position = UDim2.fromScale(0.5, 0.5),

		Size = UDim2.fromOffset(49, 49),

		BackgroundTransparency = 1,

		BorderSizePixel = 0,

		ZIndex = 501,
	},
	MiniLogo
)

AddCorner(MiniRing, 100)

local MiniRingStroke = AddStroke(
	MiniRing,
	GetAccent(),
	2,
	0.1
)


local MiniText = Create(
	"TextLabel",
	{
		AnchorPoint = Vector2.new(0.5, 0.5),

		Position = UDim2.fromScale(0.5, 0.5),

		Size = UDim2.fromOffset(40, 40),

		BackgroundTransparency = 1,

		Font = Enum.Font.GothamBlack,

		Text = "V",

		TextColor3 = GetAccent(),

		TextSize = 29,

		ZIndex = 503,
	},
	MiniLogo
)


--==============================================================================
-- [SECTION 19] MINIMIZED LOGO DRAG
--==============================================================================

local MiniDrag = {
	Active = false,

	Moved = false,

	StartPointer = nil,

	StartCenter = nil,
}


local function GetMiniCenter()

	return GetFrameCenter(MiniLogo)

end


local function ClampMini(center)

	local viewport =
		GetViewport()

	local half =
		MiniLogo.AbsoluteSize.X / 2

	local x =
		math.clamp(
			center.X,
			half + 4,
			viewport.X - half - 4
		)

	local y =
		math.clamp(
			center.Y,
			half + 4,
			viewport.Y - half - 4
		)

	return Vector2.new(x, y)
end


SafeConnect(
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

			-- Posisi awal diambil dari UDim2.
			-- Bukan AbsolutePosition.
			MiniDrag.StartCenter =
				GetMiniCenter()

		end

	end
)


SafeConnect(
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
				ClampMini(center)


			MiniLogo.Position =
				UDim2.fromOffset(
					center.X,
					center.Y
				)


			MiniLogo.AnchorPoint =
				Vector2.new(
					0.5,
					0.5
				)

		end

	end
)


SafeConnect(
	UserInputService.InputEnded,
	function(input)

		if not MiniDrag.Active then
			return
		end


		if
			input.UserInputType
			== Enum.UserInputType.MouseButton1
			or
			input.UserInputType
			== Enum.UserInputType.Touch
		then

			local restore =
				not MiniDrag.Moved


			MiniDrag.Active = false

			MiniDrag.StartPointer = nil

			MiniDrag.StartCenter = nil


			-- Tap logo = restore.
			-- Drag logo = tetap di posisi terakhir.
			if restore then

				MiniLogo.Visible = false

				Main.Visible = true

				State.Minimized = false

			end

		end

	end
)


--==============================================================================
-- [SECTION 20] MINIMIZE / RESTORE
--==============================================================================

local function MinimizeGUI()

	State.Minimized = true

	State.SettingsOpen = false

	Main.Visible = false

	MiniLogo.Visible = true

	-- Selalu muncul di tengah.
	MiniLogo.AnchorPoint =
		Vector2.new(0.5, 0.5)

	MiniLogo.Position =
		UDim2.fromScale(
			0.5,
			0.5
		)

end


local function RestoreGUI()

	State.Minimized = false

	MiniLogo.Visible = false

	Main.Visible = true

end


local function ToggleSettings()

	State.SettingsOpen =
		not State.SettingsOpen


	Home.Visible =
		not State.SettingsOpen


	SettingsPage.Visible =
		State.SettingsOpen

end


SafeConnect(
	SettingsButton.MouseButton1Click,
	function()
		ToggleSettings()
	end
)


SafeConnect(
	MinimizeButton.MouseButton1Click,
	function()
		MinimizeGUI()
	end
)


--==============================================================================
-- [SECTION 21] CLOSE
--==============================================================================

local function CloseGUI()

	if State.Destroyed then
		return
	end


	State.Destroyed = true


	DisconnectEverything()


	if ScreenGui then

		pcall(function()
			ScreenGui:Destroy()
		end)

	end


	_G.vanz = nil

end


SafeConnect(
	CloseButton.MouseButton1Click,
	function()
		CloseGUI()
	end
)


--==============================================================================
-- [SECTION 22] SETTINGS EVENTS
--==============================================================================

local ThemeNames = {
	"CYAN",
	"VIOLET",
	"MAGENTA",
	"BLUE",
	"GREEN",
}

local ThemeIndex = 1


SafeConnect(
	ThemeButton.MouseButton1Click,
	function()

		ThemeIndex += 1

		if ThemeIndex > #ThemeNames then
			ThemeIndex = 1
		end


		Config.Theme =
			ThemeNames[ThemeIndex]


		Theme =
			Themes[Config.Theme]
			or Themes.CYAN


		ThemeButton.Text =
			"THEME : "
			.. Config.Theme

	end
)


SafeConnect(
	ScaleButton.MouseButton1Click,
	function()

		Config.Scale += 0.05

		if Config.Scale > 1.20 then
			Config.Scale = 0.75
		end


		GlobalScale.Scale =
			Config.Scale


		ScaleButton.Text =
			"GUI SCALE : "
			.. math.floor(
				Config.Scale * 100
			)
			.. "%"

	end
)


local Transparency =
	Config.WindowTransparency


SafeConnect(
	OpacityButton.MouseButton1Click,
	function()

		Transparency += 0.05

		if Transparency > 0.30 then
			Transparency = 0
		end


		Config.WindowTransparency =
			Transparency


		Main.BackgroundTransparency =
			Transparency


		OpacityButton.Text =
			"WINDOW TRANSPARENCY : "
			.. math.floor(
				Transparency * 100
			)
			.. "%"

	end
)


SafeConnect(
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


SafeConnect(
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


SafeConnect(
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
-- [SECTION 23] PLAYER CONTROL SETTINGS
--==============================================================================

local CurrentSpeed = 16
local CurrentJump = 50


local function ApplySpeed(value)

	CurrentSpeed = value

	RefreshCharacter()


	if State.Humanoid then

		pcall(function()

			State.Humanoid.WalkSpeed =
				value

		end)

	end


	SpeedButton.Text =
		"WALK SPEED : "
		.. tostring(value)

end


local function ApplyJump(value)

	CurrentJump = value

	RefreshCharacter()


	if State.Humanoid then

		pcall(function()

			State.Humanoid.UseJumpPower = true

			State.Humanoid.JumpPower =
				value

		end)

	end


	JumpButton.Text =
		"JUMP POWER : "
		.. tostring(value)

end


SafeConnect(
	SpeedButton.MouseButton1Click,
	function()

		CurrentSpeed += 4

		if CurrentSpeed > 40 then
			CurrentSpeed = 16
		end


		ApplySpeed(CurrentSpeed)

	end
)


SafeConnect(
	JumpButton.MouseButton1Click,
	function()

		CurrentJump += 10

		if CurrentJump > 100 then
			CurrentJump = 50
		end


		ApplyJump(CurrentJump)

	end
)


SafeConnect(
	ResetPlayerButton.MouseButton1Click,
	function()

		ApplySpeed(16)

		ApplyJump(50)

	end
)


SafeConnect(
	ResetWindowButton.MouseButton1Click,
	function()

		Main.AnchorPoint =
			Vector2.new(0.5, 0.5)

		Main.Position =
			UDim2.fromScale(
				0.5,
				0.5
			)

	end
)


--==============================================================================
-- [SECTION 24] BUTTON FX
--==============================================================================

local function AddButtonFX(button)

	if not button then
		return
	end


	local originalColor =
		button.BackgroundColor3


	SafeConnect(
		button.MouseEnter,
		function()

			if not Config.InteractionFX then
				return
			end


			SafeTween(
				button,
				0.12,
				{
					BackgroundColor3 =
						Color3.fromRGB(
							22,
							34,
							51
						),
				}
			)

		end
	)


	SafeConnect(
		button.MouseLeave,
		function()

			if not Config.InteractionFX then
				return
			end


			SafeTween(
				button,
				0.14,
				{
					BackgroundColor3 =
						originalColor,
				}
			)

		end
	)

end


AddButtonFX(SettingsButton)
AddButtonFX(MinimizeButton)
AddButtonFX(CloseButton)

AddButtonFX(ThemeButton)
AddButtonFX(ScaleButton)
AddButtonFX(OpacityButton)

AddButtonFX(AnimationButton)
AddButtonFX(ParticleButton)
AddButtonFX(ScanlineButton)

AddButtonFX(SpeedButton)
AddButtonFX(JumpButton)
AddButtonFX(ResetPlayerButton)
AddButtonFX(ResetWindowButton)


--==============================================================================
-- [SECTION 25] RESPONSIVE MOBILE
--==============================================================================

local function UpdateResponsive()

	local camera =
		workspace.CurrentCamera

	if not camera then
		return
	end


	local viewport =
		camera.ViewportSize


	local mobile =
		viewport.X <= 720


	if mobile then

		local width =
			math.max(
				300,
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
				70
			)


		Body.Position =
			UDim2.fromOffset(
				0,
				70
			)


		Body.Size =
			UDim2.new(
				1,
				0,
				1,
				-70
			)


		Subtitle.Visible = false


		Title.Position =
			UDim2.fromOffset(
				78,
				10
			)


		Title.Size =
			UDim2.new(
				1,
				-270,
				0,
				28
			)


		Title.TextSize = 18


		Controls.Size =
			UDim2.fromOffset(
				170,
				52
			)


		for _, button in ipairs(
			Controls:GetChildren()
		) do

			if button:IsA("TextButton") then

				button.Size =
					UDim2.fromOffset(
						49,
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
				-248,
				1,
				0
			)


		StatusGrid.CellSize =
			UDim2.new(
				1,
				0,
				0,
				70
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
				Config.HeaderHeight
			)


		Body.Position =
			UDim2.fromOffset(
				0,
				Config.HeaderHeight
			)


		Body.Size =
			UDim2.new(
				1,
				0,
				1,
				-Config.HeaderHeight
			)


		Subtitle.Visible = true


		Title.Position =
			UDim2.fromOffset(
				82,
				10
			)


		Title.Size =
			UDim2.new(
				1,
				-370,
				0,
				30
			)


		Title.TextSize = 22


		Controls.Size =
			UDim2.fromOffset(
				204,
				54
			)


		for _, button in ipairs(
			Controls:GetChildren()
		) do

			if button:IsA("TextButton") then

				button.Size =
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
				70
			)

	end

end


UpdateResponsive()


local camera =
	workspace.CurrentCamera


if camera then

	SafeConnect(
		camera:GetPropertyChangedSignal(
			"ViewportSize"
		),
		UpdateResponsive
	)

end


--==============================================================================
-- [SECTION 26] PARTICLES
--==============================================================================

local ParticleContainer = Create(
	"Frame",
	{
		Size = UDim2.fromScale(1, 1),

		BackgroundTransparency = 1,

		ClipsDescendants = true,

		ZIndex = 11,
	},
	Main
)


local Particles = {}


for i = 1, 14 do

	local particle = Create(
		"Frame",
		{
			Size = UDim2.fromOffset(
				math.random(1, 3),
				math.random(1, 3)
			),

			Position = UDim2.fromScale(
				math.random(),
				math.random()
			),

			BackgroundColor3 =
				GetAccent(),

			BackgroundTransparency =
				math.random(45, 80) / 100,

			BorderSizePixel = 0,

			ZIndex = 12,
		},
		ParticleContainer
	)

	AddCorner(particle, 20)

	table.insert(
		Particles,
		particle
	)

end


--==============================================================================
-- [SECTION 27] SCANLINE
--==============================================================================

local Scanline = Create(
	"Frame",
	{
		Size = UDim2.new(
			1,
			0,
			0,
			2
		),

		Position = UDim2.fromOffset(
			0,
			0
		),

		BackgroundColor3 =
			GetAccent(),

		BackgroundTransparency = 0.72,

		BorderSizePixel = 0,

		ZIndex = 400,
	},
	Main
)


--==============================================================================
-- [SECTION 28] ANIMATION ENGINE
--==============================================================================

SafeConnect(
	RunService.RenderStepped,
	function(delta)

		if State.Destroyed then
			return
		end


		State.Elapsed += delta


		-- FPS
		if delta > 0 then

			local instantFPS =
				1 / delta

			State.FPS =
				State.FPS * 0.92
				+ instantFPS * 0.08

		end


		-- Live stats update setiap ~0.5 sec
		if math.floor(State.Elapsed * 2)
			~= math.floor((State.Elapsed - delta) * 2)
		then

			State.Ping =
				GetPing()

			State.Memory =
				GetMemory()

			UpdateStatus()

		end


		-- Animation
		if Config.Animations then

			local rotation =
				(State.Elapsed * 25)
				% 360


			HeaderLogoRing.Rotation =
				rotation


			MiniRing.Rotation =
				-rotation


			local breathe =
				1
				+ math.sin(
					State.Elapsed * 2.4
				) * 0.035


			HeaderLogoText.Size =
				UDim2.fromOffset(
					40 * breathe,
					40 * breathe
				)


			MiniText.Size =
				UDim2.fromOffset(
					40 * breathe,
					40 * breathe
				)


			local pulse =
				(
					math.sin(
						State.Elapsed * 2
					)
					+ 1
				) / 2


			HeaderRingStroke.Transparency =
				0.22 - pulse * 0.12


			MiniRingStroke.Transparency =
				0.22 - pulse * 0.12


			MainStroke.Transparency =
				0.28 - pulse * 0.14

		end


		-- Scanline
		if Config.Animations
			and Config.Scanline then

			local height =
				math.max(
					1,
					Main.AbsoluteSize.Y
				)


			local y =
				(State.Elapsed * 48)
				% height


			Scanline.Position =
				UDim2.fromOffset(
					0,
					y
				)

			Scanline.Visible = true

		else

			Scanline.Visible = false

		end


		-- Particles
		if Config.Animations
			and Config.Particles then

			ParticleContainer.Visible =
				true


			for index, particle
				in ipairs(Particles) do

				local pos =
					particle.Position


				local newY =
					pos.Y.Scale
					+ delta
					* (
						0.01
						+ index * 0.00015
					)


				if newY > 1 then
					newY = 0
				end


				particle.Position =
					UDim2.fromScale(
						pos.X.Scale,
						newY
					)

			end

		else

			ParticleContainer.Visible =
				false

		end

	end
)


--==============================================================================
-- [SECTION 29] TOPMOST WATCHDOG
--==============================================================================

task.spawn(function()

	while not State.Destroyed do

		task.wait(2)


		if ScreenGui.Parent then

			ScreenGui.Enabled = true

			ScreenGui.DisplayOrder =
				Config.DisplayOrder

		end

	end

end)


--==============================================================================
-- [SECTION 30] AVATAR
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
-- [SECTION 31] PUBLIC API
--==============================================================================

_G.vanz = _G.vanz or {}


_G.vanz.Open = function()

	if State.Destroyed then
		return
	end

	ScreenGui.Enabled = true

	if not State.Minimized then
		Main.Visible = true
	end

end


_G.vanz.Minimize = function()

	if State.Destroyed then
		return
	end

	MinimizeGUI()

end


_G.vanz.Restore = function()

	if State.Destroyed then
		return
	end

	RestoreGUI()

end


_G.vanz.Close = function()

	CloseGUI()

end


_G.vanz.SetScale = function(value)

	value = tonumber(value)

	if not value then
		return
	end


	Config.Scale =
		math.clamp(
			value,
			0.65,
			1.25
		)


	GlobalScale.Scale =
		Config.Scale

end


_G.vanz.SetWalkSpeed = function(value)

	value = tonumber(value)

	if not value then
		return
	end


	ApplySpeed(value)

end


_G.vanz.SetJumpPower = function(value)

	value = tonumber(value)

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

		Destroyed =
			State.Destroyed,

	}

end


--==============================================================================
-- [SECTION 32] INITIALIZATION
--==============================================================================

UpdateStatus()

UpdateResponsive()


Main.AnchorPoint =
	Vector2.new(0.5, 0.5)

Main.Position =
	UDim2.fromScale(
		0.5,
		0.5
	)


print(
	"[VANZ] Control Center loaded successfully."
)

print(
	"[VANZ] Safe drag engine active."
)

print(
	"[VANZ] Live user status active."
)

print(
	"[VANZ] Settings system active."
)