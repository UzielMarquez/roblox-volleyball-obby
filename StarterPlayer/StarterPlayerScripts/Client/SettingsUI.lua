--!strict

local SettingsUI = {}

function SettingsUI.Bind(button: TextButton, remotes: Folder)
	local panel: Frame? = nil
	local keyButtons: { [string]: TextButton } = {}
	local currentKeys = { Serve = "E", Set = "F", Spike = "R", Block = "Q", Dive = "C", CameraToggle = "V" }
	local currentMouseLookMode = "ShiftLock"
	local waitingAction: string? = nil
	local captureConnection: RBXScriptConnection? = nil
	local settingsConnection: RBXScriptConnection? = nil
	local defaults = { Serve = "E", Set = "F", Spike = "R", Block = "Q", Dive = "C", CameraToggle = "V" }
	local actions = {
		{ "Serve", "Recibir / sacar" }, { "Set", "Colocar" }, { "Spike", "Rematar" },
		{ "Block", "Bloquear" }, { "Dive", "Lanzarse" }, { "CameraToggle", "Alternar primera persona" },
	}
	local actionLabels = { Serve = "Recibir / sacar", Set = "Colocar", Spike = "Rematar", Block = "Bloquear", Dive = "Lanzarse", CameraToggle = "Alternar primera persona" }
	local function stopCapture()
		waitingAction = nil
		if captureConnection then captureConnection:Disconnect(); captureConnection = nil end
	end
	local function updateKeyLabels()
		for actionName, control in pairs(keyButtons) do
			control.Text = string.format("%s  [%s]", actionLabels[actionName], currentKeys[actionName] or defaults[actionName])
		end
	end
	button.Activated:Connect(function()
		if panel then
			stopCapture()
			if settingsConnection then settingsConnection:Disconnect(); settingsConnection = nil end
			panel:Destroy()
			panel = nil
			return
		end
		local parent = button.Parent
		if not parent then return end
		panel = Instance.new("Frame")
		panel.Name = "SettingsPanel"
		panel.Size = UDim2.fromOffset(340, 340)
		panel.Position = UDim2.new(1, -350, 0, 130)
		panel.BackgroundColor3 = Color3.fromRGB(30, 40, 55)
		panel.Parent = parent
		local function makeButton(name: string, text: string, y: number, height: number): TextButton
			local control = Instance.new("TextButton")
			control.Name = name
			control.Size = UDim2.new(1, -12, 0, height)
			control.Position = UDim2.fromOffset(6, y)
			control.Text = text
			control.TextScaled = true
			control.Parent = panel
			return control
		end
		for index, binding in ipairs(actions) do
			local actionName, label = binding[1], binding[2]
			local control = makeButton("Keybind_" .. actionName, label .. "  [" .. currentKeys[actionName] .. "]", 6 + (index - 1) * 34, 30)
			keyButtons[actionName] = control
			control.Activated:Connect(function()
				stopCapture()
				waitingAction = actionName
				control.Text = label .. " — presiona una tecla"
				captureConnection = game:GetService("UserInputService").InputBegan:Connect(function(input, processed)
					if processed or not waitingAction or input.KeyCode == Enum.KeyCode.Unknown then return end
					local selected = waitingAction
					stopCapture()
					remotes.SettingsRequest:FireServer("Keybind_" .. selected, input.KeyCode.Name)
				end)
			end)
		end
		local mouseMode = makeButton("MouseLookMode", "Modo de cámara: ShiftLock", 216, 30)
		mouseMode.Activated:Connect(function()
			currentMouseLookMode = if currentMouseLookMode == "ShiftLock" then "RightClick" else "ShiftLock"
			mouseMode.Text = "Modo de cámara: " .. currentMouseLookMode
			remotes.SettingsRequest:FireServer("MouseLookMode", currentMouseLookMode)
		end)
		local reset = makeButton("ResetKeybinds", "Restaurar controles predeterminados", 252, 30)
		reset.Activated:Connect(function()
			stopCapture()
			for actionName, keyName in pairs(defaults) do
				remotes.SettingsRequest:FireServer("Keybind_" .. actionName, "Default")
				currentKeys[actionName] = keyName
			end
			currentMouseLookMode = "ShiftLock"
			remotes.SettingsRequest:FireServer("MouseLookMode", currentMouseLookMode)
			mouseMode.Text = "Modo de cámara: " .. currentMouseLookMode
			updateKeyLabels()
		end)
		local status = Instance.new("TextLabel")
		status.Name = "Status"
		status.Size = UDim2.new(1, -12, 0, 36)
		status.Position = UDim2.fromOffset(6, 288)
		status.BackgroundTransparency = 1
		status.Text = "WASD para moverte; usa los botones táctiles en móvil."
		status.TextColor3 = Color3.new(1, 1, 1)
		status.TextScaled = true
		status.Parent = panel
		settingsConnection = remotes.SettingsRequest.OnClientEvent:Connect(function(actionName, settings)
			if actionName == "Settings" and type(settings) == "table" then
				if type(settings.Keybinds) == "table" then
					for key in pairs(defaults) do
						if type(settings.Keybinds[key]) == "string" then currentKeys[key] = settings.Keybinds[key] end
					end
					updateKeyLabels()
				end
				if settings.MouseLookMode == "ShiftLock" or settings.MouseLookMode == "RightClick" then
					currentMouseLookMode = settings.MouseLookMode
					mouseMode.Text = "Modo de cámara: " .. currentMouseLookMode
				end
			elseif actionName == "Error" then
				status.Text = tostring(settings)
			end
		end)
		remotes.SettingsRequest:FireServer("Get")
	end)
end

return SettingsUI
