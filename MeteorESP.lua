--// SERVICES
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local rendering = require(ReplicatedStorage.Game.rendering)
local interpolationBuffer = require(ReplicatedStorage.Game.rendering.interpolationBuffer)

--// PLAYER
local player = Players.LocalPlayer
local char = player.Character or player.CharacterAdded:Wait()
local root = char:WaitForChild("HumanoidRootPart")

player.CharacterAdded:Connect(function(c)
    char = c
    root = c:WaitForChild("HumanoidRootPart")
end)

--// MODULES
local Packets = require(ReplicatedStorage.Modules:WaitForChild("Packets"))

--// SETTINGS
local AUTO_SWING = false
local STICK_TO_TARGET = false
local SHOW_ESP = true

local lastSwing = 0

--// GUI
local gui = Instance.new("ScreenGui", game.CoreGui)
gui.Name = "MeteorFarmUI"

local frame = Instance.new("Frame", gui)
frame.Size = UDim2.new(0, 260, 0, 200)
frame.Position = UDim2.new(0.3, 0, 0.3, 0)
frame.BackgroundColor3 = Color3.fromRGB(25,25,25)
frame.BorderSizePixel = 0
Instance.new("UICorner", frame)

local function makeBtn(txt, y)
    local b = Instance.new("TextButton", frame)
    b.Size = UDim2.new(0.9,0,0,25)
    b.Position = UDim2.new(0.05,0,0,y)
    b.Text = txt
    b.BackgroundColor3 = Color3.fromRGB(40,40,40)
    b.TextColor3 = Color3.new(1,1,1)
    b.Font = Enum.Font.Gotham
    b.TextSize = 13
    Instance.new("UICorner", b)
    return b
end

local swingBtn = makeBtn("Auto Swing: OFF", 20)
local moveBtn = makeBtn("Move To Target: OFF", 50)
local espBtn = makeBtn("Core ESP: ON", 80)

-- toggle buttons
swingBtn.MouseButton1Click:Connect(function()
    AUTO_SWING = not AUTO_SWING
    swingBtn.Text = "Auto Swing: " .. (AUTO_SWING and "ON" or "OFF")
end)

moveBtn.MouseButton1Click:Connect(function()
    STICK_TO_TARGET = not STICK_TO_TARGET
    moveBtn.Text = "Move To Target: " .. (STICK_TO_TARGET and "ON" or "OFF")
end)

espBtn.MouseButton1Click:Connect(function()
    SHOW_ESP = not SHOW_ESP
    espBtn.Text = "Core ESP: " .. (SHOW_ESP and "ON" or "OFF")
end)

--// HIDE GUI BUTTON
local toggleGui = Instance.new("ScreenGui", game.CoreGui)
local toggleBtn = Instance.new("TextButton", toggleGui)

toggleBtn.Size = UDim2.new(0,120,0,30)
toggleBtn.Position = UDim2.new(0,20,0.5,0)
toggleBtn.Text = "Hide UI"
toggleBtn.BackgroundColor3 = Color3.fromRGB(30,30,30)
toggleBtn.TextColor3 = Color3.new(1,1,1)
toggleBtn.Font = Enum.Font.GothamBold
toggleBtn.TextSize = 13
Instance.new("UICorner", toggleBtn)

toggleBtn.MouseButton1Click:Connect(function()
    gui.Enabled = not gui.Enabled
    toggleBtn.Text = gui.Enabled and "Hide UI" or "Show UI"
end)

-- DRAG FUNCTION
local function drag(obj)
    local dragging, start, pos

    obj.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            start = i.Position
            pos = obj.Position
        end
    end)

    obj.InputChanged:Connect(function(i)
        if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = i.Position - start
            obj.Position = UDim2.new(pos.X.Scale, pos.X.Offset + delta.X, pos.Y.Scale, pos.Y.Offset + delta.Y)
        end
    end)

    obj.InputEnded:Connect(function()
        dragging = false
    end)
end

drag(frame)
drag(toggleBtn)

--// CACHE
local Meteors = {}
local LonelyGods = {}

local function isCore(v)
    return v:IsA("Model") and (v.Name == "Meteor Core" or v.Name == "Crystal Meteor Core")
end

local function isLonelyGod(v)
    return v:IsA("Model") and v.Name == "Lonely God"
end

for _, v in ipairs(Workspace:GetDescendants()) do
    if isCore(v) then table.insert(Meteors, v) end
    if isLonelyGod(v) then table.insert(LonelyGods, v) end
end

Workspace.DescendantAdded:Connect(function(v)
    if isCore(v) then table.insert(Meteors, v) end
    if isLonelyGod(v) then table.insert(LonelyGods, v) end
end)

Workspace.DescendantRemoving:Connect(function(v)
    for i=#Meteors,1,-1 do
        if Meteors[i]==v then table.remove(Meteors,i) end
    end
    for i=#LonelyGods,1,-1 do
        if LonelyGods[i]==v then table.remove(LonelyGods,i) end
    end
end)

--// ESP (ONLY CORES)
local ESP = {}
local folder = Instance.new("Folder", Workspace)

local function getPart(m)
    return m.PrimaryPart or m:FindFirstChildWhichIsA("BasePart")
end

local function createESP(m)
    if ESP[m] then return end
    local part = getPart(m)
    if not part then return end

    local gui = Instance.new("BillboardGui")
    gui.Adornee = part
    gui.Size = UDim2.fromOffset(140,40)
    gui.StudsOffset = Vector3.new(0,4,0)
    gui.AlwaysOnTop = true
    gui.Parent = folder

    local label = Instance.new("TextLabel", gui)
    label.Size = UDim2.fromScale(1,1)
    label.BackgroundTransparency = 1
    label.Text = m.Name
    label.TextScaled = true
    label.Font = Enum.Font.GothamBold
    label.TextColor3 = Color3.fromRGB(255,170,0)
    label.TextStrokeTransparency = 0

    ESP[m] = gui
end

task.spawn(function()
    while true do
        if SHOW_ESP then
            for _, m in ipairs(Meteors) do
                createESP(m)
            end
        else
            for _, g in pairs(ESP) do g:Destroy() end
            ESP = {}
        end

        for m,g in pairs(ESP) do
            if not m or not m.Parent then
                g:Destroy()
                ESP[m]=nil
            end
        end

        task.wait(1)
    end
end)

--// TARGETING
local function getClosest(list)
    local best, dist = nil, 25
    for _, m in ipairs(list) do
        local part = getPart(m)
        if part then
            local d = (root.Position - part.Position).Magnitude
            if d < dist then
                dist = d
                best = m
            end
        end
    end
    return best
end

local function getTarget()
    return getClosest(LonelyGods) or getClosest(Meteors)
end

--// MOVE
local function moveTo(target)
    local part = getPart(target)
    if not part then return end

    local humanoid = char:FindFirstChildOfClass("Humanoid")
    if not humanoid then return end

    local pos = part.Position + Vector3.new(0,3,0)
    humanoid:MoveTo(pos)

    if pos.Y > root.Position.Y then
        humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
    end
end

--// TIME
local function getServerTime()
    local ok, res = pcall(function()
        return require(ReplicatedStorage.Modules.Clock).getServerTime(true)
    end)
    return ok and res or tick()
end

--// SWING
local function swing(target)
    local now = getServerTime()
    if now - lastSwing < 0.25 then return end
    lastSwing = now

    local id = target:GetAttribute("EntityID")
    if not id then return end
	local buffer = interpolationBuffer.getBuffer(rendering.clientBuffer)

    local hits = {
        {
            entityID = id,
            buffer = buffer
        }
    }

    Packets.SwingTool.send({
        entityIDs = hits, -- now correctly structured
        cframe = char:GetPivot(),
        timestamp = now,
        buffer = buffer
    })
end

--// LOOP
RunService.RenderStepped:Connect(function()
    local target = getTarget()
    if not target then return end

    if STICK_TO_TARGET then moveTo(target) end
    if AUTO_SWING then swing(target) end
end)