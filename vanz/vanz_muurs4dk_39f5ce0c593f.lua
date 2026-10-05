--[[
================================================================================
 VANZ // ROBOTIC ANIME CONTROL CENTER
 FULL GUI REBUILD
================================================================================

[IMPORTANT]
- LocalScript
- Recommended location:
    StarterPlayer
        └── StarterPlayerScripts
            └── VANZ_ControlCenter

================================================================================
[MAIN STRUCTURE]

    SCREEN GUI
    │
    ├── HEADER
    │   ├── Animated VANZ Logo
    │   ├── Title
    │   ├── Settings Gear
    │   ├── Minimize
    │   └── Close
    │
    ├── HOME
    │   ├── Welcome / System Core
    │   ├── User Status
    │   ├── Movement Status
    │   ├── Character Status
    │   ├── Session Status
    │   └── Runtime Status
    │
    ├── SETTINGS
    │   ├── Appearance
    │   ├── Animation
    │   ├── Interaction
    │   ├── Window
    │   ├── Player Controls
    │   └── Reset
    │
    └── MINIMIZED LOGO
        └── Draggable / Click to Restore

================================================================================
]]

--//==============================================================
--// [SECTION 01] SERVICES
--// Semua service Roblox yang dipakai GUI
--//==============================================================

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Stats = game:GetService("Stats")
local GuiService = game:GetService("GuiService")

local LocalPlayer = Players.LocalPlayer

if not LocalPlayer then
	return
end


--//==============================================================
--// [SECTION 02] GLOBAL CONFIG
--// Pengaturan dasar GUI
--//==============================================================

_G.vanz = _G.vanz or {}

local Config = {

	Title = "VANZ",
	Subtitle = "ROBOTIC CONTROL CENTER",

	DisplayOrder = 999999999,

	DesktopWidth = 980,
	DesktopHeight = 640,

	MobileMargin = 8,

	HeaderHeight = 78,

	MinimizedLogoSize = 76,

	AnimationSpeed = 1,

	DefaultScale = 1,

	Accent = "CYAN",

	EnableAnimations = true,
	EnableParticles = true,
	EnableScanlines = true,
	EnableInteractionFX = true,

	WindowOpacity = 0.96,

	PlayerControlEnabled = true,

}

local State = {

	Destroyed = false,

	Minimized = false,

	SettingsOpen = false,

	CurrentPage = "HOME",

	DraggingWindow = false,
	DraggingLogo = false,

	DragMoved = false,

	WindowPositionInitialized = false,

	OpenedAt = os.clock(),

	FPS = 60,

	Ping = 0,

	Memory = 0,

	Hue = 0,

	Character = nil,

	Humanoid = nil,

	RootPart = nil,

}


--//==============================================================
--// [SECTION 03] CLEAN OLD VANZ GUI
--// Menghindari GUI lama numpuk
--//==============================================================

local OldNames = {
	"VANZ_ROBOTIC_GUI",
	"VANZ_PREMIUM_GUI",
	"VANZ_SOFT_ROBOTIC_GUI",
	"VANZ_CONTROL_CENTER",
}

for _, name in ipairs(OldNames) do

	local old = game:GetService("CoreGui"):FindFirstChild(name)

	if old then
		pcall(function()
			old:Destroy()
		end)
	end

	local playerGui = LocalPlayer:FindFirstChildOfClass("PlayerGui")

	if playerGui then

		local oldPlayerGui = playerGui:FindFirstChild(name)

		if oldPlayerGui then
			pcall(function()
				oldPlayerGui:Destroy()
			end)
		end

	end

end


--//==============================================================
--// [SECTION 04] COLOR SYSTEM
--// Sistem warna tema GUI
--//==============================================================

local Themes = {

	CYAN = {
		Accent = Color3.fromRGB(0, 220, 255),
		Accent2 = Color3.fromRGB(0, 140, 255),
		Accent3 = Color3.fromRGB(80, 255, 235),
	},

	VIOLET = {
		Accent = Color3.fromRGB(170, 100, 255),
		Accent2 = Color3.fromRGB(100, 70, 255),
		Accent3 = Color3.fromRGB(230, 130, 255),
	},

	MAGENTA = {
		Accent = Color3.fromRGB(255, 70, 190),
		Accent2 = Color3.fromRGB(180, 50, 255),
		Accent3 = Color3.fromRGB(255, 130, 230),
	},

	BLUE = {
		Accent = Color3.fromRGB(70, 150, 255),
		Accent2 = Color3.fromRGB(30, 80, 220),
		Accent3 = Color3.fromRGB(120, 200, 255),
	},

	GREEN = {
		Accent = Color3.fromRGB(60, 255, 170),
		Accent2 = Color3.fromRGB(20, 170, 120),
		Accent3 = Color3.fromRGB(130, 255, 210),
	},

}

local Theme = Themes[Config.Accent]


local function Accent()
	return Theme.Accent
end

local function Accent2()
	return Theme.Accent2
end

local function Accent3()
	return Theme.Accent3
end


--//==============================================================
--// [SECTION 05] UI COLORS
--// Base colors untuk panel, card, text, border
--//==============================================================

local Colors = {

	Background = Color3.fromRGB(5, 8, 14),

	Panel = Color3.fromRGB(9, 14, 23),

	Panel2 = Color3.fromRGB(12, 19, 30),

	Card = Color3.fromRGB(14, 22, 34),

	Card2 = Color3.fromRGB(17, 27, 42),

	Border = Color3.fromRGB(35, 52, 72),

	Text = Color3.fromRGB(235, 245, 255),

	SubText = Color3.fromRGB(145, 165, 185),

	Muted = Color3.fromRGB(85, 105, 125),

	Danger = Color3.fromRGB(255, 75, 95),

	Warning = Color3.fromRGB(255, 190, 75),

	Success = Color3.fromRGB(70, 255, 160),

}


--//==============================================================
--// [SECTION 06] CONNECTION MANAGER
--// Semua connection disimpan supaya bisa dibersihkan
--//==============================================================

local Connections = {}

local function Connect(signal, callback)

	local connection = signal:Connect(callback)

	table.insert(Connections, connection)

	return connection

end


local function DisconnectAll()

	for _, connection in ipairs(Connections) do

		if connection then
			pcall(function()
				connection:Disconnect()
			end)
		end

	end

	table.clear(Connections)

end


--//==============================================================
--// [SECTION 07] UTILITY FUNCTIONS
--// Fungsi kecil untuk membuat UI
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


local function Corner(parent, radius)

	return New("UICorner", {
		CornerRadius = UDim.new(0, radius),
	}, parent)

end


local function Stroke(parent, color, thickness, transparency)

	return New("UIStroke", {

		Color = color or Colors.Border,

		Thickness = thickness or 1,

		Transparency = transparency or 0,

		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,

	}, parent)

end


local function Padding(parent, left, top, right, bottom)

	return New("UIPadding", {

		PaddingLeft = UDim.new(0, left or 0),
		PaddingTop = UDim.new(0, top or 0),
		PaddingRight = UDim.new(0, right or 0),
		PaddingBottom = UDim.new(0, bottom or 0),

	}, parent)

end


local function Tween(object, info, properties)

	local tween = TweenService:Create(
		object,
		info,
		properties
	)

	tween:Play()

	return tween

end


local function MakeButton(parent, text, size, position)

	local button = New("TextButton", {

		BackgroundColor3 = Colors.Card,

		BackgroundTransparency = 0.05,

		BorderSizePixel = 0,

		Size = size,

		Position = position,

		Font = Enum.Font.GothamBold,

		Text = text,

		TextColor3 = Colors.Text,

		TextSize = 16,

		AutoButtonColor = false,

		Active = true,

	}, parent)

	Corner(button, 10)

	Stroke(button, Colors.Border, 1, 0.15)

	return button

end


--//==============================================================
--// [SECTION 08] SCREEN GUI
--// Root utama GUI
--//==============================================================

local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local ScreenGui = New("ScreenGui", {

	Name = "VANZ_CONTROL_CENTER",

	IgnoreGuiInset = true,

	ResetOnSpawn = false,

	ZIndexBehavior = Enum.ZIndexBehavior.Global,

	DisplayOrder = Config.DisplayOrder,

	Enabled = true,

}, PlayerGui)


--//==============================================================
--// [SECTION 09] UISCALE
--// Scaling seluruh GUI
--//==============================================================

local GlobalScale = New("UIScale", {

	Scale = Config.DefaultScale,

}, ScreenGui)


--//==============================================================
--// [SECTION 10] MAIN WINDOW
--// Ini adalah container utama
--//==============================================================

local MainHolder = New("Frame", {

	Name = "MainHolder",

	AnchorPoint = Vector2.new(0.5, 0.5),

	Position = UDim2.fromScale(0.5, 0.5),

	Size = UDim2.fromOffset(
		Config.DesktopWidth,
		Config.DesktopHeight
	),

	BackgroundColor3 = Colors.Background,

	BorderSizePixel = 0,

	ClipsDescendants = true,

	ZIndex = 10,

}, ScreenGui)

Corner(MainHolder, 18)

local MainStroke = Stroke(
	MainHolder,
	Accent(),
	1,
	0.15
)


--//==============================================================
--// [SECTION 11] HEADER
--// Header sengaja dibuat fixed agar tombol tidak ketutup
--//==============================================================

local Header = New("Frame", {

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

}, MainHolder)


--//==============================================================
--// [SECTION 12] HEADER DRAG ZONE
--// Hanya area ini yang boleh menarik window
--// Tombol settings/minimize/close tidak termasuk area ini
--//==============================================================

local HeaderDragZone = New("Frame", {

	Name = "HeaderDragZone",

	BackgroundTransparency = 1,

	BorderSizePixel = 0,

	Position = UDim2.fromOffset(90, 0),

	Size = UDim2.new(
		1,
		-290,
		1,
		0
	),

	Active = true,

	ZIndex = 21,

}, Header)


--//==============================================================
--// [SECTION 13] LOGO
--// Logo kecil, bukan shadow besar
--//==============================================================

local LogoFrame = New("Frame", {

	Name = "Logo",

	AnchorPoint = Vector2.new(0, 0.5),

	Position = UDim2.new(
		0,
		14,
		0.5,
		0
	),

	Size = UDim2.fromOffset(58, 58),

	BackgroundColor3 = Colors.Card,

	BorderSizePixel = 0,

	ZIndex = 25,

}, Header)

Corner(LogoFrame, 15)

Stroke(
	LogoFrame,
	Accent(),
	1,
	0.2
)


local LogoRing = New("Frame", {

	AnchorPoint = Vector2.new(0.5, 0.5),

	Position = UDim2.fromScale(0.5, 0.5),

	Size = UDim2.fromOffset(42, 42),

	BackgroundTransparency = 1,

	BorderSizePixel = 0,

	ZIndex = 26,

}, LogoFrame)

Corner(LogoRing, 100)

local LogoRingStroke = Stroke(
	LogoRing,
	Accent(),
	2,
	0.1
)


local LogoCore = New("TextLabel", {

	AnchorPoint = Vector2.new(0.5, 0.5),

	Position = UDim2.fromScale(0.5, 0.5),

	Size = UDim2.fromOffset(34, 34),

	BackgroundTransparency = 1,

	Font = Enum.Font.GothamBlack,

	Text = "V",

	TextColor3 = Accent(),

	TextSize = 26,

	ZIndex = 28,

}, LogoFrame)


--//==============================================================
--// [SECTION 14] TITLE AREA
--// Title tidak boleh masuk area tombol kanan
--//==============================================================

local TitleLabel = New("TextLabel", {

	Name = "Title",

	Position = UDim2.fromOffset(84, 10),

	Size = UDim2.new(
		1,
		-370,
		0,
		32
	),

	BackgroundTransparency = 1,

	Font = Enum.Font.GothamBlack,

	Text = Config.Title,

	TextColor3 = Colors.Text,

	TextSize = 22,

	TextXAlignment = Enum.TextXAlignment.Left,

	TextTruncate = Enum.TextTruncate.AtEnd,

	ZIndex = 25,

}, Header)


local SubtitleLabel = New("TextLabel", {

	Name = "Subtitle",

	Position = UDim2.fromOffset(85, 42),

	Size = UDim2.new(
		1,
		-370,
		0,
		20
	),

	BackgroundTransparency = 1,

	Font = Enum.Font.GothamMedium,

	Text = Config.Subtitle,

	TextColor3 = Accent(),

	TextSize = 11,

	TextXAlignment = Enum.TextXAlignment.Left,

	TextTruncate = Enum.TextTruncate.AtEnd,

	ZIndex = 25,

}, Header)


--//==============================================================
--// [SECTION 15] HEADER CONTROL ZONE
--// Ini wilayah khusus Settings / Minimize / Close
--// Tidak ada element lain boleh masuk sini
--//==============================================================

local HeaderControls = New("Frame", {

	Name = "HeaderControls",

	AnchorPoint = Vector2.new(1, 0.5),

	Position = UDim2.new(
		1,
		-8,
		0.5,
		0
	),

	Size = UDim2.fromOffset(
		206,
		56
	),

	BackgroundTransparency = 1,

	ZIndex = 50,

}, Header)


local ControlsLayout = New("UIListLayout", {

	FillDirection = Enum.FillDirection.Horizontal,

	HorizontalAlignment = Enum.HorizontalAlignment.Right,

	VerticalAlignment = Enum.VerticalAlignment.Center,

	Padding = UDim.new(0, 6),

	SortOrder = Enum.SortOrder.LayoutOrder,

}, HeaderControls)


--//==============================================================
--// [SECTION 16] SETTINGS BUTTON
--// Gear icon, bukan tulisan
--//==============================================================

local SettingsButton = MakeButton(

	HeaderControls,

	"⚙",

	UDim2.fromOffset(56, 52),

	UDim2.fromOffset(0, 0)

)

SettingsButton.LayoutOrder = 1

SettingsButton.TextSize = 25

SettingsButton.ZIndex = 55


--//==============================================================
--// [SECTION 17] MINIMIZE BUTTON
--//==============================================================

local MinimizeButton = MakeButton(

	HeaderControls,

	"—",

	UDim2.fromOffset(56, 52),

	UDim2.fromOffset(0, 0)

)

MinimizeButton.LayoutOrder = 2

MinimizeButton.TextSize = 24

MinimizeButton.ZIndex = 55


--//==============================================================
--// [SECTION 18] CLOSE BUTTON
--//==============================================================

local CloseButton = MakeButton(

	HeaderControls,

	"×",

	UDim2.fromOffset(56, 52),

	UDim2.fromOffset(0, 0)

)

CloseButton.LayoutOrder = 3

CloseButton.TextSize = 28

CloseButton.TextColor3 = Colors.Danger

CloseButton.ZIndex = 55


--//==============================================================
--// [SECTION 19] BODY
--// Semua isi Home dan Settings
--//==============================================================

local Body = New("Frame", {

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

}, MainHolder)


--//==============================================================
--// [SECTION 20] HOME PAGE
--// Halaman utama user
--//==============================================================

local HomePage = New("ScrollingFrame", {

	Name = "HomePage",

	Size = UDim2.fromScale(1, 1),

	BackgroundTransparency = 1,

	BorderSizePixel = 0,

	CanvasSize = UDim2.fromOffset(0, 0),

	AutomaticCanvasSize = Enum.AutomaticSize.Y,

	ScrollingDirection = Enum.ScrollingDirection.Y,

	ScrollBarThickness = 5,

	ScrollBarImageColor3 = Accent(),

	ElasticBehavior = Enum.ElasticBehavior.Always,

	Visible = true,

	ZIndex = 16,

}, Body)

Padding(HomePage, 16, 16, 16, 24)


local HomeLayout = New("UIListLayout", {

	FillDirection = Enum.FillDirection.Vertical,

	HorizontalAlignment = Enum.HorizontalAlignment.Center,

	SortOrder = Enum.SortOrder.LayoutOrder,

	Padding = UDim.new(0, 12),

}, HomePage)


--//==============================================================
--// [SECTION 21] HERO CARD
--// Panel pembuka Home
--//==============================================================

local HeroCard = New("Frame", {

	Name = "HeroCard",

	Size = UDim2.new(
		1,
		0,
		0,
		118
	),

	BackgroundColor3 = Colors.Panel,

	BorderSizePixel = 0,

	LayoutOrder = 1,

}, HomePage)

Corner(HeroCard, 16)

Stroke(
	HeroCard,
	Accent(),
	1,
	0.25
)


local HeroTitle = New("TextLabel", {

	Position = UDim2.fromOffset(18, 14),

	Size = UDim2.new(
		1,
		-36,
		0,
		32
	),

	BackgroundTransparency = 1,

	Font = Enum.Font.GothamBlack,

	Text = "NEURAL USER CORE",

	TextColor3 = Colors.Text,

	TextSize = 23,

	TextXAlignment = Enum.TextXAlignment.Left,

}, HeroCard)


local HeroSub = New("TextLabel", {

	Position = UDim2.fromOffset(20, 49),

	Size = UDim2.new(
		1,
		-40,
		0,
		22
	),

	BackgroundTransparency = 1,

	Font = Enum.Font.GothamMedium,

	Text = "LIVE USER TELEMETRY // REAL-TIME CHARACTER LINK",

	TextColor3 = Accent(),

	TextSize = 11,

	TextXAlignment = Enum.TextXAlignment.Left,

}, HeroCard)


local HeroStatus = New("TextLabel", {

	Position = UDim2.fromOffset(20, 76),

	Size = UDim2.new(
		1,
		-40,
		0,
		24
	),

	BackgroundTransparency = 1,

	Font = Enum.Font.GothamBold,

	Text = "● SYSTEM ONLINE",

	TextColor3 = Colors.Success,

	TextSize = 12,

	TextXAlignment = Enum.TextXAlignment.Left,

}, HeroCard)


--//==============================================================
--// [SECTION 22] USER IDENTITY CARD
--// Avatar + DisplayName + Username
--//==============================================================

local IdentityCard = New("Frame", {

	Name = "IdentityCard",

	Size = UDim2.new(
		1,
		0,
		0,
		118
	),

	BackgroundColor3 = Colors.Card,

	BorderSizePixel = 0,

	LayoutOrder = 2,

}, HomePage)

Corner(IdentityCard, 16)

Stroke(
	IdentityCard,
	Colors.Border,
	1,
	0.2
)


local AvatarImage = New("ImageLabel", {

	Name = "Avatar",

	Position = UDim2.fromOffset(16, 14),

	Size = UDim2.fromOffset(90, 90),

	BackgroundColor3 = Colors.Panel2,

	BorderSizePixel = 0,

	Image = "",

}, IdentityCard)

Corner(AvatarImage, 14)

Stroke(
	AvatarImage,
	Accent(),
	2,
	0.1
)


local IdentityTitle = New("TextLabel", {

	Position = UDim2.fromOffset(124, 17),

	Size = UDim2.new(
		1,
		-140,
		0,
		32
	),

	BackgroundTransparency = 1,

	Font = Enum.Font.GothamBlack,

	Text = LocalPlayer.DisplayName,

	TextColor3 = Colors.Text,

	TextSize = 22,

	TextXAlignment = Enum.TextXAlignment.Left,

	TextTruncate = Enum.TextTruncate.AtEnd,

}, IdentityCard)


local IdentityUsername = New("TextLabel", {

	Position = UDim2.fromOffset(125, 49),

	Size = UDim2.new(
		1,
		-145,
		0,
		22
	),

	BackgroundTransparency = 1,

	Font = Enum.Font.GothamMedium,

	Text = "@" .. LocalPlayer.Name,

	TextColor3 = Accent(),

	TextSize = 13,

	TextXAlignment = Enum.TextXAlignment.Left,

	TextTruncate = Enum.TextTruncate.AtEnd,

}, IdentityCard)


local IdentityMeta = New("TextLabel", {

	Position = UDim2.fromOffset(125, 74),

	Size = UDim2.new(
		1,
		-145,
		0,
		25
	),

	BackgroundTransparency = 1,

	Font = Enum.Font.GothamMedium,

	Text = "USER LINK // INITIALIZING",

	TextColor3 = Colors.SubText,

	TextSize = 11,

	TextXAlignment = Enum.TextXAlignment.Left,

}, IdentityCard)


--//==============================================================
--// [SECTION 23] STATUS GRID
--// Semua status user ditampilkan di sini
--//==============================================================

local StatusSection = New("Frame", {

	Name = "StatusSection",

	Size = UDim2.new(
		1,
		0,
		0,
		430
	),

	BackgroundTransparency = 1,

	LayoutOrder = 3,

}, HomePage)


local StatusGrid = New("UIGridLayout", {

	CellPadding = UDim2.fromOffset(10, 10),

	CellSize = UDim2.new(
		0.5,
		-5,
		0,
		72
	),

	SortOrder = Enum.SortOrder.LayoutOrder,

}, StatusSection)


--//==============================================================
--// [SECTION 24] STATUS CARD FACTORY
--// Membuat card status secara konsisten
--//==============================================================

local StatusCards = {}


local function CreateStatusCard(label, initialValue, order)

	local card = New("Frame", {

		Name = label:gsub("%s+", ""),

		BackgroundColor3 = Colors.Card,

		BorderSizePixel = 0,

		LayoutOrder = order or 1,

	}, StatusSection)

	Corner(card, 13)

	Stroke(
		card,
		Colors.Border,
		1,
		0.2
	)


	local accentBar = New("Frame", {

		Position = UDim2.fromOffset(0, 10),

		Size = UDim2.fromOffset(3, 52),

		BackgroundColor3 = Accent(),

		BorderSizePixel = 0,

	}, card)

	Corner(accentBar, 3)


	local title = New("TextLabel", {

		Position = UDim2.fromOffset(15, 10),

		Size = UDim2.new(
			1,
			-25,
			0,
			18
		),

		BackgroundTransparency = 1,

		Font = Enum.Font.GothamMedium,

		Text = label,

		TextColor3 = Colors.SubText,

		TextSize = 10,

		TextXAlignment = Enum.TextXAlignment.Left,

	}, card)


	local value = New("TextLabel", {

		Position = UDim2.fromOffset(15, 29),

		Size = UDim2.new(
			1,
			-25,
			0,
			30
		),

		BackgroundTransparency = 1,

		Font = Enum.Font.GothamBold,

		Text = tostring(initialValue),

		TextColor3 = Colors.Text,

		TextSize = 17,

		TextXAlignment = Enum.TextXAlignment.Left,

		TextTruncate = Enum.TextTruncate.AtEnd,

	}, card)


	StatusCards[label] = value

	return card

end


--//==============================================================
--// [SECTION 25] USER STATUS ELEMENTS
--// Banyak status sesuai permintaan
--//==============================================================

CreateStatusCard("WALK SPEED", "16", 1)

CreateStatusCard("JUMP POWER", "50", 2)

CreateStatusCard("HEALTH", "100 / 100", 3)

CreateStatusCard("HIP HEIGHT", "2", 4)

CreateStatusCard("RIG TYPE", "Unknown", 5)

CreateStatusCard("CHARACTER STATE", "Loading", 6)

CreateStatusCard("AUTO ROTATE", "ON", 7)

CreateStatusCard("PLATFORM STAND", "OFF", 8)

CreateStatusCard("MOVE VECTOR", "0, 0, 0", 9)

CreateStatusCard("POSITION", "0, 0, 0", 10)

CreateStatusCard("TEAM", "None", 11)

CreateStatusCard("ACCOUNT AGE", "0 DAYS", 12)

CreateStatusCard("USER ID", tostring(LocalPlayer.UserId), 13)

CreateStatusCard("FPS", "60", 14)

CreateStatusCard("PING", "0 ms", 15)

CreateStatusCard("MEMORY", "0 MB", 16)

CreateStatusCard("SESSION", "00:00", 17)

CreateStatusCard("DEVICE", "Detecting", 18)


--//==============================================================
--// [SECTION 26] SETTINGS PAGE
--// Semua setting GUI berada di sini
--//==============================================================

local SettingsPage = New("ScrollingFrame", {

	Name = "SettingsPage",

	Size = UDim2.fromScale(1, 1),

	BackgroundTransparency = 1,

	BorderSizePixel = 0,

	CanvasSize = UDim2.fromOffset(0, 0),

	AutomaticCanvasSize = Enum.AutomaticSize.Y,

	ScrollingDirection = Enum.ScrollingDirection.Y,

	ScrollBarThickness = 5,

	ScrollBarImageColor3 = Accent(),

	Visible = false,

	ZIndex = 30,

}, Body)

Padding(SettingsPage, 16, 16, 16, 24)


local SettingsLayout = New("UIListLayout", {

	FillDirection = Enum.FillDirection.Vertical,

	HorizontalAlignment = Enum.HorizontalAlignment.Center,

	SortOrder = Enum.SortOrder.LayoutOrder,

	Padding = UDim.new(0, 12),

}, SettingsPage)


--//==============================================================
--// [SECTION 27] SETTINGS HEADER
--//==============================================================

local SettingsHeader = New("Frame", {

	Size = UDim2.new(
		1,
		0,
		0,
		90
	),

	BackgroundColor3 = Colors.Panel,

	BorderSizePixel = 0,

	LayoutOrder = 1,

}, SettingsPage)

Corner(SettingsHeader, 16)

Stroke(
	SettingsHeader,
	Accent(),
	1,
	0.2
)


local SettingsTitle = New("TextLabel", {

	Position = UDim2.fromOffset(18, 12),

	Size = UDim2.new(
		1,
		-36,
		0,
		32
	),

	BackgroundTransparency = 1,

	Font = Enum.Font.GothamBlack,

	Text = "SYSTEM SETTINGS",

	TextColor3 = Colors.Text,

	TextSize = 23,

	TextXAlignment = Enum.TextXAlignment.Left,

}, SettingsHeader)


local SettingsSubtitle = New("TextLabel", {

	Position = UDim2.fromOffset(20, 48),

	Size = UDim2.new(
		1,
		-40,
		0,
		22
	),

	BackgroundTransparency = 1,

	Font = Enum.Font.GothamMedium,

	Text = "CUSTOMIZE YOUR VANZ INTERFACE",

	TextColor3 = Accent(),

	TextSize = 11,

	TextXAlignment = Enum.TextXAlignment.Left,

}, SettingsHeader)


--//==============================================================
--// [SECTION 28] SETTINGS CARD FACTORY
--//==============================================================

local SettingsOrder = 2


local function CreateSettingsSection(title, subtitle)

	local section = New("Frame", {

		Size = UDim2.new(
			1,
			0,
			0,
			125
		),

		BackgroundColor3 = Colors.Card,

		BorderSizePixel = 0,

		LayoutOrder = SettingsOrder,

	}, SettingsPage)

	SettingsOrder += 1

	Corner(section, 15)

	Stroke(
		section,
		Colors.Border,
		1,
		0.2
	)


	local titleLabel = New("TextLabel", {

		Position = UDim2.fromOffset(16, 12),

		Size = UDim2.new(
			1,
			-32,
			0,
			25
		),

		BackgroundTransparency = 1,

		Font = Enum.Font.GothamBlack,

		Text = title,

		TextColor3 = Colors.Text,

		TextSize = 17,

		TextXAlignment = Enum.TextXAlignment.Left,

	}, section)


	local subtitleLabel = New("TextLabel", {

		Position = UDim2.fromOffset(17, 38),

		Size = UDim2.new(
			1,
			-34,
			0,
			20
		),

		BackgroundTransparency = 1,

		Font = Enum.Font.GothamMedium,

		Text = subtitle,

		TextColor3 = Colors.SubText,

		TextSize = 10,

		TextXAlignment = Enum.TextXAlignment.Left,

	}, section)


	return section

end


--//==============================================================
--// [SECTION 29] TOGGLE FACTORY
--//==============================================================

local function CreateToggle(parent, text, y, defaultValue, callback)

	local toggle = New("TextButton", {

		Position = UDim2.fromOffset(16, y),

		Size = UDim2.new(
			1,
			-32,
			0,
			38
		),

		BackgroundColor3 = Colors.Panel2,

		BorderSizePixel = 0,

		Font = Enum.Font.GothamBold,

		Text = "",

		AutoButtonColor = false,

	}, parent)

	Corner(toggle, 9)


	local label = New("TextLabel", {

		Position = UDim2.fromOffset(12, 0),

		Size = UDim2.new(
			1,
			-75,
			1,
			0
		),

		BackgroundTransparency = 1,

		Font = Enum.Font.GothamBold,

		Text = text,

		TextColor3 = Colors.Text,

		TextSize = 12,

		TextXAlignment = Enum.TextXAlignment.Left,

	}, toggle)


	local state = defaultValue


	local stateLabel = New("TextLabel", {

		AnchorPoint = Vector2.new(1, 0.5),

		Position = UDim2.new(
			1,
			-10,
			0.5,
			0
		),

		Size = UDim2.fromOffset(45, 22),

		BackgroundTransparency = 1,

		Font = Enum.Font.GothamBlack,

		Text = state and "ON" or "OFF",

		TextColor3 = state and Accent() or Colors.Muted,

		TextSize = 10,

	}, toggle)


	local function Refresh()

		stateLabel.Text = state and "ON" or "OFF"

		stateLabel.TextColor3 =
			state and Accent()
			or Colors.Muted

		toggle.BackgroundColor3 =
			state
			and Color3.fromRGB(12, 30, 38)
			or Colors.Panel2

	end


	Connect(toggle.MouseButton1Click, function()

		state = not state

		Refresh()

		if callback then
			callback(state)
		end

	end)


	Refresh()

	return toggle

end


--//==============================================================
--// [SECTION 30] APPEARANCE SETTINGS
--//==============================================================

local AppearanceSection = CreateSettingsSection(

	"APPEARANCE",

	"Theme and visual presentation"

)

AppearanceSection.Size = UDim2.new(
	1,
	0,
	0,
	260
)


local ThemeButton = MakeButton(

	AppearanceSection,

	"THEME : " .. Config.Accent,

	UDim2.new(
		1,
		-32,
		0,
		40
	),

	UDim2.fromOffset(16, 67)

)


ThemeButton.TextSize = 13


local ThemeNames = {
	"CYAN",
	"VIOLET",
	"MAGENTA",
	"BLUE",
	"GREEN",
}

local ThemeIndex = 1


Connect(ThemeButton.MouseButton1Click, function()

	ThemeIndex += 1

	if ThemeIndex > #ThemeNames then
		ThemeIndex = 1
	end

	Config.Accent = ThemeNames[ThemeIndex]

	Theme = Themes[Config.Accent]

	ThemeButton.Text = "THEME : " .. Config.Accent

end)


local TransparencyButton = MakeButton(

	AppearanceSection,

	"WINDOW OPACITY : 96%",

	UDim2.new(
		1,
		-32,
		0,
		40
	),

	UDim2.fromOffset(16, 113)

)

TransparencyButton.TextSize = 13


Connect(TransparencyButton.MouseButton1Click, function()

	Config.WindowOpacity -= 0.05

	if Config.WindowOpacity < 0.65 then
		Config.WindowOpacity = 1
	end

	TransparencyButton.Text =
		"WINDOW OPACITY : "
		.. math.floor(Config.WindowOpacity * 100)
		.. "%"

	MainHolder.BackgroundTransparency =
		1 - Config.WindowOpacity

end)


local ScaleButton = MakeButton(

	AppearanceSection,

	"GUI SCALE : 100%",

	UDim2.new(
		1,
		-32,
		0,
		40
	),

	UDim2.fromOffset(16, 159)

)

ScaleButton.TextSize = 13


Connect(ScaleButton.MouseButton1Click, function()

	Config.DefaultScale += 0.05

	if Config.DefaultScale > 1.2 then
		Config.DefaultScale = 0.75
	end

	GlobalScale.Scale = Config.DefaultScale

	ScaleButton.Text =
		"GUI SCALE : "
		.. math.floor(Config.DefaultScale * 100)
		.. "%"

end)


--//==============================================================
--// [SECTION 31] ANIMATION SETTINGS
--//==============================================================

local AnimationSection = CreateSettingsSection(

	"ANIMATION CORE",

	"Control robotic visual motion"

)

AnimationSection.Size = UDim2.new(
	1,
	0,
	0,
	225
)


CreateToggle(

	AnimationSection,

	"Soft Animations",

	67,

	Config.EnableAnimations,

	function(value)

		Config.EnableAnimations = value

	end

)


CreateToggle(

	AnimationSection,

	"Particle System",

	109,

	Config.EnableParticles,

	function(value)

		Config.EnableParticles = value

	end

)


CreateToggle(

	AnimationSection,

	"Scanline",

	151,

	Config.EnableScanlines,

	function(value)

		Config.EnableScanlines = value

	end

)


--//==============================================================
--// [SECTION 32] INTERACTION SETTINGS
--//==============================================================

local InteractionSection = CreateSettingsSection(

	"INTERACTION",

	"Touch, hover and button feedback"

)

InteractionSection.Size = UDim2.new(
	1,
	0,
	0,
	180
)


CreateToggle(

	InteractionSection,

	"Interaction FX",

	67,

	Config.EnableInteractionFX,

	function(value)

		Config.EnableInteractionFX = value

	end

)


CreateToggle(

	InteractionSection,

	"Player Controls",

	109,

	Config.PlayerControlEnabled,

	function(value)

		Config.PlayerControlEnabled = value

	end

)


--//==============================================================
--// [SECTION 33] PLAYER CONTROL SETTINGS
--// WalkSpeed, JumpPower dll.
--//==============================================================

local PlayerSection = CreateSettingsSection(

	"PLAYER CONTROL",

	"Live character parameters"

)

PlayerSection.Size = UDim2.new(
	1,
	0,
	0,
	285
)


local SpeedButton = MakeButton(

	PlayerSection,

	"WALK SPEED : 16",

	UDim2.new(
		1,
		-32,
		0,
		42
	),

	UDim2.fromOffset(16, 67)

)

SpeedButton.TextSize = 13


local JumpButton = MakeButton(

	PlayerSection,

	"JUMP POWER : 50",

	UDim2.new(
		1,
		-32,
		0,
		42
	),

	UDim2.fromOffset(16, 116)

)

JumpButton.TextSize = 13


local ResetCharacterButton = MakeButton(

	PlayerSection,

	"RESET CHARACTER PARAMETERS",

	UDim2.new(
		1,
		-32,
		0,
		42
	),

	UDim2.fromOffset(16, 165)

)

ResetCharacterButton.TextSize = 12


local ResetWindowButton = MakeButton(

	PlayerSection,

	"RESET WINDOW POSITION",

	UDim2.new(
		1,
		-32,
		0,
		42
	),

	UDim2.fromOffset(16, 214)

)

ResetWindowButton.TextSize = 12


--//==============================================================
--// [SECTION 34] PLAYER CHARACTER TRACKING
--// Mendapatkan Humanoid / RootPart terbaru
--//==============================================================

local function RefreshCharacter()

	State.Character = LocalPlayer.Character

	if not State.Character then

		State.Humanoid = nil
		State.RootPart = nil

		return

	end


	State.Humanoid =
		State.Character:FindFirstChildOfClass("Humanoid")

	State.RootPart =
		State.Character:FindFirstChild("HumanoidRootPart")

end


RefreshCharacter()


Connect(

	LocalPlayer.CharacterAdded,

	function(character)

		State.Character = character

		State.Humanoid =
			character:WaitForChild("Humanoid", 10)

		State.RootPart =
			character:WaitForChild(
				"HumanoidRootPart",
				10
			)

	end

)


--//==============================================================
--// [SECTION 35] PLAYER CONTROL FUNCTIONS
--//==============================================================

local function SetWalkSpeed(value)

	if not Config.PlayerControlEnabled then
		return
	end

	if not State.Humanoid then
		RefreshCharacter()
	end

	if State.Humanoid then

		pcall(function()

			State.Humanoid.WalkSpeed = value

		end)

	end

end


local function SetJumpPower(value)

	if not Config.PlayerControlEnabled then
		return
	end

	if not State.Humanoid then
		RefreshCharacter()
	end

	if State.Humanoid then

		pcall(function()

			State.Humanoid.UseJumpPower = true

			State.Humanoid.JumpPower = value

		end)

	end

end


--//==============================================================
--// [SECTION 36] SPEED CONTROL
--// Setiap klik menaikkan speed
--//==============================================================

local CurrentSpeed = 16

Connect(SpeedButton.MouseButton1Click, function()

	CurrentSpeed += 4

	if CurrentSpeed > 40 then
		CurrentSpeed = 16
	end

	SetWalkSpeed(CurrentSpeed)

	SpeedButton.Text =
		"WALK SPEED : "
		.. CurrentSpeed

end)


--//==============================================================
--// [SECTION 37] JUMP CONTROL
--//==============================================================

local CurrentJump = 50

Connect(JumpButton.MouseButton1Click, function()

	CurrentJump += 10

	if CurrentJump > 100 then
		CurrentJump = 50
	end

	SetJumpPower(CurrentJump)

	JumpButton.Text =
		"JUMP POWER : "
		.. CurrentJump

end)


--//==============================================================
--// [SECTION 38] RESET CHARACTER PARAMETER
--//==============================================================

Connect(
	ResetCharacterButton.MouseButton1Click,

	function()

		CurrentSpeed = 16
		CurrentJump = 50

		SetWalkSpeed(16)
		SetJumpPower(50)

		SpeedButton.Text = "WALK SPEED : 16"

		JumpButton.Text = "JUMP POWER : 50"

	end
)


--//==============================================================
--// [SECTION 39] RESET WINDOW POSITION
--//==============================================================

Connect(
	ResetWindowButton.MouseButton1Click,

	function()

		MainHolder.AnchorPoint =
			Vector2.new(0.5, 0.5)

		MainHolder.Position =
			UDim2.fromScale(0.5, 0.5)

	end
)


--//==============================================================
--// [SECTION 40] AVATAR
--// Mengambil thumbnail Roblox user
--//==============================================================

task.spawn(function()

	local success, content = pcall(function()

		return Players:GetUserThumbnailAsync(

			LocalPlayer.UserId,

			Enum.ThumbnailType.HeadShot,

			Enum.ThumbnailSize.Size150x150

		)

	end)

	if success and content then

		AvatarImage.Image = content

	end

end)


--//==============================================================
--// [SECTION 41] DEVICE DETECTION
--//==============================================================

local function GetDeviceName()

	if UserInputService.TouchEnabled
		and not UserInputService.KeyboardEnabled then

		return "MOBILE"

	elseif UserInputService.GamepadEnabled
		and not UserInputService.KeyboardEnabled then

		return "GAMEPAD"

	elseif UserInputService.KeyboardEnabled then

		return "PC / KEYBOARD"

	end

	return "UNKNOWN"

end


--//==============================================================
--// [SECTION 42] STATUS FORMATTERS
--//==============================================================

local function FormatVector3(vector)

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

	seconds = math.max(0, math.floor(seconds))

	local hours =
		math.floor(seconds / 3600)

	local minutes =
		math.floor(
			(seconds % 3600) / 60
		)

	local secs =
		seconds % 60

	if hours > 0 then

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


--//==============================================================
--// [SECTION 43] PING
--// Mendapatkan ping menggunakan Stats
--//==============================================================

local function GetPing()

	local success, result = pcall(function()

		local network =
			Stats.Network

		local serverStats =
			network.ServerStatsItem

		local ping =
			serverStats["Data Ping"]

		return ping:GetValue()

	end)

	if success and result then
		return math.floor(result)
	end

	return 0

end


--//==============================================================
--// [SECTION 44] MEMORY
--//==============================================================

local function GetMemory()

	local success, result = pcall(function()

		return Stats:GetTotalMemoryUsageMb()

	end)

	if success then
		return math.floor(result)
	end

	return 0

end


--//==============================================================
--// [SECTION 45] UPDATE USER STATUS
--// Ini bagian penting:
--// setiap perubahan Humanoid langsung terlihat di Home
--//==============================================================

local function UpdateUserStatus()

	RefreshCharacter()

	local humanoid = State.Humanoid
	local root = State.RootPart


	if humanoid then

		StatusCards["WALK SPEED"].Text =
			string.format(
				"%.1f",
				humanoid.WalkSpeed
			)


		StatusCards["JUMP POWER"].Text =
			string.format(
				"%.1f",
				humanoid.JumpPower
			)


		StatusCards["HEALTH"].Text =
			string.format(
				"%.0f / %.0f",
				humanoid.Health,
				humanoid.MaxHealth
			)


		StatusCards["HIP HEIGHT"].Text =
			string.format(
				"%.2f",
				humanoid.HipHeight
			)


		StatusCards["RIG TYPE"].Text =
			humanoid.RigType.Name


		StatusCards["CHARACTER STATE"].Text =
			humanoid:GetState().Name


		StatusCards["AUTO ROTATE"].Text =
			humanoid.AutoRotate
			and "ON"
			or "OFF"


		StatusCards["PLATFORM STAND"].Text =
			humanoid.PlatformStand
			and "ON"
			or "OFF"


		StatusCards["MOVE VECTOR"].Text =
			FormatVector3(
				humanoid.MoveDirection
			)

	end


	if root then

		StatusCards["POSITION"].Text =
			FormatVector3(
				root.Position
			)

	end


	StatusCards["TEAM"].Text =
		LocalPlayer.Team
		and LocalPlayer.Team.Name
		or "None"


	StatusCards["ACCOUNT AGE"].Text =
		tostring(LocalPlayer.AccountAge)
		.. " DAYS"


	StatusCards["USER ID"].Text =
		tostring(LocalPlayer.UserId)


	StatusCards["FPS"].Text =
		tostring(
			math.floor(State.FPS)
		)


	StatusCards["PING"].Text =
		tostring(State.Ping)
		.. " ms"


	StatusCards["MEMORY"].Text =
		tostring(State.Memory)
		.. " MB"


	StatusCards["SESSION"].Text =
		FormatTime(
			os.clock() - State.OpenedAt
		)


	StatusCards["DEVICE"].Text =
		GetDeviceName()


end


--//==============================================================
--// [SECTION 46] DRAG ENGINE
--// FIX BUG TELEPORT
--//
--// Jangan pakai AbsolutePosition sebagai starting point.
--// Posisi awal dihitung dari UDim2 + viewport.
--// Dengan begitu saat drag pertama, window tidak loncat.
--//==============================================================

local WindowDrag = {

	Active = false,

	Input = nil,

	StartPointer = nil,

	StartCenter = nil,

	Moved = false,

}


local function GetViewport()

	local camera =
		workspace.CurrentCamera

	if camera then
		return camera.ViewportSize
	end

	return Vector2.new(
		MainHolder.AbsoluteSize.X,
		MainHolder.AbsoluteSize.Y
	)

end


local function GetUDimCenter(frame)

	local viewport = GetViewport()

	local x =
		frame.Position.X.Scale * viewport.X
		+ frame.Position.X.Offset

	local y =
		frame.Position.Y.Scale * viewport.Y
		+ frame.Position.Y.Offset

	return Vector2.new(x, y)

end


local function ClampWindowCenter(center)

	local viewport = GetViewport()

	local halfX =
		MainHolder.AbsoluteSize.X / 2

	local halfY =
		MainHolder.AbsoluteSize.Y / 2


	local margin = 4


	local minX =
		halfX + margin

	local maxX =
		viewport.X - halfX - margin

	local minY =
		halfY + margin

	local maxY =
		viewport.Y - halfY - margin


	if maxX < minX then

		minX =
			viewport.X / 2

		maxX =
			minX

	end


	if maxY < minY then

		minY =
			viewport.Y / 2

		maxY =
			minY

	end


	return Vector2.new(

		math.clamp(
			center.X,
			minX,
			maxX
		),

		math.clamp(
			center.Y,
			minY,
			maxY
		)

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

	WindowDrag.Input = input

	WindowDrag.StartPointer =
		Vector2.new(
			input.Position.X,
			input.Position.Y
		)

	-- IMPORTANT:
	-- Mengambil posisi dari UDim2.
	-- Bukan AbsolutePosition.
	-- Ini mencegah teleport saat drag pertama.
	WindowDrag.StartCenter =
		GetUDimCenter(MainHolder)

	WindowDrag.Moved = false

	State.DraggingWindow = true

end


local function UpdateWindowDrag(input)

	if not WindowDrag.Active then
		return
	end

	local currentPointer =
		Vector2.new(
			input.Position.X,
			input.Position.Y
		)


	local delta =
		currentPointer
		- WindowDrag.StartPointer


	if delta.Magnitude > 3 then
		WindowDrag.Moved = true
	end


	local newCenter =
		WindowDrag.StartCenter
		+ delta


	newCenter =
		ClampWindowCenter(
			newCenter
		)


	MainHolder.Position =
		UDim2.fromOffset(
			newCenter.X,
			newCenter.Y
		)

	MainHolder.AnchorPoint =
		Vector2.new(0.5, 0.5)

end


local function EndWindowDrag()

	WindowDrag.Active = false

	WindowDrag.Input = nil

	WindowDrag.StartPointer = nil

	WindowDrag.StartCenter = nil

	State.DraggingWindow = false

end


--//==============================================================
--// [SECTION 47] HEADER DRAG EVENTS
--//==============================================================

Connect(
	HeaderDragZone.InputBegan,

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

			UpdateWindowDrag(input)

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

			EndWindowDrag()

		end

	end
)


--//==============================================================
--// [SECTION 48] MINIMIZED LOGO
--// Tidak ada blue shadow/aura.
--// Hanya logo dengan animasi internal.
--//==============================================================

local MinimizedLogo = New("Frame", {

	Name = "MinimizedLogo",

	AnchorPoint = Vector2.new(0.5, 0.5),

	Position = UDim2.fromScale(
		0.5,
		0.5
	),

	Size = UDim2.fromOffset(
		Config.MinimizedLogoSize,
		Config.MinimizedLogoSize
	),

	BackgroundColor3 = Colors.Panel,

	BorderSizePixel = 0,

	Visible = false,

	Active = true,

	ZIndex = 500,

}, ScreenGui)

Corner(MinimizedLogo, 18)

Stroke(
	MinimizedLogo,
	Accent(),
	1,
	0.15
)


local MiniRing = New("Frame", {

	AnchorPoint = Vector2.new(0.5, 0.5),

	Position = UDim2.fromScale(0.5, 0.5),

	Size = UDim2.fromOffset(52, 52),

	BackgroundTransparency = 1,

	BorderSizePixel = 0,

	ZIndex = 501,

}, MinimizedLogo)

Corner(MiniRing, 100)

local MiniRingStroke = Stroke(
	MiniRing,
	Accent(),
	2,
	0.1
)


local MiniCore = New("TextLabel", {

	AnchorPoint = Vector2.new(0.5, 0.5),

	Position = UDim2.fromScale(0.5, 0.5),

	Size = UDim2.fromOffset(40, 40),

	BackgroundTransparency = 1,

	Font = Enum.Font.GothamBlack,

	Text = "V",

	TextColor3 = Accent(),

	TextSize = 30,

	ZIndex = 503,

}, MinimizedLogo)


--//==============================================================
--// [SECTION 49] MINIMIZED LOGO DRAG ENGINE
--// Ini juga memakai delta supaya tidak teleport.
--//==============================================================

local LogoDrag = {

	Active = false,

	StartPointer = nil,

	StartCenter = nil,

	Moved = false,

}


local function GetLogoCenter()

	local viewport = GetViewport()

	local x =
		MinimizedLogo.Position.X.Scale * viewport.X
		+ MinimizedLogo.Position.X.Offset

	local y =
		MinimizedLogo.Position.Y.Scale * viewport.Y
		+ MinimizedLogo.Position.Y.Offset

	return Vector2.new(x, y)

end


local function ClampLogoCenter(center)

	local viewport = GetViewport()

	local half =
		MinimizedLogo.AbsoluteSize.X / 2

	local margin = 4


	return Vector2.new(

		math.clamp(
			center.X,
			half + margin,
			viewport.X - half - margin
		),

		math.clamp(
			center.Y,
			half + margin,
			viewport.Y - half - margin
		)

	)

end


Connect(
	MinimizedLogo.InputBegan,

	function(input)

		if
			input.UserInputType
			== Enum.UserInputType.MouseButton1
			or
			input.UserInputType
			== Enum.UserInputType.Touch
		then

			LogoDrag.Active = true

			LogoDrag.StartPointer =
				Vector2.new(
					input.Position.X,
					input.Position.Y
				)

			-- FIX:
			-- Posisi awal dihitung dari UDim2,
			-- bukan AbsolutePosition.
			LogoDrag.StartCenter =
				GetLogoCenter()

			LogoDrag.Moved = false

		end

	end
)


Connect(
	UserInputService.InputChanged,

	function(input)

		if not LogoDrag.Active then
			return
		end

		if
			input.UserInputType
			== Enum.UserInputType.MouseMovement
			or
			input.UserInputType
			== Enum.UserInputType.Touch
		then

			local current =
				Vector2.new(
					input.Position.X,
					input.Position.Y
				)


			local delta =
				current
				- LogoDrag.StartPointer


			if delta.Magnitude > 8 then
				LogoDrag.Moved = true
			end


			local center =
				LogoDrag.StartCenter
				+ delta


			center =
				ClampLogoCenter(
					center
				)


			MinimizedLogo.Position =
				UDim2.fromOffset(
					center.X,
					center.Y
				)

			MinimizedLogo.AnchorPoint =
				Vector2.new(0.5, 0.5)

		end

	end
)


Connect(
	UserInputService.InputEnded,

	function(input)

		if not LogoDrag.Active then
			return
		end

		if
			input.UserInputType
			== Enum.UserInputType.MouseButton1
			or
			input.UserInputType
			== Enum.UserInputType.Touch
		then

			local shouldRestore =
				not LogoDrag.Moved


			LogoDrag.Active = false

			LogoDrag.StartPointer = nil

			LogoDrag.StartCenter = nil


			-- Tap = restore.
			-- Drag = tetap di posisi baru.
			if shouldRestore then

				MinimizedLogo.Visible = false

				MainHolder.Visible = true

				State.Minimized = false

			end

		end

	end
)


--//==============================================================
--// [SECTION 50] MINIMIZE FUNCTION
--//==============================================================

local function MinimizeGUI()

	if State.Minimized then
		return
	end


	State.Minimized = true

	State.SettingsOpen = false

	MainHolder.Visible = false

	MinimizedLogo.Visible = true

	-- Selalu mulai dari tengah ketika minimize.
	-- User tetap bisa drag setelahnya.
	MinimizedLogo.Position =
		UDim2.fromScale(
			0.5,
			0.5
		)

end


--//==============================================================
--// [SECTION 51] RESTORE FUNCTION
--//==============================================================

local function RestoreGUI()

	if not State.Minimized then
		return
	end


	State.Minimized = false

	MinimizedLogo.Visible = false

	MainHolder.Visible = true

end


--//==============================================================
--// [SECTION 52] SETTINGS OPEN/CLOSE
--//==============================================================

local function OpenSettings()

	State.SettingsOpen = true

	HomePage.Visible = false

	SettingsPage.Visible = true

end


local function CloseSettings()

	State.SettingsOpen = false

	SettingsPage.Visible = false

	HomePage.Visible = true

end


--//==============================================================
--// [SECTION 53] SETTINGS BUTTON EVENT
--//==============================================================

Connect(
	SettingsButton.MouseButton1Click,

	function()

		if State.SettingsOpen then

			CloseSettings()

		else

			OpenSettings()

		end

	end
)


--//==============================================================
--// [SECTION 54] MINIMIZE BUTTON EVENT
--//==============================================================

Connect(
	MinimizeButton.MouseButton1Click,

	function()

		MinimizeGUI()

	end
)


--//==============================================================
--// [SECTION 55] CLOSE BUTTON EVENT
--//==============================================================

local function CloseGUI()

	if State.Destroyed then
		return
	end

	State.Destroyed = true

	DisconnectAll()

	if ScreenGui then

		pcall(function()
			ScreenGui:Destroy()
		end)

	end

	_G.vanz = nil

end


Connect(
	CloseButton.MouseButton1Click,
	function()
		CloseGUI()
	end
)


--//==============================================================
--// [SECTION 56] BUTTON INTERACTION FX
--// Hover / press dibuat ringan
--//==============================================================

local function SetupButtonFX(button)

	local originalSize =
		button.Size


	Connect(
		button.MouseEnter,

		function()

			if not Config.EnableInteractionFX then
				return
			end

			Tween(
				button,
				TweenInfo.new(
					0.12,
					Enum.EasingStyle.Quint,
					Enum.EasingDirection.Out
				),
				{
					BackgroundColor3 =
						Color3.fromRGB(
							20,
							32,
							48
						)
				}
			)

		end
	)


	Connect(
		button.MouseLeave,

		function()

			if not Config.EnableInteractionFX then
				return
			end

			Tween(
				button,
				TweenInfo.new(
					0.15,
					Enum.EasingStyle.Quint,
					Enum.EasingDirection.Out
				),
				{
					BackgroundColor3 =
						Colors.Card
				}
			)

		end
	)


	Connect(
		button.MouseButton1Down,

		function()

			if not Config.EnableInteractionFX then
				return
			end

			Tween(
				button,
				TweenInfo.new(
					0.07,
					Enum.EasingStyle.Quint,
					Enum.EasingDirection.Out
				),
				{
					Size =
						UDim2.new(
							originalSize.X.Scale,
							originalSize.X.Offset - 2,
							originalSize.Y.Scale,
							originalSize.Y.Offset - 2
						)
				}
			)

		end
	)


	Connect(
		button.MouseButton1Up,

		function()

			Tween(
				button,
				TweenInfo.new(
					0.1,
					Enum.EasingStyle.Back,
					Enum.EasingDirection.Out
				),
				{
					Size = originalSize
				}
			)

		end
	)

end


SetupButtonFX(SettingsButton)
SetupButtonFX(MinimizeButton)
SetupButtonFX(CloseButton)

SetupButtonFX(ThemeButton)
SetupButtonFX(TransparencyButton)
SetupButtonFX(ScaleButton)
SetupButtonFX(SpeedButton)
SetupButtonFX(JumpButton)
SetupButtonFX(ResetCharacterButton)
SetupButtonFX(ResetWindowButton)


--//==============================================================
--// [SECTION 57] SCANLINE
--// Efek robotic bergerak secara vertikal
--//==============================================================

local Scanline = New("Frame", {

	Name = "Scanline",

	Size = UDim2.new(
		1,
		0,
		0,
		2
	),

	Position = UDim2.new(
		0,
		0,
		0,
		0
	),

	BackgroundColor3 = Accent(),

	BackgroundTransparency = 0.7,

	BorderSizePixel = 0,

	ZIndex = 400,

}, MainHolder)


--//==============================================================
--// [SECTION 58] PARTICLE SYSTEM
--// Partikel kecil di dalam GUI
--//==============================================================

local ParticleContainer = New("Frame", {

	Name = "Particles",

	Size = UDim2.fromScale(1, 1),

	BackgroundTransparency = 1,

	ClipsDescendants = true,

	ZIndex = 12,

}, MainHolder)


local Particles = {}


for i = 1, 18 do

	local particle = New("Frame", {

		Size = UDim2.fromOffset(
			math.random(1, 3),
			math.random(1, 3)
		),

		Position = UDim2.fromScale(
			math.random(),
			math.random()
		),

		BackgroundColor3 = Accent(),

		BackgroundTransparency =
			math.random(30, 75) / 100,

		BorderSizePixel = 0,

		ZIndex = 13,

	}, ParticleContainer)

	Corner(particle, 10)

	table.insert(
		Particles,
		particle
	)

end


--//==============================================================
--// [SECTION 59] RESPONSIVE MOBILE SYSTEM
--// Ini memastikan GUI tidak overflow di HP
--//==============================================================

local function UpdateResponsive()

	local viewport =
		GetViewport()


	local isMobile =
		viewport.X <= 720


	if isMobile then

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


		MainHolder.Size =
			UDim2.fromOffset(
				width,
				height
			)


		Header.Size =
			UDim2.new(
				1,
				0,
				0,
				72
			)


		TitleLabel.Position =
			UDim2.fromOffset(
				78,
				10
			)


		TitleLabel.Size =
			UDim2.new(
				1,
				-286,
				0,
				28
			)


		TitleLabel.TextSize = 18


		SubtitleLabel.Visible = false


		HeaderControls.Size =
			UDim2.fromOffset(
				174,
				52
			)


		SettingsButton.Size =
			UDim2.fromOffset(
				50,
				48
			)


		MinimizeButton.Size =
			UDim2.fromOffset(
				50,
				48
			)


		CloseButton.Size =
			UDim2.fromOffset(
				50,
				48
			)


		HeaderDragZone.Position =
			UDim2.fromOffset(
				74,
				0
			)


		HeaderDragZone.Size =
			UDim2.new(
				1,
				-260,
				1,
				0
			)


		Body.Position =
			UDim2.fromOffset(
				0,
				72
			)


		Body.Size =
			UDim2.new(
				1,
				0,
				1,
				-72
			)


		StatusGrid.CellSize =
			UDim2.new(
				1,
				0,
				0,
				72
			)


	else

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
				Config.HeaderHeight
			)


		TitleLabel.Position =
			UDim2.fromOffset(
				84,
				10
			)


		TitleLabel.Size =
			UDim2.new(
				1,
				-370,
				0,
				32
			)


		TitleLabel.TextSize = 22


		SubtitleLabel.Visible = true


		HeaderControls.Size =
			UDim2.fromOffset(
				206,
				56
			)


		SettingsButton.Size =
			UDim2.fromOffset(
				56,
				52
			)


		MinimizeButton.Size =
			UDim2.fromOffset(
				56,
				52
			)


		CloseButton.Size =
			UDim2.fromOffset(
				56,
				52
			)


		HeaderDragZone.Position =
			UDim2.fromOffset(
				90,
				0
			)


		HeaderDragZone.Size =
			UDim2.new(
				1,
				-290,
				1,
				0
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


--//==============================================================
--// [SECTION 60] VIEWPORT CHANGE
--// Saat HP rotate / ukuran berubah
--//==============================================================

local Camera = workspace.CurrentCamera

if Camera then

	Connect(
		Camera:GetPropertyChangedSignal(
			"ViewportSize"
		),

		function()

			UpdateResponsive()

		end
	)

end


--//==============================================================
--// [SECTION 61] TOPMOST WATCHDOG
--// Menjaga GUI tetap enabled dan order tinggi.
//// Tidak berarti GUI bisa mengalahkan UI sistem Roblox.
--//==============================================================

task.spawn(function()

	while not State.Destroyed do

		task.wait(2)

		if ScreenGui.Parent then

			ScreenGui.Enabled = true

			ScreenGui.DisplayOrder =
				Config.DisplayOrder

			ScreenGui.IgnoreGuiInset = true

		end

	end

end)


--//==============================================================
--// [SECTION 62] ANIMATION ENGINE
--// Satu RenderStepped untuk animation supaya lebih ringan
--//==============================================================

local elapsed = 0

local fpsAccumulator = 0

local fpsFrames = 0

local lastScan = 0


Connect(
	RunService.RenderStepped,

	function(delta)

		if State.Destroyed then
			return
		end


		elapsed += delta


		--==========================================================
		-- FPS CALCULATION
		--==========================================================

		fpsAccumulator += delta

		fpsFrames += 1


		if fpsAccumulator >= 0.5 then

			State.FPS =
				fpsFrames
				/ fpsAccumulator

			fpsAccumulator = 0

			fpsFrames = 0

		end


		--==========================================================
		-- LIVE NETWORK / MEMORY
		--==========================================================

		if elapsed - lastScan >= 1 then

			lastScan = elapsed

			State.Ping = GetPing()

			State.Memory = GetMemory()

			UpdateUserStatus()

		end


		--==========================================================
		-- LOGO ANIMATION
		--==========================================================

		if Config.EnableAnimations then

			local rotation =
				(elapsed * 22)
				% 360


			LogoRing.Rotation =
				rotation


			MiniRing.Rotation =
				-rotation


			local breathe =
				1
				+ math.sin(
					elapsed * 2.4
				)
				* 0.04


			LogoCore.Size =
				UDim2.fromOffset(
					34 * breathe,
					34 * breathe
				)


			MiniCore.Size =
				UDim2.fromOffset(
					40 * breathe,
					40 * breathe
				)


			local alpha =
				0.08
				+ (
					math.sin(
						elapsed * 3
					) + 1
				)
				* 0.06


			LogoRingStroke.Transparency =
				alpha


			MiniRingStroke.Transparency =
				alpha

		end


		--==========================================================
		-- SCANLINE
		--==========================================================

		if Config.EnableAnimations
			and Config.EnableScanlines then

			local y =
				(elapsed * 45)
				% math.max(
					1,
					MainHolder.AbsoluteSize.Y
				)


			Scanline.Position =
				UDim2.fromOffset(
					0,
					y
				)

			Scanline.Visible = true

		else

			Scanline.Visible = false

		end


		--==========================================================
		-- PARTICLES
		--==========================================================

		if Config.EnableParticles
			and Config.EnableAnimations then

			for index, particle
				in ipairs(Particles) do

				local seed =
					index * 1.73

				local x =
					(
						particle.Position.X.Scale
						+ delta
						* (
							0.006
							+ (
								seed
								% 0.004
							)
						)
					)
					% 1


				local y =
					particle.Position.Y.Scale
					+ math.sin(
						elapsed
						+ seed
					)
					* delta
					* 0.015


				if y > 1 then
					y = 0
				elseif y < 0 then
					y = 1
				end


				particle.Position =
					UDim2.fromScale(
						x,
						y
					)

			end

			ParticleContainer.Visible = true

		else

			ParticleContainer.Visible = false

		end


		--==========================================================
		-- ACCENT BREATHING
		--==========================================================

		if Config.EnableAnimations then

			local pulse =
				(
					math.sin(
						elapsed * 1.8
					)
					+ 1
				) / 2


			MainStroke.Transparency =
				0.28
				- pulse * 0.18

		end

	end
)


--//==============================================================
--// [SECTION 63] INITIAL STATUS UPDATE
--//==============================================================

UpdateUserStatus()


--//==============================================================
--// [SECTION 64] PUBLIC API
--// Bisa dipanggil dari script lain
--//==============================================================

_G.vanz.Open = function()

	if State.Destroyed then
		return
	end

	ScreenGui.Enabled = true

	MainHolder.Visible =
		not State.Minimized

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


_G.vanz.SetScale = function(scale)

	scale = tonumber(scale)

	if not scale then
		return
	end

	Config.DefaultScale =
		math.clamp(
			scale,
			0.65,
			1.25
		)

	GlobalScale.Scale =
		Config.DefaultScale

end


_G.vanz.GetState = function()

	return {

		Minimized =
			State.Minimized,

		SettingsOpen =
			State.SettingsOpen,

		CurrentPage =
			State.CurrentPage,

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


_G.vanz.SetWalkSpeed = function(value)

	value = tonumber(value)

	if not value then
		return
	end

	CurrentSpeed = value

	SetWalkSpeed(value)

end


_G.vanz.SetJumpPower = function(value)

	value = tonumber(value)

	if not value then
		return
	end

	CurrentJump = value

	SetJumpPower(value)

end


--//==============================================================
--// [SECTION 65] FINAL MOBILE SAFETY
--// Pastikan window tidak lahir di luar viewport
--//==============================================================

task.defer(function()

	task.wait()

	UpdateResponsive()

	MainHolder.AnchorPoint =
		Vector2.new(0.5, 0.5)

	MainHolder.Position =
		UDim2.fromScale(
			0.5,
			0.5
		)

end)


--//==============================================================
--// [SECTION 66] STARTUP ANIMATION
--// Animasi masuk yang halus
--//==============================================================

MainHolder.Visible = true

if Config.EnableAnimations then

	MainHolder.Size =
		UDim2.fromOffset(
			Config.DesktopWidth * 0.92,
			Config.DesktopHeight * 0.92
		)

	Tween(

		MainHolder,

		TweenInfo.new(
			0.55,
			Enum.EasingStyle.Quint,
			Enum.EasingDirection.Out
		),

		{
			Size =
				UDim2.fromOffset(
					Config.DesktopWidth,
					Config.DesktopHeight
				)
		}

	)

end


--//==============================================================
--// [SECTION 67] READY
--//==============================================================

print(
	"[VANZ] Robotic Control Center initialized."
)

print(
	"[VANZ] Home + Settings architecture loaded."
)

print(
	"[VANZ] Drag engine initialized without AbsolutePosition teleport."
)

print(
	"[VANZ] Live user telemetry online."
)