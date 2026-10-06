local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RS = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

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

local CONFIG = {
	Scale = 0.55,
	ScaleOptions = {0.40, 0.50, 0.55, 0.60, 0.70, 0.80, 0.90, 1.00},
	WindowOpacity = 0.10,
	CornerRadius = 14,
	HoverAnimation = true,
	DragThreshold = 8,
	LiveUpdateRate = 0.2,
	ScanInterval = 2.0,
	MaxGenerators = 7,
	MaxLevers = 5,
	EnemyThreshold = 35,
	GenWorkTimeout = 30,
	LeverWorkTimeout = 60,
	MinTeleportGap = 0.2,
	LeverSpamDelay = 0.05,
	SeqTickDelay = 0.01,
	BypassOffsetY = 10,
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
		if not CONFIG.HoverAnimation then return end
		TweenService:Create(btn, TweenInfo.new(0.18), {BackgroundColor3 = GetTheme().Accent}):Play()
	end))
	TrackConnection(btn.MouseLeave:Connect(function()
		if not CONFIG.HoverAnimation then return end
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

local MINI = 58
local MiniLogo = Create("Frame", {Size = UDim2.new(0,MINI,0,MINI), BackgroundTransparency = 1, Visible = false, Parent = ScreenGui})
local MiniBody = MakeFrame(MiniLogo, UDim2.new(1,0,1,0), nil, GetTheme().Base2, 0.15)
MakeCorner(MiniBody, MINI/2)
MakeStroke(MiniBody, GetTheme().Accent, 1.5, 0.2)
local MiniCore = MakeFrame(MiniLogo, UDim2.new(0,16,0,16), UDim2.new(0.5,-8,0.5,-8), GetTheme().Accent2, 0)
MakeCorner(MiniCore, 8)
local MiniHit = Create("TextButton", {Size = UDim2.new(1,0,1,0), BackgroundTransparency = 1, Text = "", AutoButtonColor = false, ZIndex = 5, Parent = MiniLogo})

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

local AUTO = {
	GenRunning = false, GenToken = 0, GenCurrent = 0, GenTotal = 0,
	LevRunning = false, LevToken = 0, LevCurrent = 0, LevTotal = 0,
	LevForce = false, EscapetimeHeard = false, ProgressComplete = false, Done = false,
	Status = "IDLE", Phase = "IDLE", EnemiesNear = 0, LastEvadeReason = "",
	NoclipActive = false, HasTeammate = false, SeqProgress = 0, SeqCount = 0,
	SpoofActive = false, GatePartsFound = 0,
	EndgameActive = false, EndgameTriggered = false,
	SpectatorTriggered = false,
}

local BYPASS = {
	Active = false,
	SavedCFrame = nil,
	SavedVelocity = nil,
	SavedAngularVelocity = nil,
	SavedChar = nil,
	TickCount = 0,
	LastEnemyName = nil,
	Status = "OFF",
}

local GenList = {}
local LeverList = {}
local GateParts = {}
local GateGui = nil
local EndgameGui = nil

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

local function BuildGateParts()
	GateParts = {}
	local map = workspace:FindFirstChild("Map")
	if not map then
		AUTO.GatePartsFound = 0
		return 0
	end
	for _, d in ipairs(map:GetDescendants()) do
		if d:IsA("BasePart") then
			local n = d.Name:lower()
			local pn = d.Parent and d.Parent.Name:lower() or ""
			if n:find("gate") or n:find("door") or n:find("barrier")
				or (n:find("exit") and not n:find("lever"))
				or pn:find("gate") or pn:find("door") then
				table.insert(GateParts, d)
			end
		end
	end
	AUTO.GatePartsFound = #GateParts
	return #GateParts
end

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
	SpectateEnabler = WaitPath("Remotes", "Spectate", "Spectateenabler"),
}

local function HookClient(remote, cb)
	if not remote then return end
	local ok = pcall(function() remote.OnClientEvent:Connect(cb) end)
	if not ok then pcall(function() remote.Event:Connect(cb) end) end
end

--==================================================
-- ENDGAME RESOLVER
--==================================================
local function GetEndgameGui()
	if EndgameGui and EndgameGui.Parent then return EndgameGui end
	EndgameGui = nil
	local pg = LocalPlayer:FindFirstChild("PlayerGui")
	if not pg then return nil end
	local survivor = pg:FindFirstChild("Survivor-mob")
	if not survivor then return nil end
	local timeFolder = survivor:FindFirstChild("time")
	if not timeFolder then return nil end
	local eg = timeFolder:FindFirstChild("endgame")
	if eg then EndgameGui = eg end
	return EndgameGui
end

local function TriggerEndgame()
	if AUTO.EndgameTriggered then return end
	AUTO.EndgameTriggered = true
	AUTO.EndgameActive = true
	print("[VANZ] Endgame triggered — replay .Visible=true")
end

local function ResetEndgame()
	AUTO.EndgameActive = false
	AUTO.EndgameTriggered = false
end

--==================================================
-- HOOK LISTENERS
--==================================================
HookClient(Remotes.GameStart, function()
	if AUTO.Phase == "IDLE" or AUTO.Phase == "WAIT_MAP" then AUTO.Phase = "GENERATOR" end
	AUTO.SpectatorTriggered = false
end)
HookClient(Remotes.DeleteSpec, function()
	if AUTO.Phase == "IDLE" or AUTO.Phase == "WAIT_MAP" then AUTO.Phase = "GENERATOR" end
	AUTO.SpectatorTriggered = false
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
		AUTO.SpoofActive = false
		AUTO.GenToken = AUTO.GenToken + 1
		AUTO.LevToken = AUTO.LevToken + 1
		TriggerEndgame()
	end
end)

-- 🔥 SPECTATE HOOK — matiin noclip sekali per round
HookClient(Remotes.SpectateEnabler, function()
	if AUTO.SpectatorTriggered then return end
	AUTO.SpectatorTriggered = true
	print("[VANZ] Spectateenabler triggered — noclip OFF for this round")
end)

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

local function HasActiveTeammate()
	for _, p in ipairs(Players:GetPlayers()) do
		if p ~= LocalPlayer and p.Character then
			if ClassifyColor(GetPlayerColor(p)) == "team" then return true end
		end
	end
	return false
end

-- =========================================================
-- BYPASS UNHOOK — teleport ke killer -10 stud + override server
-- =========================================================
local function BypassFindEnemyHRP()
	local myChar = LocalPlayer.Character
	if not myChar then return nil end
	local myHrp = myChar:FindFirstChild("HumanoidRootPart")
	if not myHrp then return nil end
	local best, bestD, bestPlr = nil, math.huge, nil
	for _, p in ipairs(Players:GetPlayers()) do
		if p ~= LocalPlayer and p.Character then
			if ClassifyColor(GetPlayerColor(p)) == "enemy" then
				local hrp = p.Character:FindFirstChild("HumanoidRootPart")
				local hum = p.Character:FindFirstChildOfClass("Humanoid")
				if hrp and hum and hum.Health > 0 then
					local d = (hrp.Position - myHrp.Position).Magnitude
					if d < bestD then bestD = d; best = hrp; bestPlr = p end
				end
			end
		end
	end
	if bestPlr then BYPASS.LastEnemyName = bestPlr.Name end
	return best
end

local function BypassForceOwnership(hrp)
	if not hrp then return end
	pcall(function() hrp:SetNetworkOwner(LocalPlayer) end)
	pcall(function() hrp:SetNetworkOwnershipAuto() ; hrp:SetNetworkOwner(LocalPlayer) end)
	if sethiddenproperty then
		pcall(function() sethiddenproperty(hrp, "PhysicsRepRootPart", true) end)
	end
end

local function BypassSavePos()
	local char = LocalPlayer.Character
	if not char then return false end
	local hrp = char:FindFirstChild("HumanoidRootPart")
	if not hrp then return false end
	BYPASS.SavedCFrame = hrp.CFrame
	BYPASS.SavedVelocity = hrp.AssemblyLinearVelocity
	BYPASS.SavedAngularVelocity = hrp.AssemblyAngularVelocity
	BYPASS.SavedChar = char
	return true
end

local function BypassRestorePos()
	local char = LocalPlayer.Character
	if not char then return false end
	local hrp = char:FindFirstChild("HumanoidRootPart")
	if not hrp then return false end
	if not BYPASS.SavedCFrame then return false end
	BypassForceOwnership(hrp)
	pcall(function() hrp.CFrame = BYPASS.SavedCFrame end)
	pcall(function()
		if BYPASS.SavedVelocity then hrp.AssemblyLinearVelocity = BYPASS.SavedVelocity end
		if BYPASS.SavedAngularVelocity then hrp.AssemblyAngularVelocity = BYPASS.SavedAngularVelocity end
	end)
	return true
end

local function BypassStep()
	if not BYPASS.Active then return end
	local char = LocalPlayer.Character
	if not char then return end
	if BYPASS.SavedChar and BYPASS.SavedChar ~= char then
		BYPASS.Active = false
		BYPASS.Status = "OFF (respawn)"
		return
	end
	local hrp = char:FindFirstChild("HumanoidRootPart")
	if not hrp then return end

	local enemyHrp = BypassFindEnemyHRP()
	if not enemyHrp then
		BYPASS.Status = "ON (no enemy)"
		return
	end

	BypassForceOwnership(hrp)

	local targetPos = enemyHrp.Position - Vector3.new(0, CONFIG.BypassOffsetY, 0)
	local targetCF = CFrame.new(targetPos) * (enemyHrp.CFrame - enemyHrp.Position)
	pcall(function() hrp.CFrame = targetCF end)
	pcall(function()
		hrp.AssemblyLinearVelocity = Vector3.zero
		hrp.AssemblyAngularVelocity = Vector3.zero
		hrp.Velocity = Vector3.zero
		hrp.RotVelocity = Vector3.zero
	end)
	BYPASS.TickCount = BYPASS.TickCount + 1
	BYPASS.Status = "ON → " .. (BYPASS.LastEnemyName or "?")
end

TrackConnection(RunService.RenderStepped:Connect(BypassStep))
TrackConnection(RunService.Stepped:Connect(BypassStep))
TrackConnection(RunService.Heartbeat:Connect(BypassStep))

task.spawn(function()
	while not STATE.Destroyed do
		if BYPASS.Active then BypassStep() end
		task.wait()
	end
end)

-- =========================================================
-- NOCLIP — aktif selama Map + spectate belum trigger
-- =========================================================
local noclipEnabled = false
TrackConnection(RunService.Stepped:Connect(function()
	if not noclipEnabled then return end
	local char = LocalPlayer.Character
	if not char then return end
	for _, p in ipairs(char:GetDescendants()) do
		if p:IsA("BasePart") then p.CanCollide = false end
	end
end))
local function SetNoclip(on)
	if noclipEnabled == on then return end
	noclipEnabled = on
	AUTO.NoclipActive = on
end

-- =========================================================
-- RENDER LOOP — spoof bar putih + force endgame visible
-- =========================================================
TrackConnection(RunService.RenderStepped:Connect(function()
	if AUTO.EndgameActive then
		local eg = GetEndgameGui()
		if eg then
			pcall(function() eg.Visible = true end)
		end
	end

	if not AUTO.SpoofActive then return end

	local char = LocalPlayer.Character
	if char then
		for _, p in ipairs(char:GetDescendants()) do
			if p:IsA("BasePart") then p.CanCollide = false end
		end
	end

	if #GateParts == 0 then pcall(BuildGateParts) end

	for _, g in ipairs(GateParts) do
		if g and g.Parent then
			pcall(function()
				g.CanCollide = false
				g.Transparency = 1
				g.LocalTransparencyModifier = 1
			end)
		end
	end

	if not GateGui or not GateGui.Parent then
		pcall(function()
			local pg = LocalPlayer:FindFirstChild("PlayerGui")
			GateGui = pg and pg:FindFirstChild("ProgressPromptGui")
		end)
	end
	if GateGui then
		local frame = GateGui:FindFirstChild("Frame")
		if frame then
			frame.Visible = true
			local tl = frame:FindFirstChild("TextLabel")
			if tl then tl.Text = "OPEN"; tl.TextTransparency = 0 end
			local bar = frame:FindFirstChild("Bar")
			if bar then
				bar.Size = UDim2.new(1, 0, bar.Size.Y.Scale, bar.Size.Y.Offset)
				bar.ImageTransparency = 0
			end
		end
	end
end))

-- =========================================================
-- FIRE HELPERS
-- =========================================================
local CurrentNilMain = nil
local function FindNilMain()
	if not getnilinstances then return nil end
	local ok, list = pcall(getnilinstances)
	if not ok or not list then return nil end
	for _, obj in ipairs(list) do
		if obj.Name == "Main" and typeof(obj) == "Instance" and obj:IsA("BasePart") then return obj end
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
			if (low:find("progress") or low:find("repair")) and c.Value >= 100 then return true end
		end
	end
	return false
end

local function WorkGen(idx, token)
	local entry = GenList[idx]
	if not entry then return "missing" end
	local point, model = entry.point, entry.model
	if IsGenDone(idx) then return "done" end

	if NearestEnemy() < CONFIG.EnemyThreshold then
		AUTO.LastEvadeReason = "killer pra-gen " .. idx
		return "evade"
	end

	AUTO.GenCurrent = idx
	AUTO.Status = "GEN " .. idx .. "/" .. AUTO.GenTotal

	TP(point, 3)
	task.wait(0.15)

	if NearestEnemy() < CONFIG.EnemyThreshold then
		AUTO.LastEvadeReason = "killer di gen " .. idx
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
			AUTO.LastEvadeReason = "killer " .. string.format("%.0f", dist) .. " di gen " .. idx .. " — CABUT"
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

-- =========================================================
-- SEQUENCE 0.25 → 100 LITERAL
-- =========================================================
local SeqToken = 0
local SeqRunning = false

local LeverAnimEv = RS:WaitForChild("Remotes"):WaitForChild("Exit"):WaitForChild("LeverAnim")
local ProgressEv = RS:WaitForChild("Remotes"):WaitForChild("Progress"):WaitForChild("ProgressUpdateEvent")

local function PlayLeverSequence(mainPart)
	SeqToken = SeqToken + 1
	local myToken = SeqToken
	SeqRunning = true
	AUTO.SeqProgress = 0
	AUTO.SeqCount = 0
	AUTO.SpoofActive = true

	local cf = mainPart and mainPart.CFrame or CFrame.new()

	task.spawn(function()
		firesignal(LeverAnimEv.OnClientEvent, true, cf)
		task.wait(0.05)

		firesignal(ProgressEv.OnClientEvent, 0.25, "OPEN"); AUTO.SeqProgress = 0.25; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 0.5, "OPEN"); AUTO.SeqProgress = 0.5; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 0.75, "OPEN"); AUTO.SeqProgress = 0.75; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 1, "OPEN"); AUTO.SeqProgress = 1; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 1.25, "OPEN"); AUTO.SeqProgress = 1.25; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 1.5, "OPEN"); AUTO.SeqProgress = 1.5; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 1.75, "OPEN"); AUTO.SeqProgress = 1.75; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 2, "OPEN"); AUTO.SeqProgress = 2; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 2.25, "OPEN"); AUTO.SeqProgress = 2.25; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 2.5, "OPEN"); AUTO.SeqProgress = 2.5; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 2.75, "OPEN"); AUTO.SeqProgress = 2.75; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 3, "OPEN"); AUTO.SeqProgress = 3; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 3.25, "OPEN"); AUTO.SeqProgress = 3.25; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 3.5, "OPEN"); AUTO.SeqProgress = 3.5; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 3.75, "OPEN"); AUTO.SeqProgress = 3.75; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 4, "OPEN"); AUTO.SeqProgress = 4; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 4.25, "OPEN"); AUTO.SeqProgress = 4.25; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 4.5, "OPEN"); AUTO.SeqProgress = 4.5; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 4.75, "OPEN"); AUTO.SeqProgress = 4.75; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 5, "OPEN"); AUTO.SeqProgress = 5; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 5.25, "OPEN"); AUTO.SeqProgress = 5.25; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 5.5, "OPEN"); AUTO.SeqProgress = 5.5; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 5.75, "OPEN"); AUTO.SeqProgress = 5.75; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 6, "OPEN"); AUTO.SeqProgress = 6; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 6.25, "OPEN"); AUTO.SeqProgress = 6.25; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 6.5, "OPEN"); AUTO.SeqProgress = 6.5; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 6.75, "OPEN"); AUTO.SeqProgress = 6.75; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 7, "OPEN"); AUTO.SeqProgress = 7; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 7.25, "OPEN"); AUTO.SeqProgress = 7.25; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 7.5, "OPEN"); AUTO.SeqProgress = 7.5; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 7.75, "OPEN"); AUTO.SeqProgress = 7.75; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 8, "OPEN"); AUTO.SeqProgress = 8; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 8.25, "OPEN"); AUTO.SeqProgress = 8.25; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 8.5, "OPEN"); AUTO.SeqProgress = 8.5; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 8.75, "OPEN"); AUTO.SeqProgress = 8.75; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 9, "OPEN"); AUTO.SeqProgress = 9; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 9.25, "OPEN"); AUTO.SeqProgress = 9.25; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 9.5, "OPEN"); AUTO.SeqProgress = 9.5; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 9.75, "OPEN"); AUTO.SeqProgress = 9.75; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 10, "OPEN"); AUTO.SeqProgress = 10; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 10.25, "OPEN"); AUTO.SeqProgress = 10.25; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 10.5, "OPEN"); AUTO.SeqProgress = 10.5; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 10.75, "OPEN"); AUTO.SeqProgress = 10.75; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 11, "OPEN"); AUTO.SeqProgress = 11; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 11.25, "OPEN"); AUTO.SeqProgress = 11.25; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 11.5, "OPEN"); AUTO.SeqProgress = 11.5; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 11.75, "OPEN"); AUTO.SeqProgress = 11.75; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 12, "OPEN"); AUTO.SeqProgress = 12; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 12.25, "OPEN"); AUTO.SeqProgress = 12.25; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 12.5, "OPEN"); AUTO.SeqProgress = 12.5; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 12.75, "OPEN"); AUTO.SeqProgress = 12.75; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 13, "OPEN"); AUTO.SeqProgress = 13; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 13.25, "OPEN"); AUTO.SeqProgress = 13.25; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 13.5, "OPEN"); AUTO.SeqProgress = 13.5; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 13.75, "OPEN"); AUTO.SeqProgress = 13.75; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 14, "OPEN"); AUTO.SeqProgress = 14; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 14.25, "OPEN"); AUTO.SeqProgress = 14.25; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 14.5, "OPEN"); AUTO.SeqProgress = 14.5; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 14.75, "OPEN"); AUTO.SeqProgress = 14.75; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 15, "OPEN"); AUTO.SeqProgress = 15; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 15.25, "OPEN"); AUTO.SeqProgress = 15.25; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 15.5, "OPEN"); AUTO.SeqProgress = 15.5; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 15.75, "OPEN"); AUTO.SeqProgress = 15.75; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 16, "OPEN"); AUTO.SeqProgress = 16; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 16.25, "OPEN"); AUTO.SeqProgress = 16.25; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 16.5, "OPEN"); AUTO.SeqProgress = 16.5; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 16.75, "OPEN"); AUTO.SeqProgress = 16.75; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 17, "OPEN"); AUTO.SeqProgress = 17; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 17.25, "OPEN"); AUTO.SeqProgress = 17.25; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 17.5, "OPEN"); AUTO.SeqProgress = 17.5; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 17.75, "OPEN"); AUTO.SeqProgress = 17.75; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 18, "OPEN"); AUTO.SeqProgress = 18; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 18.25, "OPEN"); AUTO.SeqProgress = 18.25; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 18.5, "OPEN"); AUTO.SeqProgress = 18.5; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 18.75, "OPEN"); AUTO.SeqProgress = 18.75; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 19, "OPEN"); AUTO.SeqProgress = 19; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 19.25, "OPEN"); AUTO.SeqProgress = 19.25; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 19.5, "OPEN"); AUTO.SeqProgress = 19.5; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 19.75, "OPEN"); AUTO.SeqProgress = 19.75; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 20, "OPEN"); AUTO.SeqProgress = 20; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 20.25, "OPEN"); AUTO.SeqProgress = 20.25; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 20.5, "OPEN"); AUTO.SeqProgress = 20.5; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 20.75, "OPEN"); AUTO.SeqProgress = 20.75; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 21, "OPEN"); AUTO.SeqProgress = 21; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 21.25, "OPEN"); AUTO.SeqProgress = 21.25; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 21.5, "OPEN"); AUTO.SeqProgress = 21.5; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 21.75, "OPEN"); AUTO.SeqProgress = 21.75; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 22, "OPEN"); AUTO.SeqProgress = 22; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 22.25, "OPEN"); AUTO.SeqProgress = 22.25; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 22.5, "OPEN"); AUTO.SeqProgress = 22.5; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 22.75, "OPEN"); AUTO.SeqProgress = 22.75; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 23, "OPEN"); AUTO.SeqProgress = 23; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 23.25, "OPEN"); AUTO.SeqProgress = 23.25; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 23.5, "OPEN"); AUTO.SeqProgress = 23.5; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 23.75, "OPEN"); AUTO.SeqProgress = 23.75; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 24, "OPEN"); AUTO.SeqProgress = 24; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 24.25, "OPEN"); AUTO.SeqProgress = 24.25; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 24.5, "OPEN"); AUTO.SeqProgress = 24.5; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 24.75, "OPEN"); AUTO.SeqProgress = 24.75; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 25, "OPEN"); AUTO.SeqProgress = 25; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 25.25, "OPEN"); AUTO.SeqProgress = 25.25; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 25.5, "OPEN"); AUTO.SeqProgress = 25.5; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 25.75, "OPEN"); AUTO.SeqProgress = 25.75; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 26, "OPEN"); AUTO.SeqProgress = 26; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 26.25, "OPEN"); AUTO.SeqProgress = 26.25; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 26.5, "OPEN"); AUTO.SeqProgress = 26.5; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 26.75, "OPEN"); AUTO.SeqProgress = 26.75; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 27, "OPEN"); AUTO.SeqProgress = 27; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 27.25, "OPEN"); AUTO.SeqProgress = 27.25; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 27.5, "OPEN"); AUTO.SeqProgress = 27.5; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 27.75, "OPEN"); AUTO.SeqProgress = 27.75; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 28, "OPEN"); AUTO.SeqProgress = 28; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 28.25, "OPEN"); AUTO.SeqProgress = 28.25; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 28.5, "OPEN"); AUTO.SeqProgress = 28.5; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 28.75, "OPEN"); AUTO.SeqProgress = 28.75; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 29, "OPEN"); AUTO.SeqProgress = 29; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 29.25, "OPEN"); AUTO.SeqProgress = 29.25; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 29.5, "OPEN"); AUTO.SeqProgress = 29.5; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 29.75, "OPEN"); AUTO.SeqProgress = 29.75; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 30, "OPEN"); AUTO.SeqProgress = 30; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 30.25, "OPEN"); AUTO.SeqProgress = 30.25; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 30.5, "OPEN"); AUTO.SeqProgress = 30.5; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 30.75, "OPEN"); AUTO.SeqProgress = 30.75; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 31, "OPEN"); AUTO.SeqProgress = 31; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 31.25, "OPEN"); AUTO.SeqProgress = 31.25; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 31.5, "OPEN"); AUTO.SeqProgress = 31.5; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 31.75, "OPEN"); AUTO.SeqProgress = 31.75; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 32, "OPEN"); AUTO.SeqProgress = 32; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 32.25, "OPEN"); AUTO.SeqProgress = 32.25; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 32.5, "OPEN"); AUTO.SeqProgress = 32.5; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 32.75, "OPEN"); AUTO.SeqProgress = 32.75; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 33, "OPEN"); AUTO.SeqProgress = 33; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 33.25, "OPEN"); AUTO.SeqProgress = 33.25; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 33.5, "OPEN"); AUTO.SeqProgress = 33.5; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 33.75, "OPEN"); AUTO.SeqProgress = 33.75; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 34, "OPEN"); AUTO.SeqProgress = 34; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 34.25, "OPEN"); AUTO.SeqProgress = 34.25; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 34.5, "OPEN"); AUTO.SeqProgress = 34.5; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 34.75, "OPEN"); AUTO.SeqProgress = 34.75; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 35, "OPEN"); AUTO.SeqProgress = 35; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 35.25, "OPEN"); AUTO.SeqProgress = 35.25; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 35.5, "OPEN"); AUTO.SeqProgress = 35.5; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 35.75, "OPEN"); AUTO.SeqProgress = 35.75; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 36, "OPEN"); AUTO.SeqProgress = 36; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 36.25, "OPEN"); AUTO.SeqProgress = 36.25; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 36.5, "OPEN"); AUTO.SeqProgress = 36.5; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 36.75, "OPEN"); AUTO.SeqProgress = 36.75; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 37, "OPEN"); AUTO.SeqProgress = 37; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 37.25, "OPEN"); AUTO.SeqProgress = 37.25; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 37.5, "OPEN"); AUTO.SeqProgress = 37.5; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 37.75, "OPEN"); AUTO.SeqProgress = 37.75; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 38, "OPEN"); AUTO.SeqProgress = 38; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 38.25, "OPEN"); AUTO.SeqProgress = 38.25; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 38.5, "OPEN"); AUTO.SeqProgress = 38.5; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 38.75, "OPEN"); AUTO.SeqProgress = 38.75; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 39, "OPEN"); AUTO.SeqProgress = 39; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 39.25, "OPEN"); AUTO.SeqProgress = 39.25; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 39.5, "OPEN"); AUTO.SeqProgress = 39.5; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 39.75, "OPEN"); AUTO.SeqProgress = 39.75; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 40, "OPEN"); AUTO.SeqProgress = 40; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 40.25, "OPEN"); AUTO.SeqProgress = 40.25; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 40.5, "OPEN"); AUTO.SeqProgress = 40.5; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 40.75, "OPEN"); AUTO.SeqProgress = 40.75; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 41, "OPEN"); AUTO.SeqProgress = 41; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 41.25, "OPEN"); AUTO.SeqProgress = 41.25; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 41.5, "OPEN"); AUTO.SeqProgress = 41.5; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 41.75, "OPEN"); AUTO.SeqProgress = 41.75; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 42, "OPEN"); AUTO.SeqProgress = 42; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 42.25, "OPEN"); AUTO.SeqProgress = 42.25; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 42.5, "OPEN"); AUTO.SeqProgress = 42.5; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 42.75, "OPEN"); AUTO.SeqProgress = 42.75; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 43, "OPEN"); AUTO.SeqProgress = 43; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 43.25, "OPEN"); AUTO.SeqProgress = 43.25; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 43.5, "OPEN"); AUTO.SeqProgress = 43.5; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 43.75, "OPEN"); AUTO.SeqProgress = 43.75; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 44, "OPEN"); AUTO.SeqProgress = 44; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 44.25, "OPEN"); AUTO.SeqProgress = 44.25; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 44.5, "OPEN"); AUTO.SeqProgress = 44.5; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 44.75, "OPEN"); AUTO.SeqProgress = 44.75; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 45, "OPEN"); AUTO.SeqProgress = 45; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 45.25, "OPEN"); AUTO.SeqProgress = 45.25; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 45.5, "OPEN"); AUTO.SeqProgress = 45.5; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 45.75, "OPEN"); AUTO.SeqProgress = 45.75; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 46, "OPEN"); AUTO.SeqProgress = 46; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 46.25, "OPEN"); AUTO.SeqProgress = 46.25; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 46.5, "OPEN"); AUTO.SeqProgress = 46.5; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 46.75, "OPEN"); AUTO.SeqProgress = 46.75; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 47, "OPEN"); AUTO.SeqProgress = 47; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 47.25, "OPEN"); AUTO.SeqProgress = 47.25; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 47.5, "OPEN"); AUTO.SeqProgress = 47.5; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 47.75, "OPEN"); AUTO.SeqProgress = 47.75; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 48, "OPEN"); AUTO.SeqProgress = 48; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 48.25, "OPEN"); AUTO.SeqProgress = 48.25; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 48.5, "OPEN"); AUTO.SeqProgress = 48.5; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 48.75, "OPEN"); AUTO.SeqProgress = 48.75; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 49, "OPEN"); AUTO.SeqProgress = 49; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 49.25, "OPEN"); AUTO.SeqProgress = 49.25; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 49.5, "OPEN"); AUTO.SeqProgress = 49.5; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 49.75, "OPEN"); AUTO.SeqProgress = 49.75; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 50, "OPEN"); AUTO.SeqProgress = 50; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 50.25, "OPEN"); AUTO.SeqProgress = 50.25; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 50.5, "OPEN"); AUTO.SeqProgress = 50.5; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 50.75, "OPEN"); AUTO.SeqProgress = 50.75; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 51, "OPEN"); AUTO.SeqProgress = 51; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 51.25, "OPEN"); AUTO.SeqProgress = 51.25; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 51.5, "OPEN"); AUTO.SeqProgress = 51.5; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 51.75, "OPEN"); AUTO.SeqProgress = 51.75; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 52, "OPEN"); AUTO.SeqProgress = 52; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 52.25, "OPEN"); AUTO.SeqProgress = 52.25; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 52.5, "OPEN"); AUTO.SeqProgress = 52.5; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 52.75, "OPEN"); AUTO.SeqProgress = 52.75; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 53, "OPEN"); AUTO.SeqProgress = 53; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 53.25, "OPEN"); AUTO.SeqProgress = 53.25; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 53.5, "OPEN"); AUTO.SeqProgress = 53.5; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 53.75, "OPEN"); AUTO.SeqProgress = 53.75; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 54, "OPEN"); AUTO.SeqProgress = 54; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 54.25, "OPEN"); AUTO.SeqProgress = 54.25; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 54.5, "OPEN"); AUTO.SeqProgress = 54.5; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 54.75, "OPEN"); AUTO.SeqProgress = 54.75; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 55, "OPEN"); AUTO.SeqProgress = 55; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 55.25, "OPEN"); AUTO.SeqProgress = 55.25; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 55.5, "OPEN"); AUTO.SeqProgress = 55.5; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 55.75, "OPEN"); AUTO.SeqProgress = 55.75; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 56, "OPEN"); AUTO.SeqProgress = 56; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 56.25, "OPEN"); AUTO.SeqProgress = 56.25; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 56.5, "OPEN"); AUTO.SeqProgress = 56.5; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 56.75, "OPEN"); AUTO.SeqProgress = 56.75; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 57, "OPEN"); AUTO.SeqProgress = 57; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 57.25, "OPEN"); AUTO.SeqProgress = 57.25; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 57.5, "OPEN"); AUTO.SeqProgress = 57.5; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 57.75, "OPEN"); AUTO.SeqProgress = 57.75; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 58, "OPEN"); AUTO.SeqProgress = 58; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 58.25, "OPEN"); AUTO.SeqProgress = 58.25; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 58.5, "OPEN"); AUTO.SeqProgress = 58.5; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 58.75, "OPEN"); AUTO.SeqProgress = 58.75; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 59, "OPEN"); AUTO.SeqProgress = 59; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 59.25, "OPEN"); AUTO.SeqProgress = 59.25; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 59.5, "OPEN"); AUTO.SeqProgress = 59.5; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 59.75, "OPEN"); AUTO.SeqProgress = 59.75; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 60, "OPEN"); AUTO.SeqProgress = 60; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 60.25, "OPEN"); AUTO.SeqProgress = 60.25; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 60.5, "OPEN"); AUTO.SeqProgress = 60.5; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 60.75, "OPEN"); AUTO.SeqProgress = 60.75; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 61, "OPEN"); AUTO.SeqProgress = 61; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 61.25, "OPEN"); AUTO.SeqProgress = 61.25; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 61.5, "OPEN"); AUTO.SeqProgress = 61.5; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 61.75, "OPEN"); AUTO.SeqProgress = 61.75; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 62, "OPEN"); AUTO.SeqProgress = 62; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 62.25, "OPEN"); AUTO.SeqProgress = 62.25; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 62.5, "OPEN"); AUTO.SeqProgress = 62.5; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 62.75, "OPEN"); AUTO.SeqProgress = 62.75; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 63, "OPEN"); AUTO.SeqProgress = 63; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 63.25, "OPEN"); AUTO.SeqProgress = 63.25; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 63.5, "OPEN"); AUTO.SeqProgress = 63.5; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 63.75, "OPEN"); AUTO.SeqProgress = 63.75; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 64, "OPEN"); AUTO.SeqProgress = 64; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 64.25, "OPEN"); AUTO.SeqProgress = 64.25; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 64.5, "OPEN"); AUTO.SeqProgress = 64.5; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 64.75, "OPEN"); AUTO.SeqProgress = 64.75; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 65, "OPEN"); AUTO.SeqProgress = 65; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 65.25, "OPEN"); AUTO.SeqProgress = 65.25; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 65.5, "OPEN"); AUTO.SeqProgress = 65.5; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 65.75, "OPEN"); AUTO.SeqProgress = 65.75; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 66, "OPEN"); AUTO.SeqProgress = 66; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 66.25, "OPEN"); AUTO.SeqProgress = 66.25; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 66.5, "OPEN"); AUTO.SeqProgress = 66.5; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 66.75, "OPEN"); AUTO.SeqProgress = 66.75; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 67, "OPEN"); AUTO.SeqProgress = 67; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 67.25, "OPEN"); AUTO.SeqProgress = 67.25; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 67.5, "OPEN"); AUTO.SeqProgress = 67.5; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 67.75, "OPEN"); AUTO.SeqProgress = 67.75; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 68, "OPEN"); AUTO.SeqProgress = 68; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 68.25, "OPEN"); AUTO.SeqProgress = 68.25; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 68.5, "OPEN"); AUTO.SeqProgress = 68.5; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 68.75, "OPEN"); AUTO.SeqProgress = 68.75; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 69, "OPEN"); AUTO.SeqProgress = 69; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 69.25, "OPEN"); AUTO.SeqProgress = 69.25; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 69.5, "OPEN"); AUTO.SeqProgress = 69.5; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 69.75, "OPEN"); AUTO.SeqProgress = 69.75; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 70, "OPEN"); AUTO.SeqProgress = 70; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 70.25, "OPEN"); AUTO.SeqProgress = 70.25; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 70.5, "OPEN"); AUTO.SeqProgress = 70.5; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 70.75, "OPEN"); AUTO.SeqProgress = 70.75; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 71, "OPEN"); AUTO.SeqProgress = 71; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 71.25, "OPEN"); AUTO.SeqProgress = 71.25; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 71.5, "OPEN"); AUTO.SeqProgress = 71.5; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 71.75, "OPEN"); AUTO.SeqProgress = 71.75; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 72, "OPEN"); AUTO.SeqProgress = 72; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 72.25, "OPEN"); AUTO.SeqProgress = 72.25; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 72.5, "OPEN"); AUTO.SeqProgress = 72.5; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 72.75, "OPEN"); AUTO.SeqProgress = 72.75; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 73, "OPEN"); AUTO.SeqProgress = 73; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 73.25, "OPEN"); AUTO.SeqProgress = 73.25; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 73.5, "OPEN"); AUTO.SeqProgress = 73.5; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 73.75, "OPEN"); AUTO.SeqProgress = 73.75; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 74, "OPEN"); AUTO.SeqProgress = 74; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 74.25, "OPEN"); AUTO.SeqProgress = 74.25; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 74.5, "OPEN"); AUTO.SeqProgress = 74.5; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 74.75, "OPEN"); AUTO.SeqProgress = 74.75; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 75, "OPEN"); AUTO.SeqProgress = 75; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 75.25, "OPEN"); AUTO.SeqProgress = 75.25; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 75.5, "OPEN"); AUTO.SeqProgress = 75.5; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 75.75, "OPEN"); AUTO.SeqProgress = 75.75; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 76, "OPEN"); AUTO.SeqProgress = 76; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 76.25, "OPEN"); AUTO.SeqProgress = 76.25; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 76.5, "OPEN"); AUTO.SeqProgress = 76.5; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 76.75, "OPEN"); AUTO.SeqProgress = 76.75; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 77, "OPEN"); AUTO.SeqProgress = 77; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 77.25, "OPEN"); AUTO.SeqProgress = 77.25; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 77.5, "OPEN"); AUTO.SeqProgress = 77.5; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 77.75, "OPEN"); AUTO.SeqProgress = 77.75; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 78, "OPEN"); AUTO.SeqProgress = 78; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 78.25, "OPEN"); AUTO.SeqProgress = 78.25; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 78.5, "OPEN"); AUTO.SeqProgress = 78.5; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 78.75, "OPEN"); AUTO.SeqProgress = 78.75; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 79, "OPEN"); AUTO.SeqProgress = 79; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 79.25, "OPEN"); AUTO.SeqProgress = 79.25; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 79.5, "OPEN"); AUTO.SeqProgress = 79.5; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 79.75, "OPEN"); AUTO.SeqProgress = 79.75; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 80, "OPEN"); AUTO.SeqProgress = 80; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 80.25, "OPEN"); AUTO.SeqProgress = 80.25; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 80.5, "OPEN"); AUTO.SeqProgress = 80.5; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 80.75, "OPEN"); AUTO.SeqProgress = 80.75; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 81, "OPEN"); AUTO.SeqProgress = 81; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 81.25, "OPEN"); AUTO.SeqProgress = 81.25; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 81.5, "OPEN"); AUTO.SeqProgress = 81.5; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 81.75, "OPEN"); AUTO.SeqProgress = 81.75; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 82, "OPEN"); AUTO.SeqProgress = 82; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 82.25, "OPEN"); AUTO.SeqProgress = 82.25; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 82.5, "OPEN"); AUTO.SeqProgress = 82.5; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 82.75, "OPEN"); AUTO.SeqProgress = 82.75; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 83, "OPEN"); AUTO.SeqProgress = 83; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 83.25, "OPEN"); AUTO.SeqProgress = 83.25; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 83.5, "OPEN"); AUTO.SeqProgress = 83.5; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 83.75, "OPEN"); AUTO.SeqProgress = 83.75; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 84, "OPEN"); AUTO.SeqProgress = 84; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 84.25, "OPEN"); AUTO.SeqProgress = 84.25; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 84.5, "OPEN"); AUTO.SeqProgress = 84.5; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 84.75, "OPEN"); AUTO.SeqProgress = 84.75; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 85, "OPEN"); AUTO.SeqProgress = 85; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 85.25, "OPEN"); AUTO.SeqProgress = 85.25; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 85.5, "OPEN"); AUTO.SeqProgress = 85.5; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 85.75, "OPEN"); AUTO.SeqProgress = 85.75; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 86, "OPEN"); AUTO.SeqProgress = 86; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 86.25, "OPEN"); AUTO.SeqProgress = 86.25; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 86.5, "OPEN"); AUTO.SeqProgress = 86.5; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 86.75, "OPEN"); AUTO.SeqProgress = 86.75; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 87, "OPEN"); AUTO.SeqProgress = 87; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 87.25, "OPEN"); AUTO.SeqProgress = 87.25; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 87.5, "OPEN"); AUTO.SeqProgress = 87.5; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 87.75, "OPEN"); AUTO.SeqProgress = 87.75; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 88, "OPEN"); AUTO.SeqProgress = 88; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 88.25, "OPEN"); AUTO.SeqProgress = 88.25; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 88.5, "OPEN"); AUTO.SeqProgress = 88.5; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 88.75, "OPEN"); AUTO.SeqProgress = 88.75; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 89, "OPEN"); AUTO.SeqProgress = 89; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 89.25, "OPEN"); AUTO.SeqProgress = 89.25; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 89.5, "OPEN"); AUTO.SeqProgress = 89.5; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 89.75, "OPEN"); AUTO.SeqProgress = 89.75; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 90, "OPEN"); AUTO.SeqProgress = 90; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 90.25, "OPEN"); AUTO.SeqProgress = 90.25; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 90.5, "OPEN"); AUTO.SeqProgress = 90.5; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 90.75, "OPEN"); AUTO.SeqProgress = 90.75; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 91, "OPEN"); AUTO.SeqProgress = 91; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 91.25, "OPEN"); AUTO.SeqProgress = 91.25; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 91.5, "OPEN"); AUTO.SeqProgress = 91.5; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 91.75, "OPEN"); AUTO.SeqProgress = 91.75; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 92, "OPEN"); AUTO.SeqProgress = 92; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 92.25, "OPEN"); AUTO.SeqProgress = 92.25; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 92.5, "OPEN"); AUTO.SeqProgress = 92.5; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 92.75, "OPEN"); AUTO.SeqProgress = 92.75; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 93, "OPEN"); AUTO.SeqProgress = 93; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 93.25, "OPEN"); AUTO.SeqProgress = 93.25; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 93.5, "OPEN"); AUTO.SeqProgress = 93.5; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 93.75, "OPEN"); AUTO.SeqProgress = 93.75; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 94, "OPEN"); AUTO.SeqProgress = 94; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 94.25, "OPEN"); AUTO.SeqProgress = 94.25; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 94.5, "OPEN"); AUTO.SeqProgress = 94.5; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 94.75, "OPEN"); AUTO.SeqProgress = 94.75; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 95, "OPEN"); AUTO.SeqProgress = 95; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 95.25, "OPEN"); AUTO.SeqProgress = 95.25; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 95.5, "OPEN"); AUTO.SeqProgress = 95.5; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 95.75, "OPEN"); AUTO.SeqProgress = 95.75; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 96, "OPEN"); AUTO.SeqProgress = 96; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 96.25, "OPEN"); AUTO.SeqProgress = 96.25; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 96.5, "OPEN"); AUTO.SeqProgress = 96.5; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 96.75, "OPEN"); AUTO.SeqProgress = 96.75; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 97, "OPEN"); AUTO.SeqProgress = 97; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 97.25, "OPEN"); AUTO.SeqProgress = 97.25; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 97.5, "OPEN"); AUTO.SeqProgress = 97.5; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 97.75, "OPEN"); AUTO.SeqProgress = 97.75; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 98, "OPEN"); AUTO.SeqProgress = 98; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 98.25, "OPEN"); AUTO.SeqProgress = 98.25; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 98.5, "OPEN"); AUTO.SeqProgress = 98.5; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 98.75, "OPEN"); AUTO.SeqProgress = 98.75; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 99, "OPEN"); AUTO.SeqProgress = 99; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 99.25, "OPEN"); AUTO.SeqProgress = 99.25; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 99.5, "OPEN"); AUTO.SeqProgress = 99.5; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 99.75, "OPEN"); AUTO.SeqProgress = 99.75; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)
		firesignal(ProgressEv.OnClientEvent, 100, "OPEN"); AUTO.SeqProgress = 100; AUTO.SeqCount = AUTO.SeqCount + 1; task.wait(CONFIG.SeqTickDelay)

		firesignal(ProgressEv.OnClientEvent, 100, "OPEN", false)
		AUTO.Status = "GATE OPENED"
		TriggerEndgame()

		SeqRunning = false
	end)
end

local function StopLeverSequence()
	SeqToken = SeqToken + 1
	SeqRunning = false
	AUTO.SpoofActive = false
	pcall(function() firesignal(LeverAnimEv.OnClientEvent, false) end)
end

-- =========================================================
-- FORCE LEVER WORKER (dipakai Force Lever + Auto Gen escape)
-- =========================================================
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

	PlayLeverSequence(entry.main)

	local startT = os.clock()
	local lastKillerCheck = os.clock()

	while os.clock() - startT < CONFIG.LeverWorkTimeout do
		if AUTO.ProgressComplete or AUTO.Done then
			FireLever(false, entry.main)
			StopLeverSequence()
			return "signal"
		end
		if not AUTO.LevRunning or AUTO.LevToken ~= token then
			FireLever(false, entry.main)
			StopLeverSequence()
			return "stop"
		end

		if os.clock() - lastKillerCheck > 0.15 then
			if NearestEnemy() < CONFIG.EnemyThreshold then
				FireLever(false, entry.main)
				StopLeverSequence()
				AUTO.LastEvadeReason = "killer di lever " .. idx .. " — CABUT"
				return "evade"
			end
			lastKillerCheck = os.clock()
		end

		FireLever(true, entry.main)
		task.wait(CONFIG.LeverSpamDelay)
	end

	FireLever(false, entry.main)
	StopLeverSequence()
	return "timeout"
end

-- =========================================================
-- START GEN — escapetime otomatis switch ke lever (mekanisme sama)
-- =========================================================
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
	ResetEndgame()

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

-- =========================================================
-- START LEVER THREAD — dipakai Force Lever + Auto Gen
-- =========================================================
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
	AUTO.SpoofActive = true

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
					AUTO.Status = reason .. " | RETRY"
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
	AUTO.SpoofActive = false
	StopLeverSequence()
end

local function StopAll()
	StopGen()
	StopLeverThread()
	AUTO.Status = "STOPPED"
	AUTO.Phase = "IDLE"
end

-- =========================================================
-- HEARTBEAT — noclip logic (Map exist + spectate belum trigger)
-- =========================================================
TrackConnection(RunService.Heartbeat:Connect(function(dt)
	if STATE.Destroyed then return end
	AUTO.HasTeammate = HasActiveTeammate()
	local mapLoaded = workspace:FindFirstChild("Map") ~= nil
	-- Noclip ON kalau Map exist DAN spectate belum pernah trigger di ronde ini
	SetNoclip(mapLoaded and not AUTO.SpectatorTriggered)
end))

local AutoCard = MakeCard(HomeScroll, "AUTO OPERATIONS", UDim2.new(1,-4,0,290), nil)
AutoCard.LayoutOrder = 1

local StatusLbl = MakeLabel(AutoCard, "Status: IDLE", UDim2.new(1,-24,0,20), UDim2.new(0,12,0,36), FONT_BOLD, 15, COLORS.Text)
local PhaseLbl  = MakeLabel(AutoCard, "Phase: IDLE", UDim2.new(1,-24,0,18), UDim2.new(0,12,0,58), FONT_TEXT, 13, COLORS.SubText)
local GenLbl    = MakeLabel(AutoCard, "Generators: 0 / 0", UDim2.new(1,-24,0,18), UDim2.new(0,12,0,78), FONT_TEXT, 13, COLORS.Text)
local LevLbl    = MakeLabel(AutoCard, "Levers: 0 / 0", UDim2.new(1,-24,0,18), UDim2.new(0,12,0,98), FONT_TEXT, 13, COLORS.Text)
local EnemyLbl  = MakeLabel(AutoCard, "Enemies: 0 (thr 35)", UDim2.new(1,-24,0,18), UDim2.new(0,12,0,118), FONT_TEXT, 13, COLORS.Text)
local SignalLbl = MakeLabel(AutoCard, "Spoof: N | GateParts: 0 | Endgame: N | Spec: N", UDim2.new(1,-24,0,18), UDim2.new(0,12,0,138), FONT_TEXT, 11, COLORS.SubText)
local SeqLbl    = MakeLabel(AutoCard, "Seq: 0 | Prog: 0", UDim2.new(1,-24,0,18), UDim2.new(0,12,0,158), FONT_TEXT, 11, COLORS.SubText)
local EvadeLbl  = MakeLabel(AutoCard, "Evade: -", UDim2.new(1,-24,0,18), UDim2.new(0,12,0,178), FONT_TEXT, 11, COLORS.Warn)

local StartGenBtn = MakeButton(AutoCard, "START AUTO GEN", UDim2.new(1,-24,0,38), UDim2.new(0,12,0,206), function()
	if AUTO.GenRunning then
		StopGen()
		StartGenBtn.Text = "START AUTO GEN"
	else
		StartGen()
		StartGenBtn.Text = "STOP AUTO GEN"
	end
end)
MakeCorner(StartGenBtn, 10)

local ForceLeverBtn
ForceLeverBtn = MakeButton(AutoCard, "FORCE LEVER : OFF", UDim2.new(1,-24,0,38), UDim2.new(0,12,0,252), function()
	if AUTO.LevForce then
		StopLeverThread()
		ForceLeverBtn.Text = "FORCE LEVER : OFF"
		ForceLeverBtn.TextColor3 = COLORS.Text
	else
		AUTO.ProgressComplete = false
		AUTO.Done = false
		ResetEndgame()
		pcall(BuildGateParts)
		StartLeverThread("FORCE LEVER")
		ForceLeverBtn.Text = "FORCE LEVER : ON"
		ForceLeverBtn.TextColor3 = COLORS.Bad
	end
end)
MakeCorner(ForceLeverBtn, 10)

local RescanBtn = MakeButton(AutoCard, "Rescan", UDim2.new(0.5,-8,0,34), UDim2.new(0,12,0,298), function()
	if workspace:FindFirstChild("Map") then
		BuildGenList(); BuildLeverList(); BuildGateParts()
	end
end)
MakeCorner(RescanBtn, 10)

local StopAllBtn = MakeButton(AutoCard, "STOP ALL", UDim2.new(0.5,-8,0,34), UDim2.new(0.5,4,0,298), function()
	StopAll()
	StartGenBtn.Text = "START AUTO GEN"
	ForceLeverBtn.Text = "FORCE LEVER : OFF"
	ForceLeverBtn.TextColor3 = COLORS.Text
end)
MakeCorner(StopAllBtn, 10)
StopAllBtn.TextColor3 = COLORS.Bad

-- =========================================================
-- BYPASS UNHOOK CARD
-- =========================================================
local BypassCard = MakeCard(HomeScroll, "BYPASS UNHOOK", UDim2.new(1,-4,0,150), nil)
BypassCard.LayoutOrder = 2

local BypassStatusLbl = MakeLabel(BypassCard,
	"Status: OFF | saved: none",
	UDim2.new(1,-24,0,18), UDim2.new(0,12,0,36), FONT_TEXT, 12, COLORS.SubText)
local BypassTickLbl = MakeLabel(BypassCard,
	"Ticks: 0 | Enemy: -",
	UDim2.new(1,-24,0,18), UDim2.new(0,12,0,56), FONT_TEXT, 11, COLORS.SubText)

local BypassBtn
BypassBtn = MakeButton(BypassCard, "BYPASS UNHOOK : OFF", UDim2.new(1,-24,0,44), UDim2.new(0,12,0,80), function()
	if BYPASS.Active then
		BypassRestorePos()
		BYPASS.Active = false
		BYPASS.Status = "OFF (restored)"
		BypassBtn.Text = "BYPASS UNHOOK : OFF"
		BypassBtn.TextColor3 = COLORS.Text
	else
		local ok = BypassSavePos()
		if ok then
			BYPASS.Active = true
			BYPASS.TickCount = 0
			BYPASS.Status = "ON"
			BypassBtn.Text = "BYPASS UNHOOK : ON"
			BypassBtn.TextColor3 = COLORS.Bad
		else
			BYPASS.Status = "FAILED — no char"
		end
	end
end)
MakeCorner(BypassBtn, 10)

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

	local autoSet = NewSetCard("AUTOMATION", 300)
	autoSet.LayoutOrder = 3
	MakeStepperRow(autoSet, "Enemy Threshold", 36, 10, 100, 5,
		function() return CONFIG.EnemyThreshold end,
		function(v) CONFIG.EnemyThreshold = v end,
		function(v) return tostring(v) .. " stud" end)
	MakeStepperRow(autoSet, "Lever Spam Delay", 88, 0.01, 0.2, 0.01,
		function() return CONFIG.LeverSpamDelay end,
		function(v) CONFIG.LeverSpamDelay = v end,
		function(v) return string.format("%.2fs", v) end)
	MakeStepperRow(autoSet, "Sequence Tick", 140, 0.001, 0.1, 0.001,
		function() return CONFIG.SeqTickDelay end,
		function(v) CONFIG.SeqTickDelay = v end,
		function(v) return string.format("%.3fs", v) end)
	MakeStepperRow(autoSet, "Teleport Gap", 192, 0.1, 1.0, 0.05,
		function() return CONFIG.MinTeleportGap end,
		function(v) CONFIG.MinTeleportGap = v end,
		function(v) return string.format("%.2fs", v) end)
	MakeStepperRow(autoSet, "Lever Timeout", 244, 15, 90, 5,
		function() return CONFIG.LeverWorkTimeout end,
		function(v) CONFIG.LeverWorkTimeout = v end,
		function(v) return tostring(v) .. "s" end)
end

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
			pcall(BuildGateParts)
		else
			GenList = {}
			LeverList = {}
			GateParts = {}
			AUTO.GenTotal = 0
			AUTO.LevTotal = 0
			AUTO.GatePartsFound = 0
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
		GenLbl.Text = "Generators: " .. doneCount .. " / " .. AUTO.GenTotal ..
			(AUTO.GenCurrent > 0 and " • #" .. AUTO.GenCurrent or "")
		LevLbl.Text = "Levers: " .. AUTO.LevCurrent .. " / " .. AUTO.LevTotal
		EnemyLbl.Text = "Enemies: " .. AUTO.EnemiesNear .. " (thr " .. CONFIG.EnemyThreshold .. ")"
		SignalLbl.Text = "Spoof: " .. (AUTO.SpoofActive and "ON" or "OFF") ..
			" | GateParts: " .. AUTO.GatePartsFound ..
			" | Endgame: " .. (AUTO.EndgameActive and "ON" or "OFF") ..
			" | Spec: " .. (AUTO.SpectatorTriggered and "YES" or "NO")
		SeqLbl.Text = "Seq: " .. AUTO.SeqCount .. " | Prog: " .. string.format("%.2f", AUTO.SeqProgress)
		EvadeLbl.Text = "Evade: " .. (AUTO.LastEvadeReason ~= "" and AUTO.LastEvadeReason or "-")

		if BypassStatusLbl then
			BypassStatusLbl.Text = "Status: " .. BYPASS.Status .. " | saved: " ..
				(BYPASS.SavedCFrame and "yes" or "none")
			BypassTickLbl.Text = "Ticks: " .. BYPASS.TickCount .. " | Enemy: " .. (BYPASS.LastEnemyName or "-")
		end

		SubtitleLabel.Text = (BYPASS.Active and "BYPASS • " .. AUTO.Phase)
			or (AUTO.EndgameActive and "ENDGAME • " .. AUTO.Phase)
			or (AUTO.SpoofActive and "SPOOF • " .. AUTO.Phase)
			or (AUTO.GenRunning and "GEN • " .. AUTO.Phase)
			or AUTO.Status
	end
end))

_G.vanz = _G.vanz or {}
_G.vanz.StartGen = StartGen
_G.vanz.StopGen = StopGen
_G.vanz.StartLever = function()
	pcall(BuildGateParts)
	StartLeverThread("FORCE LEVER")
end
_G.vanz.StopLever = StopLeverThread
_G.vanz.StopAll = StopAll
_G.vanz.TriggerEndgame = TriggerEndgame
_G.vanz.ResetEndgame = ResetEndgame
_G.vanz.GetState = function() return AUTO end
_G.vanz.GetGenList = function() return GenList end
_G.vanz.GetLeverList = function() return LeverList end
_G.vanz.GetGateParts = function() return GateParts end
_G.vanz.ScreenGui = ScreenGui
_G.vanz.GetBypass = function() return BYPASS end
_G.vanz.BypassOn = function()
	local ok = BypassSavePos()
	if ok then BYPASS.Active = true; BYPASS.TickCount = 0; BYPASS.Status = "ON" end
	return ok
end
_G.vanz.BypassOff = function()
	BypassRestorePos()
	BYPASS.Active = false
	BYPASS.Status = "OFF (restored)"
end

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
		AUTO.SpoofActive = false
		AUTO.EndgameActive = false
		BYPASS.Active = false
		CleanupAll()
		pcall(function() ScreenGui:Destroy() end)
	end
end))