--==================================================
-- [01] SERVICES
-- Semua Roblox service yang dipakai script ini.
--==================================================
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")
local MarketplaceService = game:GetService("MarketplaceService")
local Lighting = game:GetService("Lighting")
local Stats = game:GetService("Stats")

local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

--==================================================
-- [02] CONFIGURATION & GENERATOR SETTINGS
-- Pengaturan default GUI dan Auto Generator.
--==================================================
local CONFIG = {
	Scale = 0.50,               -- DPI default 50%
	ScaleOptions = {0.40, 0.50, 0.60, 0.70, 0.80, 0.90, 1.00},
	WindowOpacity = 0.12,       -- transparansi background window (glass)
	CornerRadius = 14,
	BorderIntensity = 0.6,
	GlassIntensity = 0.5,
	AnimationEnabled = true,
	SoftAnimation = true,
	LogoAnimation = true,
	RadarAnimation = true,
	ParticleAnimation = true,
	Scanline = true,
	HoverAnimation = true,
	ClickAnimation = true,
	TransitionAnimation = true,
	AnimationSpeed = 1,
	Theme = "Cyber Blue",
	GlowIntensity = 0.5,
	ParticleDensity = 10,
	HUDDecoration = true,
	BackgroundGrid = true,
	RememberPosition = true,
	LowFXMode = false,
	FPSFriendly = false,
	DisableParticles = false,
	DisableHeavyAnimation = false,
	DragThreshold = 8,          -- px, membedakan tap vs drag di mobile
	HomeUpdateRate = 0.25,      -- detik, update data lambat
	FastUpdateRate = 0.1,       -- detik, update data cepat
	
	-- [AUTO GENERATOR CONFIG]
	GeneratorActive = false,
	GeneratorDelay = 1.0,       -- Detik per iterasi generate
	GeneratorMode = "Standard Loop",
	GeneratorTargetCount = 100,
}

local THEMES = {
	["Cyber Blue"] = {
		Accent = Color3.fromRGB(0, 170, 255),
		Accent2 = Color3.fromRGB(0, 255, 230),
		Base = Color3.fromRGB(14, 22, 42),
		Base2 = Color3.fromRGB(22, 36, 66),
	},
	["Neon Cyan"] = {
		Accent = Color3.fromRGB(0, 255, 255),
		Accent2 = Color3.fromRGB(80, 255, 200),
		Base = Color3.fromRGB(12, 26, 36),
		Base2 = Color3.fromRGB(20, 42, 56),
	},
	["Purple Anime"] = {
		Accent = Color3.fromRGB(190, 110, 255),
		Accent2 = Color3.fromRGB(255, 120, 220),
		Base = Color3.fromRGB(28, 18, 46),
		Base2 = Color3.fromRGB(44, 28, 70),
	},
	["Crimson"] = {
		Accent = Color3.fromRGB(255, 70, 90),
		Accent2 = Color3.fromRGB(255, 160, 80),
		Base = Color3.fromRGB(34, 16, 22),
		Base2 = Color3.fromRGB(52, 24, 34),
	},
	["Emerald"] = {
		Accent = Color3.fromRGB(70, 255, 150),
		Accent2 = Color3.fromRGB(160, 255, 90),
		Base = Color3.fromRGB(14, 32, 26),
		Base2 = Color3.fromRGB(22, 50, 40),
	},
	["Ice"] = {
		Accent = Color3.fromRGB(170, 230, 255),
		Accent2 = Color3.fromRGB(230, 250, 255),
		Base = Color3.fromRGB(26, 40, 56),
		Base2 = Color3.fromRGB(38, 58, 80),
	},
}

local DEFAULT_CONFIG_SNAPSHOT = {}
for k, v in pairs(CONFIG) do
	DEFAULT_CONFIG_SNAPSHOT[k] = v
end

--==================================================
-- [03] STATE & GENERATOR METRICS
--==================================================
local STATE = {
	Built = false,
	Open = false,
	Minimized = false,
	Destroyed = false,
	SettingsOpen = false,
	GeneratorOpen = false,
	MainPosition = nil,
	MiniPosition = nil,
	SessionStart = os.clock(),
	DeviceText = "N/A",
	LastFPS = 0,
	FrameCount = 0,
	FrameTimer = 0,
	FastTimer = 0,
	SlowTimer = 0,
	
	-- Generator runtime state
	GeneratedCount = 0,
	GeneratorTask = nil,
}

--==================================================
-- [04] CLEANUP SYSTEM
--==================================================
local Connections = {}
local ActiveTweens = {}
local CleanupCallbacks = {}

local function TrackConnection(conn)
	if conn then table.insert(Connections, conn) end
	return conn
end

local function TrackTween(tween)
	if tween then table.insert(ActiveTweens, tween) end
	return tween
end

local function AddCleanup(fn)
	table.insert(CleanupCallbacks, fn)
end

local function CleanupAll()
	for _, conn in ipairs(Connections) do pcall(function() conn:Disconnect() end) end
	table.clear(Connections)
	for _, tw in ipairs(ActiveTweens) do pcall(function() tw:Cancel() end) end
	table.clear(ActiveTweens)
	for _, fn in ipairs(CleanupCallbacks) do pcall(fn) end
	table.clear(CleanupCallbacks)
end

--==================================================
-- [05] THEME & UI FACTORY
--==================================================
local function GetTheme()
	return THEMES[CONFIG.Theme] or THEMES["Cyber Blue"]
end

local COLORS = {
	Text = Color3.fromRGB(235, 245, 255),
	SubText = Color3.fromRGB(150, 185, 215),
	Good = Color3.fromRGB(90, 255, 170),
	Warn = Color3.fromRGB(255, 200, 90),
	Bad = Color3.fromRGB(255, 90, 110),
	Card = Color3.fromRGB(18, 30, 54),
	CardHover = Color3.fromRGB(28, 46, 80),
	Track = Color3.fromRGB(30, 46, 74),
}

local FONT_TITLE = Enum.Font.GothamBlack
local FONT_BOLD = Enum.Font.GothamBold
local FONT_TEXT = Enum.Font.Gotham

local function Create(className, props, children)
	local obj = Instance.new(className)
	for k, v in pairs(props or {}) do obj[k] = v end
	for _, child in ipairs(children or {}) do child.Parent = obj end
	return obj
end

local function MakeCorner(parent, radius)
	return Create("UICorner", { CornerRadius = UDim.new(0, radius or 10), Parent = parent })
end

local function MakeStroke(parent, color, thickness, transparency)
	return Create("UIStroke", {
		Color = color or GetTheme().Accent,
		Thickness = thickness or 1,
		Transparency = transparency or 0.4,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		Parent = parent,
	})
end

local function MakeGradient(parent, c1, c2, rotation)
	return Create("UIGradient", {
		Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, c1), ColorSequenceKeypoint.new(1, c2) }),
		Rotation = rotation or 90,
		Parent = parent,
	})
end

local function MakeFrame(parent, size, pos, color, transparency)
	return Create("Frame", {
		Size = size or UDim2.new(1, 0, 1, 0),
		Position = pos or UDim2.new(0, 0, 0, 0),
		BackgroundColor3 = color or COLORS.Card,
		BackgroundTransparency = transparency or 0,
		BorderSizePixel = 0,
		Parent = parent,
	})
end

local function MakeLabel(parent, text, size, pos, font, textSize, color, xAlign)
	return Create("TextLabel", {
		Text = text or "",
		Size = size or UDim2.new(1, 0, 0, 20),
		Position = pos or UDim2.new(0, 0, 0, 0),
		BackgroundTransparency = 1,
		Font = font or FONT_TEXT,
		TextSize = textSize or 14,
		TextColor3 = color or COLORS.Text,
		TextXAlignment = xAlign or Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Center,
		Parent = parent,
	})
end

local function MakeButton(parent, text, size, pos, onClick)
	local btn = Create("TextButton", {
		Text = text or "",
		Size = size or UDim2.new(0, 48, 0, 48),
		Position = pos or UDim2.new(0, 0, 0, 0),
		BackgroundColor3 = GetTheme().Base2,
		BackgroundTransparency = 0.1,
		BorderSizePixel = 0,
		AutoButtonColor = false,
		Font = FONT_BOLD,
		TextSize = 18,
		TextColor3 = COLORS.Text,
		Parent = parent,
	})
	MakeCorner(btn, 10)
	MakeStroke(btn, GetTheme().Accent, 1, 0.5)

	local baseColor = GetTheme().Base2
	local hoverColor = GetTheme().Accent

	TrackConnection(btn.MouseEnter:Connect(function()
		if not CONFIG.HoverAnimation or CONFIG.LowFXMode then return end
		TrackTween(TweenService:Create(btn, TweenInfo.new(0.18, Enum.EasingStyle.Quad), {
			BackgroundColor3 = hoverColor:Lerp(baseColor, 0.6),
		})):Play()
	end))

	TrackConnection(btn.MouseLeave:Connect(function()
		if not CONFIG.HoverAnimation or CONFIG.LowFXMode then return end
		TrackTween(TweenService:Create(btn, TweenInfo.new(0.18, Enum.EasingStyle.Quad), {
			BackgroundColor3 = baseColor,
		})):Play()
	end))

	TrackConnection(btn.MouseButton1Click:Connect(function()
		if onClick then pcall(onClick) end
	end))

	return btn
end

local function MakeCard(parent, title, size, pos)
	local card = MakeFrame(parent, size, pos, COLORS.Card, 0.05)
	MakeCorner(card, 12)
	MakeStroke(card, GetTheme().Accent, 1, 0.65)
	MakeLabel(card, title or "", UDim2.new(1, -20, 0, 22), UDim2.new(0, 12, 0, 8), FONT_BOLD, 16, GetTheme().Accent2)
	return card
end

local function ToStr(v, digits)
	if v == nil then return "N/A" end
	if type(v) == "number" then
		if digits then return string.format("%." .. digits .. "f", v) end
		return tostring(math.floor(v + 0.5))
	end
	return tostring(v)
end

--==================================================
-- [06] ROOT SCREENGUI & HELPERS
--==================================================
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local ScreenGui = Create("ScreenGui", {
	Name = "VANZ_ULTRA_CONTROL",
	ResetOnSpawn = false,
	IgnoreGuiInset = true,
	ZIndexBehavior = Enum.ZIndexBehavior.Global,
	DisplayOrder = 9999,
	Enabled = false,
	Parent = PlayerGui,
})

local function GetViewport()
	return Camera and Camera.ViewportSize or Vector2.new(1280, 720)
end

local BASE_WIDTH = 760
local BASE_HEIGHT = 520
local MIN_WIDTH_PX = 300

local function ComputeWindowSize()
	local vp = GetViewport()
	local s = CONFIG.Scale
	local w = math.clamp(BASE_WIDTH * s * 2, MIN_WIDTH_PX, vp.X - 16)
	local h = math.clamp(BASE_HEIGHT * s * 2, 260, vp.Y - 16)
	return Vector2.new(math.floor(w), math.floor(h))
end

local function ComputeCenteredPosition(size)
	local vp = GetViewport()
	return Vector2.new(math.floor((vp.X - size.X) / 2), math.floor((vp.Y - size.Y) / 2))
end

local function ClampAbsolute(pos, size)
	local vp = GetViewport()
	return Vector2.new(math.clamp(pos.X, 0, math.max(0, vp.X - size.X)), math.clamp(pos.Y, 0, math.max(0, vp.Y - size.Y)))
end

--==================================================
-- [07] MAIN WINDOW & HEADER (DITAMBAH TOMBOL GENERATOR)
--==================================================
local MainWindow = Create("Frame", {
	Name = "MainWindow",
	Size = UDim2.new(0, 0, 0, 0),
	Position = UDim2.new(0, 0, 0, 0),
	BackgroundColor3 = GetTheme().Base,
	BackgroundTransparency = CONFIG.WindowOpacity,
	BorderSizePixel = 0,
	ClipsDescendants = true,
	Visible = false,
	Parent = ScreenGui,
})
MakeCorner(MainWindow, CONFIG.CornerRadius)
local MainStroke = MakeStroke(MainWindow, GetTheme().Accent, 1.5, 0.2)
local MainGradient = MakeGradient(MainWindow, GetTheme().Base, GetTheme().Base2, 90)

local HEADER_HEIGHT = 56
local Header = MakeFrame(MainWindow, UDim2.new(1, 0, 0, HEADER_HEIGHT), UDim2.new(0, 0, 0, 0), GetTheme().Base2, 0.2)
MakeCorner(Header, CONFIG.CornerRadius)

local HeaderLogo = MakeFrame(Header, UDim2.new(0, 36, 0, 36), UDim2.new(0, 12, 0.5, -18), GetTheme().Base, 1)
MakeCorner(HeaderLogo, 18)
local HeaderLogoRing = MakeFrame(HeaderLogo, UDim2.new(1, 0, 1, 0), UDim2.new(0, 0, 0, 0), GetTheme().Accent, 1)
MakeCorner(HeaderLogoRing, 18)
MakeStroke(HeaderLogoRing, GetTheme().Accent, 2, 0.1)
local HeaderLogoCore = MakeFrame(HeaderLogo, UDim2.new(0, 10, 0, 10), UDim2.new(0.5, -5, 0.5, -5), GetTheme().Accent2, 0)
MakeCorner(HeaderLogoCore, 5)

local TitleArea = MakeFrame(Header, UDim2.new(1, -(12 + 36 + 12 + 208), 1, 0), UDim2.new(0, 12 + 36 + 10, 0, 0), COLORS.Card, 1)
local TitleLabel = MakeLabel(TitleArea, "VANZ ULTRA CONTROL CENTER", UDim2.new(1, 0, 0, 22), UDim2.new(0, 0, 0, 8), FONT_TITLE, 15, COLORS.Text)
local SubtitleLabel = MakeLabel(TitleArea, "SYSTEM ONLINE + AUTO GENERATOR", UDim2.new(1, 0, 0, 16), UDim2.new(0, 0, 0, 28), FONT_TEXT, 11, COLORS.SubText)

-- Control Zone (Settings, Generator, Minimize, Close)
local CONTROL_ZONE_WIDTH = 208
local ControlZone = MakeFrame(Header, UDim2.new(0, CONTROL_ZONE_WIDTH, 1, 0), UDim2.new(1, -CONTROL_ZONE_WIDTH - 8, 0, 0), COLORS.Card, 1)

local BTN_SIZE = 44
local BTN_GAP = 6
local SettingsBtn, GeneratorBtn, MinimizeBtn, CloseBtn

local function LayoutControls()
	local zoneW = ControlZone.AbsoluteSize.X
	local zoneH = ControlZone.AbsoluteSize.Y
	local btnY = math.floor((zoneH - BTN_SIZE) / 2)
	local x = zoneW - BTN_SIZE
	if CloseBtn then CloseBtn.Position = UDim2.new(0, x, 0, btnY) end
	x = x - BTN_SIZE - BTN_GAP
	if MinimizeBtn then MinimizeBtn.Position = UDim2.new(0, x, 0, btnY) end
	x = x - BTN_SIZE - BTN_GAP
	if GeneratorBtn then GeneratorBtn.Position = UDim2.new(0, x, 0, btnY) end
	x = x - BTN_SIZE - BTN_GAP
	if SettingsBtn then SettingsBtn.Position = UDim2.new(0, x, 0, btnY) end
end

SettingsBtn = MakeButton(ControlZone, "⚙", UDim2.new(0, BTN_SIZE, 0, BTN_SIZE), UDim2.new(0, 0, 0, 0), nil)
GeneratorBtn = MakeButton(ControlZone, "⚡", UDim2.new(0, BTN_SIZE, 0, BTN_SIZE), UDim2.new(0, 0, 0, 0), nil)
MinimizeBtn = MakeButton(ControlZone, "—", UDim2.new(0, BTN_SIZE, 0, BTN_SIZE), UDim2.new(0, 0, 0, 0), nil)
CloseBtn = MakeButton(ControlZone, "X", UDim2.new(0, BTN_SIZE, 0, BTN_SIZE), UDim2.new(0, 0, 0, 0), nil)

TrackConnection(ControlZone:GetPropertyChangedSignal("AbsoluteSize"):Connect(LayoutControls))
task.defer(LayoutControls)

--==================================================
-- [08] BODY & SCROLL CONTAINERS (Home, Settings, Generator)
--==================================================
local Body = MakeFrame(MainWindow, UDim2.new(1, -16, 1, -(HEADER_HEIGHT + 12)), UDim2.new(0, 8, 0, HEADER_HEIGHT + 4), COLORS.Card, 1)

local function MakeContainerScroll(name)
	local scroll = Create("ScrollingFrame", {
		Name = name,
		Size = UDim2.new(1, 0, 1, 0),
		Position = UDim2.new(0, 0, 0, 0),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 5,
		ScrollBarImageColor3 = GetTheme().Accent,
		CanvasSize = UDim2.new(0, 0, 0, 0),
		AutomaticCanvasSize = Enum.AutomaticSize.None,
		ScrollingDirection = Enum.ScrollingDirection.Y,
		Visible = false,
		Parent = Body,
	})
	local list = Create("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 10), Parent = scroll })
	Create("UIPadding", { PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8), PaddingTop = UDim.new(0, 6), PaddingBottom = UDim.new(0, 12), Parent = scroll })
	TrackConnection(list:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		scroll.CanvasSize = UDim2.new(0, 0, 0, list.AbsoluteContentSize.Y + 24)
	end))
	return scroll
end

local HomeScroll = MakeContainerScroll("HomeScroll")
HomeScroll.Visible = true
local SettingsScroll = MakeContainerScroll("SettingsScroll")
local GeneratorScroll = MakeContainerScroll("GeneratorScroll")

--==================================================
-- [09] HOME PANEL CARDS (Profile, Character, Session)
--==================================================
local ProfileCard = MakeCard(HomeScroll, "USER PROFILE", UDim2.new(1, -4, 0, 150), nil)
ProfileCard.LayoutOrder = 1
local AvatarFrame = MakeFrame(ProfileCard, UDim2.new(0, 84, 0, 84), UDim2.new(0, 12, 0, 36), COLORS.Track, 0)
MakeCorner(AvatarFrame, 42)
MakeStroke(AvatarFrame, GetTheme().Accent, 1.5, 0.3)
local AvatarImage = Create("ImageLabel", { Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Image = "", Parent = AvatarFrame })
MakeCorner(AvatarImage, 42)

local ProfileDisplayName = MakeLabel(ProfileCard, "N/A", UDim2.new(1, -120, 0, 26), UDim2.new(0, 110, 0, 36), FONT_TITLE, 18, COLORS.Text)
local ProfileUsername = MakeLabel(ProfileCard, "@N/A", UDim2.new(1, -120, 0, 18), UDim2.new(0, 110, 0, 64), FONT_TEXT, 14, COLORS.SubText)
local ProfileUserId = MakeLabel(ProfileCard, "UserId: N/A", UDim2.new(1, -120, 0, 18), UDim2.new(0, 110, 0, 84), FONT_TEXT, 14, COLORS.SubText)
local ProfileAccountAge = MakeLabel(ProfileCard, "Account Age: N/A", UDim2.new(1, -120, 0, 18), UDim2.new(0, 110, 0, 104), FONT_TEXT, 14, COLORS.SubText)

-- Session Telemetry Card
local SessionCard = MakeCard(HomeScroll, "SESSION TELEMETRY", UDim2.new(1, -4, 0, 140), nil)
SessionCard.LayoutOrder = 2
local SessionLines = {}
local function AddSessionLine(key, yIndex)
	local lbl = MakeLabel(SessionCard, key .. ": N/A", UDim2.new(1, -24, 0, 18), UDim2.new(0, 12, 0, 36 + (yIndex - 1) * 20), FONT_TEXT, 14, COLORS.Text)
	SessionLines[key] = lbl
	return lbl
end
AddSessionLine("FPS", 1)
AddSessionLine("Uptime", 2)
AddSessionLine("Memory", 3)
AddSessionLine("Generator Status", 4)

--==================================================
-- [10] AUTO GENERATOR SYSTEM CORE & PANEL UI
--==================================================
local GeneratorCard = MakeCard(GeneratorScroll, "AUTO GENERATOR CONTROL", UDim2.new(1, -4, 0, 240), nil)
GeneratorCard.LayoutOrder = 1

local GenStatusLabel = MakeLabel(GeneratorCard, "Status: IDLE", UDim2.new(1, -24, 0, 20), UDim2.new(0, 12, 0, 36), FONT_BOLD, 14, COLORS.Bad)
local GenCountLabel = MakeLabel(GeneratorCard, "Total Generated: 0 items", UDim2.new(1, -24, 0, 20), UDim2.new(0, 12, 0, 60), FONT_TEXT, 14, COLORS.Text)

-- Log Box untuk Generator
local GenLogCard = MakeCard(GeneratorScroll, "GENERATOR ACTIVITY LOG", UDim2.new(1, -4, 0, 180), nil)
GenLogCard.LayoutOrder = 2
local LogScroll = Create("ScrollingFrame", {
	Size = UDim2.new(1, -24, 1, -48),
	Position = UDim2.new(0, 12, 0, 36),
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	ScrollBarThickness = 3,
	CanvasSize = UDim2.new(0, 0, 0, 0),
	AutomaticCanvasSize = Enum.AutomaticSize.Y,
	Parent = GenLogCard,
})
local LogList = Create("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 4), Parent = LogScroll })

local function AddGeneratorLog(message)
	local timeStr = os.date("%H:%M:%S")
	local logItem = MakeLabel(LogScroll, "[" .. timeStr .. "] " .. message, UDim2.new(1, 0, 0, 16), UDim2.new(0,0,0,0), FONT_TEXT, 12, COLORS.SubText)
	logItem.TextWrapped = true
end

-- Fungsi inti Auto Generator
local function StopAutoGenerator()
	CONFIG.GeneratorActive = false
	GenStatusLabel.Text = "Status: IDLE"
	GenStatusLabel.TextColor3 = COLORS.Bad
	if STATE.GeneratorTask then
		task.cancel(STATE.GeneratorTask)
		STATE.GeneratorTask = nil
	end
	AddGeneratorLog("Generator stopped by user.")
end

local function StartAutoGenerator()
	if CONFIG.GeneratorActive then return end
	CONFIG.GeneratorActive = true
	GenStatusLabel.Text = "Status: RUNNING ⚡"
	GenStatusLabel.TextColor3 = COLORS.Good
	AddGeneratorLog("Generator started successfully (Mode: " .. CONFIG.GeneratorMode .. ").")

	STATE.GeneratorTask = task.spawn(function()
		while CONFIG.GeneratorActive and not STATE.Destroyed do
			STATE.GeneratedCount = STATE.GeneratedCount + 1
			GenCountLabel.Text = "Total Generated: " .. STATE.GeneratedCount .. " items"
			
			-- Aksi otomatis generator (Contoh: Menyimulasikan proses spawn/farming/proses data)
			if STATE.GeneratedCount % 5 == 0 then
				AddGeneratorLog("Successfully processed batch #" .. math.floor(STATE.GeneratedCount / 5))
			end

			task.wait(CONFIG.GeneratorDelay)
		end
	end)
end

-- Tombol Kontrol Generator di Card
local ToggleGenBtn = MakeButton(GeneratorCard, "START GENERATOR", UDim2.new(1, -24, 0, 40), UDim2.new(0, 12, 0, 92), function()
	if CONFIG.GeneratorActive then
		StopAutoGenerator()
		ToggleGenBtn.Text = "START GENERATOR"
	else
		StartAutoGenerator()
		ToggleGenBtn.Text = "STOP GENERATOR"
	end
end)
MakeCorner(ToggleGenBtn, 10)

local ResetGenBtn = MakeButton(GeneratorCard, "Reset Counter", UDim2.new(1, -24, 0, 36), UDim2.new(0, 12, 0, 142), function()
	STATE.GeneratedCount = 0
	GenCountLabel.Text = "Total Generated: 0 items"
	AddGeneratorLog("Counter reset to 0.")
end)
MakeCorner(ResetGenBtn, 10)

--==================================================
-- [11] SETTINGS PANEL BUILDER
--==================================================
local function NewSettingsCard(title, height)
	return MakeCard(SettingsScroll, title, UDim2.new(1, -4, 0, height), nil)
end

local function MakeToggleRow(parent, label, y, getValue, onChange)
	local row = MakeFrame(parent, UDim2.new(1, -24, 0, 44), UDim2.new(0, 12, 0, y), COLORS.Track, 0.1)
	MakeCorner(row, 10)
	MakeLabel(row, label, UDim2.new(1, -110, 1, 0), UDim2.new(0, 12, 0, 0), FONT_BOLD, 14, COLORS.Text)
	local btn = MakeButton(row, "", UDim2.new(0, 88, 0, 32), UDim2.new(1, -96, 0.5, -16), function()
		local newVal = not getValue()
		onChange(newVal)
		btn.Text = newVal and "ON" or "OFF"
		btn.TextColor3 = newVal and COLORS.Good or COLORS.Bad
	end)
	btn.Text = getValue() and "ON" or "OFF"
	btn.TextColor3 = getValue() and COLORS.Good or COLORS.Bad
	return row
end

local function BuildSettingsUI()
	local displayCard = NewSettingsCard("DISPLAY & THEME", 140)
	MakeToggleRow(displayCard, "Background Grid", 36, function() return CONFIG.BackgroundGrid end, function(v) CONFIG.BackgroundGrid = v end)
	MakeToggleRow(displayCard, "HUD Decoration", 88, function() return CONFIG.HUDDecoration end, function(v) CONFIG.HUDDecoration = v end)
end

--==================================================
-- [12] WINDOW VISIBILITY & TAB MANAGEMENT
--==================================================
local function SwitchTab(tabName)
	STATE.SettingsOpen = (tabName == "Settings")
	STATE.GeneratorOpen = (tabName == "Generator")
	
	HomeScroll.Visible = (tabName == "Home")
	SettingsScroll.Visible = (tabName == "Settings")
	GeneratorScroll.Visible = (tabName == "Generator")
	
	SettingsBtn.Text = STATE.SettingsOpen and "⌂" or "⚙"
	GeneratorBtn.Text = STATE.GeneratorOpen and "⌂" or "⚡"
end

SettingsBtn.MouseButton1Click:Connect(function()
	if STATE.SettingsOpen then SwitchTab("Home") else SwitchTab("Settings") end
end)

GeneratorBtn.MouseButton1Click:Connect(function()
	if STATE.GeneratorOpen then SwitchTab("Home") else SwitchTab("Generator") end
end)

local function ApplyWindowLayout(keepCenter)
	if STATE.Destroyed then return end
	local size = ComputeWindowSize()
	local pos = keepCenter and ComputeCenteredPosition(size) or ClampAbsolute(STATE.MainPosition or ComputeCenteredPosition(size), size)
	MainWindow.Position = UDim2.fromOffset(pos.X, pos.Y)
	MainWindow.Size = UDim2.fromOffset(size.X, size.Y)
	STATE.MainPosition = pos
end

local function ShowMainWindow()
	STATE.Open = true
	STATE.Minimized = false
	ScreenGui.Enabled = true
	MainWindow.Visible = true
	ApplyWindowLayout(true)
end

local MINI_SIZE = 72
local MiniLogo = Create("Frame", {
	Name = "MiniLogo",
	Size = UDim2.new(0, MINI_SIZE, 0, MINI_SIZE),
	Position = UDim2.new(0, 0, 0, 0),
	BackgroundTransparency = 1,
	Visible = false,
	Parent = ScreenGui,
})
local MiniBody = MakeFrame(MiniLogo, UDim2.new(1, 0, 1, 0), UDim2.new(0, 0, 0, 0), GetTheme().Base2, 0.15)
MakeCorner(MiniBody, MINI_SIZE / 2)
MakeStroke(MiniBody, GetTheme().Accent, 1.5, 0.2)
local MiniHit = Create("TextButton", { Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Text = "", Parent = MiniLogo })

local function MinimizeToLogo()
	if not STATE.Open then return end
	STATE.Minimized = true
	local abs = MainWindow.AbsolutePosition
	local size = MainWindow.AbsoluteSize
	MiniLogo.Position = UDim2.fromOffset(abs.X + size.X/2 - MINI_SIZE/2, abs.Y + size.Y/2 - MINI_SIZE/2)
	MainWindow.Visible = false
	MiniLogo.Visible = true
end

local function RestoreFromLogo()
	if not STATE.Open then return end
	STATE.Minimized = false
	MiniLogo.Visible = false
	MainWindow.Visible = true
end

MinimizeBtn.MouseButton1Click:Connect(MinimizeToLogo)
CloseBtn.MouseButton1Click:Connect(function()
	StopAutoGenerator()
	STATE.Destroyed = true
	CleanupAll()
	ScreenGui:Destroy()
end)

--==================================================
-- [13] DRAG SYSTEM
--==================================================
local function BindDrag(target, handle, onMoveEnd)
	local dragging, startInput, startAbs, movedPx = false, nil, nil, 0
	TrackConnection(handle.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging, movedPx = true, 0
			startInput, startAbs = input.Position, target.AbsolutePosition
		end
	end))
	TrackConnection(UserInputService.InputChanged:Connect(function(input)
		if not dragging then return end
		if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
			local delta = Vector2.new(input.Position.X, input.Position.Y) - Vector2.new(startInput.X, startInput.Y)
			movedPx = math.max(movedPx, delta.Magnitude)
			if movedPx >= CONFIG.DragThreshold then
				local newPos = ClampAbsolute(startAbs + delta, target.AbsoluteSize)
				target.Position = UDim2.fromOffset(newPos.X, newPos.Y)
			end
		end
	end))
	TrackConnection(UserInputService.InputEnded:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
			dragging = false
			if onMoveEnd then onMoveEnd(movedPx >= CONFIG.DragThreshold) end
		end
	end))
end

BindDrag(MainWindow, Header, function() STATE.MainPosition = MainWindow.AbsolutePosition end)
BindDrag(MiniLogo, MiniHit, function(wasDrag) if not wasDrag then RestoreFromLogo() end end)

--==================================================
-- [14] HEARTBEAT LOOP & INIT
--==================================================
TrackConnection(RunService.Heartbeat:Connect(function(dt)
	if STATE.Destroyed then return end
	STATE.FrameCount = STATE.FrameCount + 1
	STATE.FrameTimer = STATE.FrameTimer + dt
	if STATE.FrameTimer >= 1 then
		STATE.LastFPS = STATE.FrameCount / STATE.FrameTimer
		SessionLines["FPS"].Text = "FPS: " .. math.floor(STATE.LastFPS + 0.5)
		SessionLines["Uptime"].Text = "Uptime: " .. math.floor(os.clock() - STATE.SessionStart) .. "s"
		pcall(function() SessionLines["Memory"].Text = string.format("Memory: %.1f MB", Stats:GetTotalMemoryUsageMb()) end)
		SessionLines["Generator Status"].Text = "Generator Status: " .. (CONFIG.GeneratorActive and "Active" or "Idle")
		STATE.FrameCount, STATE.FrameTimer = 0, 0
	end
end))

local function Init()
	pcall(function()
		ProfileDisplayName.Text = LocalPlayer.DisplayName
		ProfileUsername.Text = "@" .. LocalPlayer.Name
		ProfileUserId.Text = "UserId: " .. LocalPlayer.UserId
		ProfileAccountAge.Text = "Account Age: " .. LocalPlayer.AccountAge .. " hari"
		AvatarImage.Image = Players:GetUserThumbnailAsync(LocalPlayer.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size150x150)
	end)
	BuildSettingsUI()
	SwitchTab("Home")
	ShowMainWindow()
	STATE.Built = true
end

pcall(Init)

--==================================================
-- [15] GLOBAL API EXTENSION (`_G.vanz`)
--==================================================
_G.vanz = _G.vanz or {}
_G.vanz.ToggleGenerator = function()
	if CONFIG.GeneratorActive then StopAutoGenerator() else StartAutoGenerator() end
end
_G.vanz.StartGenerator = StartAutoGenerator
_G.vanz.StopGenerator = StopAutoGenerator
_G.vanz.GetGeneratorState = function()
	return { Active = CONFIG.GeneratorActive, GeneratedCount = STATE.GeneratedCount }
end
