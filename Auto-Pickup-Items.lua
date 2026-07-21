--// SERVICES
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local Player = Players.LocalPlayer
local Packets = require(ReplicatedStorage.Modules.Packets)
local ItemData = require(ReplicatedStorage.Modules.ItemData)

--// SETTINGS
local AUTO_PICKUP = false
local PICKUP_ALL = false

local AUTO_PICKUP_CHESTS = false
local CHEST_PICKUP_ALL = false

local HIDE_DROPPED_ITEMS_WORKSPACE = false
local HIDE_DROPPED_ITEMS_CHESTS = false
local SHOW_PICKUP_AOE = false

local PICKUP_RADIUS = 25
local MAX_PICKUP_COUNT = 1500
local MAX_CAP = 1500
local pickupCount = 0
local ItemList = {}
local SelectedItem = nil

local Whitelist = {}
local SearchQuery = ""

--// GUI
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = Player:WaitForChild("PlayerGui")

local ToggleUIBtn = Instance.new("TextButton")
ToggleUIBtn.Size = UDim2.new(0,100,0,28)
ToggleUIBtn.Position = UDim2.new(0,12,0,12)
ToggleUIBtn.Text = "Pickup UI"
ToggleUIBtn.BackgroundColor3 = Color3.fromRGB(30,30,30)
ToggleUIBtn.TextColor3 = Color3.new(1,1,1)
ToggleUIBtn.BorderSizePixel = 0
ToggleUIBtn.TextSize = 12
ToggleUIBtn.Parent = ScreenGui
Instance.new("UICorner", ToggleUIBtn).CornerRadius = UDim.new(0,6)

local Main = Instance.new("Frame")
Main.Size = UDim2.new(0,260,0,340)
Main.Position = UDim2.new(0.5,-130,0.5,-170)
Main.BackgroundColor3 = Color3.fromRGB(20,20,20)
Main.BorderSizePixel = 0
Main.Visible = false
Main.Parent = ScreenGui
Instance.new("UICorner", Main).CornerRadius = UDim.new(0,8)

-- FIXED UI TOGGLE
ToggleUIBtn.MouseButton1Click:Connect(function()
	Main.Visible = not Main.Visible
end)

-- Scale
local UIScale = Instance.new("UIScale", Main)
if UserInputService.TouchEnabled then
	UIScale.Scale = 0.9
end

-- Title
local TitleBar = Instance.new("Frame", Main)
TitleBar.Size = UDim2.new(1,0,0,25)
TitleBar.BackgroundColor3 = Color3.fromRGB(28,28,28)
TitleBar.BorderSizePixel = 0
Instance.new("UICorner", TitleBar).CornerRadius = UDim.new(0,8)

local Title = Instance.new("TextLabel", TitleBar)
Title.Size = UDim2.new(1,0,1,0)
Title.BackgroundTransparency = 1
Title.Text = "Auto Pickup"
Title.TextColor3 = Color3.new(1,1,1)
Title.Font = Enum.Font.GothamBold
Title.TextSize = 14
Instance.new("UICorner", Title).CornerRadius = UDim.new(0,8)

-- Content
local Content = Instance.new("Frame", Main)
Content.Position = UDim2.new(0,8,0,36)
Content.Size = UDim2.new(1,-16,1,-44)
Content.BackgroundTransparency = 1

local Layout = Instance.new("UIListLayout", Content)
Layout.Padding = UDim.new(0,4)

local function CreateButton(text,color)
	local b = Instance.new("TextButton")
	b.Size = UDim2.new(1,0,0,20)
	b.Text = text
	b.BackgroundColor3 = color
	b.TextColor3 = Color3.new(1,1,1)
	b.BorderSizePixel = 0
	b.Font = Enum.Font.Gotham
	b.TextSize = 12
	Instance.new("UICorner", b).CornerRadius = UDim.new(0,6)
	b.Parent = Content
	return b
end

local Toggle = CreateButton("Auto Pickup: OFF", Color3.fromRGB(45,45,45))
local PickupAllButton = CreateButton("Pickup ALL: OFF", Color3.fromRGB(60,45,45))
local ChestToggle = CreateButton("Auto Pickup Chests: OFF", Color3.fromRGB(45,45,65))
local ChestAllToggle = CreateButton("Chest Pickup ALL: OFF", Color3.fromRGB(65,45,65))
local PickupShowAOEToggle = CreateButton("Show Pickup AOE: OFF", Color3.fromRGB(51, 65, 45))
local HideDroppedItemsWorkspace = CreateButton("Hide Dropped Items in Workspace: OFF", Color3.fromRGB(45, 65, 63))
local HideDroppedItemsChests = CreateButton("Hide Dropped Items in Chests: OFF", Color3.fromRGB(45, 65, 63))

-- Radius
local RadiusBox = Instance.new("TextBox")
RadiusBox.Size = UDim2.new(1,0,0,20)
RadiusBox.PlaceholderText = "Pickup Radius"
RadiusBox.Text = ""
RadiusBox.BackgroundColor3 = Color3.fromRGB(35,35,35)
RadiusBox.TextColor3 = Color3.new(1,1,1)
RadiusBox.BorderSizePixel = 0
RadiusBox.Font = Enum.Font.Gotham
RadiusBox.TextSize = 12
Instance.new("UICorner", RadiusBox).CornerRadius = UDim.new(0,6)
RadiusBox.Parent = Content

local SearchBox = RadiusBox:Clone()
SearchBox.PlaceholderText = "Search Items"
SearchBox.Parent = Content

local SliderHolder = Instance.new("Frame")
SliderHolder.Size = UDim2.new(1,0,0,50)
SliderHolder.BackgroundTransparency = 1
SliderHolder.Parent = Content

local SliderLabel = Instance.new("TextLabel")
SliderLabel.Size = UDim2.new(1,0,0,14)
SliderLabel.BackgroundTransparency = 1
SliderLabel.Text = "Max Pickups Per Second"
SliderLabel.TextColor3 = Color3.new(1,1,1)
SliderLabel.Font = Enum.Font.Gotham
SliderLabel.TextSize = 11
SliderLabel.TextXAlignment = Enum.TextXAlignment.Left
SliderLabel.Parent = SliderHolder

local ValueBox = Instance.new("TextBox")
ValueBox.Size = UDim2.new(0,60,0,18)
ValueBox.Position = UDim2.new(1,-60,0,0)
ValueBox.Text = tostring(MAX_PICKUP_COUNT)
ValueBox.BackgroundColor3 = Color3.fromRGB(35,35,35)
ValueBox.TextColor3 = Color3.new(1,1,1)
ValueBox.BorderSizePixel = 0
ValueBox.Font = Enum.Font.Gotham
ValueBox.TextSize = 11
Instance.new("UICorner", ValueBox).CornerRadius = UDim.new(0,4)
ValueBox.Parent = SliderHolder

local SliderBack = Instance.new("Frame")
SliderBack.Size = UDim2.new(1,0,0,12)
SliderBack.Position = UDim2.new(0,0,0,22)
SliderBack.BackgroundColor3 = Color3.fromRGB(45,45,45)
SliderBack.BorderSizePixel = 0
Instance.new("UICorner", SliderBack).CornerRadius = UDim.new(1,0)
SliderBack.Parent = SliderHolder

local SliderFill = Instance.new("Frame")
SliderFill.Size = UDim2.new(MAX_PICKUP_COUNT/MAX_CAP,0,1,0)
SliderFill.BackgroundColor3 = Color3.fromRGB(60,140,60)
SliderFill.BorderSizePixel = 0
Instance.new("UICorner", SliderFill).CornerRadius = UDim.new(1,0)
SliderFill.Parent = SliderBack

local draggingslider = false

local function UpdateSliderFromValue(value)
	value = math.clamp(math.floor(value),0,MAX_CAP)
	MAX_PICKUP_COUNT = value
	ValueBox.Text = tostring(value)
	SliderFill.Size = UDim2.new(value/MAX_CAP,0,1,0)
end

local function UpdateFromMouse(x)
	local relative = (x - SliderBack.AbsolutePosition.X) / SliderBack.AbsoluteSize.X
	local value = math.clamp(relative,0,1) * MAX_CAP
	UpdateSliderFromValue(value)
end

SliderBack.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		draggingslider = true
		UpdateFromMouse(input.Position.X)
	end
end)

SliderBack.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		draggingslider = false
	end
end)

UserInputService.InputChanged:Connect(function(input)
	if draggingslider and input.UserInputType == Enum.UserInputType.MouseMovement then
		UpdateFromMouse(input.Position.X)
	end
end)

ValueBox.FocusLost:Connect(function()
	local num = tonumber(ValueBox.Text)
	if num then
		UpdateSliderFromValue(num)
	else
		ValueBox.Text = tostring(MAX_PICKUP_COUNT)
	end
end)

-- Scroll
local Scroll = Instance.new("ScrollingFrame")
Scroll.Size = UDim2.new(1,0,0,55)
Scroll.CanvasSize = UDim2.new(0,0,0,0)
Scroll.ScrollBarThickness = 4
Scroll.BackgroundColor3 = Color3.fromRGB(30,30,30)
Scroll.BorderSizePixel = 0
Instance.new("UICorner", Scroll).CornerRadius = UDim.new(0,6)
Scroll.Parent = Content

local ListLayout = Instance.new("UIListLayout", Scroll)
ListLayout.Padding = UDim.new(0,5)

local function RefreshList()
	for _,v in pairs(Scroll:GetChildren()) do
		if v:IsA("Frame") then
			v:Destroy()
		end
	end
	
	for _,name in ipairs(ItemList) do
		
		-- SEARCH FILTER
		if SearchQuery ~= "" then
			if not string.find(string.lower(name), string.lower(SearchQuery)) then
				continue
			end
		end
		
		local holder = Instance.new("Frame")
		holder.Size = UDim2.new(1,-4,0,20)
		holder.BackgroundTransparency = 1
		holder.Parent = Scroll
		
		local btn = Instance.new("TextButton")
		btn.Size = UDim2.new(1,-26,1,0)
		btn.Text = name
		btn.BackgroundColor3 = table.find(Whitelist,name)
			and Color3.fromRGB(60,140,60) -- GREEN
			or Color3.fromRGB(50,50,50)
		btn.TextColor3 = Color3.new(1,1,1)
		btn.BorderSizePixel = 0
		btn.Font = Enum.Font.Gotham
		btn.TextSize = 12
		Instance.new("UICorner", btn).CornerRadius = UDim.new(0,5)
		btn.Parent = holder
		
		local removeX = Instance.new("TextButton")
		removeX.Size = UDim2.new(0,22,1,0)
		removeX.Position = UDim2.new(1,-22,0,0)
		removeX.Text = "X"
		removeX.BackgroundColor3 = Color3.fromRGB(120,40,40)
		removeX.TextColor3 = Color3.new(1,1,1)
		removeX.BorderSizePixel = 0
		removeX.Font = Enum.Font.GothamBold
		removeX.TextSize = 12
		Instance.new("UICorner", removeX).CornerRadius = UDim.new(0,5)
		removeX.Parent = holder
		
		-- CLICK TO ADD
		btn.MouseButton1Click:Connect(function()
			if not table.find(Whitelist,name) then
				table.insert(Whitelist,name)
			end
			RefreshList()
		end)
		
		-- X TO REMOVE
		removeX.MouseButton1Click:Connect(function()
			for i,v in ipairs(Whitelist) do
				if v == name then
					table.remove(Whitelist,i)
					break
				end
			end
			RefreshList()
		end)
	end
	
	task.wait()
	Scroll.CanvasSize = UDim2.new(0,0,0,ListLayout.AbsoluteContentSize.Y + 4)
end

-- Fetch all items (FILTERED)
for itemName, data in pairs(ItemData) do
	if type(data) == "table" then
		
		-- FILTER RULES // HEAVY FPS BOOST
		if data.load ~= nil -- must have load value
		then
			table.insert(ItemList, itemName)
		end
		
	end
end

-- Priority table (UNCHANGED)
local priority = {
	["Gold"] = 1,
	["Raw Gold"] = 2,
	["Coin2"] = 3,
	["Coin"] = 4,
	["Coin Stack"] = 5
}

-- Sort by priority (UNCHANGED)
table.sort(ItemList, function(a, b)
	local aPriority = priority[a]
	local bPriority = priority[b]

	if aPriority and bPriority then
		return aPriority < bPriority
	elseif aPriority then
		return true
	elseif bPriority then
		return false
	else
		return a < b
	end
end)

RefreshList()

local PickupAOEFolder = Instance.new("Folder")
PickupAOEFolder.Name = "PickupAOE"
PickupAOEFolder.Parent = workspace

local RING_SEGMENTS = 40 -- higher = smoother

local function updateRing(position, radius)
	
	-- Clear old segments
	PickupAOEFolder:ClearAllChildren()
	
	for i = 1, RING_SEGMENTS do
		local angle = (i / RING_SEGMENTS) * math.pi * 2
		
		local x = math.cos(angle) * radius
		local z = math.sin(angle) * radius
		
		local segment = Instance.new("Part")
		segment.Anchored = true
		segment.CanCollide = false
		segment.CanQuery = false
		segment.CanTouch = false
		segment.Material = Enum.Material.Neon
		segment.Color = Color3.fromRGB(255, 0, 0)
		segment.Transparency = 0.1
		segment.Size = Vector3.new(0.3, 0.3, radius * 0.15)
		
		segment.CFrame =
			CFrame.new(position + Vector3.new(x, 0.05, z)) *
			CFrame.Angles(0, -angle, 0)
		
		segment.Parent = PickupAOEFolder
	end
end	

-- BUTTON LOGIC
Toggle.MouseButton1Click:Connect(function()
	AUTO_PICKUP = not AUTO_PICKUP
	Toggle.Text = "Auto Pickup: "..(AUTO_PICKUP and "ON" or "OFF")
end)

PickupAllButton.MouseButton1Click:Connect(function()
	PICKUP_ALL = not PICKUP_ALL
	PickupAllButton.Text = "Pickup ALL: "..(PICKUP_ALL and "ON" or "OFF")
end)

ChestToggle.MouseButton1Click:Connect(function()
	AUTO_PICKUP_CHESTS = not AUTO_PICKUP_CHESTS
	ChestToggle.Text = "Auto Pickup Chests: "..(AUTO_PICKUP_CHESTS and "ON" or "OFF")
end)

ChestAllToggle.MouseButton1Click:Connect(function()
	CHEST_PICKUP_ALL = not CHEST_PICKUP_ALL
	ChestAllToggle.Text = "Chest Pickup ALL: "..(CHEST_PICKUP_ALL and "ON" or "OFF")
end)

PickupShowAOEToggle.MouseButton1Click:Connect(function()
	SHOW_PICKUP_AOE = not SHOW_PICKUP_AOE
	PickupShowAOEToggle.Text = "Show Pickup AOE: "..(SHOW_PICKUP_AOE and "ON" or "OFF")
end)

HideDroppedItemsWorkspace.MouseButton1Click:Connect(function()
	HIDE_DROPPED_ITEMS_WORKSPACE = not HIDE_DROPPED_ITEMS_WORKSPACE
	HideDroppedItemsWorkspace.Text = "Hide Dropped Items in Workspace: "..(HIDE_DROPPED_ITEMS_WORKSPACE and "ON" or "OFF")
end)

HideDroppedItemsChests.MouseButton1Click:Connect(function()
	HIDE_DROPPED_ITEMS_CHESTS = not HIDE_DROPPED_ITEMS_CHESTS
	HideDroppedItemsChests.Text = "Hide Dropped Items in Chests: "..(HIDE_DROPPED_ITEMS_CHESTS and "ON" or "OFF")
end)

RadiusBox.FocusLost:Connect(function()
	local num = tonumber(RadiusBox.Text)
	if num then
		PICKUP_RADIUS = num
	end
end)

SearchBox:GetPropertyChangedSignal("Text"):Connect(function()
	SearchQuery = SearchBox.Text
	RefreshList()
end)

---------------------------------------------------
-- AUTO PICKUP LOOP
---------------------------------------------------

local lastReset = tick()

RunService.Heartbeat:Connect(function()
	if not Player.Character then return end
	
	-- Reset counter every second
	if tick() - lastReset >= 1 then
		pickupCount = 0
		lastReset = tick()
	end
	
	local charPos = Player.Character:GetPivot().Position
	
	-- NORMAL ITEMS
	if workspace:FindFirstChild("Items") then
		for _,item in pairs(workspace.Items:GetChildren()) do
			if pickupCount >= MAX_PICKUP_COUNT then break end
			if not item:GetAttribute("EntityID") then continue end
			
			local distance = (charPos - item:GetPivot().Position).Magnitude
			if distance > PICKUP_RADIUS then continue end
			
			if PICKUP_ALL then
				Packets.Pickup.send(item:GetAttribute("EntityID"))
				pickupCount += 1
				continue
			end
			
			if AUTO_PICKUP and table.find(Whitelist, item.Name) then
				Packets.Pickup.send(item:GetAttribute("EntityID"))
				pickupCount += 1
			end
		end
	end
	
	-- CHEST PICKUP (CLOSEST CHEST ONLY)
	if (AUTO_PICKUP_CHESTS or CHEST_PICKUP_ALL)
		and workspace:FindFirstChild("Deployables") then
		
		local closestChest = nil
		local closestDistance = math.huge
		
		for _,model in pairs(workspace.Deployables:GetChildren()) do
			local contents = model:FindFirstChild("Contents")
			if contents and #contents:GetChildren() > 0 then
				local dist = (charPos - model:GetPivot().Position).Magnitude
				if dist < closestDistance then
					closestDistance = dist
					closestChest = contents
				end
			end
		end
		
		if closestChest and closestDistance <= PICKUP_RADIUS then
			for _,item in pairs(closestChest:GetChildren()) do
				if pickupCount >= MAX_PICKUP_COUNT then break end
				if not item:GetAttribute("EntityID") then continue end
				
				if CHEST_PICKUP_ALL then
					Packets.Pickup.send(item:GetAttribute("EntityID"))
					pickupCount += 1
				elseif AUTO_PICKUP_CHESTS and table.find(Whitelist, item.Name) then
					Packets.Pickup.send(item:GetAttribute("EntityID"))
					pickupCount += 1
				end
			end
		end
	end
end)

RunService.Heartbeat:Connect(function()

	-- NORMAL DROPPED ITEMS
	if workspace:FindFirstChild("Items") then
		for _, item in pairs(workspace.Items:GetChildren()) do
			if not item:GetAttribute("EntityID") then continue end
			
			local shouldHide = HIDE_DROPPED_ITEMS_WORKSPACE
			
			if item:IsA("BasePart") then
				item.LocalTransparencyModifier = shouldHide and 1 or 0
			
			elseif item:IsA("Model") then
				for _, obj in pairs(item:GetDescendants()) do
					if obj:IsA("BasePart") then
						obj.LocalTransparencyModifier = shouldHide and 1 or 0
					end
				end
			end
		end
	end

	-- CHEST DROPPED ITEMS
	if workspace:FindFirstChild("Deployables") then
		for _, model in pairs(workspace.Deployables:GetChildren()) do
			local contents = model:FindFirstChild("Contents")
			if not contents then continue end
			
			for _, item in pairs(contents:GetChildren()) do
				if not item:GetAttribute("EntityID") then continue end
				
				local shouldHide = HIDE_DROPPED_ITEMS_CHESTS
				
				if item:IsA("BasePart") then
					item.LocalTransparencyModifier = shouldHide and 1 or 0
				
				elseif item:IsA("Model") then
					for _, obj in pairs(item:GetDescendants()) do
						if obj:IsA("BasePart") then
							obj.LocalTransparencyModifier = shouldHide and 1 or 0
						end
					end
				end
			end
		end
	end

end)

RunService.Heartbeat:Connect(function()
	if not Player.Character or not Player.Character:FindFirstChild("HumanoidRootPart") then
		PickupAOEFolder:ClearAllChildren()
		return
	end
	
	if not SHOW_PICKUP_AOE then
		PickupAOEFolder:ClearAllChildren()
		return
	end
	
	local root = Player.Character.HumanoidRootPart
	
	updateRing(root.Position - Vector3.new(0, root.Size.Y/2, 0), PICKUP_RADIUS)
end)

---------------------------------------------------
-- DRAG SYSTEM
---------------------------------------------------

-- DRAG SYSTEM WITH SCREEN BOUNDS
local Camera = workspace.CurrentCamera

local function makeDraggable(dragObject, dragHandle)
	local dragging = false
	local dragStart = nil
	local startPos = nil

	local function update(input)
		local delta = input.Position - dragStart
		local newX = startPos.X.Offset + delta.X
		local newY = startPos.Y.Offset + delta.Y

		-- SCREEN BOUNDS
		local screenSize = Camera.ViewportSize
		local objSize = dragObject.AbsoluteSize

		newX = math.clamp(newX, 0, screenSize.X - objSize.X)
		newY = math.clamp(newY, 0, screenSize.Y - objSize.Y)

		dragObject.Position = UDim2.new(0, newX, 0, newY)
	end

	dragHandle.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
		or input.UserInputType == Enum.UserInputType.Touch then
			
			dragging = true
			dragStart = input.Position
			startPos = dragObject.Position
		end
	end)

	dragHandle.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
		or input.UserInputType == Enum.UserInputType.Touch then
			dragging = false
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if dragging then
			if input.UserInputType == Enum.UserInputType.MouseMovement
			or input.UserInputType == Enum.UserInputType.Touch then
				update(input)
			end
		end
	end)
end

-- APPLY TO BOTH
makeDraggable(Main, TitleBar)
makeDraggable(ToggleUIBtn, ToggleUIBtn)

-- Anti Idle
local VirtualUser = game:GetService("VirtualUser")
Player.Idled:Connect(function()
	VirtualUser:CaptureController()
	VirtualUser:ClickButton2(Vector2.new(0, 0))
end)
