--!strict

local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage.Shared.ObbyConfig)

local ObbyDataService = {}
local progressStore = DataStoreService:GetDataStore("VolleyballObbyProgress_v1")
local orderedStore = DataStoreService:GetOrderedDataStore(Config.BestTimeStore)
local cache: { [number]: { Stage: number, BestTime: number?, Completed: boolean, TrailUnlocked: boolean } } = {}

local function retry<T>(callback: () -> T): (boolean, T?)
	local lastError
	for attempt = 1, 3 do
		local ok, result = pcall(callback)
		if ok then return true, result end
		lastError = result
		task.wait(attempt)
	end
	warn("Falló una operación de datos del obby: " .. tostring(lastError))
	return false, nil
end

function ObbyDataService.Get(player: Player)
	return cache[player.UserId] or { Stage = 0, BestTime = nil, Completed = false, TrailUnlocked = false }
end

function ObbyDataService.Load(player: Player)
	local ok, result = retry(function()
		return progressStore:GetAsync(tostring(player.UserId))
	end)
	local loaded = if ok and type(result) == "table" then result else {}
	local data = {
		Stage = math.clamp(if type(loaded.Stage) == "number" then loaded.Stage else 0, 0, Config.StageCount),
		BestTime = if type(loaded.BestTime) == "number" then loaded.BestTime else nil,
		Completed = loaded.Completed == true,
		TrailUnlocked = loaded.TrailUnlocked == true,
	}
	cache[player.UserId] = data
	player:SetAttribute("ObbyStage", data.Stage)
	player:SetAttribute("ObbyCompleted", data.Completed)
	player:SetAttribute("BallTrailUnlocked", data.TrailUnlocked)
	return data
end

function ObbyDataService.Save(player: Player)
	local data = cache[player.UserId]
	if not data then return end
	local ok = retry(function()
		progressStore:SetAsync(tostring(player.UserId), data)
	end)
	if not ok then return end
end

function ObbyDataService.SetStage(player: Player, stage: number)
	local data = cache[player.UserId]
	if not data then return end
	data.Stage = math.clamp(stage, 0, Config.StageCount)
	player:SetAttribute("ObbyStage", data.Stage)
end

function ObbyDataService.Complete(player: Player, elapsed: number)
	local data = cache[player.UserId]
	if not data then return false end
	data.Stage = Config.StageCount
	data.Completed = true
	data.TrailUnlocked = true
	if not data.BestTime or elapsed < data.BestTime then data.BestTime = elapsed end
	player:SetAttribute("ObbyStage", data.Stage)
	player:SetAttribute("ObbyCompleted", true)
	player:SetAttribute("BallTrailUnlocked", true)
	local ok = retry(function()
		orderedStore:SetAsync(tostring(player.UserId), math.floor(elapsed * 1000))
	end)
	if not ok then warn("No se pudo actualizar el tiempo del tablero") end
	ObbyDataService.Save(player)
	return true
end

function ObbyDataService.GetTop(limit: number)
	local ok, pages = retry(function()
		return orderedStore:GetSortedAsync(true, limit)
	end)
	if not ok or not pages then return {} end
	local result = {}
	for _, entry in ipairs(pages:GetCurrentPage()) do
		table.insert(result, { UserId = tonumber(entry.key), Time = entry.value / 1000 })
	end
	return result
end

return ObbyDataService
