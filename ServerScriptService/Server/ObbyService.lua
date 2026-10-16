--!strict

local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")
local BadgeService = game:GetService("BadgeService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage.Shared.Config)
local ObbyConfig = require(ReplicatedStorage.Shared.ObbyConfig)
local StageBuilder = require(script.Parent.StageBuilder)
local ObbyValidator = require(script.Parent.ObbyValidator)
local HazardService = require(script.Parent.HazardService)
local ObbyDataService = require(script.Parent.ObbyDataService)

local ObbyService = {}

function ObbyService.Start(world: Model, remotes: Folder)
	local obby = StageBuilder.Build(world)
	local stagesFolder = obby:WaitForChild("Stages") :: Folder
	local request = remotes:WaitForChild("ObbyRequest") :: RemoteEvent
	local stateRemote = remotes:WaitForChild("ObbyState") :: RemoteEvent
	local activeTimers: { [Player]: number } = {}
	local pausedElapsed: { [Player]: number } = {}
	local checkpoints: { [Player]: CFrame } = {}
	local rates: { [Player]: number } = {}

	local valid, errors = ObbyValidator.Validate(stagesFolder)
	if not valid then
		for _, message in ipairs(errors) do warn("[ObbyValidator] " .. message) end
	else
		print("[ObbyValidator] 20 etapas válidas; huecos y alturas dentro de los límites.")
	end

	local function stagePart(stage: number): BasePart?
		local model = stagesFolder:FindFirstChild(string.format("Stage%02d", math.clamp(stage, 1, ObbyConfig.StageCount)))
		local checkpoint = model and (model:FindFirstChild("Checkpoint") or model:FindFirstChild("Finish"))
		return if checkpoint and checkpoint:IsA("BasePart") then checkpoint else nil
	end

	local function getCheckpoint(player: Player): CFrame?
		return checkpoints[player] or (obby:FindFirstChild("StartPoint") :: BasePart).CFrame + Vector3.new(0, 4, 0)
	end

	local function fire(player: Player, message: string)
		local data = ObbyDataService.Get(player)
		stateRemote:FireClient(player, {
			Stage = data.Stage, MaxStage = ObbyConfig.StageCount, Message = message,
			BestTime = data.BestTime, Elapsed = (pausedElapsed[player] or 0) + (if activeTimers[player] then os.clock() - activeTimers[player] else 0),
			InObby = player:GetAttribute("InObby") == true, Completed = data.Completed,
		})
	end

	local function teleportToCheckpoint(player: Player)
		local character = player.Character
		local target = getCheckpoint(player)
		if character and target then character:PivotTo(target) end
	end

	local function enter(player: Player)
		if player:GetAttribute("InMatch") then return end
		local data = ObbyDataService.Get(player)
		player:SetAttribute("InObby", true)
		local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			humanoid.WalkSpeed = 16
			humanoid.JumpHeight = 7.2
		end
		local destinationStage = math.max(data.Stage, 1)
		local spawnPart = if data.Stage == 0 then obby:FindFirstChild("StartPoint") else stagePart(destinationStage)
		if spawnPart and spawnPart:IsA("BasePart") then
			local spawnCFrame = if data.Stage == 0 then spawnPart.CFrame + Vector3.new(0, 4, 0) else spawnPart.CFrame + Vector3.new(-7, 4, 0)
			checkpoints[player] = spawnCFrame
			if player.Character then player.Character:PivotTo(spawnCFrame) end
		end
		if data.Stage > 0 and not activeTimers[player] then activeTimers[player] = os.clock() end
		fire(player, "¡Bienvenido al Obby! Llega a cada checkpoint en orden.")
	end

	local function leave(player: Player, returningFromMatch: boolean?)
		player:SetAttribute("InObby", false)
		if not returningFromMatch then
			activeTimers[player] = nil
			pausedElapsed[player] = nil
			local spawn = world.Lobby:FindFirstChild("LobbySpawn")
			if spawn and spawn:IsA("BasePart") and player.Character then player.Character:PivotTo(spawn.CFrame + Vector3.new(0, 4, 0)) end
		end
		fire(player, "Has salido del obby.")
	end

	local function complete(player: Player)
		local elapsed = (pausedElapsed[player] or 0) + (if activeTimers[player] then os.clock() - activeTimers[player] else 0)
		ObbyDataService.Complete(player, elapsed)
		activeTimers[player] = nil
		pausedElapsed[player] = nil
		local badgeId = ObbyConfig.BadgeId
		if badgeId > 0 then
			local ok, err = pcall(function() BadgeService:AwardBadge(player.UserId, badgeId) end)
			if not ok then warn("No se pudo otorgar la insignia: " .. tostring(err)) end
		end
		fire(player, string.format("¡Obby completado en %.1f s! Desbloqueaste una estela para el balón.", elapsed))
	end

	local function onCheckpoint(part: BasePart, hit: BasePart)
		local character = hit:FindFirstAncestorOfClass("Model")
		local player = if character then Players:GetPlayerFromCharacter(character) else nil
		if not player or not player:GetAttribute("InObby") then return end
		local stage = part:GetAttribute("Stage")
		if type(stage) ~= "number" then return end
		local data = ObbyDataService.Get(player)
		if stage ~= data.Stage + 1 then return end
		ObbyDataService.SetStage(player, stage)
		checkpoints[player] = part.CFrame + Vector3.new(0, 4, 0)
		if stage == 1 and not activeTimers[player] then activeTimers[player] = os.clock() end
		local stats = player:FindFirstChild("leaderstats")
		local stageStat = stats and stats:FindFirstChild("Etapa")
		if stageStat and stageStat:IsA("IntValue") then stageStat.Value = stage end
		if stage == ObbyConfig.StageCount then complete(player) else fire(player, "¡Checkpoint " .. stage .. "/" .. ObbyConfig.StageCount .. "!") end
		task.spawn(ObbyDataService.Save, player)
	end

	local function pauseForMatch(player: Player)
		if activeTimers[player] then
			pausedElapsed[player] = (pausedElapsed[player] or 0) + os.clock() - activeTimers[player]
			activeTimers[player] = nil
		end
	end

	for _, part in ipairs(CollectionService:GetTagged("Checkpoint")) do
		if part:IsDescendantOf(obby) and part:IsA("BasePart") then part.Touched:Connect(function(hit) onCheckpoint(part, hit) end) end
	end
	HazardService.Start(obby, getCheckpoint)

	local lobbyEntry = world.Lobby:FindFirstChild("ObbyEntry")
	local prompt = lobbyEntry and lobbyEntry:FindFirstChildOfClass("ProximityPrompt")
	if prompt then prompt.Triggered:Connect(enter) end
	local finish = stagePart(ObbyConfig.StageCount)
	local finishPrompt = finish and finish:FindFirstChild("ReturnLobbyPrompt")
	if finishPrompt and finishPrompt:IsA("ProximityPrompt") then
		finishPrompt.Triggered:Connect(function(player) leave(player) end)
	end
	local startPoint = obby:FindFirstChild("StartPoint")
	local startPrompt = startPoint and startPoint:FindFirstChildOfClass("ProximityPrompt")
	if startPrompt then startPrompt.Triggered:Connect(enter) end

	local function setupPlayer(player: Player)
		task.spawn(function()
			local data = ObbyDataService.Load(player)
			local stats = player:WaitForChild("leaderstats", 10)
			if not stats then
				stats = Instance.new("Folder")
				stats.Name = "leaderstats"
				stats.Parent = player
			end
			local stageStat = stats:FindFirstChild("Etapa") or Instance.new("IntValue")
			stageStat.Name = "Etapa"
			stageStat.Value = data.Stage
			stageStat.Parent = stats
			player.CharacterAdded:Connect(function(character)
				task.wait(0.25)
				if player:GetAttribute("InObby") then
					local humanoid = character:FindFirstChildOfClass("Humanoid")
					if humanoid then humanoid.WalkSpeed = 16; humanoid.JumpHeight = 7.2 end
					teleportToCheckpoint(player)
				end
			end)
		end)
	end
	for _, player in ipairs(Players:GetPlayers()) do setupPlayer(player) end
	Players.PlayerAdded:Connect(setupPlayer)
	Players.PlayerRemoving:Connect(function(player)
		task.spawn(ObbyDataService.Save, player)
		activeTimers[player] = nil
		pausedElapsed[player] = nil
		checkpoints[player] = nil
	end)

	request.OnServerEvent:Connect(function(player: Player, action: any)
		if type(action) ~= "string" then return end
		local now = os.clock()
		if rates[player] and now - rates[player] < 0.2 then return end
		rates[player] = now
		if action == "Enter" then enter(player)
		elseif action == "Leave" then leave(player)
		elseif action == "Reset" and player:GetAttribute("InObby") then teleportToCheckpoint(player)
		elseif action == "Status" then fire(player, "")
		end
	end)

	local board = Instance.new("Part")
	board.Name = "ObbyLeaderboard"
	board.Size = Vector3.new(12, 7, 0.5)
	board.CFrame = CFrame.new(-25, 5, 203)
	board.Anchored = true
	board.Color = Color3.fromRGB(35, 45, 60)
	board.Parent = world.Lobby
	local surface = Instance.new("SurfaceGui")
	surface.Face = Enum.NormalId.Back
	surface.Parent = board
	local text = Instance.new("TextLabel")
	text.Name = "TopTimes"
	text.Size = UDim2.fromScale(1, 1)
	text.BackgroundTransparency = 1
	text.TextColor3 = Color3.new(1, 1, 1)
	text.TextScaled = true
	text.Font = Enum.Font.GothamBold
	text.Text = "MEJORES TIEMPOS\nSe cargan al publicar"
	text.Parent = surface
	task.spawn(function()
		while board.Parent do
			local top = ObbyDataService.GetTop(5)
			local lines = { "MEJORES TIEMPOS" }
			for rank, item in ipairs(top) do table.insert(lines, string.format("%d. %s — %.1f s", rank, tostring(item.UserId), item.Time)) end
			text.Text = table.concat(lines, "\n")
			task.wait(Config.Obby.LeaderboardRefreshSeconds)
		end
	end)

	return {
		Enter = enter,
		Leave = leave,
		PauseForMatch = pauseForMatch,
		ReturnFromMatch = function(player: Player)
			player:SetAttribute("InObby", true)
			if ObbyDataService.Get(player).Stage > 0 then activeTimers[player] = os.clock() end
			teleportToCheckpoint(player)
			fire(player, "De vuelta en tu checkpoint.")
		end,
	}
end

return ObbyService
