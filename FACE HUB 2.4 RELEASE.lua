-- ==========================================
-- 🍅 FACE HUB 2.4 RELEASE 🍅
-- Автор: LuckyCore
-- Версия: 2.4 RELEASE
-- ==========================================

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")
local Stats = game:GetService("Stats")
local MarketplaceService = game:GetService("MarketplaceService")
local InsertService = game:GetService("InsertService")
local CollectionService = game:GetService("CollectionService")
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")

-- === ОБЫЧНЫЕ УВЕДОМЛЕНИЯ ===
local function Notify(Title, Text)
    game:GetService("StarterGui"):SetCore("SendNotification", {
        Title = Title,
        Text = Text,
        Duration = 3
    })
end

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
local monsterMode = false
local originalCharacter = nil
local originalAppearance = nil
local originalHealth = nil
local originalMaxHealth = nil
local originalWalkSpeed = nil
local originalJumpPower = nil
local adminMode = false
local originalCollide = {}
local currentSection = 1
local sections = {"Movement", "Trolling", "Admin", "Player", "Monster", "Fun", "Server", "Info", "Spin"}
local menuGui = nil
local menuFrame = nil
local settingsOpen = false

-- === ВЫДАЧА АДМИНА / КОНТРОЛЬ СЕРВЕРА ===
local function GiveAdmin(player)
    -- Метод 1: Через Remote Events (если есть админка в игре)
    local success = false
    
    -- Поиск всех RemoteEvent/RemoteFunction
    for _, obj in ipairs(ReplicatedStorage:GetDescendants()) do
        if obj:IsA("RemoteEvent") and obj.Name:lower():find("admin") or obj.Name:lower():find("command") then
            pcall(function()
                obj:FireServer(player, "admin", "give")
                success = true
            end)
        end
    end
    
    -- Метод 2: Через Toolbox админки
    local adminTools = {
        "https://www.roblox.com/library/142823491/Admin-House-CMD",
        "https://www.roblox.com/library/416058008/Admin-System",
        "https://www.roblox.com/library/104251703/Admin-Commands",
        "https://www.roblox.com/library/670917463/Admin-Tool"
    }
    
    for _, url in ipairs(adminTools) do
        pcall(function()
            local assetId = tonumber(url:match("library/(%d+)"))
            if assetId then
                local tool = InsertService:LoadAsset(assetId)
                if tool and tool:FindFirstChildWhichIsA("Tool") then
                    local adminTool = tool:FindFirstChildWhichIsA("Tool"):Clone()
                    adminTool.Parent = player.Backpack
                    success = true
                end
            end
        end)
    end
    
    -- Метод 3: Через FE обход
    pcall(function()
        local fakeRemote = Instance.new("RemoteEvent")
        fakeRemote.Name = "AdminCommand"
        fakeRemote.Parent = ReplicatedStorage
        fakeRemote.OnServerEvent:Connect(function(plr, cmd)
            if plr == player then
                -- Эмуляция админ команды
                Notify("ADMIN", "Команда выполнена: " .. cmd)
            end
        end)
    end)
    
    if success then
        Notify("🍅 FACE HUB", "Админ выдан " .. player.Name)
    else
        Notify("🍅 FACE HUB", "Попытка выдачи админа выполнена")
    end
end

local function GiveAllAdmin()
    for _, player in ipairs(Players:GetPlayers()) do
        GiveAdmin(player)
    end
    Notify("🍅 FACE HUB", "Админ выдан всем")
end

-- === КОНТРОЛЬ НАД СЕРВЕРОМ ===
local function ServerControl(action)
    if action == "shutdown" then
        for i = 5, 1, -1 do
            Notify("🍅 FACE HUB", "Выключение через " .. i)
            task.wait(1)
        end
        game:Shutdown()
    elseif action == "restart" then
        TeleportService:Teleport(game.PlaceId)
    elseif action == "clear" then
        for _, obj in ipairs(Workspace:GetChildren()) do
            if not obj:IsA("BasePart") and not obj:IsA("Model") then
                obj:Destroy()
            end
        end
        Notify("🍅 FACE HUB", "Сервер очищен")
    elseif action == "lag" then
        for i = 1, 1000 do
            local part = Instance.new("Part")
            part.Size = Vector3.new(10, 10, 10)
            part.Position = Vector3.new(math.random(-1000, 1000), math.random(-1000, 1000), math.random(-1000, 1000))
            part.Anchored = true
            part.Parent = Workspace
        end
        Notify("🍅 FACE HUB", "Сервер лагает")
    end
end

-- === СТАТЬ МОНСТРОМ ===
local monsterOutfits = {
    {id = 121006100, name = "Skeleton King"},
    {id = 138271700, name = "Demon Lord"},
    {id = 155458170, name = "Shadow Reaper"},
    {id = 165892500, name = "Vampire Lord"},
    {id = 183270099, name = "Werewolf"},
    {id = 201157103, name = "Dark Phantom"},
}

local function BecomeMonster()
    if monsterMode then
        if originalCharacter and LocalPlayer.Character then
            local hum = LocalPlayer.Character:FindFirstChild("Humanoid")
            if hum and originalAppearance then
                hum:ApplyDescription(originalAppearance)
            end
            if originalHealth and hum then
                hum.Health = originalHealth
                hum.MaxHealth = originalMaxHealth
            end
            if originalWalkSpeed and hum then
                hum.WalkSpeed = originalWalkSpeed
            end
            if originalJumpPower and hum then
                hum.JumpPower = originalJumpPower
            end
        end
        monsterMode = false
        Notify("🍅 FACE HUB", "Вы вернули обычный облик")
    else
        if LocalPlayer.Character then
            local hum = LocalPlayer.Character:FindFirstChild("Humanoid")
            if hum then
                originalAppearance = hum:GetAppliedDescription()
                originalHealth = hum.Health
                originalMaxHealth = hum.MaxHealth
                originalWalkSpeed = hum.WalkSpeed
                originalJumpPower = hum.JumpPower
            end
        end
        
        local monster = monsterOutfits[math.random(1, #monsterOutfits)]
        
        pcall(function()
            local desc = Instance.new("HumanoidDescription")
            desc.Id = monster.id
            if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
                LocalPlayer.Character.Humanoid:ApplyDescription(desc)
            end
        end)
        
        if LocalPlayer.Character then
            local hum = LocalPlayer.Character:FindFirstChild("Humanoid")
            if hum then
                hum.WalkSpeed = 32
                hum.JumpPower = 80
                hum.MaxHealth = 500
                hum.Health = 500
            end
        end
        
        monsterMode = true
        Notify("🍅 FACE HUB", "ВЫ СТАЛИ МОНСТРОМ! " .. monster.name)
    end
end

-- === FUN ФУНКЦИИ ===
local function Dance()
    local animations = {
        "rbxassetid://507770000",  -- Dance 1
        "rbxassetid://507770284",  -- Dance 2
        "rbxassetid://507770462",  -- Dance 3
        "rbxassetid://507770642",  -- Dance 4
    }
    local animId = animations[math.random(1, #animations)]
    local anim = Instance.new("Animation")
    anim.AnimationId = animId
    local track = LocalPlayer.Character.Humanoid:LoadAnimation(anim)
    track:Play()
    Notify("🍅 FACE HUB", "Танцуем!")
end

local function ExplodePlayer(player)
    local char = player.Character
    if char and char:FindFirstChild("HumanoidRootPart") then
        local explosion = Instance.new("Explosion")
        explosion.BlastRadius = 10
        explosion.BlastPressure = 1000000
        explosion.Position = char.HumanoidRootPart.Position
        explosion.Parent = Workspace
        explosion.Hit:Connect(function(hit)
            if hit.Parent and hit.Parent:FindFirstChild("Humanoid") then
                hit.Parent.Humanoid.Health = 0
            end
        end)
        Notify("🍅 FACE HUB", player.Name .. " взорван")
    end
end

local function FreezePlayer(player)
    local char = player.Character
    if char and char:FindFirstChild("HumanoidRootPart") then
        local bodyVel = Instance.new("BodyVelocity")
        bodyVel.Velocity = Vector3.new(0, 0, 0)
        bodyVel.MaxForce = Vector3.new(9e9, 9e9, 9e9)
        bodyVel.Parent = char.HumanoidRootPart
        task.delay(5, function()
            bodyVel:Destroy()
        end)
        Notify("🍅 FACE HUB", player.Name .. " заморожен")
    end
end

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
    Notify("🍅 FACE HUB", "КРАШ СЕРВЕРА")
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
    Notify("🍅 FACE HUB", "Выкинули " .. player.Name)
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
    Notify("🍅 FACE HUB", player.Name .. " в тюрьме")
end

-- === УБИЙСТВО ===
local function KillPlayer(player)
    local char = player.Character
    if char and char:FindFirstChild("Humanoid") then
        char.Humanoid.Health = 0
        Notify("🍅 FACE HUB", "Убили " .. player.Name)
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
    Notify("🍅 FACE HUB", "Крашнули " .. player.Name)
end

-- === КИК ===
local function KickPlayer(player, reason)
    reason = reason or "Нарушение правил"
    player:Kick(reason)
    Notify("🍅 FACE HUB", "Кикнули " .. player.Name)
end

-- === ТЕЛЕПОРТ ===
local function TeleportToPlayer(player)
    local myChar = LocalPlayer.Character
    if myChar and player.Character then
        myChar.HumanoidRootPart.CFrame = player.Character.HumanoidRootPart.CFrame
        Notify("🍅 FACE HUB", "Телепорт к " .. player.Name)
    end
end

local function TeleportPlayerToMe(player)
    if player.Character then
        player.Character.HumanoidRootPart.CFrame = LocalPlayer.Character.HumanoidRootPart.CFrame
        Notify("🍅 FACE HUB", player.Name .. " телепортирован к вам")
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
                Notify("🍅 FACE HUB", "Оружие " .. name .. " спавнено")
                return
            end
        end
        for _, obj in ipairs(ReplicatedStorage:GetDescendants()) do
            if obj.Name:lower():find(name:lower()) and obj:IsA("Tool") then
                local tool = obj:Clone()
                tool.Parent = LocalPlayer.Backpack
                Notify("🍅 FACE HUB", "Оружие " .. name .. " спавнено")
                return
            end
        end
        Notify("🍅 FACE HUB", "Оружие не найдено")
    end)
end

-- === COPY SKIN ===
local function CopySkin(player)
    if player.Character then
        local appearance = player.Character:FindFirstChild("Humanoid") and player.Character.Humanoid:GetAppliedDescription()
        if appearance then
            LocalPlayer.Character.Humanoid:ApplyDescription(appearance)
            Notify("🍅 FACE HUB", "Скопирован скин " .. player.Name)
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

-- === БЕССМЕРТИЕ ===
local function ToggleGodMode()
    godMode = not godMode
    local char = LocalPlayer.Character
    if char and char:FindFirstChild("Humanoid") then
        local hum = char.Humanoid
        if godMode then
            hum.MaxHealth = 10000000
            hum.Health = 10000000
            Notify("🍅 FACE HUB", "Бессмертие ВКЛ")
        else
            hum.MaxHealth = 100
            hum.Health = 100
            Notify("🍅 FACE HUB", "Бессмертие ВЫКЛ")
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
    Notify("🍅 FACE HUB", noclipEnabled and "Ноклип ВКЛ" or "Ноклип ВЫКЛ")
end

-- === INFINITY JUMP ===
local function ToggleInfinityJump()
    infinityJump = not infinityJump
    Notify("🍅 FACE HUB", infinityJump and "Infinity Jump ВКЛ" or "Infinity Jump ВЫКЛ")
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
    Notify("🍅 FACE HUB", "Флай ВКЛ")
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
    Notify("🍅 FACE HUB", "Флай ВЫКЛ")
end

local function SetFlySpeed(speed)
    flySpeed = speed
    Notify("🍅 FACE HUB", "Скорость флая: " .. speed)
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
            Notify("Ошибка", "Значение от " .. minVal .. " до " .. maxVal)
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
    title.Text = "🍅 FACE HUB 2.4 RELEASE 🍅"
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
    contentFrame.CanvasSize = UDim2.new(0, 0, 0, 1200)
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
            
            local explodeBtn = Instance.new("TextButton")
            explodeBtn.Size = UDim2.new(1, 0, 0, 45)
            explodeBtn.Text = "💥 ВЗОРВАТЬ ИГРОКА"
            explodeBtn.Parent = contentFrame
            explodeBtn.MouseButton1Click:Connect(function()
                ShowPlayerSelector(ExplodePlayer, "💥 КОГО ВЗОРВАТЬ?")
            end)
            
            local freezeBtn = Instance.new("TextButton")
            freezeBtn.Size = UDim2.new(1, 0, 0, 45)
            freezeBtn.Text = "❄️ ЗАМОРОЗИТЬ ИГРОКА"
            freezeBtn.Parent = contentFrame
            freezeBtn.MouseButton1Click:Connect(function()
                ShowPlayerSelector(FreezePlayer, "❄️ КОГО ЗАМОРОЗИТЬ?")
            end)
            
        elseif currentSection == 3 then -- Admin
            local giveAdminBtn = Instance.new("TextButton")
            giveAdminBtn.Size = UDim2.new(1, 0, 0, 45)
            giveAdminBtn.Text = "👑 ВЫДАТЬ АДМИН ИГРОКУ"
            giveAdminBtn.Parent = contentFrame
            giveAdminBtn.MouseButton1Click:Connect(function()
                ShowPlayerSelector(GiveAdmin, "👑 КОМУ ВЫДАТЬ АДМИН?")
            end)
            
            local allAdminBtn = Instance.new("TextButton")
            allAdminBtn.Size = UDim2.new(1, 0, 0, 45)
            allAdminBtn.Text = "👑 ВЫДАТЬ АДМИН ВСЕМ"
            allAdminBtn.BackgroundColor3 = Color3.fromRGB(229, 57, 53)
            allAdminBtn.Parent = contentFrame
            allAdminBtn.MouseButton1Click:Connect(function()
                GiveAllAdmin()
            end)
            
            local shutdownBtn = Instance.new("TextButton")
            shutdownBtn.Size = UDim2.new(1, 0, 0, 45)
            shutdownBtn.Text = "🖥️ ВЫКЛЮЧИТЬ СЕРВЕР"
            shutdownBtn.BackgroundColor3 = Color3.fromRGB(229, 57, 53)
            shutdownBtn.Parent = contentFrame
            shutdownBtn.MouseButton1Click:Connect(function()
                ServerControl("shutdown")
            end)
            
            local restartBtn = Instance.new("TextButton")
            restartBtn.Size = UDim2.new(1, 0, 0, 45)
            restartBtn.Text = "🔄 ПЕРЕЗАПУСТИТЬ СЕРВЕР"
            restartBtn.Parent = contentFrame
            restartBtn.MouseButton1Click:Connect(function()
                ServerControl("restart")
            end)
            
            local clearBtn = Instance.new("TextButton")
            clearBtn.Size = UDim2.new(1, 0, 0, 45)
            clearBtn.Text = "🧹 ОЧИСТИТЬ СЕРВЕР"
            clearBtn.Parent = contentFrame
            clearBtn.MouseButton1Click:Connect(function()
                ServerControl("clear")
            end)
            
            local lagBtn = Instance.new("TextButton")
            lagBtn.Size = UDim2.new(1, 0, 0, 45)
            lagBtn.Text = "🐌 ЗАЛАГАТЬ СЕРВЕР"
            lagBtn.Parent = contentFrame
            lagBtn.MouseButton1Click:Connect(function()
                ServerControl("lag")
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
            
            local copySkinBtn = Instance.new("TextButton")
            copySkinBtn.Size = UDim2.new(1, 0, 0, 45)
            copySkinBtn.Text = "👕 КОПИРОВАТЬ СКИН"
            copySkinBtn.Parent = contentFrame
            copySkinBtn.MouseButton1Click:Connect(function()
                ShowPlayerSelector(CopySkin, "👕 ВЫБЕРИ ДЛЯ КОПИИ СКИНА")
            end)
            
            local weaponBtn = Instance.new("TextButton")
            weaponBtn.Size = UDim2.new(1, 0, 0, 45)
            weaponBtn.Text = "🔫 СПАВН ОРУЖИЯ"
            weaponBtn.Parent = contentFrame
            weaponBtn.MouseButton1Click:Connect(SpawnWeapon)
            
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
            
        elseif currentSection == 5 then -- Monster
            local monsterBtn = Instance.new("TextButton")
            monsterBtn.Size = UDim2.new(1, 0, 0, 45)
            monsterBtn.Text = monsterMode and "👹 СНЯТЬ МОНСТРА" or "👹 СТАТЬ МОНСТРОМ"
            monsterBtn.BackgroundColor3 = monsterMode and Color3.fromRGB(76, 175, 80) or Color3.fromRGB(229, 57, 53)
            monsterBtn.Parent = contentFrame
            monsterBtn.MouseButton1Click:Connect(function()
                BecomeMonster()
                monsterBtn.Text = monsterMode and "👹 СНЯТЬ МОНСТРА" or "👹 СТАТЬ МОНСТРОМ"
                monsterBtn.BackgroundColor3 = monsterMode and Color3.fromRGB(76, 175, 80) or Color3.fromRGB(229, 57, 53)
            end)
            
            local scarySoundBtn = Instance.new("TextButton")
            scarySoundBtn.Size = UDim2.new(1, 0, 0, 45)
            scarySoundBtn.Text = "🔊 СТРАШНЫЙ ЗВУК"
            scarySoundBtn.Parent = contentFrame
            scarySoundBtn.MouseButton1Click:Connect(function()
                PlayScarySound()
            end)
            
        elseif currentSection == 6 then -- Fun
            local danceBtn = Instance.new("TextButton")
            danceBtn.Size = UDim2.new(1, 0, 0, 45)
            danceBtn.Text = "💃 ПОТАНЦЕВАТЬ"
            danceBtn.Parent = contentFrame
            danceBtn.MouseButton1Click:Connect(Dance)
            
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
            
        elseif currentSection == 7 then -- Server
            local playersCount = Instance.new("TextLabel")
            playersCount.Size = UDim2.new(1, 0, 0, 30)
            playersCount.Text = "👥 Игроков на сервере: " .. #Players:GetPlayers()
            playersCount.BackgroundTransparency = 1
            playersCount.TextColor3 = Color3.fromRGB(200, 200, 200)
            playersCount.Parent = contentFrame
            
            local serverTime = Instance.new("TextLabel")
            serverTime.Size = UDim2.new(1, 0, 0, 30)
            serverTime.Text = "⏱️ Время работы: " .. math.floor(workspace.DistributedGameTime) .. " сек"
            serverTime.BackgroundTransparency = 1
            serverTime.TextColor3 = Color3.fromRGB(200, 200, 200)
            serverTime.Parent = contentFrame
            
            local gameId = Instance.new("TextLabel")
            gameId.Size = UDim2.new(1, 0, 0, 30)
            gameId.Text = "🆔 Place ID: " .. game.PlaceId
            gameId.BackgroundTransparency = 1
            gameId.TextColor3 = Color3.fromRGB(200, 200, 200)
            gameId.Parent = contentFrame
            
            local jobId = Instance.new("TextLabel")
            jobId.Size = UDim2.new(1, 0, 0, 30)
            jobId.Text = "🔑 Job ID: " .. game.JobId
            jobId.BackgroundTransparency = 1
            jobId.TextColor3 = Color3.fromRGB(200, 200, 200)
            jobId.Parent = contentFrame
            
            task.spawn(function()
                while menuGui and menuGui.Parent do
                    if menuGui.Enabled and currentSection == 7 then
                        playersCount.Text = "👥 Игроков на сервере: " .. #Players:GetPlayers()
                        serverTime.Text = "⏱️ Время работы: " .. math.floor(workspace.DistributedGameTime) .. " сек"
                    end
                    task.wait(1)
                end
            end)
            
        elseif currentSection == 8 then -- Info
            local infoLabel = Instance.new("TextLabel")
            infoLabel.Size = UDim2.new(1, 0, 0, 30)
            infoLabel.Text = "👤 Ник: " .. LocalPlayer.Name
            infoLabel.BackgroundTransparency = 1
            infoLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
            infoLabel.Parent = contentFrame
            
            local userIdLabel = Instance.new("TextLabel")
            userIdLabel.Size = UDim2.new(1, 0, 0, 30)
            userIdLabel.Text = "🆔 User ID: " .. LocalPlayer.UserId
            userIdLabel.BackgroundTransparency = 1
            userIdLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
            userIdLabel.Parent = contentFrame
            
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
            
            local versionLabel = Instance.new("TextLabel")
            versionLabel.Size = UDim2.new(1, 0, 0, 30)
            versionLabel.Text = "🍅 Версия: 2.4 RELEASE"
            versionLabel.BackgroundTransparency = 1
            versionLabel.TextColor3 = Color3.fromRGB(229, 57, 53)
            versionLabel.Parent = contentFrame
            
            -- Обновление информации
            task.spawn(function()
                while menuGui and menuGui.Parent do
                    if menuGui.Enabled and currentSection == 8 then
                        timeLabel.Text = "⏰ Время: " .. GetTime()
                        fpsLabel.Text = "📊 FPS: " .. GetFPS()
                        pingLabel.Text = "📡 Пинг: " .. GetPing() .. " ms"
                    end
                    task.wait(1)
                end
            end)
            
        elseif currentSection == 9 then -- Spin (Колесо удачи)
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
                    "Все игроки затанцевали",
                    "Вы стали монстром",
                    "Сервер очищен",
                }
                local result = results[math.random(1, #results)]
                
                -- Выполняем действие
                if result == "Флай включен на 30 сек" then
                    StartFly()
                    task.delay(30, StopFly)
                elseif result == "Ноклип 10 сек" then
                    ToggleNoclip()
                    task.delay(10, ToggleNoclip)
                elseif result == "Бессмертие 20 сек" then
                    ToggleGodMode()
                    task.delay(20, ToggleGodMode)
                elseif result == "Все игроки затанцевали" then
                    for _, p in ipairs(Players:GetPlayers()) do
                        if p.Character and p.Character:FindFirstChild("Humanoid") then
                            local anim = Instance.new("Animation")
                            anim.AnimationId = "rbxassetid://507770000"
                            local track = p.Character.Humanoid:LoadAnimation(anim)
                            track:Play()
                        end
                    end
                elseif result == "Вы стали монстром" then
                    BecomeMonster()
                elseif result == "Сервер очищен" then
                    ServerControl("clear")
                end
                
                Notify("🍅 КОЛЕСО УДАЧИ", "🎲 Вам выпало: " .. result)
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

-- === СТРАШНЫЙ ЗВУК ===
local function PlayScarySound()
    local sound = Instance.new("Sound")
    sound.SoundId = "rbxassetid://9120386439"
    sound.Volume = 1
    sound.Parent = LocalPlayer.Character or Workspace
    sound:Play()
    task.delay(3, function()
        sound:Destroy()
    end)
    Notify("🍅 FACE HUB", "Страшный звук!")
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
    Notify("🍅 FACE HUB", "Античит обойдён")
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

-- === ОТСЛЕЖИВАНИЕ СМЕРТИ ===
local function SetupDeathListener()
    local function onCharacterAdded(character)
        local humanoid = character:WaitForChild("Humanoid")
        humanoid.Died:Connect(function()
            local killer = nil
            local lastDamager = humanoid:FindFirstChild("LastDamager")
            if lastDamager then
                killer = lastDamager.Value
            end
            if killer and killer == LocalPlayer then
                Notify("🍅 FACE HUB", "ВЫ УБИЛИ ИГРОКА")
            elseif killer then
                Notify("🍅 FACE HUB", "ВАС УБИЛ " .. string.upper(killer.Name))
            end
        end)
    end
    
    if LocalPlayer.Character then
        onCharacterAdded(LocalPlayer.Character)
    end
    LocalPlayer.CharacterAdded:Connect(onCharacterAdded)
end

-- === ЗАПУСК ===
CreateMenu()
CreateToggleButton()
SetupDeathListener()
BypassAntiCheat()
Notify("🍅 FACE HUB", "2.4 RELEASE загружен!")

-- === ФИНАЛ ===
print("🍅 FACE HUB 2.4 RELOADED 🍅")
print("Автор: LuckyCore")
print("Разделы: Movement, Trolling, Admin, Player, Monster, Fun, Server, Info, Spin")