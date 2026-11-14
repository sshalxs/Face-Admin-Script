--[[  zero.pw  |  BloxStrike  (place 114234929420007)   v1.4
      rage : silent aim / 3rd person / antiaim
      vis  : esp / chams / fog / sky / fullbright
      misc : wallshot / fly / hitbox / speed / jump / fps
      кнопка «Z» слева — меню
]]

local VERSION = "1.4"

--============================== services ==============================
local Players      = game:GetService("Players")
local RS           = game:GetService("ReplicatedStorage")
local WS           = game:GetService("Workspace")
local RunService   = game:GetService("RunService")
local Lighting     = game:GetService("Lighting")
local UIS          = game:GetService("UserInputService")
local LocalPlayer  = Players.LocalPlayer

--============================== config ===============================
local CFG = {
    silent = { on=false, fov=140, chance=100, part="Head", wall=true, team=false, circle=true,
               color=Color3.fromRGB(150, 100, 255) },
    third  = { on=false, dist=9, height=1.5 },
    aa     = { mode=0, speed=240 },
    esp    = { on=false, box=true, name=true, dist=true, hp=true, line=false, team=false,
               maxDist=600, visColor=Color3.fromRGB(120, 255, 150),
               hidColor=Color3.fromRGB(255, 70, 70) },
    chams  = { on=false, team=false, fill=Color3.fromRGB(150, 60, 255),
               outline=Color3.fromRGB(255, 255, 255), transp=0.55 },
    fog    = { on=false, start=0, fin=350, color=Color3.fromRGB(120, 60, 220) },
    sky    = { on=false, color=Color3.fromRGB(18, 10, 36) },
    bright = { on=false },
    misc   = { wallshot=false, fly=false, flySpeed=60, hitbox=false, hbSize=6,
               speed=false, speedVal=30, jump=false, jumpVal=80, fps=false },
}
if getgenv then getgenv().ZEROPW = CFG end

local function log(t)
    print("[zero.pw] " .. tostring(t))
    pcall(function()
        game:GetService("StarterGui"):SetCore("SendNotification",
            { Title = "zero.pw " .. VERSION, Text = tostring(t), Duration = 3 })
    end)
end

--============================== helpers ==============================
local function alive(plr)
    local ch = plr.Character
    if not ch then return false end
    local hum = ch:FindFirstChildOfClass("Humanoid")
    if not hum or hum.Health <= 0 then return false end
    if ch:GetAttribute("Dead") == true then return false end
    return true
end

-- сколько разных команд сейчас в игре (кэш на 1с)
local teamCount, teamStamp = 0, 0
local function teamsActive()
    local now = os.clock()
    if now - teamStamp < 1 then return teamCount >= 2 end
    teamStamp = now
    local seen, n = {}, 0
    for _, p in ipairs(Players:GetPlayers()) do
        local t = p:GetAttribute("Team")
        if t ~= nil and tostring(t) ~= "" then
            local k = tostring(t)
            if not seen[k] then seen[k] = true n = n + 1 end
        end
    end
    teamCount = n
    return n >= 2
end

local function isEnemy(plr)
    if plr == LocalPlayer then return false end
    if not teamsActive() then return true end
    if tostring(WS:GetAttribute("Gamemode")) == "Deathmatch" then return true end
    local lt = LocalPlayer:GetAttribute("Team")
    local pt = plr:GetAttribute("Team")
    if lt == nil or pt == nil then return true end
    return tostring(lt) ~= tostring(pt)
end

local rayIgnore
do
    local ok, mod = pcall(function()
        local C = RS:WaitForChild("Components", 10)
        local CM = C and C:WaitForChild("Common", 5)
        local G = CM and CM:WaitForChild("GetRayIgnore", 5)
        if not G then error("no GetRayIgnore") end
        return require(G)
    end)
    if ok and type(mod) == "function" then rayIgnore = mod end
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
    local filter = { LocalPlayer.Character, cam }
    if rayIgnore then
        local ok, list = pcall(rayIgnore)
        if ok and type(list) == "table" then
            for i = 1, #list do filter[#filter + 1] = list[i] end
        end
    end
    visParams.FilterDescendantsInstances = filter
    local res = WS:Raycast(cam.CFrame.Position, part.Position - cam.CFrame.Position, visParams)
    return not res or res.Instance:IsDescendantOf(ch)
end

local function pickPart(ch)
    local n = CFG.silent.part
    if n == "Random" then
        local list = { "Head", "UpperTorso", "HumanoidRootPart", "LowerTorso" }
        local good = {}
        for _, v in ipairs(list) do if ch:FindFirstChild(v) then good[#good + 1] = v end end
        n = good[math.random(1, #good)] or "Head"
    end
    local p = ch:FindFirstChild(n) or ch:FindFirstChild("Head") or ch.PrimaryPart
    if p and p:IsA("BasePart") then return p end
end

local function target(ignoreWalls)
    local cam = WS.CurrentCamera
    if not cam then return nil end
    local vp = cam.ViewportSize
    local cx, cy = vp.X * 0.5, vp.Y * 0.5
    local best, bestD = nil, CFG.silent.fov * CFG.silent.fov
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and alive(plr) then
            local ch = plr.Character
            if ch and (not CFG.silent.team or isEnemy(plr)) then
                local part = pickPart(ch)
                if part then
                    local sp, onScr = cam:WorldToViewportPoint(part.Position)
                    if onScr then
                        local dx, dy = sp.X - cx, sp.Y - cy
                        local d = dx * dx + dy * dy
                        if d < bestD and (ignoreWalls or visible(ch, part)) then
                            bestD, best = d, ch
                        end
                    end
                end
            end
        end
    end
    return best
end

--========================== silent aim / wallshot ====================
local aimCalls, aimHooked = 0, false
do
    local ok, mod = pcall(function()
        local C = RS:WaitForChild("Components", 10)
        local W = C and C:WaitForChild("Weapon", 5)
        local CL = W and W:WaitForChild("Classes", 5)
        local B = CL and CL:WaitForChild("Bullet", 5)
        if not B then error("no Bullet module") end
        return require(B)
    end)
    local fn = (ok and type(mod) == "table" and type(mod._performRaycast) == "function")
        and mod._performRaycast or nil
    if fn then
        local old
        local new = function(self, spread)
            aimCalls = aimCalls + 1
            if not (CFG.silent.on or CFG.misc.wallshot) then return old(self, spread) end
            if math.random(1, 100) > CFG.silent.chance then return old(self, spread) end
            local tgt = target(CFG.misc.wallshot or not CFG.silent.wall)
            if not tgt then return old(self, spread) end
            local part = pickPart(tgt)
            local cam = WS.CurrentCamera
            if not part or not cam then return old(self, spread) end
            local o = cam.CFrame.Position
            local d = part.Position - o
            return {
                Distance = d.Magnitude, Origin = o, Direction = d.Unit,
                Hits = { { Position = part.Position, Instance = part,
                           Material = "Plastic", Normal = Vector3.zero, Exit = false } },
            }
        end
        -- 1) hookfunction: переживает readonly-таблицу (в 1.2 тут молча ломалось)
        if hookfunction then
            local okh, ret = pcall(hookfunction, fn, new)
            if okh and type(ret) == "function" then
                old, aimHooked = ret, true
            end
        end
        -- 2) подмена поля, если hookfunction недоступен
        if not aimHooked then
            pcall(function()
                if setreadonly then setreadonly(mod, false) end
                mod._performRaycast = new
                if setreadonly then setreadonly(mod, true) end
                old = fn
                aimHooked = (mod._performRaycast == new)
            end)
        end
        old = old or fn
        log(aimHooked and "silent aim hook ok" or "silent aim hook failed")
    else
        log("Bullet module not found")
    end
end

--===== ShootWeapon.Send: хук ровно того места, где пули уходят на сервер
-- (так делает рабочий скрипт Lutosys; _performRaycast у части версий игры уже не тот путь)
local sendCalls, sendHits, sendOk = 0, 0, false
task.spawn(function()
    local deadline = os.clock() + 45
    local fn
    while os.clock() < deadline and not fn do
        pcall(function()
            for _, obj in next, getgc() do
                if type(obj) == "table" then
                    local f = rawget(obj, "shoot")
                    if type(f) == "function" then
                        for i = 1, 32 do
                            local nm, v = debug.getupvalue(f, i)
                            if not nm then break end
                            if type(v) == "table" then
                                local inv = rawget(v, "Inventory")
                                local sw = (type(inv) == "table") and rawget(inv, "ShootWeapon") or nil
                                local sf = (type(sw) == "table") and rawget(sw, "Send") or nil
                                if type(sf) == "function" then fn = sf return end
                            end
                        end
                    end
                end
            end
        end)
        if not fn then task.wait(0.5) end
    end
    if not fn then
        log("Send hook не найден — экипируй оружие в катке и перезапусти")
        return
    end
    local old
    local ok = pcall(function()
        old = hookfunction(fn, function(...)
            sendCalls = sendCalls + 1
            local a = table.pack(...)
            local p = a[1]
            if (CFG.silent.on or CFG.misc.wallshot) and type(p) == "table" then
                local bl = rawget(p, "Bullets")
                local bullet = (type(bl) == "table") and bl[1] or nil
                local hits = bullet and rawget(bullet, "Hits") or nil
                local hit = (type(hits) == "table") and hits[1] or nil
                if hit then
                    local tgt = target(CFG.misc.wallshot or not CFG.silent.wall)
                    local part = tgt and pickPart(tgt)
                    if part then
                        hit.Instance = part
                        hit.Position = part.Position
                        sendHits = sendHits + 1
                    end
                end
            end
            return old(table.unpack(a, 1, a.n))
        end)
        sendOk = true
    end)
    log("Send hook " .. (sendOk and "ok" or "fail"))
end)

--============================== 3rd person ===========================
local hookedCam = false
do
    local fn
    if getgc then
        for _, v in next, getgc(true) do
            if type(v) == "table" then
                local ok, f = pcall(function() return rawget(v, "updateCamera") end)
                if ok and type(f) == "function" then fn = f break end
            end
        end
    end
    if fn and hookfunction then
        local ok = pcall(function()
            local old
            old = hookfunction(fn, function(cf)
                if CFG.third.on and typeof(cf) == "CFrame" then
                    cf = cf * CFrame.new(0, CFG.third.height, CFG.third.dist)
                end
                return old(cf)
            end)
            hookedCam = true
        end)
    end
    if not hookedCam then
        RunService:BindToRenderStep("zp_cam", Enum.RenderPriority.Camera.Value + 1, function()
            local cam = WS.CurrentCamera
            if CFG.third.on and cam then
                cam.CFrame = cam.CFrame * CFrame.new(0, CFG.third.height, CFG.third.dist)
            end
        end)
    end
end

-- своё тело в 3-м лице: игра гасит его через LocalTransparencyModifier
local function ownBodyVisible()
    local ch = LocalPlayer.Character
    if not ch then return end
    for _, p in ipairs(ch:GetDescendants()) do
        if p:IsA("BasePart") then
            pcall(function() p.LocalTransparencyModifier = 0 end)
        end
    end
end

--============================== antiaim ==============================
local aaYaw = 0
RunService.RenderStepped:Connect(function(dt)
    if CFG.aa.mode == 0 then return end
    local ch = LocalPlayer.Character
    local hrp = ch and ch:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    if CFG.aa.mode == 1 then
        aaYaw = (aaYaw + math.rad(CFG.aa.speed) * dt) % (math.pi * 2)
    elseif CFG.aa.mode == 2 then
        aaYaw = math.pi
    else
        aaYaw = (math.random() - 0.5) * 2.4
    end
    hrp.CFrame = CFrame.new(hrp.Position) * CFrame.Angles(0, aaYaw, 0)
end)

--============================== fly ==================================
local flyBV, flyBG
local function flyOff()
    if flyBV then flyBV:Destroy() flyBV = nil end
    if flyBG then flyBG:Destroy() flyBG = nil end
end
local function flyOn()
    local ch = LocalPlayer.Character
    local hrp = ch and ch:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    flyBV = Instance.new("BodyVelocity")
    flyBV.MaxForce = Vector3.new(9e9, 9e9, 9e9)
    flyBV.P = 12500
    flyBV.Velocity = Vector3.zero
    flyBV.Parent = hrp
    flyBG = Instance.new("BodyGyro")
    flyBG.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
    flyBG.P = 3000
    flyBG.CFrame = hrp.CFrame
    flyBG.Parent = hrp
end

RunService.Heartbeat:Connect(function()
    if not CFG.misc.fly then if flyBV then flyOff() end return end
    local ch = LocalPlayer.Character
    local hum = ch and ch:FindFirstChildOfClass("Humanoid")
    local hrp = ch and ch:FindFirstChild("HumanoidRootPart")
    if not hum or not hrp or hum.Health <= 0 then flyOff() return end
    if not flyBV or flyBV.Parent ~= hrp then flyOff() flyOn() end
    if not flyBV then return end
    local v = hum.MoveDirection * CFG.misc.flySpeed
    if UIS:IsKeyDown(Enum.KeyCode.Space) then v = v + Vector3.new(0, CFG.misc.flySpeed, 0) end
    if UIS:IsKeyDown(Enum.KeyCode.LeftControl) then v = v - Vector3.new(0, CFG.misc.flySpeed, 0) end
    flyBV.Velocity = v
    flyBG.CFrame = CFrame.new(hrp.Position)
end)

--============================== world =================================
local brightOrig, atmOrig, skyHidden, fogOrig

local function atmSnap(atm)
    return { color = atm.Color, density = atm.Density, haze = atm.Haze,
             glare = atm.Glare, decay = atm.Decay }
end

local function applyWorld()
    -- fullbright
    if CFG.bright.on then
        if not brightOrig then
            brightOrig = { b = Lighting.Brightness, a = Lighting.Ambient,
                           oa = Lighting.OutdoorAmbient, gs = Lighting.GlobalShadows }
        end
        Lighting.Brightness = math.max(Lighting.Brightness, 2)
        Lighting.Ambient = Color3.fromRGB(190, 190, 190)
        Lighting.OutdoorAmbient = Color3.fromRGB(190, 190, 190)
        Lighting.GlobalShadows = false
    elseif brightOrig then
        Lighting.Brightness = brightOrig.b
        Lighting.Ambient = brightOrig.a
        Lighting.OutdoorAmbient = brightOrig.oa
        Lighting.GlobalShadows = brightOrig.gs
        brightOrig = nil
    end

    -- пока в Lighting живёт Atmosphere, старые Lighting.Fog* не работают
    local atm = Lighting:FindFirstChildOfClass("Atmosphere")
    local skyObj = Lighting:FindFirstChildOfClass("Sky")
    if atm and not atmOrig then atmOrig = atmSnap(atm) end

    -- небо
    if CFG.sky.on then
        if skyObj and skyObj.Parent then skyHidden = skyObj skyObj.Parent = nil end
        if atm then
            atm.Color = CFG.sky.color
            atm.Density = math.max(atm.Density, 0.9)
            atm.Haze = 0
            atm.Glare = 0
        end
    else
        if skyHidden then
            pcall(function() skyHidden.Parent = Lighting end)
            skyHidden = nil
        end
        if atmOrig and not CFG.fog.on and atm then
            atm.Color = atmOrig.color
            atm.Density = atmOrig.density
            atm.Haze = atmOrig.haze
            atm.Glare = atmOrig.glare
            atm.Decay = atmOrig.decay
            atmOrig = nil
        end
    end

    -- туман
    if CFG.fog.on then
        if not fogOrig then
            fogOrig = { s = Lighting.FogStart, e = Lighting.FogEnd, c = Lighting.FogColor }
        end
        if atm then atm.Density = 0 atm.Haze = 0 end
        Lighting.FogStart = CFG.fog.start
        Lighting.FogEnd = math.max(CFG.fog.fin, CFG.fog.start + 1)
        Lighting.FogColor = CFG.fog.color
    elseif fogOrig and not CFG.sky.on then
        Lighting.FogStart = fogOrig.s
        Lighting.FogEnd = fogOrig.e
        Lighting.FogColor = fogOrig.c
        fogOrig = nil
    end
end

local function applyFps()
    if CFG.misc.fps and setfpscap then pcall(setfpscap, 999) end
end

--============================== hitbox ================================
local hbOrig = {}
local function applyHitbox()
    if not CFG.misc.hitbox then
        for part, size in pairs(hbOrig) do
            if part.Parent then pcall(function() part.Size = size end) end
        end
        hbOrig = {}
        return
    end
    local s = CFG.misc.hbSize
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and alive(plr) and isEnemy(plr) then
            local ch = plr.Character
            for _, n in ipairs({ "HumanoidRootPart", "Head", "UpperTorso", "LowerTorso" }) do
                local p = ch and ch:FindFirstChild(n)
                if p and p:IsA("BasePart") then
                    if not hbOrig[p] then hbOrig[p] = p.Size end
                    pcall(function()
                        p.Size = Vector3.new(s, s, s)
                        p.Transparency = 1
                        p.CanCollide = false
                    end)
                end
            end
        end
    end
end

--============================== movement ==============================
local function applyMove()
    local ch = LocalPlayer.Character
    local hum = ch and ch:FindFirstChildOfClass("Humanoid")
    if not hum then return end
    if CFG.misc.speed then hum.WalkSpeed = CFG.misc.speedVal end
    if CFG.misc.jump then
        pcall(function() hum.UseJumpPower = true hum.JumpPower = CFG.misc.jumpVal end)
    end
end

--============================== esp (gui) =============================
local hud = Instance.new("ScreenGui")
hud.Name = "zp_hud"
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
    local st = Instance.new("UIStroke")
    st.Thickness = 1.2
    st.Parent = o.box
    o.stroke = st
    o.box.Parent = hud

    o.hpBg = Instance.new("Frame")
    o.hpBg.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
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

    o.line = Instance.new("Frame")
    o.line.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    o.line.AnchorPoint = Vector2.new(0.5, 0.5)
    o.line.BorderSizePixel = 0
    o.line.Parent = hud

    o.list = { o.box, o.hpBg, o.hpFg, o.name, o.dist, o.line }
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
        if CFG.esp.on and plr ~= LocalPlayer and alive(plr)
            and (not CFG.esp.team or isEnemy(plr)) then
            local ch = plr.Character
            local head = ch and ch:FindFirstChild("Head")
            local root = ch and ch:FindFirstChild("HumanoidRootPart")
            local hum = ch and ch:FindFirstChildOfClass("Humanoid")
            if head and root and hum then
                local dist = (cam.CFrame.Position - head.Position).Magnitude
                local top = cam:WorldToViewportPoint(head.Position + Vector3.new(0, 0.45, 0))
                local bot = cam:WorldToViewportPoint(root.Position - Vector3.new(0, 2.6, 0))
                if dist <= CFG.esp.maxDist and top.Z > 0 and bot.Z > 0 then
                    local h = math.abs(bot.Y - top.Y)
                    local w = h * 0.45
                    if h > 8 and w > 4 then
                        if not o then o = mkEsp() espObjs[plr] = o end
                        shown[o] = true
                        espDrawn = espDrawn + 1

                        local c = visCache[ch]
                        if not c or os.clock() - c.t > 0.15 then
                            local hp = pickPart(ch)
                            c = { t = os.clock(), v = (hp and visible(ch, hp)) or false }
                            visCache[ch] = c
                        end
                        local col = c.v and CFG.esp.visColor or CFG.esp.hidColor

                        local x = top.X - w * 0.5
                        local y = top.Y
                        o.box.Visible = CFG.esp.box
                        if CFG.esp.box then
                            o.box.Position = UDim2.fromOffset(x, y)
                            o.box.Size = UDim2.fromOffset(w, h)
                            o.stroke.Color = col
                        end

                        local frac = math.clamp(hum.Health / math.max(hum.MaxHealth, 1), 0, 1)
                        o.hpBg.Visible = CFG.esp.hp
                        o.hpFg.Visible = CFG.esp.hp
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

                        o.line.Visible = CFG.esp.line
                        if CFG.esp.line then
                            local cx, cy = cam.ViewportSize.X * 0.5, cam.ViewportSize.Y
                            local tx, ty = x + w * 0.5, y + h
                            local dx, dy = tx - cx, ty - cy
                            local len = math.sqrt(dx * dx + dy * dy)
                            o.line.Position = UDim2.fromOffset((cx + tx) * 0.5, (cy + ty) * 0.5)
                            o.line.Size = UDim2.fromOffset(len, 1)
                            o.line.Rotation = math.deg(math.atan2(dy, dx))
                            o.line.BackgroundColor3 = col
                        end
                    elseif o then
                        showEsp(o, false)
                    end
                elseif o then
                    showEsp(o, false)
                end
            elseif o then
                showEsp(o, false)
            end
        elseif o then
            showEsp(o, false)
        end
    end
    for plr, o in pairs(espObjs) do
        if not shown[o] then showEsp(o, false) end
        if plr.Parent == nil then
            for _, g in ipairs(o.list) do g:Destroy() end
            espObjs[plr] = nil
        end
    end
end

--============================== chams =================================
local chamsCache = {}

local function drawChams()
    local want = {}
    for _, plr in ipairs(Players:GetPlayers()) do
        if CFG.chams.on and plr ~= LocalPlayer and alive(plr)
            and (not CFG.chams.team or isEnemy(plr)) then
            want[plr] = true
        end
    end
    for plr in pairs(chamsCache) do
        if not want[plr] then
            pcall(function() chamsCache[plr]:Destroy() end)
            chamsCache[plr] = nil
        end
    end
    for plr in pairs(want) do
        local ch = plr.Character
        local h = chamsCache[plr]
        if ch then
            if not h or h.Parent ~= ch then
                if h then pcall(function() h:Destroy() end) end
                h = Instance.new("Highlight")
                h.Name = "zp_chams"
                h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                h.Parent = ch
                chamsCache[plr] = h
            end
            h.Adornee = ch
            h.FillColor = CFG.chams.fill
            h.OutlineColor = CFG.chams.outline
            h.FillTransparency = CFG.chams.transp
            h.OutlineTransparency = 0
        end
    end
end

Players.PlayerRemoving:Connect(function(plr)
    local o = espObjs[plr]
    if o then
        for _, g in ipairs(o.list) do pcall(function() g:Destroy() end) end
        espObjs[plr] = nil
    end
    local h = chamsCache[plr]
    if h then pcall(function() h:Destroy() end) chamsCache[plr] = nil end
end)

--============================== fov circle ============================
local fovCircle
if Drawing then
    fovCircle = Drawing.new("Circle")
    fovCircle.Thickness = 1.6
    fovCircle.NumSides = 64
    fovCircle.Filled = false
    fovCircle.Transparency = 0.85
    fovCircle.Visible = false
end

--============================== status ================================
local statGui = Instance.new("ScreenGui")
statGui.Name = "zp_stat"
statGui.ResetOnSpawn = false
statGui.IgnoreGuiInset = true
statGui.DisplayOrder = 1300
statGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

local statLbl = Instance.new("TextLabel")
statLbl.Size = UDim2.new(1, -90, 0, 14)
statLbl.Position = UDim2.new(0, 70, 0, 12)
statLbl.BackgroundTransparency = 1
statLbl.Font = Enum.Font.Code
statLbl.TextSize = 11
statLbl.TextXAlignment = Enum.TextXAlignment.Left
statLbl.TextColor3 = Color3.fromRGB(178, 150, 255)
statLbl.TextStrokeTransparency = 0.3
statLbl.Text = "zero.pw v" .. VERSION
statLbl.Parent = statGui

--============================== render ================================
local warned = {}
RunService.RenderStepped:Connect(function()
    local ok, err = pcall(drawEsp)
    if not ok then
        lastErr = "esp: " .. tostring(err)
        if not warned.esp then warned.esp = true warn("[zero.pw] esp: " .. tostring(err)) end
    end
    ok, err = pcall(drawChams)
    if not ok then
        lastErr = "chams: " .. tostring(err)
        if not warned.chams then warned.chams = true warn("[zero.pw] chams: " .. tostring(err)) end
    end
    if CFG.third.on then pcall(ownBodyVisible) end
    if fovCircle then
        local on = CFG.silent.on and CFG.silent.circle and WS.CurrentCamera
        fovCircle.Visible = on and true or false
        if on then
            fovCircle.Position = WS.CurrentCamera.ViewportSize * 0.5
            fovCircle.Radius = CFG.silent.fov
            fovCircle.Color = CFG.silent.color
        end
    end
end)

task.spawn(function()
    while true do
        local others, aliveN, enemyN = 0, 0, 0
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer then
                others = others + 1
                if alive(p) then
                    aliveN = aliveN + 1
                    if isEnemy(p) then enemyN = enemyN + 1 end
                end
            end
        end
        pcall(function()
            statLbl.Text = string.format(
                "v%s | ray %s/%d | send %s/%d|%d | esp %d | en %d/%d | fog %s sky %s | %s",
                VERSION, aimHooked and "ok" or "no", aimCalls,
                sendOk and "ok" or "no", sendCalls, sendHits, espDrawn,
                enemyN, others,
                CFG.fog.on and "on" or "off", CFG.sky.on and "on" or "off",
                lastErr or ("al " .. aliveN))
        end)
        task.wait(0.4)
    end
end)

-- медленный цикл: то, что не нужно каждый кадр
task.spawn(function()
    while true do
        pcall(applyWorld)
        pcall(applyHitbox)
        pcall(applyMove)
        pcall(applyFps)
        task.wait(0.35)
    end
end)

--============================== ui kit ================================
local function inst(cls, props, parent)
    local o = Instance.new(cls)
    for k, v in pairs(props or {}) do o[k] = v end
    if parent then o.Parent = parent end
    return o
end

local ACCENT = Color3.fromRGB(126, 82, 235)
local BG     = Color3.fromRGB(14, 12, 19)
local ROW    = Color3.fromRGB(23, 20, 31)
local TXT    = Color3.fromRGB(214, 209, 230)
local DIM    = Color3.fromRGB(132, 122, 158)

--============================== кнопка ================================
local fabGui = Instance.new("ScreenGui")
fabGui.Name = "zp_fab"
fabGui.ResetOnSpawn = false
fabGui.IgnoreGuiInset = true
fabGui.DisplayOrder = 1200
fabGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

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
local fabGrad = inst("UIGradient", {
    Color = ColorSequence.new(Color3.fromRGB(126, 82, 235), Color3.fromRGB(58, 30, 110)),
    Rotation = 45,
}, fab)
fabGrad.Transparency = NumberSequence.new({
    NumberSequenceKeypoint.new(0, 0.55), NumberSequenceKeypoint.new(1, 0.85) })

--============================== меню ==================================
local menuGui = Instance.new("ScreenGui")
menuGui.Name = "zp_menu"
menuGui.ResetOnSpawn = false
menuGui.IgnoreGuiInset = true
menuGui.DisplayOrder = 1100
menuGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
menuGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

local win = inst("Frame", {
    Size = UDim2.fromOffset(430, 290),
    Position = UDim2.fromScale(0.5, 0.5),
    AnchorPoint = Vector2.new(0.5, 0.5),
    BackgroundColor3 = BG,
    BorderSizePixel = 0, Active = true,
}, menuGui)
inst("UICorner", { CornerRadius = UDim.new(0, 10) }, win)
inst("UIStroke", { Color = Color3.fromRGB(60, 42, 92), Thickness = 1 }, win)

local sidebar = inst("Frame", {
    Size = UDim2.new(0, 104, 1, -10),
    Position = UDim2.fromOffset(5, 5),
    BackgroundColor3 = Color3.fromRGB(19, 16, 26),
    BorderSizePixel = 0,
}, win)
inst("UICorner", { CornerRadius = UDim.new(0, 8) }, sidebar)

local brand = inst("TextLabel", {
    Size = UDim2.new(1, -14, 0, 22), Position = UDim2.fromOffset(10, 4),
    BackgroundTransparency = 1, Text = "zero.pw",
    Font = Enum.Font.GothamBlack, TextSize = 14,
    TextColor3 = Color3.fromRGB(200, 175, 255),
    TextXAlignment = Enum.TextXAlignment.Left,
}, sidebar)
inst("TextLabel", {
    Size = UDim2.new(1, -14, 0, 14), Position = UDim2.fromOffset(10, 22),
    BackgroundTransparency = 1, Text = "v" .. VERSION .. "  bloxstrike",
    Font = Enum.Font.Gotham, TextSize = 9, TextColor3 = DIM,
    TextXAlignment = Enum.TextXAlignment.Left,
}, sidebar)

local closeBtn = inst("TextButton", {
    Size = UDim2.fromOffset(22, 22), Position = UDim2.new(1, -28, 0, 6),
    BackgroundTransparency = 1, Text = "x", TextSize = 15,
    Font = Enum.Font.GothamBold, TextColor3 = DIM, AutoButtonColor = false,
}, win)

local pages = inst("Frame", {
    Size = UDim2.new(1, -120, 1, -12),
    Position = UDim2.fromOffset(114, 6),
    BackgroundTransparency = 1,
}, win)

local navList = inst("Frame", {
    Size = UDim2.new(1, -10, 1, -44), Position = UDim2.fromOffset(4, 40),
    BackgroundTransparency = 1,
}, sidebar)
inst("UIListLayout", { Padding = UDim.new(0, 3), SortOrder = Enum.SortOrder.LayoutOrder }, navList)

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
        b.TextXAlignment = Enum.TextXAlignment.Left
    end
end

local function tab(name)
    local b = inst("TextButton", {
        Size = UDim2.new(1, 0, 0, 24), BackgroundColor3 = Color3.fromRGB(21, 18, 28),
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
        Size = UDim2.new(1, -4, 0, 26), BackgroundColor3 = ROW,
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
        Size = UDim2.new(1, -4, 0, 36), BackgroundColor3 = ROW, BorderSizePixel = 0,
    }, parent)
    inst("UICorner", { CornerRadius = UDim.new(0, 6) }, row)
    local lbl = inst("TextLabel", {
        Size = UDim2.new(1, -12, 0, 15), Position = UDim2.fromOffset(9, 2),
        BackgroundTransparency = 1, Text = text, TextSize = 11,
        Font = Enum.Font.Gotham, TextColor3 = TXT,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, row)
    local track = inst("Frame", {
        Size = UDim2.new(1, -18, 0, 5), Position = UDim2.fromOffset(9, 25),
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
            drag = true fromX(i.Position.X)
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

local function color(parent, text, tbl, key, cb)
    local row = inst("Frame", {
        Size = UDim2.new(1, -4, 0, 50), BackgroundColor3 = ROW, BorderSizePixel = 0,
    }, parent)
    inst("UICorner", { CornerRadius = UDim.new(0, 6) }, row)
    inst("TextLabel", {
        Size = UDim2.new(1, -60, 0, 15), Position = UDim2.fromOffset(9, 2),
        BackgroundTransparency = 1, Text = text, TextSize = 11,
        Font = Enum.Font.Gotham, TextColor3 = TXT,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, row)
    local sw = inst("Frame", {
        Size = UDim2.fromOffset(20, 12), Position = UDim2.new(1, -28, 0, 4),
        BackgroundColor3 = tbl[key], BorderSizePixel = 0,
    }, row)
    inst("UICorner", { CornerRadius = UDim.new(0, 3) }, sw)

    local comps = { tbl[key].R, tbl[key].G, tbl[key].B }
    local tracks = {}
    for i = 1, 3 do
        local t = inst("Frame", {
            Size = UDim2.new(1 / 3, -10, 0, 7),
            Position = UDim2.new((i - 1) / 3, 9, 0, 34),
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
        if cb then pcall(cb, tbl[key]) end
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

local function cycle(parent, text, tbl, key, list)
    local row = inst("TextButton", {
        Size = UDim2.new(1, -4, 0, 26), BackgroundColor3 = ROW,
        BorderSizePixel = 0, Text = "", AutoButtonColor = false, Active = true,
    }, parent)
    inst("UICorner", { CornerRadius = UDim.new(0, 6) }, row)
    local lbl = inst("TextLabel", {
        Size = UDim2.new(1, -12, 1, 0), Position = UDim2.fromOffset(9, 0),
        BackgroundTransparency = 1, Text = text .. ": " .. tostring(tbl[key]),
        TextSize = 12, Font = Enum.Font.Gotham, TextColor3 = TXT,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, row)
    local i = 1
    for k, v in ipairs(list) do if v == tbl[key] then i = k end end
    row.MouseButton1Click:Connect(function()
        i = i % #list + 1
        tbl[key] = list[i]
        lbl.Text = text .. ": " .. tostring(list[i])
    end)
    return row
end

--============================== tabs =================================
for _, n in ipairs({ "Rage", "Visuals", "Misc" }) do tab(n) end
local Rage, Vis, Misc = frames.Rage, frames.Visuals, frames.Misc

label(Rage, "SILENT AIM")
toggle(Rage, "Silent aim", CFG.silent, "on")
toggle(Rage, "FOV circle", CFG.silent, "circle")
slider(Rage, "FOV", CFG.silent, "fov", 10, 700, true)
slider(Rage, "Hit chance %", CFG.silent, "chance", 0, 100, true)
cycle(Rage, "Part", CFG.silent, "part",
      { "Head", "UpperTorso", "HumanoidRootPart", "LowerTorso", "Random" })
toggle(Rage, "Wall check", CFG.silent, "wall")
toggle(Rage, "Team check", CFG.silent, "team")
color(Rage, "FOV color", CFG.silent, "color")

label(Rage, "3RD PERSON")
toggle(Rage, "Third person", CFG.third, "on")
slider(Rage, "Distance", CFG.third, "dist", 2, 30, false)
slider(Rage, "Height", CFG.third, "height", -3, 6, false)

label(Rage, "ANTI AIM")
cycle(Rage, "Mode", CFG.aa, "mode", { 0, 1, 2, 3 })
slider(Rage, "Spin speed", CFG.aa, "speed", 30, 900, true)

label(Vis, "ESP")
toggle(Vis, "ESP", CFG.esp, "on")
toggle(Vis, "Box", CFG.esp, "box")
toggle(Vis, "Name", CFG.esp, "name")
toggle(Vis, "Distance", CFG.esp, "dist")
toggle(Vis, "Health bar", CFG.esp, "hp")
toggle(Vis, "Snapline", CFG.esp, "line")
toggle(Vis, "Team check", CFG.esp, "team")
slider(Vis, "Max distance", CFG.esp, "maxDist", 50, 2000, true)
color(Vis, "Visible color", CFG.esp, "visColor")
color(Vis, "Hidden color", CFG.esp, "hidColor")

label(Vis, "CHAMS")
toggle(Vis, "Chams", CFG.chams, "on")
toggle(Vis, "Team check", CFG.chams, "team")
color(Vis, "Fill color", CFG.chams, "fill")
color(Vis, "Outline color", CFG.chams, "outline")
slider(Vis, "Fill transparency", CFG.chams, "transp", 0, 1, false)

label(Vis, "WORLD")
toggle(Vis, "Fullbright", CFG.bright, "on")
toggle(Vis, "Fog", CFG.fog, "on")
slider(Vis, "Fog start", CFG.fog, "start", 0, 1000, true)
slider(Vis, "Fog end", CFG.fog, "fin", 10, 5000, true)
color(Vis, "Fog color", CFG.fog, "color")
toggle(Vis, "Sky", CFG.sky, "on")
color(Vis, "Sky color", CFG.sky, "color")

label(Misc, "COMBAT")
toggle(Misc, "Wall shot", CFG.misc, "wallshot")
slider(Misc, "Hitbox size", CFG.misc, "hbSize", 2, 20, true)
toggle(Misc, "Hitbox expander", CFG.misc, "hitbox")

label(Misc, "MOVEMENT")
toggle(Misc, "Fly", CFG.misc, "fly")
slider(Misc, "Fly speed", CFG.misc, "flySpeed", 10, 400, true)
toggle(Misc, "Speed hack", CFG.misc, "speed")
slider(Misc, "WalkSpeed", CFG.misc, "speedVal", 16, 200, true)
toggle(Misc, "Jump", CFG.misc, "jump")
slider(Misc, "JumpPower", CFG.misc, "jumpVal", 50, 300, true)

label(Misc, "SYSTEM")
toggle(Misc, "Unlock FPS", CFG.misc, "fps", applyFps)

select("Rage")

--============================== window ================================
local dragging, dragStart, startPos
win.InputBegan:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1
        or i.UserInputType == Enum.UserInputType.Touch then
        -- только верхняя полоса 26px, иначе палец тащит окно вместо тапа по тумблеру
        if (i.Position.Y - win.AbsolutePosition.Y) > 26 then return end
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
        or i.UserInputType == Enum.UserInputType.Touch then
        dragging = false
    end
end)

closeBtn.MouseButton1Click:Connect(function() win.Visible = false end)

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
        if moved < 12 then win.Visible = not win.Visible end
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
        win.Visible = not win.Visible
    end
end)

applyWorld()
log("loaded v" .. VERSION .. " / Z button")
print(string.format("[zero.pw] aim hook: %s | players: %d", tostring(aimHooked), #Players:GetPlayers()))
