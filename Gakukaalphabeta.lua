-- gakuka FTAP - RAGALIC STYLE v3.1 (ИСПРАВЛЕННЫЙ)
-- Меню с вкладками: Grab, Defense, Player, Misc
-- Anti-Kick из Ragalic (спавн сюрикена)
-- Third Person View
-- Все функции работают, кнопки обновляются

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local Debris = game:GetService("Debris")
local UserInputService = game:GetService("UserInputService")
local SoundService = game:GetService("SoundService")
local player = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

if not player then return end

local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local rootPart = character:WaitForChild("HumanoidRootPart")

-- ===== СОСТОЯНИЯ =====
local flingActive = false
local antiGrabActive = false
local speedModeActive = false
local anchorGrabActive = false
local antiKickActive = true
local kickNotifierActive = true
local superThrowActive = false
local jerkOffActive = false
local thirdPersonActive = false
local frozenObjects = {}
local screenGui = nil
local mainFrame = nil
local currentTab = "Grab"
local buttons = {}  -- таблица для кнопок текущей вкладки
local statusText = nil

-- ========================================
-- === ФУНКЦИЯ ОБНОВЛЕНИЯ КНОПОК ===
-- ========================================
local function updateButtons()
    for key, btn in pairs(buttons) do
        if btn and btn.Parent then
            if key == "fling" then
                btn.Text = "💥 FLING GRAB " .. (flingActive and "[ВКЛ]" or "[ВЫКЛ]")
                btn.BackgroundColor3 = flingActive and Color3.fromRGB(0, 200, 50) or Color3.fromRGB(180, 40, 40)
            elseif key == "antiGrab" then
                btn.Text = "🛡️ ANTI-GRAB " .. (antiGrabActive and "[ВКЛ]" or "[ВЫКЛ]")
                btn.BackgroundColor3 = antiGrabActive and Color3.fromRGB(0, 180, 0) or Color3.fromRGB(180, 40, 40)
            elseif key == "speed" then
                btn.Text = "🏃 ROBLOX EGOR " .. (speedModeActive and "[ВКЛ]" or "[ВЫКЛ]")
                btn.BackgroundColor3 = speedModeActive and Color3.fromRGB(0, 200, 100) or Color3.fromRGB(180, 40, 40)
            elseif key == "anchor" then
                btn.Text = "⚓ ANCHOR GRAB " .. (anchorGrabActive and "[ВКЛ]" or "[ВЫКЛ]")
                btn.BackgroundColor3 = anchorGrabActive and Color3.fromRGB(0, 180, 255) or Color3.fromRGB(180, 40, 40)
            elseif key == "antiKick" then
                btn.Text = "🔮 ANTI-KICK " .. (antiKickActive and "[ВКЛ]" or "[ВЫКЛ]")
                btn.BackgroundColor3 = antiKickActive and Color3.fromRGB(0, 180, 0) or Color3.fromRGB(180, 40, 40)
            elseif key == "notifier" then
                btn.Text = "🔔 УВЕДОМЛЕНИЯ " .. (kickNotifierActive and "[ВКЛ]" or "[ВЫКЛ]")
                btn.BackgroundColor3 = kickNotifierActive and Color3.fromRGB(0, 180, 0) or Color3.fromRGB(180, 40, 40)
            elseif key == "super" then
                btn.Text = "⚡ SUPER THROW " .. (superThrowActive and "[ВКЛ]" or "[ВЫКЛ]")
                btn.BackgroundColor3 = superThrowActive and Color3.fromRGB(0, 180, 255) or Color3.fromRGB(180, 40, 40)
            elseif key == "jerk" then
                btn.Text = "🔞 JERK OFF " .. (jerkOffActive and "[ВКЛ]" or "[ВЫКЛ]")
                btn.BackgroundColor3 = jerkOffActive and Color3.fromRGB(200, 50, 200) or Color3.fromRGB(180, 40, 40)
            elseif key == "thirdPerson" then
                btn.Text = "👁️ 3RD PERSON " .. (thirdPersonActive and "[ВКЛ]" or "[ВЫКЛ]")
                btn.BackgroundColor3 = thirdPersonActive and Color3.fromRGB(0, 200, 255) or Color3.fromRGB(180, 40, 40)
            end
        end
    end
    if statusText then
        local parts = {}
        if kickNotifierActive then table.insert(parts, "🔔 Уведомления ВКЛ") else table.insert(parts, "🔕 Уведомления ВЫКЛ") end
        if antiKickActive then table.insert(parts, "| 🛡️ Anti-Kick ВКЛ") else table.insert(parts, "| 🛡️ Anti-Kick ВЫКЛ") end
        if anchorGrabActive then table.insert(parts, "| ⚓ Заморозка ВКЛ") end
        if superThrowActive then table.insert(parts, "| ⚡ Super Throw ВКЛ") end
        if jerkOffActive then table.insert(parts, "| 🔞 Jerk Off ВКЛ") end
        if thirdPersonActive then table.insert(parts, "| 👁️ 3-е лицо ВКЛ") end
        statusText.Text = table.concat(parts, " ")
    end
end

-- ========================================
-- === ANTI-GRAB (БЕЗ БЛОКИРОВКИ) ===
-- ========================================
local antiGrabConnection = nil

local function startAntiGrab()
    if antiGrabConnection then return end
    antiGrabConnection = RunService.Heartbeat:Connect(function()
        if not antiGrabActive then return end
        if not character or not character.Parent then return end
        local head = character:FindFirstChild("Head")
        if head then
            local partOwner = head:FindFirstChild("PartOwner")
            if partOwner then
                pcall(function()
                    local struggle = ReplicatedStorage:FindFirstChild("CharacterEvents")
                    if struggle then
                        local struggleEvent = struggle:FindFirstChild("Struggle")
                        if struggleEvent then struggleEvent:FireServer() end
                    end
                    local correction = ReplicatedStorage:FindFirstChild("GameCorrectionEvents")
                    if correction then
                        local stopVelocity = correction:FindFirstChild("StopAllVelocity")
                        if stopVelocity then stopVelocity:FireServer() end
                    end
                    if rootPart then
                        rootPart.Velocity = Vector3.new(0, 0, 0)
                        rootPart.RotVelocity = Vector3.new(0, 0, 0)
                    end
                    if humanoid then
                        humanoid:ChangeState(Enum.HumanoidStateType.Running)
                    end
                    partOwner:Destroy()
                end)
            end
        end
    end)
end

local function stopAntiGrab()
    if antiGrabConnection then
        antiGrabConnection:Disconnect()
        antiGrabConnection = nil
    end
end

-- ========================================
-- === ANTI-KICK ИЗ RAGALIC (ShurikenAntiKick) ===
-- ========================================
local antiKickConnection = nil
local antiKickShuriken = nil

local function clearAntiKickShuriken()
    local plr = player
    local inv = workspace:FindFirstChild(plr.Name .. "SpawnedInToys")
    local destroyrem = ReplicatedStorage:FindFirstChild("MenuToys") and ReplicatedStorage.MenuToys:FindFirstChild("DestroyToy")
    if inv and destroyrem then
        for _, v in pairs(inv:GetChildren()) do
            if v.Name == "AntiKick" or v.Name == "NinjaShuriken" then
                pcall(function()
                    destroyrem:FireServer(v)
                end)
            end
        end
    end
end

local function startAntiKick()
    if antiKickConnection then return end
    antiKickConnection = RunService.Heartbeat:Connect(function()
        if not antiKickActive then return end
        pcall(function()
            local plr = player
            local char = plr.Character
            if not char or not char:FindFirstChild("HumanoidRootPart") then return end
            local hrp = char.HumanoidRootPart
            local canSpawn = plr:FindFirstChild("CanSpawnToy")
            if not canSpawn or not canSpawn.Value then return end
            
            local inv = workspace:FindFirstChild(plr.Name .. "SpawnedInToys")
            local shuriken = inv and inv:FindFirstChild("NinjaShuriken")
            if not shuriken then
                local spawnRemote = ReplicatedStorage.MenuToys.SpawnToyRemoteFunction
                pcall(function()
                    spawnRemote:InvokeServer("NinjaShuriken", hrp.CFrame * CFrame.new(0, 12, 20), Vector3.new())
                end)
                task.wait(0.2)
                inv = workspace:FindFirstChild(plr.Name .. "SpawnedInToys")
                shuriken = inv and inv:FindFirstChild("NinjaShuriken")
                if shuriken then
                    shuriken.Name = "AntiKick"
                end
            end
            if shuriken and shuriken:FindFirstChild("StickyPart") then
                local stickyPart = shuriken.StickyPart
                if stickyPart.CanTouch then
                    local firePart = hrp:FindFirstChild("FirePlayerPart") or hrp:WaitForChild("FirePlayerPart", 5)
                    if firePart then
                        local stickyEvent = ReplicatedStorage:WaitForChild("PlayerEvents"):WaitForChild("StickyPartEvent")
                        stickyEvent:FireServer(stickyPart, firePart, CFrame.new(0,0,0) * CFrame.Angles(0, math.rad(90), math.rad(90)))
                    end
                    for _, obj in pairs(shuriken:GetChildren()) do
                        if obj:IsA("BasePart") then
                            obj.CanTouch = false
                            obj.CanCollide = false
                            obj.CanQuery = false
                            if obj.Name ~= "Pyramid" and obj.Name ~= "Main" then
                                obj.Transparency = 1
                            end
                        end
                    end
                end
            end
        end)
    end)
end

local function stopAntiKick()
    if antiKickConnection then
        antiKickConnection:Disconnect()
        antiKickConnection = nil
    end
    clearAntiKickShuriken()
end

-- ========================================
-- === ROBLOX EGOR ===
-- ========================================
local speedLoop = nil

local function setSpeed()
    if speedLoop then speedLoop:Disconnect() end
    speedLoop = RunService.Heartbeat:Connect(function()
        if not character or not character.Parent then return end
        if not humanoid then return end
        if speedModeActive then
            if humanoid.WalkSpeed ~= 70 then humanoid.WalkSpeed = 70 end
        else
            if humanoid.WalkSpeed ~= 16 then humanoid.WalkSpeed = 16 end
        end
        humanoid.AutoRotate = true
        humanoid.PlatformStand = false
    end)
end

local function stopSpeedControl()
    if speedLoop then speedLoop:Disconnect(); speedLoop = nil end
end

-- ========================================
-- === SUPER THROW ===
-- ========================================
local superThrowConnection = nil
local superThrowStrength = 1200

local function startSuperThrow()
    if superThrowConnection then return end
    superThrowConnection = Workspace.ChildAdded:Connect(function(child)
        if not superThrowActive then return end
        if child.Name ~= "GrabParts" then return end
        local grabPart = child:FindFirstChild("GrabPart")
        if not grabPart then return end
        local weld = grabPart:FindFirstChild("WeldConstraint")
        if not weld or not weld.Part1 then return end
        local part = weld.Part1
        if not part or not part:IsA("BasePart") then return end
        local bodyVel = Instance.new("BodyVelocity")
        bodyVel.MaxForce = Vector3.new(1e9, 1e9, 1e9)
        bodyVel.Velocity = Vector3.new(0, 0, 0)
        local connection
        connection = child:GetPropertyChangedSignal("Parent"):Connect(function()
            if child.Parent == nil then
                bodyVel.Velocity = Workspace.CurrentCamera.CFrame.LookVector * superThrowStrength
                bodyVel.Parent = part
                Debris:AddItem(bodyVel, 1)
                if connection then connection:Disconnect() end
            end
        end)
    end)
end

local function stopSuperThrow()
    if superThrowConnection then
        superThrowConnection:Disconnect()
        superThrowConnection = nil
    end
end

-- ========================================
-- === ANCHOR GRAB ===
-- ========================================
local function freezeObject(object)
    if not object or not object:IsA("BasePart") then return end
    if frozenObjects[object] then return end
    pcall(function()
        local props = {
            Anchored = object.Anchored,
            CanCollide = object.CanCollide,
            Locked = object.Locked,
            CustomPhysicalProperties = object.CustomPhysicalProperties,
            Transparency = object.Transparency,
            Material = object.Material,
            Color = object.Color
        }
        object.Anchored = true
        object.CanCollide = true
        object.Locked = true
        object.Velocity = Vector3.new(0, 0, 0)
        object.RotVelocity = Vector3.new(0, 0, 0)
        object.CustomPhysicalProperties = PhysicalProperties.new(0, 0, 0, 0, 0)
        object.Transparency = 0.2
        object.Material = Enum.Material.Ice
        object.Color = Color3.fromRGB(80, 180, 255)
        local glow = Instance.new("SelectionBox")
        glow.Adornee = object
        glow.Color3 = Color3.fromRGB(0, 150, 255)
        glow.Transparency = 0.3
        glow.LineThickness = 0.15
        glow.Parent = object
        frozenObjects[object] = {Properties = props, Glow = glow}
    end)
end

local function unfreezeObject(object)
    if not object or not frozenObjects[object] then return end
    pcall(function()
        local data = frozenObjects[object]
        local props = data.Properties
        object.Anchored = props.Anchored or false
        object.CanCollide = props.CanCollide or true
        object.Locked = props.Locked or false
        object.CustomPhysicalProperties = props.CustomPhysicalProperties or PhysicalProperties.new(0.7, 0.3, 0.5, 0.5, 0.5)
        object.Transparency = props.Transparency or 0
        object.Material = props.Material or Enum.Material.Plastic
        object.Color = props.Color or Color3.fromRGB(255, 255, 255)
        if data.Glow then data.Glow:Destroy() end
        frozenObjects[object] = nil
    end)
end

local function clearAllFrozen()
    for obj, _ in pairs(frozenObjects) do unfreezeObject(obj) end
    frozenObjects = {}
end

local anchorGrabConnection = nil

local function startAnchorGrab()
    if anchorGrabConnection then return end
    anchorGrabConnection = Workspace.ChildAdded:Connect(function(child)
        if not anchorGrabActive then return end
        if child.Name == "GrabParts" then
            task.wait(0.1)
            local grabPart = child:FindFirstChild("GrabPart")
            if grabPart then
                local weld = grabPart:FindFirstChild("WeldConstraint")
                if weld then
                    local part1 = weld.Part1
                    if part1 and part1:IsA("BasePart") then
                        freezeObject(part1)
                    end
                end
            end
        end
    end)
end

local function stopAnchorGrab()
    if anchorGrabConnection then
        anchorGrabConnection:Disconnect()
        anchorGrabConnection = nil
    end
    clearAllFrozen()
end

-- ========================================
-- === FLING GRAB ===
-- ========================================
local flingConn = nil

local function startFling()
    if flingActive then return end
    flingActive = true
    if flingConn then flingConn:Disconnect() end
    flingConn = RunService.Heartbeat:Connect(function()
        if not flingActive then return end
        if rootPart and rootPart.Velocity.Magnitude > 100 then
            rootPart.Velocity = Vector3.new(0, 0, 0)
            rootPart.RotVelocity = Vector3.new(0, 0, 0)
        end
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= player then
                local char = plr.Character
                if char and char:FindFirstChild("HumanoidRootPart") then
                    local root = char.HumanoidRootPart
                    root.Velocity = Vector3.new(
                        math.random(-500, 500),
                        math.random(100, 400),
                        math.random(-500, 500)
                    )
                end
            end
        end
    end)
end

local function stopFling()
    flingActive = false
    if flingConn then
        flingConn:Disconnect()
        flingConn = nil
    end
end

-- ========================================
-- === УВЕДОМЛЕНИЯ О КИКАХ (из Ragalic) ===
-- ========================================
local kickNotifierConnection = nil
local notifiedPlayers = {}

local function playKickSound()
    local s = Instance.new("Sound")
    s.SoundId = "rbxassetid://79150789336480"
    s.Volume = 5
    s.PlayOnRemove = true
    s.Parent = SoundService
    s:Destroy()
end

local function notifyKick(displayName, username)
    if statusText then
        statusText.Text = "⚠️ " .. displayName .. " был кикнут!"
        statusText.TextColor3 = Color3.fromRGB(255, 50, 50)
        task.wait(3)
        updateButtons()
    end
end

local function getClosestPlayer(pos)
    local closestPlr = nil
    local closestDist = math.huge
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= player and plr.Character then
            local hrp = plr.Character:FindFirstChild("HumanoidRootPart")
            if hrp then
                local dist = (hrp.Position - pos).Magnitude
                if dist < closestDist then
                    closestDist = dist
                    closestPlr = plr
                end
            end
        end
    end
    return closestPlr
end

local function startKickNotifier()
    if kickNotifierConnection then return end
    notifiedPlayers = {}

    kickNotifierConnection = Workspace.ChildAdded:Connect(function(obj)
        if not kickNotifierActive then return end
        if obj.Name == "BlackHoleKick" or obj.Name == "BlackHoleDetected" then
            task.wait(0.05)
            local pos
            if obj:IsA("BasePart") then
                pos = obj.Position
            elseif obj:IsA("Model") and obj.PrimaryPart then
                pos = obj.PrimaryPart.Position
            end
            if not pos then return end
            
            local plr = getClosestPlayer(pos)
            if not plr then return end
            
            playKickSound()
            notifyKick(plr.DisplayName, plr.Name)
        end
    end)
end

local function stopKickNotifier()
    if kickNotifierConnection then
        kickNotifierConnection:Disconnect()
        kickNotifierConnection = nil
    end
    notifiedPlayers = {}
end

-- ========================================
-- === JERK OFF ===
-- ========================================
local jerkOffTrack = nil

local function startJerkOff()
    if not character or not character.Parent then return end
    local hum = character:FindFirstChildOfClass("Humanoid")
    if not hum then return end
    
    local animator = hum:FindFirstChildOfClass("Animator")
    if not animator then
        animator = Instance.new("Animator")
        animator.Parent = hum
    end
    
    local anim = Instance.new("Animation")
    anim.AnimationId = "rbxassetid://168268306"
    
    jerkOffTrack = animator:LoadAnimation(anim)
    jerkOffTrack.Priority = Enum.AnimationPriority.Action
    jerkOffTrack:Play()
    
    task.spawn(function()
        while jerkOffActive do
            task.wait(0.1)
            if jerkOffTrack and jerkOffTrack.IsPlaying then
                jerkOffTrack.TimePosition = 0.3
            end
        end
    end)
end

local function stopJerkOff()
    if jerkOffTrack then
        jerkOffTrack:Stop()
        jerkOffTrack = nil
    end
end

-- ========================================
-- === THIRD PERSON VIEW (из Ragalic) ===
-- ========================================
local function enableThirdPerson()
    player.CameraMode = Enum.CameraMode.Classic
    Camera.CameraType = Enum.CameraType.Custom
    Camera.CameraSubject = character:FindFirstChild("Humanoid")
    player.CameraMaxZoomDistance = 1000
    player.CameraMinZoomDistance = 0.5
end

local function disableThirdPerson()
    player.CameraMode = Enum.CameraMode.LockFirstPerson
    Camera.CameraType = Enum.CameraType.Custom
    Camera.CameraSubject = character:FindFirstChild("Humanoid")
    player.CameraMaxZoomDistance = 0
    player.CameraMinZoomDistance = 0
end

local function toggleThirdPerson()
    thirdPersonActive = not thirdPersonActive
    if thirdPersonActive then
        enableThirdPerson()
    else
        disableThirdPerson()
    end
    updateButtons()
end

-- ========================================
-- === TOGGLE FUNCTIONS ===
-- ========================================
local function toggleSpeed()
    speedModeActive = not speedModeActive
    setSpeed()
    updateButtons()
end

local function toggleAntiGrab()
    antiGrabActive = not antiGrabActive
    if antiGrabActive then startAntiGrab() else stopAntiGrab() end
    updateButtons()
end

local function toggleAnchorGrab()
    anchorGrabActive = not anchorGrabActive
    if anchorGrabActive then startAnchorGrab() else stopAnchorGrab() end
    updateButtons()
end

local function toggleAntiKick()
    antiKickActive = not antiKickActive
    if antiKickActive then startAntiKick() else stopAntiKick() end
    updateButtons()
end

local function toggleFling()
    if flingActive then stopFling() else startFling() end
    updateButtons()
end

local function toggleNotifier()
    kickNotifierActive = not kickNotifierActive
    if kickNotifierActive then startKickNotifier() else stopKickNotifier() end
    updateButtons()
end

local function toggleSuperThrow()
    superThrowActive = not superThrowActive
    if superThrowActive then startSuperThrow() else stopSuperThrow() end
    updateButtons()
end

local function toggleJerkOff()
    jerkOffActive = not jerkOffActive
    if jerkOffActive then startJerkOff() else stopJerkOff() end
    updateButtons()
end

local function stopAll()
    stopFling()
    stopAntiGrab()
    stopSpeedControl()
    stopAntiKick()
    stopAnchorGrab()
    stopKickNotifier()
    stopSuperThrow()
    stopJerkOff()
    if thirdPersonActive then toggleThirdPerson() end
    speedModeActive = false
    anchorGrabActive = false
    superThrowActive = false
    jerkOffActive = false
    updateButtons()
    if statusText then
        statusText.Text = "⛔ ВСЁ ОСТАНОВЛЕНО"
        statusText.TextColor3 = Color3.fromRGB(255, 100, 100)
    end
end

-- ========================================
-- === GUI (СТИЛЬ RAGALIC) ===
-- ========================================
local function createGUI()
    if screenGui then screenGui:Destroy() end
    screenGui = Instance.new("ScreenGui")
    screenGui.Name = "gakukaGUI"
    screenGui.Parent = player:WaitForChild("PlayerGui")
    screenGui.ResetOnSpawn = false

    mainFrame = Instance.new("Frame")
    mainFrame.Size = UDim2.new(0, 420, 0, 380)
    mainFrame.Position = UDim2.new(0.5, -210, 0.5, -190)
    mainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 35)
    mainFrame.BackgroundTransparency = 0.1
    mainFrame.BorderSizePixel = 2
    mainFrame.BorderColor3 = Color3.fromRGB(80, 80, 180)
    mainFrame.Parent = screenGui
    mainFrame.Active = true
    mainFrame.Draggable = true

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 12)
    corner.Parent = mainFrame

    -- Заголовок
    local titleBar = Instance.new("Frame")
    titleBar.Size = UDim2.new(1, 0, 0, 45)
    titleBar.BackgroundColor3 = Color3.fromRGB(30, 30, 55)
    titleBar.BackgroundTransparency = 0.3
    titleBar.BorderSizePixel = 2
    titleBar.BorderColor3 = Color3.fromRGB(80, 80, 180)
    titleBar.Parent = mainFrame

    local titleCorner = Instance.new("UICorner")
    titleCorner.CornerRadius = UDim.new(0, 12)
    titleCorner.Parent = titleBar

    local titleText = Instance.new("TextLabel")
    titleText.Size = UDim2.new(1, -80, 1, 0)
    titleText.Position = UDim2.new(0, 12, 0, 0)
    titleText.BackgroundTransparency = 1
    titleText.Text = "💀 gakuka FTAP"
    titleText.TextColor3 = Color3.fromRGB(200, 50, 200)
    titleText.Font = Enum.Font.GothamBold
    titleText.TextSize = 20
    titleText.TextXAlignment = Enum.TextXAlignment.Left
    titleText.Parent = titleBar

    local verText = Instance.new("TextLabel")
    verText.Size = UDim2.new(1, -80, 0, 16)
    verText.Position = UDim2.new(0, 12, 0, 26)
    verText.BackgroundTransparency = 1
    verText.Text = "v3.1 | Ragalic Style | Anti-Kick"
    verText.TextColor3 = Color3.fromRGB(255, 200, 100)
    verText.Font = Enum.Font.Gotham
    verText.TextSize = 11
    verText.TextXAlignment = Enum.TextXAlignment.Left
    verText.Parent = titleBar

    -- Кнопка закрытия
    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.new(0, 30, 0, 30)
    closeBtn.Position = UDim2.new(1, -38, 0, 8)
    closeBtn.BackgroundColor3 = Color3.fromRGB(200, 0, 0)
    closeBtn.BackgroundTransparency = 0.2
    closeBtn.Text = "✕"
    closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.TextSize = 18
    closeBtn.BorderSizePixel = 1
    closeBtn.BorderColor3 = Color3.fromRGB(200, 0, 0)
    closeBtn.Parent = titleBar

    local closeCorner = Instance.new("UICorner")
    closeCorner.CornerRadius = UDim.new(0, 6)
    closeCorner.Parent = closeBtn

    closeBtn.MouseButton1Click:Connect(function()
        stopAll()
        if screenGui then screenGui:Destroy(); screenGui = nil end
    end)

    -- Статус
    statusText = Instance.new("TextLabel")
    statusText.Size = UDim2.new(0.92, 0, 0, 24)
    statusText.Position = UDim2.new(0.04, 0, 0.13, 0)
    statusText.BackgroundColor3 = Color3.fromRGB(35, 35, 60)
    statusText.BackgroundTransparency = 0.5
    statusText.Text = "🔔 Уведомления ВКЛ | 🛡️ Anti-Kick ВКЛ"
    statusText.TextColor3 = Color3.fromRGB(100, 200, 255)
    statusText.Font = Enum.Font.GothamSemibold
    statusText.TextSize = 12
    statusText.TextXAlignment = Enum.TextXAlignment.Center
    statusText.Parent = mainFrame

    local statusCorner = Instance.new("UICorner")
    statusCorner.CornerRadius = UDim.new(0, 6)
    statusCorner.Parent = statusText

    -- Вкладки
    local tabNames = {"Grab", "Defense", "Player", "Misc"}
    local tabButtons = {}
    local contentFrame = Instance.new("Frame")
    contentFrame.Size = UDim2.new(1, 0, 1, -85)
    contentFrame.Position = UDim2.new(0, 0, 0, 85)
    contentFrame.BackgroundTransparency = 1
    contentFrame.Parent = mainFrame

    local function createTab(name, y)
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(0.23, 0, 0, 28)
        btn.Position = UDim2.new(0.02 + (y-1)*0.24, 0, 0.16, 0)
        btn.BackgroundColor3 = (name == currentTab) and Color3.fromRGB(80, 80, 180) or Color3.fromRGB(40, 40, 60)
        btn.BackgroundTransparency = 0.2
        btn.Text = name
        btn.TextColor3 = Color3.fromRGB(255, 255, 255)
        btn.Font = Enum.Font.GothamBold
        btn.TextSize = 14
        btn.BorderSizePixel = 1
        btn.BorderColor3 = Color3.fromRGB(80, 80, 150)
        btn.Parent = mainFrame
        local c = Instance.new("UICorner")
        c.CornerRadius = UDim.new(0, 6)
        c.Parent = btn

        btn.MouseButton1Click:Connect(function()
            currentTab = name
            for _, b in pairs(tabButtons) do
                b.BackgroundColor3 = (b == btn) and Color3.fromRGB(80, 80, 180) or Color3.fromRGB(40, 40, 60)
            end
            updateTabContent(name)
        end)
        table.insert(tabButtons, btn)
        return btn
    end

    for i, name in ipairs(tabNames) do
        createTab(name, i)
    end

    -- Функция обновления контента вкладки
    local function updateTabContent(tab)
        -- Очищаем контейнер и сбрасываем таблицу кнопок
        contentFrame:ClearAllChildren()
        buttons = {}  -- очищаем старые ссылки

        local function createGroupBox(title, yPos)
            local frame = Instance.new("Frame")
            frame.Size = UDim2.new(0.46, 0, 0, 120)
            frame.Position = UDim2.new(0.02, 0, yPos, 0)
            frame.BackgroundColor3 = Color3.fromRGB(30, 30, 50)
            frame.BackgroundTransparency = 0.3
            frame.BorderSizePixel = 1
            frame.BorderColor3 = Color3.fromRGB(80, 80, 150)
            frame.Parent = contentFrame
            local c = Instance.new("UICorner")
            c.CornerRadius = UDim.new(0, 6)
            c.Parent = frame

            local label = Instance.new("TextLabel")
            label.Size = UDim2.new(1, 0, 0, 20)
            label.Position = UDim2.new(0, 5, 0, 0)
            label.BackgroundTransparency = 1
            label.Text = title
            label.TextColor3 = Color3.fromRGB(200, 200, 255)
            label.Font = Enum.Font.GothamBold
            label.TextSize = 13
            label.TextXAlignment = Enum.TextXAlignment.Left
            label.Parent = frame

            return frame, label
        end

        local function addButton(group, text, callback, key)
            local btn = Instance.new("TextButton")
            btn.Size = UDim2.new(0.9, 0, 0, 26)
            btn.Position = UDim2.new(0.05, 0, 0.25 + (#group:GetChildren() - 1) * 0.2, 0)
            btn.BackgroundColor3 = Color3.fromRGB(50, 50, 80)
            btn.BackgroundTransparency = 0.3
            btn.Text = text
            btn.TextColor3 = Color3.fromRGB(255, 255, 255)
            btn.Font = Enum.Font.GothamBold
            btn.TextSize = 13
            btn.BorderSizePixel = 1
            btn.BorderColor3 = Color3.fromRGB(80, 80, 150)
            btn.Parent = group
            local c = Instance.new("UICorner")
            c.CornerRadius = UDim.new(0, 6)
            c.Parent = btn

            btn.MouseButton1Click:Connect(callback)
            if key then buttons[key] = btn end
            return btn
        end

        if tab == "Grab" then
            local group1, _ = createGroupBox("Основные", 0.02)
            addButton(group1, "💥 FLING GRAB [ВЫКЛ]", function() toggleFling() end, "fling")
            addButton(group1, "⚓ ANCHOR GRAB [ВЫКЛ]", function() toggleAnchorGrab() end, "anchor")
            addButton(group1, "⚡ SUPER THROW [ВЫКЛ]", function() toggleSuperThrow() end, "super")
        elseif tab == "Defense" then
            local group1, _ = createGroupBox("Защита", 0.02)
            addButton(group1, "🛡️ ANTI-GRAB [ВЫКЛ]", function() toggleAntiGrab() end, "antiGrab")
            addButton(group1, "🔮 ANTI-KICK [ВКЛ]", function() toggleAntiKick() end, "antiKick")
            addButton(group1, "🔔 УВЕДОМЛЕНИЯ [ВКЛ]", function() toggleNotifier() end, "notifier")
        elseif tab == "Player" then
            local group1, _ = createGroupBox("Движение", 0.02)
            addButton(group1, "🏃 ROBLOX EGOR [ВЫКЛ]", function() toggleSpeed() end, "speed")
            addButton(group1, "👁️ 3RD PERSON [ВЫКЛ]", function() toggleThirdPerson() end, "thirdPerson")
        elseif tab == "Misc" then
            local group1, _ = createGroupBox("Общее", 0.02)
            addButton(group1, "🔞 JERK OFF [ВЫКЛ]", function() toggleJerkOff() end, "jerk")
            addButton(group1, "⛔ ОСТАНОВИТЬ ВСЁ", function() stopAll() end, "stop")
        end

        -- Принудительно обновляем все кнопки
        updateButtons()
    end

    updateTabContent("Grab")
    return screenGui
end

-- ========================================
-- === ПОСТОЯННЫЙ КОНТРОЛЬ ===
-- ========================================
local function tick()
    if not character or not character.Parent then return end
    if rootPart and rootPart.Velocity.Magnitude > 100 then
        rootPart.Velocity = Vector3.new(0, 0, 0)
        rootPart.RotVelocity = Vector3.new(0, 0, 0)
    end
end

-- ========================================
-- === ИНИЦИАЛИЗАЦИЯ ===
-- ========================================
setSpeed()
startAntiKick()
startKickNotifier()
createGUI()

RunService.Heartbeat:Connect(tick)

player.CharacterAdded:Connect(function(newChar)
    character = newChar
    humanoid = character:WaitForChild("Humanoid")
    rootPart = character:WaitForChild("HumanoidRootPart")
    wait(0.5)
    setSpeed()
    if antiGrabActive then startAntiGrab() end
    if antiKickActive then startAntiKick() end
    if kickNotifierActive then startKickNotifier() end
    if superThrowActive then startSuperThrow() end
    if jerkOffActive then startJerkOff() end
    if thirdPersonActive then enableThirdPerson() end
    if flingActive then
        stopFling()
        startFling()
    end
    if anchorGrabActive then
        stopAnchorGrab()
        startAnchorGrab()
    end
end)

print("====================================")
print("  💀 gakuka FTAP - RAGALIC STYLE v3.1")
print("  =================================")
print("  ✅ Anti-Kick из Ragalic (сюрикен)")
print("  ✅ Third Person View")
print("  ✅ Меню с вкладками (Grab, Defense, Player, Misc)")
print("  ✅ Все функции: FLING GRAB, ANTI-GRAB, ROBLOX EGOR, SUPER THROW, ANCHOR GRAB, JERK OFF, уведомления")
print("  ✅ КНОПКИ МЕНЯЮТСЯ ПРИ ПЕРЕКЛЮЧЕНИИ ВКЛАДОК")
print("====================================")
