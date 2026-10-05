-- VANZ
-- LocalScript
-- Full Automated Generator & Escape System for Cybercrime Game

_G.vanz = _G.vanz or {}
local V = _G.vanz

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
	return ok, err
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
	V.Gui.Parent = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")

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
	V.Title.Text = "VANZ CYBERCRIME"
	V.Title.TextColor3 = Color3.fromRGB(255, 255, 255)
	V.Title.TextSize = 16
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
end)


-- =========================================================
-- 2_DRAG_LOGO
-- =========================================================

vanzBlock("2_DRAG_LOGO", function()
	local UserInputService = game:GetService("UserInputService")
	local dragging, dragStart, startPosition

	V.Logo.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
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
		if input.UserInputType ~= Enum.UserInputType.MouseMovement and input.UserInputType ~= Enum.UserInputType.Touch then return end
		local delta = input.Position - dragStart
		V.Logo.Position = UDim2.new(startPosition.X.Scale, startPosition.X.Offset + delta.X, startPosition.Y.Scale, startPosition.Y.Offset + delta.Y)
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

		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 9)
		corner.Parent = holder

		local label = Instance.new("TextLabel")
		label.Size = UDim2.new(1, -65, 1, 0)
		label.Position = UDim2.fromOffset(12, 0)
		label.BackgroundTransparency = 1
		label.Text = name
		label.TextColor3 = Color3.fromRGB(235, 235, 240)
		label.TextSize = 13
		label.Font = Enum.Font.GothamMedium
		label.TextXAlignment = Enum.TextXAlignment.Left
		label.Parent = holder

		local button = Instance.new("TextButton")
		button.Size = UDim2.fromOffset(42, 24)
		button.Position = UDim2.new(1, -52, 0.5, -12)
		button.BackgroundColor3 = Color3.fromRGB(55, 55, 62)
		button.Text = ""
		button.Parent = holder

		local buttonCorner = Instance.new("UICorner")
		buttonCorner.CornerRadius = UDim.new(1, 0)
		buttonCorner.Parent = button

		local state = default == true

		local function update()
			if state then
				button.BackgroundColor3 = Color3.fromRGB(80, 170, 255)
			else
				button.BackgroundColor3 = Color3.fromRGB(55, 55, 62)
			end
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
-- 4_AUTO_GAMEPLAY_ENGINE
-- =========================================================

vanzBlock("4_AUTO_GAMEPLAY_ENGINE", function()
	local Players = game:GetService("Players")
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local RunService = game:GetService("RunService")
	local LocalPlayer = Players.LocalPlayer

	V.AutoActive = false

	V.CreateToggle("Auto Generator & Escape", false, function(enabled)
		V.AutoActive = enabled
	end)

	local Remotes = ReplicatedStorage:WaitForChild("Remotes")
	local GenEvent = Remotes:WaitForChild("Generator"):WaitForChild("RepairEvent")
	local EscapeTimeEvent = Remotes:WaitForChild("Generator"):WaitForChild("Escapetime")
	local OneLeftEvent = Remotes:WaitForChild("Game"):WaitForChild("Oneleft")
	local StartEvent = Remotes:WaitForChild("Game"):WaitForChild("Start")
	local DeleteSpecEvent = Remotes:WaitForChild("Game"):WaitForChild("deletespectatorgui")
	local ExitLeverEvent = Remotes:WaitForChild("Exit"):WaitForChild("LeverEvent")
	local ProgressUpdateEvent = Remotes:WaitForChild("Progress"):WaitForChild("ProgressUpdateEvent")

	local gameStarted = false
	local escapeMode = false
	local taskCompleted = false

	-- Listeners for game states
	StartEvent.Event:Connect(function() gameStarted = true end)
	DeleteSpecEvent.OnClientEvent:Connect(function() gameStarted = true end)
	EscapeTimeEvent.OnClientEvent:Connect(function() escapeMode = true end)
	OneLeftEvent.OnClientEvent:Connect(function() escapeMode = true end)
	ProgressUpdateEvent.OnClientEvent:Connect(function(progress, status, val)
		if progress == 100 or status == "OPEN" then
			taskCompleted = true
			V.AutoActive = false
			if V.Toggles["Auto Generator & Escape"] then
				V.Toggles["Auto Generator & Escape"].Set(false)
			end
		end
	end)

	-- Check enemy within 35 studs based on color circle mechanism
	local function isEnemyNearby()
		local character = LocalPlayer.Character
		if not character or not character:FindFirstChild("HumanoidRootPart") then return false end
		local myPos = character.HumanoidRootPart.Position

		for _, player in ipairs(Players:GetPlayers()) do
			if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
				-- Deteksi team / color circle logic: red/enemy/killer check
				local enemyChar = player.Character
				local dist = (enemyChar.HumanoidRootPart.Position - myPos).Magnitude
				if dist <= 35 then
					-- Cek indikator warna/team musuh jika ada (default anggap non-teammate sebagai threat)
					if player.Team ~= LocalPlayer.Team then
						return true
					end
				end
			end
		end
		return false
	end

	local function getRootPart()
		local char = LocalPlayer.Character
		return char and char:FindFirstChild("HumanoidRootPart")
	end

	-- Main loop
	task.spawn(function()
		while true do
			task.wait(0.5)
			if V.AutoActive and not taskCompleted then
				-- Jika map belum load, cek apakah ada remotes start
				local map = workspace:FindFirstChild("Map")
				if map and map:FindFirstChild("Generator") then
					gameStarted = true
				end

				if gameStarted then
					if not escapeMode then
						-- Loop Generator 1-7
						local genFolder = map and map:FindFirstChild("Generator")
						if genFolder then
							local gens = genFolder:GetChildren()
							for i = 1, 7 do
								if not V.AutoActive or escapeMode or taskCompleted then break end
								local targetGen = genFolder:FindFirstChild("GeneratorPoint" .. tostring(i))
								if targetGen then
									-- Teleport & Repair
									local root = getRootPart()
									if root then
										root.CFrame = targetGen.CFrame + Vector3.new(0, 3, 0)
									end

									while V.AutoActive and not escapeMode and not taskCompleted do
										if isEnemyNearby() then
											GenEvent:FireServer(targetGen, false)
											task.wait(1)
										else
											GenEvent:FireServer(targetGen, true)
										end
										task.wait(0.5)
										-- Cek apakah generator sudah selesai (bisa disesuaikan jika ada atribut)
										break 
									end
								end
							end
						end
					else
						-- Loop Lever 1-5 untuk escape
						local gateFolder = map and map:FindFirstChild("Gate")
						if gateFolder and gateFolder:FindFirstChild("ExitLever") then
							local leverMain = gateFolder.ExitLever:FindFirstChild("Main")
							if leverMain then
								local root = getRootPart()
								if root then
									root.CFrame = leverMain.CFrame + Vector3.new(0, 3, 0)
								end

								while V.AutoActive and not taskCompleted do
									if isEnemyNearby() then
										ExitLeverEvent:FireServer(leverMain, false)
										task.wait(1)
									else
										ExitLeverEvent:FireServer(leverMain, true)
									end
									task.wait(0.5)
								end
							end
						end
					end
				end
			end
		end
	end)
end)
