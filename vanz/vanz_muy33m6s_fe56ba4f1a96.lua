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
-- Pengaturan default GUI. Semua nilai bisa diubah lewat Settings.
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
-- Menyimpan status runtime GUI (posisi, mode, cache).
--==================================================
local STATE = {
	Built = false,
	Open = false,
	Minimized = false,
	Destroyed = false,
	SettingsOpen = false,
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
-- Membersihkan connections, tweens, dan loops saat GUI ditutup.
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
-- Warna dan style dasar GUI, dipakai semua komponen.
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
-- Fungsi pembuat Frame, TextLabel, Button, Card.
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
-- ScreenGui utama tempat semua GUI dibangun.
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
-- Mengambil ukuran viewport dan kalkulasi ukuran window responsif.
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
-- Frame utama. Ukuran dihitung langsung dari AbsoluteSize / offset (bukan UIScale).
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
-- Header dengan logo, title, dan CONTROL ZONE (Settings/Minimize/Close).
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

local TitleArea = MakeFrame(Header, UDim2.new(1, -(12 + 36 + 12 + 156), 1, 0), UDim2.new(0, 12 + 36 + 10, 0, 0), COLORS.Card, 1)
local TitleLabel = MakeLabel(TitleArea, "VANZ ULTRA CONTROL CENTER", UDim2.new(1, 0, 0, 22), UDim2.new(0, 0, 0, 8), FONT_TITLE, 15, COLORS.Text)
local SubtitleLabel = MakeLabel(TitleArea, "SYSTEM ONLINE", UDim2.new(1, 0, 0, 16), UDim2.new(0, 0, 0, 28), FONT_TEXT, 11, COLORS.SubText)

local CONTROL_ZONE_WIDTH = 156
local ControlZone = MakeFrame(Header, UDim2.new(0, CONTROL_ZONE_WIDTH, 1, 0), UDim2.new(1, -CONTROL_ZONE_WIDTH - 8, 0, 0), COLORS.Card, 1)

local BTN_SIZE = 44
local BTN_GAP = 6
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
end

SettingsBtn = MakeButton(ControlZone, "⚙", UDim2.new(0, BTN_SIZE, 0, BTN_SIZE), UDim2.new(0, 0, 0, 0), function()
end)
MinimizeBtn = MakeButton(ControlZone, "—", UDim2.new(0, BTN_SIZE, 0, BTN_SIZE), UDim2.new(0, 0, 0, 0), function()
end)
CloseBtn = MakeButton(ControlZone, "X", UDim2.new(0, BTN_SIZE, 0, BTN_SIZE), UDim2.new(0, 0, 0, 0), function()
end)

TrackConnection(ControlZone:GetPropertyChangedSignal("AbsoluteSize"):Connect(LayoutControls))
task.defer(LayoutControls)

--==================================================
-- [11] BODY CONTAINER
-- Area konten di bawah header. Diisi oleh Home dan Settings.
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
-- [25] SETTINGS PANEL: DRAWER
--==================================================
local SettingsDrawer = nil

local function SetSettingsVisible(v)
	STATE.SettingsOpen = v
	SettingsScroll.Visible = v
	HomeScroll.Visible = not v
	if v then
		SettingsBtn.Text = "⌂"
	else
		SettingsBtn.Text = "⚙"
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
		if STATE.Open and not STATE.Minimized and not STATE.SettingsOpen then
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
	SetSettingsVisible(not STATE.SettingsOpen)
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
-- [41] AUTO PARRY MODULE
-- Modul auto-parry: kartu Home + Settings, engine, dan API.
--==================================================
local AUTOPARRY = {
	Enabled = false,
	Range = 12,
	Cooldown = 0.12,
	Method = "Activate",
	RequireUIBall = false,
	LastFire = 0,
	Fired = 0,
	Success = 0,
	LastSuccess = 0,
	LastBallName = nil,
	LastDistance = nil,
	UIRefreshAcc = 0,
	UIRefreshRate = 0.1,
}

local AutoParryLines = {}

local function GetBlockButton()
	local pg = LocalPlayer:FindFirstChild("PlayerGui")
	if not pg then return nil end
	local hotbar = pg:FindFirstChild("Hotbar")
	if not hotbar then return nil end
	local block = hotbar:FindFirstChild("Block")
	if block and block:IsA("ImageButton") then return block end
	local newBlock = hotbar:FindFirstChild("NewBlockButton")
	if newBlock and newBlock:IsA("ImageButton") then return newBlock end
	return nil
end

local function IsUIBallVisible()
	local pg = LocalPlayer:FindFirstChild("PlayerGui")
	if not pg then return false end
	local ball = pg:FindFirstChild("Ball")
	if ball and ball:IsA("GuiObject") then
		return ball.Visible
	end
	return false
end

local function IsBallPart(obj)
	if not obj:IsA("BasePart") then return false end
	local n = string.lower(obj.Name)
	return string.find(n, "ball", 1, true) ~= nil
end

local function FindNearestBall(origin)
	local best, bestD = nil, AUTOPARRY.Range + 1
	local list = workspace:GetDescendants()
	for i = 1, #list do
		local v = list[i]
		if IsBallPart(v) then
			local ok, pos = pcall(function() return v.Position end)
			if ok and pos then
				local d = (pos - origin).Magnitude
				if d < bestD then
					best = v
					bestD = d
				end
			end
		end
	end
	return best, bestD
end

local function FireParry(btn)
	if not btn then return end
	local method = AUTOPARRY.Method
	if method == "Activate" then
		pcall(function() btn:Activate() end)
	elseif method == "firesignal" then
		if type(firesignal) == "function" then
			pcall(function() firesignal(btn.Activated) end)
			pcall(function() firesignal(btn.MouseButton1Click) end)
		end
	elseif method == "click" then
		if type(firesignal) == "function" then
			pcall(function() firesignal(btn.MouseButton1Click) end)
		end
	end
end

local AutoParryCard = MakeCard(HomeScroll, "AUTO PARRY", UDim2.new(1, -4, 0, 200), nil)
AutoParryCard.LayoutOrder = 8

local function AddAutoParryLine(key, yIndex)
	local lbl = MakeLabel(AutoParryCard, key .. ": N/A", UDim2.new(1, -24, 0, 18), UDim2.new(0, 12, 0, 36 + (yIndex - 1) * 20), FONT_TEXT, 14, COLORS.Text)
	AutoParryLines[key] = lbl
	return lbl
end

AddAutoParryLine("Status", 1)
AddAutoParryLine("Range", 2)
AddAutoParryLine("Cooldown", 3)
AddAutoParryLine("Method", 4)
AddAutoParryLine("Target Ball", 5)
AddAutoParryLine("Distance", 6)
AddAutoParryLine("Fired", 7)
AddAutoParryLine("Success", 8)

local function RefreshAutoParryCard()
	if AutoParryLines["Status"] then
		AutoParryLines["Status"].Text = "Status: " .. (AUTOPARRY.Enabled and "ON" or "OFF")
	end
	if AutoParryLines["Range"] then
		AutoParryLines["Range"].Text = string.format("Range: %.1f stud", AUTOPARRY.Range)
	end
	if AutoParryLines["Cooldown"] then
		AutoParryLines["Cooldown"].Text = string.format("Cooldown: %.2fs", AUTOPARRY.Cooldown)
	end
	if AutoParryLines["Method"] then
		AutoParryLines["Method"].Text = "Method: " .. tostring(AUTOPARRY.Method)
	end
	if AutoParryLines["Target Ball"] then
		AutoParryLines["Target Ball"].Text = "Target Ball: " .. (AUTOPARRY.LastBallName or "N/A")
	end
	if AutoParryLines["Distance"] then
		AutoParryLines["Distance"].Text = "Distance: " .. (AUTOPARRY.LastDistance and string.format("%.2f", AUTOPARRY.LastDistance) or "N/A")
	end
	if AutoParryLines["Fired"] then
		AutoParryLines["Fired"].Text = "Fired: " .. tostring(AUTOPARRY.Fired)
	end
	if AutoParryLines["Success"] then
		AutoParryLines["Success"].Text = "Success: " .. tostring(AUTOPARRY.Success)
	end
end

local parrySettingsCard = NewSettingsCard("AUTO PARRY", 500)
parrySettingsCard.LayoutOrder = 7

MakeToggleRow(parrySettingsCard, "Enable Auto Parry", 36,
	function() return AUTOPARRY.Enabled end,
	function(v)
		AUTOPARRY.Enabled = v
		AUTOPARRY.LastFire = 0
	end)

MakeStepperRow(parrySettingsCard, "Range (stud)", 88, 1, 50, 1,
	function() return AUTOPARRY.Range end,
	function(v) AUTOPARRY.Range = v end,
	function(v) return string.format("%d", math.floor(v + 0.5)) end)

MakeStepperRow(parrySettingsCard, "Cooldown (s)", 140, 0.03, 1.0, 0.01,
	function() return AUTOPARRY.Cooldown end,
	function(v) AUTOPARRY.Cooldown = v end,
	function(v) return string.format("%.2f", v) end)

MakeCycleRow(parrySettingsCard, "Trigger Method", 192,
	{"Activate", "firesignal", "click"},
	function() return AUTOPARRY.Method end,
	function(v) AUTOPARRY.Method = v end,
	function(v) return tostring(v) end)

MakeToggleRow(parrySettingsCard, "Require UI Ball Visible", 244,
	function() return AUTOPARRY.RequireUIBall end,
	function(v) AUTOPARRY.RequireUIBall = v end)

local autoParryTestBtn = MakeButton(parrySettingsCard, "Test Fire Once", UDim2.new(1, -24, 0, 40), UDim2.new(0, 12, 0, 296), function()
	local btn = GetBlockButton()
	if btn then
		FireParry(btn)
	end
end)
MakeCorner(autoParryTestBtn, 10)

local autoParryResetBtn = MakeButton(parrySettingsCard, "Reset Counters", UDim2.new(1, -24, 0, 40), UDim2.new(0, 12, 0, 344), function()
	AUTOPARRY.Fired = 0
	AUTOPARRY.Success = 0
	AUTOPARRY.LastSuccess = 0
end)
MakeCorner(autoParryResetBtn, 10)

local autoParryDiagBtn = MakeButton(parrySettingsCard, "Probe Block Button", UDim2.new(1, -24, 0, 40), UDim2.new(0, 12, 0, 392), function()
	local btn = GetBlockButton()
	if not btn then
		warn("[AUTO PARRY] Block button tidak ditemukan.")
		return
	end
	print("[AUTO PARRY] Block button:", btn:GetFullName())
	for _, sig in ipairs({"Activated","MouseButton1Click","MouseButton1Down","MouseButton1Up"}) do
		if btn[sig] then
			TrackConnection(btn[sig]:Connect(function(...)
				print("[AUTO PARRY] signal fired:", sig, ...)
			end))
		end
	end
	print("[AUTO PARRY] Probe aktif. Klik Block manual sekali untuk melihat signal mana yang fire.")
end)
MakeCorner(autoParryDiagBtn, 10)

pcall(function()
	local RS = game:GetService("ReplicatedStorage")
	local remotes = RS:FindFirstChild("Remotes")
	if not remotes then return end
	local ps = remotes:FindFirstChild("ParrySuccess")
	if ps and ps:IsA("RemoteEvent") then
		TrackConnection(ps.OnClientEvent:Connect(function()
			AUTOPARRY.Success = AUTOPARRY.Success + 1
			AUTOPARRY.LastSuccess = os.clock()
		end))
	end
end)

TrackConnection(RunService.Heartbeat:Connect(function(dt)
	if STATE.Destroyed then return end

	AUTOPARRY.UIRefreshAcc = AUTOPARRY.UIRefreshAcc + dt
	if AUTOPARRY.UIRefreshAcc >= AUTOPARRY.UIRefreshRate then
		AUTOPARRY.UIRefreshAcc = 0
		if STATE.Open and not STATE.Minimized and not STATE.SettingsOpen then
			pcall(RefreshAutoParryCard)
		end
	end

	if not AUTOPARRY.Enabled then return end

	local now = os.clock()
	if now - AUTOPARRY.LastFire < AUTOPARRY.Cooldown then return end

	local char = LocalPlayer.Character
	if not char then return end
	local hrp = char:FindFirstChild("HumanoidRootPart")
	if not hrp then return end
	local humanoid = char:FindFirstChildOfClass("Humanoid")
	if humanoid and humanoid.Health <= 0 then return end

	if AUTOPARRY.RequireUIBall then
		if not IsUIBallVisible() then return end
	end

	local ball, dist = FindNearestBall(hrp.Position)
	AUTOPARRY.LastBallName = ball and ball.Name or nil
	AUTOPARRY.LastDistance = dist
	if not ball or dist > AUTOPARRY.Range then return end

	local btn = GetBlockButton()
	if not btn then return end

	AUTOPARRY.LastFire = now
	AUTOPARRY.Fired = AUTOPARRY.Fired + 1
	FireParry(btn)
end))

if _G.vanz then
	_G.vanz.AutoParry = {
		Enable = function()
			AUTOPARRY.Enabled = true
			return true
		end,
		Disable = function()
			AUTOPARRY.Enabled = false
			return true
		end,
		Toggle = function()
			AUTOPARRY.Enabled = not AUTOPARRY.Enabled
			return AUTOPARRY.Enabled
		end,
		SetRange = function(v)
			if type(v) == "number" and v > 0 then
				AUTOPARRY.Range = v
				return true
			end
			return false
		end,
		SetCooldown = function(v)
			if type(v) == "number" and v > 0 then
				AUTOPARRY.Cooldown = v
				return true
			end
			return false
		end,
		SetMethod = function(m)
			if m == "Activate" or m == "firesignal" or m == "click" then
				AUTOPARRY.Method = m
				return true
			end
			return false
		end,
		Stats = function()
			return {
				Enabled = AUTOPARRY.Enabled,
				Fired = AUTOPARRY.Fired,
				Success = AUTOPARRY.Success,
				Range = AUTOPARRY.Range,
				Cooldown = AUTOPARRY.Cooldown,
				Method = AUTOPARRY.Method,
				LastBallName = AUTOPARRY.LastBallName,
				LastDistance = AUTOPARRY.LastDistance,
			}
		end,
		Reset = function()
			AUTOPARRY.Fired = 0
			AUTOPARRY.Success = 0
			AUTOPARRY.LastSuccess = 0
		end,
		TestFire = function()
			local btn = GetBlockButton()
			if btn then
				FireParry(btn)
				return true
			end
			return false
		end,
	}
end

pcall(RefreshAutoParryCard)

--==================================================
-- [42] INIT
--==================================================
local function Init()
	FillProfile()
	BuildSettingsUI()
	ApplyTheme()
	SetSettingsVisible(false)
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