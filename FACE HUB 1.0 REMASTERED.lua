-- ==========================================
-- 🍅 FACE HUB 1.0 REMASTERED 🍅
-- ЧИСТАЯ ВЕРСИЯ
-- Автор: LuckyCore
-- ==========================================

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")
local Lighting = game:GetService("Lighting")
local Debris = game:GetService("Debris")
local SoundService = game:GetService("SoundService")
local StarterGui = game:GetService("StarterGui")
local TeleportService = game:GetService("TeleportService")

-- ==========================================
-- 📢 УВЕДОМЛЕНИЯ
-- ==========================================

local function Notify(Title, Text)
    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title = "🍅 " .. Title,
            Text = Text,
            Duration = 3
        })
    end)
end

-- ==========================================
-- 💥 CRASH (КРАШ СЕРВЕРА)
-- ==========================================

local function CrashServer()
    Notify("💀 CRASH", "Крашим сервер...")
    
    -- Массовый спавн частей
    for i = 1, 500 do
        local part = Instance.new("Part")
        part.Size = Vector3.new(50, 50, 50)
        part.Position = Vector3.new(math.random(-10000, 10000), math.random(-10000, 10000), math.random(-10000, 10000))
        part.Anchored = true
        part.Parent = Workspace
        task.wait()
    end
    
    -- GUI-краш для всех
    for _, player in ipairs(Players:GetPlayers()) do
        pcall(function()
            for i = 1, 100 do
                local gui = Instance.new("ScreenGui")
                gui.Name = "CrashGUI_" .. i
                gui.Parent = player:WaitForChild("PlayerGui")
                
                local frame = Instance.new("Frame")
                frame.Size = UDim2.new(1, 0, 1, 0)
                frame.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
                frame.Parent = gui
            end
        end)
    end
    
    task.wait(2)
    game:Shutdown()
end

-- ==========================================
-- 💨 TOUCH FLING (ФЛИНГ ПРИ ПРИБЛИЖЕНИИ)
-- ==========================================

local TouchFlingEnabled = false
local TouchFlingConnection = nil

local function FlingCharacter(character)
    if not character or not character:FindFirstChild("HumanoidRootPart") then return end
    local root = character.HumanoidRootPart
    local bodyVel = Instance.new("BodyVelocity")
    bodyVel.MaxForce = Vector3.new(9e9, 9e9, 9e9)
    bodyVel.Velocity = Vector3.new(math.random(-15000, 15000), 15000, math.random(-15000, 15000))
    bodyVel.Parent = root
    Debris:AddItem(bodyVel, 1)
end

local function EnableTouchFling()
    if TouchFlingEnabled then return end
    TouchFlingEnabled = true
    
    TouchFlingConnection = RunService.Heartbeat:Connect(function()
        if not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then return end
        local myPos = LocalPlayer.Character.HumanoidRootPart.Position
        
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                local targetPos = player.Character.HumanoidRootPart.Position
                if (myPos - targetPos).Magnitude < 10 then
                    FlingCharacter(player.Character)
                    Notify("💨 FLING", "Выкинул " .. player.Name)
                end
            end
        end
    end)
    
    Notify("💨 TOUCH FLING", "Включён (подойди к игроку)")
end

local function DisableTouchFling()
    if not TouchFlingEnabled then return end
    TouchFlingEnabled = false
    if TouchFlingConnection then
        TouchFlingConnection:Disconnect()
        TouchFlingConnection = nil
    end
    Notify("💨 TOUCH FLING", "Выключен")
end

-- ==========================================
-- 🌍 WORLD CONTROL
-- ==========================================

-- SKYBOX
local function SetBlackSkybox()
    local sky = Lighting:FindFirstChild("Sky") or Instance.new("Sky")
    sky.Parent = Lighting
    sky.SkyboxBk = "rbxassetid://19709525"
    sky.SkyboxDn = "rbxassetid://19709525"
    sky.SkyboxFt = "rbxassetid://19709525"
    sky.SkyboxLf = "rbxassetid://19709525"
    sky.SkyboxRt = "rbxassetid://19709525"
    sky.SkyboxUp = "rbxassetid://19709525"
    Lighting.Ambient = Color3.fromRGB(0, 0, 0)
    Lighting.Brightness = 0.2
    Notify("🌌 SKYBOX", "Чёрное небо")
end

-- MUSIC
local CurrentMusic = nil

local function PlayMusic(soundId)
    if CurrentMusic then
        CurrentMusic:Stop()
        CurrentMusic:Destroy()
    end
    local sound = Instance.new("Sound")
    sound.SoundId = soundId
    sound.Volume = 0.7
    sound.Looped = true
    sound.Parent = SoundService
    sound:Play()
    CurrentMusic = sound
    Notify("🎵 MUSIC", "Музыка включена")
end

local function StopMusic()
    if CurrentMusic then
        CurrentMusic:Stop()
        CurrentMusic:Destroy()
        CurrentMusic = nil
        Notify("🎵 MUSIC", "Музыка остановлена")
    end
end

-- DECAL
local function ApplyDecalToAll()
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("BasePart") then
            local decal = Instance.new("Decal")
            decal.Texture = "rbxassetid://145198809"
            decal.Face = Enum.NormalId.Front
            decal.Parent = obj
        end
    end
    Notify("🖼️ DECAL", "Текстуры наложены")
end

-- MESSAGE
local function SendServerMessage()
    for _, player in ipairs(Players:GetPlayers()) do
        pcall(function()
            StarterGui:SetCore("SendNotification", {
                Title = "FACE HUB",
                Text = "FACE HUB ВАШ БОГ",
                Duration = 5
            })
        end)
    end
    Notify("📨 MESSAGE", "Сообщение отправлено")
end

-- ==========================================
-- 🎭 ЭФФЕКТЫ
-- ==========================================

-- POLARIA
local PolariaActive = false
local PolariaEffect = nil

local function TogglePolaria()
    PolariaActive = not PolariaActive
    if PolariaActive then
        PolariaEffect = Instance.new("ColorCorrectionEffect")
        PolariaEffect.Parent = Lighting
        PolariaEffect.Saturation = -1
        PolariaEffect.TintColor = Color3.fromRGB(255, 0, 255)
        Notify("🌀 POLARIA", "Включена")
    else
        if PolariaEffect then PolariaEffect:Destroy() end
        Notify("🌀 POLARIA", "Выключена")
    end
end

-- DISCO
local DiscoActive = false
local DiscoThread = nil

local function StartDisco()
    if DiscoActive then return end
    DiscoActive = true
    DiscoThread = task.spawn(function()
        local colors = {Color3.fromRGB(255,0,0), Color3.fromRGB(0,255,0), Color3.fromRGB(0,0,255), Color3.fromRGB(255,255,0)}
        while DiscoActive do
            for _, color in ipairs(colors) do
                Lighting.Ambient = color
                task.wait(0.1)
            end
        end
    end)
    Notify("🪩 DISCO", "Дискотека!")
end

local function StopDisco()
    DiscoActive = false
    if DiscoThread then task.cancel(DiscoThread) end
    Lighting.Ambient = Color3.fromRGB(128, 128, 128)
    Notify("🪩 DISCO", "Остановлена")
end

-- ==========================================
-- 😱 JUMP SCARE
-- ==========================================

local function JumpscareAll()
    for _, player in ipairs(Players:GetPlayers()) do
        pcall(function()
            local gui = Instance.new("ScreenGui")
            gui.Parent = player:WaitForChild("PlayerGui")
            local frame = Instance.new("Frame")
            frame.Size = UDim2.new(1, 0, 1, 0)
            frame.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
            frame.Parent = gui
            
            local sound = Instance.new("Sound")
            sound.SoundId = "rbxassetid://9120386439"
            sound.Volume = 1
            sound.Parent = frame
            sound:Play()
            
            task.wait(0.5)
            gui:Destroy()
        end)
    end
    Notify("😱 JUMP SCARE", "Скример всем!")
end

-- ==========================================
-- 💀 ALL KILL / ALL KICK
-- ==========================================

local function KillAllPlayers()
    for _, player in ipairs(Players:GetPlayers()) do
        if player.Character and player.Character:FindFirstChild("Humanoid") then
            player.Character.Humanoid.Health = 0
        end
    end
    Notify("💀 ALL KILL", "Все убиты!")
end

local function KickAllPlayers()
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            player:Kick("FACE HUB")
        end
    end
    Notify("👢 ALL KICK", "Все кикнуты!")
end

-- ==========================================
-- 👾 ENTITIES
-- ==========================================

local function SpawnA60()
    local model = Instance.new("Model")
    model.Name = "A-60"
    model.Parent = Workspace
    
    local part = Instance.new("Part")
    part.Size = Vector3.new(10, 5, 10)
    part.Color = Color3.fromRGB(255, 0, 0)
    part.Material = Enum.Material.Neon
    part.Anchored = true
    part.Parent = model
    
    local sound = Instance.new("Sound")
    sound.SoundId = "rbxassetid://547347628"
    sound.Volume = 1
    sound.Looped = true
    sound.Parent = part
    sound:Play()
    
    task.spawn(function()
        local speed = 50
        while model and model.Parent do
            part.Position = part.Position + Vector3.new(speed, 0, 0)
            if math.abs(part.Position.X) > 500 then
                speed = -speed
            end
            task.wait(0.1)
        end
    end)
    Notify("👾 A-60", "Монстр появился!")
end

-- ==========================================
-- 🎮 МЕНЮ
-- ==========================================

local sections = {"WORLD", "EFFECTS", "ABUSE", "ENTITIES"}
local currentSection = 1
local menuGui = nil
local menuOpen = false

local function CreateMenu()
    menuGui = Instance.new("ScreenGui")
    menuGui.Name = "FaceHub"
    menuGui.ResetOnSpawn = false
    menuGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
    menuGui.Enabled = false
    
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 350, 0, 450)
    frame.Position = UDim2.new(0.5, -175, 0.5, -225)
    frame.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
    frame.BackgroundTransparency = 0.1
    frame.BorderSizePixel = 0
    frame.Parent = menuGui
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 12)
    corner.Parent = frame
    
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 45)
    title.Text = "🍅 FACE HUB 1.0"
    title.TextColor3 = Color3.fromRGB(229, 57, 53)
    title.BackgroundTransparency = 1
    title.Font = Enum.Font.GothamBold
    title.TextSize = 22
    title.Parent = frame
    
    -- Табы
    local tabBar = Instance.new("Frame")
    tabBar.Size = UDim2.new(1, 0, 0, 40)
    tabBar.Position = UDim2.new(0, 0, 0, 45)
    tabBar.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
    tabBar.Parent = frame
    
    local tabButtons = {}
    for i, tab in ipairs(sections) do
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(0.25, 0, 1, 0)
        btn.Position = UDim2.new((i-1) * 0.25, 0, 0, 0)
        btn.Text = tab
        btn.BackgroundColor3 = i == 1 and Color3.fromRGB(229, 57, 53) or Color3.fromRGB(30, 30, 35)
        btn.TextColor3 = Color3.fromRGB(255, 255, 255)
        btn.BorderSizePixel = 0
        btn.Parent = tabBar
        tabButtons[tab] = btn
        
        btn.MouseButton1Click:Connect(function()
            currentSection = i
            for _, b in pairs(tabButtons) do
                b.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
            end
            btn.BackgroundColor3 = Color3.fromRGB(229, 57, 53)
            UpdateContent()
        end)
    end
    
    -- Контент
    local contentFrame = Instance.new("ScrollingFrame")
    contentFrame.Size = UDim2.new(1, -20, 1, -95)
    contentFrame.Position = UDim2.new(0, 10, 0, 90)
    contentFrame.BackgroundTransparency = 1
    contentFrame.CanvasSize = UDim2.new(0, 0, 0, 400)
    contentFrame.ScrollBarThickness = 5
    contentFrame.Parent = frame
    
    local contentLayout = Instance.new("UIListLayout")
    contentLayout.Padding = UDim.new(0, 8)
    contentLayout.Parent = contentFrame
    
    -- Кнопка закрытия
    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.new(0, 30, 0, 30)
    closeBtn.Position = UDim2.new(1, -35, 0, 8)
    closeBtn.Text = "✕"
    closeBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
    closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeBtn.Parent = frame
    closeBtn.MouseButton1Click:Connect(function()
        menuGui.Enabled = false
        menuOpen = false
    end)
    
    local function UpdateContent()
        for _, child in ipairs(contentFrame:GetChildren()) do
            if child:IsA("TextButton") then
                child:Destroy()
            end
        end
        
        if currentSection == 1 then -- WORLD
            local skyboxBtn = Instance.new("TextButton")
            skyboxBtn.Size = UDim2.new(1, 0, 0, 40)
            skyboxBtn.Text = "🌑 ЧЁРНОЕ НЕБО"
            skyboxBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
            skyboxBtn.Parent = contentFrame
            skyboxBtn.MouseButton1Click:Connect(SetBlackSkybox)
            
            local musicBtn = Instance.new("TextButton")
            musicBtn.Size = UDim2.new(1, 0, 0, 40)
            musicBtn.Text = "🎵 ХОРРОР МУЗЫКА"
            musicBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
            musicBtn.Parent = contentFrame
            musicBtn.MouseButton1Click:Connect(function()
                PlayMusic("rbxassetid://9120386439")
            end)
            
            local stopMusicBtn = Instance.new("TextButton")
            stopMusicBtn.Size = UDim2.new(1, 0, 0, 40)
            stopMusicBtn.Text = "⏹️ ОСТАНОВИТЬ МУЗЫКУ"
            stopMusicBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
            stopMusicBtn.Parent = contentFrame
            stopMusicBtn.MouseButton1Click:Connect(StopMusic)
            
            local decalBtn = Instance.new("TextButton")
            decalBtn.Size = UDim2.new(1, 0, 0, 40)
            decalBtn.Text = "🖼️ НАЛОЖИТЬ DECAL"
            decalBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
            decalBtn.Parent = contentFrame
            decalBtn.MouseButton1Click:Connect(ApplyDecalToAll)
            
            local msgBtn = Instance.new("TextButton")
            msgBtn.Size = UDim2.new(1, 0, 0, 40)
            msgBtn.Text = "📨 ОТПРАВИТЬ СООБЩЕНИЕ"
            msgBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
            msgBtn.Parent = contentFrame
            msgBtn.MouseButton1Click:Connect(SendServerMessage)
            
        elseif currentSection == 2 then -- EFFECTS
            local polariaBtn = Instance.new("TextButton")
            polariaBtn.Size = UDim2.new(1, 0, 0, 40)
            polariaBtn.Text = "🌀 POLARIA"
            polariaBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
            polariaBtn.Parent = contentFrame
            polariaBtn.MouseButton1Click:Connect(TogglePolaria)
            
            local discoBtn = Instance.new("TextButton")
            discoBtn.Size = UDim2.new(1, 0, 0, 40)
            discoBtn.Text = "🪩 DISCO"
            discoBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
            discoBtn.Parent = contentFrame
            discoBtn.MouseButton1Click:Connect(StartDisco)
            
            local stopDiscoBtn = Instance.new("TextButton")
            stopDiscoBtn.Size = UDim2.new(1, 0, 0, 40)
            stopDiscoBtn.Text = "⏹️ ОСТАНОВИТЬ DISCO"
            stopDiscoBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
            stopDiscoBtn.Parent = contentFrame
            stopDiscoBtn.MouseButton1Click:Connect(StopDisco)
            
            local jumpscareBtn = Instance.new("TextButton")
            jumpscareBtn.Size = UDim2.new(1, 0, 0, 40)
            jumpscareBtn.Text = "😱 JUMP SCARE"
            jumpscareBtn.BackgroundColor3 = Color3.fromRGB(229, 57, 53)
            jumpscareBtn.Parent = contentFrame
            jumpscareBtn.MouseButton1Click:Connect(JumpscareAll)
            
        elseif currentSection == 3 then -- ABUSE
            local crashBtn = Instance.new("TextButton")
            crashBtn.Size = UDim2.new(1, 0, 0, 40)
            crashBtn.Text = "💀 CRASH СЕРВЕРА"
            crashBtn.BackgroundColor3 = Color3.fromRGB(229, 57, 53)
            crashBtn.Parent = contentFrame
            crashBtn.MouseButton1Click:Connect(CrashServer)
            
            local touchFlingBtn = Instance.new("TextButton")
            touchFlingBtn.Size = UDim2.new(1, 0, 0, 40)
            touchFlingBtn.Text = "💨 TOUCH FLING"
            touchFlingBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
            touchFlingBtn.Parent = contentFrame
            touchFlingBtn.MouseButton1Click:Connect(ToggleTouchFling)
            
            local allKillBtn = Instance.new("TextButton")
            allKillBtn.Size = UDim2.new(1, 0, 0, 40)
            allKillBtn.Text = "💀 ALL KILL"
            allKillBtn.BackgroundColor3 = Color3.fromRGB(229, 57, 53)
            allKillBtn.Parent = contentFrame
            allKillBtn.MouseButton1Click:Connect(KillAllPlayers)
            
            local allKickBtn = Instance.new("TextButton")
            allKickBtn.Size = UDim2.new(1, 0, 0, 40)
            allKickBtn.Text = "👢 ALL KICK"
            allKickBtn.BackgroundColor3 = Color3.fromRGB(229, 57, 53)
            allKickBtn.Parent = contentFrame
            allKickBtn.MouseButton1Click:Connect(KickAllPlayers)
            
        elseif currentSection == 4 then -- ENTITIES
            local a60Btn = Instance.new("TextButton")
            a60Btn.Size = UDim2.new(1, 0, 0, 40)
            a60Btn.Text = "👾 A-60"
            a60Btn.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
            a60Btn.Parent = contentFrame
            a60Btn.MouseButton1Click:Connect(SpawnA60)
        end
    end
    
    UpdateContent()
end

-- ==========================================
-- 🔘 КНОПКА АКТИВАЦИИ
-- ==========================================

local function CreateToggleButton()
    local toggleGui = Instance.new("ScreenGui")
    toggleGui.Name = "FaceHubToggle"
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
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 25)
    corner.Parent = toggleBtn
    
    toggleBtn.MouseButton1Click:Connect(function()
        if menuGui then
            menuGui.Enabled = not menuGui.Enabled
            toggleBtn.BackgroundColor3 = menuGui.Enabled and Color3.fromRGB(76, 175, 80) or Color3.fromRGB(229, 57, 53)
        end
    end)
    
    -- Перетаскивание
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

-- ==========================================
-- 🚀 ЗАПУСК
-- ==========================================

CreateMenu()
CreateToggleButton()
Notify("FACE HUB", "1.0 REMASTERED ЗАГРУЖЕН")

print("🍅 FACE HUB 1.0 REMASTERED LOADED 🍅")
print("Автор: LuckyCore")
print("Команды: WORLD | EFFECTS | ABUSE | ENTITIES")