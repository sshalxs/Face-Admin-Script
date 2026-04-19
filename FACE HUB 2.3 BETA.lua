-- ==========================================
-- 🍅 FACE HUB 2.3 BETA 🍅
-- DYNAMIC ISLAND + ГОЛОС
-- Автор: LuckyCore
-- Ключ: BETA TESTIK
-- ==========================================

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local CoreGui = game:GetService("CoreGui")
local Stats = game:GetService("Stats")
local SoundService = game:GetService("SoundService")

-- === ГОЛОСОВОЙ ДИНАМИК (TextToSpeech) ===
local function Speak(text)
    local success, err = pcall(function()
        local tts = Instance.new("TextToSpeech")
        tts.Parent = SoundService
        tts:Speak(text, "en-US", "Female")
        task.wait(1)
        tts:Destroy()
    end)
    if not success then
        -- Запасной вариант: через системный Speech
        pcall(function()
            game:GetService("GuiService"):ShowBlockedMessage(text)
        end)
    end
end

-- === DYNAMIC ISLAND ===
local dynamicIsland = nil
local messageQueue = {}
local isPlaying = false

local function CreateDynamicIsland()
    if dynamicIsland and dynamicIsland.Parent then return end
    
    local gui = Instance.new("ScreenGui")
    gui.Name = "DynamicIsland"
    gui.ResetOnSpawn = false
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    gui.Parent = LocalPlayer:WaitForChild("PlayerGui")
    
    local island = Instance.new("Frame")
    island.Size = UDim2.new(0, 120, 0, 37)
    island.Position = UDim2.new(0.5, -60, 0, 10)
    island.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
    island.BackgroundTransparency = 0.15
    island.BorderSizePixel = 0
    island.ClipsDescendants = true
    island.Parent = gui
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 20)
    corner.Parent = island
    
    local glow = Instance.new("UIGradient")
    glow.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.fromRGB(229, 57, 53)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 87, 34)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(229, 57, 53))
    }
    glow.Rotation = 45
    glow.Parent = island
    
    local icon = Instance.new("TextLabel")
    icon.Size = UDim2.new(0, 25, 0, 25)
    icon.Position = UDim2.new(0, 8, 0.5, -12)
    icon.Text = "🔊"
    icon.TextSize = 18
    icon.BackgroundTransparency = 1
    icon.Parent = island
    
    local textLabel = Instance.new("TextLabel")
    textLabel.Size = UDim2.new(1, -40, 1, 0)
    textLabel.Position = UDim2.new(0, 38, 0, 0)
    textLabel.Text = ""
    textLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    textLabel.TextSize = 13
    textLabel.TextXAlignment = Enum.TextXAlignment.Left
    textLabel.BackgroundTransparency = 1
    textLabel.Parent = island
    
    dynamicIsland = {gui = gui, island = island, text = textLabel, icon = icon}
    
    -- Анимация появления
    island.BackgroundTransparency = 1
    island.Size = UDim2.new(0, 50, 0, 37)
    TweenService:Create(island, TweenInfo.new(0.3, Enum.EasingStyle.Back), {
        Size = UDim2.new(0, 120, 0, 37),
        BackgroundTransparency = 0.15
    }):Play()
end

local function ExpandIsland(message, color)
    if not dynamicIsland then CreateDynamicIsland() end
    if not dynamicIsland then return end
    
    local island = dynamicIsland.island
    local textLabel = dynamicIsland.text
    local icon = dynamicIsland.icon
    
    textLabel.Text = message
    if color then
        icon.Text = "🔴"
        local gradient = island:FindFirstChild("UIGradient")
        if gradient then
            gradient.Color = ColorSequence.new{
                ColorSequenceKeypoint.new(0, color),
                ColorSequenceKeypoint.new(0.5, color),
                ColorSequenceKeypoint.new(1, color)
            }
        end
    else
        icon.Text = "🔊"
        local gradient = island:FindFirstChild("UIGradient")
        if gradient then
            gradient.Color = ColorSequence.new{
                ColorSequenceKeypoint.new(0, Color3.fromRGB(229, 57, 53)),
                ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 87, 34)),
                ColorSequenceKeypoint.new(1, Color3.fromRGB(229, 57, 53))
            }
        end
    end
    
    -- Расширяем
    TweenService:Create(island, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {
        Size = UDim2.new(0, math.min(250, 50 + #message * 6), 0, 45)
    }):Play()
    
    -- Сворачиваем через 2.5 секунды
    task.delay(2.5, function()
        if dynamicIsland and dynamicIsland.island then
            TweenService:Create(island, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {
                Size = UDim2.new(0, 120, 0, 37)
            }):Play()
            task.delay(0.2, function()
                if textLabel then textLabel.Text = "" end
                if icon then icon.Text = "🔊" end
            end)
        end
    end)
end

-- === ОЧЕРЕДЬ ГОЛОСА И DYNAMIC ISLAND ===
local function DynamicNotify(message, isError)
    if not dynamicIsland then CreateDynamicIsland() end
    ExpandIsland(message, isError and Color3.fromRGB(255, 50, 50) or nil)
    
    -- Озвучка с очередью
    table.insert(messageQueue, message)
    if isPlaying then return end
    isPlaying = true
    
    task.spawn(function()
        while #messageQueue > 0 do
            local msg = table.remove(messageQueue, 1)
            Speak(msg)
            task.wait(1.5)
        end
        isPlaying = false
    end)
end

-- === ЗАЩИТА КЛЮЧОМ ===
local Key = "BETA TESTIK"
local AccessGranted = false

local function ShowKeyPrompt()
    local keyGui = Instance.new("ScreenGui")
    keyGui.Name = "KeyPrompt"
    keyGui.ResetOnSpawn = false
    keyGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
    
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 300, 0, 150)
    frame.Position = UDim2.new(0.5, -150, 0.5, -75)
    frame.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
    frame.Parent = keyGui
    
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 40)
    title.Text = "🍅 FACE HUB 2.3 BETA"
    title.TextColor3 = Color3.fromRGB(229, 57, 53)
    title.BackgroundTransparency = 1
    title.Parent = frame
    
    local inputBox = Instance.new("TextBox")
    inputBox.Size = UDim2.new(0.8, 0, 0, 40)
    inputBox.Position = UDim2.new(0.1, 0, 0.3, 0)
    inputBox.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
    inputBox.TextColor3 = Color3.fromRGB(255, 255, 255)
    inputBox.PlaceholderText = "Введите ключ..."
    inputBox.Parent = frame
    
    local confirmBtn = Instance.new("TextButton")
    confirmBtn.Size = UDim2.new(0.5, 0, 0, 40)
    confirmBtn.Position = UDim2.new(0.25, 0, 0.7, 0)
    confirmBtn.BackgroundColor3 = Color3.fromRGB(229, 57, 53)
    confirmBtn.Text = "Подтвердить"
    confirmBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    confirmBtn.Parent = frame
    
    confirmBtn.MouseButton1Click:Connect(function()
        if inputBox.Text == Key then
            keyGui:Destroy()
            AccessGranted = true
            DynamicNotify("FACE HUB 2.3 BETA активирован")
            CreateMenu()
            CreateToggleButton()
        else
            DynamicNotify("Неверный ключ", true)
        end
    end)
end

-- === ОБХОД АНТИЧИТА ===
local function BypassAntiCheat()
    local mt = getrawmetatable(game)
    local old = mt.__namecall
    setreadonly(mt, false)
    mt.__namecall = newcclosure(function(self, ...)
        local method = getnamecallmethod()
        if method == "FireServer" and tostring(self):find("AntiCheat") then
            return nil
        end
        return old(self, ...)
    end)
    setreadonly(mt, true)
    DynamicNotify("Античит обойдён")
end

-- === ПРИПИСКА К НИКУ В ЧАТЕ ===
local mt = getrawmetatable(game)
local oldNamecall = mt.__namecall
setreadonly(mt, false)
mt.__namecall = newcclosure(function(self, ...)
    local args = {...}
    local method = getnamecallmethod()
    if method == "FireServer" and tostring(self):find("SayMessageRequest") then
        local msg = args[2]
        if msg and not msg:find("FACE😈") then
            args[2] = "FACE😈 " .. LocalPlayer.Name .. ": " .. msg
            return oldNamecall(self, unpack(args))
        end
    end
    return oldNamecall(self, ...)
end)
setreadonly(mt, true)

-- === ПЕРЕМЕННЫЕ ===
local flying = false
local bodyVelocity = nil
local bodyGyro = nil
local flySpeed = 50
local godMode = false
local noclipEnabled = false
local infinityJump = false
local spinEnabled = false
local spinSpeed = 2
local originalCollide = {}
local currentSection = 1
local sections = {"Movement", "Trolling", "Serious", "Player", "New", "Info", "Spin"}
local menuGui = nil
local menuFrame = nil
local settingsOpen = false

-- === НАСТРОЙКИ ===
local function ShowSettings(callback, currentValue, minVal, maxVal)
    local settingsGui = Instance.new("ScreenGui")
    settingsGui.Name = "SettingsMenu"
    settingsGui.ResetOnSpawn = false
    settingsGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
    
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 300, 0, 150)
    frame.Position = UDim2.new(0.5, -150, 0.5, -75)
    frame.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
    frame.Parent = settingsGui
    
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 40)
    title.Text = "Настройки"
    title.TextColor3 = Color3.fromRGB(229, 57, 53)
    title.BackgroundTransparency = 1
    title.Parent = frame
    
    local slider = Instance.new("TextBox")
    slider.Size = UDim2.new(0.6, 0, 0, 40)
    slider.Position = UDim2.new(0.05, 0, 0.4, 0)
    slider.Text = tostring(currentValue)
    slider.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
    slider.TextColor3 = Color3.fromRGB(255, 255, 255)
    slider.Parent = frame
    
    local saveBtn = Instance.new("TextButton")
    saveBtn.Size = UDim2.new(0.25, 0, 0, 40)
    saveBtn.Position = UDim2.new(0.7, 0, 0.4, 0)
    saveBtn.Text = "Сохранить"
    saveBtn.BackgroundColor3 = Color3.fromRGB(229, 57, 53)
    saveBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    saveBtn.Parent = frame
    saveBtn.MouseButton1Click:Connect(function()
        local newVal = tonumber(slider.Text)
        if newVal and newVal >= minVal and newVal <= maxVal then
            callback(newVal)
            settingsGui:Destroy()
        else
            DynamicNotify("Значение от " .. minVal .. " до " .. maxVal, true)
        end
    end)
    
    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.new(0.25, 0, 0, 35)
    closeBtn.Position = UDim2.new(0.375, 0, 0.7, 0)
    closeBtn.Text = "Закрыть"
    closeBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
    closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeBtn.Parent = frame
    closeBtn.MouseButton1Click:Connect(function() settingsGui:Destroy() end)
end

-- === БЕССМЕРТИЕ ===
local function ToggleGodMode()
    godMode = not godMode
    local char = LocalPlayer.Character
    if char and char:FindFirstChild("Humanoid") then
        local hum = char.Humanoid
        if godMode then
            hum.MaxHealth = 10000000
            hum.Health = 10000000
            DynamicNotify("ВЫ ВКЛЮЧИЛИ БЕССМЕРТИЕ")
        else
            hum.MaxHealth = 100
            hum.Health = 100
            DynamicNotify("ВЫ ВЫКЛЮЧИЛИ БЕССМЕРТИЕ")
        end
    end
end

-- === НОКЛИП ===
local function ToggleNoclip()
    noclipEnabled = not noclipEnabled
    local char = LocalPlayer.Character
    if char then
        for _, part in ipairs(char:GetDescendants()) do
            if part:IsA("BasePart") then
                if noclipEnabled then
                    originalCollide[part] = part.CanCollide
                    part.CanCollide = false
                else
                    part.CanCollide = originalCollide[part] ~= nil and originalCollide[part] or true
                end
            end
        end
    end
    DynamicNotify(noclipEnabled and "ВЫ ВКЛЮЧИЛИ НОКЛИП" or "ВЫ ВЫКЛЮЧИЛИ НОКЛИП")
end

-- === INFINITY JUMP ===
local function ToggleInfinityJump()
    infinityJump = not infinityJump
    DynamicNotify(infinityJump and "ВЫ ВКЛЮЧИЛИ INFINITY JUMP" or "ВЫ ВЫКЛЮЧИЛИ INFINITY JUMP")
end

RunService.RenderStepped:Connect(function()
    if infinityJump then
        local char = LocalPlayer.Character
        if char and char:FindFirstChild("Humanoid") then
            local hum = char.Humanoid
            if hum:GetState() == Enum.HumanoidStateType.Jumping then
                hum:ChangeState(Enum.HumanoidStateType.Jumping)
            end
        end
    end
    if spinEnabled and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        LocalPlayer.Character.HumanoidRootPart.CFrame = LocalPlayer.Character.HumanoidRootPart.CFrame * CFrame.Angles(0, math.rad(spinSpeed), 0)
    end
end)

-- === ФЛАЙ ===
local function StartFly()
    local char = LocalPlayer.Character
    if not char then return end
    local humanoid = char:FindFirstChild("Humanoid")
    if not humanoid then return end
    
    humanoid.PlatformStand = true
    bodyVelocity = Instance.new("BodyVelocity")
    bodyVelocity.MaxForce = Vector3.new(9e9, 9e9, 9e9)
    bodyVelocity.Velocity = Vector3.new(0, 0, 0)
    bodyVelocity.Parent = char.HumanoidRootPart
    
    bodyGyro = Instance.new("BodyGyro")
    bodyGyro.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
    bodyGyro.Parent = char.HumanoidRootPart
    bodyGyro.CFrame = char.HumanoidRootPart.CFrame
    
    flying = true
    DynamicNotify("ВЫ ВКЛЮЧИЛИ ФЛАЙ")
end

local function StopFly()
    local char = LocalPlayer.Character
    if not char then return end
    local humanoid = char:FindFirstChild("Humanoid")
    if not humanoid then return end
    
    humanoid.PlatformStand = false
    if bodyVelocity then bodyVelocity:Destroy() end
    if bodyGyro then bodyGyro:Destroy() end
    bodyVelocity = nil
    bodyGyro = nil
    flying = false
    DynamicNotify("ВЫ ВЫКЛЮЧИЛИ ФЛАЙ")
end

local function SetFlySpeed(speed)
    flySpeed = speed
    DynamicNotify("Скорость флая установлена на " .. speed)
end

-- Джойстик для флая
local touchStart = nil
UserInputService.TouchStarted:Connect(function(touch, processed)
    if processed then return end
    touchStart = touch.Position
end)

UserInputService.TouchMoved:Connect(function(touch, processed)
    if processed or not flying or not touchStart then return end
    local delta = touch.Position - touchStart
    local screenSize = workspace.CurrentCamera.ViewportSize
    local move = Vector3.new(0, 0, 0)
    
    if touch.Position.X < screenSize.X / 2 then
        move = Vector3.new(delta.X / 15, 0, -delta.Y / 15)
    else
        move = Vector3.new(0, -delta.Y / 15, 0)
    end
    
    if bodyVelocity then
        bodyVelocity.Velocity = (Camera.CFrame.LookVector * move.Z + Camera.CFrame.RightVector * move.X + Vector3.new(0, move.Y, 0)) * flySpeed
    end
    if bodyGyro then
        bodyGyro.CFrame = Camera.CFrame
    end
end)

UserInputService.TouchEnded:Connect(function()
    touchStart = nil
    if bodyVelocity then
        bodyVelocity.Velocity = Vector3.new(0, 0, 0)
    end
end)

-- === КРАШ СЕРВЕРА ===
local function CrashServer()
    for _, player in ipairs(Players:GetPlayers()) do
        local gui = Instance.new("ScreenGui")
        gui.Name = "FaceHubCrash"
        gui.ResetOnSpawn = false
        gui.Parent = player:WaitForChild("PlayerGui")
        local frame = Instance.new("Frame")
        frame.Size = UDim2.new(1, 0, 1, 0)
        frame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
        frame.BackgroundTransparency = 0.3
        frame.Parent = gui
        local text = Instance.new("TextLabel")
        text.Size = UDim2.new(1, 0, 0, 100)
        text.Position = UDim2.new(0, 0, 0.4, 0)
        text.Text = "FACE HUB ВАШ БОГ"
        text.TextColor3 = Color3.fromRGB(255, 0, 0)
        text.TextScaled = true
        text.Font = Enum.Font.GothamBold
        text.BackgroundTransparency = 1
        text.Parent = frame
    end
    task.wait(1)
    for i = 1, 300 do
        local part = Instance.new("Part")
        part.Size = Vector3.new(50, 50, 50)
        part.Position = Vector3.new(math.random(-10000, 10000), math.random(-10000, 10000), math.random(-10000, 10000))
        part.Anchored = true
        part.Parent = Workspace
        task.wait()
    end
    DynamicNotify("КРАШ СЕРВЕРА АКТИВИРОВАН")
    game:Shutdown()
end

-- === ФЛИНГ ===
local function FlingPlayer(player)
    local char = player.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return end
    local root = char.HumanoidRootPart
    local bodyVel = Instance.new("BodyVelocity")
    bodyVel.MaxForce = Vector3.new(9e9, 9e9, 9e9)
    bodyVel.Velocity = Vector3.new(10000, 10000, 10000)
    bodyVel.Parent = root
    task.wait(0.5)
    bodyVel:Destroy()
    DynamicNotify("ВЫ ВЫКИНУЛИ ЗА КАРТУ " .. string.upper(player.Name))
end

-- === ТЮРЬМА ===
local jailCells = {}
local function JailPlayer(player)
    local char = player.Character
    if not char then return end
    if jailCells[player.Name] then return end
    local pos = char.HumanoidRootPart.Position
    local size = 15
    local wallHeight = 20
    local jail = Instance.new("Model")
    jail.Name = "Jail_" .. player.Name
    jail.Parent = Workspace
    for x = -size/2, size/2, 1 do
        for z = -size/2, size/2, 1 do
            if math.abs(x) == size/2 or math.abs(z) == size/2 then
                local wall = Instance.new("Part")
                wall.Size = Vector3.new(1, wallHeight, 1)
                wall.Position = pos + Vector3.new(x, wallHeight/2, z)
                wall.Anchored = true
                wall.CanCollide = true
                wall.Transparency = 0.4
                wall.Color = Color3.fromRGB(255, 0, 0)
                wall.Material = Enum.Material.Neon
                wall.Parent = jail
            end
        end
    end
    local floor = Instance.new("Part")
    floor.Size = Vector3.new(size, 1, size)
    floor.Position = pos + Vector3.new(0, -2, 0)
    floor.Anchored = true
    floor.CanCollide = true
    floor.Parent = jail
    local roof = Instance.new("Part")
    roof.Size = Vector3.new(size, 1, size)
    roof.Position = pos + Vector3.new(0, wallHeight, 0)
    roof.Anchored = true
    roof.CanCollide = true
    roof.Parent = jail
    char.HumanoidRootPart.CFrame = pos + Vector3.new(0, 3, 0)
    jailCells[player.Name] = jail
    DynamicNotify("ВЫ ПОСАДИЛИ В ТЮРЬМУ " .. string.upper(player.Name))
end

-- === УБИЙСТВО ===
local function KillPlayer(player)
    local char = player.Character
    if char and char:FindFirstChild("Humanoid") then
        char.Humanoid.Health = 0
        DynamicNotify("ВЫ УБИЛИ " .. string.upper(player.Name))
    end
end

-- === КРАШ ИГРОКА ===
local function CrashPlayer(player)
    for i = 1, 100 do
        local part = Instance.new("Part")
        part.Size = Vector3.new(10, 10, 10)
        part.Position = player.Character.HumanoidRootPart.Position + Vector3.new(math.random(-50, 50), math.random(-50, 50), math.random(-50, 50))
        part.Anchored = true
        part.Parent = Workspace
        task.wait()
    end
    DynamicNotify("ВЫ КРАШНУЛИ " .. string.upper(player.Name))
end

-- === КИК ===
local function KickPlayer(player, reason)
    reason = reason or "Нарушение правил"
    player:Kick(reason)
    DynamicNotify("ВЫ КИКНУЛИ " .. string.upper(player.Name))
end

-- === ТЕЛЕПОРТ ===
local function TeleportToPlayer(player)
    local myChar = LocalPlayer.Character
    if myChar and player.Character then
        myChar.HumanoidRootPart.CFrame = player.Character.HumanoidRootPart.CFrame
        DynamicNotify("ВЫ ТЕЛЕПОРТИРОВАЛИСЬ К " .. string.upper(player.Name))
    end
end
local function TeleportPlayerToMe(player)
    if player.Character then
        player.Character.HumanoidRootPart.CFrame = LocalPlayer.Character.HumanoidRootPart.CFrame
        DynamicNotify("ВЫ ТЕЛЕПОРТИРОВАЛИ " .. string.upper(player.Name) .. " К СЕБЕ")
    end
end

-- === СПАВН ОРУЖИЯ ===
local function SpawnWeapon()
    local dialog = Instance.new("TextBox")
    dialog.Size = UDim2.new(0, 300, 0, 50)
    dialog.Position = UDim2.new(0.5, -150, 0.5, -25)
    dialog.Text = ""
    dialog.Parent = LocalPlayer.PlayerGui
    local ok = Instance.new("TextButton")
    ok.Size = UDim2.new(0, 80, 0, 30)
    ok.Position = UDim2.new(0.5, -40, 0.6, 0)
    ok.Text = "OK"
    ok.Parent = LocalPlayer.PlayerGui
    ok.MouseButton1Click:Connect(function()
        local name = dialog.Text
        dialog:Destroy()
        ok:Destroy()
        for _, obj in ipairs(Workspace:GetDescendants()) do
            if obj.Name:lower():find(name:lower()) and obj:IsA("Tool") then
                local tool = obj:Clone()
                tool.Parent = LocalPlayer.Backpack
                DynamicNotify("ОРУЖИЕ " .. string.upper(name) .. " СПАВНЕНО")
                return
            end
        end
        for _, obj in ipairs(ReplicatedStorage:GetDescendants()) do
            if obj.Name:lower():find(name:lower()) and obj:IsA("Tool") then
                local tool = obj:Clone()
                tool.Parent = LocalPlayer.Backpack
                DynamicNotify("ОРУЖИЕ " .. string.upper(name) .. " СПАВНЕНО")
                return
            end
        end
        DynamicNotify("ОРУЖИЕ НЕ НАЙДЕНО", true)
    end)
end

-- === COPY SKIN ===
local function CopySkin(player)
    if player.Character then
        local appearance = player.Character:FindFirstChild("Humanoid") and player.Character.Humanoid:GetAppliedDescription()
        if appearance then
            LocalPlayer.Character.Humanoid:ApplyDescription(appearance)
            DynamicNotify("ВЫ СКОПИРОВАЛИ СКИН " .. string.upper(player.Name))
        else
            DynamicNotify("НЕ УДАЛОСЬ СКОПИРОВАТЬ СКИН", true)
        end
    end
end

-- === INFO ===
local function GetTime()
    return os.date("%H:%M:%S", os.time())
end

local function GetFPS()
    local stats = Stats:FindFirstChild("PerformanceStats")
    if stats then
        return math.floor(stats.FPS)
    end
    return 60
end

local function GetPing()
    local stats = Stats:FindFirstChild("NetworkStats")
    if stats then
        return math.floor(stats.Ping)
    end
    return 50
end

-- === ВЫБОР ИГРОКА ===
local function ShowPlayerSelector(callback, extraText)
    local gui = Instance.new("ScreenGui")
    gui.Name = "PlayerSelector"
    gui.ResetOnSpawn = false
    gui.Parent = LocalPlayer:WaitForChild("PlayerGui")
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 300, 0, 400)
    frame.Position = UDim2.new(0.5, -150, 0.5, -200)
    frame.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
    frame.Parent = gui
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 40)
    title.Text = extraText or "🎯 ВЫБЕРИ ИГРОКА"
    title.TextColor3 = Color3.fromRGB(229, 57, 53)
    title.BackgroundTransparency = 1
    title.Parent = frame
    local close = Instance.new("TextButton")
    close.Size = UDim2.new(0, 35, 0, 35)
    close.Position = UDim2.new(1, -40, 0, 5)
    close.Text = "✕"
    close.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
    close.Parent = frame
    close.MouseButton1Click:Connect(function() gui:Destroy() end)
    local scroll = Instance.new("ScrollingFrame")
    scroll.Size = UDim2.new(1, -20, 1, -60)
    scroll.Position = UDim2.new(0, 10, 0, 50)
    scroll.BackgroundTransparency = 1
    scroll.CanvasSize = UDim2.new(0, 0, 0, 600)
    scroll.ScrollBarThickness = 8
    scroll.Parent = frame
    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 5)
    layout.Parent = scroll
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            local btn = Instance.new("TextButton")
            btn.Size = UDim2.new(1, 0, 0, 40)
            btn.Text = player.Name
            btn.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
            btn.TextColor3 = Color3.fromRGB(255, 255, 255)
            btn.Parent = scroll
            btn.MouseButton1Click:Connect(function()
                gui:Destroy()
                callback(player)
            end)
        end
    end
end

-- === МЕНЮ ===
local function CreateMenu()
    menuGui = Instance.new("ScreenGui")
    menuGui.Name = "FaceHubMenu"
    menuGui.ResetOnSpawn = false
    menuGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
    menuGui.Enabled = false
    
    menuFrame = Instance.new("Frame")
    menuFrame.Size = UDim2.new(0, 500, 0, 500)
    menuFrame.Position = UDim2.new(0.5, -250, 0.5, -250)
    menuFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
    menuFrame.BorderSizePixel = 0
    menuFrame.Parent = menuGui
    
    menuFrame.BackgroundTransparency = 1
    menuFrame.Size = UDim2.new(0, 400, 0, 400)
    local appearTween = TweenService:Create(menuFrame, TweenInfo.new(0.3, Enum.EasingStyle.Back), {Size = UDim2.new(0, 500, 0, 500), BackgroundTransparency = 0})
    appearTween:Play()
    
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 50)
    title.Text = "🍅 FACE HUB 2.3 BETA 🍅"
    title.TextColor3 = Color3.fromRGB(229, 57, 53)
    title.BackgroundTransparency = 1
    title.Font = Enum.Font.GothamBold
    title.TextSize = 20
    title.Parent = menuFrame
    
    -- Боковая панель
    local sidebar = Instance.new("Frame")
    sidebar.Size = UDim2.new(0, 120, 1, -50)
    sidebar.Position = UDim2.new(0, 0, 0, 50)
    sidebar.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
    sidebar.BorderSizePixel = 0
    sidebar.Parent = menuFrame
    
    local sectionButtons = {}
    for i, section in ipairs(sections) do
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1, -10, 0, 35)
        btn.Position = UDim2.new(0, 5, 0, 5 + (i-1)*40)
        btn.Text = section
        btn.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
        btn.TextColor3 = Color3.fromRGB(200, 200, 200)
        btn.BorderSizePixel = 0
        btn.Parent = sidebar
        sectionButtons[section] = btn
        btn.MouseButton1Click:Connect(function()
            currentSection = i
            for _, b in pairs(sectionButtons) do
                b.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
                b.TextColor3 = Color3.fromRGB(200, 200, 200)
            end
            btn.BackgroundColor3 = Color3.fromRGB(229, 57, 53)
            btn.TextColor3 = Color3.fromRGB(255, 255, 255)
            UpdateContent()
        end)
    end
    
    -- Контентная область
    local contentFrame = Instance.new("ScrollingFrame")
    contentFrame.Size = UDim2.new(1, -130, 1, -60)
    contentFrame.Position = UDim2.new(0, 130, 0, 55)
    contentFrame.BackgroundTransparency = 1
    contentFrame.CanvasSize = UDim2.new(0, 0, 0, 800)
    contentFrame.ScrollBarThickness = 5
    contentFrame.Parent = menuFrame
    
    local contentLayout = Instance.new("UIListLayout")
    contentLayout.Padding = UDim.new(0, 8)
    contentLayout.Parent = contentFrame
    
    -- Кнопка закрытия
    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.new(0, 30, 0, 30)
    closeBtn.Position = UDim2.new(1, -40, 0, 10)
    closeBtn.Text = "✕"
    closeBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
    closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeBtn.Parent = menuFrame
    closeBtn.MouseButton1Click:Connect(function()
        menuGui.Enabled = false
        settingsOpen = false
    end)
    
    -- Функция обновления контента
    local function UpdateContent()
        for _, child in ipairs(contentFrame:GetChildren()) do
            if child:IsA("TextButton") or child:IsA("TextLabel") then
                child:Destroy()
            end
        end
        
        if currentSection == 1 then -- Movement
            local flyBtn = Instance.new("TextButton")
            flyBtn.Size = UDim2.new(1, 0, 0, 45)
            flyBtn.Text = flying and "✈️ Флай: ВКЛ" or "✈️ Флай: ВЫКЛ"
            flyBtn.BackgroundColor3 = flying and Color3.fromRGB(76, 175, 80) or Color3.fromRGB(40, 40, 45)
            flyBtn.Parent = contentFrame
            flyBtn.MouseButton1Click:Connect(function()
                if flying then StopFly() else StartFly() end
                flyBtn.Text = flying and "✈️ Флай: ВКЛ" or "✈️ Флай: ВЫКЛ"
                flyBtn.BackgroundColor3 = flying and Color3.fromRGB(76, 175, 80) or Color3.fromRGB(40, 40, 45)
            end)
            
            local speedBtn = Instance.new("TextButton")
            speedBtn.Size = UDim2.new(1, 0, 0, 45)
            speedBtn.Text = "⚡ Скорость флая: " .. flySpeed
            speedBtn.Parent = contentFrame
            speedBtn.MouseButton1Click:Connect(function()
                ShowSettings(function(val) SetFlySpeed(val) speedBtn.Text = "⚡ Скорость флая: " .. flySpeed end, flySpeed, 10, 200)
            end)
            
            local noclipBtn = Instance.new("TextButton")
            noclipBtn.Size = UDim2.new(1, 0, 0, 45)
            noclipBtn.Text = noclipEnabled and "🌀 Ноклип: ВКЛ" or "🌀 Ноклип: ВЫКЛ"
            noclipBtn.BackgroundColor3 = noclipEnabled and Color3.fromRGB(76, 175, 80) or Color3.fromRGB(40, 40, 45)
            noclipBtn.Parent = contentFrame
            noclipBtn.MouseButton1Click:Connect(function()
                ToggleNoclip()
                noclipBtn.Text = noclipEnabled and "🌀 Ноклип: ВКЛ" or "🌀 Ноклип: ВЫКЛ"
                noclipBtn.BackgroundColor3 = noclipEnabled and Color3.fromRGB(76, 175, 80) or Color3.fromRGB(40, 40, 45)
            end)
            
            local infinityBtn = Instance.new("TextButton")
            infinityBtn.Size = UDim2.new(1, 0, 0, 45)
            infinityBtn.Text = infinityJump and "🦘 Infinity Jump: ВКЛ" or "🦘 Infinity Jump: ВЫКЛ"
            infinityBtn.BackgroundColor3 = infinityJump and Color3.fromRGB(76, 175, 80) or Color3.fromRGB(40, 40, 45)
            infinityBtn.Parent = contentFrame
            infinityBtn.MouseButton1Click:Connect(function()
                ToggleInfinityJump()
                infinityBtn.Text = infinityJump and "🦘 Infinity Jump: ВКЛ" or "🦘 Infinity Jump: ВЫКЛ"
                infinityBtn.BackgroundColor3 = infinityJump and Color3.fromRGB(76, 175, 80) or Color3.fromRGB(40, 40, 45)
            end)
            
        elseif currentSection == 2 then -- Trolling
            local flingBtn = Instance.new("TextButton")
            flingBtn.Size = UDim2.new(1, 0, 0, 45)
            flingBtn.Text = "💨 ФЛИНГ ИГРОКА"
            flingBtn.Parent = contentFrame
            flingBtn.MouseButton1Click:Connect(function()
                ShowPlayerSelector(FlingPlayer, "💨 ВЫБЕРИ ЖЕРТВУ ДЛЯ ФЛИНГА")
            end)
            
            local jailBtn = Instance.new("TextButton")
            jailBtn.Size = UDim2.new(1, 0, 0, 45)
            jailBtn.Text = "🔒 ТЮРЬМА"
            jailBtn.Parent = contentFrame
            jailBtn.MouseButton1Click:Connect(function()
                ShowPlayerSelector(JailPlayer, "🔒 ВЫБЕРИ ДЛЯ ТЮРЬМЫ")
            end)
            
            local crashBtn = Instance.new("TextButton")
            crashBtn.Size = UDim2.new(1, 0, 0, 45)
            crashBtn.Text = "💣 КРАШ ИГРОКА"
            crashBtn.Parent = contentFrame
            crashBtn.MouseButton1Click:Connect(function()
                ShowPlayerSelector(CrashPlayer, "💣 ВЫБЕРИ ЖЕРТВУ")
            end)
            
            local kickBtn = Instance.new("TextButton")
            kickBtn.Size = UDim2.new(1, 0, 0, 45)
            kickBtn.Text = "👢 КИК ИГРОКА"
            kickBtn.Parent = contentFrame
            kickBtn.MouseButton1Click:Connect(function()
                ShowPlayerSelector(function(p) KickPlayer(p, "Kicked by FACE HUB") end, "👢 ВЫБЕРИ ДЛЯ КИКА")
            end)
            
        elseif currentSection == 3 then -- Serious
            local godBtn = Instance.new("TextButton")
            godBtn.Size = UDim2.new(1, 0, 0, 45)
            godBtn.Text = godMode and "🛡️ БЕССМЕРТИЕ: ВКЛ" or "🛡️ БЕССМЕРТИЕ: ВЫКЛ"
            godBtn.BackgroundColor3 = godMode and Color3.fromRGB(76, 175, 80) or Color3.fromRGB(40, 40, 45)
            godBtn.Parent = contentFrame
            godBtn.MouseButton1Click:Connect(function()
                ToggleGodMode()
                godBtn.Text = godMode and "🛡️ БЕССМЕРТИЕ: ВКЛ" or "🛡️ БЕССМЕРТИЕ: ВЫКЛ"
                godBtn.BackgroundColor3 = godMode and Color3.fromRGB(76, 175, 80) or Color3.fromRGB(40, 40, 45)
            end)
            
            local weaponBtn = Instance.new("TextButton")
            weaponBtn.Size = UDim2.new(1, 0, 0, 45)
            weaponBtn.Text = "🔫 СПАВН ОРУЖИЯ"
            weaponBtn.Parent = contentFrame
            weaponBtn.MouseButton1Click:Connect(SpawnWeapon)
            
            local copySkinBtn = Instance.new("TextButton")
            copySkinBtn.Size = UDim2.new(1, 0, 0, 45)
            copySkinBtn.Text = "👕 КОПИРОВАТЬ СКИН"
            copySkinBtn.Parent = contentFrame
            copySkinBtn.MouseButton1Click:Connect(function()
                ShowPlayerSelector(CopySkin, "👕 ВЫБЕРИ ДЛЯ КОПИИ СКИНА")
            end)
            
            local crashServerBtn = Instance.new("TextButton")
            crashServerBtn.Size = UDim2.new(1, 0, 0, 45)
            crashServerBtn.Text = "💀 КРАШ СЕРВЕРА"
            crashServerBtn.BackgroundColor3 = Color3.fromRGB(229, 57, 53)
            crashServerBtn.Parent = contentFrame
            crashServerBtn.MouseButton1Click:Connect(function()
                CrashServer()
            end)
            
        elseif currentSection == 4 then -- Player
            local tpToBtn = Instance.new("TextButton")
            tpToBtn.Size = UDim2.new(1, 0, 0, 45)
            tpToBtn.Text = "📍 ТЕЛЕПОРТ К ИГРОКУ"
            tpToBtn.Parent = contentFrame
            tpToBtn.MouseButton1Click:Connect(function()
                ShowPlayerSelector(TeleportToPlayer, "📍 К КОМУ ТЕЛЕПОРТИРОВАТЬСЯ?")
            end)
            
            local tpMeBtn = Instance.new("TextButton")
            tpMeBtn.Size = UDim2.new(1, 0, 0, 45)
            tpMeBtn.Text = "🎯 ТЕЛЕПОРТ ИГРОКА К СЕБЕ"
            tpMeBtn.Parent = contentFrame
            tpMeBtn.MouseButton1Click:Connect(function()
                ShowPlayerSelector(TeleportPlayerToMe, "🎯 КОГО ТЕЛЕПОРТИРОВАТЬ?")
            end)
            
            local killBtn = Instance.new("TextButton")
            killBtn.Size = UDim2.new(1, 0, 0, 45)
            killBtn.Text = "💀 УБИТЬ ИГРОКА"
            killBtn.Parent = contentFrame
            killBtn.MouseButton1Click:Connect(function()
                ShowPlayerSelector(KillPlayer, "💀 КОГО УБИТЬ?")
            end)
            
        elseif currentSection == 5 then -- New
            local spinBtn = Instance.new("TextButton")
            spinBtn.Size = UDim2.new(1, 0, 0, 45)
            spinBtn.Text = spinEnabled and "🔄 ХВХ КРУТИЛКА: ВКЛ" or "🔄 ХВХ КРУТИЛКА: ВЫКЛ"
            spinBtn.BackgroundColor3 = spinEnabled and Color3.fromRGB(76, 175, 80) or Color3.fromRGB(40, 40, 45)
            spinBtn.Parent = contentFrame
            spinBtn.MouseButton1Click:Connect(function()
                spinEnabled = not spinEnabled
                spinBtn.Text = spinEnabled and "🔄 ХВХ КРУТИЛКА: ВКЛ" or "🔄 ХВХ КРУТИЛКА: ВЫКЛ"
                spinBtn.BackgroundColor3 = spinEnabled and Color3.fromRGB(76, 175, 80) or Color3.fromRGB(40, 40, 45)
            end)
            
            local spinSpeedBtn = Instance.new("TextButton")
            spinSpeedBtn.Size = UDim2.new(1, 0, 0, 45)
            spinSpeedBtn.Text = "⚙️ СКОРОСТЬ КРУЧЕНИЯ: " .. spinSpeed
            spinSpeedBtn.Parent = contentFrame
            spinSpeedBtn.MouseButton1Click:Connect(function()
                ShowSettings(function(val) spinSpeed = val spinSpeedBtn.Text = "⚙️ СКОРОСТЬ КРУЧЕНИЯ: " .. spinSpeed end, spinSpeed, 1, 10)
            end)
            
        elseif currentSection == 6 then -- Info
            local infoLabel = Instance.new("TextLabel")
            infoLabel.Size = UDim2.new(1, 0, 0, 30)
            infoLabel.Text = "👤 Ник: " .. LocalPlayer.Name
            infoLabel.BackgroundTransparency = 1
            infoLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
            infoLabel.Parent = contentFrame
            
            local timeLabel = Instance.new("TextLabel")
            timeLabel.Size = UDim2.new(1, 0, 0, 30)
            timeLabel.Text = "⏰ Время: " .. GetTime()
            timeLabel.BackgroundTransparency = 1
            timeLabel.Parent = contentFrame
            
            local fpsLabel = Instance.new("TextLabel")
            fpsLabel.Size = UDim2.new(1, 0, 0, 30)
            fpsLabel.Text = "📊 FPS: " .. GetFPS()
            fpsLabel.BackgroundTransparency = 1
            fpsLabel.Parent = contentFrame
            
            local pingLabel = Instance.new("TextLabel")
            pingLabel.Size = UDim2.new(1, 0, 0, 30)
            pingLabel.Text = "📡 Пинг: " .. GetPing() .. " ms"
            pingLabel.BackgroundTransparency = 1
            pingLabel.Parent = contentFrame
            
            -- Обновление информации
            task.spawn(function()
                while menuGui and menuGui.Parent do
                    if menuGui.Enabled and currentSection == 6 then
                        timeLabel.Text = "⏰ Время: " .. GetTime()
                        fpsLabel.Text = "📊 FPS: " .. GetFPS()
                        pingLabel.Text = "📡 Пинг: " .. GetPing() .. " ms"
                    end
                    task.wait(1)
                end
            end)
            
        elseif currentSection == 7 then -- Spin
            local wheelFrame = Instance.new("Frame")
            wheelFrame.Size = UDim2.new(1, 0, 0, 200)
            wheelFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
            wheelFrame.Parent = contentFrame
            
            local wheelBtn = Instance.new("TextButton")
            wheelBtn.Size = UDim2.new(0.8, 0, 0, 60)
            wheelBtn.Position = UDim2.new(0.1, 0, 0.6, 0)
            wheelBtn.Text = "🎡 КРУТИТЬ КОЛЕСО 🎡"
            wheelBtn.BackgroundColor3 = Color3.fromRGB(229, 57, 53)
            wheelBtn.Parent = wheelFrame
            wheelBtn.MouseButton1Click:Connect(function()
                local results = {
                    "Флай включен на 30 сек",
                    "Телепорт к рандом игроку",
                    "Ноклип 10 сек",
                    "Спавн ракетницы",
                    "Бессмертие 20 сек",
                    "Кик сам себя (шутка)"
                }
                local result = results[math.random(1, #results)]
                DynamicNotify("КОЛЕСО УДАЧИ: " .. result)
            end)
        end
    end
    
    -- Переключатель разделов по умолчанию
    if sectionButtons["Movement"] then
        sectionButtons["Movement"].BackgroundColor3 = Color3.fromRGB(229, 57, 53)
        sectionButtons["Movement"].TextColor3 = Color3.fromRGB(255, 255, 255)
    end
    UpdateContent()
end

-- === КНОПКА АКТИВАЦИИ ===
local function CreateToggleButton()
    local toggleGui = Instance.new("ScreenGui")
    toggleGui.Name = "ToggleButton"
    toggleGui.ResetOnSpawn = false
    toggleGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
    
    local toggleBtn = Instance.new("TextButton")
    toggleBtn.Size = UDim2.new(0, 50, 0, 50)
    toggleBtn.Position = UDim2.new(1, -60, 0.5, -25)
    toggleBtn.Text = "🍅"
    toggleBtn.TextSize = 30
    toggleBtn.BackgroundColor3 = Color3.fromRGB(229, 57, 53)
    toggleBtn.BorderSizePixel = 0
    toggleBtn.Parent = toggleGui
    
    toggleBtn.MouseButton1Click:Connect(function()
        if menuGui then
            menuGui.Enabled = not menuGui.Enabled
            settingsOpen = menuGui.Enabled
            toggleBtn.BackgroundColor3 = menuGui.Enabled and Color3.fromRGB(76, 175, 80) or Color3.fromRGB(229, 57, 53)
        end
    end)
    
    -- Перетаскивание кнопки
    local dragging = false
    local dragStartPos, startMousePos
    toggleBtn.MouseButton1Down:Connect(function()
        dragging = true
        dragStartPos = toggleBtn.Position
        startMousePos = UserInputService:GetMouseLocation()
    end)
    
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)
    
    RunService.RenderStepped:Connect(function()
        if dragging then
            local delta = UserInputService:GetMouseLocation() - startMousePos
            local newPos = UDim2.new(dragStartPos.X.Scale, dragStartPos.X.Offset + delta.X, dragStartPos.Y.Scale, dragStartPos.Y.Offset + delta.Y)
            toggleBtn.Position = newPos
        end
    end)
end

-- === ОТСЛЕЖИВАНИЕ СМЕРТИ ИГРОКА ===
local function SetupDeathListener()
    local function onCharacterAdded(character)
        local humanoid = character:WaitForChild("Humanoid")
        humanoid.Died:Connect(function()
            local killer = nil
            -- Попытка определить убийцу
            local lastDamager = humanoid:FindFirstChild("LastDamager")
            if lastDamager then
                killer = lastDamager.Value
            end
            if killer and killer == LocalPlayer then
                -- Тут можно добавить определение ника жертвы
                DynamicNotify("ВЫ УБИЛИ ИГРОКА")
            elseif killer then
                DynamicNotify("ВАС УБИЛ " .. string.upper(killer.Name))
            end
        end)
    end
    
    if LocalPlayer.Character then
        onCharacterAdded(LocalPlayer.Character)
    end
    LocalPlayer.CharacterAdded:Connect(onCharacterAdded)
end

-- === ЗАПУСК ===
CreateDynamicIsland()
SetupDeathListener()
BypassAntiCheat()
ShowKeyPrompt()

-- === ФИНАЛЬНОЕ СООБЩЕНИЕ ===
DynamicNotify("FACE HUB 2.3 BETA ЗАГРУЖЕН")
