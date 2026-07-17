-- // Xyesos Hub | Violence District v3.0
-- // EDUCATIONAL PURPOSE ONLY
-- // DISCLAIMER: For Lua learning and research only. Not for actual use.
-- // ПОЛНОСТЬЮ ПЕРЕРАБОТАНА: ESP (3D Box + Highlight), Hitbox, Spin, Auto Gen, Speed, Fly, NoClip, Anti-Stun, Auto Parry, TP to Gen/Player, FOV, Keybinds

-- ============================================================
-- // ЗАГРУЗЧИК RAYFIELD (БЕЗ ДВОЙНОГО ЗАПРОСА)
-- ============================================================
local Rayfield = nil
local function loadRayfield()
    local success, result = pcall(function()
        return loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
    end)
    if success then Rayfield = result
    else
        warn("⚠️ Rayfield не загружен: " .. tostring(result))
        local ScreenGui = Instance.new("ScreenGui")
        ScreenGui.Name = "XyesosFallback"
        ScreenGui.Parent = game.Players.LocalPlayer:WaitForChild("PlayerGui")
        local frame = Instance.new("Frame")
        frame.Size = UDim2.new(0, 250, 0, 150)
        frame.Position = UDim2.new(0.5, -125, 0.5, -75)
        frame.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
        frame.Parent = ScreenGui
        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(1, 0, 1, 0)
        label.BackgroundTransparency = 1
        label.Text = "⚠️ Rayfield не загружен!\nИспользуется упрощённый режим."
        label.TextColor3 = Color3.fromRGB(255, 255, 255)
        label.TextScaled = true
        label.Font = Enum.Font.GothamBold
        label.Parent = frame
        Rayfield = {CreateWindow = function() return {CreateTab = function() return {} end} end}
    end
end
loadRayfield()
if not Rayfield then error("❌ Критическая ошибка: Rayfield не загружен.") end

-- ============================================================
-- // ГЛАВНОЕ ОКНО (Xyesos Hub)
-- ============================================================
local Window = Rayfield:CreateWindow({
    Name = "XYESOS HUB | Violence District",
    Icon = 7734058803,
    LoadingTitle = "XYESOS HUB",
    LoadingSubtitle = "by FeVilAi (Ultra Edition)",
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
local espHighlights = {}
local baseSizes = {}
local generatorCache = {}
local isRepairing = false
local flyBodyVelocity = nil
local antiAFKThread = nil

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
-- // ОПРЕДЕЛЕНИЕ РОЛИ
-- ============================================================
local function getPlayerRole(plr)
    if not plr or not plr.Character then return "Spectator" end
    local char = plr.Character
    -- Проверка маркеров убийцы (адаптируйте под игру)
    if plr:FindFirstChild("Killer") or char:FindFirstChild("KillerTag") or char:FindFirstChild("IsKiller") then
        return "Killer"
    end
    local hum = char:FindFirstChild("Humanoid")
    if not hum or hum.Health <= 0 then
        return "Spectator"
    end
    return "Survivor"
end

local function getRoleColor(role)
    if role == "Killer" then return Color3.fromRGB(255, 0, 0) end
    if role == "Survivor" then return Color3.fromRGB(0, 255, 0) end
    return Color3.fromRGB(128, 128, 128) -- Spectator
end

-- ============================================================
-- // РАЗДЕЛ "ESP" (3D Box + Highlight + Name Tags)
-- ============================================================
local ESPTab = Window:CreateTab("👁️ ESP", 7734058803)

-- Функция создания ESP (3D Box + Highlight)
local function createESP(plr)
    if not plr or not plr.Character then return end
    local char = plr.Character
    local head = char:FindFirstChild("Head")
    if not head then return end

    local role = getPlayerRole(plr)
    local color = getRoleColor(role)

    -- 3D Box (вместо ников)
    local box = Instance.new("BoxHandleAdornment")
    box.Name = "XyesosESPBox"
    box.Size = Vector3.new(3, 5, 3)
    box.Color3 = color
    box.Transparency = 0.3
    box.ZIndex = 0
    box.AlwaysOnTop = true
    box.Parent = head

    -- Highlight (подсветка модели) [reference:0]
    local highlight = Instance.new("Highlight")
    highlight.Name = "XyesosESPHighlight"
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
    if not _G.PlayerESP then return end
    for _, plr in pairs(players:GetPlayers()) do
        if plr ~= player and plr.Character then
            createESP(plr)
        end
    end
end

-- Toggle ESP
ESPTab:CreateToggle({
    Name = "Player ESP (3D Box + Highlight)",
    CurrentValue = false,
    Callback = function(Value)
        _G.PlayerESP = Value
        if Value then
            updateESP()
            spawn(function()
                while _G.PlayerESP do
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
-- // РАЗДЕЛ "AUTO REPAIR" (ИСПРАВЛЕН)
-- ============================================================
local RepairTab = Window:CreateTab("🔧 Auto Repair", 7734058803)

local function findGenerators()
    local gens = {}
    for _, v in pairs(workspace:GetDescendants()) do
        if v:IsA("Model") and (v.Name:lower():find("generator") or v.Name:lower():find("gen")) then
            local interact = v:FindFirstChild("Interact") or v:FindFirstChild("Handle") or v:FindFirstChild("Part")
            if interact and interact:IsA("BasePart") then
                table.insert(gens, v)
            end
        end
    end
    return gens
end

local function updateGeneratorCache()
    generatorCache = findGenerators()
end
updateGeneratorCache()

RepairTab:CreateToggle({
    Name = "Auto Repair Generators",
    CurrentValue = false,
    Callback = function(Value)
        _G.AutoRepair = Value
        isRepairing = Value
        spawn(function()
            while _G.AutoRepair do
                task.wait(0.3)
                local char = getCharacter()
                if not char then continue end
                local hrp = char:FindFirstChild("HumanoidRootPart")
                if not hrp then continue end

                if tick() % 5 < 0.1 then updateGeneratorCache() end

                local targetPart = nil
                local minDist = math.huge

                for _, gen in pairs(generatorCache) do
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
                        pressKey(Enum.KeyCode.E)
                        task.wait(0.5)
                    end
                end
            end
        end)
    end
})

RepairTab:CreateButton({
    Name = "Teleport to Nearest Generator",
    Callback = function()
        local char = getCharacter()
        if not char then return end
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if not hrp then return end
        updateGeneratorCache()
        local nearest = nil
        local minDist = math.huge
        for _, gen in pairs(generatorCache) do
            local part = gen:FindFirstChild("Interact") or gen:FindFirstChild("Handle") or gen:FindFirstChild("Part")
            if part and part:IsA("BasePart") then
                local dist = (part.Position - hrp.Position).Magnitude
                if dist < minDist then
                    minDist = dist
                    nearest = part
                end
            end
        end
        if nearest then
            hrp.CFrame = CFrame.new(nearest.Position + Vector3.new(0, 0, 3), nearest.Position)
        end
    end
})

-- ============================================================
-- // РАЗДЕЛ "MOVEMENT" (Speed, Fly, NoClip, Infinite Jump)
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

-- Fly
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
-- // РАЗДЕЛ "HITBOX" (ИСПРАВЛЕН)
-- ============================================================
local HitboxTab = Window:CreateTab("📐 Hitbox", 7734058803)

local function applyHitbox(enabled)
    for _, plr in pairs(players:GetPlayers()) do
        if plr ~= player and plr.Character then
            local role = getPlayerRole(plr)
            if role == "Survivor" then
                for _, part in pairs(plr.Character:GetDescendants()) do
                    if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
                        if enabled then
                            if not baseSizes[part] then
                                baseSizes[part] = part.Size
                            end
                            local scale = (_G.HitboxSize or 3) / 3
                            part.Size = baseSizes[part] * scale
                        else
                            if baseSizes[part] then
                                part.Size = baseSizes[part]
                            end
                        end
                    end
                end
            end
        end
    end
end

HitboxTab:CreateSlider({
    Name = "Survivor Hitbox Size",
    Range = {3, 15},
    Increment = 0.5,
    CurrentValue = 3,
    Callback = function(Value)
        _G.HitboxSize = Value
        if _G.EnableHitbox then
            applyHitbox(true)
        end
    end
})

HitboxTab:CreateToggle({
    Name = "Enable Hitbox Expansion",
    CurrentValue = false,
    Callback = function(Value)
        _G.EnableHitbox = Value
        if Value then
            applyHitbox(true)
            spawn(function()
                while _G.EnableHitbox do
                    task.wait(0.5)
                    applyHitbox(true)
                end
            end)
        else
            applyHitbox(false)
            baseSizes = {}
        end
    end
})

-- ============================================================
-- // РАЗДЕЛ "SPIN" (ИСПРАВЛЕН)
-- ============================================================
local SpinTab = Window:CreateTab("🔄 Spin", 7734058803)

SpinTab:CreateToggle({
    Name = "Spin (Rotate by X)",
    CurrentValue = false,
    Callback = function(Value)
        _G.Spin = Value
        spawn(function()
            while _G.Spin do
                task.wait(0.016)
                local char = getCharacter()
                if char and char:FindFirstChild("HumanoidRootPart") then
                    local angle = _G.SpinSpeed or 5
                    local direction = _G.SpinDirection or "Forward"
                    if direction == "Backward" then angle = -angle end
                    if direction == "Random" then
                        angle = (math.random() > 0.5 and 1 or -1) * angle
                    end
                    char.HumanoidRootPart.CFrame = char.HumanoidRootPart.CFrame * CFrame.Angles(math.rad(angle), 0, 0)
                end
            end
        end)
    end
})

SpinTab:CreateSlider({
    Name = "Spin Speed",
    Range = {1, 20},
    Increment = 1,
    CurrentValue = 5,
    Callback = function(Value)
        _G.SpinSpeed = Value
    end
})

SpinTab:CreateDropdown({
    Name = "Spin Direction",
    Options = {"Forward", "Backward", "Random"},
    CurrentOption = "Forward",
    Callback = function(Option)
        _G.SpinDirection = Option
    end
})

-- ============================================================
-- // РАЗДЕЛ "UTILITY" (Доп. имба-функции)
-- ============================================================
local UtilityTab = Window:CreateTab("⚡ Utility", 7734058803)

-- Anti-Stun
UtilityTab:CreateToggle({
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

-- Auto Parry (авто-парирование) [reference:1][reference:2]
UtilityTab:CreateToggle({
    Name = "Auto Parry (Anti-Killer)",
    CurrentValue = false,
    Callback = function(Value)
        _G.AutoParry = Value
        spawn(function()
            while _G.AutoParry do
                task.wait(0.1)
                -- Эмуляция парирования (клавиша F или Q)
                local killer = nil
                for _, plr in pairs(players:GetPlayers()) do
                    if plr ~= player and getPlayerRole(plr) == "Killer" then
                        killer = plr
                        break
                    end
                end
                if killer and killer.Character then
                    local dist = (killer.Character.Head.Position - player.Character.Head.Position).Magnitude
                    if dist < 15 then
                        pressKey(Enum.KeyCode.F) -- или Q
                    end
                end
            end
        end)
    end
})

-- Teleport to Player
UtilityTab:CreateInput({
    Name = "Teleport to Player",
    CurrentValue = "",
    PlaceholderText = "Enter Player Name",
    Callback = function(Text)
        _G.TeleportTarget = Text
    end
})

UtilityTab:CreateButton({
    Name = "Teleport",
    Callback = function()
        local char = getCharacter()
        if not char then return end
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if not hrp then return end
        local target = players:FindFirstChild(_G.TeleportTarget)
        if target and target.Character then
            local targetHrp = target.Character:FindFirstChild("HumanoidRootPart")
            if targetHrp then
                hrp.CFrame = targetHrp.CFrame * CFrame.new(0, 0, 3)
            end
        end
    end
})

-- Anti-AFK
UtilityTab:CreateToggle({
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

-- Infinite Jump (обработка прыжка)
userInput.JumpRequest:Connect(function()
    if _G.InfiniteJump then
        local char = getCharacter()
        if char and char:FindFirstChild("Humanoid") then
            char.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
        end
    end
end)

-- ============================================================
-- // ДОПОЛНИТЕЛЬНЫЕ ФУНКЦИИ (FOV, Keybinds, Auto Parry)
-- ============================================================

-- Изменение FOV (поле зрения)
local FOVTab = Window:CreateTab("🔭 FOV", 7734058803)

FOVTab:CreateSlider({
    Name = "Camera FOV",
    Range = {40, 120},
    Increment = 5,
    CurrentValue = 70,
    Callback = function(Value)
        _G.FOVValue = Value
        camera.FieldOfView = Value
    end
})

-- Keybinds (горячие клавиши)
local KeybindsTab = Window:CreateTab("⌨️ Keybinds", 7734058803)

KeybindsTab:CreateKeybind({
    Name = "Toggle ESP",
    CurrentKeybind = Enum.KeyCode.F1,
    Callback = function()
        _G.PlayerESP = not _G.PlayerESP
        if _G.PlayerESP then
            updateESP()
            spawn(function()
                while _G.PlayerESP do
                    task.wait(0.5)
                    updateESP()
                end
            end)
        else
            clearESP()
        end
    end
})

KeybindsTab:CreateKeybind({
    Name = "Toggle Fly",
    CurrentKeybind = Enum.KeyCode.F2,
    Callback = function()
        _G.Fly = not _G.Fly
        if _G.Fly then
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

KeybindsTab:CreateKeybind({
    Name = "Toggle Speed",
    CurrentKeybind = Enum.KeyCode.F3,
    Callback = function()
        _G.EnableSpeed = not _G.EnableSpeed
    end
})

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
_G.FOVValue = 70
_G.AutoRepair = false
_G.AutoParry = false
_G.AntiStun = false
_G.Spin = false
_G.SpinSpeed = 5
_G.SpinDirection = "Forward"

-- ============================================================
-- // ИНФОРМАЦИЯ
-- ============================================================
print("✅ Xyesos Hub | Violence District v3.0 loaded successfully!")
print("🔥 Ultra Functions: ESP (3D Box + Highlight), Hitbox, Spin, Auto Gen, Speed, Fly, NoClip, Anti-Stun, Auto Parry, Teleport, Anti-AFK, FOV, Keybinds")