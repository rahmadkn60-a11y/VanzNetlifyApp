-- vanz
-- ============================================================
--  VANZ LOOPER v1.2 | Decompile Auto-Converter Edition | Luau
--  GUI → Convert → Loop → Copy Result
-- ============================================================

-- ╔══════════════════════════════════════════════════════════╗
-- ║  BLOK 0 : GLOBAL STATE INIT                             ║
-- ╚══════════════════════════════════════════════════════════╝
-- vanz
do
    local ok, err = xpcall(function()
        _G.vanz = _G.vanz or {}
        local V = _G.vanz

        V.running        = false
        V.interval       = 1
        V.userCode       = ""
        V.convertedCode  = ""
        V.lastScriptName = nil
        V.lastSourceHash = nil
        V.features       = {}
        V.guiVisible     = true
        V.loopThread     = nil
        V.blockErrors    = {}
        V.version        = "1.2"

    end, function(err)
        warn(string.format(
            "[VANZ ERROR][0_GLOBAL_INIT]\n%s\n%s",
            tostring(err), debug.traceback("", 2)
        ))
    end)
end

-- ╔══════════════════════════════════════════════════════════╗
-- ║  BLOK 1 : SERVICES & CONSTANTS                          ║
-- ╚══════════════════════════════════════════════════════════╝
-- vanz
do
    local ok, err = xpcall(function()
        local V = _G.vanz

        V.Services = {
            Players          = game:GetService("Players"),
            RunService       = game:GetService("RunService"),
            UserInputService = game:GetService("UserInputService"),
            CoreGui          = game:GetService("CoreGui"),
            TweenService     = game:GetService("TweenService"),
        }

        V.LocalPlayer = V.Services.Players.LocalPlayer

        V.Theme = {
            BG         = Color3.fromRGB(12, 12, 18),
            BG2        = Color3.fromRGB(18, 18, 28),
            Accent     = Color3.fromRGB(100, 80, 255),
            AccentDark = Color3.fromRGB(60, 40, 180),
            Text       = Color3.fromRGB(230, 230, 240),
            TextDim    = Color3.fromRGB(140, 140, 160),
            Green      = Color3.fromRGB(80, 220, 120),
            Red        = Color3.fromRGB(220, 80, 80),
            Yellow     = Color3.fromRGB(255, 200, 60),
            Border     = Color3.fromRGB(50, 50, 80),
            Logo       = Color3.fromRGB(100, 80, 255),
        }

        V.GUI_WIDTH    = 260
        V.GUI_HEIGHT_P = 0.85

    end, function(err)
        warn(string.format(
            "[VANZ ERROR][1_SERVICES]\nScript: VanzLooper.lua\n%s\n%s",
            tostring(err), debug.traceback("", 2)
        ))
    end)
end

-- ╔══════════════════════════════════════════════════════════╗
-- ║  BLOK 2 : UTILITY FUNCTIONS                             ║
-- ╚══════════════════════════════════════════════════════════╝
-- vanz
do
    local ok, err = xpcall(function()
        local V = _G.vanz

        function V.Tween(obj, props, t, style, dir)
            local ts   = V.Services.TweenService
            local info = TweenInfo.new(
                t or 0.2,
                style or Enum.EasingStyle.Quart,
                dir   or Enum.EasingDirection.Out
            )
            ts:Create(obj, info, props):Play()
        end

        function V.Make(class, props, parent)
            local obj = Instance.new(class)
            for k, v in pairs(props or {}) do obj[k] = v end
            if parent then obj.Parent = parent end
            return obj
        end

        function V.Corner(px, parent)
            local c = Instance.new("UICorner")
            c.CornerRadius = UDim.new(0, px or 8)
            c.Parent = parent
            return c
        end

        function V.Stroke(color, thick, parent)
            local s = Instance.new("UIStroke")
            s.Color     = color or Color3.fromRGB(80, 80, 120)
            s.Thickness = thick or 1
            s.Parent    = parent
            return s
        end

        function V.ParseInterval(str)
            local n = tonumber(str)
            if not n or n <= 0 then return 0.001 end
            return n / 1000
        end

        function V.LogError(blockName, errMsg, trace)
            table.insert(_G.vanz.blockErrors, {
                block = blockName,
                err   = errMsg,
                trace = trace,
                time  = os.clock()
            })
            warn(string.format(
                "[VANZ ERROR][%s]\nScript: VanzLooper.lua\n%s\n%s",
                blockName, tostring(errMsg), tostring(trace)
            ))
        end

        -- ── CONVERT HELPERS ─────────────────────────────────

        -- Clipboard universal
        function V.CopyToClipboard(text)
            if type(text) ~= "string" then return false end
            local fns = { setclipboard, toclipboard, writeclipboard }
            for _, f in ipairs(fns) do
                if type(f) == "function" then
                    if pcall(f, text) then return true end
                end
            end
            if syn and type(syn.write_clipboard) == "function" then
                if pcall(syn.write_clipboard, text) then return true end
            end
            return false
        end

        -- Ambil nama script dari header decompile output
        function V.ExtractScriptName(src)
            if type(src) ~= "string" then return nil end
            local raw = src:match("%-%-%s*Script%s*:%s*([^\n\r]+)")
            if not raw then return nil end
            local name = raw:match("^%s*([^%(]+)")
            if name then
                name = name:match("^%s*(.-)%s*$")
                return name
            end
            return raw:match("^%s*(.-)%s*$")
        end

        -- Buang header komentar + baris kosong di awal
        function V.StripDecompileHeader(src)
            if type(src) ~= "string" then return "" end
            local lines = {}
            for line in (src .. "\n"):gmatch("([^\n]*)\n") do
                lines[#lines + 1] = line
            end

            local startIdx = #lines
            for i, line in ipairs(lines) do
                local trimmed = line:match("^%s*(.-)%s*$")
                if trimmed ~= "" and not trimmed:match("^%-%-") then
                    startIdx = i
                    break
                end
            end

            local out = {}
            for i = startIdx, #lines do
                out[#out + 1] = lines[i]
            end
            return table.concat(out, "\n")
        end

        -- Converter utama
        function V.ConvertDecompiled(src)
            if type(src) ~= "string" or src == "" then
                return "", nil
            end

            local scriptName = V.ExtractScriptName(src)
            local body       = V.StripDecompileHeader(src)
            body = body:gsub("^%s+", "")

            local outHeader = table.concat({
                "-- ============================================================",
                "-- VANZ CONVERTED LUAU v" .. tostring(V.version),
                "-- Original  : " .. (scriptName or "unknown"),
                "-- Time      : " .. os.date("%Y-%m-%d %H:%M:%S"),
                "-- Note      : script.Parent auto-resolved ke Tool yang di-equip",
                "-- ============================================================",
                "",
            }, "\n")

            return outHeader .. body, scriptName
        end

        -- Cari Tool dari Backpack/Character
        function V.ResolveTool(scriptName)
            local lp = V.LocalPlayer
            if not lp then return nil end

            local char     = lp.Character
            local backpack = lp:FindFirstChildOfClass("Backpack")

            if scriptName and scriptName ~= "" then
                if char then
                    local t = char:FindFirstChild(scriptName)
                    if t and t:IsA("Tool") then return t end
                end
                if backpack then
                    local t = backpack:FindFirstChild(scriptName)
                    if t and t:IsA("Tool") then return t end
                end
            end

            -- Fallback: tool pertama
            if char then
                for _, c in ipairs(char:GetChildren()) do
                    if c:IsA("Tool") then return c end
                end
            end
            if backpack then
                for _, c in ipairs(backpack:GetChildren()) do
                    if c:IsA("Tool") then return c end
                end
            end
            return nil
        end

        -- Ambil base global env (fallback chain)
        function V.BaseGlobals()
            if type(getgenv) == "function" then
                local ok, g = pcall(getgenv)
                if ok and type(g) == "table" then return g end
            end
            return _G
        end

        -- Execute converted code SEKALI dengan fake script context
        function V.RunOnce(convertedSrc, scriptName)
            local fn, compileErr = loadstring(convertedSrc)
            if not fn then
                return false, "Compile error: " .. tostring(compileErr)
            end

            local realTool   = V.ResolveTool(scriptName)
            local fakeScript = {
                Name      = scriptName or "ConvertedLocalScript",
                ClassName = "LocalScript",
                Parent    = realTool,
            }

            local baseEnv = V.BaseGlobals()
            local env = setmetatable({
                script            = fakeScript,
                VANZ_ResolveTool  = function() return realTool end,
                VANZ_ResolveScript= function() return fakeScript end,
                VANZ_ToolName     = scriptName,
            }, { __index = baseEnv })

            if type(setfenv) == "function" then
                pcall(setfenv, fn, env)
            end

            local ok, runErr = pcall(fn)
            if not ok then
                return false, tostring(runErr)
            end
            return true
        end

    end, function(err)
        warn(string.format(
            "[VANZ ERROR][2_UTILS]\nScript: VanzLooper.lua\n%s\n%s",
            tostring(err), debug.traceback("", 2)
        ))
    end)
end

-- ╔══════════════════════════════════════════════════════════╗
-- ║  BLOK 3 : LOOP ENGINE (basic)                           ║
-- ╚══════════════════════════════════════════════════════════╝
-- vanz
do
    local ok, err = xpcall(function()
        local V = _G.vanz

        function V.StopLoop()
            V.running = false
            if V.loopThread then
                pcall(task.cancel, V.loopThread)
                V.loopThread = nil
            end
        end

        function V.RestartLoop()
            V.StopLoop()
            task.wait(0.05)
            if V.convertedCode ~= "" then
                V.StartLoop()
            end
        end

    end, function(err)
        warn(string.format(
            "[VANZ ERROR][3_LOOP_ENGINE]\nScript: VanzLooper.lua\n%s\n%s",
            tostring(err), debug.traceback("", 2)
        ))
    end)
end

-- ╔══════════════════════════════════════════════════════════╗
-- ║  BLOK 4 : DRAGGABLE SYSTEM                              ║
-- ╚══════════════════════════════════════════════════════════╝
-- vanz
do
    local ok, err = xpcall(function()
        local V = _G.vanz

        function V.MakeDraggable(frame, handle)
            handle = handle or frame
            local UIS = V.Services.UserInputService
            local dragging, dragInput, dragStart, startPos = false, nil, nil, nil

            handle.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1
                or input.UserInputType == Enum.UserInputType.Touch then
                    dragging  = true
                    dragStart = input.Position
                    startPos  = frame.Position
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

            UIS.InputChanged:Connect(function(input)
                if input == dragInput and dragging then
                    local delta = input.Position - dragStart
                    frame.Position = UDim2.new(
                        startPos.X.Scale,
                        startPos.X.Offset + delta.X,
                        startPos.Y.Scale,
                        startPos.Y.Offset + delta.Y
                    )
                end
            end)
        end

    end, function(err)
        warn(string.format(
            "[VANZ ERROR][4_DRAGGABLE]\nScript: VanzLooper.lua\n%s\n%s",
            tostring(err), debug.traceback("", 2)
        ))
    end)
end

-- ╔══════════════════════════════════════════════════════════╗
-- ║  BLOK 5 : MAIN GUI BUILD                                ║
-- ╚══════════════════════════════════════════════════════════╝
-- vanz
do
    local ok, err = xpcall(function()

        local V    = _G.vanz
        local T    = V.Theme
        local Make = V.Make

        local oldGui = V.Services.CoreGui:FindFirstChild("VanzLooper")
        if oldGui then oldGui:Destroy() end

        -- ── SCREEN GUI ──────────────────────────────────────
        local SG = Make("ScreenGui", {
            Name            = "VanzLooper",
            ResetOnSpawn    = false,
            ZIndexBehavior  = Enum.ZIndexBehavior.Sibling,
            IgnoreGuiInset  = true,
        }, V.Services.CoreGui)
        V.ScreenGui = SG

        -- ── LOGO ────────────────────────────────────────────
        local Logo = Make("TextButton", {
            Name             = "Logo",
            Size             = UDim2.new(0, 48, 0, 48),
            Position         = UDim2.new(0, 10, 0.5, -24),
            BackgroundColor3 = T.Logo,
            Text             = "V",
            TextColor3       = T.Text,
            TextSize         = 22,
            Font             = Enum.Font.GothamBold,
            Visible          = false,
            ZIndex           = 20,
        }, SG)
        V.Corner(14, Logo)
        V.Stroke(T.AccentDark, 2, Logo)
        V.MakeDraggable(Logo)

        -- ── MAIN FRAME ──────────────────────────────────────
        local Main = Make("Frame", {
            Name             = "Main",
            Size             = UDim2.new(0, V.GUI_WIDTH, V.GUI_HEIGHT_P, 0),
            Position         = UDim2.new(0, 10, (1 - V.GUI_HEIGHT_P) / 2, 0),
            BackgroundColor3 = T.BG,
            BorderSizePixel  = 0,
            ClipsDescendants = true,
        }, SG)
        V.Corner(12, Main)
        V.Stroke(T.Border, 1.5, Main)
        V.MakeDraggable(Main)
        V.MainFrame = Main

        -- ── TITLE BAR ───────────────────────────────────────
        local TitleBar = Make("Frame", {
            Name             = "TitleBar",
            Size             = UDim2.new(1, 0, 0, 40),
            BackgroundColor3 = T.BG2,
            BorderSizePixel  = 0,
        }, Main)
        V.Corner(12, TitleBar)

        local grad = Instance.new("UIGradient")
        grad.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, T.AccentDark),
            ColorSequenceKeypoint.new(1, T.BG2),
        })
        grad.Rotation = 90
        grad.Parent   = TitleBar

        Make("TextLabel", {
            Name           = "Title",
            Size           = UDim2.new(1, -50, 1, 0),
            Position       = UDim2.new(0, 12, 0, 0),
            BackgroundTransparency = 1,
            Text           = "⚡ VANZ LOOPER v" .. V.version,
            TextColor3     = T.Text,
            TextSize       = 13,
            Font           = Enum.Font.GothamBold,
            TextXAlignment = Enum.TextXAlignment.Left,
        }, TitleBar)

        local MinBtn = Make("TextButton", {
            Name             = "MinBtn",
            Size             = UDim2.new(0, 30, 0, 30),
            Position         = UDim2.new(1, -36, 0, 5),
            BackgroundColor3 = T.AccentDark,
            Text             = "—",
            TextColor3       = T.Text,
            TextSize         = 14,
            Font             = Enum.Font.GothamBold,
        }, TitleBar)
        V.Corner(6, MinBtn)

        -- ── SCROLL ──────────────────────────────────────────
        local Scroll = Make("ScrollingFrame", {
            Name                = "Scroll",
            Size                = UDim2.new(1, 0, 1, -44),
            Position            = UDim2.new(0, 0, 0, 44),
            BackgroundTransparency = 1,
            BorderSizePixel     = 0,
            ScrollBarThickness  = 3,
            ScrollBarImageColor3= T.Accent,
            CanvasSize          = UDim2.new(0, 0, 0, 0),
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
        }, Main)

        Make("UIListLayout", {
            SortOrder = Enum.SortOrder.LayoutOrder,
            Padding   = UDim.new(0, 6),
        }, Scroll)

        Make("UIPadding", {
            PaddingLeft   = UDim.new(0, 8),
            PaddingRight  = UDim.new(0, 8),
            PaddingTop    = UDim.new(0, 8),
            PaddingBottom = UDim.new(0, 8),
        }, Scroll)

        V.ScrollFrame = Scroll

        -- ════════════════════════════════════════════════════
        --  HELPER FUNCTIONS
        -- ════════════════════════════════════════════════════

        local function SectionLabel(txt, order)
            Make("TextLabel", {
                Name           = "Sec_" .. txt,
                Size           = UDim2.new(1, 0, 0, 18),
                BackgroundTransparency = 1,
                Text           = txt,
                TextColor3     = T.TextDim,
                TextSize       = 11,
                Font           = Enum.Font.GothamBold,
                TextXAlignment = Enum.TextXAlignment.Left,
                LayoutOrder    = order or 0,
            }, Scroll)
        end

        -- ── TOGGLE ──────────────────────────────────────────
        local function MakeToggle(label, key, default, order, callback)
            V.features[key] = default or false

            local Row = Make("Frame", {
                Name             = "Toggle_" .. key,
                Size             = UDim2.new(1, 0, 0, 34),
                BackgroundColor3 = T.BG2,
                BorderSizePixel  = 0,
                LayoutOrder      = order or 0,
            }, Scroll)
            V.Corner(8, Row)
            V.Stroke(T.Border, 1, Row)

            Make("TextLabel", {
                Size           = UDim2.new(1, -54, 1, 0),
                Position       = UDim2.new(0, 10, 0, 0),
                BackgroundTransparency = 1,
                Text           = label,
                TextColor3     = T.Text,
                TextSize       = 12,
                Font           = Enum.Font.Gotham,
                TextXAlignment = Enum.TextXAlignment.Left,
            }, Row)

            local Pill = Make("Frame", {
                Size             = UDim2.new(0, 40, 0, 20),
                Position         = UDim2.new(1, -48, 0.5, -10),
                BackgroundColor3 = V.features[key] and T.Green or T.Red,
                BorderSizePixel  = 0,
            }, Row)
            V.Corner(10, Pill)

            local Dot = Make("Frame", {
                Size             = UDim2.new(0, 16, 0, 16),
                Position         = V.features[key]
                    and UDim2.new(1, -18, 0.5, -8)
                    or  UDim2.new(0, 2,   0.5, -8),
                BackgroundColor3 = T.Text,
            }, Pill)
            V.Corner(8, Dot)

            local Btn = Make("TextButton", {
                Size                   = UDim2.new(1, 0, 1, 0),
                BackgroundTransparency = 1,
                Text                   = "",
            }, Row)

            Btn.MouseButton1Click:Connect(function()
                V.features[key] = not V.features[key]
                local on = V.features[key]
                V.Tween(Pill, { BackgroundColor3 = on and T.Green or T.Red })
                V.Tween(Dot,  { Position = on
                    and UDim2.new(1, -18, 0.5, -8)
                    or  UDim2.new(0, 2,   0.5, -8)
                })
                if callback then callback(on) end
            end)

            return Row, Pill, Dot
        end

        -- ── LOOP TOGGLE ─────────────────────────────────────
        local function MakeLoopToggle(order)
            local key = "loopActive"
            V.features[key] = false

            local Row = Make("Frame", {
                Name             = "Toggle_loopActive",
                Size             = UDim2.new(1, 0, 0, 42),
                BackgroundColor3 = T.BG2,
                BorderSizePixel  = 0,
                LayoutOrder      = order or 0,
            }, Scroll)
            V.Corner(8, Row)
            V.Stroke(T.Accent, 1.5, Row)

            local Lbl = Make("TextLabel", {
                Name           = "LoopLbl",
                Size           = UDim2.new(1, -60, 1, 0),
                Position       = UDim2.new(0, 10, 0, 0),
                BackgroundTransparency = 1,
                Text           = "🔁  Loop (auto-convert)",
                TextColor3     = T.Text,
                TextSize       = 13,
                Font           = Enum.Font.GothamBold,
                TextXAlignment = Enum.TextXAlignment.Left,
            }, Row)

            local SubLbl = Make("TextLabel", {
                Name           = "LoopSub",
                Size           = UDim2.new(1, -60, 0, 14),
                Position       = UDim2.new(0, 10, 0, 24),
                BackgroundTransparency = 1,
                Text           = "OFF",
                TextColor3     = T.Red,
                TextSize       = 10,
                Font           = Enum.Font.Gotham,
                TextXAlignment = Enum.TextXAlignment.Left,
            }, Row)

            local Pill = Make("Frame", {
                Size             = UDim2.new(0, 44, 0, 24),
                Position         = UDim2.new(1, -52, 0.5, -12),
                BackgroundColor3 = T.Red,
                BorderSizePixel  = 0,
            }, Row)
            V.Corner(12, Pill)

            local Dot = Make("Frame", {
                Size             = UDim2.new(0, 18, 0, 18),
                Position         = UDim2.new(0, 3, 0.5, -9),
                BackgroundColor3 = T.Text,
            }, Pill)
            V.Corner(9, Dot)

            local Btn = Make("TextButton", {
                Size                   = UDim2.new(1, 0, 1, 0),
                BackgroundTransparency = 1,
                Text                   = "",
            }, Row)

            V.LoopTogglePill   = Pill
            V.LoopToggleDot    = Dot
            V.LoopToggleSubLbl = SubLbl

            local function SyncLoopToggle(on)
                V.Tween(Pill, { BackgroundColor3 = on and T.Green or T.Red })
                V.Tween(Dot,  { Position = on
                    and UDim2.new(1, -21, 0.5, -9)
                    or  UDim2.new(0, 3,   0.5, -9)
                })
                SubLbl.Text       = on and "RUNNING" or "OFF"
                SubLbl.TextColor3 = on and T.Green    or T.Red
            end

            V.SyncLoopToggle = SyncLoopToggle

            Btn.MouseButton1Click:Connect(function()
                V.features[key] = not V.features[key]
                local on = V.features[key]
                SyncLoopToggle(on)

                if on then
                    -- Ambil kode terbaru
                    if V.CodeBoxRef then
                        V.userCode = V.CodeBoxRef.Text
                    end

                    if V.userCode == "" then
                        V.features[key] = false
                        SyncLoopToggle(false)
                        if V.StatusLabel then
                            V.StatusLabel.Text      = "⚠ Kode kosong!"
                            V.StatusLabel.TextColor3= T.Yellow
                        end
                        return
                    end

                    -- AUTO CONVERT
                    local converted, scriptName = V.ConvertDecompiled(V.userCode)
                    if converted == "" then
                        V.features[key] = false
                        SyncLoopToggle(false)
                        if V.StatusLabel then
                            V.StatusLabel.Text      = "⚠ Convert gagal"
                            V.StatusLabel.TextColor3= T.Red
                        end
                        return
                    end

                    V.convertedCode  = converted
                    V.lastScriptName = scriptName
                    V.lastSourceHash = V.userCode

                    -- Kalau ada ConvertBox, update juga
                    if V.ConvertBoxRef then
                        V.ConvertBoxRef.Text = converted
                    end

                    V.StartLoop()
                    if V.StatusLabel then
                        V.StatusLabel.Text      = "● RUNNING (" .. tostring(V.interval) .. "ms) • " .. (scriptName or "?")
                        V.StatusLabel.TextColor3= T.Green
                    end
                else
                    V.StopLoop()
                    if V.StatusLabel then
                        V.StatusLabel.Text      = "● STOPPED"
                        V.StatusLabel.TextColor3= T.Red
                    end
                end
            end)

            return Row
        end

        -- ── INPUT BOX ───────────────────────────────────────
        local function MakeInput(label, placeholder, order, callback)
            local Wrap = Make("Frame", {
                Name             = "Input_" .. label,
                Size             = UDim2.new(1, 0, 0, 54),
                BackgroundColor3 = T.BG2,
                BorderSizePixel  = 0,
                LayoutOrder      = order or 0,
            }, Scroll)
            V.Corner(8, Wrap)
            V.Stroke(T.Border, 1, Wrap)

            Make("TextLabel", {
                Size           = UDim2.new(1, -10, 0, 20),
                Position       = UDim2.new(0, 10, 0, 2),
                BackgroundTransparency = 1,
                Text           = label,
                TextColor3     = T.TextDim,
                TextSize       = 11,
                Font           = Enum.Font.Gotham,
                TextXAlignment = Enum.TextXAlignment.Left,
            }, Wrap)

            local Box = Make("TextBox", {
                Name              = "Box",
                Size              = UDim2.new(1, -16, 0, 26),
                Position          = UDim2.new(0, 8, 0, 22),
                BackgroundColor3  = T.BG,
                TextColor3        = T.Text,
                PlaceholderText   = placeholder or "",
                PlaceholderColor3 = T.TextDim,
                Text              = "",
                TextSize          = 12,
                Font              = Enum.Font.Code,
                ClearTextOnFocus  = false,
                TextXAlignment    = Enum.TextXAlignment.Left,
            }, Wrap)
            V.Corner(6, Box)
            V.Stroke(T.Accent, 1, Box)
            Make("UIPadding", { PaddingLeft = UDim.new(0, 6) }, Box)

            Box.FocusLost:Connect(function()
                if callback then callback(Box.Text) end
            end)

            return Wrap, Box
        end

        -- ── CODE BOX (INPUT) ────────────────────────────────
        local function MakeCodeBox(order)
            local Wrap = Make("Frame", {
                Name             = "CodeBox",
                Size             = UDim2.new(1, 0, 0, 130),
                BackgroundColor3 = T.BG2,
                BorderSizePixel  = 0,
                LayoutOrder      = order or 0,
            }, Scroll)
            V.Corner(8, Wrap)
            V.Stroke(T.Border, 1, Wrap)

            local HeaderRow = Make("Frame", {
                Size             = UDim2.new(1, 0, 0, 24),
                BackgroundTransparency = 1,
            }, Wrap)

            Make("TextLabel", {
                Size           = UDim2.new(1, -80, 1, 0),
                Position       = UDim2.new(0, 10, 0, 0),
                BackgroundTransparency = 1,
                Text           = "📝 Input (paste decompile output / Luau)",
                TextColor3     = T.TextDim,
                TextSize       = 10,
                Font           = Enum.Font.Gotham,
                TextXAlignment = Enum.TextXAlignment.Left,
            }, HeaderRow)

            local ClearBtn = Make("TextButton", {
                Name             = "ClearCodeBtn",
                Size             = UDim2.new(0, 70, 0, 18),
                Position         = UDim2.new(1, -76, 0.5, -9),
                BackgroundColor3 = Color3.fromRGB(80, 40, 40),
                Text             = "🗑 Clear",
                TextColor3       = T.Text,
                TextSize         = 10,
                Font             = Enum.Font.GothamBold,
            }, HeaderRow)
            V.Corner(5, ClearBtn)
            V.Stroke(T.Red, 1, ClearBtn)

            local Box = Make("TextBox", {
                Name                 = "CodeInput",
                Size                 = UDim2.new(1, -16, 0, 98),
                Position             = UDim2.new(0, 8, 0, 26),
                BackgroundColor3     = T.BG,
                TextColor3           = T.Green,
                PlaceholderText      = "-- paste hasil decompile atau tulis luau",
                PlaceholderColor3    = T.TextDim,
                Text                 = "",
                TextSize             = 11,
                Font                 = Enum.Font.Code,
                ClearTextOnFocus     = false,
                MultiLine            = true,
                TextXAlignment       = Enum.TextXAlignment.Left,
                TextYAlignment       = Enum.TextYAlignment.Top,
            }, Wrap)
            V.Corner(6, Box)
            V.Stroke(T.Accent, 1, Box)
            Make("UIPadding", {
                PaddingLeft = UDim.new(0, 6),
                PaddingTop  = UDim.new(0, 4),
            }, Box)

            Box.FocusLost:Connect(function()
                V.userCode = Box.Text
            end)

            ClearBtn.MouseButton1Click:Connect(function()
                Box.Text   = ""
                V.userCode = ""
                if V.ConvertBoxRef then V.ConvertBoxRef.Text = "" end
                if V.running then
                    V.StopLoop()
                    V.features["loopActive"] = false
                    if V.SyncLoopToggle then V.SyncLoopToggle(false) end
                    if V.StatusLabel then
                        V.StatusLabel.Text      = "● STOPPED (code cleared)"
                        V.StatusLabel.TextColor3= T.Red
                    end
                end
            end)

            ClearBtn.MouseEnter:Connect(function()
                V.Tween(ClearBtn, { BackgroundColor3 = T.Red })
            end)
            ClearBtn.MouseLeave:Connect(function()
                V.Tween(ClearBtn, { BackgroundColor3 = Color3.fromRGB(80, 40, 40) })
            end)

            return Wrap, Box
        end

        -- ── CONVERT BOX (OUTPUT, read-only) ─────────────────
        local function MakeConvertBox(order)
            local Wrap = Make("Frame", {
                Name             = "ConvertBox",
                Size             = UDim2.new(1, 0, 0, 150),
                BackgroundColor3 = T.BG2,
                BorderSizePixel  = 0,
                LayoutOrder      = order or 0,
            }, Scroll)
            V.Corner(8, Wrap)
            V.Stroke(T.Green, 1, Wrap)

            local HeaderRow = Make("Frame", {
                Size             = UDim2.new(1, 0, 0, 24),
                BackgroundTransparency = 1,
            }, Wrap)

            Make("TextLabel", {
                Size           = UDim2.new(1, -80, 1, 0),
                Position       = UDim2.new(0, 10, 0, 0),
                BackgroundTransparency = 1,
                Text           = "✅ Converted Luau",
                TextColor3     = T.Green,
                TextSize       = 10,
                Font           = Enum.Font.GothamBold,
                TextXAlignment = Enum.TextXAlignment.Left,
            }, HeaderRow)

            local CopyBtn = Make("TextButton", {
                Name             = "CopyBtn",
                Size             = UDim2.new(0, 70, 0, 18),
                Position         = UDim2.new(1, -76, 0.5, -9),
                BackgroundColor3 = T.AccentDark,
                Text             = "📋 Copy",
                TextColor3       = T.Text,
                TextSize         = 10,
                Font             = Enum.Font.GothamBold,
            }, HeaderRow)
            V.Corner(5, CopyBtn)
            V.Stroke(T.Accent, 1, CopyBtn)

            local Result = Make("TextBox", {
                Name                 = "ResultBox",
                Size                 = UDim2.new(1, -16, 0, 118),
                Position             = UDim2.new(0, 8, 0, 26),
                BackgroundColor3     = T.BG,
                TextColor3           = T.Green,
                Text                 = "",
                PlaceholderText      = "-- klik Convert untuk generate",
                PlaceholderColor3    = T.TextDim,
                TextSize             = 11,
                Font                 = Enum.Font.Code,
                MultiLine            = true,
                TextEditable         = false,
                ClearTextOnFocus     = false,
                TextXAlignment       = Enum.TextXAlignment.Left,
                TextYAlignment       = Enum.TextYAlignment.Top,
            }, Wrap)
            V.Corner(6, Result)
            V.Stroke(T.Border, 1, Result)
            Make("UIPadding", {
                PaddingLeft = UDim.new(0, 6),
                PaddingTop  = UDim.new(0, 4),
            }, Result)

            CopyBtn.MouseButton1Click:Connect(function()
                if Result.Text == "" then
                    CopyBtn.Text = "⚠ Empty"
                    task.delay(1, function() CopyBtn.Text = "📋 Copy" end)
                    return
                end
                if V.CopyToClipboard(Result.Text) then
                    CopyBtn.Text = "✅ Copied"
                    task.delay(1, function() CopyBtn.Text = "📋 Copy" end)
                else
                    CopyBtn.Text = "❌ Failed"
                    task.delay(1, function() CopyBtn.Text = "📋 Copy" end)
                end
            end)

            CopyBtn.MouseEnter:Connect(function()
                V.Tween(CopyBtn, { BackgroundColor3 = T.Accent })
            end)
            CopyBtn.MouseLeave:Connect(function()
                V.Tween(CopyBtn, { BackgroundColor3 = T.AccentDark })
            end)

            return Wrap, Result
        end

        -- ── BIG BUTTON ──────────────────────────────────────
        local function MakeBigBtn(label, color, order, callback)
            local Btn = Make("TextButton", {
                Name             = "BigBtn_" .. label,
                Size             = UDim2.new(1, 0, 0, 34),
                BackgroundColor3 = color or T.Accent,
                Text             = label,
                TextColor3       = T.Text,
                TextSize         = 12,
                Font             = Enum.Font.GothamBold,
                LayoutOrder      = order or 0,
            }, Scroll)
            V.Corner(8, Btn)

            Btn.MouseButton1Click:Connect(function()
                if callback then callback() end
            end)
            Btn.MouseEnter:Connect(function()
                V.Tween(Btn, { BackgroundColor3 = (color or T.Accent):Lerp(Color3.new(1,1,1), 0.15) })
            end)
            Btn.MouseLeave:Connect(function()
                V.Tween(Btn, { BackgroundColor3 = color or T.Accent })
            end)
            return Btn
        end

        -- ── STATUS BAR ──────────────────────────────────────
        local function MakeStatusBar(order)
            local Bar = Make("Frame", {
                Name             = "StatusBar",
                Size             = UDim2.new(1, 0, 0, 28),
                BackgroundColor3 = T.BG2,
                BorderSizePixel  = 0,
                LayoutOrder      = order,
            }, Scroll)
            V.Corner(8, Bar)

            local Lbl = Make("TextLabel", {
                Name           = "StatusLbl",
                Size           = UDim2.new(1, -10, 1, 0),
                Position       = UDim2.new(0, 10, 0, 0),
                BackgroundTransparency = 1,
                Text           = "● IDLE",
                TextColor3     = T.TextDim,
                TextSize       = 11,
                Font           = Enum.Font.GothamBold,
                TextXAlignment = Enum.TextXAlignment.Left,
            }, Bar)

            V.StatusLabel = Lbl
            return Bar
        end

        -- ════════════════════════════════════════════════════
        --  SUSUN KOMPONEN
        -- ════════════════════════════════════════════════════

        SectionLabel("─── STATUS ───", 1)
        MakeStatusBar(2)

        SectionLabel("─── INPUT ───", 3)
        local _, CodeBox = MakeCodeBox(4)
        V.CodeBoxRef = CodeBox

        SectionLabel("─── CONVERT ───", 5)

        MakeBigBtn("🔧  Convert to Luau", T.Accent, 6, function()
            local src = CodeBox.Text
            if not src or src == "" then
                V.StatusLabel.Text      = "⚠ Kode kosong!"
                V.StatusLabel.TextColor3= T.Yellow
                return
            end

            local converted, scriptName = V.ConvertDecompiled(src)
            if converted == "" then
                V.StatusLabel.Text      = "⚠ Convert gagal"
                V.StatusLabel.TextColor3= T.Red
                return
            end

            V.convertedCode  = converted
            V.lastScriptName = scriptName
            if V.ConvertBoxRef then
                V.ConvertBoxRef.Text = converted
            end

            V.StatusLabel.Text      = "● Converted • " .. (scriptName or "unknown")
            V.StatusLabel.TextColor3= T.Green
        end)

        local _, ConvertBox = MakeConvertBox(7)
        V.ConvertBoxRef = ConvertBox

        SectionLabel("─── INTERVAL ───", 8)
        local _, IntervalBox = MakeInput(
            "⏱ Interval (ms)",
            "contoh: 1 | 5 | 0.001",
            9,
            function(val)
                local n = tonumber(val)
                if n and n > 0 then
                    V.interval = n
                    if V.running then V.RestartLoop() end
                end
            end
        )
        V.IntervalBoxRef = IntervalBox

        SectionLabel("─── KONTROL ───", 10)

        -- LOOP TOGGLE (auto convert + execute)
        MakeLoopToggle(11)

        MakeBigBtn("↺  Restart Loop", T.Accent, 12, function()
            V.userCode = CodeBox.Text
            if V.userCode == "" then
                V.StatusLabel.Text      = "⚠ Kode kosong!"
                V.StatusLabel.TextColor3= T.Yellow
                return
            end

            local converted, scriptName = V.ConvertDecompiled(V.userCode)
            if converted == "" then
                V.StatusLabel.Text      = "⚠ Convert gagal"
                V.StatusLabel.TextColor3= T.Red
                return
            end
            V.convertedCode  = converted
            V.lastScriptName = scriptName
            if V.ConvertBoxRef then V.ConvertBoxRef.Text = converted end

            V.RestartLoop()
            V.features["loopActive"] = true
            if V.SyncLoopToggle then V.SyncLoopToggle(true) end
            V.StatusLabel.Text      = "● RESTARTED • " .. (scriptName or "?") .. " • " .. tostring(V.interval) .. "ms"
            V.StatusLabel.TextColor3= T.Text
        end)

        SectionLabel("─── FITUR ───", 13)

        MakeToggle("Auto-Restart on Error",  "autoRestart", false, 14)
        MakeToggle("Print per Tick (debug)", "printTick",   false, 15)
        MakeToggle("Pause on Error",         "pauseOnErr",  true,  16)
        MakeToggle("Clear Errors on Start",  "clearErr",    true,  17)

        SectionLabel("─── ERROR LOG ───", 18)

        MakeBigBtn("🔍 Lihat Error Log", T.BG2, 19, function()
            if #V.blockErrors == 0 then
                warn("[VANZ] Tidak ada error."); return
            end
            for i, e in ipairs(V.blockErrors) do
                warn(string.format(
                    "[VANZ ERROR LOG #%d][%s]\n%s\n%s",
                    i, e.block, e.err, e.trace or ""
                ))
            end
        end)

        MakeBigBtn("🗑 Hapus Error Log", Color3.fromRGB(80,50,50), 20, function()
            V.blockErrors = {}
            warn("[VANZ] Error log di-clear.")
        end)

        -- ── MINIMIZE / RESTORE ──────────────────────────────
        MinBtn.MouseButton1Click:Connect(function()
            V.guiVisible = false
            V.Tween(Main, { Size = UDim2.new(0, 0, 0, 0) }, 0.2)
            task.wait(0.22)
            Main.Visible = false
            Logo.Visible = true
        end)

        Logo.MouseButton1Click:Connect(function()
            Logo.Visible = false
            Main.Visible = true
            Main.Size    = UDim2.new(0, 0, 0, 0)
            V.Tween(Main, {
                Size = UDim2.new(0, V.GUI_WIDTH, V.GUI_HEIGHT_P, 0)
            }, 0.2)
            V.guiVisible = true
        end)

        -- ── AUTO-RESIZE ─────────────────────────────────────
        local Camera = workspace.CurrentCamera
        local function ResizeForScreen()
            local vp = Camera.ViewportSize
            local w  = math.min(V.GUI_WIDTH, vp.X - 20)
            Main.Size = UDim2.new(0, w, V.GUI_HEIGHT_P, 0)
        end
        Camera:GetPropertyChangedSignal("ViewportSize"):Connect(ResizeForScreen)
        ResizeForScreen()

    end, function(err)
        warn(string.format(
            "[VANZ ERROR][5_GUI_BUILD]\nScript: VanzLooper.lua\n%s\n%s",
            tostring(err), debug.traceback("", 2)
        ))
    end)
end

-- ╔══════════════════════════════════════════════════════════╗
-- ║  BLOK 6 : LOOP ENGINE (definitive, pake convertedCode)  ║
-- ╚══════════════════════════════════════════════════════════╝
-- vanz
do
    local ok, err = xpcall(function()
        local V = _G.vanz

        function V.StartLoop()
            if V.running then return end
            if V.convertedCode == "" then
                V.LogError("LOOP_START", "No converted code. Convert first.", "")
                return
            end

            if V.features.clearErr then V.blockErrors = {} end

            V.running    = true
            V.loopThread = task.spawn(function()
                local tickCount = 0

                while V.running do
                    tickCount = tickCount + 1

                    if V.features.printTick then
                        print(string.format(
                            "[VANZ TICK] #%d | %sms | %s",
                            tickCount,
                            tostring(V.interval),
                            tostring(V.lastScriptName or "?")
                        ))
                    end

                    -- Execute with fake script context
                    local ok2, runErr = V.RunOnce(V.convertedCode, V.lastScriptName)

                    if not ok2 then
                        V.LogError("LOOP_EXEC_T" .. tickCount, runErr, "")

                        if V.features.pauseOnErr and not V.features.autoRestart then
                            V.running = false
                            V.features["loopActive"] = false
                            if V.SyncLoopToggle then V.SyncLoopToggle(false) end
                            if V.StatusLabel then
                                V.StatusLabel.Text      = "● ERROR — PAUSED"
                                V.StatusLabel.TextColor3= V.Theme.Red
                            end
                            break
                        elseif V.features.autoRestart then
                            task.wait(0.5)
                        end
                    end

                    task.wait(V.ParseInterval(tostring(V.interval)))
                end
            end)
        end

    end, function(err)
        warn(string.format(
            "[VANZ ERROR][6_LOOP_PATCH]\nScript: VanzLooper.lua\n%s\n%s",
            tostring(err), debug.traceback("", 2)
        ))
    end)
end

-- ╔══════════════════════════════════════════════════════════╗
-- ║  BLOK 7 : BOOT MESSAGE                                  ║
-- ╚══════════════════════════════════════════════════════════╝
-- vanz
do
    local ok, err = xpcall(function()
        print([[
 ╔══════════════════════════════════════╗
 ║  VANZ LOOPER v1.2 LOADED            ║
 ║  Convert + Loop Auto-Convert Aktif  ║
 ║  Paste decompile output → Convert   ║
 ╚══════════════════════════════════════╝
]])
    end, function(err)
        warn(string.format(
            "[VANZ ERROR][7_BOOT]\nScript: VanzLooper.lua\n%s\n%s",
            tostring(err), debug.traceback("", 2)
        ))
    end)
end