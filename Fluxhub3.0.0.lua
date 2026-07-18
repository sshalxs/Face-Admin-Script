-- // FeVilAi Core: FluxHub 3.0 (Sheriff vs Murders Duels)
-- // Massive Update: ESP, Hitboxes separated, New Features

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
    Name = "FLUXHUB 3.0 | FeVilAi",
    LoadingTitle = "FLUXHUB 3.0",
    LoadingSubtitle = "Advanced Core",
    ConfigurationSaving = { Enabled = false },
    KeySystem = false
})

-- // СЕРВИСЫ
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local Camera = Workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

-- // ГЛОБАЛЬНЫЕ НАСТРОЙКИ
local Settings = {
    Aim = { Enabled = false, Part = "Head", FOV = 150 },
    Hitbox = { Enabled = false, Size = 5, Transparency = 0.6 },
    ESP = { Enabled = false, ShowNames = false, ShowDistance = false, Chams = false },
    Movement = { SpeedEnabled = false, Speed = 16, JumpEnabled = false, JumpPower = 50, InfJump = false, Noclip = false },
    HvH = { Spinbot = false, SpinSpeed = 20 },
    Misc = { Fullbright = false }
}

local CurrentTarget = nil
local ESP_Folder = Instance.new("Folder", game.CoreGui)
ESP_Folder.Name = "FluxHub_ESP"

-- // ПОИСК ЦЕЛИ ДЛЯ АИМА
local function GetTarget()
    local target = nil
    local shortestDist = Settings.Aim.FOV

    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("Humanoid") and player.Character.Humanoid.Health > 0 then
            local targetPart = player.Character:FindFirstChild(Settings.Aim.Part)
            if targetPart then
                local pos, onScreen = Camera:WorldToViewportPoint(targetPart.Position)
                if onScreen then
                    local dist = (Vector2.new(pos.X, pos.Y) - UserInputService:GetMouseLocation()).Magnitude
                    if dist < shortestDist then
                        shortestDist = dist
                        target = targetPart
                    end
                end
            end
        end
    end
    return target
end

RunService.RenderStepped:Connect(function()
    if Settings.Aim.Enabled then CurrentTarget = GetTarget() else CurrentTarget = nil end
end)

-- // АНТИ-КРАШ ХУКИ (Silent Aim)
local oldNamecall
oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
    local method = getnamecallmethod()
    local args = {...}

    if Settings.Aim.Enabled and not checkcaller() and CurrentTarget then
        if method == "Raycast" then
            args[2] = (CurrentTarget.Position - args[1]).Unit * 1000
            return oldNamecall(self, unpack(args))
        elseif method == "FindPartOnRayWithIgnoreList" or method == "FindPartOnRay" then
            args[1] = Ray.new(Camera.CFrame.Position, (CurrentTarget.Position - Camera.CFrame.Position).Unit * 1000)
            return oldNamecall(self, unpack(args))
        end
    end
    return oldNamecall(self, ...)
end)

local oldIndex
oldIndex = hookmetamethod(game, "__index", function(self, key)
    if Settings.Aim.Enabled and not checkcaller() and key == "Hit" and self == Mouse and CurrentTarget then
        return CFrame.new(CurrentTarget.Position)
    end
    return oldIndex(self, key)
end)

-- // СОЗДАНИЕ ESP
local function CreateESP(player)
    if player == LocalPlayer then return end
    
    local char = player.Character
    if not char then return end

    -- Chams (Обводка сквозь стены)
    if Settings.ESP.Chams and not char:FindFirstChild("FluxChams") then
        local highlight = Instance.new("Highlight")
        highlight.Name = "FluxChams"
        highlight.Parent = char
        highlight.FillColor = Color3.fromRGB(255, 0, 0)
        highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
        highlight.FillTransparency = 0.5
        highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    end

    -- Name/Distance Text
    if (Settings.ESP.ShowNames or Settings.ESP.ShowDistance) and char:FindFirstChild("HumanoidRootPart") and not char:FindFirstChild("FluxText") then
        local bg = Instance.new("BillboardGui")
        bg.Name = "FluxText"
        bg.Parent = char
        bg.AlwaysOnTop = true
        bg.Size = UDim2.new(0, 200, 0, 50)
        bg.StudsOffset = Vector3.new(0, 3, 0)
        
        local text = Instance.new("TextLabel")
        text.Parent = bg
        text.BackgroundTransparency = 1
        text.Size = UDim2.new(1, 0, 1, 0)
        text.Font = Enum.Font.GothamBold
        text.TextSize = 14
        text.TextColor3 = Color3.fromRGB(255, 255, 255)
        text.TextStrokeTransparency = 0
    end
end

local function UpdateESP()
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local char = player.Character
            
            if Settings.ESP.Enabled then
                CreateESP(player)
                
                if char:FindFirstChild("FluxText") then
                    local textLabel = char.FluxText.TextLabel
                    local dist = math.floor((Camera.CFrame.Position - char.HumanoidRootPart.Position).Magnitude)
                    
                    local str = ""
                    if Settings.ESP.ShowNames then str = str .. player.Name .. "\n" end
                    if Settings.ESP.ShowDistance then str = str .. "[" .. dist .. "m]" end
                    
                    textLabel.Text = str
                    char.FluxText.Enabled = (Settings.ESP.ShowNames or Settings.ESP.ShowDistance)
                end
                
                if char:FindFirstChild("FluxChams") then
                    char.FluxChams.Enabled = Settings.ESP.Chams
                end
            else
                if char:FindFirstChild("FluxText") then char.FluxText:Destroy() end
                if char:FindFirstChild("FluxChams") then char.FluxChams:Destroy() end
            end
        end
    end
end

RunService.RenderStepped:Connect(UpdateESP)

-- // ЛОГИКА HITBOX
RunService.Heartbeat:Connect(function()
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            local hrp = player.Character.HumanoidRootPart
            if Settings.Hitbox.Enabled then
                hrp.Size = Vector3.new(Settings.Hitbox.Size, Settings.Hitbox.Size, Settings.Hitbox.Size)
                hrp.Transparency = Settings.Hitbox.Transparency
                hrp.CanCollide = false
            else
                hrp.Size = Vector3.new(2, 2, 1)
                hrp.Transparency = 1
            end
        end
    end
end)

-- // NOCLIP ЛОГИКА
RunService.Stepped:Connect(function()
    if Settings.Movement.Noclip and LocalPlayer.Character then
        for _, part in pairs(LocalPlayer.Character:GetDescendants()) do
            if part:IsA("BasePart") and part.CanCollide then
                part.CanCollide = false
            end
        end
    end
end)

-- // ВКЛАДКИ UI
local CombatTab = Window:CreateTab("🎯 Combat", nil)
local HitboxTab = Window:CreateTab("🔪 Hitboxes", nil)
local VisualsTab = Window:CreateTab("👁️ Visuals (ESP)", nil)
local MovementTab = Window:CreateTab("🏃 Movement", nil)
local HvHTab = Window:CreateTab("💀 HvH", nil)
local MiscTab = Window:CreateTab("⚙️ Misc", nil)

-- // COMBAT
CombatTab:CreateToggle({ Name = "Silent Aim", Callback = function(v) Settings.Aim.Enabled = v end })
CombatTab:CreateDropdown({ Name = "Aim Part", Options = {"Head", "Torso", "HumanoidRootPart"}, CurrentOption = {"Head"}, Callback = function(v) Settings.Aim.Part = v[1] end })
CombatTab:CreateSlider({ Name = "FOV Radius", Range = {50, 500}, CurrentValue = 150, Callback = function(v) Settings.Aim.FOV = v end })

-- // HITBOXES
HitboxTab:CreateToggle({ Name = "Enable Hitbox Expander", Callback = function(v) Settings.Hitbox.Enabled = v end })
HitboxTab:CreateSlider({ Name = "Hitbox Size", Range = {2, 30}, CurrentValue = 5, Callback = function(v) Settings.Hitbox.Size = v end })
HitboxTab:CreateSlider({ Name = "Hitbox Transparency", Range = {0, 100}, CurrentValue = 60, Callback = function(v) Settings.Hitbox.Transparency = v / 100 end })

-- // VISUALS (ESP)
VisualsTab:CreateToggle({ Name = "Enable Master ESP", Callback = function(v) Settings.ESP.Enabled = v end })
VisualsTab:CreateToggle({ Name = "Show Names", Callback = function(v) Settings.ESP.ShowNames = v end })
VisualsTab:CreateToggle({ Name = "Show Distance", Callback = function(v) Settings.ESP.ShowDistance = v end })
VisualsTab:CreateToggle({ Name = "Chams (Wallhack)", Callback = function(v) Settings.ESP.Chams = v end })

-- // MOVEMENT
MovementTab:CreateToggle({ Name = "Enable WalkSpeed", Callback = function(v) Settings.Movement.SpeedEnabled = v 
    if not v and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then LocalPlayer.Character.Humanoid.WalkSpeed = 16 end 
end })
MovementTab:CreateSlider({ Name = "WalkSpeed", Range = {16, 150}, CurrentValue = 16, Callback = function(v) Settings.Movement.Speed = v end })

MovementTab:CreateToggle({ Name = "Enable JumpPower", Callback = function(v) Settings.Movement.JumpEnabled = v 
    if not v and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then LocalPlayer.Character.Humanoid.JumpPower = 50 end 
end })
MovementTab:CreateSlider({ Name = "JumpPower", Range = {50, 250}, CurrentValue = 50, Callback = function(v) Settings.Movement.JumpPower = v end })

MovementTab:CreateToggle({ Name = "Infinite Jump", Callback = function(v) Settings.Movement.InfJump = v end })
MovementTab:CreateToggle({ Name = "Noclip (Walk through walls)", Callback = function(v) Settings.Movement.Noclip = v end })

UserInputService.JumpRequest:Connect(function()
    if Settings.Movement.InfJump and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
        LocalPlayer.Character.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
    end
end)

RunService.Heartbeat:Connect(function()
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
        if Settings.Movement.SpeedEnabled then LocalPlayer.Character.Humanoid.WalkSpeed = Settings.Movement.Speed end
        if Settings.Movement.JumpEnabled then LocalPlayer.Character.Humanoid.JumpPower = Settings.Movement.JumpPower end
    end
end)

-- // HvH
HvHTab:CreateToggle({ Name = "Spinbot", Callback = function(v) Settings.HvH.Spinbot = v end })
HvHTab:CreateSlider({ Name = "Spin Speed", Range = {1, 100}, CurrentValue = 20, Callback = function(v) Settings.HvH.SpinSpeed = v end })

RunService.RenderStepped:Connect(function()
    if Settings.HvH.Spinbot and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        LocalPlayer.Character.HumanoidRootPart.CFrame = LocalPlayer.Character.HumanoidRootPart.CFrame * CFrame.Angles(0, math.rad(Settings.HvH.SpinSpeed), 0)
    end
end)

-- // MISC
MiscTab:CreateToggle({ Name = "Fullbright (No Shadows)", Callback = function(v) 
    Settings.Misc.Fullbright = v 
    if v then
        Lighting.Ambient = Color3.new(1, 1, 1)
        Lighting.ColorShift_Bottom = Color3.new(1, 1, 1)
        Lighting.ColorShift_Top = Color3.new(1, 1, 1)
    else
        Lighting.Ambient = Color3.fromRGB(127, 127, 127) -- default
    end
end })

Rayfield:LoadConfiguration()
