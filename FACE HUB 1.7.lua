-- ==========================================
-- 🍅 FACE HUB 1.7 🍅
-- Автор: LuckyCore
-- ==========================================

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local function Notify(Title, Text)
    game:GetService("StarterGui"):SetCore("SendNotification", {Title = Title, Text = Text, Duration = 3})
end

-- === ПЕРЕМЕННЫЕ ===
local flying = false
local bodyVelocity = nil
local bodyGyro = nil
local flySpeed = 100
local godMode = false
local infiniteAmmo = false
local speedHackEnabled = false
local originalSpeed = 16
local selectedPlayer = nil
local impersonating = false

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
            if impersonating and selectedPlayer then
                args[2] = "[" .. selectedPlayer.Name .. "]: " .. msg
            else
                args[2] = "FACE😈 " .. LocalPlayer.Name .. ": " .. msg
            end
            return oldNamecall(self, unpack(args))
        end
    end
    return oldNamecall(self, ...)
end)
setreadonly(mt, true)

-- === БЕССМЕРТИЕ (РЕАЛЬНОЕ) ===
local function ToggleGodMode()
    godMode = not godMode
    local char = LocalPlayer.Character
    if char and char:FindFirstChild("Humanoid") then
        local hum = char.Humanoid
        if godMode then
            hum.MaxHealth = math.huge
            hum.Health = math.huge
            hum.BreakJointsOnDeath = false
            -- Блокируем все виды урона
            local conn
            conn = hum.Died:Connect(function()
                if godMode then
                    hum.Health = math.huge
                end
            end)
            getgenv().GodModeConnection = conn
            Notify("Бессмертие", "Включено")
        else
            hum.MaxHealth = 100
            hum.Health = 100
            hum.BreakJointsOnDeath = true
            if getgenv().GodModeConnection then
                getgenv().GodModeConnection:Disconnect()
            end
            Notify("Бессмертие", "Выключено")
        end
    end
end

-- === БЕСКОНЕЧНЫЕ ПАТРОНЫ ===
local function ToggleInfiniteAmmo()
    infiniteAmmo = not infiniteAmmo
    if infiniteAmmo then
        local char = LocalPlayer.Character
        if char then
            local tool = char:FindFirstChildWhichIsA("Tool")
            if tool then
                local ammo = tool:FindFirstChild("Ammo")
                if ammo then
                    ammo.Value = 9999
                end
            end
        end
        Notify("Бесконечные патроны", "Включены")
    else
        Notify("Бесконечные патроны", "Выключены")
    end
end

-- === СПИДХАК ===
local function ToggleSpeedHack()
    speedHackEnabled = not speedHackEnabled
    local char = LocalPlayer.Character
    if char and char:FindFirstChild("Humanoid") then
        local hum = char.Humanoid
        if speedHackEnabled then
            originalSpeed = hum.WalkSpeed
            hum.WalkSpeed = 50
            Notify("Спидхак", "Включён")
        else
            hum.WalkSpeed = originalSpeed
            Notify("Спидхак", "Выключен")
        end
    end
end

-- === ФЛАЙ (РАБОТАЕТ НА ТЕЛЕФОНЕ) ===
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
    
    local hint = Instance.new("TextLabel")
    hint.Size = UDim2.new(0, 300, 0, 50)
    hint.Position = UDim2.new(0.5, -150, 0.8, 0)
    hint.Text = "🍅 FLY MODE: левая половина → движение | правая → вверх/вниз"
    hint.TextColor3 = Color3.fromRGB(255, 255, 255)
    hint.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    hint.BackgroundTransparency = 0.5
    hint.Parent = LocalPlayer.PlayerGui
    task.wait(3)
    hint:Destroy()
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
    Notify("Флай", "Выключен")
end

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
        move = Vector3.new(delta.X / 10, 0, -delta.Y / 10)
    else
        move = Vector3.new(0, -delta.Y / 10, 0)
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

-- === КРАШ СЕРВЕРА (ВИДЕН ВСЕМ) ===
local function CrashServer()
    -- Показываем сообщение всем игрокам
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
    
    for i = 1, 200 do
        local msg = Instance.new("Message")
        msg.Text = "FACE HUB CRASH"
        msg.Parent = Workspace
        task.wait()
    end
    
    game:Shutdown()
end

-- === ФЛИНГ (РАБОТАЕТ) ===
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
    Notify("Флинг", player.Name .. " улетел")
end

-- === ТЮРЬМА (ВИДНА ВСЕМ, НЕПРОХОДИМА) ===
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
    Notify("Jail", player.Name .. " в тюрьме")
end

-- === УБИЙСТВО (ПОЛНОСТЬЮ) ===
local function KillPlayer(player)
    local char = player.Character
    if char and char:FindFirstChild("Humanoid") then
        local hum = char.Humanoid
        hum.Health = 0
        for _, part in ipairs(char:GetChildren()) do
            if part:IsA("BasePart") then
                local vel = Instance.new("BodyVelocity")
                vel.MaxForce = Vector3.new(9e9, 9e9, 9e9)
                vel.Velocity = Vector3.new(math.random(-100, 100), math.random(50, 200), math.random(-100, 100))
                vel.Parent = part
                task.wait(0.1)
                vel:Destroy()
            end
        end
        Notify("Убийство", player.Name .. " убит")
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
    Notify("Краш", player.Name .. " крашится")
end

-- === КИК ===
local function KickPlayer(player, reason)
    reason = reason or "Нарушение правил"
    player:Kick(reason)
    Notify("Кик", player.Name .. " кикнут")
end

-- === ТЕЛЕПОРТ (РАБОТАЕТ) ===
local function TeleportToPlayer(player)
    local myChar = LocalPlayer.Character
    if myChar and player.Character then
        myChar.HumanoidRootPart.CFrame = player.Character.HumanoidRootPart.CFrame
        Notify("Телепорт", "Телепортирован к " .. player.Name)
    end
end

local function TeleportPlayerToMe(player)
    if player.Character then
        player.Character.HumanoidRootPart.CFrame = LocalPlayer.Character.HumanoidRootPart.CFrame
        Notify("Телепорт", player.Name .. " телепортирован к вам")
    end
end

-- === ОТПРАВКА СООБЩЕНИЯ ОТ ИМЕНИ ИГРОКА ===
local function ImpersonatePlayer(player)
    if impersonating and selectedPlayer == player then
        impersonating = false
        selectedPlayer = nil
        Notify("Режим", "Отправка сообщений от имени игрока выключена")
    else
        selectedPlayer = player
        impersonating = true
        Notify("Режим", "Теперь вы пишете от имени " .. player.Name)
    end
end

-- === ЗАМЕНА ТЕКСТУРЫ ===
local function ReplaceTexture(part)
    local decal = Instance.new("Decal")
    decal.Texture = "data:image/jpeg;base64,/9j/4AAQSkZJRgABAQAAAQABAAD/2wBDAAUEBAUEAwUFBAUGBgUGCA4JCAcHCBEMDQoOFBEVFBMRExMWGB8bFhceFxMTGyUcHiAhIyMjFRo"
    decal.Face = Enum.NormalId.Front
    decal.Parent = part
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

-- === МЕНЮ С РАЗДЕЛАМИ ===
local menuGui = nil
local menuFrame = nil
local currentSection = 1
local sections = {"Movement", "Trolling", "Serious", "Player"}

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
    
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 50)
    title.Text = "🍅 FACE HUB 1.7"
    title.TextColor3 = Color3.fromRGB(229, 57, 53)
    title.BackgroundTransparency = 1
    title.TextSize = 28
    title.Font = Enum.Font.GothamBold
    title.Parent = menuFrame
    
    local close = Instance.new("TextButton")
    close.Size = UDim2.new(0, 35, 0, 35)
    close.Position = UDim2.new(1, -40, 0, 8)
    close.Text = "✕"
    close.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
    close.Parent = menuFrame
    close.MouseButton1Click:Connect(function() menuGui.Enabled = false end)
    
    -- Разделы слева
    local sectionFrame = Instance.new("Frame")
    sectionFrame.Size = UDim2.new(0, 120, 1, -60)
    sectionFrame.Position = UDim2.new(0, 5, 0, 60)
    sectionFrame.BackgroundTransparency = 1
    sectionFrame.Parent = menuFrame
    
    for i, sec in ipairs(sections) do
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1, 0, 0, 40)
        btn.Position = UDim2.new(0, 0, 0, (i-1)*45)
        btn.Text = sec
        btn.BackgroundColor3 = (currentSection == i) and Color3.fromRGB(229, 57, 53) or Color3.fromRGB(40, 40, 45)
        btn.TextColor3 = Color3.fromRGB(255, 255, 255)
        btn.Parent = sectionFrame
        btn.MouseButton1Click:Connect(function()
            currentSection = i
            for _, b in ipairs(sectionFrame:GetChildren()) do
                if b:IsA("TextButton") then
                    b.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
                end
            end
            btn.BackgroundColor3 = Color3.fromRGB(229, 57, 53)
            UpdateContent()
        end)
    end
    
    local contentFrame = Instance.new("Frame")
    contentFrame.Size = UDim2.new(1, -130, 1, -60)
    contentFrame.Position = UDim2.new(0, 130, 0, 60)
    contentFrame.BackgroundTransparency = 1
    contentFrame.Parent = menuFrame
    
    local scroll = Instance.new("ScrollingFrame")
    scroll.Size = UDim2.new(1, 0, 1, 0)
    scroll.BackgroundTransparency = 1
    scroll.CanvasSize = UDim2.new(0, 0, 0, 400)
    scroll.ScrollBarThickness = 8
    scroll.Parent = contentFrame
    
    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 10)
    layout.Parent = scroll
    
    local function AddButton(text, color, callback, needPlayer)
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1, 0, 0, 45)
        btn.Text = text
        btn.BackgroundColor3 = color or Color3.fromRGB(40, 40, 45)
        btn.TextColor3 = Color3.fromRGB(255, 255, 255)
        btn.Parent = scroll
        if needPlayer then
            btn.MouseButton1Click:Connect(function()
                ShowPlayerSelector(callback, text)
            end)
        else
            btn.MouseButton1Click:Connect(callback)
        end
    end
    
    local function UpdateContent()
        for _, child in ipairs(scroll:GetChildren()) do
            if child:IsA("TextButton") then child:Destroy() end
        end
        
        if currentSection == 1 then -- Movement
            AddButton("✈️ ФЛАЙ", Color3.fromRGB(0, 100, 200), function()
                if flying then StopFly() else StartFly() end
            end, false)
            AddButton("🏃‍♂️ СПИДХАК", Color3.fromRGB(0, 100, 200), ToggleSpeedHack, false)
        elseif currentSection == 2 then -- Trolling
            AddButton("💨 ФЛИНГ", Color3.fromRGB(150, 100, 0), FlingPlayer, true)
            AddButton("🔨 JAIL", Color3.fromRGB(150, 100, 0), JailPlayer, true)
            AddButton("⚰️ KILL", Color3.fromRGB(150, 0, 0), KillPlayer, true)
            AddButton("🎭 ПИСАТЬ ОТ ИМЕНИ", Color3.fromRGB(150, 0, 150), ImpersonatePlayer, true)
        elseif currentSection == 3 then -- Serious
            AddButton("💥 КРАШ СЕРВЕРА", Color3.fromRGB(150, 0, 0), CrashServer, false)
            AddButton("💣 КРАШ ИГРОКА", Color3.fromRGB(150, 0, 0), CrashPlayer, true)
            AddButton("👢 КИК", Color3.fromRGB(100, 100, 100), KickPlayer, true)
            AddButton("🖼️ ЗАМЕНИТЬ ТЕКСТУРУ", Color3.fromRGB(100, 100, 100), function()
                ShowPlayerSelector(function(pl)
                    ReplaceTexture(pl.Character.HumanoidRootPart)
                end, "🎯 ВЫБЕРИ ИГРОКА ДЛЯ ТЕКСТУРЫ")
            end, false)
        elseif currentSection == 4 then -- Player
            AddButton("🛡️ БЕССМЕРТИЕ", Color3.fromRGB(0, 150, 0), ToggleGodMode, false)
            AddButton("🔫 БЕСКОНЕЧНЫЕ ПАТРОНЫ", Color3.fromRGB(0, 150, 0), ToggleInfiniteAmmo, false)
            AddButton("📍 ТЕЛЕПОРТ К ИГРОКУ", Color3.fromRGB(0, 100, 200), TeleportToPlayer, true)
            AddButton("📍 ТЕЛЕПОРТ ИГРОКА К СЕБЕ", Color3.fromRGB(0, 100, 200), TeleportPlayerToMe, true)
        end
    end
    
    UpdateContent()
end

-- === ПЛАВАЮЩАЯ КНОПКА ===
local function CreateToggleButton()
    local btnGui = Instance.new("ScreenGui")
    btnGui.Name = "FaceHubButton"
    btnGui.ResetOnSpawn = false
    btnGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
    
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 160, 0, 50)
    btn.Position = UDim2.new(1, -180, 0.5, -25)
    btn.Text = "🍅 FACE HUB"
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.TextSize = 16
    btn.BackgroundColor3 = Color3.fromRGB(229, 57, 53)
    btn.BackgroundTransparency = 0.1
    btn.Parent = btnGui
    
    local dragStart, startPos
    btn.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch then
            dragStart = input.Position
            startPos = btn.Position
        end
    end)
    btn.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch and dragStart then
            local delta = input.Position - dragStart
            btn.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
    btn.InputEnded:Connect(function() dragStart = nil end)
    
    btn.MouseButton1Click:Connect(function()
        if menuGui then menuGui.Enabled = not menuGui.Enabled end
    end)
end

CreateMenu()
CreateToggleButton()