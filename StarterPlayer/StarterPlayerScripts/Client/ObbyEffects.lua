--!strict

local ObbyEffects = {}

function ObbyEffects.Show(message: string)
	if message ~= "" then print("[Obby] " .. message) end
end

return ObbyEffects
