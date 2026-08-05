--// CONFIG

local foods = {
    "Bloodfruit",
    "Lemon",
    "Pumpkin",
    "Berry"
}

local farm_food = "Pumpkin"

local START_SCAN    = 10
local MAX_SCAN      = 100
local SCAN_STEP     = 10

local SEARCH_HEIGHT = 10

local MOVE_SPEED    = 18
local CYCLE_DELAY   = 0.05
local HEIGHT_OFFSET = 1

local PLANT_DELAY   = 1



--// SERVICES

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")



--// PLAYER

local LocalPlayer = Players.LocalPlayer



--// MODULES

local Packets = require(
    ReplicatedStorage.Modules.Packets
)

local ItemIDS = require(
    ReplicatedStorage.Modules.ItemIDS
)



--------------------------------------------------
-- FOOD SYSTEM
--------------------------------------------------

local ITEM_ID


local function updateFoodID()

    ITEM_ID = ItemIDS[farm_food]

    if not ITEM_ID then
        warn(
            "Invalid food:",
            farm_food
        )
    end

end


updateFoodID()



--------------------------------------------------
-- FOOD GUI
--------------------------------------------------

local PlayerGui =
    LocalPlayer:WaitForChild(
        "PlayerGui"
    )


local gui =
    Instance.new("ScreenGui")

gui.Name = "FarmSelector"
gui.ResetOnSpawn = false
gui.Parent = PlayerGui



local button =
    Instance.new("TextButton")

button.Size =
    UDim2.fromOffset(
        220,
        50
    )

button.Position =
    UDim2.new(
        0,
        20,
        0.5,
        -100
    )


button.BackgroundColor3 =
    Color3.fromRGB(
        35,
        35,
        35
    )

button.TextColor3 =
    Color3.fromRGB(
        255,
        255,
        255
    )

button.Font =
    Enum.Font.GothamBold

button.TextSize = 16

button.Parent = gui



local foodIndex =
    table.find(
        foods,
        farm_food
    )
    or 1



local function refreshFood()

    button.Text =
        "Farm Food: "
        ..
        farm_food

end


refreshFood()



button.MouseButton1Click:Connect(function()

    foodIndex += 1


    if foodIndex > #foods then
        foodIndex = 1
    end


    farm_food =
        foods[foodIndex]


    updateFoodID()


    refreshFood()

end)





--------------------------------------------------
-- TARGET GUI
--------------------------------------------------

local currentTargetGui



local function setTarget(model)

    if currentTargetGui then

        currentTargetGui:Destroy()

        currentTargetGui = nil

    end


    if not model then
        return
    end



    local part =
        model.PrimaryPart
        or model:FindFirstChildWhichIsA(
            "BasePart"
        )


    if not part then
        return
    end



    local gui =
        Instance.new("BillboardGui")


    gui.Name =
        "__PLANT_TARGET__"


    gui.Adornee =
        part


    gui.Size =
        UDim2.fromOffset(
            110,
            32
        )


    gui.StudsOffset =
        Vector3.new(
            0,
            2.5,
            0
        )


    gui.AlwaysOnTop = true


    gui.Parent =
        workspace



    local label =
        Instance.new("TextLabel")


    label.Size =
        UDim2.fromScale(
            1,
            1
        )


    label.BackgroundTransparency = 1


    label.Text =
        "TARGET"


    label.Font =
        Enum.Font.GothamBold


    label.TextScaled = true


    label.TextColor3 =
        Color3.fromRGB(
            255,
            255,
            255
        )


    label.Parent =
        gui



    currentTargetGui = gui

end




--------------------------------------------------
-- SCANNER
--------------------------------------------------

local function scanArea(position,size)


    local results = {}

    local checked = {}



    local parts =
        workspace:GetPartBoundsInBox(
            CFrame.new(position),
            Vector3.new(
                size,
                SEARCH_HEIGHT,
                size
            )
        )



    for _,part in ipairs(parts) do


        local model =
            part:FindFirstAncestor(
                "Plant Box"
            )


        if model
        and not checked[model]
        and model:GetAttribute(
            "EntityID"
        ) then


            checked[model] = true


            table.insert(
                results,
                model
            )

        end

    end


    return results

end




--------------------------------------------------
-- MOVEMENT
--------------------------------------------------

local function moveToPlantBox(box)


    local char =
        LocalPlayer.Character


    if not char
    or not char.PrimaryPart then
        return
    end



    local root =
        char.PrimaryPart


    local humanoid =
        char:FindFirstChildOfClass(
            "Humanoid"
        )


    if not humanoid then
        return
    end



    local part =
        box.PrimaryPart
        or box:FindFirstChildWhichIsA(
            "BasePart"
        )


    if not part then
        return
    end



    local target =
        Vector3.new(
            part.Position.X,
            part.Position.Y
            +
            part.Size.Y / 2
            +
            humanoid.HipHeight
            +
            root.Size.Y / 2
            +
            HEIGHT_OFFSET,
            part.Position.Z
        )



    local distance =
        (
            target
            -
            root.Position
        ).Magnitude



    if distance < 0.5 then
        return
    end



    humanoid.AutoRotate = false



    local tween =
        TweenService:Create(
            root,
            TweenInfo.new(
                math.max(
                    distance / MOVE_SPEED,
                    0.05
                ),
                Enum.EasingStyle.Linear
            ),
            {
                CFrame =
                    CFrame.new(target)
                    *
                    root.CFrame.Rotation
            }
        )



    pcall(function()

        tween:Play()

        tween.Completed:Wait()

    end)



    if humanoid.Parent then

        humanoid.AutoRotate = true

    end

end




--------------------------------------------------
-- MAIN LOOP
--------------------------------------------------

local scanSize = START_SCAN

local plantingCooldown = {}



task.spawn(function()


while true do


    local char =
        LocalPlayer.Character



    if char
    and char.PrimaryPart then


        local origin =
            char.PrimaryPart.Position



        local target



        while not target do


            local boxes =
                scanArea(
                    origin,
                    scanSize
                )



            for _,box in ipairs(boxes) do


                if not box:FindFirstChild(
                    "Seed"
                ) then


                    target = box
                    break

                end

            end



            if not target then

                scanSize =
                    math.min(
                        scanSize + SCAN_STEP,
                        MAX_SCAN
                    )

                task.wait(
                    CYCLE_DELAY
                )

            end

        end




        if target then


            setTarget(target)


            moveToPlantBox(
                target
            )


            local id =
                target:GetAttribute(
                    "EntityID"
                )


            if id
            and ITEM_ID then


                local last =
                    plantingCooldown[id]


                if not last
                or tick()-last >= PLANT_DELAY then


                    plantingCooldown[id] =
                        tick()


                    Packets.InteractStructure.send({

                        entityID = id,

                        itemID = ITEM_ID

                    })

                end

            end



            scanSize =
                START_SCAN

        end

    end



    task.wait(
        CYCLE_DELAY
    )


end


end)
