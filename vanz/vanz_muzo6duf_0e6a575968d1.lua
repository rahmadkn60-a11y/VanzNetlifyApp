--==================================================
-- [01] SERVICES
--==================================================
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Stats = game:GetService("Stats")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

--==================================================
-- [02] CONFIG
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

	EggHomeX = 504.4,
	EggHomeY = 70.6,
	EggHomeZ = -365.6,
	EggMinIncome = 0,
	EggAutoRefresh = 3,
	EggMinScanInterval = 3,
	EggWalkSpeed = 800,
	EggWalkTimeout = 30,
	EggReachDistance = 8,
	EggFlyHeight = 0,

	SpeedVFX = true,
	VFXSpeed = 1.5,
	VFXFOVBoost = 20,

	StolenEggFOVBoost = 5,
	StolenEggFOVUp = 0.12,
	StolenEggFOVDown = 0.30,
	StolenEggNotifHold = 1.6,
	StolenEggNotifIn = 0.16,
	StolenEggNotifOut = 0.22,
	StolenEggReplayEnabled = true,
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

local function GetVFXMult()
	local s = tonumber(CONFIG.EggWalkSpeed) or 800
	local base = CONFIG.VFXSpeed or 1.5
	return math.clamp((s / 500) * base, 0.5, 30)
end

--==================================================
-- [02.5] RARITY SYSTEM (v2)
--==================================================
local RARITY = {
	{ name = "Common",    color = Color3.fromRGB(180,180,180), min = 0,       max = 5000,      aliases = {"common","basic","starter","beginner"} },
	{ name = "Uncommon",  color = Color3.fromRGB(90,255,140),  min = 5000,    max = 5e4,       aliases = {"uncommon"} },
	{ name = "Rare",      color = Color3.fromRGB(90,170,255),  min = 5e4,     max = 5e5,       aliases = {"rare"} },
	{ name = "Epic",      color = Color3.fromRGB(190,110,255), min = 5e5,     max = 5e6,       aliases = {"epic"} },
	{ name = "Legendary", color = Color3.fromRGB(255,190,60),  min = 5e6,     max = 5e7,       aliases = {"legendary","royal","king","queen","champion"} },
	{ name = "Mythic",    color = Color3.fromRGB(255,80,130),  min = 5e7,     max = 5e8,       aliases = {"mythic","mythical","phantom"} },
	{ name = "Secret",    color = Color3.fromRGB(0,0,0),       min = math.huge, max = math.huge, aliases = {"secret"} },
	{ name = "Divine",    color = Color3.fromRGB(0,255,230),   min = 5e8,     max = 5e10,      aliases = {"divine","celestial","angelic","godly","holy","saint"} },
	{ name = "Eternal",   color = Color3.fromRGB(255,140,255), min = 5e10,    max = math.huge, aliases = {"eternal","infinity","infinite","omega","ultra"} },
}

local RARITY_BY_NAME = {}
for _, r in ipairs(RARITY) do RARITY_BY_NAME[r.name] = r end

local function GetEggRarity(name, earn, rank, total)
	-- 1) Keyword match (highest tier first so "legendary" beats "rare")
	if name then
		local lc = tostring(name):lower()
		for i = #RARITY, 1, -1 do
			local tier = RARITY[i]
			for _, a in ipairs(tier.aliases) do
				if lc:find(a, 1, true) then return tier end
			end
		end
	end
	-- 2) Percentile rank (auto-adapts to any income scale)
	if rank and total and total >= 6 then
		local pct = rank / total
		if pct <= 0.05 then return RARITY_BY_NAME.Eternal end
		if pct <= 0.12 then return RARITY_BY_NAME.Divine end
		if pct <= 0.22 then return RARITY_BY_NAME.Mythic end
		if pct <= 0.35 then return RARITY_BY_NAME.Legendary end
		if pct <= 0.55 then return RARITY_BY_NAME.Epic end
		if pct <= 0.72 then return RARITY_BY_NAME.Rare end
		if pct <= 0.88 then return RARITY_BY_NAME.Uncommon end
		return RARITY_BY_NAME.Common
	end
	-- 3) Income bands (fallback for small lists)
	local e = tonumber(earn) or 0
	for _, r in ipairs(RARITY) do
		if e >= r.min and e < r.max then return r end
	end
	return RARITY_BY_NAME.Common
end

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
	LastFrameDt = 0,
}

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

local DELIVERY_FAIL_KEYWORDS = {
	"delivery failed",
	"egg was returned",
	"returned to its nest",
	"failed to deliver",
}

local function IsDeliveryFailText(txt)
	if not txt or txt == "" then return false end
	local lower = txt:lower()
	for _, kw in ipairs(DELIVERY_FAIL_KEYWORDS) do
		if lower:find(kw, 1, true) then return true end
	end
	return false
end

local function ScrubDeliveryFail()
	local roots = { LocalPlayer:FindFirstChild("PlayerGui"), CoreGui }
	for _, root in ipairs(roots) do
		if root then
			pcall(function()
				for _, obj in ipairs(root:GetDescendants()) do
					local cls = obj.ClassName
					if cls == "TextLabel" or cls == "TextButton" or cls == "TextBox" then
						local ok, txt = pcall(function() return obj.Text end)
						if ok and IsDeliveryFailText(txt) then
							pcall(function() obj.Visible = false end)
							pcall(function() obj.Text = "" end)
							pcall(function() obj.TextTransparency = 1 end)
							local p = obj.Parent
							if p and p:IsA("GuiObject") then
								pcall(function() p.Visible = false end)
							end
						end
					end
				end
			end)
		end
	end
end

local DeliveryScrubConn = nil
local function StartDeliveryScrub()
	if DeliveryScrubConn then return end
	DeliveryScrubConn = RunService.Heartbeat:Connect(function()
		pcall(ScrubDeliveryFail)
	end)
end
local function StopDeliveryScrub()
	if DeliveryScrubConn then
		pcall(function() DeliveryScrubConn:Disconnect() end)
		DeliveryScrubConn = nil
	end
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
local EggCard = MakeCard(HomeScroll, "EGG FARM", UDim2.new(1,-4,0,600), nil)
EggCard.LayoutOrder = 8

local EggHomeLbl = MakeLabel(EggCard, "HOME: N/A", UDim2.new(1,-24,0,16), UDim2.new(0,12,0,30), FONT_TEXT, 12, COLORS.SubText)
local EggSpeedLbl = MakeLabel(EggCard, "VISUAL:", UDim2.new(0,60,0,32), UDim2.new(0,12,0,52), FONT_BOLD, 13, COLORS.Text)

local EggSigLbl = MakeLabel(EggCard, "sig: probing…", UDim2.new(1,-24,0,14), UDim2.new(0,12,0,88), FONT_TEXT, 10, COLORS.Warn)
local EggStatusLbl = MakeLabel(EggCard, "Ready.", UDim2.new(1,-24,0,14), UDim2.new(0,12,0,102), FONT_TEXT, 11, COLORS.SubText)
local EggCountLbl = MakeLabel(EggCard, "0 eggs", UDim2.new(0,120,0,14), UDim2.new(1,-132,0,102), FONT_BOLD, 11, GetTheme().Accent2, Enum.TextXAlignment.Right)

local EggSpeedInput
EggSpeedInput = MakeTextBox(EggCard, "800", UDim2.new(0,90,0,32), UDim2.new(0,70,0,52), function(text)
	local n = tonumber(text)
	if n and n > 0 then
		CONFIG.EggWalkSpeed = math.floor(n)
		EggStatusLbl.Text = "Visual=" .. CONFIG.EggWalkSpeed
	else
		EggSpeedInput.Text = tostring(CONFIG.EggWalkSpeed)
	end
end, tostring(CONFIG.EggWalkSpeed))

local EggSetHomeBtn = MakeButton(EggCard, "SET HOME", UDim2.new(0,110,0,32), UDim2.new(0,170,0,52), nil)
local EggScanBtn = MakeButton(EggCard, "SCAN", UDim2.new(0,80,0,32), UDim2.new(0,286,0,52), nil)
local EggCarryAllBtn = MakeButton(EggCard, "CARRY ALL", UDim2.new(0,110,0,32), UDim2.new(0,372,0,52), nil)
local EggStopBtn = MakeButton(EggCard, "STOP", UDim2.new(0,80,0,32), UDim2.new(0,488,0,52), nil)
EggSetHomeBtn.TextSize, EggScanBtn.TextSize, EggCarryAllBtn.TextSize, EggStopBtn.TextSize = 12, 12, 12, 12

local EggListScroll = Create("ScrollingFrame", { Size = UDim2.new(1,-20,0,460), Position = UDim2.new(0,10,0,124), BackgroundColor3 = COLORS.Track, BackgroundTransparency = 0.5, BorderSizePixel = 0, ScrollBarThickness = 4, ScrollBarImageColor3 = GetTheme().Accent, CanvasSize = UDim2.new(0,0,0,0), ScrollingDirection = Enum.ScrollingDirection.Y, ElasticBehavior = Enum.ElasticBehavior.Never, Parent = EggCard })
MakeCorner(EggListScroll, 8)
local EggListLayout = Create("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0,3), Parent = EggListScroll })
Create("UIPadding", { PaddingLeft = UDim.new(0,4), PaddingRight = UDim.new(0,4), PaddingTop = UDim.new(0,4), PaddingBottom = UDim.new(0,4), Parent = EggListScroll })

--==================================================
-- [21] EGG FARM ENGINE
--==================================================
local EggFarm = {}
local RS = game:GetService("ReplicatedStorage")
local PKGS = RS:FindFirstChild("Packages")
local NET = PKGS and PKGS:FindFirstChild("Networking")

do
	if NET then
		EggFarm.RF_SNAP     = NET:FindFirstChild("RF/EggWorld/AskFieldEggSnapshot")
		EggFarm.RF_CARRY    = NET:FindFirstChild("RF/EggWorld/AskFieldEggCarry")
		EggFarm.RF_DOFF     = NET:FindFirstChild("RF/EggWorld/AskDoffTool")
		EggFarm.RE_TRIGGER  = NET:FindFirstChild("RE/ToolTrigger/Trigger")
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

--== VISUAL WALK SYSTEM ==
local VisualWalk = {}
VisualWalk.Phantom       = nil
VisualWalk.CamConn       = nil
VisualWalk.SyncConn      = nil
VisualWalk.Active        = false
VisualWalk._savedCamType = nil

function VisualWalk:_GetSpeed()
	return math.clamp(tonumber(CONFIG.EggWalkSpeed) or 800, 1, 99999)
end

function VisualWalk:_EnsurePhantom()
	if self.Phantom and self.Phantom.Parent then return true end
	local char = LocalPlayer.Character
	if not char then return false end
	local hrp = char:FindFirstChild("HumanoidRootPart")
	if not hrp then return false end
	local p        = Instance.new("Part")
	p.Name         = "VANZ_Phantom"
	p.Size         = Vector3.new(2, 5, 1)
	p.Transparency = 1
	p.Anchored     = true
	p.CanCollide   = false
	p.CanQuery     = false
	p.CanTouch     = false
	p.Massless     = true
	p.CastShadow   = false
	p.CFrame       = hrp.CFrame
	p.Parent       = workspace
	self.Phantom   = p
	return true
end

function VisualWalk:_StartCamera()
	local cam = workspace.CurrentCamera
	if not cam then return end
	if self.CamConn then
		pcall(function() self.CamConn:Disconnect() end)
		self.CamConn = nil
	end
	self._savedCamType = cam.CameraType
	cam.CameraType = Enum.CameraType.Scriptable

	self.CamConn = RunService.RenderStepped:Connect(function()
		if not self.Active then return end
		local ph = self.Phantom
		if not ph or not ph.Parent then return end
		cam.CameraType = Enum.CameraType.Scriptable
		local look = cam.CFrame.LookVector
		local flat = Vector3.new(look.X, 0, look.Z)
		local mag  = flat.Magnitude
		flat = mag > 0.001 and flat / mag or Vector3.new(0, 0, -1)
		cam.CFrame = CFrame.lookAt(
			ph.Position + Vector3.new(0, 8, 0) - flat * 14,
			ph.Position + Vector3.new(0, 3, 0)
		)
	end)

	if self.SyncConn then
		pcall(function() self.SyncConn:Disconnect() end)
		self.SyncConn = nil
	end
	self.SyncConn = RunService.Heartbeat:Connect(function()
		if not self.Active then return end
		local ph = self.Phantom
		local char = LocalPlayer.Character
		local hrp = char and char:FindFirstChild("HumanoidRootPart")
		if ph and ph.Parent and hrp then
			hrp.CFrame = ph.CFrame
		end
	end)
end

function VisualWalk:_StopCamera()
	if self.CamConn then
		pcall(function() self.CamConn:Disconnect() end)
		self.CamConn = nil
	end
	if self.SyncConn then
		pcall(function() self.SyncConn:Disconnect() end)
		self.SyncConn = nil
	end
	local cam = workspace.CurrentCamera
	if cam then
		pcall(function()
			cam.CameraType = self._savedCamType or Enum.CameraType.Custom
		end)
	end
end

function VisualWalk:MoveTo(targetPos)
	if not self:_EnsurePhantom() then return false end
	if not self.Active then
		self.Active = true
		self:_StartCamera()
	end
	local ph = self.Phantom
	if not ph or not ph.Parent then return false end
	local startPos = ph.Position
	local endPos = Vector3.new(targetPos.X, targetPos.Y + 2.5, targetPos.Z)
	local dist   = (endPos - startPos).Magnitude

	local lookTarget = Vector3.new(endPos.X, startPos.Y, endPos.Z)
	local targetCFrame
	if (lookTarget - startPos).Magnitude > 0.001 then
		targetCFrame = CFrame.lookAt(endPos, lookTarget)
	else
		local _, yaw, _ = ph.CFrame:ToOrientation()
		targetCFrame = CFrame.new(endPos) * CFrame.Angles(0, yaw, 0)
	end

	if dist < 0.5 then
		ph.CFrame = targetCFrame
		return true
	end

	local dur = math.clamp(dist / self:_GetSpeed(), 0.03, 30)

	local tw = TweenService:Create(
		ph,
		TweenInfo.new(dur, Enum.EasingStyle.Linear, Enum.EasingDirection.Out),
		{ CFrame = targetCFrame }
	)

	local completed = false
	local conn
	conn = tw.Completed:Connect(function()
		completed = true
		if conn then conn:Disconnect() end
	end)

	tw:Play()

	local startTime = os.clock()
	while not completed and (os.clock() - startTime) < (dur + 1) do
		if STATE.Destroyed or EggFarm.Stop then
			tw:Cancel()
			if conn then conn:Disconnect() end
			return false
		end
		task.wait(0.03)
	end

	return completed or (ph.Position - endPos).Magnitude < 2
end

function VisualWalk:Stop()
	self.Active = false
	self:_StopCamera()
	if self.Phantom and self.Phantom.Parent then
		self.Phantom:Destroy()
	end
	self.Phantom = nil
end

--== WALK ==
EggFarm.WalkTo = function(targetPos, timeout)
	if STATE.Destroyed or EggFarm.Stop then return false end
	local char = LocalPlayer.Character
	if not char or not char:FindFirstChild("HumanoidRootPart") then return false end
	return VisualWalk:MoveTo(targetPos)
end

--== LOCAL CARRY VISUAL ==
-- Dibuat sendiri. Tidak membaca, mencari, atau mengaktifkan GUI bawaan game.
-- Visual muncul segera setelah karakter sampai di posisi telur.
local CarryVisual = {}
CarryVisual.Gui = nil
CarryVisual.EggModel = nil
CarryVisual.EggWeld = nil
CarryVisual.RunFrame = nil
CarryVisual.DropButton = nil
CarryVisual.Visible = false

local function CarrySafeDestroy(obj)
	if obj then pcall(function() obj:Destroy() end) end
end

function CarryVisual:_GetPlayerGui()
	return LocalPlayer and LocalPlayer:FindFirstChildOfClass("PlayerGui")
end

function CarryVisual:_CreateGui()
	local pg = self:_GetPlayerGui()
	if not pg then return false end
	if self.Gui and self.Gui.Parent then return true end

	local old = pg:FindFirstChild("VANZ_CARRY_VISUAL")
	if old then CarrySafeDestroy(old) end

	local gui = Instance.new("ScreenGui")
	gui.Name = "VANZ_CARRY_VISUAL"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.DisplayOrder = 10020
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.Enabled = false
	gui.Parent = pg

	-- Patokan GUI dump: Run/Blur di bagian atas.
	local run = Instance.new("Frame")
	run.Name = "Run"
	run.AnchorPoint = Vector2.new(0.5, 0.5)
	run.Position = UDim2.new(0.5, 0, 0.075, 0)
	run.Size = UDim2.new(0.212128, 0, 0.10192, 0)
	run.BackgroundColor3 = Color3.fromRGB(80, 0, 1)
	run.BackgroundTransparency = 0.04
	run.BorderSizePixel = 0
	run.ZIndex = 10
	run.Parent = gui

	local blur = Instance.new("ImageLabel")
	blur.Name = "Blur"
	blur.Size = UDim2.new(1, 0, 1, 0)
	blur.Position = UDim2.new(0.5, 0, 0.5, 0)
	blur.AnchorPoint = Vector2.new(0.5, 0.5)
	blur.BackgroundTransparency = 1
	blur.Image = "rbxassetid://92781008886078"
	blur.ImageTransparency = 0.63
	blur.ScaleType = Enum.ScaleType.Stretch
	blur.ZIndex = 10
	blur.Parent = run

	local runText = Instance.new("TextLabel")
	runText.Name = "TextLabel"
	runText.Size = UDim2.new(1, 0, 1, 0)
	runText.Position = UDim2.new(0.5, 0, 0.5, 0)
	runText.AnchorPoint = Vector2.new(0.5, 0.5)
	runText.BackgroundTransparency = 1
	runText.Text = "RUN!!"
	runText.TextColor3 = Color3.fromRGB(255, 255, 255)
	runText.TextScaled = true
	runText.Font = Enum.Font.GothamBlack
	runText.ZIndex = 11
	runText.Parent = run

	local runStroke = Instance.new("UIStroke")
	runStroke.Color = Color3.fromRGB(0, 0, 0)
	runStroke.Thickness = 2
	runStroke.Transparency = 0.2
	runStroke.Parent = runText

	-- Patokan GUI dump: Drop button di bawah-tengah.
	local drop = Instance.new("ImageButton")
	drop.Name = "Drop"
	drop.AnchorPoint = Vector2.new(0.5, 0.5)
	drop.Position = UDim2.new(0.4999, 0, 0.850655, 0)
	drop.Size = UDim2.new(0.146576, 0, 0.109771, 25)
	drop.BackgroundTransparency = 1
	drop.BorderSizePixel = 0
	drop.Image = "rbxassetid://126875624960627"
	drop.ImageColor3 = Color3.fromRGB(255, 255, 255)
	drop.ScaleType = Enum.ScaleType.Slice
	drop.SliceCenter = Rect.new(20, 20, 80, 80)
	drop.ZIndex = 10
	drop.Parent = gui

	local dropIcon = Instance.new("ImageLabel")
	dropIcon.Name = "Icon"
	dropIcon.Size = UDim2.new(0.7, 0, 0.6, 0)
	dropIcon.Position = UDim2.new(0.243623, 0, 0.5, 0)
	dropIcon.AnchorPoint = Vector2.new(0.5, 0.5)
	dropIcon.BackgroundTransparency = 1
	dropIcon.Image = "rbxassetid://101853655799130"
	dropIcon.ScaleType = Enum.ScaleType.Fit
	dropIcon.ZIndex = 11
	dropIcon.Parent = drop

	local dropText = Instance.new("TextLabel")
	dropText.Name = "TextLabel"
	dropText.Size = UDim2.new(0.733799, 0, 0.6, 0)
	dropText.Position = UDim2.new(0.583101, 0, 0.5, 0)
	dropText.AnchorPoint = Vector2.new(0.5, 0.5)
	dropText.BackgroundTransparency = 1
	dropText.Text = "Drop"
	dropText.TextColor3 = Color3.fromRGB(255, 255, 255)
	dropText.TextScaled = true
	dropText.Font = Enum.Font.GothamBold
	dropText.ZIndex = 11
	dropText.Parent = drop

	self.Gui = gui
	self.RunFrame = run
	self.DropButton = drop
	return true
end

function CarryVisual:_CreateEgg(eggData)
	local char = LocalPlayer.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	local hand = char and (char:FindFirstChild("RightHand") or char:FindFirstChild("Right Arm"))
	local anchor = hand or hrp
	if not anchor or not hrp then return false end

	self:HideEgg()

	local model = Instance.new("Model")
	model.Name = "VANZ_CARRIED_EGG"

	local shell = Instance.new("Part")
	shell.Name = "Egg"
	shell.Shape = Enum.PartType.Ball
	shell.Size = Vector3.new(1.15, 1.45, 1.15)
	shell.Material = Enum.Material.SmoothPlastic
	shell.Color = Color3.fromRGB(245, 245, 245)
	shell.CanCollide = false
	shell.CanTouch = false
	shell.CanQuery = false
	shell.Massless = true
	shell.CastShadow = false
	shell.Parent = model

	local mesh = Instance.new("SpecialMesh")
	mesh.MeshType = Enum.MeshType.Sphere
	mesh.Scale = Vector3.new(0.78, 1.05, 0.78)
	mesh.Parent = shell

	local rarity = eggData and eggData.rarity
	local rarityColor = rarity and rarity.color or Color3.fromRGB(255, 210, 90)

	local glow = Instance.new("Part")
	glow.Name = "RarityGlow"
	glow.Shape = Enum.PartType.Ball
	glow.Size = Vector3.new(1.28, 1.58, 1.28)
	glow.Material = Enum.Material.Neon
	glow.Color = rarityColor
	glow.Transparency = 0.82
	glow.CanCollide = false
	glow.CanTouch = false
	glow.CanQuery = false
	glow.Massless = true
	glow.CastShadow = false
	glow.Parent = model

	local glowMesh = Instance.new("SpecialMesh")
	glowMesh.MeshType = Enum.MeshType.Sphere
	glowMesh.Scale = Vector3.new(0.78, 1.05, 0.78)
	glowMesh.Parent = glow

	local weldGlow = Instance.new("WeldConstraint")
	weldGlow.Part0 = shell
	weldGlow.Part1 = glow
	weldGlow.Parent = glow

	model.PrimaryPart = shell
	model.Parent = char

	if anchor == hand then
		shell.CFrame = hand.CFrame * CFrame.new(0, -0.65, -0.45)
	else
		shell.CFrame = hrp.CFrame * CFrame.new(0, 0.15, -1.55)
	end
	glow.CFrame = shell.CFrame

	local weld = Instance.new("WeldConstraint")
	weld.Name = "CarryWeld"
	weld.Part0 = anchor
	weld.Part1 = shell
	weld.Parent = shell

	self.EggModel = model
	self.EggWeld = weld
	return true
end

function CarryVisual:HideEgg()
	if self.EggModel then
		CarrySafeDestroy(self.EggModel)
		self.EggModel = nil
		self.EggWeld = nil
	end
end

function CarryVisual:Show(eggData)
	if not self:_CreateGui() then return false end
	if not self:_CreateEgg(eggData) then return false end

	self.Visible = true
	self.Gui.Enabled = true
	self.RunFrame.BackgroundTransparency = 1
	self.DropButton.ImageTransparency = 1

	local runText = self.RunFrame:FindFirstChild("TextLabel")
	local blur = self.RunFrame:FindFirstChild("Blur")
	local dropText = self.DropButton:FindFirstChild("TextLabel")
	local dropIcon = self.DropButton:FindFirstChild("Icon")
	if runText then runText.TextTransparency = 1 end
	if blur then blur.ImageTransparency = 1 end
	if dropText then dropText.TextTransparency = 1 end
	if dropIcon then dropIcon.ImageTransparency = 1 end

	local info = TweenInfo.new(0.14, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
	TweenService:Create(self.RunFrame, info, {BackgroundTransparency = 0.04}):Play()
	TweenService:Create(self.DropButton, info, {ImageTransparency = 0}):Play()
	if runText then TweenService:Create(runText, info, {TextTransparency = 0}):Play() end
	if blur then TweenService:Create(blur, info, {ImageTransparency = 0.63}):Play() end
	if dropText then TweenService:Create(dropText, info, {TextTransparency = 0}):Play() end
	if dropIcon then TweenService:Create(dropIcon, info, {ImageTransparency = 0}):Play() end
	return true
end

function CarryVisual:Hide()
	self.Visible = false
	self:HideEgg()
	if not self.Gui then return end

	local runText = self.RunFrame and self.RunFrame:FindFirstChild("TextLabel")
	local blur = self.RunFrame and self.RunFrame:FindFirstChild("Blur")
	local dropText = self.DropButton and self.DropButton:FindFirstChild("TextLabel")
	local dropIcon = self.DropButton and self.DropButton:FindFirstChild("Icon")
	local info = TweenInfo.new(0.10, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
	if self.RunFrame then TweenService:Create(self.RunFrame, info, {BackgroundTransparency = 1}):Play() end
	if self.DropButton then TweenService:Create(self.DropButton, info, {ImageTransparency = 1}):Play() end
	if runText then TweenService:Create(runText, info, {TextTransparency = 1}):Play() end
	if blur then TweenService:Create(blur, info, {ImageTransparency = 1}):Play() end
	if dropText then TweenService:Create(dropText, info, {TextTransparency = 1}):Play() end
	if dropIcon then TweenService:Create(dropIcon, info, {ImageTransparency = 1}):Play() end

	task.delay(0.12, function()
		if self.Gui and self.Gui.Parent and not self.Visible then
			self.Gui.Enabled = false
		end
	end)
end

function CarryVisual:Destroy()
	self:HideEgg()
	if self.Gui then CarrySafeDestroy(self.Gui) end
	self.Gui = nil
	self.RunFrame = nil
	self.DropButton = nil
	self.Visible = false
end

--==================================================
-- [21.2] STOLEN EGG REPLAY + FOV (v3)
-- Top-center stacked notification card, modeled after
-- the notification style shown in the reference video.
-- IMPORTANT: this module never reuses the game's one-slot
-- MsgNotif. Every trigger creates an independent card.
--==================================================
local StolenEgg = {}
StolenEgg._fovBusy = false
StolenEgg._fovSaved = nil
StolenEgg._fovTween = nil
StolenEgg._gui = nil
StolenEgg._notifStack = {}
-- Cache is PER EGG, never one global icon.
StolenEgg._iconCache = {}

local function HexFromColor(c)
	return string.format("#%02X%02X%02X",
		math.floor(c.R * 255 + 0.5),
		math.floor(c.G * 255 + 0.5),
		math.floor(c.B * 255 + 0.5))
end

local function SafeDestroy(x)
	if x then pcall(function() x:Destroy() end) end
end

local function AddCorner(obj, radius)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, radius or 8)
	c.Parent = obj
	return c
end

local function AddStroke(obj, color, transparency, thickness)
	local s = Instance.new("UIStroke")
	s.Color = color or Color3.fromRGB(55, 55, 55)
	s.Transparency = transparency or 0.2
	s.Thickness = thickness or 1
	s.Parent = obj
	return s
end

local function GetPlayerGui()
	return LocalPlayer and LocalPlayer:FindFirstChildOfClass("PlayerGui")
end

local function NormalizeEggName(value)
	local s = tostring(value or ""):lower()
	s = s:gsub("[%s%p_]+", "")
	return s
end

local function NormalizeImageId(value)
	local kind = typeof(value)

	if kind == "number" then
		if value > 0 then
			return "rbxassetid://" .. tostring(math.floor(value))
		end
		return nil
	end

	if kind ~= "string" then
		return nil
	end

	local s = value:match("^%s*(.-)%s*$")
	if s == "" or s == "0" or s == "rbxassetid://0" then
		return nil
	end

	if s:match("^%d+$") then
		return "rbxassetid://" .. s
	end

	if s:find("rbxassetid://", 1, true) then
		return s
	end

	if s:find("rbxthumb://", 1, true) or s:find("rbxgameasset://", 1, true) then
		return s
	end

	return nil
end

local function FindImageIdInTable(value, depth, seen)
	if depth > 4 or type(value) ~= "table" then return nil end

	seen = seen or {}
	if seen[value] then return nil end
	seen[value] = true

	for key, v in pairs(value) do
		local keyName = tostring(key):lower()

		local imageKey =
			keyName == "icon"
			or keyName == "iconid"
			or keyName == "icon_id"
			or keyName == "image"
			or keyName == "imageid"
			or keyName == "image_id"
			or keyName == "texture"
			or keyName == "textureid"
			or keyName == "texture_id"
			or keyName == "thumbnail"
			or keyName == "thumbnailid"
			or keyName == "thumbnail_id"

		if imageKey then
			local id = NormalizeImageId(v)
			if id then return id end
		end

		if type(v) == "table" then
			local id = FindImageIdInTable(v, depth + 1, seen)
			if id then return id end
		end
	end

	return nil
end

local function GetNamedConfigModule(eggName)
	local data = RS and RS:FindFirstChild("Data")
	local assets = data and data:FindFirstChild("Assets")
	local configs = assets and assets:FindFirstChild("Configs")
	if not configs then return nil end

	local wanted = tostring(eggName or ""):lower()
	local wantedNorm = NormalizeEggName(eggName)

	for _, obj in ipairs(configs:GetDescendants()) do
		if obj:IsA("ModuleScript") then
			local n = tostring(obj.Name):lower()
			if n == wanted or NormalizeEggName(n) == wantedNorm then
				return obj
			end
		end
	end

	for _, obj in ipairs(configs:GetDescendants()) do
		if obj:IsA("ModuleScript") then
			local n = NormalizeEggName(obj.Name)
			if wantedNorm ~= "" and (n:find(wantedNorm, 1, true) or wantedNorm:find(n, 1, true)) then
				return obj
			end
		end
	end

	return nil
end

local function TryConfigEggIcon(eggName)
	local module = GetNamedConfigModule(eggName)
	if not module then return nil end

	local ok, data = pcall(require, module)
	if not ok then return nil end

	return FindImageIdInTable(data, 0)
end

local function InstanceNameMatchesEgg(obj, eggName)
	local wanted = NormalizeEggName(eggName)
	if wanted == "" then return false end

	local cur = obj
	for _ = 1, 5 do
		if not cur then break end
		local n = NormalizeEggName(cur.Name)
		if n == wanted or n:find(wanted, 1, true) or wanted:find(n, 1, true) then
			return true
		end
		cur = cur.Parent
	end

	return false
end

local function TryInstanceEggIcon(root, eggName)
	if not root then return nil end

	for _, d in ipairs(root:GetDescendants()) do
		if InstanceNameMatchesEgg(d, eggName) then
			if d:IsA("ImageLabel") or d:IsA("ImageButton") then
				local ok, image = pcall(function() return d.Image end)
				if ok then
					local id = NormalizeImageId(image)
					if id then return id end
				end
			elseif d:IsA("Decal") or d:IsA("Texture") then
				local ok, image = pcall(function() return d.Texture end)
				if ok then
					local id = NormalizeImageId(image)
					if id then return id end
				end
			elseif d:IsA("SpecialMesh") then
				local ok, image = pcall(function() return d.TextureId end)
				if ok then
					local id = NormalizeImageId(image)
					if id then return id end
				end
			elseif d:IsA("MeshPart") then
				local ok, image = pcall(function() return d.TextureID end)
				if ok then
					local id = NormalizeImageId(image)
					if id then return id end
				end
			end
		end
	end

	return nil
end

local function TryFindEggIcon(eggName)
	local wanted = tostring(eggName or "")
	if wanted == "" then return nil end

	local cached = StolenEgg._iconCache[wanted]
	if cached then return cached end

	local id = TryConfigEggIcon(wanted)
	if id then
		StolenEgg._iconCache[wanted] = id
		return id
	end

	local data = RS and RS:FindFirstChild("Data")
	local assets = data and data:FindFirstChild("Assets")
	id = TryInstanceEggIcon(assets, wanted)
	if id then
		StolenEgg._iconCache[wanted] = id
		return id
	end

	local pg = GetPlayerGui()
	id = TryInstanceEggIcon(pg, wanted)
	if id then
		StolenEgg._iconCache[wanted] = id
		return id
	end

	local backpack = LocalPlayer and LocalPlayer:FindFirstChildOfClass("Backpack")
	local char = LocalPlayer and LocalPlayer.Character
	for _, container in ipairs({backpack, char}) do
		if container then
			for _, tool in ipairs(container:GetChildren()) do
				if tool:IsA("Tool") then
					local toolName = NormalizeEggName(tool.Name)
					local wantedNorm = NormalizeEggName(wanted)
					if toolName == wantedNorm
						or toolName:find(wantedNorm, 1, true)
						or wantedNorm:find(toolName, 1, true) then
						local toolId = NormalizeImageId(tool.TextureId)
						if toolId then
							StolenEgg._iconCache[wanted] = toolId
							return toolId
						end
					end
				end
			end
		end
	end

	-- Do not cache a miss: the correct icon may only appear after pickup.
	return nil
end

function StolenEgg:EnsureGui()
	if self._gui and self._gui.Parent then return self._gui end

	local pg = GetPlayerGui()
	if not pg then return nil end

	local old = pg:FindFirstChild("VANZ_STOLEN_EGG_NOTIF")
	if old then SafeDestroy(old) end

	local sg = Instance.new("ScreenGui")
	sg.Name = "VANZ_STOLEN_EGG_NOTIF"
	sg.ResetOnSpawn = false
	sg.IgnoreGuiInset = true
	sg.DisplayOrder = 10000
	sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	sg.Parent = pg

	self._gui = sg
	self._notifStack = {}
	return sg
end

function StolenEgg:Reflow()
	local stack = self._notifStack or {}

	for i = #stack, 1, -1 do
		local item = stack[i]
		if not item or not item.card or not item.card.Parent then
			table.remove(stack, i)
		end
	end

	-- Newest message stays at the bottom. Older messages move upward.
	local baseY = -32
	local step = 28

	for index, item in ipairs(stack) do
		local target = UDim2.new(
			0.5,
			0,
			0.93,
			baseY - ((index - 1) * step)
		)

		pcall(function()
			TweenService:Create(
				item.card,
				TweenInfo.new(0.12, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
				{Position = target}
			):Play()
		end)
	end
end

function StolenEgg:Remove(item, immediate)
	if not item then return end

	for i = #self._notifStack, 1, -1 do
		if self._notifStack[i] == item then
			table.remove(self._notifStack, i)
			break
		end
	end

	if item.card and item.card.Parent then
		if immediate then
			SafeDestroy(item.card)
		else
			pcall(function()
				TweenService:Create(
					item.card,
					TweenInfo.new(CONFIG.StolenEggNotifOut or 0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
					{BackgroundTransparency = 1}
				):Play()
			end)
			task.delay((CONFIG.StolenEggNotifOut or 0.35) + 0.05, function()
				SafeDestroy(item.card)
			end)
		end
	end

	self:Reflow()
end

function StolenEgg:Show(rarity, eggName)
	if not CONFIG.StolenEggReplayEnabled then return end

	local rarityData = rarity
	if type(rarityData) ~= "table" or typeof(rarityData.color) ~= "Color3" then
		local rarityName = type(rarity) == "string" and rarity:lower() or "common"
		for _, tier in ipairs(RARITY) do
			if tostring(tier.name):lower() == rarityName then
				rarityData = tier
				break
			end
		end
	end

	rarityData = rarityData or RARITY_BY_NAME.Common
	local rarityColor = rarityData.color or RARITY_BY_NAME.Common.color

	local sg = self:EnsureGui()
	if not sg then return end

	-- Build the sentence from THREE separate TextLabels.
	-- This guarantees the EGG text uses rarityColor directly;
	-- no RichText parsing is involved.
	local message = Instance.new("Frame")
	message.Name = "StolenEggMessage"
	message.AnchorPoint = Vector2.new(0.5, 1)
	message.Position = UDim2.new(0.5, 0, 0.93, -24)
	message.Size = UDim2.new(0, 420, 0, 34)
	message.BackgroundTransparency = 1
	message.BorderSizePixel = 0
	message.ZIndex = 100
	message.Parent = sg

	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Horizontal
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.VerticalAlignment = Enum.VerticalAlignment.Center
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Padding = UDim.new(0, 0)
	layout.Parent = message

	local function makePart(name, text, textColor, order)
		local label = Instance.new("TextLabel")
		label.Name = name
		label.LayoutOrder = order
		label.AutomaticSize = Enum.AutomaticSize.X
		label.Size = UDim2.new(0, 0, 0, 30)
		label.BackgroundTransparency = 1
		label.BorderSizePixel = 0
		label.Text = text
		label.TextColor3 = textColor
		label.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
		label.TextStrokeTransparency = 1
		label.TextTransparency = 1
		label.TextSize = 18
		label.TextScaled = false
		label.TextWrapped = false
		label.TextXAlignment = Enum.TextXAlignment.Center
		label.TextYAlignment = Enum.TextYAlignment.Center
		label.Font = Enum.Font.GothamBold
		label.ZIndex = 101
		label.Parent = message
		return label
	end

	local left = makePart("Left", "You stole an ", Color3.fromRGB(255, 255, 255), 1)
	local egg = makePart("EGG", "EGG", rarityColor, 2)
	local right = makePart("Right", "!", Color3.fromRGB(255, 255, 255), 3)

	local item = {
		card = message,
		labels = {left, egg, right},
		created = os.clock(),
	}

	self._notifStack = self._notifStack or {}
	table.insert(self._notifStack, 1, item)

	while #self._notifStack > 8 do
		local old = table.remove(self._notifStack)
		self:Remove(old, true)
	end

	local inT = CONFIG.StolenEggNotifIn or 0.16
	local hold = CONFIG.StolenEggNotifHold or 1.6
	local outT = CONFIG.StolenEggNotifOut or 0.22

	pcall(function()
		TweenService:Create(
			message,
			TweenInfo.new(inT, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
			{Position = UDim2.new(0.5, 0, 0.93, -32)}
		):Play()
	end)

	for _, label in ipairs(item.labels) do
		pcall(function()
			TweenService:Create(
				label,
				TweenInfo.new(inT, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
				{TextTransparency = 0, TextStrokeTransparency = 0}
			):Play()
		end)
	end

	self:Reflow()

	task.delay(inT + hold, function()
		if not item.card or not item.card.Parent then return end

		for _, label in ipairs(item.labels) do
			pcall(function()
				TweenService:Create(
					label,
					TweenInfo.new(outT, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
					{TextTransparency = 1, TextStrokeTransparency = 1}
				):Play()
			end)
		end

		pcall(function()
			TweenService:Create(
				message,
				TweenInfo.new(outT, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
				{Position = UDim2.new(0.5, 0, 0.93, -24)}
			):Play()
		end)

		task.delay(outT + 0.04, function()
			self:Remove(item, true)
		end)
	end)
end

function StolenEgg:BoostFOV()
	if CONFIG.LowFXMode or CONFIG.DisableHeavyAnimation then return end
	if not Camera then return end
	if self._fovBusy then return end
	self._fovBusy = true

	if self._fovSaved == nil then
		self._fovSaved = Camera.FieldOfView
	end

	local base = self._fovSaved
	local target = math.min(120, base + (CONFIG.StolenEggFOVBoost or 8))

	if self._fovTween then
		pcall(function() self._fovTween:Cancel() end)
	end

	self._fovTween = TweenService:Create(
		Camera,
		TweenInfo.new(CONFIG.StolenEggFOVUp or 0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{FieldOfView = target}
	)
	pcall(function() self._fovTween:Play() end)

	task.delay(CONFIG.StolenEggFOVUp or 0.18, function()
		if not Camera then
			self._fovBusy = false
			return
		end

		if self._fovTween then
			pcall(function() self._fovTween:Cancel() end)
		end

		self._fovTween = TweenService:Create(
			Camera,
			TweenInfo.new(CONFIG.StolenEggFOVDown or 0.45, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{FieldOfView = base}
		)
		pcall(function() self._fovTween:Play() end)

		task.delay(CONFIG.StolenEggFOVDown or 0.45, function()
			self._fovBusy = false
		end)
	end)
end

function StolenEgg:Trigger(name, earn, explicitRarity)
	local eggName = tostring(name or "EGG")
	local rarity = explicitRarity or GetEggRarity(eggName, earn)
	self:Show(rarity, eggName)
	self:BoostFOV()
end

--==================================================
-- [21.5] SPEED VFX MODULE (VISUAL ONLY)
--==================================================
local VFX = {}
VFX.Enabled = CONFIG.SpeedVFX
VFX.TrailOn = false
VFX.AuraOn = false
VFX.TrailParts = {}
VFX.MaxTrailParts = 120
VFX.TrailLifetime = 0.45
VFX.TrailInterval = 0.02
VFX._spawnAcc = 0
VFX._spawnConn = nil
VFX._fovSaved = nil
VFX._fovTween = nil
VFX._shakeConn = nil
VFX._shakeAmp = 0

function VFX:InitFolder()
	if VFX.Folder and VFX.Folder.Parent then return end
	local cam = workspace.CurrentCamera
	if not cam then return end
	local f = Instance.new("Folder")
	f.Name = "VANZ_SPEED_VFX"
	f.Parent = cam
	VFX.Folder = f
end

function VFX:EnsureSpeedLines()
	if VFX.SpeedLinesGui and VFX.SpeedLinesGui.Parent then return end
	local sg = Instance.new("ScreenGui")
	sg.Name = "VANZ_SPEED_LINES"
	sg.ResetOnSpawn = false
	sg.IgnoreGuiInset = true
	sg.DisplayOrder = 9998
	sg.ZIndexBehavior = Enum.ZIndexBehavior.Global
	pcall(function() sg.Parent = PlayerGui end)
	if not sg.Parent then sg.Parent = CoreGui end
	VFX.SpeedLinesGui = sg
	VFX._lines = {}
end

function VFX:SpawnTrailPart()
	if not VFX.TrailOn or not VFX.Enabled then return end
	if CONFIG.LowFXMode or CONFIG.DisableParticles then return end
	local char = LocalPlayer.Character
	if not char then return end
	local hrp = char:FindFirstChild("HumanoidRootPart")
	if not hrp then return end
	VFX:InitFolder()
	if not VFX.Folder then return end

	local m = GetVFXMult()
	local part = Instance.new("Part")
	part.Size = Vector3.new(2.6, 3.6, 2.6)
	part.CFrame = hrp.CFrame
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.Massless = true
	part.CastShadow = false
	part.Material = Enum.Material.Neon
	part.Color = GetTheme().Accent2
	part.Transparency = 0.15
	part.Parent = VFX.Folder

	table.insert(VFX.TrailParts, part)
	local cap = math.min(VFX.MaxTrailParts, math.floor(30 + m * 18))
	while #VFX.TrailParts > cap do
		local old = table.remove(VFX.TrailParts, 1)
		if old and old.Parent then old:Destroy() end
	end

	local life = VFX.TrailLifetime / math.max(0.6, math.min(m, 8))
	local tw = TweenService:Create(part, TweenInfo.new(life, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Transparency = 1,
		Size = Vector3.new(0.2, 0.2, 0.2),
	})
	pcall(function() tw:Play() end)
	task.delay(life + 0.05, function()
		if part and part.Parent then part:Destroy() end
	end)
end

function VFX:SetTrail(on)
	if VFX.TrailOn == on then return end
	VFX.TrailOn = on
	if not on then
		for _, p in ipairs(VFX.TrailParts) do
			if p and p.Parent then p:Destroy() end
		end
		table.clear(VFX.TrailParts)
		if VFX._spawnConn then
			pcall(function() VFX._spawnConn:Disconnect() end)
			VFX._spawnConn = nil
		end
		VFX._spawnAcc = 0
	end
end

function VFX:BoostFOV()
	if CONFIG.LowFXMode then return end
	if not Camera then return end
	if VFX._fovSaved == nil then
		VFX._fovSaved = Camera.FieldOfView
	end
	local m = GetVFXMult()
	local target = math.min(120, VFX._fovSaved + CONFIG.VFXFOVBoost * math.min(m, 4))
	if VFX._fovTween then pcall(function() VFX._fovTween:Cancel() end) end
	VFX._fovTween = TweenService:Create(Camera, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { FieldOfView = target })
	pcall(function() VFX._fovTween:Play() end)
end

function VFX:RestoreFOV()
	if VFX._fovSaved == nil then return end
	local restore = VFX._fovSaved
	VFX._fovSaved = nil
	if not Camera then return end
	if VFX._fovTween then pcall(function() VFX._fovTween:Cancel() end) end
	VFX._fovTween = TweenService:Create(Camera, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { FieldOfView = restore })
	pcall(function() VFX._fovTween:Play() end)
end

function VFX:StartShake()
	if CONFIG.LowFXMode then return end
	if VFX._shakeConn then return end
	local m = GetVFXMult()
	VFX._shakeAmp = math.min(m, 8) * 0.4
	VFX._shakeConn = RunService.RenderStepped:Connect(function()
		if not Camera or not VFX.TrailOn then return end
		local a = VFX._shakeAmp
		local t = os.clock() * 30
		local ox = math.sin(t) * a * 0.12
		local oy = math.cos(t * 1.3) * a * 0.12
		local oz = math.sin(t * 0.7) * a * 0.08
		Camera.CFrame = Camera.CFrame * CFrame.new(ox, oy, oz)
	end)
end

function VFX:StopShake()
	if VFX._shakeConn then
		pcall(function() VFX._shakeConn:Disconnect() end)
		VFX._shakeConn = nil
	end
	VFX._shakeAmp = 0
end

function VFX:EggPickupFlash(pos)
	if CONFIG.LowFXMode or CONFIG.DisableParticles then return end
	VFX:InitFolder()
	if not VFX.Folder then return end
	local m = GetVFXMult()
	local count = math.floor(24 * math.max(0.5, math.min(m, 15)))
	for i = 1, count do
		local p = Instance.new("Part")
		p.Shape = Enum.PartType.Ball
		p.Size = Vector3.new(0.5, 0.5, 0.5)
		p.CFrame = CFrame.new(pos)
		p.Anchored = true
		p.CanCollide = false
		p.CanQuery = false
		p.CanTouch = false
		p.Massless = true
		p.CastShadow = false
		p.Material = Enum.Material.Neon
		p.Color = Color3.fromRGB(255, 220, 110)
		p.Transparency = 0
		p.Parent = VFX.Folder
		local dir = Vector3.new(math.random() - 0.5, math.random() * 0.6 + 0.3, math.random() - 0.5).Unit
		local dest = pos + dir * math.random(6, 18)
		local life = 0.5 / math.max(0.6, math.min(m, 12))
		local tw = TweenService:Create(p, TweenInfo.new(life, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			CFrame = CFrame.new(dest),
			Transparency = 1,
			Size = Vector3.new(0.05, 0.05, 0.05),
		})
		pcall(function() tw:Play() end)
		task.delay(life + 0.05, function() if p.Parent then p:Destroy() end end)
	end
	VFX:ScreenFlash(Color3.fromRGB(255, 220, 110), 0.55, 0.35)
end

function VFX:ScreenFlash(color, transparency, dur)
	VFX:EnsureSpeedLines()
	if not VFX.SpeedLinesGui then return end
	local flash = Instance.new("Frame")
	flash.Name = "Flash"
	flash.Size = UDim2.new(1,0,1,0)
	flash.BackgroundColor3 = color
	flash.BackgroundTransparency = transparency
	flash.BorderSizePixel = 0
	flash.ZIndex = 500
	flash.Parent = VFX.SpeedLinesGui
	local tw = TweenService:Create(flash, TweenInfo.new(dur, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { BackgroundTransparency = 1 })
	pcall(function() tw:Play() end)
	task.delay(dur + 0.05, function() if flash.Parent then flash:Destroy() end end)
end

function VFX:SetSpeedLines(on)
end

function VFX:TeleportZapHome()
	VFX:EnsureSpeedLines()
	if not VFX.SpeedLinesGui then return end
	local m = GetVFXMult()
	local dur = math.clamp(0.06 / math.max(0.5, m), 0.03, 0.12)
	local zap = Instance.new("Frame")
	zap.Name = "TeleZapHome"
	zap.Size = UDim2.new(1,0,1,0)
	zap.BackgroundColor3 = Color3.fromRGB(0,255,200)
	zap.BackgroundTransparency = 0.3
	zap.BorderSizePixel = 0
	zap.ZIndex = 500
	zap.Parent = VFX.SpeedLinesGui
	local g = Instance.new("UIGradient")
	g.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(0.4, 0),
		NumberSequenceKeypoint.new(0.6, 0),
		NumberSequenceKeypoint.new(1, 1),
	})
	g.Rotation = 90
	g.Parent = zap
	local tw = TweenService:Create(zap, TweenInfo.new(dur, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { BackgroundTransparency = 1 })
	pcall(function() tw:Play() end)
	task.delay(dur + 0.05, function() if zap and zap.Parent then zap:Destroy() end end)
end

function VFX:StartCarryAura()
	if VFX.AuraOn then return end
	VFX.AuraOn = true
	task.spawn(function()
		while VFX.AuraOn do
			if not CONFIG.LowFXMode and not CONFIG.DisableParticles then
				local char = LocalPlayer.Character
				if char then
					local hrp = char:FindFirstChild("HumanoidRootPart")
					if hrp and VFX.Folder then
						local m = GetVFXMult()
						local p = Instance.new("Part")
						p.Shape = Enum.PartType.Ball
						p.Size = Vector3.new(0.4, 0.4, 0.4)
						local dy = 1.2 + math.random() * 2.3
						p.CFrame = hrp.CFrame * CFrame.new(
							(math.random() - 0.5) * 4.5,
							dy,
							(math.random() - 0.5) * 4.5
						)
						p.Anchored = true
						p.CanCollide = false
						p.CanQuery = false
						p.CanTouch = false
						p.Massless = true
						p.CastShadow = false
						p.Material = Enum.Material.Neon
						p.Color = Color3.fromRGB(255, 200, 80)
						p.Transparency = 0.1
						p.Parent = VFX.Folder
						local life = 0.65
						local tw = TweenService:Create(p, TweenInfo.new(life), {
							CFrame = p.CFrame * CFrame.new(0, 2.8, 0),
							Transparency = 1,
						})
						pcall(function() tw:Play() end)
						task.delay(life + 0.05, function() if p.Parent then p:Destroy() end end)
						task.wait(0.05 / math.max(0.6, math.min(m, 10)))
					else
						task.wait(0.1)
					end
				else
					task.wait(0.1)
				end
			else
				task.wait(0.1)
			end
		end
	end)
end

function VFX:StopCarryAura()
	VFX.AuraOn = false
end

function VFX:Begin()
	if not VFX.Enabled then return end
	VFX:InitFolder()
	VFX:EnsureSpeedLines()
	VFX:SetSpeedLines(true)
	VFX:BoostFOV()
	VFX:StartShake()
	if VFX._spawnConn then pcall(function() VFX._spawnConn:Disconnect() end) end
	VFX._spawnAcc = 0
	VFX._spawnConn = RunService.RenderStepped:Connect(function(dt)
		if not VFX.TrailOn then return end
		VFX._spawnAcc = VFX._spawnAcc + dt
		local m = GetVFXMult()
		local interval = VFX.TrailInterval / math.max(0.6, math.min(m, 10))
		if VFX._spawnAcc >= interval then
			VFX._spawnAcc = 0
			VFX:SpawnTrailPart()
		end
	end)
	VFX.TrailOn = true
end

function VFX:End()
	VFX:SetTrail(false)
	VFX:SetSpeedLines(false)
	VFX:StopShake()
	VFX:RestoreFOV()
end

function VFX:Shutdown()
	CarryVisual:Destroy()
	VFX:SetTrail(false)
	VFX:StopCarryAura()
	VFX:SetSpeedLines(false)
	VFX:StopShake()
	VFX:RestoreFOV()
	if VFX.SpeedLinesGui and VFX.SpeedLinesGui.Parent then VFX.SpeedLinesGui:Destroy() end
	if VFX.Folder and VFX.Folder.Parent then VFX.Folder:Destroy() end
	if StolenEgg._gui and StolenEgg._gui.Parent then StolenEgg._gui:Destroy() end
	table.clear(StolenEgg._notifStack)
	StolenEgg._gui = nil
	StolenEgg._iconCache = nil
end

local VFX_OrigWalkTo = EggFarm.WalkTo
EggFarm.WalkTo = function(targetPos, timeout)
	local home = EggFarm.GetHomePos()
	local isHome = (targetPos - home).Magnitude < 2
	local res = VFX_OrigWalkTo(targetPos, timeout)
	if res and isHome and VFX.Enabled and not CONFIG.LowFXMode then
		VFX:TeleportZapHome()
	end
	return res
end

EggStopBtn.MouseButton1Click:Connect(function()
	EggFarm.Stop = true
	EggStatusLbl.Text = "Stopping…"
	STATE.EggBusy = false
	CarryVisual:Hide()
	VFX:StopCarryAura()
	VisualWalk:Stop()
end)

--== FIND TOOL ==
EggFarm.FindEggTool = function()
	local char = LocalPlayer.Character
	local bp = LocalPlayer:FindFirstChild("Backpack")
	local function scan(container)
		if not container then return nil end
		for _, t in ipairs(container:GetChildren()) do
			if t:IsA("Tool") and t.Name:lower():find("egg") then
				return t
			end
		end
		return nil
	end
	local inChar = scan(char)
	if inChar then return inChar end
	return scan(bp)
end

EggFarm.DoCarry = function(uid)
	local ok, res = pcall(function() return EggFarm.RF_CARRY:InvokeServer({ Uid = uid }) end)
	return ok, res
end

EggFarm.DoDoff = function(uid)
	if not EggFarm.RF_DOFF then return false, "no doff remote" end
	local ok, res = pcall(function() return EggFarm.RF_DOFF:InvokeServer(uid) end)
	return ok, res
end

EggFarm.DoTrigger = function()
	local tool = EggFarm.FindEggTool()
	if not tool then return false, "no tool" end
	local ok, res = pcall(function() return EggFarm.RE_TRIGGER:FireServer(tool) end)
	return ok, res
end

EggFarm.ClearRows = function()
	for _, r in ipairs(STATE.EggRowPool) do if r and r.Parent then r:Destroy() end end
	table.clear(STATE.EggRowPool)
end

EggFarm.BuildRow = function(i, e)
	local row = Create("Frame", { Size = UDim2.new(1,-8,0,30), BackgroundColor3 = COLORS.Card, BackgroundTransparency = 0.3, BorderSizePixel = 0, LayoutOrder = i, Parent = EggListScroll })
	MakeCorner(row, 6)
	local rarity = e.rarity or GetEggRarity(e.name, e.earn, i, #STATE.EggList)
	Create("TextLabel", { Text = tostring(i), Size = UDim2.new(0,26,1,0), Position = UDim2.new(0,4,0,0), BackgroundTransparency = 1, Font = FONT_BOLD, TextSize = 11, TextColor3 = COLORS.SubText, TextXAlignment = Enum.TextXAlignment.Center, Parent = row })
	Create("TextLabel", { Text = EggFarm.FmtShort(e.earn), Size = UDim2.new(0,60,1,0), Position = UDim2.new(0,32,0,0), BackgroundTransparency = 1, Font = FONT_BOLD, TextSize = 12, TextColor3 = rarity.color, TextXAlignment = Enum.TextXAlignment.Left, Parent = row })
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
		for idx, egg in ipairs(tmp) do
			egg.rarity = GetEggRarity(egg.name, egg.earn, idx, #tmp)
		end
		STATE.EggList = tmp
		EggFarm.RenderList()
		EggStatusLbl.Text = string.format("%d eggs sorted.", #tmp)
		EggStatusLbl.TextColor3 = COLORS.SubText
		STATE.EggScanning = false
	end)
end

--== CARRY ALL ==
EggFarm.CarryAll = function()
	if not EggFarm.Enabled then EggStatusLbl.Text = "Egg farm disabled." return end
	if STATE.EggBusy then EggStatusLbl.Text = "Busy." return end
	if #STATE.EggList == 0 then EggStatusLbl.Text = "List empty — SCAN first." return end

	STATE.EggBusy = true
	EggFarm.Stop = false
	StartDeliveryScrub()

	local function Cleanup()
		CarryVisual:Hide()
		VFX:StopCarryAura()
		StopDeliveryScrub()
		STATE.EggBusy = false
		VisualWalk:Stop()
	end

	task.spawn(function()
		local okc, failc = 0, 0
		local homePos = EggFarm.GetHomePos()

		while #STATE.EggList > 0 and not EggFarm.Stop do
			local e = STATE.EggList[1]
			EggStatusLbl.Text = string.format("[%d Left] Lari ke %s", #STATE.EggList, e.name)

			CarryVisual:Hide()
			VFX:StopCarryAura()

			local okReach = EggFarm.WalkTo(e.pos)

			if EggFarm.Stop or STATE.Destroyed then
				Cleanup()
				return
			end

			if not okReach then
				failc = failc + 1
				table.remove(STATE.EggList, 1)
				EggFarm.RenderList()
			else
				-- Sudah berada di posisi telur: visual langsung dibuat sendiri.
				CarryVisual:Show(e)
				local okCarry = EggFarm.DoCarry(e.uid)

				if okCarry then
					task.wait(0.05)
					EggFarm.DoTrigger()

					if VFX.Enabled and not CONFIG.LowFXMode then
						VFX:StartCarryAura()
						local flashPos = (VisualWalk.Phantom and VisualWalk.Phantom.Parent)
							and VisualWalk.Phantom.Position
							or (function()
								local char = LocalPlayer.Character
								local hrp = char and char:FindFirstChild("HumanoidRootPart")
								return hrp and hrp.Position or Vector3.new(0,0,0)
							end)()
						VFX:EggPickupFlash(flashPos)
					end

					EggStatusLbl.Text = string.format("[%d Left] Lari ke Home membawa %s", #STATE.EggList, e.name)
					local okHome = EggFarm.WalkTo(homePos)

					-- Sampai HOME: visual telur + RUN!! + Drop langsung hilang.
					CarryVisual:Hide()
					VFX:StopCarryAura()

					if okHome then
						task.wait(0.1)
						local okDoff = EggFarm.DoDoff(e.uid)
						if okDoff then okc = okc + 1 else failc = failc + 1 end
						-- Replay notif + FOV bump dipicu pas udah di home
						pcall(function() StolenEgg:Trigger(e.name, e.earn, e.rarity) end)
					else
						failc = failc + 1
					end

					table.remove(STATE.EggList, 1)
					EggFarm.RenderList()
				else
					CarryVisual:Hide()
					failc = failc + 1
					table.remove(STATE.EggList, 1)
					EggFarm.RenderList()
				end
			end

			task.wait(0.05)
		end

		EggStatusLbl.Text = string.format("Selesai. ok=%d fail=%d", okc, failc)
		Cleanup()
	end)
end

EggSetHomeBtn.MouseButton1Click:Connect(function()
	local hrp = EggFarm.GetHrp()
	if hrp then
		local p = hrp.Position
		CONFIG.EggHomeX, CONFIG.EggHomeY, CONFIG.EggHomeZ = p.X, p.Y, p.Z
		EggHomeLbl.Text = string.format("HOME: %.1f, %.1f, %.1f", p.X, p.Y, p.Z)
		EggStatusLbl.Text = "Home set."
	end
end)
EggScanBtn.MouseButton1Click:Connect(EggFarm.Scan)
EggCarryAllBtn.MouseButton1Click:Connect(EggFarm.CarryAll)
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
		for i, o in ipairs(opts) do
			if o == cur then idx = i; break end
		end
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

	local vfx = NewSettingsCard("SPEED VFX", 260); vfx.LayoutOrder = 5
	MakeToggleRow(vfx, "Speed VFX", 36, function() return CONFIG.SpeedVFX end, function(v) CONFIG.SpeedVFX = v; VFX.Enabled = v end)
	MakeStepperRow(vfx, "VFX Mult", 88, 0.5, 5, 0.5, function() return CONFIG.VFXSpeed end, function(v) CONFIG.VFXSpeed = v end, function(v) return string.format("%.1fx", v) end)
	MakeStepperRow(vfx, "FOV Boost", 140, 0, 60, 5, function() return CONFIG.VFXFOVBoost end, function(v) CONFIG.VFXFOVBoost = v end, function(v) return tostring(v).."°" end)
	MakeLabel(vfx, "Setting speed = VFX & Visual Walk.", UDim2.new(1,-24,0,20), UDim2.new(0,12,0,196), FONT_TEXT, 11, COLORS.SubText)

	local rp = NewSettingsCard("STOLEN EGG REPLAY", 300); rp.LayoutOrder = 6
	MakeToggleRow(rp, "Replay Notif", 36, function() return CONFIG.StolenEggReplayEnabled end, function(v) CONFIG.StolenEggReplayEnabled = v end)
	MakeStepperRow(rp, "FOV Bump", 88, 0, 30, 1, function() return CONFIG.StolenEggFOVBoost end, function(v) CONFIG.StolenEggFOVBoost = v end, function(v) return tostring(v).."°" end)
	MakeStepperRow(rp, "Notif Hold", 140, 0.4, 5, 0.2, function() return CONFIG.StolenEggNotifHold end, function(v) CONFIG.StolenEggNotifHold = v end, function(v) return string.format("%.1fs", v) end)
	MakeStepperRow(rp, "Fade In", 192, 0.05, 1, 0.05, function() return CONFIG.StolenEggNotifIn end, function(v) CONFIG.StolenEggNotifIn = v end, function(v) return string.format("%.2fs", v) end)
	MakeStepperRow(rp, "Fade Out", 244, 0.05, 1.5, 0.05, function() return CONFIG.StolenEggNotifOut end, function(v) CONFIG.StolenEggNotifOut = v end, function(v) return string.format("%.2fs", v) end)

	local w = NewSettingsCard("WINDOW", 240); w.LayoutOrder = 7
	MakeToggleRow(w, "Remember Position", 36, function() return CONFIG.RememberPosition end, function(v) CONFIG.RememberPosition = v end)
	local cb = MakeButton(w, "Center Window", UDim2.new(1,-24,0,40), UDim2.new(0,12,0,92), function() ApplyWindowLayout(true) end); MakeCorner(cb, 10)
	local rpb = MakeButton(w, "Reset Position", UDim2.new(1,-24,0,40), UDim2.new(0,12,0,140), function() STATE.MainPosition = nil; STATE.MiniPosition = nil; ApplyWindowLayout(true) end); MakeCorner(rpb, 10)
	local rs = MakeButton(w, "Reset Settings", UDim2.new(1,-24,0,40), UDim2.new(0,12,0,188), function() _G.vanz.ResetSettings() end); MakeCorner(rs, 10)

	local perf = NewSettingsCard("PERFORMANCE", 220); perf.LayoutOrder = 8
	MakeToggleRow(perf, "Low FX Mode", 36, function() return CONFIG.LowFXMode end, function(v) CONFIG.LowFXMode = v end)
	MakeToggleRow(perf, "FPS Friendly Mode", 88, function() return CONFIG.FPSFriendly end, function(v) CONFIG.FPSFriendly = v end)
	MakeToggleRow(perf, "Disable Particles", 140, function() return CONFIG.DisableParticles end, function(v) CONFIG.DisableParticles = v end)
	MakeToggleRow(perf, "Disable Heavy Animation", 192, function() return CONFIG.DisableHeavyAnimation end, function(v) CONFIG.DisableHeavyAnimation = v end)

	local egg = NewSettingsCard("EGG FARM", 300); egg.LayoutOrder = 9
	MakeLabel(egg, "Visual Speed", UDim2.new(0.5,0,1,0), UDim2.new(0,12,0,36), FONT_BOLD, 14, COLORS.Text)
	local vsIn = MakeTextBox(egg, "800", UDim2.new(0,132,0,32), UDim2.new(1,-140,0,36), function(t)
		local n = tonumber(t)
		if n and n > 0 then CONFIG.EggWalkSpeed = math.floor(n)
		else vsIn.Text = tostring(CONFIG.EggWalkSpeed) end
	end, tostring(CONFIG.EggWalkSpeed))
	MakeStepperRow(egg, "Reach Distance", 88, 2, 30, 1, function() return CONFIG.EggReachDistance end, function(v) CONFIG.EggReachDistance = v end, function(v) return tostring(v).." studs" end)
	MakeStepperRow(egg, "Min Income", 140, 0, 1e9, 100000, function() return CONFIG.EggMinIncome end, function(v) CONFIG.EggMinIncome = v end, function(v)
		if v >= 1e6 then return string.format("%.1fM", v/1e6) end
		if v >= 1e3 then return string.format("%.1fK", v/1e3) end
		return tostring(v)
	end)
	MakeCycleRow(egg, "Auto Scan", 192, {0, 3, 5, 10, 30}, function() return CONFIG.EggAutoRefresh end, function(v) CONFIG.EggAutoRefresh = v end, function(v) return v == 0 and "OFF" or (v.."s") end)
	MakeLabel(egg, "Visual Speed mengontrol kecepatan gerakan visual.", UDim2.new(1,-24,0,20), UDim2.new(0,12,0,246), FONT_TEXT, 11, COLORS.SubText)
end

function ApplyTheme()
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
	local rawW, rawH = ParticleContainer.AbsoluteSize.X, ParticleContainer.AbsoluteSize.Y
	local w = math.floor(rawW)
	local h = math.floor(rawH)
	if w <= 0 or h <= 0 then return end
	ParticleCount = ParticleCount + 1
	local sz = math.random(2, 4)
	local px = math.random(0, w)
	local py = math.random(0, h)
	local p = MakeFrame(ParticleContainer, UDim2.new(0,sz,0,sz), UDim2.new(0, px, 0, py), GetTheme().Accent2, 0.7)
	MakeCorner(p, sz)
	local dx, dy = math.random(-30, 30), math.random(-40, -10)
	local dur = math.random(25, 45) / 10 / CONFIG.AnimationSpeed
	local targetX = math.clamp(px + dx, 0, w)
	local targetY = math.clamp(py + dy, 0, h)
	local tw = TweenService:Create(p, TweenInfo.new(dur, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
		Position = UDim2.new(0, targetX, 0, targetY),
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
		local vel = root.AssemblyLinearVelocity
		MoveLines["Velocity"].Text = string.format("Velocity: %.1f", vel.Magnitude)
		PosLines["Pos X"].Text = string.format("Pos X: %.2f", root.Position.X)
		PosLines["Pos Y"].Text = string.format("Pos Y: %.2f", root.Position.Y)
		PosLines["Pos Z"].Text = string.format("Pos Z: %.2f", root.Position.Z)
		PosLines["Vel X"].Text = string.format("Vel X: %.2f", vel.X)
		PosLines["Vel Y"].Text = string.format("Vel Y: %.2f", vel.Y)
		PosLines["Vel Z"].Text = string.format("Vel Z: %.2f", vel.Z)
		PosLines["Magnitude"].Text = string.format("Magnitude: %.2f", vel.Magnitude)
		local lk = root.CFrame.LookVector
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
		table.insert(HumanoidConnections, h.Died:Connect(function() UpdateHealthCard(nil) end))
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

DestroyAll = function()
	STATE.Destroyed = true
	STATE.Open = false
	CleanupAll()
	DisconnectHumanoidEvents()
	VFX:Shutdown()
	VisualWalk:Stop()
	if ScreenGui then ScreenGui:Destroy() end
end

local function SetSettingsVisible(v)
	STATE.SettingsOpen = v
	SettingsScroll.Visible = v
	HomeScroll.Visible = not v
	SettingsBtn.Text = v and "⌂" or "⚙"
end

--==================================================
-- [40] EVENTS & INITIALIZATION
--==================================================
BuildSettingsUI()
FillProfile()
if LocalPlayer.Character then BindCharacter(LocalPlayer.Character) end

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
	VFX.Enabled = CONFIG.SpeedVFX
	ApplyTheme(); ApplyWindowLayout(true); return true
end
_G.vanz.Close = function() return DestroyAll() end
_G.vanz.EggScan = function() if EggFarm.Scan then EggFarm.Scan() end end
_G.vanz.EggCarryAll = function() if EggFarm.CarryAll then EggFarm.CarryAll() end end
_G.vanz.EggStop = function()
	EggFarm.Stop = true
	STATE.EggBusy = false
end
_G.vanz.EggSetSpeed = function(v) CONFIG.EggWalkSpeed = math.floor(tonumber(v) or CONFIG.EggWalkSpeed) end
_G.vanz.EggSetHome = function(x, y, z)
	CONFIG.EggHomeX, CONFIG.EggHomeY, CONFIG.EggHomeZ = x, y, z
	EggHomeLbl.Text = string.format("HOME: %.1f, %.1f, %.1f", x, y, z)
end
_G.vanz.TestStolenEgg = function(name, earn) StolenEgg:Trigger(name or "Common Egg", earn or 0) end
_G.vanz.GetRarity = function(name, earn) return GetEggRarity(name, earn) end
_G.vanz.GetRarityByName = function(tierName)
	local r = RARITY_BY_NAME[tostring(tierName)]
	return r and r.name or nil
end
_G.vanz.ListRarity = function()
	local out = {}
	for _, r in ipairs(RARITY) do
		out[#out+1] = string.format("%-10s  color=#%02X%02X%02X  earn=[%s..%s]  alias=%s",
			r.name,
			math.floor(r.color.R * 255 + 0.5),
			math.floor(r.color.G * 255 + 0.5),
			math.floor(r.color.B * 255 + 0.5),
			tostring(r.min), tostring(r.max),
			table.concat(r.aliases, ","))
	end
	return table.concat(out, "\n")
end
_G.vanz.GetEggListRarity = function()
	local out = {}
	for i, e in ipairs(STATE.EggList) do
		local r = e.rarity or GetEggRarity(e.name, e.earn, i, #STATE.EggList)
		out[#out+1] = string.format("%3d  %-28s  earn=%-12s  -> %s", i, tostring(e.name), EggFarm.FmtShort(e.earn), r.name)
	end
	return table.concat(out, "\n")
end

ShowMainWindow()