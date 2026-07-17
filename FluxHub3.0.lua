-- // FLUXHUB | Sheriff vs Murders Duels v3.0 (FULL REWORK)
-- // EDUCATIONAL PURPOSE ONLY
-- // DISCLAIMER: For Lua learning and research only. Not for actual use.
-- // ДОБАВЛЕНО: Aimbot (Silent + Rage), Hitbox Expander, Custom Weapon Sounds, Spinbot, Kill Aura, BHop, Model Changer

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
    LoadingSubtitle = "by FeVilAi (REWORKED)",
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
local espObjects = {}
local flyBodyVelocity = nil
local isThirdPerson = false
local thirdPersonOffset = CFrame.new(0, 2, 10)
local mouse = player:GetMouse()
local currentModel = nil
local baseSizes = {}

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

-- ============================================================
-- // РАЗДЕЛ "AIMBOT" (Silent Aim + Rage Mode) [9†L4-L8][8†L4-L13]
-- ============================================================
local AimbotTab = Window:CreateTab("🎯 Aimbot", 7734058803)

local SilentAimEnabled = false
local RageMode = false
local AimPart = "Head"
local FOVRadius = 150
local Wallbang = false
local MAX_DISTANCE = 150

-- Получение ближайшего врага через атрибуты [9†L11-L27]
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
                if worldDist <= MAX_DISTANCE then
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

-- Silent Aim через hookmetamethod [9†L27-L32]
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

-- Rage Mode (авто-атака по всем) [8†L8-L9]
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
            -- Отключаем хук
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
    Name = "Max Distance",
    Range = {50, 300},
    Increment = 10,
    CurrentValue = 150,
    Callback = function(Value)
        MAX_DISTANCE = Value
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
-- // РАЗДЕЛ "ESP" [10†L9-L10]
-- ============================================================
local ESPTab = Window:CreateTab("👁️ ESP", 7734058803)

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

ESPTab:CreateToggle({
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

ESPTab:CreateButton({
    Name = "Refresh ESP",
    Callback = updateESP
})

-- ============================================================
-- // РАЗДЕЛ "HVH" (Spinbot, Kill Aura) [8†L9]
-- ============================================================
local HVHTab = Window:CreateTab("💀 HVH", 7734058803)

-- Spinbot (Anti-Aim) [8†L9]
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

-- Kill Aura [8†L8-L9]
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
-- // РАЗДЕЛ "HITBOX" (РАБОЧИЙ) [10†L9-L10]
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
-- // РАЗДЕЛ "MODEL CHANGER" (РАБОЧИЙ)
-- ============================================================
local ModelTab = Window:CreateTab("🎨 Model", 7734058803)

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
    Options = {"Default", "Tung tung sahur", "Noob", "Blocky", "R6"},
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
    
    -- Ищем звуки в инструменте и его потомках
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
print("✅ FLUXHUB v3.0 | Sheriff vs Murders Duels loaded (REWORKED)!")
print("🔥 NEW: Aimbot (Silent + Rage), Custom Weapon Sounds, Hitbox Expander, Spinbot, Kill Aura, BHop, Model Changer")
