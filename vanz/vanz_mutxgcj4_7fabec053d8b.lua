--[[
    ╔══════════════════════════════════════════════════════════════╗
    ║                 VANZ // PREMIUM UI v3                      ║
    ║       WIDE • PREMIUM • GLOW • ANIMATED • RESPONSIVE        ║
    ╚══════════════════════════════════════════════════════════════╝

    FEATURES
    • Wide landscape layout
    • Comfortable screen margins
    • Premium glass-style panels
    • Animated RGB / accent engine
    • Animated header shine
    • Premium toggle switches
    • ON/OFF glow animation
    • Animated buttons
    • Animated tabs
    • Floating V logo
    • Minimize / restore animation
    • Responsive scaling
    • Touch + mouse friendly
    • GUI ONLY
]]

------------------------------------------------------------
-- SERVICES
------------------------------------------------------------

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

------------------------------------------------------------
-- GLOBAL CORE
------------------------------------------------------------

_G.vanz = _G.vanz or {}

_G.vanz.Config = _G.vanz.Config or {}
_G.vanz.Config.Title = "VANZ"
_G.vanz.Config.Subtitle = "PREMIUM CONTROL CENTER"
_G.vanz.Config.Scale = 1.00
_G.vanz.Config.DynamicColors = true

_G.vanz.UI = _G.vanz.UI or {}
_G.vanz.Tabs = {}
_G.vanz.Components = {}

------------------------------------------------------------
-- DISCONNECT OLD CONNECTIONS
------------------------------------------------------------

if _G.vanz.Connections then
	for _, connection in ipairs(_G.vanz.Connections) do
		pcall(function()
			connection:Disconnect()
		end)
	end
end

_G.vanz.Connections = {}

------------------------------------------------------------
-- REMOVE OLD GUI
------------------------------------------------------------

pcall(function()
	local old = PlayerGui:FindFirstChild("VANZ_PREMIUM_GUI")
	if old then
		old:Destroy()
	end
end)

------------------------------------------------------------
-- COLORS
------------------------------------------------------------

local Colors = {
	Background = Color3.fromRGB(7, 9, 14),
	Panel = Color3.fromRGB(12, 15, 23),
	Panel2 = Color3.fromRGB(16, 20, 30),
	Panel3 = Color3.fromRGB(20, 24, 36),

	Sidebar = Color3.fromRGB(9, 12, 19),

	Text = Color3.fromRGB(245, 247, 255),
	SubText = Color3.fromRGB(145, 151, 170),
	Muted = Color3.fromRGB(82, 89, 108),

	Stroke = Color3.fromRGB(48, 55, 75),

	Accent = Color3.fromRGB(95, 145, 255),
	Accent2 = Color3.fromRGB(150, 95, 255),

	Success = Color3.fromRGB(85, 255, 170),
	Danger = Color3.fromRGB(255, 90, 115),

	White = Color3.fromRGB(255, 255, 255),
	Black = Color3.fromRGB(0, 0, 0),
}

_G.vanz.UI.Colors = Colors

------------------------------------------------------------
-- HELPERS
------------------------------------------------------------

local function Tween(object, info, properties)
	local tween = TweenService:Create(object, info, properties)
	tween:Play()
	return tween
end

local function FastTween(object, properties)
	return Tween(
		object,
		TweenInfo.new(
			0.18,
			Enum.EasingStyle.Quint,
			Enum.EasingDirection.Out
		),
		properties
	)
end

local function PremiumTween(object, properties)
	return Tween(
		object,
		TweenInfo.new(
			0.32,
			Enum.EasingStyle.Quint,
			Enum.EasingDirection.Out
		),
		properties
	)
end

local function AddCorner(parent, radius)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, radius)
	corner.Parent = parent
	return corner
end

local function AddStroke(parent, color, transparency, thickness)
	local stroke = Instance.new("UIStroke")
	stroke.Color = color or Colors.Stroke
	stroke.Transparency = transparency or 0
	stroke.Thickness = thickness or 1
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Parent = parent
	return stroke
end

local function AddPadding(parent, left, right, top, bottom)
	local padding = Instance.new("UIPadding")
	padding.PaddingLeft = UDim.new(0, left or 0)
	padding.PaddingRight = UDim.new(0, right or 0)
	padding.PaddingTop = UDim.new(0, top or 0)
	padding.PaddingBottom = UDim.new(0, bottom or 0)
	padding.Parent = parent
	return padding
end

local function AddGradient(parent, color1, color2, rotation)
	local gradient = Instance.new("UIGradient")
	gradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, color1),
		ColorSequenceKeypoint.new(1, color2),
	})
	gradient.Rotation = rotation or 0
	gradient.Parent = parent
	return gradient
end

------------------------------------------------------------
-- SCREEN GUI
------------------------------------------------------------

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "VANZ_PREMIUM_GUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.IgnoreGuiInset = true
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = PlayerGui

------------------------------------------------------------
-- SCALE
------------------------------------------------------------

local UIScale = Instance.new("UIScale")
UIScale.Scale = _G.vanz.Config.Scale
UIScale.Parent = ScreenGui

_G.vanz.UI.ScreenGui = ScreenGui
_G.vanz.UI.UIScale = UIScale

------------------------------------------------------------
-- AMBIENT BACKGROUND GLOWS
------------------------------------------------------------

local AmbientLeft = Instance.new("Frame")
AmbientLeft.Name = "AmbientLeft"
AmbientLeft.AnchorPoint = Vector2.new(0.5, 0.5)
AmbientLeft.Position = UDim2.fromScale(0.18, 0.52)
AmbientLeft.Size = UDim2.fromOffset(430, 430)
AmbientLeft.BackgroundColor3 = Colors.Accent
AmbientLeft.BackgroundTransparency = 0.94
AmbientLeft.BorderSizePixel = 0
AmbientLeft.ZIndex = 0
AmbientLeft.Parent = ScreenGui
AddCorner(AmbientLeft, 215)

local AmbientRight = Instance.new("Frame")
AmbientRight.Name = "AmbientRight"
AmbientRight.AnchorPoint = Vector2.new(0.5, 0.5)
AmbientRight.Position = UDim2.fromScale(0.82, 0.48)
AmbientRight.Size = UDim2.fromOffset(430, 430)
AmbientRight.BackgroundColor3 = Colors.Accent2
AmbientRight.BackgroundTransparency = 0.95
AmbientRight.BorderSizePixel = 0
AmbientRight.ZIndex = 0
AmbientRight.Parent = ScreenGui
AddCorner(AmbientRight, 215)

------------------------------------------------------------
-- MAIN CONTAINER
------------------------------------------------------------

local MainHolder = Instance.new("Frame")
MainHolder.Name = "MainHolder"
MainHolder.AnchorPoint = Vector2.new(0.5, 0.5)
MainHolder.Position = UDim2.fromScale(0.5, 0.5)

-- WIDE LANDSCAPE
MainHolder.Size = UDim2.fromOffset(780, 500)

MainHolder.BackgroundTransparency = 1
MainHolder.BorderSizePixel = 0
MainHolder.ZIndex = 5
MainHolder.Parent = ScreenGui

------------------------------------------------------------
-- OUTER GLOW
------------------------------------------------------------

local GlowOuter = Instance.new("Frame")
GlowOuter.Name = "GlowOuter"
GlowOuter.AnchorPoint = Vector2.new(0.5, 0.5)
GlowOuter.Position = UDim2.fromScale(0.5, 0.5)
GlowOuter.Size = UDim2.new(1, 32, 1, 32)
GlowOuter.BackgroundColor3 = Colors.Accent
GlowOuter.BackgroundTransparency = 0.91
GlowOuter.BorderSizePixel = 0
GlowOuter.ZIndex = 1
GlowOuter.Parent = MainHolder
AddCorner(GlowOuter, 28)

local GlowMiddle = Instance.new("Frame")
GlowMiddle.Name = "GlowMiddle"
GlowMiddle.AnchorPoint = Vector2.new(0.5, 0.5)
GlowMiddle.Position = UDim2.fromScale(0.5, 0.5)
GlowMiddle.Size = UDim2.new(1, 18, 1, 18)
GlowMiddle.BackgroundColor3 = Colors.Accent
GlowMiddle.BackgroundTransparency = 0.93
GlowMiddle.BorderSizePixel = 0
GlowMiddle.ZIndex = 2
GlowMiddle.Parent = MainHolder
AddCorner(GlowMiddle, 25)

------------------------------------------------------------
-- MAIN PANEL
------------------------------------------------------------

local Main = Instance.new("Frame")
Main.Name = "Main"
Main.AnchorPoint = Vector2.new(0.5, 0.5)
Main.Position = UDim2.fromScale(0.5, 0.5)
Main.Size = UDim2.fromScale(1, 1)
Main.BackgroundColor3 = Colors.Background
Main.BackgroundTransparency = 0.03
Main.BorderSizePixel = 0
Main.ClipsDescendants = true
Main.ZIndex = 5
Main.Parent = MainHolder

AddCorner(Main, 22)

local MainStroke = AddStroke(
	Main,
	Colors.Accent,
	0.35,
	1.2
)

_G.vanz.UI.Main = Main
_G.vanz.UI.Shadow = GlowOuter
_G.vanz.UI.GlowOuter = GlowOuter
_G.vanz.UI.GlowMiddle = GlowMiddle

------------------------------------------------------------
-- MAIN INNER BORDER
------------------------------------------------------------

local InnerBorder = Instance.new("Frame")
InnerBorder.Name = "InnerBorder"
InnerBorder.Position = UDim2.fromOffset(1, 1)
InnerBorder.Size = UDim2.new(1, -2, 1, -2)
InnerBorder.BackgroundTransparency = 1
InnerBorder.BorderSizePixel = 0
InnerBorder.ZIndex = 20
InnerBorder.Parent = Main

AddCorner(InnerBorder, 21)

local InnerStroke = AddStroke(
	InnerBorder,
	Colors.White,
	0.94,
	1
)

------------------------------------------------------------
-- HEADER
------------------------------------------------------------

local Header = Instance.new("Frame")
Header.Name = "Header"
Header.Size = UDim2.new(1, 0, 0, 82)
Header.BackgroundColor3 = Colors.Panel
Header.BorderSizePixel = 0
Header.ZIndex = 10
Header.Parent = Main

local HeaderGradient = AddGradient(
	Header,
	Colors.Panel2,
	Colors.Background,
	0
)

------------------------------------------------------------
-- HEADER SHINE
------------------------------------------------------------

local HeaderShine = Instance.new("Frame")
HeaderShine.Name = "Shine"
HeaderShine.Size = UDim2.new(1, 0, 1, 0)
HeaderShine.BackgroundColor3 = Colors.White
HeaderShine.BackgroundTransparency = 0.88
HeaderShine.BorderSizePixel = 0
HeaderShine.ZIndex = 11
HeaderShine.Parent = Header

local ShineGradient = Instance.new("UIGradient")
ShineGradient.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Colors.White),
	ColorSequenceKeypoint.new(0.42, Colors.White),
	ColorSequenceKeypoint.new(0.5, Colors.Accent),
	ColorSequenceKeypoint.new(0.58, Colors.White),
	ColorSequenceKeypoint.new(1, Colors.White),
})

ShineGradient.Transparency = NumberSequence.new({
	NumberSequenceKeypoint.new(0, 1),
	NumberSequenceKeypoint.new(0.42, 1),
	NumberSequenceKeypoint.new(0.5, 0.75),
	NumberSequenceKeypoint.new(0.58, 1),
	NumberSequenceKeypoint.new(1, 1),
})

ShineGradient.Parent = HeaderShine

------------------------------------------------------------
-- HEADER BOTTOM LINE
------------------------------------------------------------

local HeaderLine = Instance.new("Frame")
HeaderLine.Name = "HeaderLine"
HeaderLine.AnchorPoint = Vector2.new(0.5, 1)
HeaderLine.Position = UDim2.new(0.5, 0, 1, 0)
HeaderLine.Size = UDim2.new(1, -24, 0, 1)
HeaderLine.BackgroundColor3 = Colors.Accent
HeaderLine.BackgroundTransparency = 0.55
HeaderLine.BorderSizePixel = 0
HeaderLine.ZIndex = 15
HeaderLine.Parent = Header

------------------------------------------------------------
-- LOGO
------------------------------------------------------------

local LogoGlow = Instance.new("Frame")
LogoGlow.Name = "LogoGlow"
LogoGlow.Position = UDim2.fromOffset(18, 15)
LogoGlow.Size = UDim2.fromOffset(52, 52)
LogoGlow.BackgroundColor3 = Colors.Accent
LogoGlow.BackgroundTransparency = 0.84
LogoGlow.BorderSizePixel = 0
LogoGlow.ZIndex = 12
LogoGlow.Parent = Header

AddCorner(LogoGlow, 16)

local LogoHolder = Instance.new("Frame")
LogoHolder.Name = "LogoHolder"
LogoHolder.Position = UDim2.fromOffset(22, 19)
LogoHolder.Size = UDim2.fromOffset(44, 44)
LogoHolder.BackgroundColor3 = Colors.Panel3
LogoHolder.BorderSizePixel = 0
LogoHolder.ZIndex = 14
LogoHolder.Parent = Header

AddCorner(LogoHolder, 14)
AddStroke(LogoHolder, Colors.Accent, 0.25, 1)

local LogoGradient = AddGradient(
	LogoHolder,
	Colors.Accent,
	Colors.Accent2,
	45
)

local LogoText = Instance.new("TextLabel")
LogoText.Name = "Logo"
LogoText.Size = UDim2.fromScale(1, 1)
LogoText.BackgroundTransparency = 1
LogoText.Text = "V"
LogoText.TextColor3 = Colors.White
LogoText.TextSize = 25
LogoText.Font = Enum.Font.GothamBlack
LogoText.ZIndex = 15
LogoText.Parent = LogoHolder

------------------------------------------------------------
-- TITLE
------------------------------------------------------------

local Title = Instance.new("TextLabel")
Title.Name = "Title"
Title.Position = UDim2.fromOffset(82, 17)
Title.Size = UDim2.fromOffset(280, 27)
Title.BackgroundTransparency = 1
Title.Text = "VANZ"
Title.TextColor3 = Colors.Text
Title.TextSize = 22
Title.Font = Enum.Font.GothamBold
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.ZIndex = 15
Title.Parent = Header

local Subtitle = Instance.new("TextLabel")
Subtitle.Name = "Subtitle"
Subtitle.Position = UDim2.fromOffset(83, 43)
Subtitle.Size = UDim2.fromOffset(320, 18)
Subtitle.BackgroundTransparency = 1
Subtitle.Text = "PREMIUM CONTROL CENTER"
Subtitle.TextColor3 = Colors.SubText
Subtitle.TextSize = 10
Subtitle.Font = Enum.Font.GothamMedium
Subtitle.TextXAlignment = Enum.TextXAlignment.Left
Subtitle.ZIndex = 15
Subtitle.Parent = Header

------------------------------------------------------------
-- ONLINE STATUS
------------------------------------------------------------

local StatusPill = Instance.new("Frame")
StatusPill.Name = "StatusPill"
StatusPill.AnchorPoint = Vector2.new(1, 0.5)
StatusPill.Position = UDim2.new(1, -62, 0.5, 0)
StatusPill.Size = UDim2.fromOffset(94, 28)
StatusPill.BackgroundColor3 = Colors.Panel3
StatusPill.BackgroundTransparency = 0.15
StatusPill.BorderSizePixel = 0
StatusPill.ZIndex = 15
StatusPill.Parent = Header

AddCorner(StatusPill, 14)
AddStroke(StatusPill, Colors.Success, 0.45, 1)

local StatusDot = Instance.new("Frame")
StatusDot.Name = "Dot"
StatusDot.Position = UDim2.fromOffset(10, 10)
StatusDot.Size = UDim2.fromOffset(8, 8)
StatusDot.BackgroundColor3 = Colors.Success
StatusDot.BorderSizePixel = 0
StatusDot.ZIndex = 16
StatusDot.Parent = StatusPill

AddCorner(StatusDot, 8)

local StatusText = Instance.new("TextLabel")
StatusText.Position = UDim2.fromOffset(24, 0)
StatusText.Size = UDim2.new(1, -28, 1, 0)
StatusText.BackgroundTransparency = 1
StatusText.Text = "ONLINE"
StatusText.TextColor3 = Colors.Success
StatusText.TextSize = 9
StatusText.Font = Enum.Font.GothamBold
StatusText.TextXAlignment = Enum.TextXAlignment.Left
StatusText.ZIndex = 16
StatusText.Parent = StatusPill

------------------------------------------------------------
-- MINIMIZE
------------------------------------------------------------

local Minimize = Instance.new("TextButton")
Minimize.Name = "Minimize"
Minimize.AnchorPoint = Vector2.new(1, 0.5)
Minimize.Position = UDim2.new(1, -20, 0.5, 0)
Minimize.Size = UDim2.fromOffset(28, 28)
Minimize.BackgroundColor3 = Colors.Panel3
Minimize.BackgroundTransparency = 0.15
Minimize.Text = "−"
Minimize.TextColor3 = Colors.SubText
Minimize.TextSize = 18
Minimize.Font = Enum.Font.GothamBold
Minimize.AutoButtonColor = false
Minimize.BorderSizePixel = 0
Minimize.ZIndex = 16
Minimize.Parent = Header

AddCorner(Minimize, 10)
AddStroke(Minimize, Colors.Stroke, 0.2, 1)

------------------------------------------------------------
-- CONTENT
------------------------------------------------------------

local Content = Instance.new("Frame")
Content.Name = "Content"
Content.Position = UDim2.fromOffset(0, 82)
Content.Size = UDim2.new(1, 0, 1, -82)
Content.BackgroundTransparency = 1
Content.BorderSizePixel = 0
Content.ZIndex = 7
Content.Parent = Main

------------------------------------------------------------
-- SIDEBAR
------------------------------------------------------------

local Sidebar = Instance.new("Frame")
Sidebar.Name = "Sidebar"
Sidebar.Position = UDim2.fromOffset(0, 0)
Sidebar.Size = UDim2.fromOffset(190, 1)
Sidebar.BackgroundColor3 = Colors.Sidebar
Sidebar.BackgroundTransparency = 0.02
Sidebar.BorderSizePixel = 0
Sidebar.ZIndex = 8
Sidebar.Parent = Content

local SidebarGradient = AddGradient(
	Sidebar,
	Colors.Sidebar,
	Colors.Background,
	90
)

------------------------------------------------------------
-- SIDEBAR TITLE
------------------------------------------------------------

local SidebarTitle = Instance.new("TextLabel")
SidebarTitle.Position = UDim2.fromOffset(20, 18)
SidebarTitle.Size = UDim2.new(1, -40, 0, 20)
SidebarTitle.BackgroundTransparency = 1
SidebarTitle.Text = "NAVIGATION"
SidebarTitle.TextColor3 = Colors.Muted
SidebarTitle.TextSize = 9
SidebarTitle.Font = Enum.Font.GothamBold
SidebarTitle.TextXAlignment = Enum.TextXAlignment.Left
SidebarTitle.ZIndex = 10
SidebarTitle.Parent = Sidebar

------------------------------------------------------------
-- SIDEBAR LINE
------------------------------------------------------------

local SidebarLine = Instance.new("Frame")
SidebarLine.Position = UDim2.fromOffset(20, 43)
SidebarLine.Size = UDim2.new(1, -40, 0, 1)
SidebarLine.BackgroundColor3 = Colors.Stroke
SidebarLine.BackgroundTransparency = 0.35
SidebarLine.BorderSizePixel = 0
SidebarLine.ZIndex = 10
SidebarLine.Parent = Sidebar

------------------------------------------------------------
-- TAB HOLDER
------------------------------------------------------------

local TabHolder = Instance.new("ScrollingFrame")
TabHolder.Name = "TabHolder"
TabHolder.Position = UDim2.fromOffset(10, 56)
TabHolder.Size = UDim2.new(1, -20, 1, -70)
TabHolder.BackgroundTransparency = 1
TabHolder.BorderSizePixel = 0
TabHolder.ScrollBarThickness = 0
TabHolder.CanvasSize = UDim2.new()
TabHolder.AutomaticCanvasSize = Enum.AutomaticSize.Y
TabHolder.ZIndex = 10
TabHolder.Parent = Sidebar

local TabLayout = Instance.new("UIListLayout")
TabLayout.Padding = UDim.new(0, 6)
TabLayout.SortOrder = Enum.SortOrder.LayoutOrder
TabLayout.Parent = TabHolder

------------------------------------------------------------
-- PAGES
------------------------------------------------------------

local Pages = Instance.new("Frame")
Pages.Name = "Pages"
Pages.Position = UDim2.fromOffset(190, 0)
Pages.Size = UDim2.new(1, -190, 1, 0)
Pages.BackgroundTransparency = 1
Pages.BorderSizePixel = 0
Pages.ZIndex = 8
Pages.Parent = Content

------------------------------------------------------------
-- PAGE PADDING
------------------------------------------------------------

local PagePadding = Instance.new("UIPadding")
PagePadding.PaddingLeft = UDim.new(0, 22)
PagePadding.PaddingRight = UDim.new(0, 22)
PagePadding.PaddingTop = UDim.new(0, 20)
PagePadding.PaddingBottom = UDim.new(0, 20)
PagePadding.Parent = Pages

------------------------------------------------------------
-- FLOATING LOGO
------------------------------------------------------------

local FloatingGlow = Instance.new("Frame")
FloatingGlow.Name = "FloatingGlow"
FloatingGlow.AnchorPoint = Vector2.new(1, 1)
FloatingGlow.Position = UDim2.new(1, -24, 1, -24)
FloatingGlow.Size = UDim2.fromOffset(78, 78)
FloatingGlow.BackgroundColor3 = Colors.Accent
FloatingGlow.BackgroundTransparency = 0.82
FloatingGlow.BorderSizePixel = 0
FloatingGlow.ZIndex = 40
FloatingGlow.Parent = ScreenGui

AddCorner(FloatingGlow, 24)

local FloatingButton = Instance.new("TextButton")
FloatingButton.Name = "FloatingV"
FloatingButton.AnchorPoint = Vector2.new(1, 1)
FloatingButton.Position = UDim2.new(1, -32, 1, -32)
FloatingButton.Size = UDim2.fromOffset(62, 62)
FloatingButton.BackgroundColor3 = Colors.Panel2
FloatingButton.BorderSizePixel = 0
FloatingButton.Text = "V"
FloatingButton.TextColor3 = Colors.White
FloatingButton.TextSize = 26
FloatingButton.Font = Enum.Font.GothamBlack
FloatingButton.AutoButtonColor = false
FloatingButton.ZIndex = 41
FloatingButton.Parent = ScreenGui

AddCorner(FloatingButton, 20)
AddStroke(FloatingButton, Colors.Accent, 0.2, 1.5)

local FloatingGradient = AddGradient(
	FloatingButton,
	Colors.Accent,
	Colors.Accent2,
	45
)

------------------------------------------------------------
-- RESPONSIVE
------------------------------------------------------------

local function UpdateResponsive()
	local camera = workspace.CurrentCamera

	if not camera then
		return
	end

	local viewport = camera.ViewportSize

	local width = 780
	local height = 500

	-- Keep comfortable margins.
	local maxWidth = viewport.X - 44
	local maxHeight = viewport.Y - 44

	if width > maxWidth then
		width = maxWidth
	end

	if height > maxHeight then
		height = maxHeight
	end

	width = math.max(width, 620)
	height = math.max(height, 400)

	MainHolder.Size = UDim2.fromOffset(width, height)
end

UpdateResponsive()

table.insert(
	_G.vanz.Connections,
	workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
		task.defer(UpdateResponsive)
	end)
)

if workspace.CurrentCamera then
	table.insert(
		_G.vanz.Connections,
		workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(
			UpdateResponsive
		)
	)
end

------------------------------------------------------------
-- DRAG SYSTEM
------------------------------------------------------------

local dragging = false
local dragStart
local startPosition

local function UpdateDrag(input)
	local delta = input.Position - dragStart

	MainHolder.Position = UDim2.new(
		startPosition.X.Scale,
		startPosition.X.Offset + delta.X,
		startPosition.Y.Scale,
		startPosition.Y.Offset + delta.Y
	)
end

Header.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1
		or input.UserInputType == Enum.UserInputType.Touch then

		dragging = true
		dragStart = input.Position
		startPosition = MainHolder.Position

		input.Changed:Connect(function()
			if input.UserInputState == Enum.UserInputState.End then
				dragging = false
			end
		end)
	end
end)

Header.InputChanged:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseMovement
		or input.UserInputType == Enum.UserInputType.Touch then

		dragInput = input
	end
end)

table.insert(
	_G.vanz.Connections,
	UserInputService.InputChanged:Connect(function(input)
		if dragging then
			if input.UserInputType == Enum.UserInputType.MouseMovement
				or input.UserInputType == Enum.UserInputType.Touch then

				UpdateDrag(input)
			end
		end
	end)
)

------------------------------------------------------------
-- MINIMIZE SYSTEM
------------------------------------------------------------

local minimized = false
local savedPosition = MainHolder.Position
local savedSize = MainHolder.Size

local function SetMinimized(state)
	minimized = state

	if state then
		savedPosition = MainHolder.Position
		savedSize = MainHolder.Size

		HeaderLine.BackgroundTransparency = 1

		Tween(
			MainHolder,
			TweenInfo.new(
				0.34,
				Enum.EasingStyle.Quint,
				Enum.EasingDirection.In
			),
			{
				Size = UDim2.fromOffset(70, 70),
			}
		)

		Tween(
			Main,
			TweenInfo.new(
				0.22,
				Enum.EasingStyle.Quint,
				Enum.EasingDirection.In
			),
			{
				BackgroundTransparency = 1,
			}
		)

		Tween(
			GlowOuter,
			TweenInfo.new(0.2),
			{
				BackgroundTransparency = 1,
			}
		)

		Tween(
			GlowMiddle,
			TweenInfo.new(0.2),
			{
				BackgroundTransparency = 1,
			}
		)

		task.delay(0.22, function()
			if minimized then
				Main.Visible = false
			end
		end)

	else
		Main.Visible = true

		MainHolder.Size = UDim2.fromOffset(70, 70)

		GlowOuter.BackgroundTransparency = 1
		GlowMiddle.BackgroundTransparency = 1

		Tween(
			MainHolder,
			TweenInfo.new(
				0.42,
				Enum.EasingStyle.Back,
				Enum.EasingDirection.Out
			),
			{
				Size = savedSize,
			}
		)

		Tween(
			Main,
			TweenInfo.new(
				0.3,
				Enum.EasingStyle.Quint,
				Enum.EasingDirection.Out
			),
			{
				BackgroundTransparency = 0.03,
			}
		)

		Tween(
			GlowOuter,
			TweenInfo.new(0.35),
			{
				BackgroundTransparency = 0.91,
			}
		)

		Tween(
			GlowMiddle,
			TweenInfo.new(0.35),
			{
				BackgroundTransparency = 0.93,
			}
		)
	end
end

Minimize.MouseEnter:Connect(function()
	FastTween(Minimize, {
		BackgroundColor3 = Colors.Accent,
		TextColor3 = Colors.White,
	})
end)

Minimize.MouseLeave:Connect(function()
	FastTween(Minimize, {
		BackgroundColor3 = Colors.Panel3,
		TextColor3 = Colors.SubText,
	})
end)

Minimize.MouseButton1Click:Connect(function()
	SetMinimized(not minimized)
end)

FloatingButton.MouseButton1Click:Connect(function()
	if minimized then
		SetMinimized(false)
	end
end)

------------------------------------------------------------
-- COMPONENT SYSTEM
------------------------------------------------------------

local function CreatePage(name)
	local page = Instance.new("ScrollingFrame")
	page.Name = name
	page.Size = UDim2.fromScale(1, 1)
	page.BackgroundTransparency = 1
	page.BorderSizePixel = 0
	page.ScrollBarThickness = 3
	page.ScrollBarImageColor3 = Colors.Accent
	page.ScrollBarImageTransparency = 0.45
	page.CanvasSize = UDim2.new()
	page.AutomaticCanvasSize = Enum.AutomaticSize.Y
	page.Visible = false
	page.ZIndex = 9
	page.Parent = Pages

	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 12)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = page

	return page
end

------------------------------------------------------------
-- PREMIUM SECTION
------------------------------------------------------------

local function CreateSection(parent, title)
	local section = Instance.new("Frame")
	section.Name = "Section"
	section.Size = UDim2.new(1, 0, 0, 40)
	section.BackgroundTransparency = 1
	section.BorderSizePixel = 0
	section.ZIndex = 10
	section.Parent = parent

	local accent = Instance.new("Frame")
	accent.Position = UDim2.fromOffset(0, 13)
	accent.Size = UDim2.fromOffset(3, 16)
	accent.BackgroundColor3 = Colors.Accent
	accent.BorderSizePixel = 0
	accent.ZIndex = 11
	accent.Parent = section

	AddCorner(accent, 3)

	local label = Instance.new("TextLabel")
	label.Position = UDim2.fromOffset(12, 8)
	label.Size = UDim2.new(1, -12, 0, 25)
	label.BackgroundTransparency = 1
	label.Text = title
	label.TextColor3 = Colors.Text
	label.TextSize = 13
	label.Font = Enum.Font.GothamBold
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.ZIndex = 11
	label.Parent = section

	local line = Instance.new("Frame")
	line.Position = UDim2.fromOffset(12, 33)
	line.Size = UDim2.new(1, -12, 0, 1)
	line.BackgroundColor3 = Colors.Stroke
	line.BackgroundTransparency = 0.6
	line.BorderSizePixel = 0
	line.ZIndex = 10
	line.Parent = section

	return section
end

------------------------------------------------------------
-- PREMIUM INFO
------------------------------------------------------------

local function CreateInfo(parent, title, description)
	local card = Instance.new("Frame")
	card.Name = "Info"
	card.Size = UDim2.new(1, 0, 0, 72)
	card.BackgroundColor3 = Colors.Panel
	card.BackgroundTransparency = 0.05
	card.BorderSizePixel = 0
	card.ZIndex = 10
	card.Parent = parent

	AddCorner(card, 14)
	AddStroke(card, Colors.Stroke, 0.35, 1)

	local bar = Instance.new("Frame")
	bar.Position = UDim2.fromOffset(0, 0)
	bar.Size = UDim2.fromOffset(3, 72)
	bar.BackgroundColor3 = Colors.Accent
	bar.BorderSizePixel = 0
	bar.ZIndex = 11
	bar.Parent = card

	AddCorner(bar, 3)

	local titleLabel = Instance.new("TextLabel")
	titleLabel.Position = UDim2.fromOffset(18, 12)
	titleLabel.Size = UDim2.new(1, -30, 0, 20)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Text = title
	titleLabel.TextColor3 = Colors.Text
	titleLabel.TextSize = 12
	titleLabel.Font = Enum.Font.GothamBold
	titleLabel.TextXAlignment = Enum.TextXAlignment.Left
	titleLabel.ZIndex = 12
	titleLabel.Parent = card

	local descLabel = Instance.new("TextLabel")
	descLabel.Position = UDim2.fromOffset(18, 34)
	descLabel.Size = UDim2.new(1, -30, 0, 28)
	descLabel.BackgroundTransparency = 1
	descLabel.Text = description
	descLabel.TextColor3 = Colors.SubText
	descLabel.TextSize = 10
	descLabel.Font = Enum.Font.Gotham
	descLabel.TextWrapped = true
	descLabel.TextXAlignment = Enum.TextXAlignment.Left
	descLabel.ZIndex = 12
	descLabel.Parent = card

	return card
end

------------------------------------------------------------
-- PREMIUM BUTTON
------------------------------------------------------------

local function CreateButton(parent, title, callback)
	local button = Instance.new("TextButton")
	button.Name = "Button"
	button.Size = UDim2.new(1, 0, 0, 56)
	button.BackgroundColor3 = Colors.Panel
	button.BackgroundTransparency = 0.02
	button.BorderSizePixel = 0
	button.AutoButtonColor = false
	button.Text = ""
	button.ZIndex = 10
	button.Parent = parent

	AddCorner(button, 14)

	local stroke = AddStroke(
		button,
		Colors.Stroke,
		0.28,
		1
	)

	local icon = Instance.new("Frame")
	icon.Position = UDim2.fromOffset(12, 12)
	icon.Size = UDim2.fromOffset(32, 32)
	icon.BackgroundColor3 = Colors.Panel3
	icon.BorderSizePixel = 0
	icon.ZIndex = 11
	icon.Parent = button

	AddCorner(icon, 10)

	local iconGradient = AddGradient(
		icon,
		Colors.Accent,
		Colors.Accent2,
		45
	)

	local arrow = Instance.new("TextLabel")
	arrow.Size = UDim2.fromScale(1, 1)
	arrow.BackgroundTransparency = 1
	arrow.Text = ">"
	arrow.TextColor3 = Colors.White
	arrow.TextSize = 15
	arrow.Font = Enum.Font.GothamBold
	arrow.ZIndex = 12
	arrow.Parent = icon

	local label = Instance.new("TextLabel")
	label.Position = UDim2.fromOffset(58, 0)
	label.Size = UDim2.new(1, -75, 1, 0)
	label.BackgroundTransparency = 1
	label.Text = title
	label.TextColor3 = Colors.Text
	label.TextSize = 11
	label.Font = Enum.Font.GothamSemibold
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.ZIndex = 11
	label.Parent = button

	button.MouseEnter:Connect(function()
		PremiumTween(button, {
			BackgroundColor3 = Colors.Panel2,
		})

		PremiumTween(stroke, {
			Color = Colors.Accent,
			Transparency = 0.18,
		})

		PremiumTween(icon, {
			Size = UDim2.fromOffset(35, 35),
		})

		PremiumTween(arrow, {
			TextColor3 = Colors.White,
		})
	end)

	button.MouseLeave:Connect(function()
		PremiumTween(button, {
			BackgroundColor3 = Colors.Panel,
		})

		PremiumTween(stroke, {
			Color = Colors.Stroke,
			Transparency = 0.28,
		})

		PremiumTween(icon, {
			Size = UDim2.fromOffset(32, 32),
		})
	end)

	button.MouseButton1Down:Connect(function()
		PremiumTween(button, {
			Size = UDim2.new(1, -4, 0, 54),
		})
	end)

	button.MouseButton1Up:Connect(function()
		PremiumTween(button, {
			Size = UDim2.new(1, 0, 0, 56),
		})

		if callback then
			task.spawn(function()
				pcall(callback)
			end)
		end
	end)

	return button
end

------------------------------------------------------------
-- PREMIUM TOGGLE
------------------------------------------------------------

local function CreateToggle(parent, title, description, default, callback)

	local enabled = default == true

	local card = Instance.new("Frame")
	card.Name = "PremiumToggle"
	card.Size = UDim2.new(1, 0, 0, 76)
	card.BackgroundColor3 = Colors.Panel
	card.BackgroundTransparency = 0.02
	card.BorderSizePixel = 0
	card.ZIndex = 10
	card.Parent = parent

	AddCorner(card, 15)

	local cardStroke = AddStroke(
		card,
		Colors.Stroke,
		0.28,
		1
	)

	--------------------------------------------------------
	-- LEFT ACCENT
	--------------------------------------------------------

	local accent = Instance.new("Frame")
	accent.Name = "Accent"
	accent.Position = UDim2.fromOffset(0, 12)
	accent.Size = UDim2.fromOffset(3, 52)
	accent.BackgroundColor3 = enabled and Colors.Accent or Colors.Muted
	accent.BorderSizePixel = 0
	accent.ZIndex = 11
	accent.Parent = card

	AddCorner(accent, 3)

	--------------------------------------------------------
	-- TITLE
	--------------------------------------------------------

	local titleLabel = Instance.new("TextLabel")
	titleLabel.Position = UDim2.fromOffset(18, 13)
	titleLabel.Size = UDim2.new(1, -155, 0, 21)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Text = title
	titleLabel.TextColor3 = Colors.Text
	titleLabel.TextSize = 12
	titleLabel.Font = Enum.Font.GothamBold
	titleLabel.TextXAlignment = Enum.TextXAlignment.Left
	titleLabel.ZIndex = 12
	titleLabel.Parent = card

	--------------------------------------------------------
	-- DESCRIPTION
	--------------------------------------------------------

	local descLabel = Instance.new("TextLabel")
	descLabel.Position = UDim2.fromOffset(18, 35)
	descLabel.Size = UDim2.new(1, -165, 0, 27)
	descLabel.BackgroundTransparency = 1
	descLabel.Text = description or ""
	descLabel.TextColor3 = Colors.SubText
	descLabel.TextSize = 9
	descLabel.Font = Enum.Font.Gotham
	descLabel.TextWrapped = true
	descLabel.TextXAlignment = Enum.TextXAlignment.Left
	descLabel.ZIndex = 12
	descLabel.Parent = card

	--------------------------------------------------------
	-- STATUS TEXT
	--------------------------------------------------------

	local status = Instance.new("TextLabel")
	status.Name = "Status"
	status.AnchorPoint = Vector2.new(1, 0.5)
	status.Position = UDim2.new(1, -75, 0.5, 0)
	status.Size = UDim2.fromOffset(34, 18)
	status.BackgroundTransparency = 1
	status.Text = enabled and "ON" or "OFF"
	status.TextColor3 = enabled and Colors.Accent or Colors.Muted
	status.TextSize = 8
	status.Font = Enum.Font.GothamBold
	status.TextXAlignment = Enum.TextXAlignment.Right
	status.ZIndex = 13
	status.Parent = card

	--------------------------------------------------------
	-- SWITCH GLOW
	--------------------------------------------------------

	local switchGlow = Instance.new("Frame")
	switchGlow.Name = "SwitchGlow"
	switchGlow.AnchorPoint = Vector2.new(1, 0.5)
	switchGlow.Position = UDim2.new(1, -14, 0.5, 0)
	switchGlow.Size = UDim2.fromOffset(56, 32)
	switchGlow.BackgroundColor3 = enabled and Colors.Accent or Colors.Muted
	switchGlow.BackgroundTransparency = enabled and 0.78 or 1
	switchGlow.BorderSizePixel = 0
	switchGlow.ZIndex = 11
	switchGlow.Parent = card

	AddCorner(switchGlow, 16)

	--------------------------------------------------------
	-- SWITCH
	--------------------------------------------------------

	local switch = Instance.new("TextButton")
	switch.Name = "Switch"
	switch.AnchorPoint = Vector2.new(1, 0.5)
	switch.Position = UDim2.new(1, -16, 0.5, 0)
	switch.Size = UDim2.fromOffset(54, 30)
	switch.BackgroundColor3 = enabled and Colors.Accent or Colors.Panel3
	switch.BorderSizePixel = 0
	switch.Text = ""
	switch.AutoButtonColor = false
	switch.ZIndex = 14
	switch.Parent = card

	AddCorner(switch, 15)

	local switchStroke = AddStroke(
		switch,
		enabled and Colors.Accent or Colors.Stroke,
		enabled and 0.15 or 0.2,
		1
	)

	--------------------------------------------------------
	-- KNOB
	--------------------------------------------------------

	local knob = Instance.new("Frame")
	knob.Name = "Knob"
	knob.AnchorPoint = Vector2.new(0.5, 0.5)
	knob.Position = enabled
		and UDim2.new(1, -15, 0.5, 0)
		or UDim2.new(0, 15, 0.5, 0)
	knob.Size = UDim2.fromOffset(22, 22)
	knob.BackgroundColor3 = Colors.White
	knob.BorderSizePixel = 0
	knob.ZIndex = 15
	knob.Parent = switch

	AddCorner(knob, 11)

	local knobStroke = AddStroke(
		knob,
		enabled and Colors.Accent or Colors.Stroke,
		0.25,
		1
	)

	--------------------------------------------------------
	-- SET STATE
	--------------------------------------------------------

	local function UpdateState(newState, instant)

		enabled = newState

		local tweenInfo

		if instant then
			tweenInfo = TweenInfo.new(0)
		else
			tweenInfo = TweenInfo.new(
				0.3,
				Enum.EasingStyle.Quint,
				Enum.EasingDirection.Out
			)
		end

		Tween(
			switch,
			tweenInfo,
			{
				BackgroundColor3 =
					enabled
					and Colors.Accent
					or Colors.Panel3
			}
		)

		Tween(
			switchStroke,
			tweenInfo,
			{
				Color =
					enabled
					and Colors.Accent
					or Colors.Stroke,

				Transparency =
					enabled
					and 0.12
					or 0.2
			}
		)

		Tween(
			knob,
			tweenInfo,
			{
				Position =
					enabled
					and UDim2.new(1, -15, 0.5, 0)
					or UDim2.new(0, 15, 0.5, 0)
			}
		)

		Tween(
			knobStroke,
			tweenInfo,
			{
				Color =
					enabled
					and Colors.Accent
					or Colors.Stroke
			}
		)

		Tween(
			switchGlow,
			tweenInfo,
			{
				BackgroundColor3 =
					enabled
					and Colors.Accent
					or Colors.Muted,

				BackgroundTransparency =
					enabled
					and 0.76
					or 1
			}
		)

		Tween(
			accent,
			tweenInfo,
			{
				BackgroundColor3 =
					enabled
					and Colors.Accent
					or Colors.Muted
			}
		)

		Tween(
			status,
			tweenInfo,
			{
				TextColor3 =
					enabled
					and Colors.Accent
					or Colors.Muted
			}
		)

		status.Text = enabled and "ON" or "OFF"

		Tween(
			cardStroke,
			tweenInfo,
			{
				Color =
					enabled
					and Colors.Accent
					or Colors.Stroke,

				Transparency =
					enabled
					and 0.25
					or 0.28
			}
		)

		if callback then
			task.spawn(function()
				pcall(callback, enabled)
			end)
		end
	end

	--------------------------------------------------------
	-- HOVER
	--------------------------------------------------------

	card.MouseEnter:Connect(function()
		PremiumTween(card, {
			BackgroundColor3 = Colors.Panel2,
		})

		PremiumTween(cardStroke, {
			Color = enabled and Colors.Accent or Colors.Stroke,
			Transparency = enabled and 0.12 or 0.18,
		})

		PremiumTween(switchGlow, {
			BackgroundTransparency = enabled and 0.68 or 0.94,
		})
	end)

	card.MouseLeave:Connect(function()
		PremiumTween(card, {
			BackgroundColor3 = Colors.Panel,
		})

		PremiumTween(cardStroke, {
			Transparency = enabled and 0.25 or 0.28,
		})

		PremiumTween(switchGlow, {
			BackgroundTransparency = enabled and 0.76 or 1,
		})
	end)

	switch.MouseButton1Click:Connect(function()
		UpdateState(not enabled)
	end)

	return {
		Set = function(value)
			UpdateState(value)
		end,

		Get = function()
			return enabled
		end,

		Frame = card,
	}
end

------------------------------------------------------------
-- TAB SYSTEM
------------------------------------------------------------

local currentTab

local function CreateTab(name, icon)

	local page = CreatePage(name)

	local button = Instance.new("TextButton")
	button.Name = name
	button.Size = UDim2.new(1, 0, 0, 46)
	button.BackgroundColor3 = Colors.Panel
	button.BackgroundTransparency = 1
	button.BorderSizePixel = 0
	button.Text = ""
	button.AutoButtonColor = false
	button.ZIndex = 11
	button.Parent = TabHolder

	AddCorner(button, 12)

	--------------------------------------------------------
	-- ACTIVE BACKGROUND
	--------------------------------------------------------

	local activeBackground = Instance.new("Frame")
	activeBackground.Name = "ActiveBackground"
	activeBackground.Size = UDim2.fromScale(1, 1)
	activeBackground.BackgroundColor3 = Colors.Accent
	activeBackground.BackgroundTransparency = 0.9
	activeBackground.BorderSizePixel = 0
	activeBackground.Visible = false
	activeBackground.ZIndex = 11
	activeBackground.Parent = button

	AddCorner(activeBackground, 12)

	--------------------------------------------------------
	-- ACTIVE GLOW
	--------------------------------------------------------

	local activeGlow = Instance.new("Frame")
	activeGlow.Name = "Glow"
	activeGlow.Size = UDim2.new(1, 8, 1, 8)
	activeGlow.Position = UDim2.fromOffset(-4, -4)
	activeGlow.BackgroundColor3 = Colors.Accent
	activeGlow.BackgroundTransparency = 0.94
	activeGlow.BorderSizePixel = 0
	activeGlow.Visible = false
	activeGlow.ZIndex = 10
	activeGlow.Parent = button

	AddCorner(activeGlow, 15)

	--------------------------------------------------------
	-- ACTIVE BAR
	--------------------------------------------------------

	local activeBar = Instance.new("Frame")
	activeBar.Name = "ActiveBar"
	activeBar.AnchorPoint = Vector2.new(0, 0.5)
	activeBar.Position = UDim2.new(0, 0, 0.5, 0)
	activeBar.Size = UDim2.fromOffset(3, 0)
	activeBar.BackgroundColor3 = Colors.Accent
	activeBar.BorderSizePixel = 0
	activeBar.ZIndex = 13
	activeBar.Parent = button

	AddCorner(activeBar, 3)

	--------------------------------------------------------
	-- ICON
	--------------------------------------------------------

	local iconBox = Instance.new("Frame")
	iconBox.Position = UDim2.fromOffset(8, 7)
	iconBox.Size = UDim2.fromOffset(32, 32)
	iconBox.BackgroundColor3 = Colors.Panel3
	iconBox.BackgroundTransparency = 0.2
	iconBox.BorderSizePixel = 0
	iconBox.ZIndex = 13
	iconBox.Parent = button

	AddCorner(iconBox, 9)

	local iconLabel = Instance.new("TextLabel")
	iconLabel.Size = UDim2.fromScale(1, 1)
	iconLabel.BackgroundTransparency = 1
	iconLabel.Text = icon or "•"
	iconLabel.TextColor3 = Colors.SubText
	iconLabel.TextSize = 13
	iconLabel.Font = Enum.Font.GothamBold
	iconLabel.ZIndex = 14
	iconLabel.Parent = iconBox

	--------------------------------------------------------
	-- LABEL
	--------------------------------------------------------

	local label = Instance.new("TextLabel")
	label.Position = UDim2.fromOffset(50, 0)
	label.Size = UDim2.new(1, -58, 1, 0)
	label.BackgroundTransparency = 1
	label.Text = name
	label.TextColor3 = Colors.SubText
	label.TextSize = 10
	label.Font = Enum.Font.GothamSemibold
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.ZIndex = 13
	label.Parent = button

	--------------------------------------------------------
	-- SET ACTIVE
	--------------------------------------------------------

	local function SetActive(state)

		activeBackground.Visible = state
		activeGlow.Visible = state

		PremiumTween(activeBackground, {
			BackgroundTransparency = state and 0.87 or 1,
		})

		PremiumTween(activeGlow, {
			BackgroundTransparency = state and 0.91 or 1,
		})

		PremiumTween(activeBar, {
			Size = state
				and UDim2.fromOffset(3, 26)
				or UDim2.fromOffset(3, 0),
		})

		PremiumTween(iconBox, {
			BackgroundColor3 =
				state
				and Colors.Accent
				or Colors.Panel3,
		})

		PremiumTween(iconLabel, {
			TextColor3 =
				state
				and Colors.White
				or Colors.SubText,
		})

		PremiumTween(label, {
			TextColor3 =
				state
				and Colors.Text
				or Colors.SubText,
		})
	end

	button.MouseEnter:Connect(function()

		if currentTab ~= page then
			PremiumTween(button, {
				BackgroundTransparency = 0.82,
			})

			PremiumTween(label, {
				TextColor3 = Colors.Text,
			})

			PremiumTween(iconBox, {
				BackgroundColor3 = Colors.Panel2,
			})
		end
	end)

	button.MouseLeave:Connect(function()

		if currentTab ~= page then
			PremiumTween(button, {
				BackgroundTransparency = 1,
			})

			PremiumTween(label, {
				TextColor3 = Colors.SubText,
			})

			PremiumTween(iconBox, {
				BackgroundColor3 = Colors.Panel3,
			})
		end
	end)

	button.MouseButton1Click:Connect(function()

		for _, tab in pairs(_G.vanz.Tabs) do
			if tab.Page then
				tab.Page.Visible = false
			end

			if tab.SetActive then
				tab.SetActive(false)
			end
		end

		page.Visible = true
		currentTab = page

		SetActive(true)
	end)

	local tabObject = {
		Button = button,
		Page = page,
		SetActive = SetActive,
	}

	table.insert(_G.vanz.Tabs, tabObject)

	return page
end

------------------------------------------------------------
-- CREATE TABS
------------------------------------------------------------

local Home = CreateTab("Home", "⌂")
local PlayerTab = CreateTab("Player", "P")
local Visual = CreateTab("Visual", "V")
local World = CreateTab("World", "W")
local Misc = CreateTab("Misc", "M")
local Extra = CreateTab("Extra", "E")
local Settings = CreateTab("Settings", "⚙")

------------------------------------------------------------
-- HOME
------------------------------------------------------------

CreateSection(Home, "WELCOME")

CreateInfo(
	Home,
	"VANZ PREMIUM",
	"Welcome to the premium control center. Everything is designed with a clean, wide and responsive interface."
)

CreateSection(Home, "SYSTEM")

CreateInfo(
	Home,
	"Interface Status",
	"Premium UI engine is active and ready."
)

CreateButton(
	Home,
	"Refresh Interface",
	function()
		UpdateResponsive()
	end
)

CreateToggle(
	Home,
	"Premium Animations",
	"Enable visual animations throughout the interface.",
	true,
	function(state)
		_G.vanz.Config.Animations = state
	end
)

CreateToggle(
	Home,
	"Dynamic Accent",
	"Enable animated accent colors and glow effects.",
	true,
	function(state)
		_G.vanz.Config.DynamicColors = state
	end
)

------------------------------------------------------------
-- PLAYER
------------------------------------------------------------

CreateSection(PlayerTab, "PLAYER")

CreateInfo(
	PlayerTab,
	"Player Controls",
	"Player-related modules can be connected here without changing the GUI system."
)

CreateToggle(
	PlayerTab,
	"Example Toggle",
	"Example premium toggle component.",
	false,
	function(state)
		print("Example Toggle:", state)
	end
)

CreateButton(
	PlayerTab,
	"Example Action",
	function()
		print("Example Action")
	end
)

------------------------------------------------------------
-- VISUAL
------------------------------------------------------------

CreateSection(Visual, "VISUAL")

CreateInfo(
	Visual,
	"Visual Controls",
	"Visual modules can be added into this page."
)

CreateToggle(
	Visual,
	"Visual Mode",
	"Example visual switch.",
	true,
	function(state)
		print("Visual Mode:", state)
	end
)

CreateToggle(
	Visual,
	"Glow Effects",
	"Control premium interface glow effects.",
	true,
	function(state)
		_G.vanz.Config.Glow = state
	end
)

------------------------------------------------------------
-- WORLD
------------------------------------------------------------

CreateSection(World, "WORLD")

CreateInfo(
	World,
	"World Controls",
	"World-related modules can be connected here."
)

CreateToggle(
	World,
	"World Module",
	"Example world toggle.",
	false,
	function(state)
		print("World Module:", state)
	end
)

------------------------------------------------------------
-- MISC
------------------------------------------------------------

CreateSection(Misc, "MISC")

CreateInfo(
	Misc,
	"Miscellaneous",
	"Additional modules and utilities can be placed here."
)

CreateButton(
	Misc,
	"Example Utility",
	function()
		print("Utility clicked")
	end
)

CreateToggle(
	Misc,
	"Utility Toggle",
	"Example utility state.",
	false,
	function(state)
		print("Utility Toggle:", state)
	end
)

------------------------------------------------------------
-- EXTRA
------------------------------------------------------------

CreateSection(Extra, "EXTRA")

CreateInfo(
	Extra,
	"Premium Extras",
	"Extra interface features and experimental modules."
)

CreateToggle(
	Extra,
	"Floating Button",
	"Show or hide the floating VANZ button.",
	true,
	function(state)
		FloatingButton.Visible = state
		FloatingGlow.Visible = state
	end
)

CreateToggle(
	Extra,
	"Ambient Glow",
	"Enable the background ambient glow.",
	true,
	function(state)
		AmbientLeft.Visible = state
		AmbientRight.Visible = state
	end
)

------------------------------------------------------------
-- SETTINGS
------------------------------------------------------------

CreateSection(Settings, "INTERFACE")

CreateInfo(
	Settings,
	"Display",
	"Default interface scale is 100%. The UI automatically adapts to your screen."
)

local dpiCard = Instance.new("Frame")
dpiCard.Name = "DPI"
dpiCard.Size = UDim2.new(1, 0, 0, 118)
dpiCard.BackgroundColor3 = Colors.Panel
dpiCard.BorderSizePixel = 0
dpiCard.ZIndex = 10
dpiCard.Parent = Settings

AddCorner(dpiCard, 15)
AddStroke(dpiCard, Colors.Stroke, 0.3, 1)

local dpiTitle = Instance.new("TextLabel")
dpiTitle.Position = UDim2.fromOffset(16, 12)
dpiTitle.Size = UDim2.new(1, -32, 0, 20)
dpiTitle.BackgroundTransparency = 1
dpiTitle.Text = "UI SCALE"
dpiTitle.TextColor3 = Colors.Text
dpiTitle.TextSize = 11
dpiTitle.Font = Enum.Font.GothamBold
dpiTitle.TextXAlignment = Enum.TextXAlignment.Left
dpiTitle.ZIndex = 11
dpiTitle.Parent = dpiCard

local dpiButtons = Instance.new("Frame")
dpiButtons.Position = UDim2.fromOffset(14, 42)
dpiButtons.Size = UDim2.new(1, -28, 0, 58)
dpiButtons.BackgroundTransparency = 1
dpiButtons.ZIndex = 11
dpiButtons.Parent = dpiCard

local dpiLayout = Instance.new("UIGridLayout")
dpiLayout.CellPadding = UDim2.fromOffset(7, 7)
dpiLayout.CellSize = UDim2.new(1 / 6, -6, 0, 50)
dpiLayout.FillDirection = Enum.FillDirection.Horizontal
dpiLayout.SortOrder = Enum.SortOrder.LayoutOrder
dpiLayout.Parent = dpiButtons

local dpiOptions = {
	0.70,
	0.80,
	0.90,
	1.00,
	1.10,
	1.20,
}

local dpiButtonsList = {}

local function ApplyDPI(scale)

	_G.vanz.Config.Scale = scale

	PremiumTween(UIScale, {
		Scale = scale,
	})

	for value, button in pairs(dpiButtonsList) do

		local active = math.abs(value - scale) < 0.001

		PremiumTween(button, {
			BackgroundColor3 =
				active
				and Colors.Accent
				or Colors.Panel3,
		})

		PremiumTween(button, {
			TextColor3 =
				active
				and Colors.White
				or Colors.SubText,
		})
	end
end

for _, scale in ipairs(dpiOptions) do

	local dpiButton = Instance.new("TextButton")
	dpiButton.Name = tostring(scale)
	dpiButton.BackgroundColor3 =
		math.abs(scale - 1.00) < 0.001
		and Colors.Accent
		or Colors.Panel3

	dpiButton.BorderSizePixel = 0
	dpiButton.Text = tostring(math.floor(scale * 100)) .. "%"
	dpiButton.TextColor3 =
		math.abs(scale - 1.00) < 0.001
		and Colors.White
		or Colors.SubText

	dpiButton.TextSize = 9
	dpiButton.Font = Enum.Font.GothamBold
	dpiButton.AutoButtonColor = false
	dpiButton.ZIndex = 12
	dpiButton.Parent = dpiButtons

	AddCorner(dpiButton, 10)
	AddStroke(dpiButton, Colors.Stroke, 0.3, 1)

	dpiButtonsList[scale] = dpiButton

	dpiButton.MouseEnter:Connect(function()
		if math.abs(_G.vanz.Config.Scale - scale) > 0.001 then
			PremiumTween(dpiButton, {
				BackgroundColor3 = Colors.Panel2,
			})
		end
	end)

	dpiButton.MouseLeave:Connect(function()
		local active =
			math.abs(_G.vanz.Config.Scale - scale) < 0.001

		PremiumTween(dpiButton, {
			BackgroundColor3 =
				active
				and Colors.Accent
				or Colors.Panel3,
		})
	end)

	dpiButton.MouseButton1Click:Connect(function()
		ApplyDPI(scale)
	end)
end

------------------------------------------------------------
-- DEFAULT DPI = 100%
------------------------------------------------------------

ApplyDPI(1.00)

------------------------------------------------------------
-- INITIAL TAB
------------------------------------------------------------

if _G.vanz.Tabs[1] then
	_G.vanz.Tabs[1].Page.Visible = true
	_G.vanz.Tabs[1].SetActive(true)
	currentTab = _G.vanz.Tabs[1].Page
end

------------------------------------------------------------
-- ANIMATION ENGINE
------------------------------------------------------------

local hue = 0
local animationClock = 0

table.insert(
	_G.vanz.Connections,
	RunService.RenderStepped:Connect(function(deltaTime)

		animationClock += deltaTime

		----------------------------------------------------
		-- DYNAMIC COLOR
		----------------------------------------------------

		if _G.vanz.Config.DynamicColors ~= false then

			hue = (hue + deltaTime * 0.055) % 1

			local accent =
				Color3.fromHSV(
					hue,
					0.62,
					1
				)

			local accent2 =
				Color3.fromHSV(
					(hue + 0.12) % 1,
					0.58,
					1
				)

			Colors.Accent = accent
			Colors.Accent2 = accent2

			GlowOuter.BackgroundColor3 = accent
			GlowMiddle.BackgroundColor3 = accent
			LogoGlow.BackgroundColor3 = accent
			HeaderLine.BackgroundColor3 = accent
			SidebarTitle.TextColor3 = Color3.fromRGB(100, 108, 130)

			MainStroke.Color = accent

			AmbientLeft.BackgroundColor3 = accent
			AmbientRight.BackgroundColor3 = accent2

			LogoGradient.Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, accent),
				ColorSequenceKeypoint.new(1, accent2),
			})

			FloatingGradient.Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, accent),
				ColorSequenceKeypoint.new(1, accent2),
			})

			ShineGradient.Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, Colors.White),
				ColorSequenceKeypoint.new(0.42, Colors.White),
				ColorSequenceKeypoint.new(0.5, accent),
				ColorSequenceKeypoint.new(0.58, Colors.White),
				ColorSequenceKeypoint.new(1, Colors.White),
			})

			------------------------------------------------
			-- PULSE
			------------------------------------------------

			local pulse =
				(math.sin(animationClock * 2.1) + 1) / 2

			GlowOuter.BackgroundTransparency =
				0.94 - (pulse * 0.045)

			GlowMiddle.BackgroundTransparency =
				0.95 - (pulse * 0.025)

			LogoGlow.BackgroundTransparency =
				0.88 - (pulse * 0.08)

			FloatingGlow.BackgroundColor3 = accent

			FloatingGlow.BackgroundTransparency =
				0.87 - (pulse * 0.08)

			AmbientLeft.BackgroundTransparency =
				0.955 - (pulse * 0.02)

			AmbientRight.BackgroundTransparency =
				0.96 - (pulse * 0.02)

			------------------------------------------------
			-- LOGO BREATHING
			------------------------------------------------

			local logoPulse =
				1 + math.sin(animationClock * 2.0) * 0.025

			LogoHolder.Size =
				UDim2.fromOffset(
					44 * logoPulse,
					44 * logoPulse
				)

			------------------------------------------------
			-- FLOATING BUTTON BREATHING
			------------------------------------------------

			local floatingPulse =
				1 + math.sin(animationClock * 1.7) * 0.035

			FloatingButton.Size =
				UDim2.fromOffset(
					62 * floatingPulse,
					62 * floatingPulse
				)

			------------------------------------------------
			-- HEADER SHINE
			------------------------------------------------

			local shineX =
				((animationClock * 0.22) % 1.5) - 0.25

			ShineGradient.Offset =
				Vector2.new(shineX, 0)

			------------------------------------------------
			-- GRADIENT MOVEMENT
			------------------------------------------------

			LogoGradient.Rotation =
				(animationClock * 18) % 360

			FloatingGradient.Rotation =
				(animationClock * -15) % 360
		end
	end)
)

------------------------------------------------------------
-- PREMIUM FLOATING DRAG
------------------------------------------------------------

local floatDragging = false
local floatDragStart
local floatStart

FloatingButton.InputBegan:Connect(function(input)

	if input.UserInputType == Enum.UserInputType.MouseButton1
		or input.UserInputType == Enum.UserInputType.Touch then

		floatDragging = true
		floatDragStart = input.Position
		floatStart = FloatingButton.Position

		input.Changed:Connect(function()
			if input.UserInputState == Enum.UserInputState.End then
				floatDragging = false
			end
		end)
	end
end)

table.insert(
	_G.vanz.Connections,
	UserInputService.InputChanged:Connect(function(input)

		if not floatDragging then
			return
		end

		if input.UserInputType ~= Enum.UserInputType.MouseMovement
			and input.UserInputType ~= Enum.UserInputType.Touch then
			return
		end

		local delta =
			input.Position - floatDragStart

		FloatingButton.Position =
			UDim2.new(
				floatStart.X.Scale,
				floatStart.X.Offset + delta.X,
				floatStart.Y.Scale,
				floatStart.Y.Offset + delta.Y
			)

		FloatingGlow.Position =
			UDim2.new(
				FloatingButton.Position.X.Scale,
				FloatingButton.Position.X.Offset + 8,
				FloatingButton.Position.Y.Scale,
				FloatingButton.Position.Y.Offset + 8
			)
	end)
)

------------------------------------------------------------
-- API
------------------------------------------------------------

_G.vanz.Open = function()
	if minimized then
		SetMinimized(false)
	end
end

_G.vanz.Close = function()
	if not minimized then
		SetMinimized(true)
	end
end

_G.vanz.SetScale = function(scale)
	scale = tonumber(scale)

	if not scale then
		return
	end

	scale = math.clamp(scale, 0.6, 1.25)

	ApplyDPI(scale)
end

_G.vanz.GetState = function()
	return {
		Minimized = minimized,
		Scale = _G.vanz.Config.Scale,
		DynamicColors = _G.vanz.Config.DynamicColors,
	}
end

_G.vanz.SetState = function(state)

	if typeof(state) ~= "table" then
		return
	end

	if state.Scale then
		_G.vanz.SetScale(state.Scale)
	end

	if state.Minimized ~= nil then
		SetMinimized(state.Minimized)
	end

	if state.DynamicColors ~= nil then
		_G.vanz.Config.DynamicColors = state.DynamicColors
	end
end

------------------------------------------------------------
-- FINAL REFERENCES
------------------------------------------------------------

_G.vanz.UI.MainHolder = MainHolder
_G.vanz.UI.Main = Main
_G.vanz.UI.Header = Header
_G.vanz.UI.Sidebar = Sidebar
_G.vanz.UI.Pages = Pages
_G.vanz.UI.FloatingButton = FloatingButton
_G.vanz.UI.FloatingGlow = FloatingGlow
_G.vanz.UI.Colors = Colors

------------------------------------------------------------
-- STARTUP ANIMATION
------------------------------------------------------------

MainHolder.Size = UDim2.fromOffset(680, 440)
Main.BackgroundTransparency = 1
GlowOuter.BackgroundTransparency = 1
GlowMiddle.BackgroundTransparency = 1

task.defer(function()

	Tween(
		MainHolder,
		TweenInfo.new(
			0.55,
			Enum.EasingStyle.Back,
			Enum.EasingDirection.Out
		),
		{
			Size = UDim2.fromOffset(780, 500),
		}
	)

	task.wait(0.12)

	Tween(
		Main,
		TweenInfo.new(
			0.4,
			Enum.EasingStyle.Quint,
			Enum.EasingDirection.Out
		),
		{
			BackgroundTransparency = 0.03,
		}
	)

	Tween(
		GlowOuter,
		TweenInfo.new(0.5),
		{
			BackgroundTransparency = 0.91,
		}
	)

	Tween(
		GlowMiddle,
		TweenInfo.new(0.45),
		{
			BackgroundTransparency = 0.93,
		}
	)

	task.wait(0.2)

	UpdateResponsive()
end)

------------------------------------------------------------
-- DONE
------------------------------------------------------------

print("╔══════════════════════════════════════════════════════╗")
print("║              VANZ PREMIUM UI v3                     ║")
print("║        WIDE • PREMIUM • GLOW • READY                ║")
print("╠══════════════════════════════════════════════════════╣")
print("║ Default DPI : 100%                                  ║")
print("║ Layout      : Wide Landscape                        ║")
print("║ Animations  : Enabled                               ║")
print("║ Dynamic RGB : Enabled                               ║")
print("║ Premium UI  : Enabled                               ║")
print("╚══════════════════════════════════════════════════════╝")