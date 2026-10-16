local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local RS = game:GetService("ReplicatedStorage")

local LP = Players.LocalPlayer
local PG = LP:WaitForChild("PlayerGui")

local function getParent()
    if gethui then
        local ok, h = pcall(gethui)
        if ok and h then return h end
    end
    return PG
end

local REPAIR = RS:WaitForChild("Remotes"):WaitForChild("Generator"):WaitForChild("RepairEvent")
local PROGRESS = RS:WaitForChild("Remotes"):WaitForChild("Progress"):WaitForChild("ProgressUpdateEvent")

local ROOT_NAMES = { "newGenerators", "Generators", "Generator" }

local SKILL = {
    Mode = "INSTANT",
    SuccessMin = 102,
    SuccessMax = 116,
    NeutralMin = 116,
    NeutralMax = 159,
    InstantAngle = 109,
    TriggerDelay = 0.035,
    LastTrigger = 0,
    Busy = false,
    PreviousVisible = false,
    ScourgeActive = false,
    Check = nil,
    Line = nil,
    Goal = nil,
    Action = nil,
}

local S = {
    Active = false,
    Locked = false,
    GenIndex = nil,
    GenModel = nil,
    Points = {},
    WatchThread = nil,
    KeepThread = nil,
}

local function clearPoints()
    S.Points = {}
    S.GenIndex = nil
    S.GenModel = nil
end

local function fireRepairAll(state)
    for _, p in ipairs(S.Points) do
        pcall(function() REPAIR:FireServer(p, state) end)
    end
end

local function refreshSkillRefs()
    pcall(function()
        local SkillGui = PG:FindFirstChild("SkillCheckPromptGui")
        if SkillGui then
            SKILL.Check = SkillGui:FindFirstChild("Check")
            if SKILL.Check then
                SKILL.Line = SKILL.Check:FindFirstChild("Line")
                SKILL.Goal = SKILL.Check:FindFirstChild("Goal")
            end
        end
        local Survivor = PG:FindFirstChild("Survivor-mob")
        if Survivor then
            local Controls = Survivor:FindFirstChild("Controls")
            if Controls then
                SKILL.Action = Controls:FindFirstChild("action")
            end
        end
    end)
end

refreshSkillRefs()
task.spawn(function()
    while true do
        refreshSkillRefs()
        task.wait(0.5)
    end
end)

local function triggerAction()
    if not SKILL.Action then
        refreshSkillRefs()
    end
    if not SKILL.Action then return false end

    local now = os.clock()
    if now - SKILL.LastTrigger < SKILL.TriggerDelay then
        return false
    end
    SKILL.LastTrigger = now

    pcall(function()
        if SKILL.Action:IsA("GuiButton") then
            SKILL.Action:Activate()
        end
    end)

    if typeof(firesignal) == "function" then
        pcall(function() firesignal(SKILL.Action.MouseButton1Down) end)
    end

    return true
end

local function getAngle()
    if not SKILL.Line or not SKILL.Goal then return nil end
    return tonumber(SKILL.Line.Rotation) or 0, tonumber(SKILL.Goal.Rotation) or 0
end

local function isSuccess()
    local lr, gr = getAngle()
    if not lr then return false end
    return lr >= (gr + SKILL.SuccessMin) and lr <= (gr + SKILL.SuccessMax)
end

local function isNeutral()
    local lr, gr = getAngle()
    if not lr then return false end
    return lr > (gr + SKILL.NeutralMin) and lr <= (gr + SKILL.NeutralMax)
end

-- =========================================================
-- WATCH THREAD — persis logika VD Auto Generator
-- =========================================================
local function startWatchThread()
    if S.WatchThread then
        pcall(task.cancel, S.WatchThread)
    end

    SKILL.Busy = false
    SKILL.PreviousVisible = false

    S.WatchThread = task.spawn(function()
        while S.Active do
            if not SKILL.Check then
                refreshSkillRefs()
            end

            if SKILL.Check and SKILL.Check.Parent then
                local Visible = SKILL.Check.Visible

                if Visible and not SKILL.PreviousVisible then
                    SKILL.Busy = false

                    if SKILL.Mode == "INSTANT"
                    and SKILL.Line and SKILL.Goal then
                        local gr = tonumber(SKILL.Goal.Rotation) or 0
                        pcall(function()
                            SKILL.Line.Rotation = gr + SKILL.InstantAngle
                        end)
                        triggerAction()
                    end
                end

                SKILL.PreviousVisible = Visible

                if Visible and not SKILL.Busy then
                    local should = false
                    if SKILL.Mode == "SUCCESS" then
                        should = isSuccess()
                    elseif SKILL.Mode == "NEUTRAL" then
                        should = isNeutral()
                    end

                    if should then
                        SKILL.Busy = true
                        triggerAction()
                        task.delay(0.07, function()
                            SKILL.Busy = false
                        end)
                    end
                end
            else
                SKILL.PreviousVisible = false
            end

            task.wait(0.005)
        end
    end)
end

local function stopWatchThread()
    if S.WatchThread then
        pcall(task.cancel, S.WatchThread)
        S.WatchThread = nil
    end
    SKILL.Busy = false
    SKILL.PreviousVisible = false
end

-- =========================================================
-- KEEP-ALIVE THREAD — refresh RepairEvent tiap 0.5s
-- biar server tetap anggap kita "repairing" di point itu
-- =========================================================
local function startKeepThread()
    if S.KeepThread then
        pcall(task.cancel, S.KeepThread)
    end

    S.KeepThread = task.spawn(function()
        while S.Active do
            fireRepairAll(true)
            task.wait(0.5)
        end
    end)
end

local function stopKeepThread()
    if S.KeepThread then
        pcall(task.cancel, S.KeepThread)
        S.KeepThread = nil
    end
end

local function hardStop()
    S.Active = false
    stopWatchThread()
    stopKeepThread()
    fireRepairAll(false)
    task.delay(0.1, function()
        fireRepairAll(false)
    end)
    clearPoints()
end

-- =========================================================
-- GENERATOR DETECTION
-- =========================================================
local function findGeneratorsRoot()
    local ws = workspace
    local map = ws:FindFirstChild("Map")
    if map then
        for _, name in ipairs(ROOT_NAMES) do
            local g = map:FindFirstChild(name)
            if g then return g end
        end
    end
    for _, name in ipairs(ROOT_NAMES) do
        local g = ws:FindFirstChild(name)
        if g then return g end
    end
    return nil
end

local function collectGenModels()
    local root = findGeneratorsRoot()
    local models = {}
    if not root then return models end
    for _, child in ipairs(root:GetChildren()) do
        for _, p in ipairs(child:GetChildren()) do
            if p:IsA("BasePart") and p.Name:match("^GeneratorPoint%d+$") then
                table.insert(models, child)
                break
            end
        end
    end
    if #models == 0 then
        for _, desc in ipairs(root:GetDescendants()) do
            if desc:IsA("Model") or desc:IsA("Folder") then
                for _, p in ipairs(desc:GetChildren()) do
                    if p:IsA("BasePart") and p.Name:match("^GeneratorPoint%d+$") then
                        table.insert(models, desc)
                        break
                    end
                end
            end
        end
    end
    return models
end

local function getModelPosition(model)
    if not model then return nil end
    if model.PrimaryPart then return model.PrimaryPart.Position end
    local sum, count = Vector3.zero, 0
    for _, p in ipairs(model:GetChildren()) do
        if p:IsA("BasePart") and p.Name:match("^GeneratorPoint%d+$") then
            sum = sum + p.Position
            count = count + 1
        end
    end
    if count > 0 then return sum / count end
    return nil
end

local function detectNearestGenerator()
    local models = collectGenModels()
    if #models == 0 then return nil, nil end
    local char = LP.Character
    if not char then return nil, nil end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil, nil end
    local myPos = hrp.Position
    local bestIdx, bestModel, bestDist = nil, nil, math.huge
    for i, model in ipairs(models) do
        local pos = getModelPosition(model)
        if pos then
            local d = (pos - myPos).Magnitude
            if d < bestDist then
                bestDist, bestIdx, bestModel = d, i, model
            end
        end
    end
    return bestIdx, bestModel
end

local function collectPoints(gen)
    local list = {}
    for _, p in ipairs(gen:GetChildren()) do
        if p:IsA("BasePart") and p.Name:match("^GeneratorPoint%d+$") then
            local n = tonumber(p.Name:match("^GeneratorPoint(%d+)$")) or 0
            table.insert(list, {p = p, n = n})
        end
    end
    table.sort(list, function(a, b) return a.n < b.n end)
    local out = {}
    for _, v in ipairs(list) do table.insert(out, v.p) end
    return out
end

-- =========================================================
-- KING SCOURGE
-- =========================================================
local KingScourgeStart, KingScourgeEnd
pcall(function()
    local KS = RS:WaitForChild("Remotes"):WaitForChild("KillerPerks"):WaitForChild("kingscourge")
    KingScourgeStart = KS:WaitForChild("KingScourgeStart")
    KingScourgeEnd = KS:WaitForChild("KingScourgeEnd")
end)

if KingScourgeStart then
    KingScourgeStart.OnClientEvent:Connect(function()
        if not S.Active then return end
        SKILL.ScourgeActive = true
        SKILL.Busy = false
        task.defer(function()
            if not S.Active then return end
            if SKILL.Mode == "INSTANT"
            and SKILL.Check and SKILL.Check.Visible
            and SKILL.Line and SKILL.Goal then
                local gr = tonumber(SKILL.Goal.Rotation) or 0
                pcall(function()
                    SKILL.Line.Rotation = gr + SKILL.InstantAngle
                end)
                triggerAction()
            end
        end)
    end)
end

if KingScourgeEnd then
    KingScourgeEnd.OnClientEvent:Connect(function()
        SKILL.ScourgeActive = false
        SKILL.Busy = false
    end)
end

-- =========================================================
-- GUI
-- =========================================================
local sg = Instance.new("ScreenGui")
sg.Name = "VanzBoost_" .. tostring(math.random(100000, 999999))
sg.ResetOnSpawn = false
sg.IgnoreGuiInset = true
sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
sg.DisplayOrder = 2147483647
sg.Parent = getParent()

local main = Instance.new("Frame")
main.Size = UDim2.new(0, 240, 0, 140)
main.Position = UDim2.new(0, 20, 0, 120)
main.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
main.BorderSizePixel = 0
main.Active = true
main.Parent = sg
Instance.new("UICorner", main).CornerRadius = UDim.new(0, 8)
local mstr = Instance.new("UIStroke", main)
mstr.Color = Color3.fromRGB(80, 80, 100)
mstr.Thickness = 1

local mtitle = Instance.new("TextLabel")
mtitle.Size = UDim2.new(0, 60, 0, 26)
mtitle.Position = UDim2.new(0, 10, 0, 4)
mtitle.BackgroundTransparency = 1
mtitle.Text = "BOOST"
mtitle.TextColor3 = Color3.fromRGB(255, 80, 80)
mtitle.Font = Enum.Font.GothamBold
mtitle.TextSize = 14
mtitle.TextXAlignment = Enum.TextXAlignment.Left
mtitle.Parent = main

local minBtn = Instance.new("TextButton")
minBtn.Size = UDim2.new(0, 22, 0, 22)
minBtn.Position = UDim2.new(1, -54, 0, 5)
minBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 60)
minBtn.Text = "—"
minBtn.TextColor3 = Color3.fromRGB(220, 220, 230)
minBtn.Font = Enum.Font.GothamBold
minBtn.TextSize = 14
minBtn.BorderSizePixel = 0
minBtn.Parent = main
Instance.new("UICorner", minBtn).CornerRadius = UDim.new(0, 4)

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 22, 0, 22)
closeBtn.Position = UDim2.new(1, -28, 0, 5)
closeBtn.BackgroundColor3 = Color3.fromRGB(120, 40, 40)
closeBtn.Text = "X"
closeBtn.TextColor3 = Color3.fromRGB(255, 220, 220)
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 12
closeBtn.BorderSizePixel = 0
closeBtn.Parent = main
Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 4)

local dragArea = Instance.new("TextButton")
dragArea.Size = UDim2.new(1, -130, 0, 26)
dragArea.Position = UDim2.new(0, 70, 0, 4)
dragArea.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
dragArea.Text = ""
dragArea.AutoButtonColor = false
dragArea.BorderSizePixel = 0
dragArea.Parent = main
Instance.new("UICorner", dragArea).CornerRadius = UDim.new(0, 4)

local boostBtn = Instance.new("TextButton")
boostBtn.Size = UDim2.new(1, -20, 0, 40)
boostBtn.Position = UDim2.new(0, 10, 0, 38)
boostBtn.BackgroundColor3 = Color3.fromRGB(40, 170, 90)
boostBtn.Text = "START"
boostBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
boostBtn.Font = Enum.Font.GothamBold
boostBtn.TextSize = 14
boostBtn.BorderSizePixel = 0
boostBtn.AutoButtonColor = false
boostBtn.Parent = main
Instance.new("UICorner", boostBtn).CornerRadius = UDim.new(0, 6)

local modeBtn = Instance.new("TextButton")
modeBtn.Size = UDim2.new(1, -20, 0, 30)
modeBtn.Position = UDim2.new(0, 10, 0, 84)
modeBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 60)
modeBtn.Text = "MODE : INSTANT"
modeBtn.TextColor3 = Color3.fromRGB(220, 220, 230)
modeBtn.Font = Enum.Font.GothamBold
modeBtn.TextSize = 12
modeBtn.BorderSizePixel = 0
modeBtn.AutoButtonColor = false
modeBtn.Parent = main
Instance.new("UICorner", modeBtn).CornerRadius = UDim.new(0, 6)

local lockBtn = Instance.new("TextButton")
lockBtn.Size = UDim2.new(1, -20, 0, 22)
lockBtn.Position = UDim2.new(0, 10, 0, 116)
lockBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 60)
lockBtn.Text = "LOCK : OFF"
lockBtn.TextColor3 = Color3.fromRGB(220, 220, 230)
lockBtn.Font = Enum.Font.GothamBold
lockBtn.TextSize = 11
lockBtn.BorderSizePixel = 0
lockBtn.AutoButtonColor = false
lockBtn.Parent = main
Instance.new("UICorner", lockBtn).CornerRadius = UDim.new(0, 6)

local logo = Instance.new("TextButton")
logo.Size = UDim2.new(0, 50, 0, 50)
logo.Position = UDim2.new(0, 20, 0, 120)
logo.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
logo.Text = "B"
logo.TextColor3 = Color3.fromRGB(255, 80, 80)
logo.Font = Enum.Font.GothamBold
logo.TextSize = 22
logo.AutoButtonColor = false
logo.Visible = false
logo.Parent = sg
Instance.new("UICorner", logo).CornerRadius = UDim.new(1, 0)
local lstr = Instance.new("UIStroke", logo)
lstr.Color = Color3.fromRGB(255, 80, 80)
lstr.Thickness = 2

local function bindDrag(target, handle)
    local dragging, dragInput, dragStart, startPos
    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = target.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)
    handle.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if not dragging or input ~= dragInput then return end
        if S.Locked then return end
        local delta = input.Position - dragStart
        target.Position = UDim2.new(
            startPos.X.Scale, startPos.X.Offset + delta.X,
            startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end)
end

bindDrag(main, dragArea)
bindDrag(logo, logo)

local ModeList = {"INSTANT", "SUCCESS", "NEUTRAL"}
local ModeIdx = 1

modeBtn.MouseButton1Click:Connect(function()
    ModeIdx = ModeIdx % #ModeList + 1
    SKILL.Mode = ModeList[ModeIdx]
    modeBtn.Text = "MODE : " .. SKILL.Mode
end)

lockBtn.MouseButton1Click:Connect(function()
    S.Locked = not S.Locked
    lockBtn.Text = S.Locked and "LOCK : ON" or "LOCK : OFF"
    lockBtn.BackgroundColor3 = S.Locked
        and Color3.fromRGB(180, 120, 40)
        or Color3.fromRGB(45, 45, 60)
end)

PROGRESS.OnClientEvent:Connect(function(progress, labelText)
    if not S.Active then return end
    if labelText ~= "REPAIR" then return end
    if typeof(progress) == "number" and progress >= 100 then
        hardStop()
        boostBtn.Text = "START"
        boostBtn.BackgroundColor3 = Color3.fromRGB(40, 170, 90)
    end
end)

boostBtn.MouseButton1Click:Connect(function()
    if not S.Active then
        local idx, model = detectNearestGenerator()
        if not model then
            boostBtn.Text = "NO GEN"
            task.wait(1.5)
            boostBtn.Text = "START"
            return
        end
        S.GenIndex = idx
        S.GenModel = model
        S.Points = collectPoints(model)
        if #S.Points == 0 then
            boostBtn.Text = "NO POINTS"
            task.wait(1.5)
            boostBtn.Text = "START"
            clearPoints()
            return
        end
        S.Active = true
        fireRepairAll(true)
        startWatchThread()
        startKeepThread()
        boostBtn.Text = "STOP"
        boostBtn.BackgroundColor3 = Color3.fromRGB(180, 40, 40)
    else
        hardStop()
        boostBtn.Text = "START"
        boostBtn.BackgroundColor3 = Color3.fromRGB(40, 170, 90)
    end
end)

local minimized = false
minBtn.MouseButton1Click:Connect(function()
    minimized = not minimized
    main.Visible = not minimized
    logo.Visible = minimized
end)

logo.MouseButton1Click:Connect(function()
    minimized = false
    main.Visible = true
    logo.Visible = false
end)

closeBtn.MouseButton1Click:Connect(function()
    hardStop()
    pcall(function() sg:Destroy() end)
end)

LP.CharacterAdded:Connect(function()
    task.wait(1)
    refreshSkillRefs()
end)

print("[VANZ] Boost ready (VD-style).")