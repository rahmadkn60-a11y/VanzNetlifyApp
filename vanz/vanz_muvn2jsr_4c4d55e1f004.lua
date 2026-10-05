--==================================================
-- [01] SERVICES
--==================================================
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RS = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

--==================================================
-- [02] GUI PERSIST
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

pcall(function()
	local old = LocalPlayer:WaitForChild("PlayerGui"):FindFirstChild("VanzUI")
	if old then old:Destroy() end
end)
if gethui then
	pcall(function()
		local h = gethui()
		if h then
			local old = h:FindFirstChild("VanzUI")
			if old then old:Destroy() end
		end
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
	HoverAnimation = true,
	LowFXMode = false,
	DragThreshold = 8,
	LiveUpdateRate = 0.2,
	ScanInterval = 2.0,
	MaxGenerators = 7,
	MaxLevers = 5,
	EnemyThreshold = 35,
	GenWorkTimeout = 30,
	LeverWorkTimeout = 30,
	MinTeleportGap = 0.2,
	LeverSpamDelay = 0.05,
	ProgressStep = 0.25,
	ProgressTickDelay = 0.02,
	Theme = "Cyber Blue",
}

local THEMES = {
	["Cyber Blue"]  = {Accent = Color3.fromRGB(116,92,255), Accent2 = Color3.fromRGB(0,220,255), Base = Color3.fromRGB(10,11,16), Base2 = Color3.fromRGB(17,18,25)},
	["Neon Cyan"]   = {Accent = Color3.fromRGB(0,230,255), Accent2 = Color3.fromRGB(80,255,200), Base = Color3.fromRGB(8,18,26), Base2 = Color3.fromRGB(16,32,44)},
	["Purple Anime"]= {Accent = Color3.fromRGB(190,110,255), Accent2 = Color3.fromRGB(255,120,220), Base = Color3.fromRGB(18,12,32), Base2 = Color3.fromRGB(30,20,52)},
	["Crimson"]     = {Accent = Color3.fromRGB(255,70,90), Accent2 = Color3.fromRGB(255,160,80), Base = Color3.fromRGB(24,10,14), Base2 = Color3.fromRGB(38,18,26)},
	["Emerald"]     = {Accent = Color3.fromRGB(60,255,150), Accent2 = Color3.fromRGB(160,255,90), Base = Color3.fromRGB(8,22,18), Base2 = Color3.fromRGB(16,38,30)},
	["Ice"]         = {Accent = Color3.fromRGB(160,220,255), Accent2 = Color3.fromRGB(230,250,255), Base = Color3.fromRGB(20,30,42), Base2 = Color3.fromRGB(30,46,64)},
}

local STATE = {
	Built = false, Open = true, Minimized = false, Destroyed = false,
	SettingsOpen = false, MainPosition = nil, MiniPosition = nil,
	LastFrameDt = 0, LiveTimer = 0, ScanTimer = 0,
}

local Connections = {}
local function TrackConnection(c) if c then table.insert(Connections, c) end return c end
local function CleanupAll()
	for _, c in ipairs(Connections) do pcall(function() c:Disconnect() end) end
	table.clear(Connections)
end

--==================================================
-- [04] THEME + FACTORY
--==================================================
local function GetTheme() return THEMES[CONFIG.Theme] or THEMES["Cyber Blue"] end
local COLORS = {
	Text = Color3.fromRGB(245,245,248), SubText = Color3.fromRGB(145,147,158),
	Good = Color3.fromRGB(90,255,170), Warn = Color3.fromRGB(255,200,90),
	Bad = Color3.fromRGB(255,90,110), Card = Color3.fromRGB(17,18,25),
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
	TrackConnection(btn.MouseEnter:Connect(function()
		if not CONFIG.HoverAnimation or CONFIG.LowFXMode then return end
		TweenService:Create(btn, TweenInfo.new(0.18), {BackgroundColor3 = GetTheme().Accent}):Play()
	end))
	TrackConnection(btn.MouseLeave:Connect(function()
		if not CONFIG.HoverAnimation or CONFIG.LowFXMode then return end
		TweenService:Create(btn, TweenInfo.new(0.18), {BackgroundColor3 = GetTheme().Base2}):Play()
	end))
	TrackConnection(btn.MouseButton1Click:Connect(function()
		if onClick then local ok, e = pcall(onClick); if not ok then warn("[VANZ]", e) end end
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

--==================================================
-- [05] VIEWPORT
--==================================================
local BASE_W, BASE_H, MIN_W = 720, 520, 300
local function GetViewport()
	if Camera and Camera.ViewportSize then return Camera.ViewportSize end
	return Vector2.new(1280, 720)
end
local function ComputeWindowSize()
	local vp = GetViewport()
	local s = CONFIG.Scale
	return Vector2.new(
		math.floor(math.clamp(BASE_W * s * 1.9, MIN_W, vp.X - 16)),
		math.floor(math.clamp(BASE_H * s * 1.9, 260, vp.Y - 16))
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
-- [06] MAIN WINDOW
--==================================================
local MainWindow = Create("Frame", {
	Name = "Main", Size = UDim2.new(0,0,0,0), Position = UDim2.new(0,0,0,0),
	BackgroundColor3 = GetTheme().Base, BackgroundTransparency = CONFIG.WindowOpacity,
	BorderSizePixel = 0, ClipsDescendants = true, Visible = true, Parent = ScreenGui,
})
MakeCorner(MainWindow, CONFIG.CornerRadius)
local MainStroke = MakeStroke(MainWindow, GetTheme().Accent, 1.5, 0.25)

local HEADER_H = 52
local Header = MakeFrame(MainWindow, UDim2.new(1,0,0,HEADER_H), UDim2.new(0,0,0,0), GetTheme().Base2, 0.2)
MakeCorner(Header, CONFIG.CornerRadius)

local HeaderLogo = MakeFrame(Header, UDim2.new(0,34,0,34), UDim2.new(0,12,0.5,-17), GetTheme().Base, 1)
MakeCorner(HeaderLogo, 17)
local HeaderLogoRing = MakeFrame(HeaderLogo, UDim2.new(1,0,1,0), UDim2.new(0,0,0,0), GetTheme().Accent, 1)
MakeCorner(HeaderLogoRing, 17)
MakeStroke(HeaderLogoRing, GetTheme().Accent, 2, 0.1)
local HeaderLogoCore = MakeFrame(HeaderLogo, UDim2.new(0,10,0,10), UDim2.new(0.5,-5,0.5,-5), GetTheme().Accent2, 0)
MakeCorner(HeaderLogoCore, 5)

local TitleArea = MakeFrame(Header, UDim2.new(1,-206,1,0), UDim2.new(0,56,0,0), COLORS.Card, 1)
MakeLabel(TitleArea, "VANZ CONTROL", UDim2.new(1,0,0,20), UDim2.new(0,0,0,6), FONT_TITLE, 14, COLORS.Text)
local SubtitleLabel = MakeLabel(TitleArea, "IDLE", UDim2.new(1,0,0,16), UDim2.new(0,0,0,26), FONT_TEXT, 11, COLORS.SubText)

local CONTROL_W = 150
local ControlZone = MakeFrame(Header, UDim2.new(0,CONTROL_W,1,0), UDim2.new(1,-CONTROL_W-8,0,0), COLORS.Card, 1)
local BTN_SZ = 40
local BTN_GAP = 6
local SettingsBtn, MinimizeBtn, CloseBtn
local function LayoutControls()
	local zW, zH = ControlZone.AbsoluteSize.X, ControlZone.AbsoluteSize.Y
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
	Size = UDim2.new(1,0,1,0), BackgroundTransparency = 1, BorderSizePixel = 0,
	ScrollBarThickness = 4, ScrollBarImageColor3 = GetTheme().Accent,
	CanvasSize = UDim2.new(0,0,0,0), AutomaticCanvasSize = Enum.AutomaticSize.None,
	ScrollingDirection = Enum.ScrollingDirection.Y, Parent = Body,
})
local HomeList = Create("UIListLayout", {SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0,10), Parent = HomeScroll})
Create("UIPadding", {PaddingLeft = UDim.new(0,8), PaddingRight = UDim.new(0,8), PaddingTop = UDim.new(0,6), PaddingBottom = UDim.new(0,12), Parent = HomeScroll})

local SettingsScroll = Create("ScrollingFrame", {
	Size = UDim2.new(1,0,1,0), BackgroundTransparency = 1, BorderSizePixel = 0,
	ScrollBarThickness = 4, ScrollBarImageColor3 = GetTheme().Accent2,
	CanvasSize = UDim2.new(0,0,0,0), AutomaticCanvasSize = Enum.AutomaticSize.None,
	ScrollingDirection = Enum.ScrollingDirection.Y, Visible = false, Parent = Body,
})
local SettingsList = Create("UIListLayout", {SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0,10), Parent = SettingsScroll})
Create("UIPadding", {PaddingLeft = UDim.new(0,8), PaddingRight = UDim.new(0,8), PaddingTop = UDim.new(0,6), PaddingBottom = UDim.new(0,12), Parent = SettingsScroll})

TrackConnection(HomeList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
	HomeScroll.CanvasSize = UDim2.new(0,0,0, HomeList.AbsoluteContentSize.Y + 24)
end))
TrackConnection(SettingsList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
	SettingsScroll.CanvasSize = UDim2.new(0,0,0, SettingsList.AbsoluteContentSize.Y + 24)
end))

--==================================================
-- [07] MINI LOGO
--==================================================
local MINI = 58
local MiniLogo = Create("Frame", {Size = UDim2.new(0,MINI,0,MINI), BackgroundTransparency = 1, Visible = false, Parent = ScreenGui})
local MiniBody = MakeFrame(MiniLogo, UDim2.new(1,0,1,0), nil, GetTheme().Base2, 0.15)
MakeCorner(MiniBody, MINI/2)
MakeStroke(MiniBody, GetTheme().Accent, 1.5, 0.2)
local MiniCore = MakeFrame(MiniLogo, UDim2.new(0,16,0,16), UDim2.new(0.5,-8,0.5,-8), GetTheme().Accent2, 0)
MakeCorner(MiniCore, 8)
local MiniHit = Create("TextButton", {Size = UDim2.new(1,0,1,0), BackgroundTransparency = 1, Text = "", AutoButtonColor = false, ZIndex = 5, Parent = MiniLogo})

--==================================================
-- [08] DRAG
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
		local np = ClampAbs(sAbs + delta, target.AbsoluteSize)
		target.Position = UDim2.fromOffset(np.X, np.Y)
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
local function ApplyLayout(keepCenter)
	local size = ComputeWindowSize()
	local pos = (keepCenter or not STATE.MainPosition) and CenteredPos(size) or ClampAbs(STATE.MainPosition, size)
	SetMainAbs(pos, size)
end
local function Minimize()
	if not STATE.Open then return end
	STATE.Minimized = true
	local mc = MainWindow.AbsolutePosition
	local ms = MainWindow.AbsoluteSize
	local vp = GetViewport()
	local x = math.clamp(mc.X + ms.X/2 - MINI/2, 0, vp.X - MINI)
	local y = math.clamp(mc.Y + ms.Y/2 - MINI/2, 0, vp.Y - MINI)
	MiniLogo.Position = UDim2.fromOffset(x, y)
	STATE.MiniPosition = Vector2.new(x, y)
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

BindDrag(MainWindow, Header, function(wasDrag) if wasDrag then STATE.MainPosition = MainWindow.AbsolutePosition end end)
BindDrag(MiniLogo, MiniHit, function(wasDrag)
	if wasDrag then STATE.MiniPosition = MiniLogo.AbsolutePosition else Restore() end
end)

SettingsBtn.MouseButton1Click:Connect(function()
	STATE.SettingsOpen = not STATE.SettingsOpen
	SettingsScroll.Visible = STATE.SettingsOpen
	HomeScroll.Visible = not STATE.SettingsOpen
	SettingsBtn.Text = STATE.SettingsOpen and "⌂" or "⚙"
end)
MinimizeBtn.MouseButton1Click:Connect(Minimize)
CloseBtn.MouseButton1Click:Connect(function()
	STATE.Destroyed = true
	CleanupAll()
	pcall(function() ScreenGui:Destroy() end)
end)

--==================================================
-- [09] AUTO STATE
--==================================================
local AUTO = {
	GenRunning = false, GenToken = 0,
	GenCurrent = 0, GenTotal = 0,
	LevRunning = false, LevToken = 0,
	LevCurrent = 0, LevTotal = 0,
	LevForce = false,
	EscapetimeHeard = false, ProgressComplete = false, Done = false,
	Status = "IDLE", Phase = "IDLE",
	EnemiesNear = 0,
	LastEvadeReason = "",
	NoclipActive = false,
	HasTeammate = false,
}

--==================================================
-- [10] SCANNER
--==================================================
local GenList = {}
local LeverList = {}

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
				if HasGenPoint(ch) then table.insert(found, ch) else scan(ch, depth + 1) end
			end
		end
	end
	scan(workspace, 0)
	return found
end

local function BuildGenList()
	local raw = {}
	for _, gen in ipairs(ScanGenerators()) do
		for _, c in ipairs(gen:GetChildren()) do
			local n = tonumber(c.Name:match("^GeneratorPoint(%d+)$") or "")
			if n then table.insert(raw, {point = c, num = n, model = gen}) end
		end
	end
	table.sort(raw, function(a,b) return a.num < b.num end)
	if #raw > CONFIG.MaxGenerators then
		local t = {}
		for i = 1, CONFIG.MaxGenerators do t[i] = raw[i] end
		raw = t
	end
	GenList = raw
	AUTO.GenTotal = #raw
	return #raw > 0
end

local function FindLeverMain(lever)
	local main = lever:FindFirstChild("Main")
	if main and main:IsA("BasePart") then return main end
	for _, c in ipairs(lever:GetChildren()) do
		if c:IsA("BasePart") then return c end
	end
	return nil
end

local function BuildLeverList()
	local raw = {}
	local function scan(obj, depth)
		if depth > 5 then return end
		for _, ch in ipairs(obj:GetChildren()) do
			if ch.Name == "ExitLever" then
				local m = FindLeverMain(ch)
				if m then table.insert(raw, {lever = ch, main = m, name = ch.Name}) end
			end
			if ch:IsA("Folder") or ch:IsA("Model") then scan(ch, depth + 1) end
		end
	end
	scan(workspace, 0)
	table.sort(raw, function(a,b) return a.name < b.name end)
	if #raw > CONFIG.MaxLevers then
		local t = {}
		for i = 1, CONFIG.MaxLevers do t[i] = raw[i] end
		raw = t
	end
	LeverList = raw
	AUTO.LevTotal = #raw
	return #raw > 0
end

--==================================================
-- [11] REMOTES
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
	Repair       = WaitPath("Remotes", "Generator", "RepairEvent"),
	RepairVFX    = WaitPath("Remotes", "Generator", "RepairVFX"),
	SkillCheck   = WaitPath("Remotes", "Generator", "SkillCheckResultEvent"),
	Escapetime   = WaitPath("Remotes", "Generator", "Escapetime"),
	Oneleft      = WaitPath("Remotes", "Game", "Oneleft"),
	Lever        = WaitPath("Remotes", "Exit", "LeverEvent"),
	LeverAnim    = WaitPath("Remotes", "Exit", "LeverAnim"),
	Progress     = WaitPath("Remotes", "Progress", "ProgressUpdateEvent"),
	GameStart    = WaitPath("Remotes", "Game", "Start"),
	DeleteSpec   = WaitPath("Remotes", "Game", "deletespectatorgui"),
}

local function HookClient(remote, cb)
	if not remote then return end
	local ok = pcall(function() remote.OnClientEvent:Connect(cb) end)
	if not ok then pcall(function() remote.Event:Connect(cb) end) end
end

-- 🔥 firesignal style (spoof client)
local function FireSignal(remote, ...)
	if not remote or not getconnections then return end
	local conns = getconnections(remote.OnClientEvent)
	if not conns then return end
	local args = {...}
	for _, c in ipairs(conns) do
		pcall(function() c:Fire(unpack(args)) end)
	end
end

HookClient(Remotes.GameStart, function()
	if AUTO.Phase == "IDLE" or AUTO.Phase == "WAIT_MAP" then AUTO.Phase = "GENERATOR" end
end)
HookClient(Remotes.DeleteSpec, function()
	if AUTO.Phase == "IDLE" or AUTO.Phase == "WAIT_MAP" then AUTO.Phase = "GENERATOR" end
end)
HookClient(Remotes.Oneleft, function() AUTO.EscapetimeHeard = true end)
HookClient(Remotes.Escapetime, function()
	AUTO.EscapetimeHeard = true
	if AUTO.ProgressComplete or AUTO.Done then return end
	StopGen()
	StartLeverThread("ESCAPE → LEVER")
end)
HookClient(Remotes.Progress, function(p, s)
	if tonumber(p) == 100 and tostring(s) == "OPEN" then
		AUTO.ProgressComplete = true
		AUTO.Done = true
		AUTO.Status = "DONE"
		AUTO.GenRunning = false
		AUTO.LevRunning = false
		AUTO.GenToken = AUTO.GenToken + 1
		AUTO.LevToken = AUTO.LevToken + 1
	end
end)

--==================================================
-- [12] COLOR CLASSIFIER
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
				if d <= CONFIG.EnemyThreshold then count = count + 1 end
				if d < nearest then nearest = d end
			end
		end
	end
	AUTO.EnemiesNear = count
	return nearest
end

-- 🔥 Deteksi ada teammate aktif (color = team/blue)
local function HasActiveTeammate()
	for _, p in ipairs(Players:GetPlayers()) do
		if p ~= LocalPlayer and p.Character then
			local tag = ClassifyColor(GetPlayerColor(p))
			if tag == "team" then return true end
		end
	end
	return false
end

--==================================================
-- [13] NOCLIP ENGINE
--==================================================
local noclipEnabled = false
TrackConnection(RunService.Stepped:Connect(function()
	if not noclipEnabled then return end
	local char = LocalPlayer.Character
	if not char then return end
	for _, p in ipairs(char:GetDescendants()) do
		if p:IsA("BasePart") then
			p.CanCollide = false
		end
	end
end))

local function SetNoclip(on)
	if noclipEnabled == on then return end
	noclipEnabled = on
	AUTO.NoclipActive = on
	print("[VANZ] Noclip:", on and "ON" or "OFF")
end

--==================================================
-- [14] FIRE HELPERS
--==================================================
local CurrentNilMain = nil
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

local function FireRepair(point, state)
	if Remotes.Repair and point then pcall(function() Remotes.Repair:FireServer(point, state) end) end
end
local function FireVFX()
	if Remotes.RepairVFX then pcall(function() Remotes.RepairVFX:FireServer() end) end
end
local function FireSkillCheck(model, point)
	if Remotes.SkillCheck and model and point then
		pcall(function() Remotes.SkillCheck:FireServer("success", 1, model, point) end)
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

--==================================================
-- [15] SPOOF LEVER SEQUENCE (firesignal style)
--==================================================
-- Urutan: LeverAnim(true, CF) → Progress ramp 0.25→100 "OPEN" → Progress(100,"OPEN",false)
-- Stop: LeverAnim(false)

local spoofRunning = false
local spoofToken = 0

local function SpoofLeverFull(mainPart)
	spoofToken = spoofToken + 1
	local myToken = spoofToken
	spoofRunning = true

	local cf = mainPart and mainPart.CFrame or CFrame.new()

	-- Step 1: LeverAnim(true, CF)
	FireSignal(Remotes.LeverAnim, true, cf)
	task.wait(0.05)

	-- Step 2: Progress ramp
	task.spawn(function()
		local i = CONFIG.ProgressStep
		while i <= 100 and spoofRunning and spoofToken == myToken do
			FireSignal(Remotes.Progress, i, "OPEN")
			task.wait(CONFIG.ProgressTickDelay)
			i = i + CONFIG.ProgressStep
			if AUTO.ProgressComplete then break end
		end
		if spoofRunning and spoofToken == myToken then
			-- Step 3: Final trigger (gate open)
			FireSignal(Remotes.Progress, 100, "OPEN", false)
			AUTO.Status = "GATE OPENED (client view)"
		end
	end)
end

local function SpoofLeverStop()
	spoofRunning = false
	spoofToken = spoofToken + 1
	FireSignal(Remotes.LeverAnim, false)
end

--==================================================
-- [16] TELEPORT
--==================================================
local LastTP = 0
local function TP(part, offset)
	if not part then return end
	local now = os.clock()
	if now - LastTP < CONFIG.MinTeleportGap then
		task.wait(CONFIG.MinTeleportGap - (now - LastTP))
	end
	local char = LocalPlayer.Character
	if not char then return end
	local hrp = char:FindFirstChild("HumanoidRootPart")
	if not hrp then return end
	pcall(function() hrp.CFrame = part.CFrame + Vector3.new(0, offset or 3, 0) end)
	LastTP = os.clock()
end

--==================================================
-- [17] DONE DETECTION
--==================================================
local function IsGenDone(idx)
	local entry = GenList[idx]
	if not entry then return true end
	if not entry.model or not entry.model.Parent then return true end
	for _, n in ipairs({"Completed","IsCompleted","Done","IsDone","Fixed","IsFixed","Repaired","IsRepaired"}) do
		if entry.model:GetAttribute(n) == true then return true end
	end
	for _, c in ipairs(entry.model:GetDescendants()) do
		if c:IsA("NumberValue") or c:IsA("IntValue") then
			local low = c.Name:lower()
			if (low:find("progress") or low:find("repair")) and c.Value >= 100 then
				return true
			end
		end
	end
	return false
end

--==================================================
-- [18] GENERATOR WORKER
--==================================================
local function WorkGen(idx, token)
	local entry = GenList[idx]
	if not entry then return "missing" end
	local point, model = entry.point, entry.model
	if IsGenDone(idx) then return "done" end

	if NearestEnemy() < CONFIG.EnemyThreshold then
		AUTO.LastEvadeReason = "killer di area (pra-gen " .. idx .. ")"
		return "evade"
	end

	AUTO.GenCurrent = idx
	AUTO.Status = "GEN " .. idx .. "/" .. AUTO.GenTotal

	TP(point, 3)
	task.wait(0.15)

	if NearestEnemy() < CONFIG.EnemyThreshold then
		AUTO.LastEvadeReason = "killer nongol pas sampai gen " .. idx
		return "evade"
	end

	FireRepair(point, true)
	FireVFX()
	FireSkillCheck(model, point)

	local startT = os.clock()
	local lastRefire = os.clock()
	local lastSkillCheck = os.clock()

	while os.clock() - startT < CONFIG.GenWorkTimeout do
		if AUTO.ProgressComplete or AUTO.Done then FireRepair(point, false); return "signal" end
		if not AUTO.GenRunning or AUTO.GenToken ~= token then FireRepair(point, false); return "stop" end
		if AUTO.EscapetimeHeard then FireRepair(point, false); return "escape" end

		local dist = NearestEnemy()
		if dist < CONFIG.EnemyThreshold then
			FireRepair(point, false)
			AUTO.LastEvadeReason = "killer " .. string.format("%.0f", dist) .. " stud di gen " .. idx .. " — CABUT"
			return "evade"
		end

		if os.clock() - lastSkillCheck >= 0.1 then
			FireSkillCheck(model, point)
			lastSkillCheck = os.clock()
		end

		if IsGenDone(idx) then return "done" end

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
-- [19] LEVER WORKER (Raw spam + Spoof client)
--==================================================
local function ForceLeverWork(idx, token)
	if idx < 1 or idx > #LeverList then return "missing" end
	local entry = LeverList[idx]
	if not entry then return "missing" end

	AUTO.LevCurrent = idx
	AUTO.Status = "LEVER " .. idx .. "/" .. #LeverList

	TP(entry.main, 2)
	task.wait(0.05)

	if NearestEnemy() < CONFIG.EnemyThreshold then
		AUTO.LastEvadeReason = "killer di lever " .. idx .. " — CABUT"
		return "evade"
	end

	-- 🔥 SPOOF CLIENT (firesignal style)
	SpoofLeverFull(entry.main)

	local startT = os.clock()
	local lastKillerCheck = os.clock()

	while os.clock() - startT < CONFIG.LeverWorkTimeout do
		if AUTO.ProgressComplete or AUTO.Done then
			FireLever(false, entry.main)
			SpoofLeverStop()
			return "signal"
		end
		if not AUTO.LevRunning or AUTO.LevToken ~= token then
			FireLever(false, entry.main)
			SpoofLeverStop()
			return "stop"
		end

		if os.clock() - lastKillerCheck > 0.15 then
			if NearestEnemy() < CONFIG.EnemyThreshold then
				FireLever(false, entry.main)
				SpoofLeverStop()
				AUTO.LastEvadeReason = "killer di lever " .. idx .. " — CABUT"
				return "evade"
			end
			lastKillerCheck = os.clock()
		end

		FireLever(true, entry.main)
		task.wait(CONFIG.LeverSpamDelay)
	end

	FireLever(false, entry.main)
	SpoofLeverStop()
	return "timeout"
end

--==================================================
-- [20] THREAD MANAGERS
--==================================================
local function StartGen()
	if AUTO.GenRunning then
		AUTO.GenToken = AUTO.GenToken + 1
		task.wait(0.05)
	end
	AUTO.GenRunning = true
	AUTO.GenToken = AUTO.GenToken + 1
	local myToken = AUTO.GenToken
	AUTO.EscapetimeHeard = false
	AUTO.ProgressComplete = false
	AUTO.Done = false

	task.spawn(function()
		AUTO.Phase = "WAIT_MAP"
		AUTO.Status = "WAIT MAP"

		local waitStart = os.clock()
		while AUTO.GenRunning and AUTO.GenToken == myToken and os.clock() - waitStart < 60 do
			if AUTO.EscapetimeHeard then
				StopGen()
				StartLeverThread("ESCAPE → LEVER")
				return
			end
			if workspace:FindFirstChild("Map") and BuildGenList() then break end
			task.wait(0.4)
		end

		if not AUTO.GenRunning or AUTO.GenToken ~= myToken then return end
		AUTO.Phase = "GENERATOR"

		local visited = {}
		while AUTO.GenRunning and AUTO.GenToken == myToken and not AUTO.Done do
			if AUTO.EscapetimeHeard then
				StopGen()
				StartLeverThread("ESCAPE → LEVER")
				return
			end

			BuildGenList()
			if AUTO.GenTotal == 0 then
				task.wait(0.5)
			else
				local acted = false
				local anyUndone = false
				for i = 1, AUTO.GenTotal do
					if AUTO.GenToken ~= myToken then return end
					if AUTO.EscapetimeHeard then
						StopGen()
						StartLeverThread("ESCAPE → LEVER")
						return
					end
					if not IsGenDone(i) then
						anyUndone = true
						if not visited[i] then
							acted = true
							local r = WorkGen(i, myToken)
							if r == "done" then visited = {} break
							elseif r == "evade" then visited[i] = true
							elseif r == "escape" then
								StopGen()
								StartLeverThread("ESCAPE → LEVER")
								return
							elseif r == "stop" then return
							elseif r == "timeout" or r == "missing" then visited[i] = true end
						end
					end
				end
				if not anyUndone then
					AUTO.Status = "WAIT ESCAPE"
					task.wait(1)
				elseif not acted then
					AUTO.Status = "EVADE ALL — nunggu clear"
					visited = {}
					task.wait(1)
				end
			end
			task.wait(0.1)
		end
		AUTO.GenRunning = false
	end)
end

local function StopGen()
	AUTO.GenToken = AUTO.GenToken + 1
	AUTO.GenRunning = false
end

local function StartLeverThread(reason)
	if AUTO.LevRunning then
		AUTO.LevToken = AUTO.LevToken + 1
		task.wait(0.05)
	end
	AUTO.LevRunning = true
	AUTO.LevToken = AUTO.LevToken + 1
	local myToken = AUTO.LevToken
	AUTO.LevForce = true
	AUTO.Status = reason
	AUTO.Phase = "LEVER"
	AUTO.LastEvadeReason = ""

	task.spawn(function()
		local visited = {}
		while AUTO.LevRunning and AUTO.LevToken == myToken and not AUTO.Done do
			if AUTO.ProgressComplete then
				AUTO.LevRunning = false
				return
			end

			BuildLeverList()
			if AUTO.LevTotal == 0 then
				AUTO.Status = reason .. " | WAIT LEVER"
				task.wait(0.4)
			else
				local allVisited = true
				for i = 1, AUTO.LevTotal do
					if AUTO.LevToken ~= myToken then return end
					if AUTO.ProgressComplete or AUTO.Done then return end
					if not visited[i] then
						allVisited = false
						local r = ForceLeverWork(i, myToken)
						if r == "signal" then
							AUTO.LevRunning = false
							return
						end
						if r == "stop" then return end
						visited[i] = true
					end
				end
				if allVisited then
					visited = {}
					AUTO.Status = reason .. " | RESET"
					task.wait(0.6)
				end
			end
			task.wait(0.1)
		end
		AUTO.LevRunning = false
	end)
end

local function StopLeverThread()
	AUTO.LevToken = AUTO.LevToken + 1
	AUTO.LevRunning = false
	AUTO.LevForce = false
	SpoofLeverStop()
end

local function StopAll()
	StopGen()
	StopLeverThread()
	AUTO.Status = "STOPPED"
	AUTO.Phase = "IDLE"
	SetNoclip(false)
end

--==================================================
-- [21] NOCLIP LOGIC LOOP
--==================================================
TrackConnection(RunService.Heartbeat:Connect(function(dt)
	if STATE.Destroyed then return end

	-- Cek teammate aktif
	AUTO.HasTeammate = HasActiveTeammate()

	-- Noclip on kalau:
	-- 1. Map loaded
	-- 2. Phase lever aktif (force ATAU auto gen di phase lever)
	-- 3. Ada teammate aktif (color circle = team/blue)
	local mapLoaded = workspace:FindFirstChild("Map") ~= nil
	local leverPhaseActive = AUTO.LevRunning and (AUTO.LevForce or AUTO.Phase == "LEVER")
	local shouldNoclip = mapLoaded and leverPhaseActive and AUTO.HasTeammate

	SetNoclip(shouldNoclip)
end))

--==================================================
-- [22] AUTO OPERATIONS CARD
--==================================================
local AutoCard = MakeCard(HomeScroll, "AUTO OPERATIONS", UDim2.new(1,-4,0,420), nil)
AutoCard.LayoutOrder = 1

local StatusLbl = MakeLabel(AutoCard, "Status: IDLE", UDim2.new(1,-24,0,20), UDim2.new(0,12,0,36), FONT_BOLD, 15, COLORS.Text)
local PhaseLbl  = MakeLabel(AutoCard, "Phase: IDLE", UDim2.new(1,-24,0,18), UDim2.new(0,12,0,58), FONT_TEXT, 13, COLORS.SubText)
local GenLbl    = MakeLabel(AutoCard, "Generators: 0 / 0", UDim2.new(1,-24,0,18), UDim2.new(0,12,0,78), FONT_TEXT, 13, COLORS.Text)
local LevLbl    = MakeLabel(AutoCard, "Levers: 0 / 0", UDim2.new(1,-24,0,18), UDim2.new(0,12,0,98), FONT_TEXT, 13, COLORS.Text)
local EnemyLbl  = MakeLabel(AutoCard, "Enemies Near: 0 (thr 35)", UDim2.new(1,-24,0,18), UDim2.new(0,12,0,118), FONT_TEXT, 13, COLORS.Text)
local TeamLbl   = MakeLabel(AutoCard, "Teammate: NO | Noclip: OFF", UDim2.new(1,-24,0,18), UDim2.new(0,12,0,138), FONT_TEXT, 13, COLORS.Text)
local SignalLbl = MakeLabel(AutoCard, "Map: N | Esc: N | GenRun: N | LevRun: N", UDim2.new(1,-24,0,18), UDim2.new(0,12,0,158), FONT_TEXT, 11, COLORS.SubText)
local EvadeLbl  = MakeLabel(AutoCard, "Evade: -", UDim2.new(1,-24,0,18), UDim2.new(0,12,0,178), FONT_TEXT, 11, COLORS.Warn)

local StartGenBtn = MakeButton(AutoCard, "START AUTO GEN", UDim2.new(1,-24,0,38), UDim2.new(0,12,0,208), function()
	if AUTO.GenRunning then
		StopGen()
		StartGenBtn.Text = "START AUTO GEN"
	else
		StartGen()
		StartGenBtn.Text = "STOP AUTO GEN"
	end
end)
MakeCorner(StartGenBtn, 10)

local ForceLeverBtn = MakeButton(AutoCard, "FORCE LEVER : OFF", UDim2.new(1,-24,0,38), UDim2.new(0,12,0,254), function()
	if AUTO.LevForce then
		StopLeverThread()
		ForceLeverBtn.Text = "FORCE LEVER : OFF"
		ForceLeverBtn.TextColor3 = COLORS.Text
	else
		AUTO.ProgressComplete = false
		AUTO.Done = false
		StartLeverThread("FORCE LEVER")
		ForceLeverBtn.Text = "FORCE LEVER : ON"
		ForceLeverBtn.TextColor3 = COLORS.Bad
	end
end)
MakeCorner(ForceLeverBtn, 10)

local RescanBtn = MakeButton(AutoCard, "Rescan", UDim2.new(0.5,-8,0,34), UDim2.new(0,12,0,300), function()
	if workspace:FindFirstChild("Map") then
		BuildGenList(); BuildLeverList()
	end
end)
MakeCorner(RescanBtn, 10)

local StopAllBtn = MakeButton(AutoCard, "STOP ALL", UDim2.new(0.5,-8,0,34), UDim2.new(0.5,4,0,300), function()
	StopAll()
	StartGenBtn.Text = "START AUTO GEN"
	ForceLeverBtn.Text = "FORCE LEVER : OFF"
	ForceLeverBtn.TextColor3 = COLORS.Text
end)
MakeCorner(StopAllBtn, 10)
StopAllBtn.TextColor3 = COLORS.Bad

local SpoofGateBtn = MakeButton(AutoCard, "Spoof Gate (test)", UDim2.new(1,-24,0,34), UDim2.new(0,12,0,344), function()
	-- Trigger spoof tanpa lewat lever
	local cf = CFrame.new()
	for _, entry in ipairs(LeverList) do
		if entry.main then cf = entry.main.CFrame break end
	end
	SpoofLeverFull(nil)
end)
MakeCorner(SpoofGateBtn, 10)

local SpoofStopBtn = MakeButton(AutoCard, "Spoof Stop", UDim2.new(1,-24,0,34), UDim2.new(0,12,0,382), function()
	SpoofLeverStop()
end)
MakeCorner(SpoofStopBtn, 10)

--==================================================
-- [23] SETTINGS
--==================================================
local function NewSetCard(title, h) return MakeCard(SettingsScroll, title, UDim2.new(1,-4,0,h), nil) end
local function MakeCycleRow(parent, label, y, options, getV, onChange, fmt)
	local row = MakeFrame(parent, UDim2.new(1,-24,0,44), UDim2.new(0,12,0,y), COLORS.Track, 0.1)
	MakeCorner(row, 10)
	MakeLabel(row, label, UDim2.new(1,-150,1,0), UDim2.new(0,12,0,0), FONT_BOLD, 14, COLORS.Text)
	local function cur() return fmt and fmt(getV()) or tostring(getV()) end
	local btn = MakeButton(row, cur(), UDim2.new(0,132,0,32), UDim2.new(1,-140,0.5,-16), function()
		local c = getV()
		local idx = 1
		for i,o in ipairs(options) do if o == c then idx = i break end end
		onChange(options[(idx % #options) + 1])
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

local function BuildSettings()
	local display = NewSetCard("DISPLAY", 160)
	display.LayoutOrder = 1
	MakeCycleRow(display, "GUI Scale", 36, CONFIG.ScaleOptions,
		function() return CONFIG.Scale end,
		function(v) CONFIG.Scale = v; if STATE.Open and not STATE.Minimized then ApplyLayout(false) end end,
		function(v) return string.format("%d%%", math.floor(v*100+0.5)) end)
	MakeStepperRow(display, "Opacity", 88, 0.02, 0.5, 0.02,
		function() return CONFIG.WindowOpacity end,
		function(v) CONFIG.WindowOpacity = v; if not STATE.Minimized then MainWindow.BackgroundTransparency = v end end,
		function(v) return string.format("%.2f", v) end)

	local themeCard = NewSetCard("VISUAL", 88)
	themeCard.LayoutOrder = 2
	MakeCycleRow(themeCard, "Theme", 36, {"Cyber Blue","Neon Cyan","Purple Anime","Crimson","Emerald","Ice"},
		function() return CONFIG.Theme end,
		function(v) CONFIG.Theme = v; ApplyTheme() end)

	local autoSet = NewSetCard("AUTOMATION", 256)
	autoSet.LayoutOrder = 3
	MakeStepperRow(autoSet, "Enemy Threshold", 36, 10, 100, 5,
		function() return CONFIG.EnemyThreshold end,
		function(v) CONFIG.EnemyThreshold = v end,
		function(v) return tostring(v) .. " stud" end)
	MakeStepperRow(autoSet, "Lever Spam Delay", 88, 0.01, 0.2, 0.01,
		function() return CONFIG.LeverSpamDelay end,
		function(v) CONFIG.LeverSpamDelay = v end,
		function(v) return string.format("%.2fs", v) end)
	MakeStepperRow(autoSet, "Progress Tick", 140, 0.005, 0.1, 0.005,
		function() return CONFIG.ProgressTickDelay end,
		function(v) CONFIG.ProgressTickDelay = v end,
		function(v) return string.format("%.3fs", v) end)
	MakeStepperRow(autoSet, "Teleport Gap", 192, 0.1, 1.0, 0.05,
		function() return CONFIG.MinTeleportGap end,
		function(v) CONFIG.MinTeleportGap = v end,
		function(v) return string.format("%.2fs", v) end)
end

--==================================================
-- [24] WATCHDOG
--==================================================
task.spawn(function()
	while not STATE.Destroyed do
		task.wait(2)
		pcall(function()
			local bp = BestParent()
			if ScreenGui.Parent ~= bp then ScreenGui.Parent = bp end
			if ScreenGui.DisplayOrder < 2147483647 then ScreenGui.DisplayOrder = 2147483647 end
			if not ScreenGui.Enabled then ScreenGui.Enabled = true end
		end)
	end
end)

--==================================================
-- [25] LIVE PANEL
--==================================================
TrackConnection(RunService.Heartbeat:Connect(function(dt)
	if STATE.Destroyed then return end
	STATE.LastFrameDt = dt
	STATE.LiveTimer = STATE.LiveTimer + dt
	STATE.ScanTimer = STATE.ScanTimer + dt

	if STATE.ScanTimer >= CONFIG.ScanInterval then
		STATE.ScanTimer = 0
		if workspace:FindFirstChild("Map") then
			pcall(BuildGenList)
			pcall(BuildLeverList)
		else
			GenList = {}
			LeverList = {}
			AUTO.GenTotal = 0
			AUTO.LevTotal = 0
		end
	end

	if STATE.LiveTimer >= CONFIG.LiveUpdateRate then
		STATE.LiveTimer = 0
		if not STATE.Built then return end
		local doneCount = 0
		for i = 1, AUTO.GenTotal do
			if IsGenDone(i) then doneCount = doneCount + 1 end
		end
		StatusLbl.Text = "Status: " .. AUTO.Status
		PhaseLbl.Text = "Phase: " .. AUTO.Phase
		GenLbl.Text = "Generators: " .. doneCount .. " done / " .. AUTO.GenTotal ..
			(AUTO.GenCurrent > 0 and " • #" .. AUTO.GenCurrent or "")
		LevLbl.Text = "Levers: " .. AUTO.LevCurrent .. " / " .. AUTO.LevTotal
		EnemyLbl.Text = "Enemies Near: " .. AUTO.EnemiesNear .. " (thr " .. CONFIG.EnemyThreshold .. ")"
		TeamLbl.Text = "Teammate: " .. (AUTO.HasTeammate and "YES" or "NO") ..
			" | Noclip: " .. (AUTO.NoclipActive and "ON" or "OFF")
		SignalLbl.Text = "Map: " .. (workspace:FindFirstChild("Map") and "Y" or "N") ..
			" | Esc: " .. (AUTO.EscapetimeHeard and "Y" or "N") ..
			" | GenRun: " .. (AUTO.GenRunning and "Y" or "N") ..
			" | LevRun: " .. (AUTO.LevRunning and "Y" or "N")
		EvadeLbl.Text = "Evade: " .. (AUTO.LastEvadeReason ~= "" and AUTO.LastEvadeReason or "-")
		SubtitleLabel.Text = (AUTO.LevRunning and ("LEVER • " .. AUTO.Phase) or
			AUTO.GenRunning and ("GEN • " .. AUTO.Phase) or AUTO.Status)
	end
end))

--==================================================
-- [26] GLOBAL API
--==================================================
_G.vanz = _G.vanz or {}
_G.vanz.StartGen = StartGen
_G.vanz.StopGen = StopGen
_G.vanz.StartLever = function() StartLeverThread("FORCE LEVER") end
_G.vanz.StopLever = StopLeverThread
_G.vanz.StopAll = StopAll
_G.vanz.SpoofGate = function() SpoofLeverFull(nil) end
_G.vanz.SpoofStop = SpoofLeverStop
_G.vanz.GetState = function() return AUTO end
_G.vanz.GetGenList = function() return GenList end
_G.vanz.GetLeverList = function() return LeverList end
_G.vanz.Rescan = function()
	if workspace:FindFirstChild("Map") then BuildGenList(); BuildLeverList() end
	return {gens = #GenList, levers = #LeverList}
end
_G.vanz.ScreenGui = ScreenGui

--==================================================
-- [27] INIT
--==================================================
local function Init()
	ApplyTheme()
	BuildSettings()
	local size = ComputeWindowSize()
	SetMainAbs(CenteredPos(size), size)
	STATE.Built = true
	print("[VANZ] READY — parent:" .. ParentName)
end
local okInit, errInit = pcall(Init)
if not okInit then warn("[VANZ] Init:", errInit) end

TrackConnection(Camera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
	if STATE.Destroyed then return end
	if STATE.Open and not STATE.Minimized then ApplyLayout(false) end
end))

TrackConnection(Players.PlayerRemoving:Connect(function(p)
	if p == LocalPlayer then
		SetNoclip(false)
		CleanupAll()
		pcall(function() ScreenGui:Destroy() end)
	end
end))