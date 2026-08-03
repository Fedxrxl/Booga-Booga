--// CONFIG
local farm_food     = "Pumpkin"
local PLANT_RADIUS  = 60
local MOVE_SPEED    = 18 -- studs per second (ALWAYS)
local CYCLE_DELAY   = 0.05
local HEIGHT_OFFSET = 1 -- how high above the plant box you want to be

--// SERVICES
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--// MODULES
local LocalPlayer = Players.LocalPlayer

local Packets = require(ReplicatedStorage.Modules.Packets)
local ItemIDS = require(ReplicatedStorage.Modules.ItemIDS)

local DeployablesFolder = workspace:WaitForChild("Deployables")

--// TARGET GUI
local currentTargetGui
local function setTarget(model)
    if currentTargetGui then
        currentTargetGui:Destroy()
        currentTargetGui = nil
    end
    if not model then return end

    local adornee = model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart")
    if not adornee then return end

    local gui = Instance.new("BillboardGui")
    gui.Name = "__PLANT_TARGET__"
    gui.Adornee = adornee
    gui.Size = UDim2.fromOffset(110, 32)
    gui.StudsOffset = Vector3.new(0, 2.5, 0)
    gui.AlwaysOnTop = true
    gui.Parent = workspace

    local label = Instance.new("TextLabel")
    label.Size = UDim2.fromScale(1, 1)
    label.BackgroundTransparency = 1
    label.Text = "Target"
    label.Font = Enum.Font.GothamBold
    label.TextScaled = true
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    label.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    label.TextStrokeTransparency = 0
    label.Parent = gui

    currentTargetGui = gui
end

--// MOVE PLAYER (LOCK Y + 18 STUDS/SEC)
local function tweenToPosition(box)
    local char = LocalPlayer.Character
    if not char or not char.PrimaryPart then return end

    local root = char.PrimaryPart
    local humanoid = char:FindFirstChildOfClass("Humanoid")
    if not humanoid then return end

    if humanoid then
        humanoid.AutoRotate = false
    end

    local part = box.PrimaryPart or box:FindFirstChildWhichIsA("BasePart")
    if not part then return end

    -- Top of box
    local boxTopY = part.Position.Y + (part.Size.Y / 2)

    -- HALF CHARACTER HEIGHT
    local characterHalfHeight = humanoid.HipHeight + (root.Size.Y / 2)

    -- FINAL Y = box top + half character height
    local finalY = boxTopY + characterHalfHeight + HEIGHT_OFFSET

    local targetPos = Vector3.new(
        part.Position.X,
        finalY,
        part.Position.Z
    )

    -- Stay upright (no tilt)
    local lookAtPos = Vector3.new(
        part.Position.X,
        finalY,
        part.Position.Z - 1
    )

    local goalCF = CFrame.new(targetPos) * CFrame.Angles(0, root.Orientation.Y * math.pi/180, 0)

    local distance = (targetPos - root.Position).Magnitude
    local time = distance / MOVE_SPEED

    local tween = TweenService:Create(
        root,
        TweenInfo.new(time, Enum.EasingStyle.Linear),
        { CFrame = goalCF }
    )

    tween:Play()
    tween.Completed:Wait()

    if humanoid then
        humanoid.AutoRotate = true
    end
end

task.spawn(function()
    while true do
        local char = LocalPlayer.Character
        if not char or not char.PrimaryPart then
            task.wait(CYCLE_DELAY)
            continue
        end

        local origin = char.PrimaryPart.Position

        for _, box in ipairs(DeployablesFolder:GetChildren()) do
            if box.Name == "Plant Box"
               and box:GetAttribute("EntityID")
               and not box:FindFirstChild("Seed") then

                local dist = (box:GetPivot().Position - origin).Magnitude
                if dist <= PLANT_RADIUS then
                    -- Plant immediately
                    Packets.InteractStructure.send({
                        entityID = box:GetAttribute("EntityID"),
                        itemID = ItemIDS[farm_food],
                    })
                end
            end
        end

        task.wait(CYCLE_DELAY)
    end
end)

task.spawn(function()
    while true do
        local char = LocalPlayer.Character
        if not char or not char.PrimaryPart then
            task.wait(CYCLE_DELAY)
            continue
        end

        local origin = char.PrimaryPart.Position
        local closestBox
        local closestDistance = math.huge

        for _, box in ipairs(DeployablesFolder:GetChildren()) do
            if box.Name == "Plant Box"
               and box:GetAttribute("EntityID")
               and not box:FindFirstChild("Seed") then

                local dist = (box:GetPivot().Position - origin).Magnitude
                if dist <= PLANT_RADIUS and dist < closestDistance then
                    closestDistance = dist
                    closestBox = box
                end
            end
        end

        if closestBox then
            setTarget(closestBox)
            tweenToPosition(closestBox)
        else
            setTarget(nil)
        end

        task.wait(CYCLE_DELAY)
    end
end)

