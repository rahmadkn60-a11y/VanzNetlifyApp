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
-- [02] CONFIGURATION
--==================================================
local CONFIG = {
	Scale = 0.50,
	ScaleOptions = {0.40, 0.50, 0.60, 0.70, 0.80, 0.90, 1.00},
	WindowOpacity = 0.12,
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
	DragThreshold = 8,
	HomeUpdateRate = 0.25,
	FastUpdateRate = 0.1,
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
-- [03] STATE
--==================================================
local STATE = {
	Built = false,
	Open = false,
	Minimized = false,
	Destroyed = false,
	SettingsOpen = false,
	CombatOpen = false,
	MainPosition = nil,
	MiniPosition = nil,
	SessionStart = os.clock(),
	AccountAgeText = "N/A",
	DeviceText = "N/A",
	ThumbnailReady = false,
	MarketplaceName = "N/A",
	LastFPS = 0,
	FrameCount = 0,
	FrameTimer = 0,
	FastTimer = 0,
	SlowTimer = 0,
}

--==================================================
-- [04] CLEANUP SYSTEM
--==================================================
local Connections = {}
local ActiveTweens = {}
local CleanupCallbacks = {}

local function TrackConnection(conn)
	if conn then
		table.insert(Connections, conn)
	end
	return conn
end

local function TrackTween(tween)
	if tween then
		table.insert(ActiveTweens, tween)
	end
	return tween
end

local function AddCleanup(fn)
	table.insert(CleanupCallbacks, fn)
end

local function CleanupAll()
	for _, conn in ipairs(Connections) do
		pcall(function()
			conn:Disconnect()
		end)
	end
	table.clear(Connections)

	for _, tw in ipairs(ActiveTweens) do
		pcall(function()
			tw:Cancel()
		end)
	end
	table.clear(ActiveTweens)

	for _, fn in ipairs(CleanupCallbacks) do
		pcall(fn)
	end
	table.clear(CleanupCallbacks)
end

--==================================================
-- [05] THEME
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

--==================================================
-- [06] UI FACTORY
--==================================================
local function Create(className, props, children)
	local obj = Instance.new(className)
	for k, v in pairs(props or {}) do
		obj[k] = v
	end
	for _, child in ipairs(children or {}) do
		child.Parent = obj
	end
	return obj
end

local function MakeCorner(parent, radius)
	return Create("UICorner", {
		CornerRadius = UDim.new(0, radius or 10),
		Parent = parent,
	})
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
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, c1),
			ColorSequenceKeypoint.new(1, c2),
		}),
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
		TextScaled = false,
		TextWrapped = false,
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
		if CONFIG.ClickAnimation and not CONFIG.LowFXMode then
			local originalSize = btn.Size
			TrackTween(TweenService:Create(btn, TweenInfo.new(0.08, Enum.EasingStyle.Quad), {
				BackgroundTransparency = 0,
			})):Play()
			task.delay(0.08, function()
				if btn and btn.Parent then
					btn.Size = originalSize
				end
			end)
		end
		if onClick then
			local ok, err = pcall(onClick)
			if not ok then warn("[VANZ] button error:", err) end
		end
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

local function SafeNumber(v)
	if type(v) == "number" then
		return v
	end
	return nil
end

local function ToStr(v, digits)
	if v == nil then return "N/A" end
	if type(v) == "number" then
		if digits then
			return string.format("%." .. digits .. "f", v)
		end
		return tostring(math.floor(v + 0.5))
	end
	return tostring(v)
end

--==================================================
-- [07] ROOT SCREENGUI
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

--==================================================
-- [08] SCREEN HELPERS
--==================================================
local function GetViewport()
	if Camera and Camera.ViewportSize then
		return Camera.ViewportSize
	end
	return Vector2.new(1280, 720)
end

local BASE_WIDTH = 760
local BASE_HEIGHT = 520
local MIN_WIDTH_PX = 300

local function ComputeWindowSize()
	local vp = GetViewport()
	local s = CONFIG.Scale
	local w = BASE_WIDTH * s * 2
	local h = BASE_HEIGHT * s * 2
	w = math.clamp(w, MIN_WIDTH_PX, vp.X - 16)
	h = math.clamp(h, 260, vp.Y - 16)
	return Vector2.new(math.floor(w), math.floor(h))
end

local function ComputeCenteredPosition(size)
	local vp = GetViewport()
	return Vector2.new(
		math.floor((vp.X - size.X) / 2),
		math.floor((vp.Y - size.Y) / 2)
	)
end

local function ClampAbsolute(pos, size)
	local vp = GetViewport()
	local x = math.clamp(pos.X, 0, math.max(0, vp.X - size.X))
	local y = math.clamp(pos.Y, 0, math.max(0, vp.Y - size.Y))
	return Vector2.new(x, y)
end

--==================================================
-- [09] MAIN WINDOW
--==================================================
local MainWindow = Create("Frame", {
	Name = "MainWindow",
	Size = UDim2.new(0, 0, 0, 0),
	Position = UDim2.new(0, 0, 0, 0),
	AnchorPoint = Vector2.new(0, 0),
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

local InnerBorder = MakeFrame(MainWindow, UDim2.new(1, -8, 1, -8), UDim2.new(0, 4, 0, 4), GetTheme().Base, 1)
MakeCorner(InnerBorder, CONFIG.CornerRadius - 2)
MakeStroke(InnerBorder, GetTheme().Accent2, 1, 0.82)

local AccentLine = MakeFrame(MainWindow, UDim2.new(0.3, 0, 0, 2), UDim2.new(0.35, 0, 0, 0), GetTheme().Accent2, 0.1)
MakeGradient(AccentLine, GetTheme().Accent, GetTheme().Accent2, 0)

local HEADER_HEIGHT = 56

--==================================================
-- [10] HEADER
--==================================================
local Header = MakeFrame(MainWindow, UDim2.new(1, 0, 0, HEADER_HEIGHT), UDim2.new(0, 0, 0, 0), GetTheme().Base2, 0.2)
MakeCorner(Header, CONFIG.CornerRadius)

local HeaderLogo = MakeFrame(Header, UDim2.new(0, 36, 0, 36), UDim2.new(0, 12, 0.5, -18), GetTheme().Base, 1)
MakeCorner(HeaderLogo, 18)
local HeaderLogoRing = MakeFrame(HeaderLogo, UDim2.new(1, 0, 1, 0), UDim2.new(0, 0, 0, 0), GetTheme().Accent, 1)
MakeCorner(HeaderLogoRing, 18)
MakeStroke(HeaderLogoRing, GetTheme().Accent, 2, 0.1)
local HeaderLogoCore = MakeFrame(HeaderLogo, UDim2.new(0, 10, 0, 10), UDim2.new(0.5, -5, 0.5, -5), GetTheme().Accent2, 0)
MakeCorner(HeaderLogoCore, 5)

-- CONTROL ZONE diperlebar untuk 4 tombol (Combat, Settings, Minimize, Close)
local CONTROL_ZONE_WIDTH = 200
local ControlZone = MakeFrame(Header, UDim2.new(0, CONTROL_ZONE_WIDTH, 1, 0), UDim2.new(1, -CONTROL_ZONE_WIDTH - 8, 0, 0), COLORS.Card, 1)

local TitleArea = MakeFrame(Header, UDim2.new(1, -(12 + 36 + 12 + CONTROL_ZONE_WIDTH), 1, 0), UDim2.new(0, 12 + 36 + 10, 0, 0), COLORS.Card, 1)
local TitleLabel = MakeLabel(TitleArea, "VANZ ULTRA CONTROL CENTER", UDim2.new(1, 0, 0, 22), UDim2.new(0, 0, 0, 8), FONT_TITLE, 15, COLORS.Text)
local SubtitleLabel = MakeLabel(TitleArea, "SYSTEM ONLINE", UDim2.new(1, 0, 0, 16), UDim2.new(0, 0, 0, 28), FONT_TEXT, 11, COLORS.SubText)

local BTN_SIZE = 44
local BTN_GAP = 6
local CombatBtn
local SettingsBtn
local MinimizeBtn
local CloseBtn

local function LayoutControls()
	local zoneW = ControlZone.AbsoluteSize.X
	local zoneH = ControlZone.AbsoluteSize.Y
	local btnY = math.floor((zoneH - BTN_SIZE) / 2)
	local x = zoneW - BTN_SIZE
	if CloseBtn then CloseBtn.Position = UDim2.new(0, x, 0, btnY) end
	x = x - BTN_SIZE - BTN_GAP
	if MinimizeBtn then MinimizeBtn.Position = UDim2.new(0, x, 0, btnY) end
	x = x - BTN_SIZE - BTN_GAP
	if SettingsBtn then SettingsBtn.Position = UDim2.new(0, x, 0, btnY) end
	x = x - BTN_SIZE - BTN_GAP
	if CombatBtn then CombatBtn.Position = UDim2.new(0, x, 0, btnY) end
end

CombatBtn = MakeButton(ControlZone, "⚔", UDim2.new(0, BTN_SIZE, 0, BTN_SIZE), UDim2.new(0, 0, 0, 0), function()
	-- diisi nanti oleh modul Combat
end)
SettingsBtn = MakeButton(ControlZone, "⚙", UDim2.new(0, BTN_SIZE, 0, BTN_SIZE), UDim2.new(0, 0, 0, 0), function()
	-- diisi nanti oleh modul Settings
end)
MinimizeBtn = MakeButton(ControlZone, "—", UDim2.new(0, BTN_SIZE, 0, BTN_SIZE), UDim2.new(0, 0, 0, 0), function()
	-- diisi nanti oleh modul Minimize
end)
CloseBtn = MakeButton(ControlZone, "X", UDim2.new(0, BTN_SIZE, 0, BTN_SIZE), UDim2.new(0, 0, 0, 0), function()
	-- diisi nanti oleh modul Close
end)

TrackConnection(ControlZone:GetPropertyChangedSignal("AbsoluteSize"):Connect(LayoutControls))
task.defer(LayoutControls)

--==================================================
-- [11] BODY CONTAINER
--==================================================
local Body = MakeFrame(MainWindow, UDim2.new(1, -16, 1, -(HEADER_HEIGHT + 12)), UDim2.new(0, 8, 0, HEADER_HEIGHT + 4), COLORS.Card, 1)

local HomeScroll = Create("ScrollingFrame", {
	Name = "HomeScroll",
	Size = UDim2.new(1, 0, 1, 0),
	Position = UDim2.new(0, 0, 0, 0),
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	ScrollBarThickness = 5,
	ScrollBarImageColor3 = GetTheme().Accent,
	CanvasSize = UDim2.new(0, 0, 0, 0),
	AutomaticCanvasSize = Enum.AutomaticSize.None,
	ScrollingDirection = Enum.ScrollingDirection.Y,
	ElasticBehavior = Enum.ElasticBehavior.Never,
	Visible = true,
	Parent = Body,
})

local HomeList = Create("UIListLayout", {
	SortOrder = Enum.SortOrder.LayoutOrder,
	Padding = UDim.new(0, 10),
	Parent = HomeScroll,
})
Create("UIPadding", {
	PaddingLeft = UDim.new(0, 8),
	PaddingRight = UDim.new(0, 8),
	PaddingTop = UDim.new(0, 6),
	PaddingBottom = UDim.new(0, 12),
	Parent = HomeScroll,
})

local function RefreshHomeCanvas()
	if not HomeScroll or not HomeScroll.Parent then return end
	local contentY = HomeList.AbsoluteContentSize.Y + 24
	HomeScroll.CanvasSize = UDim2.new(0, 0, 0, contentY)
end
TrackConnection(HomeList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(RefreshHomeCanvas))

local SettingsScroll = Create("ScrollingFrame", {
	Name = "SettingsScroll",
	Size = UDim2.new(1, 0, 1, 0),
	Position = UDim2.new(0, 0, 0, 0),
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	ScrollBarThickness = 5,
	ScrollBarImageColor3 = GetTheme().Accent2,
	CanvasSize = UDim2.new(0, 0, 0, 0),
	AutomaticCanvasSize = Enum.AutomaticSize.None,
	ScrollingDirection = Enum.ScrollingDirection.Y,
	ElasticBehavior = Enum.ElasticBehavior.Never,
	Visible = false,
	Parent = Body,
})

local SettingsList = Create("UIListLayout", {
	SortOrder = Enum.SortOrder.LayoutOrder,
	Padding = UDim.new(0, 10),
	Parent = SettingsScroll,
})
Create("UIPadding", {
	PaddingLeft = UDim.new(0, 8),
	PaddingRight = UDim.new(0, 8),
	PaddingTop = UDim.new(0, 6),
	PaddingBottom = UDim.new(0, 12),
	Parent = SettingsScroll,
})

local function RefreshSettingsCanvas()
	if not SettingsScroll or not SettingsScroll.Parent then return end
	local contentY = SettingsList.AbsoluteContentSize.Y + 24
	SettingsScroll.CanvasSize = UDim2.new(0, 0, 0, contentY)
end
TrackConnection(SettingsList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(RefreshSettingsCanvas))

-- COMBAT SCROLL — tab ketiga, untuk cheat / exploit module
local CombatScroll = Create("ScrollingFrame", {
	Name = "CombatScroll",
	Size = UDim2.new(1, 0, 1, 0),
	Position = UDim2.new(0, 0, 0, 0),
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	ScrollBarThickness = 5,
	ScrollBarImageColor3 = Color3.fromRGB(255, 90, 110),
	CanvasSize = UDim2.new(0, 0, 0, 0),
	AutomaticCanvasSize = Enum.AutomaticSize.None,
	ScrollingDirection = Enum.ScrollingDirection.Y,
	ElasticBehavior = Enum.ElasticBehavior.Never,
	Visible = false,
	Parent = Body,
})

local CombatList = Create("UIListLayout", {
	SortOrder = Enum.SortOrder.LayoutOrder,
	Padding = UDim.new(0, 10),
	Parent = CombatScroll,
})
Create("UIPadding", {
	PaddingLeft = UDim.new(0, 8),
	PaddingRight = UDim.new(0, 8),
	PaddingTop = UDim.new(0, 6),
	PaddingBottom = UDim.new(0, 12),
	Parent = CombatScroll,
})

local function RefreshCombatCanvas()
	if not CombatScroll or not CombatScroll.Parent then return end
	local contentY = CombatList.AbsoluteContentSize.Y + 24
	CombatScroll.CanvasSize = UDim2.new(0, 0, 0, contentY)
end
TrackConnection(CombatList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(RefreshCombatCanvas))

--==================================================
-- [12] HOME CARDS: USER PROFILE
--==================================================
local ProfileCard = MakeCard(HomeScroll, "USER PROFILE", UDim2.new(1, -4, 0, 150), nil)
ProfileCard.LayoutOrder = 1

local AvatarFrame = MakeFrame(ProfileCard, UDim2.new(0, 84, 0, 84), UDim2.new(0, 12, 0, 36), COLORS.Track, 0)
MakeCorner(AvatarFrame, 42)
MakeStroke(AvatarFrame, GetTheme().Accent, 1.5, 0.3)
local AvatarImage = Create("ImageLabel", {
	Size = UDim2.new(1, 0, 1, 0),
	BackgroundTransparency = 1,
	Image = "",
	Parent = AvatarFrame,
})
MakeCorner(AvatarImage, 42)

local OnlineDot = MakeFrame(ProfileCard, UDim2.new(0, 12, 0, 12), UDim2.new(0, 84, 0, 84), COLORS.Good, 0)
MakeCorner(OnlineDot, 6)
MakeStroke(OnlineDot, COLORS.Card, 2, 0)

local ProfileDisplayName = MakeLabel(ProfileCard, "N/A", UDim2.new(1, -120, 0, 26), UDim2.new(0, 110, 0, 36), FONT_TITLE, 18, COLORS.Text)
local ProfileUsername = MakeLabel(ProfileCard, "@N/A", UDim2.new(1, -120, 0, 18), UDim2.new(0, 110, 0, 64), FONT_TEXT, 14, COLORS.SubText)
local ProfileUserId = MakeLabel(ProfileCard, "UserId: N/A", UDim2.new(1, -120, 0, 18), UDim2.new(0, 110, 0, 84), FONT_TEXT, 14, COLORS.SubText)
local ProfileAccountAge = MakeLabel(ProfileCard, "Account Age: N/A", UDim2.new(1, -120, 0, 18), UDim2.new(0, 110, 0, 104), FONT_TEXT, 14, COLORS.SubText)
local ProfileTeam = MakeLabel(ProfileCard, "Team: N/A", UDim2.new(1, -120, 0, 18), UDim2.new(0, 110, 0, 124), FONT_TEXT, 14, COLORS.SubText)

local ProfileMembership = MakeLabel(ProfileCard, "Membership: N/A", UDim2.new(0.5, -12, 0, 18), UDim2.new(0.5, 0, 0, 36), FONT_TEXT, 14, COLORS.SubText)
local ProfileDevice = MakeLabel(ProfileCard, "Device: N/A", UDim2.new(0.5, -12, 0, 18), UDim2.new(0.5, 0, 0, 56), FONT_TEXT, 14, COLORS.SubText)

local function FillProfile()
	pcall(function()
		ProfileDisplayName.Text = LocalPlayer.DisplayName or "N/A"
		ProfileUsername.Text = "@" .. (LocalPlayer.Name or "N/A")
		ProfileUserId.Text = "UserId: " .. ToStr(LocalPlayer.UserId)
		ProfileAccountAge.Text = "Account Age: " .. ToStr(LocalPlayer.AccountAge) .. " hari"
		ProfileTeam.Text = "Team: " .. (LocalPlayer.Team and LocalPlayer.Team.Name or "N/A")
	end)

	pcall(function()
		local ok, img = pcall(function()
			return Players:GetUserThumbnailAsync(LocalPlayer.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size150x150)
		end)
		if ok and img then
			AvatarImage.Image = img
			STATE.ThumbnailReady = true
		end
	end)

	pcall(function()
		local mt = LocalPlayer.MembershipType
		local mtText = "N/A"
		if mt == Enum.MembershipType.Premium then
			mtText = "Premium"
		elseif mt == Enum.MembershipType.None then
			mtText = "None"
		end
		ProfileMembership.Text = "Membership: " .. mtText
	end)

	pcall(function()
		local device = "N/A"
		if UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled then
			device = "Mobile"
		elseif UserInputService.KeyboardEnabled then
			device = "PC"
		elseif UserInputService.GamepadEnabled then
			device = "Console"
		end
		STATE.DeviceText = device
		ProfileDevice.Text = "Device: " .. device
	end)
end

--==================================================
-- [13] HOME CARDS: CHARACTER STATUS
--==================================================
local CharCard = MakeCard(HomeScroll, "CHARACTER STATUS", UDim2.new(1, -4, 0, 210), nil)
CharCard.LayoutOrder = 2

local CharLines = {}
local function AddCharLine(key, yIndex)
	local lbl = MakeLabel(CharCard, key .. ": N/A", UDim2.new(1, -24, 0, 18), UDim2.new(0, 12, 0, 36 + (yIndex - 1) * 20), FONT_TEXT, 14, COLORS.Text)
	CharLines[key] = lbl
	return lbl
end

AddCharLine("WalkSpeed", 1)
AddCharLine("JumpPower", 2)
AddCharLine("Health", 3)
AddCharLine("MaxHealth", 4)
AddCharLine("Health %", 5)
AddCharLine("HipHeight", 6)
AddCharLine("AutoRotate", 7)
AddCharLine("PlatformStand", 8)
AddCharLine("RigType", 9)
AddCharLine("Character State", 10)

--==================================================
-- [14] HOME CARDS: MOVEMENT CORE
--==================================================
local MoveCard = MakeCard(HomeScroll, "MOVEMENT CORE", UDim2.new(1, -4, 0, 170), nil)
MoveCard.LayoutOrder = 3

local MoveLines = {}
local function AddMoveLine(key, yIndex)
	local lbl = MakeLabel(MoveCard, key .. ": N/A", UDim2.new(1, -24, 0, 18), UDim2.new(0, 12, 0, 36 + (yIndex - 1) * 20), FONT_TEXT, 14, COLORS.Text)
	MoveLines[key] = lbl
	return lbl
end

AddMoveLine("MoveDirection", 1)
AddMoveLine("Velocity", 2)
AddMoveLine("Grounded", 3)
AddMoveLine("Floor Material", 4)
AddMoveLine("Seat Status", 5)
AddMoveLine("Humanoid State", 6)
AddMoveLine("Character Name", 7)

--==================================================
-- [15] HOME CARDS: CHARACTER HEALTH BAR
--==================================================
local HealthCard = MakeCard(HomeScroll, "HEALTH", UDim2.new(1, -4, 0, 96), nil)
HealthCard.LayoutOrder = 4

local HealthTrack = MakeFrame(HealthCard, UDim2.new(1, -24, 0, 22), UDim2.new(0, 12, 0, 40), COLORS.Track, 0)
MakeCorner(HealthTrack, 8)
local HealthFill = MakeFrame(HealthTrack, UDim2.new(1, 0, 1, 0), UDim2.new(0, 0, 0, 0), COLORS.Good, 0)
MakeCorner(HealthFill, 8)
MakeGradient(HealthFill, COLORS.Good, GetTheme().Accent2, 0)
local HealthText = MakeLabel(HealthCard, "100 / 100", UDim2.new(1, -24, 0, 18), UDim2.new(0, 12, 0, 68), FONT_BOLD, 14, COLORS.Text, Enum.TextXAlignment.Right)

--==================================================
-- [16] HOME CARDS: POSITION TELEMETRY
--==================================================
local PosCard = MakeCard(HomeScroll, "POSITION TELEMETRY", UDim2.new(1, -4, 0, 196), nil)
PosCard.LayoutOrder = 5

local PosLines = {}
local function AddPosLine(key, yIndex)
	local lbl = MakeLabel(PosCard, key .. ": N/A", UDim2.new(1, -24, 0, 18), UDim2.new(0, 12, 0, 36 + (yIndex - 1) * 20), FONT_TEXT, 14, COLORS.Text)
	PosLines[key] = lbl
	return lbl
end

AddPosLine("Pos X", 1)
AddPosLine("Pos Y", 2)
AddPosLine("Pos Z", 3)
AddPosLine("Vel X", 4)
AddPosLine("Vel Y", 5)
AddPosLine("Vel Z", 6)
AddPosLine("Magnitude", 7)
AddPosLine("Facing", 8)

--==================================================
-- [17] HOME CARDS: PLAYER INFORMATION
--==================================================
local InfoCard = MakeCard(HomeScroll, "PLAYER INFORMATION", UDim2.new(1, -4, 0, 360), nil)
InfoCard.LayoutOrder = 6

local InfoLines = {}
local function AddInfoLine(key, yIndex)
	local lbl = MakeLabel(InfoCard, key .. ": N/A", UDim2.new(1, -24, 0, 18), UDim2.new(0, 12, 0, 36 + (yIndex - 1) * 20), FONT_TEXT, 14, COLORS.Text)
	InfoLines[key] = lbl
	return lbl
end

AddInfoLine("Display Name", 1)
AddInfoLine("Username", 2)
AddInfoLine("UserId", 3)
AddInfoLine("Account Age", 4)
AddInfoLine("Team", 5)
AddInfoLine("Team Color", 6)
AddInfoLine("Character", 7)
AddInfoLine("Rig Type", 8)
AddInfoLine("Device", 9)
AddInfoLine("Camera Mode", 10)
AddInfoLine("Field Of View", 11)
AddInfoLine("Graphics Quality", 12)
AddInfoLine("Session Time", 13)
AddInfoLine("Server JobId", 14)
AddInfoLine("PlaceId", 15)
AddInfoLine("GameId", 16)

--==================================================
-- [18] HOME CARDS: SESSION TELEMETRY
--==================================================
local SessionCard = MakeCard(HomeScroll, "SESSION TELEMETRY", UDim2.new(1, -4, 0, 180), nil)
SessionCard.LayoutOrder = 7

local SessionLines = {}
local function AddSessionLine(key, yIndex)
	local lbl = MakeLabel(SessionCard, key .. ": N/A", UDim2.new(1, -24, 0, 18), UDim2.new(0, 12, 0, 36 + (yIndex - 1) * 20), FONT_TEXT, 14, COLORS.Text)
	SessionLines[key] = lbl
	return lbl
end

AddSessionLine("FPS", 1)
AddSessionLine("Ping", 2)
AddSessionLine("Uptime", 3)
AddSessionLine("Memory", 4)
AddSessionLine("Heartbeat", 5)
AddSessionLine("Client State", 6)
AddSessionLine("System", 7)

--==================================================
-- [19] SETTINGS PANEL: DISPLAY
--==================================================
local SettingsDisplayCard
local ScaleLabel
local function BuildSettingsRow(parent, text, y)
	return MakeLabel(parent, text, UDim2.new(1, -24, 0, 18), UDim2.new(0, 12, 0, y), FONT_BOLD, 14, COLORS.SubText)
end

--==================================================
-- [20] SETTINGS PANEL: RUNTIME STATE HELPERS
--==================================================
local ApplyWindowLayout

--==================================================
-- [21] DRAG ENGINE
--==================================================
local DragState = {
	Active = false,
	Target = nil,
	StartInput = nil,
	StartAbs = nil,
	Moved = false,
}

local function BindDrag(target, handle, onMoveEnd)
	local dragging = false
	local startInput = nil
	local startAbs = nil
	local movedPx = 0

	TrackConnection(handle.InputBegan:Connect(function(input)
		if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then
			return
		end
		dragging = true
		movedPx = 0
		startInput = input.Position
		startAbs = target.AbsolutePosition
		DragState.Active = true
		DragState.Target = target
		DragState.StartInput = startInput
		DragState.StartAbs = startAbs
		DragState.Moved = false
	end))

	TrackConnection(UserInputService.InputChanged:Connect(function(input)
		if not dragging then return end
		if input.UserInputType ~= Enum.UserInputType.MouseMovement and input.UserInputType ~= Enum.UserInputType.Touch then
			return
		end

		local delta = Vector2.new(input.Position.X, input.Position.Y) - Vector2.new(startInput.X, startInput.Y)
		movedPx = math.max(movedPx, delta.Magnitude)

		if movedPx < CONFIG.DragThreshold then
			return
		end
		DragState.Moved = true

		local targetSize = target.AbsoluteSize
		local newPos = ClampAbsolute(startAbs + delta, targetSize)
		target.Position = UDim2.fromOffset(newPos.X, newPos.Y)
		target.AnchorPoint = Vector2.new(0, 0)
	end))

	TrackConnection(UserInputService.InputEnded:Connect(function(input)
		if not dragging then return end
		if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then
			return
		end
		dragging = false
		DragState.Active = false
		local wasDrag = movedPx >= CONFIG.DragThreshold
		if onMoveEnd then
			local ok, err = pcall(onMoveEnd, wasDrag)
			if not ok then warn("[VANZ] drag end error:", err) end
		end
	end))
end

--==================================================
-- [22] MINI LOGO
--==================================================
local MINI_SIZE = 72

local MiniLogo = Create("Frame", {
	Name = "MiniLogo",
	Size = UDim2.new(0, MINI_SIZE, 0, MINI_SIZE),
	Position = UDim2.new(0, 0, 0, 0),
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	Visible = false,
	Parent = ScreenGui,
})

local MiniBody = MakeFrame(MiniLogo, UDim2.new(1, 0, 1, 0), UDim2.new(0, 0, 0, 0), GetTheme().Base2, 0.15)
MakeCorner(MiniBody, MINI_SIZE / 2)
MakeStroke(MiniBody, GetTheme().Accent, 1.5, 0.2)

local MiniRing = MakeFrame(MiniLogo, UDim2.new(1, -10, 1, -10), UDim2.new(0, 5, 0, 5), GetTheme().Accent, 1)
MakeCorner(MiniRing, MINI_SIZE / 2)
MakeStroke(MiniRing, GetTheme().Accent2, 1.2, 0.3)

local MiniCore = MakeFrame(MiniLogo, UDim2.new(0, 18, 0, 18), UDim2.new(0.5, -9, 0.5, -9), GetTheme().Accent2, 0)
MakeCorner(MiniCore, 9)

local MiniScan = MakeFrame(MiniLogo, UDim2.new(0.6, 0, 0, 2), UDim2.new(0.2, 0, 0.5, -1), GetTheme().Accent2, 0.2)
MakeGradient(MiniScan, GetTheme().Accent, GetTheme().Accent2, 0)

local MiniHit = Create("TextButton", {
	Size = UDim2.new(1, 0, 1, 0),
	BackgroundTransparency = 1,
	Text = "",
	AutoButtonColor = false,
	ZIndex = 5,
	Parent = MiniLogo,
})

--==================================================
-- [23] FLOATING GUI MANAGER
--==================================================
local function GetMiniCenter()
	if MiniLogo.AbsoluteSize.X > 0 then
		return Vector2.new(MiniLogo.AbsolutePosition.X + MiniLogo.AbsoluteSize.X / 2,
			MiniLogo.AbsolutePosition.Y + MiniLogo.AbsoluteSize.Y / 2)
	end
	return Vector2.new(GetViewport().X / 2, GetViewport().Y / 2)
end

local function SetMainAbsolute(pos, size)
	local clamped = ClampAbsolute(pos, size)
	MainWindow.Position = UDim2.fromOffset(clamped.X, clamped.Y)
	MainWindow.Size = UDim2.fromOffset(size.X, size.Y)
	STATE.MainPosition = clamped
	return clamped
end

local function SetMiniAbsolute(pos)
	local vp = GetViewport()
	local x = math.clamp(pos.X, 0, math.max(0, vp.X - MINI_SIZE))
	local y = math.clamp(pos.Y, 0, math.max(0, vp.Y - MINI_SIZE))
	MiniLogo.Position = UDim2.fromOffset(x, y)
	STATE.MiniPosition = Vector2.new(x, y)
end

local function ReadMainAbsolute()
	if MainWindow.AbsoluteSize.X > 0 then
		return Vector2.new(MainWindow.AbsolutePosition.X, MainWindow.AbsolutePosition.Y)
	end
	return STATE.MainPosition or ComputeCenteredPosition(ComputeWindowSize())
end

--==================================================
-- [24] WINDOW LAYOUT APPLY
--==================================================
ApplyWindowLayout = function(keepCenter)
	if STATE.Destroyed then return end
	local size = ComputeWindowSize()
	local pos
	if keepCenter or not STATE.MainPosition then
		pos = ComputeCenteredPosition(size)
	else
		pos = ClampAbsolute(STATE.MainPosition, size)
	end
	SetMainAbsolute(pos, size)
end

local function ShowMainWindow()
	STATE.Open = true
	STATE.Minimized = false
	ScreenGui.Enabled = true
	MainWindow.Visible = true
	MiniLogo.Visible = false

	ApplyWindowLayout(STATE.MainPosition == nil)

	if CONFIG.AnimationEnabled and CONFIG.TransitionAnimation and not CONFIG.LowFXMode then
		MainWindow.BackgroundTransparency = 1
		TrackTween(TweenService:Create(MainWindow, TweenInfo.new(0.28 / CONFIG.AnimationSpeed, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
			BackgroundTransparency = CONFIG.WindowOpacity,
		})):Play()
	end
end

local function MinimizeToLogo()
	if not STATE.Open then return end
	STATE.Minimized = true

	local mainCenter = ReadMainAbsolute()
	local mainSize = MainWindow.AbsoluteSize
	local centerX = mainCenter.X + mainSize.X / 2
	local centerY = mainCenter.Y + mainSize.Y / 2

	SetMiniAbsolute(Vector2.new(centerX - MINI_SIZE / 2, centerY - MINI_SIZE / 2))

	MainWindow.Visible = false
	MiniLogo.Visible = true

	if CONFIG.AnimationEnabled and CONFIG.TransitionAnimation and not CONFIG.LowFXMode then
		MiniLogo.Size = UDim2.new(0, 10, 0, 10)
		TrackTween(TweenService:Create(MiniLogo, TweenInfo.new(0.22 / CONFIG.AnimationSpeed, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
			Size = UDim2.new(0, MINI_SIZE, 0, MINI_SIZE),
		})):Play()
	else
		MiniLogo.Size = UDim2.new(0, MINI_SIZE, 0, MINI_SIZE)
	end
end

local function RestoreFromLogo()
	if not STATE.Open then return end
	STATE.Minimized = false

	local miniPos = STATE.MiniPosition or Vector2.new(0, 0)
	local size = ComputeWindowSize()
	local centerX = miniPos.X + MINI_SIZE / 2
	local centerY = miniPos.Y + MINI_SIZE / 2
	local pos = Vector2.new(centerX - size.X / 2, centerY - size.Y / 2)

	MiniLogo.Visible = false
	SetMainAbsolute(pos, size)
	MainWindow.Visible = true

	if CONFIG.AnimationEnabled and CONFIG.TransitionAnimation and not CONFIG.LowFXMode then
		MainWindow.BackgroundTransparency = 1
		TrackTween(TweenService:Create(MainWindow, TweenInfo.new(0.24 / CONFIG.AnimationSpeed, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
			BackgroundTransparency = CONFIG.WindowOpacity,
		})):Play()
	end
end

local DestroyAll

--==================================================
-- [25] TAB SYSTEM (HOME / SETTINGS / COMBAT)
--==================================================
local function SetTab(tabName)
	if tabName ~= "home" and tabName ~= "settings" and tabName ~= "combat" then
		tabName = "home"
	end
	STATE.SettingsOpen = (tabName == "settings")
	STATE.CombatOpen = (tabName == "combat")
	HomeScroll.Visible = (tabName == "home")
	SettingsScroll.Visible = (tabName == "settings")
	CombatScroll.Visible = (tabName == "combat")
	if tabName == "home" then
		SettingsBtn.Text = "⚙"
		CombatBtn.Text = "⚔"
	elseif tabName == "settings" then
		SettingsBtn.Text = "⌂"
	elseif tabName == "combat" then
		CombatBtn.Text = "⌂"
	end
end

--==================================================
-- [26] SETTINGS: UI BUILDERS
--==================================================
local SettingsCards = {}

local function NewSettingsCard(title, height)
	local card = MakeCard(SettingsScroll, title, UDim2.new(1, -4, 0, height), nil)
	table.insert(SettingsCards, card)
	return card
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

local function MakeCycleRow(parent, label, y, options, getCurrent, onChange, fmt)
	local row = MakeFrame(parent, UDim2.new(1, -24, 0, 44), UDim2.new(0, 12, 0, y), COLORS.Track, 0.1)
	MakeCorner(row, 10)
	MakeLabel(row, label, UDim2.new(1, -150, 1, 0), UDim2.new(0, 12, 0, 0), FONT_BOLD, 14, COLORS.Text)

	local function currentText()
		local v = getCurrent()
		if fmt then return fmt(v) end
		return tostring(v)
	end

	local btn = MakeButton(row, currentText(), UDim2.new(0, 132, 0, 32), UDim2.new(1, -140, 0.5, -16), function()
		local cur = getCurrent()
		local idx = 1
		for i, opt in ipairs(options) do
			if opt == cur then idx = i break end
		end
		local nextIdx = (idx % #options) + 1
		onChange(options[nextIdx])
		btn.Text = currentText()
	end)
	return row, btn
end

local function MakeStepperRow(parent, label, y, minV, maxV, step, getCurrent, onChange, fmt)
	local row = MakeFrame(parent, UDim2.new(1, -24, 0, 44), UDim2.new(0, 12, 0, y), COLORS.Track, 0.1)
	MakeCorner(row, 10)
	MakeLabel(row, label, UDim2.new(0.45, 0, 1, 0), UDim2.new(0, 12, 0, 0), FONT_BOLD, 14, COLORS.Text)

	local valueLabel = MakeLabel(row, "", UDim2.new(0, 70, 0, 22), UDim2.new(1, -150, 0.5, -11), FONT_BOLD, 14, GetTheme().Accent2, Enum.TextXAlignment.Center)

	local function refresh()
		local v = getCurrent()
		valueLabel.Text = fmt and fmt(v) or tostring(v)
	end
	refresh()

	MakeButton(row, "-", UDim2.new(0, 40, 0, 32), UDim2.new(1, -116, 0.5, -16), function()
		local v = math.max(minV, getCurrent() - step)
		onChange(v)
		refresh()
	end)
	MakeButton(row, "+", UDim2.new(0, 40, 0, 32), UDim2.new(1, -52, 0.5, -16), function()
		local v = math.min(maxV, getCurrent() + step)
		onChange(v)
		refresh()
	end)
	return row
end

--==================================================
-- [27] SETTINGS: DPI / GUI SCALE
--==================================================
local function SetScale(value)
	local valid = false
	for _, opt in ipairs(CONFIG.ScaleOptions) do
		if math.abs(opt - value) < 0.001 then
			valid = true
			break
		end
	end
	if not valid then return false end
	CONFIG.Scale = value
	if STATE.Open and not STATE.Minimized then
		ApplyWindowLayout(false)
	end
	return true
end

local function ScaleText(v)
	return string.format("%d%%", math.floor(v * 100 + 0.5))
end

--==================================================
-- [28] SETTINGS: BUILD UI
--==================================================
local function BuildSettingsUI()
	local displayCard = NewSettingsCard("DISPLAY", 260)
	displayCard.LayoutOrder = 1
	MakeCycleRow(displayCard, "GUI Scale / DPI", 36, CONFIG.ScaleOptions,
		function() return CONFIG.Scale end,
		function(v) SetScale(v) end,
		ScaleText)
	MakeStepperRow(displayCard, "Window Opacity", 88, 0.02, 0.5, 0.02,
		function() return CONFIG.WindowOpacity end,
		function(v)
			CONFIG.WindowOpacity = v
			if STATE.Open and not STATE.Minimized then
				MainWindow.BackgroundTransparency = v
			end
		end,
		function(v) return string.format("%.2f", v) end)
	MakeStepperRow(displayCard, "Corner Radius", 140, 6, 24, 2,
		function() return CONFIG.CornerRadius end,
		function(v)
			CONFIG.CornerRadius = v
		end,
		function(v) return tostring(v) end)
	MakeStepperRow(displayCard, "Border Intensity", 192, 0, 1, 0.1,
		function() return CONFIG.BorderIntensity end,
		function(v)
			CONFIG.BorderIntensity = v
			MainStroke.Transparency = 1 - v
		end,
		function(v) return string.format("%.1f", v) end)

	local glassCard = NewSettingsCard("GLASS", 120)
	glassCard.LayoutOrder = 2
	MakeStepperRow(glassCard, "Glass Intensity", 36, 0, 1, 0.1,
		function() return CONFIG.GlassIntensity end,
		function(v)
			CONFIG.GlassIntensity = v
			MainGradient.Transparency = NumberSequence.new(1 - v)
		end,
		function(v) return string.format("%.1f", v) end)

	local animCard = NewSettingsCard("ANIMATION", 420)
	animCard.LayoutOrder = 3
	local animRows = {
		{"Master Animation", "AnimationEnabled"},
		{"Soft Animation", "SoftAnimation"},
		{"Logo Animation", "LogoAnimation"},
		{"Radar Animation", "RadarAnimation"},
		{"Particle Animation", "ParticleAnimation"},
		{"Scanline", "Scanline"},
		{"Hover Animation", "HoverAnimation"},
		{"Click Animation", "ClickAnimation"},
		{"Transition Animation", "TransitionAnimation"},
	}
	local ay = 36
	for _, pair in ipairs(animRows) do
		local label, key = pair[1], pair[2]
		MakeToggleRow(animCard, label, ay, function() return CONFIG[key] end, function(v)
			CONFIG[key] = v
		end)
		ay = ay + 46
	end
	MakeCycleRow(animCard, "Animation Speed", ay, {0.5, 0.75, 1, 1.25, 1.5},
		function() return CONFIG.AnimationSpeed end,
		function(v) CONFIG.AnimationSpeed = v end,
		function(v) return string.format("%.2fx", v) end)

	local visualCard = NewSettingsCard("VISUAL", 420)
	visualCard.LayoutOrder = 4
	MakeCycleRow(visualCard, "Theme", 36, {"Cyber Blue", "Neon Cyan", "Purple Anime", "Crimson", "Emerald", "Ice"},
		function() return CONFIG.Theme end,
		function(v)
			CONFIG.Theme = v
			ApplyTheme()
		end)
	MakeStepperRow(visualCard, "Glow Intensity", 88, 0, 1, 0.1,
		function() return CONFIG.GlowIntensity end,
		function(v) CONFIG.GlowIntensity = v end,
		function(v) return string.format("%.1f", v) end)
	MakeStepperRow(visualCard, "Particle Density", 140, 0, 30, 2,
		function() return CONFIG.ParticleDensity end,
		function(v) CONFIG.ParticleDensity = v end,
		function(v) return tostring(v) end)
	MakeToggleRow(visualCard, "HUD Decoration", 192, function() return CONFIG.HUDDecoration end, function(v)
		CONFIG.HUDDecoration = v
	end)
	MakeToggleRow(visualCard, "Background Grid", 244, function() return CONFIG.BackgroundGrid end, function(v)
		CONFIG.BackgroundGrid = v
	end)

	local windowCard = NewSettingsCard("WINDOW", 240)
	windowCard.LayoutOrder = 5
	MakeToggleRow(windowCard, "Remember Position", 36, function() return CONFIG.RememberPosition end, function(v)
		CONFIG.RememberPosition = v
	end)
	local centerBtn = MakeButton(windowCard, "Center Window", UDim2.new(1, -24, 0, 40), UDim2.new(0, 12, 0, 92), function()
		ApplyWindowLayout(true)
	end)
	MakeCorner(centerBtn, 10)
	local resetPosBtn = MakeButton(windowCard, "Reset Position", UDim2.new(1, -24, 0, 40), UDim2.new(0, 12, 0, 140), function()
		STATE.MainPosition = nil
		STATE.MiniPosition = nil
		ApplyWindowLayout(true)
	end)
	MakeCorner(resetPosBtn, 10)
	local resetSettingsBtn = MakeButton(windowCard, "Reset Settings", UDim2.new(1, -24, 0, 40), UDim2.new(0, 12, 0, 188), function()
		_G.vanz.ResetSettings()
	end)
	MakeCorner(resetSettingsBtn, 10)

	local perfCard = NewSettingsCard("PERFORMANCE", 220)
	perfCard.LayoutOrder = 6
	MakeToggleRow(perfCard, "Low FX Mode", 36, function() return CONFIG.LowFXMode end, function(v)
		CONFIG.LowFXMode = v
	end)
	MakeToggleRow(perfCard, "FPS Friendly Mode", 88, function() return CONFIG.FPSFriendly end, function(v)
		CONFIG.FPSFriendly = v
	end)
	MakeToggleRow(perfCard, "Disable Particles", 140, function() return CONFIG.DisableParticles end, function(v)
		CONFIG.DisableParticles = v
	end)
	MakeToggleRow(perfCard, "Disable Heavy Animation", 192, function() return CONFIG.DisableHeavyAnimation end, function(v)
		CONFIG.DisableHeavyAnimation = v
	end)
end

function ApplyTheme()
	local t = GetTheme()
	MainWindow.BackgroundColor3 = t.Base
	MainStroke.Color = t.Accent
	MainGradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, t.Base),
		ColorSequenceKeypoint.new(1, t.Base2),
	})
	AccentLine.BackgroundColor3 = t.Accent2
	HeaderLogoRing.BackgroundColor3 = t.Accent
	HeaderLogoCore.BackgroundColor3 = t.Accent2
	MiniBody.BackgroundColor3 = t.Base2
	MiniCore.BackgroundColor3 = t.Accent2
	HomeScroll.ScrollBarImageColor3 = t.Accent
	SettingsScroll.ScrollBarImageColor3 = t.Accent2
end

--==================================================
-- [29] HOME CARDS: EXTRA DECORATION (HUD)
--==================================================
local HudLayer = MakeFrame(MainWindow, UDim2.new(1, 0, 1, 0), UDim2.new(0, 0, 0, 0), COLORS.Card, 1)
HudLayer.ZIndex = 1

local function MakeBracket(pos, isLeft, isTop)
	local bx = isLeft and 0 or 1
	local by = isTop and 0 or 1
	local h = MakeFrame(HudLayer, UDim2.new(0, 14, 0, 2), UDim2.new(bx, isLeft and 6 or -20, by, isTop and 6 or -8), GetTheme().Accent, 0.3)
	local v = MakeFrame(HudLayer, UDim2.new(0, 2, 0, 14), UDim2.new(bx, isLeft and 6 or -8, by, isTop and 6 or -20), GetTheme().Accent, 0.3)
	return h, v
end
MakeBracket(nil, true, true)
MakeBracket(nil, false, true)
MakeBracket(nil, true, false)
MakeBracket(nil, false, false)

local ScanLine = MakeFrame(HudLayer, UDim2.new(1, 0, 0, 1), UDim2.new(0, 0, 0, 0), GetTheme().Accent2, 0.75)

local MicroText = MakeLabel(HudLayer, "VANZ CORE • SYSTEM ONLINE", UDim2.new(0, 200, 0, 12), UDim2.new(0, 12, 1, -16), FONT_TEXT, 10, COLORS.SubText)
MicroText.TextTransparency = 0.25

--==================================================
-- [30] ANIMATION ENGINE
--==================================================
local AnimTime = 0
local function AnimationTick(dt)
	if not CONFIG.AnimationEnabled or CONFIG.LowFXMode or CONFIG.DisableHeavyAnimation then
		return
	end
	AnimTime = AnimTime + dt * CONFIG.AnimationSpeed

	if CONFIG.LogoAnimation and STATE.Open and not STATE.Minimized then
		local pulse = 0.9 + 0.1 * math.sin(AnimTime * 2.4)
		HeaderLogoRing.Size = UDim2.new(pulse, 0, pulse, 0)
		HeaderLogoRing.Position = UDim2.new((1 - pulse) / 2, 0, (1 - pulse) / 2, 0)
	end

	if CONFIG.Scanline and CONFIG.HUDDecoration and STATE.Open then
		local span = MainWindow.AbsoluteSize.Y
		if span > 0 then
			local y = (AnimTime * 60) % span
			ScanLine.Position = UDim2.new(0, 0, 0, y)
		end
	end

	if CONFIG.RadarAnimation and STATE.Minimized then
		local ang = AnimTime * 90
		MiniScan.Rotation = ang
		MiniRing.Rotation = -ang * 0.5
	end

	if STATE.Minimized then
		local br = 0.9 + 0.1 * math.sin(AnimTime * 3)
		MiniCore.Size = UDim2.new(0, 18 * br, 0, 18 * br)
		MiniCore.Position = UDim2.new(0.5, -9 * br, 0.5, -9 * br)
	end
end

--==================================================
-- [31] PARTICLE ENGINE
--==================================================
local ParticleContainer = MakeFrame(MainWindow, UDim2.new(1, 0, 1, 0), UDim2.new(0, 0, 0, 0), COLORS.Card, 1)
ParticleContainer.ZIndex = 0
ParticleContainer.ClipsDescendants = true

local ParticleCount = 0
local MAX_PARTICLES = 40

local function SpawnParticle()
	if CONFIG.DisableParticles or CONFIG.LowFXMode or not CONFIG.ParticleAnimation then return end
	if ParticleCount >= MAX_PARTICLES then return end
	if not STATE.Open or STATE.Minimized then return end
	local w = ParticleContainer.AbsoluteSize.X
	local h = ParticleContainer.AbsoluteSize.Y
	if w <= 0 or h <= 0 then return end

	ParticleCount = ParticleCount + 1
	local size = math.random(2, 4)
	local p = MakeFrame(ParticleContainer, UDim2.new(0, size, 0, size), UDim2.new(0, math.random(0, w), 0, math.random(0, h)), GetTheme().Accent2, 0.7)
	MakeCorner(p, size)

	local dx = math.random(-30, 30)
	local dy = math.random(-40, -10)
	local dur = math.random(25, 45) / 10 / CONFIG.AnimationSpeed
	local tw = TweenService:Create(p, TweenInfo.new(dur, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
		Position = UDim2.new(0, math.clamp(p.Position.X.Offset + dx, 0, w), 0, math.clamp(p.Position.Y.Offset + dy, 0, h)),
		BackgroundTransparency = 1,
	})
	TrackTween(tw)
	tw:Play()
	task.delay(dur, function()
		ParticleCount = math.max(0, ParticleCount - 1)
		if p and p.Parent then
			p:Destroy()
		end
	end)
end

local ParticleAcc = 0

--==================================================
-- [32] DATA UPDATE: CHARACTER / HUMANOID HELPERS
--==================================================
local function GetCharacter()
	return LocalPlayer.Character
end

local function GetHumanoid()
	local c = GetCharacter()
	if c then
		return c:FindFirstChildOfClass("Humanoid")
	end
	return nil
end

local function GetRootPart()
	local c = GetCharacter()
	if c then
		return c:FindFirstChild("HumanoidRootPart")
	end
	return nil
end

--==================================================
-- [33] DATA UPDATE: FAST UPDATE
--==================================================
local function UpdateCharacterCard(h, root)
	local c = GetCharacter()
	if h then
		CharLines["WalkSpeed"].Text = "WalkSpeed: " .. ToStr(h.WalkSpeed)
		CharLines["JumpPower"].Text = "JumpPower: " .. ToStr(h.JumpPower)
		CharLines["Health"].Text = "Health: " .. ToStr(h.Health, 1)
		CharLines["MaxHealth"].Text = "MaxHealth: " .. ToStr(h.MaxHealth, 1)
		local pct = 0
		if h.MaxHealth and h.MaxHealth > 0 then
			pct = (h.Health / h.MaxHealth) * 100
		end
		CharLines["Health %"].Text = "Health %: " .. string.format("%.1f%%", pct)
		CharLines["HipHeight"].Text = "HipHeight: " .. ToStr(h.HipHeight, 2)
		CharLines["AutoRotate"].Text = "AutoRotate: " .. tostring(h.AutoRotate)
		CharLines["PlatformStand"].Text = "PlatformStand: " .. tostring(h.PlatformStand)
		CharLines["RigType"].Text = "RigType: " .. tostring(h.RigType and h.RigType.Name or "N/A")
		CharLines["Character State"].Text = "Character State: " .. tostring(h:GetState().Name)
	else
		for _, key in ipairs({"WalkSpeed","JumpPower","Health","MaxHealth","Health %","HipHeight","AutoRotate","PlatformStand","RigType","Character State"}) do
			CharLines[key].Text = key .. ": N/A"
		end
	end

	if c then
		MoveLines["Character Name"].Text = "Character Name: " .. c.Name
	else
		MoveLines["Character Name"].Text = "Character Name: N/A"
	end

	if root then
		local vel = root.AssemblyLinearVelocity
		local mag = vel.Magnitude
		MoveLines["Velocity"].Text = string.format("Velocity: %.1f", mag)
		PosLines["Pos X"].Text = string.format("Pos X: %.2f", root.Position.X)
		PosLines["Pos Y"].Text = string.format("Pos Y: %.2f", root.Position.Y)
		PosLines["Pos Z"].Text = string.format("Pos Z: %.2f", root.Position.Z)
		PosLines["Vel X"].Text = string.format("Vel X: %.2f", vel.X)
		PosLines["Vel Y"].Text = string.format("Vel Y: %.2f", vel.Y)
		PosLines["Vel Z"].Text = string.format("Vel Z: %.2f", vel.Z)
		PosLines["Magnitude"].Text = string.format("Magnitude: %.2f", mag)
		local look = root.CFrame.LookVector
		PosLines["Facing"].Text = string.format("Facing: %.2f, %.2f, %.2f", look.X, look.Y, look.Z)
	else
		for _, key in ipairs({"Pos X","Pos Y","Pos Z","Vel X","Vel Y","Vel Z","Magnitude","Facing"}) do
			PosLines[key].Text = key .. ": N/A"
		end
		MoveLines["Velocity"].Text = "Velocity: N/A"
	end

	if h then
		MoveLines["MoveDirection"].Text = "MoveDirection: " .. string.format("%.2f, %.2f, %.2f", h.MoveDirection.X, h.MoveDirection.Y, h.MoveDirection.Z)
		MoveLines["Grounded"].Text = "Grounded: " .. tostring(h.FloorMaterial ~= Enum.Material.Air)
		MoveLines["Floor Material"].Text = "Floor Material: " .. tostring(h.FloorMaterial and h.FloorMaterial.Name or "N/A")
		MoveLines["Seat Status"].Text = "Seat Status: " .. tostring(h.SeatPart and "Seated" or "Not Seated")
		MoveLines["Humanoid State"].Text = "Humanoid State: " .. tostring(h:GetState().Name)
	else
		MoveLines["MoveDirection"].Text = "MoveDirection: N/A"
		MoveLines["Grounded"].Text = "Grounded: N/A"
		MoveLines["Floor Material"].Text = "Floor Material: N/A"
		MoveLines["Seat Status"].Text = "Seat Status: N/A"
		MoveLines["Humanoid State"].Text = "Humanoid State: N/A"
	end
end

local function UpdateHealthCard(h)
	if not h or not h.MaxHealth or h.MaxHealth <= 0 then
		HealthText.Text = "N/A"
		HealthFill.Size = UDim2.new(0, 0, 1, 0)
		return
	end
	local pct = math.clamp(h.Health / h.MaxHealth, 0, 1)
	HealthFill.Size = UDim2.new(pct, 0, 1, 0)
	HealthText.Text = string.format("%d / %d", math.floor(h.Health + 0.5), math.floor(h.MaxHealth + 0.5))
	if pct > 0.6 then
		HealthFill.BackgroundColor3 = COLORS.Good
	elseif pct > 0.3 then
		HealthFill.BackgroundColor3 = COLORS.Warn
	else
		HealthFill.BackgroundColor3 = COLORS.Bad
	end
end

local function UpdateSessionCard()
	local fps = math.floor(STATE.LastFPS + 0.5)
	SessionLines["FPS"].Text = "FPS: " .. tostring(fps)

	local pingOk, pingText = pcall(function()
		local ping = Stats.Network.ServerStatsItem["Data Ping"]:GetValue()
		return string.format("%d ms", math.floor(ping + 0.5))
	end)
	SessionLines["Ping"].Text = "Ping: " .. (pingOk and pingText or "N/A")

	local uptime = os.clock() - STATE.SessionStart
	SessionLines["Uptime"].Text = "Uptime: " .. string.format("%02d:%02d", math.floor(uptime / 60), math.floor(uptime % 60))

	local memOk, memText = pcall(function()
		local mem = Stats:GetTotalMemoryUsageMb()
		return string.format("%.1f MB", mem)
	end)
	SessionLines["Memory"].Text = "Memory: " .. (memOk and memText or "N/A")

	SessionLines["Heartbeat"].Text = string.format("Heartbeat: %.1f ms", (STATE.LastFrameDt or 0) * 1000)
	SessionLines["Client State"].Text = "Client State: " .. (STATE.Open and (STATE.Minimized and "Minimized" or "Open") or "Closed")
	SessionLines["System"].Text = "System: " .. (STATE.DeviceText or "N/A")
end

local function UpdatePlayerInfo()
	local c = GetCharacter()
	local h = GetHumanoid()

	local function setInfo(key, text)
		if InfoLines[key] then
			InfoLines[key].Text = key .. ": " .. (text or "N/A")
		end
	end

	setInfo("Display Name", LocalPlayer.DisplayName)
	setInfo("Username", LocalPlayer.Name)
	setInfo("UserId", ToStr(LocalPlayer.UserId))
	setInfo("Account Age", ToStr(LocalPlayer.AccountAge) .. " hari")
	setInfo("Team", LocalPlayer.Team and LocalPlayer.Team.Name or "N/A")
	setInfo("Team Color", LocalPlayer.TeamColor and tostring(LocalPlayer.TeamColor) or "N/A")
	setInfo("Character", c and c.Name or "N/A")
	setInfo("Rig Type", (h and h.RigType and h.RigType.Name) or "N/A")
	setInfo("Device", STATE.DeviceText or "N/A")

	pcall(function()
		setInfo("Camera Mode", tostring(LocalPlayer.CameraMode and LocalPlayer.CameraMode.Name or "N/A"))
	end)

	pcall(function()
		setInfo("Field Of View", string.format("%.1f", Camera.FieldOfView))
	end)

	pcall(function()
		setInfo("Graphics Quality", tostring(settings().Rendering.QualityLevel))
	end)

	local uptime = os.clock() - STATE.SessionStart
	setInfo("Session Time", string.format("%02d:%02d", math.floor(uptime / 60), math.floor(uptime % 60)))

	pcall(function()
		setInfo("Server JobId", game.JobId ~= "" and game.JobId or "N/A")
	end)
	pcall(function()
		setInfo("PlaceId", tostring(game.PlaceId))
	end)
	pcall(function()
		setInfo("GameId", tostring(game.GameId))
	end)
end

--==================================================
-- [34] DATA UPDATE: SLOW UPDATE
--==================================================
local function UpdateSlowData()
	pcall(function()
		local mt = LocalPlayer.MembershipType
		local mtText = "N/A"
		if mt == Enum.MembershipType.Premium then
			mtText = "Premium"
		elseif mt == Enum.MembershipType.None then
			mtText = "None"
		end
		ProfileMembership.Text = "Membership: " .. mtText
	end)

	pcall(function()
		ProfileTeam.Text = "Team: " .. (LocalPlayer.Team and LocalPlayer.Team.Name or "N/A")
	end)
end

--==================================================
-- [35] EVENT BASED UPDATE
--==================================================
local HumanoidConnections = {}

local function DisconnectHumanoidEvents()
	for _, c in ipairs(HumanoidConnections) do
		pcall(function() c:Disconnect() end)
	end
	table.clear(HumanoidConnections)
end

local function BindCharacter(char)
	DisconnectHumanoidEvents()
	if not char then return end

	local h = char:WaitForChild("Humanoid", 5)
	if h then
		table.insert(HumanoidConnections, h.Died:Connect(function()
			UpdateHealthCard(nil)
		end))
		table.insert(HumanoidConnections, h.StateChanged:Connect(function() end))
	end
end

TrackConnection(LocalPlayer.CharacterAdded:Connect(function(char)
	task.defer(function()
		BindCharacter(char)
	end)
end))

TrackConnection(LocalPlayer:GetPropertyChangedSignal("Team"):Connect(function()
	UpdateSlowData()
end))

--==================================================
-- [36] MAIN UPDATE LOOP
--==================================================
TrackConnection(RunService.Heartbeat:Connect(function(dt)
	if STATE.Destroyed then return end
	STATE.LastFrameDt = dt

	STATE.FrameCount = STATE.FrameCount + 1
	STATE.FrameTimer = STATE.FrameTimer + dt
	if STATE.FrameTimer >= 1 then
		STATE.LastFPS = STATE.FrameCount / STATE.FrameTimer
		STATE.FrameCount = 0
		STATE.FrameTimer = 0
	end

	AnimationTick(dt)

	ParticleAcc = ParticleAcc + dt
	if ParticleAcc >= 0.5 and not CONFIG.LowFXMode and not CONFIG.FPSFriendly then
		ParticleAcc = 0
		local density = math.clamp(CONFIG.ParticleDensity, 0, 30)
		local spawnCount = math.floor(density / 10)
		for _ = 1, spawnCount do
			SpawnParticle()
		end
	end

	STATE.FastTimer = STATE.FastTimer + dt
	if STATE.FastTimer >= CONFIG.FastUpdateRate then
		STATE.FastTimer = 0
		if STATE.Open and not STATE.Minimized and not STATE.SettingsOpen and not STATE.CombatOpen then
			local h = GetHumanoid()
			local root = GetRootPart()
			pcall(UpdateCharacterCard, h, root)
			pcall(UpdateHealthCard, h)
			pcall(UpdatePlayerInfo)
			pcall(UpdateSessionCard)
		end
	end

	STATE.SlowTimer = STATE.SlowTimer + dt
	if STATE.SlowTimer >= CONFIG.HomeUpdateRate * 4 then
		STATE.SlowTimer = 0
		pcall(UpdateSlowData)
	end
end))

--==================================================
-- [37] DRAG BINDINGS
--==================================================
BindDrag(MainWindow, Header, function(wasDrag)
	if wasDrag then
		STATE.MainPosition = ReadMainAbsolute()
	end
end)

BindDrag(MiniLogo, MiniHit, function(wasDrag)
	if wasDrag then
		local p = MiniLogo.AbsolutePosition
		STATE.MiniPosition = Vector2.new(p.X, p.Y)
	else
		RestoreFromLogo()
	end
end)

--==================================================
-- [38] BUTTON ACTIONS
--==================================================
SettingsBtn.MouseButton1Click:Connect(function()
	SetTab(STATE.SettingsOpen and "home" or "settings")
end)

CombatBtn.MouseButton1Click:Connect(function()
	SetTab(STATE.CombatOpen and "home" or "combat")
end)

MinimizeBtn.MouseButton1Click:Connect(function()
	MinimizeToLogo()
end)

CloseBtn.MouseButton1Click:Connect(function()
	DestroyAll()
end)

--==================================================
-- [39] API / GLOBAL
--==================================================
_G.vanz = _G.vanz or {}

_G.vanz.Open = function()
	if STATE.Destroyed then return false end
	ShowMainWindow()
	return true
end

_G.vanz.Hide = function()
	if STATE.Destroyed then return false end
	MainWindow.Visible = false
	MiniLogo.Visible = false
	STATE.Open = false
	return true
end

_G.vanz.Minimize = function()
	if STATE.Destroyed then return false end
	MinimizeToLogo()
	return true
end

_G.vanz.Restore = function()
	if STATE.Destroyed then return false end
	RestoreFromLogo()
	return true
end

_G.vanz.Toggle = function()
	if STATE.Destroyed then return false end
	if STATE.Open then
		_G.vanz.Hide()
	else
		_G.vanz.Open()
	end
	return true
end

_G.vanz.SetScale = function(value)
	if STATE.Destroyed then return false end
	return SetScale(value)
end

_G.vanz.GetScale = function()
	return CONFIG.Scale
end

_G.vanz.GetState = function()
	return {
		Open = STATE.Open,
		Minimized = STATE.Minimized,
		Scale = CONFIG.Scale,
		Theme = CONFIG.Theme,
		Destroyed = STATE.Destroyed,
	}
end

_G.vanz.ResetSettings = function()
	if STATE.Destroyed then return false end
	for k, v in pairs(DEFAULT_CONFIG_SNAPSHOT) do
		CONFIG[k] = v
	end
	ApplyTheme()
	ApplyWindowLayout(true)
	return true
end

_G.vanz.Close = function()
	return DestroyAll()
end

--==================================================
-- [40] DESTROY / CLOSE
--==================================================
DestroyAll = function()
	if STATE.Destroyed then return end
	STATE.Destroyed = true
	STATE.Open = false
	STATE.Minimized = false
	CleanupAll()
	DisconnectHumanoidEvents()
	if _G.vanzCombatCleanup then
		pcall(_G.vanzCombatCleanup)
	end
	if ScreenGui and ScreenGui.Parent then
		ScreenGui:Destroy()
	end
	if _G.vanz then
		_G.vanz.Open = function() return false end
		_G.vanz.Hide = function() return false end
		_G.vanz.Minimize = function() return false end
		_G.vanz.Restore = function() return false end
		_G.vanz.Toggle = function() return false end
		_G.vanz.SetScale = function() return false end
		_G.vanz.ResetSettings = function() return false end
	end
end

--==================================================
-- [41] INIT
--==================================================
local function Init()
	FillProfile()
	BuildSettingsUI()
	ApplyTheme()
	SetTab("home")
	ApplyWindowLayout(true)
	ShowMainWindow()
	STATE.Built = true
end

local okInit, errInit = pcall(Init)
if not okInit then
	warn("[VANZ] Init error:", errInit)
end

TrackConnection(Camera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
	if STATE.Destroyed then return end
	if STATE.Open and not STATE.Minimized then
		ApplyWindowLayout(false)
	elseif STATE.Minimized then
		local p = STATE.MiniPosition
		if p then
			SetMiniAbsolute(p)
		end
	end
end))

TrackConnection(Players.PlayerRemoving:Connect(function(p)
	if p == LocalPlayer then
		DestroyAll()
	end
end))

--==================================================
-- [42] VANZ COMBAT MODULE — 1 GUI, TAB COMBAT
-- Dibungkus pcall(function() ... end) supaya locals-nya
-- TIDAK numpuk ke main chunk (limit 200 locals).
--==================================================
pcall(function()
	local P = Players
	local RS = RunService
	local UIS = UserInputService
	local LG = Lighting
	local WS = workspace
	local LP = LocalPlayer
	if not LP then return end

	local _defer = (task and task.defer) or function(fn) spawn(fn) end
	local _spawn = (task and task.spawn) or function(fn) spawn(fn) end
	local _wait = (task and task.wait) or function(t) wait(t or 0) end

	local RF_EXCLUDE = nil
	pcall(function()
		if Enum.RaycastFilterType then
			RF_EXCLUDE = Enum.RaycastFilterType.Exclude or Enum.RaycastFilterType.Blacklist
		end
	end)

	local HL_DEPTH = nil
	pcall(function()
		if Enum.HighlightDepthMode then
			HL_DEPTH = Enum.HighlightDepthMode.AlwaysOnTop
		end
	end)

	local AC = GetTheme().Accent
	local AC2 = GetTheme().Accent2
	local GD = COLORS.Good
	local BD = COLORS.Bad
	local WHITE = Color3.fromRGB(255, 255, 255)
	local RED = Color3.fromRGB(255, 60, 60)
	local BLUE = Color3.fromRGB(0, 170, 255)
	local TK = COLORS.Track
	local BA = Color3.fromRGB(14, 22, 42)

	local ECFG = {
		ESP = false,
		NoClip = false,
		InfJump = false,
		Speed = false,
		SpeedValue = 50,
		Bright = false,
		BrightValue = 5,
		Desync = false,
	}

	local combatCardOrder = 0

	local function CombatCard(title, height)
		combatCardOrder = combatCardOrder + 1
		local c = MakeCard(CombatScroll, title, UDim2.new(1, -4, 0, height), nil)
		c.LayoutOrder = combatCardOrder
		return c
	end

	local function CombatToggle(card, label, y, getter, setter)
		local row = MakeFrame(card, UDim2.new(1, -24, 0, 44), UDim2.new(0, 12, 0, y), TK, 0.1)
		MakeCorner(row, 10)
		MakeLabel(row, label, UDim2.new(1, -110, 1, 0), UDim2.new(0, 12, 0, 0), FONT_BOLD, 14, COLORS.Text)
		local btn = MakeButton(row, "", UDim2.new(0, 88, 0, 32), UDim2.new(1, -96, 0.5, -16), function()
			local new = not getter()
			local ok, err = pcall(setter, new)
			if not ok then warn("[VANZ-COMBAT] toggle err:", err) end
			btn.Text = new and "ON" or "OFF"
			btn.TextColor3 = new and GD or BD
		end)
		btn.Text = getter() and "ON" or "OFF"
		btn.TextColor3 = getter() and GD or BD
		return row
	end

	local function CombatInput(card, label, y, getter, setter)
		local row = MakeFrame(card, UDim2.new(1, -24, 0, 44), UDim2.new(0, 12, 0, y), TK, 0.1)
		MakeCorner(row, 10)
		MakeLabel(row, label, UDim2.new(0.45, 0, 1, 0), UDim2.new(0, 12, 0, 0), FONT_BOLD, 14, COLORS.Text)
		local tb = Create("TextBox", {
			Size = UDim2.new(0.5, 0, 0, 32),
			Position = UDim2.new(0.48, 0, 0.5, -16),
			BackgroundColor3 = BA,
			BorderSizePixel = 0,
			Font = FONT_BOLD,
			TextSize = 14,
			TextColor3 = AC2,
			Text = tostring(getter()),
			PlaceholderText = "0",
			ClearTextOnFocus = false,
			Parent = row,
		})
		MakeCorner(tb, 8)
		MakeStroke(tb, AC, 1, 0.4)
		local writing = false
		tb:GetPropertyChangedSignal("Text"):Connect(function()
			if writing then return end
			local filtered = string.gsub(tb.Text, "[^%d%.]", "")
			if filtered ~= tb.Text then
				writing = true
				tb.Text = filtered
				writing = false
			end
			local n = tonumber(filtered)
			if n then
				pcall(setter, n)
			end
		end)
		return row
	end

	local function CombatStepper(card, label, y, minV, maxV, step, getter, setter, fmt)
		local row = MakeFrame(card, UDim2.new(1, -24, 0, 44), UDim2.new(0, 12, 0, y), TK, 0.1)
		MakeCorner(row, 10)
		MakeLabel(row, label, UDim2.new(0.4, 0, 1, 0), UDim2.new(0, 12, 0, 0), FONT_BOLD, 14, COLORS.Text)
		local valL = MakeLabel(row, "", UDim2.new(0, 70, 0, 22), UDim2.new(1, -150, 0.5, -11), FONT_BOLD, 14, AC2, Enum.TextXAlignment.Center)
		local function refresh()
			local v = getter()
			valL.Text = fmt and fmt(v) or tostring(v)
		end
		refresh()
		MakeButton(row, "-", UDim2.new(0, 40, 0, 32), UDim2.new(1, -116, 0.5, -16), function()
			local v = math.max(minV, getter() - step)
			pcall(setter, v)
			refresh()
		end)
		MakeButton(row, "+", UDim2.new(0, 40, 0, 32), UDim2.new(1, -52, 0.5, -16), function()
			local v = math.min(maxV, getter() + step)
			pcall(setter, v)
			refresh()
		end)
		return row
	end

	local espHL = {}
	local espBB = {}
	local espTR = {}
	local DRAWING = nil

	pcall(function()
		if Drawing and Drawing.new then
			local test = Drawing.new("Line")
			if test then
				DRAWING = Drawing
				pcall(function() test:Remove() end)
			end
		end
	end)

	local function GetChar(pl)
		if not pl then return nil end
		return pl.Character
	end

	local function GetHRP(pl)
		local c = GetChar(pl)
		if not c then return nil end
		return c:FindFirstChild("HumanoidRootPart") or c.PrimaryPart
	end

	local function RelationColor(pl)
		if not pl then return WHITE end
		local mt = LP.Team
		local tt = pl.Team
		if mt == nil or tt == nil then return WHITE end
		if mt == tt then return BLUE end
		return RED
	end

	local function CleanupESP()
		for _, hl in pairs(espHL) do
			pcall(function() if hl and hl.Parent then hl:Destroy() end end)
		end
		espHL = {}
		for _, e in pairs(espBB) do
			pcall(function() if e and e.Gui and e.Gui.Parent then e.Gui:Destroy() end end)
		end
		espBB = {}
		for _, t in pairs(espTR) do
			pcall(function()
				if t and t.Obj then t.Obj:Remove() end
			end)
		end
		espTR = {}
	end

	local function MakeHL(pl)
		pcall(function()
			local c = GetChar(pl)
			if not c then return end
			local old = c:FindFirstChild("VANZ_ESP_HL")
			if old then old:Destroy() end
			local hl = Instance.new("Highlight")
			hl.Name = "VANZ_ESP_HL"
			hl.Adornee = c
			hl.FillTransparency = 0.55
			hl.OutlineTransparency = 0
			if HL_DEPTH then
				pcall(function() hl.DepthMode = HL_DEPTH end)
			end
			hl.Parent = c
			espHL[pl] = hl
		end)
	end

	local function UpdateHLColor(pl)
		local hl = espHL[pl]
		if not hl then return end
		local color = RelationColor(pl)
		pcall(function()
			hl.FillColor = color
			hl.OutlineColor = color
		end)
	end

	local function MakeBB(pl)
		pcall(function()
			local c = GetChar(pl)
			if not c then return end
			local head = c:FindFirstChild("Head") or c:FindFirstChild("HumanoidRootPart")
			if not head then return end
			local old = head:FindFirstChild("VANZ_ESP_BB")
			if old then old:Destroy() end
			local bb = Instance.new("BillboardGui")
			bb.Name = "VANZ_ESP_BB"
			bb.Size = UDim2.new(0, 200, 0, 54)
			bb.StudsOffset = Vector3.new(0, 3.2, 0)
			bb.AlwaysOnTop = true
			bb.LightInfluence = 0
			bb.MaxDistance = math.huge
			bb.Parent = head
			local col = RelationColor(pl)
			local nameL = MakeLabel(bb, pl.DisplayName .. " (@" .. pl.Name .. ")", UDim2.new(1, 0, 0, 18), UDim2.new(0, 0, 0, 0), FONT_BOLD, 13, col)
			local hpL = MakeLabel(bb, "HP: 100/100", UDim2.new(1, 0, 0, 16), UDim2.new(0, 0, 0, 18), FONT_TEXT, 12, col)
			local dsL = MakeLabel(bb, "0m", UDim2.new(1, 0, 0, 16), UDim2.new(0, 0, 0, 34), FONT_TEXT, 12, col)
			espBB[pl] = {Gui = bb, Name = nameL, HP = hpL, Dist = dsL}
		end)
	end

	local function MakeTR(pl)
		if not DRAWING then return end
		local ok, line = pcall(function()
			local l = DRAWING.new("Line")
			l.Thickness = 1.6
			l.Transparency = 0.85
			l.Visible = false
			l.From = Vector2.new(0, 0)
			l.To = Vector2.new(0, 0)
			return l
		end)
		if ok and line then
			espTR[pl] = {Type = "drawing", Obj = line}
		end
	end

	local function ESPUpdate()
		if not ECFG.ESP then return end
		local cam = WS.CurrentCamera
		if not cam then return end
		local localHRP = GetHRP(LP)
		for _, pl in ipairs(P:GetPlayers()) do
			if pl ~= LP then
				local c = GetChar(pl)
				if not c then
					if espHL[pl] then pcall(function() espHL[pl]:Destroy() end); espHL[pl] = nil end
					if espBB[pl] and espBB[pl].Gui then pcall(function() espBB[pl].Gui:Destroy() end); espBB[pl] = nil end
					if espTR[pl] and espTR[pl].Obj then pcall(function() espTR[pl].Obj:Remove() end); espTR[pl] = nil end
				else
					if not espHL[pl] or espHL[pl].Adornee ~= c then
						MakeHL(pl)
					end
					UpdateHLColor(pl)

					if not espBB[pl] then
						MakeBB(pl)
					end
					if not espTR[pl] then
						MakeTR(pl)
					end

					local hum = c:FindFirstChildOfClass("Humanoid")
					local hrp = GetHRP(pl)
					local entry = espBB[pl]
					if entry and hum and hrp then
						local relCol = RelationColor(pl)
						pcall(function()
							entry.Name.TextColor3 = relCol
							entry.Name.Text = pl.DisplayName .. " (@" .. pl.Name .. ")"
							entry.HP.Text = string.format("HP: %d/%d", math.floor(hum.Health + 0.5), math.floor(hum.MaxHealth + 0.5))
							entry.HP.TextColor3 = relCol
							local dist = 0
							if localHRP then
								dist = (hrp.Position - localHRP.Position).Magnitude
							end
							entry.Dist.Text = string.format("%dm", math.floor(dist + 0.5))
							entry.Dist.TextColor3 = relCol
						end)
					end

					local tr = espTR[pl]
					if tr and tr.Obj then
						if hrp then
							local ok, sp = pcall(function() return cam:WorldToViewportPoint(hrp.Position) end)
							if ok and sp then
								pcall(function()
									tr.Obj.From = Vector2.new(cam.ViewportSize.X / 2, cam.ViewportSize.Y)
									tr.Obj.To = Vector2.new(sp.X, sp.Y)
									tr.Obj.Color = RelationColor(pl)
									tr.Obj.Visible = true
								end)
							else
								pcall(function() tr.Obj.Visible = false end)
							end
						else
							pcall(function() tr.Obj.Visible = false end)
						end
					end
				end
			end
		end
	end

	local lastGroundY = nil
	local rayParams = nil

	local function InitRayParams()
		if rayParams then return end
		rayParams = RaycastParams.new()
		if RF_EXCLUDE then
			pcall(function() rayParams.FilterType = RF_EXCLUDE end)
		end
	end

	local function RestoreNoclip()
		local c = LP.Character
		if not c then return end
		for _, part in ipairs(c:GetDescendants()) do
			if part:IsA("BasePart") then
				pcall(function() part.CanCollide = true end)
			end
		end
	end

	local function NoclipUpdate()
		if not ECFG.NoClip then return end
		local c = LP.Character
		if not c then return end
		local hrp = c:FindFirstChild("HumanoidRootPart")
		if not hrp then return end

		InitRayParams()
		if rayParams then
			rayParams.FilterDescendantsInstances = {c}
			local ok, result = pcall(function()
				return WS:Raycast(hrp.Position, Vector3.new(0, -500, 0), rayParams)
			end)
			if ok and result and result.Position then
				local part = result.Instance
				local mat = result.Material
				local isClimbable = false
				if part then
					local nm = string.lower(part.Name)
					if string.find(nm, "ladder") or string.find(nm, "truss") or string.find(nm, "stair") or string.find(nm, "platform") then
						isClimbable = true
					end
				end
				if mat == Enum.Material.Ladder then isClimbable = true end
				if not isClimbable then
					lastGroundY = result.Position.Y
				end
			end
		end

		for _, part in ipairs(c:GetDescendants()) do
			if part:IsA("BasePart") then
				pcall(function()
					if part.CanCollide then part.CanCollide = false end
				end)
			end
		end

		if lastGroundY and hrp.Position.Y < lastGroundY - 5 then
			pcall(function()
				hrp.CFrame = CFrame.new(hrp.Position.X, lastGroundY + 3, hrp.Position.Z)
				local v = hrp.AssemblyLinearVelocity
				hrp.AssemblyLinearVelocity = Vector3.new(v.X, 0, v.Z)
			end)
		end
	end

	local jumpConn = nil
	local jumpBtnInjected = false

	local function InjectJumpButton()
		if jumpBtnInjected then return end
		if PlayerGui:FindFirstChild("VANZ_JUMP_BTN") then jumpBtnInjected = true; return end
		local jb = Create("TextButton", {
			Name = "VANZ_JUMP_BTN",
			Size = UDim2.new(0, 70, 0, 70),
			Position = UDim2.new(1, -90, 1, -170),
			BackgroundColor3 = GetTheme().Base2,
			BackgroundTransparency = 0.25,
			Text = "JUMP",
			Font = FONT_BOLD,
			TextSize = 15,
			TextColor3 = COLORS.Text,
			BorderSizePixel = 0,
			Parent = PlayerGui,
		})
		MakeCorner(jb, 35)
		MakeStroke(jb, GetTheme().Accent, 2, 0.3)
		jb.MouseButton1Click:Connect(function()
			local c = LP.Character
			if c then
				local h = c:FindFirstChildOfClass("Humanoid")
				if h then
					pcall(function() h:ChangeState(Enum.HumanoidStateType.Jumping) end)
				end
			end
		end)
		jumpBtnInjected = true
	end

	local function StartInfJump()
		InjectJumpButton()
		if jumpConn then return end
		jumpConn = UIS.JumpRequest:Connect(function()
			if not ECFG.InfJump then return end
			local c = LP.Character
			if not c then return end
			local h = c:FindFirstChildOfClass("Humanoid")
			if h then
				pcall(function() h:ChangeState(Enum.HumanoidStateType.Jumping) end)
			end
		end)
	end

	local function StopInfJump()
		if jumpConn then
			pcall(function() jumpConn:Disconnect() end)
			jumpConn = nil
		end
	end

	local function SpeedUpdate()
		if not ECFG.Speed then return end
		local c = LP.Character
		if not c then return end
		local h = c:FindFirstChildOfClass("Humanoid")
		if h then
			local target = ECFG.SpeedValue or 50
			if target < 0 then target = 0 end
			if h.WalkSpeed ~= target then
				pcall(function() h.WalkSpeed = target end)
			end
		end
	end

	local brightConn = nil

	local function ApplyBrightness()
		if not ECFG.Bright then return end
		local lvl = ECFG.BrightValue or 5
		pcall(function() LG.Brightness = 2 + lvl * 3 end)
		pcall(function() LG.ClockTime = 14 end)
		pcall(function() LG.Ambient = Color3.fromRGB(255, 255, 255) end)
		pcall(function() LG.OutdoorAmbient = Color3.fromRGB(255, 255, 255) end)
		pcall(function() LG.GlobalShadows = false end)
		pcall(function() LG.FogEnd = 1e9 end)
		pcall(function() LG.FogStart = 1e9 end)
		pcall(function() LG.FogColor = Color3.fromRGB(255, 255, 255) end)
		pcall(function() LG.EnvironmentDiffuseScale = 1 end)
		pcall(function() LG.EnvironmentSpecularScale = 1 end)
		pcall(function() LG.ShadowSoftness = 0 end)
		pcall(function() LG.ExposureCompensation = lvl * 0.15 end)
		pcall(function()
			local atmo = LG:FindFirstChildOfClass("Atmosphere")
			if atmo then
				atmo.Density = 0
				atmo.Haze = 0
				atmo.Glare = 0
			end
		end)
		pcall(function()
			local cc = LG:FindFirstChild("VANZ_BRIGHT_CC")
			if not cc then
				cc = Instance.new("ColorCorrectionEffect")
				cc.Name = "VANZ_BRIGHT_CC"
				cc.Parent = LG
			end
			cc.Brightness = 0.2 + lvl * 0.1
			cc.Contrast = 0
			cc.Saturation = 0.15
			cc.TintColor = Color3.fromRGB(255, 255, 255)
		end)
	end

	local function StartBrightness()
		if brightConn then return end
		ApplyBrightness()
		brightConn = RS.Heartbeat:Connect(function()
			if not ECFG.Bright then return end
			ApplyBrightness()
		end)
	end

	local function StopBrightness()
		if brightConn then
			pcall(function() brightConn:Disconnect() end)
			brightConn = nil
		end
		pcall(function()
			local cc = LG:FindFirstChild("VANZ_BRIGHT_CC")
			if cc then cc:Destroy() end
		end)
	end

	local desyncModel = nil

	local function StartDesync()
		local c = LP.Character
		if not c then return end
		local hrp = c:FindFirstChild("HumanoidRootPart")
		if not hrp then return end
		if desyncModel and desyncModel.Parent then
			pcall(function() desyncModel:Destroy() end)
		end
		local origin = hrp.CFrame
		local m = Instance.new("Model")
		m.Name = "VANZ_DESYNC"
		local blk = Instance.new("Part")
		blk.Name = "DesyncBlock"
		blk.Anchored = true
		blk.CanCollide = false
		blk.Material = Enum.Material.Neon
		blk.Color = Color3.fromRGB(255, 255, 255)
		blk.Transparency = 0.4
		blk.Size = Vector3.new(2, 5, 1)
		blk.CFrame = origin
		blk.Parent = m
		m.PrimaryPart = blk
		m.Parent = WS
		desyncModel = m
	end

	local function StopDesync()
		if desyncModel then
			pcall(function() desyncModel:Destroy() end)
			desyncModel = nil
		end
	end

	local function TeleportTo(pl)
		if not pl then return end
		local myChar = LP.Character
		if not myChar then return end
		local myHRP = myChar:FindFirstChild("HumanoidRootPart")
		if not myHRP then return end
		local tChar = pl.Character
		if not tChar then return end
		local tHRP = tChar:FindFirstChild("HumanoidRootPart")
		if not tHRP then return end
		pcall(function()
			myHRP.CFrame = tHRP.CFrame * CFrame.new(0, 0, 3)
			myHRP.AssemblyLinearVelocity = Vector3.zero
		end)
	end

	pcall(function()
		if type(hookfunction) == "function" and LP.Kick then
			hookfunction(LP.Kick, function() return nil end)
		end
	end)

	local function HijackNetOwner()
		local c = LP.Character
		if not c then return end
		local hrp = c:FindFirstChild("HumanoidRootPart")
		if not hrp then return end
		pcall(function()
			if hrp.CanSetNetworkOwnership and hrp:CanSetNetworkOwnership() then
				hrp:SetNetworkOwner(nil)
			end
		end)
	end

	local hbConn = RS.Heartbeat:Connect(function(_)
		pcall(ESPUpdate)
		pcall(NoclipUpdate)
		pcall(SpeedUpdate)
	end)

	local stepConn = RS.Stepped:Connect(function(_, _)
		if ECFG.NoClip then
			local c = LP.Character
			if c then
				for _, part in ipairs(c:GetDescendants()) do
					if part:IsA("BasePart") then
						pcall(function()
							if part.CanCollide then part.CanCollide = false end
						end)
					end
				end
			end
		end
		if ECFG.Speed then
			local c = LP.Character
			if c then
				local h = c:FindFirstChildOfClass("Humanoid")
				if h then
					local target = ECFG.SpeedValue or 50
					if h.WalkSpeed ~= target then
						pcall(function() h.WalkSpeed = target end)
					end
				end
			end
		end
	end)

	local MainCard = CombatCard("MAIN CONTROLS", 320)
	CombatToggle(MainCard, "ESP (Wallhack + Tracer)", 36, function() return ECFG.ESP end, function(v)
		ECFG.ESP = v
		if not v then CleanupESP() end
	end)
	CombatToggle(MainCard, "No-Clip + Anti-Void", 88, function() return ECFG.NoClip end, function(v)
		ECFG.NoClip = v
		if not v then RestoreNoclip() end
	end)
	CombatToggle(MainCard, "Infinite Jump", 140, function() return ECFG.InfJump end, function(v)
		ECFG.InfJump = v
		if v then StartInfJump() else StopInfJump() end
	end)
	CombatToggle(MainCard, "Speedhack", 192, function() return ECFG.Speed end, function(v)
		ECFG.Speed = v
	end)
	CombatToggle(MainCard, "Brightness (MAX)", 244, function() return ECFG.Bright end, function(v)
		ECFG.Bright = v
		if v then StartBrightness() else StopBrightness() end
	end)
	CombatToggle(MainCard, "Desync", 296, function() return ECFG.Desync end, function(v)
		ECFG.Desync = v
		if v then StartDesync() else StopDesync() end
	end)

	local SpeedCard = CombatCard("SPEEDHACK VALUE (LIVE)", 82)
	CombatInput(SpeedCard, "Speed", 36, function() return ECFG.SpeedValue end, function(v)
		ECFG.SpeedValue = v
	end)

	local BrightCard = CombatCard("BRIGHTNESS LEVEL", 82)
	CombatStepper(BrightCard, "Level", 36, 0, 10, 1, function() return ECFG.BrightValue end, function(v)
		ECFG.BrightValue = v
	end, function(v) return string.format("%d", v) end)

	local TPCard = CombatCard("TELEPORT LIST (LIVE)", 320)
	local TPScroll = Create("ScrollingFrame", {
		Size = UDim2.new(1, -24, 0, 240),
		Position = UDim2.new(0, 12, 0, 36),
		BackgroundColor3 = BA,
		BackgroundTransparency = 0.3,
		BorderSizePixel = 0,
		ScrollBarThickness = 4,
		ScrollBarImageColor3 = AC2,
		CanvasSize = UDim2.new(0, 0, 0, 0),
		AutomaticCanvasSize = Enum.AutomaticSize.None,
		ScrollingDirection = Enum.ScrollingDirection.Y,
		ElasticBehavior = Enum.ElasticBehavior.Never,
		Parent = TPCard,
	})
	MakeCorner(TPScroll, 8)
	MakeStroke(TPScroll, AC, 1, 0.7)

	local TPList = Create("UIListLayout", {
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, 3),
		Parent = TPScroll,
	})
	Create("UIPadding", {
		PaddingLeft = UDim.new(0, 4),
		PaddingRight = UDim.new(0, 4),
		PaddingTop = UDim.new(0, 4),
		PaddingBottom = UDim.new(0, 4),
		Parent = TPScroll,
	})

	TPList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		TPScroll.CanvasSize = UDim2.new(0, 0, 0, TPList.AbsoluteContentSize.Y + 10)
	end)

	local tpRows = {}

	local function AddTPRow(pl)
		if tpRows[pl] then return end
		if pl == LP then return end
		local row = Create("TextButton", {
			Text = "",
			Size = UDim2.new(1, -4, 0, 28),
			BackgroundColor3 = TK,
			BackgroundTransparency = 0.4,
			BorderSizePixel = 0,
			AutoButtonColor = false,
			Parent = TPScroll,
		})
		MakeCorner(row, 6)
		local lbl = MakeLabel(row, pl.DisplayName .. " @" .. pl.Name, UDim2.new(1, -60, 1, 0), UDim2.new(0, 6, 0, 0), FONT_TEXT, 12, RelationColor(pl))
		lbl.TextXAlignment = Enum.TextXAlignment.Left
		local tpBtn = MakeButton(row, "TP", UDim2.new(0, 44, 0, 22), UDim2.new(1, -50, 0.5, -11), function()
			TeleportTo(pl)
		end)
		tpBtn.TextSize = 12
		tpRows[pl] = {Row = row, NameLabel = lbl, Button = tpBtn}
	end

	local function RemoveTPRow(pl)
		local e = tpRows[pl]
		if e and e.Row then
			pcall(function() e.Row:Destroy() end)
		end
		tpRows[pl] = nil
	end

	local function RebuildTPList()
		for p, _ in pairs(tpRows) do
			if not p.Parent then
				RemoveTPRow(p)
			end
		end
		for _, pl in ipairs(P:GetPlayers()) do
			if pl ~= LP then
				AddTPRow(pl)
			end
		end
	end

	P.PlayerAdded:Connect(function(pl)
		_defer(function() pcall(AddTPRow, pl) end)
	end)
	P.PlayerRemoving:Connect(function(pl)
		RemoveTPRow(pl)
	end)

	_defer(RebuildTPList)

	_spawn(function()
		while not STATE.Destroyed and CombatScroll and CombatScroll.Parent do
			_wait(2)
			for pl, e in pairs(tpRows) do
				if e and e.NameLabel and pl.Parent then
					pcall(function()
						e.NameLabel.Text = pl.DisplayName .. " @" .. pl.Name
						e.NameLabel.TextColor3 = RelationColor(pl)
					end)
				end
			end
		end
	end)

	LP.CharacterAdded:Connect(function(_)
		_wait(0.5)
		pcall(function()
			if ECFG.ESP then CleanupESP() end
			if ECFG.InfJump then StartInfJump() end
			if ECFG.Bright then StartBrightness() end
			HijackNetOwner()
		end)
	end)

	_defer(HijackNetOwner)

	_G.vanzCombatCleanup = function()
		pcall(function() if hbConn then hbConn:Disconnect() end end)
		pcall(function() if stepConn then stepConn:Disconnect() end end)
		pcall(function() CleanupESP() end)
		pcall(function() StopInfJump() end)
		pcall(function() StopBrightness() end)
		pcall(function() StopDesync() end)
		pcall(function()
			local jb = PlayerGui:FindFirstChild("VANZ_JUMP_BTN")
			if jb then jb:Destroy() end
		end)
		pcall(function()
			for _, pl in pairs(P:GetPlayers()) do
				local c = pl.Character
				if c then
					local hl = c:FindFirstChild("VANZ_ESP_HL")
					if hl then hl:Destroy() end
					local head = c:FindFirstChild("Head")
					if head then
						local bb = head:FindFirstChild("VANZ_ESP_BB")
						if bb then bb:Destroy() end
					end
				end
			end
		end)
	end

	_G.exploit = _G.exploit or {}
	_G.exploit.Config = ECFG
	_G.exploit.ToggleESP = function(v)
		ECFG.ESP = (v ~= false)
		if not ECFG.ESP then CleanupESP() end
	end
	_G.exploit.ToggleNoclip = function(v)
		ECFG.NoClip = (v ~= false)
		if not ECFG.NoClip then RestoreNoclip() end
	end
	_G.exploit.ToggleInfJump = function(v)
		ECFG.InfJump = (v ~= false)
		if ECFG.InfJump then StartInfJump() else StopInfJump() end
	end
	_G.exploit.SetSpeed = function(n)
		ECFG.SpeedValue = tonumber(n) or 50
	end
	_G.exploit.SetBrightness = function(n)
		ECFG.BrightValue = tonumber(n) or 5
	end
	_G.exploit.Teleport = TeleportTo
	_G.exploit.CleanupESP = CleanupESP

	warn("[VANZ-COMBAT] Loaded. Tab COMBAT siap. API: _G.exploit")
end)