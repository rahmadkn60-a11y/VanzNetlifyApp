-- ==========================================
-- CLEANUP TOTAL
-- ==========================================
for _, v in pairs(game:GetService("Workspace"):GetDescendants()) do
    if v:IsA("Highlight") or v:IsA("BillboardGui") then
        pcall(function() v:Destroy() end)
    end
end
if getgenv().vanzCheat and getgenv().vanzCheat.running then
    pcall(function() getgenv().vanzCheat.shutdown() end)
end

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local lp = Players.LocalPlayer
local PG = lp:WaitForChild("PlayerGui")

local S = getgenv().vanzCheat or {}
getgenv().vanzCheat = S

S.running = true
S.enabledESP = true
S.winPos = S.winPos or UDim2.new(0.5, 0, 0.5, 0) -- Center Anchor
S.miniPos = S.miniPos or UDim2.new(0.5, -25, 0.5, -25)
S.lockUI = false

S.toggles = S.toggles or {
    Killer = true, Survivor = true, Generator = true,
    Pallet = true, Hook = true, Vault = true, Trap = true, Gate = true,
}

S.autoSkillEnabled = S.autoSkillEnabled or false
S.skillMode = S.skillMode or "INSTANT"

local COLORS = {
    Killer = Color3.fromRGB(255, 0, 0),
    Survivor = Color3.fromRGB(0, 0, 255),
    Generator = Color3.fromRGB(255, 165, 0),
    GeneratorDone = Color3.fromRGB(255, 255, 255),
    Pallet = Color3.fromRGB(139, 69, 19),
    Hook = Color3.fromRGB(128, 0, 128),
    Vault = Color3.fromRGB(135, 206, 235),
    Trap = Color3.fromRGB(255, 192, 203),
    Gate = Color3.fromRGB(255, 255, 255),
    Item = Color3.fromRGB(255, 255, 255)
}

local espCache = {}
local localGenProgress = {}
local gui = nil
local mainFrame = nil

local function getUIParent()
    if gethui then
        local ok, h = pcall(gethui)
        if ok and h then return h end
    end
    if syn and syn.protect_gui then return CoreGui end
    return PG
end

-- ==========================================
-- LOGIKA SKILL CHECK
-- ==========================================
local SKILL = {
    Check = nil, Line = nil, Goal = nil, Action = nil,
    LastTrigger = 0, Busy = false, LastVisible = false,
    SuccessMin = 102, SuccessMax = 116,
    NeutralMin = 116, NeutralMax = 159,
    InstantAngle = 109, TriggerDelay = 0.035
}

local function refreshSkillRefs()
    pcall(function()
        local skillGui = PG:FindFirstChild("SkillCheckPromptGui")
        if skillGui then
            SKILL.Check = skillGui:FindFirstChild("Check")
            if SKILL.Check then
                SKILL.Line = SKILL.Check:FindFirstChild("Line")
                SKILL.Goal = SKILL.Check:FindFirstChild("Goal")
            end
        end
        local survivor = PG:FindFirstChild("Survivor-mob")
        if survivor then
            local controls = survivor:FindFirstChild("Controls")
            if controls then SKILL.Action = controls:FindFirstChild("action") end
        end
    end)
end

local function triggerSkill()
    if not SKILL.Action then refreshSkillRefs() end
    if not SKILL.Action then return end
    local now = os.clock()
    if now - SKILL.LastTrigger < SKILL.TriggerDelay then return end
    SKILL.LastTrigger = now

    pcall(function() if SKILL.Action:IsA("GuiButton") then SKILL.Action:Activate() end end)
    pcall(function() firesignal(SKILL.Action.MouseButton1Down) end)
    pcall(function() firesignal(SKILL.Action.MouseButton1Up) end)
end

local function getAngles()
    if not SKILL.Line or not SKILL.Goal then return nil, nil end
    return tonumber(SKILL.Line.Rotation) or 0, tonumber(SKILL.Goal.Rotation) or 0
end

task.spawn(function()
    while S.running do
        if tick() % 1 < 0.02 then refreshSkillRefs() end
        
        if S.autoSkillEnabled and SKILL.Check then
            local isVisible = SKILL.Check.Visible
            
            if isVisible and not SKILL.LastVisible then
                SKILL.Busy = false
                if S.skillMode == "INSTANT" then
                    local _, gr = getAngles()
                    if gr and SKILL.Line then
                        SKILL.Line.Rotation = gr + SKILL.InstantAngle
                        task.wait(0.01)
                        triggerSkill()
                    end
                end
            end
            
            if isVisible and not SKILL.Busy then
                local lr, gr = getAngles()
                if lr and gr then
                    local should = false
                    if S.skillMode == "SUCCESS" then
                        should = (lr >= gr + SKILL.SuccessMin and lr <= gr + SKILL.SuccessMax)
                    elseif S.skillMode == "NEUTRAL" then
                        should = (lr > gr + SKILL.NeutralMin and lr <= gr + SKILL.NeutralMax)
                    end
                    
                    if should then
                        SKILL.Busy = true
                        triggerSkill()
                        task.delay(0.07, function() SKILL.Busy = false end)
                    end
                end
            end
            SKILL.LastVisible = isVisible
        else
            SKILL.LastVisible = false
        end
        task.wait(0.016)
    end
end)

-- ==========================================
-- LISTENER INSTAN GEN
-- ==========================================
task.spawn(function()
    local remote = ReplicatedStorage:FindFirstChild("Remotes")
    if remote then remote = remote:FindFirstChild("Progress") end
    if remote then remote = remote:FindFirstChild("ProgressUpdateEvent") end
    if remote and remote:IsA("RemoteEvent") then
        remote.OnClientEvent:Connect(function(progress, labelText)
            if labelText == "REPAIR" and typeof(progress) == "number" then
                local char = lp.Character
                if not char then return end
                local hrp = char:FindFirstChild("HumanoidRootPart")
                if not hrp then return end
                
                local closestGen, minDist = nil, 20
                local taggedGens = CollectionService:GetTagged("Generator")
                if #taggedGens == 0 then
                    local mapF = Workspace:FindFirstChild("Map")
                    if mapF then
                        for _, obj in ipairs(mapF:GetChildren()) do
                            if obj.Name == "Generator" and obj:IsA("Model") then table.insert(taggedGens, obj) end
                        end
                    end
                end
                
                for _, gen in ipairs(taggedGens) do
                    local dist = (hrp.Position - gen:GetPivot().Position).Magnitude
                    if dist < minDist then minDist = dist; closestGen = gen end
                end
                
                if closestGen then localGenProgress[closestGen] = progress end
            end
        end)
    end
end)

-- ==========================================
-- DETEKSI ITEM
-- ==========================================
local function getEquippedItem(char)
    local twist = char:FindFirstChild("Twist of Fate")
    if twist then return twist.Name end
    local weapon = char:FindFirstChild("Weapon")
    if weapon then 
        local trap = weapon:FindFirstChild("BearTrap")
        if trap and trap:GetAttribute("ButcherCarriedTrap") then return "Weapon (Carrying Trap)" end
        return weapon.Name 
    end
    
    local ignored = {
        ["Torso"] = true, ["Head"] = true, ["Humanoid"] = true, ["Left Arm"] = true, ["Right Arm"] = true,
        ["Left Leg"] = true, ["Right Leg"] = true, ["HumanoidRootPart"] = true, ["Hat"] = true, ["cassette"] = true, 
        ["Animations-new"] = true, ["HRP_Clone"] = true, ["CheckInterractable"] = true, ["Animate"] = true,
        ["Health"] = true, ["Sound"] = true, ["Killerost"] = true, ["Lookscriptkiller"] = true,
        ["Lookscript"] = true, ["Camera resetter"] = true, ["carriedtransparency"] = true, ["cutscene"] = true,
        ["VMscript"] = true, ["R6RagdollClient"] = true, ["Firstperson"] = true, ["PursuitPalletPredict"] = true,
        ["Instinct"] = true, ["pamela"] = true, ["CamShake"] = true, ["Animations"] = true, ["Powers"] = true,
        ["Highlight-new"] = true, ["BasicAttack"] = true, ["MaterialSounds"] = true, ["ProgressBar"] = true,
        ["Highlight-forsurvivor"] = true
    }
    for _, child in ipairs(char:GetChildren()) do
        if child:IsA("Tool") then return child.Name end
        if child:IsA("Model") and not ignored[child.Name] then return child.Name end
    end
    return nil
end

-- ==========================================
-- FUNGSI ESP
-- ==========================================
local function createESP(obj, color, mainText, subText)
    local h = Instance.new("Highlight")
    h.FillColor = color; h.OutlineColor = color
    h.FillTransparency = 0.4; h.OutlineTransparency = 0
    h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop; h.Parent = obj

    local bg = Instance.new("BillboardGui")
    bg.Size = UDim2.new(0, 200, 0, 40); bg.StudsOffset = Vector3.new(0, 2, 0)
    bg.AlwaysOnTop = true; bg.Parent = obj

    local lblMain = Instance.new("TextLabel")
    lblMain.Size = UDim2.new(1, 0, 0.5, 0); lblMain.Position = UDim2.new(0, 0, 0, 0)
    lblMain.BackgroundTransparency = 1; lblMain.Text = mainText; lblMain.TextColor3 = color
    lblMain.TextStrokeTransparency = 0; lblMain.Font = Enum.Font.GothamBold; lblMain.TextSize = 11; lblMain.Parent = bg

    local lblSub = Instance.new("TextLabel")
    lblSub.Size = UDim2.new(1, 0, 0.5, 0); lblSub.Position = UDim2.new(0, 0, 0.5, 0)
    lblSub.BackgroundTransparency = 1; lblSub.Text = subText or ""; lblSub.TextColor3 = COLORS.Item
    lblSub.TextStrokeTransparency = 0; lblSub.Font = Enum.Font.Gotham; lblSub.TextSize = 10; lblSub.Parent = bg

    return {highlight = h, billboard = bg, label = lblMain, sub = lblSub}
end

local function updateESP(obj, color, mainText, subText)
    if not espCache[obj] then
        espCache[obj] = createESP(obj, color, mainText, subText)
    else
        local esp = espCache[obj]
        if esp.label.Text ~= mainText then esp.label.Text = mainText end
        if esp.label.TextColor3 ~= color then esp.label.TextColor3 = color end
        if esp.highlight.FillColor ~= color then esp.highlight.FillColor = color end
        if esp.highlight.OutlineColor ~= color then esp.highlight.OutlineColor = color end
        local sText = subText or ""
        if esp.sub.Text ~= sText then esp.sub.Text = sText end
    end
end

local function cleanESP(obj)
    if espCache[obj] then
        pcall(function() espCache[obj].highlight:Destroy() end)
        pcall(function() espCache[obj].billboard:Destroy() end)
        espCache[obj] = nil
    end
end

-- ==========================================
-- 1. LOOP DINAMIS (Karakter & Generator)
-- ==========================================
task.spawn(function()
    while S.running do
        if S.enabledESP then
            local char = lp.Character
            local myHRP = char and char:FindFirstChild("HumanoidRootPart")
            
            if char and myHRP then
                for _, p in ipairs(Players:GetPlayers()) do
                    if p.Character then
                        local targetChar = p.Character
                        local thum = targetChar:FindFirstChildOfClass("Humanoid")
                        local targetHRP = targetChar:FindFirstChild("HumanoidRootPart")
                        
                        if thum and thum.Health > 0 and targetHRP then
                            local isKiller = targetChar:FindFirstChild("Lookscriptkiller", true) ~= nil
                            local typeStr = isKiller and "Killer" or "Survivor"
                            
                            if S.toggles[typeStr] then
                                local dist = math.floor((myHRP.Position - targetHRP.Position).Magnitude)
                                local itemName = getEquippedItem(targetChar)
                                local mainText = string.format("%s | %s | %dm", typeStr, p.Name, dist)
                                updateESP(targetChar, COLORS[typeStr], mainText, itemName)
                            else cleanESP(targetChar) end
                        end
                    end
                end

                if S.toggles.Generator then
                    local taggedGens = CollectionService:GetTagged("Generator")
                    if #taggedGens == 0 then
                        local mapF = Workspace:FindFirstChild("Map")
                        if mapF then
                            for _, obj in ipairs(mapF:GetChildren()) do
                                if obj.Name == "Generator" and obj:IsA("Model") then table.insert(taggedGens, obj) end
                            end
                        end
                    end

                    for _, gen in ipairs(taggedGens) do
                        local attrProg = gen:GetAttribute("RepairProgress") or 0
                        local remoteProg = localGenProgress[gen]
                        local finalProg = attrProg
                        if remoteProg and remoteProg > attrProg then finalProg = remoteProg end
                        if finalProg >= 99.5 then finalProg = 100 end
                        
                        local color = (finalProg >= 100) and COLORS.GeneratorDone or COLORS.Generator
                        local text = string.format("Gen: %d%%", math.floor(finalProg))
                        updateESP(gen, color, text, "")
                    end
                end
            end
        else
            for obj, _ in pairs(espCache) do cleanESP(obj) end
        end
        task.wait(0.016)
    end
end)

-- ==========================================
-- 2. LOOP STATIS (Map, tiap 5 Detik)
-- ==========================================
task.spawn(function()
    while S.running do
        if S.enabledESP then
            local char = lp.Character
            if char then
                for obj, _ in pairs(espCache) do
                    if not obj or not obj.Parent then cleanESP(obj) end
                end

                local mapF = Workspace:FindFirstChild("Map")
                if mapF then
                    for _, obj in ipairs(mapF:GetDescendants()) do
                        if S.toggles.Pallet and obj.Name == "Newpallet" then
                            local isBroken = obj:FindFirstChild("Broken") ~= nil
                            updateESP(obj, COLORS.Pallet, isBroken and "Pallet (Broken)" or "Pallet", "")
                        end
                        if S.toggles.Hook and obj.Name == "Hook" and obj:IsA("Model") and obj:FindFirstChild("HookPoint") then
                            updateESP(obj, COLORS.Hook, "Hook", "")
                        end
                        if S.toggles.Gate and obj.Name == "Gate" and obj:IsA("Model") and obj:FindFirstChild("LeftGate") then
                            updateESP(obj, COLORS.Gate, "Gate", "")
                        end
                        if S.toggles.Gate and obj.Name == "ExitLever" and obj:IsA("Model") then
                            updateESP(obj, COLORS.Gate, "Lever", "")
                        end
                        if S.toggles.Vault and obj.Name == "VaultTrigger" and obj:IsA("BasePart") then
                            updateESP(obj, COLORS.Vault, "Vault", "")
                        end
                        if S.toggles.Trap and obj.Name == "BearTrap" and obj:IsA("Model") then
                            local isArmed = obj:GetAttribute("Armed")
                            local isPlaced = obj:GetAttribute("ButcherTrapOwnerUserId") ~= nil
                            if isArmed or isPlaced then updateESP(obj, COLORS.Trap, "TRAP", "") end
                        end
                    end
                end
                
                if S.toggles.Trap then
                    for _, obj in ipairs(Workspace:GetChildren()) do
                        if obj.Name == "BearTrap" and obj:IsA("Model") then
                            if obj:GetAttribute("Armed") then updateESP(obj, COLORS.Trap, "TRAP", "") end
                        end
                    end
                end
            end
        end
        task.wait(5)
    end
end)

-- ==========================================
-- UI SETUP (TABBED + 85% HEIGHT + ANCHOR)
-- ==========================================
local function buildUI()
    if gui then pcall(function() gui:Destroy() end) end
    
    gui = Instance.new("ScreenGui")
    gui.Name = "VanzCheat"; gui.ResetOnSpawn = false; gui.IgnoreGuiInset = true
    gui.DisplayOrder = 2147483647; gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    gui.Parent = getUIParent()

    local function mk(cls, props, parent)
        local i = Instance.new(cls)
        for k, v in pairs(props) do i[k] = v end
        if parent then i.Parent = parent end
        return i
    end

    -- 85% tinggi, pas di tengah
    mainFrame = mk("Frame", { 
        Size = UDim2.new(0, 280, 0.85, 0), 
        Position = UDim2.new(0.5, 0, 0.5, 0), 
        AnchorPoint = Vector2.new(0.5, 0.5), 
        BackgroundColor3 = Color3.fromRGB(26, 26, 26), 
        BorderSizePixel = 0 
    }, gui)
    mk("UICorner", {CornerRadius = UDim.new(0, 8)}, mainFrame)
    mk("UIStroke", {Color = Color3.fromRGB(50, 50, 50), Thickness = 1}, mainFrame)

    -- TitleBar dinaikin dikit biar gampang di-drag di HP
    local titleBar = mk("Frame", { Size = UDim2.new(1, 0, 0, 44), BackgroundColor3 = Color3.fromRGB(20, 20, 20), BorderSizePixel = 0 }, mainFrame)
    mk("UICorner", {CornerRadius = UDim.new(0, 8)}, titleBar)
    mk("TextLabel", { Size = UDim2.new(1, -160, 1, 0), Position = UDim2.new(0, 12, 0, 0), BackgroundTransparency = 1, Text = "VANZ MULTI-CHEAT", TextColor3 = Color3.fromRGB(255, 255, 255), Font = Enum.Font.GothamBold, TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left }, titleBar)

    local function mkBtn(text, xOff, parent)
        local b = mk("TextButton", { Size = UDim2.new(0, 36, 0, 36), Position = UDim2.new(1, xOff, 0.5, -18), BackgroundColor3 = Color3.fromRGB(45, 45, 45), Text = text, TextColor3 = Color3.fromRGB(220, 220, 220), Font = Enum.Font.GothamBold, TextSize = 14, BorderSizePixel = 0 }, parent)
        mk("UICorner", {CornerRadius = UDim.new(0, 6)}, b)
        return b
    end

    local lockBtn = mkBtn("🔓", -120, titleBar)
    local minBtn = mkBtn("─", -80, titleBar)
    local closeBtn = mkBtn("✕", -40, titleBar)

    -- TABS
    local tabFrame = mk("Frame", { Size = UDim2.new(1, 0, 0, 40), Position = UDim2.new(0, 0, 0, 44), BackgroundTransparency = 1 }, mainFrame)
    local function createTab(text, xPos, width)
        return mk("TextButton", { Size = UDim2.new(width, -4, 1, -4), Position = UDim2.new(xPos, 2, 0, 2), BackgroundColor3 = Color3.fromRGB(40, 40, 40), Text = text, TextColor3 = Color3.fromRGB(200, 200, 200), Font = Enum.Font.GothamBold, TextSize = 12, BorderSizePixel = 0 }, tabFrame)
    end
    local tabESP = createTab("ESP", 0, 0.5); mk("UICorner", {CornerRadius = UDim.new(0, 6)}, tabESP)
    local tabSurv = createTab("SURVIVOR", 0.5, 0.5); mk("UICorner", {CornerRadius = UDim.new(0, 6)}, tabSurv)

    local contentFrame = mk("Frame", { Size = UDim2.new(1, 0, 1, -84), Position = UDim2.new(0, 0, 0, 84), BackgroundTransparency = 1 }, mainFrame)

    -- TAB 1: ESP
    local espPage = mk("ScrollingFrame", { Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 4, CanvasSize = UDim2.new(0, 0, 0, 0), AutomaticCanvasSize = Enum.AutomaticSize.Y }, contentFrame)
    
    local masterRow = mk("Frame", { Size = UDim2.new(1, -16, 0, 44), Position = UDim2.new(0, 8, 0, 8), BackgroundTransparency = 1 }, espPage)
    mk("TextLabel", { Size = UDim2.new(1, -70, 1, 0), BackgroundTransparency = 1, Text = "Master ESP", TextColor3 = Color3.fromRGB(255, 255, 255), Font = Enum.Font.GothamBold, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left }, masterRow)
    local masterToggle = mk("TextButton", { Size = UDim2.new(0, 60, 0, 30), Position = UDim2.new(1, -60, 0.5, -15), BackgroundColor3 = S.enabledESP and Color3.fromRGB(40, 140, 70) or Color3.fromRGB(60, 60, 60), Text = S.enabledESP and "ON" or "OFF", TextColor3 = Color3.fromRGB(255, 255, 255), Font = Enum.Font.GothamBold, TextSize = 11, BorderSizePixel = 0 }, masterRow)
    mk("UICorner", {CornerRadius = UDim.new(0, 5)}, masterToggle)
    masterToggle.MouseButton1Click:Connect(function()
        S.enabledESP = not S.enabledESP
        masterToggle.Text = S.enabledESP and "ON" or "OFF"
        masterToggle.BackgroundColor3 = S.enabledESP and Color3.fromRGB(40, 140, 70) or Color3.fromRGB(60, 60, 60)
    end)

    local espList = {"Killer", "Survivor", "Generator", "Pallet", "Hook", "Vault", "Trap", "Gate"}
    local espY = 56
    for _, name in ipairs(espList) do
        local row = mk("Frame", { Size = UDim2.new(1, -16, 0, 44), Position = UDim2.new(0, 8, 0, espY), BackgroundTransparency = 1 }, espPage)
        mk("TextLabel", { Size = UDim2.new(1, -70, 1, 0), BackgroundTransparency = 1, Text = name .. " ESP", TextColor3 = Color3.fromRGB(200, 200, 200), Font = Enum.Font.Gotham, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left }, row)
        local toggle = mk("TextButton", { Size = UDim2.new(0, 60, 0, 30), Position = UDim2.new(1, -60, 0.5, -15), BackgroundColor3 = S.toggles[name] and Color3.fromRGB(40, 140, 70) or Color3.fromRGB(60, 60, 60), Text = S.toggles[name] and "ON" or "OFF", TextColor3 = Color3.fromRGB(255, 255, 255), Font = Enum.Font.GothamBold, TextSize = 11, BorderSizePixel = 0 }, row)
        mk("UICorner", {CornerRadius = UDim.new(0, 5)}, toggle)
        toggle.MouseButton1Click:Connect(function()
            S.toggles[name] = not S.toggles[name]
            toggle.Text = S.toggles[name] and "ON" or "OFF"
            toggle.BackgroundColor3 = S.toggles[name] and Color3.fromRGB(40, 140, 70) or Color3.fromRGB(60, 60, 60)
        end)
        espY = espY + 44
    end

    -- TAB 2: SURVIVOR
    local survPage = mk("Frame", { Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Visible = false }, contentFrame)
    
    local skillRow = mk("Frame", { Size = UDim2.new(1, -16, 0, 44), Position = UDim2.new(0, 8, 0, 8), BackgroundTransparency = 1 }, survPage)
    mk("TextLabel", { Size = UDim2.new(1, -70, 1, 0), BackgroundTransparency = 1, Text = "Auto Skill Check", TextColor3 = Color3.fromRGB(200, 200, 200), Font = Enum.Font.Gotham, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left }, skillRow)
    local skillToggle = mk("TextButton", { Size = UDim2.new(0, 60, 0, 30), Position = UDim2.new(1, -60, 0.5, -15), BackgroundColor3 = S.autoSkillEnabled and Color3.fromRGB(40, 140, 70) or Color3.fromRGB(60, 60, 60), Text = S.autoSkillEnabled and "ON" or "OFF", TextColor3 = Color3.fromRGB(255, 255, 255), Font = Enum.Font.GothamBold, TextSize = 11, BorderSizePixel = 0 }, skillRow)
    mk("UICorner", {CornerRadius = UDim.new(0, 5)}, skillToggle)
    skillToggle.MouseButton1Click:Connect(function()
        S.autoSkillEnabled = not S.autoSkillEnabled
        skillToggle.Text = S.autoSkillEnabled and "ON" or "OFF"
        skillToggle.BackgroundColor3 = S.autoSkillEnabled and Color3.fromRGB(40, 140, 70) or Color3.fromRGB(60, 60, 60)
    end)

    local modeRow = mk("Frame", { Size = UDim2.new(1, -16, 0, 44), Position = UDim2.new(0, 8, 0, 56), BackgroundTransparency = 1 }, survPage)
    mk("TextLabel", { Size = UDim2.new(1, -70, 1, 0), BackgroundTransparency = 1, Text = "Skill Mode", TextColor3 = Color3.fromRGB(200, 200, 200), Font = Enum.Font.Gotham, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left }, modeRow)
    local modeBtn = mk("TextButton", { Size = UDim2.new(0, 80, 0, 30), Position = UDim2.new(1, -80, 0.5, -15), BackgroundColor3 = Color3.fromRGB(45, 45, 60), Text = S.skillMode, TextColor3 = Color3.fromRGB(255, 255, 255), Font = Enum.Font.GothamBold, TextSize = 11, BorderSizePixel = 0 }, modeRow)
    mk("UICorner", {CornerRadius = UDim.new(0, 5)}, modeBtn)
    local modes = {"INSTANT", "SUCCESS", "NEUTRAL"}
    local modeIdx = 1
    modeBtn.MouseButton1Click:Connect(function()
        modeIdx = modeIdx % #modes + 1
        S.skillMode = modes[modeIdx]
        modeBtn.Text = S.skillMode
    end)

    -- FLOATING BUTTON
    local miniBtnFrame = mk("TextButton", { Size = UDim2.new(0, 50, 0, 50), Position = S.miniPos, BackgroundColor3 = Color3.fromRGB(26, 26, 26), Text = "VC", TextColor3 = Color3.fromRGB(255, 255, 255), Font = Enum.Font.GothamBold, TextSize = 16, BorderSizePixel = 0, Visible = false }, gui)
    mk("UICorner", {CornerRadius = UDim.new(0, 10)}, miniBtnFrame)
    mk("UIStroke", {Color = Color3.fromRGB(60, 60, 60), Thickness = 1}, miniBtnFrame)

    local miniDragging, miniDragStart, miniStartPos = false, nil, nil
    miniBtnFrame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            miniDragging, miniDragStart, miniStartPos = true, input.Position, miniBtnFrame.Position
            input.Changed:Connect(function() if input.UserInputState == Enum.UserInputState.End then miniDragging = false end end)
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if miniDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - miniDragStart
            miniBtnFrame.Position = UDim2.new(miniStartPos.X.Scale, miniStartPos.X.Offset + delta.X, miniStartPos.Y.Scale, miniStartPos.Y.Offset + delta.Y)
            S.miniPos = miniBtnFrame.Position
        end
    end)
    local miniMoved = false
    miniBtnFrame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            miniMoved = false
            local start = miniBtnFrame.Position
            task.delay(0.15, function() if miniBtnFrame.Position ~= start then miniMoved = true end end)
        end
    end)
    miniBtnFrame.MouseButton1Click:Connect(function() if not miniMoved then miniBtnFrame.Visible = false; mainFrame.Visible = true end end)

    minBtn.MouseButton1Click:Connect(function()
        S.miniPos = UDim2.new(0.5, -25, 0.5, -25)
        miniBtnFrame.Position = S.miniPos
        mainFrame.Visible = false
        miniBtnFrame.Visible = true
    end)

    local dragging, dragStart, startPos = false, nil, nil
    titleBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            if S.lockUI then return end
            dragging, dragStart, startPos = true, input.Position, mainFrame.Position
            input.Changed:Connect(function() if input.UserInputState == Enum.UserInputState.End then dragging = false end end)
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            mainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
            S.winPos = mainFrame.Position
        end
    end)

    lockBtn.MouseButton1Click:Connect(function() S.lockUI = not S.lockUI; lockBtn.Text = S.lockUI and "🔒" or "🔓" end)
    closeBtn.MouseButton1Click:Connect(function() S.shutdown() end)

    local function setTab(tabName)
        espPage.Visible = tabName == "ESP"
        survPage.Visible = tabName == "SURVIVOR"
        tabESP.BackgroundColor3 = tabName == "ESP" and Color3.fromRGB(60, 60, 60) or Color3.fromRGB(30, 30, 30)
        tabSurv.BackgroundColor3 = tabName == "SURVIVOR" and Color3.fromRGB(60, 60, 60) or Color3.fromRGB(30, 30, 30)
    end
    tabESP.MouseButton1Click:Connect(function() setTab("ESP") end)
    tabSurv.MouseButton1Click:Connect(function() setTab("SURVIVOR") end)
    setTab("ESP")
end

function S.shutdown()
    S.running = false
    for obj, _ in pairs(espCache) do cleanESP(obj) end
    pcall(function() if gui then gui:Destroy() end end)
    getgenv().vanzCheat = nil
end

buildUI()

task.spawn(function()
    while S.running do
        task.wait(1)
        if not S.running then break end
        if not gui or not gui.Parent then buildUI() end
        if gui and gui.Enabled == false then gui.Enabled = true end
    end
end)

print("[VANZ MULTI-CHEAT] Loaded v3.5 (Center Anchor + Bigger Buttons).")