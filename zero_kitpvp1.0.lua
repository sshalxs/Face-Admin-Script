--[[  zero.pw  |  [1.8 KIT PVP]  (Bloxine Extra)
      combat : killaura / aim
      visual : esp / hud / target hud / keystrokes / particles
      misc   : custom kill sound
      меню: кнопка «Z» слева или RightShift
]]

local VERSION = "1.0"

--============================== services ==============================
local Players     = game:GetService("Players")
local RS          = game:GetService("ReplicatedStorage")
local WS          = game:GetService("Workspace")
local RunService  = game:GetService("RunService")
local UIS         = game:GetService("UserInputService")
local Tween       = game:GetService("TweenService")
local Debris      = game:GetService("Debris")
local LocalPlayer = Players.LocalPlayer

--============================== config ===============================
local CFG = {
    ka   = { on = false, range = 14, cps = 12, wall = false, team = false, face = true },
    aim  = { on = false, fov = 220, smooth = 0.35, part = "Head" },
    esp  = { on = false, box = true, name = true, hp = true, dist = true, team = false,
             maxDist = 500, vis = Color3.fromRGB(140, 255, 170),
             hid = Color3.fromRGB(255, 80, 80) },
    hud  = { on = true },
    thud = { on = true },
    keys = { on = true },
    fx   = { aura = false, kill = true },
    snd  = { on = true, id = "", vol = 0.7 },
    dbg  = { on = true },
}
if getgenv then getgenv().ZEROPW_KIT = CFG end

local ACCENT = Color3.fromRGB(126, 82, 235)
local BG     = Color3.fromRGB(14, 12, 19)
local ROW    = Color3.fromRGB(23, 20, 31)
local TXT    = Color3.fromRGB(214, 209, 230)
local DIM    = Color3.fromRGB(132, 122, 158)

local function log(t) print("[zero.pw kit] " .. tostring(t)) end

--============================== helpers ==============================
local function alive(plr)
    local ch = plr.Character
    if not ch or not ch.Parent then return false end
    local hum = ch:FindFirstChildOfClass("Humanoid")
    if not hum or hum.Health <= 0 then return false end
    if ch:GetAttribute("Dead") == true then return false end
    return true
end

local function isEnemy(plr)
    if plr == LocalPlayer then return false end
    local lt, pt = LocalPlayer.Team, plr.Team
    if lt == nil or pt == nil then return true end
    return lt ~= pt
end

local function pickPart(ch)
    local p = ch:FindFirstChild(CFG.aim.part)
        or ch:FindFirstChild("Head") or ch.PrimaryPart
    if p and p:IsA("BasePart") then return p end
end

local visParams
local function visible(ch, part)
    local cam = WS.CurrentCamera
    if not cam then return true end
    if not visParams then
        visParams = RaycastParams.new()
        visParams.FilterType = Enum.RaycastFilterType.Exclude
        visParams.IgnoreWater = true
    end
    visParams.FilterDescendantsInstances = { LocalPlayer.Character, cam }
    local res = WS:Raycast(cam.CFrame.Position, part.Position - cam.CFrame.Position, visParams)
    return not res or res.Instance:IsDescendantOf(ch)
end

-- максимально близкая к центру цель
local function findTarget(maxPx)
    local cam = WS.CurrentCamera
    if not cam then return nil, nil end
    local vp = cam.ViewportSize
    local cx, cy = vp.X * 0.5, vp.Y * 0.5
    local best, bestPart, bestD = nil, nil, maxPx * maxPx
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and alive(plr) and (not CFG.ka.team or isEnemy(plr)) then
            local part = pickPart(plr.Character)
            if part then
                local sp, on = cam:WorldToViewportPoint(part.Position)
                if on then
                    local dx, dy = sp.X - cx, sp.Y - cy
                    local d = dx * dx + dy * dy
                    if d < bestD then
                        bestD, best, bestPart = d, plr, part
                    end
                end
            end
        end
    end
    return best, bestPart
end

local function nearestInRange(range, needVis)
    local cam = WS.CurrentCamera
    local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not cam or not hrp then return nil, nil end
    local best, bestPart, bestD = nil, nil, range
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and alive(plr) and (not CFG.ka.team or isEnemy(plr)) then
            local part = pickPart(plr.Character)
            if part then
                local d = (part.Position - hrp.Position).Magnitude
                if d < bestD and (not needVis or visible(plr.Character, part)) then
                    bestD, best, bestPart = d, plr, part
                end
            end
        end
    end
    return best, bestPart
end

local function equippedTool()
    local ch = LocalPlayer.Character
    return ch and ch:FindFirstChildOfClass("Tool")
end

--============================== esp ==================================
local hud = Instance.new("ScreenGui")
hud.Name = "zpkit_hud"
hud.ResetOnSpawn = false
hud.IgnoreGuiInset = true
hud.DisplayOrder = 900
hud.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
hud.Parent = LocalPlayer:WaitForChild("PlayerGui")

local espObjs, visCache = {}, {}

local function mkEsp()
    local o = {}
    o.box = Instance.new("Frame")
    o.box.BackgroundTransparency = 1
    o.stroke = Instance.new("UIStroke")
    o.stroke.Thickness = 1.3
    o.stroke.Parent = o.box
    o.box.Parent = hud

    o.hpBg = Instance.new("Frame")
    o.hpBg.BackgroundColor3 = Color3.fromRGB(12, 12, 12)
    o.hpBg.BorderSizePixel = 0
    o.hpBg.Parent = hud
    o.hpFg = Instance.new("Frame")
    o.hpFg.BorderSizePixel = 0
    o.hpFg.Parent = hud

    o.name = Instance.new("TextLabel")
    o.name.BackgroundTransparency = 1
    o.name.Font = Enum.Font.GothamBold
    o.name.TextSize = 13
    o.name.TextStrokeTransparency = 0
    o.name.TextXAlignment = Enum.TextXAlignment.Center
    o.name.Parent = hud

    o.dist = Instance.new("TextLabel")
    o.dist.BackgroundTransparency = 1
    o.dist.Font = Enum.Font.Gotham
    o.dist.TextSize = 12
    o.dist.TextStrokeTransparency = 0
    o.dist.TextXAlignment = Enum.TextXAlignment.Center
    o.dist.Parent = hud

    o.list = { o.box, o.hpBg, o.hpFg, o.name, o.dist }
    return o
end

local function showEsp(o, v)
    for _, g in ipairs(o.list) do g.Visible = v end
end

local espDrawn, lastErr = 0, nil

local function drawEsp()
    espDrawn = 0
    local cam = WS.CurrentCamera
    if not cam then return end
    local shown = {}
    for _, plr in ipairs(Players:GetPlayers()) do
        local o = espObjs[plr]
        local okDraw = CFG.esp.on and plr ~= LocalPlayer and alive(plr)
            and (not CFG.esp.team or isEnemy(plr))
        if okDraw then
            local ch = plr.Character
            local head = ch and ch:FindFirstChild("Head")
            local root = ch and ch:FindFirstChild("HumanoidRootPart")
            local hum = ch and ch:FindFirstChildOfClass("Humanoid")
            if head and root and hum then
                local dist = (cam.CFrame.Position - head.Position).Magnitude
                local top = cam:WorldToViewportPoint(head.Position + Vector3.new(0, 0.5, 0))
                local bot = cam:WorldToViewportPoint(root.Position - Vector3.new(0, 2.4, 0))
                if dist <= CFG.esp.maxDist and top.Z > 0 and bot.Z > 0 then
                    local h = math.abs(bot.Y - top.Y)
                    local w = h * 0.45
                    if h > 8 and w > 4 then
                        if not o then o = mkEsp() espObjs[plr] = o end
                        shown[o] = true
                        espDrawn = espDrawn + 1

                        local c = visCache[ch]
                        if not c or os.clock() - c.t > 0.2 then
                            local pp = pickPart(ch)
                            c = { t = os.clock(), v = (pp and visible(ch, pp)) or false }
                            visCache[ch] = c
                        end
                        local col = c.v and CFG.esp.vis or CFG.esp.hid

                        local x, y = top.X - w * 0.5, top.Y
                        o.box.Visible = CFG.esp.box
                        if CFG.esp.box then
                            o.box.Position = UDim2.fromOffset(x, y)
                            o.box.Size = UDim2.fromOffset(w, h)
                            o.stroke.Color = col
                        end

                        local frac = math.clamp(hum.Health / math.max(hum.MaxHealth, 1), 0, 1)
                        o.hpBg.Visible, o.hpFg.Visible = CFG.esp.hp, CFG.esp.hp
                        if CFG.esp.hp then
                            o.hpBg.Position = UDim2.fromOffset(x - 6, y)
                            o.hpBg.Size = UDim2.fromOffset(3, h)
                            o.hpFg.Position = UDim2.fromOffset(x - 6, y + h * (1 - frac))
                            o.hpFg.Size = UDim2.fromOffset(3, h * frac)
                            o.hpFg.BackgroundColor3 = Color3.fromRGB(
                                math.floor(255 * (1 - frac)), math.floor(255 * frac), 40)
                        end

                        o.name.Visible = CFG.esp.name
                        if CFG.esp.name then
                            o.name.Text = plr.Name
                            o.name.TextColor3 = col
                            o.name.Position = UDim2.fromOffset(x - 30, y - 18)
                            o.name.Size = UDim2.fromOffset(w + 60, 14)
                        end

                        o.dist.Visible = CFG.esp.dist
                        if CFG.esp.dist then
                            o.dist.Text = string.format("%d m", math.floor(dist))
                            o.dist.TextColor3 = col
                            o.dist.Position = UDim2.fromOffset(x - 30, y + h + 1)
                            o.dist.Size = UDim2.fromOffset(w + 60, 13)
                        end
                    elseif o then showEsp(o, false) end
                elseif o then showEsp(o, false) end
            elseif o then showEsp(o, false) end
        elseif o then showEsp(o, false) end
    end
    for plr, o in pairs(espObjs) do
        if not shown[o] then showEsp(o, false) end
        if plr.Parent == nil then
            for _, g in ipairs(o.list) do pcall(function() g:Destroy() end) end
            espObjs[plr] = nil
        end
    end
end

Players.PlayerRemoving:Connect(function(plr)
    local o = espObjs[plr]
    if o then
        for _, g in ipairs(o.list) do pcall(function() g:Destroy() end) end
        espObjs[plr] = nil
    end
end)

--============================== ui root ==============================
local function inst(cls, props, parent)
    local o = Instance.new(cls)
    for k, v in pairs(props or {}) do o[k] = v end
    if parent then o.Parent = parent end
    return o
end

local fabGui = inst("ScreenGui", {
    Name = "zpkit_fab", ResetOnSpawn = false, IgnoreGuiInset = true,
    DisplayOrder = 1200, Parent = LocalPlayer:WaitForChild("PlayerGui"),
})

local fab = inst("TextButton", {
    Size = UDim2.fromOffset(48, 48),
    Position = UDim2.new(0, 14, 0.5, -24),
    BackgroundColor3 = Color3.fromRGB(24, 18, 38),
    BorderSizePixel = 0, Text = "Z", TextSize = 20,
    Font = Enum.Font.GothamBlack, TextColor3 = Color3.fromRGB(190, 160, 255),
    AutoButtonColor = false, Active = true,
}, fabGui)
inst("UICorner", { CornerRadius = UDim.new(0.5, 0) }, fab)
inst("UIStroke", { Color = ACCENT, Thickness = 1.4 }, fab)

local menuGui = inst("ScreenGui", {
    Name = "zpkit_menu", ResetOnSpawn = false, IgnoreGuiInset = true,
    DisplayOrder = 1100, ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    Parent = LocalPlayer:WaitForChild("PlayerGui"),
})

local win = inst("Frame", {
    Size = UDim2.fromOffset(450, 306),
    Position = UDim2.fromScale(0.5, 0.5),
    AnchorPoint = Vector2.new(0.5, 0.5),
    BackgroundColor3 = BG, BorderSizePixel = 0, Active = true,
}, menuGui)
inst("UICorner", { CornerRadius = UDim.new(0, 10) }, win)
inst("UIStroke", { Color = Color3.fromRGB(60, 42, 92), Thickness = 1 }, win)

-- шапка: за неё таскаем окно (иначе палец тянет окно вместо тапа по тумблеру)
local header = inst("Frame", {
    Size = UDim2.new(1, 0, 0, 26),
    BackgroundColor3 = Color3.fromRGB(19, 16, 26),
    BorderSizePixel = 0, Active = true,
}, win)
inst("UICorner", { CornerRadius = UDim.new(0, 10) }, header)

inst("TextLabel", {
    Size = UDim2.new(0, 200, 1, 0), Position = UDim2.fromOffset(12, 0),
    BackgroundTransparency = 1, Text = "zero.pw  kit pvp",
    Font = Enum.Font.GothamBlack, TextSize = 13,
    TextColor3 = Color3.fromRGB(200, 175, 255),
    TextXAlignment = Enum.TextXAlignment.Left,
}, header)

local closeBtn = inst("TextButton", {
    Size = UDim2.fromOffset(22, 22), Position = UDim2.new(1, -28, 0, 2),
    BackgroundTransparency = 1, Text = "x", TextSize = 15,
    Font = Enum.Font.GothamBold, TextColor3 = DIM, AutoButtonColor = false,
}, header)

local sidebar = inst("Frame", {
    Size = UDim2.new(0, 104, 1, -34), Position = UDim2.fromOffset(5, 31),
    BackgroundColor3 = Color3.fromRGB(19, 16, 26), BorderSizePixel = 0,
}, win)
inst("UICorner", { CornerRadius = UDim.new(0, 8) }, sidebar)

local navList = inst("Frame", {
    Size = UDim2.new(1, -10, 1, -34), Position = UDim2.fromOffset(4, 30),
    BackgroundTransparency = 1,
}, sidebar)
inst("UIListLayout", { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder }, navList)

inst("TextLabel", {
    Size = UDim2.new(1, -14, 0, 14), Position = UDim2.fromOffset(10, 6),
    BackgroundTransparency = 1, Text = "v" .. VERSION .. "  1.8 kit",
    Font = Enum.Font.Gotham, TextSize = 9, TextColor3 = DIM,
    TextXAlignment = Enum.TextXAlignment.Left,
}, sidebar)

local pages = inst("Frame", {
    Size = UDim2.new(1, -120, 1, -36), Position = UDim2.fromOffset(114, 31),
    BackgroundTransparency = 1,
}, win)

local content = inst("ScrollingFrame", {
    Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1,
    BorderSizePixel = 0, ScrollBarThickness = 2,
    CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y,
    ScrollingDirection = Enum.ScrollingDirection.Y,
}, pages)
inst("UIListLayout", { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder }, content)

local frames, buttons = {}, {}

local function select(name)
    for n, f in pairs(frames) do f.Visible = (n == name) end
    for n, b in pairs(buttons) do
        b.BackgroundColor3 = (n == name) and Color3.fromRGB(40, 28, 64)
                                              or Color3.fromRGB(21, 18, 28)
        b.TextColor3 = (n == name) and Color3.fromRGB(220, 200, 255) or DIM
    end
end

local function tab(name)
    local b = inst("TextButton", {
        Size = UDim2.new(1, 0, 0, 30), BackgroundColor3 = Color3.fromRGB(21, 18, 28),
        BorderSizePixel = 0, Text = "  " .. name, TextSize = 12,
        Font = Enum.Font.Gotham, TextColor3 = DIM, AutoButtonColor = false,
    }, navList)
    inst("UICorner", { CornerRadius = UDim.new(0, 6) }, b)
    local f = inst("Frame", {
        Size = UDim2.new(1, 0, 0, 0), BackgroundTransparency = 1,
        AutomaticSize = Enum.AutomaticSize.Y,
    }, content)
    inst("UIListLayout", { Padding = UDim.new(0, 4) }, f)
    frames[name], buttons[name] = f, b
    b.MouseButton1Click:Connect(function() select(name) end)
end

local function label(parent, text)
    inst("TextLabel", {
        Size = UDim2.new(1, -4, 0, 16), BackgroundTransparency = 1, Text = text,
        TextSize = 10, Font = Enum.Font.GothamBold, TextColor3 = ACCENT,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, parent)
end

local function toggle(parent, text, tbl, key, cb)
    local row = inst("TextButton", {
        Size = UDim2.new(1, -4, 0, 30), BackgroundColor3 = ROW,
        BorderSizePixel = 0, Text = "", AutoButtonColor = false, Active = true,
    }, parent)
    inst("UICorner", { CornerRadius = UDim.new(0, 6) }, row)
    local lbl = inst("TextLabel", {
        Size = UDim2.new(1, -60, 1, 0), Position = UDim2.fromOffset(9, 0),
        BackgroundTransparency = 1, Text = text, TextSize = 12,
        Font = Enum.Font.Gotham, TextColor3 = TXT,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, row)
    local sw = inst("Frame", {
        Size = UDim2.fromOffset(32, 16), Position = UDim2.new(1, -40, 0.5, -8),
        BackgroundColor3 = Color3.fromRGB(42, 37, 54), BorderSizePixel = 0,
    }, row)
    inst("UICorner", { CornerRadius = UDim.new(1, 0) }, sw)
    local knob = inst("Frame", {
        Size = UDim2.fromOffset(12, 12), Position = UDim2.fromOffset(2, 2),
        BackgroundColor3 = Color3.fromRGB(190, 190, 200), BorderSizePixel = 0,
    }, sw)
    inst("UICorner", { CornerRadius = UDim.new(1, 0) }, knob)

    local function refresh()
        local on = tbl[key] and true or false
        sw.BackgroundColor3 = on and ACCENT or Color3.fromRGB(42, 37, 54)
        knob.Position = UDim2.fromOffset(on and 18 or 2, 2)
        lbl.TextColor3 = on and Color3.fromRGB(235, 228, 255) or TXT
    end
    refresh()
    row.MouseButton1Click:Connect(function()
        tbl[key] = not tbl[key]
        refresh()
        if cb then pcall(cb, tbl[key]) end
    end)
    return row
end

local function slider(parent, text, tbl, key, min, max, isInt, cb)
    local row = inst("Frame", {
        Size = UDim2.new(1, -4, 0, 40), BackgroundColor3 = ROW, BorderSizePixel = 0,
    }, parent)
    inst("UICorner", { CornerRadius = UDim.new(0, 6) }, row)
    local lbl = inst("TextLabel", {
        Size = UDim2.new(1, -12, 0, 16), Position = UDim2.fromOffset(9, 3),
        BackgroundTransparency = 1, Text = text, TextSize = 11,
        Font = Enum.Font.Gotham, TextColor3 = TXT,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, row)
    local track = inst("Frame", {
        Size = UDim2.new(1, -18, 0, 6), Position = UDim2.fromOffset(9, 27),
        BackgroundColor3 = Color3.fromRGB(40, 35, 52), BorderSizePixel = 0,
    }, row)
    inst("UICorner", { CornerRadius = UDim.new(1, 0) }, track)
    local fill = inst("Frame", {
        Size = UDim2.new(0, 0, 1, 0), BackgroundColor3 = ACCENT, BorderSizePixel = 0,
    }, track)
    inst("UICorner", { CornerRadius = UDim.new(1, 0) }, fill)

    local function set(v)
        v = math.clamp(v, min, max)
        if isInt then v = math.floor(v + 0.5) end
        tbl[key] = v
        local rel = (v - min) / math.max(max - min, 1e-6)
        fill.Size = UDim2.new(rel, 0, 1, 0)
        lbl.Text = text .. "   " .. (isInt and tostring(math.floor(v)) or string.format("%.2f", v))
        if cb then pcall(cb, v) end
    end
    set(tbl[key])

    local drag = false
    local function fromX(px)
        local rel = (px - track.AbsolutePosition.X) / math.max(track.AbsoluteSize.X, 1)
        set(min + math.clamp(rel, 0, 1) * (max - min))
    end
    track.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1
            or i.UserInputType == Enum.UserInputType.Touch then
            drag = true
            fromX(i.Position.X)
        end
    end)
    UIS.InputChanged:Connect(function(i)
        if drag and (i.UserInputType == Enum.UserInputType.MouseMovement
            or i.UserInputType == Enum.UserInputType.Touch) then
            fromX(i.Position.X)
        end
    end)
    UIS.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1
            or i.UserInputType == Enum.UserInputType.Touch then drag = false end
    end)
    return row
end

local function color(parent, text, tbl, key)
    local row = inst("Frame", {
        Size = UDim2.new(1, -4, 0, 54), BackgroundColor3 = ROW, BorderSizePixel = 0,
    }, parent)
    inst("UICorner", { CornerRadius = UDim.new(0, 6) }, row)
    inst("TextLabel", {
        Size = UDim2.new(1, -60, 0, 16), Position = UDim2.fromOffset(9, 3),
        BackgroundTransparency = 1, Text = text, TextSize = 11,
        Font = Enum.Font.Gotham, TextColor3 = TXT,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, row)
    local sw = inst("Frame", {
        Size = UDim2.fromOffset(20, 12), Position = UDim2.new(1, -28, 0, 5),
        BackgroundColor3 = tbl[key], BorderSizePixel = 0,
    }, row)
    inst("UICorner", { CornerRadius = UDim.new(0, 3) }, sw)

    local comps = { tbl[key].R, tbl[key].G, tbl[key].B }
    local tracks = {}
    for i = 1, 3 do
        local t = inst("Frame", {
            Size = UDim2.new(1 / 3, -10, 0, 8),
            Position = UDim2.new((i - 1) / 3, 9, 0, 36),
            BackgroundColor3 = Color3.fromRGB(40, 35, 52), BorderSizePixel = 0,
        }, row)
        inst("UICorner", { CornerRadius = UDim.new(1, 0) }, t)
        local f = inst("Frame", {
            Size = UDim2.new(comps[i], 0, 1, 0), BorderSizePixel = 0,
            BackgroundColor3 = (i == 1 and Color3.fromRGB(225, 70, 70))
                or (i == 2 and Color3.fromRGB(70, 225, 70)) or Color3.fromRGB(80, 110, 235),
        }, t)
        inst("UICorner", { CornerRadius = UDim.new(1, 0) }, f)
        tracks[i] = { track = t, fill = f }
    end

    local function push()
        tbl[key] = Color3.fromRGB(comps[1], comps[2], comps[3])
        sw.BackgroundColor3 = tbl[key]
        for i = 1, 3 do tracks[i].fill.Size = UDim2.new(comps[i] / 255, 0, 1, 0) end
    end

    local dragI = 0
    for i = 1, 3 do
        tracks[i].track.InputBegan:Connect(function(inp)
            if inp.UserInputType == Enum.UserInputType.MouseButton1
                or inp.UserInputType == Enum.UserInputType.Touch then
                dragI = i
                local t = tracks[i].track
                local rel = (inp.Position.X - t.AbsolutePosition.X) / math.max(t.AbsoluteSize.X, 1)
                comps[i] = math.floor(math.clamp(rel, 0, 1) * 255)
                push()
            end
        end)
    end
    UIS.InputChanged:Connect(function(inp)
        if dragI == 0 then return end
        if inp.UserInputType == Enum.UserInputType.MouseMovement
            or inp.UserInputType == Enum.UserInputType.Touch then
            local t = tracks[dragI].track
            local rel = (inp.Position.X - t.AbsolutePosition.X) / math.max(t.AbsoluteSize.X, 1)
            comps[dragI] = math.floor(math.clamp(rel, 0, 1) * 255)
            push()
        end
    end)
    UIS.InputEnded:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1
            or inp.UserInputType == Enum.UserInputType.Touch then dragI = 0 end
    end)
    return row
end

local function textbox(parent, text, tbl, key, placeholder)
    local row = inst("Frame", {
        Size = UDim2.new(1, -4, 0, 46), BackgroundColor3 = ROW, BorderSizePixel = 0,
    }, parent)
    inst("UICorner", { CornerRadius = UDim.new(0, 6) }, row)
    inst("TextLabel", {
        Size = UDim2.new(1, -18, 0, 14), Position = UDim2.fromOffset(9, 3),
        BackgroundTransparency = 1, Text = text, TextSize = 11,
        Font = Enum.Font.Gotham, TextColor3 = TXT,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, row)
    local box = inst("TextBox", {
        Size = UDim2.new(1, -18, 0, 22), Position = UDim2.fromOffset(9, 19),
        BackgroundColor3 = Color3.fromRGB(32, 27, 44), BorderSizePixel = 0,
        Text = tbl[key] or "", PlaceholderText = placeholder or "", TextSize = 12,
        Font = Enum.Font.Code, TextColor3 = TXT, ClearTextOnFocus = false,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, row)
    inst("UICorner", { CornerRadius = UDim.new(0, 4) }, box)
    box.FocusLost:Connect(function()
        tbl[key] = box.Text
    end)
    return row
end

local function button(parent, text, cb)
    local b = inst("TextButton", {
        Size = UDim2.new(1, -4, 0, 30), BackgroundColor3 = Color3.fromRGB(34, 26, 54),
        BorderSizePixel = 0, Text = text, TextSize = 12,
        Font = Enum.Font.GothamBold, TextColor3 = Color3.fromRGB(220, 200, 255),
        AutoButtonColor = false, Active = true,
    }, parent)
    inst("UICorner", { CornerRadius = UDim.new(0, 6) }, b)
    b.MouseButton1Click:Connect(function() pcall(cb) end)
    return b
end

local playKillSound

--============================== tabs =================================
for _, n in ipairs({ "Combat", "Visuals", "Misc" }) do tab(n) end
local Combat, Visual, Misc = frames.Combat, frames.Visuals, frames.Misc

label(Combat, "KILLAURA")
toggle(Combat, "Killaura", CFG.ka, "on")
slider(Combat, "Range", CFG.ka, "range", 4, 40, true)
slider(Combat, "CPS", CFG.ka, "cps", 1, 24, true)
toggle(Combat, "Face target", CFG.ka, "face")
toggle(Combat, "Wall check", CFG.ka, "wall")
toggle(Combat, "Team check", CFG.ka, "team")

label(Combat, "AIM")
toggle(Combat, "Aim", CFG.aim, "on")
slider(Combat, "FOV px", CFG.aim, "fov", 30, 600, true)
slider(Combat, "Smooth", CFG.aim, "smooth", 0.05, 1, false)
local partBtn
partBtn = button(Combat, "Aim part: " .. CFG.aim.part, function()
    local list = { "Head", "HumanoidRootPart", "UpperTorso", "Torso" }
    local i = 1
    for k, v in ipairs(list) do if v == CFG.aim.part then i = k end end
    CFG.aim.part = list[i % #list + 1]
    partBtn.Text = "Aim part: " .. CFG.aim.part
end)

label(Visual, "ESP")
toggle(Visual, "ESP", CFG.esp, "on")
toggle(Visual, "Box", CFG.esp, "box")
toggle(Visual, "Name", CFG.esp, "name")
toggle(Visual, "Health", CFG.esp, "hp")
toggle(Visual, "Distance", CFG.esp, "dist")
toggle(Visual, "Team check", CFG.esp, "team")
slider(Visual, "Max distance", CFG.esp, "maxDist", 50, 1500, true)
color(Visual, "Visible", CFG.esp, "vis")
color(Visual, "Hidden", CFG.esp, "hid")

label(Visual, "INTERFACE")
toggle(Visual, "HUD", CFG.hud, "on")
toggle(Visual, "Target HUD", CFG.thud, "on")
toggle(Visual, "Keystrokes", CFG.keys, "on")
toggle(Visual, "Debug line", CFG.dbg, "on")

label(Visual, "PARTICLES")
toggle(Visual, "Aura", CFG.fx, "aura")
toggle(Visual, "Kill burst", CFG.fx, "kill")

label(Misc, "KILL SOUND")
toggle(Misc, "Kill sound", CFG.snd, "on")
slider(Misc, "Volume", CFG.snd, "vol", 0, 1, false)
textbox(Misc, "Sound id (цифры из rbxassetid://…)", CFG.snd, "id", "1234567890")
button(Misc, "Test sound", function() playKillSound() end)

select("Combat")

--============================== hud ==================================
local hudGui = inst("ScreenGui", {
    Name = "zpkit_info", ResetOnSpawn = false, IgnoreGuiInset = true,
    DisplayOrder = 1000, Parent = LocalPlayer:WaitForChild("PlayerGui"),
})

local watermark = inst("TextLabel", {
    Size = UDim2.new(0, 260, 0, 20), Position = UDim2.fromOffset(70, 12),
    BackgroundTransparency = 1, Font = Enum.Font.Code, TextSize = 12,
    TextXAlignment = Enum.TextXAlignment.Left, TextStrokeTransparency = 0.3,
    TextColor3 = Color3.fromRGB(178, 150, 255), Text = "zero.pw kit " .. VERSION,
}, hudGui)

--============================== target hud ===========================
local thud = inst("Frame", {
    Size = UDim2.fromOffset(190, 66), Position = UDim2.new(1, -210, 0.5, 60),
    BackgroundColor3 = Color3.fromRGB(16, 13, 24), BorderSizePixel = 0, Visible = false,
}, hudGui)
inst("UICorner", { CornerRadius = UDim.new(0, 8) }, thud)
inst("UIStroke", { Color = Color3.fromRGB(70, 50, 110), Thickness = 1 }, thud)

local thudName = inst("TextLabel", {
    Size = UDim2.new(1, -14, 0, 18), Position = UDim2.fromOffset(8, 5),
    BackgroundTransparency = 1, Text = "", TextSize = 13, Font = Enum.Font.GothamBold,
    TextColor3 = Color3.fromRGB(235, 228, 255), TextXAlignment = Enum.TextXAlignment.Left,
}, thud)

local thudHpBg = inst("Frame", {
    Size = UDim2.new(1, -16, 0, 8), Position = UDim2.fromOffset(8, 27),
    BackgroundColor3 = Color3.fromRGB(34, 30, 44), BorderSizePixel = 0,
}, thud)
inst("UICorner", { CornerRadius = UDim.new(1, 0) }, thudHpBg)

local thudHp = inst("Frame", {
    Size = UDim2.new(1, 0, 1, 0), BackgroundColor3 = Color3.fromRGB(90, 220, 110),
    BorderSizePixel = 0,
}, thudHpBg)
inst("UICorner", { CornerRadius = UDim.new(1, 0) }, thudHp)

local thudInfo = inst("TextLabel", {
    Size = UDim2.new(1, -16, 0, 16), Position = UDim2.fromOffset(8, 40),
    BackgroundTransparency = 1, Text = "", TextSize = 11, Font = Enum.Font.Code,
    TextColor3 = Color3.fromRGB(160, 150, 190), TextXAlignment = Enum.TextXAlignment.Left,
}, thud)

local menuOpen = true

--============================== keystrokes ===========================
local kGui = inst("ScreenGui", {
    Name = "zpkit_keys", ResetOnSpawn = false, IgnoreGuiInset = true,
    DisplayOrder = 1000, Parent = LocalPlayer:WaitForChild("PlayerGui"),
})

local kRoot = inst("Frame", {
    Size = UDim2.fromOffset(120, 92), Position = UDim2.new(0, 16, 0.55, 0),
    BackgroundTransparency = 1,
}, kGui)

local function keyBox(x, y, w, h, text)
    local b = inst("Frame", {
        Size = UDim2.fromOffset(w, h), Position = UDim2.fromOffset(x, y),
        BackgroundColor3 = Color3.fromRGB(22, 19, 30), BackgroundTransparency = 0.25,
        BorderSizePixel = 0,
    }, kRoot)
    inst("UICorner", { CornerRadius = UDim.new(0, 6) }, b)
    local st = inst("UIStroke", { Color = Color3.fromRGB(80, 62, 120), Thickness = 1 }, b)
    local t = inst("TextLabel", {
        Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = text,
        Font = Enum.Font.GothamBold, TextSize = 11,
        TextColor3 = Color3.fromRGB(180, 170, 210),
    }, b)
    return b, t, st
end

local kW, kWt, kWs = keyBox(30, 0, 26, 26, "W")
local kA, kAt, kAs = keyBox(0, 30, 26, 26, "A")
local kS, kSt, kSs = keyBox(30, 30, 26, 26, "S")
local kD, kDt, kDs = keyBox(60, 30, 26, 26, "D")
local kL, kLt, kLs = keyBox(0, 60, 40, 26, "LMB")
local kJ, kJt, kJs = keyBox(46, 60, 40, 26, "SPC")

local function keyOn(box, lbl, stroke, on)
    box.BackgroundColor3 = on and Color3.fromRGB(52, 38, 84) or Color3.fromRGB(22, 19, 30)
    box.BackgroundTransparency = on and 0 or 0.25
    lbl.TextColor3 = on and Color3.fromRGB(235, 225, 255) or Color3.fromRGB(150, 140, 180)
    stroke.Color = on and ACCENT or Color3.fromRGB(80, 62, 120)
end

--============================== fx ===================================
local function makeParticles(parentPart, amount, life, speed, size, color, texture)
    local att = Instance.new("Attachment")
    att.Parent = parentPart
    local pe = Instance.new("ParticleEmitter")
    pe.Texture = texture or "rbxasset://textures/particles/sparkles_main.dds"
    pe.Rate = 0
    pe.Lifetime = NumberRange.new(life * 0.7, life)
    pe.Speed = NumberRange.new(speed * 0.4, speed)
    pe.SpreadAngle = Vector2.new(180, 180)
    pe.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, size),
                                  NumberSequenceKeypoint.new(1, 0) })
    pe.Color = ColorSequence.new(color or ACCENT)
    pe.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.15),
                                           NumberSequenceKeypoint.new(1, 1) })
    pe.LightEmission = 1
    pe.Parent = att
    pe:Emit(amount)
    Debris:AddItem(att, life + 0.4)
    return pe
end

local auraAtt, auraPe
local function applyAura()
    local ch = LocalPlayer.Character
    local hrp = ch and ch:FindFirstChild("HumanoidRootPart")
    if not CFG.fx.aura or not hrp then
        if auraAtt then auraAtt:Destroy() auraAtt, auraPe = nil, nil end
        return
    end
    if auraAtt and auraAtt.Parent == hrp then
        auraPe.Rate = 14
        return
    end
    if auraAtt then auraAtt:Destroy() end
    auraAtt = Instance.new("Attachment")
    auraAtt.Parent = hrp
    auraPe = Instance.new("ParticleEmitter")
    auraPe.Texture = "rbxasset://textures/particles/sparkles_main.dds"
    auraPe.Rate = 14
    auraPe.Lifetime = NumberRange.new(0.35, 0.7)
    auraPe.Speed = NumberRange.new(0.8, 2.2)
    auraPe.SpreadAngle = Vector2.new(180, 180)
    auraPe.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.35),
                                       NumberSequenceKeypoint.new(1, 0) })
    auraPe.Color = ColorSequence.new(ACCENT)
    auraPe.LightEmission = 1
    auraPe.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.2),
                                               NumberSequenceKeypoint.new(1, 1) })
    auraPe.Parent = auraAtt
end

--============================== kill sound ===========================
local killSound
function playKillSound()
    local id = tostring(CFG.snd.id or ""):gsub("%D", "")
    if id == "" then return end
    if not killSound then
        killSound = Instance.new("Sound")
        killSound.Name = "zp_killsnd"
        killSound.Parent = LocalPlayer:WaitForChild("PlayerGui")
    end
    killSound.SoundId = "rbxassetid://" .. id
    killSound.Volume = CFG.snd.vol
    pcall(function() killSound:Play() end)
end

local function killFxAt(pos, color)
    if not CFG.fx.kill then return end
    local p = Instance.new("Part")
    p.Anchored = true
    p.CanCollide = false
    p.CanQuery = false
    p.CastShadow = false
    p.Transparency = 1
    p.Size = Vector3.new(1, 1, 1)
    p.CFrame = CFrame.new(pos)
    p.Parent = WS
    makeParticles(p, 26, 0.55, 16, 0.6, color or Color3.fromRGB(180, 120, 255))
    Debris:AddItem(p, 1)
end

--============================== kill tracking ========================
local lastHit, swingCount = {}, 0

local function watchCharacter(plr)
    if plr == LocalPlayer then return end
    local ch = plr.Character
    if not ch then return end
    local hum = ch:FindFirstChildOfClass("Humanoid")
    if not hum then return end
    hum.Died:Connect(function()
        local t = lastHit[plr]
        if t and os.clock() - t < 5 then
            lastHit[plr] = nil
            local hrp = ch:FindFirstChild("HumanoidRootPart")
            killFxAt((hrp and hrp.Position) or Vector3.zero)
            if CFG.snd.on then playKillSound() end
        end
    end)
end

local function watchPlayer(plr)
    if plr == LocalPlayer then return end
    plr.CharacterAdded:Connect(function()
        task.wait(0.4)
        watchCharacter(plr)
    end)
    watchCharacter(plr)
end

for _, plr in ipairs(Players:GetPlayers()) do watchPlayer(plr) end
Players.PlayerAdded:Connect(watchPlayer)
Players.PlayerRemoving:Connect(function(plr) lastHit[plr] = nil end)

--============================== combat loop ==========================
local cam = WS.CurrentCamera
local function refreshCam()
    cam = WS.CurrentCamera or cam
end

local lastSwing, curTarget, curTim, headshotCheck = 0, nil, nil, nil

local function doKillaura()
    if not CFG.ka.on then return end
    local now = os.clock()
    if now - lastSwing < 1 / math.max(CFG.ka.cps, 1) then return end
    local plr, part = nearestInRange(CFG.ka.range, CFG.ka.wall)
    if not plr then return end
    lastSwing = now
    swingCount = swingCount + 1
    lastHit[plr] = now
    local tool = equippedTool()
    if CFG.ka.face and cam then
        pcall(function()
            cam.CFrame = CFrame.lookAt(cam.CFrame.Position, part.Position)
        end)
    end
    if tool then
        pcall(function() tool:Activate() end)
    end
    curTarget = plr
end

local function doAim(dt)
    if not CFG.aim.on then return end
    local plr, part = findTarget(CFG.aim.fov)
    if not plr or not part or not cam then return end
    local goal = CFrame.lookAt(cam.CFrame.Position, part.Position)
    local a = math.clamp(CFG.aim.smooth * dt * 60, 0, 1)
    cam.CFrame = cam.CFrame:Lerp(goal, a)
end

--============================== loops ================================
RunService:BindToRenderStep("zp_kit_cam", Enum.RenderPriority.Camera.Value + 1, function(dt)
    refreshCam()
    local ok, err = pcall(doAim, dt)
    if not ok then lastErr = "aim: " .. tostring(err) end
end)

RunService.RenderStepped:Connect(function()
    refreshCam()
    local ok, err = pcall(drawEsp)
    if not ok then
        lastErr = "esp: " .. tostring(err)
        if not CFG.debugWarned then
            CFG.debugWarned = true
            warn("[zero.pw kit] esp: " .. tostring(err))
        end
    end

    -- target hud
    local tgt = nil
    if CFG.thud.on then
        local p = curTarget
        if not p or not alive(p) then
            p = nearestInRange(CFG.ka.range + 30, false)
        end
        tgt = p
    end
    if tgt and alive(tgt) then
        local ch = tgt.Character
        local head = ch and ch:FindFirstChild("Head")
        local hum = ch and ch:FindFirstChildOfClass("Humanoid")
        if head and hum then
            thud.Visible = true
            thudName.Text = tgt.Name
            local frac = math.clamp(hum.Health / math.max(hum.MaxHealth, 1), 0, 1)
            thudHp.Size = UDim2.new(frac, 0, 1, 0)
            thudHp.BackgroundColor3 = Color3.fromRGB(
                math.floor(255 * (1 - frac)), math.floor(220 * frac), 70)
            local d = (cam and (cam.CFrame.Position - head.Position).Magnitude) or 0
            thudInfo.Text = string.format("%d hp   %d m", math.floor(hum.Health), math.floor(d))
        end
    else
        thud.Visible = false
    end

    -- keystrokes
    if CFG.keys.on then
        kRoot.Visible = true
        local ch = LocalPlayer.Character
        local hum = ch and ch:FindFirstChildOfClass("Humanoid")
        local md = hum and hum.MoveDirection or Vector3.zero
        local lx, lz = 0, 0
        if cam then
            local v = cam.CFrame:VectorToObjectSpace(md)
            lx, lz = v.X, v.Z
        end
        keyOn(kW, kWt, kWs, lz < -0.25)
        keyOn(kS, kSt, kSs, lz > 0.25)
        keyOn(kA, kAt, kAs, lx < -0.25)
        keyOn(kD, kDt, kDs, lx > 0.25)
        keyOn(kJ, kJt, kJs, hum and hum:GetState() == Enum.HumanoidStateType.Jumping or false)
        keyOn(kL, kLt, kLs, os.clock() - lastSwing < 0.12
            or UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton1))
    else
        kRoot.Visible = false
    end

    applyAura()
end)

RunService.Heartbeat:Connect(function(dt)
    local ok, err = pcall(doKillaura)
    if not ok then lastErr = "ka: " .. tostring(err) end
end)

--============================== info loop ============================
local frames_, fps = 0, 0
RunService.RenderStepped:Connect(function() frames_ = frames_ + 1 end)

task.spawn(function()
    while true do
        task.wait(1)
        fps = frames_
        frames_ = 0
        local ping = 0
        pcall(function() ping = math.floor(LocalPlayer:GetNetworkPing() * 1000) end)
        watermark.Text = string.format("zero.pw kit v%s | %d fps | %d ms | %d pl",
            VERSION, fps, ping, #Players:GetPlayers())
        watermark.Visible = CFG.hud.on
    end
end)

task.spawn(function()
    while true do
        task.wait(0.4)
        if CFG.dbg.on and lastErr then
            watermark.Text = watermark.Text .. " | " .. lastErr
            lastErr = nil
        end
    end
end)

--============================== window drag ==========================
local dragging, dragStart, startPos
header.InputBegan:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1
        or i.UserInputType == Enum.UserInputType.Touch then
        dragging, dragStart, startPos = true, i.Position, win.Position
    end
end)
UIS.InputChanged:Connect(function(i)
    if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement
        or i.UserInputType == Enum.UserInputType.Touch) then
        local d = i.Position - dragStart
        win.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X,
                                 startPos.Y.Scale, startPos.Y.Offset + d.Y)
    end
end)
UIS.InputEnded:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1
        or i.UserInputType == Enum.UserInputType.Touch then dragging = false end
end)

-- target hud таскается ТОЛЬКО при открытом меню
local thDrag, thStart, thPos
thud.InputBegan:Connect(function(i)
    if not menuOpen then return end
    if i.UserInputType == Enum.UserInputType.MouseButton1
        or i.UserInputType == Enum.UserInputType.Touch then
        thDrag, thStart, thPos = true, i.Position, thud.Position
    end
end)
UIS.InputChanged:Connect(function(i)
    if thDrag and (i.UserInputType == Enum.UserInputType.MouseMovement
        or i.UserInputType == Enum.UserInputType.Touch) then
        local d = i.Position - thStart
        thud.Position = UDim2.new(thPos.X.Scale, thPos.X.Offset + d.X,
                                  thPos.Y.Scale, thPos.Y.Offset + d.Y)
    end
end)
UIS.InputEnded:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1
        or i.UserInputType == Enum.UserInputType.Touch then thDrag = false end
end)

--============================== fab / menu ===========================
local function setMenu(v)
    menuOpen = v
    win.Visible = v
    thud.Active = v
end

closeBtn.MouseButton1Click:Connect(function() setMenu(false) end)

local fabDrag, fabStart, fabPos
fab.InputBegan:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1
        or i.UserInputType == Enum.UserInputType.Touch then
        fabDrag, fabStart, fabPos = true, i.Position, fab.Position
    end
end)
fab.InputEnded:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1
        or i.UserInputType == Enum.UserInputType.Touch then
        local moved = fabStart and (i.Position - fabStart).Magnitude or 0
        fabDrag = false
        if moved < 12 then setMenu(not menuOpen) end
    end
end)
UIS.InputChanged:Connect(function(i)
    if fabDrag and (i.UserInputType == Enum.UserInputType.MouseMovement
        or i.UserInputType == Enum.UserInputType.Touch) then
        local d = i.Position - fabStart
        fab.Position = UDim2.new(fabPos.X.Scale, fabPos.X.Offset + d.X,
                                 fabPos.Y.Scale, fabPos.Y.Offset + d.Y)
    end
end)

UIS.InputBegan:Connect(function(input, processed)
    if processed then return end
    if input.KeyCode == Enum.KeyCode.RightShift then
        setMenu(not menuOpen)
    end
end)

--============================== boot =================================
setMenu(true)
log("loaded v" .. VERSION .. " / 1.8 kit pvp")
