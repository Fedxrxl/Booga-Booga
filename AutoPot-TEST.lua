--// SERVICES
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer

local Packets = require(ReplicatedStorage.Modules.Packets)
local GameUtil = require(ReplicatedStorage.Modules.GameUtil)

--// CONFIG
local CONFIG = {
    cauldronName = "Cauldron",
    dropDelay = 0.25,
    dragHeight = 3
}

--// POTION RECIPES
local potion_recipes = {
    poison = {
        ["Prickly Pear"] = 3,
        ["Magnetite"] = 1
    },
    swift = {
        ["Crystal"] = 1,
        ["Cloudberry"] = 3
    },
    slowness = {
        ["Crystal"] = 1,
        ["Ice Cube"] = 3,
        ["Frostfruit"] = 3
    },
    healing = {
        ["Bloodfruit"] = 5,
        ["Strawberry"] = 2
    },
    instant_dmg = {
        ["Prickly Pear"] = 3,
        ["Adurite"] = 3
    },
    fire_resistant = {
        ["Firehide"] = 2
    },
    strength = {
        ["Bloodfruit"] = 2,
        ["Adurite"] = 2
    },
    weakness = {
        ["Berrys"] = 2,
        ["Magnetite"] = 3
    },
    haste = {
        ["Iron"] = 2,
        ["Lemon"] = 2
    }
}

--// FIND CAULDRON
local function getCauldron()
    for _,v in pairs(workspace.Deployables:GetChildren()) do
        if v.Name:lower():find("cauldron") then
            return v
        end
    end
end

--// DROP ITEM FROM INVENTORY
local function dropItem(index)
    Packets.DropBagItem.send(index)
end

--// DRAG ITEM INTO CAULDRON
local function dragItem(item, cauldron)

    local part = item:IsA("Model") and item.PrimaryPart or item
    if not part then return end

    local body = Instance.new("BodyPosition")
    body.MaxForce = Vector3.new(math.huge,math.huge,math.huge)
    body.P = 25000
    body.D = 1500
    body.Parent = part

    local connection
    connection = RunService.RenderStepped:Connect(function()

        if not item.Parent then
            connection:Disconnect()
            body:Destroy()
            return
        end

        body.Position =
            cauldron:GetPivot().Position +
            Vector3.new(0,CONFIG.dragHeight,0)

    end)

end

--// GET INVENTORY
local function getInventory()

    local inv = GameUtil.Data.inventory
    local items = {}

    for index,item in pairs(inv) do
        items[item.name] = {
            index = index,
            quantity = item.quantity
        }
    end

    return items
end

--// AUTO POTION LOOP
local running = false
local selectedPotion = "poison"

local ICE_NAME = "Ice Cube"
local ICE_AMOUNT = 3
local WAIT_TIME = 30

local function startAutoPotion()

    running = true

    while running do
        task.wait()

        local recipe = potion_recipes[selectedPotion]
        if not recipe then continue end

        local inv = getInventory()
        local cauldron = getCauldron()

        if not cauldron then
            warn("No cauldron found")
            task.wait(2)
            continue
        end

        -------------------------------------------------
        -- DROP ICE FIRST
        -------------------------------------------------

        local ice = inv[ICE_NAME]

        if ice then
            for i = 1, ICE_AMOUNT do
                dropItem(ice.index)
                task.wait(CONFIG.dropDelay)
            end
        end

        -------------------------------------------------
        -- WAIT 30 SECONDS
        -------------------------------------------------

        task.wait(WAIT_TIME)

        -------------------------------------------------
        -- DROP POTION INGREDIENTS
        -------------------------------------------------

        for itemName,amount in pairs(recipe) do

            local data = inv[itemName]

            if data then

                for i = 1,amount do
                    dropItem(data.index)
                    task.wait(CONFIG.dropDelay)
                end

            end

        end

        -------------------------------------------------
        -- DRAG ITEMS INTO CAULDRON
        -------------------------------------------------

        for _,item in pairs(workspace.Items:GetChildren()) do

            if recipe[item.Name] or item.Name == ICE_NAME then
                dragItem(item,cauldron)
            end

        end

        task.wait(2)

    end
end

--// GUI
local gui = Instance.new("ScreenGui")
gui.Parent = player.PlayerGui

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0,220,0,180)
frame.Position = UDim2.new(0,20,0.5,-90)
frame.BackgroundColor3 = Color3.fromRGB(25,25,25)
frame.Parent = gui

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1,0,0,30)
title.Text = "Auto Potion"
title.BackgroundTransparency = 1
title.TextColor3 = Color3.new(1,1,1)
title.Parent = frame

local button = Instance.new("TextButton")
button.Size = UDim2.new(1,-20,0,40)
button.Position = UDim2.new(0,10,0,50)
button.Text = "START"
button.Parent = frame

button.MouseButton1Click:Connect(function()

    if running then
        running = false
        button.Text = "START"
    else
        button.Text = "STOP"
        task.spawn(startAutoPotion)
    end

end)

-- POTION SELECTOR
local dropdown = Instance.new("TextButton")
dropdown.Size = UDim2.new(1,-20,0,40)
dropdown.Position = UDim2.new(0,10,0,110)
dropdown.Text = "Potion: poison"
dropdown.Parent = frame

dropdown.MouseButton1Click:Connect(function()

    local keys = {}
    for k in pairs(potion_recipes) do
        table.insert(keys,k)
    end

    local i = table.find(keys,selectedPotion) or 1
    i += 1
    if i > #keys then i = 1 end

    selectedPotion = keys[i]
    dropdown.Text = "Potion: "..selectedPotion

end)