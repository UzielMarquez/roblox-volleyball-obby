--!strict

local Rules = {}

function Rules.GetSetTarget(setNumber: number, regularTarget: number, decisiveTarget: number): number
	return if setNumber >= 3 then decisiveTarget else regularTarget
end

function Rules.HasWonSet(score: number, opponentScore: number, target: number): boolean
	return score >= target and score - opponentScore >= 2
end

function Rules.GetPointWinner(lastTouchingSide: string, faultingSide: string?): string
	if faultingSide then
		return if faultingSide == "A" then "B" else "A"
	end
	return lastTouchingSide
end

function Rules.Rotate(position: number, teamSize: number): number
	return (position % teamSize) + 1
end

function Rules.IsInsideCourt(position: Vector3, halfLength: number, halfWidth: number): boolean
	return math.abs(position.X) <= halfLength and math.abs(position.Z) <= halfWidth
end

function Rules.CalculateLaunchVelocity(origin: Vector3, target: Vector3, flightTime: number, gravity: number): Vector3
	local delta = target - origin
	return Vector3.new(
		delta.X / flightTime,
		(delta.Y + 0.5 * gravity * flightTime * flightTime) / flightTime,
		delta.Z / flightTime
	)
end

return Rules
