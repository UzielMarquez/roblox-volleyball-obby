--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LobbyService = {}

local function ensureRemote(folder: Folder, name: string): RemoteEvent
	local remote = folder:FindFirstChild(name)
	if remote and remote:IsA("RemoteEvent") then return remote end
	local event = Instance.new("RemoteEvent")
	event.Name = name
	event.Parent = folder
	return event
end

function LobbyService.GetRemotes(): Folder
	local shared = ReplicatedStorage:WaitForChild("Shared")
	local folder = shared:FindFirstChild("Remotes")
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = "Remotes"
		folder.Parent = shared
	end
	assert(folder:IsA("Folder"), "Shared.Remotes debe ser Folder")
	for _, name in ipairs({ "QueueRequest", "MatchState", "BallAction", "ServeCharge", "ServePower", "SettingsRequest", "ObbyRequest", "ObbyState" }) do
		ensureRemote(folder, name)
	end
	return folder
end

function LobbyService.Prepare(world: Model)
	local lobby = world:WaitForChild("Lobby")
	local controls = lobby:FindFirstChild("ControlsSign")
	local display = controls and controls:FindFirstChild("ControlsDisplay")
	local text = display and display:FindFirstChild("Text")
	if text and text:IsA("TextLabel") then
		text.Text = "VOLEIBOL\nJUGAR: unirse a la cola\nENTRENAMIENTO: practicar el saque\nOBBY: circuito de calentamiento\nE: recibir o cargar el saque"
	end

	local entry = lobby:FindFirstChild("ObbyEntry")
	if not entry then
		local pad = Instance.new("Part")
		pad.Name = "ObbyEntry"
		pad.Size = Vector3.new(8, 0.7, 8)
		pad.Position = Vector3.new(0, 0.35, 210)
		pad.Anchored = true
		pad.Material = Enum.Material.Neon
		pad.Color = Color3.fromRGB(245, 170, 45)
		pad.Parent = lobby
		local prompt = Instance.new("ProximityPrompt")
		prompt.ActionText = "ENTRAR"
		prompt.ObjectText = "Obby de Calentamiento"
		prompt.HoldDuration = 0
		prompt.MaxActivationDistance = 12
		prompt.Parent = pad
	end
end

return LobbyService
