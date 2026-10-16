--!strict

local Players = game:GetService("Players")

local HUD = {}

function HUD.Create()
	local player = Players.LocalPlayer
	local gui = Instance.new("ScreenGui")
	gui.Name = "VolleyballHUD"
	gui.ResetOnSpawn = false
	gui.Parent = player:WaitForChild("PlayerGui")
	local container = Instance.new("Frame")
	container.Name = "Panel"
	container.Size = UDim2.fromOffset(350, 118)
	container.Position = UDim2.new(0.5, -175, 0, 12)
	container.BackgroundColor3 = Color3.fromRGB(20, 30, 45)
	container.BackgroundTransparency = 0.18
	container.Parent = gui
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 12)
	corner.Parent = container
	local status = Instance.new("TextLabel")
	status.Name = "Status"
	status.Size = UDim2.new(1, -16, 0, 34)
	status.Position = UDim2.fromOffset(8, 4)
	status.BackgroundTransparency = 1
	status.Font = Enum.Font.GothamBold
	status.TextColor3 = Color3.new(1, 1, 1)
	status.TextScaled = true
	status.Text = "VOLEIBOL"
	status.Parent = container
	local score = status:Clone()
	score.Name = "Score"
	score.Position = UDim2.fromOffset(8, 39)
	score.Text = "A 0 - 0 B"
	score.Parent = container
	local queue = Instance.new("TextButton")
	queue.Name = "QueueButton"
	queue.Size = UDim2.fromOffset(104, 30)
	queue.Position = UDim2.fromOffset(8, 80)
	queue.Text = "JUGAR"
	queue.Font = Enum.Font.GothamBold
	queue.TextScaled = true
	queue.TextColor3 = Color3.new(1, 1, 1)
	queue.BackgroundColor3 = Color3.fromRGB(40, 175, 95)
	queue.Parent = container
	local training = queue:Clone()
	training.Name = "TrainingButton"
	training.Position = UDim2.fromOffset(120, 80)
	training.Text = "ENTRENAR"
	training.BackgroundColor3 = Color3.fromRGB(45, 125, 205)
	training.Parent = container
	local settings = queue:Clone()
	settings.Name = "SettingsButton"
	settings.Position = UDim2.fromOffset(232, 80)
	settings.Text = "AJUSTES"
	settings.BackgroundColor3 = Color3.fromRGB(100, 90, 150)
	settings.Parent = container
	local power = Instance.new("Frame")
	power.Name = "PowerBar"
	power.Size = UDim2.fromOffset(240, 18)
	power.Position = UDim2.new(0.5, -120, 1, -42)
	power.BackgroundColor3 = Color3.fromRGB(30, 35, 45)
	power.Visible = false
	power.Parent = gui
	local fill = Instance.new("Frame")
	fill.Name = "Fill"
	fill.Size = UDim2.fromScale(0.05, 1)
	fill.BackgroundColor3 = Color3.fromRGB(70, 225, 115)
	fill.Parent = power
	local powerText = Instance.new("TextLabel")
	powerText.Name = "PowerText"
	powerText.Size = UDim2.new(1, 0, 0, 22)
	powerText.Position = UDim2.new(0, 0, 0, -23)
	powerText.BackgroundTransparency = 1
	powerText.Text = "MANTÉN E PARA CARGAR — SUELTA PARA SACAR"
	powerText.TextColor3 = Color3.new(1, 1, 1)
	powerText.TextScaled = true
	powerText.Font = Enum.Font.GothamBold
	powerText.Parent = power
	local obby = queue:Clone()
	obby.Name = "ObbyButton"
	obby.Size = UDim2.fromOffset(130, 34)
	obby.Position = UDim2.new(1, -140, 1, -45)
	obby.Text = "SALIR DEL OBBY"
	obby.BackgroundColor3 = Color3.fromRGB(225, 130, 45)
	obby.Visible = false
	obby.Parent = gui
	local reset = obby:Clone()
	reset.Name = "ResetStageButton"
	reset.Position = UDim2.new(1, -280, 1, -45)
	reset.Text = "REINICIAR ETAPA"
	reset.Parent = gui
	return {
		Gui = gui, Status = status, Score = score, Queue = queue, Training = training,
		Settings = settings, Power = power, PowerFill = fill, Obby = obby, Reset = reset,
	}
end

return HUD
