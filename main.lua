--[[
    TRXSH HUB - BY HENRIQSZ7
    VERSÃO: BLACK & GREY EDITION
    LOGICA ORIGINAL PRESERVADA - SEM SIMPLIFICAÇÃO
]]

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local VirtualUser = game:GetService("VirtualUser")
local StatsService = game:GetService("Stats")
local SoundService = game:GetService("SoundService")

local localPlayer = Players.LocalPlayer
local character = localPlayer.Character or localPlayer.CharacterAdded:Wait()
local humanoid = character:FindFirstChildWhichIsA("Humanoid")
local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
local bag = localPlayer:WaitForChild("States"):WaitForChild("Bag")
local bagSizeLevel = localPlayer:WaitForChild("Stats"):WaitForChild("BagSizeLevel"):WaitForChild("CurrentAmount")
local robEvent = ReplicatedStorage:WaitForChild("GeneralEvents"):WaitForChild("Rob")
local targetPosition = CFrame.new(1636.62537, 104.349976, -1736.184)

-- [[[ LOGICA ANTI-MORTE ORIGINAL ]]] --
local function ensureAntiDeath(char)
    local ok, h = pcall(function()
        local hum = char:FindFirstChildWhichIsA("Humanoid")
        if not hum then return end
        local cloned = hum:Clone()
        cloned.Parent = char
        localPlayer.Character = nil
        cloned:SetStateEnabled(Enum.HumanoidStateType.Dead, false)
        cloned:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
        cloned:SetStateEnabled(Enum.HumanoidStateType.Physics, false)
        hum:Destroy()
        localPlayer.Character = char
        local cam = Workspace.CurrentCamera
        cam.CameraSubject = cloned
        cam.CFrame = cam.CFrame
        cloned.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
        local animate = char:FindFirstChild("Animate")
        if animate then
            animate.Disabled = true
            task.wait(0.07)
            animate.Disabled = false
        end
        cloned.Health = cloned.MaxHealth
        humanoid = cloned
        humanoidRootPart = char:FindFirstChild("HumanoidRootPart")
    end)
    return ok
end

ensureAntiDeath(character)

localPlayer.Idled:Connect(function()
    VirtualUser:CaptureController()
    VirtualUser:ClickButton2(Vector2.new())
end)

-- Limpeza de UI Antiga
if game.CoreGui:FindFirstChild("TRXSH_HUB_MAIN") then
    game.CoreGui.TRXSH_HUB_MAIN:Destroy()
end

getgenv().AntiAfkExecuted = true
getgenv().AutoFarmActive = false
local FAST_LOOP_INTERVAL = 0.08

local function formatNumber(n)
    local s = tostring(n)
    while true do
        local k
        s, k = string.gsub(s, "^(-?%d+)(%d%d%d)", "%1,%2")
        if k == 0 then break end
    end
    return s
end

-- [[[ SISTEMA DE CACHE ORIGINAL ]]] --
local cashRegisters = {}
local safes = {}
local function clearTable(t)
    for i = 1, #t do t[i] = nil end
end

local function updateCaches()
    clearTable(cashRegisters)
    clearTable(safes)
    for _, child in ipairs(Workspace:GetChildren()) do
        if child:IsA("Model") then
            if child.Name == "CashRegister" then
                table.insert(cashRegisters, child)
            elseif child.Name == "Safe" then
                table.insert(safes, child)
            end
        end
    end
end
updateCaches()

Workspace.ChildAdded:Connect(function(child)
    if child:IsA("Model") then
        if child.Name == "CashRegister" then
            table.insert(cashRegisters, child)
        elseif child.Name == "Safe" then
            table.insert(safes, child)
        end
    end
end)

Workspace.ChildRemoved:Connect(function(child)
    if child:IsA("Model") then
        if child.Name == "CashRegister" then
            for i = #cashRegisters, 1, -1 do
                if cashRegisters[i] == child then table.remove(cashRegisters, i) end
            end
        elseif child.Name == "Safe" then
            for i = #safes, 1, -1 do
                if safes[i] == child then table.remove(safes, i) end
            end
        end
    end
end)

-- [[[ MOVIMENTAÇÃO E ROUBO ORIGINAIS ]]] --
local function moveTo(cf)
    if humanoidRootPart and cf then
        humanoidRootPart.CFrame = cf
    end
end

local function findNearestCashRegister()
    if not humanoidRootPart then return nil end
    local best, bestDist = nil, math.huge
    for _, reg in ipairs(cashRegisters) do
        if reg and reg.Parent and reg:IsDescendantOf(Workspace) then
            local openPart = reg:FindFirstChild("Open")
            if openPart then
                local d = (humanoidRootPart.Position - openPart.Position).Magnitude
                if d < bestDist then
                    bestDist = d
                    best = {model = reg, openPart = openPart}
                end
            end
        end
    end
    return best
end

local function findNearestSafe()
    if not humanoidRootPart then return nil end
    local best, bestDist = nil, math.huge
    for _, s in ipairs(safes) do
        if s and s.Parent and s:IsDescendantOf(Workspace) and s:FindFirstChild("Amount") and s.Amount.Value > 0 then
            local safePart = s:FindFirstChild("Safe")
            if safePart then
                local d = (humanoidRootPart.Position - safePart.Position).Magnitude
                if d < bestDist then
                    bestDist = d
                    best = {model = s, safePart = safePart}
                end
            end
        end
    end
    return best
end

local function attemptRegister(regData)
    if not regData or not regData.model then return false end
    local ok = pcall(function()
        moveTo(regData.openPart.CFrame)
        robEvent:FireServer("Register", {
            Part = regData.model:FindFirstChild("Union"),
            OpenPart = regData.openPart,
            ActiveValue = regData.model:FindFirstChild("Active"),
            Active = true
        })
    end)
    return ok
end

local function attemptSafe(sData)
    if not sData or not sData.model then return false end
    local ok = pcall(function()
        moveTo(sData.safePart.CFrame)
        local openFlag = sData.model:FindFirstChild("Open")
        if openFlag and openFlag.Value then
            robEvent:FireServer("Safe", sData.model)
        else
            local openSafe = sData.model:FindFirstChild("OpenSafe")
            if openSafe then
                openSafe:FireServer("Completed")
            end
            robEvent:FireServer("Safe", sData.model)
        end
    end)
    return ok
end

local function farmOnce()
    if bag.Value >= bagSizeLevel.Value then
        moveTo(targetPosition)
        return false
    end
    local reg = findNearestCashRegister()
    if reg then
        if attemptRegister(reg) then return true end
    end
    local s = findNearestSafe()
    if s then
        if attemptSafe(s) then return true end
    end
    return false
end

-- [[[ SISTEMA DE NOTIFICAÇÃO ]]] --
local function createNotifierGUI()
    local gui = Instance.new("ScreenGui")
    gui.Name = "TRXSHNotifier"
    gui.ResetOnSpawn = false
    gui.Parent = game.CoreGui
    local container = Instance.new("Frame")
    container.Name = "Container"
    container.AnchorPoint = Vector2.new(0.5, 0)
    container.Position = UDim2.new(0.5, 0, 0, 6)
    container.Size = UDim2.new(0, 380, 0, 0)
    container.BackgroundTransparency = 1
    container.Parent = gui
    return gui, container
end

local notifierGui, notifierContainer = createNotifierGUI()
local activeNotifiers = {}
local function repositionNotifiers()
    for i, v in ipairs(activeNotifiers) do
        if v and v.frame then
            local targetY = 6 + (i - 1) * 56
            TweenService:Create(v.frame, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Position = UDim2.new(0.5, 0, 0, targetY)}):Play()
        end
    end
end

local function notify(text, timeSec)
    timeSec = timeSec or 3
    if not notifierContainer or notifierContainer.Parent == nil then
        notifierGui, notifierContainer = createNotifierGUI()
    end
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 340, 0, 50)
    frame.Position = UDim2.new(0.5, 0, 0, -60)
    frame.AnchorPoint = Vector2.new(0.5, 0)
    frame.BackgroundTransparency = 1
    frame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    frame.BorderSizePixel = 0
    frame.Parent = notifierContainer
    local uic = Instance.new("UICorner", frame)
    uic.CornerRadius = UDim.new(0, 10)
    local uistroke = Instance.new("UIStroke", frame)
    uistroke.Thickness = 1
    uistroke.Color = Color3.fromRGB(60, 60, 60)
    local txt = Instance.new("TextLabel", frame)
    txt.Size = UDim2.new(1, -20, 1, 0)
    txt.Position = UDim2.new(0, 10, 0, 0)
    txt.BackgroundTransparency = 1
    txt.Text = tostring(text)
    txt.Font = Enum.Font.GothamBold
    txt.TextSize = 15
    txt.TextColor3 = Color3.fromRGB(255, 255, 255)
    txt.TextXAlignment = Enum.TextXAlignment.Left
    txt.TextTransparency = 1
    local snd = Instance.new("Sound", frame)
    snd.SoundId = "rbxassetid://3442983711"
    snd.Volume = 0.5
    snd:Play()
    table.insert(activeNotifiers, {frame = frame})
    repositionNotifiers()
    TweenService:Create(frame, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Position = UDim2.new(0.5, 0, 0, 6 + (#activeNotifiers - 1) * 56), BackgroundTransparency = 0}):Play()
    TweenService:Create(txt, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {TextTransparency = 0}):Play()
    spawn(function()
        task.wait(timeSec)
        local disappearTween = TweenService:Create(frame, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {Position = UDim2.new(0.5, 0, 0, -60), BackgroundTransparency = 1})
        disappearTween:Play()
        TweenService:Create(txt, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {TextTransparency = 1}):Play()
        disappearTween.Completed:Wait()
        frame:Destroy()
        for i = #activeNotifiers, 1, -1 do
            if activeNotifiers[i] and activeNotifiers[i].frame == frame then table.remove(activeNotifiers, i) end
        end
        repositionNotifiers()
    end)
end

-- [[[ NOVA INTERFACE UI TRXSH - BLACK & GREY ]]] --
local MainUI = Instance.new("ScreenGui")
MainUI.Name = "TRXSH_HUB_MAIN"
MainUI.Parent = game.CoreGui
MainUI.ResetOnSpawn = false

local MainFrame = Instance.new("Frame", MainUI)
MainFrame.Size = UDim2.new(0, 380, 0, 220)
MainFrame.Position = UDim2.new(0.5, -190, 0.5, -110)
MainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
MainFrame.BorderSizePixel = 0
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 12)
local MainStroke = Instance.new("UIStroke", MainFrame)
MainStroke.Color = Color3.fromRGB(45, 45, 45)
MainStroke.Thickness = 2

local Header = Instance.new("Frame", MainFrame)
Header.Size = UDim2.new(1, 0, 0, 45)
Header.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
Header.BorderSizePixel = 0
Instance.new("UICorner", Header).CornerRadius = UDim.new(0, 12)

local Title = Instance.new("TextLabel", Header)
Title.Size = UDim2.new(0.5, 0, 1, 0)
Title.Position = UDim2.new(0, 15, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = "TRXSH HUB"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.Font = Enum.Font.GothamBlack
Title.TextSize = 16
Title.TextXAlignment = "Left"

local Credits = Instance.new("TextLabel", Header)
Credits.Size = UDim2.new(0.4, 0, 1, 0)
Credits.Position = UDim2.new(0.55, -40, 0, 0)
Credits.BackgroundTransparency = 1
Credits.Text = "by henriqsz7"
Credits.TextColor3 = Color3.fromRGB(120, 120, 120)
Credits.Font = Enum.Font.Gotham
Credits.TextSize = 11
Credits.TextXAlignment = "Right"

local CloseBtn = Instance.new("TextButton", Header)
CloseBtn.Size = UDim2.new(0, 32, 0, 32)
CloseBtn.Position = UDim2.new(1, -38, 0.5, -16)
CloseBtn.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
CloseBtn.Text = "X"
CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseBtn.Font = Enum.Font.GothamBlack
CloseBtn.TextSize = 14
Instance.new("UICorner", CloseBtn)

local Container = Instance.new("Frame", MainFrame)
Container.Size = UDim2.new(1, -20, 1, -60)
Container.Position = UDim2.new(0, 10, 0, 50)
Container.BackgroundTransparency = 1

local StatsFrame = Instance.new("Frame", Container)
StatsFrame.Size = UDim2.new(0.6, 0, 1, 0)
StatsFrame.BackgroundTransparency = 1

local function makeLabel(txt, y)
    local l = Instance.new("TextLabel", StatsFrame)
    l.Size = UDim2.new(1, 0, 0, 22)
    l.Position = UDim2.new(0, 5, 0, y)
    l.BackgroundTransparency = 1
    l.TextColor3 = Color3.fromRGB(200, 200, 200)
    l.Font = Enum.Font.GothamBold
    l.TextSize = 13
    l.TextXAlignment = "Left"
    l.Text = txt
    return l
end

local CashLabel = makeLabel("Earnings: $0", 0)
local FPSLabel = makeLabel("FPS: ...", 25)
local TimerLabel = makeLabel("Time: 00:00:00", 50)
local StatusLabel = makeLabel("Status: Stopped", 75)

local ButtonsFrame = Instance.new("Frame", Container)
ButtonsFrame.Size = UDim2.new(0.4, 0, 1, 0)
ButtonsFrame.Position = UDim2.new(0.6, 0, 0, 0)
ButtonsFrame.BackgroundTransparency = 1

local StartBtn = Instance.new("TextButton", ButtonsFrame)
StartBtn.Size = UDim2.new(1, -5, 0, 45)
StartBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
StartBtn.Text = "START"
StartBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
StartBtn.Font = Enum.Font.GothamBlack
StartBtn.TextSize = 14
Instance.new("UICorner", StartBtn)
local StartStroke = Instance.new("UIStroke", StartBtn)
StartStroke.Color = Color3.fromRGB(80, 80, 80)

local StopBtn = Instance.new("TextButton", ButtonsFrame)
StopBtn.Size = UDim2.new(1, -5, 0, 35)
StopBtn.Position = UDim2.new(0, 0, 0, 55)
StopBtn.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
StopBtn.Text = "STOP"
StopBtn.TextColor3 = Color3.fromRGB(150, 150, 150)
StopBtn.Font = Enum.Font.GothamBold
StopBtn.TextSize = 12
Instance.new("UICorner", StopBtn)

-- Dragging Functionality
do
    local dragging, dragStart, startPos, currentTween
    Header.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = MainFrame.Position
        end
    end)
    Header.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Position - dragStart
            local target = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
            if currentTween then currentTween:Cancel() end
            currentTween = TweenService:Create(MainFrame, TweenInfo.new(0.06, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {Position = target})
            currentTween:Play()
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
    end)
end

-- Stats Loop (FPS Fix included)
spawn(function()
    while true do
        local dt = RunService.RenderStepped:Wait()
        FPSLabel.Text = "FPS: " .. tostring(math.floor(1 / dt))
        task.wait(0.1) -- Evita travamento visual
    end
end)

local leaderstats = localPlayer:WaitForChild("leaderstats")
local cashStat = leaderstats:WaitForChild("$$")
local initialCash = cashStat.Value
local seconds, minutes, hours = 0, 0, 0

spawn(function()
    while true do
        task.wait(0.9)
        local earned = cashStat.Value - initialCash
        CashLabel.Text = "Earnings: $" .. formatNumber(earned)
    end
end)

spawn(function()
    while true do
        task.wait(1)
        if getgenv().AutoFarmActive then
            seconds = seconds + 1
            if seconds >= 60 then seconds = 0 minutes = minutes + 1 end
            if minutes >= 60 then minutes = 0 hours = hours + 1 end
        end
        TimerLabel.Text = string.format("Time: %02d:%02d:%02d", hours, minutes, seconds)
    end
end)

-- [[[ CONTROLE DE FARM ]]] --
local farmThread
local function startFarming()
    if getgenv().AutoFarmActive then return end
    getgenv().AutoFarmActive = true
    StatusLabel.Text = "Status: Running"
    StatusLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    StartStroke.Color = Color3.fromRGB(255, 255, 255)
    notify("TRXSH HUB Started!", 2.5)
    farmThread = coroutine.create(function()
        while getgenv().AutoFarmActive do
            pcall(farmOnce)
            task.wait(FAST_LOOP_INTERVAL)
        end
    end)
    coroutine.resume(farmThread)
end

local function stopFarming()
    getgenv().AutoFarmActive = false
    StatusLabel.Text = "Status: Stopped"
    StatusLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    StartStroke.Color = Color3.fromRGB(80, 80, 80)
    notify("AutoFarm Stopped", 1.8)
    initialCash = cashStat.Value
    seconds, minutes, hours = 0, 0, 0
end

StartBtn.MouseButton1Click:Connect(startFarming)
StopBtn.MouseButton1Click:Connect(stopFarming)

CloseBtn.MouseButton1Click:Connect(function()
    getgenv().AutoFarmActive = false
    MainUI:Destroy()
    notifierGui:Destroy()
end)

-- Re-setup on death
localPlayer.CharacterAdded:Connect(function(char)
    character = char
    task.wait(0.2)
    humanoidRootPart = character:WaitForChild("HumanoidRootPart")
    ensureAntiDeath(character)
end)

notify("TRXSH HUB Loaded Successfully", 3)
