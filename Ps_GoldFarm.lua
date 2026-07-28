-- Not Aethyrion Code
if not game:IsLoaded() then game.Loaded:Wait() end

local Workspace = cloneref(game:GetService("Workspace"))
local Players = cloneref(game:GetService("Players"))
local ReplicatedStorage = cloneref(game:GetService("ReplicatedStorage"))

repeat task.wait() until ReplicatedStorage:FindFirstChild("GameLoaded")

local Packets = require(ReplicatedStorage.Modules.Packets)
local Clock = require(ReplicatedStorage.Modules.Clock)
local LocalPlayer = Players.LocalPlayer

local hitlist = {
    ["Gold"] = true,
    ["Gold Node"] = true,
    ["Ice Chunk"] = true,
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

local function getResource(part)
    local current = part

    while current and current ~= Workspace do
        if current:IsA("Model")
            and (current.Name:lower():find("gold", 1, true) or hitlist[current.Name])
        then
            return current
        end

        current = current.Parent
    end
end

local function getEntityID(resource, overlappingPart)
    local entityID = resource:GetAttribute("EntityID")
        or overlappingPart:GetAttribute("EntityID")

    if entityID then
        return entityID
    end

    for _, descendant in ipairs(resource:GetDescendants()) do
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
            local resource = getResource(part)

            if resource then
                local entityID = getEntityID(resource, part)

                if entityID and not uniqueEntities[entityID] then
                    uniqueEntities[entityID] = true
                    hitEntities[#hitEntities + 1] = {
                        entityID = entityID,
                        buffer = nil,
                    }
                end
            end
        end

        if #hitEntities > 0 then
            firepacket("SwingTool", {
                entityIDs = hitEntities,
                cframe = character:GetPivot(),
                timestamp = Clock.getServerTime(true),
            })
        end
    end
end

-- Nilhub call here
-- <----
