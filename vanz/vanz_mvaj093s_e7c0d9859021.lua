--========================================================--
-- VANZ — MOD MENU MAX (AIM + STUN + WALLHACK + GOD + FAST HEAL)
--========================================================--

_G.vanz = _G.vanz or {}
_G.vanz.Settings = _G.vanz.Settings or {}
_G.vanz.Events = _G.vanz.Events or {}
_G.vanz.Runtime = _G.vanz.Runtime or {}

--========================================================--
-- 0_CONFIG
--========================================================--
_G.vanz.TeamCfg = _G.vanz.TeamCfg or {
    enemyKeywords = { "kill", "murder", "slasher", "hunter", "monster", "enemy" },
    allyKeywords = { "survivor", "innocent", "runner", "civilian", "player", "ally" },
    enemyR = 0.55,
    allyB = 0.55,
}

_G.vanz.AimCfg = _G.vanz.AimCfg or {
    originMode = "gun",
    targetMode = "uppertorso",
    lateralOffset = 0.0,
    lateralAxis = "RightVector",
    scanInterval = 0.001,
}

_G.vanz.StunCfg = _G.vanz.StunCfg or {
    maxTime = 2,
    labelSize = 15,
    keywords = { "stun", "parried", "parry", "wallhit", "wallhitstun" },
}

_G.vanz.HighlightCfg = _G.vanz.HighlightCfg or {
    fillColor = Color3.fromRGB(255, 40, 40),
    fillTrans = 0.55,
    outlineColor = Color3.fromRGB(255, 90, 90),
    outlineTrans = 0.1,
    depthMode = "AlwaysOnTop",
}

_G.vanz.GodCfg = _G.vanz.GodCfg or {
    interval = 0.1,
}

_G.vanz.BlockCfg = _G.vanz.BlockCfg or {
    debug = false,
}

_G.vanz.FastHealCfg = _G.vanz.FastHealCfg or {
    interval = 0.001,
}

--========================================================--
-- 1_INIT_GUI
--========================================================--
do
    xpcall(function()
        local Players = game:GetService("Players")
        local UserInputService = game:GetService("UserInputService")
        local LocalPlayer = Players.LocalPlayer
        local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

        local old = PlayerGui:FindFirstChild("VANZ_GUI")
        if old then old:Destroy() end

        _G.vanz.GUI = {}

        local ScreenGui = Instance.new("ScreenGui")
        ScreenGui.Name = "VANZ_GUI"
        ScreenGui.ResetOnSpawn = false
        ScreenGui.IgnoreGuiInset = false
        ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Global
        ScreenGui.DisplayOrder = 999999

        local targetParent = PlayerGui
        if syn and syn.protect_gui then
            syn.protect_gui(ScreenGui)
            targetParent = game:GetService("CoreGui")
        elseif gethui then
            targetParent = gethui()
        end
        ScreenGui.Parent = targetParent
        _G.vanz.GUI.ScreenGui = ScreenGui

        local Main = Instance.new("Frame")
        Main.Name = "Main"
        Main.AnchorPoint = Vector2.new(0, 0.5)
        Main.Position = UDim2.new(0, 10, 0.5, 0)
        Main.Size = UDim2.new(0, 260, 0, 273)
        Main.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
        Main.BorderSizePixel = 0
        Main.ZIndex = 10
        Main.Parent = ScreenGui
        Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 10)
        _G.vanz.GUI.Main = Main

        local TitleBar = Instance.new("Frame")
        TitleBar.Size = UDim2.new(1, 0, 0, 45)
        TitleBar.BackgroundColor3 = Color3.fromRGB(24, 24, 30)
        TitleBar.BorderSizePixel = 0
        TitleBar.ZIndex = 11
        TitleBar.Parent = Main
        Instance.new("UICorner", TitleBar).CornerRadius = UDim.new(0, 10)

        local Title = Instance.new("TextLabel")
        Title.Size = UDim2.new(1, -55, 1, 0)
        Title.Position = UDim2.new(0, 15, 0, 0)
        Title.BackgroundTransparency = 1
        Title.Text = "VANZ  •  MAX"
        Title.TextColor3 = Color3.fromRGB(255, 60, 60)
        Title.TextSize = 16
        Title.Font = Enum.Font.GothamBold
        Title.TextXAlignment = Enum.TextXAlignment.Left
        Title.ZIndex = 12
        Title.Parent = TitleBar

        local Minimize = Instance.new("TextButton")
        Minimize.Size = UDim2.new(0, 32, 0, 32)
        Minimize.Position = UDim2.new(1, -40, 0, 7)
        Minimize.BackgroundColor3 = Color3.fromRGB(35, 35, 42)
        Minimize.Text = "–"
        Minimize.TextColor3 = Color3.fromRGB(255, 255, 255)
        Minimize.TextSize = 20
        Minimize.Font = Enum.Font.GothamBold
        Minimize.AutoButtonColor = false
        Minimize.ZIndex = 12
        Minimize.Parent = TitleBar
        Instance.new("UICorner", Minimize).CornerRadius = UDim.new(0, 8)

        local Content = Instance.new("Frame")
        Content.Name = "Content"
        Content.Position = UDim2.new(0, 10, 0, 55)
        Content.Size = UDim2.new(1, -20, 1, -65)
        Content.BackgroundTransparency = 1
        Content.ZIndex = 11
        Content.Parent = Main

        local HolderAim = Instance.new("Frame")
        HolderAim.Size = UDim2.new(1, 0, 0, 65)
        HolderAim.Position = UDim2.new(0, 0, 0, 0)
        HolderAim.BackgroundColor3 = Color3.fromRGB(26, 26, 32)
        HolderAim.BorderSizePixel = 0
        HolderAim.ZIndex = 12
        HolderAim.Parent = Content
        Instance.new("UICorner", HolderAim).CornerRadius = UDim.new(0, 8)

        local LabelAim = Instance.new("TextLabel")
        LabelAim.Position = UDim2.new(0, 12, 0, 7)
        LabelAim.Size = UDim2.new(1, -65, 0, 25)
        LabelAim.BackgroundTransparency = 1
        LabelAim.Text = "SILENT AIM"
        LabelAim.TextColor3 = Color3.fromRGB(255, 100, 100)
        LabelAim.TextSize = 15
        LabelAim.Font = Enum.Font.GothamBold
        LabelAim.TextXAlignment = Enum.TextXAlignment.Left
        LabelAim.ZIndex = 13
        LabelAim.Parent = HolderAim

        local DescAim = Instance.new("TextLabel")
        DescAim.Position = UDim2.new(0, 12, 0, 31)
        DescAim.Size = UDim2.new(1, -65, 0, 25)
        DescAim.BackgroundTransparency = 1
        DescAim.Text = "Direct Torso + Fire + Visual + Anti-Death + Wallhack"
        DescAim.TextColor3 = Color3.fromRGB(140, 140, 155)
        DescAim.TextSize = 10
        DescAim.Font = Enum.Font.Gotham
        DescAim.TextXAlignment = Enum.TextXAlignment.Left
        DescAim.TextWrapped = true
        DescAim.ZIndex = 13
        DescAim.Parent = HolderAim

        local ToggleAim = Instance.new("TextButton")
        ToggleAim.Size = UDim2.new(0, 42, 0, 24)
        ToggleAim.Position = UDim2.new(1, -52, 0.5, -12)
        ToggleAim.BackgroundColor3 = Color3.fromRGB(55, 55, 65)
        ToggleAim.Text = ""
        ToggleAim.AutoButtonColor = false
        ToggleAim.ZIndex = 13
        ToggleAim.Parent = HolderAim
        Instance.new("UICorner", ToggleAim).CornerRadius = UDim.new(1, 0)

        local KnobAim = Instance.new("Frame")
        KnobAim.Size = UDim2.new(0, 18, 0, 18)
        KnobAim.Position = UDim2.new(0, 3, 0.5, -9)
        KnobAim.BackgroundColor3 = Color3.fromRGB(225, 225, 225)
        KnobAim.ZIndex = 14
        KnobAim.Parent = ToggleAim
        Instance.new("UICorner", KnobAim).CornerRadius = UDim.new(1, 0)

        local HolderGod = Instance.new("Frame")
        HolderGod.Size = UDim2.new(1, 0, 0, 65)
        HolderGod.Position = UDim2.new(0, 0, 0, 73)
        HolderGod.BackgroundColor3 = Color3.fromRGB(26, 26, 32)
        HolderGod.BorderSizePixel = 0
        HolderGod.ZIndex = 12
        HolderGod.Parent = Content
        Instance.new("UICorner", HolderGod).CornerRadius = UDim.new(0, 8)

        local LabelGod = Instance.new("TextLabel")
        LabelGod.Position = UDim2.new(0, 12, 0, 7)
        LabelGod.Size = UDim2.new(1, -65, 0, 25)
        LabelGod.BackgroundTransparency = 1
        LabelGod.Text = "GOD MODE"
        LabelGod.TextColor3 = Color3.fromRGB(100, 200, 255)
        LabelGod.TextSize = 15
        LabelGod.Font = Enum.Font.GothamBold
        LabelGod.TextXAlignment = Enum.TextXAlignment.Left
        LabelGod.ZIndex = 13
        LabelGod.Parent = HolderGod

        local DescGod = Instance.new("TextLabel")
        DescGod.Position = UDim2.new(0, 12, 0, 31)
        DescGod.Size = UDim2.new(1, -65, 0, 25)
        DescGod.BackgroundTransparency = 1
        DescGod.Text = "Collision spam + namecall block"
        DescGod.TextColor3 = Color3.fromRGB(140, 140, 155)
        DescGod.TextSize = 10
        DescGod.Font = Enum.Font.Gotham
        DescGod.TextXAlignment = Enum.TextXAlignment.Left
        DescGod.TextWrapped = true
        DescGod.ZIndex = 13
        DescGod.Parent = HolderGod

        local ToggleGod = Instance.new("TextButton")
        ToggleGod.Size = UDim2.new(0, 42, 0, 24)
        ToggleGod.Position = UDim2.new(1, -52, 0.5, -12)
        ToggleGod.BackgroundColor3 = Color3.fromRGB(55, 55, 65)
        ToggleGod.Text = ""
        ToggleGod.AutoButtonColor = false
        ToggleGod.ZIndex = 13
        ToggleGod.Parent = HolderGod
        Instance.new("UICorner", ToggleGod).CornerRadius = UDim.new(1, 0)

        local KnobGod = Instance.new("Frame")
        KnobGod.Size = UDim2.new(0, 18, 0, 18)
        KnobGod.Position = UDim2.new(0, 3, 0.5, -9)
        KnobGod.BackgroundColor3 = Color3.fromRGB(225, 225, 225)
        KnobGod.ZIndex = 14
        KnobGod.Parent = ToggleGod
        Instance.new("UICorner", KnobGod).CornerRadius = UDim.new(1, 0)

        local HolderFastHeal = Instance.new("Frame")
        HolderFastHeal.Size = UDim2.new(1, 0, 0, 65)
        HolderFastHeal.Position = UDim2.new(0, 0, 0, 146)
        HolderFastHeal.BackgroundColor3 = Color3.fromRGB(26, 26, 32)
        HolderFastHeal.BorderSizePixel = 0
        HolderFastHeal.ZIndex = 12
        HolderFastHeal.Parent = Content
        Instance.new("UICorner", HolderFastHeal).CornerRadius = UDim.new(0, 8)

        local LabelFastHeal = Instance.new("TextLabel")
        LabelFastHeal.Position = UDim2.new(0, 12, 0, 7)
        LabelFastHeal.Size = UDim2.new(1, -65, 0, 25)
        LabelFastHeal.BackgroundTransparency = 1
        LabelFastHeal.Text = "FAST HEAL"
        LabelFastHeal.TextColor3 = Color3.fromRGB(120, 240, 160)
        LabelFastHeal.TextSize = 15
        LabelFastHeal.Font = Enum.Font.GothamBold
        LabelFastHeal.TextXAlignment = Enum.TextXAlignment.Left
        LabelFastHeal.ZIndex = 13
        LabelFastHeal.Parent = HolderFastHeal

        local DescFastHeal = Instance.new("TextLabel")
        DescFastHeal.Position = UDim2.new(0, 12, 0, 31)
        DescFastHeal.Size = UDim2.new(1, -65, 0, 25)
        DescFastHeal.BackgroundTransparency = 1
        DescFastHeal.Text = "Spam HealEvent 1ms — remote only"
        DescFastHeal.TextColor3 = Color3.fromRGB(140, 140, 155)
        DescFastHeal.TextSize = 10
        DescFastHeal.Font = Enum.Font.Gotham
        DescFastHeal.TextXAlignment = Enum.TextXAlignment.Left
        DescFastHeal.TextWrapped = true
        DescFastHeal.ZIndex = 13
        DescFastHeal.Parent = HolderFastHeal

        local ToggleFastHeal = Instance.new("TextButton")
        ToggleFastHeal.Size = UDim2.new(0, 42, 0, 24)
        ToggleFastHeal.Position = UDim2.new(1, -52, 0.5, -12)
        ToggleFastHeal.BackgroundColor3 = Color3.fromRGB(55, 55, 65)
        ToggleFastHeal.Text = ""
        ToggleFastHeal.AutoButtonColor = false
        ToggleFastHeal.ZIndex = 13
        ToggleFastHeal.Parent = HolderFastHeal
        Instance.new("UICorner", ToggleFastHeal).CornerRadius = UDim.new(1, 0)

        local KnobFastHeal = Instance.new("Frame")
        KnobFastHeal.Size = UDim2.new(0, 18, 0, 18)
        KnobFastHeal.Position = UDim2.new(0, 3, 0.5, -9)
        KnobFastHeal.BackgroundColor3 = Color3.fromRGB(225, 225, 225)
        KnobFastHeal.ZIndex = 14
        KnobFastHeal.Parent = ToggleFastHeal
        Instance.new("UICorner", KnobFastHeal).CornerRadius = UDim.new(1, 0)

        _G.vanz.Settings.SilentAim = false
        _G.vanz.Settings.VisualLine = false
        _G.vanz.Settings.FireButton = false
        _G.vanz.Settings.AntiDeath = false
        _G.vanz.Settings.GodMode = false
        _G.vanz.Settings.FastHeal = false

        local function UpdateAimVisual()
            if _G.vanz.Settings.SilentAim then
                ToggleAim.BackgroundColor3 = Color3.fromRGB(180, 40, 40)
                KnobAim.Position = UDim2.new(1, -21, 0.5, -9)
                LabelAim.TextColor3 = Color3.fromRGB(255, 150, 150)
            else
                ToggleAim.BackgroundColor3 = Color3.fromRGB(55, 55, 65)
                KnobAim.Position = UDim2.new(0, 3, 0.5, -9)
                LabelAim.TextColor3 = Color3.fromRGB(255, 100, 100)
            end
        end

        local function UpdateGodVisual()
            if _G.vanz.Settings.GodMode then
                ToggleGod.BackgroundColor3 = Color3.fromRGB(40, 130, 200)
                KnobGod.Position = UDim2.new(1, -21, 0.5, -9)
                LabelGod.TextColor3 = Color3.fromRGB(150, 220, 255)
            else
                ToggleGod.BackgroundColor3 = Color3.fromRGB(55, 55, 65)
                KnobGod.Position = UDim2.new(0, 3, 0.5, -9)
                LabelGod.TextColor3 = Color3.fromRGB(100, 200, 255)
            end
        end

        local function UpdateFastHealVisual()
            if _G.vanz.Settings.FastHeal then
                ToggleFastHeal.BackgroundColor3 = Color3.fromRGB(40, 160, 90)
                KnobFastHeal.Position = UDim2.new(1, -21, 0.5, -9)
                LabelFastHeal.TextColor3 = Color3.fromRGB(180, 255, 200)
            else
                ToggleFastHeal.BackgroundColor3 = Color3.fromRGB(55, 55, 65)
                KnobFastHeal.Position = UDim2.new(0, 3, 0.5, -9)
                LabelFastHeal.TextColor3 = Color3.fromRGB(120, 240, 160)
            end
        end

        ToggleAim.MouseButton1Click:Connect(function()
            local on = not _G.vanz.Settings.SilentAim
            _G.vanz.Settings.SilentAim = on
            _G.vanz.Settings.VisualLine = on
            _G.vanz.Settings.FireButton = on
            _G.vanz.Settings.AntiDeath = on

            UpdateAimVisual()

            if _G.vanz.Runtime.FireButton then
                _G.vanz.Runtime.FireButton.Visible = on
            end
            if not on then
                if _G.vanz.Runtime.DrawLine then _G.vanz.Runtime.DrawLine.Visible = false end
                if _G.vanz.Runtime.DrawDot then _G.vanz.Runtime.DrawDot.Visible = false end
            end

            local keys = { "FireButton", "VisualLine" }
            for _, k in ipairs(keys) do
                local ev = _G.vanz.Events[k]
                if type(ev) == "function" then
                    task.spawn(function()
                        xpcall(function() ev(on) end, function(err)
                            warn(string.format("[VANZ ERROR][%s] %s", k, tostring(err)))
                        end)
                    end)
                end
            end
        end)

        ToggleGod.MouseButton1Click:Connect(function()
            local on = not _G.vanz.Settings.GodMode
            _G.vanz.Settings.GodMode = on
            UpdateGodVisual()

            local ev = _G.vanz.Events.GodMode
            if type(ev) == "function" then
                task.spawn(function()
                    xpcall(function() ev(on) end, function(err)
                        warn(string.format("[VANZ ERROR][GodMode] %s", tostring(err)))
                    end)
                end)
            end
        end)

        ToggleFastHeal.MouseButton1Click:Connect(function()
            local on = not _G.vanz.Settings.FastHeal
            _G.vanz.Settings.FastHeal = on
            UpdateFastHealVisual()

            local ev = _G.vanz.Events.FastHeal
            if type(ev) == "function" then
                task.spawn(function()
                    xpcall(function() ev(on) end, function(err)
                        warn(string.format("[VANZ ERROR][FastHeal] %s", tostring(err)))
                    end)
                end)
            end
        end)

        UpdateAimVisual()
        UpdateGodVisual()
        UpdateFastHealVisual()

        _G.vanz.FireTof = _G.vanz.FireTof or function()
            warn("[VANZ] FireTof belum siap.")
        end

        local FireBtn = Instance.new("TextButton")
        FireBtn.Name = "VANZ_FireBtn"
        FireBtn.AnchorPoint = Vector2.new(1, 0.5)
        FireBtn.Position = UDim2.new(1, -20, 0.5, 0)
        FireBtn.Size = UDim2.new(0, 70, 0, 70)
        FireBtn.BackgroundColor3 = Color3.fromRGB(180, 40, 40)
        FireBtn.BackgroundTransparency = 0.15
        FireBtn.Text = "FIRE"
        FireBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        FireBtn.TextSize = 16
        FireBtn.Font = Enum.Font.GothamBold
        FireBtn.AutoButtonColor = true
        FireBtn.Visible = false
        FireBtn.Active = true
        FireBtn.ZIndex = 100
        FireBtn.Parent = ScreenGui
        Instance.new("UICorner", FireBtn).CornerRadius = UDim.new(1, 0)
        local fstroke = Instance.new("UIStroke")
        fstroke.Color = Color3.fromRGB(255, 90, 90)
        fstroke.Thickness = 2
        fstroke.Parent = FireBtn

        FireBtn.MouseButton1Click:Connect(function()
            task.spawn(function()
                xpcall(function() _G.vanz.FireTof() end, function(err)
                    warn(string.format("[VANZ ERROR][FireButton] %s", tostring(err)))
                end)
            end)
        end)

        _G.vanz.Runtime.FireButton = FireBtn

        local Logo = Instance.new("TextButton")
        Logo.Name = "FloatingLogo"
        Logo.Size = UDim2.new(0, 52, 0, 52)
        Logo.Position = UDim2.new(0, 10, 0.5, -26)
        Logo.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
        Logo.Text = "V"
        Logo.TextColor3 = Color3.fromRGB(255, 60, 60)
        Logo.TextSize = 22
        Logo.Font = Enum.Font.GothamBold
        Logo.AutoButtonColor = false
        Logo.Visible = false
        Logo.ZIndex = 100
        Logo.Parent = ScreenGui
        Instance.new("UICorner", Logo).CornerRadius = UDim.new(1, 0)
        local stroke = Instance.new("UIStroke")
        stroke.Color = Color3.fromRGB(255, 60, 60)
        stroke.Thickness = 2
        stroke.Parent = Logo
        _G.vanz.GUI.Logo = Logo

        Minimize.MouseButton1Click:Connect(function()
            Main.Visible = false
            Logo.Visible = true
        end)
        Logo.MouseButton1Click:Connect(function()
            Logo.Visible = false
            Main.Visible = true
        end)

        local function MakeDraggable(object)
            local dragging = false
            local dragStart
            local startPos
            local dragInput
            object.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1
                or input.UserInputType == Enum.UserInputType.Touch then
                    dragging = true
                    dragStart = input.Position
                    startPos = object.Position
                    input.Changed:Connect(function()
                        if input.UserInputState == Enum.UserInputState.End then
                            dragging = false
                        end
                    end)
                end
            end)
            object.InputChanged:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseMovement
                or input.UserInputType == Enum.UserInputType.Touch then
                    dragInput = input
                end
            end)
            UserInputService.InputChanged:Connect(function(input)
                if dragging and input == dragInput then
                    local delta = input.Position - dragStart
                    object.Position = UDim2.new(
                        startPos.X.Scale, startPos.X.Offset + delta.X,
                        startPos.Y.Scale, startPos.Y.Offset + delta.Y)
                end
            end)
        end

        MakeDraggable(Main)
        MakeDraggable(Logo)

        local function Resize()
            local cam = workspace.CurrentCamera
            if not cam then return end
            local vp = cam.ViewportSize
            Main.Size = UDim2.new(0, math.min(260, vp.X - 20), 0, 273)
        end
        Resize()

        workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
            task.defer(Resize)
        end)
    end, function(err) warn("[VANZ ERROR][1_GUI] " .. tostring(err)) end)
end

--========================================================--
-- 2_FPS
--========================================================--
do
    xpcall(function()
        local RunService = game:GetService("RunService")
        _G.vanz.Runtime.SmoothFPS = 60
        _G.vanz.Runtime.FrameTimeAcc = 0
        _G.vanz.Runtime.FrameCount = 0
        _G.vanz.Runtime.LastFPSSample = tick()

        RunService.Heartbeat:Connect(function(dt)
            local now = tick()
            _G.vanz.Runtime.FrameTimeAcc = _G.vanz.Runtime.FrameTimeAcc + dt
            _G.vanz.Runtime.FrameCount = _G.vanz.Runtime.FrameCount + 1
            if now - _G.vanz.Runtime.LastFPSSample >= 0.5 then
                local avgDt = _G.vanz.Runtime.FrameTimeAcc / math.max(_G.vanz.Runtime.FrameCount, 1)
                local fps = 1 / math.max(avgDt, 0.001)
                _G.vanz.Runtime.SmoothFPS = _G.vanz.Runtime.SmoothFPS * 0.7 + fps * 0.3
                _G.vanz.Runtime.FrameTimeAcc = 0
                _G.vanz.Runtime.FrameCount = 0
                _G.vanz.Runtime.LastFPSSample = now
            end
        end)
    end, function(err) warn("[VANZ ERROR][2_FPS] " .. tostring(err)) end)
end

--========================================================--
-- 3_TARGET_SCAN
--========================================================--
do
    xpcall(function()
        local Players = game:GetService("Players")
        local LocalPlayer = Players.LocalPlayer

        local function Classify(plr)
            if not plr or plr == LocalPlayer then return "self" end
            local team = plr.Team
            if not team then return "unknown" end
            local cfg = _G.vanz.TeamCfg
            local name = string.lower(team.Name or "")
            for _, kw in ipairs(cfg.enemyKeywords) do
                if string.find(name, kw, 1, true) then return "enemy" end
            end
            for _, kw in ipairs(cfg.allyKeywords) do
                if string.find(name, kw, 1, true) then return "ally" end
            end
            local tc = team.TeamColor
            local c = tc and tc.Color
            if c then
                if c.R >= cfg.enemyR and c.G < 0.45 and c.B < 0.45 then return "enemy" end
                if c.B >= cfg.allyB then return "ally" end
            end
            return "unknown"
        end

        local function GetRoot(plr)
            local char = plr and plr.Character
            if not char then return nil end
            return char:FindFirstChild("UpperTorso")
                or char:FindFirstChild("HumanoidRootPart")
                or char:FindFirstChild("Torso")
        end

        _G.vanz.Classify = Classify
        _G.vanz.GetRoot = GetRoot

        if _G.vanz.Runtime.ScanThread then
            pcall(task.cancel, _G.vanz.Runtime.ScanThread)
        end

        _G.vanz.Runtime.ScanThread = task.spawn(function()
            local interval = _G.vanz.AimCfg.scanInterval or 0.001
            while true do
                local myRoot = GetRoot(LocalPlayer)
                if myRoot then
                    local bestDist, best = math.huge, nil
                    local myPos = myRoot.Position
                    for _, plr in ipairs(Players:GetPlayers()) do
                        if Classify(plr) == "enemy" then
                            local root = GetRoot(plr)
                            if root then
                                local d = (root.Position - myPos).Magnitude
                                if d < bestDist then
                                    bestDist, best = d, plr
                                end
                            end
                        end
                    end
                    _G.vanz.Runtime.Target = best
                else
                    _G.vanz.Runtime.Target = nil
                end
                task.wait(interval)
            end
        end)
    end, function(err) warn("[VANZ ERROR][3_TARGET] " .. tostring(err)) end)
end

--========================================================--
-- 4_FIRETOF
--========================================================--
do
    xpcall(function()
        local Players = game:GetService("Players")
        local LocalPlayer = Players.LocalPlayer
        local RS = game:GetService("ReplicatedStorage")

        local function GetToFModel()
            local char = LocalPlayer.Character
            if not char then return nil end
            return char:FindFirstChild("Twist of Fate")
        end

        local function GetGunPart()
            local char = LocalPlayer.Character
            if not char then return nil end
            local tof = char:FindFirstChild("Twist of Fate")
            if not tof then return nil end
            local rightArm = tof:FindFirstChild("Right Arm")
            if not rightArm then return nil end
            return rightArm:FindFirstChild("gun")
                or rightArm:FindFirstChildWhichIsA("BasePart", true)
        end

        local function GetAimOrigin()
            local char = LocalPlayer.Character
            if not char then return nil end
            local mode = _G.vanz.AimCfg.originMode or "gun"
            if mode == "gun" then
                local gun = GetGunPart()
                if gun and gun:IsA("BasePart") then return gun.Position end
            end
            if mode == "head" then
                local head = char:FindFirstChild("Head")
                if head and head:IsA("BasePart") then return head.Position end
            end
            local hrp = char:FindFirstChild("HumanoidRootPart")
                or char:FindFirstChild("UpperTorso")
                or char:FindFirstChild("Torso")
            return hrp and hrp.Position or nil
        end

        local function GetTorsoPart(plr)
            if not plr then return nil end
            local char = plr.Character
            if not char then return nil end
            local p = char:FindFirstChild("UpperTorso")
                or char:FindFirstChild("Torso")
                or char:FindFirstChild("HumanoidRootPart")
            if p and p:IsA("BasePart") and p.Parent then return p end
            return nil
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

        _G.vanz.FireTof = function()
            local tgt = _G.vanz.Runtime.Target
            if not tgt then return end

            local tofModel = GetToFModel()
            local fire = GetFireRemote()
            if not tofModel or not fire then return end

            local origin = GetAimOrigin()
            if not origin then return end

            local torso = GetTorsoPart(tgt)
            if not torso then return end

            local targetPos = torso.Position
            local off = _G.vanz.AimCfg.lateralOffset or 0
            local axis = _G.vanz.AimCfg.lateralAxis or "RightVector"
            if off ~= 0 then
                local ok, axisVec = pcall(function() return torso.CFrame[axis] end)
                if ok and axisVec then
                    targetPos = targetPos + axisVec * off
                end
            end

            local diff = targetPos - origin
            if diff.Magnitude < 0.01 then return end
            local dir = diff.Unit

            pcall(function()
                fire:FireServer(tofModel, dir)
            end)
        end

        _G.vanz.Events.FireButton = function(enabled)
            if _G.vanz.Runtime.FireButton then
                _G.vanz.Runtime.FireButton.Visible = enabled
            end
        end
    end, function(err) warn("[VANZ ERROR][4_FIRETOF] " .. tostring(err)) end)
end

--========================================================--
-- 5_ANTI_DEATH
--========================================================--
do
    xpcall(function()
        local Players = game:GetService("Players")
        local RunService = game:GetService("RunService")
        local LocalPlayer = Players.LocalPlayer
        local RS = game:GetService("ReplicatedStorage")

        local HealEvent
        pcall(function() HealEvent = RS.Remotes.Healing.HealEvent end)

        local lastSpam = 0
        RunService.Heartbeat:Connect(function()
            if not _G.vanz.Settings.AntiDeath then return end
            local char = LocalPlayer.Character
            if not char then return end
            local hum = char:FindFirstChildOfClass("Humanoid")
            local hrp = char:FindFirstChild("HumanoidRootPart")
            if not (hum and hrp) then return end
            if hum.Health > 0 and hum.Health <= 30 then
                local now = tick()
                if now - lastSpam >= 0.35 then
                    lastSpam = now
                    if HealEvent then
                        pcall(function() HealEvent:FireServer(hrp, true) end)
                    end
                end
            end
        end)
    end, function(err) warn("[VANZ ERROR][5_ANTIDEATH] " .. tostring(err)) end)
end

--========================================================--
-- 6_VISUAL_LINE
--========================================================--
do
    xpcall(function()
        local RunService = game:GetService("RunService")
        local LocalPlayer = game:GetService("Players").LocalPlayer

        if type(Drawing) ~= "table" or type(Drawing.new) ~= "function" then return end

        local line = Drawing.new("Line")
        line.Visible = false
        line.Color = Color3.fromRGB(255, 55, 55)
        line.Thickness = 2
        line.Transparency = 1
        _G.vanz.Runtime.DrawLine = line

        local dot = Drawing.new("Circle")
        dot.Visible = false
        dot.Color = Color3.fromRGB(255, 55, 55)
        dot.Thickness = 2
        dot.Radius = 6
        dot.Filled = false
        dot.Transparency = 1
        _G.vanz.Runtime.DrawDot = dot

        local function Project(worldPos, cam)
            local vp = cam.ViewportSize
            local cx, cy = vp.X * 0.5, vp.Y * 0.5
            local sp = cam:WorldToViewportPoint(worldPos)
            if sp.Z > 0 then return Vector2.new(sp.X, sp.Y) end
            local dx, dy = cx - sp.X, cy - sp.Y
            local len = math.sqrt(dx * dx + dy * dy)
            if len < 1 then return Vector2.new(cx, cy + 2000) end
            local scale = 3000 / len
            return Vector2.new(cx + dx * scale, cy + dy * scale)
        end

        local function GetGunPos()
            local char = LocalPlayer.Character
            if not char then return nil end
            local tof = char:FindFirstChild("Twist of Fate")
            if tof then
                local rightArm = tof:FindFirstChild("Right Arm")
                if rightArm then
                    local muzzle = rightArm:FindFirstChild("gun")
                        or rightArm:FindFirstChildWhichIsA("BasePart", true)
                    if muzzle and muzzle:IsA("BasePart") then
                        return muzzle.Position
                    end
                end
            end
            local hrp = char:FindFirstChild("HumanoidRootPart")
            return hrp and (hrp.Position + Vector3.new(0, 1, 0)) or nil
        end

        local function GetTargetPos()
            local tgt = _G.vanz.Runtime.Target
            if not tgt or not tgt.Character then return nil end
            local part = tgt.Character:FindFirstChild("UpperTorso")
                or tgt.Character:FindFirstChild("Torso")
                or tgt.Character:FindFirstChild("HumanoidRootPart")
            if not (part and part:IsA("BasePart") and part.Parent) then return nil end
            return part.Position
        end

        if _G.vanz.Runtime.LineConn then
            _G.vanz.Runtime.LineConn:Disconnect()
        end

        _G.vanz.Runtime.LineConn = RunService.RenderStepped:Connect(function()
            if not _G.vanz.Settings.VisualLine then
                line.Visible = false
                dot.Visible = false
                return
            end
            local gunPos = GetGunPos()
            local targetPos = GetTargetPos()
            local cam = workspace.CurrentCamera
            if not (gunPos and targetPos and cam) then
                line.Visible = false
                dot.Visible = false
                return
            end
            line.From = Project(gunPos, cam)
            line.To = Project(targetPos, cam)
            line.Visible = true
            dot.Position = Project(targetPos, cam)
            dot.Visible = true
        end)

        _G.vanz.Events.VisualLine = function(enabled)
            if not enabled then
                if _G.vanz.Runtime.DrawLine then _G.vanz.Runtime.DrawLine.Visible = false end
                if _G.vanz.Runtime.DrawDot then _G.vanz.Runtime.DrawDot.Visible = false end
            end
        end
    end, function(err) warn("[VANZ ERROR][6_VISUAL] " .. tostring(err)) end)
end

--========================================================--
-- 7_HUD
--========================================================--
do
    xpcall(function()
        local RunService = game:GetService("RunService")
        local Players = game:GetService("Players")
        local LocalPlayer = Players.LocalPlayer
        if not (_G.vanz.GUI and _G.vanz.GUI.ScreenGui) then return end

        local Info = Instance.new("TextLabel")
        Info.Name = "VANZ_INFO"
        Info.AnchorPoint = Vector2.new(0.5, 1)
        Info.Position = UDim2.new(0.5, 0, 1, -15)
        Info.Size = UDim2.new(0, 660, 0, 24)
        Info.BackgroundTransparency = 0.3
        Info.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
        Info.TextColor3 = Color3.fromRGB(255, 75, 75)
        Info.TextSize = 10
        Info.Font = Enum.Font.Code
        Info.TextXAlignment = Enum.TextXAlignment.Center
        Info.Text = "[VANZ] INITIALIZING..."
        Info.ZIndex = 50
        Info.Parent = _G.vanz.GUI.ScreenGui

        local stroke = Instance.new("UIStroke")
        stroke.Color = Color3.fromRGB(255, 40, 40)
        stroke.Transparency = 0.5
        stroke.Thickness = 1
        stroke.Parent = Info
        Instance.new("UICorner", Info).CornerRadius = UDim.new(0, 6)

        RunService.Heartbeat:Connect(function()
            local tgt = _G.vanz.Runtime.Target
            local name = tgt and tgt.Name or "NONE"
            local distStr = "0m"
            local hpStr = "N/A"
            if tgt and tgt.Character then
                local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                local tgtRoot = tgt.Character:FindFirstChild("HumanoidRootPart")
                local hum = tgt.Character:FindFirstChildOfClass("Humanoid")
                if myRoot and tgtRoot then
                    distStr = string.format("%.1fm", (tgtRoot.Position - myRoot.Position).Magnitude)
                end
                if hum then
                    hpStr = string.format("%.0f/%.0f", hum.Health, hum.MaxHealth)
                end
            end
            local fps = _G.vanz.Runtime.SmoothFPS or 60
            local aim = _G.vanz.Settings.SilentAim and "ON" or "OFF"
            local god = _G.vanz.Settings.GodMode and "ON" or "OFF"
            local fh = _G.vanz.Settings.FastHeal and "ON" or "OFF"
            local blk = #(_G.vanz.Runtime.BlockLog or {})
            Info.Text = string.format("AIM:%s GOD:%s FH:%s BLK:%d TGT:%s HP:%s DIST:%s FPS:%.0f",
                aim, god, fh, blk, name, hpStr, distStr, fps)
        end)
    end, function(err) warn("[VANZ ERROR][7_HUD] " .. tostring(err)) end)
end

--========================================================--
-- 8_STUN_VISUAL
--========================================================--
do
    xpcall(function()
        local Players = game:GetService("Players")
        local RunService = game:GetService("RunService")
        local RS = game:GetService("ReplicatedStorage")
        local LocalPlayer = Players.LocalPlayer

        _G.vanz.Runtime.StunVis = _G.vanz.Runtime.StunVis or {}

        local function hasStunKeyword(s)
            if not s or s == "" then return false end
            local low = string.lower(s)
            for _, k in ipairs(_G.vanz.StunCfg.keywords) do
                if low:find(k, 1, true) then return true end
            end
            return false
        end

        local function isCharStunned(char)
            if not char or not char.Parent then return false end
            for _, attr in ipairs(char:GetAttributes()) do
                if hasStunKeyword(attr) and char:GetAttribute(attr) == true then
                    return true
                end
            end
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum then
                for _, attr in ipairs(hum:GetAttributes()) do
                    if hasStunKeyword(attr) and hum:GetAttribute(attr) == true then
                        return true
                    end
                end
            end
            if not hum then return false end
            local animator = hum:FindFirstChildOfClass("Animator")
            if not animator then return false end
            local ok, tracks = pcall(function() return animator:GetPlayingAnimationTracks() end)
            if ok and tracks then
                for _, t in ipairs(tracks) do
                    local anim = t.Animation
                    if anim then
                        local n = anim.Name or ""
                        if n ~= "" and hasStunKeyword(n) then
                            return true
                        end
                    end
                end
            end
            return false
        end

        local function createStunVisual(char)
            local head = char:FindFirstChild("Head")
            if not head then return nil end
            local bb = Instance.new("BillboardGui")
            bb.Name = "VanzStunVis"
            bb.Adornee = head
            bb.Size = UDim2.new(0, 150, 0, 46)
            bb.StudsOffsetWorldSpace = Vector3.new(0, 3.5, 0)
            bb.AlwaysOnTop = true
            bb.MaxDistance = math.huge
            bb.Parent = char

            local lbl = Instance.new("TextLabel")
            lbl.Size = UDim2.new(1, 0, 0, 22)
            lbl.BackgroundTransparency = 1
            lbl.Text = "STUNNED!!"
            lbl.TextColor3 = Color3.fromRGB(255, 210, 60)
            lbl.Font = Enum.Font.GothamBlack
            lbl.TextSize = _G.vanz.StunCfg.labelSize or 15
            lbl.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
            lbl.TextStrokeTransparency = 0.25
            lbl.Parent = bb

            local barBg = Instance.new("Frame")
            barBg.Size = UDim2.new(0.85, 0, 0, 8)
            barBg.Position = UDim2.new(0.075, 0, 0, 26)
            barBg.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
            barBg.BorderSizePixel = 0
            barBg.Parent = bb
            local bc = Instance.new("UICorner", barBg)
            bc.CornerRadius = UDim.new(0, 4)

            local fill = Instance.new("Frame")
            fill.Name = "Fill"
            fill.Size = UDim2.new(1, 0, 1, 0)
            fill.BackgroundColor3 = Color3.fromRGB(80, 220, 90)
            fill.BorderSizePixel = 0
            fill.Parent = barBg
            local fc = Instance.new("UICorner", fill)
            fc.CornerRadius = UDim.new(0, 4)

            return { bb = bb, bar = fill, startTime = os.clock(), forced = false }
        end

        local function destroyStunVisual(char)
            local v = _G.vanz.Runtime.StunVis[char]
            if v and v.bb then
                pcall(function() v.bb:Destroy() end)
            end
            _G.vanz.Runtime.StunVis[char] = nil
        end

        local function forceStunVisual(char)
            if not char or not char.Parent then return end
            if _G.vanz.Runtime.StunVis[char] then
                _G.vanz.Runtime.StunVis[char].startTime = os.clock()
                _G.vanz.Runtime.StunVis[char].forced = true
                return
            end
            local v = createStunVisual(char)
            if v then
                v.forced = true
                _G.vanz.Runtime.StunVis[char] = v
            end
        end

        local function findNearestKillerChar()
            local myChar = LocalPlayer.Character
            local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
            if not myRoot then return nil end
            local best, bd = nil, math.huge
            for _, p in ipairs(Players:GetPlayers()) do
                if p ~= LocalPlayer and p.Character then
                    local hrp = p.Character:FindFirstChild("HumanoidRootPart")
                    local hum = p.Character:FindFirstChildOfClass("Humanoid")
                    if hrp and hum and hum.Health > 0 then
                        local d = (hrp.Position - myRoot.Position).Magnitude
                        if d < bd then
                            bd = d
                            best = p.Character
                        end
                    end
                end
            end
            return best
        end

        local function extractCharFromArgs(...)
            local args = table.pack(...)
            for i = 1, args.n do
                local v = args[i]
                if typeof(v) == "Instance" then
                    if v:IsA("Player") and v.Character then
                        return v.Character
                    elseif v:IsA("Model") and v:FindFirstChild("Humanoid") then
                        return v
                    elseif v:IsA("Humanoid") then
                        return v.Parent
                    end
                end
            end
            return nil
        end

        local function signalIndicatesStun(selfName, ...)
            if hasStunKeyword(selfName) then return true end
            local args = table.pack(...)
            for i = 1, args.n do
                local v = args[i]
                if typeof(v) == "string" and hasStunKeyword(v) then
                    return true
                end
            end
            return false
        end

        local function hookStunRemote(rem)
            if not rem or not rem:IsA("RemoteEvent") then return end
            rem.OnClientEvent:Connect(function(...)
                if not signalIndicatesStun(rem.Name, ...) then return end
                local char = extractCharFromArgs(...) or findNearestKillerChar()
                if char then forceStunVisual(char) end
            end)
        end

        local remotes = RS:FindFirstChild("Remotes")
        if remotes then
            for _, d in ipairs(remotes:GetDescendants()) do
                if d:IsA("RemoteEvent") then
                    hookStunRemote(d)
                end
            end
            remotes.DescendantAdded:Connect(function(d)
                if d:IsA("RemoteEvent") then
                    hookStunRemote(d)
                end
            end)
        end

        local function attachCharWatchers(char)
            if not char then return end
            local hum = char:FindFirstChildOfClass("Humanoid")
            local animator = hum and hum:FindFirstChildOfClass("Animator")
            if animator then
                animator.AnimationPlayed:Connect(function(track)
                    local anim = track.Animation
                    if not anim then return end
                    local n = anim.Name or ""
                    if n ~= "" and hasStunKeyword(n) then
                        forceStunVisual(char)
                    end
                end)
            end
            char.AttributeChanged:Connect(function(attrName)
                if hasStunKeyword(tostring(attrName))
                and char:GetAttribute(attrName) == true then
                    forceStunVisual(char)
                end
            end)
            if hum then
                hum.AttributeChanged:Connect(function(attrName)
                    if hasStunKeyword(tostring(attrName))
                    and hum:GetAttribute(attrName) == true then
                        forceStunVisual(char)
                    end
                end)
            end
        end

        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and p.Character then
                attachCharWatchers(p.Character)
            end
            p.CharacterAdded:Connect(attachCharWatchers)
        end
        Players.PlayerAdded:Connect(function(p)
            p.CharacterAdded:Connect(attachCharWatchers)
        end)

        if _G.vanz.Runtime.StunUpdateConn then
            _G.vanz.Runtime.StunUpdateConn:Disconnect()
        end

        _G.vanz.Runtime.StunUpdateConn = RunService.RenderStepped:Connect(function()
            local vis = _G.vanz.Runtime.StunVis
            for _, player in ipairs(Players:GetPlayers()) do
                if player ~= LocalPlayer then
                    local char = player.Character
                    if char then
                        local stunned = isCharStunned(char)
                        local v = vis[char]
                        local has = v ~= nil
                        if v and v.forced then
                            if (os.clock() - v.startTime) > (_G.vanz.StunCfg.maxTime or 2) then
                                destroyStunVisual(char)
                                v = nil
                                has = false
                            end
                        end
                        if stunned and not has then
                            local nv = createStunVisual(char)
                            if nv then vis[char] = nv end
                        elseif not stunned and has and not vis[char].forced then
                            destroyStunVisual(char)
                        end
                        v = vis[char]
                        if v then
                            local el = os.clock() - v.startTime
                            local mx = _G.vanz.StunCfg.maxTime or 2
                            local frac = math.clamp(1 - el / mx, 0, 1)
                            v.bar.Size = UDim2.new(frac, 0, 1, 0)
                        end
                    end
                end
            end
            for char, v in pairs(vis) do
                if not char or not char.Parent then
                    if v and v.bb then pcall(function() v.bb:Destroy() end) end
                    vis[char] = nil
                end
            end
        end)
    end, function(err) warn("[VANZ ERROR][8_STUN] " .. tostring(err)) end)
end

--========================================================--
-- 9_HIGHLIGHT
--========================================================--
do
    xpcall(function()
        local Players = game:GetService("Players")
        local RunService = game:GetService("RunService")
        local LocalPlayer = Players.LocalPlayer

        local cfg = _G.vanz.HighlightCfg
        local depth = Enum.HighlightDepthMode.AlwaysOnTop
        if cfg.depthMode == "Occluded" then
            depth = Enum.HighlightDepthMode.Occluded
        end

        local function shouldHighlight(plr)
            if not plr or plr == LocalPlayer then return false end
            if _G.vanz.Classify then
                return _G.vanz.Classify(plr) == "enemy"
            end
            return false
        end

        local function applyHighlight(plr)
            if not plr then return end
            local char = plr.Character
            if not char then return end
            if shouldHighlight(plr) then
                if not char:FindFirstChild("VanzHighlight") then
                    local hl = Instance.new("Highlight")
                    hl.Name = "VanzHighlight"
                    hl.FillColor = cfg.fillColor
                    hl.FillTransparency = cfg.fillTrans
                    hl.OutlineColor = cfg.outlineColor
                    hl.OutlineTransparency = cfg.outlineTrans
                    hl.DepthMode = depth
                    hl.Adornee = char
                    hl.Parent = char
                end
            else
                local hl = char:FindFirstChild("VanzHighlight")
                if hl then hl:Destroy() end
            end
        end

        local function onChar(c)
            if not c then return end
            local plr = Players:GetPlayerFromCharacter(c)
            if plr then applyHighlight(plr) end
        end

        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer then
                if plr.Character then applyHighlight(plr) end
                plr.CharacterAdded:Connect(function(c)
                    task.defer(function() onChar(c) end)
                end)
            end
        end

        Players.PlayerAdded:Connect(function(plr)
            plr.CharacterAdded:Connect(function(c)
                task.defer(function() onChar(c) end)
            end)
        end)

        RunService.Heartbeat:Connect(function()
            for _, plr in ipairs(Players:GetPlayers()) do
                if plr ~= LocalPlayer then
                    local char = plr.Character
                    if char then
                        local should = shouldHighlight(plr)
                        local has = char:FindFirstChild("VanzHighlight") ~= nil
                        if should and not has then
                            applyHighlight(plr)
                        elseif not should and has then
                            local hl = char:FindFirstChild("VanzHighlight")
                            if hl then hl:Destroy() end
                        end
                    end
                end
            end
        end)
    end, function(err) warn("[VANZ ERROR][9_HL] " .. tostring(err)) end)
end

--========================================================--
-- 10_GOD_MODE
--========================================================--
do
    xpcall(function()
        local RS = game:GetService("ReplicatedStorage")
        local EnableCollision
        pcall(function() EnableCollision = RS.Remotes.Collision.EnableCollision end)

        local godThread = nil

        local function stopGod()
            if godThread then
                pcall(task.cancel, godThread)
                godThread = nil
            end
        end

        local function startGod()
            stopGod()
            if not EnableCollision then return end
            local interval = _G.vanz.GodCfg.interval or 0.1
            godThread = task.spawn(function()
                while _G.vanz.Settings.GodMode do
                    pcall(function() EnableCollision:FireServer() end)
                    task.wait(interval)
                end
            end)
        end

        _G.vanz.Events.GodMode = function(enabled)
            if enabled then startGod() else stopGod() end
        end
    end, function(err) warn("[VANZ ERROR][10_GOD] " .. tostring(err)) end)
end

--========================================================--
-- 11_FAST_HEAL (remote only, no button)
--========================================================--
do
    xpcall(function()
        local Players = game:GetService("Players")
        local LocalPlayer = Players.LocalPlayer
        local RS = game:GetService("ReplicatedStorage")

        local HealEvent
        pcall(function() HealEvent = RS.Remotes.Healing.HealEvent end)

        local fastThread = nil

        local function stopFast()
            if fastThread then
                pcall(task.cancel, fastThread)
                fastThread = nil
            end
        end

        local function startFast()
            stopFast()
            if not HealEvent then
                warn("[VANZ][FastHeal] HealEvent gak ketemu.")
                return
            end

            local interval = _G.vanz.FastHealCfg.interval or 0.001
            fastThread = task.spawn(function()
                while _G.vanz.Settings.FastHeal do
                    local char = LocalPlayer.Character
                    if char then
                        local hrp = char:FindFirstChild("HumanoidRootPart")
                        if hrp then
                            pcall(function()
                                HealEvent:FireServer(hrp, true)
                            end)
                        end
                    end
                    task.wait(interval)
                end
            end)
        end

        _G.vanz.Events.FastHeal = function(enabled)
            if enabled then startFast() else stopFast() end
        end
    end, function(err) warn("[VANZ ERROR][11_HEAL] " .. tostring(err)) end)
end

--========================================================--
-- 12_BLOCKER
--========================================================--
do
    xpcall(function()
        local Players = game:GetService("Players")
        local LocalPlayer = Players.LocalPlayer
        local RS = game:GetService("ReplicatedStorage")

        local function safeFind(root, a, b, c)
            local n = root
            if a then n = n and n:FindFirstChild(a) end
            if b then n = n and n:FindFirstChild(b) end
            if c then n = n and n:FindFirstChild(c) end
            return n
        end

        local remotes = RS:FindFirstChild("Remotes") or RS:WaitForChild("Remotes", 10)
        if not remotes then return end

        local R_Emote      = safeFind(remotes, "EmoteHandler")
        local R_DisCol     = safeFind(remotes, "Collision", "DisableCollision")
        local R_RunEvent   = safeFind(remotes, "Chase", "Runevent")
        local R_ChangeAttr = safeFind(remotes, "Mechanics", "ChangeAttribute")
        local R_HealReset  = safeFind(remotes, "Healing", "Reset")

        local LOG = {}
        _G.vanz.Runtime.BlockLog = LOG

        local function log(tag)
            LOG[#LOG + 1] = tag
            if #LOG > 40 then table.remove(LOG, 1) end
            if _G.vanz.BlockCfg.debug then
                print("[VANZ BLOCK]", tag)
            end
        end

        local function check(self, args)
            if not _G.vanz.Settings.GodMode then return nil end
            if rawequal(self, R_Emote) and args[1] == "StopEmote" then
                return "Emote:StopEmote"
            end
            if rawequal(self, R_DisCol) then
                return "DisableCollision"
            end
            if rawequal(self, R_RunEvent) and args[2] == false then
                return "Runevent:false"
            end
            if rawequal(self, R_ChangeAttr)
            and args[1] == "Crouchingserver"
            and args[2] == false then
                return "ChangeAttr:Crouch"
            end
            if rawequal(self, R_HealReset) and rawequal(args[1], LocalPlayer) then
                return "HealReset:self"
            end
            return nil
        end

        local mt = getrawmetatable(game)
        if not mt or not mt.__namecall then
            warn("[VANZ] metatable tidak support.")
            return
        end

        local oldNC = mt.__namecall
        local newNC = function(self, ...)
            if getnamecallmethod() == "FireServer" then
                local args = table.pack(...)
                local tag = check(self, args)
                if tag then
                    log(tag)
                    return nil
                end
                return oldNC(self, table.unpack(args, 1, args.n))
            end
            return oldNC(self, ...)
        end

        local ok = pcall(function()
            setreadonly(mt, false)
            mt.__namecall = newNC
            setreadonly(mt, true)
        end)

        if not ok then
            pcall(function()
                hookmetamethod(game, "__namecall", newNC)
            end)
        end

        print("[VANZ] Blocker ready.")
    end, function(err) warn("[VANZ ERROR][12_BLOCK] " .. tostring(err)) end)
end