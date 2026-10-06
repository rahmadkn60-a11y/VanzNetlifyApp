--==================================================
-- [AC SPY] UNIVERSAL ANTI-CHEAT RECON v2
--==================================================
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local RS = game:GetService("ReplicatedStorage")

local LP = Players.LocalPlayer
local PG = LP:WaitForChild("PlayerGui")

--== CONFIG ==--
local CFG = {
	Width = 340,
	Height = 440,
	MaxEvents = 300,
	MaxRemoteRing = 80,
	PosJumpThreshold = 25,
	PosJumpMinGap = 0.005,
	HealthEpsilon = 0.5,
	RemoteContextWindow = 3,
}

local C = {
	BG = Color3.fromRGB(14, 18, 28),
	BG2 = Color3.fromRGB(22, 28, 42),
	BG3 = Color3.fromRGB(30, 38, 56),
	Accent = Color3.fromRGB(0, 200, 255),
	Accent2 = Color3.fromRGB(0, 255, 200),
	Good = Color3.fromRGB(80, 255, 150),
	Bad = Color3.fromRGB(255, 80, 100),
	Warn = Color3.fromRGB(255, 200, 80),
	Text = Color3.fromRGB(230, 240, 255),
	Sub = Color3.fromRGB(140, 165, 200),
}

local S = {
	Enabled = true,
	Destroyed = false,
	Events = {},
	RemoteRing = {},
	StartTime = os.clock(),
	LastHealth = nil,
	LastPos = nil,
	LastPosTime = nil,
	Hooked = false,
	CharConns = {},
	UI = {},
}

local function nowStr() return string.format("%.3f", os.clock() - S.StartTime) end

local function pushRemote(method, name, args)
	if S.Destroyed then return end
	S.RemoteRing[#S.RemoteRing+1] = {
		t = os.clock() - S.StartTime,
		method = method,
		name = name,
		args = args,
	}
	while #S.RemoteRing > CFG.MaxRemoteRing do
		table.remove(S.RemoteRing, 1)
	end
end

local function snapshotRemotes()
	local tNow = os.clock() - S.StartTime
	local out = {}
	for _, r in ipairs(S.RemoteRing) do
		if tNow - r.t <= CFG.RemoteContextWindow then
			out[#out+1] = r
		end
	end
	return out
end

local function emitEvent(cat, msg)
	if S.Destroyed or not S.Enabled then return end
	S.Events[#S.Events+1] = {
		t = os.clock() - S.StartTime,
		cat = cat,
		msg = msg,
		remotes = snapshotRemotes(),
	}
	while #S.Events > CFG.MaxEvents do
		table.remove(S.Events, 1)
	end
	if S.UI.refresh then S.UI.refresh() end
end

--== NAMECALL HOOK (silent) ==--
local function installHook()
	if S.Hooked then return end
	local ok = pcall(function()
		local mt = getrawmetatable(game)
		local oldNC = mt.__namecall
		setreadonly(mt, false)
		mt.__namecall = newcclosure(function(self, ...)
			local method = getnamecallmethod()
			if method == "FireServer" or method == "InvokeServer" then
				local ok2, fullName = pcall(function() return self:GetFullName() end)
				if ok2 and fullName then
					local n = select("#", ...)
					local argParts = {}
					for i = 1, math.min(n, 5) do
						local v = select(i, ...)
						local t = typeof(v)
						if type(v) == "table" then
							local cnt = 0
							for _ in pairs(v) do cnt = cnt + 1 end
							argParts[#argParts+1] = "table("..cnt..")"
						elseif t == "CFrame" then
							argParts[#argParts+1] = string.format("CF(%.0f,%.0f,%.0f)", v.X, v.Y, v.Z)
						elseif t == "Vector3" then
							argParts[#argParts+1] = string.format("V3(%.0f,%.0f,%.0f)", v.X, v.Y, v.Z)
						elseif t == "Instance" then
							argParts[#argParts+1] = v.Name
						else
							local s = tostring(v)
							if #s > 45 then s = s:sub(1, 45).."…" end
							argParts[#argParts+1] = s
						end
					end
					pushRemote(method, fullName, table.concat(argParts, ", "))
				end
			end
			return oldNC(self, ...)
		end)
		setreadonly(mt, true)
	end)
	S.Hooked = ok
end

--== CHARACTER WATCH ==--
local function clearCharConns()
	for _, c in ipairs(S.CharConns) do
		pcall(function() c:Disconnect() end)
	end
	table.clear(S.CharConns)
end

local function watchChar(char)
	clearCharConns()
	S.LastPos = nil
	S.LastPosTime = nil
	S.LastHealth = nil

	local h = char:WaitForChild("Humanoid", 5)
	if not h then return end

	S.LastHealth = h.Health

	table.insert(S.CharConns, h.HealthChanged:Connect(function(newH)
		local old = S.LastHealth or newH
		if newH < old - CFG.HealthEpsilon then
			local hrp = char:FindFirstChild("HumanoidRootPart")
			local pos = hrp and hrp.Position or Vector3.new()
			emitEvent("HEALTH_DROP", string.format(
				"%.1f -> %.1f (d=%.1f) @ (%.0f,%.0f,%.0f)",
				old, newH, newH - old, pos.X, pos.Y, pos.Z))
		end
		S.LastHealth = newH
	end))

	table.insert(S.CharConns, h.Died:Connect(function()
		emitEvent("DIED", "Humanoid died")
	end))

	local hrp = char:FindFirstChild("HumanoidRootPart")
	if hrp then
		S.LastPos = hrp.Position
		S.LastPosTime = os.clock()
		table.insert(S.CharConns, RunService.Heartbeat:Connect(function()
			if S.Destroyed or not S.Enabled then return end
			if not hrp.Parent then return end
			local cur = hrp.Position
			local curT = os.clock()
			local dt = curT - S.LastPosTime
			if dt < CFG.PosJumpMinGap then return end
			local d = (cur - S.LastPos).Magnitude
			if d >= CFG.PosJumpThreshold then
				emitEvent("POS_JUMP", string.format(
					"%.0f studs in %.3fs  (%.0f,%.0f,%.0f) -> (%.0f,%.0f,%.0f)",
					d, dt, S.LastPos.X, S.LastPos.Y, S.LastPos.Z, cur.X, cur.Y, cur.Z))
			end
			S.LastPos = cur
			S.LastPosTime = curT
		end))
	end
end

local function watchRemoteAdd()
	RS.DescendantAdded:Connect(function(o)
		if S.Destroyed or not S.Enabled then return end
		if o:IsA("RemoteEvent") or o:IsA("RemoteFunction") then
			emitEvent("REMOTE_NEW", o.ClassName.." "..o:GetFullName())
		end
	end)
end

--== UI HELPERS ==--
local function create(class, props)
	local o = Instance.new(class)
	for k, v in pairs(props) do o[k] = v end
	return o
end

local function makeCorner(p, r)
	create("UICorner", { CornerRadius = UDim.new(0, r), Parent = p })
end

local function makeStroke(p, color, thick, transp)
	create("UIStroke", {
		Color = color, Thickness = thick or 1,
		Transparency = transp or 0.3,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		Parent = p,
	})
end

--== REPORT BUILDER ==--
local function buildReport()
	local lines = {}
	lines[#lines+1] = "=== AC SPY REPORT ==="
	lines[#lines+1] = string.format("Uptime: %s", nowStr())
	lines[#lines+1] = string.format("Events: %d", #S.Events)
	lines[#lines+1] = ""
	if #S.Events == 0 then
		lines[#lines+1] = "(no AC events captured)"
	else
		for _, ev in ipairs(S.Events) do
			lines[#lines+1] = string.format("[%8.3f] %s", ev.t, ev.cat)
			lines[#lines+1] = "  " .. ev.msg
			if ev.remotes and #ev.remotes > 0 then
				lines[#lines+1] = "  -- remotes (last "..CFG.RemoteContextWindow.."s) --"
				for _, r in ipairs(ev.remotes) do
					lines[#lines+1] = string.format("  [%8.3f] %s %s  (%s)", r.t, r.method, r.name, r.args)
				end
			end
			lines[#lines+1] = ""
		end
	end
	return table.concat(lines, "\n")
end

local function copyToClipboard(txt)
	local methods = {
		setclipboard,
		toclipboard,
		writeclipboard,
		syn and syn.write_clipboard,
		Delta and Delta.setclipboard,
		(getgenv and getgenv().setclipboard) or nil,
	}
	for _, fn in ipairs(methods) do
		if type(fn) == "function" then
			local ok = pcall(fn, txt)
			if ok then return true end
		end
	end
	if writefile then
		local ok = pcall(writefile, "ac_spy_report.txt", txt)
		if ok then return "file" end
	end
	return false
end

--== GUI ==--
local function buildGUI()
	local old = PG:FindFirstChild("ACSPY_GUI")
	if old then old:Destroy() end

	local gui = create("ScreenGui", {
		Name = "ACSPY_GUI",
		ResetOnSpawn = false,
		ZIndexBehavior = Enum.ZIndexBehavior.Global,
		DisplayOrder = 999,
		Parent = PG,
	})
	S.GUI = gui

	local main = create("Frame", {
		Name = "Main",
		Size = UDim2.fromOffset(CFG.Width, CFG.Height),
		Position = UDim2.new(0, 30, 0, 100),
		BackgroundColor3 = C.BG,
		BackgroundTransparency = 0.05,
		BorderSizePixel = 0,
		Active = true,
		Draggable = true,
		Parent = gui,
	})
	makeCorner(main, 12)
	makeStroke(main, C.Accent, 1.5, 0.3)

	-- HEADER
	local header = create("Frame", {
		Size = UDim2.new(1, 0, 0, 40),
		BackgroundColor3 = C.BG2,
		BorderSizePixel = 0,
		Parent = main,
	})
	makeCorner(header, 12)

	create("TextLabel", {
		Size = UDim2.new(1, -100, 1, 0),
		Position = UDim2.new(0, 12, 0, 0),
		BackgroundTransparency = 1,
		Text = "AC SPY v2",
		Font = Enum.Font.GothamBlack,
		TextSize = 16,
		TextColor3 = C.Accent,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = header,
	})

	local dot = create("Frame", {
		Size = UDim2.fromOffset(10, 10),
		Position = UDim2.new(0, 100, 0.5, -5),
		BackgroundColor3 = C.Good,
		BorderSizePixel = 0,
		Parent = header,
	})
	makeCorner(dot, 5)

	local close = create("TextButton", {
		Size = UDim2.fromOffset(28, 28),
		Position = UDim2.new(1, -34, 0.5, -14),
		BackgroundColor3 = C.BG3,
		BorderSizePixel = 0,
		Text = "X",
		Font = Enum.Font.GothamBold,
		TextSize = 12,
		TextColor3 = C.Sub,
		AutoButtonColor = false,
		Parent = header,
	})
	makeCorner(close, 6)
	close.MouseButton1Click:Connect(function()
		gui.Enabled = not gui.Enabled
	end)

	-- STATUS + CONTROLS ROW (ON/OFF + COPY side by side)
	local ctrlRow = create("Frame", {
		Size = UDim2.new(1, -16, 0, 34),
		Position = UDim2.new(0, 8, 0, 46),
		BackgroundColor3 = C.BG2,
		BorderSizePixel = 0,
		Parent = main,
	})
	makeCorner(ctrlRow, 8)

	local statusLbl = create("TextLabel", {
		Size = UDim2.new(1, -150, 1, 0),
		Position = UDim2.new(0, 10, 0, 0),
		BackgroundTransparency = 1,
		Text = "ACTIVE   Events: 0",
		Font = Enum.Font.GothamBold,
		TextSize = 11,
		TextColor3 = C.Text,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = ctrlRow,
	})

	-- ON/OFF toggle
	local toggleBtn = create("TextButton", {
		Size = UDim2.fromOffset(64, 24),
		Position = UDim2.new(1, -138, 0.5, -12),
		BackgroundColor3 = C.Good,
		BorderSizePixel = 0,
		Text = "ON",
		Font = Enum.Font.GothamBlack,
		TextSize = 11,
		TextColor3 = C.BG,
		AutoButtonColor = false,
		Parent = ctrlRow,
	})
	makeCorner(toggleBtn, 6)

	-- COPY button right next to toggle
	local copyBtn = create("TextButton", {
		Size = UDim2.fromOffset(64, 24),
		Position = UDim2.new(1, -70, 0.5, -12),
		BackgroundColor3 = C.Accent,
		BorderSizePixel = 0,
		Text = "COPY",
		Font = Enum.Font.GothamBlack,
		TextSize = 11,
		TextColor3 = C.BG,
		AutoButtonColor = false,
		Parent = ctrlRow,
	})
	makeCorner(copyBtn, 6)

	-- LOG SCROLL
	local logFrame = create("Frame", {
		Size = UDim2.new(1, -16, 1, -180),
		Position = UDim2.new(0, 8, 0, 86),
		BackgroundColor3 = C.BG2,
		BorderSizePixel = 0,
		Parent = main,
	})
	makeCorner(logFrame, 8)

	local scroll = create("ScrollingFrame", {
		Size = UDim2.new(1, -8, 1, -8),
		Position = UDim2.new(0, 4, 0, 4),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 4,
		ScrollBarImageColor3 = C.Accent,
		CanvasSize = UDim2.new(0, 0, 0, 0),
		Parent = logFrame,
	})

	local list = create("UIListLayout", {
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, 3),
		Parent = scroll,
	})

	local emptyLbl = create("TextLabel", {
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		Text = "Waiting for AC events…\n\nTip: tekan TRIGGER atau teleport manual.",
		Font = Enum.Font.Gotham,
		TextSize = 11,
		TextColor3 = C.Sub,
		TextTransparency = 0.3,
		TextWrapped = true,
		Parent = scroll,
	})

	-- BOTTOM BUTTON ROW
	local btnRow = create("Frame", {
		Size = UDim2.new(1, -16, 0, 36),
		Position = UDim2.new(0, 8, 1, -74),
		BackgroundTransparency = 1,
		Parent = main,
	})

	local function mkBtn(text, xscale, color)
		local b = create("TextButton", {
			Size = UDim2.new(xscale, -4, 1, 0),
			BackgroundColor3 = color,
			BorderSizePixel = 0,
			Text = text,
			Font = Enum.Font.GothamBold,
			TextSize = 11,
			TextColor3 = C.BG,
			AutoButtonColor = false,
			Parent = btnRow,
		})
		makeCorner(b, 8)
		return b
	end

	local trigBtn = mkBtn("TRIGGER 500", 0.34, C.Warn)
	trigBtn.Position = UDim2.new(0, 0, 0, 0)

	local trigBtn2 = mkBtn("TRIGGER 2000", 0.34, C.Warn)
	trigBtn2.Position = UDim2.new(0.34, 0, 0, 0)

	local clearBtn = mkBtn("CLEAR", 0.30, C.Sub)
	clearBtn.Position = UDim2.new(0.68, 0, 0, 0)

	-- TOAST
	local toast = create("TextLabel", {
		Size = UDim2.new(1, -16, 0, 20),
		Position = UDim2.new(0, 8, 1, -36),
		BackgroundTransparency = 1,
		Text = "",
		Font = Enum.Font.GothamBold,
		TextSize = 10,
		TextColor3 = C.Accent2,
		TextXAlignment = Enum.TextXAlignment.Center,
		Parent = main,
	})

	local function showToast(txt, color)
		toast.Text = txt
		toast.TextColor3 = color or C.Accent2
		task.delay(2.2, function()
			if toast and toast.Parent and toast.Text == txt then
				toast.Text = ""
			end
		end)
	end

	-- WIRE UP
	toggleBtn.MouseButton1Click:Connect(function()
		S.Enabled = not S.Enabled
		if S.Enabled then
			toggleBtn.Text = "ON"
			toggleBtn.BackgroundColor3 = C.Good
			dot.BackgroundColor3 = C.Good
			showToast("Spy ACTIVE")
		else
			toggleBtn.Text = "OFF"
			toggleBtn.BackgroundColor3 = C.Bad
			dot.BackgroundColor3 = C.Bad
			showToast("Spy PAUSED", C.Warn)
		end
	end)

	copyBtn.MouseButton1Click:Connect(function()
		local txt = buildReport()
		local res = copyToClipboard(txt)
		if res == true then
			showToast("Copied "..#S.Events.." events to clipboard", C.Good)
		elseif res == "file" then
			showToast("Saved: ac_spy_report.txt", C.Good)
		else
			showToast("Copy failed — no clipboard API", C.Bad)
		end
	end)

	trigBtn.MouseButton1Click:Connect(function()
		local hrp = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
		if hrp then
			hrp.CFrame = hrp.CFrame + Vector3.new(500, 30, 500)
			showToast("Triggered 707 studs", C.Warn)
		end
	end)

	trigBtn2.MouseButton1Click:Connect(function()
		local hrp = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
		if hrp then
			hrp.CFrame = hrp.CFrame + Vector3.new(2000, 100, 2000)
			showToast("Triggered 2828 studs", C.Warn)
		end
	end)

	clearBtn.MouseButton1Click:Connect(function()
		table.clear(S.Events)
		if S.UI.refresh then S.UI.refresh() end
		showToast("Cleared", C.Sub)
	end)

	-- REFRESH
	S.UI.refresh = function()
		if S.Destroyed then return end
		local uptime = os.clock() - S.StartTime
		local mm = math.floor(uptime / 60)
		local ss = math.floor(uptime % 60)
		statusLbl.Text = string.format("%s  Events: %d  %d:%02d",
			S.Enabled and "ACTIVE" or "PAUSED", #S.Events, mm, ss)

		for _, c in ipairs(scroll:GetChildren()) do
			if c:IsA("TextLabel") and c ~= emptyLbl then
				c:Destroy()
			end
		end

		if #S.Events == 0 then
			emptyLbl.Visible = true
		else
			emptyLbl.Visible = false
			local startIdx = math.max(1, #S.Events - 25)
			for i = startIdx, #S.Events do
				local ev = S.Events[i]
				local color = C.Text
				if ev.cat == "DIED" then color = C.Bad
				elseif ev.cat == "HEALTH_DROP" then color = C.Warn
				elseif ev.cat == "POS_JUMP" then color = C.Accent
				elseif ev.cat == "REMOTE_NEW" then color = C.Accent2
				end

				local row = create("Frame", {
					Size = UDim2.new(1, -8, 0, 42),
					BackgroundColor3 = C.BG3,
					BackgroundTransparency = 0.5,
					BorderSizePixel = 0,
					LayoutOrder = i,
					Parent = scroll,
				})
				makeCorner(row, 6)

				create("TextLabel", {
					Size = UDim2.new(1, -8, 0, 14),
					Position = UDim2.new(0, 6, 0, 4),
					BackgroundTransparency = 1,
					Text = string.format("[%.2f] %s", ev.t, ev.cat),
					Font = Enum.Font.GothamBold,
					TextSize = 11,
					TextColor3 = color,
					TextXAlignment = Enum.TextXAlignment.Left,
					Parent = row,
				})

				create("TextLabel", {
					Size = UDim2.new(1, -8, 0, 22),
					Position = UDim2.new(0, 6, 0, 18),
					BackgroundTransparency = 1,
					Text = ev.msg,
					Font = Enum.Font.Code,
					TextSize = 10,
					TextColor3 = C.Sub,
					TextXAlignment = Enum.TextXAlignment.Left,
					TextYAlignment = Enum.TextYAlignment.Top,
					TextWrapped = true,
					Parent = row,
				})
			end
		end

		scroll.CanvasSize = UDim2.new(0, 0, 0, list.AbsoluteContentSize.Y + 8)
	end

	S.UI.refresh()
end

--== BOOT ==--
local function boot()
	buildGUI()
	installHook()
	watchRemoteAdd()

	if LP.Character then
		task.spawn(watchChar, LP.Character)
	end
	LP.CharacterAdded:Connect(function(char)
		task.defer(watchChar, char)
	end)

	task.spawn(function()
		while not S.Destroyed do
			task.wait(1)
			if S.UI.refresh then S.UI.refresh() end
		end
	end)
end

boot()

--== PUBLIC API ==--
_G.acspy = {
	Enable = function() S.Enabled = true end,
	Disable = function() S.Enabled = false end,
	Toggle = function() S.Enabled = not S.Enabled end,
	Clear = function() table.clear(S.Events) end,
	Trigger = function(dist)
		dist = dist or 500
		local hrp = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
		if hrp then hrp.CFrame = hrp.CFrame + Vector3.new(dist, 30, dist) end
	end,
	Build = buildReport,
	Copy = function()
		return copyToClipboard(buildReport())
	end,
	Destroy = function()
		S.Destroyed = true
		clearCharConns()
		if S.GUI then S.GUI:Destroy() end
	end,
}