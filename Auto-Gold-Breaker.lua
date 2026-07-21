--// SERVICES
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--// PLAYER
local player = Players.LocalPlayer
local char = player.Character or player.CharacterAdded:Wait()
local root = char:WaitForChild("HumanoidRootPart")

player.CharacterAdded:Connect(function(c)
    char = c
    root = c:WaitForChild("HumanoidRootPart")
end)

local rendering = require(ReplicatedStorage.Game.rendering)
local interpolationBuffer = require(ReplicatedStorage.Game.rendering.interpolationBuffer)

--// NETWORK
local Packets = require(ReplicatedStorage.Modules:WaitForChild("Packets"))

--// TIME
local function getServerTime()
    local ok, res = pcall(function()
        return require(ReplicatedStorage.Modules.Clock).getServerTime(true)
    end)
    return ok and res or tick()
end

--// SETTINGS
local AUTO_SWING = false
local RANGE = 25
local lastSwing = 0

--// GUI
local gui = Instance.new("ScreenGui")
gui.Name = "GoldNodeFarm"
gui.Parent = player:WaitForChild("PlayerGui")
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true

-- MAIN FRAME
local frame = Instance.new("Frame", gui)
frame.Size = UDim2.new(0, 220, 0, 120)
frame.Position = UDim2.new(0.3, 0, 0.3, 0)
frame.BackgroundColor3 = Color3.fromRGB(25,25,25)
frame.BorderSizePixel = 0
frame.Active = true
frame.Draggable = true
Instance.new("UICorner", frame)

-- TITLE
local title = Instance.new("TextLabel", frame)
title.Size = UDim2.new(1,0,0,25)
title.Text = "Gold Node Farm"
title.BackgroundTransparency = 1
title.TextColor3 = Color3.new(1,1,1)
title.Font = Enum.Font.GothamBold
title.TextSize = 14

-- TOGGLE BUTTON
local toggle = Instance.new("TextButton", frame)
toggle.Size = UDim2.new(0.9,0,0,30)
toggle.Position = UDim2.new(0.05,0,0,35)
toggle.Text = "Auto Swing: OFF"
toggle.BackgroundColor3 = Color3.fromRGB(40,40,40)
toggle.TextColor3 = Color3.new(1,1,1)
toggle.Font = Enum.Font.Gotham
toggle.TextSize = 13
Instance.new("UICorner", toggle)

-- HIDE BUTTON
local hide = Instance.new("TextButton", frame)
hide.Size = UDim2.new(0.9,0,0,25)
hide.Position = UDim2.new(0.05,0,0,75)
hide.Text = "Hide GUI"
hide.BackgroundColor3 = Color3.fromRGB(60,20,20)
hide.TextColor3 = Color3.new(1,1,1)
hide.Font = Enum.Font.Gotham
hide.TextSize = 13
Instance.new("UICorner", hide)

-- SHOW BUTTON (FLOATING)
local showBtn = Instance.new("TextButton", gui)
showBtn.Size = UDim2.new(0, 100, 0, 30)
showBtn.Position = UDim2.new(0.05, 0, 0.5, 0)
showBtn.Text = "Show GUI"
showBtn.BackgroundColor3 = Color3.fromRGB(20,60,20)
showBtn.TextColor3 = Color3.new(1,1,1)
showBtn.Font = Enum.Font.GothamBold
showBtn.TextSize = 13
showBtn.Visible = false
showBtn.Active = true
showBtn.Draggable = true
Instance.new("UICorner", showBtn)

-- TOGGLE LOGIC
toggle.MouseButton1Click:Connect(function()
    AUTO_SWING = not AUTO_SWING
    toggle.Text = "Auto Swing: " .. (AUTO_SWING and "ON" or "OFF")
end)

-- HIDE GUI
hide.MouseButton1Click:Connect(function()
    frame.Visible = false
    showBtn.Visible = true
end)

-- SHOW GUI
showBtn.MouseButton1Click:Connect(function()
    frame.Visible = true
    showBtn.Visible = false
end)

--// SWING GOLD NODES
local function swingGoldNodes()
    local now = getServerTime()
    if now - lastSwing < 0.08 then return end
    lastSwing = now

    local hits = {}

    local resources = workspace:FindFirstChild("Resources")
    if not resources then return end

    for _, v in pairs(resources:GetChildren()) do
        if v:IsA("Model") and v.Name == "Gold Node" then
            local id = v:GetAttribute("EntityID")
            if id then
                local part = v.PrimaryPart or v:FindFirstChildWhichIsA("BasePart")
                if part then
                    if (root.Position - part.Position).Magnitude <= RANGE then
                        hits[#hits + 1] = {
                            entityID = id,
                            buffer = interpolationBuffer.getBuffer(rendering.clientBuffer)
                        }
                    end
                end
            end
        end
    end

    if #hits > 0 then
        Packets.SwingTool.send({
            entityIDs = hits,      -- array of numbers
            cframe = char:GetPivot(),
            timestamp = now
        })
    end
end

--// LOOP
RunService.RenderStepped:Connect(function()
    if AUTO_SWING then
        swingGoldNodes()
    end
end)
