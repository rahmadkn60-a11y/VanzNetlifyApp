local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local rootPart = character:WaitForChild("HumanoidRootPart")

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "CoordGui"
screenGui.ResetOnSpawn = false
screenGui.Parent = player.PlayerGui

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 220, 0, 36)
frame.Position = UDim2.new(0.5, -110, 0, 12)
frame.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
frame.BorderSizePixel = 0
frame.Parent = screenGui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 6)
corner.Parent = frame

local coordLabel = Instance.new("TextLabel")
coordLabel.Size = UDim2.new(1, -44, 1, 0)
coordLabel.Position = UDim2.new(0, 8, 0, 0)
coordLabel.BackgroundTransparency = 1
coordLabel.TextColor3 = Color3.fromRGB(0, 255, 128)
coordLabel.TextSize = 13
coordLabel.Font = Enum.Font.Code
coordLabel.TextXAlignment = Enum.TextXAlignment.Left
coordLabel.Text = "X:0 Y:0 Z:0"
coordLabel.Parent = frame

local copyBtn = Instance.new("TextButton")
copyBtn.Size = UDim2.new(0, 36, 1, 0)
copyBtn.Position = UDim2.new(1, -36, 0, 0)
copyBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
copyBtn.BorderSizePixel = 0
copyBtn.TextColor3 = Color3.fromRGB(180, 180, 180)
copyBtn.TextSize = 11
copyBtn.Font = Enum.Font.Code
copyBtn.Text = "copy"
copyBtn.Parent = frame

local copyCorner = Instance.new("UICorner")
copyCorner.CornerRadius = UDim.new(0, 6)
copyCorner.Parent = copyBtn

local currentCoord = ""

RunService.RenderStepped:Connect(function()
	if rootPart and rootPart.Parent then
		local p = rootPart.Position
		currentCoord = string.format("X:%.1f Y:%.1f Z:%.1f", p.X, p.Y, p.Z)
		coordLabel.Text = currentCoord
	end
end)

copyBtn.MouseButton1Click:Connect(function()
	setclipboard(currentCoord)
	copyBtn.Text = "✓"
	copyBtn.TextColor3 = Color3.fromRGB(0, 255, 128)
	task.delay(1.2, function()
		copyBtn.Text = "copy"
		copyBtn.TextColor3 = Color3.fromRGB(180, 180, 180)
	end)
end)