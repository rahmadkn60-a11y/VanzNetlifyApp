--==================================================
-- [01] SERVICES
--==================================================
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Stats = game:GetService("Stats")
local RS = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

--==================================================
-- [02] GUI PERSIST INIT
--==================================================
local function BestParent()
	if gethui then
		local ok, h = pcall(gethui)
		if ok and h then return h, "gethui" end
	end
	local ok, cg = pcall(function() return game:GetService("CoreGui") end)
	if ok and cg then return cg, "CoreGui" end
	return LocalPlayer:WaitForChild("PlayerGui"), "PlayerGui"
end

for _, p in ipairs({LocalPlayer:WaitForChild("PlayerGui"), (pcall(function() return game:GetService("CoreGui") end) and select(2, pcall(function() return game:GetService("CoreGui") end)))}) do
	pcall(function()
		local old = p and p:FindFirstChild("VanzUI")
		if old then old:Destroy() end
	end)
end
if gethui then
	pcall(function()
		local old = gethui():FindFirstChild("VanzUI")
		if old then old:Destroy() end
	end)
end

local Parent, ParentName = BestParent()
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "VanzUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.IgnoreGuiInset = true
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.DisplayOrder = 2147483647
ScreenGui.Enabled = true
ScreenGui.Parent = Parent

--==================================================
-- [03] CONFIG
--==================================================
local CONFIG = {
	Scale = 0.55,
	ScaleOptions = {0.40, 0.50, 0.55, 0.60, 0.70, 0.80, 0.90, 1.00},
	WindowOpacity = 0.10,
	CornerRadius = 14,
	BorderIntensity = 0.65,
	AnimationEnabled = true,
	LogoAnimation = true,
	Scanline = true,
	HoverAnimation = true,
	LowFXMode = false,
	DragThreshold = 8,
	FastUpdateRate = 0.15,
	HomeUpdateRate = 0.5,
}

local THEMES = {
	["Cyber Blue"]  = {Accent = Color3.fromRGB(116,92,255), Accent2 = Color3.fromRGB(0,220,255), Base = Color3.fromRGB(10,11,16), Base2 = Color3.fromRGB(17,18,25)},
	["Neon Cyan"]   = {Accent = Color3.fromRGB(0,230,255), Accent2 = Color3.fromRGB(80,255,200), Base = Color3.fromRGB(8,18,26), Base2 = Color3.fromRGB(16,32,44)},
	["Purple Anime"]= {Accent = Color3.fromRGB(190,110,255), Accent2 = Color3.fromRGB(255,120,220), Base = Color3.fromRGB(18,12,32), Base2 = Color3.fromRGB(30,20,52)},
	["Crimson"]     = {Accent = Color3.fromRGB(255,70,90), Accent2 = Color3.fromRGB(255,160,80), Base = Color3.fromRGB(24,10,14), Base2 = Color3.fromRGB(38,18,26)},
	["Emerald"]     = {Accent = Color3.fromRGB(60,255,150), Accent2 = Color3.fromRGB(160,255,90), Base = Color3.fromRGB(8,22,18), Base2 = Color3.fromRGB(16,38,30)},
	["Ice"]         = {Accent = Color3.fromRGB(160,220,255), Accent2 = Color3.fromRGB(230,250,255), Base = Color3.fromRGB(20,30,42), Base2 = Color3.fromRGB(30,46,64)},
}

local DEFAULT_SNAPSHOT = {}
for k, v in pairs(CONFIG) do DEFAULT_SNAPSHOT[k] = v end

--==================================================
-- [04] STATE
--==================================================
local STATE = {
	Built = false, Open = true, Minimized = false, Destroyed = false,
	SettingsOpen = false, MainPosition = nil, MiniPosition = nil,
	SessionStart = os.clock(), DeviceText = "N/A",
	LastFPS = 0, LastFrameDt = 0, FrameCount = 0, FrameTimer = 0,
	FastTimer = 0, SlowTimer = 0,
}

--==================================================
-- [05] CLEANUP
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
-- [06] THEME + FACTORY
--==================================================
local function GetTheme() return THEMES[CONFIG.Theme or "Cyber Blue"] or THEMES["Cyber Blue"] end

local COLORS = {
	Text = Color3.fromRGB(245,245,248),
	SubText = Color3.fromRGB(145,147,158),
	Good = Color3.fromRGB(90,255,170),
	Warn = Color3.fromRGB(255,200,90),
	Bad = Color3.fromRGB(255,90,110),
	Card = Color3.fromRGB(17,18,25),
	CardHover = Color3.fromRGB(28,30,42),
	Track = Color3.fromRGB(30,32,42),
}

local FONT_TITLE = Enum.Font.GothamBlack
local FONT_BOLD = Enum.Font.GothamBold
local FONT_TEXT = Enum.Font.Gotham

local function Create(cls, props, children)
	local o = Instance.new(cls)
	for k, v in pairs(props or {}) do o[k] = v end
	for _, c in ipairs(children or {}) do c.Parent = o end
	return o
end
local function MakeCorner(p, r) return Create("UICorner", {CornerRadius = UDim.new(0, r or 10), Parent = p}) end
local function MakeStroke(p, c, t, tr) return Create("UIStroke", {Color = c or GetTheme().Accent, Thickness = t or 1, Transparency = tr or 0.4, ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Parent = p}) end
local function MakeGradient(p, c1, c2, rot)
	return Create("UIGradient", {Color = ColorSequence.new({ColorSequenceKeypoint.new(0, c1), ColorSequenceKeypoint.new(1, c2)}), Rotation = rot or 90, Parent = p})
end
local function MakeFrame(p, s, pos, c, tr)
	return Create("Frame", {Size = s or UDim2.new(1,0,1,0), Position = pos or UDim2.new(0,0,0,0), BackgroundColor3 = c or COLORS.Card, BackgroundTransparency = tr or 0, BorderSizePixel = 0, Parent = p})
end
local function MakeLabel(p, txt, s, pos, f, ts, c, xa)
	return Create("TextLabel", {Text = txt or "", Size = s or UDim2.new(1,0,0,20), Position = pos or UDim2.new(0,0,0,0), BackgroundTransparency = 1, Font = f or FONT_TEXT, TextSize = ts or 14, TextColor3 = c or COLORS.Text, TextXAlignment = xa or Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Center, Parent = p})
end
local function MakeButton(p, txt, s, pos, onClick)
	local btn = Create("TextButton", {Text = txt or "", Size = s or UDim2.new(0,48,0,48), Position = pos or UDim2.new(0,0,0,0), BackgroundColor3 = GetTheme().Base2, BackgroundTransparency = 0.1, BorderSizePixel = 0, AutoButtonColor = false, Font = FONT_BOLD, TextSize = 16, TextColor3 = COLORS.Text, Parent = p})
	MakeCorner(btn, 10)
	MakeStroke(btn, GetTheme().Accent, 1, 0.5)
	local base = GetTheme().Base2
	TrackConnection(btn.MouseEnter:Connect(function()
		if not CONFIG.HoverAnimation or CONFIG.LowFXMode then return end
		TrackTween(TweenService:Create(btn, TweenInfo.new(0.18), {BackgroundColor3 = GetTheme().Accent:Lerp(base, 0.6)})):Play()
	end))
	TrackConnection(btn.MouseLeave:Connect(function()
		if not CONFIG.HoverAnimation or CONFIG.LowFXMode then return end
		TrackTween(TweenService:Create(btn, TweenInfo.new(0.18), {BackgroundColor3 = base})):Play()
	end))
	TrackConnection(btn.MouseButton1Click:Connect(function()
		if onClick then
			local ok, err = pcall(onClick)
			if not ok then warn("[VANZ] button:", err) end
		end
	end))
	return btn
end
local function MakeCard(p, title, s, pos)
	local c = MakeFrame(p, s, pos, COLORS.Card, 0.05)
	MakeCorner(c, 12)
	MakeStroke(c, GetTheme().Accent, 1, 0.7)
	MakeLabel(c, title or "", UDim2.new(1,-20,0,22), UDim2.new(0,12,0,8), FONT_BOLD, 15, GetTheme().Accent2)
	return c
end
local function ToStr(v, d)
	if v == nil then return "N/A" end
	if type(v) == "number" then return d and string.format("%." .. d .. "f", v) or tostring(math.floor(v + 0.5)) end
	return tostring(v)
end

--==================================================
-- [07] VIEWPORT HELPERS
--==================================================
local BASE_W, BASE_H, MIN_W = 720, 500, 280
local function GetViewport()
	if Camera and Camera.ViewportSize then return Camera.ViewportSize end
	return Vector2.new(1280, 720)
end
local function ComputeWindowSize()
	local vp = GetViewport()
	local s = CONFIG.Scale
	return Vector2.new(
		math.floor(math.clamp(BASE_W * s * 1.9, MIN_W, vp.X - 16)),
		math.floor(math.clamp(BASE_H * s * 1.9, 240, vp.Y - 16))
	)
end
local function CenteredPos(size)
	local vp = GetViewport()
	return Vector2.new(math.floor((vp.X - size.X)/2), math.floor((vp.Y - size.Y)/2))
end
local function ClampAbs(pos, size)
	local vp = GetViewport()
	return Vector2.new(math.clamp(pos.X, 0, math.max(0, vp.X - size.X)), math.clamp(pos.Y, 0, math.max(0, vp.Y - size.Y)))
end

--==================================================
-- [08] MAIN WINDOW
--==================================================
local MainWindow = Create("Frame", {
	Name = "Main", Size = UDim2.new(0,0,0,0), Position = UDim2.new(0,0,0,0),
	BackgroundColor3 = GetTheme().Base, BackgroundTransparency = CONFIG.WindowOpacity,
	BorderSizePixel = 0, ClipsDescendants = true, Visible = true, Parent = ScreenGui,
})
MakeCorner(MainWindow, CONFIG.CornerRadius)
local MainStroke = MakeStroke(MainWindow, GetTheme().Accent, 1.5, 0.25)
MakeGradient(MainWindow, GetTheme().Base, GetTheme().Base2, 90)

local HEADER_H = 56

local Header = MakeFrame(MainWindow, UDim2.new(1,0,0,HEADER_H), UDim2.new(0,0,0,0), GetTheme().Base2, 0.2)
MakeCorner(Header, CONFIG.CornerRadius)

local HeaderLogo = MakeFrame(Header, UDim2.new(0,36,0,36), UDim2.new(0,12,0.5,-18), GetTheme().Base, 1)
MakeCorner(HeaderLogo, 18)
local HeaderLogoRing = MakeFrame(HeaderLogo, UDim2.new(1,0,1,0), UDim2.new(0,0,0,0), GetTheme().Accent, 1)
MakeCorner(HeaderLogoRing, 18)
MakeStroke(HeaderLogoRing, GetTheme().Accent, 2, 0.1)
local HeaderLogoCore = MakeFrame(HeaderLogo, UDim2.new(0,10,0,10), UDim2.new(0.5,-5,0.5,-5), GetTheme().Accent2, 0)
MakeCorner(HeaderLogoCore, 5)

local TitleArea = MakeFrame(Header, UDim2.new(1,-216,1,0), UDim2.new(0,58,0,0), COLORS.Card, 1)
MakeLabel(TitleArea, "VANZ CONTROL CENTER", UDim2.new(1,0,0,22), UDim2.new(0,0,0,8), FONT_TITLE, 15, COLORS.Text)
local SubtitleLabel = MakeLabel(TitleArea, "IDLE", UDim2.new(1,0,0,16), UDim2.new(0,0,0,28), FONT_TEXT, 11, COLORS.SubText)

local CONTROL_W = 156
local ControlZone = MakeFrame(Header, UDim2.new(0,CONTROL_W,1,0), UDim2.new(1,-CONTROL_W-8,0,0), COLORS.Card, 1)
local BTN_SZ = 44
local BTN_GAP = 6
local SettingsBtn, MinimizeBtn, CloseBtn
local function LayoutControls()
	local zW = ControlZone.AbsoluteSize.X
	local zH = ControlZone.AbsoluteSize.Y
	local y = math.floor((zH - BTN_SZ)/2)
	local x = zW - BTN_SZ
	if CloseBtn then CloseBtn.Position = UDim2.new(0,x,0,y) end
	x = x - BTN_SZ - BTN_GAP
	if MinimizeBtn then MinimizeBtn.Position = UDim2.new(0,x,0,y) end
	x = x - BTN_SZ - BTN_GAP
	if SettingsBtn then SettingsBtn.Position = UDim2.new(0,x,0,y) end
end
SettingsBtn = MakeButton(ControlZone, "⚙", UDim2.new(0,BTN_SZ,0,BTN_SZ), UDim2.new(0,0,0,0), function() end)
MinimizeBtn = MakeButton(ControlZone, "—", UDim2.new(0,BTN_SZ,0,BTN_SZ), UDim2.new(0,0,0,0), function() end)
CloseBtn = MakeButton(ControlZone, "X", UDim2.new(0,BTN_SZ,0,BTN_SZ), UDim2.new(0,0,0,0), function() end)
TrackConnection(ControlZone:GetPropertyChangedSignal("AbsoluteSize"):Connect(LayoutControls))
task.defer(LayoutControls)

local Body = MakeFrame(MainWindow, UDim2.new(1,-16,1,-(HEADER_H+12)), UDim2.new(0,8,0,HEADER_H+4), COLORS.Card, 1)

local HomeScroll = Create("ScrollingFrame", {
	Name = "Home", Size = UDim2.new(1,0,1,0), BackgroundTransparency = 1, BorderSizePixel = 0,
	ScrollBarThickness = 4, ScrollBarImageColor3 = GetTheme().Accent,
	CanvasSize = UDim2.new(0,0,0,0), AutomaticCanvasSize = Enum.AutomaticSize.None,
	ScrollingDirection = Enum.ScrollingDirection.Y, ElasticBehavior = Enum.ElasticBehavior.Never, Parent = Body,
})
local HomeList = Create("UIListLayout", {SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0,10), Parent = HomeScroll})
Create("UIPadding", {PaddingLeft = UDim.new(0,8), PaddingRight = UDim.new(0,8), PaddingTop = UDim.new(0,6), PaddingBottom = UDim.new(0,12), Parent = HomeScroll})

local SettingsScroll = Create("ScrollingFrame", {
	Name = "Settings", Size = UDim2.new(1,0,1,0), BackgroundTransparency = 1, BorderSizePixel = 0,
	ScrollBarThickness = 4, ScrollBarImageColor3 = GetTheme().Accent2,
	CanvasSize = UDim2.new(0,0,0,0), AutomaticCanvasSize = Enum.AutomaticSize.None,
	ScrollingDirection = Enum.ScrollingDirection.Y, ElasticBehavior = Enum.ElasticBehavior.Never, Visible = false, Parent = Body,
})
local SettingsList = Create("UIListLayout", {SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0,10), Parent = SettingsScroll})
Create("UIPadding", {PaddingLeft = UDim.new(0,8), PaddingRight = UDim.new(0,8), PaddingTop = UDim.new(0,6), PaddingBottom = UDim.new(0,12), Parent = SettingsScroll})

--==================================================
-- [09] MINI LOGO
--==================================================
local MINI = 60
local MiniLogo = Create("Frame", {Name = "MiniLogo", Size = UDim2.new(0,MINI,0,MINI), Position = UDim2.new(0,0,0,0), BackgroundTransparency = 1, Visible = false, Parent = ScreenGui})
local MiniBody = MakeFrame(MiniLogo, UDim2.new(1,0,1,0), nil, GetTheme().Base2, 0.15)
MakeCorner(MiniBody, MINI/2)
MakeStroke(MiniBody, GetTheme().Accent, 1.5, 0.2)
local MiniCore = MakeFrame(MiniLogo, UDim2.new(0,16,0,16), UDim2.new(0.5,-8,0.5,-8), GetTheme().Accent2, 0)
MakeCorner(MiniCore, 8)
local MiniScan = MakeFrame(MiniLogo, UDim2.new(0.5,0,0,2), UDim2.new(0.25,0,0.5,-1), GetTheme().Accent2, 0.3)
local MiniHit = Create("TextButton", {Size = UDim2.new(1,0,1,0), BackgroundTransparency = 1, Text = "", AutoButtonColor = false, ZIndex = 5, Parent = MiniLogo})

--==================================================
-- [10] DRAG + MIN/MAX
--==================================================
local function BindDrag(target, handle, onEnd)
	local drag, sIn, sAbs, moved = false, nil, nil, 0
	TrackConnection(handle.InputBegan:Connect(function(input)
		if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then return end
		drag = true; moved = 0; sIn = input.Position; sAbs = target.AbsolutePosition
	end))
	TrackConnection(UserInputService.InputChanged:Connect(function(input)
		if not drag then return end
		if input.UserInputType ~= Enum.UserInputType.MouseMovement and input.UserInputType ~= Enum.UserInputType.Touch then return end
		local delta = Vector2.new(input.Position.X, input.Position.Y) - Vector2.new(sIn.X, sIn.Y)
		moved = math.max(moved, delta.Magnitude)
		if moved < CONFIG.DragThreshold then return end
		target.Position = UDim2.fromOffset(ClampAbs(sAbs + delta, target.AbsoluteSize).X, ClampAbs(sAbs + delta, target.AbsoluteSize).Y)
		target.AnchorPoint = Vector2.new(0,0)
	end))
	TrackConnection(UserInputService.InputEnded:Connect(function(input)
		if not drag then return end
		if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then return end
		drag = false
		if onEnd then pcall(onEnd, moved >= CONFIG.DragThreshold) end
	end))
end

local function SetMainAbs(pos, size)
	local c = ClampAbs(pos, size)
	MainWindow.Position = UDim2.fromOffset(c.X, c.Y)
	MainWindow.Size = UDim2.fromOffset(size.X, size.Y)
	STATE.MainPosition = c
end
local function SetMiniAbs(pos)
	local vp = GetViewport()
	MiniLogo.Position = UDim2.fromOffset(math.clamp(pos.X, 0, math.max(0, vp.X - MINI)), math.clamp(pos.Y, 0, math.max(0, vp.Y - MINI)))
	STATE.MiniPosition = Vector2.new(MiniLogo.Position.X.Offset, MiniLogo.Position.Y.Offset)
end
local function ApplyLayout(keepCenter)
	local size = ComputeWindowSize()
	local pos = (keepCenter or not STATE.MainPosition) and CenteredPos(size) or ClampAbs(STATE.MainPosition, size)
	SetMainAbs(pos, size)
end
local function Minimize()
	if not STATE.Open then return end
	STATE.Minimized = true
	local mc = Vector2.new(MainWindow.AbsolutePosition.X, MainWindow.AbsolutePosition.Y)
	local ms = MainWindow.AbsoluteSize
	SetMiniAbs(Vector2.new(mc.X + ms.X/2 - MINI/2, mc.Y + ms.Y/2 - MINI/2))
	MainWindow.Visible = false
	MiniLogo.Visible = true
end
local function Restore()
	if not STATE.Open then return end
	STATE.Minimized = false
	local mp = STATE.MiniPosition or Vector2.new(0,0)
	local size = ComputeWindowSize()
	SetMainAbs(Vector2.new(mp.X + MINI/2 - size.X/2, mp.Y + MINI/2 - size.Y/2), size)
	MiniLogo.Visible = false
	MainWindow.Visible = true
end

BindDrag(MainWindow, Header, function(wasDrag) if wasDrag then STATE.MainPosition = Vector2.new(MainWindow.AbsolutePosition.X, MainWindow.AbsolutePosition.Y) end end)
BindDrag(MiniLogo, MiniHit, function(wasDrag)
	if wasDrag then STATE.MiniPosition = Vector2.new(MiniLogo.AbsolutePosition.X, MiniLogo.AbsolutePosition.Y) else Restore() end
end)

SettingsBtn.MouseButton1Click:Connect(function()
	STATE.SettingsOpen = not STATE.SettingsOpen
	SettingsScroll.Visible = STATE.SettingsOpen
	HomeScroll.Visible = not STATE.SettingsOpen
	SettingsBtn.Text = STATE.SettingsOpen and "⌂" or "⚙"
end)
MinimizeBtn.MouseButton1Click:Connect(Minimize)
CloseBtn.MouseButton1Click:Connect(function() STATE.Destroyed = true; CleanupAll(); ScreenGui:Destroy() end)

--==================================================
-- [11] REFRESH CANVAS
--==================================================
TrackConnection(HomeList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
	HomeScroll.CanvasSize = UDim2.new(0,0,0, HomeList.AbsoluteContentSize.Y + 24)
end))
TrackConnection(SettingsList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
	SettingsScroll.CanvasSize = UDim2.new(0,0,0, SettingsList.AbsoluteContentSize.Y + 24)
end))

--==================================================
-- [12] AUTOMATION ENGINE
--==================================================
local AUTO = {
	Enabled = false,
	Phase = "IDLE",
	Status = "IDLE",
	EscapetimeHeard = false,
	ProgressComplete = false,
	EnemyThreshold = 35,
	GenIndex = 0,
	GenTotal = 0,
	LevIndex = 0,
	LevTotal = 0,
	EnemiesNear = 0,
	Running = false,
	StopRequested = false,
	Done = false,
}

--==================================================
-- [13] REMOTES
--==================================================
local function WaitPath(...)
	local names = {...}
	local node = RS
	for _, n in ipairs(names) do
		local ok, f = pcall(function() return node:WaitForChild(n, 25) end)
		if not ok or not f then return nil end
		node = f
	end
	return node
end

local Remotes = {
	Repair          = WaitPath("Remotes", "Generator", "RepairEvent"),
	RepairVFX       = WaitPath("Remotes", "Generator", "RepairVFX"),
	SkillCheck      = WaitPath("Remotes", "Generator", "SkillCheckResultEvent"),
	Escapetime      = WaitPath("Remotes", "Generator", "Escapetime"),
	Lever           = WaitPath("Remotes", "Exit", "LeverEvent"),
	LeverAnim       = WaitPath("Remotes", "Exit", "LeverAnim"),
	Progress        = WaitPath("Remotes", "Progress", "ProgressUpdateEvent"),
	PlayerAction    = WaitPath("Remotes", "Game", "PlayerActionEvent"),
	ShowResults     = WaitPath("Remotes", "Game", "showresults"),
	Darkness2       = WaitPath("Remotes", "Darkness2"),
	GameStart       = WaitPath("Remotes", "Game", "Start"),
	DeleteSpec      = WaitPath("Remotes", "Game", "deletespectatorgui"),
}

local function HookClient(remote, cb)
	if not remote then return end
	local ok = pcall(function() remote.OnClientEvent:Connect(cb) end)
	if not ok then pcall(function() remote.Event:Connect(cb) end) end
end

local function FireClientSpoof(remote, ...)
	if not remote or not getconnections then return end
	local ok, conns = pcall(getconnections, remote.OnClientEvent)
	if not ok or not conns then return end
	local args = {...}
	for _, c in ipairs(conns) do
		pcall(function()
			if c.Fire then c:Fire(unpack(args)) end
		end)
	end
end

HookClient(Remotes.GameStart, function()
	if AUTO.Phase == "IDLE" or AUTO.Phase == "WAIT_MAP" then
		AUTO.Phase = "GENERATOR"
		print("[VANZ] Game.Start signal — phase=GENERATOR")
	end
end)
HookClient(Remotes.DeleteSpec, function()
	if AUTO.Phase == "IDLE" or AUTO.Phase == "WAIT_MAP" then
		AUTO.Phase = "GENERATOR"
		print("[VANZ] deletespectatorgui signal — phase=GENERATOR")
	end
end)
HookClient(Remotes.Escapetime, function(...)
	AUTO.EscapetimeHeard = true
	print("[VANZ] 🚨 Escapetime — go lever")
	if AUTO.Running and AUTO.Phase ~= "DONE" then AUTO.Phase = "LEVER" end
end)
HookClient(Remotes.Progress, function(p, s)
	if tonumber(p) == 100 and tostring(s) == "OPEN" then
		AUTO.ProgressComplete = true
		AUTO.Done = true
		AUTO.Phase = "DONE"
		AUTO.Status = "DONE"
		AUTO.Running = false
		print("[VANZ] ✅ Progress 100/OPEN — STOP ALL")
	end
end)

--==================================================
-- [14] GENERATOR SCANNER (dynamic)
--==================================================
local GenList = {}
local function HasGenPoint(obj)
	for _, c in ipairs(obj:GetChildren()) do
		if c.Name:match("^GeneratorPoint%d+$") then return c end
	end
	return nil
end
local function ScanGenerators()
	local found = {}
	local function scan(obj, depth)
		if depth > 4 then return end
		for _, ch in ipairs(obj:GetChildren()) do
			if ch:IsA("Folder") or ch:IsA("Model") then
				if HasGenPoint(ch) then
					table.insert(found, ch)
				else
					scan(ch, depth + 1)
				end
			end
		end
	end
	scan(workspace, 0)
	return found
end
local function BuildGenList()
	local list = {}
	for _, gen in ipairs(ScanGenerators()) do
		local allPoints = {}
		for _, c in ipairs(gen:GetChildren()) do
			local n = tonumber(c.Name:match("^GeneratorPoint(%d+)$") or "")
			if n then table.insert(allPoints, {point = c, num = n, model = gen}) end
		end
		for _, p in ipairs(allPoints) do table.insert(list, p) end
	end
	table.sort(list, function(a,b) return a.num < b.num end)
	GenList = list
	AUTO.GenTotal = #list
	return #list > 0
end

--==================================================
-- [15] DONE DETECTION
--==================================================
local DONE_ATTRS = {"Completed","IsCompleted","Done","IsDone","Fixed","IsFixed","Repaired","IsRepaired","Finished","IsFinished"}
local PROG_ATTRS = {"Progress","Value","Percent","RepairProgress","Repair","ProgressValue","RepairPercent"}
local PROG_CHILD_KEYS = {"progress","repair","value","percent","fixed"}
local DoneCache = {}

local function GetAttrNum(obj, names)
	if not obj then return nil end
	for _, n in ipairs(names) do
		local v = obj:GetAttribute(n)
		if typeof(v) == "number" then return v end
	end
	return nil
end
local function GetProgress(entry)
	if not entry then return nil end
	local v = GetAttrNum(entry.model, PROG_ATTRS)
	if v then return v end
	v = GetAttrNum(entry.point, PROG_ATTRS)
	if v then return v end
	for _, c in ipairs(entry.model:GetDescendants()) do
		if c:IsA("NumberValue") or c:IsA("IntValue") then
			local low = c.Name:lower()
			for _, k in ipairs(PROG_CHILD_KEYS) do
				if low:find(k) then return c.Value end
			end
		end
	end
	return nil
end
local function IsGenDone(idx)
	local entry = GenList[idx]
	if not entry then return true end
	if not entry.model or not entry.model.Parent then return true end
	if DoneCache[entry.model] then return true end
	for _, n in ipairs(DONE_ATTRS) do
		if entry.model:GetAttribute(n) == true then
			DoneCache[entry.model] = true
			return true
		end
	end
	local prog = GetProgress(entry)
	if typeof(prog) == "number" and prog >= 100 then
		DoneCache[entry.model] = true
		return true
	end
	return false
end
local function CountDone()
	local n = 0
	for i = 1, AUTO.GenTotal do if IsGenDone(i) then n = n + 1 end end
	return n
end
local function NextUndone(from)
	for i = from, AUTO.GenTotal do if not IsGenDone(i) then return i end end
	for i = 1, from - 1 do if not IsGenDone(i) then return i end end
	return nil
end

--==================================================
-- [16] LEVER SCANNER (dynamic)
--==================================================
local LeverList = {}
local function FindLeverMain(lever)
	local main = lever:FindFirstChild("Main")
	if main and main:IsA("BasePart") then return main end
	for _, c in ipairs(lever:GetChildren()) do
		if c:IsA("BasePart") then return c end
	end
	return nil
end
local function BuildLeverList()
	local found = {}
	local function scan(obj, depth)
		if depth > 5 then return end
		for _, ch in ipairs(obj:GetChildren()) do
			if ch.Name == "ExitLever" then
				local m = FindLeverMain(ch)
				if m then table.insert(found, {lever = ch, main = m, name = ch.Name}) end
			end
			if ch:IsA("Folder") or ch:IsA("Model") then scan(ch, depth + 1) end
		end
	end
	scan(workspace, 0)
	table.sort(found, function(a,b) return a.name < b.name end)
	LeverList = found
	AUTO.LevTotal = #found
	return #found > 0
end
local function FindNilMain()
	if not getnilinstances then return nil end
	local ok, list = pcall(getnilinstances)
	if not ok or not list then return nil end
	for _, obj in ipairs(list) do
		if obj.Name == "Main" and typeof(obj) == "Instance" and obj:IsA("BasePart") then
			return obj
		end
	end
	return nil
end

--==================================================
-- [17] ENEMY CLASSIFIER
--==================================================
local function GetPlayerColor(plr)
	local char = plr.Character
	if not char then return nil end
	local hl = char:FindFirstChildOfClass("Highlight")
	if hl then return hl.FillColor end
	local sb = char:FindFirstChildOfClass("SelectionBox")
	if sb then return sb.Color3 end
	for _, d in ipairs(char:GetDescendants()) do
		if d:IsA("Frame") then
			local n = d.Name:lower()
			if n:find("circle") or n:find("indicator") or n:find("dot") or n:find("ring") then
				return d.BackgroundColor3
			end
		elseif d:IsA("ImageLabel") then
			local n = d.Name:lower()
			if n:find("circle") or n:find("indicator") or n:find("dot") or n:find("ring") then
				return d.ImageColor3
			end
		end
	end
	if plr.TeamColor then return plr.TeamColor.Color end
	if plr.Team and plr.Team.TeamColor then return plr.Team.TeamColor.Color end
	local torso = char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso")
	if torso and torso:IsA("BasePart") then return torso.Color end
	return nil
end
local function ClassifyColor(c)
	if not c then return "unknown" end
	local r, g, b = c.R, c.G, c.B
	if r > 0.5 and g < 0.4 and b < 0.4 then return "enemy" end
	if b > 0.5 and r < 0.55 and g < 0.7 then return "team" end
	if r > 0.75 and g > 0.75 and b > 0.75 then return "unknown" end
	return "unknown"
end
local function NearestEnemy()
	local myChar = LocalPlayer.Character
	if not myChar then return math.huge end
	local myRoot = myChar:FindFirstChild("HumanoidRootPart")
	if not myRoot then return math.huge end
	local nearest, count = math.huge, 0
	for _, p in ipairs(Players:GetPlayers()) do
		if p ~= LocalPlayer and p.Character then
			local hrp = p.Character:FindFirstChild("HumanoidRootPart")
			local hum = p.Character:FindFirstChildOfClass("Humanoid")
			if hrp and hum and hum.Health > 0 and ClassifyColor(GetPlayerColor(p)) == "enemy" then
				local d = (hrp.Position - myRoot.Position).Magnitude
				if d <= AUTO.EnemyThreshold then count = count + 1 end
				if d < nearest then nearest = d end
			end
		end
	end
	AUTO.EnemiesNear = count
	return nearest
end

--==================================================
-- [18] FIRE HELPERS
--==================================================
local CurrentNilMain = nil
local function FireRepair(point, state)
	if Remotes.Repair and point then pcall(function() Remotes.Repair:FireServer(point, state) end) end
end
local function FireVFX()
	if Remotes.RepairVFX then pcall(function() Remotes.RepairVFX:FireServer() end) end
end
local function FireSkillCheck(model, point)
	if Remotes.SkillCheck then
		pcall(function() Remotes.SkillCheck:FireServer("succes", 1, model, point) end)
	end
end
local function FireLever(state, mainPart)
	if not Remotes.Lever then return false end
	CurrentNilMain = CurrentNilMain or FindNilMain()
	if CurrentNilMain then
		pcall(function() Remotes.Lever:FireServer(CurrentNilMain, state) end)
		return true
	end
	if mainPart then
		pcall(function() Remotes.Lever:FireServer(mainPart, state) end)
		return true
	end
	return false
end
local function FireLeverAnim(cf)
	FireClientSpoof(Remotes.LeverAnim, true, cf or CFrame.new())
end
local function FireProgress(v, s, b)
	FireClientSpoof(Remotes.Progress, v, s, b)
end
local function FireAction(...)
	FireClientSpoof(Remotes.PlayerAction, ...)
end
local function FireResults()
	FireClientSpoof(Remotes.ShowResults)
end
local function FireDarkness(...)
	FireClientSpoof(Remotes.Darkness2, ...)
end

--==================================================
-- [19] TELEPORT
--==================================================
local function TP(part, offset)
	if not part then return end
	local char = LocalPlayer.Character
	if not char then return end
	local hrp = char:FindFirstChild("HumanoidRootPart")
	if not hrp then return end
	pcall(function() hrp.CFrame = part.CFrame + Vector3.new(0, offset or 3, 0) end)
end

--==================================================
-- [20] GENERATOR WORKER
--==================================================
local function WorkGen(idx, maxTime)
	local entry = GenList[idx]
	if not entry then return "missing" end
	local point, model = entry.point, entry.model
	AUTO.GenIndex = idx
	AUTO.Status = "GEN " .. idx .. "/" .. AUTO.GenTotal
	TP(point, 3)
	task.wait(0.2)
	FireRepair(point, true)
	FireVFX()
	local startT = os.clock()
	local lastRefire = os.clock()
	local lastProg = -1
	local lastProgChange = os.clock()
	while os.clock() - startT < (maxTime or 30) do
		if AUTO.ProgressComplete or AUTO.Done then FireRepair(point, false); return "signal" end
		if not AUTO.Running or AUTO.StopRequested then FireRepair(point, false); return "stop" end
		if AUTO.EscapetimeHeard then FireRepair(point, false); return "escape" end

		local dist = NearestEnemy()
		if dist < AUTO.EnemyThreshold then
			FireRepair(point, false)
			AUTO.Status = "GEN " .. idx .. " EVADE"
			while NearestEnemy() < AUTO.EnemyThreshold and AUTO.Running and not AUTO.Done and not AUTO.ProgressComplete do
				task.wait(0.25)
			end
			if AUTO.ProgressComplete or AUTO.EscapetimeHeard then return "signal" end
			FireRepair(point, true)
			FireVFX()
			lastRefire = os.clock()
		end

		FireSkillCheck(model, point)

		local prog = GetProgress(entry)
		if typeof(prog) == "number" and prog ~= lastProg then
			lastProg = prog
			lastProgChange = os.clock()
		end
		if IsGenDone(idx) then
			print("[VANZ] Gen #" .. idx .. " done")
			return "done"
		end
		if os.clock() - lastProgChange > 4 then
			FireRepair(point, false)
			task.wait(0.15)
			TP(point, 3)
			task.wait(0.15)
			FireRepair(point, true)
			FireVFX()
			lastRefire = os.clock()
			lastProgChange = os.clock()
		end
		if os.clock() - lastRefire > 1.5 then
			FireRepair(point, true)
			FireVFX()
			lastRefire = os.clock()
		end
		task.wait(0.1)
	end
	FireRepair(point, false)
	return "timeout"
end

--==================================================
-- [21] LEVER WORKER + SEQUENCE
--==================================================
local SequenceRunning = false
local function RunLeverSequence()
	if SequenceRunning then return end
	SequenceRunning = true
	task.spawn(function()
		local ok, err = pcall(function()
			local entry = LeverList[AUTO.LevIndex]
			if not entry then return end
			FireLever(true, entry.main)
			task.wait(0.05)
			FireLeverAnim(entry.main.CFrame)
			task.wait(0.05)
			local i = 0.25
			while i <= 5.0 do
				FireProgress(i, "OPEN")
				task.wait(0.02)
				i = i + 0.25
			end
			i = 5
			while i <= 100 do
				FireProgress(i, "OPEN")
				task.wait(0.02)
				i = i + 5
			end
			FireProgress(100, "OPEN", false)
			task.wait(0.05)
			FireAction("ESCAPED", 189)
			task.wait(0.05)
			FireDarkness(3.3, 1, 1)
			task.wait(0.05)
			FireResults()
		end)
		if not ok then warn("[VANZ] Sequence err:", err) end
		SequenceRunning = false
	end)
end

local function WorkLever(idx, maxTime)
	if idx < 1 or idx > AUTO.LevTotal then return "missing" end
	local entry = LeverList[idx]
	if not entry then return "missing" end
	AUTO.LevIndex = idx
	AUTO.Status = "LEVER " .. idx .. "/" .. AUTO.LevTotal
	TP(entry.main, 3)
	task.wait(0.2)
	FireLever(true, entry.main)
	local startT = os.clock()
	local lastFire = os.clock()
	while os.clock() - startT < (maxTime or 25) do
		if AUTO.ProgressComplete or AUTO.Done then FireLever(false, entry.main); return "signal" end
		if not AUTO.Running or AUTO.StopRequested then FireLever(false, entry.main); return "stop" end

		local dist = NearestEnemy()
		if dist < AUTO.EnemyThreshold then
			FireLever(false, entry.main)
			AUTO.Status = "LEVER " .. idx .. " EVADE"
			while NearestEnemy() < AUTO.EnemyThreshold and AUTO.Running and not AUTO.Done do
				task.wait(0.25)
			end
			if AUTO.ProgressComplete then return "signal" end
			FireLever(true, entry.main)
			lastFire = os.clock()
		end

		RunLeverSequence()

		if os.clock() - lastFire > 1.5 then
			FireLever(true, entry.main)
			lastFire = os.clock()
		end
		task.wait(0.15)
	end
	FireLever(false, entry.main)
	return "timeout"
end

--==================================================
-- [22] MAIN STATE MACHINE
--==================================================
local function RunAutomation()
	AUTO.Running = true
	AUTO.StopRequested = false
	AUTO.Status = "WAIT MAP"
	AUTO.Phase = "WAIT_MAP"
	while AUTO.Running and not AUTO.Done do
		if AUTO.Phase == "WAIT_MAP" or AUTO.Phase == "IDLE" then
			if workspace:FindFirstChild("Map") and BuildGenList() then
				AUTO.Phase = "GENERATOR"
			else
				task.wait(0.5)
			end
		elseif AUTO.Phase == "GENERATOR" then
			if AUTO.ProgressComplete or AUTO.EscapetimeHeard or AUTO.Done then
				AUTO.Phase = "LEVER"
			else
				BuildGenList()
				local idx = NextUndone(1)
				if not idx then
					AUTO.Status = "WAIT ESCAPE"
					task.wait(1)
				else
					local r = WorkGen(idx, 30)
					if r == "escape" or r == "signal" then AUTO.Phase = "LEVER" end
					if r == "missing" then task.wait(0.5) end
				end
			end
		elseif AUTO.Phase == "LEVER" then
			if AUTO.ProgressComplete or AUTO.Done then
				AUTO.Phase = "DONE"
			else
				BuildLeverList()
				local done = false
				for i = 1, math.max(1, AUTO.LevTotal) do
					if AUTO.ProgressComplete or AUTO.Done then done = true break end
					local r = WorkLever(i, 25)
					if r == "missing" then break end
					if r == "signal" then done = true break end
				end
				if done or AUTO.ProgressComplete then AUTO.Phase = "DONE" else
					AUTO.Status = "WAIT PROGRESS"
					task.wait(2)
				end
			end
		elseif AUTO.Phase == "DONE" then
			AUTO.Status = "DONE"
			AUTO.Running = false
			break
		end
		task.wait(0.2)
	end
	AUTO.Running = false
	AUTO.Status = AUTO.Done and "DONE" or "STOPPED"
end

local function StartAuto()
	if AUTO.Running then return end
	AUTO.EscapetimeHeard = false
	AUTO.ProgressComplete = false
	AUTO.Done = false
	AUTO.StopRequested = false
	AUTO.Phase = "WAIT_MAP"
	AUTO.Status = "WAIT MAP"
	task.spawn(RunAutomation)
end
local function StopAuto()
	AUTO.StopRequested = true
	AUTO.Running = false
	AUTO.Phase = "IDLE"
	AUTO.Status = "STOPPED"
end

--==================================================
-- [23] AUTO OPERATIONS CARD
--==================================================
local AutoCard = MakeCard(HomeScroll, "AUTO OPERATIONS", UDim2.new(1,-4,0,238), nil)
AutoCard.LayoutOrder = 1

local StatusLbl = MakeLabel(AutoCard, "Status: IDLE", UDim2.new(1,-24,0,18), UDim2.new(0,12,0,36), FONT_BOLD, 14, COLORS.Text)
local PhaseLbl  = MakeLabel(AutoCard, "Phase: IDLE", UDim2.new(1,-24,0,18), UDim2.new(0,12,0,56), FONT_TEXT, 13, COLORS.SubText)
local GenLbl    = MakeLabel(AutoCard, "Generator: 0/0", UDim2.new(1,-24,0,18), UDim2.new(0,12,0,76), FONT_TEXT, 13, COLORS.SubText)
local LevLbl    = MakeLabel(AutoCard, "Lever: 0/0", UDim2.new(1,-24,0,18), UDim2.new(0,12,0,96), FONT_TEXT, 13, COLORS.SubText)
local EnemyLbl  = MakeLabel(AutoCard, "Enemies Near: 0", UDim2.new(1,-24,0,18), UDim2.new(0,12,0,116), FONT_TEXT, 13, COLORS.SubText)
local MapLbl    = MakeLabel(AutoCard, "Map: NO • Escape: NO • Progress: 0%", UDim2.new(1,-24,0,18), UDim2.new(0,12,0,136), FONT_TEXT, 13, COLORS.SubText)

local StartBtn = MakeButton(AutoCard, "START AUTO", UDim2.new(0.5,-8,0,40), UDim2.new(0,12,0,166), function()
	if AUTO.Running then
		StopAuto()
		StartBtn.Text = "START AUTO"
	else
		StartAuto()
		StartBtn.Text = "STOP AUTO"
	end
end)
MakeCorner(StartBtn, 10)

local StopBtn = MakeButton(AutoCard, "STOP", UDim2.new(0.5,-8,0,40), UDim2.new(0.5,4,0,166), function()
	StopAuto()
	StartBtn.Text = "START AUTO"
end)
MakeCorner(StopBtn, 10)

local StopAllBtn = MakeButton(AutoCard, "STOP ALL", UDim2.new(1,-24,0,36), UDim2.new(0,12,0,212), function()
	StopAuto()
	AUTO.ProgressComplete = true
	AUTO.Done = true
	AUTO.Phase = "DONE"
	AUTO.Status = "STOPPED"
	StartBtn.Text = "START AUTO"
end)
MakeCorner(StopAllBtn, 10)
StopAllBtn.TextColor3 = COLORS.Bad

--==================================================
-- [24] STATUS UPDATER
--==================================================
TrackConnection(RunService.Heartbeat:Connect(function()
	if STATE.Destroyed then return end
	STATE.FastTimer = STATE.FastTimer + (STATE.LastFrameDt or 0)
	if STATE.FastTimer < CONFIG.FastUpdateRate then return end
	STATE.FastTimer = 0
	if not STATE.Built then return end
	StatusLbl.Text = "Status: " .. AUTO.Status
	PhaseLbl.Text = "Phase: " .. AUTO.Phase
	GenLbl.Text = "Generator: " .. CountDone() .. "/" .. AUTO.GenTotal
	LevLbl.Text = "Lever: " .. AUTO.LevIndex .. "/" .. AUTO.LevTotal
	EnemyLbl.Text = "Enemies Near: " .. AUTO.EnemiesNear .. " (thr " .. AUTO.EnemyThreshold .. ")"
	MapLbl.Text = "Map: " .. (workspace:FindFirstChild("Map") and "YES" or "NO")
		.. " • Escape: " .. (AUTO.EscapetimeHeard and "YES" or "NO")
		.. " • Done: " .. (AUTO.ProgressComplete and "YES" or "NO")
	SubtitleLabel.Text = (AUTO.Running and ("RUNNING • " .. AUTO.Phase) or AUTO.Status)
end))

--==================================================
-- [25] STATUS CARD
--==================================================
local ProfileCard = MakeCard(HomeScroll, "PLAYER", UDim2.new(1,-4,0,90), nil)
ProfileCard.LayoutOrder = 2

local AvatarFrame = MakeFrame(ProfileCard, UDim2.new(0,60,0,60), UDim2.new(0,12,0,24), COLORS.Track, 0)
MakeCorner(AvatarFrame, 30)
MakeStroke(AvatarFrame, GetTheme().Accent, 1.5, 0.35)
local AvatarImage = Create("ImageLabel", {Size = UDim2.new(1,0,1,0), BackgroundTransparency = 1, Image = "", Parent = AvatarFrame})
MakeCorner(AvatarImage, 30)
local PName = MakeLabel(ProfileCard, "N/A", UDim2.new(1,-90,0,24), UDim2.new(0,84,0,24), FONT_BOLD, 16, COLORS.Text)
local PSub  = MakeLabel(ProfileCard, "@N/A", UDim2.new(1,-90,0,18), UDim2.new(0,84,0,48), FONT_TEXT, 12, COLORS.SubText)
local PTeam = MakeLabel(ProfileCard, "Team: N/A", UDim2.new(1,-90,0,18), UDim2.new(0,84,0,66), FONT_TEXT, 12, COLORS.SubText)

pcall(function()
	PName.Text = LocalPlayer.DisplayName or "N/A"
	PSub.Text = "@" .. LocalPlayer.Name
	PTeam.Text = "Team: " .. (LocalPlayer.Team and LocalPlayer.Team.Name or "N/A")
end)
pcall(function()
	local ok, img = pcall(function() return Players:GetUserThumbnailAsync(LocalPlayer.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size150x150) end)
	if ok and img then AvatarImage.Image = img end
end)

--==================================================
-- [26] SETTINGS BUILDERS
--==================================================
local function NewSetCard(title, h)
	local c = MakeCard(SettingsScroll, title, UDim2.new(1,-4,0,h), nil)
	return c
end
local function MakeToggleRow(parent, label, y, getV, onChange)
	local row = MakeFrame(parent, UDim2.new(1,-24,0,44), UDim2.new(0,12,0,y), COLORS.Track, 0.1)
	MakeCorner(row, 10)
	MakeLabel(row, label, UDim2.new(1,-110,1,0), UDim2.new(0,12,0,0), FONT_BOLD, 14, COLORS.Text)
	local btn = MakeButton(row, "", UDim2.new(0,88,0,32), UDim2.new(1,-96,0.5,-16), function()
		local n = not getV()
		onChange(n)
		btn.Text = n and "ON" or "OFF"
		btn.TextColor3 = n and COLORS.Good or COLORS.Bad
	end)
	btn.Text = getV() and "ON" or "OFF"
	btn.TextColor3 = getV() and COLORS.Good or COLORS.Bad
	return row
end
local function MakeCycleRow(parent, label, y, options, getV, onChange, fmt)
	local row = MakeFrame(parent, UDim2.new(1,-24,0,44), UDim2.new(0,12,0,y), COLORS.Track, 0.1)
	MakeCorner(row, 10)
	MakeLabel(row, label, UDim2.new(1,-150,1,0), UDim2.new(0,12,0,0), FONT_BOLD, 14, COLORS.Text)
	local function cur() return fmt and fmt(getV()) or tostring(getV()) end
	local btn = MakeButton(row, cur(), UDim2.new(0,132,0,32), UDim2.new(1,-140,0.5,-16), function()
		local c = getV()
		local idx = 1
		for i,o in ipairs(options) do if o == c then idx = i break end end
		local n = options[(idx % #options) + 1]
		onChange(n)
		btn.Text = cur()
	end)
	return row
end
local function MakeStepperRow(parent, label, y, mn, mx, step, getV, onChange, fmt)
	local row = MakeFrame(parent, UDim2.new(1,-24,0,44), UDim2.new(0,12,0,y), COLORS.Track, 0.1)
	MakeCorner(row, 10)
	MakeLabel(row, label, UDim2.new(0.5,0,1,0), UDim2.new(0,12,0,0), FONT_BOLD, 14, COLORS.Text)
	local vLbl = MakeLabel(row, "", UDim2.new(0,70,0,22), UDim2.new(1,-150,0.5,-11), FONT_BOLD, 14, GetTheme().Accent2, Enum.TextXAlignment.Center)
	local function refresh() vLbl.Text = fmt and fmt(getV()) or tostring(getV()) end
	refresh()
	MakeButton(row, "-", UDim2.new(0,40,0,32), UDim2.new(1,-116,0.5,-16), function() onChange(math.max(mn, getV() - step)); refresh() end)
	MakeButton(row, "+", UDim2.new(0,40,0,32), UDim2.new(1,-52,0.5,-16), function() onChange(math.min(mx, getV() + step)); refresh() end)
	return row
end

local function ApplyTheme()
	local t = GetTheme()
	MainWindow.BackgroundColor3 = t.Base
	MainStroke.Color = t.Accent
	HeaderLogoRing.BackgroundColor3 = t.Accent
	HeaderLogoCore.BackgroundColor3 = t.Accent2
	MiniBody.BackgroundColor3 = t.Base2
	MiniCore.BackgroundColor3 = t.Accent2
	HomeScroll.ScrollBarImageColor3 = t.Accent
	SettingsScroll.ScrollBarImageColor3 = t.Accent2
end

local function SetScale(v)
	local ok = false
	for _, o in ipairs(CONFIG.ScaleOptions) do if math.abs(o - v) < 0.001 then ok = true break end end
	if not ok then return false end
	CONFIG.Scale = v
	if STATE.Open and not STATE.Minimized then ApplyLayout(false) end
	return true
end

local function BuildSettings()
	local display = NewSetCard("DISPLAY", 208)
	display.LayoutOrder = 1
	MakeCycleRow(display, "GUI Scale", 36, CONFIG.ScaleOptions,
		function() return CONFIG.Scale end,
		function(v) SetScale(v) end,
		function(v) return string.format("%d%%", math.floor(v*100+0.5)) end)
	MakeStepperRow(display, "Window Opacity", 88, 0.02, 0.5, 0.02,
		function() return CONFIG.WindowOpacity end,
		function(v) CONFIG.WindowOpacity = v; if not STATE.Minimized then MainWindow.BackgroundTransparency = v end end,
		function(v) return string.format("%.2f", v) end)
	MakeStepperRow(display, "Border", 140, 0, 1, 0.05,
		function() return CONFIG.BorderIntensity end,
		function(v) CONFIG.BorderIntensity = v; MainStroke.Transparency = 1 - v end,
		function(v) return string.format("%.2f", v) end)

	local themeCard = NewSetCard("VISUAL", 88)
	themeCard.LayoutOrder = 2
	MakeCycleRow(themeCard, "Theme", 36, {"Cyber Blue","Neon Cyan","Purple Anime","Crimson","Emerald","Ice"},
		function() return CONFIG.Theme or "Cyber Blue" end,
		function(v) CONFIG.Theme = v; ApplyTheme() end)

	local perfCard = NewSetCard("PERFORMANCE", 140)
	perfCard.LayoutOrder = 3
	MakeToggleRow(perfCard, "Low FX Mode", 36, function() return CONFIG.LowFXMode end, function(v) CONFIG.LowFXMode = v end)
	MakeToggleRow(perfCard, "Animations", 88, function() return CONFIG.AnimationEnabled end, function(v) CONFIG.AnimationEnabled = v end)

	local autoSet = NewSetCard("AUTOMATION", 140)
	autoSet.LayoutOrder = 4
	MakeStepperRow(autoSet, "Enemy Threshold", 36, 10, 100, 5,
		function() return AUTO.EnemyThreshold end,
		function(v) AUTO.EnemyThreshold = v end,
		function(v) return tostring(v) .. " stud" end)

	local dbgCard = NewSetCard("DEBUG", 140)
	dbgCard.LayoutOrder = 5
	local rescanBtn = MakeButton(dbgCard, "Rescan All", UDim2.new(1,-24,0,36), UDim2.new(0,12,0,36), function()
		BuildGenList(); BuildLeverList()
		print("[VANZ] Rescan — Gen:" .. #GenList .. " Lever:" .. #LeverList)
	end)
	MakeCorner(rescanBtn, 10)
	local forceEscapeBtn = MakeButton(dbgCard, "Force Escapetime", UDim2.new(1,-24,0,36), UDim2.new(0,12,0,80), function()
		AUTO.EscapetimeHeard = true
		if AUTO.Running then AUTO.Phase = "LEVER" end
		print("[VANZ] Force Escapetime")
	end)
	MakeCorner(forceEscapeBtn, 10)
end

--==================================================
-- [27] WATCHDOG (GUI PERSIST)
--==================================================
task.spawn(function()
	while not STATE.Destroyed do
		task.wait(2)
		pcall(function()
			if ScreenGui.Parent == nil then
				local bp = BestParent()
				ScreenGui.Parent = bp
			end
			if ScreenGui.DisplayOrder < 2147483647 then ScreenGui.DisplayOrder = 2147483647 end
			if not ScreenGui.Enabled then ScreenGui.Enabled = true end
		end)
	end
end)

--==================================================
-- [28] BACKGROUND RESCAN
--==================================================
task.spawn(function()
	while not STATE.Destroyed do
		task.wait(3)
		if not AUTO.Running then
			pcall(function()
				if workspace:FindFirstChild("Map") then
					BuildGenList()
					BuildLeverList()
				end
			end)
		end
	end
end)

--==================================================
-- [29] ANIMATION TICK
--==================================================
TrackConnection(RunService.Heartbeat:Connect(function(dt)
	if STATE.Destroyed then return end
	STATE.LastFrameDt = dt
	STATE.FrameCount = STATE.FrameCount + 1
	STATE.FrameTimer = STATE.FrameTimer + dt
	if STATE.FrameTimer >= 1 then
		STATE.LastFPS = STATE.FrameCount / STATE.FrameTimer
		STATE.FrameCount = 0; STATE.FrameTimer = 0
	end
	if CONFIG.AnimationEnabled and not CONFIG.LowFXMode and STATE.Open and not STATE.Minimized then
		local pulse = 0.92 + 0.08 * math.sin(os.clock() * 2.2)
		HeaderLogoRing.Size = UDim2.new(pulse,0,pulse,0)
		HeaderLogoRing.Position = UDim2.new((1-pulse)/2,0,(1-pulse)/2,0)
	end
end))

--==================================================
-- [30] GLOBAL API
--==================================================
_G.vanz = _G.vanz or {}
_G.vanz.Open = function() STATE.Open = true; STATE.Minimized = false; MainWindow.Visible = true; MiniLogo.Visible = false; return true end
_G.vanz.Hide = function() STATE.Open = false; MainWindow.Visible = false; MiniLogo.Visible = false; return true end
_G.vanz.Minimize = Minimize
_G.vanz.Restore = Restore
_G.vanz.Start = StartAuto
_G.vanz.Stop = StopAuto
_G.vanz.GetState = function() return AUTO end
_G.vanz.GenList = GenList
_G.vanz.LeverList = LeverList
_G.vanz.ScreenGui = ScreenGui

--==================================================
-- [31] INIT
--==================================================
local function Init()
	ApplyTheme()
	BuildSettings()
	local size = ComputeWindowSize()
	SetMainAbs(CenteredPos(size), size)
	STATE.Built = true
	print("[VANZ] READY — parent: " .. ParentName)
end
local okInit, errInit = pcall(Init)
if not okInit then warn("[VANZ] Init err:", errInit) end

TrackConnection(Camera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
	if STATE.Destroyed then return end
	if STATE.Open and not STATE.Minimized then ApplyLayout(false) end
end))
TrackConnection(Players.PlayerRemoving:Connect(function(p)
	if p == LocalPlayer then CleanupAll(); ScreenGui:Destroy() end
end))