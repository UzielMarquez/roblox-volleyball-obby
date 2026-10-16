--!strict

local ServerScriptService = game:GetService("ServerScriptService")

local serverFolder = ServerScriptService:WaitForChild("Server")
local CourtService = require(serverFolder:WaitForChild("CourtService"))
local LobbyService = require(serverFolder:WaitForChild("LobbyService"))
local GameService = require(serverFolder:WaitForChild("GameService"))
local ObbyService = require(serverFolder:WaitForChild("ObbyService"))

local world = CourtService.Build()
local remotes = LobbyService.GetRemotes()
LobbyService.Prepare(world)
local obby = ObbyService.Start(world, remotes)
GameService.Start(world, remotes, obby.ReturnFromMatch, obby.PauseForMatch)
print("Voleibol y Obby iniciados")
