if not game:IsLoaded() then game.Loaded:Wait() end -- Wait for the game to load

--// Services
local Workspace = cloneref(game:GetService("Workspace"))
local Players = cloneref(game:GetService("Players"))
local ReplicatedStorage = cloneref(game:GetService("ReplicatedStorage"))

local Player = Players.LocalPlayer or Players.PlayerAdded:Wait() -- Get the local player

repeat task.wait() until ReplicatedStorage:FindFirstChild("GameLoaded") -- Wait for the game to load 'game-based' idk if this is right

--// Workspace
local DeployablesFolder = workspace:WaitForChild("Deployables")
local DroppedItemsFolder = workspace:WaitForChild("Items")

-- // Modules
local Packets = require(ReplicatedStorage.Modules.Packets)
local ItemIDS = require(ReplicatedStorage.Modules.ItemIDS)
local ItemDATA = require(ReplicatedStorage.Modules.ItemData)

--// Functions
local function firepacket(packetName, ...) -- Function to send a packet to the server
    local packet = Packets and Packets[packetName]
    if not packet then
        warn("packet not found:", packetName)
        return false -- Failed to find packet
    end

    local success, err = pcall(packet.send, ...) -- Send the packet
    if not success then
        warn("packet failed:", packetName, err)
    end

    return success
end

local function GetItemId(itemName) -- Function to get the ID of an item by its name
	for id, name in pairs(ItemIDS) do
		if name == itemName then
			return id
		end
	end

	return nil -- Item not found
end

local function closest_GetDeployableId(deployableName)
    local character = Player.Character
    if not character then
        return nil
    end

    local root = character:FindFirstChild("HumanoidRootPart")
    if not root then
        return nil
    end

    local closestId = nil
    local closestDistance = math.huge

    for _, deployable in ipairs(workspace:GetDescendants()) do
        if deployable.Name == deployableName then
            local entityId = deployable:GetAttribute("EntityId")

            if entityId then
                local position

                if deployable:IsA("Model") then
                    local primary = deployable.PrimaryPart
                    if primary then
                        position = primary.Position
                    end
                elseif deployable:IsA("BasePart") then
                    position = deployable.Position
                end

                if position then
                    local distance = (root.Position - position).Magnitude

                    if distance < closestDistance then
                        closestDistance = distance
                        closestId = entityId
                    end
                end
            end
        end
    end

    return closestId
end


firepacket("InteractStructure", {
    ["entityID"] = closest_GetDeployableId("Grinder"), 
    ["itemID"] = GetItemId("Barley") 
})
