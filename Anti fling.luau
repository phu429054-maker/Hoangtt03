--!strict

local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

export type AntiFlingController = {
	gui: ScreenGui,
	setEnabled: (self: AntiFlingController, enabled: boolean) -> (),
	isEnabled: (self: AntiFlingController) -> boolean,
	destroy: (self: AntiFlingController) -> (),
}

local RAINBOW_SPEED_DEG_PER_SEC: number = 95

local function emitLog(level: string, eventName: string, fields: { [string]: string | number | boolean }): ()
	local ts = os.date("!%Y-%m-%dT%H:%M:%SZ")
	local parts: { string } = {
		string.format('ts="%s"', tostring(ts)),
		string.format('level="%s"', level),
		'module="AntiFlingRainbowDraggable"',
		string.format('event="%s"', eventName),
	}

	for key, val in pairs(fields) do
		if type(val) == "string" then
			table.insert(parts, string.format('%s="%s"', key, val))
		else
			table.insert(parts, string.format("%s=%s", key, tostring(val)))
		end
	end

	local line = table.concat(parts, " ")
	if level == "ERROR" or level == "WARN" then
		warn(line)
	else
		print(line)
	end
end

local function resolveParentContainer(): Instance?
	local localPlayer = Players.LocalPlayer
	if localPlayer then
		local playerGui = localPlayer:FindFirstChildOfClass("PlayerGui")
		if playerGui then
			return playerGui
		end
		local okWait, waited = pcall(function(): Instance?
			return localPlayer:WaitForChild("PlayerGui", 5)
		end)
		if okWait and waited then
			return waited
		end
	end

	local okCore, coreGuiRef = pcall(function(): Instance
		return CoreGui
	end)
	if okCore and coreGuiRef then
		return coreGuiRef
	end

	return nil
end

local function applyNoCollisionToOtherPlayers(speaker: Player?): ()
	for _, player in ipairs(Players:GetPlayers()) do
		if player ~= speaker then
			local character = player.Character
			if character then
				for _, descendant in ipairs(character:GetDescendants()) do
					if descendant:IsA("BasePart") then
						pcall(function()
							descendant.CanCollide = false
						end)
					end
				end
			end
		end
	end
end

local function createAntiFlingDraggableGui(): AntiFlingController?
	local parentContainer = resolveParentContainer()
	if not parentContainer then
		emitLog("ERROR", "gui_parent_not_found", { reason = "NO_PLAYER_OR_CORE_GUI" })
		return nil
	end

	local speaker: Player? = Players.LocalPlayer
	local antifling: RBXScriptConnection? = nil
	local rainbowConn: RBXScriptConnection? = nil
	local uiConnections: { RBXScriptConnection } = {}
	local enabledState: boolean = false
	local isDestroyed: boolean = false

	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "AntiFlingRainbowScreenGui"
	screenGui.ResetOnSpawn = false
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	screenGui.Parent = parentContainer

	local mainFrame = Instance.new("Frame")
	mainFrame.Name = "AntiFlingFrame"
	mainFrame.Size = UDim2.fromOffset(220, 102)
	mainFrame.Position = UDim2.new(0.5, -110, 0.5, -51)
	mainFrame.BackgroundColor3 = Color3.fromRGB(15, 18, 28)
	mainFrame.BorderSizePixel = 0
	mainFrame.Active = true
	mainFrame.Parent = screenGui

	local frameCorner = Instance.new("UICorner")
	frameCorner.CornerRadius = UDim.new(0, 12)
	frameCorner.Parent = mainFrame

	local frameStroke = Instance.new("UIStroke")
	frameStroke.Name = "RainbowStroke"
	frameStroke.Thickness = 2.5
	frameStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	frameStroke.Color = Color3.fromRGB(255, 255, 255)
	frameStroke.Parent = mainFrame

	local rainbowGradient = Instance.new("UIGradient")
	rainbowGradient.Name = "RainbowGradient"
	rainbowGradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0.00, Color3.fromRGB(255, 0, 85)),
		ColorSequenceKeypoint.new(0.20, Color3.fromRGB(255, 145, 0)),
		ColorSequenceKeypoint.new(0.40, Color3.fromRGB(255, 235, 0)),
		ColorSequenceKeypoint.new(0.60, Color3.fromRGB(0, 235, 130)),
		ColorSequenceKeypoint.new(0.80, Color3.fromRGB(0, 165, 255)),
		ColorSequenceKeypoint.new(1.00, Color3.fromRGB(175, 65, 255)),
	})
	rainbowGradient.Rotation = 0
	rainbowGradient.Parent = frameStroke

	local titleLabel = Instance.new("TextLabel")
	titleLabel.Name = "TitleLabel"
	titleLabel.Size = UDim2.new(1, -24, 0, 26)
	titleLabel.Position = UDim2.fromOffset(12, 8)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Text = "ANTI FLING"
	titleLabel.TextColor3 = Color3.fromRGB(248, 250, 252)
	titleLabel.TextSize = 14
	titleLabel.Font = Enum.Font.GothamBlack
	titleLabel.TextXAlignment = Enum.TextXAlignment.Left
	titleLabel.Parent = mainFrame

	local toggleButton = Instance.new("TextButton")
	toggleButton.Name = "ToggleButton"
	toggleButton.Size = UDim2.new(1, -24, 0, 42)
	toggleButton.Position = UDim2.fromOffset(12, 44)
	toggleButton.BackgroundColor3 = Color3.fromRGB(220, 38, 38)
	toggleButton.Text = "OFF"
	toggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	toggleButton.TextSize = 15
	toggleButton.Font = Enum.Font.GothamBold
	toggleButton.BorderSizePixel = 0
	toggleButton.Parent = mainFrame

	local toggleCorner = Instance.new("UICorner")
	toggleCorner.CornerRadius = UDim.new(0, 8)
	toggleCorner.Parent = toggleButton

	-- Logic kéo thả mượt qua UserInputService (chuột & cảm ứng)
	local dragging = false
	local dragInput: InputObject? = nil
	local dragStartPos = Vector3.zero
	local startFramePos = mainFrame.Position

	table.insert(uiConnections, mainFrame.InputBegan:Connect(function(input: InputObject)
		if isDestroyed then
			return
		end
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			dragInput = input
			dragStartPos = input.Position
			startFramePos = mainFrame.Position

			local endedConn: RBXScriptConnection? = nil
			endedConn = input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragging = false
					if dragInput == input then
						dragInput = nil
					end
					if endedConn and endedConn.Connected then
						endedConn:Disconnect()
					end
				end
			end)
			if endedConn then
				table.insert(uiConnections, endedConn)
			end
		end
	end))

	table.insert(uiConnections, UserInputService.InputChanged:Connect(function(input: InputObject)
		if isDestroyed or not dragging then
			return
		end
		if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
			if dragInput == nil then
				dragInput = input
			end
			if input == dragInput then
				local delta = input.Position - dragStartPos
				mainFrame.Position = UDim2.new(
					startFramePos.X.Scale,
					startFramePos.X.Offset + delta.X,
					startFramePos.Y.Scale,
					startFramePos.Y.Offset + delta.Y
				)
			end
		end
	end))

	table.insert(uiConnections, UserInputService.InputEnded:Connect(function(input: InputObject)
		if input == dragInput then
			dragging = false
			dragInput = nil
		end
	end))

	local function stopSteppedLoop(): ()
		if antifling then
			pcall(function()
				if antifling and antifling.Connected then
					antifling:Disconnect()
				end
			end)
			antifling = nil
		end
	end

	local function startSteppedLoop(): ()
		stopSteppedLoop()
		antifling = RunService.Stepped:Connect(function()
			if isDestroyed or not enabledState then
				return
			end
			applyNoCollisionToOtherPlayers(speaker)
		end)
	end

	local function setEnabled(nextEnabled: boolean): ()
		if isDestroyed then
			return
		end
		enabledState = nextEnabled

		if enabledState then
			startSteppedLoop()
			toggleButton.Text = "ON"
			toggleButton.BackgroundColor3 = Color3.fromRGB(16, 185, 129)
			emitLog("INFO", "anti_fling_enabled", {})
		else
			stopSteppedLoop()
			toggleButton.Text = "OFF"
			toggleButton.BackgroundColor3 = Color3.fromRGB(220, 38, 38)
			emitLog("INFO", "anti_fling_disabled", {})
		end
	end

	local function destroy(): ()
		if isDestroyed then
			return
		end
		isDestroyed = true
		enabledState = false
		dragging = false
		dragInput = nil

		stopSteppedLoop()

		if rainbowConn then
			pcall(function()
				if rainbowConn and rainbowConn.Connected then
					rainbowConn:Disconnect()
				end
			end)
			rainbowConn = nil
		end

		for _, conn in ipairs(uiConnections) do
			if conn.Connected then
				conn:Disconnect()
			end
		end
		table.clear(uiConnections)

		pcall(function()
			screenGui:Destroy()
		end)

		emitLog("INFO", "anti_fling_gui_destroyed", {})
	end

	rainbowConn = RunService.RenderStepped:Connect(function(deltaTime: number)
		if isDestroyed then
			return
		end
		rainbowGradient.Rotation = (rainbowGradient.Rotation + (RAINBOW_SPEED_DEG_PER_SEC * deltaTime)) % 360
	end)

	table.insert(uiConnections, toggleButton.MouseButton1Click:Connect(function()
		setEnabled(not enabledState)
	end))

	emitLog("INFO", "anti_fling_gui_created", { initialState = "OFF", draggable = true })

	local controller: AntiFlingController = {
		gui = screenGui,
		setEnabled = function(_self: AntiFlingController, state: boolean): ()
			setEnabled(state)
		end,
		isEnabled = function(_self: AntiFlingController): boolean
			return enabledState
		end,
		destroy = destroy,
	}

	return controller
end

local antiFlingController = createAntiFlingDraggableGui()

return {
	createAntiFlingDraggableGui = createAntiFlingDraggableGui,
	controller = antiFlingController,
}
