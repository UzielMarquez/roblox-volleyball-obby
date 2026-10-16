--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage.Shared.Config)
local MatchService = require(script.Parent.MatchService)
local BallService = require(script.Parent.BallService)
local DataService = require(script.Parent.DataService)

local GameService = {}

function GameService.Start(world: Model, remotes: Folder, returnToObby: (Player) -> (), pauseObby: (Player) -> ())
	local queueRemote = remotes:WaitForChild("QueueRequest") :: RemoteEvent
	local stateRemote = remotes:WaitForChild("MatchState") :: RemoteEvent
	local settingsRemote = remotes:WaitForChild("SettingsRequest") :: RemoteEvent
	local queue: { Player } = {}
	local active: { [Player]: boolean } = {}
	local teams: { [string]: { Player } } = { A = {}, B = {} }
	local positions: { [Player]: number } = {}
	local scores = { A = 0, B = 0 }
	local sets = { A = 0, B = 0 }
	local setNumber = 1
	local servingSide = "A"
	local servingPlayer: Player? = nil
	local state = "Lobby"
	local training = false
	local countdownToken = 0
	local rateLimits: { [Player]: number } = {}
	local matchStats: { [Player]: { Aces: number, Spikes: number, Blocks: number } } = {}
	local ballController

	local function publish(message: string?)
		local packet = {
			State = state, QueueCount = #queue, TeamSize = Config.TEAM_SIZE,
			ScoreA = scores.A, ScoreB = scores.B, SetsA = sets.A, SetsB = sets.B,
			SetNumber = setNumber, ServingSide = servingSide,
			Touches = ballController and ballController.GetTouches() or 0,
			Message = message or "",
			Queued = {},
		}
		for _, player in ipairs(queue) do packet.Queued[player.UserId] = true end
		stateRemote:FireAllClients(packet)
	end

	local function removeFromQueue(player: Player)
		local index = table.find(queue, player)
		if index then table.remove(queue, index) end
		publish()
	end

	local function teleportLobby(player: Player)
		local spawn = world.Lobby:FindFirstChild("LobbySpawn")
		if spawn and spawn:IsA("BasePart") and player.Character then
			player.Character:PivotTo(spawn.CFrame + Vector3.new(0, 4, 0))
		end
		player:SetAttribute("TeamSide", nil)
	end

	local function endMatch(winner: string)
		state = "Results"
		if ballController then ballController.SetRally(false) end
		for _, team in pairs(teams) do
			for _, player in ipairs(team) do
				local data = DataService.Get(player)
				if data then
					DataService.Update(player, "Matches", 1)
					if player:GetAttribute("TeamSide") == winner then DataService.Update(player, "Wins", 1) end
				end
				player:SetAttribute("InMatch", false)
				if player:GetAttribute("WasInObby") then
					player:SetAttribute("WasInObby", false)
					returnToObby(player)
				else
					teleportLobby(player)
				end
				local stats = player:FindFirstChild("leaderstats")
				local dataNow = DataService.Get(player)
				if stats and dataNow then
					for _, key in ipairs({ "Matches", "Wins", "Points" }) do
						local value = stats:FindFirstChild(key)
						if value and value:IsA("IntValue") then value.Value = dataNow[key] end
					end
				end
			end
		end
		publish("¡Gana el equipo " .. winner .. "!")
		task.delay(8, function()
			for player in pairs(active) do if player.Parent then active[player] = nil end end
			teams = { A = {}, B = {} }
			state = "Lobby"
			training = false
			publish("Partido finalizado")
		end)
	end

	local function prepareServe()
		state = "Serve"
		if ballController then
			ballController.ResetForServe(servingSide)
			ballController.SetRally(false)
		end
		servingPlayer = teams[servingSide][1]
		if servingPlayer then
			for _, candidate in ipairs(teams[servingSide]) do
				if positions[candidate] == 1 then servingPlayer = candidate; break end
			end
			local serveX = if servingSide == "A" then -36 else 36
			if servingPlayer.Character then
				servingPlayer.Character:PivotTo(CFrame.lookAt(Vector3.new(serveX, 3, 0), Vector3.new(0, 3, 0)))
			end
			servingPlayer:SetAttribute("Serving", true)
		end
		local deadline = os.clock() + Config.SERVE_LIMIT_SECONDS
		publish("Saque del equipo " .. servingSide .. " — mantén E y suelta para sacar")
		task.spawn(function()
			while state == "Serve" and servingPlayer and os.clock() < deadline do task.wait(0.25) end
			if state == "Serve" and servingPlayer then
				local faultWinner = if servingSide == "A" then "B" else "A"
				GameService.OnPoint(faultWinner, "Se agotó el tiempo de saque")
			end
		end)
	end

	local function startMatch(players: { Player }, isTraining: boolean)
		training = isTraining
		for _, queuedPlayer in ipairs(queue) do queuedPlayer:SetAttribute("InQueue", false) end
		queue = {}
		active = {}
		teams = { A = {}, B = {} }
		positions = {}
		scores = { A = 0, B = 0 }
		sets = { A = 0, B = 0 }
		setNumber = 1
		servingSide = "A"
		local left, right = MatchService.Balance(players, Config.TEAM_SIZE)
		teams.A, teams.B = left, right
		for _, team in ipairs({ left, right }) do
			for index, player in ipairs(team) do
				active[player] = true
				positions[player] = index
				matchStats[player] = { Aces = 0, Spikes = 0, Blocks = 0 }
				player:SetAttribute("WasInObby", player:GetAttribute("InObby") == true)
				if player:GetAttribute("WasInObby") then pauseObby(player) end
				player:SetAttribute("InObby", false)
				player:SetAttribute("InMatch", true)
				player:SetAttribute("TeamSide", if table.find(left, player) then "A" else "B")
				if player.Character then player.Character:PivotTo(MatchService.GetPosition(player:GetAttribute("TeamSide"), index, #team)) end
			end
		end
		state = if isTraining then "Training" else "Preparation"
		publish(if isTraining then "Entrenamiento — practica tus golpes" else "¡Partido iniciado!")
		if not isTraining then task.wait(1) end
		prepareServe()
	end

	local function enoughPlayers(): boolean
		return (#queue >= Config.TEAM_SIZE * 2) or (Config.DEBUG_ALLOW_SOLO and #queue >= 1)
	end

	local function tryCountdown()
		if state == "Countdown" or state == "Preparation" or state == "Serve" or state == "Rally" then return end
		if not enoughPlayers() then state = if #queue > 0 then "Queue" else "Lobby"; publish(); return end
		countdownToken += 1
		local token = countdownToken
		state = "Countdown"
		task.spawn(function()
			for remaining = Config.COUNTDOWN_SECONDS, 1, -1 do
				if token ~= countdownToken or not enoughPlayers() then
					state = if #queue > 0 then "Queue" else "Lobby"
					publish("Cuenta regresiva cancelada")
					return
				end
				publish("Partida en " .. tostring(remaining))
				task.wait(1)
			end
			if token == countdownToken and enoughPlayers() then
				local selected = {}
				for index = 1, math.min(#queue, Config.TEAM_SIZE * 2) do selected[index] = queue[index] end
				startMatch(selected, false)
			end
		end)
	end

	function GameService.OnPoint(winner: string, reason: string)
		if state ~= "Rally" and state ~= "Serve" and state ~= "Training" then return end
		if training then
			state = "Training"
			publish(reason .. " — entrenamiento reiniciado")
			task.delay(1.2, function()
				if state == "Training" then prepareServe() end
			end)
			return
		end
		scores[winner] += 1
		for _, player in ipairs(teams[winner]) do
			DataService.Update(player, "Points", 1)
			local stat = player:FindFirstChild("leaderstats") and player.leaderstats:FindFirstChild("Points")
			if stat and stat:IsA("IntValue") then stat.Value += 1 end
		end
		local target = if setNumber >= 3 then Config.DECISIVE_SET_POINTS else Config.POINTS_PER_SET
		if scores[winner] >= target and scores[winner] - scores[if winner == "A" then "B" else "A"] >= 2 then
			sets[winner] += 1
			scores = { A = 0, B = 0 }
			setNumber += 1
			if sets[winner] >= Config.SETS_TO_WIN then
				endMatch(winner)
				return
			end
			MatchService.Rotate(positions, teams[winner], math.max(#teams[winner], 1))
			servingSide = winner
			publish("Fin del set — cambio de lado")
			for side, team in pairs(teams) do
				for _, player in ipairs(team) do
					local opposite = if side == "A" then "B" else "A"
					player:PivotTo(MatchService.GetPosition(opposite, positions[player] or 1, #team))
					player:SetAttribute("TeamSide", opposite)
				end
			end
			teams.A, teams.B = teams.B, teams.A
			servingSide = if winner == "A" then "B" else "A"
			task.wait(2)
		else
			if winner ~= servingSide and #teams[winner] > 0 then
				MatchService.Rotate(positions, teams[winner], #teams[winner])
				for _, player in ipairs(teams[winner]) do
					player:PivotTo(MatchService.GetPosition(winner, positions[player], #teams[winner]))
				end
			end
			servingSide = winner
		end
		state = "Point"
		publish(reason .. " — punto para " .. winner)
		task.delay(1.5, function()
			if state == "Point" then prepareServe() end
		end)
	end

	ballController = require(script.Parent.BallService).Start(world.Court, remotes, function()
		return state, servingPlayer, servingSide
	end, GameService.OnPoint, function(_side: string)
		if state == "Serve" or state == "Training" then
			state = "Rally"
			publish("¡Rally! Toques del equipo: " .. tostring(ballController and ballController.GetTouches() or 0) .. "/3")
		end
	end)

	queueRemote.OnServerEvent:Connect(function(player: Player, action: any)
		if type(action) ~= "string" or #action > 24 then return end
		local now = os.clock()
		if rateLimits[player] and now - rateLimits[player] < 0.25 then return end
		rateLimits[player] = now
		if action == "Join" then
			if active[player] or table.find(queue, player) then return end
			table.insert(queue, player)
			player:SetAttribute("InQueue", true)
			publish("En cola " .. #queue .. "/" .. (Config.TEAM_SIZE * 2))
			tryCountdown()
		elseif action == "Cancel" then
			removeFromQueue(player)
			player:SetAttribute("InQueue", false)
			countdownToken += 1
			tryCountdown()
		elseif action == "Training" then
			if active[player] then return end
			removeFromQueue(player)
			player:SetAttribute("InQueue", false)
			startMatch({ player }, true)
		elseif action == "ReturnLobby" then
			if active[player] then active[player] = nil end
			player:SetAttribute("InMatch", false)
			teleportLobby(player)
			if training then
				state = "Lobby"
				training = false
			end
			publish()
		end
	end)

	local function bindPrompt(name: string, action: string)
		local part = world.Lobby:FindFirstChild(name)
		local prompt = part and part:FindFirstChildOfClass("ProximityPrompt")
		if prompt then
			prompt.Triggered:Connect(function(player)
				if action == "Training" then
					if not active[player] then startMatch({ player }, true) end
				elseif action == "Join" and not active[player] and not table.find(queue, player) then
					table.insert(queue, player)
					player:SetAttribute("InQueue", true)
					publish("En cola " .. #queue .. "/" .. (Config.TEAM_SIZE * 2))
					tryCountdown()
				end
			end)
		end
	end
	bindPrompt("PlayPad", "Join")
	bindPrompt("TrainingPad", "Training")

	settingsRemote.OnServerEvent:Connect(function(player: Player, key: any, value: any)
		if type(key) ~= "string" then return end
		if key == "Get" then
			local deadline = os.clock() + 15
			while not DataService.IsLoaded(player) and player.Parent and os.clock() < deadline do
				task.wait(0.1)
			end
			if not DataService.IsLoaded(player) then
				settingsRemote:FireClient(player, "Error", "No se pudieron cargar los ajustes.")
				return
			end
			settingsRemote:FireClient(player, "Settings", DataService.Get(player).Settings)
			return
		end
		if DataService.SetSetting(player, key, value) then
			remotes.SettingsRequest:FireClient(player, "Settings", DataService.Get(player).Settings)
		else
			settingsRemote:FireClient(player, "Error", "Ajuste o tecla no permitido")
		end
	end)

	Players.PlayerRemoving:Connect(function(player)
		local side = player:GetAttribute("TeamSide")
		local wasActive = active[player] == true
		active[player] = nil
		positions[player] = nil
		matchStats[player] = nil
		removeFromQueue(player)
		player:SetAttribute("InQueue", false)
		if wasActive and side then
			local team = teams[side]
			local teamIndex = table.find(team, player)
			if teamIndex then table.remove(team, teamIndex) end
			if #queue > 0 then
				local replacement = table.remove(queue, 1)
				if replacement then
					replacement:SetAttribute("InQueue", false)
					replacement:SetAttribute("InMatch", true)
					replacement:SetAttribute("TeamSide", side)
					replacement:SetAttribute("InObby", false)
					active[replacement] = true
					table.insert(team, replacement)
					positions[replacement] = 1
					if replacement.Character then replacement.Character:PivotTo(MatchService.GetPosition(side, 1, #team)) end
				end
			elseif #team == 0 and #teams[if side == "A" then "B" else "A"] > 0 then
				endMatch(if side == "A" then "B" else "A")
			end
		end
	end)
	local function loadPlayerData(player: Player)
		task.spawn(function()
			DataService.Load(player)
			if player.Parent then
				settingsRemote:FireClient(player, "Settings", DataService.Get(player).Settings)
			end
		end)
	end
	Players.PlayerAdded:Connect(function(player)
		loadPlayerData(player)
		player.CharacterAdded:Connect(function(character)
			task.wait(0.25)
			local spawn = world.Lobby:FindFirstChild("LobbySpawn")
			if spawn and spawn:IsA("BasePart") and not active[player] and not player:GetAttribute("InObby") then
				character:PivotTo(spawn.CFrame + Vector3.new(0, 4, 0))
			end
		end)
	end)
	for _, player in ipairs(Players:GetPlayers()) do
		loadPlayerData(player)
	end
	return {
		Publish = publish,
		GetState = function() return state end,
		IsActive = function(player: Player) return active[player] == true end,
	}
end

return GameService
