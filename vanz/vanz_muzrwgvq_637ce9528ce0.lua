--==================================================
-- [01] SERVICES
--==================================================
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")
local MarketplaceService = game:GetService("MarketplaceService")
local Lighting = game:GetService("Lighting")
local Stats = game:GetService("Stats")

--==================================================
-- [01-B] RUNTIME COMPATIBILITY
--==================================================
-- Luau/Roblox-compatible scheduler helpers. Prefer the standard task API;
-- fall back only when the runtime does not expose it.
local function IsFunction(v)
	return type(v) == "function"
end

local NativeTask = task
local NativeWait = wait
local NativeSpawn = spawn
local Unpack = table.unpack or unpack

local CompatWait
if type(NativeTask) == "table" and IsFunction(NativeTask.wait) then
	CompatWait = function(seconds)
		return NativeTask.wait(seconds)
	end
elseif IsFunction(NativeWait) then
	CompatWait = function(seconds)
		return NativeWait(seconds)
	end
else
	CompatWait = function(seconds)
		return coroutine.yield(seconds or 0)
	end
end

local CompatSpawn
if type(NativeTask) == "table" and IsFunction(NativeTask.spawn) then
	CompatSpawn = function(fn, ...)
		return NativeTask.spawn(fn, ...)
	end
elseif IsFunction(NativeSpawn) then
	CompatSpawn = function(fn, ...)
		return NativeSpawn(fn, ...)
	end
else
	CompatSpawn = function(fn, ...)
		local args = {...}
		return coroutine.wrap(function()
			fn(Unpack(args))
		end)()
	end
end

local CompatDelay
if type(NativeTask) == "table" and IsFunction(NativeTask.delay) then
	CompatDelay = function(seconds, fn, ...)
		return NativeTask.delay(seconds, fn, ...)
	end
else
	CompatDelay = function(seconds, fn, ...)
		local args = {...}
		return CompatSpawn(function()
			CompatWait(seconds)
			fn(Unpack(args))
		end)
	end
end

local CompatDefer
if type(NativeTask) == "table" and IsFunction(NativeTask.defer) then
	CompatDefer = function(fn, ...)
		return NativeTask.defer(fn, ...)
	end
else
	CompatDefer = CompatSpawn
end

local function ClearTable(t)
	if type(t) ~= "table" then return end
	if type(table.clear) == "function" then
		table.clear(t)
	else
		for k in pairs(t) do
			t[k] = nil
		end
	end
end

local function ClampNumber(value, minValue, maxValue)
	value = tonumber(value) or 0
	if value < minValue then return minValue end
	if value > maxValue then return maxValue end
	return value
end

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
	["Cyber Blue"] = { Accent = Color3.fromRGB(0, 170, 255), Accent2 = Color3.fromRGB(0, 255, 230), Base = Color3.fromRGB(14, 22, 42), Base2 = Color3.fromRGB(22, 36, 66) },
	["Neon Cyan"] = { Accent = Color3.fromRGB(0, 255, 255), Accent2 = Color3.fromRGB(80, 255, 200), Base = Color3.fromRGB(12, 26, 36), Base2 = Color3.fromRGB(20, 42, 56) },
	["Purple Anime"] = { Accent = Color3.fromRGB(190, 110, 255), Accent2 = Color3.fromRGB(255, 120, 220), Base = Color3.fromRGB(28, 18, 46), Base2 = Color3.fromRGB(44, 28, 70) },
	["Crimson"] = { Accent = Color3.fromRGB(255, 70, 90), Accent2 = Color3.fromRGB(255, 160, 80), Base = Color3.fromRGB(34, 16, 22), Base2 = Color3.fromRGB(52, 24, 34) },
	["Emerald"] = { Accent = Color3.fromRGB(70, 255, 150), Accent2 = Color3.fromRGB(160, 255, 90), Base = Color3.fromRGB(14, 32, 26), Base2 = Color3.fromRGB(22, 50, 40) },
	["Ice"] = { Accent = Color3.fromRGB(170, 230, 255), Accent2 = Color3.fromRGB(230, 250, 255), Base = Color3.fromRGB(26, 40, 56), Base2 = Color3.fromRGB(38, 58, 80) },
}

local DEFAULT_CONFIG_SNAPSHOT = {}
for k, v in pairs(CONFIG) do
	DEFAULT_CONFIG_SNAPSHOT[k] = v
end

--==================================================
-- [03] STATE
--==================================================
local STATE = {
	Built = false, Open = false, Minimized = false, Destroyed = false,
	SettingsOpen = false, MainPosition = nil, MiniPosition = nil,
	SessionStart = os.clock(), AccountAgeText = "N/A", DeviceText = "N/A",
	ThumbnailReady = false, MarketplaceName = "N/A",
	LastFPS = 0, FrameCount = 0, FrameTimer = 0, FastTimer = 0, SlowTimer = 0, LastFrameDt = 0,
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
local function TrackTween(tw)
	if tw then table.insert(ActiveTweens, tw) end
	return tw
end
local function AddCleanup(fn)
	table.insert(CleanupCallbacks, fn)
end
local function CleanupAll()
	for _, c in ipairs(Connections) do pcall(function() c:Disconnect() end) end
	ClearTable(Connections)
	for _, t in ipairs(ActiveTweens) do pcall(function() t:Cancel() end) end
	ClearTable(ActiveTweens)
	for _, f in ipairs(CleanupCallbacks) do pcall(f) end
	ClearTable(CleanupCallbacks)
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
	for k, v in pairs(props or {}) do obj[k] = v end
	for _, ch in ipairs(children or {}) do ch.Parent = obj end
	return obj
end
local function MakeCorner(parent, radius)
	return Create("UICorner", { CornerRadius = UDim.new(0, radius or 10), Parent = parent })
end
local function MakeStroke(parent, color, thickness, transparency)
	return Create("UIStroke", {
		Color = color or GetTheme().Accent, Thickness = thickness or 1,
		Transparency = transparency or 0.4,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Parent = parent,
	})
end
local function MakeGradient(parent, c1, c2, rotation)
	return Create("UIGradient", {
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, c1),
			ColorSequenceKeypoint.new(1, c2),
		}),
		Rotation = rotation or 90, Parent = parent,
	})
end
local function MakeFrame(parent, size, pos, color, transparency)
	return Create("Frame", {
		Size = size or UDim2.new(1, 0, 1, 0),
		Position = pos or UDim2.new(0, 0, 0, 0),
		BackgroundColor3 = color or COLORS.Card,
		BackgroundTransparency = transparency or 0,
		BorderSizePixel = 0, Parent = parent,
	})
end
local function MakeLabel(parent, text, size, pos, font, textSize, color, xAlign)
	return Create("TextLabel", {
		Text = text or "", Size = size or UDim2.new(1, 0, 0, 20),
		Position = pos or UDim2.new(0, 0, 0, 0),
		BackgroundTransparency = 1, Font = font or FONT_TEXT, TextSize = textSize or 14,
		TextColor3 = color or COLORS.Text,
		TextXAlignment = xAlign or Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Center,
		TextScaled = false, TextWrapped = false, Parent = parent,
	})
end
local function MakeButton(parent, text, size, pos, onClick)
	local btn = Create("TextButton", {
		Text = text or "", Size = size or UDim2.new(0, 48, 0, 48),
		Position = pos or UDim2.new(0, 0, 0, 0),
		BackgroundColor3 = GetTheme().Base2, BackgroundTransparency = 0.1,
		BorderSizePixel = 0, AutoButtonColor = false,
		Font = FONT_BOLD, TextSize = 18, TextColor3 = COLORS.Text, Parent = parent,
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
			TrackTween(TweenService:Create(btn, TweenInfo.new(0.08, Enum.EasingStyle.Quad), {
				BackgroundTransparency = 0,
			})):Play()
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
local function ToStr(v, digits)
	if v == nil then return "N/A" end
	if type(v) == "number" then
		if digits then return string.format("%." .. digits .. "f", v) end
		return tostring(math.floor(v + 0.5))
	end
	return tostring(v)
end

--==================================================
-- [07] ROOT SCREENGUI
--==================================================
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local ScreenGui = Create("ScreenGui", {
	Name = "VANZ_ULTRA_CONTROL", ResetOnSpawn = false, IgnoreGuiInset = true,
	ZIndexBehavior = Enum.ZIndexBehavior.Global, DisplayOrder = 9999,
	Enabled = false, Parent = PlayerGui,
})

--==================================================
-- [08] SCREEN HELPERS
--==================================================
local function GetViewport()
	if Camera and Camera.ViewportSize then return Camera.ViewportSize end
	return Vector2.new(1280, 720)
end
local BASE_WIDTH = 760
local BASE_HEIGHT = 520
local MIN_WIDTH_PX = 300
local function ComputeWindowSize()
	local vp = GetViewport()
	local s = CONFIG.Scale
	local w = ClampNumber(BASE_WIDTH * s * 2, MIN_WIDTH_PX, vp.X - 16)
	local h = ClampNumber(BASE_HEIGHT * s * 2, 260, vp.Y - 16)
	return Vector2.new(math.floor(w), math.floor(h))
end
local function ComputeCenteredPosition(size)
	local vp = GetViewport()
	return Vector2.new(math.floor((vp.X - size.X) / 2), math.floor((vp.Y - size.Y) / 2))
end
local function ClampAbsolute(pos, size)
	local vp = GetViewport()
	return Vector2.new(
		ClampNumber(pos.X, 0, math.max(0, vp.X - size.X)),
		ClampNumber(pos.Y, 0, math.max(0, vp.Y - size.Y))
	)
end

--==================================================
-- [09] MAIN WINDOW
--==================================================
local MainWindow = Create("Frame", {
	Name = "MainWindow", Size = UDim2.new(0, 0, 0, 0), Position = UDim2.new(0, 0, 0, 0),
	AnchorPoint = Vector2.new(0, 0), BackgroundColor3 = GetTheme().Base,
	BackgroundTransparency = CONFIG.WindowOpacity, BorderSizePixel = 0,
	ClipsDescendants = true, Visible = false, Parent = ScreenGui,
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

local TitleArea = MakeFrame(Header, UDim2.new(1, -(12 + 36 + 12 + 156), 1, 0), UDim2.new(0, 12 + 36 + 10, 0, 0), COLORS.Card, 1)
MakeLabel(TitleArea, "VANZ ULTRA CONTROL CENTER", UDim2.new(1, 0, 0, 22), UDim2.new(0, 0, 0, 8), FONT_TITLE, 15, COLORS.Text)
MakeLabel(TitleArea, "SYSTEM ONLINE", UDim2.new(1, 0, 0, 16), UDim2.new(0, 0, 0, 28), FONT_TEXT, 11, COLORS.SubText)

local CONTROL_ZONE_WIDTH = 156
local ControlZone = MakeFrame(Header, UDim2.new(0, CONTROL_ZONE_WIDTH, 1, 0), UDim2.new(1, -CONTROL_ZONE_WIDTH - 8, 0, 0), COLORS.Card, 1)
local BTN_SIZE = 44
local BTN_GAP = 6
local SettingsBtn, MinimizeBtn, CloseBtn

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
SettingsBtn = MakeButton(ControlZone, "⚙", UDim2.new(0, BTN_SIZE, 0, BTN_SIZE), UDim2.new(0, 0, 0, 0), function() end)
MinimizeBtn = MakeButton(ControlZone, "—", UDim2.new(0, BTN_SIZE, 0, BTN_SIZE), UDim2.new(0, 0, 0, 0), function() end)
CloseBtn = MakeButton(ControlZone, "X", UDim2.new(0, BTN_SIZE, 0, BTN_SIZE), UDim2.new(0, 0, 0, 0), function() end)
TrackConnection(ControlZone:GetPropertyChangedSignal("AbsoluteSize"):Connect(LayoutControls))
CompatDefer(LayoutControls)

--==================================================
-- [11] BODY CONTAINER
--==================================================
local Body = MakeFrame(MainWindow, UDim2.new(1, -16, 1, -(HEADER_HEIGHT + 12)), UDim2.new(0, 8, 0, HEADER_HEIGHT + 4), COLORS.Card, 1)
local HomeScroll = Create("ScrollingFrame", {
	Name = "HomeScroll", Size = UDim2.new(1, 0, 1, 0), Position = UDim2.new(0, 0, 0, 0),
	BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 5,
	ScrollBarImageColor3 = GetTheme().Accent, CanvasSize = UDim2.new(0, 0, 0, 0),
	AutomaticCanvasSize = Enum.AutomaticSize.None,
	ScrollingDirection = Enum.ScrollingDirection.Y,
	ElasticBehavior = Enum.ElasticBehavior.Never, Visible = true, Parent = Body,
})
local HomeList = Create("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 10), Parent = HomeScroll })
Create("UIPadding", { PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8), PaddingTop = UDim.new(0, 6), PaddingBottom = UDim.new(0, 12), Parent = HomeScroll })

local function RefreshHomeCanvas()
	if not HomeScroll or not HomeScroll.Parent then return end
	HomeScroll.CanvasSize = UDim2.new(0, 0, 0, HomeList.AbsoluteContentSize.Y + 24)
end
TrackConnection(HomeList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(RefreshHomeCanvas))

local SettingsScroll = Create("ScrollingFrame", {
	Name = "SettingsScroll", Size = UDim2.new(1, 0, 1, 0), Position = UDim2.new(0, 0, 0, 0),
	BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 5,
	ScrollBarImageColor3 = GetTheme().Accent2, CanvasSize = UDim2.new(0, 0, 0, 0),
	AutomaticCanvasSize = Enum.AutomaticSize.None,
	ScrollingDirection = Enum.ScrollingDirection.Y,
	ElasticBehavior = Enum.ElasticBehavior.Never, Visible = false, Parent = Body,
})
local SettingsList = Create("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 10), Parent = SettingsScroll })
Create("UIPadding", { PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8), PaddingTop = UDim.new(0, 6), PaddingBottom = UDim.new(0, 12), Parent = SettingsScroll })

local function RefreshSettingsCanvas()
	if not SettingsScroll or not SettingsScroll.Parent then return end
	SettingsScroll.CanvasSize = UDim2.new(0, 0, 0, SettingsList.AbsoluteContentSize.Y + 24)
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
local AvatarImage = Create("ImageLabel", { Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Image = "", Parent = AvatarFrame })
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
		if ok and img then AvatarImage.Image = img; STATE.ThumbnailReady = true end
	end)
	pcall(function()
		local mt = LocalPlayer.MembershipType
		local t = (mt == Enum.MembershipType.Premium and "Premium") or (mt == Enum.MembershipType.None and "None") or "N/A"
		ProfileMembership.Text = "Membership: " .. t
	end)
	pcall(function()
		local device = "N/A"
		if UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled then device = "Mobile"
		elseif UserInputService.KeyboardEnabled then device = "PC"
		elseif UserInputService.GamepadEnabled then device = "Console" end
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
local function AddCharLine(key, i)
	CharLines[key] = MakeLabel(CharCard, key .. ": N/A", UDim2.new(1, -24, 0, 18), UDim2.new(0, 12, 0, 36 + (i - 1) * 20), FONT_TEXT, 14, COLORS.Text)
end
AddCharLine("WalkSpeed", 1); AddCharLine("JumpPower", 2); AddCharLine("Health", 3)
AddCharLine("MaxHealth", 4); AddCharLine("Health %", 5); AddCharLine("HipHeight", 6)
AddCharLine("AutoRotate", 7); AddCharLine("PlatformStand", 8); AddCharLine("RigType", 9)
AddCharLine("Character State", 10)

--==================================================
-- [14] HOME CARDS: MOVEMENT CORE
--==================================================
local MoveCard = MakeCard(HomeScroll, "MOVEMENT CORE", UDim2.new(1, -4, 0, 170), nil)
MoveCard.LayoutOrder = 3
local MoveLines = {}
local function AddMoveLine(key, i)
	MoveLines[key] = MakeLabel(MoveCard, key .. ": N/A", UDim2.new(1, -24, 0, 18), UDim2.new(0, 12, 0, 36 + (i - 1) * 20), FONT_TEXT, 14, COLORS.Text)
end
AddMoveLine("MoveDirection", 1); AddMoveLine("Velocity", 2); AddMoveLine("Grounded", 3)
AddMoveLine("Floor Material", 4); AddMoveLine("Seat Status", 5); AddMoveLine("Humanoid State", 6)
AddMoveLine("Character Name", 7)

--==================================================
-- [15] HOME CARDS: HEALTH BAR
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
local function AddPosLine(key, i)
	PosLines[key] = MakeLabel(PosCard, key .. ": N/A", UDim2.new(1, -24, 0, 18), UDim2.new(0, 12, 0, 36 + (i - 1) * 20), FONT_TEXT, 14, COLORS.Text)
end
AddPosLine("Pos X", 1); AddPosLine("Pos Y", 2); AddPosLine("Pos Z", 3)
AddPosLine("Vel X", 4); AddPosLine("Vel Y", 5); AddPosLine("Vel Z", 6)
AddPosLine("Magnitude", 7); AddPosLine("Facing", 8)

--==================================================
-- [17] HOME CARDS: PLAYER INFORMATION
--==================================================
local InfoCard = MakeCard(HomeScroll, "PLAYER INFORMATION", UDim2.new(1, -4, 0, 360), nil)
InfoCard.LayoutOrder = 6
local InfoLines = {}
local function AddInfoLine(key, i)
	InfoLines[key] = MakeLabel(InfoCard, key .. ": N/A", UDim2.new(1, -24, 0, 18), UDim2.new(0, 12, 0, 36 + (i - 1) * 20), FONT_TEXT, 14, COLORS.Text)
end
AddInfoLine("Display Name", 1); AddInfoLine("Username", 2); AddInfoLine("UserId", 3)
AddInfoLine("Account Age", 4); AddInfoLine("Team", 5); AddInfoLine("Team Color", 6)
AddInfoLine("Character", 7); AddInfoLine("Rig Type", 8); AddInfoLine("Device", 9)
AddInfoLine("Camera Mode", 10); AddInfoLine("Field Of View", 11); AddInfoLine("Graphics Quality", 12)
AddInfoLine("Session Time", 13); AddInfoLine("Server JobId", 14); AddInfoLine("PlaceId", 15); AddInfoLine("GameId", 16)

--==================================================
-- [18] HOME CARDS: SESSION TELEMETRY
--==================================================
local SessionCard = MakeCard(HomeScroll, "SESSION TELEMETRY", UDim2.new(1, -4, 0, 180), nil)
SessionCard.LayoutOrder = 7
local SessionLines = {}
local function AddSessionLine(key, i)
	SessionLines[key] = MakeLabel(SessionCard, key .. ": N/A", UDim2.new(1, -24, 0, 18), UDim2.new(0, 12, 0, 36 + (i - 1) * 20), FONT_TEXT, 14, COLORS.Text)
end
AddSessionLine("FPS", 1); AddSessionLine("Ping", 2); AddSessionLine("Uptime", 3)
AddSessionLine("Memory", 4); AddSessionLine("Heartbeat", 5); AddSessionLine("Client State", 6); AddSessionLine("System", 7)

--==================================================
-- [18-B] HOME CARDS: STORE AUTO-FIRE
--==================================================
local CheatCard = MakeCard(HomeScroll, "STORE AUTO-FIRE", UDim2.new(1, -4, 0, 210), nil)
CheatCard.LayoutOrder = 8
local CheatState = { Running = false, Current = 0, Max = 1000, Repeats = 2, Delay = 0.05, Logged = 0, LastError = "" }
local CheatStatus = MakeLabel(CheatCard, "Status: Idle", UDim2.new(1, -24, 0, 18), UDim2.new(0, 12, 0, 36), FONT_TEXT, 14, COLORS.Text)
local CheatCurrent = MakeLabel(CheatCard, "Current: 0 / 1000", UDim2.new(1, -24, 0, 18), UDim2.new(0, 12, 0, 56), FONT_BOLD, 14, GetTheme().Accent2)
local CheatBarTrack = MakeFrame(CheatCard, UDim2.new(1, -24, 0, 12), UDim2.new(0, 12, 0, 80), COLORS.Track, 0)
MakeCorner(CheatBarTrack, 6)
local CheatBarFill = MakeFrame(CheatBarTrack, UDim2.new(0, 0, 1, 0), UDim2.new(0, 0, 0, 0), GetTheme().Accent2, 0)
MakeCorner(CheatBarFill, 6)
MakeLabel(CheatCard, "Delay", UDim2.new(0.3, 0, 0, 32), UDim2.new(0, 12, 0, 100), FONT_BOLD, 14, COLORS.Text)
local CheatDelayValue = MakeLabel(CheatCard, "0.05s", UDim2.new(0, 70, 0, 32), UDim2.new(1, -160, 0, 100), FONT_BOLD, 14, GetTheme().Accent2, Enum.TextXAlignment.Center)
local CheatDelayMinus = MakeButton(CheatCard, "-", UDim2.new(0, 36, 0, 32), UDim2.new(1, -84, 0, 100), nil)
local CheatDelayPlus = MakeButton(CheatCard, "+", UDim2.new(0, 36, 0, 32), UDim2.new(1, -44, 0, 100), nil)
local CheatStartBtn = MakeButton(CheatCard, "START", UDim2.new(0.5, -8, 0, 40), UDim2.new(0, 12, 0, 148), nil)
local CheatStopBtn = MakeButton(CheatCard, "STOP", UDim2.new(0.5, -8, 0, 40), UDim2.new(0.5, 8, 0, 148), nil)

local function GetStoreRemoteShared()
	local ok, remote = pcall(function()
		return game:GetService("ReplicatedStorage").Shared.Universe.Network.RemoteEvent.Store
	end)
	if ok and remote then return remote end
	return nil
end
local CheatThread = nil
local function CheatStop()
	if not CheatState.Running then return end
	CheatState.Running = false
	CheatStatus.Text = "Status: Stopped at " .. CheatState.Current
	CheatStatus.TextColor3 = COLORS.Warn
end
local function CheatRun()
	if CheatState.Running then return end
	local remote = GetStoreRemoteShared()
	if not remote then
		CheatStatus.Text = "Status: Remote not found"
		CheatStatus.TextColor3 = COLORS.Bad
		return
	end
	CheatState.Running = true
	CheatState.Current = 0
	CheatState.Logged = 0
	CheatStatus.Text = "Status: Running"
	CheatStatus.TextColor3 = COLORS.Good
	CheatBarFill.Size = UDim2.new(0, 0, 1, 0)
	CheatCurrent.Text = "Current: 0 / " .. CheatState.Max
	CheatThread = CompatSpawn(function()
		for i = 1, CheatState.Max do
			if not CheatState.Running then break end
			for _ = 1, CheatState.Repeats do
				if not CheatState.Running then break end
				pcall(function() remote:FireServer(i) end)
				CheatState.Logged = CheatState.Logged + 1
				if CheatState.Delay > 0 then CompatWait(CheatState.Delay) end
			end
			CheatState.Current = i
			CheatCurrent.Text = "Current: " .. i .. " / " .. CheatState.Max
			CheatBarFill.Size = UDim2.new(i / CheatState.Max, 0, 1, 0)
		end
		if CheatState.Running then
			CheatStatus.Text = "Status: Completed"
			CheatStatus.TextColor3 = COLORS.Good
		end
		CheatState.Running = false
	end)
end
TrackConnection(CheatDelayMinus.MouseButton1Click:Connect(function()
	local v = math.max(0, CheatState.Delay - 0.05)
	CheatState.Delay = math.floor(v * 100 + 0.5) / 100
	CheatDelayValue.Text = string.format("%.2fs", CheatState.Delay)
end))
TrackConnection(CheatDelayPlus.MouseButton1Click:Connect(function()
	local v = math.min(2, CheatState.Delay + 0.05)
	CheatState.Delay = math.floor(v * 100 + 0.5) / 100
	CheatDelayValue.Text = string.format("%.2fs", CheatState.Delay)
end))
TrackConnection(CheatStartBtn.MouseButton1Click:Connect(function() CheatRun() end))
TrackConnection(CheatStopBtn.MouseButton1Click:Connect(function() CheatStop() end))
AddCleanup(function() CheatState.Running = false end)

--==================================================
-- [18-C] HOME CARDS: ITEM AUTO-SCANNER
-- Scan ReplicatedStorage (hier) + probe Store IDs, watch Backpack/NotifyClient untuk capture name<->id.
--==================================================
local ScanCard = MakeCard(HomeScroll, "ITEM AUTO-SCANNER", UDim2.new(1, -4, 0, 580), nil)
ScanCard.LayoutOrder = 9

local ScanState = {
	Items = {},
	Order = {},
	Firing = false,
	Delay = 0.15,
	Fired = 0,
	LastError = "",
	Scanning = false,
	Probing = false,
	ProbeCurrent = 0,
	ProbeMax = 1200,
	ProbeDelay = 0.25,
	ProbeHits = 0,
	ProbeMisses = 0,
	Collecting = false,
	CollectCurrent = 0,
	CollectFired = 0,
	CollectErrors = 0,
	CollectDelay = 0.001,
	CollectLastError = "",
}

local ScanStatusLabel = MakeLabel(ScanCard, "Items: 0", UDim2.new(1, -140, 0, 18), UDim2.new(0, 12, 0, 32), FONT_TEXT, 12, COLORS.SubText)
local ScanStatusRight = MakeLabel(ScanCard, "Fired: 0", UDim2.new(0, 128, 0, 18), UDim2.new(1, -140, 0, 32), FONT_TEXT, 12, COLORS.SubText, Enum.TextXAlignment.Right)

local ScanHierBtn = MakeButton(ScanCard, "SCAN HIER", UDim2.new(0.33, -12, 0, 30), UDim2.new(0, 12, 0, 54), nil)
ScanHierBtn.TextSize = 12
local ScanProbeBtn = MakeButton(ScanCard, "PROBE IDs", UDim2.new(0.33, -12, 0, 30), UDim2.new(0.33, 6, 0, 54), nil)
ScanProbeBtn.TextSize = 12
local ScanStopBtn = MakeButton(ScanCard, "STOP", UDim2.new(0.34, -12, 0, 30), UDim2.new(0.67, -6, 0, 54), nil)
ScanStopBtn.TextSize = 12

local ScanProbeBarBg = MakeFrame(ScanCard, UDim2.new(1, -24, 0, 12), UDim2.new(0, 12, 0, 92), COLORS.Track, 0)
MakeCorner(ScanProbeBarBg, 6)
local ScanProbeBar = MakeFrame(ScanProbeBarBg, UDim2.new(0, 0, 1, 0), UDim2.new(0, 0, 0, 0), GetTheme().Accent2, 0)
MakeCorner(ScanProbeBar, 6)
local ScanProbeLabel = MakeLabel(ScanCard, "Idle", UDim2.new(1, -24, 0, 14), UDim2.new(0, 12, 0, 106), FONT_TEXT, 11, COLORS.SubText)

local ScanIdBox = Create("TextBox", {
	Text = "", PlaceholderText = "ID",
	Size = UDim2.new(0.22, -12, 0, 28), Position = UDim2.new(0, 12, 0, 122),
	BackgroundColor3 = COLORS.Track, BackgroundTransparency = 0.1, BorderSizePixel = 0,
	Font = FONT_BOLD, TextSize = 13, TextColor3 = COLORS.Text, PlaceholderColor3 = COLORS.SubText,
	ClearTextOnFocus = false, TextXAlignment = Enum.TextXAlignment.Center, Parent = ScanCard,
})
MakeCorner(ScanIdBox, 6)
MakeStroke(ScanIdBox, GetTheme().Accent, 1, 0.5)

local ScanNameBox = Create("TextBox", {
	Text = "", PlaceholderText = "Nama item",
	Size = UDim2.new(0.55, -12, 0, 28), Position = UDim2.new(0.22, -6, 0, 122),
	BackgroundColor3 = COLORS.Track, BackgroundTransparency = 0.1, BorderSizePixel = 0,
	Font = FONT_BOLD, TextSize = 13, TextColor3 = COLORS.Text, PlaceholderColor3 = COLORS.SubText,
	ClearTextOnFocus = false, TextXAlignment = Enum.TextXAlignment.Left, Parent = ScanCard,
})
MakeCorner(ScanNameBox, 6)
MakeStroke(ScanNameBox, GetTheme().Accent, 1, 0.5)

local ScanAddBtn = MakeButton(ScanCard, "ADD", UDim2.new(0.23, -12, 0, 28), UDim2.new(0.77, -6, 0, 122), nil)
ScanAddBtn.TextSize = 12

local ScanList = Create("ScrollingFrame", {
	Size = UDim2.new(1, -24, 0, 250), Position = UDim2.new(0, 12, 0, 158),
	BackgroundColor3 = COLORS.Track, BackgroundTransparency = 0.5, BorderSizePixel = 0,
	ScrollBarThickness = 4, ScrollBarImageColor3 = GetTheme().Accent,
	CanvasSize = UDim2.new(0, 0, 0, 0), ScrollingDirection = Enum.ScrollingDirection.Y,
	ElasticBehavior = Enum.ElasticBehavior.Never, ClipsDescendants = true, Parent = ScanCard,
})
MakeCorner(ScanList, 8)
MakeStroke(ScanList, GetTheme().Accent, 1, 0.7)

local ScanListLayout = Create("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 4), Parent = ScanList })
Create("UIPadding", { PaddingLeft = UDim.new(0, 6), PaddingRight = UDim.new(0, 6), PaddingTop = UDim.new(0, 6), PaddingBottom = UDim.new(0, 6), Parent = ScanList })

local ScanEmptyLabel = MakeLabel(ScanList, "Belum ada item.\nKlik SCAN HIER atau PROBE IDs.", UDim2.new(1, -12, 0, 40), UDim2.new(0, 6, 0, 6), FONT_TEXT, 12, COLORS.SubText)
ScanEmptyLabel.TextWrapped = true

local function RefreshScanCanvas()
	ScanList.CanvasSize = UDim2.new(0, 0, 0, ScanListLayout.AbsoluteContentSize.Y + 16)
end

local ScanRows = {}

local function RemoveScanRow(id)
	local row = ScanRows[id]
	if row and row.Parent then row:Destroy() end
	ScanRows[id] = nil
end

local function RefreshScanStatus()
	ScanStatusLabel.Text = "Items: " .. #ScanState.Order .. " | Hits: " .. ScanState.ProbeHits
	ScanEmptyLabel.Visible = (#ScanState.Order == 0)
end

local function FireIdOnce(id)
	local remote = GetStoreRemoteShared()
	if not remote then
		ScanState.LastError = "Remote not found"
		return false
	end
	local ok, err = pcall(function() remote:FireServer(id) end)
	ScanState.Fired = ScanState.Fired + 1
	ScanStatusRight.Text = "Fired: " .. ScanState.Fired
	if not ok then
		ScanState.LastError = tostring(err)
		return false
	end
	return true
end

local function BuildScanRow(id, name)
	RemoveScanRow(id)
	ScanEmptyLabel.Visible = false
	local row = MakeFrame(ScanList, UDim2.new(1, -4, 0, 32), nil, GetTheme().Base2, 0.3)
	MakeCorner(row, 8)
	MakeStroke(row, GetTheme().Accent, 1, 0.75)
	row.LayoutOrder = #ScanState.Order

	MakeLabel(row, "#" .. tostring(id), UDim2.new(0, 64, 1, 0), UDim2.new(0, 8, 0, 0), FONT_BOLD, 12, GetTheme().Accent2)
	MakeLabel(row, name, UDim2.new(1, -180, 1, 0), UDim2.new(0, 74, 0, 0), FONT_BOLD, 12, COLORS.Text)

	local pickBtn = MakeButton(row, "PICK", UDim2.new(0, 56, 0, 24), UDim2.new(1, -128, 0.5, -12), function()
		FireIdOnce(id)
	end)
	pickBtn.TextSize = 11

	local copyBtn = MakeButton(row, "COPY", UDim2.new(0, 44, 0, 24), UDim2.new(1, -70, 0.5, -12), function()
		if setclipboard then
			pcall(function()
				setclipboard("local Event = game:GetService(\"ReplicatedStorage\").Shared.Universe.Network.RemoteEvent.Store\nEvent:FireServer(" .. id .. ")")
			end)
		end
	end)
	copyBtn.TextSize = 10

	local delBtn = MakeButton(row, "X", UDim2.new(0, 24, 0, 24), UDim2.new(1, -28, 0.5, -12), function()
		ScanState.Items[id] = nil
		for i = #ScanState.Order, 1, -1 do
			if ScanState.Order[i] == id then table.remove(ScanState.Order, i) end
		end
		RemoveScanRow(id)
		RefreshScanStatus()
		RefreshScanCanvas()
	end)
	delBtn.TextSize = 11

	ScanRows[id] = row
	RefreshScanCanvas()
	RefreshScanStatus()
end

local function AddScanItem(id, name)
	if not ScanState.Items[id] then table.insert(ScanState.Order, id) end
	ScanState.Items[id] = name
	BuildScanRow(id, name)
end

ScanAddBtn.MouseButton1Click:Connect(function()
	local id = tonumber(ScanIdBox.Text)
	if not id then
		ScanStatusLabel.Text = "Err: ID harus angka"
		ScanStatusLabel.TextColor3 = COLORS.Bad
		return
	end
	id = math.floor(id)
	local name = ScanNameBox.Text
	if not name or name == "" then name = "Item " .. tostring(id) end
	ScanIdBox.Text = ""
	ScanNameBox.Text = ""
	AddScanItem(id, name)
end)

local function IsNpcLike(name)
	local nm = string.lower(name)
	local bad = {
		"zombie","soldier","outlaw","ghost","skeleton","alien","vampire",
		"elf","rig","model_","animator","animate","emote","covenant",
		"acolyte","summoner","banker","boxer","walker","runner",
		"prescott","rockefeller","ufo","yeat","santa","turret",
		"rifle","revolver","shotgun","maxim","cannon","ballista",
	}
	for _, p in ipairs(bad) do
		if string.find(nm, p, 1, true) then return true end
	end
	return false
end

local function TryExtractId(inst)
	local ok, attrs = pcall(function() return inst:GetAttributes() end)
	if ok and attrs then
		for an, av in pairs(attrs) do
			local ln = string.lower(an)
			if ln == "id" or ln == "itemid" or ln == "item_id" or ln == "index" or ln == "storeid" then
				if type(av) == "number" then return av end
			end
		end
	end
	local n = string.match(inst.Name, "^(%d+)$")
	if n then return tonumber(n) end
	return nil
end

local function ScanHierarchy()
	if ScanState.Scanning then return end
	ScanState.Scanning = true
	ScanStatusLabel.Text = "Scanning hierarchy..."
	ScanStatusLabel.TextColor3 = COLORS.Warn
	CompatSpawn(function()
		local seen = {}
		local found = 0
		local withId = 0
		local function collect(inst, depth)
			if depth > 6 then return end
			for _, ch in ipairs(inst:GetChildren()) do
				local isItem = false
				if ch:IsA("Tool") or ch:IsA("Accessory") then
					isItem = true
				elseif ch:IsA("Model") and not IsNpcLike(ch.Name) then
					if ch.PrimaryPart or ch:FindFirstChild("Handle") then isItem = true end
				end
				if isItem and not seen[ch.Name] then
					seen[ch.Name] = true
					found = found + 1
					local id = TryExtractId(ch)
					if id then
						withId = withId + 1
						AddScanItem(id, ch.Name)
					end
					CompatWait()
				end
				if ch:IsA("Folder") or ch:IsA("Model") or ch:IsA("Actor") then
					collect(ch, depth + 1)
				end
			end
		end
		pcall(function() collect(game:GetService("ReplicatedStorage"), 0) end)
		pcall(function() collect(workspace, 0) end)
		ScanState.Scanning = false
		ScanStatusLabel.Text = "Hier done. Found: " .. found .. " | w/ID: " .. withId
		ScanStatusLabel.TextColor3 = COLORS.Good
		RefreshScanStatus()
	end)
end

ScanHierBtn.MouseButton1Click:Connect(function() CompatSpawn(ScanHierarchy) end)

local ProbeWatch = { Watching = false, LastAdded = nil, Conns = {} }

local function StartProbeWatch()
	ProbeWatch.LastAdded = nil
	ProbeWatch.Watching = true

	local function bindContainer(container)
		if not container then return end
		local c = container.ChildAdded:Connect(function(child)
			if ProbeWatch.Watching and child:IsA("Tool") then
				ProbeWatch.LastAdded = child.Name
			end
		end)
		table.insert(ProbeWatch.Conns, c)
	end

	bindContainer(LocalPlayer:FindFirstChild("Backpack"))
	bindContainer(LocalPlayer.Character)

	pcall(function()
		local nc = game:GetService("ReplicatedStorage").Shared.Universe.Network.RemoteEvent.NotifyClient
		if nc then
			local c = nc.OnClientEvent:Connect(function(...)
				if not ProbeWatch.Watching then return end
				if ProbeWatch.LastAdded then return end
				local args = { ... }
				for _, a in ipairs(args) do
					if type(a) == "string" and #a > 2 and #a < 60 then
						local looksLikeMsg = string.find(a, "%s") and #a > 15
						if not looksLikeMsg then
							ProbeWatch.LastAdded = a
							break
						end
					end
				end
			end)
			table.insert(ProbeWatch.Conns, c)
		end
	end)
end

local function StopProbeWatch()
	ProbeWatch.Watching = false
	local result = ProbeWatch.LastAdded
	for _, c in ipairs(ProbeWatch.Conns) do pcall(function() c:Disconnect() end) end
	ClearTable(ProbeWatch.Conns)
	return result
end

local function ProbeRange(maxId)
	if ScanState.Probing then return end
	ScanState.Probing = true
	ScanState.ProbeCurrent = 0
	ScanState.ProbeMax = maxId or 1200
	ScanState.ProbeHits = 0
	ScanState.ProbeMisses = 0
	ScanStatusLabel.Text = "Probing..."
	ScanStatusLabel.TextColor3 = COLORS.Warn

	CompatSpawn(function()
		local remote = GetStoreRemoteShared()
		if not remote then
			ScanState.Probing = false
			ScanStatusLabel.Text = "Err: remote tidak ada"
			ScanStatusLabel.TextColor3 = COLORS.Bad
			return
		end
		for i = 1, ScanState.ProbeMax do
			if not ScanState.Probing then break end
			ScanState.ProbeCurrent = i
			ScanProbeBar.Size = UDim2.new(i / ScanState.ProbeMax, 0, 1, 0)
			ScanProbeLabel.Text = string.format("ID %d/%d | Hits: %d | Miss: %d", i, ScanState.ProbeMax, ScanState.ProbeHits, ScanState.ProbeMisses)

			StartProbeWatch()
			pcall(function() remote:FireServer(i) end)
			CompatWait(ScanState.ProbeDelay)
			local name = StopProbeWatch()

			if name then
				ScanState.ProbeHits = ScanState.ProbeHits + 1
				if ScanState.Items[i] then
					AddScanItem(i, name)
				else
					AddScanItem(i, name)
				end
			else
				ScanState.ProbeMisses = ScanState.ProbeMisses + 1
			end
		end
		ScanState.Probing = false
		ScanProbeLabel.Text = "Done. Hits: " .. ScanState.ProbeHits
		ScanStatusLabel.Text = "Probe complete. Hits: " .. ScanState.ProbeHits
		ScanStatusLabel.TextColor3 = COLORS.Good
		ScanProbeBar.Size = UDim2.new(1, 0, 1, 0)
	end)
end

ScanProbeBtn.MouseButton1Click:Connect(function() ProbeRange(ScanState.ProbeMax) end)

ScanStopBtn.MouseButton1Click:Connect(function()
	ScanState.Probing = false
	ScanState.Scanning = false
	ScanState.Firing = false
	StopActionableCollect()
	ScanProbeLabel.Text = "Stopped."
end)

--==================================================
-- ACTIONABLE AUTO-COLLECTOR (INFINITE)
-- Starts at 1 and increments forever. Each number is fired once.
-- It stops only when Collecting is set to false (STOP COLLECT / STOP).
--==================================================
local ScanCollectStatus = MakeLabel(ScanCard, "Collect: Idle", UDim2.new(1, -24, 0, 18), UDim2.new(0, 12, 0, 382), FONT_BOLD, 12, GetTheme().Accent2)

local function GetActionableRemote()
	local ok, remote = pcall(function()
		local rs = game:GetService("ReplicatedStorage")
		local shared = rs:FindFirstChild("Shared")
		local universe = shared and shared:FindFirstChild("Universe")
		local network = universe and universe:FindFirstChild("Network")
		local remoteFolder = network and network:FindFirstChild("RemoteEvent")
		local actionable = remoteFolder and remoteFolder:FindFirstChild("Actionable")
		return actionable
	end)
	if ok and remote then
		local isRemoteEvent = false
		pcall(function() isRemoteEvent = remote:IsA("RemoteEvent") end)
		if isRemoteEvent then
			return remote
		end
	end
	return nil
end

local function StopActionableCollect()
	if not ScanState.Collecting then return end
	ScanState.Collecting = false
	ScanCollectStatus.Text = "Collect: Stopped at " .. tostring(ScanState.CollectCurrent) .. " | Fired: " .. tostring(ScanState.CollectFired)
	ScanCollectStatus.TextColor3 = COLORS.Warn
end

local function StartActionableCollect()
	if ScanState.Collecting then return false end
	local remote = GetActionableRemote()
	if not remote then
		ScanState.CollectLastError = "Actionable RemoteEvent not found"
		ScanCollectStatus.Text = "Collect: Remote not found"
		ScanCollectStatus.TextColor3 = COLORS.Bad
		return false
	end

	ScanState.Collecting = true
	ScanState.CollectCurrent = 0
	ScanState.CollectFired = 0
	ScanState.CollectErrors = 0
	ScanState.CollectLastError = ""
	ScanCollectStatus.Text = "Collect: Running from 1 | Fired: 0"
	ScanCollectStatus.TextColor3 = COLORS.Good

	CompatSpawn(function()
		local id = 1
		while ScanState.Collecting do
			local ok, err = pcall(function()
				remote:FireServer(id)
			end)

			ScanState.CollectCurrent = id
			if ok then
				ScanState.CollectFired = ScanState.CollectFired + 1
			else
				ScanState.CollectErrors = ScanState.CollectErrors + 1
				ScanState.CollectLastError = tostring(err)
			end

			if ScanState.Collecting then
				ScanCollectStatus.Text = string.format(
					"Collect: %s | ID: %s | Fired: %d | Err: %d",
					ok and "Running" or "Running / error",
					tostring(id),
					ScanState.CollectFired,
					ScanState.CollectErrors
				)
			end

			id = id + 1
			CompatWait(ScanState.CollectDelay)
		end
	end)
	return true
end

local ScanCollectBtn = MakeButton(ScanCard, "COLLECT INF", UDim2.new(0.5, -18, 0, 30), UDim2.new(0, 12, 0, 406), function()
	StartActionableCollect()
end)
ScanCollectBtn.TextSize = 12

local ScanCollectStopBtn = MakeButton(ScanCard, "STOP COLLECT", UDim2.new(0.5, -18, 0, 30), UDim2.new(0.5, 6, 0, 406), function()
	StopActionableCollect()
end)
ScanCollectStopBtn.TextSize = 12

local ScanPickAllBtn = MakeButton(ScanCard, "PICKUP ALL", UDim2.new(0.5, -18, 0, 30), UDim2.new(0, 12, 0, 444), function()
	if ScanState.Firing then return end
	if #ScanState.Order == 0 then return end
	ScanState.Firing = true
	CompatSpawn(function()
		for _, id in ipairs(ScanState.Order) do
			if not ScanState.Firing then break end
			FireIdOnce(id)
			CompatWait(ScanState.Delay)
		end
		ScanState.Firing = false
	end)
end)
ScanPickAllBtn.TextSize = 12

local ScanClearBtn = MakeButton(ScanCard, "CLEAR", UDim2.new(0.5, -18, 0, 30), UDim2.new(0.5, 6, 0, 444), function()
	for _, row in pairs(ScanRows) do
		if row and row.Parent then row:Destroy() end
	end
	ClearTable(ScanRows)
	ClearTable(ScanState.Items)
	ClearTable(ScanState.Order)
	ScanState.Firing = false
	ScanState.Probing = false
	RefreshScanStatus()
	RefreshScanCanvas()
end)
ScanClearBtn.TextSize = 12

MakeLabel(ScanCard, "Delay", UDim2.new(0.25, 0, 0, 26), UDim2.new(0, 12, 0, 482), FONT_BOLD, 12, COLORS.Text)
local ScanDelayLabel = MakeLabel(ScanCard, string.format("%.2fs", ScanState.Delay), UDim2.new(0, 40, 0, 26), UDim2.new(1, -124, 0, 482), FONT_BOLD, 12, GetTheme().Accent2, Enum.TextXAlignment.Center)
local ScanDelayMinus = MakeButton(ScanCard, "-", UDim2.new(0, 28, 0, 26), UDim2.new(1, -76, 0, 482), function()
	ScanState.Delay = math.max(0, math.floor((ScanState.Delay - 0.05) * 100 + 0.5) / 100)
	ScanDelayLabel.Text = string.format("%.2fs", ScanState.Delay)
end)
ScanDelayMinus.TextSize = 12
local ScanDelayPlus = MakeButton(ScanCard, "+", UDim2.new(0, 28, 0, 26), UDim2.new(1, -44, 0, 482), function()
	ScanState.Delay = math.min(2, math.floor((ScanState.Delay + 0.05) * 100 + 0.5) / 100)
	ScanDelayLabel.Text = string.format("%.2fs", ScanState.Delay)
end)
ScanDelayPlus.TextSize = 12

AddCleanup(function()
	ScanState.Firing = false
	ScanState.Probing = false
	ScanState.Scanning = false
	ScanState.Collecting = false
	for _, c in ipairs(ProbeWatch.Conns) do pcall(function() c:Disconnect() end) end
	ClearTable(ProbeWatch.Conns)
end)

--==================================================
-- [19] SETTINGS PANEL: DISPLAY
--==================================================
local ApplyWindowLayout

--==================================================
-- [20] SETTINGS PANEL: RUNTIME STATE HELPERS
--==================================================

--==================================================
-- [21] DRAG ENGINE
--==================================================
local DragState = { Active = false, Target = nil, StartInput = nil, StartAbs = nil, Moved = false }
local function BindDrag(target, handle, onMoveEnd)
	local dragging = false
	local startInput = nil
	local startAbs = nil
	local movedPx = 0
	TrackConnection(handle.InputBegan:Connect(function(input)
		if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then return end
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
		if input.UserInputType ~= Enum.UserInputType.MouseMovement and input.UserInputType ~= Enum.UserInputType.Touch then return end
		local delta = Vector2.new(input.Position.X, input.Position.Y) - Vector2.new(startInput.X, startInput.Y)
		movedPx = math.max(movedPx, delta.Magnitude)
		if movedPx < CONFIG.DragThreshold then return end
		DragState.Moved = true
		local targetSize = target.AbsoluteSize
		local newPos = ClampAbsolute(startAbs + delta, targetSize)
		target.Position = UDim2.fromOffset(newPos.X, newPos.Y)
		target.AnchorPoint = Vector2.new(0, 0)
	end))
	TrackConnection(UserInputService.InputEnded:Connect(function(input)
		if not dragging then return end
		if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then return end
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
	Name = "MiniLogo", Size = UDim2.new(0, MINI_SIZE, 0, MINI_SIZE),
	Position = UDim2.new(0, 0, 0, 0), BackgroundTransparency = 1, BorderSizePixel = 0,
	Visible = false, Parent = ScreenGui,
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
local MiniHit = Create("TextButton", { Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Text = "", AutoButtonColor = false, ZIndex = 5, Parent = MiniLogo })

--==================================================
-- [23] FLOATING GUI MANAGER
--==================================================
local function SetMainAbsolute(pos, size)
	local clamped = ClampAbsolute(pos, size)
	MainWindow.Position = UDim2.fromOffset(clamped.X, clamped.Y)
	MainWindow.Size = UDim2.fromOffset(size.X, size.Y)
	STATE.MainPosition = clamped
	return clamped
end
local function SetMiniAbsolute(pos)
	local vp = GetViewport()
	local x = ClampNumber(pos.X, 0, math.max(0, vp.X - MINI_SIZE))
	local y = ClampNumber(pos.Y, 0, math.max(0, vp.Y - MINI_SIZE))
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
	local pos = (keepCenter or not STATE.MainPosition) and ComputeCenteredPosition(size) or ClampAbsolute(STATE.MainPosition, size)
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
	local cx = mainCenter.X + mainSize.X / 2
	local cy = mainCenter.Y + mainSize.Y / 2
	SetMiniAbsolute(Vector2.new(cx - MINI_SIZE / 2, cy - MINI_SIZE / 2))
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
	local cx = miniPos.X + MINI_SIZE / 2
	local cy = miniPos.Y + MINI_SIZE / 2
	local pos = Vector2.new(cx - size.X / 2, cy - size.Y / 2)
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
local function SetSettingsVisible(v)
	STATE.SettingsOpen = v
	SettingsScroll.Visible = v
	HomeScroll.Visible = not v
	SettingsBtn.Text = v and "⌂" or "⚙"
end

--==================================================
-- [26] SETTINGS: UI BUILDERS
--==================================================
local SettingsCards = {}
local function NewSettingsCard(title, height)
	local c = MakeCard(SettingsScroll, title, UDim2.new(1, -4, 0, height), nil)
	table.insert(SettingsCards, c)
	return c
end
local function MakeToggleRow(parent, label, y, getValue, onChange)
	local row = MakeFrame(parent, UDim2.new(1, -24, 0, 44), UDim2.new(0, 12, 0, y), COLORS.Track, 0.1)
	MakeCorner(row, 10)
	MakeLabel(row, label, UDim2.new(1, -110, 1, 0), UDim2.new(0, 12, 0, 0), FONT_BOLD, 14, COLORS.Text)
	local btn = MakeButton(row, "", UDim2.new(0, 88, 0, 32), UDim2.new(1, -96, 0.5, -16), function()
		local nv = not getValue()
		onChange(nv)
		btn.Text = nv and "ON" or "OFF"
		btn.TextColor3 = nv and COLORS.Good or COLORS.Bad
	end)
	btn.Text = getValue() and "ON" or "OFF"
	btn.TextColor3 = getValue() and COLORS.Good or COLORS.Bad
	return row
end
local function MakeCycleRow(parent, label, y, options, getCurrent, onChange, fmt)
	local row = MakeFrame(parent, UDim2.new(1, -24, 0, 44), UDim2.new(0, 12, 0, y), COLORS.Track, 0.1)
	MakeCorner(row, 10)
	MakeLabel(row, label, UDim2.new(1, -150, 1, 0), UDim2.new(0, 12, 0, 0), FONT_BOLD, 14, COLORS.Text)
	local function ct() local v = getCurrent() return fmt and fmt(v) or tostring(v) end
	local btn = MakeButton(row, ct(), UDim2.new(0, 132, 0, 32), UDim2.new(1, -140, 0.5, -16), function()
		local cur = getCurrent()
		local idx = 1
		for i, o in ipairs(options) do if o == cur then idx = i break end end
		onChange(options[(idx % #options) + 1])
		btn.Text = ct()
	end)
	return row, btn
end
local function MakeStepperRow(parent, label, y, minV, maxV, step, getCurrent, onChange, fmt)
	local row = MakeFrame(parent, UDim2.new(1, -24, 0, 44), UDim2.new(0, 12, 0, y), COLORS.Track, 0.1)
	MakeCorner(row, 10)
	MakeLabel(row, label, UDim2.new(0.45, 0, 1, 0), UDim2.new(0, 12, 0, 0), FONT_BOLD, 14, COLORS.Text)
	local vl = MakeLabel(row, "", UDim2.new(0, 70, 0, 22), UDim2.new(1, -150, 0.5, -11), FONT_BOLD, 14, GetTheme().Accent2, Enum.TextXAlignment.Center)
	local function refresh() local v = getCurrent() vl.Text = fmt and fmt(v) or tostring(v) end
	refresh()
	MakeButton(row, "-", UDim2.new(0, 40, 0, 32), UDim2.new(1, -116, 0.5, -16), function()
		onChange(math.max(minV, getCurrent() - step)); refresh()
	end)
	MakeButton(row, "+", UDim2.new(0, 40, 0, 32), UDim2.new(1, -52, 0.5, -16), function()
		onChange(math.min(maxV, getCurrent() + step)); refresh()
	end)
	return row
end

--==================================================
-- [27] SETTINGS: DPI / GUI SCALE
--==================================================
local function SetScale(value)
	local valid = false
	for _, opt in ipairs(CONFIG.ScaleOptions) do
		if math.abs(opt - value) < 0.001 then valid = true break end
	end
	if not valid then return false end
	CONFIG.Scale = value
	if STATE.Open and not STATE.Minimized then ApplyWindowLayout(false) end
	return true
end
local function ScaleText(v) return string.format("%d%%", math.floor(v * 100 + 0.5)) end

function ApplyTheme()
	local t = GetTheme()
	MainWindow.BackgroundColor3 = t.Base
	MainStroke.Color = t.Accent
	MainGradient.Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, t.Base), ColorSequenceKeypoint.new(1, t.Base2) })
	AccentLine.BackgroundColor3 = t.Accent2
	HeaderLogoRing.BackgroundColor3 = t.Accent
	HeaderLogoCore.BackgroundColor3 = t.Accent2
	MiniBody.BackgroundColor3 = t.Base2
	MiniCore.BackgroundColor3 = t.Accent2
	HomeScroll.ScrollBarImageColor3 = t.Accent
	SettingsScroll.ScrollBarImageColor3 = t.Accent2
end

--==================================================
-- [28] SETTINGS: BUILD UI
--==================================================
local function BuildSettingsUI()
	local displayCard = NewSettingsCard("DISPLAY", 260)
	displayCard.LayoutOrder = 1
	MakeCycleRow(displayCard, "GUI Scale / DPI", 36, CONFIG.ScaleOptions, function() return CONFIG.Scale end, function(v) SetScale(v) end, ScaleText)
	MakeStepperRow(displayCard, "Window Opacity", 88, 0.02, 0.5, 0.02, function() return CONFIG.WindowOpacity end, function(v)
		CONFIG.WindowOpacity = v
		if STATE.Open and not STATE.Minimized then MainWindow.BackgroundTransparency = v end
	end, function(v) return string.format("%.2f", v) end)
	MakeStepperRow(displayCard, "Corner Radius", 140, 6, 24, 2, function() return CONFIG.CornerRadius end, function(v) CONFIG.CornerRadius = v end, function(v) return tostring(v) end)
	MakeStepperRow(displayCard, "Border Intensity", 192, 0, 1, 0.1, function() return CONFIG.BorderIntensity end, function(v)
		CONFIG.BorderIntensity = v
		MainStroke.Transparency = 1 - v
	end, function(v) return string.format("%.1f", v) end)

	local glassCard = NewSettingsCard("GLASS", 120)
	glassCard.LayoutOrder = 2
	MakeStepperRow(glassCard, "Glass Intensity", 36, 0, 1, 0.1, function() return CONFIG.GlassIntensity end, function(v)
		CONFIG.GlassIntensity = v
		MainGradient.Transparency = NumberSequence.new(1 - v)
	end, function(v) return string.format("%.1f", v) end)

	local animCard = NewSettingsCard("ANIMATION", 420)
	animCard.LayoutOrder = 3
	local rows = {
		{"Master Animation", "AnimationEnabled"}, {"Soft Animation", "SoftAnimation"},
		{"Logo Animation", "LogoAnimation"}, {"Radar Animation", "RadarAnimation"},
		{"Particle Animation", "ParticleAnimation"}, {"Scanline", "Scanline"},
		{"Hover Animation", "HoverAnimation"}, {"Click Animation", "ClickAnimation"},
		{"Transition Animation", "TransitionAnimation"},
	}
	local ay = 36
	for _, p in ipairs(rows) do
		MakeToggleRow(animCard, p[1], ay, function() return CONFIG[p[2]] end, function(v) CONFIG[p[2]] = v end)
		ay = ay + 46
	end
	MakeCycleRow(animCard, "Animation Speed", ay, {0.5, 0.75, 1, 1.25, 1.5}, function() return CONFIG.AnimationSpeed end, function(v) CONFIG.AnimationSpeed = v end, function(v) return string.format("%.2fx", v) end)

	local visualCard = NewSettingsCard("VISUAL", 420)
	visualCard.LayoutOrder = 4
	MakeCycleRow(visualCard, "Theme", 36, {"Cyber Blue", "Neon Cyan", "Purple Anime", "Crimson", "Emerald", "Ice"},
		function() return CONFIG.Theme end,
		function(v) CONFIG.Theme = v; ApplyTheme() end)
	MakeStepperRow(visualCard, "Glow Intensity", 88, 0, 1, 0.1, function() return CONFIG.GlowIntensity end, function(v) CONFIG.GlowIntensity = v end, function(v) return string.format("%.1f", v) end)
	MakeStepperRow(visualCard, "Particle Density", 140, 0, 30, 2, function() return CONFIG.ParticleDensity end, function(v) CONFIG.ParticleDensity = v end, function(v) return tostring(v) end)
	MakeToggleRow(visualCard, "HUD Decoration", 192, function() return CONFIG.HUDDecoration end, function(v) CONFIG.HUDDecoration = v end)
	MakeToggleRow(visualCard, "Background Grid", 244, function() return CONFIG.BackgroundGrid end, function(v) CONFIG.BackgroundGrid = v end)

	local windowCard = NewSettingsCard("WINDOW", 240)
	windowCard.LayoutOrder = 5
	MakeToggleRow(windowCard, "Remember Position", 36, function() return CONFIG.RememberPosition end, function(v) CONFIG.RememberPosition = v end)
	local cb = MakeButton(windowCard, "Center Window", UDim2.new(1, -24, 0, 40), UDim2.new(0, 12, 0, 92), function() ApplyWindowLayout(true) end)
	MakeCorner(cb, 10)
	local rp = MakeButton(windowCard, "Reset Position", UDim2.new(1, -24, 0, 40), UDim2.new(0, 12, 0, 140), function()
		STATE.MainPosition = nil
		STATE.MiniPosition = nil
		ApplyWindowLayout(true)
	end)
	MakeCorner(rp, 10)
	local rs = MakeButton(windowCard, "Reset Settings", UDim2.new(1, -24, 0, 40), UDim2.new(0, 12, 0, 188), function() _G.vanz.ResetSettings() end)
	MakeCorner(rs, 10)

	local perfCard = NewSettingsCard("PERFORMANCE", 220)
	perfCard.LayoutOrder = 6
	MakeToggleRow(perfCard, "Low FX Mode", 36, function() return CONFIG.LowFXMode end, function(v) CONFIG.LowFXMode = v end)
	MakeToggleRow(perfCard, "FPS Friendly Mode", 88, function() return CONFIG.FPSFriendly end, function(v) CONFIG.FPSFriendly = v end)
	MakeToggleRow(perfCard, "Disable Particles", 140, function() return CONFIG.DisableParticles end, function(v) CONFIG.DisableParticles = v end)
	MakeToggleRow(perfCard, "Disable Heavy Animation", 192, function() return CONFIG.DisableHeavyAnimation end, function(v) CONFIG.DisableHeavyAnimation = v end)
end

--==================================================
-- [29] HOME CARDS: EXTRA DECORATION (HUD)
--==================================================
local HudLayer = MakeFrame(MainWindow, UDim2.new(1, 0, 1, 0), UDim2.new(0, 0, 0, 0), COLORS.Card, 1)
HudLayer.ZIndex = 1
local function MakeBracket(isLeft, isTop)
	local bx = isLeft and 0 or 1
	local by = isTop and 0 or 1
	MakeFrame(HudLayer, UDim2.new(0, 14, 0, 2), UDim2.new(bx, isLeft and 6 or -20, by, isTop and 6 or -8), GetTheme().Accent, 0.3)
	MakeFrame(HudLayer, UDim2.new(0, 2, 0, 14), UDim2.new(bx, isLeft and 6 or -8, by, isTop and 6 or -20), GetTheme().Accent, 0.3)
end
MakeBracket(true, true); MakeBracket(false, true); MakeBracket(true, false); MakeBracket(false, false)
local ScanLineFx = MakeFrame(HudLayer, UDim2.new(1, 0, 0, 1), UDim2.new(0, 0, 0, 0), GetTheme().Accent2, 0.75)
local MicroText = MakeLabel(HudLayer, "VANZ CORE • SYSTEM ONLINE", UDim2.new(0, 200, 0, 12), UDim2.new(0, 12, 1, -16), FONT_TEXT, 10, COLORS.SubText)
MicroText.TextTransparency = 0.25

--==================================================
-- [30] ANIMATION ENGINE
--==================================================
local AnimTime = 0
local function AnimationTick(dt)
	if not CONFIG.AnimationEnabled or CONFIG.LowFXMode or CONFIG.DisableHeavyAnimation then return end
	AnimTime = AnimTime + dt * CONFIG.AnimationSpeed
	if CONFIG.LogoAnimation and STATE.Open and not STATE.Minimized then
		local pulse = 0.9 + 0.1 * math.sin(AnimTime * 2.4)
		HeaderLogoRing.Size = UDim2.new(pulse, 0, pulse, 0)
		HeaderLogoRing.Position = UDim2.new((1 - pulse) / 2, 0, (1 - pulse) / 2, 0)
	end
	if CONFIG.Scanline and CONFIG.HUDDecoration and STATE.Open then
		local span = MainWindow.AbsoluteSize.Y
		if span > 0 then ScanLineFx.Position = UDim2.new(0, 0, 0, (AnimTime * 60) % span) end
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
		Position = UDim2.new(0, ClampNumber(p.Position.X.Offset + dx, 0, w), 0, ClampNumber(p.Position.Y.Offset + dy, 0, h)),
		BackgroundTransparency = 1,
	})
	TrackTween(tw)
	tw:Play()
	CompatDelay(dur, function()
		ParticleCount = math.max(0, ParticleCount - 1)
		if p and p.Parent then p:Destroy() end
	end)
end
local ParticleAcc = 0

--==================================================
-- [32] DATA UPDATE: HELPERS
--==================================================
local function GetCharacter() return LocalPlayer.Character end
local function GetHumanoid()
	local c = GetCharacter()
	if c then return c:FindFirstChildOfClass("Humanoid") end
	return nil
end
local function GetRootPart()
	local c = GetCharacter()
	if c then return c:FindFirstChild("HumanoidRootPart") end
	return nil
end

--==================================================
-- [33] DATA UPDATE: FAST
--==================================================
local function UpdateCharacterCard(h, root)
	local c = GetCharacter()
	if h then
		CharLines["WalkSpeed"].Text = "WalkSpeed: " .. ToStr(h.WalkSpeed)
		CharLines["JumpPower"].Text = "JumpPower: " .. ToStr(h.JumpPower)
		CharLines["Health"].Text = "Health: " .. ToStr(h.Health, 1)
		CharLines["MaxHealth"].Text = "MaxHealth: " .. ToStr(h.MaxHealth, 1)
		local pct = (h.MaxHealth and h.MaxHealth > 0) and (h.Health / h.MaxHealth * 100) or 0
		CharLines["Health %"].Text = "Health %: " .. string.format("%.1f%%", pct)
		CharLines["HipHeight"].Text = "HipHeight: " .. ToStr(h.HipHeight, 2)
		CharLines["AutoRotate"].Text = "AutoRotate: " .. tostring(h.AutoRotate)
		CharLines["PlatformStand"].Text = "PlatformStand: " .. tostring(h.PlatformStand)
		CharLines["RigType"].Text = "RigType: " .. tostring(h.RigType and h.RigType.Name or "N/A")
		CharLines["Character State"].Text = "Character State: " .. tostring(h:GetState().Name)
	else
		for _, k in ipairs({"WalkSpeed","JumpPower","Health","MaxHealth","Health %","HipHeight","AutoRotate","PlatformStand","RigType","Character State"}) do
			CharLines[k].Text = k .. ": N/A"
		end
	end
	MoveLines["Character Name"].Text = "Character Name: " .. (c and c.Name or "N/A")
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
		for _, k in ipairs({"Pos X","Pos Y","Pos Z","Vel X","Vel Y","Vel Z","Magnitude","Facing"}) do
			PosLines[k].Text = k .. ": N/A"
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
		for _, k in ipairs({"MoveDirection","Grounded","Floor Material","Seat Status","Humanoid State"}) do
			MoveLines[k].Text = k .. ": N/A"
		end
	end
end

local function UpdateHealthCard(h)
	if not h or not h.MaxHealth or h.MaxHealth <= 0 then
		HealthText.Text = "N/A"
		HealthFill.Size = UDim2.new(0, 0, 1, 0)
		return
	end
	local pct = ClampNumber(h.Health / h.MaxHealth, 0, 1)
	HealthFill.Size = UDim2.new(pct, 0, 1, 0)
	HealthText.Text = string.format("%d / %d", math.floor(h.Health + 0.5), math.floor(h.MaxHealth + 0.5))
	if pct > 0.6 then HealthFill.BackgroundColor3 = COLORS.Good
	elseif pct > 0.3 then HealthFill.BackgroundColor3 = COLORS.Warn
	else HealthFill.BackgroundColor3 = COLORS.Bad end
end

local function UpdateSessionCard()
	SessionLines["FPS"].Text = "FPS: " .. tostring(math.floor(STATE.LastFPS + 0.5))
	local pingOk, pingText = pcall(function()
		local ping = Stats.Network.ServerStatsItem["Data Ping"]:GetValue()
		return string.format("%d ms", math.floor(ping + 0.5))
	end)
	SessionLines["Ping"].Text = "Ping: " .. (pingOk and pingText or "N/A")
	local up = os.clock() - STATE.SessionStart
	SessionLines["Uptime"].Text = "Uptime: " .. string.format("%02d:%02d", math.floor(up / 60), math.floor(up % 60))
	local memOk, memText = pcall(function() return string.format("%.1f MB", Stats:GetTotalMemoryUsageMb()) end)
	SessionLines["Memory"].Text = "Memory: " .. (memOk and memText or "N/A")
	SessionLines["Heartbeat"].Text = string.format("Heartbeat: %.1f ms", (STATE.LastFrameDt or 0) * 1000)
	SessionLines["Client State"].Text = "Client State: " .. (STATE.Open and (STATE.Minimized and "Minimized" or "Open") or "Closed")
	SessionLines["System"].Text = "System: " .. (STATE.DeviceText or "N/A")
end

local function UpdatePlayerInfo()
	local c = GetCharacter()
	local h = GetHumanoid()
	local function setInfo(k, t)
		if InfoLines[k] then InfoLines[k].Text = k .. ": " .. (t or "N/A") end
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
	pcall(function() setInfo("Camera Mode", tostring(LocalPlayer.CameraMode and LocalPlayer.CameraMode.Name or "N/A")) end)
	pcall(function() setInfo("Field Of View", string.format("%.1f", Camera.FieldOfView)) end)
	pcall(function() setInfo("Graphics Quality", tostring(settings().Rendering.QualityLevel)) end)
	local up = os.clock() - STATE.SessionStart
	setInfo("Session Time", string.format("%02d:%02d", math.floor(up / 60), math.floor(up % 60)))
	pcall(function() setInfo("Server JobId", game.JobId ~= "" and game.JobId or "N/A") end)
	pcall(function() setInfo("PlaceId", tostring(game.PlaceId)) end)
	pcall(function() setInfo("GameId", tostring(game.GameId)) end)
end

--==================================================
-- [34] DATA UPDATE: SLOW
--==================================================
local function UpdateSlowData()
	pcall(function()
		local mt = LocalPlayer.MembershipType
		local t = (mt == Enum.MembershipType.Premium and "Premium") or (mt == Enum.MembershipType.None and "None") or "N/A"
		ProfileMembership.Text = "Membership: " .. t
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
	for _, c in ipairs(HumanoidConnections) do pcall(function() c:Disconnect() end) end
	ClearTable(HumanoidConnections)
end
local function BindCharacter(char)
	DisconnectHumanoidEvents()
	if not char then return end
	local h = char:WaitForChild("Humanoid", 5)
	if h then
		table.insert(HumanoidConnections, h.Died:Connect(function() UpdateHealthCard(nil) end))
		table.insert(HumanoidConnections, h.StateChanged:Connect(function() end))
	end
end
TrackConnection(LocalPlayer.CharacterAdded:Connect(function(char) CompatDefer(function() BindCharacter(char) end) end))
TrackConnection(LocalPlayer:GetPropertyChangedSignal("Team"):Connect(function() UpdateSlowData() end))

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
		local density = ClampNumber(CONFIG.ParticleDensity, 0, 30)
		for _ = 1, math.floor(density / 10) do SpawnParticle() end
	end
	STATE.FastTimer = STATE.FastTimer + dt
	if STATE.FastTimer >= CONFIG.FastUpdateRate then
		STATE.FastTimer = 0
		if STATE.Open and not STATE.Minimized and not STATE.SettingsOpen then
			local h = GetHumanoid()
			local r = GetRootPart()
			pcall(UpdateCharacterCard, h, r)
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
	if wasDrag then STATE.MainPosition = ReadMainAbsolute() end
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
SettingsBtn.MouseButton1Click:Connect(function() SetSettingsVisible(not STATE.SettingsOpen) end)
MinimizeBtn.MouseButton1Click:Connect(function() MinimizeToLogo() end)
CloseBtn.MouseButton1Click:Connect(function() DestroyAll() end)

--==================================================
-- [39] API / GLOBAL
--==================================================
_G.vanz = _G.vanz or {}

_G.vanz.Open = function() if STATE.Destroyed then return false end ShowMainWindow() return true end
_G.vanz.Hide = function() if STATE.Destroyed then return false end MainWindow.Visible = false MiniLogo.Visible = false STATE.Open = false return true end
_G.vanz.Minimize = function() if STATE.Destroyed then return false end MinimizeToLogo() return true end
_G.vanz.Restore = function() if STATE.Destroyed then return false end RestoreFromLogo() return true end
_G.vanz.Toggle = function()
	if STATE.Destroyed then return false end
	if STATE.Open then _G.vanz.Hide() else _G.vanz.Open() end
	return true
end
_G.vanz.SetScale = function(v) if STATE.Destroyed then return false end return SetScale(v) end
_G.vanz.GetScale = function() return CONFIG.Scale end
_G.vanz.GetState = function()
	return { Open = STATE.Open, Minimized = STATE.Minimized, Scale = CONFIG.Scale, Theme = CONFIG.Theme, Destroyed = STATE.Destroyed }
end
_G.vanz.ResetSettings = function()
	if STATE.Destroyed then return false end
	for k, v in pairs(DEFAULT_CONFIG_SNAPSHOT) do CONFIG[k] = v end
	ApplyTheme()
	ApplyWindowLayout(true)
	return true
end

_G.vanz.StartAutoFire = function() if STATE.Destroyed then return false end CheatRun() return true end
_G.vanz.StopAutoFire = function() if STATE.Destroyed then return false end CheatStop() return true end
_G.vanz.GetAutoFireState = function()
	return { Running = CheatState.Running, Current = CheatState.Current, Max = CheatState.Max, Delay = CheatState.Delay, Repeats = CheatState.Repeats, Logged = CheatState.Logged }
end
_G.vanz.SetAutoFireDelay = function(v)
	if STATE.Destroyed then return false end
	local n = tonumber(v); if not n then return false end
	CheatState.Delay = math.floor(ClampNumber(n, 0, 2) * 100 + 0.5) / 100
	CheatDelayValue.Text = string.format("%.2fs", CheatState.Delay)
	return true
end

_G.vanz.ScannerScanHierarchy = function() if STATE.Destroyed then return false end CompatSpawn(ScanHierarchy) return true end
_G.vanz.ScannerProbe = function(maxId) if STATE.Destroyed then return false end ProbeRange(tonumber(maxId) or ScanState.ProbeMax) return true end
_G.vanz.ScannerStop = function() if STATE.Destroyed then return false end ScanState.Probing = false ScanState.Scanning = false ScanState.Firing = false StopActionableCollect() return true end
_G.vanz.StartAutoCollect = function()
	if STATE.Destroyed then return false end
	return StartActionableCollect()
end
_G.vanz.StopAutoCollect = function()
	if STATE.Destroyed then return false end
	StopActionableCollect()
	return true
end
_G.vanz.GetAutoCollectState = function()
	return {
		Running = ScanState.Collecting,
		Current = ScanState.CollectCurrent,
		Fired = ScanState.CollectFired,
		Errors = ScanState.CollectErrors,
		Delay = ScanState.CollectDelay,
		LastError = ScanState.CollectLastError,
	}
end
_G.vanz.ScannerAdd = function(id, name)
	if STATE.Destroyed then return false end
	local n = tonumber(id); if not n then return false end
	n = math.floor(n)
	if not name or name == "" then name = "Item " .. tostring(n) end
	AddScanItem(n, name)
	return true
end
_G.vanz.ScannerRemove = function(id)
	if STATE.Destroyed then return false end
	local n = tonumber(id); if not n then return false end
	n = math.floor(n)
	ScanState.Items[n] = nil
	for i = #ScanState.Order, 1, -1 do
		if ScanState.Order[i] == n then table.remove(ScanState.Order, i) end
	end
	RemoveScanRow(n)
	RefreshScanStatus()
	RefreshScanCanvas()
	return true
end
_G.vanz.ScannerFire = function(id)
	if STATE.Destroyed then return false end
	local n = tonumber(id); if not n then return false end
	return FireIdOnce(math.floor(n))
end
_G.vanz.ScannerFireAll = function()
	if STATE.Destroyed then return false end
	if ScanState.Firing then return false end
	if #ScanState.Order == 0 then return false end
	ScanState.Firing = true
	CompatSpawn(function()
		for _, id in ipairs(ScanState.Order) do
			if not ScanState.Firing then break end
			FireIdOnce(id)
			CompatWait(ScanState.Delay)
		end
		ScanState.Firing = false
	end)
	return true
end
_G.vanz.ScannerSetDelay = function(v)
	if STATE.Destroyed then return false end
	local n = tonumber(v); if not n then return false end
	ScanState.Delay = math.floor(ClampNumber(n, 0, 2) * 100 + 0.5) / 100
	ScanDelayLabel.Text = string.format("%.2fs", ScanState.Delay)
	return true
end
_G.vanz.ScannerList = function()
	local out = {}
	for _, id in ipairs(ScanState.Order) do
		table.insert(out, { Id = id, Name = ScanState.Items[id] })
	end
	return out
end
_G.vanz.ScannerGetState = function()
	return { Items = _G.vanz.ScannerList(), Firing = ScanState.Firing, Probing = ScanState.Probing, Delay = ScanState.Delay, Fired = ScanState.Fired, Hits = ScanState.ProbeHits, LastError = ScanState.LastError }
end

_G.vanz.Close = function() return DestroyAll() end

--==================================================
-- [40] DESTROY / CLOSE
--==================================================
DestroyAll = function()
	if STATE.Destroyed then return end
	STATE.Destroyed = true
	STATE.Open = false
	STATE.Minimized = false
	CheatState.Running = false
	ScanState.Firing = false
	ScanState.Probing = false
	ScanState.Scanning = false
	ScanState.Collecting = false
	CleanupAll()
	DisconnectHumanoidEvents()
	if ScreenGui and ScreenGui.Parent then ScreenGui:Destroy() end
	if _G.vanz then
		local falseFn = function() return false end
		_G.vanz.Open = falseFn
		_G.vanz.Hide = falseFn
		_G.vanz.Minimize = falseFn
		_G.vanz.Restore = falseFn
		_G.vanz.Toggle = falseFn
		_G.vanz.SetScale = falseFn
		_G.vanz.ResetSettings = falseFn
		_G.vanz.StartAutoFire = falseFn
		_G.vanz.StopAutoFire = falseFn
		_G.vanz.SetAutoFireDelay = falseFn
		_G.vanz.ScannerScanHierarchy = falseFn
		_G.vanz.ScannerProbe = falseFn
		_G.vanz.ScannerStop = falseFn
		_G.vanz.ScannerAdd = falseFn
		_G.vanz.ScannerRemove = falseFn
		_G.vanz.ScannerFire = falseFn
		_G.vanz.ScannerFireAll = falseFn
		_G.vanz.ScannerSetDelay = falseFn
_G.vanz.StartAutoCollect = falseFn
		_G.vanz.StopAutoCollect = falseFn
		_G.vanz.GetAutoCollectState = falseFn
	end
end

--==================================================
-- [41] INIT
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
if not okInit then warn("[VANZ] Init error:", errInit) end

TrackConnection(Camera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
	if STATE.Destroyed then return end
	if STATE.Open and not STATE.Minimized then
		ApplyWindowLayout(false)
	elseif STATE.Minimized then
		local p = STATE.MiniPosition
		if p then SetMiniAbsolute(p) end
	end
end))

TrackConnection(Players.PlayerRemoving:Connect(function(p)
	if p == LocalPlayer then DestroyAll() end
end))
