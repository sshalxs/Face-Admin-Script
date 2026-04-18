-- ==========================================
-- 🔥 FACE ADMIN GUI 🔥
-- Автор: LuckyCore
-- Ключ: FaceAdmin
-- ==========================================

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")

local function Notify(Title, Text)
    game:GetService("StarterGui"):SetCore("SendNotification", {Title = Title, Text = Text, Duration = 2})
end

-- === ЗАЩИТА КЛЮЧОМ ===
local Key = "FaceAdmin"
local AccessGranted = false
local selectedPlayer = nil

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
    title.Text = "🔥 FACE ADMIN"
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
            Notify("Успех", "Доступ получен! FACE ADMIN")
            CreateMenu()
            CreateToggleButton()
        else
            Notify("Ошибка", "Неверный ключ!")
        end
    end)
end

-- === ФУНКЦИИ ===
local function GetPlayerFromName(name)
    for _, player in ipairs(Players:GetPlayers()) do
        if player.Name:lower():find(name:lower()) then
            return player
        end
    end
    return nil
end

local function GetAllPlayersExceptMe()
    local list = {}
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            table.insert(list, player)
        end
    end
    return list
end

local function CrashServer()
    for i = 1, 100 do
        local part = Instance.new("Part")
        part.Size = Vector3.new(50, 50, 50)
        part.Position = Vector3.new(math.random(-5000, 5000), math.random(-5000, 5000), math.random(-5000, 5000))
        part.Anchored = true
        part.Parent = Workspace
        task.wait()
    end
    Notify("Краш", "Сервер крашится...")
end

local function JailPlayer(player)
    local char = player.Character
    if not char then return end
    local pos = char.HumanoidRootPart.Position
    local jail = Instance.new("Part")
    jail.Size = Vector3.new(20, 20, 20)
    jail.Position = pos
    jail.Anchored = true
    jail.CanCollide = true
    jail.Color = Color3.fromRGB(255, 0, 0)
    jail.Parent = Workspace
    
    local walls = {}
    for i = -2, 2 do
        for j = -2, 2 do
            if math.abs(i) == 2 or math.abs(j) == 2 then
                local wall = Instance.new("Part")
                wall.Size = Vector3.new(4, 10, 4)
                wall.Position = pos + Vector3.new(i * 4, 5, j * 4)
                wall.Anchored = true
                wall.CanCollide = true
                wall.Color = Color3.fromRGB(100, 100, 100)
                wall.Parent = Workspace
                table.insert(walls, wall)
            end
        end
    end
    char.HumanoidRootPart.CFrame = pos
    Notify("Jail", player.Name .. " в тюрьме")
end

local function KillPlayer(player)
    local char = player.Character
    if char and char:FindFirstChild("Humanoid") then
        char.Humanoid.Health = 0
        Notify("Убийство", player.Name .. " убит")
    end
end

local function CrashPlayer(player)
    for i = 1, 50 do
        local part = Instance.new("Part")
        part.Size = Vector3.new(10, 10, 10)
        part.Position = player.Character.HumanoidRootPart.Position + Vector3.new(math.random(-20, 20), math.random(-20, 20), math.random(-20, 20))
        part.Anchored = true
        part.Parent = Workspace
        task.wait()
    end
    Notify("Краш", player.Name .. " крашится")
end

local function KickPlayer(player, reason)
    reason = reason or "error"
    player:Kick(reason)
    Notify("Кик", player.Name .. " кикнут. Причина: " .. reason)
end

local function BanPlayer(player, duration, reason)
    reason = reason or "Нарушение правил"
    player:Kick("Вы забанены. Причина: " .. reason)
    Notify("Бан", player.Name .. " забанен")
end

-- === ВЫБОР ИГРОКА ===
local function ShowPlayerSelector(callback)
    local selectorGui = Instance.new("ScreenGui")
    selectorGui.Name = "PlayerSelector"
    selectorGui.ResetOnSpawn = false
    selectorGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
    
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 300, 0, 400)
    frame.Position = UDim2.new(0.5, -150, 0.5, -200)
    frame.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
    frame.Parent = selectorGui
    
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 40)
    title.Text = "🎉 ВЫБЕРИТЕ ЖЕРТВУ 🎉"
    title.TextColor3 = Color3.fromRGB(229, 57, 53)
    title.BackgroundTransparency = 1
    title.Parent = frame
    
    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.new(0, 35, 0, 35)
    closeBtn.Position = UDim2.new(1, -40, 0, 5)
    closeBtn.Text = "✕"
    closeBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
    closeBtn.Parent = frame
    closeBtn.MouseButton1Click:Connect(function() selectorGui:Destroy() end)
    
    local searchBox = Instance.new("TextBox")
    searchBox.Size = UDim2.new(0.9, 0, 0, 35)
    searchBox.Position = UDim2.new(0.05, 0, 0.13, 0)
    searchBox.PlaceholderText = "Поиск игрока..."
    searchBox.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
    searchBox.TextColor3 = Color3.fromRGB(255, 255, 255)
    searchBox.Parent = frame
    
    local scroll = Instance.new("ScrollingFrame")
    scroll.Size = UDim2.new(1, -20, 1, -160)
    scroll.Position = UDim2.new(0, 10, 0, 170)
    scroll.BackgroundTransparency = 1
    scroll.CanvasSize = UDim2.new(0, 0, 0, 600)
    scroll.ScrollBarThickness = 8
    scroll.Parent = frame
    
    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 5)
    layout.Parent = scroll
    
    local function UpdateList(filter)
        for _, child in ipairs(scroll:GetChildren()) do
            if child:IsA("TextButton") then child:Destroy() end
        end
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer then
                if not filter or player.Name:lower():find(filter:lower()) then
                    local btn = Instance.new("TextButton")
                    btn.Size = UDim2.new(1, 0, 0, 40)
                    btn.Text = player.Name
                    btn.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
                    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
                    btn.Parent = scroll
                    btn.MouseButton1Click:Connect(function()
                        selectorGui:Destroy()
                        callback(player)
                    end)
                end
            end
        end
    end
    
    searchBox.Changed:Connect(function()
        UpdateList(searchBox.Text)
    end)
    UpdateList()
end

-- === МЕНЮ ===
local menuGui = nil
local menuFrame = nil

local function CreateMenu()
    menuGui = Instance.new("ScreenGui")
    menuGui.Name = "FaceAdminMenu"
    menuGui.ResetOnSpawn = false
    menuGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
    menuGui.Enabled = false
    
    menuFrame = Instance.new("Frame")
    menuFrame.Size = UDim2.new(0, 350, 0, 500)
    menuFrame.Position = UDim2.new(0.5, -175, 0.5, -250)
    menuFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
    menuFrame.BorderSizePixel = 0
    menuFrame.Parent = menuGui
    
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 60)
    title.Text = "FACE🫪ADMIN😘SCRIPT❤️"
    title.TextColor3 = Color3.fromRGB(229, 57, 53)
    title.BackgroundTransparency = 1
    title.TextSize = 24
    title.Font = Enum.Font.GothamBold
    title.Parent = menuFrame
    
    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.new(0, 35, 0, 35)
    closeBtn.Position = UDim2.new(1, -40, 0, 10)
    closeBtn.Text = "✕"
    closeBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
    closeBtn.Parent = menuFrame
    closeBtn.MouseButton1Click:Connect(function() menuGui.Enabled = false end)
    
    local content = Instance.new("ScrollingFrame")
    content.Size = UDim2.new(1, -20, 1, -100)
    content.Position = UDim2.new(0, 10, 0, 70)
    content.BackgroundTransparency = 1
    content.CanvasSize = UDim2.new(0, 0, 0, 500)
    content.ScrollBarThickness = 8
    content.Parent = menuFrame
    
    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 10)
    layout.Parent = content
    
    local function AddButton(text, callback, hasSettings)
        local btnFrame = Instance.new("Frame")
        btnFrame.Size = UDim2.new(1, 0, 0, 45)
        btnFrame.BackgroundTransparency = 1
        btnFrame.Parent = content
        
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(0.8, 0, 1, 0)
        btn.Text = text
        btn.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
        btn.TextColor3 = Color3.fromRGB(255, 255, 255)
        btn.Parent = btnFrame
        btn.MouseButton1Click:Connect(callback)
        
        if hasSettings then
            local settingsBtn = Instance.new("TextButton")
            settingsBtn.Size = UDim2.new(0.15, 0, 1, 0)
            settingsBtn.Position = UDim2.new(0.82, 0, 0, 0)
            settingsBtn.Text = "¡"
            settingsBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 65)
            settingsBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
            settingsBtn.TextSize = 18
            settingsBtn.Parent = btnFrame
            settingsBtn.MouseButton1Click:Connect(function()
                ShowPlayerSelector(callback)
            end)
        end
    end
    
    AddButton("💥 КРАШ СЕРВЕРА", CrashServer, false)
    AddButton("🔨 JAIL", function(player) if player then JailPlayer(player) end end, true)
    AddButton("⚰️ KILL", function(player) if player then KillPlayer(player) end end, true)
    AddButton("💣 CRASH", function(player) if player then CrashPlayer(player) end end, true)
    AddButton("👢 KICK", function(player) if player then 
        local reason = "Нарушение правил"
        KickPlayer(player, reason)
    end end, true)
    AddButton("🔨 БАН", function(player) if player then 
        local reason = "Нарушение правил"
        BanPlayer(player, 3600, reason)
    end end, true)
end

-- === ПЛАВАЮЩАЯ КНОПКА (прямоугольник) ===
local function CreateToggleButton()
    local btnGui = Instance.new("ScreenGui")
    btnGui.Name = "FaceAdminButton"
    btnGui.ResetOnSpawn = false
    btnGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
    
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 160, 0, 50)
    btn.Position = UDim2.new(1, -180, 0.5, -25)
    btn.Text = "FACE ADMIN\nSCRIPT"
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.TextSize = 14
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

ShowKeyPrompt()