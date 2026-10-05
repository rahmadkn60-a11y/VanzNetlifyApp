--[[
================================================================================
 VANZ NEXUS // ULTIMATE ROBOTIC MOD-MENU UI
================================================================================

 TYPE:
 LocalScript

 RECOMMENDED LOCATION:
 StarterPlayer > StarterPlayerScripts
 atau
 StarterGui

================================================================================
 CORE DESIGN
================================================================================

 MAIN WINDOW
 ├── HEADER
 │    ├── LOGO
 │    ├── TITLE
 │    ├── STATUS
 │    └── [ MINIMIZE ][ CLOSE ]
 │
 ├── SIDEBAR
 │    ├── HOME
 │    ├── VISUALS
 │    ├── SYSTEM
 │    ├── NEXUS
 │    ├── SETTINGS
 │    └── ABOUT
 │
 └── PAGE AREA
      └── ScrollingFrame
           ├── Cards
           ├── Switches
           ├── Status
           └── Controls

 MOBILE
 ├── HEADER
 ├── SCROLLING PAGE
 └── BOTTOM NAVIGATION

 MINIMIZED
 └── NEXUS CORE
      ├── draggable
      ├── animated
      ├── no external shadow
      └── tap = restore

================================================================================
 DRAG FIX
================================================================================

 BUG LAMA:
 AbsolutePosition -> delta -> Position
 kadang menghasilkan sedikit teleport ketika layout/viewport berubah.

 SISTEM BARU:
 1. Ambil posisi UDim2 saat drag dimulai.
 2. Convert Scale + Offset ke pixel berdasarkan viewport saat itu.
 3. Simpan pointer awal.
 4. Hitung delta pointer.
 5. NewPosition = StartPosition + Delta.
 6. Clamp ke viewport.
 7. Setelah drag pertama, Position menjadi offset murni.

 Jadi tidak ada perhitungan ulang dari AbsolutePosition object.

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

	Name = "VANZ_ULTIMATE_NEXUS",

	DisplayOrder = 999999999,

	DesktopWidth = 1020,
	DesktopHeight = 650,

	MobileMargin = 6,

	HeaderHeight = 82,

	SidebarWidth = 200,

	MobileNavHeight = 72,

	AnimationSpeed = 1,

	Colors = {

		Background = Color3.fromRGB(4, 6, 13),

		Panel = Color3.fromRGB(8, 11, 21),

		Panel2 = Color3.fromRGB(12, 16, 29),

		Panel3 = Color3.fromRGB(17, 22, 39),

		Panel4 = Color3.fromRGB(21, 27, 47),

		Cyan = Color3.fromRGB(45, 235, 255),

		Blue = Color3.fromRGB(72, 126, 255),

		Violet = Color3.fromRGB(160, 85, 255),

		Pink = Color3.fromRGB(255, 75, 190),

		White = Color3.fromRGB(240, 247, 255),

		SoftWhite = Color3.fromRGB(180, 195, 215),

		Muted = Color3.fromRGB(91, 106, 130),

		Success = Color3.fromRGB(67, 255, 169),

		Warning = Color3.fromRGB(255, 190, 70),

		Danger = Color3.fromRGB(255, 72, 105),

		Line = Color3.fromRGB(41, 61, 96),
	},
}

--==============================================================================
-- [SECTION 03] STATE
--==============================================================================

local State = {

	Destroyed = false,

	Minimized = false,

	Mobile = false,

	CurrentTab = "HOME",

	FPS = 0,

	Ping = "--",

	Memory = "--",

	Uptime = 0,

	AnimationTime = 0,

	Hue = 0,

	DraggingMain = false,

	DraggingMini = false,

	MainMoved = false,

	MiniMoved = false,

	MainDragInput = nil,

	MiniDragInput = nil,

	MainPointerStart = nil,

	MainPositionStart = nil,

	MiniPointerStart = nil,

	MiniPositionStart = nil,

	PageChanging = false,
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
-- [SECTION 05] DESTROY OLD VANZ GUI
--==============================================================================

for _, gui in ipairs(PlayerGui:GetChildren()) do

	if gui:IsA("ScreenGui") then

		if
			gui.Name == CONFIG.Name
			or gui.Name == "VANZ_NEXUS_ROBOTIC_ANIME"
			or gui.Name == "VANZ_ROBOTIC_GUI"
			or gui.Name == "VANZ_PREMIUM_GUI"
			or gui.Name == "VANZ_SOFT_ROBOTIC_GUI"
			or gui.Name == "VANZ_NEXUS_GUI"
		then

			pcall(function()
				gui:Destroy()
			end)
		end
	end
end

--==============================================================================
-- [SECTION 06] UI FACTORY
--==============================================================================

local function Create(className, properties, parent)

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

local function AddCorner(object, radius)

	return Create("UICorner", {
		CornerRadius = UDim.new(0, radius),
	}, object)
end

local function AddStroke(object, color, transparency, thickness)

	return Create("UIStroke", {

		Color = color or CONFIG.Colors.Cyan,

		Transparency = transparency or 0,

		Thickness = thickness or 1,

		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,

	}, object)
end

local function AddGradient(object, keypoints, rotation)

	return Create("UIGradient", {

		Color = ColorSequence.new(keypoints),

		Rotation = rotation or 0,

	}, object)
end

local function Tween(object, duration, properties, easing, direction)

	if not object then
		return
	end

	local tweenInfo = TweenInfo.new(

		duration or 0.25,

		easing or Enum.EasingStyle.Quint,

		direction or Enum.EasingDirection.Out

	)

	local tween = TweenService:Create(
		object,
		tweenInfo,
		properties
	)

	tween:Play()

	return tween
end

--==============================================================================
-- [SECTION 07] ROOT SCREEN GUI
--==============================================================================

local ScreenGui = Create("ScreenGui", {

	Name = CONFIG.Name,

	IgnoreGuiInset = true,

	ResetOnSpawn = false,

	ZIndexBehavior = Enum.ZIndexBehavior.Global,

	DisplayOrder = CONFIG.DisplayOrder,

	Enabled = true,

}, PlayerGui)

pcall(function()
	ScreenGui.ScreenInsets = Enum.ScreenInsets.None
end)

--==============================================================================
-- [SECTION 08] MAIN WINDOW HOLDER
--==============================================================================

local MainHolder = Create("Frame", {

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

local MainScale = Create("UIScale", {

	Scale = 1,

}, MainHolder)

--==============================================================================
-- [SECTION 09] MAIN WINDOW
--==============================================================================

local Window = Create("Frame", {

	Name = "Window",

	Size = UDim2.fromScale(1, 1),

	BackgroundColor3 = CONFIG.Colors.Background,

	BorderSizePixel = 0,

	ClipsDescendants = true,

	ZIndex = 100,

}, MainHolder)

AddCorner(Window, 17)

AddStroke(
	Window,
	Color3.fromRGB(54, 81, 126),
	0.18,
	1
)

AddGradient(Window, {

	ColorSequenceKeypoint.new(
		0,
		Color3.fromRGB(5, 8, 17)
	),

	ColorSequenceKeypoint.new(
		0.5,
		Color3.fromRGB(7, 11, 22)
	),

	ColorSequenceKeypoint.new(
		1,
		Color3.fromRGB(15, 7, 25)
	),

}, 135)

--==============================================================================
-- [SECTION 10] TOP HOLOGRAPHIC LINE
--==============================================================================

local TopLaser = Create("Frame", {

	Name = "TopLaser",

	Position = UDim2.fromOffset(0, 0),

	Size = UDim2.new(1, 0, 0, 2),

	BackgroundColor3 = CONFIG.Colors.Cyan,

	BackgroundTransparency = 0.1,

	BorderSizePixel = 0,

	ZIndex = 500,

}, Window)

--==============================================================================
-- [SECTION 11] HEADER
--==============================================================================

local Header = Create("Frame", {

	Name = "Header",

	Position = UDim2.fromOffset(0, 0),

	Size = UDim2.new(
		1,
		0,
		0,
		CONFIG.HeaderHeight
	),

	BackgroundTransparency = 1,

	BorderSizePixel = 0,

	ZIndex = 200,

}, Window)

--==============================================================================
-- [SECTION 12] HEADER LOGO
--==============================================================================

local HeaderLogo = Create("Frame", {

	Position = UDim2.fromOffset(9, 9),

	Size = UDim2.fromOffset(64, 64),

	BackgroundColor3 = CONFIG.Colors.Panel3,

	BorderSizePixel = 0,

	ZIndex = 210,

}, Header)

AddCorner(HeaderLogo, 16)
AddStroke(HeaderLogo, CONFIG.Colors.Cyan, 0.3, 1)

local HeaderRing1 = Create("Frame", {

	AnchorPoint = Vector2.new(0.5, 0.5),

	Position = UDim2.fromScale(0.5, 0.5),

	Size = UDim2.fromOffset(48, 48),

	BackgroundTransparency = 1,

	BorderSizePixel = 0,

	ZIndex = 211,

}, HeaderLogo)

AddCorner(HeaderRing1, 100)
AddStroke(HeaderRing1, CONFIG.Colors.Cyan, 0.12, 2)

local HeaderRing2 = Create("Frame", {

	AnchorPoint = Vector2.new(0.5, 0.5),

	Position = UDim2.fromScale(0.5, 0.5),

	Size = UDim2.fromOffset(32, 32),

	BackgroundTransparency = 1,

	BorderSizePixel = 0,

	ZIndex = 212,

}, HeaderLogo)

AddCorner(HeaderRing2, 100)
AddStroke(HeaderRing2, CONFIG.Colors.Violet, 0.2, 1)

local HeaderCore = Create("Frame", {

	AnchorPoint = Vector2.new(0.5, 0.5),

	Position = UDim2.fromScale(0.5, 0.5),

	Size = UDim2.fromOffset(15, 15),

	BackgroundColor3 = CONFIG.Colors.Cyan,

	BorderSizePixel = 0,

	ZIndex = 213,

}, HeaderLogo)

AddCorner(HeaderCore, 100)

local HeaderCoreText = Create("TextLabel", {

	Size = UDim2.fromScale(1, 1),

	BackgroundTransparency = 1,

	Text = "N",

	TextColor3 = CONFIG.Colors.Background,

	TextSize = 9,

	Font = Enum.Font.GothamBlack,

	ZIndex = 214,

}, HeaderCore)

--==============================================================================
-- [SECTION 13] HEADER TITLE ZONE
--==============================================================================

local HeaderTitleZone = Create("Frame", {

	Position = UDim2.fromOffset(82, 8),

	Size = UDim2.new(
		1,
		-205,
		1,
		-16
	),

	BackgroundTransparency = 1,

	BorderSizePixel = 0,

	ZIndex = 205,

}, Header)

local HeaderTitle = Create("TextLabel", {

	Position = UDim2.fromOffset(0, 4),

	Size = UDim2.new(
		1,
		0,
		0,
		30
	),

	BackgroundTransparency = 1,

	Text = "VANZ NEXUS",

	TextColor3 = CONFIG.Colors.White,

	TextSize = 24,

	Font = Enum.Font.GothamBlack,

	TextXAlignment = Enum.TextXAlignment.Left,

	TextTruncate = Enum.TextTruncate.AtEnd,

	ZIndex = 206,

}, HeaderTitleZone)

local HeaderSubtitle = Create("TextLabel", {

	Position = UDim2.fromOffset(0, 35),

	Size = UDim2.new(
		1,
		0,
		0,
		18
	),

	BackgroundTransparency = 1,

	Text = "ROBOTIC // ANIME COMMAND CENTER",

	TextColor3 = CONFIG.Colors.Cyan,

	TextSize = 9,

	Font = Enum.Font.GothamBold,

	TextXAlignment = Enum.TextXAlignment.Left,

	TextTruncate = Enum.TextTruncate.AtEnd,

	ZIndex = 206,

}, HeaderTitleZone)

local HeaderStatus = Create("TextLabel", {

	Position = UDim2.fromOffset(0, 55),

	Size = UDim2.new(
		1,
		0,
		0,
		15
	),

	BackgroundTransparency = 1,

	Text = "● NEXUS LINK ACTIVE // SYSTEM READY",

	TextColor3 = CONFIG.Colors.Success,

	TextSize = 8,

	Font = Enum.Font.GothamBold,

	TextXAlignment = Enum.TextXAlignment.Left,

	TextTruncate = Enum.TextTruncate.AtEnd,

	ZIndex = 206,

}, HeaderTitleZone)

--==============================================================================
-- [SECTION 14] EXCLUSIVE HEADER CONTROLS
--==============================================================================

local HeaderControls = Create("Frame", {

	Name = "HeaderControls",

	AnchorPoint = Vector2.new(1, 0),

	Position = UDim2.new(
		1,
		-8,
		0,
		9
	),

	Size = UDim2.fromOffset(
		108,
		64
	),

	BackgroundTransparency = 1,

	BorderSizePixel = 0,

	ZIndex = 400,

}, Header)

local HeaderControlsLayout = Create("UIListLayout", {

	FillDirection = Enum.FillDirection.Horizontal,

	HorizontalAlignment = Enum.HorizontalAlignment.Right,

	VerticalAlignment = Enum.VerticalAlignment.Center,

	Padding = UDim.new(0, 6),

	SortOrder = Enum.SortOrder.LayoutOrder,

}, HeaderControls)

local function CreateControlButton(name, text, accent)

	local button = Create("TextButton", {

		Name = name,

		Size = UDim2.fromOffset(
			51,
			51
		),

		BackgroundColor3 = CONFIG.Colors.Panel3,

		BackgroundTransparency = 0.02,

		BorderSizePixel = 0,

		AutoButtonColor = false,

		Text = text,

		TextColor3 = CONFIG.Colors.White,

		TextSize = 21,

		Font = Enum.Font.GothamBlack,

		ZIndex = 410,

	}, HeaderControls)

	AddCorner(button, 13)

	AddStroke(
		button,
		accent,
		0.3,
		1
	)

	local bottom = Create("Frame", {

		AnchorPoint = Vector2.new(
			0.5,
			1
		),

		Position = UDim2.new(
			0.5,
			0,
			1,
			-3
		),

		Size = UDim2.fromOffset(
			22,
			2
		),

		BackgroundColor3 = accent,

		BorderSizePixel = 0,

		ZIndex = 411,

	}, button)

	AddCorner(bottom, 5)

	Connect(button.MouseEnter, function()

		Tween(
			button,
			0.14,
			{
				BackgroundColor3 =
					Color3.fromRGB(
						24,
						32,
						53
					)
			}
		)

		Tween(
			bottom,
			0.14,
			{
				Size = UDim2.fromOffset(
					32,
					2
				)
			}
		)
	end)

	Connect(button.MouseLeave, function()

		Tween(
			button,
			0.14,
			{
				BackgroundColor3 =
					CONFIG.Colors.Panel3
			}
		)

		Tween(
			bottom,
			0.14,
			{
				Size = UDim2.fromOffset(
					22,
					2
				)
			}
		)
	end)

	return button
end

local MinimizeButton = CreateControlButton(
	"Minimize",
	"—",
	CONFIG.Colors.Cyan
)

local CloseButton = CreateControlButton(
	"Close",
	"×",
	CONFIG.Colors.Danger
)

--==============================================================================
-- [SECTION 15] BODY
--==============================================================================

local Body = Create("Frame", {

	Name = "Body",

	Position = UDim2.fromOffset(
		0,
		CONFIG.HeaderHeight
	),

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
-- [SECTION 16] SIDEBAR
--==============================================================================

local Sidebar = Create("Frame", {

	Name = "Sidebar",

	Position = UDim2.fromOffset(
		9,
		8
	),

	Size = UDim2.new(
		0,
		CONFIG.SidebarWidth,
		1,
		-16
	),

	BackgroundColor3 = CONFIG.Colors.Panel,

	BorderSizePixel = 0,

	ZIndex = 125,

}, Body)

AddCorner(Sidebar, 14)
AddStroke(Sidebar, CONFIG.Colors.Line, 0.35, 1)

local SidebarHeader = Create("TextLabel", {

	Position = UDim2.fromOffset(
		15,
		13
	),

	Size = UDim2.new(
		1,
		-30,
		0,
		24
	),

	BackgroundTransparency = 1,

	Text = "NEXUS MENU",

	TextColor3 = CONFIG.Colors.White,

	TextSize = 14,

	Font = Enum.Font.GothamBlack,

	TextXAlignment = Enum.TextXAlignment.Left,

	ZIndex = 126,

}, Sidebar)

local SidebarSub = Create("TextLabel", {

	Position = UDim2.fromOffset(
		15,
		36
	),

	Size = UDim2.new(
		1,
		-30,
		0,
		18
	),

	BackgroundTransparency = 1,

	Text = "CONTROL MATRIX",

	TextColor3 = CONFIG.Colors.Muted,

	TextSize = 8,

	Font = Enum.Font.GothamBold,

	TextXAlignment = Enum.TextXAlignment.Left,

	ZIndex = 126,

}, Sidebar)

local SidebarLine = Create("Frame", {

	Position = UDim2.fromOffset(
		15,
		61
	),

	Size = UDim2.new(
		1,
		-30,
		0,
		1
	),

	BackgroundColor3 = CONFIG.Colors.Cyan,

	BackgroundTransparency = 0.7,

	BorderSizePixel = 0,

	ZIndex = 126,

}, Sidebar)

--==============================================================================
-- [SECTION 17] TAB DEFINITIONS
--==============================================================================

local Tabs = {

	{
		Id = "HOME",
		Name = "HOME",
		Icon = "⌂",
		Description = "Overview",
	},

	{
		Id = "VISUALS",
		Name = "VISUALS",
		Icon = "◈",
		Description = "Appearance",
	},

	{
		Id = "SYSTEM",
		Name = "SYSTEM",
		Icon = "⌁",
		Description = "Telemetry",
	},

	{
		Id = "NEXUS",
		Name = "NEXUS",
		Icon = "✦",
		Description = "Core",
	},

	{
		Id = "SETTINGS",
		Name = "SETTINGS",
		Icon = "⚙",
		Description = "Options",
	},

	{
		Id = "ABOUT",
		Name = "ABOUT",
		Icon = "?",
		Description = "Information",
	},
}

local TabButtons = {}
local Pages = {}

--==============================================================================
-- [SECTION 18] CONTENT HOLDER
--==============================================================================

local ContentHolder = Create("Frame", {

	Name = "ContentHolder",

	Position = UDim2.new(
		0,
		CONFIG.SidebarWidth + 18,
		0,
		8
	),

	Size = UDim2.new(
		1,
		-CONFIG.SidebarWidth - 27,
		1,
		-16
	),

	BackgroundColor3 = CONFIG.Colors.Panel,

	BorderSizePixel = 0,

	ClipsDescendants = true,

	ZIndex = 124,

}, Body)

AddCorner(ContentHolder, 14)
AddStroke(ContentHolder, CONFIG.Colors.Line, 0.45, 1)

--==============================================================================
-- [SECTION 19] SIDEBAR TAB CREATION
--==============================================================================

local function CreateSidebarTab(tab, index)

	local button = Create("TextButton", {

		Name = tab.Id .. "Tab",

		Position = UDim2.fromOffset(
			9,
			75 + ((index - 1) * 56)
		),

		Size = UDim2.new(
			1,
			-18,
			0,
			48
		),

		BackgroundColor3 = CONFIG.Colors.Panel2,

		BackgroundTransparency = 0.15,

		BorderSizePixel = 0,

		AutoButtonColor = false,

		Text = "",

		ZIndex = 130,

	}, Sidebar)

	AddCorner(button, 11)

	local activeBar = Create("Frame", {

		Position = UDim2.fromOffset(
			0,
			9
		),

		Size = UDim2.fromOffset(
			3,
			30
		),

		BackgroundColor3 = CONFIG.Colors.Cyan,

		BackgroundTransparency = 1,

		BorderSizePixel = 0,

		ZIndex = 134,

	}, button)

	AddCorner(activeBar, 5)

	local iconBox = Create("Frame", {

		Position = UDim2.fromOffset(
			7,
			6
		),

		Size = UDim2.fromOffset(
			36,
			36
		),

		BackgroundColor3 = CONFIG.Colors.Panel3,

		BorderSizePixel = 0,

		ZIndex = 131,

	}, button)

	AddCorner(iconBox, 10)

	AddStroke(
		iconBox,
		CONFIG.Colors.Cyan,
		0.72,
		1
	)

	local icon = Create("TextLabel", {

		Size = UDim2.fromScale(
			1,
			1
		),

		BackgroundTransparency = 1,

		Text = tab.Icon,

		TextColor3 = CONFIG.Colors.SoftWhite,

		TextSize = 17,

		Font = Enum.Font.GothamBold,

		ZIndex = 132,

	}, iconBox)

	local title = Create("TextLabel", {

		Position = UDim2.fromOffset(
			51,
			6
		),

		Size = UDim2.new(
			1,
			-60,
			0,
			19
		),

		BackgroundTransparency = 1,

		Text = tab.Name,

		TextColor3 = CONFIG.Colors.SoftWhite,

		TextSize = 11,

		Font = Enum.Font.GothamBlack,

		TextXAlignment = Enum.TextXAlignment.Left,

		ZIndex = 132,

	}, button)

	local description = Create("TextLabel", {

		Position = UDim2.fromOffset(
			51,
			25
		),

		Size = UDim2.new(
			1,
			-60,
			0,
			15
		),

		BackgroundTransparency = 1,

		Text = tab.Description,

		TextColor3 = CONFIG.Colors.Muted,

		TextSize = 8,

		Font = Enum.Font.GothamMedium,

		TextXAlignment = Enum.TextXAlignment.Left,

		ZIndex = 132,

	}, button)

	TabButtons[tab.Id] = {

		Button = button,

		Icon = icon,

		Title = title,

		Description = description,

		ActiveBar = activeBar,

	}

	Connect(button.MouseEnter, function()

		if State.CurrentTab ~= tab.Id then

			Tween(
				button,
				0.12,
				{
					BackgroundColor3 =
						Color3.fromRGB(
							18,
							25,
							43
						)
				}
			)
		end
	end)

	Connect(button.MouseLeave, function()

		if State.CurrentTab ~= tab.Id then

			Tween(
				button,
				0.12,
				{
					BackgroundColor3 =
						CONFIG.Colors.Panel2
				}
			)
		end
	end)

	Connect(button.Activated, function()

		if State.CurrentTab == tab.Id then
			return
		end

		State.CurrentTab = tab.Id

		-- Update tab visuals
		for id, data in pairs(TabButtons) do

			local active = id == tab.Id

			Tween(
				data.Button,
				0.16,
				{
					BackgroundColor3 =
						active
						and Color3.fromRGB(
							18,
							31,
							51
						)
						or CONFIG.Colors.Panel2
				}
			)

			Tween(
				data.Icon,
				0.16,
				{
					TextColor3 =
						active
						and CONFIG.Colors.Cyan
						or CONFIG.Colors.SoftWhite
				}
			)

			Tween(
				data.Title,
				0.16,
				{
					TextColor3 =
						active
						and CONFIG.Colors.White
						or CONFIG.Colors.SoftWhite
				}
			)

			Tween(
				data.ActiveBar,
				0.16,
				{
					BackgroundTransparency =
						active and 0 or 1
				}
			)
		end

		-- Page transition
		for id, page in pairs(Pages) do

			if id == tab.Id then

				page.Visible = true

				local scrolling = page

				scrolling.CanvasPosition =
					Vector2.new(
						0,
						0
					)

				scrolling.Position =
					UDim2.new(
						0,
						18,
						0,
						0
					)

				Tween(
					scrolling,
					0.24,
					{
						Position =
							UDim2.new(
								0,
								0,
								0,
								0
							)
					},
					Enum.EasingStyle.Quint
				)

			else

				page.Visible = false
			end
		end

		-- Mobile state
		for id, data in pairs(MobileTabButtons) do

			local active = id == tab.Id

			Tween(
				data.Button,
				0.15,
				{
					BackgroundColor3 =
						active
						and Color3.fromRGB(
							18,
							31,
							51
						)
						or CONFIG.Colors.Panel2
				}
			)

			Tween(
				data.Icon,
				0.15,
				{
					TextColor3 =
						active
						and CONFIG.Colors.Cyan
						or CONFIG.Colors.SoftWhite
				}
			)

			Tween(
				data.Title,
				0.15,
				{
					TextColor3 =
						active
						and CONFIG.Colors.White
						or CONFIG.Colors.Muted
				}
			)
		end
	end)

	return button
end

for index, tab in ipairs(Tabs) do

	CreateSidebarTab(
		tab,
		index
	)
end

--==============================================================================
-- [SECTION 20] SIDEBAR STATUS
--==============================================================================

local SidebarStatus = Create("Frame", {

	AnchorPoint = Vector2.new(
		0,
		1
	),

	Position = UDim2.new(
		0,
		9,
		1,
		-9
	),

	Size = UDim2.new(
		1,
		-18,
		0,
		72
	),

	BackgroundColor3 = CONFIG.Colors.Panel2,

	BorderSizePixel = 0,

	ZIndex = 130,

}, Sidebar)

AddCorner(SidebarStatus, 11)
AddStroke(
	SidebarStatus,
	CONFIG.Colors.Success,
	0.65,
	1
)

local SidebarStatusTitle = Create("TextLabel", {

	Position = UDim2.fromOffset(
		12,
		9
	),

	Size = UDim2.new(
		1,
		-24,
		0,
		16
	),

	BackgroundTransparency = 1,

	Text = "CORE STATUS",

	TextColor3 = CONFIG.Colors.Muted,

	TextSize = 8,

	Font = Enum.Font.GothamBlack,

	TextXAlignment = Enum.TextXAlignment.Left,

	ZIndex = 131,

}, SidebarStatus)

local SidebarStatusValue = Create("TextLabel", {

	Position = UDim2.fromOffset(
		12,
		27
	),

	Size = UDim2.new(
		1,
		-24,
		0,
		25
	),

	BackgroundTransparency = 1,

	Text = "ONLINE",

	TextColor3 = CONFIG.Colors.Success,

	TextSize = 16,

	Font = Enum.Font.GothamBlack,

	TextXAlignment = Enum.TextXAlignment.Left,

	ZIndex = 131,

}, SidebarStatus)

local SidebarStatusDot = Create("Frame", {

	AnchorPoint = Vector2.new(
		1,
		0.5
	),

	Position = UDim2.new(
		1,
		-13,
		0.5,
		5
	),

	Size = UDim2.fromOffset(
		8,
		8
	),

	BackgroundColor3 = CONFIG.Colors.Success,

	BorderSizePixel = 0,

	ZIndex = 132,

}, SidebarStatus)

AddCorner(SidebarStatusDot, 100)

--==============================================================================
-- [SECTION 21] PAGE FACTORY
--==============================================================================

local function CreatePage(id)

	-- ScrollingFrame adalah inti perbaikan:
	-- semua content yang panjang bisa digeser.
	local page = Create("ScrollingFrame", {

		Name = id .. "Page",

		Position = UDim2.fromOffset(
			0,
			0
		),

		Size = UDim2.fromScale(
			1,
			1
		),

		BackgroundTransparency = 1,

		BorderSizePixel = 0,

		ScrollBarThickness = 4,

		ScrollBarImageColor3 =
			CONFIG.Colors.Cyan,

		ScrollBarImageTransparency = 0.3,

		ScrollingDirection =
			Enum.ScrollingDirection.Y,

		CanvasSize = UDim2.new(
			0,
			0,
			0,
			0
		),

		AutomaticCanvasSize =
			Enum.AutomaticSize.Y,

		ElasticBehavior =
			Enum.ElasticBehavior.Always,

		Visible = false,

		ClipsDescendants = true,

		ZIndex = 130,

	}, ContentHolder)

	Pages[id] = page

	return page
end

--==============================================================================
-- [SECTION 22] PAGE PADDING
--==============================================================================

local function AddPagePadding(page)

	Create("UIPadding", {

		PaddingTop = UDim.new(
			0,
			14
		),

		PaddingBottom = UDim.new(
			0,
			20
		),

		PaddingLeft = UDim.new(
			0,
			15
		),

		PaddingRight = UDim.new(
			0,
			15
		),

	}, page)

end

--==============================================================================
-- [SECTION 23] CARD FACTORY
--==============================================================================

local function Card(
	parent,
	title,
	description,
	height
)

	local card = Create("Frame", {

		Size = UDim2.new(
			1,
			0,
			0,
			height or 100
		),

		BackgroundColor3 =
			CONFIG.Colors.Panel2,

		BorderSizePixel = 0,

		ZIndex = 135,

	}, parent)

	AddCorner(card, 14)

	AddStroke(
		card,
		CONFIG.Colors.Line,
		0.42,
		1
	)

	local titleLabel = Create("TextLabel", {

		Position = UDim2.fromOffset(
			15,
			12
		),

		Size = UDim2.new(
			1,
			-30,
			0,
			22
		),

		BackgroundTransparency = 1,

		Text = title,

		TextColor3 = CONFIG.Colors.White,

		TextSize = 13,

		Font = Enum.Font.GothamBlack,

		TextXAlignment =
			Enum.TextXAlignment.Left,

		TextTruncate =
			Enum.TextTruncate.AtEnd,

		ZIndex = 136,

	}, card)

	local descriptionLabel = Create("TextLabel", {

		Position = UDim2.fromOffset(
			15,
			35
		),

		Size = UDim2.new(
			1,
			-30,
			0,
			18
		),

		BackgroundTransparency = 1,

		Text = description or "",

		TextColor3 = CONFIG.Colors.Muted,

		TextSize = 9,

		Font = Enum.Font.GothamMedium,

		TextXAlignment =
			Enum.TextXAlignment.Left,

		TextTruncate =
			Enum.TextTruncate.AtEnd,

		ZIndex = 136,

	}, card)

	return card
end

--==============================================================================
-- [SECTION 24] VERTICAL LIST HELPER
--==============================================================================

local function Stack(page, spacing)

	local holder = Create("Frame", {

		Size = UDim2.new(
			1,
			0,
			0,
			0
		),

		BackgroundTransparency = 1,

		AutomaticSize =
			Enum.AutomaticSize.Y,

		ZIndex = 134,

	}, page)

	Create("UIListLayout", {

		FillDirection =
			Enum.FillDirection.Vertical,

		HorizontalAlignment =
			Enum.HorizontalAlignment.Center,

		VerticalAlignment =
			Enum.VerticalAlignment.Top,

		Padding =
			UDim.new(
				0,
				spacing or 10
			),

		SortOrder =
			Enum.SortOrder.LayoutOrder,

	}, holder)

	return holder
end

--==============================================================================
-- [SECTION 25] HOME PAGE
--==============================================================================

local HomePage = CreatePage("HOME")

AddPagePadding(HomePage)

local HomeStack = Stack(
	HomePage,
	10
)

local HomeTitle = Create("TextLabel", {

	Size = UDim2.new(
		1,
		0,
		0,
		38
	),

	BackgroundTransparency = 1,

	Text = "NEXUS CONTROL DECK",

	TextColor3 = CONFIG.Colors.White,

	TextSize = 23,

	Font = Enum.Font.GothamBlack,

	TextXAlignment =
		Enum.TextXAlignment.Left,

	ZIndex = 135,

}, HomeStack)

local HomeSubtitle = Create("TextLabel", {

	Size = UDim2.new(
		1,
		0,
		0,
		25
	),

	BackgroundTransparency = 1,

	Text = "Robotic command interface // live system synchronization",

	TextColor3 = CONFIG.Colors.Muted,

	TextSize = 10,

	Font = Enum.Font.GothamMedium,

	TextXAlignment =
		Enum.TextXAlignment.Left,

	ZIndex = 135,

}, HomeStack)

-- Hero
local HomeHero = Card(
	HomeStack,
	"VANZ // NEXUS ONLINE",
	"Command matrix synchronized. All core modules are ready.",
	135
)

AddGradient(HomeHero, {

	ColorSequenceKeypoint.new(
		0,
		Color3.fromRGB(
			9,
			25,
			42
		)
	),

	ColorSequenceKeypoint.new(
		0.5,
		Color3.fromRGB(
			10,
			15,
			30
		)
	),

	ColorSequenceKeypoint.new(
		1,
		Color3.fromRGB(
			28,
			10,
			39
		)
	),

}, 15)

local HeroStatus = Create("Frame", {

	AnchorPoint = Vector2.new(
		1,
		0.5
	),

	Position = UDim2.new(
		1,
		-18,
		0.5,
		10
	),

	Size = UDim2.fromOffset(
		105,
		76
	),

	BackgroundColor3 =
		CONFIG.Colors.Panel3,

	BorderSizePixel = 0,

	ZIndex = 140,

}, HomeHero)

AddCorner(HeroStatus, 13)

AddStroke(
	HeroStatus,
	CONFIG.Colors.Success,
	0.45,
	1
)

local HeroStatusDot = Create("Frame", {

	AnchorPoint = Vector2.new(
		0.5,
		0
	),

	Position = UDim2.new(
		0.5,
		0,
		0,
		10
	),

	Size = UDim2.fromOffset(
		10,
		10
	),

	BackgroundColor3 =
		CONFIG.Colors.Success,

	BorderSizePixel = 0,

	ZIndex = 141,

}, HeroStatus)

AddCorner(
	HeroStatusDot,
	100
)

local HeroStatusText = Create("TextLabel", {

	Position = UDim2.fromOffset(
		0,
		31
	),

	Size = UDim2.new(
		1,
		0,
		0,
		25
	),

	BackgroundTransparency = 1,

	Text = "ONLINE",

	TextColor3 =
		CONFIG.Colors.Success,

	TextSize = 14,

	Font = Enum.Font.GothamBlack,

	ZIndex = 141,

}, HeroStatus)

local HomeStatsCard = Card(
	HomeStack,
	"LIVE SYSTEM TELEMETRY",
	"Current client state.",
	245
)

local HomeStatsGrid = Create("Frame", {

	Position = UDim2.fromOffset(
		14,
		61
	),

	Size = UDim2.new(
		1,
		-28,
		1,
		-72
	),

	BackgroundTransparency = 1,

	ZIndex = 138,

}, HomeStatsCard)

Create("UIGridLayout", {

	CellSize = UDim2.new(
		0.5,
		-5,
		0,
		75
	),

	CellPadding = UDim2.fromOffset(
		10,
		10
	),

	SortOrder =
		Enum.SortOrder.LayoutOrder,

}, HomeStatsGrid)

local HomeValues = {}

local function CreateStatCell(parent, title)

	local cell = Create("Frame", {

		BackgroundColor3 =
			CONFIG.Colors.Panel3,

		BorderSizePixel = 0,

		ZIndex = 140,

	}, parent)

	AddCorner(cell, 11)

	AddStroke(
		cell,
		CONFIG.Colors.Line,
		0.5,
		1
	)

	local label = Create("TextLabel", {

		Position = UDim2.fromOffset(
			12,
			9
		),

		Size = UDim2.new(
			1,
			-24,
			0,
			15
		),

		BackgroundTransparency = 1,

		Text = title,

		TextColor3 =
			CONFIG.Colors.Muted,

		TextSize = 8,

		Font = Enum.Font.GothamBlack,

		TextXAlignment =
			Enum.TextXAlignment.Left,

		ZIndex = 141,

	}, cell)

	local value = Create("TextLabel", {

		Position = UDim2.fromOffset(
			12,
			27
		),

		Size = UDim2.new(
			1,
			-24,
			0,
			30
		),

		BackgroundTransparency = 1,

		Text = "--",

		TextColor3 =
			CONFIG.Colors.Cyan,

		TextSize = 19,

		Font = Enum.Font.GothamBlack,

		TextXAlignment =
			Enum.TextXAlignment.Left,

		ZIndex = 141,

	}, cell)

	HomeValues[title] = value

	return cell
end

CreateStatCell(
	HomeStatsGrid,
	"FPS"
)

CreateStatCell(
	HomeStatsGrid,
	"PING"
)

CreateStatCell(
	HomeStatsGrid,
	"MEMORY"
)

CreateStatCell(
	HomeStatsGrid,
	"UPTIME"
)

-- Radar
local RadarCardHome = Card(
	HomeStack,
	"NEURAL RADAR",
	"Animated network activity visualization.",
	215
)

local Radar = Create("Frame", {

	AnchorPoint = Vector2.new(
		0.5,
		0.5
	),

	Position = UDim2.new(
		0.5,
		0,
		0.58,
		0
	),

	Size = UDim2.fromOffset(
		145,
		145
	),

	BackgroundColor3 =
		Color3.fromRGB(
			5,
			14,
			23
		),

	BorderSizePixel = 0,

	ZIndex = 140,

}, RadarCardHome)

AddCorner(
	Radar,
	100
)

AddStroke(
	Radar,
	CONFIG.Colors.Cyan,
	0.35,
	1
)

for _, size in ipairs({
	0.8,
	0.58,
	0.36,
	0.16
}) do

	local ring = Create("Frame", {

		AnchorPoint = Vector2.new(
			0.5,
			0.5
		),

		Position = UDim2.fromScale(
			0.5,
			0.5
		),

		Size = UDim2.fromScale(
			size,
			size
		),

		BackgroundTransparency = 1,

		BorderSizePixel = 0,

		ZIndex = 141,

	}, Radar)

	AddCorner(
		ring,
		100
	)

	AddStroke(
		ring,
		CONFIG.Colors.Cyan,
		0.76,
		1
	)
end

local RadarH = Create("Frame", {

	AnchorPoint = Vector2.new(
		0.5,
		0.5
	),

	Position = UDim2.fromScale(
		0.5,
		0.5
	),

	Size = UDim2.new(
		1,
		-16,
		0,
		1
	),

	BackgroundColor3 =
		CONFIG.Colors.Cyan,

	BackgroundTransparency = 0.7,

	BorderSizePixel = 0,

	ZIndex = 142,

}, Radar)

local RadarV = Create("Frame", {

	AnchorPoint = Vector2.new(
		0.5,
		0.5
	),

	Position = UDim2.fromScale(
		0.5,
		0.5
	),

	Size = UDim2.new(
		0,
		1,
		1,
		-16
	),

	BackgroundColor3 =
		CONFIG.Colors.Cyan,

	BackgroundTransparency = 0.7,

	BorderSizePixel = 0,

	ZIndex = 142,

}, Radar)

local RadarSweep = Create("Frame", {

	AnchorPoint = Vector2.new(
		0,
		0.5
	),

	Position = UDim2.fromScale(
		0.5,
		0.5
	),

	Size = UDim2.new(
		0.5,
		0,
		0,
		2
	),

	BackgroundColor3 =
		CONFIG.Colors.Cyan,

	BackgroundTransparency = 0.1,

	BorderSizePixel = 0,

	ZIndex = 143,

}, Radar)

local RadarCore = Create("Frame", {

	AnchorPoint = Vector2.new(
		0.5,
		0.5
	),

	Position = UDim2.fromScale(
		0.5,
		0.5
	),

	Size = UDim2.fromOffset(
		8,
		8
	),

	BackgroundColor3 =
		CONFIG.Colors.White,

	BorderSizePixel = 0,

	ZIndex = 144,

}, Radar)

AddCorner(
	RadarCore,
	100
)

--==============================================================================
-- [SECTION 26] VISUALS PAGE
--==============================================================================

local VisualsPage = CreatePage("VISUALS")

AddPagePadding(VisualsPage)

local VisualsStack = Stack(
	VisualsPage,
	10
)

local VisualsTitle = Create("TextLabel", {

	Size = UDim2.new(
		1,
		0,
		0,
		38
	),

	BackgroundTransparency = 1,

	Text = "VISUAL MATRIX",

	TextColor3 = CONFIG.Colors.White,

	TextSize = 23,

	Font = Enum.Font.GothamBlack,

	TextXAlignment =
		Enum.TextXAlignment.Left,

	ZIndex = 135,

}, VisualsStack)

local VisualsSubtitle = Create("TextLabel", {

	Size = UDim2.new(
		1,
		0,
		0,
		24
	),

	BackgroundTransparency = 1,

	Text = "Control the living visual layer of the interface.",

	TextColor3 = CONFIG.Colors.Muted,

	TextSize = 10,

	Font = Enum.Font.GothamMedium,

	TextXAlignment =
		Enum.TextXAlignment.Left,

	ZIndex = 135,

}, VisualsStack)

local VisualOptions = {

	SoftAnimation = true,

	NeonColor = true,

	Radar = true,

	Particles = true,

	Interaction = true,

}

local VisualToggles = {}

local function CreateToggle(
	parent,
	title,
	description,
	key
)

	local row = Create("TextButton", {

		Size = UDim2.new(
			1,
			0,
			0,
			78
		),

		BackgroundColor3 =
			CONFIG.Colors.Panel2,

		BorderSizePixel = 0,

		AutoButtonColor = false,

		Text = "",

		ZIndex = 136,

	}, parent)

	AddCorner(row, 13)

	AddStroke(
		row,
		CONFIG.Colors.Line,
		0.45,
		1
	)

	local titleLabel = Create("TextLabel", {

		Position = UDim2.fromOffset(
			15,
			11
		),

		Size = UDim2.new(
			1,
			-100,
			0,
			22
		),

		BackgroundTransparency = 1,

		Text = title,

		TextColor3 =
			CONFIG.Colors.White,

		TextSize = 13,

		Font = Enum.Font.GothamBlack,

		TextXAlignment =
			Enum.TextXAlignment.Left,

		ZIndex = 137,

	}, row)

	local descriptionLabel = Create("TextLabel", {

		Position = UDim2.fromOffset(
			15,
			36
		),

		Size = UDim2.new(
			1,
			-100,
			0,
			18
		),

		BackgroundTransparency = 1,

		Text = description,

		TextColor3 =
			CONFIG.Colors.Muted,

		TextSize = 9,

		Font = Enum.Font.GothamMedium,

		TextXAlignment =
			Enum.TextXAlignment.Left,

		TextTruncate =
			Enum.TextTruncate.AtEnd,

		ZIndex = 137,

	}, row)

	local switch = Create("Frame", {

		AnchorPoint = Vector2.new(
			1,
			0.5
		),

		Position = UDim2.new(
			1,
			-16,
			0.5,
			0
		),

		Size = UDim2.fromOffset(
			58,
			31
		),

		BackgroundColor3 =
			CONFIG.Colors.Cyan,

		BorderSizePixel = 0,

		ZIndex = 138,

	}, row)

	AddCorner(
		switch,
		20
	)

	local knob = Create("Frame", {

		AnchorPoint = Vector2.new(
			1,
			0.5
		),

		Position = UDim2.new(
			1,
			-4,
			0.5,
			0
		),

		Size = UDim2.fromOffset(
			23,
			23
		),

		BackgroundColor3 =
			CONFIG.Colors.White,

		BorderSizePixel = 0,

		ZIndex = 139,

	}, switch)

	AddCorner(
		knob,
		100
	)

	VisualToggles[key] = {
		Switch = switch,
		Knob = knob,
	}

	local function Refresh()

		local active =
			VisualOptions[key]

		Tween(
			switch,
			0.18,
			{
				BackgroundColor3 =
					active
					and CONFIG.Colors.Cyan
					or Color3.fromRGB(
						45,
						52,
						69
					)
			}
		)

		Tween(
			knob,
			0.18,
			{
				Position =
					active
					and UDim2.new(
						1,
						-4,
						0.5,
						0
					)
					or UDim2.new(
						0,
						4,
						0.5,
						0
					)
			}
		)
	end

	Connect(
		row.Activated,
		function()

			VisualOptions[key] =
				not VisualOptions[key]

			Refresh()
		end
	)

	Refresh()

	return row
end

CreateToggle(
	VisualsStack,
	"SOFT ANIMATION",
	"Breathing core, rotation and micro-motion.",
	"SoftAnimation"
)

CreateToggle(
	VisualsStack,
	"NEON AMBIENCE",
	"Dynamic cyan/violet holographic accents.",
	"NeonColor"
)

CreateToggle(
	VisualsStack,
	"NEURAL RADAR",
	"Animated radar sweep and scanner grid.",
	"Radar"
)

CreateToggle(
	VisualsStack,
	"PARTICLE FIELD",
	"Lightweight floating system particles.",
	"Particles"
)

CreateToggle(
	VisualsStack,
	"INTERACTION FX",
	"Hover, touch and button feedback.",
	"Interaction"
)

--==============================================================================
-- [SECTION 27] SYSTEM PAGE
--==============================================================================

local SystemPage = CreatePage("SYSTEM")

AddPagePadding(SystemPage)

local SystemStack = Stack(
	SystemPage,
	10
)

local SystemTitle = Create("TextLabel", {

	Size = UDim2.new(
		1,
		0,
		0,
		38
	),

	BackgroundTransparency = 1,

	Text = "SYSTEM TELEMETRY",

	TextColor3 =
		CONFIG.Colors.White,

	TextSize = 23,

	Font = Enum.Font.GothamBlack,

	TextXAlignment =
		Enum.TextXAlignment.Left,

	ZIndex = 135,

}, SystemStack)

local SystemSubtitle = Create("TextLabel", {

	Size = UDim2.new(
		1,
		0,
		0,
		24
	),

	BackgroundTransparency = 1,

	Text = "Live client diagnostics and session information.",

	TextColor3 =
		CONFIG.Colors.Muted,

	TextSize = 10,

	Font = Enum.Font.GothamMedium,

	TextXAlignment =
		Enum.TextXAlignment.Left,

	ZIndex = 135,

}, SystemStack)

local SystemTelemetryCard = Card(
	SystemStack,
	"LIVE DIAGNOSTICS",
	"Values update automatically.",
	340
)

local SystemGrid = Create("Frame", {

	Position = UDim2.fromOffset(
		14,
		62
	),

	Size = UDim2.new(
		1,
		-28,
		1,
		-76
	),

	BackgroundTransparency = 1,

	ZIndex = 138,

}, SystemTelemetryCard)

Create("UIGridLayout", {

	CellSize = UDim2.new(
		0.5,
		-5,
		0,
		82
	),

	CellPadding = UDim2.fromOffset(
		10,
		10
	),

}, SystemGrid)

local SystemValues = {}

local function CreateSystemMetric(
	parent,
	title,
	accent
)

	local metric = Create("Frame", {

		BackgroundColor3 =
			CONFIG.Colors.Panel3,

		BorderSizePixel = 0,

		ZIndex = 140,

	}, parent)

	AddCorner(
		metric,
		11
	)

	AddStroke(
		metric,
		accent,
		0.58,
		1
	)

	local label = Create("TextLabel", {

		Position = UDim2.fromOffset(
			12,
			10
		),

		Size = UDim2.new(
			1,
			-24,
			0,
			17
		),

		BackgroundTransparency = 1,

		Text = title,

		TextColor3 =
			CONFIG.Colors.Muted,

		TextSize = 8,

		Font = Enum.Font.GothamBlack,

		TextXAlignment =
			Enum.TextXAlignment.Left,

		ZIndex = 141,

	}, metric)

	local value = Create("TextLabel", {

		Position = UDim2.fromOffset(
			12,
			31
		),

		Size = UDim2.new(
			1,
			-24,
			0,
			34
		),

		BackgroundTransparency = 1,

		Text = "--",

		TextColor3 =
			accent,

		TextSize = 20,

		Font = Enum.Font.GothamBlack,

		TextXAlignment =
			Enum.TextXAlignment.Left,

		TextTruncate =
			Enum.TextTruncate.AtEnd,

		ZIndex = 141,

	}, metric)

	SystemValues[title] = value

	return metric
end

CreateSystemMetric(
	SystemGrid,
	"FPS",
	CONFIG.Colors.Cyan
)

CreateSystemMetric(
	SystemGrid,
	"PING",
	CONFIG.Colors.Violet
)

CreateSystemMetric(
	SystemGrid,
	"MEMORY",
	CONFIG.Colors.Pink
)

CreateSystemMetric(
	SystemGrid,
	"UPTIME",
	CONFIG.Colors.Success
)

CreateSystemMetric(
	SystemGrid,
	"ACTIVE TAB",
	CONFIG.Colors.Blue
)

CreateSystemMetric(
	SystemGrid,
	"WINDOW",
	CONFIG.Colors.Warning
)

--==============================================================================
-- [SECTION 28] NEXUS PAGE
--==============================================================================

local NexusPage = CreatePage("NEXUS")

AddPagePadding(NexusPage)

local NexusStack = Stack(
	NexusPage,
	10
)

local NexusTitle = Create("TextLabel", {

	Size = UDim2.new(
		1,
		0,
		0,
		38
	),

	BackgroundTransparency = 1,

	Text = "NEXUS CORE",

	TextColor3 =
		CONFIG.Colors.White,

	TextSize = 23,

	Font = Enum.Font.GothamBlack,

	TextXAlignment =
		Enum.TextXAlignment.Left,

	ZIndex = 135,

}, NexusStack)

local NexusSubtitle = Create("TextLabel", {

	Size = UDim2.new(
		1,
		0,
		0,
		24
	),

	BackgroundTransparency = 1,

	Text = "Robotic anime-inspired command core.",

	TextColor3 =
		CONFIG.Colors.Muted,

	TextSize = 10,

	Font = Enum.Font.GothamMedium,

	TextXAlignment =
		Enum.TextXAlignment.Left,

	ZIndex = 135,

}, NexusStack)

local NexusCoreCard = Card(
	NexusStack,
	"NEURAL CORE",
	"SYNC // PROCESS // EVOLVE",
	330
)

local BigCore = Create("Frame", {

	AnchorPoint = Vector2.new(
		0.5,
		0.5
	),

	Position = UDim2.new(
		0.5,
		0,
		0.55,
		0
	),

	Size = UDim2.fromOffset(
		170,
		170
	),

	BackgroundColor3 =
		Color3.fromRGB(
			7,
			13,
			25
		),

	BorderSizePixel = 0,

	ZIndex = 140,

}, NexusCoreCard)

AddCorner(
	BigCore,
	100
)

AddStroke(
	BigCore,
	CONFIG.Colors.Cyan,
	0.2,
	2
)

local BigRing1 = Create("Frame", {

	AnchorPoint = Vector2.new(
		0.5,
		0.5
	),

	Position = UDim2.fromScale(
		0.5,
		0.5
	),

	Size = UDim2.fromOffset(
		135,
		135
	),

	BackgroundTransparency = 1,

	BorderSizePixel = 0,

	ZIndex = 141,

}, BigCore)

AddCorner(
	BigRing1,
	100
)

AddStroke(
	BigRing1,
	CONFIG.Colors.Violet,
	0.25,
	2
)

local BigRing2 = Create("Frame", {

	AnchorPoint = Vector2.new(
		0.5,
		0.5
	),

	Position = UDim2.fromScale(
		0.5,
		0.5
	),

	Size = UDim2.fromOffset(
		98,
		98
	),

	BackgroundTransparency = 1,

	BorderSizePixel = 0,

	ZIndex = 142,

}, BigCore)

AddCorner(
	BigRing2,
	100
)

AddStroke(
	BigRing2,
	CONFIG.Colors.Pink,
	0.28,
	1
)

local BigCoreCenter = Create("Frame", {

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

	BackgroundColor3 =
		CONFIG.Colors.Cyan,

	BorderSizePixel = 0,

	ZIndex = 144,

}, BigCore)

AddCorner(
	BigCoreCenter,
	100
)

local BigCoreText = Create("TextLabel", {

	Size = UDim2.fromScale(
		1,
		1
	),

	BackgroundTransparency = 1,

	Text = "N",

	TextColor3 =
		CONFIG.Colors.Background,

	TextSize = 21,

	Font = Enum.Font.GothamBlack,

	ZIndex = 145,

}, BigCoreCenter)

local CoreStatus = Create("TextLabel", {

	AnchorPoint = Vector2.new(
		0.5,
		0
	),

	Position = UDim2.new(
		0.5,
		0,
		0,
		15
	),

	Size = UDim2.new(
		1,
		-40,
		0,
		22
	),

	BackgroundTransparency = 1,

	Text = "NEURAL CORE ACTIVE",

	TextColor3 =
		CONFIG.Colors.White,

	TextSize = 13,

	Font = Enum.Font.GothamBlack,

	ZIndex = 146,

}, NexusCoreCard)

--==============================================================================
-- [SECTION 29] SETTINGS PAGE
--==============================================================================

local SettingsPage = CreatePage("SETTINGS")

AddPagePadding(SettingsPage)

local SettingsStack = Stack(
	SettingsPage,
	10
)

local SettingsTitle = Create("TextLabel", {

	Size = UDim2.new(
		1,
		0,
		0,
		38
	),

	BackgroundTransparency = 1,

	Text = "NEXUS SETTINGS",

	TextColor3 =
		CONFIG.Colors.White,

	TextSize = 23,

	Font = Enum.Font.GothamBlack,

	TextXAlignment =
		Enum.TextXAlignment.Left,

	ZIndex = 135,

}, SettingsStack)

local SettingsSubtitle = Create("TextLabel", {

	Size = UDim2.new(
		1,
		0,
		0,
		24
	),

	BackgroundTransparency = 1,

	Text = "Interface behavior and accessibility controls.",

	TextColor3 =
		CONFIG.Colors.Muted,

	TextSize = 10,

	Font = Enum.Font.GothamMedium,

	TextXAlignment =
		Enum.TextXAlignment.Left,

	ZIndex = 135,

}, SettingsStack)

local SettingsOptions = {

	LargeText = true,

	LargeButtons = true,

	AutoResponsive = true,

}

local function CreateSettingsToggle(
	title,
	description,
	key
)

	local row = Create("TextButton", {

		Size = UDim2.new(
			1,
			0,
			0,
			78
		),

		BackgroundColor3 =
			CONFIG.Colors.Panel2,

		BorderSizePixel = 0,

		AutoButtonColor = false,

		Text = "",

		ZIndex = 136,

	}, SettingsStack)

	AddCorner(
		row,
		13
	)

	AddStroke(
		row,
		CONFIG.Colors.Line,
		0.45,
		1
	)

	local titleLabel = Create("TextLabel", {

		Position = UDim2.fromOffset(
			15,
			11
		),

		Size = UDim2.new(
			1,
			-100,
			0,
			22
		),

		BackgroundTransparency = 1,

		Text = title,

		TextColor3 =
			CONFIG.Colors.White,

		TextSize = 13,

		Font = Enum.Font.GothamBlack,

		TextXAlignment =
			Enum.TextXAlignment.Left,

		ZIndex = 137,

	}, row)

	local descriptionLabel = Create("TextLabel", {

		Position = UDim2.fromOffset(
			15,
			36
		),

		Size = UDim2.new(
			1,
			-100,
			0,
			18
		),

		BackgroundTransparency = 1,

		Text = description,

		TextColor3 =
			CONFIG.Colors.Muted,

		TextSize = 9,

		Font = Enum.Font.GothamMedium,

		TextXAlignment =
			Enum.TextXAlignment.Left,

		ZIndex = 137,

	}, row)

	local switch = Create("Frame", {

		AnchorPoint = Vector2.new(
			1,
			0.5
		),

		Position = UDim2.new(
			1,
			-16,
			0.5,
			0
		),

		Size = UDim2.fromOffset(
			58,
			31
		),

		BackgroundColor3 =
			CONFIG.Colors.Cyan,

		BorderSizePixel = 0,

		ZIndex = 138,

	}, row)

	AddCorner(
		switch,
		20
	)

	local knob = Create("Frame", {

		AnchorPoint = Vector2.new(
			1,
			0.5
		),

		Position = UDim2.new(
			1,
			-4,
			0.5,
			0
		),

		Size = UDim2.fromOffset(
			23,
			23
		),

		BackgroundColor3 =
			CONFIG.Colors.White,

		BorderSizePixel = 0,

		ZIndex = 139,

	}, switch)

	AddCorner(
		knob,
		100
	)

	local function Refresh()

		local active =
			SettingsOptions[key]

		Tween(
			switch,
			0.18,
			{
				BackgroundColor3 =
					active
					and CONFIG.Colors.Cyan
					or Color3.fromRGB(
						45,
						52,
						69
					)
			}
		)

		Tween(
			knob,
			0.18,
			{
				Position =
					active
					and UDim2.new(
						1,
						-4,
						0.5,
						0
					)
					or UDim2.new(
						0,
						4,
						0.5,
						0
					)
			}
		)
	end

	Connect(
		row.Activated,
		function()

			SettingsOptions[key] =
				not SettingsOptions[key]

			Refresh()
		end
	)

	Refresh()
end

CreateSettingsToggle(
	"LARGE TEXT",
	"Keep interface labels highly readable.",
	"LargeText"
)

CreateSettingsToggle(
	"LARGE TOUCH TARGETS",
	"Keep important controls comfortable on mobile.",
	"LargeButtons"
)

CreateSettingsToggle(
	"AUTO RESPONSIVE",
	"Automatically adapt the interface to viewport size.",
	"AutoResponsive"
)

-- Extra settings card
local GestureCard = Card(
	SettingsStack,
	"GESTURE CONTROL",
	"Main window and minimized core are draggable.",
	110
)

local GestureText = Create("TextLabel", {

	Position = UDim2.fromOffset(
		15,
		60
	),

	Size = UDim2.new(
		1,
		-30,
		0,
		35
	),

	BackgroundTransparency = 1,

	Text = "DRAG HEADER  •  MOVE WINDOW\nDRAG NEXUS CORE  •  MOVE MINIMIZED UI",

	TextColor3 =
		CONFIG.Colors.Cyan,

	TextSize = 10,

	Font = Enum.Font.GothamBold,

	TextXAlignment =
		Enum.TextXAlignment.Left,

	TextYAlignment =
		Enum.TextYAlignment.Top,

	ZIndex = 136,

}, GestureCard)

--==============================================================================
-- [SECTION 30] ABOUT PAGE
--==============================================================================

local AboutPage = CreatePage("ABOUT")

AddPagePadding(AboutPage)

local AboutStack = Stack(
	AboutPage,
	10
)

local AboutTitle = Create("TextLabel", {

	Size = UDim2.new(
		1,
		0,
		0,
		38
	),

	BackgroundTransparency = 1,

	Text = "ABOUT VANZ",

	TextColor3 =
		CONFIG.Colors.White,

	TextSize = 23,

	Font = Enum.Font.GothamBlack,

	TextXAlignment =
		Enum.TextXAlignment.Left,

	ZIndex = 135,

}, AboutStack)

local AboutSubtitle = Create("TextLabel", {

	Size = UDim2.new(
		1,
		0,
		0,
		24
	),

	BackgroundTransparency = 1,

	Text = "Robotic interface architecture // VANZ NEXUS",

	TextColor3 =
		CONFIG.Colors.Muted,

	TextSize = 10,

	Font = Enum.Font.GothamMedium,

	TextXAlignment =
		Enum.TextXAlignment.Left,

	ZIndex = 135,

}, AboutStack)

local AboutCard = Card(
	AboutStack,
	"VANZ NEXUS",
	"ULTIMATE ROBOTIC COMMAND INTERFACE",
	250
)

local AboutText = Create("TextLabel", {

	Position = UDim2.fromOffset(
		15,
		65
	),

	Size = UDim2.new(
		1,
		-30,
		0,
		105
	),

	BackgroundTransparency = 1,

	Text =
		"Designed around a clean mod-menu structure: " ..
		"persistent navigation, scrollable pages, large touch controls, " ..
		"responsive mobile layout and a living robotic core.",

	TextColor3 =
		CONFIG.Colors.SoftWhite,

	TextSize = 11,

	Font = Enum.Font.GothamMedium,

	TextWrapped = true,

	TextXAlignment =
		Enum.TextXAlignment.Left,

	TextYAlignment =
		Enum.TextYAlignment.Top,

	ZIndex = 136,

}, AboutCard)

local AboutBuild = Create("TextLabel", {

	Position = UDim2.fromOffset(
		15,
		180
	),

	Size = UDim2.new(
		1,
		-30,
		0,
		22
	),

	BackgroundTransparency = 1,

	Text = "BUILD // NEXUS ULTIMATE",

	TextColor3 =
		CONFIG.Colors.Cyan,

	TextSize = 10,

	Font = Enum.Font.GothamBlack,

	TextXAlignment =
		Enum.TextXAlignment.Left,

	ZIndex = 136,

}, AboutCard)

--==============================================================================
-- [SECTION 31] MOBILE NAVIGATION
--==============================================================================

local MobileNav = Create("Frame", {

	Name = "MobileNavigation",

	AnchorPoint = Vector2.new(
		0.5,
		1
	),

	Position = UDim2.new(
		0.5,
		0,
		1,
		-6
	),

	Size = UDim2.new(
		1,
		-12,
		0,
		CONFIG.MobileNavHeight
	),

	BackgroundColor3 =
		CONFIG.Colors.Panel,

	BorderSizePixel = 0,

	Visible = false,

	ZIndex = 300,

}, Window)

AddCorner(
	MobileNav,
	15
)

AddStroke(
	MobileNav,
	CONFIG.Colors.Line,
	0.3,
	1
)

local MobileLayout = Create("UIListLayout", {

	FillDirection =
		Enum.FillDirection.Horizontal,

	HorizontalAlignment =
		Enum.HorizontalAlignment.Center,

	VerticalAlignment =
		Enum.VerticalAlignment.Center,

	Padding =
		UDim.new(
			0,
			3
		),

	SortOrder =
		Enum.SortOrder.LayoutOrder,

}, MobileNav)

local MobileTabButtons = {}

local function CreateMobileTab(tab)

	local button = Create("TextButton", {

		Size = UDim2.fromOffset(
			58,
			59
		),

		BackgroundColor3 =
			CONFIG.Colors.Panel2,

		BackgroundTransparency = 0.15,

		BorderSizePixel = 0,

		AutoButtonColor = false,

		Text = "",

		ZIndex = 305,

	}, MobileNav)

	AddCorner(
		button,
		11
	)

	local icon = Create("TextLabel", {

		Position = UDim2.fromOffset(
			0,
			6
		),

		Size = UDim2.new(
			1,
			0,
			0,
			23
		),

		BackgroundTransparency = 1,

		Text = tab.Icon,

		TextColor3 =
			CONFIG.Colors.SoftWhite,

		TextSize = 17,

		Font = Enum.Font.GothamBold,

		ZIndex = 306,

	}, button)

	local title = Create("TextLabel", {

		Position = UDim2.fromOffset(
			0,
			32
		),

		Size = UDim2.new(
			1,
			0,
			0,
			17
		),

		BackgroundTransparency = 1,

		Text = tab.Name,

		TextColor3 =
			CONFIG.Colors.Muted,

		TextSize = 7,

		Font = Enum.Font.GothamBlack,

		ZIndex = 306,

	}, button)

	MobileTabButtons[tab.Id] = {

		Button = button,

		Icon = icon,

		Title = title,

	}

	Connect(
		button.Activated,
		function()

			if State.CurrentTab == tab.Id then
				return
			end

			State.CurrentTab = tab.Id

			for id, data in pairs(MobileTabButtons) do

				local active =
					id == tab.Id

				Tween(
					data.Button,
					0.14,
					{
						BackgroundColor3 =
							active
							and Color3.fromRGB(
								18,
								31,
								51
							)
							or CONFIG.Colors.Panel2
					}
				)

				Tween(
					data.Icon,
					0.14,
					{
						TextColor3 =
							active
							and CONFIG.Colors.Cyan
							or CONFIG.Colors.SoftWhite
					}
				)

				Tween(
					data.Title,
					0.14,
					{
						TextColor3 =
							active
							and CONFIG.Colors.White
							or CONFIG.Colors.Muted
					}
				)
			end

			for id, page in pairs(Pages) do

				page.Visible =
					id == tab.Id

				if id == tab.Id then

					page.CanvasPosition =
						Vector2.new(
							0,
							0
						)

					page.Position =
						UDim2.fromOffset(
							14,
							0
						)

					Tween(
						page,
						0.22,
						{
							Position =
								UDim2.fromOffset(
									0,
									0
								)
						}
					)
				end
			end
		end
	)
end

for _, tab in ipairs(Tabs) do

	CreateMobileTab(tab)

end

--==============================================================================
-- [SECTION 32] INITIAL TAB STATE
--==============================================================================

State.CurrentTab = "HOME"

for id, data in pairs(TabButtons) do

	local active =
		id == State.CurrentTab

	data.Button.BackgroundColor3 =
		active
		and Color3.fromRGB(
			18,
			31,
			51
		)
		or CONFIG.Colors.Panel2

	data.Icon.TextColor3 =
		active
		and CONFIG.Colors.Cyan
		or CONFIG.Colors.SoftWhite

	data.Title.TextColor3 =
		active
		and CONFIG.Colors.White
		or CONFIG.Colors.SoftWhite

	data.ActiveBar.BackgroundTransparency =
		active and 0 or 1
end

for id, page in pairs(Pages) do

	page.Visible =
		id == State.CurrentTab

end

for id, data in pairs(MobileTabButtons) do

	local active =
		id == State.CurrentTab

	data.Button.BackgroundColor3 =
		active
		and Color3.fromRGB(
			18,
			31,
			51
		)
		or CONFIG.Colors.Panel2

	data.Icon.TextColor3 =
		active
		and CONFIG.Colors.Cyan
		or CONFIG.Colors.SoftWhite

	data.Title.TextColor3 =
		active
		and CONFIG.Colors.White
		or CONFIG.Colors.Muted
end

--==============================================================================
-- [SECTION 33] MINIMIZED NEXUS CORE
--==============================================================================

local MiniCoreButton = Create("TextButton", {

	Name = "MiniNexusCore",

	AnchorPoint = Vector2.new(
		0.5,
		0.5
	),

	Position = UDim2.fromScale(
		0.5,
		0.5
	),

	Size = UDim2.fromOffset(
		76,
		76
	),

	BackgroundColor3 =
		CONFIG.Colors.Background,

	BorderSizePixel = 0,

	AutoButtonColor = false,

	Text = "",

	Visible = false,

	ZIndex = 800,

}, ScreenGui)

AddCorner(
	MiniCoreButton,
	100
)

AddStroke(
	MiniCoreButton,
	CONFIG.Colors.Cyan,
	0.2,
	1
)

local MiniRing1 = Create("Frame", {

	AnchorPoint = Vector2.new(
		0.5,
		0.5
	),

	Position = UDim2.fromScale(
		0.5,
		0.5
	),

	Size = UDim2.fromOffset(
		61,
		61
	),

	BackgroundTransparency = 1,

	BorderSizePixel = 0,

	ZIndex = 801,

}, MiniCoreButton)

AddCorner(
	MiniRing1,
	100
)

AddStroke(
	MiniRing1,
	CONFIG.Colors.Cyan,
	0.12,
	2
)

local MiniRing2 = Create("Frame", {

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

	BorderSizePixel = 0,

	ZIndex = 802,

}, MiniCoreButton)

AddCorner(
	MiniRing2,
	100
)

AddStroke(
	MiniRing2,
	CONFIG.Colors.Violet,
	0.16,
	1
)

local MiniCoreCenter = Create("Frame", {

	AnchorPoint = Vector2.new(
		0.5,
		0.5
	),

	Position = UDim2.fromScale(
		0.5,
		0.5
	),

	Size = UDim2.fromOffset(
		23,
		23
	),

	BackgroundColor3 =
		CONFIG.Colors.Cyan,

	BorderSizePixel = 0,

	ZIndex = 804,

}, MiniCoreButton)

AddCorner(
	MiniCoreCenter,
	100
)

local MiniLetter = Create("TextLabel", {

	Size = UDim2.fromScale(
		1,
		1
	),

	BackgroundTransparency = 1,

	Text = "N",

	TextColor3 =
		CONFIG.Colors.Background,

	TextSize = 12,

	Font = Enum.Font.GothamBlack,

	ZIndex = 805,

}, MiniCoreCenter)

local MiniScanline = Create("Frame", {

	AnchorPoint = Vector2.new(
		0.5,
		0.5
	),

	Position = UDim2.fromScale(
		0.5,
		0.2
	),

	Size = UDim2.new(
		0.65,
		0,
		0,
		1
	),

	BackgroundColor3 =
		CONFIG.Colors.White,

	BackgroundTransparency = 0.2,

	BorderSizePixel = 0,

	ZIndex = 806,

}, MiniCoreButton)

local MiniOrbit = Create("Frame", {

	AnchorPoint = Vector2.new(
		0.5,
		0.5
	),

	Position = UDim2.new(
		0.5,
		27,
		0.5,
		0
	),

	Size = UDim2.fromOffset(
		5,
		5
	),

	BackgroundColor3 =
		CONFIG.Colors.Pink,

	BorderSizePixel = 0,

	ZIndex = 807,

}, MiniCoreButton)

AddCorner(
	MiniOrbit,
	100
)

--==============================================================================
-- [SECTION 34] DRAG MATH
--==============================================================================

local function GetViewport()

	local camera =
		workspace.CurrentCamera

	if camera then

		return camera.ViewportSize

	end

	return Vector2.new(
		1920,
		1080
	)
end

-- IMPORTANT:
-- Ini mengubah UDim2 posisi menjadi pixel berdasarkan viewport.
-- Tidak memakai AbsolutePosition.
local function UDimPositionToPixel(position)

	local viewport =
		GetViewport()

	return Vector2.new(

		position.X.Scale * viewport.X
			+ position.X.Offset,

		position.Y.Scale * viewport.Y
			+ position.Y.Offset
	)
end

local function ClampMainPosition(pixel)

	local viewport =
		GetViewport()

	local size =
		MainHolder.AbsoluteSize

	local halfX =
		size.X * 0.5

	local halfY =
		size.Y * 0.5

	local margin =
		State.Mobile
		and 4
		or 10

	local x =
		math.clamp(

			pixel.X,

			halfX + margin,

			math.max(
				halfX + margin,
				viewport.X
					- halfX
					- margin
			)

		)

	local y =
		math.clamp(

			pixel.Y,

			halfY + margin,

			math.max(
				halfY + margin,
				viewport.Y
					- halfY
					- margin
			)

		)

	return Vector2.new(
		x,
		y
	)
end

local function ClampMiniPosition(pixel)

	local viewport =
		GetViewport()

	local size =
		MiniCoreButton.AbsoluteSize

	local halfX =
		size.X * 0.5

	local halfY =
		size.Y * 0.5

	return Vector2.new(

		math.clamp(
			pixel.X,
			halfX + 4,
			viewport.X - halfX - 4
		),

		math.clamp(
			pixel.Y,
			halfY + 4,
			viewport.Y - halfY - 4
		)

	)
end

--==============================================================================
-- [SECTION 35] MAIN WINDOW DRAG START
--==============================================================================

local function StartMainDrag(input)

	if State.Destroyed
		or State.Minimized then

		return
	end

	if
		input.UserInputType
			~= Enum.UserInputType.MouseButton1

		and input.UserInputType
			~= Enum.UserInputType.Touch
	then

		return
	end

	State.DraggingMain = true

	State.MainMoved = false

	State.MainDragInput = input

	State.MainPointerStart =
		Vector2.new(
			input.Position.X,
			input.Position.Y
		)

	-- FIX:
	-- Ambil posisi dari UDim2, bukan AbsolutePosition.
	State.MainPositionStart =
		UDimPositionToPixel(
			MainHolder.Position
		)

	-- Setelah drag dimulai, ubah menjadi offset pixel.
	-- Ini membuat sistem stabil selama drag.
	MainHolder.Position =
		UDim2.fromOffset(
			State.MainPositionStart.X,
			State.MainPositionStart.Y
		)

	MainHolder.AnchorPoint =
		Vector2.new(
			0.5,
			0.5
		)
end

--==============================================================================
-- [SECTION 36] MAIN WINDOW DRAG UPDATE
--==============================================================================

local function UpdateMainDrag(input)

	if not State.DraggingMain then
		return
	end

	if
		input.UserInputType
			~= Enum.UserInputType.MouseMovement

		and input.UserInputType
			~= Enum.UserInputType.Touch
	then

		return
	end

	local current =
		Vector2.new(
			input.Position.X,
			input.Position.Y
		)

	local delta =
		current
		- State.MainPointerStart

	if delta.Magnitude > 6 then
		State.MainMoved = true
	end

	local newPosition =
		State.MainPositionStart
		+ delta

	newPosition =
		ClampMainPosition(
			newPosition
		)

	MainHolder.Position =
		UDim2.fromOffset(
			newPosition.X,
			newPosition.Y
		)
end

local function EndMainDrag(input)

	if not State.DraggingMain then
		return
	end

	if
		input.UserInputType
			== Enum.UserInputType.MouseButton1

		or input.UserInputType
			== Enum.UserInputType.Touch
	then

		State.DraggingMain = false

		State.MainDragInput = nil

	end
end

--==============================================================================
-- [SECTION 37] MAIN HEADER DRAG INPUT
--==============================================================================

Connect(
	Header.InputBegan,
	function(input)

		if
			input.UserInputType
				~= Enum.UserInputType.MouseButton1

			and input.UserInputType
				~= Enum.UserInputType.Touch
		then

			return
		end

		-- Kalau menyentuh Minimize/Close,
		-- JANGAN mulai drag.
		if
			input.Target
				== MinimizeButton

			or input.Target
				== CloseButton

			or input.Target:IsDescendantOf(
				HeaderControls
			)
		then

			return
		end

		StartMainDrag(input)
	end
)

--==============================================================================
-- [SECTION 38] MINIMIZED CORE DRAG
--==============================================================================

local function StartMiniDrag(input)

	if
		not State.Minimized
		or State.Destroyed
	then

		return
	end

	if
		input.UserInputType
			~= Enum.UserInputType.MouseButton1

		and input.UserInputType
			~= Enum.UserInputType.Touch
	then

		return
	end

	State.DraggingMini = true

	State.MiniMoved = false

	State.MiniDragInput = input

	State.MiniPointerStart =
		Vector2.new(
			input.Position.X,
			input.Position.Y
		)

	-- FIX YANG SAMA:
	-- Posisi awal berasal dari UDim2, bukan AbsolutePosition.
	State.MiniPositionStart =
		UDimPositionToPixel(
			MiniCoreButton.Position
		)

	MiniCoreButton.Position =
		UDim2.fromOffset(
			State.MiniPositionStart.X,
			State.MiniPositionStart.Y
		)

	MiniCoreButton.AnchorPoint =
		Vector2.new(
			0.5,
			0.5
		)
end

local function UpdateMiniDrag(input)

	if not State.DraggingMini then
		return
	end

	if
		input.UserInputType
			~= Enum.UserInputType.MouseMovement

		and input.UserInputType
			~= Enum.UserInputType.Touch
	then

		return
	end

	local current =
		Vector2.new(
			input.Position.X,
			input.Position.Y
		)

	local delta =
		current
		- State.MiniPointerStart

	if delta.Magnitude > 7 then
		State.MiniMoved = true
	end

	local newPosition =
		State.MiniPositionStart
		+ delta

	newPosition =
		ClampMiniPosition(
			newPosition
		)

	MiniCoreButton.Position =
		UDim2.fromOffset(
			newPosition.X,
			newPosition.Y
		)
end

local function EndMiniDrag(input)

	if not State.DraggingMini then
		return
	end

	if
		input.UserInputType
			== Enum.UserInputType.MouseButton1

		or input.UserInputType
			== Enum.UserInputType.Touch
	then

		State.DraggingMini = false

		State.MiniDragInput = nil
	end
end

Connect(
	MiniCoreButton.InputBegan,
	function(input)

		StartMiniDrag(input)

	end
)

--==============================================================================
-- [SECTION 39] GLOBAL INPUT DRAG LOOP
--==============================================================================

Connect(
	UserInputService.InputChanged,
	function(input)

		if State.DraggingMain then
			UpdateMainDrag(input)
		end

		if State.DraggingMini then
			UpdateMiniDrag(input)
		end

	end
)

Connect(
	UserInputService.InputEnded,
	function(input)

		EndMainDrag(input)

		EndMiniDrag(input)

	end
)

--==============================================================================
-- [SECTION 40] MINIMIZE
--==============================================================================

local function Minimize()

	if
		State.Destroyed
		or State.Minimized
	then

		return
	end

	State.Minimized = true

	-- Reset minimized core ke tengah.
	-- Ini hanya dilakukan saat minimize,
	-- bukan setiap frame.
	MiniCoreButton.AnchorPoint =
		Vector2.new(
			0.5,
			0.5
		)

	MiniCoreButton.Position =
		UDim2.fromScale(
			0.5,
			0.5
		)

	MiniCoreButton.Size =
		UDim2.fromOffset(
			State.Mobile
			and 68
			or 76,

			State.Mobile
			and 68
			or 76
		)

	MiniCoreButton.Visible =
		true

	MainScale.Scale = 1

	Tween(
		MainScale,
		0.18,
		{
			Scale = 0.94
		},
		Enum.EasingStyle.Quint
	)

	task.delay(
		0.12,
		function()

			if State.Destroyed then
				return
			end

			MainHolder.Visible =
				false

		end
	)

end

--==============================================================================
-- [SECTION 41] RESTORE
--==============================================================================

local function Restore()

	if
		State.Destroyed
		or not State.Minimized
	then

		return
	end

	State.Minimized =
		false

	MiniCoreButton.Visible =
		false

	MainHolder.Visible =
		true

	MainScale.Scale =
		0.92

	Tween(
		MainScale,
		0.27,
		{
			Scale = 1
		},
		Enum.EasingStyle.Back
	)
end

--==============================================================================
-- [SECTION 42] CLOSE
--==============================================================================

local function Close()

	if State.Destroyed then
		return
	end

	State.Destroyed =
		true

	Tween(
		MainScale,
		0.18,
		{
			Scale = 0.94
		}
	)

	task.delay(
		0.18,
		function()

			DisconnectAll()

			pcall(function()
				ScreenGui:Destroy()
			end)

			if _G.vanz then
				_G.vanz = nil
			end
		end
	)
end

--==============================================================================
-- [SECTION 43] HEADER BUTTON EVENTS
--==============================================================================

Connect(
	MinimizeButton.Activated,
	function()

		Minimize()

	end
)

Connect(
	CloseButton.Activated,
	function()

		Close()

	end
)

--==============================================================================
-- [SECTION 44] MINI CORE TAP
--==============================================================================

Connect(
	MiniCoreButton.Activated,
	function()

		-- Kalau benar-benar drag,
		-- jangan restore.
		if State.MiniMoved then

			State.MiniMoved =
				false

			return
		end

		Restore()

	end
)

--==============================================================================
-- [SECTION 45] RESPONSIVE SYSTEM
--==============================================================================

local LastViewport =
	Vector2.new(
		0,
		0
	)

local function ApplyResponsive()

	if State.Destroyed then
		return
	end

	local viewport =
		GetViewport()

	if viewport ==
		LastViewport then

		return
	end

	LastViewport =
		viewport

	local isMobile =
		viewport.X <= 760
		or viewport.Y <= 560

	State.Mobile =
		isMobile

	if isMobile then

		--==============================================================
		-- MOBILE WINDOW
		--==============================================================

		MainHolder.Size =
			UDim2.fromOffset(

				math.max(
					300,
					viewport.X
						- (
							CONFIG.MobileMargin
							* 2
						)
				),

				math.max(
					390,
					viewport.Y
						- (
							CONFIG.MobileMargin
							* 2
						)
				)

			)

		MainHolder.Position =
			UDim2.fromScale(
				0.5,
				0.5
			)

		-- Sidebar OFF
		Sidebar.Visible =
			false

		SidebarStatus.Visible =
			false

		-- Content full
		ContentHolder.Position =
			UDim2.fromOffset(
				6,
				6
			)

		ContentHolder.Size =
			UDim2.new(
				1,
				-12,
				1,
				-CONFIG.MobileNavHeight
					- 12
			)

		-- Mobile nav ON
		MobileNav.Visible =
			true

		-- Header title area
		HeaderLogo.Position =
			UDim2.fromOffset(
				7,
				10
			)

		HeaderLogo.Size =
			UDim2.fromOffset(
				56,
				56
			)

		HeaderTitleZone.Position =
			UDim2.fromOffset(
				70,
				8
			)

		-- Control zone tetap reserved.
		HeaderControls.Size =
			UDim2.fromOffset(
				106,
				64
			)

		HeaderControls.Position =
			UDim2.new(
				1,
				-7,
				0,
				9
			)

		HeaderTitleZone.Size =
			UDim2.new(
				1,
				-190,
				1,
				-16
			)

		HeaderTitle.Text =
			"VANZ NEXUS"

		HeaderTitle.TextSize =
			18

		HeaderSubtitle.Visible =
			false

		HeaderStatus.Visible =
			false

		MinimizeButton.Size =
			UDim2.fromOffset(
				49,
				49
			)

		CloseButton.Size =
			UDim2.fromOffset(
				49,
				49
			)

		MiniCoreButton.Size =
			UDim2.fromOffset(
				68,
				68
			)

	else

		--==============================================================
		-- DESKTOP
		--==============================================================

		MainHolder.Size =
			UDim2.fromOffset(
				CONFIG.DesktopWidth,
				CONFIG.DesktopHeight
			)

		MainHolder.Position =
			UDim2.fromScale(
				0.5,
				0.5
			)

		Sidebar.Visible =
			true

		SidebarStatus.Visible =
			true

		ContentHolder.Position =
			UDim2.new(
				0,
				CONFIG.SidebarWidth + 18,
				0,
				8
			)

		ContentHolder.Size =
			UDim2.new(
				1,
				-CONFIG.SidebarWidth - 27,
				1,
				-16
			)

		MobileNav.Visible =
			false

		HeaderLogo.Position =
			UDim2.fromOffset(
				9,
				9
			)

		HeaderLogo.Size =
			UDim2.fromOffset(
				64,
				64
			)

		HeaderTitleZone.Position =
			UDim2.fromOffset(
				82,
				8
			)

		HeaderTitleZone.Size =
			UDim2.new(
				1,
				-205,
				1,
				-16
			)

		HeaderControls.Size =
			UDim2.fromOffset(
				108,
				64
			)

		HeaderTitle.Text =
			"VANZ NEXUS"

		HeaderTitle.TextSize =
			24

		HeaderSubtitle.Visible =
			true

		HeaderStatus.Visible =
			true

		MinimizeButton.Size =
			UDim2.fromOffset(
				51,
				51
			)

		CloseButton.Size =
			UDim2.fromOffset(
				51,
				51
			)

		MiniCoreButton.Size =
			UDim2.fromOffset(
				76,
				76
			)
	end
end

ApplyResponsive()

--==============================================================================
-- [SECTION 46] CAMERA VIEWPORT WATCHER
--==============================================================================

local function ConnectCamera()

	local camera =
		workspace.CurrentCamera

	if not camera then
		return
	end

	Connect(
		camera:GetPropertyChangedSignal(
			"ViewportSize"
		),
		function()

			ApplyResponsive()

		end
	)
end

ConnectCamera()

Connect(
	workspace:GetPropertyChangedSignal(
		"CurrentCamera"
	),
	function()

		ConnectCamera()

		ApplyResponsive()

	end
)

--==============================================================================
-- [SECTION 47] STATS
--==============================================================================

local function GetPing()

	local success, result =
		pcall(
			function()

				local serverStats =
					Stats.Network.ServerStatsItem

				local ping =
					serverStats:FindFirstChild(
						"Data Ping"
					)

				if ping then
					return ping:GetValueString()
				end

				return "--"

			end
		)

	if success and result then
		return tostring(result)
	end

	return "--"
end

local function GetMemory()

	local success, result =
		pcall(
			function()

				return Stats:GetTotalMemoryUsageMb()

			end
		)

	if success and result then

		return string.format(
			"%.0f MB",
			result
		)
	end

	return "--"
end

local function FormatTime(seconds)

	local total =
		math.floor(
			seconds
		)

	local hours =
		math.floor(
			total / 3600
		)

	local minutes =
		math.floor(
			(total % 3600) / 60
		)

	local secondsLeft =
		total % 60

	return string.format(
		"%02d:%02d:%02d",
		hours,
		minutes,
		secondsLeft
	)
end

--==============================================================================
-- [SECTION 48] TELEMETRY UPDATE
--==============================================================================

local function UpdateTelemetry()

	State.Ping =
		GetPing()

	State.Memory =
		GetMemory()

	State.Uptime =
		os.clock()

	-- HOME
	if HomeValues.FPS then

		HomeValues.FPS.Text =
			string.format(
				"%d",
				math.floor(
					State.FPS + 0.5
				)
			)
	end

	if HomeValues.PING then

		HomeValues.PING.Text =
			State.Ping

	end

	if HomeValues.MEMORY then

		HomeValues.MEMORY.Text =
			State.Memory

	end

	if HomeValues.UPTIME then

		HomeValues.UPTIME.Text =
			FormatTime(
				State.Uptime
			)

	end

	-- SYSTEM
	if SystemValues.FPS then

		SystemValues.FPS.Text =
			string.format(
				"%d FPS",
				math.floor(
					State.FPS + 0.5
				)
			)
	end

	if SystemValues.PING then

		SystemValues.PING.Text =
			State.Ping

	end

	if SystemValues.MEMORY then

		SystemValues.MEMORY.Text =
			State.Memory

	end

	if SystemValues.UPTIME then

		SystemValues.UPTIME.Text =
			FormatTime(
				State.Uptime
			)

	end

	if SystemValues["ACTIVE TAB"] then

		SystemValues["ACTIVE TAB"].Text =
			State.CurrentTab

	end

	if SystemValues.WINDOW then

		SystemValues.WINDOW.Text =
			State.Minimized
			and "MINIMIZED"
			or "ACTIVE"

	end
end

--==============================================================================
-- [SECTION 49] ANIMATION ENGINE
--==============================================================================

local FrameCounter =
	0

local FPSTimer =
	0

local TelemetryTimer =
	0

local WatchdogTimer =
	0

Connect(
	RunService.RenderStepped,
	function(deltaTime)

		if State.Destroyed then
			return
		end

		State.AnimationTime +=
			deltaTime

		local t =
			State.AnimationTime

		--==============================================================
		-- FPS
		--==============================================================

		FrameCounter += 1

		FPSTimer +=
			deltaTime

		if FPSTimer >= 0.5 then

			State.FPS =
				FrameCounter
				/ FPSTimer

			FrameCounter =
				0

			FPSTimer =
				0
		end

		--==============================================================
		-- SOFT CORE ANIMATION
		--==============================================================

		if VisualOptions.SoftAnimation then

			HeaderRing1.Rotation =
				(t * 18)
				% 360

			HeaderRing2.Rotation =
				(-t * 25)
				% 360

			local headerPulse =
				1
				+ math.sin(
					t * 3
				) * 0.08

			HeaderCore.Size =
				UDim2.fromOffset(
					15 * headerPulse,
					15 * headerPulse
				)

			-- Mini core
			MiniRing1.Rotation =
				(t * 32)
				% 360

			MiniRing2.Rotation =
				(-t * 43)
				% 360

			local miniPulse =
				1
				+ math.sin(
					t * 3.5
				) * 0.09

			MiniCoreCenter.Size =
				UDim2.fromOffset(
					23 * miniPulse,
					23 * miniPulse
				)

			-- Big Nexus core
			BigRing1.Rotation =
				(t * 15)
				% 360

			BigRing2.Rotation =
				(-t * 22)
				% 360

			local bigPulse =
				1
				+ math.sin(
					t * 2.2
				) * 0.08

			BigCoreCenter.Size =
				UDim2.fromOffset(
					42 * bigPulse,
					42 * bigPulse
				)

			-- Status breathing
			local status =
				0.65
				+ (
					(math.sin(
						t * 3
					) + 1)
					* 0.17
				)

			HeroStatusDot.BackgroundTransparency =
				1 - status

			SidebarStatusDot.BackgroundTransparency =
				1 - status
		end

		--==============================================================
		-- RADAR
		--==============================================================

		if VisualOptions.Radar then

			RadarSweep.Rotation =
				(t * 72)
				% 360

			Radar.Visible =
				true

		else

			Radar.Visible =
				false

		end

		--==============================================================
		-- MINI SCANLINE
		--==============================================================

		local scan =
			0.15
			+ (
				(
					math.sin(
						t * 2
					)
					+ 1
				)
				* 0.35
			)

		MiniScanline.Position =
			UDim2.new(
				0.5,
				0,
				scan,
				0
			)

		--==============================================================
		-- MINI ORBIT
		--==============================================================

		local orbitAngle =
			t * 2

		local orbitRadius =
			27

		MiniOrbit.Position =
			UDim2.new(
				0.5,
				math.cos(
					orbitAngle
				) * orbitRadius,
				0.5,
				math.sin(
					orbitAngle
				) * orbitRadius
			)

		--==============================================================
		-- DYNAMIC COLOR
		--==============================================================

		if VisualOptions.NeonColor then

			State.Hue =
				(
					State.Hue
					+ deltaTime * 0.025
				)
				% 1

			local color =
				Color3.fromHSV(
					State.Hue,
					0.42,
					1
				)

			TopLaser.BackgroundColor3 =
				color

		else

			TopLaser.BackgroundColor3 =
				CONFIG.Colors.Cyan

		end

		--==============================================================
		-- TELEMETRY
		--==============================================================

		TelemetryTimer +=
			deltaTime

		if TelemetryTimer >= 1 then

			TelemetryTimer =
				0

			UpdateTelemetry()
		end

		--==============================================================
		-- WATCHDOG
		--==============================================================

		WatchdogTimer +=
			deltaTime

		if WatchdogTimer >= 1 then

			WatchdogTimer =
				0

			if ScreenGui.Parent
				~= PlayerGui then

				pcall(function()

					ScreenGui.Parent =
						PlayerGui

				end)
			end

			ScreenGui.Enabled =
				true

			ScreenGui.DisplayOrder =
				CONFIG.DisplayOrder

		end
	end
)

--==============================================================================
-- [SECTION 50] PARTICLE FIELD
--==============================================================================

local ParticleContainer = Create("Frame", {

	Name = "ParticleField",

	Size = UDim2.fromScale(
		1,
		1
	),

	BackgroundTransparency = 1,

	ClipsDescendants = true,

	ZIndex = 115,

}, Window)

local Particles = {}

for i = 1, 18 do

	local particle = Create("Frame", {

		Position = UDim2.fromScale(
			math.random(),
			math.random()
		),

		Size = UDim2.fromOffset(
			math.random(1, 3),
			math.random(1, 3)
		),

		BackgroundColor3 =
			i % 3 == 0
			and CONFIG.Colors.Violet
			or CONFIG.Colors.Cyan,

		BackgroundTransparency =
			math.random(
				35,
				75
			) / 100,

		BorderSizePixel = 0,

		ZIndex = 116,

	}, ParticleContainer)

	AddCorner(
		particle,
		100
	)

	table.insert(
		Particles,
		{
			Object = particle,

			Speed =
				math.random(
					5,
					15
				) / 10000,

			Offset =
				math.random(
					0,
					100
				) / 10,
		}
	)
end

--==============================================================================
-- [SECTION 51] PARTICLE UPDATE
--==============================================================================

Connect(
	RunService.RenderStepped,
	function(deltaTime)

		if State.Destroyed then
			return
		end

		if not VisualOptions.Particles then

			ParticleContainer.Visible =
				false

			return
		end

		ParticleContainer.Visible =
			true

		for _, data in ipairs(Particles) do

			local object =
				data.Object

			local pos =
				object.Position

			local y =
				pos.Y.Scale
				- data.Speed
					* deltaTime
					* 60

			if y < -0.05 then
				y = 1.05
			end

			object.Position =
				UDim2.fromScale(
					pos.X.Scale,
					y
				)

			local pulse =
				0.5
				+ (
					math.sin(
						State.AnimationTime
							+ data.Offset
					)
					* 0.25
				)

			object.BackgroundTransparency =
				math.clamp(
					pulse,
					0.15,
					0.9
				)
		end
	end
)

--==============================================================================
-- [SECTION 52] CHARACTER RESPAWN SAFETY
--==============================================================================

Connect(
	LocalPlayer.CharacterAdded,
	function()

		task.wait(
			0.5
		)

		if State.Destroyed then
			return
		end

		ScreenGui.Parent =
			PlayerGui

		ScreenGui.Enabled =
			true

		ScreenGui.DisplayOrder =
			CONFIG.DisplayOrder

		ApplyResponsive()

	end
)

--==============================================================================
-- [SECTION 53] PUBLIC API
--==============================================================================

_G.vanz = _G.vanz or {}

_G.vanz.Open = function()

	if State.Destroyed then
		return
	end

	ScreenGui.Enabled =
		true

	if State.Minimized then
		Restore()
	end
end

_G.vanz.Restore = function()

	if State.Destroyed then
		return
	end

	Restore()
end

_G.vanz.Minimize = function()

	if State.Destroyed then
		return
	end

	Minimize()
end

_G.vanz.Close = function()

	Close()

end

_G.vanz.GetState = function()

	return {

		Destroyed =
			State.Destroyed,

		Minimized =
			State.Minimized,

		Mobile =
			State.Mobile,

		CurrentTab =
			State.CurrentTab,

		FPS =
			State.FPS,

		Ping =
			State.Ping,

		Memory =
			State.Memory,

		Uptime =
			State.Uptime,

	}
end

--==============================================================================
-- [SECTION 54] STARTUP
--==============================================================================

MainScale.Scale =
	0.94

Window.BackgroundTransparency =
	1

Tween(
	MainScale,
	0.42,
	{
		Scale = 1
	},
	Enum.EasingStyle.Quint
)

Tween(
	Window,
	0.42,
	{
		BackgroundTransparency = 0
	},
	Enum.EasingStyle.Quint
)

UpdateTelemetry()

ApplyResponsive()

--==============================================================================
-- [SECTION 55] FINAL Z-INDEX SAFETY
--==============================================================================

Header.ZIndex = 200

HeaderLogo.ZIndex = 210

HeaderTitleZone.ZIndex = 205

HeaderControls.ZIndex = 400

MinimizeButton.ZIndex = 410

CloseButton.ZIndex = 410

MobileNav.ZIndex = 300

MiniCoreButton.ZIndex = 800

--==============================================================================
-- [END]
--==============================================================================