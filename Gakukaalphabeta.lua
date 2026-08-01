-- gakuka FTAP - Tokra Style Menu v2.0 (Исправлено: кнопки меняются, прыжок нормальный)
-- Вкладки: Grab | Defense | Speed | Misc
-- Все функции: Anti-Grab, Иллюзия безопасности (Shuriken), ROBLOX EGOR, Anchor Grab, FLING GRAB

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
local frozenObjects = {}
local screenGui = nil
local mainFrame = nil
local contentFrame = nil
local currentTab = "Grab"

-- ===== КНОПКИ ВКЛАДОК =====
local tabButtons = {}

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
-- === ROBLOX EGOR (БЕЗ ИЗМЕНЕНИЯ ПРЫЖКА) ===
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
        -- НЕ ТРОГАЕМ JumpPower, оставляем как в игре
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
-- === TOGGLE FUNCTIONS ===
-- ========================================
local function toggleSpeed()
    speedModeActive = not speedModeActive
    setSpeed()
    updateTabContent(currentTab)
end

local function toggleAntiGrab()
    antiGrabActive = not antiGrabActive
    if antiGrabActive then startAntiGrab() else stopAntiGrab() end
    updateTabContent(currentTab)
end

local function toggleAnchorGrab()
    anchorGrabActive = not anchorGrabActive
    if anchorGrabActive then startAnchorGrab() else stopAnchorGrab() end
    updateTabContent(currentTab)
end

local function toggleIllusion()
    antiKickActive = not antiKickActive
    if antiKickActive then startIllusion() else stopIllusion() end
    updateTabContent(currentTab)
end

local function toggleFling()
    if flingActive then stopFling() else startFling() end
    updateTabContent(currentTab)
end

local function stopAll()
    stopFling()
    stopAntiGrab()
    stopSpeedControl()
    stopIllusion()
    stopAnchorGrab()
    speedModeActive = false
    anchorGrabActive = false
    updateTabContent(currentTab)
end

-- ========================================
-- === GUI (TOKRA STYLE) ===
-- ========================================
local closeBtn = nil

local function createTabButtons()
    local tabNames = {"Grab", "Defense", "Speed", "Misc"}
    local tabY = 0.07
    for i, name in ipairs(tabNames) do
        local tabBtn = Instance.new("TextButton")
        tabBtn.Size = UDim2.new(0.22, 0, 0, 25)
        tabBtn.Position = UDim2.new(0.02 + (i-1) * 0.24, 0, tabY, 0)
        tabBtn.BackgroundColor3 = (name == currentTab) and Color3.fromRGB(80, 80, 180) or Color3.fromRGB(40, 40, 60)
        tabBtn.BackgroundTransparency = 0.3
        tabBtn.Text = name
        tabBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        tabBtn.Font = Enum.Font.GothamBold
        tabBtn.TextSize = 13
        tabBtn.BorderSizePixel = 1
        tabBtn.BorderColor3 = Color3.fromRGB(80, 80, 150)
        tabBtn.Parent = mainFrame
        local c = Instance.new("UICorner")
        c.CornerRadius = UDim.new(0, 6)
        c.Parent = tabBtn
        tabBtn.MouseButton1Click:Connect(function()
            currentTab = name
            for _, btn in pairs(tabButtons) do
                btn.BackgroundColor3 = (btn == tabBtn) and Color3.fromRGB(80, 80, 180) or Color3.fromRGB(40, 40, 60)
            end
            updateTabContent(name)
        end)
        tabButtons[name] = tabBtn
    end
end

local function updateTabContent(tab)
    if contentFrame then
        contentFrame:ClearAllChildren()
    end
    
    local y = 0.0
    local function addButton(text, color, callback)
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(0.85, 0, 0, 28)
        btn.Position = UDim2.new(0.075, 0, y, 0)
        btn.BackgroundColor3 = color or Color3.fromRGB(50, 50, 80)
        btn.BackgroundTransparency = 0.3
        btn.Text = text
        btn.TextColor3 = Color3.fromRGB(255, 255, 255)
        btn.Font = Enum.Font.GothamBold
        btn.TextSize = 12
        btn.BorderSizePixel = 2
        btn.BorderColor3 = Color3.fromRGB(80, 80, 150)
        btn.Parent = contentFrame
        local c = Instance.new("UICorner")
        c.CornerRadius = UDim.new(0, 8)
        c.Parent = btn
        btn.MouseButton1Click:Connect(callback)
        y = y + 0.09
        return btn
    end
    
    if tab == "Grab" then
        addButton("💥 FLING GRAB " .. (flingActive and "[ВКЛ]" or "[ВЫКЛ]"), flingActive and Color3.fromRGB(0, 200, 50) or Color3.fromRGB(180, 40, 40), function()
            toggleFling()
        end)
        addButton("⚓ ANCHOR GRAB " .. (anchorGrabActive and "[ВКЛ]" or "[ВЫКЛ]"), anchorGrabActive and Color3.fromRGB(0, 180, 255) or Color3.fromRGB(180, 40, 40), function()
            toggleAnchorGrab()
        end)
    elseif tab == "Defense" then
        addButton("🛡️ ANTI-GRAB " .. (antiGrabActive and "[ВКЛ]" or "[ВЫКЛ]"), antiGrabActive and Color3.fromRGB(0, 180, 0) or Color3.fromRGB(180, 40, 40), function()
            toggleAntiGrab()
        end)
        addButton("🔮 ИЛЛЮЗИЯ БЕЗОПАСНОСТИ " .. (antiKickActive and "[ВКЛ]" or "[ВЫКЛ]"), antiKickActive and Color3.fromRGB(0, 180, 0) or Color3.fromRGB(180, 40, 40), function()
            toggleIllusion()
        end)
    elseif tab == "Speed" then
        addButton("🏃 ROBLOX EGOR " .. (speedModeActive and "[ВКЛ]" or "[ВЫКЛ]"), speedModeActive and Color3.fromRGB(0, 200, 100) or Color3.fromRGB(180, 40, 40), function()
            toggleSpeed()
        end)
    elseif tab == "Misc" then
        addButton("⛔ ОСТАНОВИТЬ ВСЁ", Color3.fromRGB(150, 0, 30), function()
            stopAll()
        end)
    end
end

-- ===== GUI СОЗДАНИЕ =====
local function createGUI()
    if screenGui then screenGui:Destroy() end
    screenGui = Instance.new("ScreenGui")
    screenGui.Name = "gakukaGUI"
    screenGui.Parent = player:WaitForChild("PlayerGui")
    screenGui.ResetOnSpawn = false
    
    mainFrame = Instance.new("Frame")
    mainFrame.Size = UDim2.new(0, 320, 0, 320)
    mainFrame.Position = UDim2.new(0.5, -160, 0.5, -160)
    mainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 30)
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
    titleBar.Size = UDim2.new(1, 0, 0, 35)
    titleBar.BackgroundColor3 = Color3.fromRGB(30, 30, 55)
    titleBar.BackgroundTransparency = 0.3
    titleBar.BorderSizePixel = 2
    titleBar.BorderColor3 = Color3.fromRGB(80, 80, 180)
    titleBar.Parent = mainFrame
    local titleCorner = Instance.new("UICorner")
    titleCorner.CornerRadius = UDim.new(0, 12)
    titleCorner.Parent = titleBar
    
    local titleText = Instance.new("TextLabel")
    titleText.Size = UDim2.new(1, -60, 1, 0)
    titleText.Position = UDim2.new(0, 10, 0, 0)
    titleText.BackgroundTransparency = 1
    titleText.Text = "💀 gakuka FTAP"
    titleText.TextColor3 = Color3.fromRGB(200, 50, 200)
    titleText.Font = Enum.Font.GothamBold
    titleText.TextSize = 16
    titleText.TextXAlignment = Enum.TextXAlignment.Left
    titleText.Parent = titleBar
    
    -- Кнопка закрытия
    closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.new(0, 28, 0, 28)
    closeBtn.Position = UDim2.new(1, -34, 0, 4)
    closeBtn.BackgroundColor3 = Color3.fromRGB(200, 0, 0)
    closeBtn.BackgroundTransparency = 0.2
    closeBtn.Text = "✕"
    closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.TextSize = 16
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
    
    -- Контейнер для контента вкладок
    contentFrame = Instance.new("Frame")
    contentFrame.Size = UDim2.new(1, 0, 1, -50)
    contentFrame.Position = UDim2.new(0, 0, 0, 50)
    contentFrame.BackgroundTransparency = 1
    contentFrame.Parent = mainFrame
    
    createTabButtons()
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
startIllusion()
createGUI()

RunService.Heartbeat:Connect(tick)

player.CharacterAdded:Connect(function(newChar)
    character = newChar
    humanoid = character:WaitForChild("Humanoid")
    rootPart = character:WaitForChild("HumanoidRootPart")
    wait(0.5)
    setSpeed()
    if antiGrabActive then startAntiGrab() end
    if antiKickActive then startIllusion() end
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
print("  💀 gakuka FTAP - TOKRA STYLE")
print("  =================================")
print("  🛡️ ANTI-GRAB - БЕЗ БЛОКИРОВКИ")
print("  🔮 ИЛЛЮЗИЯ БЕЗОПАСНОСТИ (СЮРИКЕН) - ВКЛ")
print("  ✅ ROBLOX EGOR - скорость 70 (прыжок НЕ ТРОГАЕМ)")
print("  ⚓ ANCHOR GRAB - РАБОТАЕТ")
print("  💥 FLING GRAB - все летают (кроме тебя)")
print("  ✅ ТЫ НЕ ЛЕТАЕШЬ")
print("  =================================")
print("  📌 ВКЛАДКИ: Grab | Defense | Speed | Misc")
print("====================================")
