--[[
    zero.pw  |  unstablesmp  |  delta (mobile)
    one round "z" button opens/closes the menu. everything combat is OFF on launch.

    built blind (no access to the place internals):
      - Config > Learn Attack: tap it, swing once at an enemy, zero.pw copies the hit remote
        and replays it on targets. without it, killaura falls back to Tool:Activate().
      - auto mace / totem / pearl expect those items to be Tools (backpack/hand),
        matched by name substring, see CFG.*.name below.
]]

-- ===== config ============================================================
local CFG = {
    killaura = { on = false, range = 16, cps = 6, multi = 1, face = true, players = true, team = true },
    aim      = { on = false, fov = 180, smooth = 0.35, range = 60, head = true, players = true, team = true },
    mace     = { on = false, name = "mace", engage = 16, reach = 7, minFall = 2.5, cd = 1.2 },
    totem    = { on = false, name = "totem", hp = 45 },
    pearl    = { on = false, name = "pearl", hp = 30, enemy = 14, cd = 4 },
    esp      = { on = false, range = 160, max = 40, players = true },
    hud      = { on = true },
    target   = { on = true },
}
local kFile = "zero.pw.json"

-- ===== services ==========================================================
local Players      = game:GetService("Players")
local RunService   = game:GetService("RunService")
local UIS          = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local HttpService  = game:GetService("HttpService")
local Stats        = game:GetService("Stats")
local Workspace    = game:GetService("Workspace")

local LP     = Players.LocalPlayer
local Camera = Workspace.CurrentCamera
local genv   = (getgenv and getgenv()) or _G

if genv.ZeroPW then pcall(genv.ZeroPW.Destroy) end

local C = {
    bg     = Color3.fromRGB(14, 14, 20),
    panel  = Color3.fromRGB(22, 22, 32),
    item   = Color3.fromRGB(32, 32, 46),
    accent = Color3.fromRGB(138, 99, 255),
    accent2 = Color3.fromRGB(80, 200, 255),
    text   = Color3.fromRGB(236, 236, 246),
    dim    = Color3.fromRGB(140, 140, 162),
    good   = Color3.fromRGB(90, 220, 140),
    bad    = Color3.fromRGB(255, 90, 110),
}

local state = { lock = 0, pearlT = 0, lastHit = 0, lastMace = 0, peakY = 0,
                target = nil, aimTarget = nil, preTotem = nil, err = nil, fps = 60 }

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
                local isPlr = Players:GetPlayerFromCharacter(m) ~= nil
                local skip = false
                if isPlr and teamCheck then
                    local pl = Players:GetPlayerFromCharacter(m)
                    skip = pl ~= nil and pl.Team ~= nil and pl.Team == LP.Team
                end
                if (allowPlayers or not isPlr) and not skip then
                    local d = (root.Position - r.Position).Magnitude
                    if d <= range then
                        out[#out + 1] = { hum = hum, model = m, root = root, dist = d, plr = isPlr }
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

-- ===== attack learner (hit remote) =======================================
local Learn = { armed = false, stop = 0, remote = nil, args = nil, idx = nil, status = "idle", log = {}, dead = false }

local function modelOf(inst)
    local cur = inst
    while cur and cur ~= Workspace do
        if cur:IsA("Model") and cur:FindFirstChildOfClass("Humanoid") then return cur end
        cur = cur.Parent
    end
    return nil
end

local function onRemote(remote, args)
    local d = {}
    for i = 1, args.n do d[i] = typeof(args[i]) end
    Learn.log[#Learn.log + 1] = remote.Name .. "(" .. table.concat(d, ",") .. ")"
    if #Learn.log > 6 then table.remove(Learn.log, 1) end
    for i = 1, args.n do
        local a = args[i]
        if typeof(a) == "Instance" then
            local m = modelOf(a)
            if m and m ~= LP.Character then
                Learn.remote, Learn.args, Learn.idx = remote, args, i
                Learn.armed = false
                Learn.status = "learned " .. remote.Name .. " (arg " .. i .. ")"
                return
            end
        end
    end
end

local okHook = pcall(function()
    local wrap = newcclosure or function(f) return f end
    local old
    old = hookmetamethod(game, "__namecall", wrap(function(self, ...)
        if Learn.armed and not Learn.dead then
            local m = getnamecallmethod()
            if (m == "FireServer" or m == "InvokeServer") and not (checkcaller and checkcaller()) then
                task.defer(onRemote, self, table.pack(...))
            end
        end
        return old(self, ...)
    end))
end)
if not okHook then Learn.status = "no hook support: Tool:Activate() only" end

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

-- ===== modules ===========================================================
local function auraStep(now, root)
    local K = CFG.killaura
    local list = targets(K.range, K.players, K.team)
    local t = list[1]
    if not t then return end
    state.target = t
    if K.face then
        local p = t.root.Position
        root.CFrame = CFrame.lookAt(root.Position, Vector3.new(p.X, root.Position.Y, p.Z))
    end
    if now < state.lock then return end
    if now - state.lastHit < 1 / K.cps then return end
    state.lastHit = now
    for i = 1, math.min(K.multi, #list) do
        if not fireLearned(list[i], root) then
            local tool = heldTool()
            if tool then tool:Activate() end
        end
    end
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
    local t = targets(M.engage, true, true)[1]
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
        if not fireLearned(t, root) then tool:Activate() end
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
    local t = targets(P.enemy, true, true)[1]
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

local function aimStep()
    state.aimTarget = nil
    local A = CFG.aim
    if not A.on then return end
    local r = myRoot()
    if not r then return end
    local cam = Workspace.CurrentCamera
    local vp = cam.ViewportSize
    local center = Vector2.new(vp.X / 2, vp.Y / 2)
    local best, bestD
    for hum in pairs(hums) do
        local m = hum.Parent
        local pl = m and Players:GetPlayerFromCharacter(m)
        local teamSkip = pl and A.team and pl.Team ~= nil and pl.Team == LP.Team
        if m and m ~= LP.Character and hum.Health > 0 and (A.players or not pl) and not teamSkip then
            local root = m:FindFirstChild("HumanoidRootPart")
            local part = (A.head and m:FindFirstChild("Head")) or root
            if part and root and (root.Position - r.Position).Magnitude <= A.range then
                local sp, on = cam:WorldToViewportPoint(part.Position)
                if on then
                    local d = (Vector2.new(sp.X, sp.Y) - center).Magnitude
                    if d <= A.fov and (not bestD or d < bestD) then
                        best = { hum = hum, model = m, root = root, part = part,
                                 dist = (root.Position - r.Position).Magnitude }
                        bestD = d
                    end
                end
            end
        end
    end
    if best then
        state.aimTarget = best
        cam.CFrame = cam.CFrame:Lerp(CFrame.lookAt(cam.CFrame.Position, best.part.Position), A.smooth)
    end
end
RunService:BindToRenderStep("zeropw_aim", Enum.RenderPriority.Camera.Value + 1, function()
    safe(aimStep)
end)

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
    Size = UDim2.new(0, 160, 1, 0), Text = "unstablesmp  \194\183  drag me", TextColor3 = C.dim,
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
local pVisual = addTab("Visuals")
local pConfig = addTab("Config")

card(pCombat, "Killaura", "killaura", {
    { "slider", "range", "range", 4, 40, 1 },
    { "slider", "cps", "attacks / sec", 1, 20, 1 },
    { "slider", "multi", "targets per hit", 1, 5, 1 },
    { "toggle", "face", "face target" },
    { "toggle", "players", "hit players" },
    { "toggle", "team", "skip teammates" },
})
card(pCombat, "Aim", "aim", {
    { "slider", "fov", "fov (px)", 40, 500, 10 },
    { "slider", "smooth", "smoothing", 0.05, 1, 0.05 },
    { "slider", "range", "range", 10, 150, 5 },
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

card(pVisual, "ESP", "esp", {
    { "slider", "range", "range", 20, 400, 10 },
    { "slider", "max", "max boxes", 5, 80, 5 },
    { "toggle", "players", "show players" },
})
card(pVisual, "HUD", "hud", {})
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
        for _, m in ipairs({ "killaura", "aim", "mace", "totem", "pearl" }) do CFG[m].on = false end
    end
    for _, f in ipairs(refreshers) do f() end
end

local function Destroy()
    Learn.dead = true
    Learn.armed = false
    for _, c in ipairs(conns) do pcall(function() c:Disconnect() end) end
    pcall(function() RunService:UnbindFromRenderStep("zeropw_aim") end)
    pcall(function() gui:Destroy() end)
    pcall(function() espFolder:Destroy() end)
    genv.ZeroPW = nil
end
genv.ZeroPW = { Destroy = Destroy }

local cbtn = button(pConfig, "Learn Attack  (then swing at an enemy)", function()
    Learn.armed = true
    Learn.stop = os.clock() + 10
    Learn.status = "swing at an enemy now (10s)"
end)
cbtn.LayoutOrder = 1
button(pConfig, "Forget learned attack", function()
    Learn.remote, Learn.args, Learn.idx = nil, nil, nil
    Learn.status = "idle"
end).LayoutOrder = 2
button(pConfig, "Save config", saveCfg).LayoutOrder = 3
button(pConfig, "Load config", function() loadCfg(false) end).LayoutOrder = 4
button(pConfig, "Unload zero.pw", Destroy).LayoutOrder = 5

updaters[#updaters + 1] = function()
    if Learn.armed and os.clock() > Learn.stop then
        Learn.armed = false
        Learn.status = "nothing caught (hits not via remote with a target?)"
    end
    local lines = {
        "attack: " .. (Learn.remote and ("remote " .. Learn.remote.Name) or "Tool:Activate() fallback"),
        "learn : " .. Learn.status,
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

local arr = new("Frame", { BackgroundTransparency = 1, AnchorPoint = Vector2.new(1, 0),
    Position = UDim2.new(1, -10, 0, 8), Size = UDim2.fromOffset(130, 0), AutomaticSize = Enum.AutomaticSize.Y }, hud)
new("UIListLayout", { HorizontalAlignment = Enum.HorizontalAlignment.Right, Padding = UDim.new(0, 2),
    SortOrder = Enum.SortOrder.LayoutOrder }, arr)
local ARR = { { "Killaura", "killaura" }, { "Aim", "aim" }, { "Auto Mace", "mace" }, { "Auto Totem", "totem" },
              { "Auto Pearl", "pearl" }, { "ESP", "esp" } }
local arrLabels = {}
for i, m in ipairs(ARR) do
    arrLabels[i] = new("TextLabel", { BackgroundColor3 = C.bg, BackgroundTransparency = 0.25, BorderSizePixel = 0,
        AutomaticSize = Enum.AutomaticSize.X, Size = UDim2.fromOffset(0, 16), Text = " " .. m[1] .. " ",
        TextColor3 = C.accent2, Font = Enum.Font.GothamMedium, TextSize = 12, Visible = false, LayoutOrder = i }, arr)
end

local thud = new("Frame", { BackgroundColor3 = C.bg, BackgroundTransparency = 0.12, BorderSizePixel = 0,
    AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 10), Size = UDim2.fromOffset(210, 54),
    Visible = false }, gui)
corner(thud, 8)
stroke(thud, C.accent, 1.2, 0.3)
local tName = new("TextLabel", { BackgroundTransparency = 1, Position = UDim2.fromOffset(10, 5),
    Size = UDim2.new(1, -20, 0, 16), Font = Enum.Font.GothamBold, TextSize = 14, TextColor3 = C.text,
    TextXAlignment = Enum.TextXAlignment.Left, Text = "" }, thud)
local tBg = new("Frame", { BackgroundColor3 = C.panel, BorderSizePixel = 0, Position = UDim2.fromOffset(10, 25),
    Size = UDim2.new(1, -20, 0, 8) }, thud)
corner(tBg, 4)
local tFill = new("Frame", { BackgroundColor3 = C.good, BorderSizePixel = 0, Size = UDim2.fromScale(1, 1) }, tBg)
corner(tFill, 4)
local tTxt = new("TextLabel", { BackgroundTransparency = 1, Position = UDim2.fromOffset(10, 36),
    Size = UDim2.new(1, -20, 0, 14), Font = Enum.Font.GothamMedium, TextSize = 11, TextColor3 = C.dim,
    TextXAlignment = Enum.TextXAlignment.Left, Text = "" }, thud)

local function hudStep()
    local H = CFG.hud
    hud.Visible = H.on
    if H.on then
        local ping = 0
        pcall(function() ping = math.floor(Stats.Network.ServerStatsItem["Data Ping"]:GetValue()) end)
        markTxt.Text = '<font color="#8a63ff">zero</font>.pw  |  ' .. math.floor(state.fps) .. " fps  |  " .. ping .. " ms"
        for i, m in ipairs(ARR) do arrLabels[i].Visible = CFG[m[2]].on end
    end
    local tgt = nil
    if CFG.target.on then
        tgt = state.target or state.aimTarget or targets(40, true, true)[1]
    end
    if tgt and tgt.hum.Parent and tgt.hum.Health > 0 then
        local pct = math.clamp(tgt.hum.Health / math.max(tgt.hum.MaxHealth, 1), 0, 1)
        thud.Visible = true
        tName.Text = tgt.model.Name
        tTxt.Text = math.floor(tgt.hum.Health) .. " / " .. math.floor(tgt.hum.MaxHealth) .. "   \194\183   " ..
            math.floor(tgt.dist) .. "m"
        TweenService:Create(tFill, TweenInfo.new(0.12), { Size = UDim2.fromScale(pct, 1),
            BackgroundColor3 = C.bad:Lerp(C.good, pct) }):Play()
    else
        thud.Visible = false
    end
end

-- ===== esp ===============================================================
local espObjs = {}
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
        for _, e in ipairs(targets(E.range, E.players)) do
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

-- ===== loops =============================================================
bind(RunService.Heartbeat, function()
    local now = os.clock()
    state.target = nil
    local hum, root = myHum(), myRoot()
    if not hum or not root or hum.Health <= 0 then return end
    if CFG.totem.on then safe(totemStep, now, hum) end
    if CFG.pearl.on then safe(pearlStep, now, hum, root) end
    if CFG.mace.on then safe(maceStep, now, hum, root) end
    if CFG.killaura.on then safe(auraStep, now, root) end
end)

local acc = 0
bind(RunService.RenderStepped, function(dt)
    state.fps = state.fps * 0.9 + (1 / math.max(dt, 0.001)) * 0.1
    acc = acc + dt
    if acc < 0.1 then return end
    acc = 0
    safe(hudStep)
    safe(espStep)
    for _, u in ipairs(updaters) do safe(u) end
end)

loadCfg(true)
print("[zero.pw] loaded. tap the z button.")
