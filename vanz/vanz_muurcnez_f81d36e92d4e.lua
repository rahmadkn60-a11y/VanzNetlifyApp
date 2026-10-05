--[[
================================================================================
 VANZ NEXUS // ROBOTIC ANIME COMMAND CENTER
 Full LocalScript
================================================================================

 FITUR UTAMA:
 • Responsive desktop + mobile
 • Minimize / Close selalu punya zona eksklusif
 • Main GUI draggable
 • Minimized logo draggable
 • Fix bug "drag pertama teleport ke kiri atas"
 • Minimized logo kecil dan tanpa outer blue shadow
 • Logo punya animasi internal: core, ring, scanline, orbit
 • Tab: HOME / VISUALS / TELEMETRY / NEXUS / ABOUT
 • Mobile memakai bottom navigation
 • Tombol besar dan mudah disentuh
 • Animasi smooth dan ringan
 • FPS / Ping / Memory / Uptime telemetry
 • Watchdog menjaga GUI tetap aktif
 • Cleanup + public API
 • Komentar dibuat seperti pseudo-code agar mudah diedit

 CATATAN:
 GUI Roblox tidak bisa dijamin selalu berada di atas CoreGui / UI sistem Roblox.
 Script ini menggunakan DisplayOrder tinggi, Global ZIndex, dan watchdog untuk
 menjaga GUI custom ini berada di layer paling atas di antara GUI custom.
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
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

--==============================================================================
-- [SECTION 02] CONFIGURATION
--==============================================================================

local CONFIG = {

	-- Nama internal GUI
	GuiName = "VANZ_NEXUS_ROBOTIC_ANIME",

	-- Judul
	Title = "VANZ NEXUS",
	Subtitle = "ROBOTIC // ANIME COMMAND CENTER",

	-- Warna utama
	Colors = {
		Background = Color3.fromRGB(5, 7, 14),
		Panel = Color3.fromRGB(9, 12, 23),
		Panel2 = Color3.fromRGB(12, 16, 30),
		Panel3 = Color3.fromRGB(17, 21, 38),

		Cyan = Color3.fromRGB(54, 235, 255),
		Blue = Color3.fromRGB(75, 130, 255),
		Violet = Color3.fromRGB(163, 91, 255),
		Pink = Color3.fromRGB(255, 86, 191),

		White = Color3.fromRGB(238, 247, 255),
		SoftWhite = Color3.fromRGB(175, 192, 212),
		Muted = Color3.fromRGB(91, 108, 133),

		Success = Color3.fromRGB(67, 255, 171),
		Warning = Color3.fromRGB(255, 194, 75),
		Danger = Color3.fromRGB(255, 75, 108),
	},

	-- Ukuran desktop
	DesktopWidth = 980,
	DesktopHeight = 630,

	-- Ukuran sidebar desktop
	SidebarWidth = 195,

	-- Safe margin mobile
	MobileMargin = 6,

	-- Tinggi header
	HeaderHeight = 82,

	-- Tinggi bottom navigation mobile
	MobileNavHeight = 70,

	-- Ukuran touch button
	MinTouchSize = 48,

	-- DisplayOrder tinggi untuk custom GUI
	DisplayOrder = 999999999,

	-- Kecepatan animasi
	AnimationSpeed = 1,

	-- Efek
	EnableParticles = true,
	EnableRadar = true,
	EnableTelemetry = true,

	-- Mobile breakpoint
	MobileWidth = 760,
	MobileHeight = 560,
}

--==============================================================================
-- [SECTION 03] STATE
--==============================================================================

local State = {

	Destroyed = false,

	Mobile = false,

	Minimized = false,

	Closed = false,

	CurrentTab = "HOME",

	FPS = 0,

	Ping = "--",

	Memory = "--",

	Uptime = 0,

	Hue = 0,

	AnimationTime = 0,

	DraggingMain = false,

	DraggingMini = false,

	DragMovedMain = false,

	DragMovedMini = false,

	MainDragInput = nil,

	MiniDragInput = nil,

	MainDragStartPointer = nil,

	MainDragStartAbsolute = nil,

	MiniDragStartPointer = nil,

	MiniDragStartAbsolute = nil,

	MainOriginalPosition = nil,

	MiniOriginalPosition = nil,
}

--==============================================================================
-- [SECTION 04] CONNECTION MANAGER
--==============================================================================

local Connections = {}

local function Connect(signal, callback)
	local connection = signal:Connect(callback)
	table.insert(Connections, connection)
	return connection
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
-- [SECTION 05] OLD GUI CLEANUP
--==============================================================================

for _, child in ipairs(PlayerGui:GetChildren()) do
	if child:IsA("ScreenGui") then

		if child.Name == CONFIG.GuiName
			or child.Name == "VANZ_ROBOTIC_GUI"
			or child.Name == "VANZ_PREMIUM_GUI"
			or child.Name == "VANZ_SOFT_ROBOTIC_GUI"
			or child.Name == "VANZ_NEXUS_GUI" then

			pcall(function()
				child:Destroy()
			end)
		end
	end
end

--==============================================================================
-- [SECTION 06] GENERIC UI HELPERS
--==============================================================================

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
		CornerRadius = UDim.new(0, radius or 10)
	}, parent)
end

local function Stroke(parent, color, transparency, thickness)
	return New("UIStroke", {
		Color = color or CONFIG.Colors.Cyan,
		Transparency = transparency or 0,
		Thickness = thickness or 1,
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

local function Tween(object, duration, properties, style, direction)
	if not object then
		return
	end

	local info = TweenInfo.new(
		duration or 0.25,
		style or Enum.EasingStyle.Quint,
		direction or Enum.EasingDirection.Out
	)

	local tween = TweenService:Create(object, info, properties)
	tween:Play()

	return tween
end

local function SetText(label, text)
	if label and label:IsA("TextLabel") then
		label.Text = tostring(text)
	end
end

--==============================================================================
-- [SECTION 07] ROOT SCREEN GUI
--==============================================================================
-- PSEUDO:
-- 1. Buat ScreenGui.
-- 2. IgnoreGuiInset agar layout menggunakan seluruh viewport.
-- 3. DisplayOrder tinggi agar berada di atas custom GUI lain.
-- 4. Global ZIndex supaya layering predictable.
--==============================================================================

local ScreenGui = New("ScreenGui", {
	Name = CONFIG.GuiName,
	IgnoreGuiInset = true,
	ResetOnSpawn = false,
	ZIndexBehavior = Enum.ZIndexBehavior.Global,
	DisplayOrder = CONFIG.DisplayOrder,
	Enabled = true,
}, PlayerGui)

-- Coba property tambahan kalau tersedia pada versi Roblox tertentu.
pcall(function()
	ScreenGui.ScreenInsets = Enum.ScreenInsets.None
end)

--==============================================================================
-- [SECTION 08] MAIN WINDOW ROOT
--==============================================================================

local MainHolder = New("Frame", {
	Name = "MainHolder",

	AnchorPoint = Vector2.new(0.5, 0.5),

	Position = UDim2.fromScale(0.5, 0.5),

	Size = UDim2.fromOffset(
		CONFIG.DesktopWidth,
		CONFIG.DesktopHeight
	),

	BackgroundTransparency = 1,

	BorderSizePixel = 0,

	ZIndex = 100,
}, ScreenGui)

-- Scale dipakai hanya untuk animasi open/close,
-- bukan untuk memaksa layout mobile.
local MainScale = New("UIScale", {
	Scale = 1,
}, MainHolder)

--==============================================================================
-- [SECTION 09] WINDOW BACKGROUND
--==============================================================================

local Window = New("Frame", {
	Name = "Window",

	Size = UDim2.fromScale(1, 1),

	BackgroundColor3 = CONFIG.Colors.Background,

	BorderSizePixel = 0,

	ZIndex = 100,
}, MainHolder)

Corner(Window, 16)
Stroke(Window, Color3.fromRGB(50, 78, 125), 0.25, 1)

-- Gradient background
local WindowGradient = Gradient(Window, {
	ColorSequenceKeypoint.new(0, Color3.fromRGB(5, 8, 17)),
	ColorSequenceKeypoint.new(0.45, Color3.fromRGB(8, 12, 24)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(11, 7, 25)),
}, 135)

--==============================================================================
-- [SECTION 10] INTERNAL BORDER / HOLOGRAM LINES
--==============================================================================

local InnerBorder = New("Frame", {
	Name = "InnerBorder",

	Position = UDim2.fromOffset(2, 2),

	Size = UDim2.new(1, -4, 1, -4),

	BackgroundTransparency = 1,

	BorderSizePixel = 0,

	ZIndex = 101,
}, Window)

Corner(InnerBorder, 15)
Stroke(InnerBorder, CONFIG.Colors.Cyan, 0.82, 1)

-- Top holographic line
local TopLine = New("Frame", {
	Name = "TopHolographicLine",

	Position = UDim2.fromOffset(0, 0),

	Size = UDim2.new(1, 0, 0, 2),

	BackgroundColor3 = CONFIG.Colors.Cyan,

	BackgroundTransparency = 0.15,

	BorderSizePixel = 0,

	ZIndex = 200,
}, Window)

--==============================================================================
-- [SECTION 11] HEADER
--==============================================================================
-- HEADER DIBAGI MENJADI 3 ZONA:
--
-- [LEFT]   Logo
-- [CENTER] Title + subtitle
-- [RIGHT]  Minimize + Close
--
-- PENTING:
-- Tidak ada element lain yang boleh masuk ke zona RIGHT.
-- Jadi tombol Minimize/Close tidak akan ketiban title/status.
--==============================================================================

local Header = New("Frame", {
	Name = "Header",

	Position = UDim2.fromOffset(0, 0),

	Size = UDim2.new(1, 0, 0, CONFIG.HeaderHeight),

	BackgroundTransparency = 1,

	BorderSizePixel = 0,

	ZIndex = 150,
}, Window)

--==============================================================================
-- [SECTION 12] HEADER LEFT / LOGO ZONE
--==============================================================================

local HeaderLogoZone = New("Frame", {
	Name = "HeaderLogoZone",

	Position = UDim2.fromOffset(10, 8),

	Size = UDim2.fromOffset(68, 66),

	BackgroundTransparency = 1,

	BorderSizePixel = 0,

	ZIndex = 160,
}, Header)

-- Logo outer plate
local LogoPlate = New("Frame", {
	Name = "LogoPlate",

	AnchorPoint = Vector2.new(0.5, 0.5),

	Position = UDim2.fromScale(0.5, 0.5),

	Size = UDim2.fromOffset(58, 58),

	BackgroundColor3 = CONFIG.Colors.Panel3,

	BackgroundTransparency = 0.05,

	BorderSizePixel = 0,

	ZIndex = 161,
}, HeaderLogoZone)

Corner(LogoPlate, 16)
Stroke(LogoPlate, CONFIG.Colors.Cyan, 0.38, 1)

-- Logo ring
local LogoRing = New("Frame", {
	Name = "LogoRing",

	AnchorPoint = Vector2.new(0.5, 0.5),

	Position = UDim2.fromScale(0.5, 0.5),

	Size = UDim2.fromOffset(42, 42),

	BackgroundTransparency = 1,

	BorderSizePixel = 0,

	ZIndex = 162,
}, LogoPlate)

Corner(LogoRing, 100)
Stroke(LogoRing, CONFIG.Colors.Cyan, 0.15, 2)

-- Logo inner ring
local LogoInnerRing = New("Frame", {
	Name = "LogoInnerRing",

	AnchorPoint = Vector2.new(0.5, 0.5),

	Position = UDim2.fromScale(0.5, 0.5),

	Size = UDim2.fromOffset(28, 28),

	BackgroundTransparency = 1,

	BorderSizePixel = 0,

	ZIndex = 163,
}, LogoPlate)

Corner(LogoInnerRing, 100)
Stroke(LogoInnerRing, CONFIG.Colors.Violet, 0.2, 1)

-- Logo core
local LogoCore = New("Frame", {
	Name = "LogoCore",

	AnchorPoint = Vector2.new(0.5, 0.5),

	Position = UDim2.fromScale(0.5, 0.5),

	Size = UDim2.fromOffset(15, 15),

	BackgroundColor3 = CONFIG.Colors.Cyan,

	BackgroundTransparency = 0.05,

	BorderSizePixel = 0,

	ZIndex = 164,
}, LogoPlate)

Corner(LogoCore, 100)

-- Crosshair vertical
local LogoCrossV = New("Frame", {
	Position = UDim2.new(0.5, -1, 0, 5),

	Size = UDim2.new(0, 2, 1, -10),

	BackgroundColor3 = CONFIG.Colors.White,

	BackgroundTransparency = 0.45,

	BorderSizePixel = 0,

	ZIndex = 165,
}, LogoPlate)

-- Crosshair horizontal
local LogoCrossH = New("Frame", {
	Position = UDim2.new(0, 5, 0.5, -1),

	Size = UDim2.new(1, -10, 0, 2),

	BackgroundColor3 = CONFIG.Colors.White,

	BackgroundTransparency = 0.45,

	BorderSizePixel = 0,

	ZIndex = 165,
}, LogoPlate)

--==============================================================================
-- [SECTION 13] HEADER CENTER / TITLE ZONE
--==============================================================================

local HeaderCenter = New("Frame", {
	Name = "HeaderCenter",

	Position = UDim2.fromOffset(82, 10),

	Size = UDim2.new(1, -202, 1, -20),

	BackgroundTransparency = 1,

	BorderSizePixel = 0,

	ZIndex = 155,
}, Header)

-- Title
local TitleLabel = New("TextLabel", {
	Name = "Title",

	Position = UDim2.fromOffset(0, 5),

	Size = UDim2.new(1, 0, 0, 31),

	BackgroundTransparency = 1,

	Text = CONFIG.Title,

	TextColor3 = CONFIG.Colors.White,

	TextSize = 25,

	Font = Enum.Font.GothamBlack,

	TextXAlignment = Enum.TextXAlignment.Left,

	TextTruncate = Enum.TextTruncate.AtEnd,

	ZIndex = 156,
}, HeaderCenter)

-- Subtitle
local SubtitleLabel = New("TextLabel", {
	Name = "Subtitle",

	Position = UDim2.fromOffset(0, 38),

	Size = UDim2.new(1, 0, 0, 20),

	BackgroundTransparency = 1,

	Text = CONFIG.Subtitle,

	TextColor3 = CONFIG.Colors.Cyan,

	TextSize = 10,

	Font = Enum.Font.GothamBold,

	TextXAlignment = Enum.TextXAlignment.Left,

	TextTruncate = Enum.TextTruncate.AtEnd,

	ZIndex = 156,
}, HeaderCenter)

-- Tiny status line
local HeaderStatus = New("TextLabel", {
	Name = "HeaderStatus",

	Position = UDim2.fromOffset(0, 58),

	Size = UDim2.new(1, 0, 0, 15),

	BackgroundTransparency = 1,

	Text = "● SYSTEM LINKED  //  NEXUS ONLINE",

	TextColor3 = CONFIG.Colors.Success,

	TextSize = 9,

	Font = Enum.Font.GothamMedium,

	TextXAlignment = Enum.TextXAlignment.Left,

	TextTruncate = Enum.TextTruncate.AtEnd,

	ZIndex = 156,
}, HeaderCenter)

--==============================================================================
-- [SECTION 14] HEADER RIGHT / EXCLUSIVE CONTROL ZONE
--==============================================================================
-- ZONA INI KHUSUS:
-- [ MINIMIZE ] [ CLOSE ]
--
-- Tidak ada title / status / logo yang boleh melewati area ini.
--==============================================================================

local HeaderControls = New("Frame", {
	Name = "HeaderControls",

	AnchorPoint = Vector2.new(1, 0),

	Position = UDim2.new(1, -9, 0, 10),

	Size = UDim2.fromOffset(108, 62),

	BackgroundTransparency = 1,

	BorderSizePixel = 0,

	ZIndex = 220,
}, Header)

local ControlsLayout = New("UIListLayout", {
	FillDirection = Enum.FillDirection.Horizontal,

	HorizontalAlignment = Enum.HorizontalAlignment.Right,

	VerticalAlignment = Enum.VerticalAlignment.Center,

	Padding = UDim.new(0, 6),

	SortOrder = Enum.SortOrder.LayoutOrder,
}, HeaderControls)

-- Helper untuk membuat control button
local function CreateHeaderButton(name, symbol, color)
	local button = New("TextButton", {
		Name = name,

		Size = UDim2.fromOffset(51, 51),

		BackgroundColor3 = CONFIG.Colors.Panel3,

		BackgroundTransparency = 0.04,

		BorderSizePixel = 0,

		AutoButtonColor = false,

		Text = symbol,

		TextColor3 = CONFIG.Colors.White,

		TextSize = 21,

		Font = Enum.Font.GothamBold,

		ZIndex = 225,
	}, HeaderControls)

	Corner(button, 13)
	Stroke(button, color, 0.25, 1)

	local accent = New("Frame", {
		AnchorPoint = Vector2.new(0.5, 1),

		Position = UDim2.new(0.5, 0, 1, -3),

		Size = UDim2.new(0, 20, 0, 2),

		BackgroundColor3 = color,

		BackgroundTransparency = 0.15,

		BorderSizePixel = 0,

		ZIndex = 226,
	}, button)

	Corner(accent, 5)

	Connect(button.MouseEnter, function()
		Tween(button, 0.15, {
			BackgroundColor3 = Color3.fromRGB(24, 31, 52)
		})

		Tween(accent, 0.15, {
			Size = UDim2.new(0, 32, 0, 2)
		})
	end)

	Connect(button.MouseLeave, function()
		Tween(button, 0.15, {
			BackgroundColor3 = CONFIG.Colors.Panel3
		})

		Tween(accent, 0.15, {
			Size = UDim2.new(0, 20, 0, 2)
		})
	end)

	return button
end

local MinimizeButton = CreateHeaderButton(
	"MinimizeButton",
	"—",
	CONFIG.Colors.Cyan
)

local CloseButton = CreateHeaderButton(
	"CloseButton",
	"×",
	CONFIG.Colors.Danger
)

--==============================================================================
-- [SECTION 15] BODY
--==============================================================================
-- Body berada tepat di bawah header.
-- Tidak akan mengambil area header.
--==============================================================================

local Body = New("Frame", {
	Name = "Body",

	Position = UDim2.fromOffset(0, CONFIG.HeaderHeight),

	Size = UDim2.new(
		1,
		0,
		1,
		-CONFIG.HeaderHeight
	),

	BackgroundTransparency = 1,

	BorderSizePixel = 0,

	ZIndex = 120,
}, Window)

--==============================================================================
-- [SECTION 16] DESKTOP SIDEBAR
--==============================================================================

local Sidebar = New("Frame", {
	Name = "Sidebar",

	Position = UDim2.fromOffset(10, 8),

	Size = UDim2.new(
		0,
		CONFIG.SidebarWidth,
		1,
		-16
	),

	BackgroundColor3 = CONFIG.Colors.Panel,

	BackgroundTransparency = 0.03,

	BorderSizePixel = 0,

	ZIndex = 125,
}, Body)

Corner(Sidebar, 14)
Stroke(Sidebar, Color3.fromRGB(38, 57, 91), 0.4, 1)

-- Sidebar title
local SidebarTitle = New("TextLabel", {
	Position = UDim2.fromOffset(16, 14),

	Size = UDim2.new(1, -32, 0, 25),

	BackgroundTransparency = 1,

	Text = "NEXUS MENU",

	TextColor3 = CONFIG.Colors.White,

	TextSize = 15,

	Font = Enum.Font.GothamBlack,

	TextXAlignment = Enum.TextXAlignment.Left,

	ZIndex = 126,
}, Sidebar)

local SidebarSub = New("TextLabel", {
	Position = UDim2.fromOffset(16, 38),

	Size = UDim2.new(1, -32, 0, 18),

	BackgroundTransparency = 1,

	Text = "CONTROL MATRIX",

	TextColor3 = CONFIG.Colors.Muted,

	TextSize = 9,

	Font = Enum.Font.GothamBold,

	TextXAlignment = Enum.TextXAlignment.Left,

	ZIndex = 126,
}, Sidebar)

-- Sidebar separator
local SidebarLine = New("Frame", {
	Position = UDim2.fromOffset(16, 63),

	Size = UDim2.new(1, -32, 0, 1),

	BackgroundColor3 = CONFIG.Colors.Cyan,

	BackgroundTransparency = 0.7,

	BorderSizePixel = 0,

	ZIndex = 126,
}, Sidebar)

--==============================================================================
-- [SECTION 17] TAB SYSTEM DATA
--==============================================================================

local Tabs = {
	{
		Id = "HOME",
		Name = "HOME",
		Icon = "⌂",
		Desc = "System overview",
	},

	{
		Id = "VISUALS",
		Name = "VISUALS",
		Icon = "◈",
		Desc = "Visual control",
	},

	{
		Id = "TELEMETRY",
		Name = "TELEMETRY",
		Icon = "⌁",
		Desc = "Live diagnostics",
	},

	{
		Id = "NEXUS",
		Name = "NEXUS",
		Icon = "✦",
		Desc = "Anime core",
	},

	{
		Id = "ABOUT",
		Name = "ABOUT",
		Icon = "?",
		Desc = "System info",
	},
}

local TabButtons = {}
local Pages = {}

--==============================================================================
-- [SECTION 18] SIDEBAR TAB BUTTON CREATOR
--==============================================================================

local function CreateSidebarTab(tab, index)

	local button = New("TextButton", {
		Name = tab.Id .. "Tab",

		Position = UDim2.fromOffset(10, 78 + ((index - 1) * 57)),

		Size = UDim2.new(1, -20, 0, 49),

		BackgroundColor3 = CONFIG.Colors.Panel2,

		BackgroundTransparency = 0.15,

		BorderSizePixel = 0,

		AutoButtonColor = false,

		Text = "",

		ZIndex = 128,
	}, Sidebar)

	Corner(button, 12)

	local iconBox = New("Frame", {
		Position = UDim2.fromOffset(7, 7),

		Size = UDim2.fromOffset(35, 35),

		BackgroundColor3 = CONFIG.Colors.Panel3,

		BorderSizePixel = 0,

		ZIndex = 129,
	}, button)

	Corner(iconBox, 10)
	Stroke(iconBox, CONFIG.Colors.Cyan, 0.75, 1)

	local icon = New("TextLabel", {
		Size = UDim2.fromScale(1, 1),

		BackgroundTransparency = 1,

		Text = tab.Icon,

		TextColor3 = CONFIG.Colors.SoftWhite,

		TextSize = 18,

		Font = Enum.Font.GothamBold,

		ZIndex = 130,
	}, iconBox)

	local name = New("TextLabel", {
		Position = UDim2.fromOffset(50, 7),

		Size = UDim2.new(1, -58, 0, 18),

		BackgroundTransparency = 1,

		Text = tab.Name,

		TextColor3 = CONFIG.Colors.SoftWhite,

		TextSize = 12,

		Font = Enum.Font.GothamBlack,

		TextXAlignment = Enum.TextXAlignment.Left,

		ZIndex = 130,
	}, button)

	local desc = New("TextLabel", {
		Position = UDim2.fromOffset(50, 25),

		Size = UDim2.new(1, -58, 0, 15),

		BackgroundTransparency = 1,

		Text = tab.Desc,

		TextColor3 = CONFIG.Colors.Muted,

		TextSize = 8,

		Font = Enum.Font.GothamMedium,

		TextXAlignment = Enum.TextXAlignment.Left,

		ZIndex = 130,
	}, button)

	local activeBar = New("Frame", {
		Position = UDim2.fromOffset(0, 10),

		Size = UDim2.fromOffset(3, 29),

		BackgroundColor3 = CONFIG.Colors.Cyan,

		BackgroundTransparency = 1,

		BorderSizePixel = 0,

		ZIndex = 131,
	}, button)

	Corner(activeBar, 4)

	TabButtons[tab.Id] = {
		Button = button,
		Icon = icon,
		Name = name,
		Desc = desc,
		ActiveBar = activeBar,
	}

	Connect(button.MouseEnter, function()
		if State.CurrentTab ~= tab.Id then
			Tween(button, 0.15, {
				BackgroundColor3 = Color3.fromRGB(17, 25, 44)
			})
		end
	end)

	Connect(button.MouseLeave, function()
		if State.CurrentTab ~= tab.Id then
			Tween(button, 0.15, {
				BackgroundColor3 = CONFIG.Colors.Panel2
			})
		end
	end)

	Connect(button.Activated, function()
		if State.CurrentTab ~= tab.Id then
			-- Pindah tab
			State.CurrentTab = tab.Id

			for id, data in pairs(TabButtons) do
				local active = id == tab.Id

				Tween(data.Button, 0.18, {
					BackgroundColor3 = active
						and Color3.fromRGB(19, 31, 51)
						or CONFIG.Colors.Panel2
				})

				Tween(data.Icon, 0.18, {
					TextColor3 = active
						and CONFIG.Colors.Cyan
						or CONFIG.Colors.SoftWhite
				})

				Tween(data.Name, 0.18, {
					TextColor3 = active
						and CONFIG.Colors.White
						or CONFIG.Colors.SoftWhite
				})

				Tween(data.ActiveBar, 0.18, {
					BackgroundTransparency = active and 0 or 1
				})
			end

			for id, page in pairs(Pages) do
				if id == tab.Id then
					page.Visible = true
					page.Position = UDim2.new(0, 12, 0, 10)
					page.BackgroundTransparency = 1

					Tween(page, 0.28, {
						Position = UDim2.new(0, 0, 0, 10),
						BackgroundTransparency = 0,
					})
				else
					page.Visible = false
				end
			end
		end
	end)

	return button
end

for index, tab in ipairs(Tabs) do
	CreateSidebarTab(tab, index)
end

--==============================================================================
-- [SECTION 19] SIDEBAR SYSTEM STATUS
--==============================================================================

local SystemStatus = New("Frame", {
	AnchorPoint = Vector2.new(0, 1),

	Position = UDim2.new(0, 10, 1, -10),

	Size = UDim2.new(1, -20, 0, 78),

	BackgroundColor3 = CONFIG.Colors.Panel2,

	BorderSizePixel = 0,

	ZIndex = 126,
}, Sidebar)

Corner(SystemStatus, 12)
Stroke(SystemStatus, CONFIG.Colors.Success, 0.65, 1)

local SystemStatusTitle = New("TextLabel", {
	Position = UDim2.fromOffset(12, 10),

	Size = UDim2.new(1, -24, 0, 18),

	BackgroundTransparency = 1,

	Text = "SYSTEM STATUS",

	TextColor3 = CONFIG.Colors.SoftWhite,

	TextSize = 9,

	Font = Enum.Font.GothamBlack,

	TextXAlignment = Enum.TextXAlignment.Left,

	ZIndex = 127,
}, SystemStatus)

local SystemStatusValue = New("TextLabel", {
	Position = UDim2.fromOffset(12, 29),

	Size = UDim2.new(1, -24, 0, 24),

	BackgroundTransparency = 1,

	Text = "ONLINE",

	TextColor3 = CONFIG.Colors.Success,

	TextSize = 17,

	Font = Enum.Font.GothamBlack,

	TextXAlignment = Enum.TextXAlignment.Left,

	ZIndex = 127,
}, SystemStatus)

local SystemStatusDot = New("Frame", {
	AnchorPoint = Vector2.new(1, 0.5),

	Position = UDim2.new(1, -12, 0, 41),

	Size = UDim2.fromOffset(9, 9),

	BackgroundColor3 = CONFIG.Colors.Success,

	BorderSizePixel = 0,

	ZIndex = 128,
}, SystemStatus)

Corner(SystemStatusDot, 100)

--==============================================================================
-- [SECTION 20] CONTENT CONTAINER
--==============================================================================

local Content = New("Frame", {
	Name = "Content",

	Position = UDim2.new(
		0,
		CONFIG.SidebarWidth + 20,
		0,
		8
	),

	Size = UDim2.new(
		1,
		-CONFIG.SidebarWidth - 30,
		1,
		-16
	),

	BackgroundColor3 = CONFIG.Colors.Panel,

	BackgroundTransparency = 0.04,

	BorderSizePixel = 0,

	ClipsDescendants = true,

	ZIndex = 124,
}, Body)

Corner(Content, 14)
Stroke(Content, Color3.fromRGB(38, 57, 91), 0.5, 1)

--==============================================================================
-- [SECTION 21] PAGE FACTORY
--==============================================================================

local function CreatePage(id)
	local page = New("Frame", {
		Name = id .. "Page",

		Position = UDim2.fromOffset(0, 10),

		Size = UDim2.new(1, 0, 1, -10),

		BackgroundTransparency = 0,

		BackgroundColor3 = CONFIG.Colors.Panel,

		BorderSizePixel = 0,

		Visible = false,

		ZIndex = 125,
	}, Content)

	Pages[id] = page

	return page
end

--==============================================================================
-- [SECTION 22] CARD FACTORY
--==============================================================================

local function CreateCard(parent, position, size, title, subtitle)

	local card = New("Frame", {
		Position = position,

		Size = size,

		BackgroundColor3 = CONFIG.Colors.Panel2,

		BackgroundTransparency = 0.02,

		BorderSizePixel = 0,

		ZIndex = 128,
	}, parent)

	Corner(card, 13)
	Stroke(card, Color3.fromRGB(41, 62, 99), 0.45, 1)

	local cardTitle = New("TextLabel", {
		Position = UDim2.fromOffset(14, 12),

		Size = UDim2.new(1, -28, 0, 22),

		BackgroundTransparency = 1,

		Text = title or "CARD",

		TextColor3 = CONFIG.Colors.White,

		TextSize = 13,

		Font = Enum.Font.GothamBlack,

		TextXAlignment = Enum.TextXAlignment.Left,

		TextTruncate = Enum.TextTruncate.AtEnd,

		ZIndex = 129,
	}, card)

	local cardSubtitle = New("TextLabel", {
		Position = UDim2.fromOffset(14, 34),

		Size = UDim2.new(1, -28, 0, 18),

		BackgroundTransparency = 1,

		Text = subtitle or "",

		TextColor3 = CONFIG.Colors.Muted,

		TextSize = 8,

		Font = Enum.Font.GothamMedium,

		TextXAlignment = Enum.TextXAlignment.Left,

		TextTruncate = Enum.TextTruncate.AtEnd,

		ZIndex = 129,
	}, card)

	return card, cardTitle, cardSubtitle
end

--==============================================================================
-- [SECTION 23] HOME TAB
--==============================================================================

local HomePage = CreatePage("HOME")

local HomeHeader = New("TextLabel", {
	Position = UDim2.fromOffset(18, 12),

	Size = UDim2.new(1, -36, 0, 34),

	BackgroundTransparency = 1,

	Text = "NEXUS CONTROL DECK",

	TextColor3 = CONFIG.Colors.White,

	TextSize = 22,

	Font = Enum.Font.GothamBlack,

	TextXAlignment = Enum.TextXAlignment.Left,

	ZIndex = 130,
}, HomePage)

local HomeDescription = New("TextLabel", {
	Position = UDim2.fromOffset(18, 44),

	Size = UDim2.new(1, -36, 0, 24),

	BackgroundTransparency = 1,

	Text = "Robotic command interface // live system synchronization",

	TextColor3 = CONFIG.Colors.Muted,

	TextSize = 10,

	Font = Enum.Font.GothamMedium,

	TextXAlignment = Enum.TextXAlignment.Left,

	ZIndex = 130,
}, HomePage)

-- Main hero card
local HeroCard = New("Frame", {
	Position = UDim2.fromOffset(18, 78),

	Size = UDim2.new(1, -36, 0, 145),

	BackgroundColor3 = Color3.fromRGB(10, 17, 32),

	BorderSizePixel = 0,

	ZIndex = 128,
}, HomePage)

Corner(HeroCard, 16)
Stroke(HeroCard, CONFIG.Colors.Cyan, 0.45, 1)

local HeroGradient = Gradient(HeroCard, {
	ColorSequenceKeypoint.new(0, Color3.fromRGB(11, 24, 42)),
	ColorSequenceKeypoint.new(0.5, Color3.fromRGB(12, 15, 31)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(30, 12, 37)),
}, 20)

local HeroTitle = New("TextLabel", {
	Position = UDim2.fromOffset(18, 17),

	Size = UDim2.new(1, -170, 0, 32),

	BackgroundTransparency = 1,

	Text = "VANZ // NEXUS ONLINE",

	TextColor3 = CONFIG.Colors.White,

	TextSize = 21,

	Font = Enum.Font.GothamBlack,

	TextXAlignment = Enum.TextXAlignment.Left,

	TextTruncate = Enum.TextTruncate.AtEnd,

	ZIndex = 130,
}, HeroCard)

local HeroSub = New("TextLabel", {
	Position = UDim2.fromOffset(18, 51),

	Size = UDim2.new(1, -170, 0, 38),

	BackgroundTransparency = 1,

	Text = "Your command matrix is synchronized. All core modules are ready.",

	TextColor3 = CONFIG.Colors.SoftWhite,

	TextSize = 11,

	Font = Enum.Font.GothamMedium,

	TextWrapped = true,

	TextXAlignment = Enum.TextXAlignment.Left,

	ZIndex = 130,
}, HeroCard)

-- Hero status
local HeroStatus = New("Frame", {
	AnchorPoint = Vector2.new(1, 0.5),

	Position = UDim2.new(1, -18, 0.5, 0),

	Size = UDim2.fromOffset(112, 86),

	BackgroundColor3 = CONFIG.Colors.Panel3,

	BorderSizePixel = 0,

	ZIndex = 131,
}, HeroCard)

Corner(HeroStatus, 14)
Stroke(HeroStatus, CONFIG.Colors.Success, 0.4, 1)

local HeroStatusDot = New("Frame", {
	AnchorPoint = Vector2.new(0.5, 0),

	Position = UDim2.fromScale(0.5, 0.15),

	Size = UDim2.fromOffset(12, 12),

	BackgroundColor3 = CONFIG.Colors.Success,

	BorderSizePixel = 0,

	ZIndex = 132,
}, HeroStatus)

Corner(HeroStatusDot, 100)

local HeroStatusText = New("TextLabel", {
	Position = UDim2.new(0, 8, 0.5, -2),

	Size = UDim2.new(1, -16, 0, 20),

	BackgroundTransparency = 1,

	Text = "ONLINE",

	TextColor3 = CONFIG.Colors.Success,

	TextSize = 13,

	Font = Enum.Font.GothamBlack,

	ZIndex = 132,
}, HeroStatus)

--==============================================================================
-- [SECTION 24] HOME TELEMETRY CARDS
--==============================================================================

local HomeCards = {}

local homeCardData = {
	{"FPS", "LIVE FRAME RATE"},
	{"PING", "NETWORK LATENCY"},
	{"MEMORY", "CLIENT MEMORY"},
	{"UPTIME", "SESSION TIME"},
}

for index, data in ipairs(homeCardData) do

	local column = (index - 1) % 2
	local row = math.floor((index - 1) / 2)

	local card = CreateCard(
		HomePage,

		UDim2.new(
			0,
			18 + (column * 184),
			0,
			235 + (row * 88)
		),

		UDim2.new(
			0,
			170,
			0,
			76
		),

		data[1],
		data[2]
	)

	local value = New("TextLabel", {
		Position = UDim2.fromOffset(14, 48),

		Size = UDim2.new(1, -28, 0, 24),

		BackgroundTransparency = 1,

		Text = "--",

		TextColor3 = CONFIG.Colors.Cyan,

		TextSize = 19,

		Font = Enum.Font.GothamBlack,

		TextXAlignment = Enum.TextXAlignment.Left,

		ZIndex = 130,
	}, card)

	HomeCards[data[1]] = value
end

--==============================================================================
-- [SECTION 25] HOME RADAR
--==============================================================================

local RadarCard = New("Frame", {
	AnchorPoint = Vector2.new(1, 0),

	Position = UDim2.new(1, -18, 0, 235),

	Size = UDim2.fromOffset(245, 165),

	BackgroundColor3 = CONFIG.Colors.Panel2,

	BorderSizePixel = 0,

	ZIndex = 128,
}, HomePage)

Corner(RadarCard, 14)
Stroke(RadarCard, CONFIG.Colors.Violet, 0.5, 1)

local RadarTitle = New("TextLabel", {
	Position = UDim2.fromOffset(14, 10),

	Size = UDim2.new(1, -28, 0, 20),

	BackgroundTransparency = 1,

	Text = "NEURAL RADAR",

	TextColor3 = CONFIG.Colors.White,

	TextSize = 11,

	Font = Enum.Font.GothamBlack,

	TextXAlignment = Enum.TextXAlignment.Left,

	ZIndex = 130,
}, RadarCard)

local Radar = New("Frame", {
	AnchorPoint = Vector2.new(0.5, 1),

	Position = UDim2.new(0.5, 0, 1, -12),

	Size = UDim2.fromOffset(122, 122),

	BackgroundColor3 = Color3.fromRGB(7, 17, 27),

	BorderSizePixel = 0,

	ZIndex = 129,
}, RadarCard)

Corner(Radar, 100)
Stroke(Radar, CONFIG.Colors.Cyan, 0.35, 1)

for _, scale in ipairs({0.72, 0.45, 0.22}) do

	local ring = New("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),

		Position = UDim2.fromScale(0.5, 0.5),

		Size = UDim2.fromScale(scale, scale),

		BackgroundTransparency = 1,

		BorderSizePixel = 0,

		ZIndex = 130,
	}, Radar)

	Corner(ring, 100)
	Stroke(ring, CONFIG.Colors.Cyan, 0.75, 1)
end

local RadarVertical = New("Frame", {
	AnchorPoint = Vector2.new(0.5, 0.5),

	Position = UDim2.fromScale(0.5, 0.5),

	Size = UDim2.new(0, 1, 1, -12),

	BackgroundColor3 = CONFIG.Colors.Cyan,

	BackgroundTransparency = 0.7,

	BorderSizePixel = 0,

	ZIndex = 130,
}, Radar)

local RadarHorizontal = New("Frame", {
	AnchorPoint = Vector2.new(0.5, 0.5),

	Position = UDim2.fromScale(0.5, 0.5),

	Size = UDim2.new(1, -12, 0, 1),

	BackgroundColor3 = CONFIG.Colors.Cyan,

	BackgroundTransparency = 0.7,

	BorderSizePixel = 0,

	ZIndex = 130,
}, Radar)

local RadarSweep = New("Frame", {
	AnchorPoint = Vector2.new(0, 1),

	Position = UDim2.fromScale(0.5, 0.5),

	Size = UDim2.new(0.5, 0, 0, 2),

	BackgroundColor3 = CONFIG.Colors.Cyan,

	BackgroundTransparency = 0.1,

	BorderSizePixel = 0,

	ZIndex = 132,
}, Radar)

local RadarCore = New("Frame", {
	AnchorPoint = Vector2.new(0.5, 0.5),

	Position = UDim2.fromScale(0.5, 0.5),

	Size = UDim2.fromOffset(7, 7),

	BackgroundColor3 = CONFIG.Colors.White,

	BorderSizePixel = 0,

	ZIndex = 133,
}, Radar)

Corner(RadarCore, 100)

--==============================================================================
-- [SECTION 26] VISUALS TAB
--==============================================================================

local VisualsPage = CreatePage("VISUALS")

local VisualsTitle = New("TextLabel", {
	Position = UDim2.fromOffset(18, 15),

	Size = UDim2.new(1, -36, 0, 32),

	BackgroundTransparency = 1,

	Text = "VISUAL MATRIX",

	TextColor3 = CONFIG.Colors.White,

	TextSize = 22,

	Font = Enum.Font.GothamBlack,

	TextXAlignment = Enum.TextXAlignment.Left,

	ZIndex = 130,
}, VisualsPage)

local VisualsSub = New("TextLabel", {
	Position = UDim2.fromOffset(18, 47),

	Size = UDim2.new(1, -36, 0, 24),

	BackgroundTransparency = 1,

	Text = "Tune the living interface and interaction layer.",

	TextColor3 = CONFIG.Colors.Muted,

	TextSize = 10,

	Font = Enum.Font.GothamMedium,

	TextXAlignment = Enum.TextXAlignment.Left,

	ZIndex = 130,
}, VisualsPage)

--==============================================================================
-- [SECTION 27] TOGGLE SYSTEM
--==============================================================================

local VisualSettings = {
	SoftAnimations = true,
	NeonAmbience = true,
	InteractionFX = true,
	Radar = true,
}

local ToggleObjects = {}

local function CreateToggle(parent, y, title, description, key)

	local row = New("TextButton", {
		Position = UDim2.fromOffset(18, y),

		Size = UDim2.new(1, -36, 0, 70),

		BackgroundColor3 = CONFIG.Colors.Panel2,

		BorderSizePixel = 0,

		AutoButtonColor = false,

		Text = "",

		ZIndex = 128,
	}, parent)

	Corner(row, 13)
	Stroke(row, Color3.fromRGB(40, 60, 96), 0.45, 1)

	local titleLabel = New("TextLabel", {
		Position = UDim2.fromOffset(16, 10),

		Size = UDim2.new(1, -100, 0, 22),

		BackgroundTransparency = 1,

		Text = title,

		TextColor3 = CONFIG.Colors.White,

		TextSize = 13,

		Font = Enum.Font.GothamBlack,

		TextXAlignment = Enum.TextXAlignment.Left,

		ZIndex = 129,
	}, row)

	local descLabel = New("TextLabel", {
		Position = UDim2.fromOffset(16, 34),

		Size = UDim2.new(1, -100, 0, 18),

		BackgroundTransparency = 1,

		Text = description,

		TextColor3 = CONFIG.Colors.Muted,

		TextSize = 9,

		Font = Enum.Font.GothamMedium,

		TextXAlignment = Enum.TextXAlignment.Left,

		TextTruncate = Enum.TextTruncate.AtEnd,

		ZIndex = 129,
	}, row)

	local toggle = New("Frame", {
		AnchorPoint = Vector2.new(1, 0.5),

		Position = UDim2.new(1, -16, 0.5, 0),

		Size = UDim2.fromOffset(58, 31),

		BackgroundColor3 = CONFIG.Colors.Cyan,

		BorderSizePixel = 0,

		ZIndex = 130,
	}, row)

	Corner(toggle, 20)

	local knob = New("Frame", {
		AnchorPoint = Vector2.new(1, 0.5),

		Position = UDim2.new(1, -4, 0.5, 0),

		Size = UDim2.fromOffset(23, 23),

		BackgroundColor3 = CONFIG.Colors.White,

		BorderSizePixel = 0,

		ZIndex = 131,
	}, toggle)

	Corner(knob, 100)

	ToggleObjects[key] = {
		Row = row,
		Toggle = toggle,
		Knob = knob,
	}

	local function Refresh()

		local enabled = VisualSettings[key]

		Tween(toggle, 0.18, {
			BackgroundColor3 = enabled
				and CONFIG.Colors.Cyan
				or Color3.fromRGB(45, 54, 70)
		})

		Tween(knob, 0.18, {
			Position = enabled
				and UDim2.new(1, -4, 0.5, 0)
				or UDim2.new(0, 4, 0.5, 0)
		})
	end

	Connect(row.Activated, function()
		VisualSettings[key] = not VisualSettings[key]
		Refresh()
	end)

	Refresh()

	return row
end

CreateToggle(
	VisualsPage,
	82,
	"SOFT ANIMATIONS",
	"Enable smooth breathing and holographic motion.",
	"SoftAnimations"
)

CreateToggle(
	VisualsPage,
	160,
	"NEON AMBIENCE",
	"Enable dynamic accent color and interface glow.",
	"NeonAmbience"
)

CreateToggle(
	VisualsPage,
	238,
	"INTERACTION FX",
	"Enable button hover and touch feedback.",
	"InteractionFX"
)

CreateToggle(
	VisualsPage,
	316,
	"NEURAL RADAR",
	"Enable the animated radar sweep.",
	"Radar"
)

--==============================================================================
-- [SECTION 28] TELEMETRY TAB
--==============================================================================

local TelemetryPage = CreatePage("TELEMETRY")

local TelemetryTitle = New("TextLabel", {
	Position = UDim2.fromOffset(18, 15),

	Size = UDim2.new(1, -36, 0, 32),

	BackgroundTransparency = 1,

	Text = "LIVE TELEMETRY",

	TextColor3 = CONFIG.Colors.White,

	TextSize = 22,

	Font = Enum.Font.GothamBlack,

	TextXAlignment = Enum.TextXAlignment.Left,

	ZIndex = 130,
}, TelemetryPage)

local TelemetrySub = New("TextLabel", {
	Position = UDim2.fromOffset(18, 47),

	Size = UDim2.new(1, -36, 0, 24),

	BackgroundTransparency = 1,

	Text = "Real-time client diagnostics and session information.",

	TextColor3 = CONFIG.Colors.Muted,

	TextSize = 10,

	Font = Enum.Font.GothamMedium,

	TextXAlignment = Enum.TextXAlignment.Left,

	ZIndex = 130,
}, TelemetryPage)

local TelemetryValues = {}

local telemetryData = {
	{"FPS", "FRAME RATE"},
	{"PING", "SERVER LATENCY"},
	{"MEMORY", "CLIENT MEMORY"},
	{"UPTIME", "SESSION TIME"},
	{"TAB", "ACTIVE MODULE"},
	{"STATE", "WINDOW STATE"},
}

for index, data in ipairs(telemetryData) do

	local column = (index - 1) % 2
	local row = math.floor((index - 1) / 2)

	local card = CreateCard(
		TelemetryPage,

		UDim2.new(
			0,
			18 + (column * 245),
			0,
			82 + (row * 105)
		),

		UDim2.new(
			0,
			225,
			0,
			92
		),

		data[1],
		data[2]
	)

	local value = New("TextLabel", {
		Position = UDim2.fromOffset(14, 49),

		Size = UDim2.new(1, -28, 0, 30),

		BackgroundTransparency = 1,

		Text = "--",

		TextColor3 = CONFIG.Colors.Cyan,

		TextSize = 21,

		Font = Enum.Font.GothamBlack,

		TextXAlignment = Enum.TextXAlignment.Left,

		TextTruncate = Enum.TextTruncate.AtEnd,

		ZIndex = 130,
	}, card)

	TelemetryValues[data[1]] = value
end

--==============================================================================
-- [SECTION 29] NEXUS / ANIME CORE TAB
--==============================================================================

local NexusPage = CreatePage("NEXUS")

local NexusTitle = New("TextLabel", {
	Position = UDim2.fromOffset(18, 15),

	Size = UDim2.new(1, -36, 0, 32),

	BackgroundTransparency = 1,

	Text = "NEXUS CORE",

	TextColor3 = CONFIG.Colors.White,

	TextSize = 22,

	Font = Enum.Font.GothamBlack,

	TextXAlignment = Enum.TextXAlignment.Left,

	ZIndex = 130,
}, NexusPage)

local NexusSub = New("TextLabel", {
	Position = UDim2.fromOffset(18, 47),

	Size = UDim2.new(1, -36, 0, 24),

	BackgroundTransparency = 1,

	Text = "Robotic anime-inspired visual core // no external assets required.",

	TextColor3 = CONFIG.Colors.Muted,

	TextSize = 10,

	Font = Enum.Font.GothamMedium,

	TextXAlignment = Enum.TextXAlignment.Left,

	ZIndex = 130,
}, NexusPage)

-- Big core
local NexusCorePanel = New("Frame", {
	AnchorPoint = Vector2.new(0.5, 0),

	Position = UDim2.new(0.5, 0, 0, 82),

	Size = UDim2.new(1, -36, 0, 300),

	BackgroundColor3 = Color3.fromRGB(8, 12, 24),

	BorderSizePixel = 0,

	ZIndex = 128,
}, NexusPage)

Corner(NexusCorePanel, 18)
Stroke(NexusCorePanel, CONFIG.Colors.Violet, 0.42, 1)

local NexusCore = New("Frame", {
	AnchorPoint = Vector2.new(0.5, 0.5),

	Position = UDim2.new(0.5, 0, 0.55, 0),

	Size = UDim2.fromOffset(150, 150),

	BackgroundColor3 = Color3.fromRGB(10, 17, 31),

	BorderSizePixel = 0,

	ZIndex = 130,
}, NexusCorePanel)

Corner(NexusCore, 100)
Stroke(NexusCore, CONFIG.Colors.Cyan, 0.25, 2)

local NexusRing1 = New("Frame", {
	AnchorPoint = Vector2.new(0.5, 0.5),

	Position = UDim2.fromScale(0.5, 0.5),

	Size = UDim2.fromOffset(112, 112),

	BackgroundTransparency = 1,

	BorderSizePixel = 0,

	ZIndex = 131,
}, NexusCore)

Corner(NexusRing1, 100)
Stroke(NexusRing1, CONFIG.Colors.Violet, 0.25, 2)

local NexusRing2 = New("Frame", {
	AnchorPoint = Vector2.new(0.5, 0.5),

	Position = UDim2.fromScale(0.5, 0.5),

	Size = UDim2.fromOffset(75, 75),

	BackgroundTransparency = 1,

	BorderSizePixel = 0,

	ZIndex = 132,
}, NexusCore)

Corner(NexusRing2, 100)
Stroke(NexusRing2, CONFIG.Colors.Pink, 0.35, 1)

local NexusCoreCenter = New("Frame", {
	AnchorPoint = Vector2.new(0.5, 0.5),

	Position = UDim2.fromScale(0.5, 0.5),

	Size = UDim2.fromOffset(34, 34),

	BackgroundColor3 = CONFIG.Colors.Cyan,

	BorderSizePixel = 0,

	ZIndex = 134,
}, NexusCore)

Corner(NexusCoreCenter, 100)

local NexusCoreText = New("TextLabel", {
	AnchorPoint = Vector2.new(0.5, 0.5),

	Position = UDim2.fromScale(0.5, 0.5),

	Size = UDim2.new(1, 0, 1, 0),

	BackgroundTransparency = 1,

	Text = "N",

	TextColor3 = CONFIG.Colors.Background,

	TextSize = 20,

	Font = Enum.Font.GothamBlack,

	ZIndex = 135,
}, NexusCoreCenter)

local NexusCoreLabel = New("TextLabel", {
	AnchorPoint = Vector2.new(0.5, 0),

	Position = UDim2.new(0.5, 0, 0, 16),

	Size = UDim2.new(1, -40, 0, 24),

	BackgroundTransparency = 1,

	Text = "NEURAL ANIME CORE",

	TextColor3 = CONFIG.Colors.White,

	TextSize = 14,

	Font = Enum.Font.GothamBlack,

	ZIndex = 132,
}, NexusCorePanel)

local NexusCoreDesc = New("TextLabel", {
	AnchorPoint = Vector2.new(0.5, 0),

	Position = UDim2.new(0.5, 0, 0, 40),

	Size = UDim2.new(1, -40, 0, 18),

	BackgroundTransparency = 1,

	Text = "SYNC / PROCESS / EVOLVE",

	TextColor3 = CONFIG.Colors.Cyan,

	TextSize = 9,

	Font = Enum.Font.GothamBold,

	ZIndex = 132,
}, NexusCorePanel)

--==============================================================================
-- [SECTION 30] ABOUT TAB
--==============================================================================

local AboutPage = CreatePage("ABOUT")

local AboutTitle = New("TextLabel", {
	Position = UDim2.fromOffset(18, 15),

	Size = UDim2.new(1, -36, 0, 32),

	BackgroundTransparency = 1,

	Text = "ABOUT VANZ NEXUS",

	TextColor3 = CONFIG.Colors.White,

	TextSize = 22,

	Font = Enum.Font.GothamBlack,

	TextXAlignment = Enum.TextXAlignment.Left,

	ZIndex = 130,
}, AboutPage)

local AboutCard = New("Frame", {
	Position = UDim2.fromOffset(18, 68),

	Size = UDim2.new(1, -36, 0, 330),

	BackgroundColor3 = CONFIG.Colors.Panel2,

	BorderSizePixel = 0,

	ZIndex = 128,
}, AboutPage)

Corner(AboutCard, 16)
Stroke(AboutCard, CONFIG.Colors.Cyan, 0.55, 1)

local AboutMain = New("TextLabel", {
	Position = UDim2.fromOffset(22, 22),

	Size = UDim2.new(1, -44, 0, 40),

	BackgroundTransparency = 1,

	Text = "VANZ NEXUS",

	TextColor3 = CONFIG.Colors.Cyan,

	TextSize = 25,

	Font = Enum.Font.GothamBlack,

	TextXAlignment = Enum.TextXAlignment.Left,

	ZIndex = 130,
}, AboutCard)

local AboutBody = New("TextLabel", {
	Position = UDim2.fromOffset(22, 70),

	Size = UDim2.new(1, -44, 0, 150),

	BackgroundTransparency = 1,

	Text = "A custom robotic command interface built with native Roblox UI objects. " ..
		"The interface is designed around responsive layouts, large touch targets, " ..
		"clear navigation, animated telemetry, and a compact minimized control core.",

	TextColor3 = CONFIG.Colors.SoftWhite,

	TextSize = 12,

	Font = Enum.Font.GothamMedium,

	TextWrapped = true,

	TextXAlignment = Enum.TextXAlignment.Left,

	TextYAlignment = Enum.TextYAlignment.Top,

	ZIndex = 130,
}, AboutCard)

local AboutVersion = New("TextLabel", {
	Position = UDim2.fromOffset(22, 235),

	Size = UDim2.new(1, -44, 0, 24),

	BackgroundTransparency = 1,

	Text = "VANZ NEXUS // BUILD 09",

	TextColor3 = CONFIG.Colors.Violet,

	TextSize = 11,

	Font = Enum.Font.GothamBlack,

	TextXAlignment = Enum.TextXAlignment.Left,

	ZIndex = 130,
}, AboutCard)

local AboutHint = New("TextLabel", {
	Position = UDim2.fromOffset(22, 265),

	Size = UDim2.new(1, -44, 0, 24),

	BackgroundTransparency = 1,

	Text = "TIP: Minimize untuk mengubah window menjadi NEXUS CORE.",

	TextColor3 = CONFIG.Colors.Muted,

	TextSize = 10,

	Font = Enum.Font.GothamMedium,

	TextXAlignment = Enum.TextXAlignment.Left,

	ZIndex = 130,
}, AboutCard)

--==============================================================================
-- [SECTION 31] MOBILE BOTTOM NAVIGATION
--==============================================================================
-- Desktop menggunakan sidebar.
-- Mobile menyembunyikan sidebar dan menggunakan navigation bar di bawah.
--==============================================================================

local MobileNav = New("Frame", {
	Name = "MobileNav",

	AnchorPoint = Vector2.new(0.5, 1),

	Position = UDim2.new(0.5, 0, 1, -7),

	Size = UDim2.new(1, -14, 0, CONFIG.MobileNavHeight),

	BackgroundColor3 = CONFIG.Colors.Panel,

	BorderSizePixel = 0,

	Visible = false,

	ZIndex = 250,
}, Window)

Corner(MobileNav, 15)
Stroke(MobileNav, Color3.fromRGB(43, 68, 106), 0.25, 1)

local MobileNavLayout = New("UIListLayout", {
	FillDirection = Enum.FillDirection.Horizontal,

	HorizontalAlignment = Enum.HorizontalAlignment.Center,

	VerticalAlignment = Enum.VerticalAlignment.Center,

	Padding = UDim.new(0, 4),

	SortOrder = Enum.SortOrder.LayoutOrder,
}, MobileNav)

local MobileTabButtons = {}

local function CreateMobileTab(tab)

	local button = New("TextButton", {
		Name = tab.Id .. "MobileTab",

		Size = UDim2.fromOffset(58, 58),

		BackgroundColor3 = CONFIG.Colors.Panel2,

		BackgroundTransparency = 0.15,

		BorderSizePixel = 0,

		AutoButtonColor = false,

		Text = "",

		ZIndex = 252,
	}, MobileNav)

	Corner(button, 11)

	local icon = New("TextLabel", {
		Position = UDim2.fromOffset(0, 7),

		Size = UDim2.new(1, 0, 0, 22),

		BackgroundTransparency = 1,

		Text = tab.Icon,

		TextColor3 = CONFIG.Colors.SoftWhite,

		TextSize = 17,

		Font = Enum.Font.GothamBold,

		ZIndex = 253,
	}, button)

	local name = New("TextLabel", {
		Position = UDim2.fromOffset(0, 31),

		Size = UDim2.new(1, 0, 0, 17),

		BackgroundTransparency = 1,

		Text = tab.Name,

		TextColor3 = CONFIG.Colors.Muted,

		TextSize = 7,

		Font = Enum.Font.GothamBlack,

		ZIndex = 253,
	}, button)

	MobileTabButtons[tab.Id] = {
		Button = button,
		Icon = icon,
		Name = name,
	}

	Connect(button.Activated, function()

		if State.CurrentTab == tab.Id then
			return
		end

		State.CurrentTab = tab.Id

		for id, data in pairs(MobileTabButtons) do

			local active = id == tab.Id

			Tween(data.Button, 0.16, {
				BackgroundColor3 = active
					and Color3.fromRGB(18, 30, 51)
					or CONFIG.Colors.Panel2
			})

			Tween(data.Icon, 0.16, {
				TextColor3 = active
					and CONFIG.Colors.Cyan
					or CONFIG.Colors.SoftWhite
			})

			Tween(data.Name, 0.16, {
				TextColor3 = active
					and CONFIG.Colors.White
					or CONFIG.Colors.Muted
			})
		end

		for id, page in pairs(Pages) do
			page.Visible = id == tab.Id
		end
	end)
end

for _, tab in ipairs(Tabs) do
	CreateMobileTab(tab)
end

--==============================================================================
-- [SECTION 32] INITIAL TAB
--==============================================================================

State.CurrentTab = "HOME"

for id, data in pairs(TabButtons) do

	local active = id == State.CurrentTab

	data.Button.BackgroundColor3 = active
		and Color3.fromRGB(19, 31, 51)
		or CONFIG.Colors.Panel2

	data.Icon.TextColor3 = active
		and CONFIG.Colors.Cyan
		or CONFIG.Colors.SoftWhite

	data.Name.TextColor3 = active
		and CONFIG.Colors.White
		or CONFIG.Colors.SoftWhite

	data.ActiveBar.BackgroundTransparency = active and 0 or 1
end

for id, page in pairs(Pages) do
	page.Visible = id == State.CurrentTab
end

--==============================================================================
-- [SECTION 33] MINIMIZED LOGO
--==============================================================================
-- PENTING:
-- Tidak ada shadow / aura biru di luar logo.
--
-- Logo dibuat kecil:
-- Desktop ~78 px
-- Mobile  ~68 px
--
-- Animasi hanya terjadi DI DALAM logo.
--==============================================================================

local MiniLogo = New("TextButton", {
	Name = "MiniLogo",

	AnchorPoint = Vector2.new(0.5, 0.5),

	Position = UDim2.fromScale(0.5, 0.5),

	Size = UDim2.fromOffset(78, 78),

	BackgroundColor3 = CONFIG.Colors.Background,

	BorderSizePixel = 0,

	AutoButtonColor = false,

	Text = "",

	Visible = false,

	ZIndex = 500,
}, ScreenGui)

Corner(MiniLogo, 100)
Stroke(MiniLogo, CONFIG.Colors.Cyan, 0.25, 1)

-- Mini logo internal ring
local MiniRingOuter = New("Frame", {
	AnchorPoint = Vector2.new(0.5, 0.5),

	Position = UDim2.fromScale(0.5, 0.5),

	Size = UDim2.fromOffset(62, 62),

	BackgroundTransparency = 1,

	BorderSizePixel = 0,

	ZIndex = 501,
}, MiniLogo)

Corner(MiniRingOuter, 100)
Stroke(MiniRingOuter, CONFIG.Colors.Cyan, 0.12, 2)

local MiniRingInner = New("Frame", {
	AnchorPoint = Vector2.new(0.5, 0.5),

	Position = UDim2.fromScale(0.5, 0.5),

	Size = UDim2.fromOffset(43, 43),

	BackgroundTransparency = 1,

	BorderSizePixel = 0,

	ZIndex = 502,
}, MiniLogo)

Corner(MiniRingInner, 100)
Stroke(MiniRingInner, CONFIG.Colors.Violet, 0.18, 1)

local MiniCore = New("Frame", {
	AnchorPoint = Vector2.new(0.5, 0.5),

	Position = UDim2.fromScale(0.5, 0.5),

	Size = UDim2.fromOffset(21, 21),

	BackgroundColor3 = CONFIG.Colors.Cyan,

	BorderSizePixel = 0,

	ZIndex = 503,
}, MiniLogo)

Corner(MiniCore, 100)

local MiniCoreLetter = New("TextLabel", {
	Size = UDim2.fromScale(1, 1),

	BackgroundTransparency = 1,

	Text = "N",

	TextColor3 = CONFIG.Colors.Background,

	TextSize = 12,

	Font = Enum.Font.GothamBlack,

	ZIndex = 504,
}, MiniCore)

-- Mini scanline
local MiniScan = New("Frame", {
	AnchorPoint = Vector2.new(0.5, 0.5),

	Position = UDim2.fromScale(0.5, 0.2),

	Size = UDim2.new(0.72, 0, 0, 1),

	BackgroundColor3 = CONFIG.Colors.White,

	BackgroundTransparency = 0.25,

	BorderSizePixel = 0,

	ZIndex = 505,
}, MiniLogo)

-- Orbit dot
local MiniOrbitDot = New("Frame", {
	AnchorPoint = Vector2.new(0.5, 0.5),

	Position = UDim2.new(0.5, 27, 0.5, 0),

	Size = UDim2.fromOffset(5, 5),

	BackgroundColor3 = CONFIG.Colors.Pink,

	BorderSizePixel = 0,

	ZIndex = 506,
}, MiniLogo)

Corner(MiniOrbitDot, 100)

--==============================================================================
-- [SECTION 34] MINIMIZE / RESTORE FUNCTIONS
--==============================================================================

local function CenterMiniLogo()

	MiniLogo.AnchorPoint = Vector2.new(0.5, 0.5)

	MiniLogo.Position = UDim2.fromScale(0.5, 0.5)
end

local function MinimizeGUI()

	if State.Destroyed or State.Minimized then
		return
	end

	State.Minimized = true

	-- Logo selalu mulai dari tengah layar.
	CenterMiniLogo()

	MiniLogo.Visible = true

	-- Window mengecil dulu
	MainScale.Scale = 1

	Tween(
		MainScale,
		0.22,
		{
			Scale = 0.92
		},
		Enum.EasingStyle.Quint
	)

	task.delay(0.12, function()

		if State.Destroyed then
			return
		end

		MainHolder.Visible = false

		MiniLogo.Size = UDim2.fromOffset(64, 64)

		Tween(
			MiniLogo,
			0.24,
			{
				Size = UDim2.fromOffset(
					State.Mobile and 68 or 78,
					State.Mobile and 68 or 78
				)
			},
			Enum.EasingStyle.Back
		)
	end)
end

local function RestoreGUI()

	if State.Destroyed or not State.Minimized then
		return
	end

	State.Minimized = false

	MiniLogo.Visible = false

	MainHolder.Visible = true

	MainScale.Scale = 0.90

	Tween(
		MainScale,
		0.28,
		{
			Scale = 1
		},
		Enum.EasingStyle.Quint
	)
end

--==============================================================================
-- [SECTION 35] CLOSE FUNCTION
--==============================================================================

local function CloseGUI()

	if State.Destroyed then
		return
	end

	State.Destroyed = true
	State.Closed = true

	Tween(
		MainScale,
		0.2,
		{
			Scale = 0.94
		},
		Enum.EasingStyle.Quint
	)

	task.delay(0.2, function()

		DisconnectAll()

		pcall(function()
			ScreenGui:Destroy()
		end)
	end)
end

--==============================================================================
-- [SECTION 36] HEADER BUTTON CONNECTIONS
--==============================================================================

Connect(MinimizeButton.Activated, function()
	MinimizeGUI()
end)

Connect(CloseButton.Activated, function()
	CloseGUI()
end)

Connect(MiniLogo.Activated, function()

	-- Activated akan tetap dipanggil setelah touch/mouse selesai.
	-- Kalau sedang drag, jangan restore.
	if State.DragMovedMini then
		State.DragMovedMini = false
		return
	end

	RestoreGUI()
end)

--==============================================================================
-- [SECTION 37] MAIN WINDOW DRAG SYSTEM
--==============================================================================
-- INI FIX UNTUK BUG TELEPORT.
--
-- Ketika drag dimulai:
-- 1. Ambil posisi pointer saat itu.
-- 2. Ambil AbsolutePosition MainHolder saat itu.
-- 3. Saat bergerak, hitung DELTA.
-- 4. Tambahkan delta ke posisi awal.
--
-- Jadi posisi pertama tidak pernah dihitung dari 0,0.
--==============================================================================

local function GetViewport()
	return workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize
		or Vector2.new(1920, 1080)
end

local function ClampMainCenter(center)

	local viewport = GetViewport()

	local size = MainHolder.AbsoluteSize

	local halfX = size.X * 0.5
	local halfY = size.Y * 0.5

	local margin = State.Mobile and 5 or 10

	local minX = halfX + margin
	local maxX = viewport.X - halfX - margin

	local minY = halfY + margin
	local maxY = viewport.Y - halfY - margin

	if maxX < minX then
		minX = viewport.X * 0.5
		maxX = minX
	end

	if maxY < minY then
		minY = viewport.Y * 0.5
		maxY = minY
	end

	return Vector2.new(
		math.clamp(center.X, minX, maxX),
		math.clamp(center.Y, minY, maxY)
	)
end

local function BeginMainDrag(input)

	if State.Minimized or State.Destroyed then
		return
	end

	if input.UserInputType ~= Enum.UserInputType.MouseButton1
		and input.UserInputType ~= Enum.UserInputType.Touch then
		return
	end

	State.DraggingMain = true
	State.DragMovedMain = false

	State.MainDragInput = input

	State.MainDragStartPointer = input.Position

	State.MainDragStartAbsolute = MainHolder.AbsolutePosition
end

local function UpdateMainDrag(input)

	if not State.DraggingMain then
		return
	end

	if input.UserInputType ~= Enum.UserInputType.MouseMovement
		and input.UserInputType ~= Enum.UserInputType.Touch then
		return
	end

	local currentPointer = input.Position

	local delta = Vector2.new(
		currentPointer.X - State.MainDragStartPointer.X,
		currentPointer.Y - State.MainDragStartPointer.Y
	)

	if delta.Magnitude > 5 then
		State.DragMovedMain = true
	end

	local startCenter = State.MainDragStartAbsolute
		+ (MainHolder.AbsoluteSize * 0.5)

	local newCenter = startCenter + delta

	newCenter = ClampMainCenter(newCenter)

	MainHolder.AnchorPoint = Vector2.new(0.5, 0.5)

	MainHolder.Position = UDim2.fromOffset(
		newCenter.X,
		newCenter.Y
	)
end

local function EndMainDrag(input)

	if not State.DraggingMain then
		return
	end

	if input == State.MainDragInput
		or input.UserInputType == Enum.UserInputType.MouseButton1
		or input.UserInputType == Enum.UserInputType.Touch then

		State.DraggingMain = false
		State.MainDragInput = nil
	end
end

-- Header sendiri menjadi drag area,
-- TAPI tombol minimize/close berada di child area dan tidak ikut dipakai sebagai drag.
Connect(Header.InputBegan, function(input)

	if input.UserInputType ~= Enum.UserInputType.MouseButton1
		and input.UserInputType ~= Enum.UserInputType.Touch then
		return
	end

	local target = input.Target

	if target == MinimizeButton
		or target == CloseButton
		or target:IsDescendantOf(HeaderControls) then

		return
	end

	BeginMainDrag(input)
end)

Connect(UserInputService.InputChanged, function(input)

	if State.DraggingMain then
		UpdateMainDrag(input)
	end

	if State.DraggingMini then

		local currentPointer = input.Position

		local delta = Vector2.new(
			currentPointer.X - State.MiniDragStartPointer.X,
			currentPointer.Y - State.MiniDragStartPointer.Y
		)

		if delta.Magnitude > 5 then
			State.DragMovedMini = true
		end

		local viewport = GetViewport()

		local size = MiniLogo.AbsoluteSize

		local startCenter =
			State.MiniDragStartAbsolute
			+ (size * 0.5)

		local newCenter = startCenter + delta

		local halfX = size.X * 0.5
		local halfY = size.Y * 0.5

		newCenter = Vector2.new(
			math.clamp(
				newCenter.X,
				halfX + 4,
				viewport.X - halfX - 4
			),

			math.clamp(
				newCenter.Y,
				halfY + 4,
				viewport.Y - halfY - 4
			)
		)

		MiniLogo.Position = UDim2.fromOffset(
			newCenter.X,
			newCenter.Y
		)
	end
end)

Connect(UserInputService.InputEnded, function(input)

	EndMainDrag(input)

	if State.DraggingMini then
		State.DraggingMini = false
		State.MiniDragInput = nil
	end
end)

--==============================================================================
-- [SECTION 38] MINIMIZED LOGO DRAG SYSTEM
--==============================================================================
-- Prinsipnya sama dengan MainHolder:
-- simpan AbsolutePosition ketika drag dimulai.
-- Tidak menggunakan posisi mouse sebagai posisi logo.
-- Jadi tidak teleport pada drag pertama.
--==============================================================================

Connect(MiniLogo.InputBegan, function(input)

	if input.UserInputType ~= Enum.UserInputType.MouseButton1
		and input.UserInputType ~= Enum.UserInputType.Touch then
		return
	end

	State.DraggingMini = true
	State.DragMovedMini = false

	State.MiniDragInput = input

	State.MiniDragStartPointer = input.Position

	State.MiniDragStartAbsolute = MiniLogo.AbsolutePosition
end)

--==============================================================================
-- [SECTION 39] RESPONSIVE LAYOUT ENGINE
--==============================================================================

local LastMobile = nil

local function ApplyResponsiveLayout(force)

	local viewport = GetViewport()

	local mobile =
		viewport.X <= CONFIG.MobileWidth
		or viewport.Y <= CONFIG.MobileHeight

	if not force and LastMobile == mobile then

		-- Tetap update ukuran jika orientation/viewport berubah.
	else
		LastMobile = mobile
	end

	State.Mobile = mobile

	if mobile then

		--==============================================================
		-- MOBILE
		--==============================================================

		MainHolder.AnchorPoint = Vector2.new(0.5, 0.5)

		MainHolder.Position = UDim2.fromScale(0.5, 0.5)

		MainHolder.Size = UDim2.fromOffset(
			math.max(300, viewport.X - (CONFIG.MobileMargin * 2)),
			math.max(360, viewport.Y - (CONFIG.MobileMargin * 2))
		)

		-- Sidebar OFF
		Sidebar.Visible = false

		-- Mobile navigation ON
		MobileNav.Visible = true

		-- Content mengambil seluruh width
		Content.Position = UDim2.fromOffset(7, 7)

		Content.Size = UDim2.new(
			1,
			-14,
			1,
			-CONFIG.MobileNavHeight - 14
		)

		-- Header
		HeaderLogoZone.Position = UDim2.fromOffset(7, 8)
		HeaderLogoZone.Size = UDim2.fromOffset(58, 66)

		HeaderCenter.Position = UDim2.fromOffset(70, 9)

		-- EXCLUSIVE CONTROL ZONE tetap 108 px
		HeaderControls.Size = UDim2.fromOffset(106, 62)
		HeaderControls.Position = UDim2.new(1, -7, 0, 10)

		-- Title tidak boleh masuk zona kanan.
		HeaderCenter.Size = UDim2.new(
			1,
			-190,
			1,
			-18
		)

		TitleLabel.Text = "VANZ NEXUS"
		TitleLabel.TextSize = 18

		SubtitleLabel.Visible = false
		HeaderStatus.Visible = false

		-- Logo lebih kecil
		LogoPlate.Size = UDim2.fromOffset(52, 52)
		LogoRing.Size = UDim2.fromOffset(37, 37)
		LogoInnerRing.Size = UDim2.fromOffset(25, 25)
		LogoCore.Size = UDim2.fromOffset(13, 13)

		-- Header buttons tetap mudah disentuh
		MinimizeButton.Size = UDim2.fromOffset(49, 49)
		CloseButton.Size = UDim2.fromOffset(49, 49)

		-- Mobile mini logo
		MiniLogo.Size = UDim2.fromOffset(68, 68)

	else

		--==============================================================
		-- DESKTOP
		--==============================================================

		MainHolder.AnchorPoint = Vector2.new(0.5, 0.5)

		MainHolder.Size = UDim2.fromOffset(
			CONFIG.DesktopWidth,
			CONFIG.DesktopHeight
		)

		MainHolder.Position = UDim2.fromScale(0.5, 0.5)

		Sidebar.Visible = true
		MobileNav.Visible = false

		Content.Position = UDim2.new(
			0,
			CONFIG.SidebarWidth + 20,
			0,
			8
		)

		Content.Size = UDim2.new(
			1,
			-CONFIG.SidebarWidth - 30,
			1,
			-16
		)

		HeaderLogoZone.Position = UDim2.fromOffset(10, 8)
		HeaderLogoZone.Size = UDim2.fromOffset(68, 66)

		HeaderCenter.Position = UDim2.fromOffset(82, 10)

		HeaderCenter.Size = UDim2.new(
			1,
			-202,
			1,
			-20
		)

		HeaderControls.Size = UDim2.fromOffset(108, 62)
		HeaderControls.Position = UDim2.new(1, -9, 0, 10)

		TitleLabel.Text = CONFIG.Title
		TitleLabel.TextSize = 25

		SubtitleLabel.Visible = true
		HeaderStatus.Visible = true

		LogoPlate.Size = UDim2.fromOffset(58, 58)
		LogoRing.Size = UDim2.fromOffset(42, 42)
		LogoInnerRing.Size = UDim2.fromOffset(28, 28)
		LogoCore.Size = UDim2.fromOffset(15, 15)

		MinimizeButton.Size = UDim2.fromOffset(51, 51)
		CloseButton.Size = UDim2.fromOffset(51, 51)

		MiniLogo.Size = UDim2.fromOffset(78, 78)
	end
end

-- Initial responsive layout
ApplyResponsiveLayout(true)

--==============================================================================
-- [SECTION 40] CAMERA / SCREEN SIZE WATCHER
--==============================================================================

local Camera = workspace.CurrentCamera

local function ConnectCamera()
	Camera = workspace.CurrentCamera

	if not Camera then
		return
	end

	Connect(Camera:GetPropertyChangedSignal("ViewportSize"), function()

		if State.Destroyed then
			return
		end

		ApplyResponsiveLayout(true)
	end)
end

ConnectCamera()

Connect(workspace:GetPropertyChangedSignal("CurrentCamera"), function()
	ConnectCamera()
end)

--==============================================================================
-- [SECTION 41] FPS CALCULATOR
--==============================================================================

local fpsAccumulator = 0
local fpsFrames = 0

local telemetryAccumulator = 0
local watchdogAccumulator = 0

--==============================================================================
-- [SECTION 42] STATS HELPERS
--==============================================================================

local function GetPing()

	local success, value = pcall(function()

		local network = Stats.Network

		local serverStats = network.ServerStatsItem

		local pingItem = serverStats:FindFirstChild("Data Ping")

		if pingItem then
			return pingItem:GetValueString()
		end

		return nil
	end)

	if success and value then
		return tostring(value)
	end

	return "--"
end

local function GetMemory()

	local success, value = pcall(function()

		return Stats:GetTotalMemoryUsageMb()
	end)

	if success and value then
		return string.format("%.0f MB", value)
	end

	return "--"
end

local function FormatUptime(seconds)

	local total = math.floor(seconds)

	local hours = math.floor(total / 3600)

	local minutes = math.floor((total % 3600) / 60)

	local secs = total % 60

	return string.format(
		"%02d:%02d:%02d",
		hours,
		minutes,
		secs
	)
end

--==============================================================================
-- [SECTION 43] TELEMETRY UPDATE
--==============================================================================

local function UpdateTelemetry()

	State.Ping = GetPing()
	State.Memory = GetMemory()

	State.Uptime = os.clock()

	-- HOME
	if HomeCards.FPS then
		HomeCards.FPS.Text = string.format(
			"%d",
			math.floor(State.FPS + 0.5)
		)
	end

	if HomeCards.PING then
		HomeCards.PING.Text = State.Ping
	end

	if HomeCards.MEMORY then
		HomeCards.MEMORY.Text = State.Memory
	end

	if HomeCards.UPTIME then
		HomeCards.UPTIME.Text = FormatUptime(State.Uptime)
	end

	-- TELEMETRY
	if TelemetryValues.FPS then
		TelemetryValues.FPS.Text = string.format(
			"%d FPS",
			math.floor(State.FPS + 0.5)
		)
	end

	if TelemetryValues.PING then
		TelemetryValues.PING.Text = State.Ping
	end

	if TelemetryValues.MEMORY then
		TelemetryValues.MEMORY.Text = State.Memory
	end

	if TelemetryValues.UPTIME then
		TelemetryValues.UPTIME.Text =
			FormatUptime(State.Uptime)
	end

	if TelemetryValues.TAB then
		TelemetryValues.TAB.Text =
			State.CurrentTab
	end

	if TelemetryValues.STATE then
		TelemetryValues.STATE.Text =
			State.Minimized and "MINIMIZED" or "ACTIVE"
	end
end

--==============================================================================
-- [SECTION 44] ANIMATION ENGINE
--==============================================================================
-- Semua animasi ringan dijalankan dari satu RenderStepped.
--
-- Yang dianimasikan:
-- • Logo rotation
-- • Logo core breathing
-- • Mini logo ring
-- • Mini core
-- • Radar sweep
-- • Nexus core
-- • Header line
-- • Status pulse
-- • Dynamic accent hue
-- • Scanline
--==============================================================================

local RenderConnection

RenderConnection = Connect(
	RunService.RenderStepped,
	function(deltaTime)

		if State.Destroyed then
			return
		end

		State.AnimationTime += deltaTime

		--==============================================================
		-- FPS
		--==============================================================

		fpsAccumulator += deltaTime
		fpsFrames += 1

		if fpsAccumulator >= 0.5 then

			State.FPS =
				fpsFrames / fpsAccumulator

			fpsAccumulator = 0
			fpsFrames = 0
		end

		--==============================================================
		-- UPTIME
		--==============================================================

		State.Uptime = os.clock()

		--==============================================================
		-- SOFT ANIMATION MASTER SWITCH
		--==============================================================

		local softAnimation =
			VisualSettings.SoftAnimations

		local t = State.AnimationTime

		--==============================================================
		-- MAIN LOGO
		--==============================================================

		if softAnimation then

			LogoRing.Rotation =
				(t * 18) % 360

			LogoInnerRing.Rotation =
				(-t * 25) % 360

			local pulse =
				1
				+ math.sin(t * 3) * 0.08

			LogoCore.Size =
				UDim2.fromOffset(
					15 * pulse,
					15 * pulse
				)

			-- Mini logo
			MiniRingOuter.Rotation =
				(t * 35) % 360

			MiniRingInner.Rotation =
				(-t * 48) % 360

			local miniPulse =
				1
				+ math.sin(t * 3.5) * 0.08

			MiniCore.Size =
				UDim2.fromOffset(
					21 * miniPulse,
					21 * miniPulse
				)

			-- Nexus
			NexusRing1.Rotation =
				(t * 16) % 360

			NexusRing2.Rotation =
				(-t * 23) % 360

			local nexusPulse =
				1
				+ math.sin(t * 2.4) * 0.1

			NexusCoreCenter.Size =
				UDim2.fromOffset(
					34 * nexusPulse,
					34 * nexusPulse
				)

			-- Status pulse
			local statusPulse =
				0.8
				+ ((math.sin(t * 3) + 1) * 0.1)

			HeroStatusDot.BackgroundTransparency =
				1 - statusPulse
		end

		--==============================================================
		-- RADAR
		--==============================================================

		if VisualSettings.Radar and CONFIG.EnableRadar then

			RadarSweep.Rotation =
				(t * 70) % 360

			Radar.Visible = true
		else
			Radar.Visible = false
		end

		--==============================================================
		-- MINI SCANLINE
		--==============================================================

		local scanY =
			0.15
			+ ((math.sin(t * 2) + 1) * 0.35)

		MiniScan.Position =
			UDim2.new(
				0.5,
				0,
				scanY,
				0
			)

		--==============================================================
		-- ORBIT DOT
		--==============================================================

		local orbitAngle = t * 2

		local orbitRadius = 27

		MiniOrbitDot.Position =
			UDim2.new(
				0.5,
				math.cos(orbitAngle) * orbitRadius,
				0.5,
				math.sin(orbitAngle) * orbitRadius
			)

		--==============================================================
		-- NEON AMBIENCE
		--==============================================================

		if VisualSettings.NeonAmbience then

			State.Hue =
				(State.Hue + deltaTime * 0.025)
				% 1

			local dynamic =
				Color3.fromHSV(
					State.Hue,
					0.42,
					1
				)

			-- Sangat halus, bukan full rainbow.
			TopLine.BackgroundColor3 =
				dynamic

		else

			TopLine.BackgroundColor3 =
				CONFIG.Colors.Cyan
		end

		--==============================================================
		-- TELEMETRY TIMER
		--==============================================================

		telemetryAccumulator += deltaTime

		if telemetryAccumulator >= 1 then

			telemetryAccumulator = 0

			if CONFIG.EnableTelemetry then
				UpdateTelemetry()
			end
		end

		--==============================================================
		-- WATCHDOG
		--==============================================================

		watchdogAccumulator += deltaTime

		if watchdogAccumulator >= 1 then

			watchdogAccumulator = 0

			if ScreenGui.Parent ~= PlayerGui then

				pcall(function()
					ScreenGui.Parent = PlayerGui
				end)
			end

			if ScreenGui.Enabled ~= true then
				ScreenGui.Enabled = true
			end

			ScreenGui.DisplayOrder =
				CONFIG.DisplayOrder
		end
	end
)

--==============================================================================
-- [SECTION 45] INITIAL TELEMETRY
--==============================================================================

UpdateTelemetry()

--==============================================================================
-- [SECTION 46] PUBLIC API
--==============================================================================

_G.vanz = _G.vanz or {}

_G.vanz.Open = function()
	if State.Destroyed then
		return
	end

	if State.Minimized then
		RestoreGUI()
	end

	State.Closed = false

	ScreenGui.Enabled = true
end

_G.vanz.Restore = function()
	if State.Destroyed then
		return
	end

	RestoreGUI()
end

_G.vanz.Minimize = function()
	if State.Destroyed then
		return
	end

	MinimizeGUI()
end

_G.vanz.Close = function()
	CloseGUI()
end

_G.vanz.GetState = function()

	return {
		Destroyed = State.Destroyed,
		Minimized = State.Minimized,
		Closed = State.Closed,
		Mobile = State.Mobile,
		CurrentTab = State.CurrentTab,
		FPS = State.FPS,
		Ping = State.Ping,
		Memory = State.Memory,
		Uptime = State.Uptime,
	}
end

_G.vanz.SetScale = function(scale)

	if State.Destroyed then
		return
	end

	scale = tonumber(scale)

	if not scale then
		return
	end

	scale = math.clamp(scale, 0.75, 1.25)

	MainScale.Scale = scale
end

--==============================================================================
-- [SECTION 47] STARTUP ANIMATION
--==============================================================================

MainScale.Scale = 0.94

Window.BackgroundTransparency = 1

Tween(
	MainScale,
	0.4,
	{
		Scale = 1
	},
	Enum.EasingStyle.Quint
)

Tween(
	Window,
	0.4,
	{
		BackgroundTransparency = 0
	},
	Enum.EasingStyle.Quint
)

--==============================================================================
-- [SECTION 48] FINAL MOBILE SAFETY PASS
--==============================================================================

task.defer(function()

	if State.Destroyed then
		return
	end

	ApplyResponsiveLayout(true)

	-- Pastikan kontrol selalu visible.
	HeaderControls.Visible = true
	MinimizeButton.Visible = true
	CloseButton.Visible = true

	-- Pastikan header tidak tertutup body.
	Header.ZIndex = 150
	HeaderControls.ZIndex = 220
	MinimizeButton.ZIndex = 225
	CloseButton.ZIndex = 225
end)

--==============================================================================
-- [SECTION 49] CHARACTER RESPAWN SAFETY
--==============================================================================

Connect(LocalPlayer.CharacterAdded, function()

	task.wait(0.5)

	if State.Destroyed then
		return
	end

	ScreenGui.Enabled = true
	ScreenGui.DisplayOrder = CONFIG.DisplayOrder

	ApplyResponsiveLayout(true)
end)

--==============================================================================
-- [SECTION 50] CLEANUP IF GUI IS EXTERNALLY DESTROYED
--==============================================================================

Connect(ScreenGui.AncestryChanged, function(_, parent)

	if parent == nil and not State.Destroyed then

		State.Destroyed = true

		DisconnectAll()

		_G.vanz = nil
	end
end)

--==============================================================================
-- [END]
--
-- MAIN STRUCTURE:
--
-- ScreenGui
-- └── MainHolder
--     └── Window
--         ├── Header
--         │   ├── Logo
--         │   ├── Title Zone
--         │   └── Exclusive Control Zone
--         │       ├── Minimize
--         │       └── Close
--         │
--         └── Body
--             ├── Sidebar
--             │   └── Tabs
--             │
--             └── Content
--                 ├── HOME
--                 ├── VISUALS
--                 ├── TELEMETRY
--                 ├── NEXUS
--                 └── ABOUT
--
-- ScreenGui
-- └── MiniLogo
--     ├── Ring
--     ├── Inner Ring
--     ├── Core
--     ├── Scanline
--     └── Orbit Dot
--
-- DRAG:
-- Main GUI  = AbsolutePosition + pointer delta
-- Mini Logo = AbsolutePosition + pointer delta
--
-- Jadi drag pertama tidak menggunakan posisi mouse sebagai posisi baru,
-- sehingga tidak ada lagi bug teleport ke pojok kiri atas.
--==============================================================================