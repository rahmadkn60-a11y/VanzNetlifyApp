-- VANZ
-- LocalScript
-- GUI + Auto Generator + Auto Lever + Color Circle + AFK Safe

_G.vanz = _G.vanz or {}
local V = _G.vanz

local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local LP = Players.LocalPlayer

-- =========================================================
-- ERROR HANDLER
-- =========================================================

local function vanzErrorHandler(blockName, err)
	local message = tostring(err)
	local traceback = debug.traceback("", 2)
	warn(string.format("[VANZ ERROR][%s] %s\n%s", blockName, message, traceback))
	return message .. "\n" .. traceback
end

local function vanzBlock(blockName, callback)
	local ok, err = xpcall(callback, function(e)
		return vanzErrorHandler(blockName, e)
	end)
	if not ok then return false, err end
	return true
end


-- =========================================================
-- 1_INIT_GUI
-- =========================================================

vanzBlock("1_INIT_GUI", function()

	V.Gui = Instance.new("ScreenGui")
	V.Gui.Name = "VANZ"
	V.Gui.ResetOnSpawn = false
	V.Gui.IgnoreGuiInset = true
	V.Gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	V.Gui.Parent = LP:WaitForChild("PlayerGui")

	V.Main = Instance.new("Frame")
	V.Main.Name = "Main"
	V.Main.Size = UDim2.new(0, 260, 0.85, 0)
	V.Main.Position = UDim2.new(0, 15, 0.5, 0)
	V.Main.AnchorPoint = Vector2.new(0, 0.5)
	V.Main.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
	V.Main.BorderSizePixel = 0
	V.Main.Parent = V.Gui

	local mainConstraint = Instance.new("UISizeConstraint")
	mainConstraint.MinSize = Vector2.new(220, 300)
	mainConstraint.MaxSize = Vector2.new(260, 900)
	mainConstraint.Parent = V.Main

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 12)
	corner.Parent = V.Main

	V.Header = Instance.new("Frame")
	V.Header.Name = "Header"
	V.Header.Size = UDim2.new(1, 0, 0, 48)
	V.Header.BackgroundTransparency = 1
	V.Header.Parent = V.Main

	V.Title = Instance.new("TextLabel")
	V.Title.Size = UDim2.new(1, -55, 1, 0)
	V.Title.Position = UDim2.fromOffset(15, 0)
	V.Title.BackgroundTransparency = 1
	V.Title.Text = "VANZ"
	V.Title.TextColor3 = Color3.fromRGB(255, 255, 255)
	V.Title.TextSize = 20
	V.Title.Font = Enum.Font.GothamBold
	V.Title.TextXAlignment = Enum.TextXAlignment.Left
	V.Title.Parent = V.Header

	V.Minimize = Instance.new("TextButton")
	V.Minimize.Name = "Minimize"
	V.Minimize.Size = UDim2.fromOffset(38, 38)
	V.Minimize.Position = UDim2.new(1, -43, 0, 5)
	V.Minimize.BackgroundColor3 = Color3.fromRGB(35, 35, 42)
	V.Minimize.Text = "—"
	V.Minimize.TextColor3 = Color3.fromRGB(255, 255, 255)
	V.Minimize.TextSize = 20
	V.Minimize.Font = Enum.Font.GothamBold
	V.Minimize.Parent = V.Header

	local minCorner = Instance.new("UICorner")
	minCorner.CornerRadius = UDim.new(0, 9)
	minCorner.Parent = V.Minimize

	V.Content = Instance.new("ScrollingFrame")
	V.Content.Name = "Content"
	V.Content.Position = UDim2.fromOffset(8, 52)
	V.Content.Size = UDim2.new(1, -16, 1, -60)
	V.Content.BackgroundTransparency = 1
	V.Content.BorderSizePixel = 0
	V.Content.ScrollBarThickness = 3
	V.Content.CanvasSize = UDim2.fromOffset(0, 0)
	V.Content.AutomaticCanvasSize = Enum.AutomaticSize.Y
	V.Content.Parent = V.Main

	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 7)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = V.Content

	-- Status label
	V.StatusLabel = Instance.new("TextLabel")
	V.StatusLabel.Size = UDim2.new(1, 0, 0, 36)
	V.StatusLabel.BackgroundColor3 = Color3.fromRGB(22, 22, 28)
	V.StatusLabel.TextColor3 = Color3.fromRGB(160, 160, 180)
	V.StatusLabel.TextSize = 12
	V.StatusLabel.Font = Enum.Font.GothamMedium
	V.StatusLabel.Text = "Status: Lobby"
	V.StatusLabel.BorderSizePixel = 0
	V.StatusLabel.Parent = V.Content

	local statusCorner = Instance.new("UICorner")
	statusCorner.CornerRadius = UDim.new(0, 9)
	statusCorner.Parent = V.StatusLabel

	V.PhaseLabel = Instance.new("TextLabel")
	V.PhaseLabel.Size = UDim2.new(1, 0, 0, 30)
	V.PhaseLabel.BackgroundTransparency = 1
	V.PhaseLabel.TextColor3 = Color3.fromRGB(100, 200, 255)
	V.PhaseLabel.TextSize = 12
	V.PhaseLabel.Font = Enum.Font.Gotham
	V.PhaseLabel.Text = "Phase: Waiting"
	V.PhaseLabel.BorderSizePixel = 0
	V.PhaseLabel.Parent = V.Content

	V.Logo = Instance.new("TextButton")
	V.Logo.Name = "Logo"
	V.Logo.Size = UDim2.fromOffset(55, 55)
	V.Logo.Position = UDim2.new(0, 15, 0.5, 0)
	V.Logo.AnchorPoint = Vector2.new(0, 0.5)
	V.Logo.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
	V.Logo.Text = "V"
	V.Logo.TextColor3 = Color3.fromRGB(255, 255, 255)
	V.Logo.TextSize = 25
	V.Logo.Font = Enum.Font.GothamBold
	V.Logo.Visible = false
	V.Logo.Parent = V.Gui

	local logoCorner = Instance.new("UICorner")
	logoCorner.CornerRadius = UDim.new(1, 0)
	logoCorner.Parent = V.Logo

	V.Minimize.MouseButton1Click:Connect(function()
		V.Main.Visible = false
		V.Logo.Visible = true
	end)

	V.Logo.MouseButton1Click:Connect(function()
		V.Logo.Visible = false
		V.Main.Visible = true
	end)

	function V.SetStatus(text)
		V.StatusLabel.Text = "Status: " .. text
	end

	function V.SetPhase(text)
		V.PhaseLabel.Text = "Phase: " .. text
	end

end)


-- =========================================================
-- 2_DRAG_LOGO
-- =========================================================

vanzBlock("2_DRAG_LOGO", function()

	local dragging = false
	local dragStart
	local startPosition

	V.Logo.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			dragStart = input.Position
			startPosition = V.Logo.Position
			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragging = false
				end
			end)
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if not dragging then return end
		if input.UserInputType ~= Enum.UserInputType.MouseMovement
			and input.UserInputType ~= Enum.UserInputType.Touch then return end
		local delta = input.Position - dragStart
		V.Logo.Position = UDim2.new(
			startPosition.X.Scale, startPosition.X.Offset + delta.X,
			startPosition.Y.Scale, startPosition.Y.Offset + delta.Y
		)
	end)

end)


-- =========================================================
-- 3_UI_HELPERS
-- =========================================================

vanzBlock("3_UI_HELPERS", function()

	V.Toggles = {}

	function V.CreateToggle(name, default, callback)
		local holder = Instance.new("Frame")
		holder.Name = name
		holder.Size = UDim2.new(1, 0, 0, 48)
		holder.BackgroundColor3 = Color3.fromRGB(27, 27, 33)
		holder.BorderSizePixel = 0
		holder.Parent = V.Content

		local c = Instance.new("UICorner")
		c.CornerRadius = UDim.new(0, 9)
		c.Parent = holder

		local label = Instance.new("TextLabel")
		label.Size = UDim2.new(1, -65, 1, 0)
		label.Position = UDim2.fromOffset(12, 0)
		label.BackgroundTransparency = 1
		label.Text = name
		label.TextColor3 = Color3.fromRGB(235, 235, 240)
		label.TextSize = 14
		label.Font = Enum.Font.GothamMedium
		label.TextXAlignment = Enum.TextXAlignment.Left
		label.Parent = holder

		local button = Instance.new("TextButton")
		button.Size = UDim2.fromOffset(42, 24)
		button.Position = UDim2.new(1, -52, 0.5, -12)
		button.BackgroundColor3 = Color3.fromRGB(55, 55, 62)
		button.Text = ""
		button.Parent = holder

		local bc = Instance.new("UICorner")
		bc.CornerRadius = UDim.new(1, 0)
		bc.Parent = button

		local state = default == true

		local function update()
			button.BackgroundColor3 = state
				and Color3.fromRGB(80, 170, 255)
				or Color3.fromRGB(55, 55, 62)
			if callback then callback(state) end
		end

		button.MouseButton1Click:Connect(function()
			state = not state
			update()
		end)

		V.Toggles[name] = {
			Get = function() return state end,
			Set = function(value) state = value == true; update() end
		}

		update()
		return V.Toggles[name]
	end

end)


-- =========================================================
-- 4_CORE_STATE
-- =========================================================

vanzBlock("4_CORE_STATE", function()

	V.State = {
		AutoGen    = false,
		GameActive = false,
		Phase      = "lobby",   -- lobby / generator / lever / done
		GenIndex   = 1,
		LeverIndex = 1,
		Stopped    = false,
	}

	V.ENEMY_DIST   = 35
	V.GEN_COUNT    = 7
	V.LEVER_COUNT  = 5

end)


-- =========================================================
-- 5_COLOR_CIRCLE (Team logic)
-- blue = team, white = unknown, red = enemy/killer
-- =========================================================

vanzBlock("5_COLOR_CIRCLE", function()

	function V.GetPlayerTeam(player)
		if not player.Team then return "white" end
		local teamColor = player.Team.TeamColor
		local name = tostring(teamColor)
		name = name:lower()
		if name:find("red") or name:find("killer") or name:find("enemy") then
			return "red"
		elseif name:find("blue") or name:find("team") then
			return "blue"
		end
		return "white"
	end

	function V.IsEnemyNearby(range)
		local char = LP.Character
		if not char then return false end
		local root = char:FindFirstChild("HumanoidRootPart")
		if not root then return false end

		for _, player in ipairs(Players:GetPlayers()) do
			if player == LP then continue end
			local color = V.GetPlayerTeam(player)
			if color ~= "red" then continue end

			local pchar = player.Character
			if not pchar then continue end
			local proot = pchar:FindFirstChild("HumanoidRootPart")
			if not proot then continue end

			local dist = (root.Position - proot.Position).Magnitude
			if dist <= range then
				return true
			end
		end

		return false
	end

end)


-- =========================================================
-- 6_TELEPORT
-- =========================================================

vanzBlock("6_TELEPORT", function()

	function V.TeleportTo(target)
		local char = LP.Character
		if not char then return end
		local root = char:FindFirstChild("HumanoidRootPart")
		if not root then return end

		if typeof(target) == "Instance" then
			local pos = target:IsA("BasePart")
				and target.Position
				or (target:FindFirstChildOfClass("BasePart") and target:FindFirstChildOfClass("BasePart").Position)
			if pos then
				root.CFrame = CFrame.new(pos + Vector3.new(0, 4, 0))
			end
		elseif typeof(target) == "Vector3" then
			root.CFrame = CFrame.new(target + Vector3.new(0, 4, 0))
		end
	end

end)


-- =========================================================
-- 7_GET_OBJECTS
-- =========================================================

vanzBlock("7_GET_OBJECTS", function()

	function V.GetGeneratorPoint(index)
		local ok, result = pcall(function()
			local gens = workspace:WaitForChild("Map", 5)
				:WaitForChild("Generator", 5)
				:GetChildren()
			local genFolder = gens[4]
			if not genFolder then return nil end
			return genFolder:FindFirstChild("GeneratorPoint" .. index)
		end)
		if ok then return result end
		return nil
	end

	function V.GetLever(index)
		local ok, result = pcall(function()
			return workspace:WaitForChild("Map", 5)
				:WaitForChild("Gate", 5)
				:WaitForChild("ExitLever", 5)
				:WaitForChild("Main", 5)
		end)
		if ok then return result end
		return nil
	end

end)


-- =========================================================
-- 8_REMOTES
-- =========================================================

vanzBlock("8_REMOTES", function()

	V.Remotes = {}

	local function safeGet(path)
		local ok, result = pcall(function()
			local node = RS
			for _, part in ipairs(path) do
				node = node:WaitForChild(part, 10)
			end
			return node
		end)
		if ok then return result end
		return nil
	end

	V.Remotes.GeneratorRepair = safeGet({"Remotes", "Generator", "RepairEvent"})
	V.Remotes.LeverEvent      = safeGet({"Remotes", "Exit", "LeverEvent"})
	V.Remotes.Oneleft         = safeGet({"Remotes", "Game", "Oneleft"})
	V.Remotes.Escapetime      = safeGet({"Remotes", "Generator", "Escapetime"})
	V.Remotes.GameStart       = safeGet({"Remotes", "Game", "Start"})
	V.Remotes.DeleteSpectator = safeGet({"Remotes", "Game", "deletespectatorgui"})
	V.Remotes.ProgressUpdate  = safeGet({"Remotes", "Progress", "ProgressUpdateEvent"})

end)


-- =========================================================
-- 9_LISTEN_ESCAPE
-- Server→Client: Oneleft / Escapetime → switch to Lever phase
-- =========================================================

vanzBlock("9_LISTEN_ESCAPE", function()

	local function onEscapeSignal()
		if V.State.Phase ~= "generator" then return end
		V.State.Phase = "lever"
		V.State.LeverIndex = 1
		V.SetStatus("Escape signal! → Lever")
		V.SetPhase("Lever")
	end

	if V.Remotes.Oneleft then
		V.Remotes.Oneleft.OnClientEvent:Connect(onEscapeSignal)
	end

	if V.Remotes.Escapetime then
		V.Remotes.Escapetime.OnClientEvent:Connect(onEscapeSignal)
	end

end)


-- =========================================================
-- 10_LISTEN_PROGRESS
-- Server→Client: ProgressUpdateEvent(100, "OPEN", false) → stop all
-- =========================================================

vanzBlock("10_LISTEN_PROGRESS", function()

	if V.Remotes.ProgressUpdate then
		V.Remotes.ProgressUpdate.OnClientEvent:Connect(function(progress, state, _)
			if progress == 100 and state == "OPEN" then
				V.State.Phase    = "done"
				V.State.Stopped  = true
				V.SetStatus("Gate OPEN — Done")
				V.SetPhase("Done")
			end
		end)
	end

end)


-- =========================================================
-- 11_LISTEN_GAME_START
-- Server→Client: GameStart / DeleteSpectator → switch to generator phase
-- =========================================================

vanzBlock("11_LISTEN_GAME_START", function()

	local function onGameStart()
		if V.State.Phase ~= "lobby" then return end
		if not V.State.AutoGen then return end
		V.State.Phase    = "generator"
		V.State.GenIndex = 1
		V.SetStatus("Game started → Generator")
		V.SetPhase("Generator 1")
	end

	if V.Remotes.GameStart then
		V.Remotes.GameStart.OnClientEvent:Connect(onGameStart)
	end

	if V.Remotes.DeleteSpectator then
		V.Remotes.DeleteSpectator.OnClientEvent:Connect(onGameStart)
	end

end)


-- =========================================================
-- 12_FIRE_GENERATOR
-- =========================================================

vanzBlock("12_FIRE_GENERATOR", function()

	function V.FireGenerator(genPoint, active)
		if not V.Remotes.GeneratorRepair then return end
		if not genPoint then return end
		pcall(function()
			V.Remotes.GeneratorRepair:FireServer(genPoint, active)
		end)
	end

end)


-- =========================================================
-- 13_FIRE_LEVER
-- =========================================================

vanzBlock("13_FIRE_LEVER", function()

	function V.FireLever(leverObj, active)
		if not V.Remotes.LeverEvent then return end
		if not leverObj then return end
		pcall(function()
			V.Remotes.LeverEvent:FireServer(leverObj, active)
		end)
	end

end)


-- =========================================================
-- 14_MAIN_LOOP
-- Tick-based loop untuk generator & lever
-- =========================================================

vanzBlock("14_MAIN_LOOP", function()

	local TICK_RATE     = 0.2
	local GEN_INTERVAL  = 0.5
	local lastGenFire   = 0
	local lastLeverFire = 0
	local LEVER_INTERVAL = 0.5

	local currentGenPoint  = nil
	local currentLeverObj  = nil
	local generatingActive = false
	local leverActive      = false

	RunService.Heartbeat:Connect(function()

		if not V.State.AutoGen then return end
		if V.State.Stopped then return end

		local now = tick()
		local phase = V.State.Phase

		-- ============================
		-- GENERATOR PHASE
		-- ============================

		if phase == "generator" then

			local idx = V.State.GenIndex
			if idx > V.GEN_COUNT then
				-- semua gen selesai, tunggu escape signal
				V.SetPhase("Waiting escape...")
				return
			end

			-- Resolving generator point
			if not currentGenPoint then
				currentGenPoint = V.GetGeneratorPoint(idx)
				if not currentGenPoint then return end
				V.TeleportTo(currentGenPoint)
				task.wait(0.6)
				generatingActive = false
			end

			-- Color circle check
			local enemyNear = V.IsEnemyNearby(V.ENEMY_DIST)

			if enemyNear then
				-- Stop generator, pindah ke gen berikutnya
				if generatingActive then
					V.FireGenerator(currentGenPoint, false)
					generatingActive = false
				end
				V.SetStatus("Enemy! Skipping Gen " .. idx)
				V.State.GenIndex    = idx + 1
				currentGenPoint     = nil
				task.wait(0.3)
				return
			end

			-- Fire generator
			if now - lastGenFire >= GEN_INTERVAL then
				V.FireGenerator(currentGenPoint, true)
				generatingActive = true
				lastGenFire = now
				V.SetStatus("Gen " .. idx .. " → Repairing")
				V.SetPhase("Generator " .. idx)
			end
		end

		-- ============================
		-- LEVER PHASE
		-- ============================

		if phase == "lever" then

			local idx = V.State.LeverIndex
			if idx > V.LEVER_COUNT then
				V.SetPhase("All levers done")
				return
			end

			if not currentLeverObj then
				currentLeverObj = V.GetLever(idx)
				if not currentLeverObj then
					-- lever index ini kosong, skip
					V.State.LeverIndex = idx + 1
					return
				end
				V.TeleportTo(currentLeverObj)
				task.wait(0.6)
				leverActive = false
			end

			local enemyNear = V.IsEnemyNearby(V.ENEMY_DIST)

			if enemyNear then
				if leverActive then
					V.FireLever(currentLeverObj, false)
					leverActive = false
				end
				V.SetStatus("Enemy! Skipping Lever " .. idx)
				V.State.LeverIndex = idx + 1
				currentLeverObj    = nil
				task.wait(0.3)
				return
			end

			if now - lastLeverFire >= LEVER_INTERVAL then
				V.FireLever(currentLeverObj, true)
				leverActive     = true
				lastLeverFire   = now
				V.SetStatus("Lever " .. idx .. " → Pulling")
				V.SetPhase("Lever " .. idx)
			end
		end

		-- ============================
		-- DONE
		-- ============================

		if phase == "done" then
			if generatingActive and currentGenPoint then
				V.FireGenerator(currentGenPoint, false)
				generatingActive = false
			end
			if leverActive and currentLeverObj then
				V.FireLever(currentLeverObj, false)
				leverActive = false
			end
			currentGenPoint = nil
			currentLeverObj = nil
		end

	end)

	-- Reset antar round
	V.ResetRound = function()
		V.State.Phase      = "lobby"
		V.State.GenIndex   = 1
		V.State.LeverIndex = 1
		V.State.Stopped    = false
		V.State.GameActive = false
		currentGenPoint    = nil
		currentLeverObj    = nil
		generatingActive   = false
		leverActive        = false
		V.SetStatus("Lobby")
		V.SetPhase("Waiting")
	end

end)


-- =========================================================
-- 15_FEATURES_TOGGLE
-- =========================================================

vanzBlock("15_FEATURES_TOGGLE", function()

	V.CreateToggle("Auto Generator", false, function(enabled)
		V.State.AutoGen = enabled
		if enabled then
			V.SetStatus("Auto Gen ON")
		else
			V.SetStatus("Auto Gen OFF")
		end
	end)

	V.CreateToggle("Reset Round", false, function(enabled)
		if enabled then
			V.ResetRound()
			task.wait(0.3)
			V.Toggles["Reset Round"].Set(false)
		end
	end)

end)