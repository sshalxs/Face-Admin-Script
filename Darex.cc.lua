-- // Darex.cc | BloxStrike
-- // EDUCATIONAL PURPOSE ONLY
-- // DISCLAIMER: For Lua learning and research only. Not for actual use.
-- // Оптимизировано для Delta (мобильный экзекьютор)

-- ============================================================
-- // ЗАГРУЗКА RAYFIELD
-- ============================================================
local Rayfield = loadstring(game:HttpGet("https://raw.githubusercontent.com/twistedk1d/BloxStrike/refs/heads/main/Source/UI/source.lua"))()

-- ============================================================
-- // ГЛАВНОЕ ОКНО (Darex.cc)
-- ============================================================
local Window = Rayfield:CreateWindow({
    Name = "Darex.cc",
    Icon = 0,
    LoadingTitle = "loading Darex.cc (Blox Strike)",
    LoadingSubtitle = "by FeVilAi",
    ShowText = "Menu",
    Theme = "Amethyst",
    ToggleUIKeybind = Enum.KeyCode.RightShift,
    DisableRayfieldPrompts = false,
    DisableBuildWarnings = false,
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "Darex.cc",
        FileName = "Darex.cc"
    }
})

-- ============================================================
-- // SERVICES & GLOBALS
-- ============================================================
local RS = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local CAS = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")
local player = Players.LocalPlayer
local camera = Workspace.CurrentCamera
local CharactersFolder = Workspace:WaitForChild("Characters", 10)
local VirtualInputManager = game:GetService("VirtualInputManager")

-- ============================================================
-- // TABS
-- ============================================================
local Tab_Combat = Window:CreateTab("Combat", "crosshair")
local Tab_Skins = Window:CreateTab("Skins", "swords")
local Tab_Visuals = Window:CreateTab("Visuals", "eye")
local Tab_HVH = Window:CreateTab("HVH", "skull")

Tab_Skins:CreateLabel("Skin Changer by twistedk1d (adapted for Darex.cc)", "code", Color3.fromRGB(80,80,80), false)

-- ============================================================
-- // SHARED LOGIC (TEAM CHECK)
-- ============================================================
local function getTFolder()
    return CharactersFolder:FindFirstChild("Terrorists")
end

local function getCTFolder()
    return CharactersFolder:FindFirstChild("Counter-Terrorists")
end

local function isAlive()
    local t, ct = getTFolder(), getCTFolder()
    return (t and t:FindFirstChild(player.Name)) or (ct and ct:FindFirstChild(player.Name))
end

local function getEnemyFolder()
    if not isAlive() then return nil end
    local t, ct = getTFolder(), getCTFolder()
    if t and t:FindFirstChild(player.Name) then
        return ct
    end
    if ct and ct:FindFirstChild(player.Name) then
        return t
    end
    return nil
end

-- ============================================================
-- // AIMBOT & FOV LOGIC
-- ============================================================
local AimbotEnabled = false
local ShowFOV = false
local FOV_Radius = 100
local Smoothing = 3
local AimKey = Enum.UserInputType.MouseButton2
local isAiming = false

local FOVCircle = Drawing.new("Circle")
FOVCircle.Position = Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y / 2)
FOVCircle.Radius = FOV_Radius
FOVCircle.Filled = false
FOVCircle.Color = Color3.fromRGB(255, 255, 255)
FOVCircle.Visible = false
FOVCircle.Thickness = 1

local function getClosestEnemyToMouse()
    local closestEnemy = nil
    local shortestDistance = FOV_Radius
    local enemyFolder = getEnemyFolder()
    if not enemyFolder or not AimbotEnabled then return nil end
    local mousePos = UserInputService:GetMouseLocation()
    for _, enemy in ipairs(enemyFolder:GetChildren()) do
        local hum = enemy:FindFirstChildOfClass("Humanoid")
        local head = enemy:FindFirstChild("Head")
        if hum and hum.Health > 0 and head then
            local headPos, onScreen = camera:WorldToViewportPoint(head.Position)
            if onScreen then
                local distance = (Vector2.new(headPos.X, headPos.Y) - mousePos).Magnitude
                if distance < shortestDistance then
                    shortestDistance = distance
                    closestEnemy = head
                end
            end
        end
    end
    return closestEnemy
end

UserInputService.InputBegan:Connect(function(input)
    if input.UserInputType == AimKey then
        isAiming = true
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == AimKey then
        isAiming = false
    end
end)

RunService.RenderStepped:Connect(function()
    if ShowFOV then
        FOVCircle.Position = UserInputService:GetMouseLocation()
        FOVCircle.Radius = FOV_Radius
        FOVCircle.Visible = true
    else
        FOVCircle.Visible = false
    end

    if not isAiming or not isAlive() or not AimbotEnabled then return end

    local targetHead = getClosestEnemyToMouse()
    if targetHead then
        local headPos = camera:WorldToViewportPoint(targetHead.Position)
        local mousePos = UserInputService:GetMouseLocation()
        local moveX = (headPos.X - mousePos.X) / Smoothing
        local moveY = (headPos.Y - mousePos.Y) / Smoothing
        if mousemoverel then
            mousemoverel(moveX, moveY)
        end
    end
end)

Tab_Combat:CreateSection("Aimbot Settings")
Tab_Combat:CreateToggle({
    Name = "Enable Aimbot (Hold Right Click)",
    CurrentValue = false,
    Flag = "AimbotToggle",
    Callback = function(Value)
        AimbotEnabled = Value
    end
})

Tab_Combat:CreateToggle({
    Name = "Show FOV Circle",
    CurrentValue = false,
    Flag = "FOVToggle",
    Callback = function(Value)
        ShowFOV = Value
    end
})

Tab_Combat:CreateSlider({
    Name = "FOV Radius",
    Range = {10, 500},
    Increment = 10,
    Suffix = "px",
    CurrentValue = 100,
    Flag = "FOVSlider",
    Callback = function(Value)
        FOV_Radius = Value
    end
})

Tab_Combat:CreateSlider({
    Name = "Aimbot Smoothing",
    Range = {1, 10},
    Increment = 1,
    Suffix = " (Lower is faster)",
    CurrentValue = 3,
    Flag = "AimbotSmoothing",
    Callback = function(Value)
        Smoothing = Value
    end
})

-- ============================================================
-- // TRIGGERBOT LOGIC
-- ============================================================
local TriggerBotEnabled = false
local TriggerBotDelay = 0

Tab_Combat:CreateSection("TriggerBot Settings")
Tab_Combat:CreateToggle({
    Name = "Enable TriggerBot",
    CurrentValue = false,
    Flag = "TriggerBotToggle",
    Callback = function(Value)
        TriggerBotEnabled = Value
    end
})

Tab_Combat:CreateSlider({
    Name = "Shot Delay",
    Range = {0, 500},
    Increment = 10,
    Suffix = "ms",
    CurrentValue = 0,
    Flag = "TriggerBotDelay",
    Callback = function(Value)
        TriggerBotDelay = Value
    end
})

task.spawn(function()
    while task.wait(0.01) do
        if TriggerBotEnabled and isAlive() then
            local viewportSize = camera.ViewportSize
            local ray = camera:ViewportPointToRay(viewportSize.X / 2, viewportSize.Y / 2)
            local raycastParams = RaycastParams.new()
            raycastParams.FilterType = Enum.RaycastFilterType.Exclude
            local ignoreList = {camera}
            if player.Character then
                table.insert(ignoreList, player.Character)
            end
            raycastParams.FilterDescendantsInstances = ignoreList
            local result = Workspace:Raycast(ray.Origin, ray.Direction * 1000, raycastParams)
            if result and result.Instance then
                local hitPart = result.Instance
                local model = hitPart:FindFirstAncestorOfClass("Model")
                if model and model:FindFirstChildOfClass("Humanoid") then
                    local enemyFolder = getEnemyFolder()
                    if enemyFolder and model.Parent == enemyFolder then
                        local hum = model:FindFirstChildOfClass("Humanoid")
                        if hum and hum.Health > 0 then
                            if TriggerBotDelay > 0 then
                                task.wait(TriggerBotDelay / 1000)
                            end
                            if mouse1click then
                                mouse1click()
                            end
                            task.wait(0.05)
                        end
                    end
                end
            end
        end
    end
end)

-- ============================================================
-- // SIMPLE HITBOX LOGIC
-- ============================================================
local HitboxEnabled = false
local HitboxSize = 3
local originalHeadSizes = {}

Tab_Combat:CreateSection("Simple Hitbox (Max 3)")
Tab_Combat:CreateToggle({
    Name = "Enable Hitbox",
    CurrentValue = false,
    Flag = "HitboxToggle",
    Callback = function(Value)
        HitboxEnabled = Value
    end
})

Tab_Combat:CreateSlider({
    Name = "Hitbox Size",
    Range = {1, 3},
    Increment = 0.1,
    Suffix = " Studs",
    CurrentValue = 3,
    Flag = "HitboxSize",
    Callback = function(Value)
        HitboxSize = Value
    end
})

task.spawn(function()
    while task.wait(0.5) do
        local enemyFolder = getEnemyFolder()
        if enemyFolder then
            for _, enemy in ipairs(enemyFolder:GetChildren()) do
                local head = enemy:FindFirstChild("Head")
                local hum = enemy:FindFirstChildOfClass("Humanoid")
                if head and hum and hum.Health > 0 then
                    if not originalHeadSizes[head] then
                        originalHeadSizes[head] = head.Size
                    end
                    if HitboxEnabled then
                        head.Size = Vector3.new(HitboxSize, HitboxSize, HitboxSize)
                        head.CanCollide = false
                        head.Transparency = 0.5
                    else
                        if originalHeadSizes[head] and head.Size ~= originalHeadSizes[head] then
                            head.Size = originalHeadSizes[head]
                            head.Transparency = 0
                        end
                    end
                end
            end
        end
    end
end)

-- ============================================================
-- // BHOP (BUNNY HOP) LOGIC
-- ============================================================
local BhopEnabled = false

Tab_Combat:CreateSection("Movement Settings")
Tab_Combat:CreateToggle({
    Name = "Enable Bunny Hop (Hold Space)",
    CurrentValue = false,
    Flag = "BhopToggle",
    Callback = function(Value)
        BhopEnabled = Value
    end
})

RunService.RenderStepped:Connect(function()
    if BhopEnabled and UserInputService:IsKeyDown(Enum.KeyCode.Space) and isAlive() then
        if player.Character then
            local hum = player.Character:FindFirstChildOfClass("Humanoid")
            if hum and hum:GetState() ~= Enum.HumanoidStateType.Jumping and hum:GetState() ~= Enum.HumanoidStateType.Freefall then
                hum.Jump = true
            end
        end
    end
end)

-- ============================================================
-- // SKINS TAB LOGIC
-- ============================================================
local scriptRunning = false
local selectedKnife = "Butterfly Knife"
local spawned = false
local inspecting = false
local swinging = false
local lastAttackTime = 0
local ATTACK_COOLDOWN = 1
local ACTION_INSPECT = "InspectKnifeAction"
local ACTION_ATTACK = "AttackKnifeAction"

pcall(function()
    RS.Assets.Weapons.Karambit.Camera.ViewmodelLight.Transparency = 1
end)

local knives = {
    ["Karambit"] = {Offset = CFrame.new(0, -1.5, 1.5)},
    ["Butterfly Knife"] = {Offset = CFrame.new(0, -1.5, 1.5)},
    ["M9 Bayonet"] = {Offset = CFrame.new(0, -1.5, 1)},
    ["Flip Knife"] = {Offset = CFrame.new(0, -1.5, 1.25)},
    ["Gut Knife"] = {Offset = CFrame.new(0, -1.5, 0.5)},
}

local vm, animator
local equipAnim, idleAnim, inspectAnim, HeavySwingAnim, Swing1Anim, Swing2Anim

local function getKnifeInCamera()
    return camera:FindFirstChild("T Knife") or camera:FindFirstChild("CT Knife")
end

local function cleanPart(part)
    if not part:IsA("BasePart") then return end
    part.CanCollide = false
    part.Anchored = false
    part.CastShadow = false
    part.CanTouch = false
    part.CanQuery = false
end

local function disableCollisions(model)
    for _, part in model:GetDescendants() do
        cleanPart(part)
    end
end

local function hideOriginalKnife(knife)
    for _, part in knife:GetDescendants() do
        if part:IsA("BasePart") or part:IsA("MeshPart") or part:IsA("Texture") then
            part.Transparency = 1
        end
    end
end

local function playSound(folder, name)
    local weaponSounds = RS.Sounds:FindFirstChild(selectedKnife)
    if not weaponSounds then return end
    local sound = weaponSounds:WaitForChild(folder):WaitForChild(name):Clone()
    sound.Parent = camera
    sound:Play()
    sound.Ended:Once(function()
        sound:Destroy()
    end)
    return sound
end

local function attachAsset(folder, armPartName, assetModelName, finalName, offset)
    local targetArm = vm:FindFirstChild(armPartName)
    if not targetArm then return end
    local assetMesh = folder:WaitForChild(assetModelName):Clone()
    cleanPart(assetMesh)
    assetMesh.Name = finalName
    assetMesh.Parent = targetArm
    local motor = Instance.new("Motor6D")
    motor.Part0 = targetArm
    motor.Part1 = assetMesh
    motor.C0 = offset
    motor.Parent = targetArm
end

local function handleAction(actionName, inputState, inputObject)
    if inputState ~= Enum.UserInputState.Begin or not spawned or not animator or not isAlive() then
        return Enum.ContextActionResult.Pass
    end

    if actionName == ACTION_INSPECT then
        if (equipAnim and equipAnim.IsPlaying) or inspecting or swinging then
            return Enum.ContextActionResult.Pass
        end
        inspecting = true
        if idleAnim then idleAnim:Stop() end
        inspectAnim:Play()
        inspectAnim.Stopped:Once(function()
            inspecting = false
        end)
    elseif actionName == ACTION_ATTACK then
        local currentTime = os.clock()
        if (equipAnim and equipAnim.IsPlaying) or (currentTime - lastAttackTime < ATTACK_COOLDOWN) then
            return Enum.ContextActionResult.Pass
        end
        lastAttackTime = currentTime
        if inspecting then
            inspecting = false
            if inspectAnim then inspectAnim:Stop() end
        end
        swinging = true
        if idleAnim then idleAnim:Stop() end
        local anims = {HeavySwingAnim, Swing1Anim, Swing2Anim}
        local chosenAnim = anims[math.random(1, #anims)]
        local soundFolder = (chosenAnim == HeavySwingAnim and "HitOne") or (chosenAnim == Swing1Anim and "HitTwo") or "HitThree"
        chosenAnim:Play()
        local s = playSound(soundFolder, "1")
        if s then s.Volume = 5 end
        chosenAnim.Stopped:Once(function()
            swinging = false
        end)
    end
    return Enum.ContextActionResult.Pass
end

local function removeViewmodel()
    spawned = false
    CAS:UnbindAction(ACTION_INSPECT)
    CAS:UnbindAction(ACTION_ATTACK)
    if vm then
        vm:Destroy()
        vm = nil
    end
    animator = nil
    inspecting = false
    swinging = false
end

local function spawnViewmodel()
    removeViewmodel()
    local knife = getKnifeInCamera()
    if not knife then return end

    spawned = true
    vm = Instance.new("Model")
    vm.Name = "Viewmodel"
    vm.Parent = camera

    local base = Instance.new("Part")
    base.Name = "Base"
    base.Size = Vector3.new(1, 1, 1)
    base.Transparency = 1
    base.Anchored = true
    base.CanCollide = false
    base.Parent = vm

    local knifeData = knives[selectedKnife]
    if not knifeData then return end

    local knifeFolder = RS.Assets.Weapons:FindFirstChild(selectedKnife)
    if not knifeFolder then return end

    local knifeMesh = knifeFolder:WaitForChild(selectedKnife):Clone()
    knifeMesh.Name = "Knife"
    knifeMesh.Parent = vm
    disableCollisions(knifeMesh)

    local leftArm = Instance.new("Part")
    leftArm.Name = "Left Arm"
    leftArm.Size = Vector3.new(1, 1, 1)
    leftArm.Transparency = 1
    leftArm.Anchored = true
    leftArm.CanCollide = false
    leftArm.Parent = vm

    local rightArm = Instance.new("Part")
    rightArm.Name = "Right Arm"
    rightArm.Size = Vector3.new(1, 1, 1)
    rightArm.Transparency = 1
    rightArm.Anchored = true
    rightArm.CanCollide = false
    rightArm.Parent = vm

    local viewmodelOffset = CFrame.new(0, -1.5, 1.5)
    vm:SetPrimaryPartCFrame(camera.CFrame * viewmodelOffset)

    local animatorInst = Instance.new("Animator")
    animatorInst.Parent = vm

    local function loadAnim(animName)
        local anim = RS.Animations:FindFirstChild(animName)
        if anim then
            return animatorInst:LoadAnimation(anim)
        end
        return nil
    end

    equipAnim = loadAnim("Equip")
    idleAnim = loadAnim("Idle")
    inspectAnim = loadAnim("Inspect")
    HeavySwingAnim = loadAnim("HeavySwing")
    Swing1Anim = loadAnim("Swing1")
    Swing2Anim = loadAnim("Swing2")

    if equipAnim then
        equipAnim:Play()
        equipAnim.Stopped:Once(function()
            if idleAnim then
                idleAnim:Play()
            end
        end)
    end

    CAS:BindAction(ACTION_INSPECT, handleAction, false, Enum.KeyCode.Y)
    CAS:BindAction(ACTION_ATTACK, handleAction, false, Enum.KeyCode.MouseButton1)
end

Tab_Skins:CreateSection("Knife Selection")
Tab_Skins:CreateDropdown({
    Name = "Select Knife",
    Options = {"Karambit", "Butterfly Knife", "M9 Bayonet", "Flip Knife", "Gut Knife"},
    CurrentOption = "Butterfly Knife",
    Flag = "KnifeDropdown",
    Callback = function(Value)
        selectedKnife = Value
        if spawned then
            spawnViewmodel()
        end
    end
})

Tab_Skins:CreateButton({
    Name = "Spawn Viewmodel",
    Callback = function()
        spawnViewmodel()
    end
})

Tab_Skins:CreateButton({
    Name = "Remove Viewmodel",
    Callback = function()
        removeViewmodel()
    end
})

-- ============================================================
-- // VISUALS TAB (ESP)
-- ============================================================
local ESPEnabled = false
local ESPObjects = {}

local function createESP(plr)
    if not plr or not plr.Character then return end
    local char = plr.Character
    local head = char:FindFirstChild("Head")
    if not head then return end

    local color = Color3.fromRGB(255, 0, 0)
    local enemyFolder = getEnemyFolder()
    if enemyFolder and char.Parent == enemyFolder then
        color = Color3.fromRGB(255, 0, 0) -- враг
    else
        color = Color3.fromRGB(0, 255, 0) -- союзник
    end

    local box = Instance.new("BoxHandleAdornment")
    box.Size = Vector3.new(3, 5, 3)
    box.Color3 = color
    box.Transparency = 0.3
    box.ZIndex = 0
    box.AlwaysOnTop = true
    box.Parent = head

    local highlight = Instance.new("Highlight")
    highlight.Adornee = char
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.FillColor = color
    highlight.FillTransparency = 0.5
    highlight.OutlineColor = color
    highlight.OutlineTransparency = 0.3
    highlight.Parent = char

    table.insert(ESPObjects, {box = box, highlight = highlight, target = head, plr = plr})
end

local function clearESP()
    for _, obj in pairs(ESPObjects) do
        pcall(function()
            if obj.box then obj.box:Destroy() end
            if obj.highlight then obj.highlight:Destroy() end
        end)
    end
    ESPObjects = {}
end

local function updateESP()
    clearESP()
    if not ESPEnabled then return end
    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= player and plr.Character then
            createESP(plr)
        end
    end
end

Tab_Visuals:CreateSection("ESP Settings")
Tab_Visuals:CreateToggle({
    Name = "Enable ESP",
    CurrentValue = false,
    Flag = "ESPToggle",
    Callback = function(Value)
        ESPEnabled = Value
        if Value then
            updateESP()
            task.spawn(function()
                while ESPEnabled do
                    task.wait(0.5)
                    updateESP()
                end
            end)
        else
            clearESP()
        end
    end
})

Tab_Visuals:CreateButton({
    Name = "Refresh ESP",
    Callback = function()
        updateESP()
    end
})

-- ============================================================
-- // HVH TAB (Anti-Aim, Third Person, Model Changer)
-- ============================================================
local AntiAimEnabled = false
local AntiAimSpeed = 10
local AntiAimDirection = "Right"
local ThirdPersonEnabled = false
local ThirdPersonDistance = 10
local ThirdPersonHeight = 2
local ModelChangerEnabled = false
local SelectedModel = "Default"
local currentModel = nil

-- Anti-Aim
Tab_HVH:CreateSection("Anti-Aim Settings")
Tab_HVH:CreateToggle({
    Name = "Enable Anti-Aim (Spin)",
    CurrentValue = false,
    Flag = "AntiAimToggle",
    Callback = function(Value)
        AntiAimEnabled = Value
        task.spawn(function()
            while AntiAimEnabled do
                task.wait(0.016)
                local char = player.Character
                if char and char:FindFirstChild("HumanoidRootPart") then
                    local angle = AntiAimSpeed
                    if AntiAimDirection == "Left" then angle = -angle end
                    if AntiAimDirection == "Random" then
                        angle = (math.random() > 0.5 and 1 or -1) * angle
                    end
                    char.HumanoidRootPart.CFrame = char.HumanoidRootPart.CFrame * CFrame.Angles(0, math.rad(angle), 0)
                end
            end
        end)
    end
})

Tab_HVH:CreateSlider({
    Name = "Anti-Aim Speed",
    Range = {1, 30},
    Increment = 1,
    Suffix = " deg/frame",
    CurrentValue = 10,
    Flag = "AntiAimSpeed",
    Callback = function(Value)
        AntiAimSpeed = Value
    end
})

Tab_HVH:CreateDropdown({
    Name = "Anti-Aim Direction",
    Options = {"Right", "Left", "Random"},
    CurrentOption = "Right",
    Flag = "AntiAimDirection",
    Callback = function(Value)
        AntiAimDirection = Value
    end
})

-- Third Person
Tab_HVH:CreateSection("Third Person Settings")
Tab_HVH:CreateToggle({
    Name = "Enable Third Person",
    CurrentValue = false,
    Flag = "ThirdPersonToggle",
    Callback = function(Value)
        ThirdPersonEnabled = Value
        if not Value then
            camera.CameraType = Enum.CameraType.Custom
        end
    end
})

Tab_HVH:CreateSlider({
    Name = "Camera Distance",
    Range = {5, 30},
    Increment = 0.5,
    Suffix = " studs",
    CurrentValue = 10,
    Flag = "ThirdPersonDistance",
    Callback = function(Value)
        ThirdPersonDistance = Value
    end
})

Tab_HVH:CreateSlider({
    Name = "Camera Height",
    Range = {0, 5},
    Increment = 0.5,
    Suffix = " studs",
    CurrentValue = 2,
    Flag = "ThirdPersonHeight",
    Callback = function(Value)
        ThirdPersonHeight = Value
    end
})

RunService.RenderStepped:Connect(function()
    if ThirdPersonEnabled then
        local char = player.Character
        if char then
            local root = char:FindFirstChild("HumanoidRootPart")
            if root then
                local lookVector = root.CFrame.LookVector
                local camPos = root.Position - lookVector * ThirdPersonDistance + Vector3.new(0, ThirdPersonHeight, 0)
                camera.CameraType = Enum.CameraType.Scriptable
                camera.CFrame = CFrame.new(camPos, root.Position + Vector3.new(0, 1, 0))
            end
        end
    end
end)

-- Model Changer (Tung tung tung sahur)
Tab_HVH:CreateSection("Model Changer")
Tab_HVH:CreateDropdown({
    Name = "Select Model",
    Options = {"Default", "Tung tung tung sahur", "Noob", "Blocky", "R6"},
    CurrentOption = "Default",
    Flag = "ModelChanger",
    Callback = function(Value)
        SelectedModel = Value
        local char = player.Character
        if not char then return end

        if currentModel then
            currentModel:Destroy()
            currentModel = nil
        end

        if Value == "Default" then return end

        local newModel = Instance.new("Model")
        newModel.Name = "DarexModel"
        local newPart = Instance.new("Part")
        newPart.Size = Vector3.new(2, 2, 2)
        newPart.Position = char.HumanoidRootPart.Position
        newPart.Anchored = true
        newPart.Parent = newModel
        newModel.Parent = Workspace

        if Value == "Tung tung tung sahur" then
            newPart.BrickColor = BrickColor.new("Bright red")
        elseif Value == "Noob" then
            newPart.BrickColor = BrickColor.new("Bright yellow")
        elseif Value == "Blocky" then
            newPart.BrickColor = BrickColor.new("Bright blue")
        elseif Value == "R6" then
            newPart.BrickColor = BrickColor.new("Bright green")
        end
        currentModel = newModel
    end
})

-- ============================================================
-- // INFO
-- ============================================================
print("✅ Darex.cc | BloxStrike loaded successfully!")
print("🔥 Functions: Aimbot, Triggerbot, Hitbox, Bhop, Skins, ESP, Anti-Aim, Third Person, Model Changer")