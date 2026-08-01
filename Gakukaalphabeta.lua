-- gakuka FTAP - ULTIMATE v1.3 (Anti-Grab без блокировки)
-- Anti-Grab по умолчанию выключен, не мешает движению
-- Anti-Kick включен, защищает от вытеснения

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

-- ===== КНОПКИ =====
local flingBtn, antiBtn, speedBtn, anchorBtn, kickBtn, statusText

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
                    -- ВЫРЫВАЕМСЯ
                    local struggle = ReplicatedStorage:FindFirstChild("CharacterEvents")
                    if struggle then
                        local struggleEvent = struggle:FindFirstChild("Struggle")
                        if struggleEvent then struggleEvent:FireServer() end
                    end
                    
                    -- ОСТАНАВЛИВАЕМ СКОРОСТЬ
                    local correction = ReplicatedStorage:FindFirstChild("GameCorrectionEvents")
                    if correction then
                        local stopVelocity = correction:FindFirstChild("StopAllVelocity")
                        if stopVelocity then stopVelocity:FireServer() end
                    end
                    
                    -- СБРАСЫВАЕМ СКОРОСТЬ СЕБЯ
                    if rootPart then
                        rootPart.Velocity = Vector3.new(0, 0, 0)
                        rootPart.RotVelocity = Vector3.new(0, 0, 0)
                    end
                    
                    -- ПРИНУДИТЕЛЬНО ВЫХОДИМ ИЗ GRABBED
                    if humanoid then
                        humanoid:ChangeState(Enum.HumanoidStateType.Running)
                    end
                    
                    -- УДАЛЯЕМ PART OWNER
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
-- === ANTI-KICK (ЗАЩИТА ОТ ВЫТЕСНЕНИЯ) ===
-- ========================================
local antiKickConnection = nil

local function startAntiKick()
    if antiKickConnection then return end
    
    antiKickConnection = RunService.Heartbeat:Connect(function()
        if not antiKickActive then return end
        if not character or not character.Parent then return end
        
        pcall(function()
            local kickScript = Workspace:FindFirstChild("KickScript")
            if kickScript then kickScript:Destroy() end
            
            local charKick = character:FindFirstChild("KickScript")
            if charKick then charKick:Destroy() end
            
            local grabParts = Workspace:FindFirstChild("GrabParts")
            if grabParts then
                local grabPart = grabParts:FindFirstChild("GrabPart")
                if grabPart and grabPart:FindFirstChild("Kick") then
                    grabPart:Destroy()
                end
            end
            
            local kickEvent = ReplicatedStorage:FindFirstChild("KickEvent")
            if kickEvent then kickEvent:Destroy() end
        end)
    end)
end

local function stopAntiKick()
    if antiKickConnection then
        antiKickConnection:Disconnect()
        antiKickConnection = nil
    end
end

-- ========================================
-- === ROBLOX EGOR (СКОРОСТЬ) ===
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
        humanoid.JumpPower = 50
        humanoid.AutoRotate = true
        humanoid.PlatformStand = false
    end)
end

local function stopSpeedControl()
    if speedLoop then speedLoop:Disconnect(); speedLoop = nil end
end

-- ========================================
-- === ANCHOR GRAB (ПЕРЕХВАТ GRABPARTS) ===
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
-- === FLING ALL ===
-- ========================================
local flingConn = nil

local function startFling()
    if flingActive then return end
    flingActive = true
    if flingBtn then
        flingBtn.Text = "💥 FLING ALL [ВКЛ]"
        flingBtn.BackgroundColor3 = Color3.fromRGB(0, 200, 50)
    end
    if statusText then
        statusText.Text = "💥 FLING АКТИВЕН!"
        statusText.TextColor3 = Color3.fromRGB(0, 255, 100)
    end
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
    if flingBtn then
        flingBtn.Text = "💥 FLING ALL [ВЫКЛ]"
        flingBtn.BackgroundColor3 = Color3.fromRGB(180, 40, 40)
    end
    if statusText then
        statusText.Text = "✅ FLING ВЫКЛЮЧЕН"
        statusText.TextColor3 = Color3.fromRGB(200, 200, 200)
    end
end

-- ========================================
-- === TOGGLE FUNCTIONS ===
-- ========================================
local function toggleSpeed()
    speedModeActive = not speedModeActive
    setSpeed()
    if speedModeActive then
        speedBtn.Text = "🏃 ROBLOX EGOR [ВКЛ]"
        speedBtn.BackgroundColor3 = Color3.fromRGB(0, 200, 100)
        statusText.Text = "🏃 ROBLOX EGOR ВКЛ! (скорость 70)"
        statusText.TextColor3 = Color3.fromRGB(255, 200, 0)
    else
        speedBtn.Text = "🏃 ROBLOX EGOR [ВЫКЛ]"
        speedBtn.BackgroundColor3 = Color3.fromRGB(180, 40, 40)
        statusText.Text = "✅ ROBLOX EGOR ВЫКЛ"
        statusText.TextColor3 = Color3.fromRGB(200, 200, 200)
    end
end

local function toggleAntiGrab()
    antiGrabActive = not antiGrabActive
    if antiGrabActive then
        startAntiGrab()
        antiBtn.Text = "🛡️ ANTI-GRAB [ВКЛ]"
        antiBtn.BackgroundColor3 = Color3.fromRGB(0, 180, 0)
        statusText.Text = "🛡️ ANTI-GRAB ВКЛЮЧЕН (движение свободно)"
        statusText.TextColor3 = Color3.fromRGB(0, 255, 100)
    else
        stopAntiGrab()
        antiBtn.Text = "🛡️ ANTI-GRAB [ВЫКЛ]"
        antiBtn.BackgroundColor3 = Color3.fromRGB(180, 40, 40)
        statusText.Text = "🛡️ ANTI-GRAB ВЫКЛЮЧЕН"
        statusText.TextColor3 = Color3.fromRGB(255, 150, 0)
    end
end

local function toggleAnchorGrab()
    anchorGrabActive = not anchorGrabActive
    if anchorGrabActive then
        startAnchorGrab()
        anchorBtn.Text = "⚓ ANCHOR GRAB [ВКЛ]"
        anchorBtn.BackgroundColor3 = Color3.fromRGB(0, 180, 255)
        statusText.Text = "⚓ ANCHOR GRAB ВКЛЮЧЕН!"
        statusText.TextColor3 = Color3.fromRGB(0, 200, 255)
    else
        stopAnchorGrab()
        anchorBtn.Text = "⚓ ANCHOR GRAB [ВЫКЛ]"
        anchorBtn.BackgroundColor3 = Color3.fromRGB(180, 40, 40)
        statusText.Text = "✅ ANCHOR GRAB ВЫКЛЮЧЕН"
        statusText.TextColor3 = Color3.fromRGB(200, 200, 200)
    end
end

local function toggleAntiKick()
    antiKickActive = not antiKickActive
    if antiKickActive then
        startAntiKick()
        kickBtn.Text = "🚫 ANTI-KICK [ВКЛ]"
        kickBtn.BackgroundColor3 = Color3.fromRGB(0, 180, 0)
        statusText.Text = "🚫 ANTI-KICK ВКЛЮЧЕН"
        statusText.TextColor3 = Color3.fromRGB(0, 255, 100)
    else
        stopAntiKick()
        kickBtn.Text = "🚫 ANTI-KICK [ВЫКЛ]"
        kickBtn.BackgroundColor3 = Color3.fromRGB(180, 40, 40)
        statusText.Text = "🚫 ANTI-KICK ВЫКЛЮЧЕН"
        statusText.TextColor3 = Color3.fromRGB(255, 150, 0)
    end
end

local function stopAll()
    stopFling()
    stopAntiGrab()
    stopSpeedControl()
    stopAntiKick()
    if speedModeActive then
        speedModeActive = false
        speedBtn.Text = "🏃 ROBLOX EGOR [ВЫКЛ]"
        speedBtn.BackgroundColor3 = Color3.fromRGB(180, 40, 40)
    end
    if anchorGrabActive then
        anchorGrabActive = false
        stopAnchorGrab()
        anchorBtn.Text = "⚓ ANCHOR GRAB [ВЫКЛ]"
        anchorBtn.BackgroundColor3 = Color3.fromRGB(180, 40, 40)
    end
    statusText.Text = "⛔ ВСЁ ОСТАНОВЛЕНО"
    statusText.TextColor3 = Color3.fromRGB(255, 100, 100)
end

-- ========================================
-- === GUI ===
-- ========================================
local function createGUI()
    if screenGui then screenGui:Destroy() end
    screenGui = Instance.new("ScreenGui")
    screenGui.Name = "gakukaGUI"
    screenGui.Parent = player:WaitForChild("PlayerGui")
    screenGui.ResetOnSpawn = false
    
    mainFrame = Instance.new("Frame")
    mainFrame.Size = UDim2.new(0, 350, 0, 350)
    mainFrame.Position = UDim2.new(0.5, -175, 0.5, -175)
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
    titleText.Size = UDim2.new(1, -60, 1, 0)
    titleText.Position = UDim2.new(0, 12, 0, 0)
    titleText.BackgroundTransparency = 1
    titleText.Text = "💀 gakuka FTAP"
    titleText.TextColor3 = Color3.fromRGB(200, 50, 200)
    titleText.Font = Enum.Font.GothamBold
    titleText.TextSize = 18
    titleText.TextXAlignment = Enum.TextXAlignment.Left
    titleText.Parent = titleBar
    local verText = Instance.new("TextLabel")
    verText.Size = UDim2.new(1, -60, 0, 16)
    verText.Position = UDim2.new(0, 12, 0, 26)
    verText.BackgroundTransparency = 1
    verText.Text = "v1.3 | Anti-Grab без блокировки"
    verText.TextColor3 = Color3.fromRGB(0, 255, 100)
    verText.Font = Enum.Font.Gotham
    verText.TextSize = 10
    verText.TextXAlignment = Enum.TextXAlignment.Left
    verText.Parent = titleBar
    
    -- Кнопка закрытия
    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.new(0, 32, 0, 32)
    closeBtn.Position = UDim2.new(1, -38, 0, 7)
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
    statusText.Size = UDim2.new(0.9, 0, 0, 25)
    statusText.Position = UDim2.new(0.05, 0, 0.15, 0)
    statusText.BackgroundColor3 = Color3.fromRGB(35, 35, 60)
    statusText.BackgroundTransparency = 0.5
    statusText.Text = "🚫 ANTI-KICK ВКЛ | ANTI-GRAB ВЫКЛ"
    statusText.TextColor3 = Color3.fromRGB(0, 255, 100)
    statusText.Font = Enum.Font.GothamSemibold
    statusText.TextSize = 11
    statusText.Parent = mainFrame
    local statusCorner = Instance.new("UICorner")
    statusCorner.CornerRadius = UDim.new(0, 6)
    statusCorner.Parent = statusText
    
    -- ===== КНОПКИ =====
    local function createBtn(text, y, color, cb)
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(0.85, 0, 0, 30)
        btn.Position = UDim2.new(0.075, 0, y, 0)
        btn.BackgroundColor3 = color or Color3.fromRGB(50, 50, 80)
        btn.BackgroundTransparency = 0.3
        btn.Text = text
        btn.TextColor3 = Color3.fromRGB(255, 255, 255)
        btn.Font = Enum.Font.GothamBold
        btn.TextSize = 12
        btn.BorderSizePixel = 2
        btn.BorderColor3 = Color3.fromRGB(80, 80, 150)
        btn.Parent = mainFrame
        local c = Instance.new("UICorner")
        c.CornerRadius = UDim.new(0, 8)
        c.Parent = btn
        btn.MouseButton1Click:Connect(cb)
        return btn
    end
    
    local y = 0.21
    flingBtn = createBtn("💥 FLING ALL [ВЫКЛ]", y, Color3.fromRGB(180, 40, 40), function()
        if flingActive then stopFling() else startFling() end
    end)
    y = y + 0.09
    antiBtn = createBtn("🛡️ ANTI-GRAB [ВЫКЛ]", y, Color3.fromRGB(180, 40, 40), toggleAntiGrab)
    y = y + 0.09
    speedBtn = createBtn("🏃 ROBLOX EGOR [ВЫКЛ]", y, Color3.fromRGB(180, 40, 40), toggleSpeed)
    y = y + 0.09
    anchorBtn = createBtn("⚓ ANCHOR GRAB [ВЫКЛ]", y, Color3.fromRGB(180, 40, 40), toggleAnchorGrab)
    y = y + 0.09
    kickBtn = createBtn("🚫 ANTI-KICK [ВКЛ]", y, Color3.fromRGB(0, 180, 0), toggleAntiKick)
    y = y + 0.09
    local stopBtn = createBtn("⛔ ОСТАНОВИТЬ ВСЁ", y, Color3.fromRGB(150, 0, 30), function()
        stopAll()
        statusText.Text = "⛔ ВСЁ ОСТАНОВЛЕНО"
        statusText.TextColor3 = Color3.fromRGB(255, 100, 100)
    end)
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
print("  💀 gakuka FTAP - ULTIMATE v1.3")
print("  =================================")
print("  🛡️ ANTI-GRAB - БЕЗ БЛОКИРОВКИ ДВИЖЕНИЯ")
print("  🚫 ANTI-KICK - ВКЛЮЧЕН")
print("  ✅ ROBLOX EGOR - скорость 70")
print("  ⚓ ANCHOR GRAB - РАБОТАЕТ")
print("  💥 FLING ALL - все летают")
print("  ✅ ТЫ НЕ ЛЕТАЕШЬ")
print("====================================")
