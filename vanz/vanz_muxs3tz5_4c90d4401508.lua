--==================================================
-- [01] SERVICES
--==================================================
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Stats = game:GetService("Stats")
local CoreGuiService = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

--==================================================
-- [02] CONFIG
--==================================================
local CONFIG = {
	Scale = 0.50,
	ScaleOptions = {0.40, 0.50, 0.60, 0.70, 0.80, 0.90, 1.00},
	WindowOpacity = 0.12, CornerRadius = 14, BorderIntensity = 0.6, GlassIntensity = 0.5,
	AnimationEnabled = true, SoftAnimation = true, LogoAnimation = true, RadarAnimation = true,
	ParticleAnimation = true, Scanline = true, HoverAnimation = true, ClickAnimation = true,
	TransitionAnimation = true, AnimationSpeed = 1, Theme = "Cyber Blue", GlowIntensity = 0.5,
	ParticleDensity = 10, HUDDecoration = true, BackgroundGrid = true, RememberPosition = true,
	LowFXMode = false, FPSFriendly = false, DisableParticles = false, DisableHeavyAnimation = false,
	DragThreshold = 8, HomeUpdateRate = 0.25, FastUpdateRate = 0.1,

	EggHomeX = 504.4, EggHomeY = 70.6, EggHomeZ = -365.6,
	EggMinIncome = 0, EggAutoRefresh = 3,
	EggWalkSpeed = 1000, EggWalkTimeout = 30,
	EggReachDistance = 12,
	EggPrecisionDist = 4,
	EggPrecisionSpeed = 25,
	EggRampUp = 1.5,
	EggHPSafePct = 55,
	EggAlignMaxForce = 1e8,
	EggSpoofMaxStep = 20,
	EggSpoofInterval = 0.030,
	EggSettleTime = 0.35,
	EggMinDeliveryTime = 1.6,
	EggRetry = 1,
}

local THEMES = {
	["Cyber Blue"] = { Accent = Color3.fromRGB(0,170,255), Accent2 = Color3.fromRGB(0,255,230), Base = Color3.fromRGB(14,22,42), Base2 = Color3.fromRGB(22,36,66) },
	["Neon Cyan"] = { Accent = Color3.fromRGB(0,255,255), Accent2 = Color3.fromRGB(80,255,200), Base = Color3.fromRGB(12,26,36), Base2 = Color3.fromRGB(20,42,56) },
	["Purple Anime"] = { Accent = Color3.fromRGB(190,110,255), Accent2 = Color3.fromRGB(255,120,220), Base = Color3.fromRGB(28,18,46), Base2 = Color3.fromRGB(44,28,70) },
	["Crimson"] = { Accent = Color3.fromRGB(255,70,90), Accent2 = Color3.fromRGB(255,160,80), Base = Color3.fromRGB(34,16,22), Base2 = Color3.fromRGB(52,24,34) },
	["Emerald"] = { Accent = Color3.fromRGB(70,255,150), Accent2 = Color3.fromRGB(160,255,90), Base = Color3.fromRGB(14,32,26), Base2 = Color3.fromRGB(22,50,40) },
	["Ice"] = { Accent = Color3.fromRGB(170,230,255), Accent2 = Color3.fromRGB(230,250,255), Base = Color3.fromRGB(26,40,56), Base2 = Color3.fromRGB(38,58,80) },
}

local DEFAULT_CONFIG_SNAPSHOT = {}
for k, v in pairs(CONFIG) do DEFAULT_CONFIG_SNAPSHOT[k] = v end

--==================================================
-- [03] STATE
--==================================================
local STATE = {
	Built = false, Open = false, Minimized = false, Destroyed = false,
	SettingsOpen = false, MainPosition = nil, MiniPosition = nil,
	SessionStart = os.clock(), DeviceText = "N/A",
	LastFPS = 0, FrameCount = 0, FrameTimer = 0, FastTimer = 0, SlowTimer = 0,
	EggBusy = false, EggScanning = false, EggList = {}, EggRowPool = {},
	EggAutoTimer = 0, EggIncomeIndex = nil,
	EggStatus = "Ready.",
	SnapshotSignature = nil, SnapshotLastError = nil,
	SpeedConns = {},
	Deaths = 0, Aborts = 0,
	Hooked = false, TargetWalkSpeed = 16, SpeedLockActive = false,
	AlignPos = nil, AlignAtt = nil,
	AntiCheatKilled = false,
	IndexHooked = false, SelfRead = false,
	LastFakePos = nil, LastFakeUpdate = 0,
	RigWipeBlocked = 0, HealthBlocked = 0, PosBlocked = 0, SpeedBlocked = 0,
	TextBlocked = 0,
	HardStopped = false,
	NotifScrubRunning = false,
}

local ApplyWindowLayout

--==================================================
-- [04] CLEANUP
--==================================================
local Connections, ActiveTweens = {}, {}
local function TrackConnection(c) if c then table.insert(Connections, c) end return c end
local function TrackTween(t) if t then table.insert(ActiveTweens, t) end return t end
local function CleanupAll()
	for _, c in ipairs(Connections) do pcall(function() c:Disconnect() end) end
	table.clear(Connections)
	for _, t in ipairs(ActiveTweens) do pcall(function() t:Cancel() end) end
	table.clear(ActiveTweens)
end

--==================================================
-- [05] THEME
--==================================================
local function GetTheme() return THEMES[CONFIG.Theme] or THEMES["Cyber Blue"] end
local COLORS = {
	Text = Color3.fromRGB(235,245,255), SubText = Color3.fromRGB(150,185,215),
	Good = Color3.fromRGB(90,255,170), Warn = Color3.fromRGB(255,200,90),
	Bad = Color3.fromRGB(255,90,110), Card = Color3.fromRGB(18,30,54),
	Track = Color3.fromRGB(30,46,74),
}
local FONT_TITLE, FONT_BOLD, FONT_TEXT = Enum.Font.GothamBlack, Enum.Font.GothamBold, Enum.Font.Gotham

--==================================================
-- [06] UI FACTORY
--==================================================
local function Create(c, p, ch)
	local o = Instance.new(c)
	for k, v in pairs(p or {}) do o[k] = v end
	for _, x in ipairs(ch or {}) do x.Parent = o end
	return o
end
local function MakeCorner(p, r) return Create("UICorner", { CornerRadius = UDim.new(0, r or 10), Parent = p }) end
local function MakeStroke(p, c, t, tr)
	return Create("UIStroke", { Color = c or GetTheme().Accent, Thickness = t or 1, Transparency = tr or 0.4, ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Parent = p })
end
local function MakeGradient(p, c1, c2, rot)
	return Create("UIGradient", { Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, c1), ColorSequenceKeypoint.new(1, c2) }), Rotation = rot or 90, Parent = p })
end
local function MakeFrame(p, s, pos, c, tr)
	return Create("Frame", { Size = s or UDim2.new(1,0,1,0), Position = pos or UDim2.new(0,0,0,0), BackgroundColor3 = c or COLORS.Card, BackgroundTransparency = tr or 0, BorderSizePixel = 0, Parent = p })
end
local function MakeLabel(p, t, s, pos, f, ts, c, xa)
	return Create("TextLabel", { Text = t or "", Size = s or UDim2.new(1,0,0,20), Position = pos or UDim2.new(0,0,0,0), BackgroundTransparency = 1, Font = f or FONT_TEXT, TextSize = ts or 14, TextColor3 = c or COLORS.Text, TextXAlignment = xa or Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Center, Parent = p })
end
local function MakeButton(p, t, s, pos, cb)
	local b = Create("TextButton", { Text = t or "", Size = s or UDim2.new(0,48,0,48), Position = pos or UDim2.new(0,0,0,0), BackgroundColor3 = GetTheme().Base2, BackgroundTransparency = 0.1, BorderSizePixel = 0, AutoButtonColor = false, Font = FONT_BOLD, TextSize = 18, TextColor3 = COLORS.Text, Parent = p })
	MakeCorner(b, 10)
	MakeStroke(b, GetTheme().Accent, 1, 0.5)
	local base, hov = GetTheme().Base2, GetTheme().Accent
	TrackConnection(b.MouseEnter:Connect(function()
		if not CONFIG.HoverAnimation or CONFIG.LowFXMode then return end
		TrackTween(TweenService:Create(b, TweenInfo.new(0.18, Enum.EasingStyle.Quad), { BackgroundColor3 = hov:Lerp(base, 0.6) })):Play()
	end))
	TrackConnection(b.MouseLeave:Connect(function()
		if not CONFIG.HoverAnimation or CONFIG.LowFXMode then return end
		TrackTween(TweenService:Create(b, TweenInfo.new(0.18, Enum.EasingStyle.Quad), { BackgroundColor3 = base })):Play()
	end))
	TrackConnection(b.MouseButton1Click:Connect(function()
		if CONFIG.ClickAnimation and not CONFIG.LowFXMode then
			TrackTween(TweenService:Create(b, TweenInfo.new(0.08), { BackgroundTransparency = 0 })):Play()
		end
		if cb then pcall(cb) end
	end))
	return b
end
local function MakeCard(p, t, s, pos)
	local c = MakeFrame(p, s, pos, COLORS.Card, 0.05)
	MakeCorner(c, 12)
	MakeStroke(c, GetTheme().Accent, 1, 0.65)
	MakeLabel(c, t or "", UDim2.new(1,-20,0,22), UDim2.new(0,12,0,8), FONT_BOLD, 16, GetTheme().Accent2)
	return c
end
local function MakeTextBox(p, ph, s, pos, onEnter, init)
	local tb = Create("TextBox", { Text = init or "", PlaceholderText = ph or "", Size = s or UDim2.new(0,132,0,32), Position = pos or UDim2.new(0,0,0,0), BackgroundColor3 = GetTheme().Base2, BackgroundTransparency = 0.05, BorderSizePixel = 0, Font = FONT_BOLD, TextSize = 14, TextColor3 = COLORS.Text, PlaceholderColor3 = COLORS.SubText, TextXAlignment = Enum.TextXAlignment.Center, ClearTextOnFocus = false, Parent = p })
	MakeCorner(tb, 10)
	MakeStroke(tb, GetTheme().Accent, 1, 0.5)
	local lastValid = init
	TrackConnection(tb:GetPropertyChangedSignal("Text"):Connect(function()
		local n = tonumber(tb.Text)
		if n and n > 0 then
			lastValid = tb.Text
			if onEnter then pcall(onEnter, tb.Text, false) end
		end
	end))
	TrackConnection(tb.FocusLost:Connect(function()
		local n = tonumber(tb.Text)
		if not n or n <= 0 then tb.Text = lastValid or init or "" end
	end))
	return tb
end
local function ToStr(v, d)
	if v == nil then return "N/A" end
	if type(v) == "number" then
		if d then return string.format("%."..d.."f", v) end
		return tostring(math.floor(v + 0.5))
	end
	return tostring(v)
end

--==================================================
-- [07] SCREENGUI
--==================================================
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local ScreenGui = Create("ScreenGui", { Name = "VANZ_ULTRA_CONTROL", ResetOnSpawn = false, IgnoreGuiInset = true, ZIndexBehavior = Enum.ZIndexBehavior.Global, DisplayOrder = 9999, Enabled = false, Parent = PlayerGui })

--==================================================
-- [08] SCREEN HELPERS
--==================================================
local function GetViewport() return Camera and Camera.ViewportSize or Vector2.new(1280,720) end
local BASE_WIDTH, BASE_HEIGHT, MIN_WIDTH_PX = 760, 520, 300
local function ComputeWindowSize()
	local vp = GetViewport()
	local s = CONFIG.Scale
	local w = math.clamp(BASE_WIDTH * s * 2, MIN_WIDTH_PX, vp.X - 16)
	local h = math.clamp(BASE_HEIGHT * s * 2, 260, vp.Y - 16)
	return Vector2.new(math.floor(w), math.floor(h))
end
local function ComputeCenteredPosition(sz)
	local vp = GetViewport()
	return Vector2.new(math.floor((vp.X - sz.X)/2), math.floor((vp.Y - sz.Y)/2))
end
local function ClampAbsolute(pos, sz)
	local vp = GetViewport()
	return Vector2.new(math.clamp(pos.X, 0, math.max(0, vp.X - sz.X)), math.clamp(pos.Y, 0, math.max(0, vp.Y - sz.Y)))
end

--==================================================
-- [09] MAIN WINDOW
--==================================================
local MainWindow = Create("Frame", { Name = "MainWindow", Size = UDim2.new(0,0,0,0), Position = UDim2.new(0,0,0,0), BackgroundColor3 = GetTheme().Base, BackgroundTransparency = CONFIG.WindowOpacity, BorderSizePixel = 0, ClipsDescendants = true, Visible = false, Parent = ScreenGui })
MakeCorner(MainWindow, CONFIG.CornerRadius)
local MainStroke = MakeStroke(MainWindow, GetTheme().Accent, 1.5, 0.2)
local MainGradient = MakeGradient(MainWindow, GetTheme().Base, GetTheme().Base2, 90)
local InnerBorder = MakeFrame(MainWindow, UDim2.new(1,-8,1,-8), UDim2.new(0,4,0,4), GetTheme().Base, 1)
MakeCorner(InnerBorder, CONFIG.CornerRadius - 2)
MakeStroke(InnerBorder, GetTheme().Accent2, 1, 0.82)
local AccentLine = MakeFrame(MainWindow, UDim2.new(0.3,0,0,2), UDim2.new(0.35,0,0,0), GetTheme().Accent2, 0.1)
MakeGradient(AccentLine, GetTheme().Accent, GetTheme().Accent2, 0)
local HEADER_HEIGHT = 56

--==================================================
-- [10] HEADER
--==================================================
local Header = MakeFrame(MainWindow, UDim2.new(1,0,0,HEADER_HEIGHT), UDim2.new(0,0,0,0), GetTheme().Base2, 0.2)
MakeCorner(Header, CONFIG.CornerRadius)
local HeaderLogo = MakeFrame(Header, UDim2.new(0,36,0,36), UDim2.new(0,12,0.5,-18), GetTheme().Base, 1)
MakeCorner(HeaderLogo, 18)
local HeaderLogoRing = MakeFrame(HeaderLogo, UDim2.new(1,0,1,0), UDim2.new(0,0,0,0), GetTheme().Accent, 1)
MakeCorner(HeaderLogoRing, 18)
MakeStroke(HeaderLogoRing, GetTheme().Accent, 2, 0.1)
local HeaderLogoCore = MakeFrame(HeaderLogo, UDim2.new(0,10,0,10), UDim2.new(0.5,-5,0.5,-5), GetTheme().Accent2, 0)
MakeCorner(HeaderLogoCore, 5)
local TitleArea = MakeFrame(Header, UDim2.new(1,-(12+36+12+156),1,0), UDim2.new(0,12+36+10,0,0), COLORS.Card, 1)
MakeLabel(TitleArea, "VANZ ULTRA CONTROL CENTER", UDim2.new(1,0,0,22), UDim2.new(0,0,0,8), FONT_TITLE, 15, COLORS.Text)
MakeLabel(TitleArea, "SYSTEM ONLINE", UDim2.new(1,0,0,16), UDim2.new(0,0,0,28), FONT_TEXT, 11, COLORS.SubText)
local CONTROL_ZONE_WIDTH, BTN_SIZE, BTN_GAP = 156, 44, 6
local ControlZone = MakeFrame(Header, UDim2.new(0,CONTROL_ZONE_WIDTH,1,0), UDim2.new(1,-CONTROL_ZONE_WIDTH-8,0,0), COLORS.Card, 1)
local SettingsBtn, MinimizeBtn, CloseBtn
local function LayoutControls()
	local zW, zH = ControlZone.AbsoluteSize.X, ControlZone.AbsoluteSize.Y
	local y = math.floor((zH - BTN_SIZE)/2)
	local x = zW - BTN_SIZE
	if CloseBtn then CloseBtn.Position = UDim2.new(0,x,0,y) end
	x = x - BTN_SIZE - BTN_GAP
	if MinimizeBtn then MinimizeBtn.Position = UDim2.new(0,x,0,y) end
	x = x - BTN_SIZE - BTN_GAP
	if SettingsBtn then SettingsBtn.Position = UDim2.new(0,x,0,y) end
end
SettingsBtn = MakeButton(ControlZone, "⚙", UDim2.new(0,BTN_SIZE,0,BTN_SIZE), nil)
MinimizeBtn = MakeButton(ControlZone, "—", UDim2.new(0,BTN_SIZE,0,BTN_SIZE), nil)
CloseBtn = MakeButton(ControlZone, "X", UDim2.new(0,BTN_SIZE,0,BTN_SIZE), nil)
TrackConnection(ControlZone:GetPropertyChangedSignal("AbsoluteSize"):Connect(LayoutControls))
task.defer(LayoutControls)

--==================================================
-- [11] BODY
--==================================================
local Body = MakeFrame(MainWindow, UDim2.new(1,-16,1,-(HEADER_HEIGHT+12)), UDim2.new(0,8,0,HEADER_HEIGHT+4), COLORS.Card, 1)
local HomeScroll = Create("ScrollingFrame", { Size = UDim2.new(1,0,1,0), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 5, ScrollBarImageColor3 = GetTheme().Accent, CanvasSize = UDim2.new(0,0,0,0), ScrollingDirection = Enum.ScrollingDirection.Y, ElasticBehavior = Enum.ElasticBehavior.Never, Parent = Body })
local HomeList = Create("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0,10), Parent = HomeScroll })
Create("UIPadding", { PaddingLeft = UDim.new(0,8), PaddingRight = UDim.new(0,8), PaddingTop = UDim.new(0,6), PaddingBottom = UDim.new(0,12), Parent = HomeScroll })
TrackConnection(HomeList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
	HomeScroll.CanvasSize = UDim2.new(0,0,0, HomeList.AbsoluteContentSize.Y + 24)
end))

local SettingsScroll = Create("ScrollingFrame", { Size = UDim2.new(1,0,1,0), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 5, ScrollBarImageColor3 = GetTheme().Accent2, CanvasSize = UDim2.new(0,0,0,0), ScrollingDirection = Enum.ScrollingDirection.Y, ElasticBehavior = Enum.ElasticBehavior.Never, Visible = false, Parent = Body })
local SettingsList = Create("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0,10), Parent = SettingsScroll })
Create("UIPadding", { PaddingLeft = UDim.new(0,8), PaddingRight = UDim.new(0,8), PaddingTop = UDim.new(0,6), PaddingBottom = UDim.new(0,12), Parent = SettingsScroll })
TrackConnection(SettingsList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
	SettingsScroll.CanvasSize = UDim2.new(0,0,0, SettingsList.AbsoluteContentSize.Y + 24)
end))

--==================================================
-- [12] USER PROFILE
--==================================================
local ProfileCard = MakeCard(HomeScroll, "USER PROFILE", UDim2.new(1,-4,0,150), nil)
ProfileCard.LayoutOrder = 1
local AvatarFrame = MakeFrame(ProfileCard, UDim2.new(0,84,0,84), UDim2.new(0,12,0,36), COLORS.Track, 0)
MakeCorner(AvatarFrame, 42)
MakeStroke(AvatarFrame, GetTheme().Accent, 1.5, 0.3)
local AvatarImage = Create("ImageLabel", { Size = UDim2.new(1,0,1,0), BackgroundTransparency = 1, Image = "", Parent = AvatarFrame })
MakeCorner(AvatarImage, 42)
local ProfileDisplayName = MakeLabel(ProfileCard, "N/A", UDim2.new(1,-120,0,26), UDim2.new(0,110,0,36), FONT_TITLE, 18, COLORS.Text)
local ProfileUsername = MakeLabel(ProfileCard, "@N/A", UDim2.new(1,-120,0,18), UDim2.new(0,110,0,64), FONT_TEXT, 14, COLORS.SubText)
local ProfileUserId = MakeLabel(ProfileCard, "UserId: N/A", UDim2.new(1,-120,0,18), UDim2.new(0,110,0,84), FONT_TEXT, 14, COLORS.SubText)
local ProfileAccountAge = MakeLabel(ProfileCard, "Account Age: N/A", UDim2.new(1,-120,0,18), UDim2.new(0,110,0,104), FONT_TEXT, 14, COLORS.SubText)
local ProfileTeam = MakeLabel(ProfileCard, "Team: N/A", UDim2.new(1,-120,0,18), UDim2.new(0,110,0,124), FONT_TEXT, 14, COLORS.SubText)
local ProfileMembership = MakeLabel(ProfileCard, "Membership: N/A", UDim2.new(0.5,-12,0,18), UDim2.new(0.5,0,0,36), FONT_TEXT, 14, COLORS.SubText)
local ProfileDevice = MakeLabel(ProfileCard, "Device: N/A", UDim2.new(0.5,-12,0,18), UDim2.new(0.5,0,0,56), FONT_TEXT, 14, COLORS.SubText)

local function FillProfile()
	pcall(function()
		ProfileDisplayName.Text = LocalPlayer.DisplayName or "N/A"
		ProfileUsername.Text = "@" .. (LocalPlayer.Name or "N/A")
		ProfileUserId.Text = "UserId: " .. ToStr(LocalPlayer.UserId)
		ProfileAccountAge.Text = "Account Age: " .. ToStr(LocalPlayer.AccountAge) .. " hari"
		ProfileTeam.Text = "Team: " .. (LocalPlayer.Team and LocalPlayer.Team.Name or "N/A")
	end)
	pcall(function()
		local ok, img = pcall(function() return Players:GetUserThumbnailAsync(LocalPlayer.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size150x150) end)
		if ok and img then AvatarImage.Image = img end
	end)
	pcall(function()
		local mt = LocalPlayer.MembershipType
		ProfileMembership.Text = "Membership: " .. (mt == Enum.MembershipType.Premium and "Premium" or mt == Enum.MembershipType.None and "None" or "N/A")
	end)
	pcall(function()
		local dev = "N/A"
		if UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled then dev = "Mobile"
		elseif UserInputService.KeyboardEnabled then dev = "PC"
		elseif UserInputService.GamepadEnabled then dev = "Console" end
		STATE.DeviceText = dev
		ProfileDevice.Text = "Device: " .. dev
	end)
end

--==================================================
-- [13-18] TELEMETRY CARDS
--==================================================
local CharCard = MakeCard(HomeScroll, "CHARACTER STATUS", UDim2.new(1,-4,0,210), nil)
CharCard.LayoutOrder = 2
local CharLines = {}
for i, k in ipairs({"WalkSpeed","JumpPower","Health","MaxHealth","Health %","HipHeight","AutoRotate","PlatformStand","RigType","Character State"}) do
	CharLines[k] = MakeLabel(CharCard, k..": N/A", UDim2.new(1,-24,0,18), UDim2.new(0,12,0,36+(i-1)*20), FONT_TEXT, 14, COLORS.Text)
end

local MoveCard = MakeCard(HomeScroll, "MOVEMENT CORE", UDim2.new(1,-4,0,170), nil)
MoveCard.LayoutOrder = 3
local MoveLines = {}
for i, k in ipairs({"MoveDirection","Velocity","Grounded","Floor Material","Seat Status","Humanoid State","Character Name"}) do
	MoveLines[k] = MakeLabel(MoveCard, k..": N/A", UDim2.new(1,-24,0,18), UDim2.new(0,12,0,36+(i-1)*20), FONT_TEXT, 14, COLORS.Text)
end

local HealthCard = MakeCard(HomeScroll, "HEALTH", UDim2.new(1,-4,0,96), nil)
HealthCard.LayoutOrder = 4
local HealthTrack = MakeFrame(HealthCard, UDim2.new(1,-24,0,22), UDim2.new(0,12,0,40), COLORS.Track, 0)
MakeCorner(HealthTrack, 8)
local HealthFill = MakeFrame(HealthTrack, UDim2.new(1,0,1,0), nil, COLORS.Good, 0)
MakeCorner(HealthFill, 8)
MakeGradient(HealthFill, COLORS.Good, GetTheme().Accent2, 0)
local HealthText = MakeLabel(HealthCard, "100 / 100", UDim2.new(1,-24,0,18), UDim2.new(0,12,0,68), FONT_BOLD, 14, COLORS.Text, Enum.TextXAlignment.Right)

local PosCard = MakeCard(HomeScroll, "POSITION TELEMETRY", UDim2.new(1,-4,0,196), nil)
PosCard.LayoutOrder = 5
local PosLines = {}
for i, k in ipairs({"Pos X","Pos Y","Pos Z","Vel X","Vel Y","Vel Z","Magnitude","Facing"}) do
	PosLines[k] = MakeLabel(PosCard, k..": N/A", UDim2.new(1,-24,0,18), UDim2.new(0,12,0,36+(i-1)*20), FONT_TEXT, 14, COLORS.Text)
end

local InfoCard = MakeCard(HomeScroll, "PLAYER INFORMATION", UDim2.new(1,-4,0,360), nil)
InfoCard.LayoutOrder = 6
local InfoLines = {}
for i, k in ipairs({"Display Name","Username","UserId","Account Age","Team","Team Color","Character","Rig Type","Device","Camera Mode","Field Of View","Graphics Quality","Session Time","Server JobId","PlaceId","GameId"}) do
	InfoLines[k] = MakeLabel(InfoCard, k..": N/A", UDim2.new(1,-24,0,18), UDim2.new(0,12,0,36+(i-1)*20), FONT_TEXT, 14, COLORS.Text)
end

local SessionCard = MakeCard(HomeScroll, "SESSION TELEMETRY", UDim2.new(1,-4,0,180), nil)
SessionCard.LayoutOrder = 7
local SessionLines = {}
for i, k in ipairs({"FPS","Ping","Uptime","Memory","Heartbeat","Client State","System"}) do
	SessionLines[k] = MakeLabel(SessionCard, k..": N/A", UDim2.new(1,-24,0,18), UDim2.new(0,12,0,36+(i-1)*20), FONT_TEXT, 14, COLORS.Text)
end

--==================================================
-- [19] EGG FARM CARD
--==================================================
local EggCard = MakeCard(HomeScroll, "EGG FARM", UDim2.new(1,-4,0,660), nil)
EggCard.LayoutOrder = 8

local ApplyLiveSpeed

local EggHomeLbl = MakeLabel(EggCard, "HOME: N/A", UDim2.new(1,-24,0,16), UDim2.new(0,12,0,30), FONT_TEXT, 12, COLORS.SubText)
local EggSpeedLbl = MakeLabel(EggCard, "SPEED:", UDim2.new(0,60,0,32), UDim2.new(0,12,0,52), FONT_BOLD, 13, COLORS.Text)
local EggSpeedInput = MakeTextBox(EggCard, "1000", UDim2.new(0,90,0,32), UDim2.new(0,70,0,52), function(text)
	local n = tonumber(text)
	if n and n > 0 then
		ApplyLiveSpeed(n)
	else
		EggSpeedInput.Text = tostring(CONFIG.EggWalkSpeed)
	end
end, tostring(CONFIG.EggWalkSpeed))

local EggSetHomeBtn = MakeButton(EggCard, "SET HOME", UDim2.new(0,110,0,32), UDim2.new(0,170,0,52), nil)
local EggScanBtn = MakeButton(EggCard, "SCAN", UDim2.new(0,80,0,32), UDim2.new(0,286,0,52), nil)
local EggCarryAllBtn = MakeButton(EggCard, "CARRY ALL", UDim2.new(0,110,0,32), UDim2.new(0,372,0,52), nil)
local EggStopBtn = MakeButton(EggCard, "STOP", UDim2.new(0,80,0,32), UDim2.new(0,488,0,52), nil)
EggSetHomeBtn.TextSize, EggScanBtn.TextSize, EggCarryAllBtn.TextSize, EggStopBtn.TextSize = 12, 12, 12, 12

local EggSigLbl = MakeLabel(EggCard, "sig: probing…", UDim2.new(1,-24,0,14), UDim2.new(0,12,0,94), FONT_TEXT, 10, COLORS.Warn)
local EggStatusLbl = MakeLabel(EggCard, "Ready.", UDim2.new(1,-24,0,14), UDim2.new(0,12,0,108), FONT_TEXT, 11, COLORS.SubText)
local EggCountLbl = MakeLabel(EggCard, "0 eggs", UDim2.new(0,120,0,14), UDim2.new(1,-132,0,108), FONT_BOLD, 11, GetTheme().Accent2, Enum.TextXAlignment.Right)
local EggStatLbl = MakeLabel(EggCard, "deaths: 0  aborts: 0  align: off", UDim2.new(1,-24,0,14), UDim2.new(0,12,0,124), FONT_TEXT, 11, COLORS.Warn)

local EggListScroll = Create("ScrollingFrame", { Size = UDim2.new(1,-20,0,490), Position = UDim2.new(0,10,0,146), BackgroundColor3 = COLORS.Track, BackgroundTransparency = 0.5, BorderSizePixel = 0, ScrollBarThickness = 4, ScrollBarImageColor3 = GetTheme().Accent, CanvasSize = UDim2.new(0,0,0,0), ScrollingDirection = Enum.ScrollingDirection.Y, ElasticBehavior = Enum.ElasticBehavior.Never, Parent = EggCard })
MakeCorner(EggListScroll, 8)
local EggListLayout = Create("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0,3), Parent = EggListScroll })
Create("UIPadding", { PaddingLeft = UDim.new(0,4), PaddingRight = UDim.new(0,4), PaddingTop = UDim.new(0,4), PaddingBottom = UDim.new(0,4), Parent = EggListScroll })

--==================================================
-- [20] ANTI-CHEAT + NOTIF SCRUB + SPEED BYPASS
--==================================================
local RS = game:GetService("ReplicatedStorage")
local PKGS = RS:FindFirstChild("Packages")
local NET = PKGS and PKGS:FindFirstChild("Networking")
local RigWipeRemote, ProbeSatchelRemote, SlowToggleRemote
if NET then
	RigWipeRemote = NET:FindFirstChild("RE/RigSync/AskRigWipe")
	ProbeSatchelRemote = NET:FindFirstChild("RE/RigSync/ProbeSatchel")
	SlowToggleRemote = NET:FindFirstChild("RF/Treadmill/AskSlowToggle")
end

local AC_KEYWORDS = {"anticheat","anti_cheat","anti-cheat","watchdog","sentinel","detector","guardian","ac_main","ac_core","ac_client","cheat_detect","exploit_detect","security_probe","pos_check","speed_check"}
local KilledScripts = {}

local function IsNotifText(s)
	if type(s) ~= "string" then return false end
	local len = #s
	if len < 6 or len > 300 then return false end
	local low = s:lower()
	local hit = 0
	if low:find("egg", 1, true) then hit = hit + 1 end
	if low:find("return", 1, true) then hit = hit + 1 end
	if low:find("nest", 1, true) then hit = hit + 1 end
	if low:find("fail", 1, true) then hit = hit + 1 end
	if low:find("delivery", 1, true) then hit = hit + 1 end
	if low:find("deliver", 1, true) then hit = hit + 1 end
	if hit >= 2 then return true end
	return false
end

local function HideLabel(label)
	pcall(function() label.Text = "" end)
	pcall(function() label.TextTransparency = 1 end)
	pcall(function() label.Visible = false end)
	local p = label.Parent
	if p and p:IsA("GuiObject") then
		local okSz, sz = pcall(function() return p.AbsoluteSize end)
		if okSz and sz and sz.X > 80 and sz.Y > 20 and sz.X < 900 then
			pcall(function() p.Visible = false end)
		end
	end
end

local function ScrubNotifRoots()
	local roots = { PlayerGui, CoreGuiService }
	for _, root in ipairs(roots) do
		if root then
			local ok, descs = pcall(function() return root:GetDescendants() end)
			if ok and descs then
				for i = 1, #descs do
					local obj = descs[i]
					local cls = obj.ClassName
					if cls == "TextLabel" or cls == "TextButton" or cls == "TextBox" then
						local okTxt, txt = pcall(function() return obj.Text end)
						if okTxt and IsNotifText(txt) then
							HideLabel(obj)
							STATE.TextBlocked = STATE.TextBlocked + 1
						end
					end
				end
			end
		end
	end
end

local function ScanAndDisableAC()
	pcall(function()
		for _, obj in ipairs(game:GetDescendants()) do
			if obj:IsA("BaseScript") then
				local n = obj.Name:lower()
				for _, kw in ipairs(AC_KEYWORDS) do
					if n:find(kw, 1, true) then
						pcall(function() obj.Disabled = true end)
						table.insert(KilledScripts, obj:GetFullName())
						break
					end
				end
			end
		end
	end)
end

local function KillAntiCheatHooks()
	if STATE.AntiCheatKilled then return end
	pcall(function()
		for _, v in ipairs(getconnections(LocalPlayer.Idled)) do
			pcall(function() v:Disable() end)
		end
	end)
	pcall(function()
		local mt = getrawmetatable(game)
		if mt then
			setreadonly(mt, false)
			local oldNameCall = mt.__namecall
			mt.__namecall = newcclosure(function(self, ...)
				local method = getnamecallmethod()
				if method == "FireServer" or method == "InvokeServer" then
					if self == RigWipeRemote then
						STATE.RigWipeBlocked = STATE.RigWipeBlocked + 1
						return nil
					end
					if self == ProbeSatchelRemote then return nil end
					if self == SlowToggleRemote then return nil end
					local args = {...}
					for _, a in ipairs(args) do
						if typeof(a) == "string" then
							local s = a:lower()
							if s:find("kick") or s:find("ban") or s:find("wipe") or s:find("anticheat") or s:find("vanzmode") then
								return nil
							end
						end
					end
				end
				return oldNameCall(self, ...)
			end)
			setreadonly(mt, true)
		end
	end)
	STATE.AntiCheatKilled = true
end

local function InstallIndexSpoof()
	if STATE.IndexHooked then return true end
	local ok = pcall(function()
		local mt = getrawmetatable(game)
		if not mt then error("no mt") end
		local oldIndex = mt.__index
		setreadonly(mt, false)
		mt.__index = newcclosure(function(self, key)
			if STATE.SpeedLockActive and not STATE.SelfRead then
				if key == "Position" or key == "CFrame" or key == "AssemblyLinearVelocity" or key == "Velocity" then
					local okIs = pcall(function() return self:IsA("BasePart") end)
					if okIs then
						local c = LocalPlayer.Character
						if c and self:IsDescendantOf(c) then
							local nm = self.Name
							if nm == "HumanoidRootPart" or nm == "Torso" or nm == "UpperTorso" or nm == "LowerTorso" or nm == "Head" then
								STATE.PosBlocked = STATE.PosBlocked + 1
								local now = os.clock()
								if not STATE.LastFakePos then
									STATE.SelfRead = true
									STATE.LastFakePos = oldIndex(self, "Position")
									STATE.SelfRead = false
									STATE.LastFakeUpdate = now
								end
								if now - STATE.LastFakeUpdate >= CONFIG.EggSpoofInterval then
									STATE.SelfRead = true
									local realPos = oldIndex(self, "Position")
									STATE.SelfRead = false
									local d = realPos - STATE.LastFakePos
									if d.Magnitude > CONFIG.EggSpoofMaxStep then
										STATE.LastFakePos = STATE.LastFakePos + d.Unit * CONFIG.EggSpoofMaxStep
									else
										STATE.LastFakePos = realPos
									end
									STATE.LastFakeUpdate = now
								end
								if key == "Position" then return STATE.LastFakePos end
								if key == "CFrame" then return CFrame.new(STATE.LastFakePos) end
								if key == "AssemblyLinearVelocity" or key == "Velocity" then return Vector3.zero end
							end
						end
					end
				end
			end
			return oldIndex(self, key)
		end)
		setreadonly(mt, true)
	end)
	STATE.IndexHooked = ok
	return ok
end

local function InstallSpeedHook()
	if STATE.Hooked then return true end
	KillAntiCheatHooks()
	local ok = pcall(function()
		local mt = getrawmetatable(game)
		if not mt then error("no mt") end
		local oldNewIndex = mt.__newindex
		setreadonly(mt, false)
		mt.__newindex = newcclosure(function(self, key, value)
			if STATE.SpeedLockActive then
				if key == "WalkSpeed" then
					local okIs = pcall(function() return self:IsA("Humanoid") end)
					if okIs then
						local c = LocalPlayer.Character
						if c and self.Parent == c then
							if type(value) == "number" and value < STATE.TargetWalkSpeed then
								STATE.SpeedBlocked = STATE.SpeedBlocked + 1
								return
							end
						end
					end
				elseif key == "Health" then
					local okIs = pcall(function() return self:IsA("Humanoid") end)
					if okIs then
						local c = LocalPlayer.Character
						if c and self.Parent == c then
							if type(value) == "number" then
								STATE.HealthBlocked = STATE.HealthBlocked + 1
								return
							end
						end
					end
				elseif key == "CFrame" or key == "Position" or key == "AssemblyLinearVelocity" then
					local okIs = pcall(function() return self:IsA("BasePart") end)
					if okIs then
						local c = LocalPlayer.Character
						if c and self:IsDescendantOf(c) then
							local nm = self.Name
							if nm == "HumanoidRootPart" or nm == "Torso" or nm == "UpperTorso" or nm == "LowerTorso" or nm == "Head" then
								STATE.PosBlocked = STATE.PosBlocked + 1
								return
							end
						end
					end
				end
			end
			return oldNewIndex(self, key, value)
		end)
		setreadonly(mt, true)
	end)
	STATE.Hooked = ok
	return ok
end

local function StartNotifScrubLoop()
	if STATE.NotifScrubRunning then return end
	STATE.NotifScrubRunning = true
	task.spawn(function()
		while not STATE.Destroyed do
			if STATE.EggBusy then
				pcall(ScrubNotifRoots)
				task.wait(0.3)
			else
				task.wait(0.5)
			end
		end
	end)
end

--==================================================
-- [21] EGG FARM ENGINE
--==================================================
local EggFarm = {}
do
	if NET then
		EggFarm.RF_SNAP    = NET:FindFirstChild("RF/EggWorld/AskFieldEggSnapshot")
		EggFarm.RF_CARRY   = NET:FindFirstChild("RF/EggWorld/AskFieldEggCarry")
		EggFarm.RF_DOFF    = NET:FindFirstChild("RF/EggWorld/AskDoffTool")
		EggFarm.RE_TRIGGER = NET:FindFirstChild("RE/ToolTrigger/Trigger")
		EggFarm.Enabled = (EggFarm.RF_SNAP ~= nil and EggFarm.RF_CARRY ~= nil)
	else
		EggFarm.Enabled = false
	end
	EggFarm.Stop = false
end

EggFarm.FmtShort = function(n)
	if not n or n == 0 then return "0" end
	if n >= 1e12 then return string.format("%.1fT", n/1e12) end
	if n >= 1e9 then return string.format("%.1fB", n/1e9) end
	if n >= 1e6 then return string.format("%.1fM", n/1e6) end
	if n >= 1e3 then return string.format("%.1fK", n/1e3) end
	return tostring(math.floor(n))
end

EggFarm.BuildIncomeIndex = function()
	if STATE.EggIncomeIndex then return STATE.EggIncomeIndex end
	local idx = {}
	local root = RS:FindFirstChild("Data")
	root = root and root:FindFirstChild("Assets")
	root = root and root:FindFirstChild("Configs")
	if root then
		for _, m in ipairs(root:GetDescendants()) do
			if m:IsA("ModuleScript") then
				local ok, res = pcall(require, m)
				if ok and type(res) == "table" then
					local v = res.EarningRate or res.Earning or res.Income
					if type(v) == "number" then idx[m.Name] = v end
				end
			end
		end
	end
	STATE.EggIncomeIndex = idx
	return idx
end

EggFarm.IncomeFor = function(cat)
	local idx = EggFarm.BuildIncomeIndex()
	if not cat then return 0 end
	local d = idx[cat]; if d then return d end
	local lc = cat:lower()
	for k, v in pairs(idx) do if k:lower() == lc then return v end end
	for k, v in pairs(idx) do
		local kl = k:lower()
		if kl:find(lc, 1, true) or lc:find(kl, 1, true) then return v end
	end
	return 0
end

EggFarm.TrySnapshot = function()
	if not EggFarm.RF_SNAP then return nil, "no remote" end
	local sigs = {
		{ name = "noarg",      fn = function() return EggFarm.RF_SNAP:InvokeServer() end },
		{ name = "tbl({})",    fn = function() return EggFarm.RF_SNAP:InvokeServer({}) end },
		{ name = "tbl{Force}", fn = function() return EggFarm.RF_SNAP:InvokeServer({ Force = true }) end },
		{ name = "true",       fn = function() return EggFarm.RF_SNAP:InvokeServer(true) end },
		{ name = "false",      fn = function() return EggFarm.RF_SNAP:InvokeServer(false) end },
		{ name = "int 0",      fn = function() return EggFarm.RF_SNAP:InvokeServer(0) end },
		{ name = "int 1",      fn = function() return EggFarm.RF_SNAP:InvokeServer(1) end },
	}
	if STATE.SnapshotSignature then table.insert(sigs, 1, STATE.SnapshotSignature) end
	local results = {}
	for _, s in ipairs(sigs) do
		local ok, res = pcall(s.fn)
		local desc
		if not ok then
			desc = "ERR: " .. tostring(res):sub(1, 120)
		elseif type(res) == "table" then
			if res.Records and type(res.Records) == "table" then
				STATE.SnapshotSignature = s
				EggSigLbl.Text = "sig: " .. s.name .. " OK (" .. #res.Records .. ")"
				EggSigLbl.TextColor3 = COLORS.Good
				return res, nil
			end
			local n = 0; local ks = {}
			for k in pairs(res) do n = n + 1; if #ks < 6 then ks[#ks+1] = tostring(k) end end
			desc = "TABLE(" .. n .. "): " .. table.concat(ks, ",")
		elseif type(res) == "string" then
			desc = "STRING: " .. res:sub(1, 200)
		else
			desc = typeof(res) .. ": " .. tostring(res):sub(1, 120)
		end
		results[#results+1] = string.format("%-14s -> %s", s.name, desc)
	end
	STATE.SnapshotLastError = table.concat(results, "\n")
	return nil, STATE.SnapshotLastError
end

EggFarm.GetHomePos = function() return Vector3.new(CONFIG.EggHomeX, CONFIG.EggHomeY, CONFIG.EggHomeZ) end
EggFarm.GetHumanoid = function() local c = LocalPlayer.Character; return c and c:FindFirstChildOfClass("Humanoid") or nil end
EggFarm.GetHrp = function() local c = LocalPlayer.Character; return c and c:FindFirstChild("HumanoidRootPart") or nil end

EggFarm.EnableSurvival = function()
	local c = LocalPlayer.Character
	if not c then return end
	pcall(function() c:SetAttribute("VanzSurvive", true) end)
	local h = c:FindFirstChildOfClass("Humanoid")
	if h then
		pcall(function() h.BreakJointsOnDeath = false end)
	end
end

EggFarm.EnableSurvivalLoop = function()
	if STATE.SurvivalConn then pcall(function() STATE.SurvivalConn:Disconnect() end) end
	STATE.SurvivalConn = RunService.Heartbeat:Connect(function()
		if not STATE.SpeedLockActive or STATE.Destroyed then return end
		local c = LocalPlayer.Character
		if not c then return end
		local h = c:FindFirstChildOfClass("Humanoid")
		if h then
			if h.Health > 0 and h.Health < h.MaxHealth then
				pcall(function() h.Health = h.MaxHealth end)
			end
		end
	end)
end

EggFarm.ClearSpeed = function()
	STATE.SpeedLockActive = false
	STATE.SelfRead = false
	STATE.LastFakePos = nil
	STATE.LastFakeUpdate = 0
	STATE.HardStopped = false
	for _, c in ipairs(STATE.SpeedConns) do pcall(function() c:Disconnect() end) end
	table.clear(STATE.SpeedConns)
	if STATE.SurvivalConn then pcall(function() STATE.SurvivalConn:Disconnect() end) STATE.SurvivalConn = nil end
	if STATE.AlignPos then pcall(function() STATE.AlignPos:Destroy() end) STATE.AlignPos = nil end
	if STATE.AlignAtt then pcall(function() STATE.AlignAtt:Destroy() end) STATE.AlignAtt = nil end
	local hum = EggFarm.GetHumanoid()
	if hum then pcall(function() hum.WalkSpeed = 16 end) end
	EggStatLbl.Text = string.format("deaths: %d  wp=%d  hp=%d  pos=%d  sp=%d  tx=%d",
		STATE.Deaths, STATE.RigWipeBlocked, STATE.HealthBlocked, STATE.PosBlocked, STATE.SpeedBlocked, STATE.TextBlocked)
end

EggFarm.SetupSpeed = function(targetSpeed)
	EggFarm.ClearSpeed()
	STATE.TargetWalkSpeed = targetSpeed
	STATE.SpeedLockActive = true
	STATE.LastFakePos = nil
	STATE.LastFakeUpdate = 0
	STATE.HardStopped = false

	InstallSpeedHook()
	InstallIndexSpoof()

	local function applyWS()
		if not STATE.SpeedLockActive or STATE.Destroyed or STATE.HardStopped then return end
		local c = LocalPlayer.Character
		if not c then return end
		local h = c:FindFirstChildOfClass("Humanoid")
		if h then
			local want = CONFIG.EggWalkSpeed
			STATE.TargetWalkSpeed = want
			if h.WalkSpeed ~= want then
				pcall(function() h.WalkSpeed = want end)
			end
			if h.Health > 0 and h.Health < h.MaxHealth then
				pcall(function() h.Health = h.MaxHealth end)
			end
			pcall(function()
				if h:GetState() ~= Enum.HumanoidStateType.Running then
					h:ChangeState(Enum.HumanoidStateType.Running)
				end
			end)
		end
	end

	local preSim = RunService.PreSimulation
	if preSim then STATE.SpeedConns[#STATE.SpeedConns+1] = preSim:Connect(applyWS) end
	STATE.SpeedConns[#STATE.SpeedConns+1] = RunService.Stepped:Connect(applyWS)
	STATE.SpeedConns[#STATE.SpeedConns+1] = RunService.Heartbeat:Connect(applyWS)
	applyWS()

	local hrp = EggFarm.GetHrp()
	if hrp then
		local att = Instance.new("Attachment")
		att.Name = "VanzAlignAtt"
		att.Parent = hrp
		local ap = Instance.new("AlignPosition")
		ap.Name = "VanzAlignPos"
		ap.Mode = Enum.PositionAlignmentMode.OneAttachment
		ap.Attachment0 = att
		ap.MaxForce = CONFIG.EggAlignMaxForce
		ap.Responsiveness = 80
		ap.ApplyAtCenterOfMass = true
		STATE.SelfRead = true
		ap.Position = hrp.Position
		STATE.SelfRead = false
		ap.Parent = hrp
		STATE.AlignPos = ap
		STATE.AlignAtt = att
	end

	EggFarm.EnableSurvivalLoop()
	EggStatLbl.Text = string.format("deaths: %d  wp=%d  hp=%d  pos=%d  sp=%d  tx=%d",
		STATE.Deaths, STATE.RigWipeBlocked, STATE.HealthBlocked, STATE.PosBlocked, STATE.SpeedBlocked, STATE.TextBlocked)
end

EggFarm.WalkTo = function(targetPos, timeout)
	local hum = EggFarm.GetHumanoid()
	local hrp = EggFarm.GetHrp()
	if not hum or not hrp then return false end

	local target = Vector3.new(targetPos.X, targetPos.Y, targetPos.Z)
	local startTime = os.clock()
	local timeoutSec = timeout or CONFIG.EggWalkTimeout
	local ok = false

	EggFarm.SetupSpeed(CONFIG.EggWalkSpeed)

	local conn = RunService.RenderStepped:Connect(function()
		if STATE.Destroyed or EggFarm.Stop then return end
		local c = LocalPlayer.Character
		if not c then return end
		local h = c:FindFirstChildOfClass("Humanoid")
		local r = c:FindFirstChild("HumanoidRootPart")
		if not h or not r then return end

		STATE.SelfRead = true
		local realPos = r.Position
		STATE.SelfRead = false

		local d = target - realPos
		local dist = d.Magnitude

		if dist < CONFIG.EggPrecisionDist then
			ok = true
			return
		end

		local want
		if dist < CONFIG.EggReachDistance then
			want = CONFIG.EggPrecisionSpeed
		else
			local elapsed = os.clock() - startTime
			local factor = math.clamp(elapsed / CONFIG.EggRampUp, 0, 1)
			want = math.max(16, CONFIG.EggWalkSpeed * factor)
		end

		STATE.TargetWalkSpeed = want
		pcall(function() h.WalkSpeed = want end)

		if STATE.AlignPos then
			STATE.AlignPos.Position = target
		end

		local horizDir = Vector3.new(d.X, 0, d.Z)
		if horizDir.Magnitude > 0.15 then
			pcall(function() h:Move(horizDir.Unit) end)
		end
	end)

	while os.clock() - startTime < timeoutSec do
		if STATE.Destroyed or EggFarm.Stop or ok then break end
		task.wait(0.02)
	end

	pcall(function() conn:Disconnect() end)
	EggFarm.ClearSpeed()
	return ok
end

EggFarm.SettleAt = function(seconds)
	STATE.HardStopped = true
	local h = EggFarm.GetHumanoid()
	if h then
		pcall(function()
			h.WalkSpeed = 0
			h:Move(Vector3.zero, false)
		end)
	end
	task.wait(seconds or CONFIG.EggSettleTime)
	STATE.HardStopped = false
end

EggFarm.DoCarry = function(uid)
	return pcall(function() return EggFarm.RF_CARRY:InvokeServer({ Uid = uid }) end)
end
EggFarm.DoDoff = function(uid)
	if not EggFarm.RF_DOFF then return false end
	return pcall(function() return EggFarm.RF_DOFF:InvokeServer(uid) end)
end

EggFarm.FindEggTool = function()
	local function scanOne(c)
		if not c then return nil end
		for _, t in ipairs(c:GetChildren()) do
			if t:IsA("Tool") and t.Name:lower():find("egg") then return t end
			if t:IsA("Folder") then
				local inner = scanOne(t)
				if inner then return inner end
			end
		end
		return nil
	end
	local containers = {
		LocalPlayer.Character,
		LocalPlayer:FindFirstChild("Backpack"),
	}
	for _, c in ipairs(containers) do
		local found = scanOne(c)
		if found then return found end
	end
	return nil
end
EggFarm.HasEggTool = function() return EggFarm.FindEggTool() ~= nil end
EggFarm.EquipEggTool = function()
	local tool = EggFarm.FindEggTool()
	if not tool then return false end
	local char = LocalPlayer.Character
	if tool.Parent == char then return true end
	local hum = EggFarm.GetHumanoid()
	if not hum then return false end
	return pcall(function() hum:EquipTool(tool) end)
end
EggFarm.DoTrigger = function()
	local tool = EggFarm.FindEggTool()
	if not tool then return false end
	return pcall(function() return EggFarm.RE_TRIGGER:FireServer(tool) end)
end

EggFarm.ClearRows = function()
	for _, r in ipairs(STATE.EggRowPool) do if r and r.Parent then r:Destroy() end end
	table.clear(STATE.EggRowPool)
end

EggFarm.BuildRow = function(i, e)
	local row = Create("Frame", { Size = UDim2.new(1,-8,0,30), BackgroundColor3 = COLORS.Card, BackgroundTransparency = 0.3, BorderSizePixel = 0, LayoutOrder = i, Parent = EggListScroll })
	MakeCorner(row, 6)
	Create("TextLabel", { Text = tostring(i), Size = UDim2.new(0,26,1,0), Position = UDim2.new(0,4,0,0), BackgroundTransparency = 1, Font = FONT_BOLD, TextSize = 11, TextColor3 = COLORS.SubText, TextXAlignment = Enum.TextXAlignment.Center, Parent = row })
	Create("TextLabel", { Text = EggFarm.FmtShort(e.earn), Size = UDim2.new(0,60,1,0), Position = UDim2.new(0,32,0,0), BackgroundTransparency = 1, Font = FONT_BOLD, TextSize = 12, TextColor3 = GetTheme().Accent2, TextXAlignment = Enum.TextXAlignment.Left, Parent = row })
	Create("TextLabel", { Text = e.name .. (e.area ~= "?" and ("  •  "..e.area) or ""), Size = UDim2.new(1,-110,1,0), Position = UDim2.new(0,96,0,0), BackgroundTransparency = 1, Font = FONT_TEXT, TextSize = 12, TextColor3 = COLORS.Text, TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd, Parent = row })
	return row
end

EggFarm.RenderList = function()
	EggFarm.ClearRows()
	for i, e in ipairs(STATE.EggList) do
		STATE.EggRowPool[#STATE.EggRowPool+1] = EggFarm.BuildRow(i, e)
	end
	EggListScroll.CanvasSize = UDim2.new(0,0,0, EggListLayout.AbsoluteContentSize.Y + 8)
	EggCountLbl.Text = string.format("%d eggs", #STATE.EggList)
end

EggFarm.Scan = function()
	if not EggFarm.Enabled then EggStatusLbl.Text = "Egg farm disabled." return end
	if STATE.EggBusy or STATE.EggScanning then return end
	STATE.EggScanning = true
	EggStatusLbl.Text = "Scanning…"
	task.spawn(function()
		local res, err = EggFarm.TrySnapshot()
		if not res then
			STATE.SnapshotLastError = err
			EggStatusLbl.Text = "Snapshot failed"
			EggStatusLbl.TextColor3 = COLORS.Bad
			EggSigLbl.Text = "sig: FAIL"
			EggSigLbl.TextColor3 = COLORS.Bad
			STATE.EggScanning = false
			return
		end
		local tmp = {}
		for _, r in ipairs(res.Records) do
			if r.State == "Slot" and r.Uid and r.BottomCFrame then
				local cat = r.AssetCategory or "?"
				local earn = EggFarm.IncomeFor(cat)
				if earn >= CONFIG.EggMinIncome then
					tmp[#tmp+1] = { uid = r.Uid, name = cat, area = r.AreaId or "?", pos = r.BottomCFrame.Position, earn = earn }
				end
			end
		end
		table.sort(tmp, function(a, b) return a.earn > b.earn end)
		STATE.EggList = tmp
		EggFarm.RenderList()
		EggStatusLbl.Text = string.format("%d eggs sorted.", #tmp)
		EggStatusLbl.TextColor3 = COLORS.SubText
		STATE.EggScanning = false
	end)
end

EggFarm.ProcessOne = function(e, homePos)
	local tStart = os.clock()

	local okReach = EggFarm.WalkTo(e.pos)
	if not okReach then return false, "reach_egg" end

	EggFarm.SettleAt(CONFIG.EggSettleTime)

	EggFarm.DoCarry(e.uid)
	task.wait(0.35)

	EggFarm.EquipEggTool()
	task.wait(0.05)
	EggFarm.DoTrigger()
	task.wait(0.1)

	pcall(ScrubNotifRoots)

	local okHome = EggFarm.WalkTo(homePos, 25)
	if not okHome then
		EggFarm.SettleAt(0.3)
		EggFarm.DoDoff(e.uid)
		return false, "reach_home"
	end

	local elapsed = os.clock() - tStart
	if elapsed < CONFIG.EggMinDeliveryTime then
		task.wait(CONFIG.EggMinDeliveryTime - elapsed)
	end

	EggFarm.SettleAt(CONFIG.EggSettleTime)

	EggFarm.DoDoff(e.uid)
	task.wait(0.35)
	pcall(ScrubNotifRoots)

	local toolAfter = EggFarm.HasEggTool()
	if toolAfter then
		for r = 1, CONFIG.EggRetry do
			if EggFarm.Stop then break end
			task.wait(0.4)
			EggFarm.SettleAt(0.2)
			EggFarm.DoDoff(e.uid)
			task.wait(0.35)
			pcall(ScrubNotifRoots)
			toolAfter = EggFarm.HasEggTool()
			if not toolAfter then break end
		end
	end

	if toolAfter then return false, "doff_fail" end
	return true, "ok"
end

EggFarm.CarryAll = function()
	if not EggFarm.Enabled then EggStatusLbl.Text = "Egg farm disabled." return end
	if STATE.EggBusy then EggStatusLbl.Text = "Busy." return end
	if #STATE.EggList == 0 then EggStatusLbl.Text = "List empty — SCAN first." return end

	STATE.EggBusy = true
	EggFarm.Stop = false
	InstallSpeedHook()
	InstallIndexSpoof()
	EggFarm.EnableSurvival()

	task.spawn(function()
		local okc, failc = 0, 0
		local homePos = EggFarm.GetHomePos()

		for i, e in ipairs(STATE.EggList) do
			if EggFarm.Stop then break end

			EggStatusLbl.Text = string.format("[%d/%d] → %s", i, #STATE.EggList, e.name)
			local ok, reason = EggFarm.ProcessOne(e, homePos)

			if ok then okc = okc + 1 else failc = failc + 1 end

			EggStatusLbl.Text = string.format("[%d/%d] %s ok=%d fail=%d %s", i, #STATE.EggList, e.name, okc, failc, reason or "")
			EggStatLbl.Text = string.format("deaths: %d  wp=%d  hp=%d  pos=%d  sp=%d  tx=%d",
				STATE.Deaths, STATE.RigWipeBlocked, STATE.HealthBlocked, STATE.PosBlocked, STATE.SpeedBlocked, STATE.TextBlocked)
		end

		if EggFarm.Stop then
			EggStatusLbl.Text = string.format("STOPPED ok=%d fail=%d", okc, failc)
		else
			EggStatusLbl.Text = string.format("Done. ok=%d fail=%d", okc, failc)
		end
		EggFarm.ClearSpeed()
		STATE.EggBusy = false
	end)
end

EggSetHomeBtn.MouseButton1Click:Connect(function()
	local hrp = EggFarm.GetHrp()
	if hrp then
		STATE.SelfRead = true
		local p = hrp.Position
		STATE.SelfRead = false
		CONFIG.EggHomeX, CONFIG.EggHomeY, CONFIG.EggHomeZ = p.X, p.Y, p.Z
		EggHomeLbl.Text = string.format("HOME: %.1f, %.1f, %.1f", p.X, p.Y, p.Z)
		EggStatusLbl.Text = "Home set."
	end
end)
EggScanBtn.MouseButton1Click:Connect(EggFarm.Scan)
EggCarryAllBtn.MouseButton1Click:Connect(EggFarm.CarryAll)
EggStopBtn.MouseButton1Click:Connect(function()
	EggFarm.Stop = true
	EggStatusLbl.Text = "Stopping…"
	EggFarm.ClearSpeed()
	STATE.EggBusy = false
end)
EggHomeLbl.Text = string.format("HOME: %.1f, %.1f, %.1f", CONFIG.EggHomeX, CONFIG.EggHomeY, CONFIG.EggHomeZ)

--==================================================
-- [22-30] SETTINGS
--==================================================
local SettingsCards = {}
local function NewSettingsCard(t, h)
	local c = MakeCard(SettingsScroll, t, UDim2.new(1,-4,0,h), nil)
	table.insert(SettingsCards, c)
	return c
end
local function MakeToggleRow(p, label, y, get, set)
	local row = MakeFrame(p, UDim2.new(1,-24,0,44), UDim2.new(0,12,0,y), COLORS.Track, 0.1)
	MakeCorner(row, 10)
	MakeLabel(row, label, UDim2.new(1,-110,1,0), UDim2.new(0,12,0,0), FONT_BOLD, 14, COLORS.Text)
	local b = MakeButton(row, "", UDim2.new(0,88,0,32), UDim2.new(1,-96,0.5,-16), function()
		local nv = not get(); set(nv)
		b.Text = nv and "ON" or "OFF"
		b.TextColor3 = nv and COLORS.Good or COLORS.Bad
	end)
	b.Text = get() and "ON" or "OFF"
	b.TextColor3 = get() and COLORS.Good or COLORS.Bad
	return row
end
local function MakeCycleRow(p, label, y, opts, get, set, fmt)
	local row = MakeFrame(p, UDim2.new(1,-24,0,44), UDim2.new(0,12,0,y), COLORS.Track, 0.1)
	MakeCorner(row, 10)
	MakeLabel(row, label, UDim2.new(1,-150,1,0), UDim2.new(0,12,0,0), FONT_BOLD, 14, COLORS.Text)
	local function txt() local v = get(); return fmt and fmt(v) or tostring(v) end
	local b = MakeButton(row, txt(), UDim2.new(0,132,0,32), UDim2.new(1,-140,0.5,-16), function()
		local cur = get(); local idx = 1
		for i, o in ipairs(opts) do if o == cur then idx = i break end end
		set(opts[(idx % #opts) + 1]); b.Text = txt()
	end)
	return row
end
local function MakeStepperRow(p, label, y, minV, maxV, step, get, set, fmt)
	local row = MakeFrame(p, UDim2.new(1,-24,0,44), UDim2.new(0,12,0,y), COLORS.Track, 0.1)
	MakeCorner(row, 10)
	MakeLabel(row, label, UDim2.new(0.45,0,1,0), UDim2.new(0,12,0,0), FONT_BOLD, 14, COLORS.Text)
	local vl = MakeLabel(row, "", UDim2.new(0,70,0,22), UDim2.new(1,-150,0.5,-11), FONT_BOLD, 14, GetTheme().Accent2, Enum.TextXAlignment.Center)
	local function rf() local v = get(); vl.Text = fmt and fmt(v) or tostring(v) end
	rf()
	MakeButton(row, "-", UDim2.new(0,40,0,32), UDim2.new(1,-116,0.5,-16), function() set(math.max(minV, get() - step)); rf() end)
	MakeButton(row, "+", UDim2.new(0,40,0,32), UDim2.new(1,-52,0.5,-16), function() set(math.min(maxV, get() + step)); rf() end)
end

local ApplyTheme

local function SetScale(v)
	for _, o in ipairs(CONFIG.ScaleOptions) do
		if math.abs(o - v) < 0.001 then
			CONFIG.Scale = v
			if STATE.Open and not STATE.Minimized then ApplyWindowLayout(false) end
			return true
		end
	end
	return false
end
local function ScaleText(v) return string.format("%d%%", math.floor(v*100+0.5)) end

local function BuildSettingsUI()
	local d = NewSettingsCard("DISPLAY", 260); d.LayoutOrder = 1
	MakeCycleRow(d, "GUI Scale", 36, CONFIG.ScaleOptions, function() return CONFIG.Scale end, SetScale, ScaleText)
	MakeStepperRow(d, "Window Opacity", 88, 0.02, 0.5, 0.02, function() return CONFIG.WindowOpacity end, function(v)
		CONFIG.WindowOpacity = v
		if STATE.Open and not STATE.Minimized then MainWindow.BackgroundTransparency = v end
	end, function(v) return string.format("%.2f", v) end)
	MakeStepperRow(d, "Corner Radius", 140, 6, 24, 2, function() return CONFIG.CornerRadius end, function(v) CONFIG.CornerRadius = v end, tostring)
	MakeStepperRow(d, "Border Intensity", 192, 0, 1, 0.1, function() return CONFIG.BorderIntensity end, function(v)
		CONFIG.BorderIntensity = v; MainStroke.Transparency = 1 - v
	end, function(v) return string.format("%.1f", v) end)

	local g = NewSettingsCard("GLASS", 120); g.LayoutOrder = 2
	MakeStepperRow(g, "Glass Intensity", 36, 0, 1, 0.1, function() return CONFIG.GlassIntensity end, function(v)
		CONFIG.GlassIntensity = v; MainGradient.Transparency = NumberSequence.new(1 - v)
	end, function(v) return string.format("%.1f", v) end)

	local a = NewSettingsCard("ANIMATION", 420); a.LayoutOrder = 3
	local arows = {{"Master Animation","AnimationEnabled"},{"Soft Animation","SoftAnimation"},{"Logo Animation","LogoAnimation"},{"Radar Animation","RadarAnimation"},{"Particle Animation","ParticleAnimation"},{"Scanline","Scanline"},{"Hover Animation","HoverAnimation"},{"Click Animation","ClickAnimation"},{"Transition Animation","TransitionAnimation"}}
	local ay = 36
	for _, p in ipairs(arows) do MakeToggleRow(a, p[1], ay, function() return CONFIG[p[2]] end, function(v) CONFIG[p[2]] = v end); ay = ay + 46 end
	MakeCycleRow(a, "Animation Speed", ay, {0.5,0.75,1,1.25,1.5}, function() return CONFIG.AnimationSpeed end, function(v) CONFIG.AnimationSpeed = v end, function(v) return string.format("%.2fx", v) end)

	local vis = NewSettingsCard("VISUAL", 420); vis.LayoutOrder = 4
	MakeCycleRow(vis, "Theme", 36, {"Cyber Blue","Neon Cyan","Purple Anime","Crimson","Emerald","Ice"}, function() return CONFIG.Theme end, function(v) CONFIG.Theme = v; ApplyTheme() end)
	MakeStepperRow(vis, "Glow Intensity", 88, 0, 1, 0.1, function() return CONFIG.GlowIntensity end, function(v) CONFIG.GlowIntensity = v end, function(v) return string.format("%.1f", v) end)
	MakeStepperRow(vis, "Particle Density", 140, 0, 30, 2, function() return CONFIG.ParticleDensity end, function(v) CONFIG.ParticleDensity = v end, tostring)
	MakeToggleRow(vis, "HUD Decoration", 192, function() return CONFIG.HUDDecoration end, function(v) CONFIG.HUDDecoration = v end)
	MakeToggleRow(vis, "Background Grid", 244, function() return CONFIG.BackgroundGrid end, function(v) CONFIG.BackgroundGrid = v end)

	local w = NewSettingsCard("WINDOW", 240); w.LayoutOrder = 5
	MakeToggleRow(w, "Remember Position", 36, function() return CONFIG.RememberPosition end, function(v) CONFIG.RememberPosition = v end)
	local cb = MakeButton(w, "Center Window", UDim2.new(1,-24,0,40), UDim2.new(0,12,0,92), function() ApplyWindowLayout(true) end); MakeCorner(cb, 10)
	local rp = MakeButton(w, "Reset Position", UDim2.new(1,-24,0,40), UDim2.new(0,12,0,140), function() STATE.MainPosition = nil; STATE.MiniPosition = nil; ApplyWindowLayout(true) end); MakeCorner(rp, 10)
	local rs = MakeButton(w, "Reset Settings", UDim2.new(1,-24,0,40), UDim2.new(0,12,0,188), function() _G.vanz.ResetSettings() end); MakeCorner(rs, 10)

	local perf = NewSettingsCard("PERFORMANCE", 220); perf.LayoutOrder = 6
	MakeToggleRow(perf, "Low FX Mode", 36, function() return CONFIG.LowFXMode end, function(v) CONFIG.LowFXMode = v end)
	MakeToggleRow(perf, "FPS Friendly Mode", 88, function() return CONFIG.FPSFriendly end, function(v) CONFIG.FPSFriendly = v end)
	MakeToggleRow(perf, "Disable Particles", 140, function() return CONFIG.DisableParticles end, function(v) CONFIG.DisableParticles = v end)
	MakeToggleRow(perf, "Disable Heavy Animation", 192, function() return CONFIG.DisableHeavyAnimation end, function(v) CONFIG.DisableHeavyAnimation = v end)

	local egg = NewSettingsCard("EGG FARM", 500); egg.LayoutOrder = 7
	MakeLabel(egg, "Walk Speed", UDim2.new(0.5,0,1,0), UDim2.new(0,12,0,36), FONT_BOLD, 14, COLORS.Text)
	local wsIn = MakeTextBox(egg, "1000", UDim2.new(0,132,0,32), UDim2.new(1,-140,0,36), function(t)
		local n = tonumber(t)
		if n and n > 0 then ApplyLiveSpeed(n)
		else wsIn.Text = tostring(CONFIG.EggWalkSpeed) end
	end, tostring(CONFIG.EggWalkSpeed))
	MakeStepperRow(egg, "Ramp-Up (s)", 88, 0.3, 5, 0.1, function() return CONFIG.EggRampUp end, function(v) CONFIG.EggRampUp = v end, function(v) return string.format("%.2fs", v) end)
	MakeStepperRow(egg, "Reach Distance", 140, 2, 30, 1, function() return CONFIG.EggReachDistance end, function(v) CONFIG.EggReachDistance = v end, function(v) return tostring(v).." studs" end)
	MakeStepperRow(egg, "Precision Dist", 192, 1, 15, 1, function() return CONFIG.EggPrecisionDist end, function(v) CONFIG.EggPrecisionDist = v end, function(v) return tostring(v).." studs" end)
	MakeStepperRow(egg, "Precision Speed", 244, 5, 100, 5, function() return CONFIG.EggPrecisionSpeed end, function(v) CONFIG.EggPrecisionSpeed = v end, tostring)
	MakeStepperRow(egg, "Settle Time (s)", 296, 0.1, 1, 0.05, function() return CONFIG.EggSettleTime end, function(v) CONFIG.EggSettleTime = v end, function(v) return string.format("%.2fs", v) end)
	MakeStepperRow(egg, "Min Delivery (s)", 348, 0.5, 5, 0.1, function() return CONFIG.EggMinDeliveryTime end, function(v) CONFIG.EggMinDeliveryTime = v end, function(v) return string.format("%.1fs", v) end)
	MakeStepperRow(egg, "Walk Timeout (s)", 400, 5, 60, 5, function() return CONFIG.EggWalkTimeout end, function(v) CONFIG.EggWalkTimeout = v end, function(v) return tostring(v).."s" end)
	MakeStepperRow(egg, "Min Income", 452, 0, 1e9, 100000, function() return CONFIG.EggMinIncome end, function(v) CONFIG.EggMinIncome = v end, function(v)
		if v >= 1e6 then return string.format("%.1fM", v/1e6) end
		if v >= 1e3 then return string.format("%.1fK", v/1e3) end
		return tostring(v)
	end)
end

ApplyTheme = function()
	local t = GetTheme()
	MainWindow.BackgroundColor3 = t.Base
	MainStroke.Color = t.Accent
	MainGradient.Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, t.Base), ColorSequenceKeypoint.new(1, t.Base2) })
	AccentLine.BackgroundColor3 = t.Accent2
	HeaderLogoRing.BackgroundColor3 = t.Accent
	HeaderLogoCore.BackgroundColor3 = t.Accent2
	HomeScroll.ScrollBarImageColor3 = t.Accent
	SettingsScroll.ScrollBarImageColor3 = t.Accent2
end

ApplyLiveSpeed = function(n)
	if not n or n <= 0 then return end
	CONFIG.EggWalkSpeed = math.floor(n)
	STATE.TargetWalkSpeed = CONFIG.EggWalkSpeed
	if STATE.SpeedLockActive and not STATE.HardStopped then
		local c = LocalPlayer.Character
		if c then
			local h = c:FindFirstChildOfClass("Humanoid")
			if h then
				pcall(function() h.WalkSpeed = CONFIG.EggWalkSpeed end)
			end
		end
	end
end

--==================================================
-- [31] HUD DECORATION
--==================================================
local HudLayer = MakeFrame(MainWindow, UDim2.new(1,0,1,0), nil, COLORS.Card, 1)
HudLayer.ZIndex = 1
local function MakeBracket(isLeft, isTop)
	local bx, by = isLeft and 0 or 1, isTop and 0 or 1
	MakeFrame(HudLayer, UDim2.new(0,14,0,2), UDim2.new(bx, isLeft and 6 or -20, by, isTop and 6 or -8), GetTheme().Accent, 0.3)
	MakeFrame(HudLayer, UDim2.new(0,2,0,14), UDim2.new(bx, isLeft and 6 or -8, by, isTop and 6 or -20), GetTheme().Accent, 0.3)
end
MakeBracket(true, true); MakeBracket(false, true); MakeBracket(true, false); MakeBracket(false, false)
local ScanLine = MakeFrame(HudLayer, UDim2.new(1,0,0,1), nil, GetTheme().Accent2, 0.75)
local MicroText = MakeLabel(HudLayer, "VANZ CORE • SYSTEM ONLINE", UDim2.new(0,200,0,12), UDim2.new(0,12,1,-16), FONT_TEXT, 10, COLORS.SubText)
MicroText.TextTransparency = 0.25

--==================================================
-- [32] ANIMATION
--==================================================
local AnimTime = 0
local function AnimationTick(dt)
	if not CONFIG.AnimationEnabled or CONFIG.LowFXMode or CONFIG.DisableHeavyAnimation then return end
	AnimTime = AnimTime + dt * CONFIG.AnimationSpeed
	if CONFIG.LogoAnimation and STATE.Open and not STATE.Minimized then
		local p = 0.9 + 0.1 * math.sin(AnimTime * 2.4)
		HeaderLogoRing.Size = UDim2.new(p,0,p,0)
		HeaderLogoRing.Position = UDim2.new((1-p)/2,0,(1-p)/2,0)
	end
	if CONFIG.Scanline and CONFIG.HUDDecoration and STATE.Open then
		local span = MainWindow.AbsoluteSize.Y
		if span > 0 then ScanLine.Position = UDim2.new(0,0,0, (AnimTime*60) % span) end
	end
end

--==================================================
-- [33] PARTICLE
--==================================================
local ParticleContainer = MakeFrame(MainWindow, UDim2.new(1,0,1,0), nil, COLORS.Card, 1)
ParticleContainer.ZIndex = 0
ParticleContainer.ClipsDescendants = true
local ParticleCount, MAX_PARTICLES = 0, 40
local function SpawnParticle()
	if CONFIG.DisableParticles or CONFIG.LowFXMode or not CONFIG.ParticleAnimation then return end
	if ParticleCount >= MAX_PARTICLES or not STATE.Open or STATE.Minimized then return end
	local w, h = ParticleContainer.AbsoluteSize.X, ParticleContainer.AbsoluteSize.Y
	if w <= 0 or h <= 0 then return end
	ParticleCount = ParticleCount + 1
	local sz = math.random(2, 4)
	local p = MakeFrame(ParticleContainer, UDim2.new(0,sz,0,sz), UDim2.new(0, math.random(0,w), 0, math.random(0,h)), GetTheme().Accent2, 0.7)
	MakeCorner(p, sz)
	local dx, dy = math.random(-30,30), math.random(-40,-10)
	local dur = math.random(25,45)/10/CONFIG.AnimationSpeed
	local tw = TweenService:Create(p, TweenInfo.new(dur, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
		Position = UDim2.new(0, math.clamp(p.Position.X.Offset + dx, 0, w), 0, math.clamp(p.Position.Y.Offset + dy, 0, h)),
		BackgroundTransparency = 1,
	})
	TrackTween(tw); tw:Play()
	task.delay(dur, function()
		ParticleCount = math.max(0, ParticleCount - 1)
		if p and p.Parent then p:Destroy() end
	end)
end
local ParticleAcc = 0

--==================================================
-- [34] DATA UPDATE
--==================================================
local function GetCharacter() return LocalPlayer.Character end
local function GetHumanoid() local c = GetCharacter(); return c and c:FindFirstChildOfClass("Humanoid") or nil end
local function GetRootPart() local c = GetCharacter(); return c and c:FindFirstChild("HumanoidRootPart") or nil end

local function UpdateCharacterCard(h, root)
	local c = GetCharacter()
	if h then
		CharLines["WalkSpeed"].Text = "WalkSpeed: " .. ToStr(h.WalkSpeed)
		CharLines["JumpPower"].Text = "JumpPower: " .. ToStr(h.JumpPower)
		CharLines["Health"].Text = "Health: " .. ToStr(h.Health, 1)
		CharLines["MaxHealth"].Text = "MaxHealth: " .. ToStr(h.MaxHealth, 1)
		local pct = h.MaxHealth > 0 and (h.Health/h.MaxHealth)*100 or 0
		CharLines["Health %"].Text = string.format("Health %%: %.1f%%", pct)
		CharLines["HipHeight"].Text = "HipHeight: " .. ToStr(h.HipHeight, 2)
		CharLines["AutoRotate"].Text = "AutoRotate: " .. tostring(h.AutoRotate)
		CharLines["PlatformStand"].Text = "PlatformStand: " .. tostring(h.PlatformStand)
		CharLines["RigType"].Text = "RigType: " .. tostring(h.RigType and h.RigType.Name or "N/A")
		CharLines["Character State"].Text = "Character State: " .. tostring(h:GetState().Name)
	else
		for k in pairs(CharLines) do CharLines[k].Text = k .. ": N/A" end
	end
	MoveLines["Character Name"].Text = "Character Name: " .. (c and c.Name or "N/A")
	if root then
		STATE.SelfRead = true
		local vel = root.AssemblyLinearVelocity
		local pos = root.Position
		local lk = root.CFrame.LookVector
		STATE.SelfRead = false
		MoveLines["Velocity"].Text = string.format("Velocity: %.1f", vel.Magnitude)
		PosLines["Pos X"].Text = string.format("Pos X: %.2f", pos.X)
		PosLines["Pos Y"].Text = string.format("Pos Y: %.2f", pos.Y)
		PosLines["Pos Z"].Text = string.format("Pos Z: %.2f", pos.Z)
		PosLines["Vel X"].Text = string.format("Vel X: %.2f", vel.X)
		PosLines["Vel Y"].Text = string.format("Vel Y: %.2f", vel.Y)
		PosLines["Vel Z"].Text = string.format("Vel Z: %.2f", vel.Z)
		PosLines["Magnitude"].Text = string.format("Magnitude: %.2f", vel.Magnitude)
		PosLines["Facing"].Text = string.format("Facing: %.2f, %.2f, %.2f", lk.X, lk.Y, lk.Z)
	else
		for k in pairs(PosLines) do PosLines[k].Text = k .. ": N/A" end
		MoveLines["Velocity"].Text = "Velocity: N/A"
	end
	if h then
		MoveLines["MoveDirection"].Text = string.format("MoveDirection: %.2f, %.2f, %.2f", h.MoveDirection.X, h.MoveDirection.Y, h.MoveDirection.Z)
		MoveLines["Grounded"].Text = "Grounded: " .. tostring(h.FloorMaterial ~= Enum.Material.Air)
		MoveLines["Floor Material"].Text = "Floor Material: " .. tostring(h.FloorMaterial and h.FloorMaterial.Name or "N/A")
		MoveLines["Seat Status"].Text = "Seat Status: " .. (h.SeatPart and "Seated" or "Not Seated")
		MoveLines["Humanoid State"].Text = "Humanoid State: " .. tostring(h:GetState().Name)
	else
		for _, k in ipairs({"MoveDirection","Grounded","Floor Material","Seat Status","Humanoid State"}) do MoveLines[k].Text = k .. ": N/A" end
	end
end

local function UpdateHealthCard(h)
	if not h or not h.MaxHealth or h.MaxHealth <= 0 then
		HealthText.Text = "N/A"; HealthFill.Size = UDim2.new(0,0,1,0); return
	end
	local pct = math.clamp(h.Health/h.MaxHealth, 0, 1)
	HealthFill.Size = UDim2.new(pct, 0, 1, 0)
	HealthText.Text = string.format("%d / %d", math.floor(h.Health+0.5), math.floor(h.MaxHealth+0.5))
	HealthFill.BackgroundColor3 = pct > 0.6 and COLORS.Good or pct > 0.3 and COLORS.Warn or COLORS.Bad
end

local function UpdateSessionCard()
	SessionLines["FPS"].Text = "FPS: " .. tostring(math.floor(STATE.LastFPS + 0.5))
	local ok, txt = pcall(function() return string.format("%d ms", math.floor(Stats.Network.ServerStatsItem["Data Ping"]:GetValue() + 0.5)) end)
	SessionLines["Ping"].Text = "Ping: " .. (ok and txt or "N/A")
	local up = os.clock() - STATE.SessionStart
	SessionLines["Uptime"].Text = string.format("Uptime: %02d:%02d", math.floor(up/60), math.floor(up%60))
	local ok2, mem = pcall(function() return string.format("%.1f MB", Stats:GetTotalMemoryUsageMb()) end)
	SessionLines["Memory"].Text = "Memory: " .. (ok2 and mem or "N/A")
	SessionLines["Heartbeat"].Text = string.format("Heartbeat: %.1f ms", (STATE.LastFrameDt or 0) * 1000)
	SessionLines["Client State"].Text = "Client State: " .. (STATE.Open and (STATE.Minimized and "Minimized" or "Open") or "Closed")
	SessionLines["System"].Text = "System: " .. (STATE.DeviceText or "N/A")
end

local function UpdatePlayerInfo()
	local c, h = GetCharacter(), GetHumanoid()
	local function setI(k, v) if InfoLines[k] then InfoLines[k].Text = k .. ": " .. (v or "N/A") end end
	setI("Display Name", LocalPlayer.DisplayName)
	setI("Username", LocalPlayer.Name)
	setI("UserId", ToStr(LocalPlayer.UserId))
	setI("Account Age", ToStr(LocalPlayer.AccountAge).." hari")
	setI("Team", LocalPlayer.Team and LocalPlayer.Team.Name or "N/A")
	setI("Team Color", LocalPlayer.TeamColor and tostring(LocalPlayer.TeamColor) or "N/A")
	setI("Character", c and c.Name or "N/A")
	setI("Rig Type", (h and h.RigType and h.RigType.Name) or "N/A")
	setI("Device", STATE.DeviceText or "N/A")
	pcall(function() setI("Camera Mode", tostring(LocalPlayer.CameraMode and LocalPlayer.CameraMode.Name or "N/A")) end)
	pcall(function() setI("Field Of View", string.format("%.1f", Camera.FieldOfView)) end)
	pcall(function() setI("Graphics Quality", tostring(settings().Rendering.QualityLevel)) end)
	local up = os.clock() - STATE.SessionStart
	setI("Session Time", string.format("%02d:%02d", math.floor(up/60), math.floor(up%60)))
	pcall(function() setI("Server JobId", game.JobId ~= "" and game.JobId or "N/A") end)
	pcall(function() setI("PlaceId", tostring(game.PlaceId)) end)
	pcall(function() setI("GameId", tostring(game.GameId)) end)
end

local function UpdateSlowData()
	pcall(function()
		local mt = LocalPlayer.MembershipType
		ProfileMembership.Text = "Membership: " .. (mt == Enum.MembershipType.Premium and "Premium" or mt == Enum.MembershipType.None and "None" or "N/A")
	end)
	pcall(function() ProfileTeam.Text = "Team: " .. (LocalPlayer.Team and LocalPlayer.Team.Name or "N/A") end)
end

--==================================================
-- [35] CHARACTER EVENTS
--==================================================
local HumanoidConnections = {}
local function DisconnectHumanoidEvents()
	for _, c in ipairs(HumanoidConnections) do pcall(function() c:Disconnect() end) end
	table.clear(HumanoidConnections)
end
local function BindCharacter(char)
	DisconnectHumanoidEvents()
	if not char then return end
	local h = char:WaitForChild("Humanoid", 5)
	if h then
		pcall(function() h.BreakJointsOnDeath = false end)
		table.insert(HumanoidConnections, h.Died:Connect(function()
			STATE.Deaths = STATE.Deaths + 1
			EggStatLbl.Text = string.format("deaths: %d  wp=%d  hp=%d  pos=%d  sp=%d  tx=%d",
				STATE.Deaths, STATE.RigWipeBlocked, STATE.HealthBlocked, STATE.PosBlocked, STATE.SpeedBlocked, STATE.TextBlocked)
			UpdateHealthCard(nil)
		end))
	end
end
TrackConnection(LocalPlayer.CharacterAdded:Connect(function(c) task.defer(BindCharacter, c) end))
TrackConnection(LocalPlayer:GetPropertyChangedSignal("Team"):Connect(UpdateSlowData))

--==================================================
-- [36] MAIN LOOP
--==================================================
TrackConnection(RunService.Heartbeat:Connect(function(dt)
	if STATE.Destroyed then return end
	STATE.LastFrameDt = dt
	STATE.FrameCount = STATE.FrameCount + 1
	STATE.FrameTimer = STATE.FrameTimer + dt
	if STATE.FrameTimer >= 1 then
		STATE.LastFPS = STATE.FrameCount / STATE.FrameTimer
		STATE.FrameCount, STATE.FrameTimer = 0, 0
	end
	AnimationTick(dt)
	ParticleAcc = ParticleAcc + dt
	if ParticleAcc >= 0.5 and not CONFIG.LowFXMode and not CONFIG.FPSFriendly then
		ParticleAcc = 0
		for _ = 1, math.floor(math.clamp(CONFIG.ParticleDensity, 0, 30) / 10) do SpawnParticle() end
	end
	STATE.FastTimer = STATE.FastTimer + dt
	if STATE.FastTimer >= CONFIG.FastUpdateRate then
		STATE.FastTimer = 0
		if STATE.Open and not STATE.Minimized and not STATE.SettingsOpen then
			pcall(UpdateCharacterCard, GetHumanoid(), GetRootPart())
			pcall(UpdateHealthCard, GetHumanoid())
			pcall(UpdatePlayerInfo)
			pcall(UpdateSessionCard)
		end
	end
	STATE.SlowTimer = STATE.SlowTimer + dt
	if STATE.SlowTimer >= CONFIG.HomeUpdateRate * 4 then
		STATE.SlowTimer = 0
		pcall(UpdateSlowData)
	end
	if EggFarm and EggFarm.Enabled and not STATE.Destroyed then
		if STATE.Open and not STATE.Minimized and not STATE.SettingsOpen and not STATE.EggBusy and CONFIG.EggAutoRefresh > 0 then
			STATE.EggAutoTimer = STATE.EggAutoTimer + dt
			if STATE.EggAutoTimer >= CONFIG.EggAutoRefresh then
				STATE.EggAutoTimer = 0
				EggFarm.Scan()
			end
		end
	end
end))

--==================================================
-- [37] DRAG
--==================================================
local function BindDrag(target, handle, onEnd)
	local drag, si, sa, mv = false, nil, nil, 0
	TrackConnection(handle.InputBegan:Connect(function(i)
		if i.UserInputType ~= Enum.UserInputType.MouseButton1 and i.UserInputType ~= Enum.UserInputType.Touch then return end
		drag, mv = true, 0
		si, sa = i.Position, target.AbsolutePosition
	end))
	TrackConnection(UserInputService.InputChanged:Connect(function(i)
		if not drag then return end
		if i.UserInputType ~= Enum.UserInputType.MouseMovement and i.UserInputType ~= Enum.UserInputType.Touch then return end
		local d = Vector2.new(i.Position.X, i.Position.Y) - Vector2.new(si.X, si.Y)
		mv = math.max(mv, d.Magnitude)
		if mv < CONFIG.DragThreshold then return end
		local np = ClampAbsolute(sa + d, target.AbsoluteSize)
		target.Position = UDim2.fromOffset(np.X, np.Y)
	end))
	TrackConnection(UserInputService.InputEnded:Connect(function(i)
		if not drag then return end
		if i.UserInputType ~= Enum.UserInputType.MouseButton1 and i.UserInputType ~= Enum.UserInputType.Touch then return end
		drag = false
		if onEnd then pcall(onEnd, mv >= CONFIG.DragThreshold) end
	end))
end

--==================================================
-- [38] MINI LOGO
--==================================================
local MINI_SIZE = 72
local MiniLogo = Create("Frame", { Size = UDim2.new(0,MINI_SIZE,0,MINI_SIZE), Position = UDim2.new(0,0,0,0), BackgroundTransparency = 1, Visible = false, Parent = ScreenGui })
local MiniBody = MakeFrame(MiniLogo, UDim2.new(1,0,1,0), nil, GetTheme().Base2, 0.15)
MakeCorner(MiniBody, MINI_SIZE/2)
MakeStroke(MiniBody, GetTheme().Accent, 1.5, 0.2)
local MiniRing = MakeFrame(MiniLogo, UDim2.new(1,-10,1,-10), UDim2.new(0,5,0,5), GetTheme().Accent, 1)
MakeCorner(MiniRing, MINI_SIZE/2)
MakeStroke(MiniRing, GetTheme().Accent2, 1.2, 0.3)
local MiniCore = MakeFrame(MiniLogo, UDim2.new(0,18,0,18), UDim2.new(0.5,-9,0.5,-9), GetTheme().Accent2, 0)
MakeCorner(MiniCore, 9)
local MiniHit = Create("TextButton", { Size = UDim2.new(1,0,1,0), BackgroundTransparency = 1, Text = "", AutoButtonColor = false, ZIndex = 5, Parent = MiniLogo })

--==================================================
-- [39] FLOATING MANAGER
--==================================================
local function SetMainAbsolute(pos, sz)
	local c = ClampAbsolute(pos, sz)
	MainWindow.Position = UDim2.fromOffset(c.X, c.Y)
	MainWindow.Size = UDim2.fromOffset(sz.X, sz.Y)
	STATE.MainPosition = c
end
local function SetMiniAbsolute(pos)
	local vp = GetViewport()
	local x = math.clamp(pos.X, 0, math.max(0, vp.X - MINI_SIZE))
	local y = math.clamp(pos.Y, 0, math.max(0, vp.Y - MINI_SIZE))
	MiniLogo.Position = UDim2.fromOffset(x, y)
	STATE.MiniPosition = Vector2.new(x, y)
end
local function ReadMainAbsolute()
	if MainWindow.AbsoluteSize.X > 0 then return Vector2.new(MainWindow.AbsolutePosition.X, MainWindow.AbsolutePosition.Y) end
	return STATE.MainPosition or ComputeCenteredPosition(ComputeWindowSize())
end
ApplyWindowLayout = function(center)
	if STATE.Destroyed then return end
	local sz = ComputeWindowSize()
	local pos = (center or not STATE.MainPosition) and ComputeCenteredPosition(sz) or ClampAbsolute(STATE.MainPosition, sz)
	SetMainAbsolute(pos, sz)
end

local function ShowMainWindow()
	STATE.Open, STATE.Minimized = true, false
	ScreenGui.Enabled = true
	MainWindow.Visible = true
	MiniLogo.Visible = false
	ApplyWindowLayout(STATE.MainPosition == nil)
end
local function MinimizeToLogo()
	if not STATE.Open then return end
	STATE.Minimized = true
	local mc = ReadMainAbsolute()
	local ms = MainWindow.AbsoluteSize
	SetMiniAbsolute(Vector2.new(mc.X + ms.X/2 - MINI_SIZE/2, mc.Y + ms.Y/2 - MINI_SIZE/2))
	MainWindow.Visible = false
	MiniLogo.Visible = true
	MiniLogo.Size = UDim2.new(0, MINI_SIZE, 0, MINI_SIZE)
end
local function RestoreFromLogo()
	if not STATE.Open then return end
	STATE.Minimized = false
	local mp = STATE.MiniPosition or Vector2.new(0,0)
	local sz = ComputeWindowSize()
	SetMainAbsolute(Vector2.new(mp.X + MINI_SIZE/2 - sz.X/2, mp.Y + MINI_SIZE/2 - sz.Y/2), sz)
	MiniLogo.Visible = false
	MainWindow.Visible = true
end
local DestroyAll

local function SetSettingsVisible(v)
	STATE.SettingsOpen = v
	SettingsScroll.Visible = v
	HomeScroll.Visible = not v
	SettingsBtn.Text = v and "⌂" or "⚙"
end

--==================================================
-- [40] EVENTS
--==================================================
BindDrag(MainWindow, Header, function(w) if w then STATE.MainPosition = ReadMainAbsolute() end end)
BindDrag(MiniLogo, MiniHit, function(w)
	if w then
		local p = MiniLogo.AbsolutePosition
		STATE.MiniPosition = Vector2.new(p.X, p.Y)
	else
		RestoreFromLogo()
	end
end)

SettingsBtn.MouseButton1Click:Connect(function() SetSettingsVisible(not STATE.SettingsOpen) end)
MinimizeBtn.MouseButton1Click:Connect(MinimizeToLogo)
CloseBtn.MouseButton1Click:Connect(function() DestroyAll() end)

--==================================================
-- [41] API
--==================================================
_G.vanz = _G.vanz or {}
_G.vanz.Open = function() if not STATE.Destroyed then ShowMainWindow() return true end return false end
_G.vanz.Hide = function()
	if STATE.Destroyed then return false end
	MainWindow.Visible, MiniLogo.Visible, STATE.Open = false, false, false
	return true
end
_G.vanz.Minimize = function() if not STATE.Destroyed then MinimizeToLogo() return true end return false end
_G.vanz.Restore = function() if not STATE.Destroyed then RestoreFromLogo() return true end return false end
_G.vanz.Toggle = function() if STATE.Open then _G.vanz.Hide() else _G.vanz.Open() end return true end
_G.vanz.SetScale = SetScale
_G.vanz.GetScale = function() return CONFIG.Scale end
_G.vanz.ResetSettings = function()
	for k, v in pairs(DEFAULT_CONFIG_SNAPSHOT) do CONFIG[k] = v end
	ApplyTheme(); ApplyWindowLayout(true); return true
end
_G.vanz.Close = function() return DestroyAll() end
_G.vanz.EggScan = function() if EggFarm.Scan then EggFarm.Scan() end end
_G.vanz.EggCarryAll = function() if EggFarm.CarryAll then EggFarm.CarryAll() end end
_G.vanz.EggStop = function()
	EggFarm.Stop = true
	EggFarm.ClearSpeed()
	STATE.EggBusy = false
end
_G.vanz.EggSetSpeed = function(v) ApplyLiveSpeed(tonumber(v)) end
_G.vanz.EggSetHome = function(x, y, z)
	CONFIG.EggHomeX, CONFIG.EggHomeY, CONFIG.EggHomeZ = x, y, z
	EggHomeLbl.Text = string.format("HOME: %.1f, %.1f, %.1f", x, y, z)
end
_G.vanz.EggSurvive = function()
	local c = LocalPlayer.Character
	if not c then return end
	local h = c:FindFirstChildOfClass("Humanoid")
	if h then
		pcall(function() h.MaxHealth = math.huge; h.Health = math.huge end)
		EggStatusLbl.Text = "God mode attempted (health set to inf)"
	end
end
_G.vanz.EggStats = function()
	return {
		RigWipe = STATE.RigWipeBlocked,
		Health = STATE.HealthBlocked,
		Pos = STATE.PosBlocked,
		Speed = STATE.SpeedBlocked,
		Text = STATE.TextBlocked,
		KilledScripts = #KilledScripts,
	}
end
_G.vanz.KilledScripts = function() return KilledScripts end
_G.vanz.ScrubText = function() pcall(ScrubNotifRoots) return STATE.TextBlocked end

--==================================================
-- [42] DESTROY
--==================================================
DestroyAll = function()
	if STATE.Destroyed then return end
	STATE.Destroyed = true
	STATE.Open, STATE.Minimized = false, false
	EggFarm.Stop = true
	EggFarm.ClearSpeed()
	CleanupAll()
	DisconnectHumanoidEvents()
	if ScreenGui and ScreenGui.Parent then ScreenGui:Destroy() end
	if _G.vanz then
		for _, f in ipairs({"Open","Hide","Minimize","Restore","Toggle","SetScale","ResetSettings","EggScan","EggCarryAll","EggStop"}) do
			_G.vanz[f] = function() return false end
		end
	end
end

--==================================================
-- [43] INIT
--==================================================
local function Init()
	FillProfile()
	BuildSettingsUI()
	ApplyTheme()
	SetSettingsVisible(false)
	ApplyWindowLayout(true)
	ShowMainWindow()
	STATE.Built = true

	ScanAndDisableAC()
	InstallSpeedHook()
	InstallIndexSpoof()
	StartNotifScrubLoop()

	if LocalPlayer.Character then task.defer(BindCharacter, LocalPlayer.Character) end
end
local okI, errI = pcall(Init)
if not okI then warn("[VANZ] Init error:", errI) end

TrackConnection(Camera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
	if STATE.Destroyed then return end
	if STATE.Open and not STATE.Minimized then ApplyWindowLayout(false)
	elseif STATE.Minimized then if STATE.MiniPosition then SetMiniAbsolute(STATE.MiniPosition) end end
end))

TrackConnection(Players.PlayerRemoving:Connect(function(p)
	if p == LocalPlayer then DestroyAll() end
end))