local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Stats = game:GetService("Stats")

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")
local Deployables = workspace:WaitForChild("Deployables")

--// MODULES
local Modules = ReplicatedStorage:WaitForChild("Modules")
local ItemData = select(2, pcall(require, Modules:WaitForChild("ItemData")))
local Packets = select(2, pcall(require, Modules:WaitForChild("Packets")))
local ItemIDS = select(2, pcall(require, Modules:WaitForChild("ItemIDS")))

--// CONFIG
local MAX_SPEED = 60 			-- Max speed
local GOLD_TO_COIN = 5			-- Gold to coin ratio // How much does 1 gold coin give the user once converted into a coin

--// STATE
local goldAmount = 20000		-- Amount of Gold to coin // 18+ speed should have 1 taken off and depending on higher speed more should be too, -1 = dont stop till user presses stop
local useGoldAmount = 0			-- Amount of Gold to coin // 18+ speed should have 1 taken off and depending on higher speed more should be too, -1 = dont stop till user presses stop
local coinSpeed = 60			-- Default Coin Speed
local coiningEnabled = false	-- Leave this alone
local paused = false			-- Leave this alone
local autoKickOnFinish = false  -- Leave this alone

local startGold = 0				-- Leave this alone
local targetGold = 0			-- Leave this alone
local lastUse = 0				-- Leave this alone

local walkspeed = 21			-- Players walkspeed

local foods = {}

-- selector state
local selectedPressID = "All"
local pressOrder = {}
local pressIndex = 1

-- name flip settings
local nameFlipEnabled = false
local index = 1
local INTERVAL = 1
local SWAP_INTERVAL = 15

local foods = {}

for itemName, data in pairs(ItemData) do
	if type(data) == "table" then
		if data.itemType == "food" then
			table.insert(foods, itemName)
		end
	end
end

table.sort(foods, function(a, b)
	return a < b
end)

-- debug print

-- Path to the list container
local listContainer = PlayerGui:WaitForChild("SecondaryGui")
    :WaitForChild("PlayerList")
    :WaitForChild("List")

-- Names to cycle through
local names = {
    "9usher. on discord to buy",
	"discord.gg/seya27eKXF"
}

--// GUI ROOT
local gui = Instance.new("ScreenGui", PlayerGui)
gui.Name = "Aethyrion_CoiningGUI_f0r_push3r"
gui.ResetOnSpawn = false

local main = Instance.new("Frame", gui)
main.Size = UDim2.fromOffset(460, 380)
main.Position = UDim2.fromScale(0.5, 0.5)
main.AnchorPoint = Vector2.new(0.5, 0.5)
main.BackgroundColor3 = Color3.fromRGB(30,30,30)
main.BorderSizePixel = 0
main.Active = true
main.Draggable = true

print("Initializing VirtualUser to prevent AFK kick...")
local bb = game:service'VirtualUser'
game:service'Players'.LocalPlayer.Idled:connect(function()
	bb:CaptureController()
	bb:ClickButton2(Vector2.new())
end)

--// UI HELPERS
local function label(text, y)
	local l = Instance.new("TextLabel", main)
	l.Size = UDim2.fromOffset(420, 22)
	l.Position = UDim2.fromOffset(20, y)
	l.Text = text
	l.TextColor3 = Color3.new(1,1,1)
	l.BackgroundTransparency = 1
	l.Font = Enum.Font.SourceSansBold
	l.TextXAlignment = Enum.TextXAlignment.Left
	return l
end

local function textbox(text, x, y)
	local t = Instance.new("TextBox", main)
	t.Size = UDim2.fromOffset(80, 26)
	t.Position = UDim2.fromOffset(x, y)
	t.Text = tostring(text)
	t.BackgroundColor3 = Color3.fromRGB(45,45,45)
	t.TextColor3 = Color3.new(1,1,1)
	t.ClearTextOnFocus = false
	t.TextScaled = true
	return t
end

local function button(text, x, y, w)
	local b = Instance.new("TextButton", main)
	b.Size = UDim2.fromOffset(w or 180, 30)
	b.Position = UDim2.fromOffset(x, y)
	b.Text = text
	b.BackgroundColor3 = Color3.fromRGB(70,70,70)
	b.TextColor3 = Color3.new(1,1,1)
	b.Font = Enum.Font.SourceSansBold
	return b
end

--// INVENTORY GOLD (AUTHORITATIVE)
local function getInventoryGold()
	local t =
		PlayerGui:FindFirstChild("MainGui")
		and PlayerGui.MainGui:FindFirstChild("RightPanel")
		and PlayerGui.MainGui.RightPanel:FindFirstChild("Inventory")
		and PlayerGui.MainGui.RightPanel.Inventory:FindFirstChild("List")
		and PlayerGui.MainGui.RightPanel.Inventory.List:FindFirstChild("Gold")
		and PlayerGui.MainGui.RightPanel.Inventory.List.Gold:FindFirstChild("QuantityImage")
		and PlayerGui.MainGui.RightPanel.Inventory.List.Gold.QuantityImage:FindFirstChild("QuantityText")

	if t and tonumber(t.Text) then
		return tonumber(t.Text)
	end
	return 0
end

--// UI ELEMENTS
label("Gold Amount", 20)
local goldBox = textbox(goldAmount or 0, 160, 20)

label("Coins", 50)
local coinInfo = label(goldAmount * GOLD_TO_COIN or "0", 160)

goldBox.FocusLost:Connect(function()
	goldAmount = math.max(0, tonumber(goldBox.Text) or 0)
	coinInfo.Text = tostring(goldAmount * GOLD_TO_COIN)
end)

label("Coin Speed (uses/sec)", 80)
local speedBox = textbox(coinSpeed, 160, 80)
speedBox.FocusLost:Connect(function()
	coinSpeed = math.clamp(tonumber(speedBox.Text) or coinSpeed, 1, MAX_SPEED)
	speedBox.Text = coinSpeed
end)

--// PROGRESS BAR
local barBack = Instance.new("Frame", main)
barBack.Size = UDim2.fromOffset(420, 16)
barBack.Position = UDim2.fromOffset(20, 140)
barBack.BackgroundColor3 = Color3.fromRGB(50,50,50)
barBack.BorderSizePixel = 0

local barFill = Instance.new("Frame", barBack)
barFill.Size = UDim2.fromScale(0,1)
barFill.BackgroundColor3 = Color3.fromRGB(0,170,255)
barFill.BorderSizePixel = 0

local progressText = Instance.new("TextLabel", barBack)
progressText.Size = UDim2.fromScale(1, 1)
progressText.BackgroundTransparency = 1
progressText.TextColor3 = Color3.new(1,1,1)
progressText.Font = Enum.Font.SourceSansBold
progressText.TextScaled = true
progressText.Text = "0%"

--// BUTTONS
local startBtn = button("Start", 20, 170, 130)
local pauseBtn = button("Pause", 160, 170, 130)

local memoryBtn = button("Memory Check", 300, 170, 130)

local kickBtn = button("Auto Kick: OFF", 300, 205, 130)

local nameFlipBtn = button("Name Flip: OFF", 300, 240, 130)

nameFlipBtn.MouseButton1Click:Connect(function()
	nameFlipEnabled = not nameFlipEnabled
	nameFlipBtn.Text = "Name Flip: " .. (nameFlipEnabled and "ON" or "OFF")
end)

kickBtn.MouseButton1Click:Connect(function()
	autoKickOnFinish = not autoKickOnFinish
	kickBtn.Text = "Auto Kick: " .. (autoKickOnFinish and "ON" or "OFF")
end)

--// COIN PRESS TRACKING + BILLBOARDS
local CoinPresses = {}
local BillboardGuis = {}

--// DROPDOWN SELECTOR
label("Coin Press Selector", 210)

local dropdownBtn = button("Selected: ALL", 20, 235, 200)

-- container
local dropdownFrame = Instance.new("Frame", main)
dropdownFrame.Size = UDim2.fromOffset(200, 150)
dropdownFrame.Position = UDim2.fromOffset(20, 270)
dropdownFrame.BackgroundColor3 = Color3.fromRGB(40,40,40)
dropdownFrame.BorderSizePixel = 0
dropdownFrame.Visible = false
dropdownFrame.ClipsDescendants = true

label("Food Selector", 210)

local selectedFood = foods[1] or "No Food Found"

local dropdownBtn_eat = button("Selected Food: " .. selectedFood, 300, 275, 130)

-- container
local dropdownFrame_eat = Instance.new("Frame", main)
dropdownFrame_eat.Size = UDim2.fromOffset(200, 150)
dropdownFrame_eat.Position = UDim2.fromOffset(20, 270)
dropdownFrame_eat.BackgroundColor3 = Color3.fromRGB(40,40,40)
dropdownFrame_eat.BorderSizePixel = 0
dropdownFrame_eat.Visible = false
dropdownFrame_eat.ClipsDescendants = true

-- scrolling list
local scroll_eat = Instance.new("ScrollingFrame", dropdownFrame_eat)
scroll_eat.Size = UDim2.fromScale(1,1)
scroll_eat.CanvasSize = UDim2.new(0,0,0,0)
scroll_eat.ScrollBarImageTransparency = 0
scroll_eat.ScrollBarThickness = 6
scroll_eat.BackgroundTransparency = 1
scroll_eat.BorderSizePixel = 0
scroll_eat.AutomaticCanvasSize = Enum.AutomaticSize.None

local layout_eat = Instance.new("UIListLayout", scroll_eat)
layout_eat.Padding = UDim.new(0, 4)

-- keep canvas sized to content
layout_eat:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
	scroll_eat.CanvasSize = UDim2.fromOffset(0, layout_eat.AbsoluteContentSize.Y + 6)
end)

function updateFoodDropdown()
	-- clear old buttons
	for _, child in ipairs(scroll_eat:GetChildren()) do
		if child:IsA("TextButton") then
			child:Destroy()
		end
	end

	local function addOption(name)
		local b = Instance.new("TextButton")
		b.Size = UDim2.fromOffset(200, 24)
		b.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
		b.TextColor3 = Color3.new(1, 1, 1)
		b.Font = Enum.Font.SourceSans
		b.TextScaled = true
		b.AutoButtonColor = true
		b.Text = name
		b.Parent = scroll_eat

		b.MouseButton1Click:Connect(function()
			selectedFood = name
			dropdownBtn_eat.Text = "Selected Food: " .. name
			dropdownFrame_eat.Visible = false
		end)
	end

	-- add all foods
	for _, foodName in ipairs(foods) do
		addOption(foodName)
	end
end

-- toggle dropdown
dropdownBtn_eat.MouseButton1Click:Connect(function()
	dropdownFrame_eat.Visible = not dropdownFrame_eat.Visible
end)

updateFoodDropdown()

-- scrolling list
local scroll = Instance.new("ScrollingFrame", dropdownFrame)
scroll.Size = UDim2.fromScale(1,1)
scroll.CanvasSize = UDim2.new(0,0,0,0)
scroll.ScrollBarImageTransparency = 0
scroll.ScrollBarThickness = 6
scroll.BackgroundTransparency = 1
scroll.BorderSizePixel = 0
scroll.AutomaticCanvasSize = Enum.AutomaticSize.None

local layout = Instance.new("UIListLayout", scroll)
layout.Padding = UDim.new(0, 4)

-- keep canvas sized to content
layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
	scroll.CanvasSize = UDim2.fromOffset(0, layout.AbsoluteContentSize.Y + 6)
end)

function updatePressDropdown()
    -- Clear old buttons
    for _, child in ipairs(scroll:GetChildren()) do
        if child:IsA("TextButton") then
            child:Destroy()
        end
    end

    local function addOption(name)
        local b = Instance.new("TextButton")
        b.Size = UDim2.fromOffset(200, 24)
        b.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
        b.TextColor3 = Color3.new(1, 1, 1)
        b.Font = Enum.Font.SourceSans
        b.TextScaled = true
        b.AutoButtonColor = true
        b.Text = name
        b.Parent = scroll

        -- Connect click AFTER parenting
        b.MouseButton1Click:Connect(function()
            selectedPressID = name
            dropdownBtn.Text = "Selected: " .. name
            dropdownFrame.Visible = false
        end)
    end

    -- Add "ALL" option first
    addOption("ALL")

    -- Add coin presses in order
    for _, id in ipairs(pressOrder) do
        addOption(id)
    end

    -- Validate current selection
    if selectedPressID ~= "ALL" and not CoinPresses[selectedPressID] then
        selectedPressID = "ALL"
        dropdownBtn.Text = "Selected: ALL"
    end
end

local function refreshCoinPresses()
	CoinPresses = {}
	pressOrder = {}

	local count = 1
	for _, obj in ipairs(Deployables:GetChildren()) do
		if obj:IsA("Model") and obj.Name:find("Coin Press") then
			local id = "Press-" .. count
			CoinPresses[id] = obj
			table.insert(pressOrder, id)

			if not BillboardGuis[id] then
				local bg = Instance.new("BillboardGui", obj)
				bg.Name = "PressID"
				bg.Adornee = obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart")
				bg.Size = UDim2.fromOffset(100, 30)
				bg.StudsOffset = Vector3.new(0, 3, 0)
				bg.AlwaysOnTop = true

				local tl = Instance.new("TextLabel", bg)
				tl.Size = UDim2.fromScale(1,1)
				tl.BackgroundTransparency = 1
				tl.TextColor3 = Color3.fromRGB(0,255,255)
				tl.Font = Enum.Font.SourceSansBold
				tl.TextScaled = true
				tl.Text = id

				BillboardGuis[id] = bg
			end
			count += 1
		end
	end

	updatePressDropdown()
end

Deployables.ChildAdded:Connect(refreshCoinPresses)
Deployables.ChildRemoved:Connect(refreshCoinPresses)

-- toggle dropdown visibility
dropdownBtn.MouseButton1Click:Connect(function()
    dropdownFrame.Visible = not dropdownFrame.Visible
end)

--// COIN PRESS USE
local function useCoinPress(press)
	local eid = press:GetAttribute("EntityID")
	if not eid then return end
	Packets.InteractStructure.send({
		entityID = eid;
		itemID = ItemIDS["Gold"];
	})
end

--// WALK SPEED CONFIG
label("WalkSpeed", 110)
local walkSpeedBox = textbox(walkspeed, 160, 110)
walkSpeedBox.FocusLost:Connect(function()
	walkspeed = math.clamp(tonumber(walkSpeedBox.Text) or walkspeed, 16, 250)
	if Player.Character and Player.Character:FindFirstChild("Humanoid") then
		Player.Character.Humanoid.WalkSpeed = walkspeed
	end
end)

--// TWEEN TO COIN PRESS TOGGLE
local tweenToPressEnabled = false
local movingToPress = false
local tweenBtn = button("Tween to Press: OFF", 250, 110, 180)

tweenBtn.MouseButton1Click:Connect(function()
	tweenToPressEnabled = not tweenToPressEnabled
	movingToPress = not movingToPress
	tweenBtn.Text = "Tween to Press: " .. (tweenToPressEnabled and "ON" or "OFF")
end)

-- =====================
-- TWEEN STATE
-- =====================

--// BUTTON LOGIC
startBtn.MouseButton1Click:Connect(function()
	if not coiningEnabled then
		startGold = getInventoryGold()

		-- Check speed so we can tank x / 1 off of gold amount
		if 18 <= coinSpeed then
			useGoldAmount = goldAmount - 1
		else
			useGoldAmount = goldAmount
		-- add extra check here so higher coin speed
		end
		
		-- Check if its 0 but should be 1
		if useGoldAmount == 0 and goldAmount == 1 then
			useGoldAmount += 1
		end
		
		targetGold = startGold - math.clamp(useGoldAmount, 0, startGold)
		lastUse = 0
		barFill.Size = UDim2.fromScale(0,1)
		paused = false
	end
	coiningEnabled = not coiningEnabled
	startBtn.Text = coiningEnabled and "Stop" or "Start"
end)

pauseBtn.MouseButton1Click:Connect(function()
	if not coiningEnabled then return end
	paused = not paused
	pauseBtn.Text = paused and "Resume" or "Pause"
end)

--// TOGGLE GUI
local toggleGui = Instance.new("ScreenGui")
toggleGui.Name = "MainToggleGui"
toggleGui.ResetOnSpawn = false
toggleGui.Parent = gui

--// BUTTON
local minibutton = Instance.new("TextButton")
minibutton.Size = UDim2.fromOffset(110, 36)
minibutton.Position = UDim2.fromScale(0, 0.5)
minibutton.AnchorPoint = Vector2.new(0, 0.5)
minibutton.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
minibutton.BorderSizePixel = 0
minibutton.TextColor3 = Color3.new(1, 1, 1)
minibutton.TextScaled = true
minibutton.Draggable = true
minibutton.Font = Enum.Font.GothamBold
minibutton.Text = "PUSHER" -- PUSHER = Copyright usage for user of script. MADE FOR PUSHER
minibutton.Parent = toggleGui

--// ROUND CORNERS
Instance.new("UICorner", minibutton).CornerRadius = UDim.new(0, 10)

--// STATE
local visible = true

minibutton.MouseButton1Click:Connect(function()
	visible = not visible
	main.Visible = visible
	minibutton.Text = visible and "PUSHER" or "PUSHER" -- PUSHER = Copyright usage for user of script. MADE FOR PUSHER
end)

local invitetext = Instance.new("TextLabel")
invitetext.Size = UDim2.fromOffset(110, 36)
invitetext.Position = UDim2.fromScale(0.1, 0.7)
invitetext.AnchorPoint = Vector2.new(0, 0.5)
invitetext.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
invitetext.BorderSizePixel = 0
invitetext.TextColor3 = Color3.new(1, 1, 1)
invitetext.TextScaled = true
invitetext.Draggable = true
invitetext.Font = Enum.Font.GothamBold
invitetext.Text = "discord.gg/seya27eKXF"
invitetext.Parent = toggleGui

--// ROUND CORNERS
Instance.new("UICorner", invitetext).CornerRadius = UDim.new(0, 10)

local function memoryCheck()
	local memoryUsage = Stats:GetTotalMemoryUsageMb()
    print(string.format("Current Memory Usage: %.2f MB", memoryUsage)) -- MB
    local memoryGB = memoryUsage / 1024                                -- Convert MB to GB
    print(string.format("Current Memory Usage: %.2f GB", memoryGB))    -- GB
end

-- Fixed this button to actually work and not bug out
memoryBtn.MouseButton1Click:Connect(function()
	memoryCheck()
end)

-- CONFIG
local STAND_DISTANCE = 3 -- studs in front of press

-- =====================
-- MAIN LOOP
-- =====================
RunService.Heartbeat:Connect(function()
	if not tweenToPressEnabled then
		movingToPress = false
		return
	end

	if selectedPressID == "ALL" and #pressOrder == 0 then return end

	local character = Player.Character
	if not character then return end

	local hrp = character:FindFirstChild("HumanoidRootPart")
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not hrp or not humanoid then return end

	-- Determine target press
	local targetPress
	if selectedPressID == "ALL" then
		targetPress = CoinPresses[pressOrder[pressIndex]]
	else
		targetPress = CoinPresses[selectedPressID]
	end
	if not targetPress or not targetPress.PrimaryPart then return end

	-- =====================
	-- CALCULATE FRONT POSITION
	-- =====================
	local pressPart = targetPress.PrimaryPart
	local pressCF = pressPart.CFrame
	local pressSize = pressPart.Size

	local toPlayer = hrp.Position - pressCF.Position
	toPlayer = Vector3.new(toPlayer.X, 0, toPlayer.Z)

	if toPlayer.Magnitude == 0 then
		toPlayer = -pressCF.LookVector
	end

	local normal = toPlayer.Unit
	local horizontalOffset =
		((math.max(pressSize.X, pressSize.Z) / 2) + STAND_DISTANCE + 1)

	local goalPosition = Vector3.new(
		pressCF.Position.X + normal.X * horizontalOffset,
		hrp.Position.Y,
		pressCF.Position.Z + normal.Z * horizontalOffset
	)

	local distance = (hrp.Position - goalPosition).Magnitude
	if distance < 2 then return end

	-- =====================
	-- CONTINUOUS WALK LOGIC
	-- =====================

	humanoid.AutoRotate = true

	-- Only re-issue MoveTo if target moved enough
	if movingToPress then
		
		humanoid:MoveTo(goalPosition)
	end
end)

--// MAIN LOOP (SELECTOR AWARE)
RunService.Heartbeat:Connect(function(dt)
	if not coiningEnabled or paused then return end

	local currentGold = getInventoryGold()

	-- PREVENT LAST EXTRA USE
	if currentGold - 1 < targetGold then
		coiningEnabled = false
		startBtn.Text = "Start"
		barFill.Size = UDim2.fromScale(1,1)

		if autoKickOnFinish then
			task.delay(0.2, function()
				Player:Kick("Coining finished.")
			end)
		end

		return
	end


	local used = startGold - currentGold
	local total = startGold - targetGold
	--barFill.Size = UDim2.fromScale(math.clamp(used / total, 0, 1), 1)  -- old kept for broken ahh code
	local percent = 0

	if total > 0 then
		percent = math.clamp(used / total, 0, 1)
	end

	barFill.Size = UDim2.fromScale(percent, 1)
	progressText.Text = tostring(math.floor(percent * 100)) .. "%"

	lastUse += dt
				-- this should allow the script to run faster, as we -triple (3x)- sextuple (6x) the speed secretly
	if lastUse < (1 / (coinSpeed * 6)) then return end
	lastUse = 0

	if selectedPressID == "ALL" then
		if #pressOrder == 0 then return end
		pressIndex = (pressIndex % #pressOrder) + 1
		local id = pressOrder[pressIndex]
		useCoinPress(CoinPresses[id])
	else
		useCoinPress(CoinPresses[selectedPressID])
	end
end)

-- Apply WalkSpeed when changed
RunService.Heartbeat:Connect(function()
	if Player.Character and Player.Character:FindFirstChild("Humanoid") and Player.Character.Humanoid.WalkSpeed ~= walkspeed then
		Player.Character.Humanoid.WalkSpeed = walkspeed
	else
		task.wait(1)
	end
end)

-- Apply current name to a label
local function applyName(label)
	if label and label:IsA("TextLabel") and label.Name == "NameLabel" then
		label.Text = names[index]
	end
end

-- Apply to everything (fallback / interval use)
local function applyToAll()
	for _, obj in ipairs(listContainer:GetDescendants()) do
		applyName(obj)
	end
end

-- 🔁 Interval loop (keeps cycling names)
task.spawn(function()
	while true do
		if nameFlipEnabled then
			applyToAll()

			index += 1
			if index > #names then
				index = 1
			end

			-- swap names every SWAP_INTERVAL cycles
			if index % SWAP_INTERVAL == 0 then
				local currentName = names[index]
				local nextIndex = index + 1

				if nextIndex > #names then
					nextIndex = 1
				end

				names[index] = names[nextIndex]
				names[nextIndex] = currentName
			end
		end

		task.wait(INTERVAL)
	end
end)

-- ⚡ INSTANT apply when UI updates (THIS FIXES YOUR ISSUE)
listContainer.DescendantAdded:Connect(function(obj)
	if not nameFlipEnabled then return end
	if obj:IsA("TextLabel") and obj.Name == "NameLabel" then
		task.defer(function()
			applyName(obj)
		end)
	end
end)

-- init
refreshCoinPresses()
