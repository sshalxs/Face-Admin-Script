-- // SPEED HUB X | Version: 3.7.0 (Mobile)
-- // EDUCATIONAL PURPOSE ONLY
-- // DISCLAIMER: For Lua learning and research only. Not for actual use.
-- // Адаптировано для мобильных экзекьюторов (Delta, Arceus X, Codex)

local SpeedHubX = {
    Title = "Speed Hub X",
    Version = "3.7.0 Mobile",
    Creator = "FeVilAi"
}

-- // UI Library (Mobile-оптимизированный Rayfield)
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

-- // Main Window
local Window = Rayfield:CreateWindow({
    Name = SpeedHubX.Title .. " | " .. SpeedHubX.Version,
    Icon = "rbxassetid://7733765398",
    LoadingTitle = SpeedHubX.Title,
    LoadingSubtitle = "The Strongest Battlegrounds",
    Theme = "Dark"
})

-- // TABS
local MainTab = Window:CreateTab("Main", 7734058803)
local AutoKillTab = Window:CreateTab("Auto Kill", 7734058803)
local MiscTab = Window:CreateTab("Misc", 7734058803)
local PlayerTab = Window:CreateTab("Player", 7734058803)
local LocalPlayerTab = Window:CreateTab("Local Player", 7734058803)

-- ===================================================================
-- // ВСПОМОГАТЕЛЬНЫЕ ФУНКЦИИ ДЛЯ МОБИЛЬНОГО УПРАВЛЕНИЯ
-- ===================================================================

-- Эмуляция нажатия на кнопку (по названию)
local function tapButton(buttonName)
    local player = game.Players.LocalPlayer
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

-- Поиск ближайшего врага
local function getNearestEnemy()
    local player = game.Players.LocalPlayer
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

-- ===================================================================
-- // MAIN TAB
-- ===================================================================

-- Auto Ultimate (Mobile)
MainTab:CreateToggle({
    Name = "Auto Ultimate",
    CurrentValue = false,
    Callback = function(Value)
        _G.AutoUltimate = Value
        spawn(function()
            while _G.AutoUltimate do
                task.wait(0.1)
                local enemy = getNearestEnemy()
                if enemy then
                    tapButton("UltimateButton") -- Название кнопки ультимейта в игре
                end
            end
        end)
    end
})

-- Auto Dash (Mobile)
MainTab:CreateToggle({
    Name = "Auto Dash",
    CurrentValue = false,
    Callback = function(Value)
        _G.AutoDash = Value
        spawn(function()
            while _G.AutoDash do
                task.wait(0.3)
                local enemy = getNearestEnemy()
                if enemy then
                    tapButton("DashButton") -- Название кнопки рывка
                end
            end
        end)
    end
})

-- Aim (Select Body Part)
MainTab:CreateDropdown({
    Name = "Aim",
    Options = {"Head", "Torso", "Legs"},
    CurrentOption = "Head",
    Callback = function(Option)
        _G.AimPart = Option
    end
})

-- Aimlock (Mobile)
MainTab:CreateToggle({
    Name = "Aimlock",
    CurrentValue = false,
    Callback = function(Value)
        _G.Aimlock = Value
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
    end
})

-- ===================================================================
-- // AUTO KILL TAB
-- ===================================================================

-- Select Player
AutoKillTab:CreateInput({
    Name = "Select Player",
    CurrentValue = "",
    PlaceholderText = "Enter Player Name",
    Callback = function(Text)
        _G.SelectedPlayer = Text
    end
})

-- Auto Kill Player
AutoKillTab:CreateToggle({
    Name = "Auto Kill Player",
    CurrentValue = false,
    Callback = function(Value)
        _G.AutoKill = Value
        spawn(function()
            while _G.AutoKill do
                task.wait(0.1)
                for _, player in pairs(game.Players:GetPlayers()) do
                    if player.Name == _G.SelectedPlayer and player.Character then
                        local targetChar = player.Character
                        local myChar = game.Players.LocalPlayer.Character
                        if myChar then
                            -- Teleport to target
                            myChar.HumanoidRootPart.CFrame = targetChar.HumanoidRootPart.CFrame * CFrame.new(0, 0, 5)
                            -- Auto attack (M1)
                            tapButton("AttackButton") -- Кнопка атаки (M1)
                            task.wait(0.2)
                            tapButton("AttackButton")
                            task.wait(0.2)
                            tapButton("AttackButton")
                        end
                    end
                end
            end
        end)
    end
})

-- Teleport to Player
AutoKillTab:CreateButton({
    Name = "Teleport to Player",
    Callback = function()
        local player = game.Players[_G.SelectedPlayer]
        if player and player.Character then
            game.Players.LocalPlayer.Character.HumanoidRootPart.CFrame = player.Character.HumanoidRootPart.CFrame * CFrame.new(0, 0, 3)
        end
    end
})

-- Spectate Player
AutoKillTab:CreateButton({
    Name = "Spectate Player",
    Callback = function()
        local player = game.Players[_G.SelectedPlayer]
        if player and player.Character then
            workspace.CurrentCamera.CameraSubject = player.Character.Humanoid
        end
    end
})

-- ===================================================================
-- // MISC TAB
-- ===================================================================

-- Auto Dodge Attack (Mobile)
MiscTab:CreateToggle({
    Name = "Auto Dodge Attack",
    CurrentValue = false,
    Callback = function(Value)
        _G.AutoDodge = Value
        spawn(function()
            while _G.AutoDodge do
                task.wait(0.05)
                local enemy = getNearestEnemy()
                if enemy and enemy:FindFirstChild("Humanoid") then
                    -- Проверка анимации атаки (упрощённо)
                    local animator = enemy.Humanoid:FindFirstChild("Animator")
                    if animator then
                        for _, track in pairs(animator:GetPlayingAnimationTracks()) do
                            if track.Animation and string.find(track.Animation.Name, "Attack") then
                                tapButton("DashButton") -- Уклонение (рывок)
                                break
                            end
                        end
                    end
                end
            end
        end)
    end
})

-- Auto Block (Mobile)
MiscTab:CreateToggle({
    Name = "Auto Block",
    CurrentValue = false,
    Callback = function(Value)
        _G.AutoBlock = Value
        spawn(function()
            while _G.AutoBlock do
                task.wait(0.05)
                local enemy = getNearestEnemy()
                if enemy and enemy:FindFirstChild("Humanoid") then
                    local animator = enemy.Humanoid:FindFirstChild("Animator")
                    if animator then
                        for _, track in pairs(animator:GetPlayingAnimationTracks()) do
                            if track.Animation and string.find(track.Animation.Name, "Attack") then
                                tapButton("BlockButton") -- Активация блока
                                task.wait(0.3)
                                break
                            end
                        end
                    end
                end
            end
        end)
    end
})

-- Auto Void (если есть способность)
MiscTab:CreateToggle({
    Name = "Auto Void",
    CurrentValue = false,
    Callback = function(Value)
        _G.AutoVoid = Value
        spawn(function()
            while _G.AutoVoid do
                task.wait(0.5)
                local enemy = getNearestEnemy()
                if enemy then
                    tapButton("VoidButton") -- Кнопка способности Void
                end
            end
        end)
    end
})

-- Anti-Slow
MiscTab:CreateToggle({
    Name = "Anti-Slow",
    CurrentValue = false,
    Callback = function(Value)
        _G.AntiSlow = Value
        spawn(function()
            while _G.AntiSlow do
                task.wait(0.5)
                local char = game.Players.LocalPlayer.Character
                if char and char:FindFirstChild("Humanoid") then
                    local humanoid = char.Humanoid
                    if humanoid.WalkSpeed < 16 then
                        humanoid.WalkSpeed = 16 -- Сброс замедления
                    end
                end
            end
        end)
    end
})

-- ===================================================================
-- // PLAYER TAB
-- ===================================================================

-- Safe Mode (Auto Retreat)
PlayerTab:CreateToggle({
    Name = "Safe Mode",
    CurrentValue = false,
    Callback = function(Value)
        _G.SafeMode = Value
        spawn(function()
            while _G.SafeMode do
                task.wait(0.1)
                local char = game.Players.LocalPlayer.Character
                if char and char:FindFirstChild("Humanoid") then
                    local hp = char.Humanoid.Health
                    local maxHp = char.Humanoid.MaxHealth
                    if hp / maxHp < 0.3 then -- 30% здоровья
                        -- Телепорт в безопасное место (спавн)
                        local spawn = game:GetService("Workspace"):FindFirstChild("SpawnLocation")
                        if spawn then
                            char.HumanoidRootPart.CFrame = spawn.CFrame
                        end
                    end
                end
            end
        end)
    end
})

-- Anti-Knockback (BETA)
PlayerTab:CreateToggle({
    Name = "Anti-Knockback (BETA)",
    CurrentValue = false,
    Callback = function(Value)
        _G.AntiKnockback = Value
        spawn(function()
            while _G.AntiKnockback do
                task.wait()
                local char = game.Players.LocalPlayer.Character
                if char then
                    for _, v in pairs(char:GetChildren()) do
                        if v:IsA("BodyVelocity") or v:IsA("BodyForce") then
                            v:Destroy()
                        end
                    end
                end
            end
        end)
    end
})

-- Anti-Stun (BETA)
PlayerTab:CreateToggle({
    Name = "Anti-Stun (BETA)",
    CurrentValue = false,
    Callback = function(Value)
        _G.AntiStun = Value
        spawn(function()
            while _G.AntiStun do
                task.wait(0.1)
                local char = game.Players.LocalPlayer.Character
                if char and char:FindFirstChild("Humanoid") then
                    char.Humanoid.PlatformStand = false -- Сброс оглушения
                end
            end
        end)
    end
})

-- ===================================================================
-- // LOCAL PLAYER TAB
-- ===================================================================

-- Set WalkSpeed
LocalPlayerTab:CreateInput({
    Name = "WalkSpeed",
    CurrentValue = "16",
    PlaceholderText = "Speed (e.g. 999)",
    Callback = function(Text)
        _G.WalkSpeedValue = tonumber(Text) or 16
    end
})

-- Enable WalkSpeed
LocalPlayerTab:CreateToggle({
    Name = "Enable WalkSpeed",
    CurrentValue = false,
    Callback = function(Value)
        _G.EnableWalkSpeed = Value
        spawn(function()
            while _G.EnableWalkSpeed do
                task.wait()
                local char = game.Players.LocalPlayer.Character
                if char and char:FindFirstChild("Humanoid") then
                    char.Humanoid.WalkSpeed = _G.WalkSpeedValue or 999
                end
            end
        end)
    end
})

-- Set JumpPower
LocalPlayerTab:CreateInput({
    Name = "JumpPower",
    CurrentValue = "50",
    PlaceholderText = "Jump (e.g. 999)",
    Callback = function(Text)
        _G.JumpPowerValue = tonumber(Text) or 50
    end
})

-- Enable JumpPower
LocalPlayerTab:CreateToggle({
    Name = "Enable JumpPower",
    CurrentValue = false,
    Callback = function(Value)
        _G.EnableJumpPower = Value
        spawn(function()
            while _G.EnableJumpPower do
                task.wait()
                local char = game.Players.LocalPlayer.Character
                if char and char:FindFirstChild("Humanoid") then
                    char.Humanoid.JumpPower = _G.JumpPowerValue or 999
                end
            end
        end)
    end
})

-- No Clip (Mobile)
LocalPlayerTab:CreateToggle({
    Name = "No Clip",
    CurrentValue = false,
    Callback = function(Value)
        _G.NoClip = Value
        spawn(function()
            while _G.NoClip do
                task.wait()
                local char = game.Players.LocalPlayer.Character
                if char then
                    for _, part in pairs(char:GetChildren()) do
                        if part:IsA("BasePart") then
                            part.CanCollide = false
                        end
                    end
                end
            end
        end)
    end
})

-- Infinite Jump (Mobile)
LocalPlayerTab:CreateToggle({
    Name = "Infinite Jump",
    CurrentValue = false,
    Callback = function(Value)
        _G.InfiniteJump = Value
        spawn(function()
            game:GetService("UserInputService").JumpRequest:Connect(function()
                if _G.InfiniteJump then
                    local char = game.Players.LocalPlayer.Character
                    if char and char:FindFirstChild("Humanoid") then
                        char.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
                    end
                end
            end)
        end)
    end
})

-- ===================================================================
-- // ЗАПУСК (GUI)
-- ===================================================================

print("Speed Hub X (Mobile) loaded successfully!")
print("Version: 3.7.0 Mobile")
print("Features: Auto Ultimate, Auto Dash, Aimlock, Auto Kill, Auto Dodge, Auto Block, No Clip, Infinite Jump")