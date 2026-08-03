-- SERVICES
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local TeleportService = game:GetService("TeleportService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Packets = require(ReplicatedStorage.Modules.Packets)

-- SETTINGS
local PICKUP_RADIUS = 25
local MAX_PICKUP_PER_SECOND = 50

local pickupCount = 0
local lastReset = tick()
-- PLAYER
local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local hrp = character:WaitForChild("HumanoidRootPart")

player.CharacterAdded:Connect(function(char)
	character = char
	hrp = char:WaitForChild("HumanoidRootPart")
end)

-- Anti-AFK (Added because I got kicked while afk testing somehow)
local bb = game:GetService('VirtualUser')

print("Initializing VirtualUser to prevent AFK kick...")
player.Idled:Connect(function()
	bb:CaptureController()
	bb:ClickButton2(Vector2.new())
	print("Safe!")
end)

-- SETTINGS
local CHECK_RADIUS = 20
local CLICK_DELAY = 0.0
local BED_CLICK_DELAY = 1
local MOVE_SPEED = 1.5
local HEIGHT_OFFSET = 0

-- REJOIN SETTINGS
local REJOIN_TIME = 2 * 60 -- 4 minutes
local clickStartTime = nil
local rejoined = false
local PLACE_ID = game.PlaceId  -- your game's place ID

-- POSITIONS
local JOIN_POSITION = Vector3.new(-1686.31201171875, -3, -2534.194091796875) -- join area
local TWEEN_TRIGGER_ZONE = Vector3.new(-667.74, 312.29, -1162.96) -- Bed spawn
local CLICK_POSITION = Vector3.new(-667.74, 312.29, -1162.96)

-- BED BUTTON
local gui = player:WaitForChild("PlayerGui")
local bedButton = gui
	:WaitForChild("SpawnGui")
	:WaitForChild("Customization")
	:WaitForChild("BedButton")

task.wait(4)

local absPos = bedButton.AbsolutePosition
local absSize = bedButton.AbsoluteSize
local clickX = absPos.X + absSize.X / 2
local clickY = absPos.Y + absSize.Y / 2 + 50

-- STATE
local clicking = false
local clickingBed = false
local tweening = false

-- CLICKING
local function startClicking()
	if clicking then return end
	clicking = true

	-- START TIMER ON FIRST CLICK
	if not clickStartTime then
		clickStartTime = os.clock()
	end

	task.spawn(function()
		while clicking do
			VirtualInputManager:SendMouseButtonEvent(clickX, clickY, 0, true, game, 0)
			VirtualInputManager:SendMouseButtonEvent(clickX, clickY, 0, false, game, 0)
			task.wait(CLICK_DELAY)
		end
	end)
end

local function startBedClicking()
	if clickingBed then return end
	clickingBed = true

	task.spawn(function()
		while clickingBed do
			VirtualInputManager:SendMouseButtonEvent(clickX, clickY, 0, true, game, 0)
			VirtualInputManager:SendMouseButtonEvent(clickX, clickY, 0, false, game, 0)
			task.wait(BED_CLICK_DELAY)
		end
	end)
end

local function stopClicking()
	clickingBed = false
end

-- PRESS 1
local function pressOneKey()
	VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.One, false, game)
	task.wait(0.05)
	VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.One, false, game)
end

-- TWEEN PATH
local function runTweenPath()
	if tweening then return end
	tweening = true
	stopClicking()

	pressOneKey()

	while tweening do
		if not hrp then break end

		local guardian = workspace.Resources["Crystal Guardian"]["Crystal Guardian"]
		if not guardian then
			task.wait(1)
			continue
		end

		local targetPos

		if guardian:IsA("Model") then
			targetPos = guardian:GetPivot().Position
		else
			targetPos = guardian.Position
		end

		targetPos = targetPos + Vector3.new(0, HEIGHT_OFFSET, 0)

		local dist = (hrp.Position - targetPos).Magnitude
		local time = dist / (MOVE_SPEED * 10)

		local tween = TweenService:Create(
			hrp,
			TweenInfo.new(time, Enum.EasingStyle.Linear),
			{CFrame = CFrame.new(targetPos)}
		)

		tween:Play()
		tween.Completed:Wait()

		task.wait(0.1) -- small refresh so it keeps tracking the boss
	end
end

-- REJOIN CHECK
local function checkRejoin()
	if rejoined then return end
	if not clickStartTime then return end -- haven't started clicking yet

	if os.clock() - clickStartTime >= REJOIN_TIME then
		rejoined = true

		-- Teleport to VIP (let Roblox handle instance)
		player:Kick("Rejoining...")
		TeleportService:Teleport(PLACE_ID, player)
	end
end

-- Helper to format Vector3 nicely
local function fmtVector3(v)
    return string.format("(%.2f, %.2f, %.2f)", v.X, v.Y, v.Z)
end

print("===============================")
print("           Settings            ")
print("===============================")
print("Click Delay: " .. CLICK_DELAY)
print("Check Radius: " .. CHECK_RADIUS)
print("Bed Click Delay: " .. BED_CLICK_DELAY)
print("Rejoin Time: " .. REJOIN_TIME .. " seconds")
print("Move Speed: " .. MOVE_SPEED)
print("Height Offset: " .. HEIGHT_OFFSET)
print("Place ID: " .. PLACE_ID)
print("===============================")
print("           Positions           ")
print("===============================")
print("Join Position: ", fmtVector3(JOIN_POSITION))
print("Tween Trigger Zone: ", fmtVector3(TWEEN_TRIGGER_ZONE))
print("Third Position: ", fmtVector3(CLICK_POSITION))
print("===============================")

RunService.Heartbeat:Connect(function()

	if not player.Character then return end

	-- reset counter every second
	if tick() - lastReset >= 1 then
		pickupCount = 0
		lastReset = tick()
	end

	if not workspace:FindFirstChild("Items") then return end

	local charPos = player.Character:GetPivot().Position

	for _, item in pairs(workspace.Items:GetChildren()) do

		if pickupCount >= MAX_PICKUP_PER_SECOND then
			break
		end

		local entity = item:GetAttribute("EntityID")
		if not entity then
			continue
		end

		local distance = (charPos - item:GetPivot().Position).Magnitude
		if distance > PICKUP_RADIUS then
			continue
		end

		Packets.Pickup.send(entity)

		pickupCount += 1
	end

end)

-- MAIN LOOP
RunService.Heartbeat:Connect(function()
	if not hrp then return end

	local pos = hrp.Position

	-- START clicking near JOIN
	if (pos - JOIN_POSITION).Magnitude <= CHECK_RADIUS then
		startBedClicking()
		return
	end

	-- TWEEN TRIGGER
	if (pos - TWEEN_TRIGGER_ZONE).Magnitude <= CHECK_RADIUS then
		runTweenPath()
	end

	-- START clicking at THIRD POSITION
	if (pos - CLICK_POSITION).Magnitude <= CHECK_RADIUS then
		startClicking()
	else
		stopClicking()
	end

	checkRejoin()
end)