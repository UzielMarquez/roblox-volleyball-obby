--!strict

local Config = require(script.Parent.Config)

local zones = {
	{ Name = "Calentamiento", First = 1, Last = 5, Color = Config.Obby.ZoneColors[1], MaxGap = 4.5, MaxRise = 4 },
	{ Name = "Cancha", First = 6, Last = 10, Color = Config.Obby.ZoneColors[2], MaxGap = 5.5, MaxRise = 4.5 },
	{ Name = "Gimnasio", First = 11, Last = 15, Color = Config.Obby.ZoneColors[3], MaxGap = 6.5, MaxRise = 5 },
	{ Name = "Torneo", First = 16, Last = 20, Color = Config.Obby.ZoneColors[4], MaxGap = 7.5, MaxRise = 5.5 },
}

local stages = {}
for index, kind in ipairs(Config.Obby.StageTypes) do
	local zone = math.ceil(index / 5)
	stages[index] = {
		Index = index,
		Kind = kind,
		Zone = zone,
		Name = zones[zone].Name,
		Color = zones[zone].Color,
		MaxGap = zones[zone].MaxGap,
		MaxRise = zones[zone].MaxRise,
	}
end

return {
	StageCount = Config.Obby.StageCount,
	Stages = stages,
	Zones = zones,
	BadgeId = Config.Obby.BadgeId,
	BestTimeStore = Config.Obby.BestTimeStore,
	LeaderboardRefreshSeconds = Config.Obby.LeaderboardRefreshSeconds,
}
