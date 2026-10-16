--!strict

local LobbyUI = {}

function LobbyUI.Bind(hud, remotes: Folder, player: Player)
	hud.Queue.Activated:Connect(function()
		if player:GetAttribute("InQueue") then
			remotes.QueueRequest:FireServer("Cancel")
		else
			remotes.QueueRequest:FireServer("Join")
		end
	end)
	hud.Training.Activated:Connect(function() remotes.QueueRequest:FireServer("Training") end)
	hud.Obby.Activated:Connect(function() remotes.ObbyRequest:FireServer("Leave") end)
	hud.Reset.Activated:Connect(function() remotes.ObbyRequest:FireServer("Reset") end)
end

return LobbyUI
