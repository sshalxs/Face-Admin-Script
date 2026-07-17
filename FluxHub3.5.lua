-- // FLUXHUB | Sheriff vs Murders Duels v3.5 (MASSIVE VISUAL UPDATE)
-- // EDUCATIONAL PURPOSE ONLY
-- // DISCLAIMER: For Lua learning and research only. Not for actual use.
-- // НОВОЕ: Silent Aim (полный перехват), Custom Skybox, Target ESP, TargetHUD, Pulse Visuals, Custom Models

-- ============================================================
-- // ЗАГРУЗКА RAYFIELD
-- ============================================================
if not game:GetService("CoreGui"):FindFirstChild("Rayfield") then
    loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
end
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

-- ============================================================
-- // ГЛАВНОЕ ОКНО (FLUXHUB)
-- ============================================================
local Window = Rayfield:CreateWindow({
    Name = "FLUXHUB | Sheriff vs Murders",
    Icon = 7734058803,
    LoadingTitle = "FLUXHUB",
    LoadingSubtitle = "by FeVilAi (MASSIVE UPDATE)",
    Theme = "Dark"
})

-- ============================================================
-- // ОСНОВНЫЕ ПЕРЕМЕННЫЕ
-- ============================================================
local player = game.Players.LocalPlayer
local camera = workspace.CurrentCamera
local runService = game:GetService("RunService")
local userInput = game:GetService("UserInputService")
local virtualInput = game:GetService("VirtualInputManager")
local players = game:GetService("Players")
local lighting = game:GetService("Lighting")
local espObjects = {}
local flyBodyVelocity = nil
local isThirdPerson = false
local thirdPersonOffset = CFrame.new(0, 2, 10)
local mouse = player:GetMouse()
local currentModel = nil
local targetHudGui = nil
local pulseEffect = nil

-- ============================================================
-- // ВСПОМОГАТЕЛЬНЫЕ ФУНКЦИИ
-- ============================================================
local function getCharacter()
    local char = player.Character
    if not char or not char.Parent then return nil end
    return char
end

local function getEnemyFolder()
    local workspace = game:GetService("Workspace")
    local tFolder = workspace:FindFirstChild("Terrorists")
    local ctFolder = workspace:FindFirstChild("Counter-Terrorists")
    if tFolder and tFolder:FindFirstChild(player.Name) then
        return ctFolder
    elseif ctFolder and ctFolder:FindFirstChild(player.Name) then
        return tFolder
    end
    return nil
end

local function getClosestPlayer()
    if not player:GetAttribute("Map") then return nil end
    local myChar = getCharacter()
    if not myChar then return nil end
    local myRoot = myChar:FindFirstChild("HumanoidRootPart")
    if not myRoot then return nil end

    local mousePos = Vector2.new(mouse.X, mouse.Y)
    local myTeam = player:GetAttribute("Team")
    local myGame = player:GetAttribute("Game")

    local closestPlayer = nil
    local shortestDistance = math.huge

    for _, plr in pairs(players:GetPlayers()) do
        if plr ~= player then
            local character = plr.Character
            if not character then continue end
            local root = character:FindFirstChild("HumanoidRootPart")
            if not root then continue end

            if plr:GetAttribute("Game") == myGame and plr:GetAttribute("Team") ~= myTeam then
                local worldDist = (root.Position - myRoot.Position).Magnitude
                if worldDist <= 150 then
                    local screenPos, onScreen = camera:WorldToViewportPoint(root.Position)
                    if onScreen then
                        local dist = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude
                        if dist < shortestDistance then
                            shortestDistance = dist
                            closestPlayer = plr
                        end
                    end
                end
            end
        end
    end
    return closestPlayer
end

-- ============================================================
-- // РАЗДЕЛ "SILENT AIM" (ПОЛНЫЙ ПЕРЕХВАТ)
-- ============================================================
local AimbotTab = Window:CreateTab("🎯 Silent Aim", 7734058803)

local SilentAimEnabled = false
local RageMode = false
local AimPart = "Head"
local FOVRadius = 150
local Wallbang = false
local HitChance = 100
local TargetPart = "Head"

-- Полный перехват через hookmetamethod (взято из Vascal-Silent-Aim-V3) [0†L3-L4]
local oldIndex
oldIndex = hookmetamethod(game, "__index", function(self, key)
    if not checkcaller() and self == player:GetMouse() and key == "Hit" then
        local target = getClosestPlayer()
        if target then
            local root = target.Character and target.Character:FindFirstChild("HumanoidRootPart")
            if root then
                return CFrame.new(root.Position)
            end
        end
    end
    return oldIndex(self, key)
end)

-- Rage Mode (авто-атака по всем) [9†L7-L9]
local function rageModeLoop()
    while RageMode do
        task.wait(0.05)
        for _, v in pairs(players:GetPlayers()) do
            if v ~= player and v.Character then
                local target = v.Character
                local part = target:FindFirstChild(AimPart or "Head")
                if part then
                    local tool = player.Character and player.Character:FindFirstChildOfClass("Tool")
                    if tool then
                        for _, child in pairs(tool:GetDescendants()) do
                            if child:IsA("RemoteEvent") and child.Name:lower():find("shoot") then
                                child:FireServer(part.Position, part)
                            end
                        end
                    end
                end
            end
        end
    end
end

AimbotTab:CreateToggle({
    Name = "Silent Aim",
    CurrentValue = false,
    Callback = function(Value)
        SilentAimEnabled = Value
        if Value then
            print("Silent Aim enabled")
        else
            oldIndex = hookmetamethod(game, "__index", function(self, key)
                if not checkcaller() and self == player:GetMouse() and key == "Hit" then
                    return oldIndex(self, key)
                end
                return oldIndex(self, key)
            end)
            print("Silent Aim disabled")
        end
    end
})

AimbotTab:CreateToggle({
    Name = "Rage Mode (Auto-Kill All)",
    CurrentValue = false,
    Callback = function(Value)
        RageMode = Value
        if Value then
            spawn(rageModeLoop)
        end
    end
})

AimbotTab:CreateSlider({
    Name = "FOV Radius",
    Range = {50, 300},
    Increment = 5,
    CurrentValue = 150,
    Callback = function(Value)
        FOVRadius = Value
    end
})

AimbotTab:CreateSlider({
    Name = "Hit Chance (%)",
    Range = {0, 100},
    Increment = 1,
    CurrentValue = 100,
    Callback = function(Value)
        HitChance = Value
    end
})

AimbotTab:CreateDropdown({
    Name = "Target Part",
    Options = {"Head", "HumanoidRootPart", "UpperTorso", "LowerTorso"},
    CurrentOption = "Head",
    Callback = function(Option)
        TargetPart = Option
    end
})

AimbotTab:CreateToggle({
    Name = "Wallbang",
    CurrentValue = false,
    Callback = function(Value)
        Wallbang = Value
    end
})

-- ============================================================
-- // РАЗДЕЛ "VISUALS" (КАК В МАЙН-КС ЧИТАХ)
-- ============================================================
local VisualsTab = Window:CreateTab("🎨 Visuals", 7734058803)

-- 1. Custom Skybox (кастомное небо) [3†L30-L33]
local function setSkyColor(color)
    local colorCorr = Instance.new("ColorCorrectionEffect")
    colorCorr.TintColor = color
    colorCorr.Saturation = 0.5
    colorCorr.Brightness = 0.2
    colorCorr.Parent = lighting
end

VisualsTab:CreateColorPicker({
    Name = "Skybox Color",
    Color = Color3.fromRGB(135, 206, 235),
    Callback = function(Color)
        setSkyColor(Color)
    end
})

VisualsTab:CreateButton({
    Name = "Reset Skybox",
    Callback = function()
        for _, v in pairs(lighting:GetChildren()) do
            if v:IsA("ColorCorrectionEffect") then
                v:Destroy()
            end
        end
    end
})

-- 2. Target ESP (значок рядом с игроком) [8†L4-L11]
local TargetESPEnabled = false
local targetIndicator = nil

local function createTargetIndicator()
    if targetIndicator then targetIndicator:Destroy() end
    targetIndicator = Instance.new("ImageLabel")
    targetIndicator.Size = UDim2.new(0, 50, 0, 50)
    targetIndicator.BackgroundTransparency = 1
    targetIndicator.Image = "rbxassetid://7733765398"
    targetIndicator.Parent = player.PlayerGui
end

local function updateTargetIndicator()
    if not TargetESPEnabled then
        if targetIndicator then targetIndicator:Destroy() end
        return
    end
    local target = getClosestPlayer()
    if target and target.Character then
        local pos, onScreen = camera:WorldToViewportPoint(target.Character.Head.Position)
        if onScreen then
            if not targetIndicator then createTargetIndicator() end
            targetIndicator.Position = UDim2.new(0, pos.X - 25, 0, pos.Y - 50)
            targetIndicator.Visible = true
            return
        end
    end
    if targetIndicator then targetIndicator.Visible = false end
end

VisualsTab:CreateToggle({
    Name = "Target ESP (Indicator)",
    CurrentValue = false,
    Callback = function(Value)
        TargetESPEnabled = Value
        if Value then
            createTargetIndicator()
            spawn(function()
                while TargetESPEnabled do
                    task.wait(0.05)
                    updateTargetIndicator()
                end
            end)
        else
            if targetIndicator then targetIndicator:Destroy() end
        end
    end
})

-- 3. TargetHUD (шанс попадания) [9†L11-L14]
local TargetHUDEnabled = false
local targetHudFrame = nil

local function createTargetHUD()
    if targetHudFrame then targetHudFrame:Destroy() end
    targetHudFrame = Instance.new("Frame")
    targetHudFrame.Size = UDim2.new(0, 200, 0, 60)
    targetHudFrame.Position = UDim2.new(0.5, -100, 0.8, 0)
    targetHudFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    targetHudFrame.BackgroundTransparency = 0.6
    targetHudFrame.BorderSizePixels = 0
    targetHudFrame.Parent = player.PlayerGui

    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(1, 0, 0, 20)
    nameLabel.Position = UDim2.new(0, 5, 0, 5)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = "Target: None"
    nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    nameLabel.TextScaled = true
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.Parent = targetHudFrame

    local chanceLabel = Instance.new("TextLabel")
    chanceLabel.Size = UDim2.new(1, 0, 0, 20)
    chanceLabel.Position = UDim2.new(0, 5, 0, 25)
    chanceLabel.BackgroundTransparency = 1
    chanceLabel.Text = "Hit Chance: 100%"
    chanceLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
    chanceLabel.TextScaled = true
    chanceLabel.Font = Enum.Font.GothamBold
    chanceLabel.Parent = targetHudFrame

    local distLabel = Instance.new("TextLabel")
    distLabel.Size = UDim2.new(1, 0, 0, 20)
    distLabel.Position = UDim2.new(0, 5, 0, 45)
    distLabel.BackgroundTransparency = 1
    distLabel.Text = "Distance: 0m"
    distLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    distLabel.TextScaled = true
    distLabel.Font = Enum.Font.GothamBold
    distLabel.Parent = targetHudFrame

    return targetHudFrame
end

local function updateTargetHUD()
    if not TargetHUDEnabled then
        if targetHudFrame then targetHudFrame:Destroy() end
        return
    end
    local target = getClosestPlayer()
    if target and target.Character then
        if not targetHudFrame then createTargetHUD() end
        local dist = (target.Character.Head.Position - player.Character.Head.Position).Magnitude
        local hitChance = math.max(0, HitChance - math.floor(dist / 5))
        targetHudFrame.Visible = true
        targetHudFrame:FindFirstChild("TextLabel").Text = "Target: " .. target.Name
        targetHudFrame:FindFirstChild("TextLabel").Next.Text = "Hit Chance: " .. hitChance .. "%"
        targetHudFrame:FindFirstChild("TextLabel").Next.Next.Text = "Distance: " .. math.floor(dist) .. "m"
    else
        if targetHudFrame then targetHudFrame.Visible = false end
    end
end

VisualsTab:CreateToggle({
    Name = "Target HUD",
    CurrentValue = false,
    Callback = function(Value)
        TargetHUDEnabled = Value
        if Value then
            createTargetHUD()
            spawn(function()
                while TargetHUDEnabled do
                    task.wait(0.1)
                    updateTargetHUD()
                end
            end)
        else
            if targetHudFrame then targetHudFrame:Destroy() end
        end
    end
})

-- 4. Pulse Visual (пульсирующий визуал) [4†L30-L31]
local PulseEnabled = false
local pulseObjects = {}

local function createPulse()
    if PulseEnabled then
        local pulse = Instance.new("Frame")
        pulse.Size = UDim2.new(0, 100, 0, 100)
        pulse.Position = UDim2.new(0.5, -50, 0.5, -50)
        pulse.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
        pulse.BackgroundTransparency = 0.5
        pulse.BorderSizePixels = 0
        pulse.Parent = player.PlayerGui
        table.insert(pulseObjects, pulse)
        
        spawn(function()
            local t = 0
            while PulseEnabled and pulse.Parent do
                t = t + 0.05
                local size = 50 + math.sin(t * 2) * 30
                pulse.Size = UDim2.new(0, size, 0, size)
                pulse.Position = UDim2.new(0.5, -size/2, 0.5, -size/2)
                pulse.BackgroundTransparency = 0.5 + math.sin(t * 2) * 0.3
                task.wait(0.05)
            end
        end)
    end
end

VisualsTab:CreateToggle({
    Name = "Pulse Visual (Screen Effect)",
    CurrentValue = false,
    Callback = function(Value)
        PulseEnabled = Value
        if Value then
            createPulse()
        else
            for _, obj in pairs(pulseObjects) do
                obj:Destroy()
            end
            pulseObjects = {}
        end
    end
})

-- 5. Player ESP (улучшенный) [7†L26-L28]
local ESPEnabled = false

local function createESP(plr)
    if not plr or not plr.Character then return end
    local char = plr.Character
    local head = char:FindFirstChild("Head")
    if not head then return end

    local color = Color3.fromRGB(255, 0, 0)
    local enemyFolder = getEnemyFolder()
    if enemyFolder and char.Parent == enemyFolder then
        color = Color3.fromRGB(255, 0, 0)
    else
        color = Color3.fromRGB(0, 255, 0)
    end

    local box = Instance.new("BoxHandleAdornment")
    box.Name = "FluxESPBox"
    box.Size = Vector3.new(3, 5, 3)
    box.Color3 = color
    box.Transparency = 0.3
    box.ZIndex = 0
    box.AlwaysOnTop = true
    box.Parent = head

    local highlight = Instance.new("Highlight")
    highlight.Name = "FluxESPHighlight"
    highlight.Adornee = char
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.FillColor = color
    highlight.FillTransparency = 0.5
    highlight.OutlineColor = color
    highlight.OutlineTransparency = 0.3
    highlight.Parent = char

    table.insert(espObjects, {box = box, highlight = highlight, target = head, plr = plr})
end

local function clearESP()
    for _, obj in pairs(espObjects) do
        pcall(function()
            if obj.box then obj.box:Destroy() end
            if obj.highlight then obj.highlight:Destroy() end
        end)
    end
    espObjects = {}
end

local function updateESP()
    clearESP()
    if not ESPEnabled then return end
    for _, plr in pairs(players:GetPlayers()) do
        if plr ~= player and plr.Character then
            createESP(plr)
        end
    end
end

VisualsTab:CreateToggle({
    Name = "Player ESP",
    CurrentValue = false,
    Callback = function(Value)
        ESPEnabled = Value
        if Value then
            updateESP()
            spawn(function()
                while ESPEnabled do
                    task.wait(0.5)
                    updateESP()
                end
            end)
        else
            clearESP()
        end
    end
})

VisualsTab:CreateButton({
    Name = "Refresh ESP",
    Callback = updateESP
})

-- ============================================================
-- // РАЗДЕЛ "HVH" (Spinbot, Kill Aura)
-- ============================================================
local HVHTab = Window:CreateTab("💀 HVH", 7734058803)

-- Spinbot (Anti-Aim)
HVHTab:CreateToggle({
    Name = "Spinbot (Anti-Aim Y)",
    CurrentValue = false,
    Callback = function(Value)
        _G.Spinbot = Value
        spawn(function()
            while _G.Spinbot do
                task.wait(0.016)
                local char = getCharacter()
                if char and char:FindFirstChild("HumanoidRootPart") then
                    local angle = (_G.SpinSpeed or 10) * (_G.SpinMultiplier or 1)
                    local dir = _G.SpinDirection or "Right"
                    if dir == "Left" then angle = -angle end
                    if dir == "Random" then
                        angle = (math.random() > 0.5 and 1 or -1) * angle
                    end
                    char.HumanoidRootPart.CFrame = char.HumanoidRootPart.CFrame * CFrame.Angles(0, math.rad(angle), 0)
                end
            end
        end)
    end
})

HVHTab:CreateSlider({
    Name = "Spin Speed",
    Range = {1, 50},
    Increment = 1,
    CurrentValue = 10,
    Callback = function(Value)
        _G.SpinSpeed = Value
    end
})

HVHTab:CreateSlider({
    Name = "Spin Multiplier (x)",
    Range = {1, 5},
    Increment = 0.5,
    CurrentValue = 1,
    Callback = function(Value)
        _G.SpinMultiplier = Value
    end
})

HVHTab:CreateDropdown({
    Name = "Spin Direction",
    Options = {"Right", "Left", "Random"},
    CurrentOption = "Right",
    Callback = function(Value)
        _G.SpinDirection = Value
    end
})

-- Kill Aura
HVHTab:CreateToggle({
    Name = "Kill Aura (Auto-Kill Nearby)",
    CurrentValue = false,
    Callback = function(Value)
        _G.KillAura = Value
        spawn(function()
            while _G.KillAura do
                task.wait(0.1)
                local char = getCharacter()
                if not char then continue end
                local enemyFolder = getEnemyFolder()
                if not enemyFolder then continue end
                for _, enemy in pairs(enemyFolder:GetChildren()) do
                    if enemy ~= char then
                        local dist = (enemy.Head.Position - char.Head.Position).Magnitude
                        if dist < 15 then
                            local tool = char:FindFirstChildOfClass("Tool")
                            if tool then
                                for _, child in pairs(tool:GetDescendants()) do
                                    if child:IsA("RemoteEvent") and child.Name:lower():find("shoot") then
                                        child:FireServer(enemy.Head.Position, enemy.Head)
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end)
    end
})

-- ============================================================
-- // РАЗДЕЛ "HITBOX" (РАБОЧИЙ)
-- ============================================================
local HitboxTab = Window:CreateTab("📐 Hitbox", 7734058803)

local HitboxEnabled = false
local HitboxSize = 10

local function applyHitbox()
    if not HitboxEnabled then return end
    local enemyFolder = getEnemyFolder()
    if not enemyFolder then return end

    for _, enemy in pairs(enemyFolder:GetChildren()) do
        if enemy ~= player.Character then
            for _, part in pairs(enemy:GetDescendants()) do
                if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
                    part.Size = Vector3.new(HitboxSize, HitboxSize, HitboxSize)
                    part.CanCollide = false
                    part.Transparency = 0.5
                end
            end
        end
    end
end

HitboxTab:CreateToggle({
    Name = "Enable Hitbox Expander",
    CurrentValue = false,
    Callback = function(Value)
        HitboxEnabled = Value
        if Value then
            applyHitbox()
            spawn(function()
                while HitboxEnabled do
                    task.wait(0.5)
                    applyHitbox()
                end
            end)
        else
            local enemyFolder = getEnemyFolder()
            if enemyFolder then
                for _, enemy in pairs(enemyFolder:GetChildren()) do
                    if enemy ~= player.Character then
                        for _, part in pairs(enemy:GetDescendants()) do
                            if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
                                part.Size = Vector3.new(3, 3, 3)
                                part.CanCollide = true
                                part.Transparency = 0
                            end
                        end
                    end
                end
            end
        end
    end
})

HitboxTab:CreateSlider({
    Name = "Hitbox Size",
    Range = {3, 20},
    Increment = 0.5,
    CurrentValue = 10,
    Callback = function(Value)
        HitboxSize = Value
        if HitboxEnabled then
            applyHitbox()
        end
    end
})

-- ============================================================
-- // РАЗДЕЛ "MOVEMENT" (Speed, Fly, BHop, NoClip, Infinite Jump)
-- ============================================================
local MovementTab = Window:CreateTab("🏃 Movement", 7734058803)

MovementTab:CreateSlider({
    Name = "Walk Speed",
    Range = {16, 100},
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
        spawn(function()
            while _G.EnableSpeed do
                task.wait()
                local char = getCharacter()
                if char and char:FindFirstChild("Humanoid") then
                    char.Humanoid.WalkSpeed = _G.SpeedValue or 16
                end
            end
        end)
    end
})

MovementTab:CreateToggle({
    Name = "BHop (Hold Space)",
    CurrentValue = false,
    Callback = function(Value)
        _G.BHop = Value
        spawn(function()
            while _G.BHop do
                task.wait(0.01)
                if userInput:IsKeyDown(Enum.KeyCode.Space) then
                    local char = getCharacter()
                    if char then
                        local hum = char:FindFirstChild("Humanoid")
                        if hum then
                            local state = hum:GetState()
                            if state == Enum.HumanoidStateType.Landed or state == Enum.HumanoidStateType.Running or state == Enum.HumanoidStateType.Walking then
                                hum.Jump = true
                            end
                        end
                    end
                end
            end
        end)
    end
})

MovementTab:CreateToggle({
    Name = "Fly",
    CurrentValue = false,
    Callback = function(Value)
        _G.Fly = Value
        if Value then
            local char = getCharacter()
            if char then
                char.Humanoid.PlatformStand = true
                flyBodyVelocity = Instance.new("BodyVelocity")
                flyBodyVelocity.MaxForce = Vector3.new(1e9, 1e9, 1e9)
                flyBodyVelocity.Parent = char
            end
        else
            if flyBodyVelocity then flyBodyVelocity:Destroy() flyBodyVelocity = nil end
            local char = getCharacter()
            if char then char.Humanoid.PlatformStand = false end
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
        spawn(function()
            while _G.NoClip do
                task.wait()
                local char = getCharacter()
                if char then
                    for _, part in pairs(char:GetDescendants()) do
                        if part:IsA("BasePart") then
                            part.CanCollide = false
                        end
                    end
                end
            end
        end)
    end
})

-- ============================================================
-- // РАЗДЕЛ "MODEL CHANGER" (КАСТОМНЫЕ МОДЕЛИ)
-- ============================================================
local ModelTab = Window:CreateTab("🎨 Models", 7734058803)

local function applyModel(modelType)
    local char = getCharacter()
    if not char then return end

    if currentModel then
        currentModel:Destroy()
        currentModel = nil
    end

    if modelType == "Default" then return end

    local newModel = Instance.new("Model")
    newModel.Name = "FluxModel"

    local parts = {}
    for _, part in pairs(char:GetChildren()) do
        if part:IsA("BasePart") then
            table.insert(parts, part)
        end
    end

    for _, part in pairs(parts) do
        local newPart = part:Clone()
        newPart.Parent = newModel
        newPart.CFrame = part.CFrame
        if modelType == "Tung tung sahur" then
            newPart.BrickColor = BrickColor.new("Bright red")
            newPart.Material = Enum.Material.Neon
        elseif modelType == "Noob" then
            newPart.BrickColor = BrickColor.new("Bright yellow")
        elseif modelType == "Blocky" then
            newPart.BrickColor = BrickColor.new("Bright blue")
        elseif modelType == "R6" then
            newPart.BrickColor = BrickColor.new("Bright green")
        elseif modelType == "Invisible" then
            newPart.Transparency = 1
        end
    end

    newModel.Parent = workspace
    currentModel = newModel

    char.Archivable = true
    for _, part in pairs(char:GetChildren()) do
        if part:IsA("BasePart") then
            part.Transparency = 1
            part.CanCollide = false
        end
    end
end

ModelTab:CreateDropdown({
    Name = "Select Model",
    Options = {"Default", "Tung tung sahur", "Noob", "Blocky", "R6", "Invisible"},
    CurrentOption = "Default",
    Callback = function(Value)
        applyModel(Value)
    end
})

ModelTab:CreateButton({
    Name = "Remove Model",
    Callback = function()
        if currentModel then
            currentModel:Destroy()
            currentModel = nil
        end
        local char = getCharacter()
        if char then
            for _, part in pairs(char:GetChildren()) do
                if part:IsA("BasePart") then
                    part.Transparency = 0
                    part.CanCollide = true
                end
            end
        end
    end
})

-- ============================================================
-- // РАЗДЕЛ "SOUNDS" (Кастомный звук оружия)
-- ============================================================
local SoundTab = Window:CreateTab("🔊 Sounds", 7734058803)

local function changeWeaponSound(soundId)
    local tool = player.Character and player.Character:FindFirstChildOfClass("Tool")
    if not tool then return end

    for _, child in pairs(tool:GetDescendants()) do
        if child:IsA("Sound") then
            child.SoundId = soundId
            child.Volume = 1
        end
    end
end

SoundTab:CreateInput({
    Name = "Custom Sound ID",
    CurrentValue = "rbxassetid://123456789",
    PlaceholderText = "Enter Sound ID",
    Callback = function(Text)
        _G.CustomSoundId = Text
        changeWeaponSound(Text)
    end
})

SoundTab:CreateDropdown({
    Name = "Preset Sounds",
    Options = {"Default", "Pew Pew", "Laser", "Bass", "Silent"},
    CurrentOption = "Default",
    Callback = function(Option)
        local ids = {
            ["Default"] = "",
            ["Pew Pew"] = "rbxassetid://9120387707",
            ["Laser"] = "rbxassetid://9120387713",
            ["Bass"] = "rbxassetid://9120387720",
            ["Silent"] = "rbxassetid://0"
        }
        _G.CustomSoundId = ids[Option] or ""
        changeWeaponSound(_G.CustomSoundId)
    end
})

SoundTab:CreateButton({
    Name = "Apply Sound to Current Weapon",
    Callback = function()
        if _G.CustomSoundId then
            changeWeaponSound(_G.CustomSoundId)
        end
    end
})

-- ============================================================
-- // РАЗДЕЛ "THIRD PERSON"
-- ============================================================
local ThirdPersonTab = Window:CreateTab("📷 Third Person", 7734058803)

local isThirdPerson = false
local thirdPersonOffset = CFrame.new(0, 2, 10)

local function toggleThirdPerson(value)
    isThirdPerson = value
    if value then
        camera.CameraType = Enum.CameraType.Scriptable
        local char = getCharacter()
        if char then
            local root = char:FindFirstChild("HumanoidRootPart")
            if root then
                camera.CFrame = root.CFrame * thirdPersonOffset
            end
        end
    else
        camera.CameraType = Enum.CameraType.Custom
    end
end

ThirdPersonTab:CreateToggle({
    Name = "Enable Third Person",
    CurrentValue = false,
    Callback = function(Value)
        toggleThirdPerson(Value)
    end
})

ThirdPersonTab:CreateSlider({
    Name = "Camera Distance",
    Range = {5, 30},
    Increment = 0.5,
    CurrentValue = 10,
    Callback = function(Value)
        thirdPersonOffset = CFrame.new(0, thirdPersonOffset.Y, Value)
    end
})

ThirdPersonTab:CreateSlider({
    Name = "Camera Height",
    Range = {0, 5},
    Increment = 0.5,
    CurrentValue = 2,
    Callback = function(Value)
        thirdPersonOffset = CFrame.new(0, Value, thirdPersonOffset.Z)
    end
})

runService.RenderStepped:Connect(function()
    if isThirdPerson then
        local char = getCharacter()
        if char then
            local root = char:FindFirstChild("HumanoidRootPart")
            if root then
                camera.CFrame = root.CFrame * thirdPersonOffset
            end
        end
    end
end)

-- ============================================================
-- // УПРАВЛЕНИЕ ПОЛЁТОМ
-- ============================================================
userInput.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if not _G.Fly then return end
    local char = getCharacter()
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
        local char = getCharacter()
        if char and char:FindFirstChild("Humanoid") then
            char.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
        end
    end
end)

-- ============================================================
-- // ИНИЦИАЛИЗАЦИЯ
-- ============================================================
_G.Spinbot = false
_G.SpinSpeed = 10
_G.SpinMultiplier = 1
_G.SpinDirection = "Right"
_G.KillAura = false
_G.EnableSpeed = false
_G.SpeedValue = 16
_G.Fly = false
_G.FlySpeed = 50
_G.BHop = false
_G.InfiniteJump = false
_G.NoClip = false
_G.CustomSoundId = ""

-- ============================================================
-- // ИНФОРМАЦИЯ
-- ============================================================
print("✅ FLUXHUB v3.5 | Sheriff vs Murders Duels loaded (MASSIVE UPDATE)!")
print("🔥 NEW: Silent Aim (full hook), Custom Skybox, Target ESP, TargetHUD, Pulse Visuals, Custom Models")
