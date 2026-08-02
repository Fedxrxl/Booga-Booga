if not game:IsLoaded() then game.Loaded:Wait() end

local Workspace = cloneref(game:GetService("Workspace"))
local Players = cloneref(game:GetService("Players"))
local ReplicatedStorage = cloneref(game:GetService("ReplicatedStorage"))

repeat task.wait() until ReplicatedStorage:FindFirstChild("GameLoaded")

local Packets = require(ReplicatedStorage.Modules.Packets)
local ItemIDS = require(ReplicatedStorage.Modules.ItemIDS)
local Clock = require(ReplicatedStorage.Modules.Clock)
local LocalPlayer = Players.LocalPlayer

-- CPS Settings
local cpsCap = 16
local dontBreakCap = true
local minHealth = 99
local fruit = "Bloodfruit"

-- Hitlist for Targets
local hitlist = {
    ["Sky Crewmate"] = true,
    ["Crewmate"] = true,
    ["Sky Captain"] = true,
    ["Captain"] = true,
    ["Dark Greybeard"] = true,
}

local function firepacket(packetName, ...)
    local packet = Packets and Packets[packetName]
    if not packet then
        warn("packet not found:", packetName)
        return false
    end

    local success, err = pcall(packet.send, ...)
    if not success then
        warn("packet failed:", packetName, err)
    end

    return success
end

local function GetItemId(itemName)
	for id, name in pairs(ItemIDS) do
		if name == itemName then
			return id
		end
	end

	return nil -- Item not found
end

local clicks = {}

local function heal()
    local now = tick()

    -- Remove entries older than 1 second
    while #clicks > 0 and now - clicks[1] >= 1 do
        table.remove(clicks, 1)
    end

    -- Current CPS is #clicks
    if dontBreakCap and #clicks >= cpsCap then
        return
    end

    local FruitID = GetItemId(fruit)
    if not FruitID then
        warn("Fruit not found:", fruit)
        return
    end

    table.insert(clicks, now)

    firepacket("UseBagItem", {
        value = FruitID,
    })
end

local function getPirate(part)
    local current = part

    while current and current ~= Workspace do
        if current:IsA("Model")
            and (current.Name:lower():find("crewmate", 1, true) or hitlist[current.Name])
        then
            return current
        end

        current = current.Parent
    end
end

local function getEntityID(pirate, overlappingPart)
    local entityID = pirate:GetAttribute("EntityID")
        or overlappingPart:GetAttribute("EntityID")

    if entityID then
        return entityID
    end

    for _, descendant in ipairs(pirate:GetDescendants()) do
        entityID = descendant:GetAttribute("EntityID")
        if entityID then
            return entityID
        end
    end
end

repeat task.wait() until LocalPlayer:GetAttribute("hasSpawned")

while task.wait(0.05) do
    local character = LocalPlayer.Character
    local humanoidRootPart = character and character:FindFirstChild("HumanoidRootPart")
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")

    if humanoidRootPart and humanoid and humanoid.Health > 0 then
        local uniqueEntities = {}
        local hitEntities = {}

        for _, part in ipairs(Workspace:GetPartBoundsInBox(humanoidRootPart.CFrame, Vector3.new(30, 30, 30))) do
            local pirate = getPirate(part)

            if pirate then
                local entityID = getEntityID(pirate, part)

                if entityID and not uniqueEntities[entityID] then
                    uniqueEntities[entityID] = true
                    hitEntities[#hitEntities + 1] = {
                        entityID = entityID,
                        buffer = nil,
                    }

                    if humanoid.Health >= minHealth then
                        print("Healing...")
                        heal()
                    end
                end
            end
        end

        if #hitEntities > 0 then
            -- Call Animation // Gotta figure out how this call works
            --firepacket("PlayAnimation", {
            --    value = true
            --})
            -- Call Swing
            firepacket("SwingTool", {
                entityIDs = hitEntities,
                cframe = character:GetPivot(),
                timestamp = Clock.getServerTime(true),
            })
        end
    end
end
