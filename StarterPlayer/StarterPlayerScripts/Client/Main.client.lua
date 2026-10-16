--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer
local modules = script.Parent
local remotes = ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Remotes")
local hud = require(modules.HUD).Create()
require(modules.LobbyUI).Bind(hud, remotes, player)
require(modules.SettingsUI).Bind(hud.Settings, remotes)
require(modules.CameraController).Start(remotes)
require(modules.InputController).Start(remotes, hud)

local function update(packet)
	if type(packet) ~= "table" then return end
	player:SetAttribute("GameState", packet.State)
	hud.Status.Text = packet.Message ~= "" and packet.Message or packet.State
	hud.Score.Text = string.format("A %d (%d sets)  —  %d (%d sets) B", packet.ScoreA or 0, packet.SetsA or 0, packet.ScoreB or 0, packet.SetsB or 0)
	hud.Queue.Text = if packet.Queued and packet.Queued[player.UserId] then "CANCELAR" else "JUGAR " .. tostring(packet.QueueCount or 0) .. "/" .. tostring((packet.TeamSize or 3) * 2)
	hud.Power.Visible = packet.State == "Serve"
end
remotes.MatchState.OnClientEvent:Connect(update)
remotes.ObbyState.OnClientEvent:Connect(function(packet)
	if type(packet) ~= "table" then return end
	hud.Obby.Visible = packet.InObby == true
	hud.Reset.Visible = packet.InObby == true
	if packet.InObby then
		hud.Status.Text = string.format("OBBY %d/%d — %.1f s\n%s", packet.Stage or 0, packet.MaxStage or 20, packet.Elapsed or 0, packet.Message or "")
	else
		hud.Status.Text = "Lobby — listo para jugar"
	end
end)
remotes.ObbyRequest:FireServer("Status")
task.spawn(function()
	while hud.Gui.Parent do
		if player:GetAttribute("InObby") then remotes.ObbyRequest:FireServer("Status") end
		task.wait(1)
	end
end)
