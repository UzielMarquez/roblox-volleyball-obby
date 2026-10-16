--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ObbyConfig = require(ReplicatedStorage.Shared.ObbyConfig)

local ObbyValidator = {}

function ObbyValidator.Validate(stagesFolder: Folder): (boolean, { string })
	local platforms = {}
	for _, item in ipairs(stagesFolder:GetDescendants()) do
		if item:IsA("BasePart") and item:GetAttribute("ObbyPlatform") == true then
			table.insert(platforms, item)
		end
	end
	table.sort(platforms, function(a, b)
		local stageA, stageB = a:GetAttribute("Stage") or 0, b:GetAttribute("Stage") or 0
		if stageA == stageB then return (a:GetAttribute("Sequence") or 0) < (b:GetAttribute("Sequence") or 0) end
		return stageA < stageB
	end)

	local errors = {}
	for index = 2, #platforms do
		local previous, current = platforms[index - 1], platforms[index]
		local stage = math.clamp(current:GetAttribute("Stage") or 1, 1, ObbyConfig.StageCount)
		local zone = ObbyConfig.Stages[stage]
		local dx = math.abs(current.Position.X - previous.Position.X)
		local dz = math.abs(current.Position.Z - previous.Position.Z)
		local gap = math.max(0, dx - previous.Size.X / 2 - current.Size.X / 2, dz - previous.Size.Z / 2 - current.Size.Z / 2)
		local rise = math.abs(current.Position.Y - previous.Position.Y)
		if gap > zone.MaxGap + 0.05 then
			table.insert(errors, string.format("Etapa %d: hueco %.2f > %.2f", stage, gap, zone.MaxGap))
		end
		if rise > zone.MaxRise + 0.05 then
			table.insert(errors, string.format("Etapa %d: escalón %.2f > %.2f", stage, rise, zone.MaxRise))
		end
	end
	return #errors == 0, errors
end

return ObbyValidator
