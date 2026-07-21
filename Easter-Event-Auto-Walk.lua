local Players = game:GetService("Players")
local PathfindingService = game:GetService("PathfindingService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer

-- SETTINGS
local running = false
local showPath = true
local SCAN_RADIUS = 1000

-- PATH STATE
local currentPath = nil
local index = 1
local lastTarget = nil
local lastCompute = 0

-- PATH VISUAL
local pathFolder = Instance.new("Folder")
pathFolder.Name = "PathVisual"
pathFolder.Parent = workspace

-- GUI
local gui = Instance.new("ScreenGui", player:WaitForChild("PlayerGui"))
gui.ResetOnSpawn = false

local frame = Instance.new("Frame", gui)
frame.Size = UDim2.new(0,200,0,150)
frame.Position = UDim2.new(0,20,0,100)
frame.BackgroundColor3 = Color3.fromRGB(30,30,30)

local startBtn = Instance.new("TextButton", frame)
startBtn.Size = UDim2.new(1,-20,0,30)
startBtn.Position = UDim2.new(0,10,0,10)
startBtn.Text = "Start"

local pathBtn = Instance.new("TextButton", frame)
pathBtn.Size = UDim2.new(1,-20,0,30)
pathBtn.Position = UDim2.new(0,10,0,50)
pathBtn.Text = "Path: ON"

local toggleBtn = Instance.new("TextButton", gui)
toggleBtn.Size = UDim2.new(0,120,0,30)
toggleBtn.Position = UDim2.new(0,20,0,60)
toggleBtn.Text = "Hide UI"

toggleBtn.MouseButton1Click:Connect(function()
	frame.Visible = not frame.Visible
	toggleBtn.Text = frame.Visible and "Hide UI" or "Show UI"
end)

-- CHARACTER
local function getChar()
	local char = player.Character or player.CharacterAdded:Wait()
	return char, char:WaitForChild("Humanoid"), char:WaitForChild("HumanoidRootPart")
end

-- VISUAL
local function clearPath()
	pathFolder:ClearAllChildren()
end

local function drawLine(a,b)
	if not showPath then return end
	local dist = (a-b).Magnitude

	local p = Instance.new("Part")
	p.Anchored = true
	p.CanCollide = false
	p.Material = Enum.Material.Neon
	p.Color = Color3.fromRGB(0,255,255)
	p.Size = Vector3.new(0.2,0.2,dist)
	p.CFrame = CFrame.new(a,b) * CFrame.new(0,0,-dist/2)
	p.Parent = pathFolder
end

local function drawPath(path)
	clearPath()
	if not showPath then return end

	for i=1,#path-1 do
		drawLine(path[i].Position, path[i+1].Position)
	end
end

-- 🥚 PRIORITY SYSTEM
local PRIORITIES = {
	["255,255,255"] = 1,   -- normal
	["255,214,79"] = 3,    -- gold
	["120,255,255"] = 5,   -- diamond
	["57,22,57"]   = 20    -- void
}

local function getEggPriority(egg)
	local handle = egg:FindFirstChild("Handle", true)
	if not handle or not handle:IsA("BasePart") then return 1 end

	local c = handle.Color
	local key = math.floor(c.R*255)..","..math.floor(c.G*255)..","..math.floor(c.B*255)

	return PRIORITIES[key] or 1
end

local function isValidWaypoint(fromPos, toPos)
    -- 1) Wall check (line of sight)
    local rayParams = RaycastParams.new()
    rayParams.FilterType = Enum.RaycastFilterType.Blacklist
    rayParams.FilterDescendantsInstances = {player.Character}

    local result = workspace:Raycast(fromPos, toPos - fromPos, rayParams)
    if result then
        return false -- blocked by map/wall
    end

    -- 2) Ground snap check (prevents flying into void / inside map)
    local groundRay = workspace:Raycast(toPos + Vector3.new(0, 5, 0), Vector3.new(0, -50, 0), rayParams)
    if not groundRay then
        return false
    end

    return true
end

local function getBestEgg(root)
	local folder = workspace:FindFirstChild("EasterEggs")
	if not folder then return nil end

	local best = nil
	local bestScore = 0

	for _,v in ipairs(folder:GetChildren()) do
		if v.Name == "Egg" then
			local part = v.PrimaryPart or v:FindFirstChildWhichIsA("BasePart")
			if part then
				local dist = (root.Position - part.Position).Magnitude
				if dist < SCAN_RADIUS then
					local priority = getEggPriority(v)
					local score = priority / math.max(dist,1)

					if score > bestScore then
						bestScore = score
						best = v
					end
				end
			end
		end
	end

	return best
end

-- PATH
local function createPath(a,b)
	local path = PathfindingService:CreatePath({
		AgentRadius = 3,
		AgentHeight = 5,
		AgentCanJump = true,
		WaypointSpacing = 8, -- 🔥 smoother hills

		Costs = {
			Water = 0
		}
	})

	path:ComputeAsync(a,b)

	if path.Status == Enum.PathStatus.Success then
		return path:GetWaypoints()
	end
end

local function startPath(path, targetPos)
	local char, humanoid, root = getChar()

	currentPath = {}
	index = 1
	lastTarget = targetPos
	lastCompute = tick()

	-- 🔥 FILTER WAYPOINTS HERE (THIS IS THE IMPORTANT PART)
	for _, wp in ipairs(path) do
		if isValidWaypoint(root.Position, wp.Position) then
			table.insert(currentPath, wp)
		end
	end

	-- fallback: if everything got filtered, force direct target
	if #currentPath == 0 then
		currentPath = { {Position = targetPos} }
	end
end

RunService.Heartbeat:Connect(function()
	if not running then return end

	local char, humanoid, root = getChar()
	if not currentPath or not currentPath[index] then return end

	local waypoint = currentPath[index]

	local waypointDist = (root.Position - waypoint.Position).Magnitude
	local eggDist = lastTarget and (root.Position - lastTarget).Magnitude or math.huge

	-- 🥚 FINAL PUSH (this is the missing piece)
	if lastTarget and eggDist < 10 then
		humanoid:MoveTo(lastTarget + Vector3.new(0, 1, 0))

		-- force finish
		if eggDist < 3 then
			currentPath = nil
		end

		return
	end

	-- normal movement
	local safePos = waypoint.Position + Vector3.new(0, math.clamp(root.Velocity.Magnitude * 0.05, 1, 3), 0)
	humanoid:MoveTo(safePos)

	-- waypoint progress
	if waypointDist < 6 then
		index += 1
	end
end)

-- LOGIC LOOP
task.spawn(function()
	local lastPos = nil
	local lastMove = tick()

	while true do
		if running then
			local char, humanoid, root = getChar()

			local egg = getBestEgg(root)
			if egg then
				local part = egg.PrimaryPart or egg:FindFirstChildWhichIsA("BasePart")

				if part then
					local needNewPath = false

					if not currentPath or not currentPath[index] then
						needNewPath = true
					end

					if lastTarget and (part.Position - lastTarget).Magnitude > 15 then
						needNewPath = true
					end

					-- stuck
					if not lastPos then lastPos = root.Position end

					if (root.Position - lastPos).Magnitude > 1 then
						lastPos = root.Position
						lastMove = tick()
					elseif tick() - lastMove > 2 then
                        humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
                        currentPath = nil -- 🔥 FORCE REPATH (THIS WAS MISSING)
                        lastMove = tick()
					end

					if needNewPath and tick() - lastCompute > 0.5 then
						local newPath = createPath(root.Position, part.Position)
						if newPath then
							startPath(newPath, part.Position)
							drawPath(newPath)
						end
					end
				end
			end
		end

		task.wait(0.2)
	end
end)

-- BUTTONS
startBtn.MouseButton1Click:Connect(function()
	running = not running
	startBtn.Text = running and "Stop" or "Start"
end)

pathBtn.MouseButton1Click:Connect(function()
	showPath = not showPath
	pathBtn.Text = showPath and "Path: ON" or "Path: OFF"
	if not showPath then clearPath() end
end)
