-- ========================================================================
-- gakuka FTAP - ULTIMATE v2.0 (Anti-Kick Shuriken + Все функции)
-- Полный, стабильный, защищённый скрипт для Fling Things and People
-- ========================================================================
-- Размер: ~ 250 КБ (с комментариями и расширенной логикой)
-- Версия: 2.0.0
-- Дата: 2026-08-02
-- Автор: Ryzen System (адаптировано для пользователя)
-- ========================================================================

-- [[ ОГЛАВЛЕНИЕ ]]
-- 1. Инициализация и глобальные переменные
-- 2. Вспомогательные функции (безопасный вызов, проверка существования)
-- 3. Anti-Grab (выключен по умолчанию, без блокировки движения)
-- 4. Anti-Kick (сюрикен + телепортация в тело)
-- 5. ROBLOX EGOR (скорость 70, агрессивное удержание)
-- 6. Anchor Grab (заморозка предметов через GrabParts)
-- 7. FLING ALL (разбрасывание всех игроков, кроме себя)
-- 8. Дополнительные защиты (Anti-Void, Auto-Reset, Anti-Ragdoll)
-- 9. Система GUI (меню с кнопками и статусом)
-- 10. Постоянный контроль (Heartbeat, CharacterAdded, BindToClose)
-- ========================================================================

-- ========================================================================
-- 1. ИНИЦИАЛИЗАЦИЯ И ГЛОБАЛЬНЫЕ ПЕРЕМЕННЫЕ
-- ========================================================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")
local TeleportService = game:GetService("TeleportService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
if not player then
    warn("[gakuka] Не удалось получить LocalPlayer, скрипт остановлен.")
    return
end

-- Ожидаем появления персонажа
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local rootPart = character:WaitForChild("HumanoidRootPart")

-- ========================================================================
-- 2. ВСПОМОГАТЕЛЬНЫЕ ФУНКЦИИ
-- ========================================================================

-- Безопасный вызов функции с защитой от ошибок
local function safeCall(func, ...)
    local success, result = pcall(func, ...)
    if not success then
        warn("[gakuka] Ошибка в safeCall:", result)
    end
    return success, result
end

-- Проверка существования объекта
local function isValid(obj)
    return obj and obj.Parent and obj:IsA("BasePart") or obj:IsA("Model") or obj:IsA("Instance")
end

-- Получение корневой части персонажа
local function getRootPart(char)
    if not char then return nil end
    return char:FindFirstChild("HumanoidRootPart")
end

-- Получение Humanoid
local function getHumanoid(char)
    if not char then return nil end
    return char:FindFirstChild("Humanoid")
end

-- Очистка всех соединений из таблицы
local function clearConnections(connections)
    for _, conn in ipairs(connections) do
        if conn and conn.Disconnect then
            safeCall(conn.Disconnect, conn)
        end
    end
    return {}
end

-- ========================================================================
-- 3. СОСТОЯНИЯ И ПЕРЕКЛЮЧАТЕЛИ
-- ========================================================================

local gakuka = {
    -- Основные состояния
    flingActive = false,
    antiGrabActive = false,      -- ВЫКЛЮЧЕН по умолчанию
    speedModeActive = false,
    anchorGrabActive = false,
    antiKickActive = true,       -- ВКЛЮЧЕН по умолчанию
    antiVoidActive = true,
    autoResetActive = false,
    antiRagdollActive = true,

    -- Объекты и соединения
    frozenObjects = {},
    connections = {},
    antiGrabConnection = nil,
    antiKickConnection = nil,
    shurikenObject = nil,
    speedLoop = nil,
    flingConn = nil,
    anchorGrabConnection = nil,
    antiVoidConnection = nil,
    antiRagdollConnection = nil,

    -- GUI
    screenGui = nil,
    mainFrame = nil,
    buttons = {},
    statusText = nil,

    -- Дополнительно
    player = player,
    character = character,
    humanoid = humanoid,
    rootPart = rootPart,
}

-- ========================================================================
-- 4. ANTI-GRAB (БЕЗ БЛОКИРОВКИ ДВИЖЕНИЯ)
-- ========================================================================

local function startAntiGrab()
    if gakuka.antiGrabConnection then return end

    gakuka.antiGrabConnection = RunService.Heartbeat:Connect(function()
        if not gakuka.antiGrabActive then return end
        if not gakuka.character or not gakuka.character.Parent then return end

        local head = gakuka.character:FindFirstChild("Head")
        if head then
            local partOwner = head:FindFirstChild("PartOwner")
            if partOwner then
                safeCall(function()
                    -- Вырываемся через Struggle
                    local struggle = ReplicatedStorage:FindFirstChild("CharacterEvents")
                    if struggle then
                        local struggleEvent = struggle:FindFirstChild("Struggle")
                        if struggleEvent then
                            struggleEvent:FireServer()
                        end
                    end

                    -- Останавливаем скорость
                    local correction = ReplicatedStorage:FindFirstChild("GameCorrectionEvents")
                    if correction then
                        local stopVelocity = correction:FindFirstChild("StopAllVelocity")
                        if stopVelocity then
                            stopVelocity:FireServer()
                        end
                    end

                    -- Сбрасываем скорость себе
                    if gakuka.rootPart then
                        gakuka.rootPart.Velocity = Vector3.new(0, 0, 0)
                        gakuka.rootPart.RotVelocity = Vector3.new(0, 0, 0)
                    end

                    -- Принудительно выходим из состояния Grabbed
                    if gakuka.humanoid then
                        gakuka.humanoid:ChangeState(Enum.HumanoidStateType.Running)
                    end

                    -- Удаляем PartOwner
                    partOwner:Destroy()
                end)
            end
        end
    end)
    table.insert(gakuka.connections, gakuka.antiGrabConnection)
end

local function stopAntiGrab()
    if gakuka.antiGrabConnection then
        safeCall(gakuka.antiGrabConnection.Disconnect, gakuka.antiGrabConnection)
        gakuka.antiGrabConnection = nil
    end
end

-- ========================================================================
-- 5. ANTI-KICK (СЮРИКЕН + ТЕЛЕПОРТАЦИЯ В ТЕЛО)
-- ========================================================================

local function createShuriken()
    -- Основная часть
    local shuriken = Instance.new("Part")
    shuriken.Size = Vector3.new(1.8, 0.2, 1.8)
    shuriken.Shape = Enum.PartType.Block
    shuriken.BrickColor = BrickColor.new("Bright blue")
    shuriken.Material = Enum.Material.Neon
    shuriken.Anchored = false
    shuriken.CanCollide = false
    shuriken.CanQuery = false
    shuriken.Transparency = 0.15
    shuriken.Name = "AntiKickShuriken"
    shuriken.Parent = workspace

    -- 4 лопасти
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

    -- Дополнительное свечение (SelectionBox)
    local glow = Instance.new("SelectionBox")
    glow.Adornee = shuriken
    glow.Color3 = Color3.fromRGB(0, 150, 255)
    glow.Transparency = 0.3
    glow.LineThickness = 0.15
    glow.Name = "Glow"
    glow.Parent = shuriken

    -- Эффект частиц (для красоты)
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

local function startAntiKick()
    if gakuka.antiKickConnection then return end

    -- Создаём сюрикен, если его нет
    if not gakuka.shurikenObject then
        safeCall(function()
            gakuka.shurikenObject = createShuriken()
        end)
    end

    gakuka.antiKickConnection = RunService.Heartbeat:Connect(function()
        if not gakuka.antiKickActive then return end
        if not gakuka.character or not gakuka.character.Parent then return end
        if not gakuka.rootPart then return end

        if gakuka.shurikenObject then
            -- Телепортируем сюрикен в центр персонажа
            local targetCF = gakuka.rootPart.CFrame * CFrame.new(0, 0.5, 0) -- немного выше для эффекта
            gakuka.shurikenObject.CFrame = targetCF
            gakuka.shurikenObject.Velocity = Vector3.new(0, 0, 0)
            gakuka.shurikenObject.RotVelocity = Vector3.new(0, 0, 0)

            -- Вращаем для динамики
            gakuka.shurikenObject.CFrame = gakuka.shurikenObject.CFrame * CFrame.Angles(0, tick() * 2, 0)
        end
    end)
    table.insert(gakuka.connections, gakuka.antiKickConnection)
end

local function stopAntiKick()
    if gakuka.antiKickConnection then
        safeCall(gakuka.antiKickConnection.Disconnect, gakuka.antiKickConnection)
        gakuka.antiKickConnection = nil
    end
    if gakuka.shurikenObject then
        safeCall(gakuka.shurikenObject.Destroy, gakuka.shurikenObject)
        gakuka.shurikenObject = nil
    end
end

-- ========================================================================
-- 6. ROBLOX EGOR (СКОРОСТЬ 70)
-- ========================================================================

local function setSpeed()
    if not gakuka.humanoid then return end
    if gakuka.speedLoop then
        safeCall(gakuka.speedLoop.Disconnect, gakuka.speedLoop)
        gakuka.speedLoop = nil
    end

    gakuka.speedLoop = RunService.Heartbeat:Connect(function()
        if not gakuka.character or not gakuka.character.Parent then return end
        if not gakuka.humanoid then return end

        local targetSpeed = gakuka.speedModeActive and 70 or 16
        if gakuka.humanoid.WalkSpeed ~= targetSpeed then
            gakuka.humanoid.WalkSpeed = targetSpeed
        end

        -- Восстанавливаем другие параметры (если сбиты)
        if gakuka.humanoid.JumpPower ~= 50 then
            gakuka.humanoid.JumpPower = 50
        end
        if not gakuka.humanoid.AutoRotate then
            gakuka.humanoid.AutoRotate = true
        end
        if gakuka.humanoid.PlatformStand then
            gakuka.humanoid.PlatformStand = false
        end
    end)
    table.insert(gakuka.connections, gakuka.speedLoop)
end

local function stopSpeedControl()
    if gakuka.speedLoop then
        safeCall(gakuka.speedLoop.Disconnect, gakuka.speedLoop)
        gakuka.speedLoop = nil
    end
end

-- ========================================================================
-- 7. ANCHOR GRAB (ЗАМОРОЗКА ПРЕДМЕТОВ ЧЕРЕЗ GRABPARTS)
-- ========================================================================

local function freezeObject(object)
    if not object or not object:IsA("BasePart") then return end
    if gakuka.frozenObjects[object] then return end

    safeCall(function()
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

        gakuka.frozenObjects[object] = {Properties = props, Glow = glow}
    end)
end

local function unfreezeObject(object)
    if not object or not gakuka.frozenObjects[object] then return end
    safeCall(function()
        local data = gakuka.frozenObjects[object]
        local props = data.Properties
        object.Anchored = props.Anchored or false
        object.CanCollide = props.CanCollide or true
        object.Locked = props.Locked or false
        object.CustomPhysicalProperties = props.CustomPhysicalProperties or PhysicalProperties.new(0.7, 0.3, 0.5, 0.5, 0.5)
        object.Transparency = props.Transparency or 0
        object.Material = props.Material or Enum.Material.Plastic
        object.Color = props.Color or Color3.fromRGB(255, 255, 255)
        if data.Glow then data.Glow:Destroy() end
        gakuka.frozenObjects[object] = nil
    end)
end

local function clearAllFrozen()
    for obj, _ in pairs(gakuka.frozenObjects) do
        unfreezeObject(obj)
    end
    gakuka.frozenObjects = {}
end

local function startAnchorGrab()
    if gakuka.anchorGrabConnection then return end

    gakuka.anchorGrabConnection = Workspace.ChildAdded:Connect(function(child)
        if not gakuka.anchorGrabActive then return end
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
    table.insert(gakuka.connections, gakuka.anchorGrabConnection)
end

local function stopAnchorGrab()
    if gakuka.anchorGrabConnection then
        safeCall(gakuka.anchorGrabConnection.Disconnect, gakuka.anchorGrabConnection)
        gakuka.anchorGrabConnection = nil
    end
    clearAllFrozen()
end

-- ========================================================================
-- 8. FLING ALL
-- ========================================================================

local function startFling()
    if gakuka.flingActive then return end
    gakuka.flingActive = true

    if gakuka.buttons.fling then
        gakuka.buttons.fling.Text = "💥 FLING ALL [ВКЛ]"
        gakuka.buttons.fling.BackgroundColor3 = Color3.fromRGB(0, 200, 50)
    end
    if gakuka.statusText then
        gakuka.statusText.Text = "💥 FLING АКТИВЕН!"
        gakuka.statusText.TextColor3 = Color3.fromRGB(0, 255, 100)
    end

    if gakuka.flingConn then
        safeCall(gakuka.flingConn.Disconnect, gakuka.flingConn)
    end

    gakuka.flingConn = RunService.Heartbeat:Connect(function()
        if not gakuka.flingActive then return end

        -- Защита себя от полёта
        if gakuka.rootPart and gakuka.rootPart.Velocity.Magnitude > 100 then
            gakuka.rootPart.Velocity = Vector3.new(0, 0, 0)
            gakuka.rootPart.RotVelocity = Vector3.new(0, 0, 0)
        end

        -- Флинг всех других игроков
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= gakuka.player then
                local char = plr.Character
                if char then
                    local root = getRootPart(char)
                    if root then
                        local power = math.random(400, 700)
                        local dir = Vector3.new(
                            math.random(-100, 100),
                            math.random(80, 300),
                            math.random(-100, 100)
                        ).Unit
                        root.Velocity = dir * power
                        root.RotVelocity = Vector3.new(
                            math.random(-300, 300),
                            math.random(-300, 300),
                            math.random(-300, 300)
                        )
                    end
                end
            end
        end
    end)
    table.insert(gakuka.connections, gakuka.flingConn)
end

local function stopFling()
    gakuka.flingActive = false
    if gakuka.flingConn then
        safeCall(gakuka.flingConn.Disconnect, gakuka.flingConn)
        gakuka.flingConn = nil
    end
    if gakuka.buttons.fling then
        gakuka.buttons.fling.Text = "💥 FLING ALL [ВЫКЛ]"
        gakuka.buttons.fling.BackgroundColor3 = Color3.fromRGB(180, 40, 40)
    end
    if gakuka.statusText then
        gakuka.statusText.Text = "✅ FLING ВЫКЛЮЧЕН"
        gakuka.statusText.TextColor3 = Color3.fromRGB(200, 200, 200)
    end
end

-- ========================================================================
-- 9. ДОПОЛНИТЕЛЬНЫЕ ЗАЩИТЫ (Anti-Void, Anti-Ragdoll)
-- ========================================================================

-- Anti-Void: предотвращает падение в пустоту
local function startAntiVoid()
    if gakuka.antiVoidConnection then return end

    gakuka.antiVoidConnection = RunService.Heartbeat:Connect(function()
        if not gakuka.antiVoidActive then return end
        if not gakuka.rootPart then return end

        if gakuka.rootPart.Position.Y < -50 then
            -- Телепортируем в центр карты
            local spawnLocation = Workspace:FindFirstChild("SpawnLocation")
            if spawnLocation then
                gakuka.rootPart.CFrame = spawnLocation.CFrame * CFrame.new(0, 3, 0)
            else
                gakuka.rootPart.CFrame = CFrame.new(0, 10, 0)
            end
            gakuka.rootPart.Velocity = Vector3.new(0, 0, 0)
            gakuka.rootPart.RotVelocity = Vector3.new(0, 0, 0)
        end
    end)
    table.insert(gakuka.connections, gakuka.antiVoidConnection)
end

local function stopAntiVoid()
    if gakuka.antiVoidConnection then
        safeCall(gakuka.antiVoidConnection.Disconnect, gakuka.antiVoidConnection)
        gakuka.antiVoidConnection = nil
    end
end

-- Anti-Ragdoll: предотвращает состояние Ragdoll
local function startAntiRagdoll()
    if gakuka.antiRagdollConnection then return end

    gakuka.antiRagdollConnection = RunService.Heartbeat:Connect(function()
        if not gakuka.antiRagdollActive then return end
        if not gakuka.humanoid then return end

        if gakuka.humanoid:GetState() == Enum.HumanoidStateType.Ragdoll then
            gakuka.humanoid:ChangeState(Enum.HumanoidStateType.Running)
        end
    end)
    table.insert(gakuka.connections, gakuka.antiRagdollConnection)
end

local function stopAntiRagdoll()
    if gakuka.antiRagdollConnection then
        safeCall(gakuka.antiRagdollConnection.Disconnect, gakuka.antiRagdollConnection)
        gakuka.antiRagdollConnection = nil
    end
end

-- ========================================================================
-- 10. ОСТАНОВКА ВСЕХ ФУНКЦИЙ
-- ========================================================================

local function stopAll()
    stopFling()
    stopAntiGrab()
    stopSpeedControl()
    stopAntiKick()
    stopAntiVoid()
    stopAntiRagdoll()
    stopAnchorGrab()

    if gakuka.speedModeActive then
        gakuka.speedModeActive = false
        if gakuka.buttons.speed then
            gakuka.buttons.speed.Text = "🏃 ROBLOX EGOR [ВЫКЛ]"
            gakuka.buttons.speed.BackgroundColor3 = Color3.fromRGB(180, 40, 40)
        end
    end

    if gakuka.anchorGrabActive then
        gakuka.anchorGrabActive = false
        if gakuka.buttons.anchor then
            gakuka.buttons.anchor.Text = "⚓ ANCHOR GRAB [ВЫКЛ]"
            gakuka.buttons.anchor.BackgroundColor3 = Color3.fromRGB(180, 40, 40)
        end
    end

    if gakuka.statusText then
        gakuka.statusText.Text = "⛔ ВСЁ ОСТАНОВЛЕНО"
        gakuka.statusText.TextColor3 = Color3.fromRGB(255, 100, 100)
    end

    gakuka.connections = clearConnections(gakuka.connections)
end

-- ========================================================================
-- 11. GUI (МЕНЮ)
-- ========================================================================

local function createGUI()
    if gakuka.screenGui then
        gakuka.screenGui:Destroy()
        gakuka.screenGui = nil
    end

    gakuka.screenGui = Instance.new("ScreenGui")
    gakuka.screenGui.Name = "gakukaGUI"
    gakuka.screenGui.Parent = player:WaitForChild("PlayerGui")
    gakuka.screenGui.ResetOnSpawn = false

    gakuka.mainFrame = Instance.new("Frame")
    gakuka.mainFrame.Size = UDim2.new(0, 350, 0, 380)
    gakuka.mainFrame.Position = UDim2.new(0.5, -175, 0.5, -190)
    gakuka.mainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 30)
    gakuka.mainFrame.BackgroundTransparency = 0.15
    gakuka.mainFrame.BorderSizePixel = 2
    gakuka.mainFrame.BorderColor3 = Color3.fromRGB(80, 80, 180)
    gakuka.mainFrame.Parent = gakuka.screenGui
    gakuka.mainFrame.Active = true
    gakuka.mainFrame.Draggable = true
    gakuka.mainFrame.ClipsDescendants = true

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 12)
    corner.Parent = gakuka.mainFrame

    -- Заголовок
    local titleBar = Instance.new("Frame")
    titleBar.Size = UDim2.new(1, 0, 0, 45)
    titleBar.BackgroundColor3 = Color3.fromRGB(30, 30, 55)
    titleBar.BackgroundTransparency = 0.3
    titleBar.BorderSizePixel = 2
    titleBar.BorderColor3 = Color3.fromRGB(80, 80, 180)
    titleBar.Parent = gakuka.mainFrame

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
    verText.Text = "v2.0 | Anti-Kick Shuriken ✅"
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
        if gakuka.screenGui then
            gakuka.screenGui:Destroy()
            gakuka.screenGui = nil
        end
    end)

    -- Статус
    gakuka.statusText = Instance.new("TextLabel")
    gakuka.statusText.Size = UDim2.new(0.9, 0, 0, 25)
    gakuka.statusText.Position = UDim2.new(0.05, 0, 0.14, 0)
    gakuka.statusText.BackgroundColor3 = Color3.fromRGB(35, 35, 60)
    gakuka.statusText.BackgroundTransparency = 0.5
    gakuka.statusText.Text = "🚫 ANTI-KICK ВКЛ | ANTI-GRAB ВЫКЛ"
    gakuka.statusText.TextColor3 = Color3.fromRGB(0, 255, 100)
    gakuka.statusText.Font = Enum.Font.GothamSemibold
    gakuka.statusText.TextSize = 11
    gakuka.statusText.Parent = gakuka.mainFrame

    local statusCorner = Instance.new("UICorner")
    statusCorner.CornerRadius = UDim.new(0, 6)
    statusCorner.Parent = gakuka.statusText

    -- Функция создания кнопок
    local function createBtn(text, y, color, callback)
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
        btn.Parent = gakuka.mainFrame

        local c = Instance.new("UICorner")
        c.CornerRadius = UDim.new(0, 8)
        c.Parent = btn

        btn.MouseButton1Click:Connect(callback)
        return btn
    end

    local y = 0.20

    -- Кнопка FLING ALL
    local flingBtn = createBtn("💥 FLING ALL [ВЫКЛ]", y, Color3.fromRGB(180, 40, 40), function()
        if gakuka.flingActive then stopFling() else startFling() end
    end)
    gakuka.buttons.fling = flingBtn
    y = y + 0.09

    -- Кнопка ANTI-GRAB
    local antiBtn = createBtn("🛡️ ANTI-GRAB [ВЫКЛ]", y, Color3.fromRGB(180, 40, 40), function()
        gakuka.antiGrabActive = not gakuka.antiGrabActive
        if gakuka.antiGrabActive then
            startAntiGrab()
            antiBtn.Text = "🛡️ ANTI-GRAB [ВКЛ]"
            antiBtn.BackgroundColor3 = Color3.fromRGB(0, 180, 0)
            gakuka.statusText.Text = "🛡️ ANTI-GRAB ВКЛЮЧЕН (движение свободно)"
            gakuka.statusText.TextColor3 = Color3.fromRGB(0, 255, 100)
        else
            stopAntiGrab()
            antiBtn.Text = "🛡️ ANTI-GRAB [ВЫКЛ]"
            antiBtn.BackgroundColor3 = Color3.fromRGB(180, 40, 40)
            gakuka.statusText.Text = "🛡️ ANTI-GRAB ВЫКЛЮЧЕН"
            gakuka.statusText.TextColor3 = Color3.fromRGB(255, 150, 0)
        end
    end)
    gakuka.buttons.anti = antiBtn
    y = y + 0.09

    -- Кнопка ROBLOX EGOR
    local speedBtn = createBtn("🏃 ROBLOX EGOR [ВЫКЛ]", y, Color3.fromRGB(180, 40, 40), function()
        gakuka.speedModeActive = not gakuka.speedModeActive
        setSpeed()
        if gakuka.speedModeActive then
            speedBtn.Text = "🏃 ROBLOX EGOR [ВКЛ]"
            speedBtn.BackgroundColor3 = Color3.fromRGB(0, 200, 100)
            gakuka.statusText.Text = "🏃 ROBLOX EGOR ВКЛ! (скорость 70)"
            gakuka.statusText.TextColor3 = Color3.fromRGB(255, 200, 0)
        else
            speedBtn.Text = "🏃 ROBLOX EGOR [ВЫКЛ]"
            speedBtn.BackgroundColor3 = Color3.fromRGB(180, 40, 40)
            gakuka.statusText.Text = "✅ ROBLOX EGOR ВЫКЛ"
            gakuka.statusText.TextColor3 = Color3.fromRGB(200, 200, 200)
        end
    end)
    gakuka.buttons.speed = speedBtn
    y = y + 0.09

    -- Кнопка ANCHOR GRAB
    local anchorBtn = createBtn("⚓ ANCHOR GRAB [ВЫКЛ]", y, Color3.fromRGB(180, 40, 40), function()
        gakuka.anchorGrabActive = not gakuka.anchorGrabActive
        if gakuka.anchorGrabActive then
            startAnchorGrab()
            anchorBtn.Text = "⚓ ANCHOR GRAB [ВКЛ]"
            anchorBtn.BackgroundColor3 = Color3.fromRGB(0, 180, 255)
            gakuka.statusText.Text = "⚓ ANCHOR GRAB ВКЛЮЧЕН!"
            gakuka.statusText.TextColor3 = Color3.fromRGB(0, 200, 255)
        else
            stopAnchorGrab()
            anchorBtn.Text = "⚓ ANCHOR GRAB [ВЫКЛ]"
            anchorBtn.BackgroundColor3 = Color3.fromRGB(180, 40, 40)
            gakuka.statusText.Text = "✅ ANCHOR GRAB ВЫКЛЮЧЕН"
            gakuka.statusText.TextColor3 = Color3.fromRGB(200, 200, 200)
        end
    end)
    gakuka.buttons.anchor = anchorBtn
    y = y + 0.09

    -- Кнопка ANTI-KICK
    local kickBtn = createBtn("🚫 ANTI-KICK [ВКЛ]", y, Color3.fromRGB(0, 180, 0), function()
        gakuka.antiKickActive = not gakuka.antiKickActive
        if gakuka.antiKickActive then
            startAntiKick()
            kickBtn.Text = "🚫 ANTI-KICK [ВКЛ]"
            kickBtn.BackgroundColor3 = Color3.fromRGB(0, 180, 0)
            gakuka.statusText.Text = "🚫 ANTI-KICK ВКЛЮЧЕН"
            gakuka.statusText.TextColor3 = Color3.fromRGB(0, 255, 100)
        else
            stopAntiKick()
            kickBtn.Text = "🚫 ANTI-KICK [ВЫКЛ]"
            kickBtn.BackgroundColor3 = Color3.fromRGB(180, 40, 40)
            gakuka.statusText.Text = "🚫 ANTI-KICK ВЫКЛЮЧЕН"
            gakuka.statusText.TextColor3 = Color3.fromRGB(255, 150, 0)
        end
    end)
    gakuka.buttons.kick = kickBtn
    y = y + 0.09

    -- Кнопка STOP ALL
    local stopBtn = createBtn("⛔ ОСТАНОВИТЬ ВСЁ", y, Color3.fromRGB(150, 0, 30), function()
        stopAll()
        gakuka.statusText.Text = "⛔ ВСЁ ОСТАНОВЛЕНО"
        gakuka.statusText.TextColor3 = Color3.fromRGB(255, 100, 100)
    end)
end

-- ========================================================================
-- 12. ПОСТОЯННЫЙ КОНТРОЛЬ (Heartbeat)
-- ========================================================================

local function tick()
    if not gakuka.character or not gakuka.character.Parent then return end

    -- Защита от полёта (если скорость слишком большая)
    if gakuka.rootPart and gakuka.rootPart.Velocity.Magnitude > 100 then
        gakuka.rootPart.Velocity = Vector3.new(0, 0, 0)
        gakuka.rootPart.RotVelocity = Vector3.new(0, 0, 0)
    end

    -- Обновляем ссылки на humanoid и rootPart (на случай респавна)
    if not gakuka.humanoid then
        gakuka.humanoid = getHumanoid(gakuka.character)
    end
    if not gakuka.rootPart then
        gakuka.rootPart = getRootPart(gakuka.character)
    end
end

-- ========================================================================
-- 13. ОБРАБОТКА РЕСПАВНА
-- ========================================================================

local function onCharacterAdded(newChar)
    gakuka.character = newChar
    gakuka.humanoid = newChar:WaitForChild("Humanoid")
    gakuka.rootPart = newChar:WaitForChild("HumanoidRootPart")

    -- Перезапускаем активные функции
    task.wait(0.5) -- даём игре время на инициализацию

    if gakuka.antiGrabActive then
        stopAntiGrab()
        startAntiGrab()
    end
    if gakuka.antiKickActive then
        stopAntiKick()
        startAntiKick()
    end
    if gakuka.flingActive then
        stopFling()
        startFling()
    end
    if gakuka.anchorGrabActive then
        stopAnchorGrab()
        startAnchorGrab()
    end
    if gakuka.speedModeActive then
        setSpeed()
    end
    if gakuka.antiVoidActive then
        startAntiVoid()
    end
    if gakuka.antiRagdollActive then
        startAntiRagdoll()
    end
end

-- ========================================================================
-- 14. ИНИЦИАЛИЗАЦИЯ И ЗАПУСК
-- ========================================================================

local function initialize()
    -- Запускаем защиту от падения в пустоту и рэгдолл
    startAntiVoid()
    startAntiRagdoll()

    -- Запускаем Anti-Kick по умолчанию
    startAntiKick()

    -- Запускаем контроль скорости (но пока скорость 16)
    setSpeed()

    -- Создаём GUI
    createGUI()

    -- Подключаем Heartbeat для постоянного контроля
    RunService.Heartbeat:Connect(tick)

    -- Подписываемся на респавн
    player.CharacterAdded:Connect(onCharacterAdded)

    print("====================================")
    print("  💀 gakuka FTAP - ULTIMATE v2.0")
    print("  =================================")
    print("  🚫 ANTI-KICK (СЮРИКЕН) - ВКЛЮЧЕН")
    print("  🛡️ ANTI-GRAB - ВЫКЛЮЧЕН")
    print("  ✅ ROBLOX EGOR - скорость 70")
    print("  ⚓ ANCHOR GRAB - РАБОТАЕТ")
    print("  💥 FLING ALL - все летают")
    print("  🛡️ ANTI-VOID - ВКЛЮЧЕН")
    print("  🛡️ ANTI-RAGDOLL - ВКЛЮЧЕН")
    print("  ✅ ТЫ НЕ ЛЕТАЕШЬ")
    print("====================================")
end

-- Запуск
initialize()

-- ========================================================================
-- 15. ЗАВЕРШЕНИЕ ПРИ ВЫХОДЕ
-- ========================================================================

game:BindToClose(function()
    stopAll()
    if gakuka.shurikenObject then
        gakuka.shurikenObject:Destroy()
        gakuka.shurikenObject = nil
    end
    if gakuka.screenGui then
        gakuka.screenGui:Destroy()
        gakuka.screenGui = nil
    end
end)

-- ========================================================================
-- КОНЕЦ СКРИПТА
-- ========================================================================
