-- SERVICES
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local TeleportService = game:GetService("TeleportService")

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
local MOVE_SPEED = 1
local HEIGHT_OFFSET = 0

-- REJOIN SETTINGS
local REJOIN_TIME = 4 * 60 -- 4 minutes
local clickStartTime = nil
local rejoined = false
local PLACE_ID = game.PlaceId  -- your game's place ID

-- POSITIONS
local JOIN_POSITION = Vector3.new(-1686.31201171875, -3, -2534.194091796875) -- join area
local TWEEN_TRIGGER_ZONE = Vector3.new(1137.05, -61.13, 1107.35) -- Bed spawn
local FORTH_POSITION = Vector3.new(1163.17, -58.15, 1096.77)

local TWEEN_PATH = {
	Vector3.new(1137.60, -61.60, 1095.09),
	Vector3.new(1148.27, -59.96, 1098.22),
	Vector3.new(1156.25, -59.31, 1110.58),
	Vector3.new(1163.17, -58.15, 1096.77),
}

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
	clicking = false
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

	for _, pos in ipairs(TWEEN_PATH) do
		if not hrp then break end

		local target = Vector3.new(pos.X, pos.Y + HEIGHT_OFFSET, pos.Z)
		local dist = (hrp.Position - target).Magnitude
		local time = dist / (MOVE_SPEED * 10)

		local tween = TweenService:Create(
			hrp,
			TweenInfo.new(time, Enum.EasingStyle.Linear),
			{ CFrame = CFrame.new(target) }
		)

		tween:Play()
		tween.Completed:Wait()
	end

	tweening = false
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
print("Forth Position: ", fmtVector3(FORTH_POSITION))
print("Tween Path:")
if typeof(TWEEN_PATH) == "table" then
    for i, pos in ipairs(TWEEN_PATH) do
        print(string.format("  %d: %s", i, fmtVector3(pos)))
    end
else
    print("  (TWEEN_PATH is nil or not a table)")
end
print("===============================")

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
	if (pos - FORTH_POSITION).Magnitude <= CHECK_RADIUS then
		startClicking()
	else
		stopClicking()
	end

	checkRejoin()
end)
