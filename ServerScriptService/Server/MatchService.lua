--!strict

local MatchService = {}

function MatchService.Balance(players: { Player }, teamSize: number): ({ Player }, { Player })
	local left, right = {}, {}
	for index, player in ipairs(players) do
		if #left <= #right and #left < teamSize then
			table.insert(left, player)
			player:SetAttribute("TeamSide", "A")
		elseif #right < teamSize then
			table.insert(right, player)
			player:SetAttribute("TeamSide", "B")
		else
			player:SetAttribute("TeamSide", nil)
		end
	end
	return left, right
end

function MatchService.GetPosition(side: string, position: number, teamSize: number): CFrame
	local six = {
		Vector3.new(24, 3, -8), Vector3.new(8, 3, -8), Vector3.new(8, 3, 0),
		Vector3.new(8, 3, 8), Vector3.new(24, 3, 8), Vector3.new(24, 3, 0),
	}
	local point = six[((position - 1) % math.clamp(teamSize, 1, 6)) + 1]
	if side == "A" then point = Vector3.new(-point.X, point.Y, point.Z) end
	return CFrame.lookAt(point, Vector3.new(0, point.Y, 0))
end

function MatchService.Rotate(positions: { [Player]: number }, team: { Player }, teamSize: number)
	for _, player in ipairs(team) do
		positions[player] = ((positions[player] or 1) % teamSize) + 1
	end
end

return MatchService
