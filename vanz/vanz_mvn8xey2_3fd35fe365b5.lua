if getgenv().vanzUtility and getgenv().vanzUtility.running then
    pcall(function() getgenv().vanzUtility.shutdown() end)
end

local Players = game:GetService("Players")
local lp = Players.LocalPlayer
local PG = lp:WaitForChild("PlayerGui")

local S = getgenv().vanzUtility or {}
getgenv().vanzUtility = S
S.running = true
S.enabledSkill = true
S.enabledWiggle = true

local TRIGGER_DELAY = 0.05
local SKILL_COOLDOWN = 0.15
local WIGGLE_COOLDOWN = 0.1

local UTILS = {
    Check = nil, Line = nil, Goal = nil, Action = nil, TrapPerfect = nil,
    LastSkillTrigger = 0, SkillBusy = false, LastVisible = false,
    
    ProgressGui = nil, WiggleLabel = nil,
    LastWiggleTrigger = 0
}

-- ==========================================
-- REFRESH REFERENSI
-- ==========================================
local function refresh()
    pcall(function()
        -- Skill Check Refs
        local skillGui = PG:FindFirstChild("SkillCheckPromptGui")
        if not skillGui then skillGui = PG:FindFirstChild("SkillCheckPromptGui-con") end
        if skillGui then
            UTILS.Check = skillGui:FindFirstChild("Check")
            if UTILS.Check then
                UTILS.Line = UTILS.Check:FindFirstChild("Line")
                UTILS.Goal = UTILS.Check:FindFirstChild("Goal")
                UTILS.TrapPerfect = UTILS.Check:FindFirstChild("TrapPerfect")
            end
        end
        
        -- Action Button
        local survivor = PG:FindFirstChild("Survivor-mob")
        if survivor then
            local controls = survivor:FindFirstChild("Controls")
            if controls then UTILS.Action = controls:FindFirstChild("action") end
        end
        
        -- Wiggle Refs
        UTILS.ProgressGui = PG:FindFirstChild("ProgressPromptGui")
        if UTILS.ProgressGui then
            local frame = UTILS.ProgressGui:FindFirstChild("Frame") or UTILS.ProgressGui:FindFirstChild("oldFrame")
            if frame then
                UTILS.WiggleLabel = frame:FindFirstChild("TextLabel")
            end
        end
    end)
end

-- ==========================================
-- FUNGSI TRIGGER TOMBOL
-- ==========================================
local function triggerAction()
    if not UTILS.Action then return end
    pcall(function()
        firesignal(UTILS.Action.MouseButton1Down)
        task.wait(TRIGGER_DELAY)
        firesignal(UTILS.Action.MouseButton1Up)
    end)
end

-- ==========================================
-- LOGIKA SKILLCHECK (Anti-Melengkung)
-- ==========================================
local function getShortestDistance(angle1, angle2)
    local diff = math.abs(angle1 - angle2) % 360
    if diff > 180 then diff = 360 - diff end
    return diff
end

local function checkSkillcheck()
    if not UTILS.Line or not UTILS.Goal then return false end
    
    local lr = tonumber(UTILS.Line.Rotation) or 0
    local gr = tonumber(UTILS.Goal.Rotation) or 0
    
    -- Cek Normal Skillcheck (Tengah di 109°, toleransi 7°)
    local targetAngle = (gr + 109) % 360
    if getShortestDistance(lr, targetAngle) <= 7 then
        return true
    end
    
    -- Cek Trap Skillcheck (Kalau TrapPerfect muncul)
    if UTILS.TrapPerfect and UTILS.TrapPerfect.Visible then
        local tr = tonumber(UTILS.TrapPerfect.Rotation) or 0
        if getShortestDistance(lr, tr) <= 7 then
            return true
        end
    end
    
    return false
end

-- ==========================================
-- LOOP UTAMA (1ms)
-- ==========================================
task.spawn(function()
    refresh()
    
    while S.running do
        if tick() % 1 < 0.005 then refresh() end
        
        -- 1. AUTO SKILLCHECK (Generator, Heal, Trap)
        if S.enabledSkill and UTILS.Check and UTILS.Check.Parent then
            local visible = UTILS.Check.Visible
            
            if visible and not UTILS.LastVisible then
                UTILS.SkillBusy = false
            end
            
            if visible and not UTILS.SkillBusy then
                if checkSkillcheck() then
                    local now = os.clock()
                    if now - UTILS.LastSkillTrigger > SKILL_COOLDOWN then
                        UTILS.SkillBusy = true
                        UTILS.LastSkillTrigger = now
                        task.spawn(triggerAction)
                        task.delay(SKILL_COOLDOWN, function() UTILS.SkillBusy = false end)
                    end
                end
            end
            
            UTILS.LastVisible = visible
        else
            UTILS.LastVisible = false
        end
        
        -- 2. AUTO WIGGLE (Pas di-hook)
        if S.enabledWiggle and UTILS.ProgressGui and UTILS.WiggleLabel then
            local frame = UTILS.WiggleLabel.Parent
            if frame.Visible and UTILS.WiggleLabel.Text == "WIGGLE" then
                local now = os.clock()
                if now - UTILS.LastWiggleTrigger > WIGGLE_COOLDOWN then
                    UTILS.LastWiggleTrigger = now
                    task.spawn(triggerAction)
                    pcall(function() game:GetService("VirtualInputManager"):SendKeyEvent(true, "Space", false, game) end)
                    task.wait(0.02)
                    pcall(function() game:GetService("VirtualInputManager"):SendKeyEvent(false, "Space", false, game) end)
                end
            end
        end
        
        task.wait(0.001)
    end
end)

function S.shutdown()
    S.running = false
    getgenv().vanzUtility = nil
end

print("[VANZ AUTO UTILITY v1.1] Loaded.")
print("[!] Auto Skillcheck (Generator, Heal, Trap) : ON")
print("[!] Auto Wiggle (Pas di-hook)               : ON")