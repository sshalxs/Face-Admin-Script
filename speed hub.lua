-- // SPEED HUB X | Version: 4.1
-- // EDUCATIONAL PURPOSE ONLY
-- // DISCLAIMER: For Lua learning and research only. Not for actual use.
-- // UI: SpeedHub (Custom)
-- // РАЗДЕЛЫ: Main | Auto Kill | Misc | Player | Local Player

local SpeedHubX = {
    Title = "Speed Hub X",
    Version = "4.1",
    Creator = "FeVilAi"
}

-- ============================================================
-- // UI (SpeedHub) — ОСНОВНОЕ ОКНО
-- ============================================================

local player = game.Players.LocalPlayer
local gui = player:WaitForChild("PlayerGui")

local oldGui = gui:FindFirstChild("SpeedHubX")
if oldGui then oldGui:Destroy() end

local hubGui = Instance.new("ScreenGui")
hubGui.Name = "SpeedHubX"
hubGui.ResetOnSpawn = false
hubGui.Parent = gui

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 450, 0, 600)
mainFrame.Position = UDim2.new(0.5, -225, 0.5, -300)
mainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
mainFrame.BackgroundTransparency = 0.1
mainFrame.BorderSizePixels = 0
mainFrame.ClipsDescendants = true
mainFrame.Parent = hubGui

-- Заголовок
local titleBar = Instance.new("Frame")
titleBar.Size = UDim2.new(1, 0, 0, 40)
titleBar.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
titleBar.BackgroundTransparency = 0.3
titleBar.Parent = mainFrame

local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(1, -80, 1, 0)
titleLabel.Position = UDim2.new(0, 10, 0, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "Speed Hub X v4.1"
titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
titleLabel.TextScaled = true
titleLabel.Font = Enum.Font.GothamBold
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.Parent = titleBar

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 30, 0, 30)
closeBtn.Position = UDim2.new(1, -35, 0, 5)
closeBtn.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
closeBtn.Text = "X"
closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
closeBtn.TextScaled = true
closeBtn.Font = Enum.Font.GothamBold
closeBtn.Parent = titleBar
closeBtn.MouseButton1Click:Connect(function() hubGui:Destroy() end)

-- Контейнер для вкладок
local tabContainer = Instance.new("Frame")
tabContainer.Size = UDim2.new(1, 0, 0, 40)
tabContainer.Position = UDim2.new(0, 0, 0, 40)
tabContainer.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
tabContainer.BackgroundTransparency = 0.2
tabContainer.Parent = mainFrame

-- Контейнер для содержимого
local contentContainer = Instance.new("ScrollingFrame")
contentContainer.Size = UDim2.new(1, -10, 1, -90)
contentContainer.Position = UDim2.new(0, 5, 0, 80)
contentContainer.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
contentContainer.BackgroundTransparency = 0.1
contentContainer.BorderSizePixels = 0
contentContainer.ScrollBarThickness = 4
contentContainer.ScrollBarImageColor3 = Color3.fromRGB(255, 0, 0)
contentContainer.Parent = mainFrame

local contentList = Instance.new("UIListLayout")
contentList.Padding = UDim.new(0, 5)
contentList.SortOrder = Enum.SortOrder.LayoutOrder
contentList.Parent = contentContainer

-- ============================================================
-- // СИСТЕМА ВКЛАДОК
-- ============================================================

local tabs = {}

local function createTab(name)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 80, 1, -5)
    btn.Position = UDim2.new(0, 5 + (#tabs * 85), 0, 2)
    btn.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
    btn.BackgroundTransparency = 0.3
    btn.Text = name
    btn.TextColor3 = Color3.fromRGB(200, 200, 200)
    btn.TextScaled = true
    btn.Font = Enum.Font.GothamSemibold
    btn.Parent = tabContainer

    local tabContent = Instance.new("Frame")
    tabContent.Size = UDim2.new(1, 0, 1, 0)
    tabContent.BackgroundTransparency = 1
    tabContent.Visible = false
    tabContent.Parent = contentContainer

    local tabList = Instance.new("UIListLayout")
    tabList.Padding = UDim.new(0, 8)
    tabList.SortOrder = Enum.SortOrder.LayoutOrder
    tabList.Parent = tabContent

    table.insert(tabs, {btn = btn, content = tabContent})

    btn.MouseButton1Click:Connect(function()
        for _, tab in pairs(tabs) do
            tab.content.Visible = false
            tab.btn.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
            tab.btn.TextColor3 = Color3.fromRGB(200, 200, 200)
        end
        tabContent.Visible = true
        btn.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
        btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    end)

    if #tabs == 1 then
        tabContent.Visible = true
        btn.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
        btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    end

    return tabContent
end

-- ============================================================
-- // ФУНКЦИИ UI
-- ============================================================

local function createToggle(parent, label, default, callback)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, -10, 0, 35)
    frame.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
    frame.BackgroundTransparency = 0.2
    frame.Parent = parent

    local labelText = Instance.new("TextLabel")
    labelText.Size = UDim2.new(0.7, -10, 1, 0)
    labelText.Position = UDim2.new(0, 5, 0, 0)
    labelText.BackgroundTransparency = 1
    labelText.Text = label
    labelText.TextColor3 = Color3.fromRGB(220, 220, 220)
    labelText.TextScaled = true
    labelText.Font = Enum.Font.GothamMedium
    labelText.TextXAlignment = Enum.TextXAlignment.Left
    labelText.Parent = frame

    local toggleBtn = Instance.new("TextButton")
    toggleBtn.Size = UDim2.new(0, 60, 0, 25)
    toggleBtn.Position = UDim2.new(1, -65, 0.5, -12.5)
    toggleBtn.BackgroundColor3 = default and Color3.fromRGB(255, 0, 0) or Color3.fromRGB(100, 100, 100)
    toggleBtn.Text = default and "ON" or "OFF"
    toggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    toggleBtn.TextScaled = true
    toggleBtn.Font = Enum.Font.GothamBold
    toggleBtn.Parent = frame

    local value = default
    toggleBtn.MouseButton1Click:Connect(function()
        value = not value
        toggleBtn.BackgroundColor3 = value and Color3.fromRGB(255, 0, 0) or Color3.fromRGB(100, 100, 100)
        toggleBtn.Text = value and "ON" or "OFF"
        callback(value)
    end)

    return frame
end

local function createInput(parent, label, placeholder, callback)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, -10, 0, 40)
    frame.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
    frame.BackgroundTransparency = 0.2
    frame.Parent = parent

    local labelText = Instance.new("TextLabel")
    labelText.Size = UDim2.new(0.4, -5, 1, 0)
    labelText.Position = UDim2.new(0, 5, 0, 0)
    labelText.BackgroundTransparency = 1
    labelText.Text = label
    labelText.TextColor3 = Color3.fromRGB(220, 220, 220)
    labelText.TextScaled = true
    labelText.Font = Enum.Font.GothamMedium
    labelText.TextXAlignment = Enum.TextXAlignment.Left
    labelText.Parent = frame

    local inputBox = Instance.new("TextBox")
    inputBox.Size = UDim2.new(0.5, -10, 0, 25)
    inputBox.Position = UDim2.new(0.5, 5, 0.5, -12.5)
    inputBox.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
    inputBox.TextColor3 = Color3.fromRGB(255, 255, 255)
    inputBox.PlaceholderText = placeholder or ""
    inputBox.PlaceholderColor3 = Color3.fromRGB(150, 150, 150)
    inputBox.TextScaled = true
    inputBox.Font = Enum.Font.GothamMedium
    inputBox.Parent = frame

    inputBox.FocusLost:Connect(function(enterPressed)
        if enterPressed then callback(inputBox.Text) end
    end)

    return frame
end

local function createButton(parent, label, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -10, 0, 35)
    btn.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
    btn.Text = label
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.TextScaled = true
    btn.Font = Enum.Font.GothamBold
    btn.Parent = parent
    btn.MouseButton1Click:Connect(callback)
    return btn
end

local function createDropdown(parent, label, options, default, callback)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, -10, 0, 40)
    frame.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
    frame.BackgroundTransparency = 0.2
    frame.Parent = parent

    local labelText = Instance.new("TextLabel")
    labelText.Size = UDim2.new(0.4, -5, 1, 0)
    labelText.Position = UDim2.new(0, 5, 0, 0)
    labelText.BackgroundTransparency = 1
    labelText.Text = label
    labelText.TextColor3 = Color3.fromRGB(220, 220, 220)
    labelText.TextScaled = true
    labelText.Font = Enum.Font.GothamMedium
    labelText.TextXAlignment = Enum.TextXAlignment.Left
    labelText.Parent = frame

    local dropdown = Instance.new("TextButton")
    dropdown.Size = UDim2.new(0.5, -10, 0, 25)
    dropdown.Position = UDim2.new(0.5, 5, 0.5, -12.5)
    dropdown.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
    dropdown.Text = default or options[1]
    dropdown.TextColor3 = Color3.fromRGB(255, 255, 255)
    dropdown.TextScaled = true
    dropdown.Font = Enum.Font.GothamMedium
    dropdown.Parent = frame

    local index = 1
    dropdown.MouseButton1Click:Connect(function()
        index = index % #options + 1
        dropdown.Text = options[index]
        callback(options[index])
    end)

    return frame
end

-- ============================================================
-- // СОЗДАНИЕ ВКЛАДОК
-- ============================================================

local mainTab = createTab("Main")
local autoKillTab = createTab("Auto Kill")
local miscTab = createTab("Misc")
local playerTab = createTab("Player")
local localPlayerTab = createTab("Local Player")

-- ============================================================
-- // ВСПОМОГАТЕЛЬНЫЕ ФУНКЦИИ
-- ============================================================

local function getNearestEnemy()
    local char = player.Character
    if not char then return nil end
    local nearest = nil
    local minDist = math.huge
    for _, v in pairs(game.Players:GetPlayers()) do
        if v ~= player and v.Character and v.Character:FindFirstChild("Humanoid") then
            local dist = (v.Character.Head.Position - char.Head.Position).Magnitude
            if dist < minDist and dist < 20 then
                minDist = dist
                nearest = v.Character
            end
        end
    end
    return nearest
end

local function isAttacking(character)
    local humanoid = character:FindFirstChild("Humanoid")
    if not humanoid then return false end
    local animator = humanoid:FindFirstChild("Animator")
    if not animator then return false end
    for _, track in pairs(animator:GetPlayingAnimationTracks()) do
        if track.Animation and string.find(track.Animation.Name, "Attack") then
            return true
        end
    end
    return false
end

local function tapButton(buttonName)
    local gui = player.PlayerGui
    local button = gui:FindFirstChild(buttonName, true)
    if button and button:IsA("ImageButton") then
        local touch = Instance.new("TouchEvent")
        touch.Position = button.AbsolutePosition + button.AbsoluteSize / 2
        touch.UserInputState = Enum.UserInputState.Begin
        button:FireTouchEvent(touch)
        task.wait(0.05)
        touch.UserInputState = Enum.UserInputState.End
        button:FireTouchEvent(touch)
        return true
    end
    return false
end

-- ============================================================
-- // MAIN TAB
-- ============================================================

createToggle(mainTab, "Auto Ultimate", false, function(v)
    _G.AutoUltimate = v
    spawn(function()
        while _G.AutoUltimate do
            task.wait(0.1)
            local enemy = getNearestEnemy()
            if enemy then tapButton("UltimateButton") end
        end
    end)
end)

createToggle(mainTab, "Auto Dash", false, function(v)
    _G.AutoDash = v
    spawn(function()
        while _G.AutoDash do
            task.wait(0.3)
            local enemy = getNearestEnemy()
            if enemy then tapButton("DashButton") end
        end
    end)
end)

createDropdown(mainTab, "Aim", {"Head", "Torso", "Legs"}, "Head", function(opt)
    _G.AimPart = opt
end)

createToggle(mainTab, "Aimlock", false, function(v)
    _G.Aimlock = v
    spawn(function()
        while _G.Aimlock do
            task.wait()
            local enemy = getNearestEnemy()
            if enemy then
                local camera = workspace.CurrentCamera
                local part = enemy:FindFirstChild(_G.AimPart or "Head") or enemy.Head
                camera.CFrame = CFrame.new(camera.CFrame.Position, part.Position)
            end
        end
    end)
end)

-- ============================================================
-- // AUTO KILL TAB
-- ============================================================

createInput(autoKillTab, "Select Player", "Enter Name", function(text)
    _G.SelectedPlayer = text
end)

createToggle(autoKillTab, "Auto Kill Player", false, function(v)
    _G.AutoKill = v
    spawn(function()
        while _G.AutoKill do
            task.wait(0.1)
            for _, p in pairs(game.Players:GetPlayers()) do
                if p.Name == _G.SelectedPlayer and p.Character then
                    local target = p.Character
                    local myChar = player.Character
                    if myChar then
                        myChar.HumanoidRootPart.CFrame = target.HumanoidRootPart.CFrame * CFrame.new(0, 0, 5)
                        tapButton("AttackButton")
                        task.wait(0.2)
                        tapButton("AttackButton")
                        task.wait(0.2)
                        tapButton("AttackButton")
                    end
                end
            end
        end
    end)
end)

createButton(autoKillTab, "Teleport to Player", function()
    local p = game.Players[_G.SelectedPlayer]
    if p and p.Character then
        player.Character.HumanoidRootPart.CFrame = p.Character.HumanoidRootPart.CFrame * CFrame.new(0, 0, 3)
    end
end)

createButton(autoKillTab, "Spectate Player", function()
    local p = game.Players[_G.SelectedPlayer]
    if p and p.Character then
        workspace.CurrentCamera.CameraSubject = p.Character.Humanoid
    end
end)

-- ============================================================
-- // MISC TAB
-- ============================================================

createToggle(miscTab, "Auto Dodge Attack", false, function(v)
    _G.AutoDodge = v
    spawn(function()
        while _G.AutoDodge do
            task.wait(0.05)
            local enemy = getNearestEnemy()
            if enemy and isAttacking(enemy) then
                tapButton("DashButton")
            end
        end
    end)
end)

createToggle(miscTab, "Auto Block", false, function(v)
    _G.AutoBlock = v
    spawn(function()
        while _G.AutoBlock do
            task.wait(0.05)
            local enemy = getNearestEnemy()
            if enemy and isAttacking(enemy) then
                tapButton("BlockButton")
                task.wait(0.3)
            end
        end
    end)
end)

createToggle(miscTab, "Auto Void", false, function(v)
    _G.AutoVoid = v
    spawn(function()
        while _G.AutoVoid do
            task.wait(0.5)
            local enemy = getNearestEnemy()
            if enemy then tapButton("VoidButton") end
        end
    end)
end)

createToggle(miscTab, "Anti-Slow", false, function(v)
    _G.AntiSlow = v
    spawn(function()
        while _G.AntiSlow do
            task.wait(0.5)
            local char = player.Character
            if char and char:FindFirstChild("Humanoid") then
                if char.Humanoid.WalkSpeed < 16 then
                    char.Humanoid.WalkSpeed = 16
                end
            end
        end
    end)
end)

-- ============================================================
-- // PLAYER TAB
-- ============================================================

createToggle(playerTab, "Safe Mode", false, function(v)
    _G.SafeMode = v
    spawn(function()
        while _G.SafeMode do
            task.wait(0.1)
            local char = player.Character
            if char and char:FindFirstChild("Humanoid") then
                local hp = char.Humanoid.Health
                local maxHp = char.Humanoid.MaxHealth
                if hp / maxHp < 0.3 then
                    local spawn = workspace:FindFirstChild("SpawnLocation")
                    if spawn then
                        char.HumanoidRootPart.CFrame = spawn.CFrame
                    end
                end
            end
        end
    end)
end)

createToggle(playerTab, "Anti-Knockback (BETA)", false, function(v)
    _G.AntiKnockback = v
    spawn(function()
        while _G.AntiKnockback do
            task.wait()
            local char = player.Character
            if char then
                for _, v in pairs(char:GetChildren()) do
                    if v:IsA("BodyVelocity") or v:IsA("BodyForce") then
                        v:Destroy()
                    end
                end
            end
        end
    end)
end)

createToggle(playerTab, "Anti-Stun (BETA)", false, function(v)
    _G.AntiStun = v
    spawn(function()
        while _G.AntiStun do
            task.wait(0.1)
            local char = player.Character
            if char and char:FindFirstChild("Humanoid") then
                char.Humanoid.PlatformStand = false
            end
        end
    end)
end)

-- ============================================================
-- // LOCAL PLAYER TAB
-- ============================================================

createInput(localPlayerTab, "WalkSpeed", "Speed (e.g. 999)", function(text)
    _G.WalkSpeedValue = tonumber(text) or 16
end)

createToggle(localPlayerTab, "Enable WalkSpeed", false, function(v)
    _G.EnableWalkSpeed = v
    spawn(function()
        while _G.EnableWalkSpeed do
            task.wait()
            local char = player.Character
            if char and char:FindFirstChild("Humanoid") then
                char.Humanoid.WalkSpeed = _G.WalkSpeedValue or 999
            end
        end
    end)
end)

createInput(localPlayerTab, "JumpPower", "Jump (e.g. 999)", function(text)
    _G.JumpPowerValue = tonumber(text) or 50
end)

createToggle(localPlayerTab, "Enable JumpPower", false, function(v)
    _G.EnableJumpPower = v
    spawn(function()
        while _G.EnableJumpPower do
            task.wait()
            local char = player.Character
            if char and char:FindFirstChild("Humanoid") then
                char.Humanoid.JumpPower = _G.JumpPowerValue or 999
            end
        end
    end)
end)

createToggle(localPlayerTab, "No Clip", false, function(v)
    _G.NoClip = v
    spawn(function()
        while _G.NoClip do
            task.wait()
            local char = player.Character
            if char then
                for _, part in pairs(char:GetChildren()) do
                    if part:IsA("BasePart") then
                        part.CanCollide = false
                    end
                end
            end
        end
    end)
end)

createToggle(localPlayerTab, "Infinite Jump", false, function(v)
    _G.InfiniteJump = v
    spawn(function()
        game:GetService("UserInputService").JumpRequest:Connect(function()
            if _G.InfiniteJump then
                local char = player.Character
                if char and char:FindFirstChild("Humanoid") then
                    char.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
                end
            end
        end)
    end)
end)

-- ============================================================
-- // ЗАПУСК
-- ============================================================

print("Speed Hub X v4.1 loaded successfully!")
print("Разделы: Main | Auto Kill | Misc | Player | Local Player")