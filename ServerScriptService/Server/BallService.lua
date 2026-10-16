--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Config = require(ReplicatedStorage.Shared.Config)
local Rules = require(ReplicatedStorage.Shared.Rules)

local BallService = {}

function BallService.Start(court: Model, remotes: Folder, getState: () -> (string, Player?, string?), onPoint: (string, string) -> (), onRallyStart: (string) -> ())
	local ball = Instance.new("Part")
	ball.Name = "Volleyball"
	ball.Shape = Enum.PartType.Ball
	ball.Size = Vector3.new(2, 2, 2)
	ball.Color = Color3.fromRGB(245, 235, 180)
	ball.Material = Enum.Material.SmoothPlastic
	ball.Anchored = true
	ball.CanCollide = true
	ball.CustomPhysicalProperties = PhysicalProperties.new(0.6, 0.35, 0.65, 1, 1)
	ball.Parent = court

	local gravityAttachment = Instance.new("Attachment")
	gravityAttachment.Name = "BallGravityAttachment"
	gravityAttachment.Parent = ball
	local gravityForce = Instance.new("VectorForce")
	gravityForce.Name = "ReducedGravity"
	gravityForce.Attachment0 = gravityAttachment
	gravityForce.ApplyAtCenterOfMass = true
	gravityForce.RelativeTo = Enum.ActuatorRelativeTo.World
	gravityForce.Parent = ball

	local serveRemote = remotes:WaitForChild("ServeCharge") :: RemoteEvent
	local actionRemote = remotes:WaitForChild("BallAction") :: RemoteEvent
	local powerRemote = remotes:WaitForChild("ServePower") :: RemoteEvent
	local chargeStarted: { [Player]: number } = {}
	local lastAction: { [Player]: number } = {}
	local touches = 0
	local lastPlayer: Player? = nil
	local lastSide = "A"
	local rallyLive = false
	local previousPosition = ball.Position
	local pointPending = false

	local function placeForServe(side: string)
		local x = if side == "A" then -33 else 33
		ball.Anchored = true
		ball.AssemblyLinearVelocity = Vector3.zero
		ball.AssemblyAngularVelocity = Vector3.zero
		ball.CFrame = CFrame.new(x, 4.5, 0)
		ball:SetAttribute("ServingSide", side)
		ball:SetAttribute("CrossedNet", false)
		previousPosition = ball.Position
		touches = 0
		lastPlayer = nil
		lastSide = side
		rallyLive = false
		pointPending = false
	end

	local function finishPoint(winner: string, reason: string)
		if pointPending then return end
		pointPending = true
		rallyLive = false
		table.clear(chargeStarted)
		onPoint(winner, reason)
	end

	local function allowedToAct(player: Player): (boolean, string)
		local state = getState()
		if state ~= "Rally" or not rallyLive then return false, "Rally" end
		local expectedSide = if ball.Position.X < 0 then "A" else "B"
		return player:GetAttribute("TeamSide") == expectedSide, expectedSide
	end

	serveRemote.OnServerEvent:Connect(function(player: Player, phase: any, direction: any)
		if phase == "Start" then
			if chargeStarted[player] then return end
			local valid = allowedToAct(player)
			if not valid or getState() ~= "Serve" then return end
			local character = player.Character
			local root = character and character:FindFirstChild("HumanoidRootPart")
			if not root or not root:IsA("BasePart") or (root.Position - ball.Position).Magnitude > Config.MAX_CONTACT_DISTANCE then return end
			chargeStarted[player] = os.clock()
			return
		end
		if phase ~= "Release" or typeof(direction) ~= "Vector3" then return end
		local allowed = allowedToAct(player)
		if not allowed then return end
		local started = chargeStarted[player]
		chargeStarted[player] = nil
		if not started then return end
		local elapsed = math.clamp(os.clock() - started, 0, Config.SERVE_LIMIT_SECONDS)
		if elapsed > Config.SERVE_LIMIT_SECONDS then
			finishPoint(if player:GetAttribute("TeamSide") == "A" then "B" else "A", "Límite de saque")
			return
		end
		local flat = Vector3.new(direction.X, 0, direction.Z)
		local side = player:GetAttribute("TeamSide") or "A"
		local forward = if side == "A" then 1 else -1
		if flat.Magnitude < 0.1 then flat = Vector3.new(forward, 0, 0) end
		flat = flat.Unit
		if flat.X * forward < 0.15 then
			flat = Vector3.new(forward, 0, flat.Z).Unit
		end
		local target = Vector3.new(forward * 22, 1, math.clamp(flat.Z * 20, -13, 13))
		local speed = 40 + elapsed * 18
		local flightTime = math.clamp((target - ball.Position).Magnitude / speed, 0.75, 1.25)
		ball.Anchored = false
		ball:SetNetworkOwner(nil)
		gravityForce.Force = Vector3.new(0, ball.AssemblyMass * (workspace.Gravity - Config.BALL_GRAVITY), 0)
		ball.AssemblyLinearVelocity = Rules.CalculateLaunchVelocity(ball.Position, target, flightTime, Config.BALL_GRAVITY)
		ball.AssemblyAngularVelocity = Vector3.new(0, 0, -4)
		touches = 1
		lastPlayer = player
		lastSide = side
		rallyLive = true
		onRallyStart(side)
		powerRemote:FireClient(player, "Released", elapsed / Config.SERVE_LIMIT_SECONDS)
		return
	end)

	actionRemote.OnServerEvent:Connect(function(player: Player, action: any, direction: any)
		if (action ~= "Bump" and action ~= "Set" and action ~= "Spike" and action ~= "Block" and action ~= "Dive")
			or typeof(direction) ~= "Vector3" or direction.Magnitude < 0.5 or direction.Magnitude > 1.5 then return end
		local now = os.clock()
		if lastAction[player] and now - lastAction[player] < Config.MAX_REMOTE_RATE then return end
		lastAction[player] = now
		local allowed, side = allowedToAct(player)
		if not allowed or ball.Anchored or action == "Serve" then return end
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		if not root or not root:IsA("BasePart") or (root.Position - ball.Position).Magnitude > Config.MAX_CONTACT_DISTANCE then return end
		if action ~= "Block" and lastPlayer == player then
			finishPoint(if side == "A" then "B" else "A", "Doble contacto")
			return
		end
		if action ~= "Block" then
			if touches >= 3 then
				finishPoint(if side == "A" then "B" else "A", "Cuatro toques")
				return
			end
			touches += 1
			lastPlayer = player
		end
		local aim = Vector3.new(direction.X, math.clamp(direction.Y, -0.7, 0.8), direction.Z)
		local targetX = if side == "A" then 12 else -12
		local flightTime = 1.15
		if action == "Set" then
			targetX = if side == "A" then 6 else -6
			flightTime = 1.4
		elseif action == "Spike" then
			targetX = if side == "A" then 22 else -22
			flightTime = 0.65
		elseif action == "Block" then
			targetX = if side == "A" then 2 else -2
			flightTime = 0.55
		elseif action == "Dive" and root.AssemblyLinearVelocity.Magnitude < 1 then
			root.AssemblyLinearVelocity = root.CFrame.LookVector * 24 + Vector3.new(0, 8, 0)
		end
		local target = Vector3.new(targetX, if action == "Spike" then 0.5 else 5, math.clamp(ball.Position.Z + aim.Z * 14, -14, 14))
		local velocity = Rules.CalculateLaunchVelocity(ball.Position, target, flightTime, Config.BALL_GRAVITY)
		if action == "Block" then
			velocity = Vector3.new(-velocity.X, math.max(velocity.Y, 8), velocity.Z)
		end
		ball.AssemblyLinearVelocity = velocity
		ball:SetNetworkOwner(nil)
		lastSide = side
		onRallyStart(side)
	end)

	local heartbeat
	heartbeat = RunService.Heartbeat:Connect(function()
		if not ball.Parent then heartbeat:Disconnect(); return end
		gravityForce.Force = if not ball.Anchored
			then Vector3.new(0, ball.AssemblyMass * (workspace.Gravity - Config.BALL_GRAVITY), 0)
			else Vector3.zero
		local current = ball.Position
		if rallyLive then
			if (previousPosition.X < 0 and current.X >= 0) or (previousPosition.X > 0 and current.X <= 0) then
				ball:SetAttribute("CrossedNet", true)
			end
			if math.abs(current.X) > Config.Court.LENGTH / 2 + 1 or math.abs(current.Z) > Config.Court.WIDTH / 2 + 1 or current.Y > Config.Court.BOUNDARY_HEIGHT - 2 then
				finishPoint(if lastSide == "A" then "B" else "A", "Fuera")
			elseif current.Y <= 1.15 then
				local landedSide = if current.X < 0 then "A" else "B"
				if Rules.IsInsideCourt(current, Config.Court.LENGTH / 2, Config.Court.WIDTH / 2) then
					finishPoint(if landedSide == lastSide then (if landedSide == "A" then "B" else "A") else landedSide, "Balón al piso")
				else
					finishPoint(if landedSide == "A" then "B" else "A", "Fuera")
				end
			end
		end
		previousPosition = current
	end)

	Players.PlayerRemoving:Connect(function(player)
		chargeStarted[player] = nil
		lastAction[player] = nil
	end)

	placeForServe("A")
	return {
		Ball = ball,
		ResetForServe = placeForServe,
		SetRally = function(value: boolean) rallyLive = value end,
		GetTouches = function() return touches end,
	}
end

return BallService
