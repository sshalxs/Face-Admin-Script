--[[  zero.pw  |  BloxStrike  (place 114234929420007)
      rage : silent aim / 3rd person / antiaim
      vis  : esp / chams / fog + color / sky + color
      misc : wall shot / fly
      toggle menu: RightShift
]]

--============================== services ==============================
local Players       = game:GetService("Players")
local RS            = game:GetService("ReplicatedStorage")
local WS            = game:GetService("Workspace")
local RunService    = game:GetService("RunService")
local Lighting      = game:GetService("Lighting")
local UIS           = game:GetService("UserInputService")
local TweenService  = game:GetService("TweenService")
local LocalPlayer   = Players.LocalPlayer

local function cdr(x) if cloneref then local ok, r = pcall(cloneref, x) if ok then return r end end return x end
Players = cdr(Players); RS = cdr(RS); WS = cdr(WS); RunService = cdr(RunService)
Lighting = cdr(Lighting); UIS = cdr(UIS); LocalPlayer = Players.LocalPlayer

--============================== config ===============================
local CFG = {
    silent = {
        enabled   = false,
        fov       = 120,      -- радиус в пикселях от центра
        chance    = 100,      -- шанс попадания, %
        part      = "Head",
        wallcheck = true,     -- цель только в прямой видимости
        teamcheck = true,
        circle    = true,
        color     = Color3.fromRGB(140, 90, 255),
    },
    third = {
        enabled  = false,
        distance = 9,
        height   = 1.5,
    },
    antiaim = {
        mode  = 0,            -- 0 off / 1 spin / 2 back / 3 jitter
        speed = 240,          -- градусов в секунду для spin
    },
    esp = {
        enabled  = false,
        box      = true,
        name     = true,
        dist     = true,
        hp       = true,
        line     = false,
        teamcheck= true,
        maxDist  = 500,
        visColor = Color3.fromRGB(120, 255, 160),
        hidColor = Color3.fromRGB(255, 70, 70),
    },
    chams = {
        enabled = false,
        fill    = Color3.fromRGB(160, 60, 255),
        outline = Color3.fromRGB(255, 255, 255),
        transp  = 0.55,
        teamcheck = true,
    },
    fog = {
        enabled = false,
        start   = 0,
        fin     = 350,
        color   = Color3.fromRGB(120, 60, 220),
    },
    sky = {
        enabled = false,
        color   = Color3.fromRGB(20, 12, 40),
    },
    misc = {
        wallshot = false,
        fly      = false,
        flySpeed = 60,
    },
}

if getgenv then getgenv().ZEROPW = CFG end

local function notify(txt)
    if setclipboard then end
    print("[zero.pw] " .. tostring(txt))
    if game:GetService("StarterGui") then
        pcall(function()
            game:GetService("StarterGui"):SetCore("SendNotification", {
                Title = "zero.pw", Text = tostring(txt), Duration = 3,
            })
        end)
    end
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

local function isEnemy(plr)
    local lt = LocalPlayer:GetAttribute("Team")
    local pt = plr:GetAttribute("Team")
    if not lt or not pt then return true end
    if WS:GetAttribute("Gamemode") == "Deathmatch" then return true end
    return lt ~= pt
end

local rayIgnore
do
    local ok, mod = pcall(function()
        return require(RS:WaitForChild("Components"):WaitForChild("Common"):WaitForChild("GetRayIgnore"))
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
    return nil
end

-- ближайший к центру экрана враг в FOV
local function target(ignoreWalls)
    local cam = WS.CurrentCamera
    if not cam then return nil end
    local vp = cam.ViewportSize
    local cx, cy = vp.X * 0.5, vp.Y * 0.5
    local best, bestD = nil, CFG.silent.fov * CFG.silent.fov
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and alive(plr) then
            local ch = plr.Character
            if ch and (not CFG.silent.teamcheck or isEnemy(plr)) then
                local part = pickPart(ch)
                if part then
                    local sp, onScreen = cam:WorldToViewportPoint(part.Position)
                    if onScreen then
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
local BulletMod, oldRaycast
do
    local ok, mod = pcall(function()
        return require(RS:WaitForChild("Components"):WaitForChild("Weapon")
            :WaitForChild("Classes"):WaitForChild("Bullet"))
    end)
    if ok and type(mod) == "table" and type(mod._performRaycast) == "function" then
        BulletMod = mod
        oldRaycast = mod._performRaycast
    else
        notify("Bullet module not found - silent aim off")
    end
end

if BulletMod then
    local newRaycast = function(self, spread)
        local active = CFG.silent.enabled or CFG.misc.wallshot
        if not active then return oldRaycast(self, spread) end
        if math.random(1, 100) > CFG.silent.chance then return oldRaycast(self, spread) end

        local tgt = target(CFG.misc.wallshot or not CFG.silent.wallcheck)
        if not tgt then return oldRaycast(self, spread) end
        local part = pickPart(tgt)
        if not part then return oldRaycast(self, spread) end

        local cam = WS.CurrentCamera
        if not cam then return oldRaycast(self, spread) end
        local origin = cam.CFrame.Position
        local dir = part.Position - origin
        return {
            Distance  = dir.Magnitude,
            Origin    = origin,
            Direction = dir.Unit,
            Hits = { {
                Position = part.Position,
                Instance = part,
                Material = "Plastic",
                Normal   = Vector3.zero,
                Exit     = false,
            } },
        }
    end
    pcall(function() if setreadonly then setreadonly(BulletMod, false) end end)
    BulletMod._performRaycast = newRaycast
    pcall(function() if setreadonly then setreadonly(BulletMod, true) end end)
end

--============================== 3rd person ===========================
local oldUpdateCam
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
            oldUpdateCam = hookfunction(fn, function(cf)
                if CFG.third.enabled and typeof(cf) == "CFrame" then
                    cf = cf * CFrame.new(0, CFG.third.height, CFG.third.distance)
                end
                return oldUpdateCam(cf)
            end)
        end)
        if not ok then oldUpdateCam = nil end
    end
    if not oldUpdateCam then
        -- запасной путь, если функцию камеры не нашли
        RunService:BindToRenderStep("zp_cam", Enum.RenderPriority.Camera.Value + 1, function()
            local cam = WS.CurrentCamera
            if CFG.third.enabled and cam then
                cam.CFrame = cam.CFrame * CFrame.new(0, CFG.third.height, CFG.third.distance)
            end
        end)
    end
end

--============================== antiaim ==============================
local aaYaw = 0
RunService.RenderStepped:Connect(function(dt)
    if CFG.antiaim.mode == 0 then return end
    local ch = LocalPlayer.Character
    local hrp = ch and ch:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    if CFG.antiaim.mode == 1 then
        aaYaw = (aaYaw + math.rad(CFG.antiaim.speed) * dt) % (math.pi * 2)
    elseif CFG.antiaim.mode == 2 then
        aaYaw = math.pi
    else
        aaYaw = (math.random() - 0.5) * 2.4
    end
    hrp.CFrame = CFrame.new(hrp.Position) * CFrame.Angles(0, aaYaw, 0)
end)

--============================== fly ==================================
local flyBV, flyBG, flyHum
local function flyOff()
    if flyBV then flyBV:Destroy() flyBV = nil end
    if flyBG then flyBG:Destroy() flyBG = nil end
    flyHum = nil
end

local function flyOn()
    local ch = LocalPlayer.Character
    local hrp = ch and ch:FindFirstChild("HumanoidRootPart")
    local hum = ch and ch:FindFirstChildOfClass("Humanoid")
    if not hrp or not hum then return end
    flyHum = hum
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
    if not flyBV then flyOn() end
    if not flyBV then return end
    local hum = flyHum
    if not hum or not hum.Parent or hum.Health <= 0 then flyOff() return end
    local dir = hum.MoveDirection
    local v = dir * CFG.misc.flySpeed
    if UIS:IsKeyDown(Enum.KeyCode.Space) then v = v + Vector3.new(0, CFG.misc.flySpeed, 0) end
    if UIS:IsKeyDown(Enum.KeyCode.LeftControl) then v = v - Vector3.new(0, CFG.misc.flySpeed, 0) end
    if flyBV.Parent ~= hum.Parent:FindFirstChild("HumanoidRootPart") then flyOff() return end
    flyBV.Velocity = v
    flyBG.CFrame = CFrame.new(hum.Parent.HumanoidRootPart.Position)
end)

--============================== esp ==================================
local Drawing = Drawing
local espCache = {}
local fovCircle

if Drawing then
    fovCircle = Drawing.new("Circle")
    fovCircle.Thickness = 1.6
    fovCircle.NumSides = 64
    fovCircle.Filled = false
    fovCircle.Transparency = 0.85
    fovCircle.Visible = false
end

local function newEsp()
    return {
        box  = Drawing.new("Square"),
        hpBg = Drawing.new("Square"),
        hpFg = Drawing.new("Square"),
        name = Drawing.new("Text"),
        dist = Drawing.new("Text"),
        line = Drawing.new("Line"),
    }
end

local function hideEsp(e)
    e.box.Visible, e.hpBg.Visible, e.hpFg.Visible = false, false, false
    e.name.Visible, e.dist.Visible, e.line.Visible = false, false, false
end

local visCache = {}

local function drawEsp()
    local cam = WS.CurrentCamera
    if not cam then return end
    local d = LocalPlayer.Character

    for _, plr in ipairs(Players:GetPlayers()) do
        local e = espCache[plr]
        if plr ~= LocalPlayer and CFG.esp.enabled and alive(plr)
            and (not CFG.esp.teamcheck or isEnemy(plr)) then
            local ch = plr.Character
            local head = ch:FindFirstChild("Head")
            local root = ch:FindFirstChild("HumanoidRootPart")
            local hum = ch:FindFirstChildOfClass("Humanoid")
            if head and root and hum then
                local dist = (cam.CFrame.Position - head.Position).Magnitude
                if dist <= CFG.esp.maxDist then
                    if not e then e = newEsp() espCache[plr] = e end
                    local c = visCache[ch]
                    if not c or os.clock() - c.t > 0.15 then
                        local hp = pickPart(ch)
                        c = { t = os.clock(), v = hp and visible(ch, hp) or false }
                        visCache[ch] = c
                    end
                    local col = c.v and CFG.esp.visColor or CFG.esp.hidColor

                    local hpos = cam:WorldToViewportPoint(head.Position + Vector3.new(0, 0.45, 0))
                    local fpos = cam:WorldToViewportPoint(root.Position - Vector3.new(0, 2.6, 0))
                    if hpos.Z > 0 and fpos.Z > 0 then
                        local h = math.abs(fpos.Y - hpos.Y)
                        local w = h * 0.45
                        local x = hpos.X - w * 0.5
                        local y = hpos.Y
                        if w > 3 and h > 6 then
                            e.box.Size = Vector2.new(w, h)
                            e.box.Position = Vector2.new(x, y)
                            e.box.Color = col
                            e.box.Thickness = 1
                            e.box.Filled = false
                            e.box.Visible = CFG.esp.box

                            local frac = math.clamp(hum.Health / math.max(hum.MaxHealth, 1), 0, 1)
                            local bh = h * frac
                            e.hpBg.Size = Vector2.new(3, h)
                            e.hpBg.Position = Vector2.new(x - 6, y)
                            e.hpBg.Color = Color3.fromRGB(20, 20, 20)
                            e.hpBg.Filled = true
                            e.hpBg.Visible = CFG.esp.hp

                            e.hpFg.Size = Vector2.new(3, bh)
                            e.hpFg.Position = Vector2.new(x - 6, y + (h - bh))
                            e.hpFg.Color = Color3.fromRGB(
                                math.floor(255 * (1 - frac)),
                                math.floor(255 * frac), 40)
                            e.hpFg.Filled = true
                            e.hpFg.Visible = CFG.esp.hp

                            e.name.Text = plr.Name
                            e.name.Position = Vector2.new(x + w * 0.5, y - 15)
                            e.name.Size = 14
                            e.name.Center = true
                            e.name.Outline = true
                            e.name.Color = col
                            e.name.Visible = CFG.esp.name

                            e.dist.Text = string.format("%d m", math.floor(dist))
                            e.dist.Position = Vector2.new(x + w * 0.5, y + h + 2)
                            e.dist.Size = 13
                            e.dist.Center = true
                            e.dist.Outline = true
                            e.dist.Color = col
                            e.dist.Visible = CFG.esp.dist

                            if CFG.esp.line then
                                e.line.From = Vector2.new(cam.ViewportSize.X * 0.5,
                                                          cam.ViewportSize.Y)
                                e.line.To = Vector2.new(x + w * 0.5, y + h)
                                e.line.Color = col
                                e.line.Thickness = 1
                                e.line.Visible = true
                            else
                                e.line.Visible = false
                            end
                        else
                            hideEsp(e)
                        end
                    else
                        hideEsp(e)
                    end
                elseif e then
                    hideEsp(e)
                end
            elseif e then
                hideEsp(e)
            end
        elseif e then
            hideEsp(e)
        end
    end
end

--============================== chams ================================
local chamsCache = {}
local function drawChams()
    local want = {}
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and CFG.chams.enabled and alive(plr)
            and (not CFG.chams.teamcheck or isEnemy(plr)) then
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

--============================== fog / sky ============================
local fogOrig, skyPart

local function applyFog()
    if CFG.fog.enabled then
        if not fogOrig then
            fogOrig = { s = Lighting.FogStart, e = Lighting.FogEnd, c = Lighting.FogColor }
        end
        Lighting.FogStart = CFG.fog.start
        Lighting.FogEnd   = math.max(CFG.fog.fin, CFG.fog.start + 1)
        Lighting.FogColor = CFG.fog.color
    elseif fogOrig then
        Lighting.FogStart, Lighting.FogEnd, Lighting.FogColor =
            fogOrig.s, fogOrig.e, fogOrig.c
        fogOrig = nil
    end
end

local function applySky()
    if CFG.sky.enabled then
        if not skyPart then
            skyPart = Instance.new("Part")
            skyPart.Name = "zp_sky"
            skyPart.Shape = Enum.PartType.Ball
            skyPart.Size = Vector3.new(1, 1, 1) * 6000
            skyPart.Material = Enum.Material.SmoothPlastic
            skyPart.Anchored = true
            skyPart.CanCollide = false
            skyPart.CanQuery = false
            skyPart.CanTouch = false
            skyPart.CastShadow = false
            skyPart.TopSurface = Enum.SurfaceType.Smooth
            skyPart.BottomSurface = Enum.SurfaceType.Smooth
            skyPart.Parent = WS.CurrentCamera or WS
        end
        skyPart.Color = CFG.sky.color
        skyPart.CFrame = CFrame.new(WS.CurrentCamera.CFrame.Position)
    elseif skyPart then
        skyPart:Destroy()
        skyPart = nil
    end
end

--============================== render ===============================
RunService.RenderStepped:Connect(function()
    pcall(drawEsp)
    pcall(drawChams)
    if fovCircle then
        local on = CFG.silent.enabled and CFG.silent.circle
        fovCircle.Visible = on
        if on and WS.CurrentCamera then
            fovCircle.Position = WS.CurrentCamera.ViewportSize * 0.5
            fovCircle.Radius = CFG.silent.fov
            fovCircle.Color = CFG.silent.color
        end
    end
    if CFG.sky.enabled and skyPart and WS.CurrentCamera then
        if skyPart.Parent ~= WS.CurrentCamera then
            skyPart.Parent = WS.CurrentCamera
        end
        skyPart.CFrame = CFrame.new(WS.CurrentCamera.CFrame.Position)
    end
end)

--============================== ui ===================================
local function new(cls, props, parent)
    local o = Instance.new(cls)
    for k, v in pairs(props or {}) do o[k] = v end
    if parent then o.Parent = parent end
    return o
end

local gui = new("ScreenGui", {
    Name = "zp_menu",
    ResetOnSpawn = false,
    IgnoreGuiInset = true,
    DisplayOrder = 999,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
}, LocalPlayer:WaitForChild("PlayerGui"))

local main = new("Frame", {
    Name = "main",
    Size = UDim2.fromOffset(420, 300),
    Position = UDim2.fromScale(0.5, 0.5),
    AnchorPoint = Vector2.new(0.5, 0.5),
    BackgroundColor3 = Color3.fromRGB(16, 14, 22),
    BorderSizePixel = 0,
    Active = true,
}, gui)
new("UICorner", { CornerRadius = UDim.new(0, 8) }, main)
new("UIStroke", { Color = Color3.fromRGB(90, 55, 160), Thickness = 1 }, main)

local title = new("Frame", {
    Size = UDim2.new(1, 0, 0, 30),
    BackgroundColor3 = Color3.fromRGB(24, 20, 34),
    BorderSizePixel = 0,
}, main)
new("UICorner", { CornerRadius = UDim.new(0, 8) }, title)
new("TextLabel", {
    Size = UDim2.new(1, -34, 1, 0), Position = UDim2.fromOffset(10, 0),
    BackgroundTransparency = 1, Text = "zero.pw  |  bloxstrike",
    TextColor3 = Color3.fromRGB(200, 180, 255), TextSize = 13,
    Font = Enum.Font.GothamBold, TextXAlignment = Enum.TextXAlignment.Left,
}, title)
local closeBtn = new("TextButton", {
    Size = UDim2.fromOffset(28, 28), Position = UDim2.new(1, -30, 0, 1),
    BackgroundTransparency = 1, Text = "x", TextSize = 14,
    TextColor3 = Color3.fromRGB(200, 180, 255), Font = Enum.Font.GothamBold,
}, title)

local tabsBar = new("Frame", {
    Size = UDim2.new(1, -16, 0, 26), Position = UDim2.fromOffset(8, 34),
    BackgroundTransparency = 1,
}, main)
new("UIListLayout", {
    FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 4),
    SortOrder = Enum.SortOrder.LayoutOrder,
}, tabsBar)

local content = new("ScrollingFrame", {
    Size = UDim2.new(1, -16, 1, -74), Position = UDim2.fromOffset(8, 64),
    BackgroundTransparency = 1, ScrollBarThickness = 3,
    CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y,
    ScrollingDirection = Enum.ScrollingDirection.Y,
}, main)
new("UIListLayout", {
    Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder,
}, content)

local tabFrames, tabButtons = {}, {}
local currentTab

local function selectTab(name)
    currentTab = name
    for n, f in pairs(tabFrames) do f.Visible = (n == name) end
    for n, b in pairs(tabButtons) do
        b.BackgroundColor3 = (n == name) and Color3.fromRGB(60, 36, 110)
                                              or Color3.fromRGB(26, 22, 36)
        b.TextColor3 = (n == name) and Color3.fromRGB(235, 225, 255)
                                      or Color3.fromRGB(140, 130, 165)
    end
end

local function makeTab(name)
    local b = new("TextButton", {
        Size = UDim2.fromOffset(84, 24), BackgroundColor3 = Color3.fromRGB(26, 22, 36),
        BorderSizePixel = 0, Text = name, TextSize = 12, Font = Enum.Font.Gotham,
        TextColor3 = Color3.fromRGB(160, 150, 185), AutoButtonColor = false,
    }, tabsBar)
    new("UICorner", { CornerRadius = UDim.new(0, 5) }, b)
    local f = new("Frame", {
        Size = UDim2.new(1, 0, 0, 0), BackgroundTransparency = 1,
        AutomaticSize = Enum.AutomaticSize.Y,
    }, content)
    new("UIListLayout", { Padding = UDim.new(0, 4) }, f)
    tabFrames[name] = f
    tabButtons[name] = b
    b.MouseButton1Click:Connect(function() selectTab(name) end)
end

local function addToggle(parent, text, tbl, key, onChange)
    local row = new("TextButton", {
        Size = UDim2.new(1, -4, 0, 26), BackgroundColor3 = Color3.fromRGB(24, 21, 32),
        BorderSizePixel = 0, Text = "", AutoButtonColor = false,
    }, parent)
    new("UICorner", { CornerRadius = UDim.new(0, 5) }, row)
    new("TextLabel", {
        Size = UDim2.new(1, -50, 1, 0), Position = UDim2.fromOffset(8, 0),
        BackgroundTransparency = 1, Text = text, TextSize = 12, Font = Enum.Font.Gotham,
        TextColor3 = Color3.fromRGB(210, 205, 225), TextXAlignment = Enum.TextXAlignment.Left,
    }, row)
    local sw = new("Frame", {
        Size = UDim2.fromOffset(30, 15), Position = UDim2.new(1, -38, 0.5, -7),
        BackgroundColor3 = Color3.fromRGB(45, 40, 60), BorderSizePixel = 0,
    }, row)
    new("UICorner", { CornerRadius = UDim.new(1, 0) }, sw)
    local knob = new("Frame", {
        Size = UDim2.fromOffset(11, 11), Position = UDim2.fromOffset(2, 2),
        BackgroundColor3 = Color3.fromRGB(200, 200, 210), BorderSizePixel = 0,
    }, sw)
    new("UICorner", { CornerRadius = UDim.new(1, 0) }, knob)

    local function refresh()
        local on = tbl[key]
        sw.BackgroundColor3 = on and Color3.fromRGB(90, 50, 160) or Color3.fromRGB(45, 40, 60)
        knob.Position = UDim2.fromOffset(on and 17 or 2, 2)
    end
    refresh()
    row.MouseButton1Click:Connect(function()
        tbl[key] = not tbl[key]
        refresh()
        if onChange then onChange(tbl[key]) end
    end)
    return row
end

local function addSlider(parent, text, tbl, key, min, max, isInt, onChange)
    local row = new("Frame", {
        Size = UDim2.new(1, -4, 0, 34), BackgroundColor3 = Color3.fromRGB(24, 21, 32),
        BorderSizePixel = 0,
    }, parent)
    new("UICorner", { CornerRadius = UDim.new(0, 5) }, row)
    local lbl = new("TextLabel", {
        Size = UDim2.new(1, -10, 0, 16), Position = UDim2.fromOffset(8, 1),
        BackgroundTransparency = 1, Text = text, TextSize = 11,
        Font = Enum.Font.Gotham, TextColor3 = Color3.fromRGB(205, 200, 220),
        TextXAlignment = Enum.TextXAlignment.Left,
    }, row)
    local track = new("Frame", {
        Size = UDim2.new(1, -16, 0, 5), Position = UDim2.fromOffset(8, 24),
        BackgroundColor3 = Color3.fromRGB(45, 40, 60), BorderSizePixel = 0,
    }, row)
    new("UICorner", { CornerRadius = UDim.new(1, 0) }, track)
    local fill = new("Frame", {
        Size = UDim2.new(0, 0, 1, 0), BackgroundColor3 = Color3.fromRGB(110, 65, 200),
        BorderSizePixel = 0,
    }, track)
    new("UICorner", { CornerRadius = UDim.new(1, 0) }, fill)

    local function set(v)
        v = math.clamp(v, min, max)
        if isInt then v = math.floor(v + 0.5) end
        tbl[key] = v
        local rel = (v - min) / math.max(max - min, 1e-6)
        fill.Size = UDim2.new(rel, 0, 1, 0)
        lbl.Text = text .. "  " .. (isInt and tostring(math.floor(v))
                                         or string.format("%.2f", v))
        if onChange then onChange(v) end
    end
    set(tbl[key])

    local dragging = false
    local function fromX(x)
        local rel = (x - track.AbsolutePosition.X) / math.max(track.AbsoluteSize.X, 1)
        set(min + math.clamp(rel, 0, 1) * (max - min))
    end
    track.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1
            or i.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            fromX(i.Position.X)
        end
    end)
    track.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1
            or i.UserInputType == Enum.UserInputType.Touch then dragging = false end
    end)
    UIS.InputChanged:Connect(function(i)
        if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement
            or i.UserInputType == Enum.UserInputType.Touch) then
            fromX(i.Position.X)
        end
    end)
    return row
end

local function addColor(parent, text, tbl, key, onChange)
    local row = new("Frame", {
        Size = UDim2.new(1, -4, 0, 48), BackgroundColor3 = Color3.fromRGB(24, 21, 32),
        BorderSizePixel = 0,
    }, parent)
    new("UICorner", { CornerRadius = UDim.new(0, 5) }, row)
    new("TextLabel", {
        Size = UDim2.new(1, -50, 0, 16), Position = UDim2.fromOffset(8, 1),
        BackgroundTransparency = 1, Text = text, TextSize = 11,
        Font = Enum.Font.Gotham, TextColor3 = Color3.fromRGB(205, 200, 220),
        TextXAlignment = Enum.TextXAlignment.Left,
    }, row)
    local sw = new("Frame", {
        Size = UDim2.fromOffset(18, 12), Position = UDim2.new(1, -26, 0, 3),
        BackgroundColor3 = tbl[key], BorderSizePixel = 0,
    }, row)
    new("UICorner", { CornerRadius = UDim.new(0, 3) }, sw)

    local chans = { "R", "G", "B" }
    local comps = { tbl[key].R, tbl[key].G, tbl[key].B }
    local tracks = {}
    for i = 1, 3 do
        local t = new("Frame", {
            Size = UDim2.new(1 / 3, -9, 0, 6),
            Position = UDim2.new((i - 1) / 3, 8, 0, 32),
            BackgroundColor3 = Color3.fromRGB(45, 40, 60), BorderSizePixel = 0,
        }, row)
        new("UICorner", { CornerRadius = UDim.new(1, 0) }, t)
        local f = new("Frame", {
            Size = UDim2.new(comps[i], 0, 1, 0), BorderSizePixel = 0,
            BackgroundColor3 = (i == 1 and Color3.fromRGB(220, 60, 60))
                or (i == 2 and Color3.fromRGB(60, 220, 60)) or Color3.fromRGB(60, 90, 220),
        }, t)
        new("UICorner", { CornerRadius = UDim.new(1, 0) }, f)
        tracks[i] = { track = t, fill = f }
    end

    local function push()
        tbl[key] = Color3.fromRGB(comps[1], comps[2], comps[3])
        sw.BackgroundColor3 = tbl[key]
        for i = 1, 3 do tracks[i].fill.Size = UDim2.new(comps[i] / 255, 0, 1, 0) end
        if onChange then onChange(tbl[key]) end
    end

    local drag = 0
    for i = 1, 3 do
        local t = tracks[i].track
        t.InputBegan:Connect(function(inp)
            if inp.UserInputType == Enum.UserInputType.MouseButton1
                or inp.UserInputType == Enum.UserInputType.Touch then
                drag = i
                local rel = (inp.Position.X - t.AbsolutePosition.X) / math.max(t.AbsoluteSize.X, 1)
                comps[i] = math.floor(math.clamp(rel, 0, 1) * 255)
                push()
            end
        end)
    end
    UIS.InputChanged:Connect(function(inp)
        if drag == 0 then return end
        if inp.UserInputType == Enum.UserInputType.MouseMovement
            or inp.UserInputType == Enum.UserInputType.Touch then
            local t = tracks[drag].track
            local rel = (inp.Position.X - t.AbsolutePosition.X) / math.max(t.AbsoluteSize.X, 1)
            comps[drag] = math.floor(math.clamp(rel, 0, 1) * 255)
            push()
        end
    end)
    UIS.InputEnded:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1
            or inp.UserInputType == Enum.UserInputType.Touch then drag = 0 end
    end)
    return row
end

local function addLabel(parent, text)
    new("TextLabel", {
        Size = UDim2.new(1, -4, 0, 18), BackgroundTransparency = 1, Text = text,
        TextSize = 10, Font = Enum.Font.Gotham,
        TextColor3 = Color3.fromRGB(120, 105, 150),
        TextXAlignment = Enum.TextXAlignment.Left,
    }, parent)
end

--============================== tabs =================================
local tabNames = { "Rage", "Visuals", "Misc" }
for _, n in ipairs(tabNames) do makeTab(n) end

local Rage = tabFrames["Rage"]
local Vis  = tabFrames["Visuals"]
local Misc = tabFrames["Misc"]

addLabel(Rage, "SILENT AIM")
addToggle(Rage, "Silent aim", CFG.silent, "enabled")
addToggle(Rage, "FOV circle", CFG.silent, "circle")
addSlider(Rage, "FOV", CFG.silent, "fov", 10, 600, true)
addSlider(Rage, "Hit chance %", CFG.silent, "chance", 0, 100, true)
addToggle(Rage, "Wall check", CFG.silent, "wallcheck")
addToggle(Rage, "Team check", CFG.silent, "teamcheck")
addColor(Rage, "FOV color", CFG.silent, "color")
addLabel(Rage, "3RD PERSON")
addToggle(Rage, "Third person", CFG.third, "enabled")
addSlider(Rage, "Distance", CFG.third, "distance", 2, 30, false)
addSlider(Rage, "Height", CFG.third, "height", -3, 6, false)
addLabel(Rage, "ANTI AIM")
addSlider(Rage, "Mode (0 off /1 spin /2 back /3 jitter)", CFG.antiaim, "mode", 0, 3, true)
addSlider(Rage, "Spin speed", CFG.antiaim, "speed", 30, 900, true)

addLabel(Vis, "ESP")
addToggle(Vis, "ESP", CFG.esp, "enabled")
addToggle(Vis, "Box", CFG.esp, "box")
addToggle(Vis, "Name", CFG.esp, "name")
addToggle(Vis, "Distance", CFG.esp, "dist")
addToggle(Vis, "Health bar", CFG.esp, "hp")
addToggle(Vis, "Snapline", CFG.esp, "line")
addToggle(Vis, "Team check", CFG.esp, "teamcheck")
addSlider(Vis, "Max distance", CFG.esp, "maxDist", 50, 2000, true)
addColor(Vis, "Visible color", CFG.esp, "visColor")
addColor(Vis, "Hidden color", CFG.esp, "hidColor")
addLabel(Vis, "CHAMS")
addToggle(Vis, "Chams", CFG.chams, "enabled")
addToggle(Vis, "Team check", CFG.chams, "teamcheck")
addColor(Vis, "Fill color", CFG.chams, "fill")
addColor(Vis, "Outline color", CFG.chams, "outline")
addSlider(Vis, "Fill transparency", CFG.chams, "transp", 0, 1, false)
addLabel(Vis, "FOG")
addToggle(Vis, "Fog", CFG.fog, "enabled", applyFog)
addSlider(Vis, "Fog start", CFG.fog, "start", 0, 1000, true, applyFog)
addSlider(Vis, "Fog end", CFG.fog, "fin", 10, 5000, true, applyFog)
addColor(Vis, "Fog color", CFG.fog, "color", applyFog)
addLabel(Vis, "SKY")
addToggle(Vis, "Sky", CFG.sky, "enabled", applySky)
addColor(Vis, "Sky color", CFG.sky, "color", applySky)

addLabel(Misc, "COMBAT")
addToggle(Misc, "Wall shot", CFG.misc, "wallshot")
addLabel(Misc, "MOVEMENT")
addToggle(Misc, "Fly", CFG.misc, "fly")
addSlider(Misc, "Fly speed", CFG.misc, "flySpeed", 10, 400, true)
addLabel(Misc, "HOTKEYS: RightShift menu | Space/Ctrl up/down in fly")

selectTab("Rage")

Players.PlayerRemoving:Connect(function(plr)
    local e = espCache[plr]
    if e then
        for _, o in pairs(e) do pcall(function() o:Remove() end) end
        espCache[plr] = nil
    end
    local h = chamsCache[plr]
    if h then pcall(function() h:Destroy() end) chamsCache[plr] = nil end
end)

-- target part dropdown
do
    local parts = { "Head", "UpperTorso", "HumanoidRootPart", "LowerTorso", "Random" }
    local row = new("TextButton", {
        Size = UDim2.new(1, -4, 0, 26), BackgroundColor3 = Color3.fromRGB(24, 21, 32),
        BorderSizePixel = 0, Text = "", AutoButtonColor = false,
    }, Rage)
    new("UICorner", { CornerRadius = UDim.new(0, 5) }, row)
    local lbl = new("TextLabel", {
        Size = UDim2.new(1, -10, 1, 0), BackgroundTransparency = 1,
        Text = "Part: " .. CFG.silent.part, TextSize = 12, Font = Enum.Font.Gotham,
        TextColor3 = Color3.fromRGB(210, 205, 225), TextXAlignment = Enum.TextXAlignment.Left,
        Position = UDim2.fromOffset(8, 0),
    }, row)
    local i = 1
    for k, v in ipairs(parts) do if v == CFG.silent.part then i = k end end
    row.MouseButton1Click:Connect(function()
        i = i % #parts + 1
        CFG.silent.part = parts[i]
        lbl.Text = "Part: " .. CFG.silent.part
    end)
end

--============================== window logic =========================
local dragging, dragStart, startPos
title.InputBegan:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1
        or i.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = i.Position
        startPos = main.Position
    end
end)
UIS.InputChanged:Connect(function(i)
    if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement
        or i.UserInputType == Enum.UserInputType.Touch) then
        local d = i.Position - dragStart
        main.Position = UDim2.new(startPos.X.Scale,
            startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
    end
end)
UIS.InputEnded:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1
        or i.UserInputType == Enum.UserInputType.Touch then dragging = false end
end)
closeBtn.MouseButton1Click:Connect(function() main.Visible = false end)

local fab = new("TextButton", {
    Size = UDim2.fromOffset(42, 42), Position = UDim2.new(0, 12, 0, 90),
    BackgroundColor3 = Color3.fromRGB(30, 22, 46), BorderSizePixel = 0,
    Text = "zp", TextSize = 14, Font = Enum.Font.GothamBold,
    TextColor3 = Color3.fromRGB(190, 160, 255), AutoButtonColor = false,
    Active = true,
}, gui)
new("UICorner", { CornerRadius = UDim.new(1, 0) }, fab)
new("UIStroke", { Color = Color3.fromRGB(100, 65, 180), Thickness = 1 }, fab)

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
        local moved = (i.Position - fabStart).Magnitude
        fabDrag = false
        if moved < 12 then main.Visible = not main.Visible end
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
        main.Visible = not main.Visible
    end
end)

applyFog()
applySky()
notify("loaded / RightShift menu")
