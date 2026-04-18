-- ==========================================
-- 🔥 FACE ADMIN SCRIPT 🔥
-- Автор: LuckyCore
-- Ключ: FaceAdmin
-- ==========================================

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")

local function Notify(Title, Text)
    game:GetService("StarterGui"):SetCore("SendNotification", {Title = Title, Text = Text, Duration = 2})
end

-- === ЗАЩИТА КЛЮЧОМ ===
local Key = "FaceAdmin"
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
            StartCommandListener()
        else
            Notify("Ошибка", "Неверный ключ!")
        end
    end)
end

-- === КОМАНДЫ ===
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
    for i = 1, 50 do
        local msg = Instance.new("Message")
        msg.Text = "FACE ADMIN CRASH"
        msg.Parent = Workspace
        task.wait()
    end
    Notify("Краш", "Сервер крашится...")
end

local function JailPlayer(player, duration)
    local char = player.Character
    if not char then return end
    local pos = char.HumanoidRootPart.Position
    local jail = Instance.new("Part")
    jail.Size = Vector3.new(20, 20, 20)
    jail.Position = pos
    jail.Anchored = true
    jail.CanCollide = true
    jail.Color = Color3.fromRGB(255, 0, 0)
    jail.Material = Enum.Material.Neon
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
    
    if duration then
        task.wait(duration)
        for _, wall in ipairs(walls) do wall:Destroy() end
        jail:Destroy()
        Notify("Jail", player.Name .. " освобождён")
    end
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
    local banData = {
        name = player.Name,
        userId = player.UserId,
        until = os.time() + duration,
        reason = reason or "Нарушение правил"
    }
    local bans = getgenv().FaceBans or {}
    table.insert(bans, banData)
    getgenv().FaceBans = bans
    player:Kick("Вы забанены до " .. os.date("%Y-%m-%d %H:%M:%S", banData.until) .. " Причина: " .. banData.reason)
    Notify("Бан", player.Name .. " забанен на " .. duration .. " сек")
end

local function ParseDuration(str)
    if str:match("(%d+)ч") then
        return tonumber(str:match("(%d+)ч")) * 3600
    elseif str:match("(%d+)мин") then
        return tonumber(str:match("(%d+)мин")) * 60
    elseif str:match("(%d+)д") then
        return tonumber(str:match("(%d+)д")) * 86400
    elseif str:match("(%d+)м") then
        return tonumber(str:match("(%d+)м")) * 86400 * 30
    else
        return tonumber(str) or 0
    end
end

-- === GUI ИНФО ===
local function ShowInfoGUI()
    local gui = Instance.new("ScreenGui")
    gui.Name = "FaceAdminInfo"
    gui.ResetOnSpawn = false
    gui.Parent = LocalPlayer:WaitForChild("PlayerGui")
    
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 400, 0, 500)
    frame.Position = UDim2.new(0.5, -200, 0.5, -250)
    frame.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
    frame.Parent = gui
    
    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.new(0, 35, 0, 35)
    closeBtn.Position = UDim2.new(1, -40, 0, 5)
    closeBtn.Text = "✕"
    closeBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
    closeBtn.Parent = frame
    closeBtn.MouseButton1Click:Connect(function() gui:Destroy() end)
    
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 45)
    title.Text = "📋 FACE ADMIN - СПИСОК КОМАНД"
    title.TextColor3 = Color3.fromRGB(229, 57, 53)
    title.BackgroundTransparency = 1
    title.Parent = frame
    
    local searchBox = Instance.new("TextBox")
    searchBox.Size = UDim2.new(0.9, 0, 0, 35)
    searchBox.Position = UDim2.new(0.05, 0, 0.12, 0)
    searchBox.PlaceholderText = "Поиск команды..."
    searchBox.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
    searchBox.TextColor3 = Color3.fromRGB(255, 255, 255)
    searchBox.Parent = frame
    
    local scroll = Instance.new("ScrollingFrame")
    scroll.Size = UDim2.new(1, -20, 1, -180)
    scroll.Position = UDim2.new(0, 10, 0, 160)
    scroll.BackgroundTransparency = 1
    scroll.CanvasSize = UDim2.new(0, 0, 0, 600)
    scroll.ScrollBarThickness = 8
    scroll.Parent = frame
    
    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 5)
    layout.Parent = scroll
    
    local commands = {
        {cmd = "/crash server", desc = "Крашит весь сервер"},
        {cmd = '/jail "ник"', desc = "Заключает игрока в тюрьму"},
        {cmd = '/jail all', desc = "Заключает всех игроков в тюрьму"},
        {cmd = '/kill "ник"', desc = "Убивает игрока"},
        {cmd = '/kill all', desc = "Убивает всех игроков"},
        {cmd = '/crash "ник"', desc = "Крашит игру у игрока"},
        {cmd = '/crash all', desc = "Крашит игру у всех игроков"},
        {cmd = '/kick "ник" "причина"', desc = "Кикает игрока с указанной причиной"},
        {cmd = '/ban "ник" "время" "причина"', desc = "Банит игрока на время (1д, 5ч, 30мин, 1м)"},
        {cmd = '/info', desc = "Показывает это меню"},
    }
    
    local function UpdateList(filter)
        for _, child in ipairs(scroll:GetChildren()) do
            if child:IsA("TextButton") then child:Destroy() end
        end
        for _, cmdData in ipairs(commands) do
            if not filter or cmdData.cmd:lower():find(filter:lower()) then
                local btn = Instance.new("TextButton")
                btn.Size = UDim2.new(1, 0, 0, 40)
                btn.Text = cmdData.cmd .. "\n" .. cmdData.desc
                btn.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
                btn.TextColor3 = Color3.fromRGB(255, 255, 255)
                btn.TextWrapped = true
                btn.TextXAlignment = Enum.TextXAlignment.Left
                btn.Parent = scroll
            end
        end
    end
    
    searchBox.Changed:Connect(function()
        UpdateList(searchBox.Text)
    end)
    UpdateList()
end

-- === ПАРСИНГ КОМАНД ===
local function ExecuteCommand(msg)
    local args = {}
    for word in msg:gmatch("%S+") do
        table.insert(args, word)
    end
    if #args == 0 then return end
    
    local cmd = args[1]:lower()
    
    if cmd == "/crash" and args[2] == "server" then
        CrashServer()
    elseif cmd == "/jail" then
        if args[2] == "all" then
            for _, player in ipairs(GetAllPlayersExceptMe()) do
                JailPlayer(player)
            end
        elseif args[2] then
            local target = GetPlayerFromName(args[2])
            if target then JailPlayer(target) end
        end
    elseif cmd == "/kill" then
        if args[2] == "all" then
            for _, player in ipairs(GetAllPlayersExceptMe()) do
                KillPlayer(player)
            end
        elseif args[2] then
            local target = GetPlayerFromName(args[2])
            if target then KillPlayer(target) end
        end
    elseif cmd == "/crash" and args[2] and args[2] ~= "server" then
        if args[2] == "all" then
            for _, player in ipairs(GetAllPlayersExceptMe()) do
                CrashPlayer(player)
            end
        else
            local target = GetPlayerFromName(args[2])
            if target then CrashPlayer(target) end
        end
    elseif cmd == "/kick" then
        local target = GetPlayerFromName(args[2])
        if target then
            local reason = args[3] or "error"
            KickPlayer(target, reason)
        end
    elseif cmd == "/ban" then
        local target = GetPlayerFromName(args[2])
        if target and args[3] then
            local duration = ParseDuration(args[3])
            local reason = args[4] or "Нарушение правил"
            BanPlayer(target, duration, reason)
        end
    elseif cmd == "/info" then
        ShowInfoGUI()
    end
end

-- === ПРОСЛУШКА СООБЩЕНИЙ ===
local function StartCommandListener()
    local function onChat(msg)
        if msg:sub(1, 1) == "/" then
            ExecuteCommand(msg)
        end
    end
    
    local mt = getrawmetatable(game)
    local old = mt.__namecall
    setreadonly(mt, false)
    mt.__namecall = newcclosure(function(self, ...)
        local args = {...}
        local method = getnamecallmethod()
        if method == "FireServer" and tostring(self):find("SayMessageRequest") then
            local msg = args[2]
            if msg and msg:sub(1, 1) == "/" then
                onChat(msg)
                return nil
            end
        end
        return old(self, ...)
    end)
    setreadonly(mt, true)
    Notify("FACE ADMIN", "Команды активированы. /info")
end

ShowKeyPrompt()