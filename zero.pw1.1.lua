--[[
    zero.pw v2  |  1.8 kit pvp  |  delta (mobile)
    one round "z" button opens/closes the menu. everything combat/move is OFF on launch.

    killaura pipeline (first that works wins):
      1) learned hit remote  - auto-learns the first remote that carries a nearby player/model,
                               just swing at your friend once. Config > Learn Attack re-learns.
      2) Tool:Activate() + firetouchinterest(handle, target)  - for touch-based swords
    Config tab shows which one is used and why aura did nothing ("aura:" line).
    mace / totem / pearl look for Tools by name substring (CFG.*.name).
]]

-- ===== config ============================================================
local CFG = {
    killaura = { on = false, range = 9, cps = 14, multi = 1, face = true, players = true, team = false },
    aim      = { on = false, fov = 180, smooth = 0.35, range = 70, predict = 0.08, head = true,
                 players = true, team = false, showFov = true, sticky = true },
    mace     = { on = false, name = "mace", engage = 16, reach = 7, minFall = 2.5, cd = 1.2 },
    totem    = { on = false, name = "totem", hp = 45 },
    pearl    = { on = false, name = "pearl", hp = 30, enemy = 14, cd = 4 },
    speed    = { on = false, speed = 28, cframe = true },
    fly      = { on = false, speed = 40 },
    bhop     = { on = false },
    antikb   = { on = false, reduce = 0.7 },
    esp      = { on = false, range = 160, max = 40, players = true },
    chams    = { on = false, fill = 0.5, range = 300 },
    fullbright = { on = false },
    hud      = { on = true, stats = true },
    target   = { on = true },
}
local kFile = "zero.pw.v2.json"

-- ===== services ==========================================================
local Players      = game:GetService("Players")
local RunService   = game:GetService("RunService")
local UIS          = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local HttpService  = game:GetService("HttpService")
local Stats        = game:GetService("Stats")
local Lighting     = game:GetService("Lighting")
local Workspace    = game:GetService("Workspace")

local LP     = Players.LocalPlayer
local Camera = Workspace.CurrentCamera
local genv   = (getgenv and getgenv()) or _G

if genv.ZeroPW then pcall(genv.ZeroPW.Destroy) end

local C = {
    bg      = Color3.fromRGB(14, 14, 20),
    panel   = Color3.fromRGB(22, 22, 32),
    item    = Color3.fromRGB(32, 32, 46),
    accent  = Color3.fromRGB(138, 99, 255),
    accent2 = Color3.fromRGB(80, 200, 255),
    text    = Color3.fromRGB(236, 236, 246),
    dim     = Color3.fromRGB(140, 140, 162),
    good    = Color3.fromRGB(90, 220, 140),
    bad     = Color3.fromRGB(255, 90, 110),
}

local state = {
    lock = 0, pearlT = 0, lastHit = 0, lastMace = 0, peakY = 0,
    target = nil, aimTarget = nil, aimLock = nil, preTotem = nil, err = nil, fps = 60,
    kills = 0, deaths = 0, streak = 0, wasDead = false, t0 = os.clock(),
    prevVel = nil, baseWS = nil, auraInfo = "off",
}

local conns = {}
local function bind(sig, fn)
    local c = sig:Connect(fn)
    conns[#conns + 1] = c
    return c
end

local function safe(f, ...)
    local ok, e = pcall(f, ...)
    if not ok and e ~= state.err then
        state.err = e
        warn("[zero.pw] " .. tostring(e))
    end
end

local function new(class, props, parent)
    local o = Instance.new(class)
    for k, v in pairs(props or {}) do o[k] = v end
    if parent then o.Parent = parent end
    return o
end
local function corner(o, r) return new("UICorner", { CornerRadius = UDim.new(0, r) }, o) end
local function stroke(o, col, th, tr)
    return new("UIStroke", { Color = col, Thickness = th or 1, Transparency = tr or 0,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, o)
end

-- ===== entities ==========================================================
local hums = {}
local function track(d) if d:IsA("Humanoid") then hums[d] = true end end
for _, d in ipairs(Workspace:GetDescendants()) do track(d) end
bind(Workspace.DescendantAdded, track)
bind(Workspace.DescendantRemoving, function(d) if hums[d] then hums[d] = nil end end)

local function myHum() local c = LP.Character; return c and c:FindFirstChildOfClass("Humanoid") end
local function myRoot() local c = LP.Character; return c and c:FindFirstChild("HumanoidRootPart") end

local function targets(range, allowPlayers, teamCheck)
    local r = myRoot()
    local out = {}
    if not r then return out end
    for hum in pairs(hums) do
        local m = hum.Parent
        if m and m ~= LP.Character and hum.Health > 0 then
            local root = m:FindFirstChild("HumanoidRootPart") or m.PrimaryPart
            if root then
                local pl = Players:GetPlayerFromCharacter(m)
                local skip = false
                if pl and teamCheck then
                    skip = pl.Team ~= nil and pl.Team == LP.Team
                end
                if (allowPlayers or not pl) and not skip then
                    local d = (root.Position - r.Position).Magnitude
                    if d <= range then
                        out[#out + 1] = { hum = hum, model = m, root = root, dist = d, plr = pl ~= nil }
                    end
                end
            end
        end
    end
    table.sort(out, function(a, b) return a.dist < b.dist end)
    return out
end

-- ===== tools =============================================================
local function findTool(pat)
    pat = pat:lower()
    local bp = LP:FindFirstChildOfClass("Backpack")
    for _, holder in ipairs({ LP.Character, bp }) do
        if holder then
            for _, t in ipairs(holder:GetChildren()) do
                if t:IsA("Tool") and t.Name:lower():find(pat, 1, true) then return t end
            end
        end
    end
    return nil
end
local function heldTool() local c = LP.Character; return c and c:FindFirstChildOfClass("Tool") end
local function equip(tool)
    local h = myHum()
    if h and tool and tool.Parent ~= LP.Character then h:EquipTool(tool) end
end
local function anyTool()
    local bp = LP:FindFirstChildOfClass("Backpack")
    if bp then
        for _, t in ipairs(bp:GetChildren()) do
            if t:IsA("Tool") then return t end
        end
    end
    return nil
end

-- ===== attack learner (hit remote) =======================================
local Learn = { armed = false, stop = 0, remote = nil, args = nil, idx = nil, status = "waiting: swing at someone",
                log = {}, dead = false }

local function modelOf(inst)
    local cur = inst
    while cur and cur ~= Workspace do
        if cur:IsA("Model") and cur:FindFirstChildOfClass("Humanoid") then return cur end
        cur = cur.Parent
    end
    return nil
end

local function onRemote(remote, args)
    if Learn.dead then return end
    local d = {}
    for i = 1, args.n do d[i] = typeof(args[i]) end
    Learn.log[#Learn.log + 1] = remote.Name .. "(" .. table.concat(d, ",") .. ")"
    if #Learn.log > 6 then table.remove(Learn.log, 1) end
    local mr = myRoot()
    if not mr then return end
    for i = 1, args.n do
        local a = args[i]
        if typeof(a) == "Instance" then
            local m
            if a:IsA("Player") then m = a.Character else m = modelOf(a) end
            if m and m ~= LP.Character then
                local rr = m:FindFirstChild("HumanoidRootPart")
                if rr and (rr.Position - mr.Position).Magnitude < 45 then
                    local how = Learn.armed and "" or "auto-"
                    Learn.remote, Learn.args, Learn.idx = remote, args, i
                    Learn.armed = false
                    Learn.status = how .. "learned " .. remote.Name .. " (arg " .. i .. ")"
                    return
                end
            end
        end
    end
end

local okHook = pcall(function()
    local wrap = newcclosure or function(f) return f end
    local old
    old = hookmetamethod(game, "__namecall", wrap(function(self, ...)
        if (Learn.armed or not Learn.remote) and not Learn.dead then
            local m = getnamecallmethod()
            if (m == "FireServer" or m == "InvokeServer") and not (checkcaller and checkcaller()) then
                task.defer(onRemote, self, table.pack(...))
            end
        end
        return old(self, ...)
    end))
end)
if not okHook then Learn.status = "no hook support: touch/Activate only" end

local function fireLearned(tgt, root)
    local L = Learn
    if not L.remote or not L.args then return false end
    local a = table.clone(L.args)
    local old = a[L.idx]
    local new_ = tgt.model
    if typeof(old) == "Instance" then
        if old:IsA("Humanoid") then
            new_ = tgt.hum
        elseif old:IsA("BasePart") then
            new_ = tgt.model:FindFirstChild(old.Name) or tgt.root
        elseif old:IsA("Player") then
            new_ = Players:GetPlayerFromCharacter(tgt.model)
            if not new_ then return false end
        end
    end
    a[L.idx] = new_
    for i = 1, a.n do
        local v = a[i]
        if i ~= L.idx then
            if typeof(v) == "Vector3" then
                if math.abs(v.Magnitude - 1) < 0.05 then
                    a[i] = (tgt.root.Position - root.Position).Unit
                else
                    a[i] = tgt.root.Position
                end
            elseif typeof(v) == "CFrame" then
                a[i] = CFrame.lookAt(root.Position, tgt.root.Position)
            end
        end
    end
    local r = L.remote
    local ok = pcall(function()
        if r:IsA("RemoteFunction") then
            task.spawn(r.InvokeServer, r, table.unpack(a, 1, a.n))
        else
            r:FireServer(table.unpack(a, 1, a.n))
        end
    end)
    return ok
end

local function hitTarget(tgt, root)
    if fireLearned(tgt, root) then return "remote" end
    local tool = heldTool()
    if not tool then
        tool = anyTool()
        if tool then equip(tool) end
        return "equipping"
    end
    tool:Activate()
    local handle = tool:FindFirstChild("Handle")
    if handle and firetouchinterest then
        local part = tgt.model:FindFirstChild("HumanoidRootPart") or tgt.root
        pcall(function()
            firetouchinterest(handle, part, 0)
            firetouchinterest(handle, part, 1)
        end)
        return "activate+touch"
    end
    return "activate"
end

-- ===== combat modules ====================================================
local function auraStep(now, root)
    local K = CFG.killaura
    local list = targets(K.range, K.players, K.team)
    local t = list[1]
    if not t then
        state.auraInfo = "no target within " .. K.range .. " (players=" .. tostring(K.players) .. ")"
        return
    end
    state.target = t
    if K.face then
        local p = t.root.Position
        root.CFrame = CFrame.lookAt(root.Position, Vector3.new(p.X, root.Position.Y, p.Z))
    end
    if now < state.lock then
        state.auraInfo = "paused (totem/pearl swap)"
        return
    end
    if now - state.lastHit < 1 / K.cps then return end
    state.lastHit = now
    local how = "?"
    for i = 1, math.min(K.multi, #list) do
        how = hitTarget(list[i], root)
    end
    state.auraInfo = t.model.Name .. " " .. math.floor(t.dist) .. "m via " .. how
end

local function maceStep(now, hum, root)
    local M = CFG.mace
    local air = hum.FloorMaterial == Enum.Material.Air
    if air then
        state.peakY = math.max(state.peakY, root.Position.Y)
    else
        state.peakY = root.Position.Y
    end
    if now < state.lock then return end
    local t = targets(M.engage, true, false)[1]
    if not t then return end
    local tool = findTool(M.name)
    if not tool then return end
    if heldTool() ~= tool then
        equip(tool)
        return
    end
    state.target = state.target or t
    local d = t.root.Position - root.Position
    local horiz = Vector3.new(d.X, 0, d.Z).Magnitude
    if not air then
        if horiz > M.reach * 0.8 then
            hum:MoveTo(t.root.Position)
        elseif now - state.lastMace > M.cd then
            hum.Jump = true
            state.lastMace = now
        end
        return
    end
    local fall = state.peakY - root.Position.Y
    if root.AssemblyLinearVelocity.Y < -2 and fall >= M.minFall and horiz <= M.reach and d.Y <= 1 then
        state.lastMace = now
        state.peakY = root.Position.Y
        hitTarget(t, root)
    end
end

local function totemStep(now, hum)
    local T = CFG.totem
    local pct = hum.Health / math.max(hum.MaxHealth, 1) * 100
    local tool = findTool(T.name)
    if pct <= T.hp and tool then
        state.lock = now + 0.6
        if state.preTotem == nil then
            local h = heldTool()
            state.preTotem = (h ~= tool and h) or false
        end
        if heldTool() ~= tool then equip(tool) end
    elseif state.preTotem ~= nil then
        local p = state.preTotem
        state.preTotem = nil
        if p and p.Parent then equip(p) end
    end
end

local function pearlStep(now, hum, root)
    local P = CFG.pearl
    if now - state.pearlT < P.cd then return end
    local pct = hum.Health / math.max(hum.MaxHealth, 1) * 100
    if pct > P.hp then return end
    local t = targets(P.enemy, true, false)[1]
    if not t then return end
    local tool = findTool(P.name)
    if not tool then return end
    state.pearlT = now
    state.lock = now + 0.9
    local prev = heldTool()
    task.spawn(function()
        equip(tool)
        task.wait(0.12)
        local away = (root.Position - t.root.Position) * Vector3.new(1, 0, 1)
        if away.Magnitude < 0.1 then away = root.CFrame.LookVector end
        local look = (away.Unit + Vector3.new(0, 0.35, 0)).Unit
        local cam = Workspace.CurrentCamera
        local oldCF = cam.CFrame
        root.CFrame = CFrame.lookAt(root.Position, root.Position + Vector3.new(look.X, 0, look.Z))
        RunService.RenderStepped:Wait()
        cam.CFrame = CFrame.lookAt(cam.CFrame.Position, cam.CFrame.Position + look)
        tool:Activate()
        task.wait(0.1)
        cam.CFrame = oldCF
        if prev and prev ~= tool and prev.Parent then equip(prev) end
    end)
end

-- ===== movement modules ==================================================
local function moveStep(dt, hum, root)
    local S, F = CFG.speed, CFG.fly
    local dir = hum.MoveDirection

    if F.on then
        local cam = Workspace.CurrentCamera
        local lv = cam.CFrame.LookVector
        local rv = cam.CFrame.RightVector
        local ff = Vector3.new(lv.X, 0, lv.Z)
        local fr = Vector3.new(rv.X, 0, rv.Z)
        local f, r = 0, 0
        local rUnit = Vector3.new()
        if ff.Magnitude > 0.01 then f = dir:Dot(ff.Unit) end
        if fr.Magnitude > 0.01 then
            rUnit = fr.Unit
            r = dir:Dot(rUnit)
        end
        root.AssemblyLinearVelocity = (lv * f + rUnit * r) * F.speed
        hum:ChangeState(Enum.HumanoidStateType.Freefall)
        state.prevVel = root.AssemblyLinearVelocity
        return
    end

    if S.on and not S.cframe then
        state.baseWS = state.baseWS or hum.WalkSpeed
        hum.WalkSpeed = S.speed
    elseif state.baseWS then
        hum.WalkSpeed = state.baseWS
        state.baseWS = nil
    end
    if S.on and S.cframe and dir.Magnitude > 0 then
        local extra = math.max(S.speed - hum.WalkSpeed, 0)
        root.CFrame = root.CFrame + dir.Unit * extra * dt
    end

    if CFG.bhop.on and dir.Magnitude > 0 and hum.FloorMaterial ~= Enum.Material.Air then
        hum.Jump = true
    end

    local v = root.AssemblyLinearVelocity
    local pv = state.prevVel or v
    if CFG.antikb.on then
        local dx, dz = v.X - pv.X, v.Z - pv.Z
        if math.sqrt(dx * dx + dz * dz) > 18 then
            local k = 1 - CFG.antikb.reduce
            root.AssemblyLinearVelocity = Vector3.new(pv.X + dx * k, v.Y, pv.Z + dz * k)
        end
    end
    state.prevVel = root.AssemblyLinearVelocity
end

local fbOrig
local function fbStep()
    if CFG.fullbright.on then
        if not fbOrig then
            fbOrig = { Brightness = Lighting.Brightness, ClockTime = Lighting.ClockTime, FogEnd = Lighting.FogEnd,
                       GlobalShadows = Lighting.GlobalShadows, Ambient = Lighting.Ambient,
                       OutdoorAmbient = Lighting.OutdoorAmbient }
        end
        Lighting.Brightness = 2
        Lighting.ClockTime = 14
        Lighting.FogEnd = 1e6
        Lighting.GlobalShadows = false
        Lighting.Ambient = Color3.new(1, 1, 1)
        Lighting.OutdoorAmbient = Color3.new(1, 1, 1)
    elseif fbOrig then
        for k, v in pairs(fbOrig) do Lighting[k] = v end
        fbOrig = nil
    end
end

-- ===== ui root ===========================================================
local function parentGui()
    local ok, p = pcall(function() return (gethui and gethui()) or game:GetService("CoreGui") end)
    if ok and p then return p end
    return LP:WaitForChild("PlayerGui")
end

local gui = new("ScreenGui", { Name = HttpService:GenerateGUID(false):sub(1, 8), ResetOnSpawn = false,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling, DisplayOrder = 999 })
gui.Parent = parentGui()
local espFolder = new("Folder", { Name = "e" })
espFolder.Parent = gui.Parent

-- fov circle lives in its own full-viewport gui so it matches WorldToViewportPoint
local fovGui = new("ScreenGui", { Name = HttpService:GenerateGUID(false):sub(1, 8), ResetOnSpawn = false,
    IgnoreGuiInset = true, ZIndexBehavior = Enum.ZIndexBehavior.Sibling, DisplayOrder = 998 })
fovGui.Parent = gui.Parent
local fovCircle = new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
    Size = UDim2.fromOffset(360, 360), BackgroundTransparency = 1, Visible = false }, fovGui)
new("UICorner", { CornerRadius = UDim.new(0.5, 0) }, fovCircle)
local fovStroke = stroke(fovCircle, C.accent2, 1.5, 0.15)

local refreshers, updaters = {}, {}

local function draggable(handle, target, onTap)
    local dragging, moved, start, startPos = false, false, nil, nil
    bind(handle.InputBegan, function(i)
        if i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging, moved = true, false
            start, startPos = i.Position, target.Position
            local c
            c = i.Changed:Connect(function()
                if i.UserInputState == Enum.UserInputState.End then
                    dragging = false
                    c:Disconnect()
                    if not moved and onTap then onTap() end
                end
            end)
        end
    end)
    bind(UIS.InputChanged, function(i)
        if dragging and (i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseMovement) then
            local d = i.Position - start
            if d.Magnitude > 8 then moved = true end
            if moved then
                target.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X,
                                            startPos.Y.Scale, startPos.Y.Offset + d.Y)
            end
        end
    end)
end

local function switch(parent, tbl, key)
    local sw = new("TextButton", { Text = "", AutoButtonColor = false, AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, 0, 0.5, 0), Size = UDim2.fromOffset(42, 22), BackgroundColor3 = C.panel,
        BorderSizePixel = 0 }, parent)
    corner(sw, 11)
    local knob = new("Frame", { Size = UDim2.fromOffset(16, 16), Position = UDim2.fromOffset(3, 3),
        BackgroundColor3 = C.dim, BorderSizePixel = 0 }, sw)
    corner(knob, 8)
    local function paint()
        local on = tbl[key]
        TweenService:Create(sw, TweenInfo.new(0.15), { BackgroundColor3 = on and C.accent or C.panel }):Play()
        TweenService:Create(knob, TweenInfo.new(0.15),
            { Position = UDim2.fromOffset(on and 23 or 3, 3), BackgroundColor3 = on and C.text or C.dim }):Play()
    end
    paint()
    refreshers[#refreshers + 1] = paint
    bind(sw.Activated, function() tbl[key] = not tbl[key]; paint() end)
    return sw
end

local function toggleRow(parent, tbl, key, label)
    local row = new("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 26) }, parent)
    new("TextLabel", { BackgroundTransparency = 1, Size = UDim2.new(1, -52, 1, 0), Text = label, TextColor3 = C.dim,
        Font = Enum.Font.GothamMedium, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left }, row)
    switch(row, tbl, key)
end

local function slider(parent, scroll, tbl, key, label, mn, mx, step)
    local row = new("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 36) }, parent)
    new("TextLabel", { BackgroundTransparency = 1, Size = UDim2.new(0.6, 0, 0, 14), Text = label, TextColor3 = C.dim,
        Font = Enum.Font.GothamMedium, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left }, row)
    local val = new("TextLabel", { BackgroundTransparency = 1, AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.new(1, 0, 0, 0), Size = UDim2.new(0.4, 0, 0, 14), TextColor3 = C.text,
        Font = Enum.Font.GothamBold, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Right, Text = "" }, row)
    local bar = new("Frame", { BackgroundColor3 = C.panel, BorderSizePixel = 0, Position = UDim2.new(0, 0, 0, 24),
        Size = UDim2.new(1, 0, 0, 6) }, row)
    corner(bar, 3)
    local fill = new("Frame", { BackgroundColor3 = C.accent, BorderSizePixel = 0, Size = UDim2.fromScale(0, 1) }, bar)
    corner(fill, 3)
    new("UIGradient", { Color = ColorSequence.new(C.accent, C.accent2) }, fill)
    local function paint()
        fill.Size = UDim2.fromScale(math.clamp((tbl[key] - mn) / (mx - mn), 0, 1), 1)
        val.Text = string.format("%g", tbl[key])
    end
    paint()
    refreshers[#refreshers + 1] = paint
    local hit = new("TextButton", { BackgroundTransparency = 1, Text = "", Size = UDim2.new(1, 0, 1, 0) }, row)
    local dragging = false
    local function setX(x)
        local a = math.clamp((x - bar.AbsolutePosition.X) / math.max(bar.AbsoluteSize.X, 1), 0, 1)
        tbl[key] = math.floor((mn + (mx - mn) * a) / step + 0.5) * step
        paint()
    end
    bind(hit.InputBegan, function(i)
        if i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            scroll.ScrollingEnabled = false
            setX(i.Position.X)
        end
    end)
    bind(UIS.InputChanged, function(i)
        if dragging and (i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseMovement) then
            setX(i.Position.X)
        end
    end)
    bind(UIS.InputEnded, function(i)
        if dragging and (i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseButton1) then
            dragging = false
            scroll.ScrollingEnabled = true
        end
    end)
end

local function card(page, title, mod, rows)
    local t = CFG[mod]
    local c = new("Frame", { BackgroundColor3 = C.item, BorderSizePixel = 0, Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y }, page)
    corner(c, 8)
    new("UIListLayout", { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder }, c)
    new("UIPadding", { PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10), PaddingTop = UDim.new(0, 6),
        PaddingBottom = UDim.new(0, 6) }, c)
    local head = new("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 28), LayoutOrder = 0 }, c)
    local hasRows = rows and #rows > 0
    local nameBtn = new("TextButton", { BackgroundTransparency = 1, Size = UDim2.new(1, -52, 1, 0),
        Text = title .. (hasRows and "  \226\150\190" or ""), TextColor3 = C.text, Font = Enum.Font.GothamBold,
        TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left }, head)
    switch(head, t, "on")
    local body = new("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y, Visible = false, LayoutOrder = 1 }, c)
    new("UIListLayout", { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder }, body)
    for _, r in ipairs(rows or {}) do
        if r[1] == "slider" then
            slider(body, page, t, r[2], r[3], r[4], r[5], r[6])
        else
            toggleRow(body, t, r[2], r[3])
        end
    end
    bind(nameBtn.Activated, function() if hasRows then body.Visible = not body.Visible end end)
end

local function button(parent, text, fn)
    local b = new("TextButton", { Text = text, Font = Enum.Font.GothamBold, TextSize = 13, TextColor3 = C.text,
        BackgroundColor3 = C.item, BorderSizePixel = 0, Size = UDim2.new(1, 0, 0, 32) }, parent)
    corner(b, 8)
    stroke(b, C.accent, 1, 0.6)
    bind(b.Activated, fn)
    return b
end

-- ===== main panel ========================================================
local vp = Camera.ViewportSize
local W, H = math.min(430, vp.X - 24), math.min(310, vp.Y - 24)

local panel = new("Frame", { Name = "p", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
    Size = UDim2.fromOffset(W, H), BackgroundColor3 = C.bg, BorderSizePixel = 0, Visible = false, Active = true }, gui)
corner(panel, 12)
local pStroke = stroke(panel, C.accent, 1.4, 0.2)
new("UIGradient", { Color = ColorSequence.new(C.accent, C.accent2), Rotation = 45 }, pStroke)
local scale = new("UIScale", { Scale = 1 }, panel)

local header = new("Frame", { BackgroundColor3 = C.panel, BorderSizePixel = 0, Size = UDim2.new(1, 0, 0, 38) }, panel)
corner(header, 12)
new("Frame", { BackgroundColor3 = C.panel, BorderSizePixel = 0, Position = UDim2.new(0, 0, 1, -12),
    Size = UDim2.new(1, 0, 0, 12) }, header)
local title = new("TextLabel", { BackgroundTransparency = 1, Position = UDim2.fromOffset(14, 0),
    Size = UDim2.new(0, 120, 1, 0), Text = "zero.pw", TextColor3 = Color3.new(1, 1, 1), Font = Enum.Font.GothamBlack,
    TextSize = 20, TextXAlignment = Enum.TextXAlignment.Left }, header)
new("UIGradient", { Color = ColorSequence.new(C.accent, C.accent2) }, title)
new("TextLabel", { BackgroundTransparency = 1, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -12, 0, 0),
    Size = UDim2.new(0, 160, 1, 0), Text = "1.8 kit pvp  \194\183  drag me", TextColor3 = C.dim,
    Font = Enum.Font.GothamMedium, TextSize = 11, TextXAlignment = Enum.TextXAlignment.Right }, header)
draggable(header, panel)

local side = new("Frame", { BackgroundTransparency = 1, Position = UDim2.fromOffset(8, 46),
    Size = UDim2.new(0, 92, 1, -54) }, panel)
new("UIListLayout", { Padding = UDim.new(0, 6) }, side)
local content = new("Frame", { BackgroundTransparency = 1, Position = UDim2.fromOffset(108, 46),
    Size = UDim2.new(1, -116, 1, -54) }, panel)

local tabs = {}
local function makePage()
    local s = new("ScrollingFrame", { BackgroundTransparency = 1, BorderSizePixel = 0, Size = UDim2.fromScale(1, 1),
        ScrollBarThickness = 3, ScrollBarImageColor3 = C.accent, CanvasSize = UDim2.new(),
        AutomaticCanvasSize = Enum.AutomaticSize.Y, Visible = false }, content)
    new("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }, s)
    new("UIPadding", { PaddingRight = UDim.new(0, 6) }, s)
    return s
end
local function selectTab(name)
    for n, tb in pairs(tabs) do
        local on = n == name
        tb.btn.BackgroundTransparency = on and 0 or 1
        tb.btn.TextColor3 = on and C.text or C.dim
        tb.page.Visible = on
    end
end
local function addTab(name)
    local page = makePage()
    local b = new("TextButton", { Text = name, Font = Enum.Font.GothamBold, TextSize = 13, TextColor3 = C.dim,
        BackgroundColor3 = C.accent, BackgroundTransparency = 1, BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 34) }, side)
    corner(b, 8)
    tabs[name] = { btn = b, page = page }
    bind(b.Activated, function() selectTab(name) end)
    return page
end

local pCombat = addTab("Combat")
local pMove   = addTab("Move")
local pVisual = addTab("Visuals")
local pConfig = addTab("Config")

card(pCombat, "Killaura", "killaura", {
    { "slider", "range", "range", 4, 30, 1 },
    { "slider", "cps", "attacks / sec", 1, 30, 1 },
    { "slider", "multi", "targets per hit", 1, 5, 1 },
    { "toggle", "face", "face target" },
    { "toggle", "players", "hit players" },
    { "toggle", "team", "skip teammates" },
})
card(pCombat, "Aim", "aim", {
    { "slider", "fov", "fov (px)", 40, 500, 10 },
    { "slider", "smooth", "aim speed", 0.05, 1, 0.05 },
    { "slider", "predict", "prediction (s)", 0, 0.3, 0.01 },
    { "slider", "range", "range", 10, 200, 5 },
    { "toggle", "showFov", "show fov circle" },
    { "toggle", "sticky", "stick to target" },
    { "toggle", "head", "aim head" },
    { "toggle", "players", "aim at players" },
    { "toggle", "team", "skip teammates" },
})
card(pCombat, "Auto Mace", "mace", {
    { "slider", "engage", "engage range", 6, 40, 1 },
    { "slider", "reach", "smash reach", 3, 12, 0.5 },
    { "slider", "minFall", "min fall (studs)", 0.5, 10, 0.5 },
    { "slider", "cd", "jump cooldown", 0.4, 3, 0.1 },
})
card(pCombat, "Auto Totem", "totem", {
    { "slider", "hp", "hold totem below hp %", 10, 90, 5 },
})
card(pCombat, "Auto Pearl", "pearl", {
    { "slider", "hp", "flee below hp %", 10, 90, 5 },
    { "slider", "enemy", "enemy within", 4, 40, 1 },
    { "slider", "cd", "cooldown", 1, 15, 0.5 },
})

card(pMove, "Speed", "speed", {
    { "slider", "speed", "speed", 16, 120, 2 },
    { "toggle", "cframe", "cframe mode (safer)" },
})
card(pMove, "Fly", "fly", {
    { "slider", "speed", "speed", 10, 120, 2 },
})
card(pMove, "Bhop", "bhop", {})
card(pMove, "Anti Knockback", "antikb", {
    { "slider", "reduce", "reduce by", 0, 1, 0.05 },
})

card(pVisual, "ESP", "esp", {
    { "slider", "range", "range", 20, 400, 10 },
    { "slider", "max", "max boxes", 5, 80, 5 },
    { "toggle", "players", "show players" },
})
card(pVisual, "Chams", "chams", {
    { "slider", "fill", "fill transparency", 0, 1, 0.05 },
    { "slider", "range", "range", 30, 600, 10 },
})
card(pVisual, "Fullbright", "fullbright", {})
card(pVisual, "HUD", "hud", {
    { "toggle", "stats", "stats panel" },
})
card(pVisual, "Target HUD", "target", {})

-- config tab
local info = new("TextLabel", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0),
    AutomaticSize = Enum.AutomaticSize.Y, TextWrapped = true, Text = "", TextColor3 = C.dim, Font = Enum.Font.Code,
    TextSize = 11, TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top,
    LayoutOrder = 0 }, pConfig)

local function saveCfg()
    if writefile then pcall(function() writefile(kFile, HttpService:JSONEncode(CFG)) end) end
end
local function loadCfg(forceOff)
    if isfile and readfile and isfile(kFile) then
        local ok, data = pcall(function() return HttpService:JSONDecode(readfile(kFile)) end)
        if ok and type(data) == "table" then
            for mod, t in pairs(data) do
                if type(t) == "table" and CFG[mod] then
                    for k, v in pairs(t) do
                        if CFG[mod][k] ~= nil and type(CFG[mod][k]) == type(v) then CFG[mod][k] = v end
                    end
                end
            end
        end
    end
    if forceOff then
        for _, m in ipairs({ "killaura", "aim", "mace", "totem", "pearl", "speed", "fly", "bhop", "antikb",
                             "fullbright" }) do
            CFG[m].on = false
        end
    end
    for _, f in ipairs(refreshers) do f() end
end

local function Destroy()
    Learn.dead = true
    Learn.armed = false
    CFG.fullbright.on = false
    pcall(fbStep)
    local h = myHum()
    if h and state.baseWS then pcall(function() h.WalkSpeed = state.baseWS end) end
    for _, c in ipairs(conns) do pcall(function() c:Disconnect() end) end
    pcall(function() RunService:UnbindFromRenderStep("zeropw_aim") end)
    pcall(function() gui:Destroy() end)
    pcall(function() fovGui:Destroy() end)
    pcall(function() espFolder:Destroy() end)
    genv.ZeroPW = nil
end
genv.ZeroPW = { Destroy = Destroy }

button(pConfig, "Learn Attack  (then swing at someone)", function()
    Learn.armed = true
    Learn.stop = os.clock() + 10
    Learn.status = "swing at someone now (10s)"
end).LayoutOrder = 1
button(pConfig, "Forget learned attack", function()
    Learn.remote, Learn.args, Learn.idx = nil, nil, nil
    Learn.status = "waiting: swing at someone"
end).LayoutOrder = 2
button(pConfig, "Save config", saveCfg).LayoutOrder = 3
button(pConfig, "Load config", function() loadCfg(false) end).LayoutOrder = 4
button(pConfig, "Unload zero.pw", Destroy).LayoutOrder = 5

updaters[#updaters + 1] = function()
    if Learn.armed and os.clock() > Learn.stop then
        Learn.armed = false
        Learn.status = "nothing caught (touch-based hits?)"
    end
    local lines = {
        "attack: " .. (Learn.remote and ("remote " .. Learn.remote.Name) or "touch/Activate fallback"),
        "learn : " .. Learn.status,
        "aura  : " .. state.auraInfo,
        "touch : " .. (firetouchinterest and "yes" or "no") .. "   hook: " .. (okHook and "yes" or "no"),
    }
    for i = math.max(1, #Learn.log - 2), #Learn.log do lines[#lines + 1] = "  " .. Learn.log[i] end
    info.Text = table.concat(lines, "\n")
end

selectTab("Combat")

-- ===== toggle button =====================================================
local open = false
local function setOpen(v)
    open = v
    panel.Visible = v
    if v then
        scale.Scale = 0.92
        TweenService:Create(scale, TweenInfo.new(0.15, Enum.EasingStyle.Quad), { Scale = 1 }):Play()
    end
end
local zbtn = new("TextButton", { Name = "z", Text = "z", Font = Enum.Font.GothamBlack, TextSize = 24,
    TextColor3 = C.text, BackgroundColor3 = C.bg, AutoButtonColor = false, Size = UDim2.fromOffset(46, 46),
    Position = UDim2.new(1, -66, 0.4, 0), ZIndex = 50 }, gui)
corner(zbtn, 23)
local zs = stroke(zbtn, C.accent, 2, 0)
new("UIGradient", { Color = ColorSequence.new(C.accent, C.accent2), Rotation = 45 }, zs)
draggable(zbtn, zbtn, function() setOpen(not open) end)

-- ===== aim (render step) =================================================
local function aimEval(hum, r, cam, center, A)
    local m = hum.Parent
    if not m or m == LP.Character or hum.Health <= 0 then return nil end
    local pl = Players:GetPlayerFromCharacter(m)
    if pl then
        if not A.players then return nil end
        if A.team and pl.Team ~= nil and pl.Team == LP.Team then return nil end
    end
    local root = m:FindFirstChild("HumanoidRootPart")
    if not root then return nil end
    local part = (A.head and m:FindFirstChild("Head")) or root
    local dist = (root.Position - r.Position).Magnitude
    if dist > A.range then return nil end
    local sp, on = cam:WorldToViewportPoint(part.Position)
    if not on then return nil end
    local sd = (Vector2.new(sp.X, sp.Y) - center).Magnitude
    if sd > A.fov then return nil end
    return { hum = hum, model = m, root = root, part = part, dist = dist, sd = sd, plr = pl ~= nil }
end

local function aimStep(dt)
    state.aimTarget = nil
    local A = CFG.aim
    fovCircle.Visible = A.on and A.showFov
    if not A.on then
        state.aimLock = nil
        return
    end
    fovCircle.Size = UDim2.fromOffset(A.fov * 2, A.fov * 2)
    local r = myRoot()
    if not r then return end
    local cam = Workspace.CurrentCamera
    local vps = cam.ViewportSize
    local center = Vector2.new(vps.X / 2, vps.Y / 2)
    local best
    if A.sticky and state.aimLock then
        best = aimEval(state.aimLock, r, cam, center, A)
    end
    if not best then
        for hum in pairs(hums) do
            local e = aimEval(hum, r, cam, center, A)
            if e and (not best or e.sd < best.sd) then best = e end
        end
    end
    state.aimLock = best and best.hum or nil
    fovStroke.Color = best and C.bad or C.accent2
    if best then
        state.aimTarget = best
        local pos = best.part.Position + best.root.AssemblyLinearVelocity * A.predict
        local a = 1 - (1 - math.clamp(A.smooth, 0, 0.999)) ^ (dt * 60)
        cam.CFrame = cam.CFrame:Lerp(CFrame.lookAt(cam.CFrame.Position, pos), math.clamp(a, 0, 1))
    end
end
RunService:BindToRenderStep("zeropw_aim", Enum.RenderPriority.Camera.Value + 1, function(dt)
    safe(aimStep, dt)
end)

-- ===== hud ===============================================================
local hud = new("Frame", { Name = "h", BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1) }, gui)
local mark = new("Frame", { BackgroundColor3 = C.bg, BackgroundTransparency = 0.15, BorderSizePixel = 0,
    Position = UDim2.fromOffset(10, 8), Size = UDim2.fromOffset(0, 24), AutomaticSize = Enum.AutomaticSize.X }, hud)
corner(mark, 6)
stroke(mark, C.accent, 1, 0.5)
new("UIPadding", { PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8) }, mark)
local markTxt = new("TextLabel", { BackgroundTransparency = 1, Size = UDim2.fromOffset(0, 24),
    AutomaticSize = Enum.AutomaticSize.X, Text = "", RichText = true, TextColor3 = C.text,
    Font = Enum.Font.GothamBold, TextSize = 12 }, mark)

local statsFrame = new("Frame", { BackgroundColor3 = C.bg, BackgroundTransparency = 0.15, BorderSizePixel = 0,
    Position = UDim2.fromOffset(10, 38), Size = UDim2.fromOffset(0, 0), AutomaticSize = Enum.AutomaticSize.XY }, hud)
corner(statsFrame, 6)
stroke(statsFrame, C.accent, 1, 0.6)
new("UIPadding", { PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8), PaddingTop = UDim.new(0, 5),
    PaddingBottom = UDim.new(0, 5) }, statsFrame)
new("UIListLayout", { Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder }, statsFrame)
local statLines = {}
for i = 1, 3 do
    statLines[i] = new("TextLabel", { BackgroundTransparency = 1, Size = UDim2.fromOffset(0, 14),
        AutomaticSize = Enum.AutomaticSize.X, Text = "", TextColor3 = C.text, Font = Enum.Font.GothamMedium,
        TextSize = 11, TextXAlignment = Enum.TextXAlignment.Left, LayoutOrder = i }, statsFrame)
end

local arr = new("Frame", { BackgroundTransparency = 1, AnchorPoint = Vector2.new(1, 0),
    Position = UDim2.new(1, -10, 0, 8), Size = UDim2.fromOffset(130, 0), AutomaticSize = Enum.AutomaticSize.Y }, hud)
new("UIListLayout", { HorizontalAlignment = Enum.HorizontalAlignment.Right, Padding = UDim.new(0, 2),
    SortOrder = Enum.SortOrder.LayoutOrder }, arr)
local ARR = { { "Killaura", "killaura" }, { "Aim", "aim" }, { "Auto Mace", "mace" }, { "Auto Totem", "totem" },
              { "Auto Pearl", "pearl" }, { "Speed", "speed" }, { "Fly", "fly" }, { "Bhop", "bhop" },
              { "Anti KB", "antikb" }, { "ESP", "esp" }, { "Chams", "chams" }, { "Fullbright", "fullbright" } }
local arrLabels = {}
for i, m in ipairs(ARR) do
    arrLabels[i] = new("TextLabel", { BackgroundColor3 = C.bg, BackgroundTransparency = 0.25, BorderSizePixel = 0,
        AutomaticSize = Enum.AutomaticSize.X, Size = UDim2.fromOffset(0, 16), Text = " " .. m[1] .. " ",
        TextColor3 = C.accent2, Font = Enum.Font.GothamMedium, TextSize = 12, Visible = false, LayoutOrder = i }, arr)
end

-- target hud: avatar + hearts, kill banner
local thud = new("Frame", { BackgroundColor3 = C.bg, BackgroundTransparency = 0.12, BorderSizePixel = 0,
    AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 10), Size = UDim2.fromOffset(240, 66),
    Visible = false }, gui)
corner(thud, 8)
stroke(thud, C.accent, 1.2, 0.3)
local avatar = new("ImageLabel", { BackgroundColor3 = C.panel, BorderSizePixel = 0, Position = UDim2.fromOffset(8, 9),
    Size = UDim2.fromOffset(48, 48), Image = "" }, thud)
corner(avatar, 8)
local cross = new("Frame", { BackgroundTransparency = 1, ClipsDescendants = true, Visible = false,
    Position = UDim2.fromOffset(8, 9), Size = UDim2.fromOffset(48, 48), ZIndex = 5 }, thud)
corner(cross, 8)
for _, rot in ipairs({ 45, -45 }) do
    new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromOffset(6, 70), Rotation = rot, BackgroundColor3 = C.bad, BorderSizePixel = 0,
        ZIndex = 6 }, cross)
end
local tName = new("TextLabel", { BackgroundTransparency = 1, Position = UDim2.fromOffset(64, 6),
    Size = UDim2.new(1, -72, 0, 16), Font = Enum.Font.GothamBold, TextSize = 14, TextColor3 = C.text,
    TextXAlignment = Enum.TextXAlignment.Left, Text = "" }, thud)
local heartRow = new("Frame", { BackgroundTransparency = 1, Position = UDim2.fromOffset(64, 25),
    Size = UDim2.fromOffset(160, 16) }, thud)
local heartClips = {}
for i = 1, 10 do
    local cell = new("Frame", { BackgroundTransparency = 1, Position = UDim2.fromOffset((i - 1) * 16, 0),
        Size = UDim2.fromOffset(16, 16) }, heartRow)
    new("TextLabel", { BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), Text = "\226\153\165",
        TextColor3 = Color3.fromRGB(70, 46, 58), Font = Enum.Font.SourceSansBold, TextSize = 20 }, cell)
    local clip = new("Frame", { BackgroundTransparency = 1, ClipsDescendants = true, Size = UDim2.fromScale(0, 1) },
        cell)
    new("TextLabel", { BackgroundTransparency = 1, Size = UDim2.fromOffset(16, 16), Text = "\226\153\165",
        TextColor3 = C.bad, Font = Enum.Font.SourceSansBold, TextSize = 20 }, clip)
    heartClips[i] = clip
end
local tTxt = new("TextLabel", { BackgroundTransparency = 1, Position = UDim2.fromOffset(64, 44),
    Size = UDim2.new(1, -72, 0, 14), Font = Enum.Font.GothamMedium, TextSize = 11, TextColor3 = C.dim,
    TextXAlignment = Enum.TextXAlignment.Left, Text = "" }, thud)
local killLbl = new("TextLabel", { BackgroundTransparency = 1, Position = UDim2.fromOffset(64, 24),
    Size = UDim2.new(1, -72, 0, 28), Font = Enum.Font.SourceSansBold, TextSize = 24, TextColor3 = C.bad,
    TextXAlignment = Enum.TextXAlignment.Left, Text = "\208\190\208\180\208\184\208\189 \209\129\208\178\208\184\208\189\209\140\209\143",
    Visible = false }, thud)

local thumbCache, thumbBusy = {}, {}
local function setAvatar(model)
    local pl = model and Players:GetPlayerFromCharacter(model)
    if not pl then
        avatar.Image = ""
        return
    end
    local url = thumbCache[pl.UserId]
    if url then
        avatar.Image = url
    else
        avatar.Image = ""
        if not thumbBusy[pl.UserId] then
            thumbBusy[pl.UserId] = true
            task.spawn(function()
                local ok, u = pcall(Players.GetUserThumbnailAsync, Players, pl.UserId,
                    Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size100x100)
                thumbCache[pl.UserId] = ok and u or ""
                thumbBusy[pl.UserId] = nil
            end)
        end
    end
end

local function setHearts(hum)
    local maxh = math.max(hum.MaxHealth, 1)
    local h = math.clamp(hum.Health, 0, maxh) / maxh * 10
    for i = 1, 10 do
        local f = math.clamp(h - (i - 1), 0, 1)
        f = math.ceil(f * 2) / 2
        heartClips[i].Size = UDim2.fromScale(f, 1)
    end
    return h
end

local cur, killInfo, killUntil = nil, nil, 0

local function hudStep()
    local now = os.clock()
    local H = CFG.hud
    local mh, mr = myHum(), myRoot()

    -- own deaths
    local dead = mh ~= nil and mh.Health <= 0
    if dead and not state.wasDead then
        state.deaths = state.deaths + 1
        state.streak = 0
    end
    state.wasDead = dead

    hud.Visible = H.on
    if H.on then
        local ping = 0
        pcall(function() ping = math.floor(Stats.Network.ServerStatsItem["Data Ping"]:GetValue()) end)
        markTxt.Text = '<font color="#8a63ff">zero</font>.pw  |  ' .. math.floor(state.fps) .. " fps  |  " .. ping .. " ms"
        for i, m in ipairs(ARR) do arrLabels[i].Visible = CFG[m[2]].on end
        statsFrame.Visible = H.stats
        if H.stats then
            local t = math.floor(now - state.t0)
            statLines[1].Text = string.format("kills %d   deaths %d   streak %d   %02d:%02d",
                state.kills, state.deaths, state.streak, math.floor(t / 60), t % 60)
            local hp, sp, pos = 0, 0, "-"
            if mh then hp = math.clamp(mh.Health, 0, math.max(mh.MaxHealth, 1)) / math.max(mh.MaxHealth, 1) * 10 end
            if mr then
                local v = mr.AssemblyLinearVelocity
                sp = Vector3.new(v.X, 0, v.Z).Magnitude
                pos = math.floor(mr.Position.X) .. " / " .. math.floor(mr.Position.Y) .. " / " ..
                    math.floor(mr.Position.Z)
            end
            statLines[2].Text = string.format("hp %.1f/10   speed %d st/s", hp, math.floor(sp))
            statLines[3].Text = "xyz " .. pos
        end
    end

    -- target hud
    if cur and cur.hum.Health <= 0 then
        killInfo, killUntil = cur, now + 3
        state.kills = state.kills + 1
        state.streak = state.streak + 1
        cur = nil
    elseif cur and not cur.hum:IsDescendantOf(Workspace) then
        cur = nil
    end
    local tgt = nil
    if CFG.target.on then
        tgt = state.target or state.aimTarget or targets(40, true, false)[1]
    end
    if tgt and tgt.hum.Health > 0 then cur = tgt else cur = nil end

    if CFG.target.on and killInfo and now < killUntil then
        thud.Visible = true
        setAvatar(killInfo.model)
        avatar.ImageColor3 = Color3.fromRGB(110, 110, 110)
        cross.Visible = true
        heartRow.Visible = false
        tTxt.Visible = false
        killLbl.Visible = true
        tName.Text = killInfo.model.Name
    elseif cur then
        thud.Visible = true
        setAvatar(cur.model)
        avatar.ImageColor3 = Color3.new(1, 1, 1)
        cross.Visible = false
        heartRow.Visible = true
        tTxt.Visible = true
        killLbl.Visible = false
        tName.Text = cur.model.Name
        local h = setHearts(cur.hum)
        tTxt.Text = string.format("%.1f hearts   \194\183   %dm", h, math.floor(cur.dist))
    else
        thud.Visible = false
    end

    fbStep()
end

-- ===== esp + chams =======================================================
local espObjs, chamObjs = {}, {}
local function makeEsp(e)
    local col = e.plr and C.accent2 or C.bad
    local g = new("BillboardGui", { Adornee = e.root, AlwaysOnTop = true, Size = UDim2.fromScale(4, 6),
        LightInfluence = 0 })
    local box = new("Frame", { BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1) }, g)
    stroke(box, col, 1.5)
    local bg = new("Frame", { BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 0.4,
        BorderSizePixel = 0, Position = UDim2.new(0, -6, 0, 0), Size = UDim2.new(0, 3, 1, 0) }, box)
    local fill = new("Frame", { AnchorPoint = Vector2.new(0, 1), BorderSizePixel = 0, BackgroundColor3 = C.good,
        Position = UDim2.fromScale(0, 1), Size = UDim2.fromScale(1, 1) }, bg)
    local label = new("TextLabel", { BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 1),
        Position = UDim2.new(0.5, 0, 0, -2), Size = UDim2.new(0, 140, 0, 14), Font = Enum.Font.GothamMedium,
        TextSize = 12, TextColor3 = col, TextStrokeTransparency = 0.4, Text = "" }, box)
    g.Parent = espFolder
    return { gui = g, fill = fill, label = label }
end

local function espStep()
    local E = CFG.esp
    local seen = {}
    if E.on then
        local n = 0
        for _, e in ipairs(targets(E.range, E.players, false)) do
            n = n + 1
            if n > E.max then break end
            local o = espObjs[e.model]
            if not o or not o.gui.Parent then
                o = makeEsp(e)
                espObjs[e.model] = o
            end
            seen[e.model] = true
            local pct = math.clamp(e.hum.Health / math.max(e.hum.MaxHealth, 1), 0, 1)
            o.fill.Size = UDim2.fromScale(1, pct)
            o.fill.BackgroundColor3 = C.bad:Lerp(C.good, pct)
            o.label.Text = e.model.Name .. "  " .. math.floor(e.dist) .. "m"
        end
    end
    for m, o in pairs(espObjs) do
        if not seen[m] then
            o.gui:Destroy()
            espObjs[m] = nil
        end
    end
end

local function chamsStep()
    local Ch = CFG.chams
    local seen = {}
    if Ch.on then
        local n = 0
        for _, e in ipairs(targets(Ch.range, true, false)) do
            n = n + 1
            if n > 30 then break end -- roblox renders at most 31 highlights
            local h = chamObjs[e.model]
            if not h or not h.Parent then
                h = new("Highlight", { Adornee = e.model, DepthMode = Enum.HighlightDepthMode.AlwaysOnTop,
                    OutlineColor = Color3.new(1, 1, 1), OutlineTransparency = 0 })
                h.Parent = espFolder
                chamObjs[e.model] = h
            end
            local pl = Players:GetPlayerFromCharacter(e.model)
            local friendly = pl ~= nil and pl.Team ~= nil and pl.Team == LP.Team
            h.FillColor = friendly and C.good or C.bad
            h.FillTransparency = Ch.fill
            seen[e.model] = true
        end
    end
    for m, h in pairs(chamObjs) do
        if not seen[m] then
            h:Destroy()
            chamObjs[m] = nil
        end
    end
end

-- ===== loops =============================================================
bind(RunService.Heartbeat, function(dt)
    local now = os.clock()
    state.target = nil
    local hum, root = myHum(), myRoot()
    if not hum or not root or hum.Health <= 0 then
        state.prevVel = nil
        return
    end
    if CFG.totem.on then safe(totemStep, now, hum) end
    if CFG.pearl.on then safe(pearlStep, now, hum, root) end
    if CFG.mace.on then safe(maceStep, now, hum, root) end
    if CFG.killaura.on then safe(auraStep, now, root) else state.auraInfo = "off" end
    safe(moveStep, dt, hum, root)
end)

local acc = 0
bind(RunService.RenderStepped, function(dt)
    state.fps = state.fps * 0.9 + (1 / math.max(dt, 0.001)) * 0.1
    acc = acc + dt
    if acc < 0.1 then return end
    acc = 0
    safe(hudStep)
    safe(espStep)
    safe(chamsStep)
    for _, u in ipairs(updaters) do safe(u) end
end)

loadCfg(true)
print("[zero.pw] v2 loaded. tap the z button.")
