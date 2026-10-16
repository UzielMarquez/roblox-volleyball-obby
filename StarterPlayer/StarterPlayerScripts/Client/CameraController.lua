--!strict

local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Keybinds = require(ReplicatedStorage.Shared.Keybinds)

local CameraController = {}

local MIN_ZOOM = 0.5
local MAX_ZOOM = 25
local THIRD_PERSON_RESET_DISTANCE = 6

function CameraController.Start(remotes: Folder)
	local player = Players.LocalPlayer
	local lookMode = "ShiftLock"
	local toggleKey = Keybinds.CameraToggle or Enum.KeyCode.V
	local character: Model? = nil
	local humanoid: Humanoid? = nil
	local cameraTypeConnection: RBXScriptConnection? = nil
	local characterDescendantConnection: RBXScriptConnection? = nil
	local bodyHidden = false

	local function setBodyHidden(hidden: boolean)
		if bodyHidden == hidden then return end
		bodyHidden = hidden
		if not character then return end
		for _, item in ipairs(character:GetDescendants()) do
			if item:IsA("BasePart") then
				item.LocalTransparencyModifier = if hidden then 1 else 0
			end
		end
	end

	local function isFirstPerson(camera: Camera): boolean
		return player.CameraMode == Enum.CameraMode.LockFirstPerson
			or (camera.Focus.Position - camera.CFrame.Position).Magnitude <= 1.1
	end

	local function bindCharacter(newCharacter: Model)
		setBodyHidden(false)
		if characterDescendantConnection then characterDescendantConnection:Disconnect() end
		character = newCharacter
		humanoid = newCharacter:WaitForChild("Humanoid") :: Humanoid
		characterDescendantConnection = newCharacter.DescendantAdded:Connect(function(item)
			if bodyHidden and item:IsA("BasePart") then item.LocalTransparencyModifier = 1 end
		end)
		local camera = workspace.CurrentCamera
		if camera then
			camera.CameraType = Enum.CameraType.Custom
			camera.CameraSubject = humanoid
		end
	end

	local function setCamera(camera: Camera?)
		if cameraTypeConnection then
			cameraTypeConnection:Disconnect()
			cameraTypeConnection = nil
		end
		if not camera then return end
		camera.CameraType = Enum.CameraType.Custom
		if humanoid then camera.CameraSubject = humanoid end
		cameraTypeConnection = camera:GetPropertyChangedSignal("CameraType"):Connect(function()
			if camera.CameraType ~= Enum.CameraType.Custom then
				camera.CameraType = Enum.CameraType.Custom
			end
		end)
	end

	local function toggleFirstPerson()
		local camera = workspace.CurrentCamera
		local currentlyFirstPerson = player.CameraMode == Enum.CameraMode.LockFirstPerson
			or (camera ~= nil and isFirstPerson(camera))
		if currentlyFirstPerson then
			player.CameraMode = Enum.CameraMode.Classic
			player.CameraMinZoomDistance = THIRD_PERSON_RESET_DISTANCE
			task.delay(0.15, function()
				if player.Parent then player.CameraMinZoomDistance = MIN_ZOOM end
			end)
		else
			player.CameraMode = Enum.CameraMode.LockFirstPerson
			player.CameraMinZoomDistance = MIN_ZOOM
		end
	end

	local function cameraToggleAction(_, inputState: Enum.UserInputState)
		if inputState == Enum.UserInputState.Begin then toggleFirstPerson() end
		return Enum.ContextActionResult.Sink
	end

	local settingsConnection = remotes.SettingsRequest.OnClientEvent:Connect(function(action, settings)
		if action ~= "Settings" or type(settings) ~= "table" then return end
		if settings.MouseLookMode == "ShiftLock" or settings.MouseLookMode == "RightClick" then
			lookMode = settings.MouseLookMode
		end
		if type(settings.Keybinds) == "table" then
			for _, keyCode in ipairs(Enum.KeyCode:GetEnumItems()) do
				if keyCode.Name == settings.Keybinds.CameraToggle then
					toggleKey = keyCode
					break
				end
			end
			ContextActionService:UnbindAction("Volley_CameraToggle")
			ContextActionService:BindAction("Volley_CameraToggle", cameraToggleAction, false, toggleKey)
		end
	end)

	player.CameraMode = Enum.CameraMode.Classic
	player.CameraMinZoomDistance = MIN_ZOOM
	player.CameraMaxZoomDistance = MAX_ZOOM
	ContextActionService:BindAction("Volley_CameraToggle", cameraToggleAction, false, toggleKey)

	if player.Character then bindCharacter(player.Character) end
	local characterAddedConnection = player.CharacterAdded:Connect(bindCharacter)
	local cameraChangedConnection = workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
		setCamera(workspace.CurrentCamera)
	end)
	setCamera(workspace.CurrentCamera)

	local renderConnection = RunService.RenderStepped:Connect(function()
		local camera = workspace.CurrentCamera
		if not camera then return end

		local firstPerson = isFirstPerson(camera)
		local inMatch = player:GetAttribute("InMatch") == true
		local playerGui = player:FindFirstChildOfClass("PlayerGui")
		local hud = playerGui and playerGui:FindFirstChild("VolleyballHUD")
		local panel = hud and hud:FindFirstChild("Panel")
		local settingsPanel = panel and panel:FindFirstChild("SettingsPanel")
		local settingsOpen = settingsPanel and settingsPanel:IsA("GuiObject") and settingsPanel.Visible
		local lockCenter = firstPerson or (inMatch and lookMode == "ShiftLock" and not settingsOpen)
		if UserInputService.TouchEnabled and not UserInputService.MouseEnabled and not firstPerson then
			lockCenter = false
		end
		UserInputService.MouseBehavior = if lockCenter then Enum.MouseBehavior.LockCenter else Enum.MouseBehavior.Default
		UserInputService.MouseIconEnabled = not lockCenter
		setBodyHidden(firstPerson)
	end)

	remotes.SettingsRequest:FireServer("Get")
	return function()
		renderConnection:Disconnect()
		characterAddedConnection:Disconnect()
		cameraChangedConnection:Disconnect()
		settingsConnection:Disconnect()
		if cameraTypeConnection then cameraTypeConnection:Disconnect() end
		if characterDescendantConnection then characterDescendantConnection:Disconnect() end
		setBodyHidden(false)
		ContextActionService:UnbindAction("Volley_CameraToggle")
		UserInputService.MouseBehavior = Enum.MouseBehavior.Default
		UserInputService.MouseIconEnabled = true
	end
end

return CameraController
