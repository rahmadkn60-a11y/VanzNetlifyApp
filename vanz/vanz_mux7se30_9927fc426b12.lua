--==================================================
-- SPY: ANTI-CHEAT RECON
--==================================================
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local RS = game:GetService("ReplicatedStorage")
local LP = Players.LocalPlayer

local buf = {}
local T0 = os.clock()

local function log(s)
    local line = string.format("[%7.3f] %s", os.clock() - T0, tostring(s))
    buf[#buf+1] = line
    print(line)
end

log("=== SPY START ===")

-- [1] HOOK __namecall: tangkap semua remote fire dari client
do
    local ok = pcall(function()
        local mt = getrawmetatable(game)
        local old = mt.__namecall
        setreadonly(mt, false)
        mt.__namecall = newcclosure(function(self, ...)
            local method = getnamecallmethod()
            if method == "FireServer" or method == "InvokeServer" then
                local ok2, path = pcall(function() return self:GetFullName() end)
                if ok2 and path and path:lower():find("eggworld") == nil then
                    -- skip eggworld remotes biar gk spam
                end
                if ok2 then
                    local args = {...}
                    local parts = {}
                    for i = 1, math.min(#args, 6) do
                        local v = args[i]
                        local t = typeof(v)
                        if type(v) == "table" then
                            local n = 0; for _ in pairs(v) do n = n + 1 end
                            parts[#parts+1] = "tbl("..n..")"
                        elseif t == "CFrame" then
                            parts[#parts+1] = string.format("CF(%.0f,%.0f,%.0f)", v.X, v.Y, v.Z)
                        elseif t == "Vector3" then
                            parts[#parts+1] = string.format("V3(%.0f,%.0f,%.0f)", v.X, v.Y, v.Z)
                        else
                            parts[#parts+1] = tostring(v):sub(1, 50)
                        end
                    end
                    log("-> "..method.." "..path.."  ("..table.concat(parts, ", ")..")")
                end
            end
            return old(self, ...)
        end)
        setreadonly(mt, true)
    end)
    if ok then log("__namecall hooked OK") else log("__namecall hook FAILED") end
end

-- [2] WATCH CHARACTER
local watchConns = {}
local lastPos = nil

local function clearWatch()
    for _, c in ipairs(watchConns) do pcall(function() c:Disconnect() end) end
    table.clear(watchConns)
    lastPos = nil
end

local function watchChar(char)
    clearWatch()
    log("Character spawned: "..char.Name)
    local h = char:WaitForChild("Humanoid", 5)
    if not h then return end

    local lastHealth = h.Health
    table.insert(watchConns, h.HealthChanged:Connect(function(newH)
        local delta = newH - lastHealth
        if delta < -0.01 then
            local hrp = char:FindFirstChild("HumanoidRootPart")
            local p = hrp and hrp.Position or Vector3.zero
            log(string.format("!! HEALTH %.1f -> %.1f (d %.1f) @ %.0f,%.0f,%.0f",
                lastHealth, newH, delta, p.X, p.Y, p.Z))
        end
        lastHealth = newH
    end))

    table.insert(watchConns, h.Died:Connect(function()
        log("!!! DIED !!!")
    end))

    local hrp = char:FindFirstChild("HumanoidRootPart")
    if hrp then
        lastPos = hrp.Position
        table.insert(watchConns, RunService.Heartbeat:Connect(function()
            if not hrp.Parent then return end
            local cur = hrp.Position
            local d = (cur - lastPos).Magnitude
            if d > 30 then
                log(string.format("!! POS JUMP %.0f studs (%.0f,%.0f,%.0f -> %.0f,%.0f,%.0f)",
                    d, lastPos.X, lastPos.Y, lastPos.Z, cur.X, cur.Y, cur.Z))
            end
            lastPos = cur
        end))
    end
end

if LP.Character then watchChar(LP.Character) end
LP.CharacterAdded:Connect(watchChar)

-- [3] NEW REMOTES
RS.DescendantAdded:Connect(function(o)
    if o:IsA("RemoteEvent") or o:IsA("RemoteFunction") then
        log("NEW REMOTE: "..o:GetFullName().." ("..o.ClassName..")")
    end
end)

-- [4] MANUAL TRIGGERS
_G.spyTrigger = function(distance)
    distance = distance or 500
    local hrp = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then log("no hrp"); return end
    local from = hrp.Position
    local to = from + Vector3.new(distance, 30, distance)
    log(string.format("=== MANUAL TELEPORT TRIGGER %.0f studs ===", distance))
    log(string.format("from %.0f,%.0f,%.0f -> %.0f,%.0f,%.0f", from.X, from.Y, from.Z, to.X, to.Y, to.Z))
    hrp.CFrame = CFrame.new(to)
end

_G.spyDump = function()
    local report = table.concat(buf, "\n")
    if setclipboard then
        local ok = pcall(setclipboard, report)
        print("[SPY] clipboard: "..(ok and "OK" or "FAIL"))
    end
    if writefile then
        pcall(writefile, "ac_spy.txt", report)
        print("[SPY] file: ac_spy.txt")
    end
    return report
end

_G.spyClear = function()
    table.clear(buf)
    log("=== CLEARED ===")
end

-- [5] AUTO COPY setelah 90s
task.delay(90, function()
    if #buf > 1 then
        _G.spyDump()
        log("=== AUTO-COPIED after 90s ===")
    end
end)

log("=== READY ===")
log("Commands:")
log("  _G.spyTrigger(500)   -- teleport 500 studs untuk trigger AC")
log("  _G.spyDump()         -- copy log ke clipboard")
log("  _G.spyClear()        -- reset log")
log("=========================")