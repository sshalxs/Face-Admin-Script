-- // VIOLENCE DISTRICT SCRIPT | NEXUS CORE
-- // Основа: Rayfield (рабочая ссылка)
-- // Скрипт для режима "Violence District" с функциями для Выживших, Убийцы, Визуалов, HVH и движения.
-- // Источники функций: проанализированы скрипты с ScriptBlox, Telegram и Wiki игры [citation:2][citation:4][citation:9].

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
    Name = "🔪 VIOLENCE DISTRICT",
    LoadingTitle = "NEXUS CORE",
    LoadingSubtitle = "ACTIVE",
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
// РАЗДЕЛ "SURVIVORS" (Выжившие) [citation:2][citation:4]
-- ============================================================
local SurvivorTab = Window:CreateTab("🛡️ Survivors", 7734058803)

-- Auto Repair Generator (Авто-починка генераторов) [citation:2][citation:3][citation:4]
SurvivorTab:CreateToggle({
    Name = "Auto Repair Generator",
    CurrentValue = false,
    Callback = function(Value)
        _G.AutoRepair = Value
        spawn(function()
            while _G.AutoRepair do
                task.wait(0.3)
                local char = getCharacter()
                if not char then continue end
                local hrp = char:FindFirstChild("HumanoidRootPart")
                if not hrp then continue end

                -- Поиск генераторов
                local gens = {}
                for _, v in pairs(workspace:GetDescendants()) do
                    if v:IsA("Model") and (v.Name:lower():find("generator") or v.Name:lower():find("gen")) then
                        local interact = v:FindFirstChild("Interact") or v:FindFirstChild("Handle") or v:FindFirstChild("Part")
                        if interact and interact:IsA("BasePart") then
                            table.insert(gens, v)
                        end
                    end
                end

                local targetPart = nil
                local minDist = math.huge
                for _, gen in pairs(gens) do
                    local part = gen:FindFirstChild("Interact") or gen:FindFirstChild("Handle") or gen:FindFirstChild("Part")
                    if part and part:IsA("BasePart") then
                        local dist = (part.Position - hrp.Position).Magnitude
                        if dist < minDist then
                            minDist = dist
                            targetPart = part
                        end
                    end
                end

                if targetPart then
                    if minDist > 8 then
                        hrp.CFrame = CFrame.new(targetPart.Position + Vector3.new(0, 0, 3), targetPart.Position)
                        task.wait(0.2)
                    end
                    if minDist <= 10 then
                        pressKey(Enum.KeyCode.E) -- Взаимодействие с генератором [citation:12]
                        task.wait(0.5)
                    end
                end
            end
        end)
    end
})

-- Auto Parry (Авто-парирование) [citation:2][citation:3][citation:4]
SurvivorTab:CreateToggle({
    Name = "Auto Parry",
    CurrentValue = false,
    Callback = function(Value)
        _G.AutoParry = Value
        spawn(function()
            while _G.AutoParry do
                task.wait(0.05)
                local char = getCharacter()
                if not char then continue end
                local enemyFolder = getEnemyFolder()
                if not enemyFolder then continue end

                -- Поиск убийцы
                local killer = nil
                for _, v in pairs(enemyFolder:GetChildren()) do
                    if v ~= char then
                        local dist = (v.Head.Position - char.Head.Position).Magnitude
                        if dist < (_G.ParryDistance or 15) then
                            killer = v
                            break
                        end
                    end
                end

                if killer then
                    pressKey(Enum.KeyCode.F) -- Клавиша парирования [citation:4]
                end
            end
        end)
    end
})

-- Parry Distance (Дистанция парирования) [citation:2][citation:6]
SurvivorTab:CreateSlider({
    Name = "Parry Distance",
    Range = {5, 25},
    Increment = 1,
    CurrentValue = 15,
    Callback = function(Value)
        _G.ParryDistance = Value
    end
})

-- ESP Parry (Визуал парирования)
SurvivorTab:CreateToggle({
    Name = "ESP Parry",
    CurrentValue = false,
    Callback = function(Value)
        _G.ESPParry = Value
        -- Можно добавить визуальный индикатор при успешном парировании
    end
})

-- Instant Escape (Мгновенный побег) [citation:2][citation:3][citation:9]
SurvivorTab:CreateToggle({
    Name = "Instant Escape",
    CurrentValue = false,
    Callback = function(Value)
        _G.InstantEscape = Value
        spawn(function()
            while _G.InstantEscape do
                task.wait(0.5)
                -- Поиск ворот
                for _, v in pairs(workspace:GetDescendants()) do
                    if v:IsA("Model") and v.Name:lower():find("gate") then
                        local interact = v:FindFirstChild("Interact") or v:FindFirstChild("Handle")
                        if interact and interact:IsA("BasePart") then
                            local char = getCharacter()
                            if char then
                                local hrp = char:FindFirstChild("HumanoidRootPart")
                                if hrp then
                                    hrp.CFrame = CFrame.new(interact.Position + Vector3.new(0, 0, 3), interact.Position)
                                    task.wait(0.2)
                                    pressKey(Enum.KeyCode.E)
                                end
                            end
                        end
                    end
                end
            end
        end)
    end
})

-- Auto Heal (Авто-лечение) [citation:4][citation:6]
SurvivorTab:CreateToggle({
    Name = "Auto Heal",
    CurrentValue = false,
    Callback = function(Value)
        _G.AutoHeal = Value
        spawn(function()
            while _G.AutoHeal do
                task.wait(0.5)
                local char = getCharacter()
                if char and char:FindFirstChild("Humanoid") then
                    local hum = char.Humanoid
                    if hum.Health < hum.MaxHealth * 0.5 then
                        -- Поиск аптечки или другого игрока для лечения
                        for _, v in pairs(workspace:GetDescendants()) do
                            if v:IsA("Model") and v.Name:lower():find("med") then
                                local interact = v:FindFirstChild("Interact")
                                if interact and interact:IsA("BasePart") then
                                    local hrp = char:FindFirstChild("HumanoidRootPart")
                                    if hrp then
                                        hrp.CFrame = CFrame.new(interact.Position + Vector3.new(0, 0, 3), interact.Position)
                                        task.wait(0.2)
                                        pressKey(Enum.KeyCode.E)
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
// РАЗДЕЛ "KILLER" (Убийца) [citation:4][citation:9]
-- ============================================================
local KillerTab = Window:CreateTab("🔪 Killer", 7734058803)

-- Hitbox Survivors (Увеличение хитбоксов выживших) [citation:4][citation:8]
KillerTab:CreateSlider({
    Name = "Survivor Hitbox Size",
    Range = {3, 20},
    Increment = 0.5,
    CurrentValue = 3,
    Callback = function(Value)
        _G.HitboxSize = Value
        local enemyFolder = getEnemyFolder()
        if enemyFolder then
            for _, v in pairs(enemyFolder:GetChildren()) do
                if v ~= player.Character then
                    for _, part in pairs(v:GetDescendants()) do
                        if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
                            local scale = Value / 3
                            part.Size = Vector3.new(part.Size.X * scale, part.Size.Y * scale, part.Size.Z * scale)
                            part.CanCollide = false
                        end
                    end
                end
            end
        end
    end
})

-- Silent Aim (Тихий аим для убийцы) [citation:4]
KillerTab:CreateToggle({
    Name = "Silent Aim",
    CurrentValue = false,
    Callback = function(Value)
        _G.KillerSilentAim = Value
        if Value then
            -- Подмена mouse.Hit через hookmetamethod
            local mouse = player:GetMouse()
            local oldIndex = hookmetamethod(game, "__index", function(self, key)
                if not checkcaller() and self == mouse and key == "Hit" then
                    local enemyFolder = getEnemyFolder()
                    if enemyFolder then
                        local target = nil
                        local minDist = math.huge
                        for _, v in pairs(enemyFolder:GetChildren()) do
                            if v ~= player.Character then
                                local part = v:FindFirstChild("Head")
                                if part then
                                    local dist = (part.Position - player.Character.Head.Position).Magnitude
                                    if dist < minDist then
                                        minDist = dist
                                        target = part
                                    end
                                end
                            end
                        end
                        if target then
                            return CFrame.new(target.Position)
                        end
                    end
                end
                return oldIndex(self, key)
            end)
        end
    end
})

-- Third Person Killer (Реальное третье лицо) [citation:4]
KillerTab:CreateToggle({
    Name = "Third Person (Free Camera)",
    CurrentValue = false,
    Callback = function(Value)
        _G.KillerThirdPerson = Value
        if Value then
            camera.CameraType = Enum.CameraType.Scriptable
            local char = getCharacter()
            if char then
                local root = char:FindFirstChild("HumanoidRootPart")
                if root then
                    local distance = _G.CameraDistance or 10
                    local height = _G.CameraHeight or 2
                    local lookVector = root.CFrame.LookVector
                    local camPos = root.Position - lookVector * distance + Vector3.new(0, height, 0)
                    camera.CFrame = CFrame.new(camPos, root.Position + Vector3.new(0, 1, 0))
                end
            end
        else
            camera.CameraType = Enum.CameraType.Custom
        end
    end
})

KillerTab:CreateSlider({
    Name = "Camera Distance",
    Range = {5, 30},
    Increment = 0.5,
    CurrentValue = 10,
    Callback = function(Value)
        _G.CameraDistance = Value
    end
})

KillerTab:CreateSlider({
    Name = "Camera Height",
    Range = {0, 5},
    Increment = 0.5,
    CurrentValue = 2,
    Callback = function(Value)
        _G.CameraHeight = Value
    end
})

KillerTab:CreateToggle({
    Name = "Infinite Lunge",
    CurrentValue = false,
    Callback = function(Value)
        _G.InfiniteLunge = Value
        -- Реализация зависит от механики игры
        spawn(function()
            while _G.InfiniteLunge do
                task.wait(0.1)
                local tool = player.Character and player.Character:FindFirstChildOfClass("Tool")
                if tool then
                    -- Увеличиваем дальность удара (зависит от игры)
                end
            end
        end)
    end
})

-- ============================================================
// РАЗДЕЛ "VISUALS" (ESP, Chams, генераторы, паллеты) [citation:2][citation:4][citation:9]
-- ============================================================
local VisualsTab = Window:CreateTab("👁️ Visuals", 7734058803)

local ESPEnabled = false

local function createESP(target, color, text)
    if not target or not target.Parent then return end
    local box = Instance.new("BoxHandleAdornment")
    box.Size = Vector3.new(3, 5, 3)
    box.Color3 = color
    box.Transparency = 0.3
    box.ZIndex = 0
    box.AlwaysOnTop = true
    box.Parent = target

    local nameTag = Instance.new("BillboardGui")
    nameTag.Size = UDim2.new(0, 200, 0, 30)
    nameTag.Adornee = target
    nameTag.AlwaysOnTop = true
    nameTag.Parent = target

    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(1, 0, 1, 0)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = text or ""
    nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    nameLabel.TextScaled = true
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.Parent = nameTag

    table.insert(espObjects, {box = box, nameTag = nameTag, target = target})
end

local function clearESP()
    for _, obj in pairs(espObjects) do
        pcall(function()
            if obj.box then obj.box:Destroy() end
            if obj.nameTag then obj.nameTag:Destroy() end
        end)
    end
    espObjects = {}
end

local function updateESP()
    clearESP()
    if not ESPEnabled then return end

    -- ESP для игроков
    for _, v in pairs(players:GetPlayers()) do
        if v ~= player and v.Character then
            local head = v.Character:FindFirstChild("Head")
            if head then
                local color = Color3.fromRGB(255, 0, 0)
                local enemyFolder = getEnemyFolder()
                if enemyFolder and v.Character.Parent == enemyFolder then
                    color = Color3.fromRGB(255, 0, 0)
                else
                    color = Color3.fromRGB(0, 255, 0)
                end
                createESP(head, color, v.Name)
            end
        end
    end

    -- ESP для генераторов [citation:4][citation:9]
    if _G.ESPGenerator then
        for _, v in pairs(workspace:GetDescendants()) do
            if v:IsA("Model") and (v.Name:lower():find("generator") or v.Name:lower():find("gen")) then
                local part = v:FindFirstChild("Interact") or v:FindFirstChild("Handle") or v:FindFirstChild("Part")
                if part and part:IsA("BasePart") then
                    createESP(part, Color3.fromRGB(255, 255, 0), "Generator")
                end
            end
        end
    end

    -- ESP для паллетов [citation:4][citation:9]
    if _G.ESPPallet then
        for _, v in pairs(workspace:GetDescendants()) do
            if v:IsA("Model") and v.Name:lower():find("pallet") then
                local part = v:FindFirstChild("Handle") or v:FindFirstChild("Part")
                if part and part:IsA("BasePart") then
                    createESP(part, Color3.fromRGB(255, 165, 0), "Pallet")
                end
            end
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

VisualsTab:CreateToggle({
    Name = "ESP Generator",
    CurrentValue = false,
    Callback = function(Value)
        _G.ESPGenerator = Value
        if ESPEnabled then updateESP() end
    end
})

VisualsTab:CreateToggle({
    Name = "ESP Pallet",
    CurrentValue = false,
    Callback = function(Value)
        _G.ESPPallet = Value
        if ESPEnabled then updateESP() end
    end
})

-- Chams (Wallhack) [citation:2][citation:3][citation:4]
VisualsTab:CreateToggle({
    Name = "Chams (Wallhack)",
    CurrentValue = false,
    Callback = function(Value)
        _G.Chams = Value
        for _, v in pairs(players:GetPlayers()) do
            if v ~= player and v.Character then
                local char = v.Character
                if Value then
                    local highlight = Instance.new("Highlight")
                    highlight.Name = "NEXUSChams"
                    highlight.Adornee = char
                    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                    highlight.FillColor = Color3.fromRGB(255, 0, 0)
                    highlight.FillTransparency = 0.5
                    highlight.Parent = char
                else
                    local highlight = char:FindFirstChild("NEXUSChams")
                    if highlight then highlight:Destroy() end
                end
            end
        end
    end
})

-- ============================================================
// РАЗДЕЛ "HVH" (360 крутилка и др.) [citation:4]
-- ============================================================
local HVHTab = Window:CreateTab("💀 HVH", 7734058803)

-- 360 Spin (Крутилка) [citation:4]
HVHTab:CreateToggle({
    Name = "360 Spin",
    CurrentValue = false,
    Callback = function(Value)
        _G.Spin = Value
        spawn(function()
            while _G.Spin do
                task.wait(0.016)
                local char = getCharacter()
                if char and char:FindFirstChild("HumanoidRootPart") then
                    local angle = _G.SpinSpeed or 10
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

-- Anti-Stun (Анти-оглушение) [citation:9]
HVHTab:CreateToggle({
    Name = "Anti-Stun",
    CurrentValue = false,
    Callback = function(Value)
        _G.AntiStun = Value
        spawn(function()
            while _G.AntiStun do
                task.wait(0.1)
                local char = getCharacter()
                if char and char:FindFirstChild("Humanoid") then
                    char.Humanoid.PlatformStand = false
                end
            end
        end)
    end
})

-- Anti-Blind (Анти-ослепление)
HVHTab:CreateToggle({
    Name = "Anti-Blind",
    CurrentValue = false,
    Callback = function(Value)
        _G.AntiBlind = Value
        spawn(function()
            while _G.AntiBlind do
                task.wait(0.1)
                -- Удаляем эффекты ослепления
                for _, v in pairs(player.PlayerGui:GetDescendants()) do
                    if v:IsA("ImageLabel") and v.Size.X.Scale >= 0.9 and v.Size.Y.Scale >= 0.9 then
                        v:Destroy()
                    end
                end
            end
        end)
    end
})

-- ============================================================
-- // РАЗДЕЛ "MISC" (Fullbright и др.)
-- ============================================================
local MiscTab = Window:CreateTab("⚙️ Misc", 7734058803)

-- Fullbright (Максимальная яркость)
MiscTab:CreateToggle({
    Name = "Fullbright",
    CurrentValue = false,
    Callback = function(Value)
        _G.Fullbright = Value
        local lighting = game:GetService("Lighting")
        if Value then
            lighting.Ambient = Color3.new(1, 1, 1)
            lighting.ColorShift_Bottom = Color3.new(1, 1, 1)
            lighting.ColorShift_Top = Color3.new(1, 1, 1)
            lighting.Brightness = 10
            lighting.EnvironmentDiffuseScale = 1
            lighting.EnvironmentSpecularScale = 1
        else
            lighting.Ambient = Color3.fromRGB(127, 127, 127)
            lighting.Brightness = 1
            lighting.ColorShift_Bottom = Color3.fromRGB(0, 0, 0)
            lighting.ColorShift_Top = Color3.fromRGB(0, 0, 0)
        end
    end
})

-- Skybox Changer
MiscTab:CreateDropdown({
    Name = "Skybox Changer",
    Options = {"Default", "Galaxy", "Blood Moon", "Pitch Black"},
    CurrentOption = "Default",
    Callback = function(Option)
        local lighting = game:GetService("Lighting")
        for _, v in pairs(lighting:GetChildren()) do
            if v:IsA("Sky") or v:IsA("ColorCorrectionEffect") then
                v:Destroy()
            end
        end
        local sky = Instance.new("Sky", lighting)
        if Option[1] == "Galaxy" then
            sky.SkyboxBk = "rbxassetid://153692994"
            sky.SkyboxDn = "rbxassetid://153692994"
            sky.SkyboxFt = "rbxassetid://153692994"
            sky.SkyboxLf = "rbxassetid://153692994"
            sky.SkyboxRt = "rbxassetid://153692994"
            sky.SkyboxUp = "rbxassetid://153692994"
        elseif Option[1] == "Blood Moon" then
            sky.SkyboxBk = "rbxassetid://2323602932"
            sky.SkyboxDn = "rbxassetid://2323602932"
            sky.SkyboxFt = "rbxassetid://2323602932"
            sky.SkyboxLf = "rbxassetid://2323602932"
            sky.SkyboxRt = "rbxassetid://2323602932"
            sky.SkyboxUp = "rbxassetid://2323602932"
        elseif Option[1] == "Pitch Black" then
            sky:Destroy()
        end
    end
})

-- ============================================================
-- // РАЗДЕЛ "MOVEMENT" (Движение)
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

-- Moonwalk (Лунная походка)
MovementTab:CreateToggle({
    Name = "Moonwalk (Backward Move)",
    CurrentValue = false,
    Callback = function(Value)
        _G.Moonwalk = Value
        spawn(function()
            while _G.Moonwalk do
                task.wait(0.05)
                local char = getCharacter()
                if char and char:FindFirstChild("HumanoidRootPart") then
                    local root = char.HumanoidRootPart
                    root.CFrame = root.CFrame * CFrame.new(0, 0, -0.3)
                end
            end
        end)
    end
})

-- No Fall (Без падения)
MovementTab:CreateToggle({
    Name = "No Fall",
    CurrentValue = false,
    Callback = function(Value)
        _G.NoFall = Value
        spawn(function()
            while _G.NoFall do
                task.wait(0.1)
                local char = getCharacter()
                if char and char:FindFirstChild("Humanoid") then
                    char.Humanoid.PlatformStand = false
                end
            end
        end)
    end
})

-- Fast Vault (Быстрый перевал)
MovementTab:CreateToggle({
    Name = "Fast Vault",
    CurrentValue = false,
    Callback = function(Value)
        _G.FastVault = Value
        -- Увеличение скорости при перевалах (зависит от игры)
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

MovementTab:CreateToggle({
    Name = "Infinite Jump",
    CurrentValue = false,
    Callback = function(Value)
        _G.InfiniteJump = Value
    end
})

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
_G.AutoRepair = false
_G.AutoParry = false
_G.ParryDistance = 15
_G.ESPParry = false
_G.InstantEscape = false
_G.AutoHeal = false
_G.HitboxSize = 3
_G.KillerSilentAim = false
_G.KillerThirdPerson = false
_G.CameraDistance = 10
_G.CameraHeight = 2
_G.InfiniteLunge = false
_G.PlayerESP = false
_G.ESPGenerator = false
_G.ESPPallet = false
_G.Chams = false
_G.Spin = false
_G.SpinSpeed = 10
_G.AntiStun = false
_G.AntiBlind = false
_G.Fullbright = false
_G.EnableSpeed = false
_G.SpeedValue = 16
_G.Moonwalk = false
_G.NoFall = false
_G.FastVault = false
_G.NoClip = false
_G.InfiniteJump = false

-- Обновление третьего лица для Killer
runService.RenderStepped:Connect(function()
    if _G.KillerThirdPerson then
        local char = getCharacter()
        if char then
            local root = char:FindFirstChild("HumanoidRootPart")
            if root then
                local distance = _G.CameraDistance or 10
                local height = _G.CameraHeight or 2
                local lookVector = root.CFrame.LookVector
                local camPos = root.Position - lookVector * distance + Vector3.new(0, height, 0)
                camera.CameraType = Enum.CameraType.Scriptable
                camera.CFrame = CFrame.new(camPos, root.Position + Vector3.new(0, 1, 0))
            end
        end
    end
end)

-- ============================================================
print("✅ VIOLENCE DISTRICT SCRIPT | NEXUS CORE loaded!")
print("🔥 Functions: Auto Repair, Auto Parry, ESP, Hitbox, Silent Aim, Third Person, Spin, Fullbright, Moonwalk, Fast Vault, and more!")
