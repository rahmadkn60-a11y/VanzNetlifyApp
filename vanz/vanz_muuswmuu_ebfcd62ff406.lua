--==================================================
-- VANZ ULTRA CONTROL CENTER — MERGED v8-MAX (FIXED)
--==================================================
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
local RS = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

--==================================================
-- [00] FORWARD DECLARATIONS
-- Deklarasi upvalue yang dipakai lintas section (fix lexical scope).
--==================================================
local MiniBody, MiniCore, MiniRing, MiniScan
local FireBtn, HUDInfo
local ApplyWindowLayout

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

	-- === COMBAT SUITE ===
	SilentAim      = false,
	VisualLine     = false,
	LeadPredict    = false,
	AntiKnock      = false,
	AntiDeath      = false,
	AutoHeal       = false,
	ShowFireButton = true,
	ShowHUDInfo    = true,
}

local THEMES = {
	["Cyber Blue"]   = {Accent = Color3.fromRGB(0,170,255), Accent2 = Color3.fromRGB(0,255,230), Base = Color3.fromRGB(14,22,42), Base2 = Color3.fromRGB(22,36,66)},
	["Neon Cyan"]    = {Accent = Color3.fromRGB(0,255,255), Accent2 = Color3.fromRGB(80,255,200), Base = Color3.fromRGB(12,26,36), Base2 = Color3.fromRGB(20,42,56)},
	["Purple Anime"] = {Accent = Color3.fromRGB(190,110,255), Accent2 = Color3.fromRGB(255,120,220), Base = Color3.fromRGB(28,18,46), Base2 = Color3.fromRGB(44,28,70)},
	["Crimson"]      = {Accent = Color3.fromRGB(255,70,90), Accent2 = Color3.fromRGB(255,160,80), Base = Color3.fromRGB(34,16,22), Base2 = Color3.fromRGB(52,24,34)},
	["Emerald"]      = {Accent = Color3.fromRGB(70,255,150), Accent2 = Color3.fromRGB(160,255,90), Base = Color3.fromRGB(14,32,26), Base2 = Color3.fromRGB(22,50,40)},
	["Ice"]          = {Accent = Color3.fromRGB(170,230,255), Accent2 = Color3.fromRGB(230,250,255), Base = Color3.fromRGB(26,40,56), Base2 = Color3.fromRGB(38,58,80)},
}

local DEFAULT_CONFIG_SNAPSHOT = {}
for k, v in pairs(CONFIG) do DEFAULT_CONFIG_SNAPSHOT[k] = v end

--==================================================
-- [03] STATE
--==================================================
local STATE = {
	Built = false, Open = false, Minimized = false, Destroyed = false, SettingsOpen = false,
	MainPosition = nil, MiniPosition = nil,
	SessionStart = os.clock(),
	AccountAgeText = "N/A", DeviceText = "N/A", ThumbnailReady = false,
	MarketplaceName = "N/A",
	LastFPS = 0, FrameCount = 0, FrameTimer = 0, FastTimer = 0, SlowTimer = 0,
	LastFrameDt = 0,
	-- Combat
	Target = nil,
	SmoothFPS = 60, FrameTimeAcc = 0, CombatFrameCount = 0, LastFPSSample = 0,
	VelTracker = {}, BulletSpeedBySkin = {},
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
-- [04B] COMBAT SUITE — CONFIG
--==================================================
local TeamCfg = {
	enemyKeywords = { "kill", "murder", "slasher", "hunter", "monster", "enemy" },
	allyKeywords  = { "survivor", "innocent", "runner", "civilian", "player", "ally" },
	enemyR = 0.55, allyB = 0.55,
}

local AimCfg = {
	originMode      = "gun",
	targetMode      = "uppertorso",
	leadPrediction  = true,
	bulletSpeed     = 200,
	bulletSpeedAuto = true,
	leadIterations  = 9999,
	flipY           = false,
	flipZ           = false,
	maxScanDistance = 999,
	lateralOffset   = 0.5,
	lateralAxis     = "RightVector",
}

local FireTofImpl
local DrawLine, DrawDot, DrawRawDot

--==================================================
-- [04C] TARGET SCAN
--==================================================
local function ClassifyPlayer(plr)
	if not plr or plr == LocalPlayer then return "self" end
	local team = plr.Team
	if not team then return "unknown" end
	local name = string.lower(team.Name or "")
	for _, kw in ipairs(TeamCfg.enemyKeywords) do
		if string.find(name, kw, 1, true) then return "enemy" end
	end
	for _, kw in ipairs(TeamCfg.allyKeywords) do
		if string.find(name, kw, 1, true) then return "ally" end
	end
	local c = team.TeamColor and team.TeamColor.Color
	if c then
		if c.R >= TeamCfg.enemyR and c.G < 0.45 and c.B < 0.45 then return "enemy" end
		if c.B >= TeamCfg.allyB then return "ally" end
	end
	return "unknown"
end

local function GetRootOf(plr)
	local char = plr and plr.Character
	if not char then return nil end
	return char:FindFirstChild("UpperTorso")
		or char:FindFirstChild("HumanoidRootPart")
		or char:FindFirstChild("Torso")
end

local function ScanTarget()
	if not (CONFIG.SilentAim or CONFIG.VisualLine) then
		STATE.Target = nil
		return
	end
	local myRoot = GetRootOf(LocalPlayer)
	if not myRoot then STATE.Target = nil return end
	local bestDist, best = math.huge, nil
	local myPos = myRoot.Position
	for _, plr in ipairs(Players:GetPlayers()) do
		if ClassifyPlayer(plr) == "enemy" then
			local root = GetRootOf(plr)
			if root then
				local d = (root.Position - myPos).Magnitude
				if d < bestDist then bestDist, best = d, plr end
			end
		end
	end
	STATE.Target = best
end

--==================================================
-- [04D] VELOCITY TRACKER
--==================================================
local SAMPLE_WINDOW, MAX_SAMPLES, SMOOTH_ALPHA = 0.05, 30, 0.68

local function SampleVelocity(plr, maxDist, myPos)
	local root = GetRootOf(plr)
	if not root then return end
	if maxDist and myPos then
		local d = (root.Position - myPos).Magnitude
		if d > maxDist then STATE.VelTracker[plr] = nil return end
	end
	local now = tick()
	local pos = root.Position
	local tracker = STATE.VelTracker[plr]
	if not tracker then
		tracker = {samples = {}, smoothVel = Vector3.zero, lastSpeed = 0, lastPos = pos, unchangedCount = 0}
		STATE.VelTracker[plr] = tracker
	end
	if (pos - tracker.lastPos).Magnitude < 0.05 then
		tracker.unchangedCount = tracker.unchangedCount + 1
		if tracker.unchangedCount > 3 then
			tracker.smoothVel = Vector3.zero
			tracker.lastSpeed = 0
			return
		end
	else
		tracker.unchangedCount = 0
	end
	tracker.lastPos = pos
	table.insert(tracker.samples, {t = now, pos = pos})
	while #tracker.samples > MAX_SAMPLES do table.remove(tracker.samples, 1) end
	while #tracker.samples > 2 and (now - tracker.samples[1].t) > SAMPLE_WINDOW do
		table.remove(tracker.samples, 1)
	end
	if #tracker.samples >= 2 then
		local oldest = tracker.samples[1]
		local newest = tracker.samples[#tracker.samples]
		local dt = newest.t - oldest.t
		if dt > 0.003 then
			local instVel = (newest.pos - oldest.pos) / dt
			tracker.smoothVel = tracker.smoothVel:Lerp(instVel, SMOOTH_ALPHA)
			tracker.lastSpeed = tracker.smoothVel.Magnitude
		end
	end
end

local function SampleNow(plr)
	if not plr then return end
	local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
	local myPos = myRoot and myRoot.Position
	SampleVelocity(plr, nil, myPos)
end

local function GetPlayerVelocity(plr)
	if not plr then return Vector3.zero end
	local tr = STATE.VelTracker[plr]
	return tr and tr.smoothVel or Vector3.zero
end

local function GetPlayerSpeed(plr)
	return GetPlayerVelocity(plr).Magnitude
end

--==================================================
-- [04E] BULLET CALIBRATION
--==================================================
do
	local ok, vb = pcall(function()
		return RS.Remotes.Items["Twist of Fate"].VisualizeBullet
	end)
	if ok and vb then
		TrackConnection(vb.OnClientEvent:Connect(function(_, _, speed, skin)
			if typeof(speed) == "number" and speed > 0 then
				local key = tostring(skin or "default")
				STATE.BulletSpeedBySkin[key] = speed
				if AimCfg.bulletSpeedAuto ~= false then AimCfg.bulletSpeed = speed end
			end
		end))
	end
end

--==================================================
-- [04F] FIRETOF
--==================================================
do
	local function GetGunPart()
		local char = LocalPlayer.Character
		if not char then return nil end
		local tof = char:FindFirstChild("Twist of Fate")
		if not tof then return nil end
		local rightArm = tof:FindFirstChild("Right Arm")
		if not rightArm then return nil end
		return rightArm:FindFirstChild("gun") or rightArm:FindFirstChildWhichIsA("BasePart", true)
	end

	local function GetAimOrigin()
		local char = LocalPlayer.Character
		if not char then return nil end
		local mode = AimCfg.originMode
		if mode == "gun" then
			local gun = GetGunPart()
			if gun and gun:IsA("BasePart") then return gun.Position end
		end
		if mode == "head" then
			local head = char:FindFirstChild("Head")
			if head and head:IsA("BasePart") then return head.Position end
		end
		local hrp = char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso")
		return hrp and hrp.Position or nil
	end

	local function GetTargetPart()
		local tgt = STATE.Target
		if not tgt then return nil end
		local char = tgt.Character
		if not char then return nil end
		local mode = AimCfg.targetMode or "uppertorso"
		local p
		if mode == "head" then p = char:FindFirstChild("Head")
		elseif mode == "torso" then p = char:FindFirstChild("Torso")
		elseif mode == "hrp" then p = char:FindFirstChild("HumanoidRootPart")
		else
			p = char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso") or char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Head")
		end
		return (p and p:IsA("BasePart")) and p or nil
	end

	local function GetBulletSpeed()
		local s = AimCfg.bulletSpeed
		if typeof(s) == "number" and s > 0 then return s end
		return 200
	end

	local function GetTargetVelocityFresh(plr, part)
		if SampleNow and plr then SampleNow(plr) end
		local directVel = Vector3.zero
		if part then
			local ok1, av = pcall(function() return part.AssemblyLinearVelocity end)
			if ok1 and av then directVel = av end
			if directVel.Magnitude < 0.05 then
				local ok2, v2 = pcall(function() return part.Velocity end)
				if ok2 and v2 then directVel = v2 end
			end
		end
		local trackerVel = GetPlayerVelocity(plr) or Vector3.zero
		local dm, tm = directVel.Magnitude, trackerVel.Magnitude
		if dm > tm * 1.5 then return directVel end
		if tm > dm * 1.5 then return trackerVel end
		return (directVel + trackerVel) * 0.5
	end

	local function PredictTargetPos(origin, rawTarget, velocity)
		if not AimCfg.leadPrediction then return rawTarget, 0, GetBulletSpeed() end
		local speed = GetBulletSpeed()
		local iterations = AimCfg.leadIterations or 9999
		local predicted = rawTarget
		local flightTime = 0
		for _ = 1, iterations do
			local dist = (predicted - origin).Magnitude
			flightTime = dist / speed
			predicted = rawTarget + velocity * flightTime
		end
		return predicted, flightTime, speed
	end

	local function GetTargetDir()
		local origin = GetAimOrigin()
		local part = GetTargetPart()
		local tgtPlr = STATE.Target
		if not (origin and part and part.Parent) then return nil end
		local rawTarget = part.Position
		local off = AimCfg.lateralOffset or 0
		local axis = AimCfg.lateralAxis or "RightVector"
		if off ~= 0 then
			local ok, axisVec = pcall(function() return part.CFrame[axis] end)
			if ok and axisVec then rawTarget = rawTarget + axisVec * off end
		end
		local velocity = GetTargetVelocityFresh(tgtPlr, part)
		local predicted = PredictTargetPos(origin, rawTarget, velocity)
		local diff = predicted - origin
		if diff.Magnitude < 0.01 then return nil end
		local dir = diff.Unit
		if AimCfg.flipY or AimCfg.flipZ then
			dir = Vector3.new(dir.X, AimCfg.flipY and -dir.Y or dir.Y, AimCfg.flipZ and -dir.Z or dir.Z)
		end
		return dir
	end

	local function GetFireRemote()
		local remotes = RS:FindFirstChild("Remotes")
		if not remotes then return nil end
		local items = remotes:FindFirstChild("Items")
		if not items then return nil end
		local tof = items:FindFirstChild("Twist of Fate")
		if not tof then return nil end
		return tof:FindFirstChild("Fire")
	end

	FireTofImpl = function()
		local gun = GetGunPart()
		local fire = GetFireRemote()
		local dir = GetTargetDir()
		if not gun or not fire or not dir then return end
		pcall(function() fire:FireServer(gun, dir) end)
	end
end

--==================================================
-- [04G] ANTI-KNOCK / ANTI-DEATH / AUTO-HEAL LOOP
--==================================================
do
	local EnableCollision, HealEvent
	pcall(function() EnableCollision = RS.Remotes.Collision.EnableCollision end)
	pcall(function() HealEvent = RS.Remotes.Healing.HealEvent end)

	local lastKnockFire, lastHealth, lastHeal = 0, nil, 0

	TrackConnection(RunService.Heartbeat:Connect(function()
		local char = LocalPlayer.Character
		if not char then return end
		local hum = char:FindFirstChildOfClass("Humanoid")
		if not hum then return end
		local hrp = char:FindFirstChild("HumanoidRootPart")
		local now = tick()

		if CONFIG.AntiKnock then
			local isKnocked = false
			if lastHealth and (lastHealth - hum.Health) >= 15 then isKnocked = true end
			lastHealth = hum.Health
			if (isKnocked or (now - lastKnockFire >= 2)) and EnableCollision then
				lastKnockFire = now
				pcall(function() EnableCollision:FireServer() end)
			end
		else
			lastHealth = hum.Health
		end

		if CONFIG.AntiDeath and hum.Health > 0 and hum.Health <= 30 and hrp and HealEvent then
			if now - lastHeal >= 0.35 then
				lastHeal = now
				pcall(function() HealEvent:FireServer(hrp, true) end)
			end
		end

		if CONFIG.AutoHeal and hum.Health > 0 and hum.Health < hum.MaxHealth * 0.6 and hrp and HealEvent then
			if now - lastHeal >= 0.6 then
				lastHeal = now
				pcall(function() HealEvent:FireServer(hrp, true) end)
			end
		end
	end))
end

--==================================================
-- [04H] VISUAL LINE DRAWING
--==================================================
do
	local hasDrawing = (type(Drawing) == "table" and type(Drawing.new) == "function")
	if hasDrawing then
		DrawLine = Drawing.new("Line")
		DrawLine.Visible = false
		DrawLine.Color = Color3.fromRGB(255, 55, 55)
		DrawLine.Thickness = 2
		DrawLine.Transparency = 1

		DrawDot = Drawing.new("Circle")
		DrawDot.Visible = false
		DrawDot.Color = Color3.fromRGB(255, 55, 55)
		DrawDot.Thickness = 2
		DrawDot.Radius = 6
		DrawDot.Filled = false
		DrawDot.Transparency = 1

		DrawRawDot = Drawing.new("Circle")
		DrawRawDot.Visible = false
		DrawRawDot.Color = Color3.fromRGB(255, 200, 0)
		DrawRawDot.Thickness = 1
		DrawRawDot.Radius = 4
		DrawRawDot.Filled = false
		DrawRawDot.Transparency = 0.6

		local function Project(worldPos, cam)
			local vp = cam.ViewportSize
			local cx, cy = vp.X * 0.5, vp.Y * 0.5
			local sp = cam:WorldToViewportPoint(worldPos)
			if sp.Z > 0 then return Vector2.new(sp.X, sp.Y) end
			local dx, dy = cx - sp.X, cy - sp.Y
			local len = math.sqrt(dx*dx + dy*dy)
			if len < 1 then return Vector2.new(cx, cy + 2000) end
			local scale = 3000 / len
			return Vector2.new(cx + dx*scale, cy + dy*scale)
		end

		local function GetGunPos()
			local char = LocalPlayer.Character
			if not char then return nil end
			local tof = char:FindFirstChild("Twist of Fate")
			if tof then
				local rightArm = tof:FindFirstChild("Right Arm")
				if rightArm then
					local muzzle = rightArm:FindFirstChild("gun") or rightArm:FindFirstChildWhichIsA("BasePart", true)
					if muzzle and muzzle:IsA("BasePart") then return muzzle.Position end
				end
			end
			local hrp = char:FindFirstChild("HumanoidRootPart")
			return hrp and (hrp.Position + Vector3.new(0, 1, 0)) or nil
		end

		local function GetTargetData()
			local tgt = STATE.Target
			if not tgt then return nil, nil end
			local char = tgt.Character
			if not char then return nil, nil end
			local part = char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso") or char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Head")
			if not (part and part:IsA("BasePart") and part.Parent) then return nil, nil end

			local rawPos = part.Position
			local off = AimCfg.lateralOffset or 0
			local axis = AimCfg.lateralAxis or "RightVector"
			if off ~= 0 then
				local ok, axisVec = pcall(function() return part.CFrame[axis] end)
				if ok and axisVec then rawPos = rawPos + axisVec * off end
			end

			local origin = GetGunPos()
			if not origin then return rawPos, rawPos end
			local speed = AimCfg.bulletSpeed
			if typeof(speed) ~= "number" or speed <= 0 then speed = 200 end
			local vel = GetPlayerVelocity(tgt) or Vector3.zero
			if not AimCfg.leadPrediction then return rawPos, rawPos end
			local iter = AimCfg.leadIterations or 9999
			local predicted = rawPos
			for _ = 1, iter do
				local dist = (predicted - origin).Magnitude
				local t = dist / speed
				predicted = rawPos + vel * t
			end
			return rawPos, predicted
		end

		TrackConnection(RunService.RenderStepped:Connect(function()
			if not CONFIG.VisualLine then
				DrawLine.Visible = false; DrawDot.Visible = false; DrawRawDot.Visible = false
				return
			end
			local gunPos = GetGunPos()
			local rawPos, predPos = GetTargetData()
			local cam = workspace.CurrentCamera
			if not (gunPos and predPos and cam) then
				DrawLine.Visible = false; DrawDot.Visible = false; DrawRawDot.Visible = false
				return
			end
			DrawLine.From = Project(gunPos, cam)
			DrawLine.To = Project(predPos, cam)
			DrawLine.Visible = true
			DrawDot.Position = Project(predPos, cam)
			DrawDot.Visible = true
			if rawPos then
				DrawRawDot.Position = Project(rawPos, cam)
				DrawRawDot.Visible = AimCfg.leadPrediction
			end
		end))

		AddCleanup(function()
			if DrawLine then DrawLine:Remove() end
			if DrawDot then DrawDot:Remove() end
			if DrawRawDot then DrawRawDot:Remove() end
		end)
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
	CardHover = Color3.fromRGB(28,46,80), Track = Color3.fromRGB(30,46,74),
}

local FONT_TITLE = Enum.Font.GothamBlack
local FONT_BOLD  = Enum.Font.GothamBold
local FONT_TEXT  = Enum.Font.Gotham

--==================================================
-- [06] UI FACTORY
--==================================================
local function Create(className, props, children)
	local obj = Instance.new(className)
	for k, v in pairs(props or {}) do obj[k] = v end
	for _, child in ipairs(children or {}) do child.Parent = obj end
	return obj
end

local function MakeCorner(parent, radius)
	return Create("UICorner", {CornerRadius = UDim.new(0, radius or 10), Parent = parent})
end

local function MakeStroke(parent, color, thickness, transparency)
	return Create("UIStroke", {
		Color = color or GetTheme().Accent, Thickness = thickness or 1,
		Transparency = transparency or 0.4, ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Parent = parent,
	})
end

local function MakeGradient(parent, c1, c2, rotation)
	return Create("UIGradient", {
		Color = ColorSequence.new({ColorSequenceKeypoint.new(0, c1), ColorSequenceKeypoint.new(1, c2)}),
		Rotation = rotation or 90, Parent = parent,
	})
end

local function MakeFrame(parent, size, pos, color, transparency)
	return Create("Frame", {
		Size = size or UDim2.new(1,0,1,0), Position = pos or UDim2.new(0,0,0,0),
		BackgroundColor3 = color or COLORS.Card, BackgroundTransparency = transparency or 0,
		BorderSizePixel = 0, Parent = parent,
	})
end

local function MakeLabel(parent, text, size, pos, font, textSize, color, xAlign)
	return Create("TextLabel", {
		Text = text or "", Size = size or UDim2.new(1,0,0,20), Position = pos or UDim2.new(0,0,0,0),
		BackgroundTransparency = 1, Font = font or FONT_TEXT, TextSize = textSize or 14,
		TextColor3 = color or COLORS.Text, TextXAlignment = xAlign or Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Center, Parent = parent,
	})
end

local function MakeButton(parent, text, size, pos, onClick)
	local btn = Create("TextButton", {
		Text = text or "", Size = size or UDim2.new(0,48,0,48), Position = pos or UDim2.new(0,0,0,0),
		BackgroundColor3 = GetTheme().Base2, BackgroundTransparency = 0.1, BorderSizePixel = 0,
		AutoButtonColor = false, Font = FONT_BOLD, TextSize = 18, TextColor3 = COLORS.Text, Parent = parent,
	})
	MakeCorner(btn, 10)
	MakeStroke(btn, GetTheme().Accent, 1, 0.5)
	local baseColor, hoverColor = GetTheme().Base2, GetTheme().Accent
	TrackConnection(btn.MouseEnter:Connect(function()
		if not CONFIG.HoverAnimation or CONFIG.LowFXMode then return end
		TrackTween(TweenService:Create(btn, TweenInfo.new(0.18, Enum.EasingStyle.Quad), {BackgroundColor3 = hoverColor:Lerp(baseColor, 0.6)})):Play()
	end))
	TrackConnection(btn.MouseLeave:Connect(function()
		if not CONFIG.HoverAnimation or CONFIG.LowFXMode then return end
		TrackTween(TweenService:Create(btn, TweenInfo.new(0.18, Enum.EasingStyle.Quad), {BackgroundColor3 = baseColor})):Play()
	end))
	TrackConnection(btn.MouseButton1Click:Connect(function()
		if CONFIG.ClickAnimation and not CONFIG.LowFXMode then
			TrackTween(TweenService:Create(btn, TweenInfo.new(0.08), {BackgroundTransparency = 0})):Play()
			task.delay(0.08, function() if btn and btn.Parent then btn.BackgroundTransparency = 0.1 end end)
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
	MakeLabel(card, title or "", UDim2.new(1,-20,0,22), UDim2.new(0,12,0,8), FONT_BOLD, 16, GetTheme().Accent2)
	return card
end

local function SafeNumber(v) if type(v) == "number" then return v end return nil end
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
	ZIndexBehavior = Enum.ZIndexBehavior.Global, DisplayOrder = 9999, Enabled = false, Parent = PlayerGui,
})

--==================================================
-- [08] SCREEN HELPERS
--==================================================
local function GetViewport()
	if Camera and Camera.ViewportSize then return Camera.ViewportSize end
	return Vector2.new(1280, 720)
end

local BASE_WIDTH, BASE_HEIGHT, MIN_WIDTH_PX = 760, 520, 300

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
	return Vector2.new(math.floor((vp.X - size.X)/2), math.floor((vp.Y - size.Y)/2))
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
	Name = "MainWindow", Size = UDim2.new(0,0,0,0), Position = UDim2.new(0,0,0,0),
	AnchorPoint = Vector2.new(0,0), BackgroundColor3 = GetTheme().Base,
	BackgroundTransparency = CONFIG.WindowOpacity, BorderSizePixel = 0,
	ClipsDescendants = true, Visible = false, Parent = ScreenGui,
})
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

local TitleArea = MakeFrame(Header, UDim2.new(1,-(12+36+12+156),1,0), UDim2.new(0,58,0,0), COLORS.Card, 1)
local TitleLabel = MakeLabel(TitleArea, "VANZ ULTRA CONTROL CENTER", UDim2.new(1,0,0,22), UDim2.new(0,0,0,8), FONT_TITLE, 15, COLORS.Text)
local SubtitleLabel = MakeLabel(TitleArea, "SYSTEM ONLINE", UDim2.new(1,0,0,16), UDim2.new(0,0,0,28), FONT_TEXT, 11, COLORS.SubText)

local CONTROL_ZONE_WIDTH = 156
local ControlZone = MakeFrame(Header, UDim2.new(0,CONTROL_ZONE_WIDTH,1,0), UDim2.new(1,-CONTROL_ZONE_WIDTH-8,0,0), COLORS.Card, 1)

local BTN_SIZE, BTN_GAP = 44, 6
local SettingsBtn, MinimizeBtn, CloseBtn

local function LayoutControls()
	local zoneW = ControlZone.AbsoluteSize.X
	local zoneH = ControlZone.AbsoluteSize.Y
	local btnY = math.floor((zoneH - BTN_SIZE)/2)
	local x = zoneW - BTN_SIZE
	if CloseBtn then CloseBtn.Position = UDim2.new(0,x,0,btnY) end
	x = x - BTN_SIZE - BTN_GAP
	if MinimizeBtn then MinimizeBtn.Position = UDim2.new(0,x,0,btnY) end
	x = x - BTN_SIZE - BTN_GAP
	if SettingsBtn then SettingsBtn.Position = UDim2.new(0,x,0,btnY) end
end

SettingsBtn = MakeButton(ControlZone, "⚙", UDim2.new(0,BTN_SIZE,0,BTN_SIZE), UDim2.new(0,0,0,0), function() end)
MinimizeBtn = MakeButton(ControlZone, "—", UDim2.new(0,BTN_SIZE,0,BTN_SIZE), UDim2.new(0,0,0,0), function() end)
CloseBtn    = MakeButton(ControlZone, "X", UDim2.new(0,BTN_SIZE,0,BTN_SIZE), UDim2.new(0,0,0,0), function() end)

TrackConnection(ControlZone:GetPropertyChangedSignal("AbsoluteSize"):Connect(LayoutControls))
task.defer(LayoutControls)

--==================================================
-- [11] BODY CONTAINER
--==================================================
local Body = MakeFrame(MainWindow, UDim2.new(1,-16,1,-(HEADER_HEIGHT+12)), UDim2.new(0,8,0,HEADER_HEIGHT+4), COLORS.Card, 1)

local HomeScroll = Create("ScrollingFrame", {
	Name = "HomeScroll", Size = UDim2.new(1,0,1,0), Position = UDim2.new(0,0,0,0),
	BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 5,
	ScrollBarImageColor3 = GetTheme().Accent, CanvasSize = UDim2.new(0,0,0,0),
	ScrollingDirection = Enum.ScrollingDirection.Y, ElasticBehavior = Enum.ElasticBehavior.Never,
	Visible = true, Parent = Body,
})
local HomeList = Create("UIListLayout", {SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0,10), Parent = HomeScroll})
Create("UIPadding", {PaddingLeft = UDim.new(0,8), PaddingRight = UDim.new(0,8), PaddingTop = UDim.new(0,6), PaddingBottom = UDim.new(0,12), Parent = HomeScroll})

local function RefreshHomeCanvas()
	if not HomeScroll or not HomeScroll.Parent then return end
	HomeScroll.CanvasSize = UDim2.new(0,0,0, HomeList.AbsoluteContentSize.Y + 24)
end
TrackConnection(HomeList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(RefreshHomeCanvas))

local SettingsScroll = Create("ScrollingFrame", {
	Name = "SettingsScroll", Size = UDim2.new(1,0,1,0), Position = UDim2.new(0,0,0,0),
	BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 5,
	ScrollBarImageColor3 = GetTheme().Accent2, CanvasSize = UDim2.new(0,0,0,0),
	ScrollingDirection = Enum.ScrollingDirection.Y, ElasticBehavior = Enum.ElasticBehavior.Never,
	Visible = false, Parent = Body,
})
local SettingsList = Create("UIListLayout", {SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0,10), Parent = SettingsScroll})
Create("UIPadding", {PaddingLeft = UDim.new(0,8), PaddingRight = UDim.new(0,8), PaddingTop = UDim.new(0,6), PaddingBottom = UDim.new(0,12), Parent = SettingsScroll})

local function RefreshSettingsCanvas()
	if not SettingsScroll or not SettingsScroll.Parent then return end
	SettingsScroll.CanvasSize = UDim2.new(0,0,0, SettingsList.AbsoluteContentSize.Y + 24)
end
TrackConnection(SettingsList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(RefreshSettingsCanvas))

--==================================================
-- [12] HOME: USER PROFILE
--==================================================
local ProfileCard = MakeCard(HomeScroll, "USER PROFILE", UDim2.new(1,-4,0,150), nil)
ProfileCard.LayoutOrder = 1

local AvatarFrame = MakeFrame(ProfileCard, UDim2.new(0,84,0,84), UDim2.new(0,12,0,36), COLORS.Track, 0)
MakeCorner(AvatarFrame, 42)
MakeStroke(AvatarFrame, GetTheme().Accent, 1.5, 0.3)
local AvatarImage = Create("ImageLabel", {Size = UDim2.new(1,0,1,0), BackgroundTransparency = 1, Image = "", Parent = AvatarFrame})
MakeCorner(AvatarImage, 42)

local OnlineDot = MakeFrame(ProfileCard, UDim2.new(0,12,0,12), UDim2.new(0,84,0,84), COLORS.Good, 0)
MakeCorner(OnlineDot, 6)
MakeStroke(OnlineDot, COLORS.Card, 2, 0)

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
		local ok, img = pcall(function()
			return Players:GetUserThumbnailAsync(LocalPlayer.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size150x150)
		end)
		if ok and img then AvatarImage.Image = img; STATE.ThumbnailReady = true end
	end)
	pcall(function()
		local mt = LocalPlayer.MembershipType
		local mtText = "N/A"
		if mt == Enum.MembershipType.Premium then mtText = "Premium"
		elseif mt == Enum.MembershipType.None then mtText = "None" end
		ProfileMembership.Text = "Membership: " .. mtText
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
-- [13] HOME: CHARACTER STATUS
--==================================================
local CharCard = MakeCard(HomeScroll, "CHARACTER STATUS", UDim2.new(1,-4,0,210), nil)
CharCard.LayoutOrder = 2
local CharLines = {}
local function AddCharLine(key, yIndex)
	CharLines[key] = MakeLabel(CharCard, key .. ": N/A", UDim2.new(1,-24,0,18), UDim2.new(0,12,0,36+(yIndex-1)*20), FONT_TEXT, 14, COLORS.Text)
end
for i, k in ipairs({"WalkSpeed","JumpPower","Health","MaxHealth","Health %","HipHeight","AutoRotate","PlatformStand","RigType","Character State"}) do AddCharLine(k, i) end

--==================================================
-- [14] HOME: MOVEMENT CORE
--==================================================
local MoveCard = MakeCard(HomeScroll, "MOVEMENT CORE", UDim2.new(1,-4,0,170), nil)
MoveCard.LayoutOrder = 3
local MoveLines = {}
local function AddMoveLine(key, yIndex)
	MoveLines[key] = MakeLabel(MoveCard, key .. ": N/A", UDim2.new(1,-24,0,18), UDim2.new(0,12,0,36+(yIndex-1)*20), FONT_TEXT, 14, COLORS.Text)
end
for i, k in ipairs({"MoveDirection","Velocity","Grounded","Floor Material","Seat Status","Humanoid State","Character Name"}) do AddMoveLine(k, i) end

--==================================================
-- [15] HOME: HEALTH BAR
--==================================================
local HealthCard = MakeCard(HomeScroll, "HEALTH", UDim2.new(1,-4,0,96), nil)
HealthCard.LayoutOrder = 4
local HealthTrack = MakeFrame(HealthCard, UDim2.new(1,-24,0,22), UDim2.new(0,12,0,40), COLORS.Track, 0)
MakeCorner(HealthTrack, 8)
local HealthFill = MakeFrame(HealthTrack, UDim2.new(1,0,1,0), UDim2.new(0,0,0,0), COLORS.Good, 0)
MakeCorner(HealthFill, 8)
MakeGradient(HealthFill, COLORS.Good, GetTheme().Accent2, 0)
local HealthText = MakeLabel(HealthCard, "100 / 100", UDim2.new(1,-24,0,18), UDim2.new(0,12,0,68), FONT_BOLD, 14, COLORS.Text, Enum.TextXAlignment.Right)

--==================================================
-- [16] HOME: POSITION TELEMETRY
--==================================================
local PosCard = MakeCard(HomeScroll, "POSITION TELEMETRY", UDim2.new(1,-4,0,196), nil)
PosCard.LayoutOrder = 5
local PosLines = {}
local function AddPosLine(key, yIndex)
	PosLines[key] = MakeLabel(PosCard, key .. ": N/A", UDim2.new(1,-24,0,18), UDim2.new(0,12,0,36+(yIndex-1)*20), FONT_TEXT, 14, COLORS.Text)
end
for i, k in ipairs({"Pos X","Pos Y","Pos Z","Vel X","Vel Y","Vel Z","Magnitude","Facing"}) do AddPosLine(k, i) end

--==================================================
-- [17] HOME: PLAYER INFORMATION
--==================================================
local InfoCard = MakeCard(HomeScroll, "PLAYER INFORMATION", UDim2.new(1,-4,0,360), nil)
InfoCard.LayoutOrder = 6
local InfoLines = {}
local function AddInfoLine(key, yIndex)
	InfoLines[key] = MakeLabel(InfoCard, key .. ": N/A", UDim2.new(1,-24,0,18), UDim2.new(0,12,0,36+(yIndex-1)*20), FONT_TEXT, 14, COLORS.Text)
end
for i, k in ipairs({"Display Name","Username","UserId","Account Age","Team","Team Color","Character","Rig Type","Device","Camera Mode","Field Of View","Graphics Quality","Session Time","Server JobId","PlaceId","GameId"}) do AddInfoLine(k, i) end

--==================================================
-- [18] HOME: SESSION TELEMETRY
--==================================================
local SessionCard = MakeCard(HomeScroll, "SESSION TELEMETRY", UDim2.new(1,-4,0,180), nil)
SessionCard.LayoutOrder = 7
local SessionLines = {}
local function AddSessionLine(key, yIndex)
	SessionLines[key] = MakeLabel(SessionCard, key .. ": N/A", UDim2.new(1,-24,0,18), UDim2.new(0,12,0,36+(yIndex-1)*20), FONT_TEXT, 14, COLORS.Text)
end
for i, k in ipairs({"FPS","Ping","Uptime","Memory","Heartbeat","Client State","System"}) do AddSessionLine(k, i) end

--==================================================
-- [19] HOME: COMBAT SUITE
--==================================================
local CombatCard = MakeCard(HomeScroll, "COMBAT SUITE", UDim2.new(1,-4,0,260), nil)
CombatCard.LayoutOrder = 8
local CombatLines = {}
local function AddCombatLine(key, yIndex)
	CombatLines[key] = MakeLabel(CombatCard, key .. ": N/A", UDim2.new(1,-24,0,18), UDim2.new(0,12,0,36+(yIndex-1)*20), FONT_TEXT, 14, COLORS.Text)
end
for i, k in ipairs({"Silent Aim","Target","Target HP","Target Dist","Target Vel","Bullet Speed","Iterations","Lead Predict","Anti-Knock","Anti-Death","Auto-Heal","Drawing Lib"}) do AddCombatLine(k, i) end

--==================================================
-- [20] SETTINGS CARDS (helper)
--==================================================
local SettingsCards = {}

local function NewSettingsCard(title, height)
	local card = MakeCard(SettingsScroll, title, UDim2.new(1,-4,0,height), nil)
	table.insert(SettingsCards, card)
	return card
end

local function MakeToggleRow(parent, label, y, getValue, onChange)
	local row = MakeFrame(parent, UDim2.new(1,-24,0,44), UDim2.new(0,12,0,y), COLORS.Track, 0.1)
	MakeCorner(row, 10)
	MakeLabel(row, label, UDim2.new(1,-110,1,0), UDim2.new(0,12,0,0), FONT_BOLD, 14, COLORS.Text)
	local btn = MakeButton(row, "", UDim2.new(0,88,0,32), UDim2.new(1,-96,0.5,-16), function()
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
	local row = MakeFrame(parent, UDim2.new(1,-24,0,44), UDim2.new(0,12,0,y), COLORS.Track, 0.1)
	MakeCorner(row, 10)
	MakeLabel(row, label, UDim2.new(1,-150,1,0), UDim2.new(0,12,0,0), FONT_BOLD, 14, COLORS.Text)
	local function currentText()
		local v = getCurrent()
		if fmt then return fmt(v) end
		return tostring(v)
	end
	local btn = MakeButton(row, currentText(), UDim2.new(0,132,0,32), UDim2.new(1,-140,0.5,-16), function()
		local cur = getCurrent()
		local idx = 1
		for i, opt in ipairs(options) do if opt == cur then idx = i break end end
		local nextIdx = (idx % #options) + 1
		onChange(options[nextIdx])
		btn.Text = currentText()
	end)
	return row, btn
end

local function MakeStepperRow(parent, label, y, minV, maxV, step, getCurrent, onChange, fmt)
	local row = MakeFrame(parent, UDim2.new(1,-24,0,44), UDim2.new(0,12,0,y), COLORS.Track, 0.1)
	MakeCorner(row, 10)
	MakeLabel(row, label, UDim2.new(0.45,0,1,0), UDim2.new(0,12,0,0), FONT_BOLD, 14, COLORS.Text)
	local valueLabel = MakeLabel(row, "", UDim2.new(0,70,0,22), UDim2.new(1,-150,0.5,-11), FONT_BOLD, 14, GetTheme().Accent2, Enum.TextXAlignment.Center)
	local function refresh()
		local v = getCurrent()
		valueLabel.Text = fmt and fmt(v) or tostring(v)
	end
	refresh()
	MakeButton(row, "-", UDim2.new(0,40,0,32), UDim2.new(1,-116,0.5,-16), function()
		local v = math.max(minV, getCurrent() - step); onChange(v); refresh()
	end)
	MakeButton(row, "+", UDim2.new(0,40,0,32), UDim2.new(1,-52,0.5,-16), function()
		local v = math.min(maxV, getCurrent() + step); onChange(v); refresh()
	end)
	return row
end

--==================================================
-- [21] SETTINGS: SCALE + APPLY LAYOUT + THEME
--==================================================
local function SetScale(value)
	local valid = false
	for _, opt in ipairs(CONFIG.ScaleOptions) do
		if math.abs(opt - value) < 0.001 then valid = true; break end
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
	MainGradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, t.Base),
		ColorSequenceKeypoint.new(1, t.Base2),
	})
	AccentLine.BackgroundColor3 = t.Accent2
	HeaderLogoRing.BackgroundColor3 = t.Accent
	HeaderLogoCore.BackgroundColor3 = t.Accent2
	if MiniBody then MiniBody.BackgroundColor3 = t.Base2 end
	if MiniCore then MiniCore.BackgroundColor3 = t.Accent2 end
	HomeScroll.ScrollBarImageColor3 = t.Accent
	SettingsScroll.ScrollBarImageColor3 = t.Accent2
end

--==================================================
-- [22] SETTINGS BUILD
--==================================================
local function BuildSettingsUI()
	-- DISPLAY
	local displayCard = NewSettingsCard("DISPLAY", 260); displayCard.LayoutOrder = 1
	MakeCycleRow(displayCard, "GUI Scale / DPI", 36, CONFIG.ScaleOptions,
		function() return CONFIG.Scale end, function(v) SetScale(v) end, ScaleText)
	MakeStepperRow(displayCard, "Window Opacity", 88, 0.02, 0.5, 0.02,
		function() return CONFIG.WindowOpacity end,
		function(v) CONFIG.WindowOpacity = v; if STATE.Open and not STATE.Minimized then MainWindow.BackgroundTransparency = v end end,
		function(v) return string.format("%.2f", v) end)
	MakeStepperRow(displayCard, "Corner Radius", 140, 6, 24, 2,
		function() return CONFIG.CornerRadius end, function(v) CONFIG.CornerRadius = v end,
		function(v) return tostring(v) end)
	MakeStepperRow(displayCard, "Border Intensity", 192, 0, 1, 0.1,
		function() return CONFIG.BorderIntensity end,
		function(v) CONFIG.BorderIntensity = v; MainStroke.Transparency = 1 - v end,
		function(v) return string.format("%.1f", v) end)

	-- GLASS
	local glassCard = NewSettingsCard("GLASS", 120); glassCard.LayoutOrder = 2
	MakeStepperRow(glassCard, "Glass Intensity", 36, 0, 1, 0.1,
		function() return CONFIG.GlassIntensity end,
		function(v) CONFIG.GlassIntensity = v; MainGradient.Transparency = NumberSequence.new(1 - v) end,
		function(v) return string.format("%.1f", v) end)

	-- ANIMATION
	local animCard = NewSettingsCard("ANIMATION", 420); animCard.LayoutOrder = 3
	local animRows = {
		{"Master Animation","AnimationEnabled"},{"Soft Animation","SoftAnimation"},{"Logo Animation","LogoAnimation"},
		{"Radar Animation","RadarAnimation"},{"Particle Animation","ParticleAnimation"},{"Scanline","Scanline"},
		{"Hover Animation","HoverAnimation"},{"Click Animation","ClickAnimation"},{"Transition Animation","TransitionAnimation"},
	}
	local ay = 36
	for _, pair in ipairs(animRows) do
		local label, key = pair[1], pair[2]
		MakeToggleRow(animCard, label, ay, function() return CONFIG[key] end, function(v) CONFIG[key] = v end)
		ay = ay + 46
	end
	MakeCycleRow(animCard, "Animation Speed", ay, {0.5,0.75,1,1.25,1.5},
		function() return CONFIG.AnimationSpeed end, function(v) CONFIG.AnimationSpeed = v end,
		function(v) return string.format("%.2fx", v) end)

	-- VISUAL
	local visualCard = NewSettingsCard("VISUAL", 420); visualCard.LayoutOrder = 4
	MakeCycleRow(visualCard, "Theme", 36, {"Cyber Blue","Neon Cyan","Purple Anime","Crimson","Emerald","Ice"},
		function() return CONFIG.Theme end, function(v) CONFIG.Theme = v; ApplyTheme() end)
	MakeStepperRow(visualCard, "Glow Intensity", 88, 0, 1, 0.1,
		function() return CONFIG.GlowIntensity end, function(v) CONFIG.GlowIntensity = v end,
		function(v) return string.format("%.1f", v) end)
	MakeStepperRow(visualCard, "Particle Density", 140, 0, 30, 2,
		function() return CONFIG.ParticleDensity end, function(v) CONFIG.ParticleDensity = v end,
		function(v) return tostring(v) end)
	MakeToggleRow(visualCard, "HUD Decoration", 192, function() return CONFIG.HUDDecoration end, function(v) CONFIG.HUDDecoration = v end)
	MakeToggleRow(visualCard, "Background Grid", 244, function() return CONFIG.BackgroundGrid end, function(v) CONFIG.BackgroundGrid = v end)

	-- COMBAT SUITE
	local combatCard = NewSettingsCard("COMBAT SUITE", 380); combatCard.LayoutOrder = 5
	MakeToggleRow(combatCard, "Silent Aim (MASTER)", 36, function() return CONFIG.SilentAim end, function(v)
		CONFIG.SilentAim = v; CONFIG.VisualLine = v; CONFIG.LeadPredict = v
		CONFIG.AntiKnock = v; CONFIG.AntiDeath = v; CONFIG.AutoHeal = v
		AimCfg.leadPrediction = v
		if not v then
			if DrawLine then DrawLine.Visible = false end
			if DrawDot then DrawDot.Visible = false end
			if DrawRawDot then DrawRawDot.Visible = false end
		end
	end)
	MakeToggleRow(combatCard, "Visual Line", 88, function() return CONFIG.VisualLine end, function(v)
		CONFIG.VisualLine = v
		if not v then
			if DrawLine then DrawLine.Visible = false end
			if DrawDot then DrawDot.Visible = false end
			if DrawRawDot then DrawRawDot.Visible = false end
		end
	end)
	MakeToggleRow(combatCard, "Lead Predict", 140, function() return CONFIG.LeadPredict end, function(v)
		CONFIG.LeadPredict = v; AimCfg.leadPrediction = v
	end)
	MakeToggleRow(combatCard, "Anti-Knock", 192, function() return CONFIG.AntiKnock end, function(v) CONFIG.AntiKnock = v end)
	MakeToggleRow(combatCard, "Anti-Death", 244, function() return CONFIG.AntiDeath end, function(v) CONFIG.AntiDeath = v end)
	MakeToggleRow(combatCard, "Auto-Heal", 296, function() return CONFIG.AutoHeal end, function(v) CONFIG.AutoHeal = v end)
	MakeToggleRow(combatCard, "Show Fire Button", 348, function() return CONFIG.ShowFireButton end, function(v)
		CONFIG.ShowFireButton = v
		if FireBtn then FireBtn.Visible = v end
	end)

	-- COMBAT TUNING
	local tuneCard = NewSettingsCard("COMBAT TUNING", 340); tuneCard.LayoutOrder = 6
	MakeCycleRow(tuneCard, "Origin Mode", 36, {"gun","head","hrp"},
		function() return AimCfg.originMode end, function(v) AimCfg.originMode = v end)
	MakeCycleRow(tuneCard, "Target Part", 88, {"uppertorso","torso","hrp","head"},
		function() return AimCfg.targetMode end, function(v) AimCfg.targetMode = v end)
	MakeCycleRow(tuneCard, "Lateral Axis", 140, {"RightVector","UpVector","LookVector"},
		function() return AimCfg.lateralAxis end, function(v) AimCfg.lateralAxis = v end)
	MakeStepperRow(tuneCard, "Lateral Offset", 192, -3, 3, 0.25,
		function() return AimCfg.lateralOffset end, function(v) AimCfg.lateralOffset = v end,
		function(v) return string.format("%.2f", v) end)
	MakeStepperRow(tuneCard, "Bullet Speed", 244, 50, 1000, 25,
		function() return AimCfg.bulletSpeed end,
		function(v) AimCfg.bulletSpeed = v; AimCfg.bulletSpeedAuto = false end,
		function(v) return tostring(math.floor(v)) end)
	MakeStepperRow(tuneCard, "Lead Iterations", 296, 1, 40, 1,
		function() return AimCfg.leadIterations end, function(v) AimCfg.leadIterations = v end,
		function(v) return tostring(math.floor(v)) end)

	-- WINDOW
	local windowCard = NewSettingsCard("WINDOW", 240); windowCard.LayoutOrder = 7
	MakeToggleRow(windowCard, "Remember Position", 36, function() return CONFIG.RememberPosition end, function(v) CONFIG.RememberPosition = v end)
	local centerBtn = MakeButton(windowCard, "Center Window", UDim2.new(1,-24,0,40), UDim2.new(0,12,0,92), function() ApplyWindowLayout(true) end)
	MakeCorner(centerBtn, 10)
	local resetPosBtn = MakeButton(windowCard, "Reset Position", UDim2.new(1,-24,0,40), UDim2.new(0,12,0,140), function()
		STATE.MainPosition = nil; STATE.MiniPosition = nil; ApplyWindowLayout(true)
	end)
	MakeCorner(resetPosBtn, 10)
	local resetSettingsBtn = MakeButton(windowCard, "Reset Settings", UDim2.new(1,-24,0,40), UDim2.new(0,12,0,188), function()
		if _G.vanz then _G.vanz.ResetSettings() end
	end)
	MakeCorner(resetSettingsBtn, 10)

	-- PERFORMANCE
	local perfCard = NewSettingsCard("PERFORMANCE", 220); perfCard.LayoutOrder = 8
	MakeToggleRow(perfCard, "Low FX Mode", 36, function() return CONFIG.LowFXMode end, function(v) CONFIG.LowFXMode = v end)
	MakeToggleRow(perfCard, "FPS Friendly Mode", 88, function() return CONFIG.FPSFriendly end, function(v) CONFIG.FPSFriendly = v end)
	MakeToggleRow(perfCard, "Disable Particles", 140, function() return CONFIG.DisableParticles end, function(v) CONFIG.DisableParticles = v end)
	MakeToggleRow(perfCard, "Disable Heavy Animation", 192, function() return CONFIG.DisableHeavyAnimation end, function(v) CONFIG.DisableHeavyAnimation = v end)
end

--==================================================
-- [23] DRAG ENGINE
--==================================================
local function BindDrag(target, handle, onMoveEnd)
	local dragging, startInput, startAbs, movedPx = false, nil, nil, 0

	TrackConnection(handle.InputBegan:Connect(function(input)
		if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then return end
		dragging = true; movedPx = 0
		startInput = input.Position
		startAbs = target.AbsolutePosition
	end))

	TrackConnection(UserInputService.InputChanged:Connect(function(input)
		if not dragging then return end
		if input.UserInputType ~= Enum.UserInputType.MouseMovement and input.UserInputType ~= Enum.UserInputType.Touch then return end
		local delta = Vector2.new(input.Position.X, input.Position.Y) - Vector2.new(startInput.X, startInput.Y)
		movedPx = math.max(movedPx, delta.Magnitude)
		if movedPx < CONFIG.DragThreshold then return end
		local targetSize = target.AbsoluteSize
		local newPos = ClampAbsolute(startAbs + delta, targetSize)
		target.Position = UDim2.fromOffset(newPos.X, newPos.Y)
		target.AnchorPoint = Vector2.new(0,0)
	end))

	TrackConnection(UserInputService.InputEnded:Connect(function(input)
		if not dragging then return end
		if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then return end
		dragging = false
		local wasDrag = movedPx >= CONFIG.DragThreshold
		if onMoveEnd then
			local ok, err = pcall(onMoveEnd, wasDrag)
			if not ok then warn("[VANZ] drag end error:", err) end
		end
	end))
end

--==================================================
-- [23B] FLOATING FIRE BUTTON
--==================================================
FireBtn = Create("TextButton", {
	Name = "VANZ_FireBtn", AnchorPoint = Vector2.new(1, 0.5),
	Position = UDim2.new(1, -20, 0.5, 0),
	Size = UDim2.new(0, 70, 0, 70),
	BackgroundColor3 = Color3.fromRGB(180, 40, 40),
	BackgroundTransparency = 0.15, Text = "FIRE", TextColor3 = Color3.fromRGB(255,255,255),
	TextSize = 16, Font = FONT_BOLD, AutoButtonColor = true, Visible = false,
	ZIndex = 200, Parent = ScreenGui,
})
MakeCorner(FireBtn, 35)
MakeStroke(FireBtn, Color3.fromRGB(255, 90, 90), 2, 0)

TrackConnection(FireBtn.MouseButton1Click:Connect(function()
	task.spawn(function()
		xpcall(function()
			if FireTofImpl then FireTofImpl() end
		end, function(err) warn("[VANZ] Fire err: " .. tostring(err)) end)
	end)
end))

--==================================================
-- [23C] FLOATING HUD INFO
--==================================================
HUDInfo = Create("TextLabel", {
	Name = "VANZ_HUDInfo", AnchorPoint = Vector2.new(0.5, 1),
	Position = UDim2.new(0.5, 0, 1, -15),
	Size = UDim2.new(0, 540, 0, 24),
	BackgroundTransparency = 0.3, BackgroundColor3 = Color3.fromRGB(15,15,20),
	TextColor3 = Color3.fromRGB(255, 75, 75), TextSize = 10,
	Font = Enum.Font.Code, TextXAlignment = Enum.TextXAlignment.Center,
	Text = "[VANZ] INITIALIZING...", Visible = false, ZIndex = 200, Parent = ScreenGui,
})
MakeCorner(HUDInfo, 6)
MakeStroke(HUDInfo, Color3.fromRGB(255, 40, 40), 1, 0.5)

--==================================================
-- [24] MINI LOGO
--==================================================
local MINI_SIZE = 72

local MiniLogo = Create("Frame", {
	Name = "MiniLogo", Size = UDim2.new(0,MINI_SIZE,0,MINI_SIZE), Position = UDim2.new(0,0,0,0),
	BackgroundTransparency = 1, BorderSizePixel = 0, Visible = false, Parent = ScreenGui,
})
MiniBody = MakeFrame(MiniLogo, UDim2.new(1,0,1,0), UDim2.new(0,0,0,0), GetTheme().Base2, 0.15)
MakeCorner(MiniBody, MINI_SIZE/2)
MakeStroke(MiniBody, GetTheme().Accent, 1.5, 0.2)
MiniRing = MakeFrame(MiniLogo, UDim2.new(1,-10,1,-10), UDim2.new(0,5,0,5), GetTheme().Accent, 1)
MakeCorner(MiniRing, MINI_SIZE/2)
MakeStroke(MiniRing, GetTheme().Accent2, 1.2, 0.3)
MiniCore = MakeFrame(MiniLogo, UDim2.new(0,18,0,18), UDim2.new(0.5,-9,0.5,-9), GetTheme().Accent2, 0)
MakeCorner(MiniCore, 9)
MiniScan = MakeFrame(MiniLogo, UDim2.new(0.6,0,0,2), UDim2.new(0.2,0,0.5,-1), GetTheme().Accent2, 0.2)
MakeGradient(MiniScan, GetTheme().Accent, GetTheme().Accent2, 0)
local MiniHit = Create("TextButton", {Size = UDim2.new(1,0,1,0), BackgroundTransparency = 1, Text = "", AutoButtonColor = false, ZIndex = 5, Parent = MiniLogo})

--==================================================
-- [25] FLOATING GUI MANAGER
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
	STATE.Open = true; STATE.Minimized = false
	ScreenGui.Enabled = true; MainWindow.Visible = true; MiniLogo.Visible = false
	ApplyWindowLayout(STATE.MainPosition == nil)
	if CONFIG.AnimationEnabled and CONFIG.TransitionAnimation and not CONFIG.LowFXMode then
		MainWindow.BackgroundTransparency = 1
		TrackTween(TweenService:Create(MainWindow, TweenInfo.new(0.28/CONFIG.AnimationSpeed, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
			BackgroundTransparency = CONFIG.WindowOpacity,
		})):Play()
	end
	if FireBtn then FireBtn.Visible = CONFIG.ShowFireButton end
	if HUDInfo then HUDInfo.Visible = CONFIG.ShowHUDInfo end
end

local function MinimizeToLogo()
	if not STATE.Open then return end
	STATE.Minimized = true
	local mainCenter = ReadMainAbsolute()
	local mainSize = MainWindow.AbsoluteSize
	local centerX = mainCenter.X + mainSize.X / 2
	local centerY = mainCenter.Y + mainSize.Y / 2
	SetMiniAbsolute(Vector2.new(centerX - MINI_SIZE/2, centerY - MINI_SIZE/2))
	MainWindow.Visible = false; MiniLogo.Visible = true
	if CONFIG.AnimationEnabled and CONFIG.TransitionAnimation and not CONFIG.LowFXMode then
		MiniLogo.Size = UDim2.new(0,10,0,10)
		TrackTween(TweenService:Create(MiniLogo, TweenInfo.new(0.22/CONFIG.AnimationSpeed, Enum.EasingStyle.Quint), {
			Size = UDim2.new(0, MINI_SIZE, 0, MINI_SIZE),
		})):Play()
	else
		MiniLogo.Size = UDim2.new(0, MINI_SIZE, 0, MINI_SIZE)
	end
end

local function RestoreFromLogo()
	if not STATE.Open then return end
	STATE.Minimized = false
	local miniPos = STATE.MiniPosition or Vector2.new(0,0)
	local size = ComputeWindowSize()
	local centerX = miniPos.X + MINI_SIZE/2
	local centerY = miniPos.Y + MINI_SIZE/2
	local pos = Vector2.new(centerX - size.X/2, centerY - size.Y/2)
	MiniLogo.Visible = false
	SetMainAbsolute(pos, size)
	MainWindow.Visible = true
	if CONFIG.AnimationEnabled and CONFIG.TransitionAnimation and not CONFIG.LowFXMode then
		MainWindow.BackgroundTransparency = 1
		TrackTween(TweenService:Create(MainWindow, TweenInfo.new(0.24/CONFIG.AnimationSpeed, Enum.EasingStyle.Quint), {
			BackgroundTransparency = CONFIG.WindowOpacity,
		})):Play()
	end
end

local DestroyAll

local function SetSettingsVisible(v)
	STATE.SettingsOpen = v
	SettingsScroll.Visible = v
	HomeScroll.Visible = not v
	SettingsBtn.Text = v and "⌂" or "⚙"
end

--==================================================
-- [26] HUD DECORATION
--==================================================
local HudLayer = MakeFrame(MainWindow, UDim2.new(1,0,1,0), UDim2.new(0,0,0,0), COLORS.Card, 1)
HudLayer.ZIndex = 1

local function MakeBracket(pos, isLeft, isTop)
	local bx = isLeft and 0 or 1
	local by = isTop and 0 or 1
	MakeFrame(HudLayer, UDim2.new(0,14,0,2), UDim2.new(bx, isLeft and 6 or -20, by, isTop and 6 or -8), GetTheme().Accent, 0.3)
	MakeFrame(HudLayer, UDim2.new(0,2,0,14), UDim2.new(bx, isLeft and 6 or -8, by, isTop and 6 or -20), GetTheme().Accent, 0.3)
end
MakeBracket(nil, true, true); MakeBracket(nil, false, true)
MakeBracket(nil, true, false); MakeBracket(nil, false, false)

local ScanLine = MakeFrame(HudLayer, UDim2.new(1,0,0,1), UDim2.new(0,0,0,0), GetTheme().Accent2, 0.75)
local MicroText = MakeLabel(HudLayer, "VANZ CORE • SYSTEM ONLINE", UDim2.new(0,200,0,12), UDim2.new(0,12,1,-16), FONT_TEXT, 10, COLORS.SubText)
MicroText.TextTransparency = 0.25

--==================================================
-- [27] ANIMATION ENGINE
--==================================================
local AnimTime = 0
local function AnimationTick(dt)
	if not CONFIG.AnimationEnabled or CONFIG.LowFXMode or CONFIG.DisableHeavyAnimation then return end
	AnimTime = AnimTime + dt * CONFIG.AnimationSpeed
	if CONFIG.LogoAnimation and STATE.Open and not STATE.Minimized then
		local pulse = 0.9 + 0.1 * math.sin(AnimTime * 2.4)
		HeaderLogoRing.Size = UDim2.new(pulse,0,pulse,0)
		HeaderLogoRing.Position = UDim2.new((1-pulse)/2,0,(1-pulse)/2,0)
	end
	if CONFIG.Scanline and CONFIG.HUDDecoration and STATE.Open then
		local span = MainWindow.AbsoluteSize.Y
		if span > 0 then
			ScanLine.Position = UDim2.new(0,0,0, (AnimTime * 60) % span)
		end
	end
	if CONFIG.RadarAnimation and STATE.Minimized and MiniScan and MiniRing then
		local ang = AnimTime * 90
		MiniScan.Rotation = ang
		MiniRing.Rotation = -ang * 0.5
	end
	if STATE.Minimized and MiniCore then
		local br = 0.9 + 0.1 * math.sin(AnimTime * 3)
		MiniCore.Size = UDim2.new(0, 18*br, 0, 18*br)
		MiniCore.Position = UDim2.new(0.5, -9*br, 0.5, -9*br)
	end
end

--==================================================
-- [28] PARTICLE ENGINE
--==================================================
local ParticleContainer = MakeFrame(MainWindow, UDim2.new(1,0,1,0), UDim2.new(0,0,0,0), COLORS.Card, 1)
ParticleContainer.ZIndex = 0
ParticleContainer.ClipsDescendants = true
local ParticleCount, MAX_PARTICLES, ParticleAcc = 0, 40, 0

local function SpawnParticle()
	if CONFIG.DisableParticles or CONFIG.LowFXMode or not CONFIG.ParticleAnimation then return end
	if ParticleCount >= MAX_PARTICLES then return end
	if not STATE.Open or STATE.Minimized then return end
	local w = ParticleContainer.AbsoluteSize.X
	local h = ParticleContainer.AbsoluteSize.Y
	if w <= 0 or h <= 0 then return end
	ParticleCount = ParticleCount + 1
	local size = math.random(2,4)
	local p = MakeFrame(ParticleContainer, UDim2.new(0,size,0,size), UDim2.new(0, math.random(0,w), 0, math.random(0,h)), GetTheme().Accent2, 0.7)
	MakeCorner(p, size)
	local dx = math.random(-30, 30)
	local dy = math.random(-40, -10)
	local dur = math.random(25, 45) / 10 / CONFIG.AnimationSpeed
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

--==================================================
-- [29] DATA UPDATE HELPERS
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

local function UpdateCharacterCard(h, root)
	local c = GetCharacter()
	if h then
		CharLines["WalkSpeed"].Text = "WalkSpeed: " .. ToStr(h.WalkSpeed)
		CharLines["JumpPower"].Text = "JumpPower: " .. ToStr(h.JumpPower)
		CharLines["Health"].Text = "Health: " .. ToStr(h.Health, 1)
		CharLines["MaxHealth"].Text = "MaxHealth: " .. ToStr(h.MaxHealth, 1)
		local pct = 0
		if h.MaxHealth and h.MaxHealth > 0 then pct = (h.Health / h.MaxHealth) * 100 end
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
	if c then MoveLines["Character Name"].Text = "Character Name: " .. c.Name
	else MoveLines["Character Name"].Text = "Character Name: N/A" end
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
		for _, key in ipairs({"MoveDirection","Grounded","Floor Material","Seat Status","Humanoid State"}) do
			MoveLines[key].Text = key .. ": N/A"
		end
	end
end

local function UpdateHealthCard(h)
	if not h or not h.MaxHealth or h.MaxHealth <= 0 then
		HealthText.Text = "N/A"
		HealthFill.Size = UDim2.new(0,0,1,0)
		return
	end
	local pct = math.clamp(h.Health / h.MaxHealth, 0, 1)
	HealthFill.Size = UDim2.new(pct, 0, 1, 0)
	HealthText.Text = string.format("%d / %d", math.floor(h.Health + 0.5), math.floor(h.MaxHealth + 0.5))
	if pct > 0.6 then HealthFill.BackgroundColor3 = COLORS.Good
	elseif pct > 0.3 then HealthFill.BackgroundColor3 = COLORS.Warn
	else HealthFill.BackgroundColor3 = COLORS.Bad end
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
	SessionLines["Uptime"].Text = "Uptime: " .. string.format("%02d:%02d", math.floor(uptime/60), math.floor(uptime%60))
	local memOk, memText = pcall(function()
		return string.format("%.1f MB", Stats:GetTotalMemoryUsageMb())
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
		if InfoLines[key] then InfoLines[key].Text = key .. ": " .. (text or "N/A") end
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
	local uptime = os.clock() - STATE.SessionStart
	setInfo("Session Time", string.format("%02d:%02d", math.floor(uptime/60), math.floor(uptime%60)))
	pcall(function() setInfo("Server JobId", game.JobId ~= "" and game.JobId or "N/A") end)
	pcall(function() setInfo("PlaceId", tostring(game.PlaceId)) end)
	pcall(function() setInfo("GameId", tostring(game.GameId)) end)
end

local function UpdateCombatCard()
	local hasDrawing = (type(Drawing) == "table" and type(Drawing.new) == "function")
	CombatLines["Silent Aim"].Text = "Silent Aim: " .. (CONFIG.SilentAim and "ON" or "OFF")
	CombatLines["Lead Predict"].Text = "Lead Predict: " .. (AimCfg.leadPrediction and "ON" or "OFF")
	CombatLines["Anti-Knock"].Text = "Anti-Knock: " .. (CONFIG.AntiKnock and "ON" or "OFF")
	CombatLines["Anti-Death"].Text = "Anti-Death: " .. (CONFIG.AntiDeath and "ON" or "OFF")
	CombatLines["Auto-Heal"].Text = "Auto-Heal: " .. (CONFIG.AutoHeal and "ON" or "OFF")
	CombatLines["Drawing Lib"].Text = "Drawing Lib: " .. (hasDrawing and "OK" or "MISSING")

	local tgt = STATE.Target
	if tgt and tgt.Character then
		local name = tgt.Name or "N/A"
		local char = tgt.Character
		local hum = char:FindFirstChildOfClass("Humanoid")
		local myRoot = GetRootPart()
		local tgtRoot = char:FindFirstChild("HumanoidRootPart")
		local dist = 0
		if myRoot and tgtRoot then
			dist = (tgtRoot.Position - myRoot.Position).Magnitude
		end
		CombatLines["Target"].Text = "Target: " .. name
		CombatLines["Target HP"].Text = "Target HP: " .. (hum and string.format("%.0f/%.0f", hum.Health, hum.MaxHealth) or "N/A")
		CombatLines["Target Dist"].Text = string.format("Target Dist: %.1fm", dist)
		CombatLines["Target Vel"].Text = string.format("Target Vel: %.1f", GetPlayerSpeed(tgt))
	else
		CombatLines["Target"].Text = "Target: NONE"
		CombatLines["Target HP"].Text = "Target HP: N/A"
		CombatLines["Target Dist"].Text = "Target Dist: N/A"
		CombatLines["Target Vel"].Text = "Target Vel: N/A"
	end

	local bs = AimCfg.bulletSpeed
	CombatLines["Bullet Speed"].Text = "Bullet Speed: " .. ((typeof(bs) == "number" and bs > 0) and string.format("%.0f", bs) or "200")
	CombatLines["Iterations"].Text = "Iterations: " .. tostring(AimCfg.leadIterations or 9999)
end

local function UpdateSlowData()
	pcall(function()
		local mt = LocalPlayer.MembershipType
		local mtText = "N/A"
		if mt == Enum.MembershipType.Premium then mtText = "Premium"
		elseif mt == Enum.MembershipType.None then mtText = "None" end
		ProfileMembership.Text = "Membership: " .. mtText
	end)
	pcall(function()
		ProfileTeam.Text = "Team: " .. (LocalPlayer.Team and LocalPlayer.Team.Name or "N/A")
	end)
end

--==================================================
-- [30] HUMANOID EVENTS
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
		table.insert(HumanoidConnections, h.StateChanged:Connect(function() end))
	end
end

TrackConnection(LocalPlayer.CharacterAdded:Connect(function(char)
	task.defer(function() BindCharacter(char) end)
end))
TrackConnection(LocalPlayer:GetPropertyChangedSignal("Team"):Connect(function() UpdateSlowData() end))

--==================================================
-- [31] MAIN UPDATE LOOP
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

	local now = tick()
	STATE.FrameTimeAcc = STATE.FrameTimeAcc + dt
	STATE.CombatFrameCount = STATE.CombatFrameCount + 1
	if now - STATE.LastFPSSample >= 0.5 then
		local avgDt = STATE.FrameTimeAcc / math.max(STATE.CombatFrameCount, 1)
		local fps = 1 / math.max(avgDt, 0.001)
		STATE.SmoothFPS = STATE.SmoothFPS * 0.7 + fps * 0.3
		STATE.FrameTimeAcc = 0
		STATE.CombatFrameCount = 0
		STATE.LastFPSSample = now
	end

	AnimationTick(dt)

	ParticleAcc = ParticleAcc + dt
	if ParticleAcc >= 0.5 and not CONFIG.LowFXMode and not CONFIG.FPSFriendly then
		ParticleAcc = 0
		local density = math.clamp(CONFIG.ParticleDensity, 0, 30)
		local spawnCount = math.floor(density / 10)
		for _ = 1, spawnCount do SpawnParticle() end
	end

	pcall(ScanTarget)

	if CONFIG.SilentAim or CONFIG.VisualLine or CONFIG.LeadPredict then
		local myRoot = GetRootPart()
		local myPos = myRoot and myRoot.Position
		local maxDist = AimCfg.maxScanDistance or 999
		for _, plr in ipairs(Players:GetPlayers()) do
			if plr ~= LocalPlayer then
				pcall(SampleVelocity, plr, maxDist, myPos)
			end
		end
	end

	STATE.FastTimer = STATE.FastTimer + dt
	if STATE.FastTimer >= CONFIG.FastUpdateRate then
		STATE.FastTimer = 0
		if STATE.Open and not STATE.Minimized then
			if not STATE.SettingsOpen then
				local h = GetHumanoid()
				local root = GetRootPart()
				pcall(UpdateCharacterCard, h, root)
				pcall(UpdateHealthCard, h)
				pcall(UpdatePlayerInfo)
				pcall(UpdateSessionCard)
			end
			pcall(UpdateCombatCard)
		end
	end

	STATE.SlowTimer = STATE.SlowTimer + dt
	if STATE.SlowTimer >= CONFIG.HomeUpdateRate * 4 then
		STATE.SlowTimer = 0
		pcall(UpdateSlowData)
	end
end))

--==================================================
-- [32] HUD INFO UPDATE
--==================================================
TrackConnection(RunService.Heartbeat:Connect(function()
	if STATE.Destroyed then return end
	if not HUDInfo then return end
	if not CONFIG.ShowHUDInfo then
		HUDInfo.Visible = false
		return
	end
	HUDInfo.Visible = STATE.Open or STATE.Minimized
	local tgt = STATE.Target
	local name = tgt and tgt.Name or "NONE"
	local distStr, hpStr = "0m", "N/A"
	if tgt and tgt.Character then
		local myRoot = GetRootPart()
		local tgtRoot = tgt.Character:FindFirstChild("HumanoidRootPart")
		local hum = tgt.Character:FindFirstChildOfClass("Humanoid")
		if myRoot and tgtRoot then
			distStr = string.format("%.1fm", (tgtRoot.Position - myRoot.Position).Magnitude)
		end
		if hum then
			hpStr = string.format("%.0f/%.0f", hum.Health, hum.MaxHealth)
		end
	end
	local vel = tgt and GetPlayerSpeed(tgt) or 0
	local bs = AimCfg.bulletSpeed
	local bsStr = (typeof(bs) == "number" and bs > 0) and string.format("%.0f", bs) or "200"
	local fps = STATE.SmoothFPS or 60
	local iter = AimCfg.leadIterations or 9999
	local state = CONFIG.SilentAim and "ACTIVE" or "STANDBY"
	HUDInfo.Text = string.format(
		"SYS:[%s] | TGT: %s | HP: %s | DIST: %s | VEL: %.1f | SPD: %s | ITER: %d | FPS: %.0f",
		state, name, hpStr, distStr, vel, bsStr, iter, fps
	)
end))

--==================================================
-- [33] DRAG BINDINGS
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
-- [34] BUTTON ACTIONS
--==================================================
TrackConnection(SettingsBtn.MouseButton1Click:Connect(function()
	SetSettingsVisible(not STATE.SettingsOpen)
end))
TrackConnection(MinimizeBtn.MouseButton1Click:Connect(function()
	MinimizeToLogo()
end))
TrackConnection(CloseBtn.MouseButton1Click:Connect(function()
	DestroyAll()
end))

--==================================================
-- [35] GLOBAL API
--==================================================
_G.vanz = _G.vanz or {}
_G.vanz.Settings = _G.vanz.Settings or {}
_G.vanz.Events   = _G.vanz.Events   or {}
_G.vanz.Runtime  = _G.vanz.Runtime  or {}
_G.vanz.TeamCfg  = TeamCfg
_G.vanz.AimCfg   = AimCfg
_G.vanz.FireTof  = function() if FireTofImpl then FireTofImpl() end end

_G.vanz.Open = function() if STATE.Destroyed then return false end ShowMainWindow() return true end
_G.vanz.Hide = function()
	if STATE.Destroyed then return false end
	MainWindow.Visible = false; MiniLogo.Visible = false; STATE.Open = false
	return true
end
_G.vanz.Minimize = function() if STATE.Destroyed then return false end MinimizeToLogo() return true end
_G.vanz.Restore  = function() if STATE.Destroyed then return false end RestoreFromLogo() return true end
_G.vanz.Toggle = function()
	if STATE.Destroyed then return false end
	if STATE.Open then _G.vanz.Hide() else _G.vanz.Open() end
	return true
end
_G.vanz.SetScale = function(v) if STATE.Destroyed then return false end return SetScale(v) end
_G.vanz.GetScale = function() return CONFIG.Scale end
_G.vanz.GetState = function()
	return {
		Open = STATE.Open, Minimized = STATE.Minimized, Scale = CONFIG.Scale,
		Theme = CONFIG.Theme, Destroyed = STATE.Destroyed,
		SilentAim = CONFIG.SilentAim, Target = STATE.Target,
	}
end
_G.vanz.ResetSettings = function()
	if STATE.Destroyed then return false end
	for k, v in pairs(DEFAULT_CONFIG_SNAPSHOT) do CONFIG[k] = v end
	ApplyTheme(); ApplyWindowLayout(true)
	return true
end
_G.vanz.Close = function() return DestroyAll() end

--==================================================
-- [36] DESTROY
--==================================================
DestroyAll = function()
	if STATE.Destroyed then return end
	STATE.Destroyed = true
	STATE.Open = false; STATE.Minimized = false
	CleanupAll()
	DisconnectHumanoidEvents()
	if ScreenGui and ScreenGui.Parent then ScreenGui:Destroy() end
	if FireBtn and FireBtn.Parent then FireBtn:Destroy() end
	if HUDInfo and HUDInfo.Parent then HUDInfo:Destroy() end
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
-- [37] INIT
--==================================================
local function Init()
	FillProfile()
	BuildSettingsUI()
	ApplyTheme()
	SetSettingsVisible(false)
	ApplyWindowLayout(true)
	ShowMainWindow()
	BindCharacter(LocalPlayer.Character)
	STATE.Built = true
end

local okInit, errInit = pcall(Init)
if not okInit then warn("[VANZ] Init error:", errInit) end

TrackConnection(Camera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
	if STATE.Destroyed then return end
	if STATE.Open and not STATE.Minimized then ApplyWindowLayout(false)
	elseif STATE.Minimized then
		local p = STATE.MiniPosition
		if p then SetMiniAbsolute(p) end
	end
end))

TrackConnection(Players.PlayerRemoving:Connect(function(p)
	if p == LocalPlayer then DestroyAll() end
end))

print("[VANZ] MERGED v8-MAX READY (FIXED).")