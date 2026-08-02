-- gakuka FTAP v0.1 beta (исправленный)
-- Убрана лишняя кнопка "МЕНЮ"
-- Anti-Kick теперь спавнит сюрикен только если его нет или он не приклеен к телу

-- Загрузка библиотеки Obsidian
local repo = "https://raw.githubusercontent.com/deividcomsono/Obsidian/main/"
local Library = loadstring(game:HttpGet(repo .. "Library.lua"))()
local ThemeManager = loadstring(game:HttpGet(repo .. "addons/ThemeManager.lua"))()
local SaveManager = loadstring(game:HttpGet(repo .. "addons/SaveManager.lua"))()
local Options = Library.Options
local Toggles = Library.Toggles
Library.ForceCheckbox = false

-- Создание окна (меню)
local Window = Library:CreateWindow({
    Title = "💀 gakuka FTAP",
    Footer = "v0.1 beta",
    NotifySide = "Right",
    ShowCustomCursor = true,
})

-- Вкладки
local Tabs = {
    Defense = Window:AddTab("Defense", "shield"),
    Target = Window:AddTab("Target", "crosshair"),
    Grab = Window:AddTab("Grab", "hand"),
    Player = Window:AddTab("Player", "user"),
    Misc = Window:AddTab("Misc", "layers"),
    ["UI Settings"] = Window:AddTab("UI Settings", "settings")
}

-- Группы вкладок
local DefenseGroup = Tabs.Defense:AddLeftGroupbox("Защита")
local TargetGroup = Tabs.Target:AddLeftGroupbox("Цель")
local GrabGroup = Tabs.Grab:AddLeftGroupbox("Основные")
local PlayerGroup = Tabs.Player:AddLeftGroupbox("Движение")
local MiscGroup = Tabs.Misc:AddLeftGroupbox("Общее")

-- ========================================
-- ГЛОБАЛЬНЫЕ ПЕРЕМЕННЫЕ
-- ========================================
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

-- Состояния
local flingActive = false
local antiGrabActive = false
local speedModeActive = false
local anchorGrabActive = false
local antiKickActive = false
local kickNotifierActive = true
local superThrowActive = false
local jerkOffActive = false
local thirdPersonActive = false
local frozenObjects = {}

-- ========================================
-- ВСПОМОГАТЕЛЬНЫЕ ФУНКЦИИ
-- ========================================
local function notify(title, content, duration)
    Library:Notify({
        Title = title or "Notification",
        Description = content or "",
        Time = duration or 5,
    })
end

-- ========================================
-- ANTI-GRAB
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
-- ANTI-KICK (ШУРИКЕН)
-- ========================================
local antiKickConnection = nil

local function clearAntiKickShuriken()
    local inv = workspace:FindFirstChild(player.Name .. "SpawnedInToys")
    local destroyrem = ReplicatedStorage:FindFirstChild("MenuToys") and ReplicatedStorage.MenuToys:FindFirstChild("DestroyToy")
    if inv and destroyrem then
        for _, v in pairs(inv:GetChildren()) do
            if v.Name == "AntiKick" or v.Name == "NinjaShuriken" then
                pcall(function() destroyrem:FireServer(v) end)
            end
        end
    end
end

local function hasShurikenAttached()
    local char = player.Character
    if not char then return false end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return false end
    local firePart = hrp:FindFirstChild("FirePlayerPart")
    if not firePart then return false end
    -- Проверяем, есть ли у FirePlayerPart приклеенные части от сюрикена
    for _, child in ipairs(firePart:GetChildren()) do
        if child:IsA("Weld") or child:IsA("WeldConstraint") then
            local otherPart = child.Part0 or child.Part1
            if otherPart and otherPart.Parent and otherPart.Parent.Name == "AntiKick" then
                return true
            end
        end
    end
    -- Альтернатива: проверить папку с игрушками на наличие приклеенного сюрикена
    local inv = workspace:FindFirstChild(player.Name .. "SpawnedInToys")
    if inv then
        local shuriken = inv:FindFirstChild("AntiKick")
        if shuriken and shuriken:FindFirstChild("StickyPart") then
            local sp = shuriken.StickyPart
            if sp:FindFirstChild("StickyWeld") and sp.StickyWeld.Part1 then
                return true
            end
        end
    end
    return false
end

local function startAntiKick()
    if antiKickConnection then return end
    antiKickConnection = RunService.Heartbeat:Connect(function()
        if not antiKickActive then return end
        -- Если сюрикен уже приклеен, не спавним новый
        if hasShurikenAttached() then
            return
        end
        pcall(function()
            local char = player.Character
            if not char or not char:FindFirstChild("HumanoidRootPart") then return end
            local hrp = char.HumanoidRootPart
            local canSpawn = player:FindFirstChild("CanSpawnToy")
            if not canSpawn or not canSpawn.Value then return end

            local inv = workspace:FindFirstChild(player.Name .. "SpawnedInToys")
            local shuriken = inv and inv:FindFirstChild("NinjaShuriken")
            if not shuriken then
                local spawnRemote = ReplicatedStorage.MenuToys.SpawnToyRemoteFunction
                pcall(function()
                    spawnRemote:InvokeServer("NinjaShuriken", hrp.CFrame * CFrame.new(0, 12, 20), Vector3.new())
                end)
                task.wait(0.2)
                inv = workspace:FindFirstChild(player.Name .. "SpawnedInToys")
                shuriken = inv and inv:FindFirstChild("NinjaShuriken")
                if shuriken then shuriken.Name = "AntiKick" end
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
-- УВЕДОМЛЕНИЯ О КИКАХ
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

local function notifyKick(displayName)
    Library:Notify({
        Title = "⚠️ Кикнут",
        Description = displayName .. " был кикнут чёрной дырой!",
        Time = 4,
    })
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
    kickNotifierConnection = Workspace.ChildAdded:Connect(function(obj)
        if not kickNotifierActive then return end
        if obj.Name == "BlackHoleKick" or obj.Name == "BlackHoleDetected" then
            task.wait(0.05)
            local pos = obj:IsA("BasePart") and obj.Position or (obj:IsA("Model") and obj.PrimaryPart and obj.PrimaryPart.Position)
            if not pos then return end
            local plr = getClosestPlayer(pos)
            if plr then
                playKickSound()
                notifyKick(plr.DisplayName)
            end
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
-- ROBLOX EGOR
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
-- THIRD PERSON VIEW
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
    if thirdPersonActive then enableThirdPerson() else disableThirdPerson() end
end

-- ========================================
-- SUPER THROW
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
-- ANCHOR GRAB
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
-- FLING GRAB
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
-- JERK OFF
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
-- ОСТАНОВКА ВСЕГО
-- ========================================
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
    Library:Notify({
        Title = "⛔ Всё остановлено",
        Description = "Все функции отключены",
        Time = 2,
    })
end

-- ========================================
-- ДОБАВЛЯЕМ TOGGLES В МЕНЮ
-- ========================================
-- Grab Group
GrabGroup:AddToggle("FlingGrabToggle", {
    Text = "💥 FLING GRAB",
    Default = false,
    Callback = function(value)
        flingActive = value
        if value then startFling() else stopFling() end
    end
})

GrabGroup:AddToggle("AnchorGrabToggle", {
    Text = "⚓ ANCHOR GRAB",
    Default = false,
    Callback = function(value)
        anchorGrabActive = value
        if value then startAnchorGrab() else stopAnchorGrab() end
    end
})

GrabGroup:AddToggle("SuperThrowToggle", {
    Text = "⚡ SUPER THROW",
    Default = false,
    Callback = function(value)
        superThrowActive = value
        if value then startSuperThrow() else stopSuperThrow() end
    end
})

-- Defense Group
DefenseGroup:AddToggle("AntiGrabToggle", {
    Text = "🛡️ ANTI-GRAB",
    Default = false,
    Callback = function(value)
        antiGrabActive = value
        if value then startAntiGrab() else stopAntiGrab() end
    end
})

DefenseGroup:AddToggle("AntiKickToggle", {
    Text = "🔮 ANTI-KICK",
    Default = false,
    Callback = function(value)
        antiKickActive = value
        if value then startAntiKick() else stopAntiKick() end
    end
})

DefenseGroup:AddToggle("NotifierToggle", {
    Text = "🔔 УВЕДОМЛЕНИЯ",
    Default = true,
    Callback = function(value)
        kickNotifierActive = value
        if value then startKickNotifier() else stopKickNotifier() end
    end
})

-- Player Group
PlayerGroup:AddToggle("RobloxEgorToggle", {
    Text = "🏃 ROBLOX EGOR",
    Default = false,
    Callback = function(value)
        speedModeActive = value
        setSpeed()
    end
})

PlayerGroup:AddToggle("ThirdPersonToggle", {
    Text = "👁️ 3RD PERSON",
    Default = false,
    Callback = function(value)
        thirdPersonActive = value
        if value then enableThirdPerson() else disableThirdPerson() end
    end
})

-- Misc Group
MiscGroup:AddToggle("JerkOffToggle", {
    Text = "🔞 JERK OFF",
    Default = false,
    Callback = function(value)
        jerkOffActive = value
        if value then startJerkOff() else stopJerkOff() end
    end
})

MiscGroup:AddButton({
    Text = "⛔ ОСТАНОВИТЬ ВСЁ",
    Func = function()
        stopAll()
        Toggles.FlingGrabToggle:SetValue(false)
        Toggles.AnchorGrabToggle:SetValue(false)
        Toggles.SuperThrowToggle:SetValue(false)
        Toggles.AntiGrabToggle:SetValue(false)
        Toggles.AntiKickToggle:SetValue(false)
        Toggles.NotifierToggle:SetValue(true)
        Toggles.RobloxEgorToggle:SetValue(false)
        Toggles.ThirdPersonToggle:SetValue(false)
        Toggles.JerkOffToggle:SetValue(false)
    end
})

-- ========================================
-- НАСТРОЙКИ UI
-- ========================================
local MenuGroup = Tabs["UI Settings"]:AddLeftGroupbox("Menu")
MenuGroup:AddButton("Unload", function()
    Library:Unload()
end)
MenuGroup:AddLabel("Menu Keybind"):AddKeyPicker("MenuKeybind", {
    Default = "RightShift",
    NoUI = true,
    Text = "Menu keybind"
})
Library.ToggleKeybind = Options.MenuKeybind

ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({
    "MenuKeybind"
})
ThemeManager:SetFolder("gakuka")
SaveManager:SetFolder("gakuka/Configs")
SaveManager:BuildConfigSection(Tabs["UI Settings"])
ThemeManager:ApplyToTab(Tabs["UI Settings"])

-- ========================================
-- ИНИЦИАЛИЗАЦИЯ
-- ========================================
setSpeed()
startKickNotifier() -- уведомления включены по умолчанию

-- Постоянный контроль
local function tick()
    if not character or not character.Parent then return end
    if rootPart and rootPart.Velocity.Magnitude > 100 then
        rootPart.Velocity = Vector3.new(0, 0, 0)
        rootPart.RotVelocity = Vector3.new(0, 0, 0)
    end
end
RunService.Heartbeat:Connect(tick)

-- Обработка респавна
player.CharacterAdded:Connect(function(newChar)
    character = newChar
    humanoid = character:WaitForChild("Humanoid")
    rootPart = character:WaitForChild("HumanoidRootPart")
    task.wait(0.5)
    setSpeed()
    if antiGrabActive then startAntiGrab() end
    if antiKickActive then startAntiKick() end
    if kickNotifierActive then startKickNotifier() end
    if superThrowActive then startSuperThrow() end
    if jerkOffActive then startJerkOff() end
    if thirdPersonActive then enableThirdPerson() end
    if flingActive then stopFling(); startFling() end
    if anchorGrabActive then stopAnchorGrab(); startAnchorGrab() end
end)

print("====================================")
print("  💀 gakuka FTAP v0.1 beta")
print("  =================================")
print("  ✅ Меню в стиле Ragalic Mobile")
print("  ✅ Anti-Kick по умолчанию ВЫКЛЮЧЕН")
print("  ✅ Anti-Kick спавнит сюрикен только если он не приклеен")
print("  ✅ Убрана лишняя кнопка МЕНЮ")
print("  ✅ Все функции: FLING GRAB, ANTI-GRAB, ANTI-KICK, ROBLOX EGOR, SUPER THROW, ANCHOR GRAB, JERK OFF, уведомления")
print("====================================")
