--!strict

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage.Shared.Config)

local DataService = {}
local store = DataStoreService:GetDataStore(Config.DATASTORE_NAME)
local cache: { [number]: { Matches: number, Wins: number, Points: number, Aces: number, Spikes: number, Blocks: number, Settings: { [string]: any } } } = {}
local dataReady: { [number]: boolean } = {}
local loading: { [number]: boolean } = {}
local pendingSettings: { [number]: { [string]: any } } = {}
local pendingUpdates: { [number]: { [string]: number } } = {}

local DEFAULT_KEYBINDS = { Serve = "E", Set = "F", Spike = "R", Block = "Q", Dive = "C", CameraToggle = "V" }
local DEFAULT = {
	Matches = 0, Wins = 0, Points = 0, Aces = 0, Spikes = 0, Blocks = 0,
	Settings = { Sensitivity = 1, Volume = 0.5, FollowBall = false, MouseLookMode = "ShiftLock", Keybinds = DEFAULT_KEYBINDS },
}

local function copyDefault()
	local settings = table.clone(DEFAULT.Settings)
	settings.Keybinds = table.clone(DEFAULT_KEYBINDS)
	return {
		Matches = DEFAULT.Matches, Wins = DEFAULT.Wins, Points = DEFAULT.Points,
		Aces = DEFAULT.Aces, Spikes = DEFAULT.Spikes, Blocks = DEFAULT.Blocks,
		Settings = settings,
	}
end

local function validKeyName(value: string): boolean
	for _, keyCode in ipairs(Enum.KeyCode:GetEnumItems()) do
		if keyCode.Name == value then return true end
	end
	return false
end

local function retry(operation: () -> any): (boolean, any)
	local lastError
	for attempt = 1, 3 do
		local ok, result = pcall(operation)
		if ok then
			return true, result
		end
		lastError = result
		task.wait(attempt)
	end
	return false, lastError
end

function DataService.Get(player: Player)
	cache[player.UserId] = cache[player.UserId] or copyDefault()
	return cache[player.UserId]
end

function DataService.IsLoaded(player: Player): boolean
	return cache[player.UserId] ~= nil
end

function DataService.Update(player: Player, field: string, amount: number)
	local data = cache[player.UserId]
	if not data or data[field] == nil or type(data[field]) ~= "number" then
		return
	end
	data[field] += amount
	if not dataReady[player.UserId] then
		pendingUpdates[player.UserId] = pendingUpdates[player.UserId] or {}
		pendingUpdates[player.UserId][field] = (pendingUpdates[player.UserId][field] or 0) + amount
	end
end

function DataService.SetSetting(player: Player, key: string, value: any): boolean
	local data = cache[player.UserId]
	if not data then return false end
	if key == "Sensitivity" and type(value) == "number" and value >= 0.2 and value <= 3 then
		data.Settings.Sensitivity = value
	elseif key == "Volume" and type(value) == "number" and value >= 0 and value <= 1 then
		data.Settings.Volume = value
	elseif key == "FollowBall" and type(value) == "boolean" then
		data.Settings.FollowBall = value
	elseif key == "MouseLookMode" and (value == "ShiftLock" or value == "RightClick") then
		data.Settings.MouseLookMode = value
	else
		local action = string.match(key, "^Keybind_(%w+)$")
		if not action or DEFAULT_KEYBINDS[action] == nil then return false end
		local keyName = if value == "Default" then DEFAULT_KEYBINDS[action] else value
		if type(keyName) ~= "string" or not validKeyName(keyName) then return false end
		local reserved = { W = true, A = true, S = true, D = true, Space = true, LeftShift = true, Escape = true }
		if reserved[keyName] then return false end
		for otherAction, currentKey in pairs(data.Settings.Keybinds) do
			if otherAction ~= action and currentKey == keyName then return false end
		end
		data.Settings.Keybinds[action] = keyName
	end
	if not dataReady[player.UserId] then
		pendingSettings[player.UserId] = pendingSettings[player.UserId] or {}
		pendingSettings[player.UserId][key] = value
	end
	return true
end

function DataService.Load(player: Player)
	local userId = player.UserId
	if dataReady[userId] or loading[userId] then return end
	loading[userId] = true
	cache[userId] = cache[userId] or copyDefault()
	dataReady[userId] = false
	local ok, result = retry(function()
		return store:GetAsync(tostring(player.UserId))
	end)
	if not player.Parent then
		loading[userId] = nil
		return
	end
	if not ok then
		warn("No se pudieron cargar los datos de " .. player.Name .. ": " .. tostring(result))
	end
	local loaded = if ok and type(result) == "table" then result else copyDefault()
	local data = copyDefault()
	for key in pairs(data) do
		if key == "Settings" then
			if type(loaded.Settings) == "table" then
				for settingKey, settingValue in pairs(DEFAULT.Settings) do
					if settingKey == "Keybinds" and type(loaded.Settings.Keybinds) == "table" then
						local used = {}
						for action, defaultKey in pairs(DEFAULT_KEYBINDS) do
							local loadedKey = loaded.Settings.Keybinds[action]
							if type(loadedKey) == "string" and validKeyName(loadedKey) and not used[loadedKey] then
								data.Settings.Keybinds[action] = loadedKey
								used[loadedKey] = true
							else
								data.Settings.Keybinds[action] = defaultKey
								used[defaultKey] = true
							end
						end
					elseif settingKey == "MouseLookMode" and (loaded.Settings.MouseLookMode == "ShiftLock" or loaded.Settings.MouseLookMode == "RightClick") then
						data.Settings.MouseLookMode = loaded.Settings.MouseLookMode
					elseif settingKey ~= "Keybinds" and settingKey ~= "MouseLookMode" and typeof(loaded.Settings[settingKey]) == typeof(settingValue) then
						data.Settings[settingKey] = loaded.Settings[settingKey]
					end
				end
			end
		elseif type(loaded[key]) == "number" then
			data[key] = loaded[key]
		end
	end
	for field, amount in pairs(pendingUpdates[userId] or {}) do
		if type(data[field]) == "number" then data[field] += amount end
	end
	cache[userId] = data
	for key, value in pairs(pendingSettings[userId] or {}) do
		DataService.SetSetting(player, key, value)
	end
	dataReady[userId] = true
	loading[userId] = nil
	pendingSettings[userId] = nil
	pendingUpdates[userId] = nil
	local stats = player:FindFirstChild("leaderstats")
	if not stats then
		stats = Instance.new("Folder")
		stats.Name = "leaderstats"
		stats.Parent = player
	end
	for _, field in ipairs({ "Matches", "Wins", "Points" }) do
		local value = stats:FindFirstChild(field) or Instance.new("IntValue")
		value.Name = field
		value.Value = data[field]
		value.Parent = stats
	end
end

function DataService.Save(player: Player)
	local data = cache[player.UserId]
	if not data or not dataReady[player.UserId] then return end
	local ok, result = retry(function()
		store:SetAsync(tostring(player.UserId), data)
	end)
	if not ok then
		warn("No se pudieron guardar los datos de " .. player.Name .. ": " .. tostring(result))
	end
end

Players.PlayerRemoving:Connect(function(player)
	DataService.Save(player)
	cache[player.UserId] = nil
	dataReady[player.UserId] = nil
	loading[player.UserId] = nil
	pendingSettings[player.UserId] = nil
	pendingUpdates[player.UserId] = nil
end)

game:BindToClose(function()
	for _, player in ipairs(Players:GetPlayers()) do
		DataService.Save(player)
	end
end)

return DataService
