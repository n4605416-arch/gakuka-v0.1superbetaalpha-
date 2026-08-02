-- gakuka FTAP - Raufield Style v1.3 (Полная версия с уведомлениями о киках)
-- Меню в стиле Raufield (сине-голубая тема)
-- Anti-Kick из Venom X Hub (защита от кика и кик-граба)
-- Уведомления о киках: BillboardGui над кикнутым игроком + лог в консоль

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local player = Players.LocalPlayer

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
local frozenObjects = {}
local screenGui = nil
local mainFrame = nil

-- ===== КНОПКИ =====
local flingBtn, antiBtn, speedBtn, anchorBtn, kickBtn, notifierBtn, stopBtn, statusText

-- ========================================
-- === ANTI-KICK ИЗ VENOM X HUB ===
-- ========================================
local antiKickCoroutine = nil
local kickGrabConnections = {}

local function startAntiKick()
    if antiKickCoroutine then return end

    antiKickCoroutine = coroutine.create(function()
        while antiKickActive do
            pcall(function()
                -- 1. Удаляем KickScript из Workspace
                local kickScript = workspace:FindFirstChild("KickScript")
                if kickScript then kickScript:Destroy() end

                -- 2. Удаляем KickScript из персонажа
                local charKick = character:FindFirstChild("KickScript")
                if charKick then charKick:Destroy() end

                -- 3. Удаляем GrabPart с атрибутом Kick
                local grabParts = workspace:FindFirstChild("GrabParts")
                if grabParts then
                    local grabPart = grabParts:FindFirstChild("GrabPart")
                    if grabPart and grabPart:FindFirstChild("Kick") then
                        grabPart:Destroy()
                    end
                end

                -- 4. Удаляем KickEvent из ReplicatedStorage
                local kickEvent = ReplicatedStorage:FindFirstChild("KickEvent")
                if kickEvent then kickEvent:Destroy() end
            end)
            task.wait()
        end
    end)
    coroutine.resume(antiKickCoroutine)

    -- Защита от кик-граба
    local connection
    connection = Workspace.ChildAdded:Connect(function(child)
        if not antiKickActive then return end
        if child.Name == "GrabParts" then
            task.wait(0.1)
            local grabPart = child:FindFirstChild("GrabPart")
            if grabPart then
                local weld = grabPart:FindFirstChild("WeldConstraint")
                if weld and weld.Part1 then
                    local primaryPart = weld.Part1
                    if primaryPart.Name == "FirePlayerPart" then
                        for _, childPart in ipairs(primaryPart:GetChildren()) do
                            if childPart:IsA("BodyPosition") or childPart:IsA("BodyGyro") then
                                childPart:Destroy()
                            end
                        end
                        while workspace:FindFirstChild("GrabParts") do
                            task.wait()
                        end
                    end
                end
            end
        end
    end)
    table.insert(kickGrabConnections, connection)
end

local function stopAntiKick()
    antiKickActive = false
    if antiKickCoroutine then
        coroutine.close(antiKickCoroutine)
        antiKickCoroutine = nil
    end
    for _, conn in ipairs(kickGrabConnections) do
        pcall(conn.Disconnect, conn)
    end
    kickGrabConnections = {}
end

-- ========================================
-- === УВЕДОМЛЕНИЯ О КИКАХ (BillboardGui) ===
-- ========================================
local kickNotifierConnection = nil
local notifiedPlayers = {} -- чтобы не спамить уведомлениями повторно

local function showKickNotification(playerName, characterToNotify)
    if not characterToNotify or not characterToNotify.Parent then return end
    local head = characterToNotify:FindFirstChild("Head")
    if not head then return end

    -- Создаём BillboardGui
    local billboard = Instance.new("BillboardGui")
    billboard.Size = UDim2.new(0, 250, 0, 60)
    billboard.StudsOffset = Vector3.new(0, 3, 0)
    billboard.Parent = head

    -- Фон уведомления
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 1, 0)
    frame.BackgroundColor3 = Color3.fromRGB(30, 0, 0)
    frame.BackgroundTransparency = 0.4
    frame.BorderSizePixel = 2
    frame.BorderColor3 = Color3.fromRGB(255, 0, 0)
    frame.Parent = billboard
    local frameCorner = Instance.new("UICorner")
    frameCorner.CornerRadius = UDim.new(0, 8)
    frameCorner.Parent = frame

    -- Текст
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.Text = "⚠️ " .. playerName .. " был кикнут!"
    label.TextColor3 = Color3.fromRGB(255, 50, 50)
    label.TextScaled = true
    label.Font = Enum.Font.GothamBold
    label.TextWrapped = true
    label.Parent = frame

    -- Автоудаление через 4 секунды
    task.wait(4)
    billboard:Destroy()
end

local function startKickNotifier()
    if kickNotifierConnection then return end

    -- Очищаем список уведомлённых при перезапуске
    notifiedPlayers = {}

    kickNotifierConnection = RunService.Heartbeat:Connect(function()
        if not kickNotifierActive then return end

        pcall(function()
            -- Ищем чёрную дыру
            local blackHole = Workspace:FindFirstChild("BlackHole")
            if not blackHole then return end

            -- Проверяем всех игроков
            for _, plr in ipairs(Players:GetPlayers()) do
                if plr ~= player then
                    local char = plr.Character
                    if char then
                        local root = char:FindFirstChild("HumanoidRootPart")
                        if root then
                            local distance = (root.Position - blackHole.Position).Magnitude
                            -- Если игрок в радиусе чёрной дыры и его ещё не уведомили
                            if distance < 20 and not notifiedPlayers[plr.UserId] then
                                -- Показываем уведомление
                                showKickNotification(plr.Name, char)
                                notifiedPlayers[plr.UserId] = true
                                print("[Уведомление] Игрок " .. plr.Name .. " был кикнут чёрной дырой!")
                            end
                            -- Если игрок вышел из радиуса, разрешаем уведомить снова (если вернётся)
                            if distance >= 20 then
                                notifiedPlayers[plr.UserId] = nil
                            end
                        end
                    end
                end
            end
        end)
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
-- === ANTI-GRAB (БЕЗ БЛОКИРОВКИ ДВИЖЕНИЯ) ===
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
-- === ИЛЛЮЗИЯ БЕЗОПАСНОСТИ (СЮРИКЕН) ===
-- ========================================
local antiKickConnection = nil
local shurikenObject = nil

local function createShuriken()
    local shuriken = Instance.new("Part")
    shuriken.Size = Vector3.new(1.8, 0.2, 1.8)
    shuriken.Shape = Enum.PartType.Block
    shuriken.BrickColor = BrickColor.new("Bright blue")
    shuriken.Material = Enum.Material.Neon
    shuriken.Anchored = false
    shuriken.CanCollide = false
    shuriken.CanQuery = false
    shuriken.Transparency = 0.15
    shuriken.Name = "IllusionShuriken"
    shuriken.Parent = workspace

    local angles = {0, 90, 180, 270}
    for _, angle in ipairs(angles) do
        local blade = Instance.new("Part")
        blade.Size = Vector3.new(0.8, 0.2, 2.0)
        blade.Shape = Enum.PartType.Block
        blade.BrickColor = BrickColor.new("Bright blue")
        blade.Material = Enum.Material.Neon
        blade.Anchored = false
        blade.CanCollide = false
        blade.CanQuery = false
        blade.Transparency = 0.2
        blade.Name = "Blade"
        blade.Parent = shuriken
        blade.CFrame = shuriken.CFrame * CFrame.Angles(0, math.rad(angle), 0) * CFrame.new(0, 0, 1.0)
    end

    local glow = Instance.new("SelectionBox")
    glow.Adornee = shuriken
    glow.Color3 = Color3.fromRGB(0, 150, 255)
    glow.Transparency = 0.3
    glow.LineThickness = 0.15
    glow.Name = "Glow"
    glow.Parent = shuriken

    local particles = Instance.new("ParticleEmitter")
    particles.Texture = "rbxassetid://7575379200"
    particles.Rate = 20
    particles.VelocityInheritance = 0
    particles.Lifetime = NumberRange.new(1, 1.5)
    particles.SpreadAngle = Vector2.new(360, 360)
    particles.Rotation = NumberRange.new(0, 360)
    particles.Transparency = NumberSequence.new(0.8, 0)
    particles.Color = ColorSequence.new(Color3.fromRGB(0, 150, 255))
    particles.Size = NumberSequence.new(0.5, 1)
    particles.Parent = shuriken

    return shuriken
end

local function startIllusion()
    if antiKickConnection then return end
    if not shurikenObject then
        shurikenObject = createShuriken()
    end
    antiKickConnection = RunService.Heartbeat:Connect(function()
        if not antiKickActive then return end
        if not character or not character.Parent then return end
        if not rootPart then return end
        if shurikenObject then
            shurikenObject.CFrame = rootPart.CFrame * CFrame.new(0, 0.5, 0)
            shurikenObject.Velocity = Vector3.new(0, 0, 0)
            shurikenObject.RotVelocity = Vector3.new(0, 0, 0)
            shurikenObject.CFrame = shurikenObject.CFrame * CFrame.Angles(0, tick() * 2, 0)
        end
    end)
end

local function stopIllusion()
    if antiKickConnection then
        antiKickConnection:Disconnect()
        antiKickConnection = nil
    end
    if shurikenObject then
        shurikenObject:Destroy()
        shurikenObject = nil
    end
end

-- ========================================
-- === ROBLOX EGOR ===
-- ========================================
local speedLoop = nil

local function setSpeed()
    if not humanoid then return end
    if speedLoop then speedLoop:Disconnect() end
    speedLoop = RunService.Heartbeat:Connect(function()
        if not character or not character.Parent then return end
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
-- === ОБНОВЛЕНИЕ КНОПОК ===
-- ========================================
local function updateAllButtons()
    if flingBtn then
        flingBtn.Text = "💥 FLING GRAB " .. (flingActive and "[ВКЛ]" or "[ВЫКЛ]")
        flingBtn.BackgroundColor3 = flingActive and Color3.fromRGB(0, 200, 50) or Color3.fromRGB(180, 40, 40)
    end
    if antiBtn then
        antiBtn.Text = "🛡️ ANTI-GRAB " .. (antiGrabActive and "[ВКЛ]" or "[ВЫКЛ]")
        antiBtn.BackgroundColor3 = antiGrabActive and Color3.fromRGB(0, 180, 0) or Color3.fromRGB(180, 40, 40)
    end
    if speedBtn then
        speedBtn.Text = "🏃 ROBLOX EGOR " .. (speedModeActive and "[ВКЛ]" or "[ВЫКЛ]")
        speedBtn.BackgroundColor3 = speedModeActive and Color3.fromRGB(0, 200, 100) or Color3.fromRGB(180, 40, 40)
    end
    if anchorBtn then
        anchorBtn.Text = "⚓ ANCHOR GRAB " .. (anchorGrabActive and "[ВКЛ]" or "[ВЫКЛ]")
        anchorBtn.BackgroundColor3 = anchorGrabActive and Color3.fromRGB(0, 180, 255) or Color3.fromRGB(180, 40, 40)
    end
    if kickBtn then
        kickBtn.Text = "🔮 ИЛЛЮЗИЯ БЕЗОПАСНОСТИ " .. (antiKickActive and "[ВКЛ]" or "[ВЫКЛ]")
        kickBtn.BackgroundColor3 = antiKickActive and Color3.fromRGB(0, 180, 0) or Color3.fromRGB(180, 40, 40)
    end
    if notifierBtn then
        notifierBtn.Text = "🔔 УВЕДОМЛЕНИЯ О КИКЕ " .. (kickNotifierActive and "[ВКЛ]" or "[ВЫКЛ]")
        notifierBtn.BackgroundColor3 = kickNotifierActive and Color3.fromRGB(0, 180, 0) or Color3.fromRGB(180, 40, 40)
    end
    if statusText then
        local parts = {}
        if kickNotifierActive then table.insert(parts, "🔔 Уведомления ВКЛ") else table.insert(parts, "🔕 Уведомления ВЫКЛ") end
        if antiKickActive then table.insert(parts, "| 🛡️ Защита ВКЛ") else table.insert(parts, "| 🛡️ Защита ВЫКЛ") end
        if anchorGrabActive then table.insert(parts, "| ⚓ Заморозка ВКЛ") end
        statusText.Text = table.concat(parts, " ")
    end
end

-- ========================================
-- === TOGGLE FUNCTIONS ===
-- ========================================
local function toggleSpeed()
    speedModeActive = not speedModeActive
    setSpeed()
    updateAllButtons()
end

local function toggleAntiGrab()
    antiGrabActive = not antiGrabActive
    if antiGrabActive then startAntiGrab() else stopAntiGrab() end
    updateAllButtons()
end

local function toggleAnchorGrab()
    anchorGrabActive = not anchorGrabActive
    if anchorGrabActive then startAnchorGrab() else stopAnchorGrab() end
    updateAllButtons()
end

local function toggleIllusion()
    antiKickActive = not antiKickActive
    if antiKickActive then startAntiKick() else stopAntiKick() end
    updateAllButtons()
end

local function toggleFling()
    if flingActive then stopFling() else startFling() end
    updateAllButtons()
end

local function toggleNotifier()
    kickNotifierActive = not kickNotifierActive
    if kickNotifierActive then startKickNotifier() else stopKickNotifier() end
    updateAllButtons()
end

local function stopAll()
    stopFling()
    stopAntiGrab()
    stopSpeedControl()
    stopAntiKick()
    stopAnchorGrab()
    stopKickNotifier()
    speedModeActive = false
    anchorGrabActive = false
    updateAllButtons()
    if statusText then
        statusText.Text = "⛔ ВСЁ ОСТАНОВЛЕНО"
        statusText.TextColor3 = Color3.fromRGB(255, 100, 100)
    end
end

-- ========================================
-- === GUI (СТИЛЬ RAUFIELD) ===
-- ========================================
local function createGUI()
    if screenGui then screenGui:Destroy() end
    screenGui = Instance.new("ScreenGui")
    screenGui.Name = "gakukaGUI"
    screenGui.Parent = player:WaitForChild("PlayerGui")
    screenGui.ResetOnSpawn = false

    mainFrame = Instance.new("Frame")
    mainFrame.Size = UDim2.new(0, 380, 0, 440)
    mainFrame.Position = UDim2.new(0.5, -190, 0.5, -220)
    mainFrame.BackgroundColor3 = Color3.fromRGB(10, 20, 40)
    mainFrame.BackgroundTransparency = 0.15
    mainFrame.BorderSizePixel = 2
    mainFrame.BorderColor3 = Color3.fromRGB(0, 150, 255)
    mainFrame.Parent = screenGui
    mainFrame.Active = true
    mainFrame.Draggable = true

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 12)
    corner.Parent = mainFrame

    -- Заголовок
    local titleBar = Instance.new("Frame")
    titleBar.Size = UDim2.new(1, 0, 0, 50)
    titleBar.BackgroundColor3 = Color3.fromRGB(0, 80, 180)
    titleBar.BackgroundTransparency = 0.2
    titleBar.BorderSizePixel = 0
    titleBar.Parent = mainFrame

    local titleCorner = Instance.new("UICorner")
    titleCorner.CornerRadius = UDim.new(0, 12)
    titleCorner.Parent = titleBar

    local titleText = Instance.new("TextLabel")
    titleText.Size = UDim2.new(1, -60, 1, 0)
    titleText.Position = UDim2.new(0, 15, 0, 0)
    titleText.BackgroundTransparency = 1
    titleText.Text = "💀 gakuka FTAP"
    titleText.TextColor3 = Color3.fromRGB(0, 200, 255)
    titleText.Font = Enum.Font.GothamBold
    titleText.TextSize = 22
    titleText.TextXAlignment = Enum.TextXAlignment.Left
    titleText.Parent = titleBar

    local verText = Instance.new("TextLabel")
    verText.Size = UDim2.new(1, -60, 0, 18)
    verText.Position = UDim2.new(0, 15, 0, 28)
    verText.BackgroundTransparency = 1
    verText.Text = "v1.3 | Raufield Style + Notify"
    verText.TextColor3 = Color3.fromRGB(150, 200, 255)
    verText.Font = Enum.Font.Gotham
    verText.TextSize = 11
    verText.TextXAlignment = Enum.TextXAlignment.Left
    verText.Parent = titleBar

    -- Кнопка закрытия
    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.new(0, 32, 0, 32)
    closeBtn.Position = UDim2.new(1, -40, 0, 9)
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

    -- СТАТУС
    statusText = Instance.new("TextLabel")
    statusText.Size = UDim2.new(0.92, 0, 0, 28)
    statusText.Position = UDim2.new(0.04, 0, 0.14, 0)
    statusText.BackgroundColor3 = Color3.fromRGB(0, 40, 80)
    statusText.BackgroundTransparency = 0.5
    statusText.Text = "🔔 Уведомления ВКЛ | 🛡️ Защита ВКЛ"
    statusText.TextColor3 = Color3.fromRGB(100, 200, 255)
    statusText.Font = Enum.Font.GothamSemibold
    statusText.TextSize = 13
    statusText.TextXAlignment = Enum.TextXAlignment.Center
    statusText.Parent = mainFrame

    local statusCorner = Instance.new("UICorner")
    statusCorner.CornerRadius = UDim.new(0, 6)
    statusCorner.Parent = statusText

    -- ===== КНОПКИ =====
    local function createBtn(text, y, color, cb)
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(0.88, 0, 0, 34)
        btn.Position = UDim2.new(0.06, 0, y, 0)
        btn.BackgroundColor3 = color or Color3.fromRGB(0, 60, 120)
        btn.BackgroundTransparency = 0.3
        btn.Text = text
        btn.TextColor3 = Color3.fromRGB(255, 255, 255)
        btn.Font = Enum.Font.GothamBold
        btn.TextSize = 14
        btn.BorderSizePixel = 1
        btn.BorderColor3 = Color3.fromRGB(0, 150, 255)
        btn.Parent = mainFrame

        local c = Instance.new("UICorner")
        c.CornerRadius = UDim.new(0, 8)
        c.Parent = btn

        btn.MouseButton1Click:Connect(cb)
        return btn
    end

    local y = 0.20

    flingBtn = createBtn("💥 FLING GRAB [ВЫКЛ]", y, Color3.fromRGB(180, 40, 40), function()
        toggleFling()
    end)
    y = y + 0.10

    antiBtn = createBtn("🛡️ ANTI-GRAB [ВЫКЛ]", y, Color3.fromRGB(180, 40, 40), function()
        toggleAntiGrab()
    end)
    y = y + 0.10

    speedBtn = createBtn("🏃 ROBLOX EGOR [ВЫКЛ]", y, Color3.fromRGB(180, 40, 40), function()
        toggleSpeed()
    end)
    y = y + 0.10

    anchorBtn = createBtn("⚓ ANCHOR GRAB [ВЫКЛ]", y, Color3.fromRGB(180, 40, 40), function()
        toggleAnchorGrab()
    end)
    y = y + 0.10

    kickBtn = createBtn("🔮 ИЛЛЮЗИЯ БЕЗОПАСНОСТИ [ВКЛ]", y, Color3.fromRGB(0, 180, 0), function()
        toggleIllusion()
    end)
    y = y + 0.10

    notifierBtn = createBtn("🔔 УВЕДОМЛЕНИЯ О КИКЕ [ВКЛ]", y, Color3.fromRGB(0, 180, 0), function()
        toggleNotifier()
    end)
    y = y + 0.10

    stopBtn = createBtn("⛔ ОСТАНОВИТЬ ВСЁ", y, Color3.fromRGB(150, 0, 30), function()
        stopAll()
    end)

    updateAllButtons()
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
print("  💀 gakuka FTAP - Raufield Style")
print("  =================================")
print("  🛡️ ANTI-GRAB - БЕЗ БЛОКИРОВКИ")
print("  🔮 ИЛЛЮЗИЯ БЕЗОПАСНОСТИ - ВКЛ")
print("  🔔 УВЕДОМЛЕНИЯ О КИКЕ - ВКЛ")
print("  ✅ ROBLOX EGOR - скорость 70")
print("  ⚓ ANCHOR GRAB - РАБОТАЕТ")
print("  💥 FLING GRAB - все летают")
print("  ✅ ТЫ НЕ ЛЕТАЕШЬ")
print("====================================")
