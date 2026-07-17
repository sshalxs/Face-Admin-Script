-- // FLUXHUB | Sheriff vs Murders Duels v2.0 (HVH + Model Changer)
-- // EDUCATIONAL PURPOSE ONLY
-- // DISCLAIMER: For Lua learning and research only. Not for actual use.
-- // ДОБАВЛЕНО: BHop, Model Changer (Tung tung sahur), Silent Aim, Spinbot, Kill Aura, Hitbox Expander, Rage Mode

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
    LoadingSubtitle = "by FeVilAi (HVH Edition)",
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
local antiAFKThread = nil
local isThirdPerson = false
local thirdPersonOffset = CFrame.new(0, 2, 10)
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

local function pressKey(key)
    pcall(function()
        virtualInput:SendKeyEvent(key, Enum.KeyState.Press, false)
        task.wait(0.05)
        virtualInput:SendKeyEvent(key, Enum.KeyState.Release, false)
    end)
end

-- ============================================================
-- // ОПРЕДЕЛЕНИЕ РОЛИ (Sheriff, Murderer, Spectator)
-- ============================================================
local function getPlayerRole(plr)
    if not plr or not plr.Character then return "Spectator" end
    local char = plr.Character
    if plr:FindFirstChild("Murderer") or char:FindFirstChild("MurdererTag") or char:FindFirstChild("IsMurderer") then
        return "Murderer"
    end
    if plr:FindFirstChild("Sheriff") or char:FindFirstChild("SheriffTag") or char:FindFirstChild("IsSheriff") then
        return "Sheriff"
    end
    local hum = char:FindFirstChild("Humanoid")
    if not hum or hum.Health <= 0 then
        return "Spectator"
    end
    return "Spectator"
end

local function getRoleColor(role)
    if role == "Murderer" then return Color3.fromRGB(255, 0, 0) end
    if role == "Sheriff" then return Color3.fromRGB(0, 0, 255) end
    return Color3.fromRGB(128, 128, 128)
end

-- ============================================================
-- // РАЗДЕЛ "AIMBOT" (Silent Aim + Rage)
-- ============================================================
local AimbotTab = Window:CreateTab("🎯 Aimbot", 7734058803)

local SilentAimEnabled = false
local RageMode = false
local AimPart = "Head"
local FOVRadius = 150
local Wallbang = false

-- Silent Aim (основная функция)
local function getNearestEnemy()
    local char = getCharacter()
    if not char then return nil end
    local nearest = nil
    local minDist = math.huge
    local mousePos = Vector2.new(userInput:GetMouseLocation().X, userInput:GetMouseLocation().Y)

    for _, v in pairs(players:GetPlayers()) do
        if v ~= player and v.Character then
            local targetChar = v.Character
            local part = targetChar:FindFirstChild(AimPart or "Head")
            if part then
                local pos, onScreen = camera:WorldToViewportPoint(part.Position)
                if not Wallbang and not onScreen then continue end
                local dist = (part.Position - char.Head.Position).Magnitude
                if onScreen then
                    local screenPos = Vector2.new(pos.X, pos.Y)
                    local fovDist = (screenPos - mousePos).Magnitude
                    if fovDist <= (FOVRadius or 150) and dist < minDist then
                        minDist = dist
                        nearest = targetChar
                    end
                elseif Wallbang then
                    if dist < minDist then
                        minDist = dist
                        nearest = targetChar
                    end
                end
            end
        end
    end
    return nearest
end

-- Rage Mode (авто-атака по всем)
local function rageMode()
    if not RageMode then return end
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

AimbotTab:CreateToggle({
    Name = "Silent Aim",
    CurrentValue = false,
    Callback = function(Value)
        SilentAimEnabled = Value
    end
})

AimbotTab:CreateToggle({
    Name = "Rage Mode (Auto-Kill All)",
    CurrentValue = false,
    Callback = function(Value)
        RageMode = Value
        spawn(function()
            while RageMode do
                task.wait(0.1)
                rageMode()
            end
        end)
    end
})

AimbotTab:CreateDropdown({
    Name = "Aim Part",
    Options = {"Head", "Torso", "Legs"},
    CurrentOption = "Head",
    Callback = function(Option)
        AimPart = Option
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

AimbotTab:CreateToggle({
    Name = "Wallbang",
    CurrentValue = false,
    Callback = function(Value)
        Wallbang = Value
    end
})

-- Silent Aim Loop
runService.RenderStepped:Connect(function()
    if not SilentAimEnabled then return end
    local target = getNearestEnemy()
    if target then
        local part = target:FindFirstChild(AimPart or "Head")
        if part then
            local tool = player.Character and player.Character:FindFirstChildOfClass("Tool")
            if tool then
                for _, child in pairs(tool:GetDescendants()) do
                    if child:IsA("RemoteEvent") and child.Name:lower():find("shoot") then
                        child:FireServer(part.Position, part)
                        return
                    end
                end
            end
        end
    end
end)

-- ============================================================
-- // РАЗДЕЛ "ESP"
-- ============================================================
local ESPTab = Window:CreateTab("👁️ ESP", 7734058803)

local ESPEnabled = false

local function createESP(plr)
    if not plr or not plr.Character then return end
    local char = plr.Character
    local head = char:FindFirstChild("Head")
    if not head then return end

    local role = getPlayerRole(plr)
    local color = getRoleColor(role)

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
    Name = "Player ESP (Role-Based)",
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
-- // РАЗДЕЛ "HVH" (Spinbot, Kill Aura, Anti-Aim)
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
                    local angle = _G.SpinSpeed or 10
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
    Range = {1, 30},
    Increment = 1,
    CurrentValue = 10,
    Callback = function(Value)
        _G.SpinSpeed = Value
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

-- Kill Aura (авто-убийство в радиусе)
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
                for _, v in pairs(players:GetPlayers()) do
                    if v ~= player and v.Character then
                        local target = v.Character
                        local dist = (target.Head.Position - char.Head.Position).Magnitude
                        if dist < 15 then
                            local tool = char:FindFirstChildOfClass("Tool")
                            if tool then
                                for _, child in pairs(tool:GetDescendants()) do
                                    if child:IsA("RemoteEvent") and child.Name:lower():find("shoot") then
                                        child:FireServer(target.Head.Position, target.Head)
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

-- Hitbox Expander
HVHTab:CreateSlider({
    Name = "Hitbox Expander (Enemies)",
    Range = {3, 20},
    Increment = 0.5,
    CurrentValue = 3,
    Callback = function(Value)
        _G.HitboxSize = Value
        for _, v in pairs(players:GetPlayers()) do
            if v ~= player and v.Character then
                for _, part in pairs(v.Character:GetDescendants()) do
                    if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
                        if not baseSizes[part] then
                            baseSizes[part] = part.Size
                        end
                        local scale = (Value or 3) / 3
                        part.Size = baseSizes[part] * scale
                    end
                end
            end
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

-- BHop (Bunny Hop)
MovementTab:CreateToggle({
    Name = "BHop (Hold Space)",
    CurrentValue = false,
    Callback = function(Value)
        _G.BHop = Value
        spawn(function()
            while _G.BHop do
                task.wait()
                if userInput:IsKeyDown(Enum.KeyCode.Space) then
                    local char = getCharacter()
                    if char and char:FindFirstChild("Humanoid") then
                        local hum = char.Humanoid
                        if hum:GetState() ~= Enum.HumanoidStateType.Jumping and hum:GetState() ~= Enum.HumanoidStateType.Freefall then
                            hum.Jump = true
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
-- // РАЗДЕЛ "MODEL CHANGER" (Тунг тунг сахур)
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
    local newPart = Instance.new("Part")
    newPart.Size = Vector3.new(2, 2, 2)
    newPart.Position = char.HumanoidRootPart.Position
    newPart.Anchored = true
    newPart.Parent = newModel
    newModel.Parent = workspace

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
    currentModel = newModel
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
    end
})

-- ============================================================
-- // РАЗДЕЛ "THIRD PERSON" (Свободная камера)
-- ============================================================
local ThirdPersonTab = Window:CreateTab("📷 Third Person", 7734058803)

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
    Name = "Enable Third Person (Free Camera)",
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
-- // УПРАВЛЕНИЕ ПОЛЁТОМ (WASD + Space + Shift)
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

-- Infinite Jump
userInput.JumpRequest:Connect(function()
    if _G.InfiniteJump then
        local char = getCharacter()
        if char and char:FindFirstChild("Humanoid") then
            char.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
        end
    end
end)

-- ============================================================
-- // РАЗДЕЛ "MISC" (Anti-AFK)
-- ============================================================
local MiscTab = Window:CreateTab("⚙️ Misc", 7734058803)

MiscTab:CreateToggle({
    Name = "Anti-AFK",
    CurrentValue = false,
    Callback = function(Value)
        _G.AntiAFK = Value
        if Value then
            antiAFKThread = task.spawn(function()
                while _G.AntiAFK do
                    task.wait(30)
                    local char = getCharacter()
                    if char and char:FindFirstChild("Humanoid") then
                        char.Humanoid:Move(Vector3.new(0, 0, 0))
                    end
                end
            end)
        else
            if antiAFKThread then antiAFKThread = nil end
        end
    end
})

-- ============================================================
-- // ИНИЦИАЛИЗАЦИЯ ВСЕХ ГЛОБАЛЬНЫХ ПЕРЕМЕННЫХ
-- ============================================================
_G.SilentAim = false
_G.RageMode = false
_G.AimPart = "Head"
_G.FOVRadius = 150
_G.Wallbang = false
_G.Spinbot = false
_G.SpinSpeed = 10
_G.SpinDirection = "Right"
_G.KillAura = false
_G.HitboxSize = 3
_G.EnableSpeed = false
_G.SpeedValue = 16
_G.Fly = false
_G.FlySpeed = 50
_G.BHop = false
_G.InfiniteJump = false
_G.NoClip = false
_G.AntiAFK = false
_G.ESPEnabled = false
_G.ThirdPerson = false
_G.SelectedModel = "Default"

-- ============================================================
-- // ИНФОРМАЦИЯ
-- ============================================================
print("✅ FLUXHUB v2.0 | Sheriff vs Murders Duels loaded!")
print("🔥 HVH Features: Silent Aim, Rage Mode, Spinbot, Kill Aura, Hitbox Expander, BHop, Model Changer")
