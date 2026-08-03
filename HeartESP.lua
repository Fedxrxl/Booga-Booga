local heartMarkers = {}
local heartId = 0
local HeartsFolder = nil

local function getAdornee(heart)
	return heart.PrimaryPart or heart:FindFirstChildWhichIsA("BasePart")
end

local function createMarker(heart)
	if heartMarkers[heart] then
		return
	end

	local adornee = getAdornee(heart)
	if not adornee then
		return
	end

	heartId += 1

	local gui = Instance.new("BillboardGui")
	gui.Name = "HeartMarker_" .. heartId
	gui.Adornee = adornee
	gui.Size = UDim2.fromOffset(110, 32)
	gui.StudsOffset = Vector3.new(0, 2.5, 0)
	gui.MaxDistance = math.huge
	gui.LightInfluence = 0
	gui.AlwaysOnTop = true
	gui.Parent = workspace

	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1,1)
	label.BackgroundTransparency = 1
	label.Text = "Heart " .. heartId
	label.Font = Enum.Font.GothamBold
	label.TextScaled = true
	label.TextColor3 = Color3.fromRGB(255,255,255)
	label.TextStrokeColor3 = Color3.fromRGB(0,0,0)
	label.TextStrokeTransparency = 0
	label.Parent = gui

	heartMarkers[heart] = gui
end

-- 🔥 function to attach to current Heart folder
local function attachToHeartFolder(folder)
	HeartsFolder = folder
end

-- 🔥 constantly watch workspace for Heart folder replacement
task.spawn(function()
	while true do
		local currentFolder = workspace:FindFirstChild("Heart")

		if currentFolder and currentFolder ~= HeartsFolder then
			attachToHeartFolder(currentFolder)
		end

		if HeartsFolder and HeartsFolder.Parent then
			for _, heart in ipairs(HeartsFolder:GetChildren()) do
				createMarker(heart)
			end
		end

		-- cleanup invalid markers
		for heart, gui in pairs(heartMarkers) do
			if not heart or not heart.Parent then
				if gui then
					gui:Destroy()
				end
				heartMarkers[heart] = nil
				heartId -= 1
			end
		end

		task.wait(0.5)
	end
end)