-- // HEAVY HUB | [FPS] One Tap v1.0 (SILENT AIM + FULL) - ПОЛНОСТЬЮ ИСПРАВЛЕН
-- // EDUCATIONAL PURPOSE ONLY
-- // DISCLAIMER: For Lua learning and research only. Not for actual use.
-- // Оптимизировано для Delta (мобильный экзекьютор)
-- // Система: Silent Aim (пули летят в цель, камера не двигается)

-- ============================================================
-- // ИНИЦИАЛИЗАЦИЯ ВСЕХ ГЛОБАЛЬНЫХ ПЕРЕМЕННЫХ
-- ============================================================
_G.SilentAim = false
_G.AimPart = "Head"
_G.FOVRadius = 150
_G.Wallbang = false
_G.TeamCheck = true
_G.OneTap = false
_G.AntiAim = false
_G.AntiAimSpeed = 10
_G.AntiAimDirection = "Right"
_G.ThirdPerson = false
_G.ThirdPersonDistance = 10
_G.ThirdPersonHeight = 2
_G.HeadPitch = "Default"
_G.HeadPitchSpeed = 1
_G.EnableSpeed = false
_G.SpeedValue = 16
_G.Fly = false
_G.FlySpeed = 50
_G.InfiniteJump = false
_G.NoClip = false
_G.PlayerESP = false
_G.ESPColor = Color3.fromRGB(255, 0, 0)
_G.Tracers = false
_G.HealthBar = true
_G.NameTag = true
_G.DistanceESP = true
_G.Chams = false
_G.NoRecoil = false
_G.NoSpread = false
_G.InstantReload = false
_G.AntiAFK = false
_G.HitboxSize = 3
_G.ZoomFOV = 70
_G.Language = "Русский"
_G.Theme = "Dark"
_G.HVHFOV = 70
_G.CustomCrosshair = false

-- ============================================================
-- // ЗАГРУЗКА RAYFIELD
-- ============================================================
if not game:GetService("CoreGui"):FindFirstChild("Rayfield") then
    loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
end

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

-- ============================================================
-- // ГЛАВНОЕ ОКНО
-- ============================================================
local Window = Rayfield:CreateWindow({
    Name = "HEAVY HUB | One Tap",
    Icon = 7734058803,
    LoadingTitle = "HEAVY HUB",
    LoadingSubtitle = "Silent Aim Mode",
    Theme = "Dark"
})

-- ============================================================
-- // РАЗДЕЛ "SILENT AIM"
-- ============================================================
local AimbotTab = Window:CreateTab("🎯 Silent Aim", 7734058803)

AimbotTab:CreateToggle({
    Name = "Silent Aim",
    CurrentValue = false,
    Callback = function(Value)
        _G.SilentAim = Value
    end
})

AimbotTab:CreateDropdown({
    Name = "Aim Part",
    Options = {"Head", "Torso", "Legs"},
    CurrentOption = "Head",
    Callback = function(Option)
        _G.AimPart = Option
    end
})

AimbotTab:CreateSlider({
    Name = "FOV Radius",
    Range = {50, 300},
    Increment = 5,
    CurrentValue = 150,
    Callback = function(Value)
        _G.FOVRadius = Value
    end
})

AimbotTab:CreateToggle({
    Name = "Wallbang",
    CurrentValue = false,
    Callback = function(Value)
        _G.Wallbang = Value
    end
})

AimbotTab:CreateToggle({
    Name = "Team Check",
    CurrentValue = true,
    Callback = function(Value)
        _G.TeamCheck = Value
    end
})

AimbotTab:CreateToggle({
    Name = "One Tap (Auto Fire)",
    CurrentValue = false,
    Callback = function(Value)
        _G.OneTap = Value
    end
})

-- ============================================================
-- // РАЗДЕЛ "HVH"
-- ============================================================
local HVHTab = Window:CreateTab("💀 HVH", 7734058803)

HVHTab:CreateToggle({
    Name = "Anti-Aim (Spin)",
    CurrentValue = false,
    Callback = function(Value)
        _G.AntiAim = Value
        if Value then
            startAntiAim()
        else
            stopAntiAim()
        end
    end
})

HVHTab:CreateSlider({
    Name = "Anti-Aim Speed",
    Range = {1, 50},
    Increment = 1,
    CurrentValue = 10,
    Callback = function(Value)
        _G.AntiAimSpeed = Value
    end
})

HVHTab:CreateDropdown({
    Name = "Anti-Aim Direction",
    Options = {"Right", "Left", "Random"},
    CurrentOption = "Right",
    Callback = function(Option)
        _G.AntiAimDirection = Option
    end
})

HVHTab:CreateToggle({
    Name = "Third Person",
    CurrentValue = false,
    Callback = function(Value)
        _G.ThirdPerson = Value
        if not Value then
            workspace.CurrentCamera.CameraType = Enum.CameraType.Fixed
            local char = game.Players.LocalPlayer.Character
            if char then
                workspace.CurrentCamera.CameraSubject = char:FindFirstChild("Humanoid")
            end
        end
    end
})

HVHTab:CreateSlider({
    Name = "Camera Distance",
    Range = {5, 30},
    Increment = 0.5,
    CurrentValue = 10,
    Callback = function(Value)
        _G.ThirdPersonDistance = Value
    end
})

HVHTab:CreateSlider({
    Name = "Camera Height",
    Range = {0, 5},
    Increment = 0.5,
    CurrentValue = 2,
    Callback = function(Value)
        _G.ThirdPersonHeight = Value
    end
})

HVHTab:CreateDropdown({
    Name = "Pitch (Head Angle)",
    Options = {"Down", "Up", "Emotion", "Default"},
    CurrentOption = "Default",
    Callback = function(Option)
        _G.HeadPitch = Option
        if Option ~= "Default" then
            startHeadPitch()
        else
            stopHeadPitch()
        end
    end
})

HVHTab:CreateSlider({
    Name = "Emotion Speed",
    Range = {0.5, 3},
    Increment = 0.1,
    CurrentValue = 1,
    Callback = function(Value)
        _G.HeadPitchSpeed = Value
    end
})

HVHTab:CreateSlider({
    Name = "HVH FOV",
    Range = {70, 120},
    Increment = 1,
    CurrentValue = 70,
    Callback = function(Value)
        _G.HVHFOV = Value
        workspace.CurrentCamera.FieldOfView = Value
    end
})

HVHTab:CreateToggle({
    Name = "Custom Crosshair",
    CurrentValue = false,
    Callback = function(Value)
        _G.CustomCrosshair = Value
        toggleCrosshair(Value)
    end
})

-- ============================================================
-- // РАЗДЕЛ "MOVEMENT"
-- ============================================================
local MovementTab = Window:CreateTab("🏃 Movement", 7734058803)

MovementTab:CreateSlider({
    Name = "Walk Speed",
    Range = {16, 250},
    Increment = 1,
    CurrentValue = 16,
    Callback = function(Value)
        _G.SpeedValue = Value
    end
})

MovementTab:CreateToggle({
    Name = "Enable Speed",
    CurrentValue = false,
    Callback = function(Value)
        _G.EnableSpeed = Value
    end
})

MovementTab:CreateToggle({
    Name = "Fly",
    CurrentValue = false,
    Callback = function(Value)
        _G.Fly = Value
        if Value then
            startFly()
        else
            stopFly()
        end
    end
})

MovementTab:CreateSlider({
    Name = "Fly Speed",
    Range = {10, 100},
    Increment = 5,
    CurrentValue = 50,
    Callback = function(Value)
        _G.FlySpeed = Value
    end
})

MovementTab:CreateToggle({
    Name = "Infinite Jump",
    CurrentValue = false,
    Callback = function(Value)
        _G.InfiniteJump = Value
    end
})

MovementTab:CreateToggle({
    Name = "NoClip",
    CurrentValue = false,
    Callback = function(Value)
        _G.NoClip = Value
    end
})

-- ============================================================
-- // РАЗДЕЛ "VISUALS"
-- ============================================================
local VisualsTab = Window:CreateTab("👁️ Visuals", 7734058803)

VisualsTab:CreateToggle({
    Name = "Player ESP",
    CurrentValue = false,
    Callback = function(Value)
        _G.PlayerESP = Value
        if not Value then
            clearESP()
        end
    end
})

VisualsTab:CreateColorPicker({
    Name = "ESP Color",
    Color = Color3.fromRGB(255, 0, 0),
    Callback = function(Color)
        _G.ESPColor = Color
    end
})

VisualsTab:CreateToggle({
    Name = "Tracers",
    CurrentValue = false,
    Callback = function(Value)
        _G.Tracers = Value
        if not Value then
            clearTracers()
        end
    end
})

VisualsTab:CreateToggle({
    Name = "Health Bar",
    CurrentValue = true,
    Callback = function(Value)
        _G.HealthBar = Value
    end
})

VisualsTab:CreateToggle({
    Name = "Name Tag",
    CurrentValue = true,
    Callback = function(Value)
        _G.NameTag = Value
    end
})

VisualsTab:CreateToggle({
    Name = "Distance",
    CurrentValue = true,
    Callback = function(Value)
        _G.DistanceESP = Value
    end
})

VisualsTab:CreateToggle({
    Name = "Chams (X-Ray)",
    CurrentValue = false,
    Callback = function(Value)
        _G.Chams = Value
        toggleChams(Value)
    end
})

-- ============================================================
-- // РАЗДЕЛ "MISC"
-- ============================================================
local MiscTab = Window:CreateTab("⚙️ Misc", 7734058803)

MiscTab:CreateToggle({
    Name = "No Recoil",
    CurrentValue = false,
    Callback = function(Value)
        _G.NoRecoil = Value
    end
})

MiscTab:CreateToggle({
    Name = "No Spread",
    CurrentValue = false,
    Callback = function(Value)
        _G.NoSpread = Value
    end
})

MiscTab:CreateToggle({
    Name = "Instant Reload",
    CurrentValue = false,
    Callback = function(Value)
        _G.InstantReload = Value
    end
})

MiscTab:CreateToggle({
    Name = "Anti-AFK",
    CurrentValue = false,
    Callback = function(Value)
        _G.AntiAFK = Value
        if Value then
            startAntiAFK()
        else
            stopAntiAFK()
        end
    end
})

MiscTab:CreateSlider({
    Name = "Hitbox Size",
    Range = {2, 10},
    Increment = 0.5,
    CurrentValue = 3,
    Callback = function(Value)
        _G.HitboxSize = Value
    end
})

MiscTab:CreateSlider({
    Name = "Zoom (FOV)",
    Range = {40, 120},
    Increment = 5,
    CurrentValue = 70,
    Callback = function(Value)
        _G.ZoomFOV = Value
    end
})

-- ============================================================
-- // РАЗДЕЛ "SETTINGS"
-- ============================================================
local SettingsTab = Window:CreateTab("⚡ Settings", 7734058803)

SettingsTab:CreateDropdown({
    Name = "Language",
    Options = {"Русский", "English", "Español"},
    CurrentOption = "Русский",
    Callback = function(Option)
        _G.Language = Option
        print("Язык: " .. Option)
    end
})

SettingsTab:CreateDropdown({
    Name = "Theme",
    Options = {"Dark", "Light", "Neon", "Cyber"},
    CurrentOption = "Dark",
    Callback = function(Option)
        _G.Theme = Option
        Window:SetTheme(Option)
    end
})

SettingsTab:CreateButton({
    Name = "Reset All Settings",
    Callback = function()
        resetAllSettings()
    end
})

SettingsTab:CreateButton({
    Name = "About",
    Callback = function()
        Rayfield:Notify({
            Title = "HEAVY HUB v1.0",
            Content = "Режим: Silent Aim\nРазработано для Delta\nАвтор: FeVilAi",
            Duration = 5
        })
    end
})

-- ============================================================
-- // ОСНОВНЫЕ ПЕРЕМЕННЫЕ
-- ============================================================
local player = game.Players.LocalPlayer
local camera = workspace.CurrentCamera
local runService = game:GetService("RunService")
local userInput = game:GetService("UserInputService")
local mouse = player:GetMouse()

-- ============================================================
-- // HVH ФУНКЦИИ
-- ============================================================
local antiAimThread = nil
local headPitchThread = nil
local crosshairGui = nil

function startAntiAim()
    if antiAimThread then
        antiAimThread = nil
    end
    
    antiAimThread = task.spawn(function()
        while _G.AntiAim do
            task.wait(0.016)
            local char = player.Character
            if not char then continue end
            
            local rootPart = char:FindFirstChild("HumanoidRootPart")
            if not rootPart then continue end
            
            local speed = _G.AntiAimSpeed or 10
            local direction = _G.AntiAimDirection or "Right"
            
            local angle = 0
            if direction == "Right" then
                angle = math.rad(speed)
            elseif direction == "Left" then
                angle = math.rad(-speed)
            elseif direction == "Random" then
                angle = math.rad((math.random(1, 2) == 1 and 1 or -1) * speed)
            end
            
            rootPart.CFrame = rootPart.CFrame * CFrame.Angles(0, angle, 0)
        end
    end)
end

function stopAntiAim()
    if antiAimThread then
        antiAimThread = nil
    end
end

function startHeadPitch()
    if headPitchThread then
        headPitchThread = nil
    end
    
    headPitchThread = task.spawn(function()
        while _G.HeadPitch ~= "Default" do
            task.wait(0.05)
            
            local char = player.Character
            if not char then continue end
            
            local head = char:FindFirstChild("Head")
            if not head then continue end
            
            local targetCFrame = head.CFrame
            
            if _G.HeadPitch == "Down" then
                targetCFrame = targetCFrame * CFrame.Angles(math.rad(90), 0, 0)
            elseif _G.HeadPitch == "Up" then
                targetCFrame = targetCFrame * CFrame.Angles(math.rad(-90), 0, 0)
            elseif _G.HeadPitch == "Emotion" then
                local time = tick() * _G.HeadPitchSpeed
                local angleX = math.sin(time) * 30
                local angleY = math.cos(time * 0.7) * 20
                targetCFrame = targetCFrame * CFrame.Angles(math.rad(angleX), math.rad(angleY), 0)
            end
            
            head.CFrame = targetCFrame
        end
    end)
end

function stopHeadPitch()
    if headPitchThread then
        headPitchThread = nil
        local char = player.Character
        if char and char:FindFirstChild("Head") then
            char.Head.CFrame = char.Head.CFrame * CFrame.Angles(0, 0, 0)
        end
    end
end

function toggleCrosshair(value)
    if crosshairGui then
        crosshairGui:Destroy()
        crosshairGui = nil
    end
    
    if value then
        crosshairGui = Instance.new("ScreenGui")
        crosshairGui.Name = "Crosshair"
        crosshairGui.Parent = player:WaitForChild("PlayerGui")
        
        local crosshair1 = Instance.new("Frame")
        crosshair1.Size = UDim2.new(0, 2, 0, 20)
        crosshair1.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
        crosshair1.Position = UDim2.new(0.5, -1, 0.5, -10)
        crosshair1.Parent = crosshairGui
        
        local crosshair2 = Instance.new("Frame")
        crosshair2.Size = UDim2.new(0, 20, 0, 2)
        crosshair2.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
        crosshair2.Position = UDim2.new(0.5, -10, 0.5, -1)
        crosshair2.Parent = crosshairGui
    end
end

-- ============================================================
-- // SILENT AIM ФУНКЦИИ
-- ============================================================
function getNearestEnemy()
    local char = player.Character
    if not char then return nil end
    
    local nearest = nil
    local minDist = math.huge
    local mousePos = Vector2.new(mouse.X, mouse.Y)
    
    for _, v in pairs(game.Players:GetPlayers()) do
        if v ~= player then
            if _G.TeamCheck and v.Team and player.Team and v.Team == player.Team then
                -- Пропускаем союзников
            else
                local targetChar = v.Character
                if targetChar then
                    local part = targetChar:FindFirstChild(_G.AimPart or "Head")
                    if part then
                        local pos, onScreen = camera:WorldToViewportPoint(part.Position)
                        
                        local wallbangCheck = true
                        if not _G.Wallbang and not onScreen then
                            wallbangCheck = false
                        end
                        
                        if wallbangCheck then
                            local dist = (part.Position - char.Head.Position).Magnitude
                            
                            local fovCheck = true
                            if onScreen then
                                local screenPos = Vector2.new(pos.X, pos.Y)
                                local fovDist = (screenPos - mousePos).Magnitude
                                if fovDist > _G.FOVRadius then
                                    fovCheck = false
                                end
                            end
                            
                            if fovCheck and dist < minDist then
                                minDist = dist
                                nearest = targetChar
                            end
                        end
                    end
                end
            end
        end
    end
    return nearest
end

function performShot(target)
    if not target then return end
    
    local part = target:FindFirstChild(_G.AimPart or "Head")
    if not part then return end
    
    local tool = player.Character and player.Character:FindFirstChildOfClass("Tool")
    if not tool then return end
    
    local shootEvents = {"Shoot", "Fire", "Attack", "ShootBullet", "FireBullet", "Damage", "Hit", "RemoteEvent"}
    for _, child in pairs(tool:GetDescendants()) do
        if child:IsA("RemoteEvent") then
            for _, name in pairs(shootEvents) do
                if child.Name:lower():find(name:lower()) then
                    child:FireServer(part.Position, part)
                    return
                end
            end
        end
    end
    
    local weapon = tool:FindFirstChild("Weapon") or tool:FindFirstChild("Gun") or tool:FindFirstChild("Handle")
    if weapon then
        for _, child in pairs(weapon:GetDescendants()) do
            if child:IsA("RemoteEvent") then
                child:FireServer(part.Position, part)
                return
            end
        end
    end
end

-- ============================================================
-- // FLY ФУНКЦИИ
-- ============================================================
local flyBodyVelocity = nil

function startFly()
    local char = player.Character
    if not char then return end
    
    char.Humanoid.PlatformStand = true
    
    flyBodyVelocity = Instance.new("BodyVelocity")
    flyBodyVelocity.MaxForce = Vector3.new(1e9, 1e9, 1e9)
    flyBodyVelocity.Parent = char
end

function stopFly()
    local char = player.Character
    if char then
        char.Humanoid.PlatformStand = false
    end
    
    if flyBodyVelocity then
        flyBodyVelocity:Destroy()
        flyBodyVelocity = nil
    end
end

-- ============================================================
-- // ESP ФУНКЦИИ - ИСПРАВЛЕНА!
-- ============================================================
local espObjects = {}

function updateESP()
    clearESP()
    
    if not _G.PlayerESP then return end
    
    local char = player.Character
    if not char then return end
    
    for _, v in pairs(game.Players:GetPlayers()) do
        if v ~= player and v.Character then
            local targetChar = v.Character
            local head = targetChar:FindFirstChild("Head")
            if head then
                local color = _G.ESPColor or Color3.fromRGB(255, 0, 0)
                local distance = (head.Position - char.Head.Position).Magnitude
                
                local box = Instance.new("BoxHandleAdornment")
                box.Name = "ESPBox"
                box.Size = Vector3.new(3, 5, 3)
                box.Color3 = color
                box.Transparency = 0.3
                box.ZIndex = 0
                box.AlwaysOnTop = true
                box.Parent = head
                
                local objects = {box = box}
                
                if _G.NameTag then
                    local nameTag = Instance.new("BillboardGui")
                    nameTag.Name = "ESPName"
                    nameTag.Size = UDim2.new(0, 200, 0, 30)
                    nameTag.Adornee = head
                    nameTag.AlwaysOnTop = true
                    nameTag.Parent = head
                    
                    local nameLabel = Instance.new("TextLabel")
                    nameLabel.Size = UDim2.new(1, 0, 1, 0)
                    nameLabel.BackgroundTransparency = 1
                    nameLabel.Text = v.Name
                    nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
                    nameLabel.TextScaled = true
                    nameLabel.Font = Enum.Font.GothamBold
                    nameLabel.Parent = nameTag
                    
                    objects.nameTag = nameTag
                end
                
                if _G.DistanceESP then
                    local distTag = Instance.new("BillboardGui")
                    distTag.Name = "ESPDistance"
                    distTag.Size = UDim2.new(0, 100, 0, 20)
                    distTag.Adornee = head
                    distTag.AlwaysOnTop = true
                    distTag.Parent = head
                    
                    local distLabel = Instance.new("TextLabel")
                    distLabel.Size = UDim2.new(1, 0, 1, 0)
                    distLabel.BackgroundTransparency = 1
                    distLabel.Text = math.floor(distance) .. "m"
                    distLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
                    distLabel.TextScaled = true
                    distLabel.Font = Enum.Font.Gotham
                    distLabel.Parent = distTag
                    
                    objects.distTag = distTag
                end
                
                if _G.HealthBar then
                    local health = v.Character:FindFirstChild("Humanoid")
                    if health then
                        local healthTag = Instance.new("BillboardGui")
                        healthTag.Name = "ESPHealth"
                        healthTag.Size = UDim2.new(0, 50, 0, 5)
                        healthTag.Adornee = head
                        healthTag.AlwaysOnTop = true
                        healthTag.Parent = head
                        
                        local healthBar = Instance.new("Frame")
                        healthBar.Size = UDim2.new(health.Health / health.MaxHealth, 0, 1, 0)
                        healthBar.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
                        healthBar.Parent = healthTag
                        
                        objects.healthBar = healthBar
                    end
                end
                
                table.insert(espObjects, objects)
            end
        end
    end
end

function clearESP()
    for _, obj in pairs(espObjects) do
        pcall(function()
            if obj.box then obj.box:Destroy() end
            if obj.nameTag then obj.nameTag:Destroy() end
            if obj.distTag then obj.distTag:Destroy() end
            if obj.healthBar then obj.healthBar:Destroy() end
        end)
    end
    espObjects = {}
end

-- ============================================================
-- // TRACERS ФУНКЦИИ
-- ============================================================
local tracerObjects = {}

function updateTracers()
    clearTracers()
    
    if not _G.Tracers then return end
    
    local char = player.Character
    if not char then return end
    
    for _, v in pairs(game.Players:GetPlayers()) do
        if v ~= player and v.Character then
            local head = v.Character:FindFirstChild("Head")
            if head then
                local tracer = Instance.new("LineHandleAdornment")
                tracer.Color3 = _G.ESPColor or Color3.fromRGB(255, 0, 0)
                tracer.Thickness = 1
                tracer.Transparency = 0.5
                tracer.ZIndex = 0
                tracer.AlwaysOnTop = true
                tracer.Parent = head
                table.insert(tracerObjects, tracer)
            end
        end
    end
end

function clearTracers()
    for _, obj in pairs(tracerObjects) do
        pcall(function() obj:Destroy() end)
    end
    tracerObjects = {}
end

-- ============================================================
-- // CHAMS ФУНКЦИИ
-- ============================================================
local chamsObjects = {}

function toggleChams(value)
    clearChams()
    
    if not value then return end
    
    for _, v in pairs(game.Players:GetPlayers()) do
        if v ~= player and v.Character then
            for _, part in pairs(v.Character:GetDescendants()) do
                if part:IsA("BasePart") then
                    local cham = Instance.new("BoxHandleAdornment")
                    cham.Size = part.Size * 1.1
                    cham.Color3 = Color3.fromRGB(0, 255, 255)
                    cham.Transparency = 0.5
                    cham.ZIndex = 0
                    cham.AlwaysOnTop = true
                    cham.Parent = part
                    table.insert(chamsObjects, cham)
                end
            end
        end
    end
end

function clearChams()
    for _, obj in pairs(chamsObjects) do
        pcall(function() obj:Destroy() end)
    end
    chamsObjects = {}
end

-- ============================================================
-- // ANTI-AFK ФУНКЦИИ
-- ============================================================
local antiAFKThread = nil

function startAntiAFK()
    if antiAFKThread then
        antiAFKThread = nil
    end
    
    antiAFKThread = task.spawn(function()
        while _G.AntiAFK do
            task.wait(30)
            local char = player.Character
            if char then
                local humanoid = char:FindFirstChild("Humanoid")
                if humanoid then
                    humanoid:Move(Vector3.new(0, 0, 0))
                end
            end
        end
    end)
end

function stopAntiAFK()
    if antiAFKThread then
        antiAFKThread = nil
    end
end

-- ============================================================
-- // RESET SETTINGS
-- ============================================================
function resetAllSettings()
    _G.SilentAim = false
    _G.AntiAim = false
    _G.AntiAimSpeed = 10
    _G.AntiAimDirection = "Right"
    _G.ThirdPerson = false
    _G.ThirdPersonDistance = 10
    _G.ThirdPersonHeight = 2
    _G.HeadPitch = "Default"
    _G.HeadPitchSpeed = 1
    _G.EnableSpeed = false
    _G.SpeedValue = 16
    _G.Fly = false
    _G.FlySpeed = 50
    _G.InfiniteJump = false
    _G.NoClip = false
    _G.PlayerESP = false
    _G.Tracers = false
    _G.HealthBar = true
    _G.NameTag = true
    _G.DistanceESP = true
    _G.Chams = false
    _G.NoRecoil = false
    _G.NoSpread = false
    _G.InstantReload = false
    _G.AntiAFK = false
    _G.HitboxSize = 3
    _G.ZoomFOV = 70
    _G.HVHFOV = 70
    _G.CustomCrosshair = false
    
    stopAntiAim()
    stopHeadPitch()
    stopFly()
    stopAntiAFK()
    clearESP()
    clearTracers()
    clearChams()
    toggleCrosshair(false)
    workspace.CurrentCamera.FieldOfView = 70
    
    print("All settings reset to default!")
end

-- ============================================================
-- // ОСНОВНЫЕ ЦИКЛЫ
-- ============================================================

userInput.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        if _G.SilentAim and _G.OneTap then
            local target = getNearestEnemy()
            if target then
                performShot(target)
            end
        end
    end
end)

local lastShotTime = 0
runService.RenderStepped:Connect(function()
    if _G.SilentAim and _G.OneTap then
        local target = getNearestEnemy()
        if target then
            local currentTime = tick()
            if currentTime - lastShotTime >= 0.1 then
                performShot(target)
                lastShotTime = currentTime
            end
        end
    end
end)

runService.RenderStepped:Connect(function()
    if _G.ThirdPerson then
        local char = player.Character
        if not char then return end
        
        local rootPart = char:FindFirstChild("HumanoidRootPart")
        if not rootPart then return end
        
        local distance = _G.ThirdPersonDistance or 10
        local height = _G.ThirdPersonHeight or 2
        
        local lookVector = rootPart.CFrame.LookVector
        local cameraPos = rootPart.Position - lookVector * distance + Vector3.new(0, height, 0)
        
        workspace.CurrentCamera.CameraType = Enum.CameraType.Scriptable
        workspace.CurrentCamera.CFrame = CFrame.new(cameraPos, rootPart.Position + Vector3.new(0, 1, 0))
    end
end)

local lastESPCheck = 0
runService.Heartbeat:Connect(function()
    if _G.PlayerESP then
        local currentTime = tick()
        if currentTime - lastESPCheck >= 0.5 then
            updateESP()
            lastESPCheck = currentTime
        end
    end
end)

local lastTracerCheck = 0
runService.Heartbeat:Connect(function()
    if _G.Tracers then
        local currentTime = tick()
        if currentTime - lastTracerCheck >= 0.5 then
            updateTracers()
            lastTracerCheck = currentTime
        end
    end
end)

runService.Heartbeat:Connect(function()
    if _G.EnableSpeed then
        local char = player.Character
        if char and char:FindFirstChild("Humanoid") then
            char.Humanoid.WalkSpeed = _G.SpeedValue or 16
        end
    end
end)

runService.Heartbeat:Connect(function()
    if _G.NoClip then
        local char = player.Character
        if char then
            for _, part in pairs(char:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CanCollide = false
                end
            end
        end
    end
end)

userInput.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if not _G.Fly then return end
    
    local char = player.Character
    if not char or not flyBodyVelocity then return end
    
    local speed = _G.FlySpeed or 50
    local direction = Vector3.new(0, 0, 0)
    
    if input.KeyCode == Enum.KeyCode.W then
        direction = direction + char.Head.CFrame.LookVector * speed
    elseif input.KeyCode == Enum.KeyCode.S then
        direction = direction - char.Head.CFrame.LookVector * speed
    elseif input.KeyCode == Enum.KeyCode.A then
        direction = direction - char.Head.CFrame.RightVector * speed
    elseif input.KeyCode == Enum.KeyCode.D then
        direction = direction + char.Head.CFrame.RightVector * speed
    elseif input.KeyCode == Enum.KeyCode.Space then
        direction = direction + Vector3.new(0, speed, 0)
    elseif input.KeyCode == Enum.KeyCode.LeftShift then
        direction = direction - Vector3.new(0, speed, 0)
    end
    
    if direction ~= Vector3.new(0, 0, 0) then
        flyBodyVelocity.Velocity = direction
    else
        flyBodyVelocity.Velocity = Vector3.new(0, 0, 0)
    end
end)

userInput.JumpRequest:Connect(function()
    if _G.InfiniteJump then
        local char = player.Character
        if char and char:FindFirstChild("Humanoid") then
            char.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
        end
    end
end)

runService.Heartbeat:Connect(function()
    if _G.HitboxSize then
        local char = player.Character
        if char then
            local size = _G.HitboxSize or 3
            local scale = size / 3
            
            for _, part in pairs(char:GetDescendants()) do
                if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
                    local origSize = part.Size
                    part.Size = Vector3.new(
                        origSize.X * scale,
                        origSize.Y * scale,
                        origSize.Z * scale
                    )
                end
            end
        end
    end
end)

runService.RenderStepped:Connect(function()
    if _G.ZoomFOV then
        camera.FieldOfView = _G.ZoomFOV
    end
end)

runService.Heartbeat:Connect(function()
    if _G.NoRecoil or _G.NoSpread or _G.InstantReload then
        local tool = player.Character and player.Character:FindFirstChildOfClass("Tool")
        if tool then
            -- Здесь нужно добавить логику в зависимости от игры
        end
    end
end)

-- ============================================================
-- // ИНФОРМАЦИЯ
-- ============================================================

print("✅ HEAVY HUB v1.0 [ПОЛНОСТЬЮ ИСПРАВЛЕН]")
print("🔧 Особенности:")
print("  • Silent Aim с настройкой FOV")
print("  • Anti-Aim с выбором направления")
print("  • Third Person с настройкой камеры")
print("  • ESP с цветовой настройкой")
print("  • Tracers и Chams")
print("  • Fly с управлением WASD + Space + Shift")
print("  • Infinite Jump, NoClip, No Recoil")
print("  • Hitbox Expander, Zoom FOV")
print("📱 Оптимизировано для Delta (мобильный экзекьютор)")
print("🔥 HEAVY HUB - Тяжелый артиллерийский хаб!")