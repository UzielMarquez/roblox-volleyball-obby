--!strict

local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Keybinds = require(ReplicatedStorage.Shared.Keybinds)

local InputController = {}

function InputController.Start(remotes: Folder, hud)
	local player = Players.LocalPlayer
	local charging = false
	local chargeStarted = 0
	local actionNames = { "Serve", "Set", "Spike", "Block", "Dive" }
	local defaultKeys = {
		Serve = Keybinds.Serve, Set = Keybinds.Set, Spike = Keybinds.Spike,
		Block = Keybinds.Block, Dive = Keybinds.Dive,
	}
	local currentBindings: { [string]: Enum.KeyCode } = table.clone(defaultKeys)
	local function cameraDirection(): Vector3
		local camera = workspace.CurrentCamera
		return if camera then camera.CFrame.LookVector else Vector3.xAxis
	end
	local function keyCodeFromName(name: any, fallback: Enum.KeyCode): Enum.KeyCode
		if type(name) == "string" then
			for _, keyCode in ipairs(Enum.KeyCode:GetEnumItems()) do
				if keyCode.Name == name then return keyCode end
			end
		end
		return fallback
	end
	local function serveAction(_, state)
		if player:GetAttribute("InMatch") ~= true and player:GetAttribute("GameState") ~= "Serve" then return Enum.ContextActionResult.Pass end
		if state == Enum.UserInputState.Begin and not charging then
			if player:GetAttribute("GameState") == "Serve" then
				charging = true
				chargeStarted = os.clock()
				hud.Power.Visible = true
				remotes.ServeCharge:FireServer("Start")
			else
				remotes.BallAction:FireServer("Bump", cameraDirection())
			end
			return Enum.ContextActionResult.Sink
		elseif (state == Enum.UserInputState.End or state == Enum.UserInputState.Cancel) and charging then
			charging = false
			remotes.ServeCharge:FireServer("Release", cameraDirection())
			hud.Power.Visible = false
			return Enum.ContextActionResult.Sink
		end
		return Enum.ContextActionResult.Pass
	end
	local gamepadKeys = { Serve = Enum.KeyCode.ButtonX, Set = Enum.KeyCode.ButtonY, Spike = Enum.KeyCode.ButtonB, Block = Enum.KeyCode.ButtonL1, Dive = Enum.KeyCode.ButtonR1 }
	local function bindActions()
		if charging then remotes.ServeCharge:FireServer("Release", cameraDirection()) end
		for _, name in ipairs(actionNames) do ContextActionService:UnbindAction("Volley_" .. name) end
		charging = false
		hud.Power.Visible = false
		ContextActionService:BindAction("Volley_Serve", serveAction, true, currentBindings.Serve, gamepadKeys.Serve)
		ContextActionService:SetTitle("Volley_Serve", "Recibir / Sacar")
		for _, name in ipairs({ "Set", "Spike", "Block", "Dive" }) do
			ContextActionService:BindAction("Volley_" .. name, function(_, state)
				if state == Enum.UserInputState.Begin then remotes.BallAction:FireServer(name, cameraDirection()) end
				return Enum.ContextActionResult.Sink
			end, true, currentBindings[name], gamepadKeys[name])
			ContextActionService:SetTitle("Volley_" .. name, name)
		end
	end
	local settingsConnection = remotes.SettingsRequest.OnClientEvent:Connect(function(actionName, settings)
		if actionName ~= "Settings" or type(settings) ~= "table" or type(settings.Keybinds) ~= "table" then return end
		for _, name in ipairs(actionNames) do currentBindings[name] = keyCodeFromName(settings.Keybinds[name], defaultKeys[name]) end
		bindActions()
	end)
	local inputEndedConnection = UserInputService.InputEnded:Connect(function(input)
		if input.KeyCode == currentBindings.Serve and (charging or player:GetAttribute("GameState") == "Serve") then
			charging = false
			remotes.ServeCharge:FireServer("Release", cameraDirection())
			hud.Power.Visible = false
		end
	end)
	local powerConnection = remotes.ServePower.OnClientEvent:Connect(function(actionName, value)
		if actionName == "Released" then hud.PowerFill.Size = UDim2.fromScale(math.clamp(value, 0, 1), 1) end
	end)
	local renderConnection = RunService.RenderStepped:Connect(function()
		if charging then hud.PowerFill.Size = UDim2.fromScale(math.clamp((os.clock() - chargeStarted) / 8, 0, 1), 1) end
	end)
	bindActions()
	remotes.SettingsRequest:FireServer("Get")
	return function()
		renderConnection:Disconnect()
		powerConnection:Disconnect()
		inputEndedConnection:Disconnect()
		settingsConnection:Disconnect()
		for _, name in ipairs(actionNames) do ContextActionService:UnbindAction("Volley_" .. name) end
	end
end

return InputController
