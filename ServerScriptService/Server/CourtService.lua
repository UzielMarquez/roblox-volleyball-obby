--!strict

local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

local CourtService = {}

type PartOptions = {
	Anchored: boolean?,
	CanCollide: boolean?,
	Transparency: number?,
	Material: Enum.Material?,
}

local function makePart(
	parent: Instance,
	name: string,
	size: Vector3,
	cframe: CFrame,
	color: Color3,
	options: PartOptions?
): Part
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.CFrame = cframe
	part.Color = color
	part.Anchored = if options and options.Anchored ~= nil then options.Anchored else true
	part.CanCollide = if options and options.CanCollide ~= nil then options.CanCollide else true
	part.Transparency = if options and options.Transparency ~= nil then options.Transparency else 0
	part.Material = if options and options.Material then options.Material else Enum.Material.SmoothPlastic
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Parent = parent
	return part
end

local function addCourtLine(parent: Instance, name: string, size: Vector3, position: Vector3)
	makePart(
		parent,
		name,
		size,
		CFrame.new(position),
		Config.Colors.CourtLine,
		{ CanCollide = false }
	)
end

local function buildCourt(world: Model)
	local court = Instance.new("Model")
	court.Name = "Court"
	court.Parent = world

	local length = Config.Court.LENGTH
	local width = Config.Court.WIDTH
	local floorThickness = Config.Court.FLOOR_THICKNESS
	local halfLength = length / 2
	local halfWidth = width / 2
	local floorCenterY = -floorThickness / 2

	makePart(
		court,
		"PlayingSurface",
		Vector3.new(length, floorThickness, width),
		CFrame.new(0, floorCenterY, 0),
		Config.Colors.CourtFloor,
		{ Material = Enum.Material.Wood }
	)

	local serveZoneDepth = Config.Court.SERVE_ZONE_DEPTH
	for _, x in ipairs({ -halfLength - serveZoneDepth / 2, halfLength + serveZoneDepth / 2 }) do
		makePart(
			court,
			"ServePlatform",
			Vector3.new(serveZoneDepth, floorThickness, width),
			CFrame.new(x, floorCenterY, 0),
			Config.Colors.CourtFloor,
			{ Material = Enum.Material.Wood }
		)
	end

	local lineThickness = 0.18
	local lineHeight = 0.035
	local lineY = 0.018
	addCourtLine(court, "EndLineA", Vector3.new(lineThickness, lineHeight, width), Vector3.new(-halfLength, lineY, 0))
	addCourtLine(court, "EndLineB", Vector3.new(lineThickness, lineHeight, width), Vector3.new(halfLength, lineY, 0))
	addCourtLine(court, "SidelineFront", Vector3.new(length, lineHeight, lineThickness), Vector3.new(0, lineY, -halfWidth))
	addCourtLine(court, "SidelineBack", Vector3.new(length, lineHeight, lineThickness), Vector3.new(0, lineY, halfWidth))
	addCourtLine(court, "CenterLine", Vector3.new(lineThickness, lineHeight, width), Vector3.new(0, lineY, 0))

	local attackDistance = Config.Court.ATTACK_LINE_DISTANCE
	for _, x in ipairs({ -attackDistance, attackDistance }) do
		addCourtLine(
			court,
			if x < 0 then "AttackLineA" else "AttackLineB",
			Vector3.new(lineThickness, lineHeight, width),
			Vector3.new(x, lineY, 0)
		)
	end

	local netHeight = Config.Court.NET_HEIGHT
	local netWidth = width
	local net = makePart(
		court,
		"Net",
		Vector3.new(Config.Court.NET_THICKNESS, netHeight, netWidth),
		CFrame.new(0, netHeight / 2, 0),
		Config.Colors.Net,
		{ CanCollide = false, Transparency = 0.3, Material = Enum.Material.Fabric }
	)
	net.CastShadow = false

	local postHeight = netHeight + 1.5
	for _, z in ipairs({ -halfWidth - 0.45, halfWidth + 0.45 }) do
		makePart(
			court,
			"NetPost",
			Vector3.new(0.45, postHeight, 0.45),
			CFrame.new(0, postHeight / 2, z),
			Config.Colors.Post,
			{ Material = Enum.Material.Metal }
		)
	end

	local boundaryHeight = Config.Court.BOUNDARY_HEIGHT
	local boundaryThickness = Config.Court.BOUNDARY_THICKNESS
	local serveZoneDepth = Config.Court.SERVE_ZONE_DEPTH
	local boundaryOptions: PartOptions = {
		Transparency = 1,
		CanCollide = true,
	}
	for _, x in ipairs({
		-halfLength - serveZoneDepth - boundaryThickness / 2,
		halfLength + serveZoneDepth + boundaryThickness / 2,
	}) do
		makePart(
			court,
			"SafetyBoundaryEnd",
			Vector3.new(boundaryThickness, boundaryHeight, width + 2 * boundaryThickness),
			CFrame.new(x, boundaryHeight / 2, 0),
			Color3.new(1, 1, 1),
			boundaryOptions
		)
	end
	for _, z in ipairs({ -halfWidth - boundaryThickness / 2, halfWidth + boundaryThickness / 2 }) do
		makePart(
			court,
			"SafetyBoundarySide",
			Vector3.new(length, boundaryHeight, boundaryThickness),
			CFrame.new(0, boundaryHeight / 2, z),
			Color3.new(1, 1, 1),
			boundaryOptions
		)
	end
	makePart(
		court,
		"SafetyCeiling",
		Vector3.new(length + 2 * (serveZoneDepth + boundaryThickness), boundaryThickness, width + 2 * boundaryThickness),
		CFrame.new(0, boundaryHeight, 0),
		Color3.new(1, 1, 1),
		boundaryOptions
	)

	local zones = Instance.new("Folder")
	zones.Name = "Zones"
	zones.Parent = court

	local zoneOptions: PartOptions = {
		Transparency = 1,
		CanCollide = false,
	}
	for _, side in ipairs({ "A", "B" }) do
		local sideCenterX = if side == "A" then -halfLength / 2 else halfLength / 2
		makePart(
			zones,
			"Side" .. side,
			Vector3.new(halfLength, 0.1, width),
			CFrame.new(sideCenterX, 0.05, 0),
			Color3.new(1, 1, 1),
			zoneOptions
		)
		local serveX = if side == "A" then -halfLength - 4 else halfLength + 4
		makePart(
			zones,
			"Serve" .. side,
			Vector3.new(serveZoneDepth, 0.1, width),
			CFrame.new(serveX, 0.05, 0),
			Color3.new(1, 1, 1),
			zoneOptions
		)
	end
	makePart(
		zones,
		"NetPlane",
		Vector3.new(0.1, netHeight, width),
		CFrame.new(0, netHeight / 2, 0),
		Color3.new(1, 1, 1),
		zoneOptions
	)
end

local function addPrompt(pad: Part, actionText: string, objectText: string)
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = actionText
	prompt.ObjectText = objectText
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = 12
	prompt.RequiresLineOfSight = false
	prompt.Parent = pad
end

local function buildLobby(world: Model)
	local lobby = Instance.new("Model")
	lobby.Name = "Lobby"
	lobby.Parent = world

	local center = Config.Lobby.CENTER
	local floorSize = Config.Lobby.FLOOR_SIZE
	local floorTopY = center.Y

	makePart(
		lobby,
		"LobbyFloor",
		floorSize,
		CFrame.new(center.X, floorTopY - floorSize.Y / 2, center.Z),
		Config.Colors.LobbyFloor,
		{ Material = Enum.Material.Concrete }
	)

	local wallHeight = 18
	local wallThickness = 1
	local halfX = floorSize.X / 2
	local halfZ = floorSize.Z / 2
	local wallY = floorTopY + wallHeight / 2
	local wallColor = Config.Colors.LobbyWall
	makePart(lobby, "BackWall", Vector3.new(floorSize.X, wallHeight, wallThickness), CFrame.new(center.X, wallY, center.Z + halfZ), wallColor)
	makePart(lobby, "LeftWall", Vector3.new(wallThickness, wallHeight, floorSize.Z), CFrame.new(center.X - halfX, wallY, center.Z), wallColor)
	makePart(lobby, "RightWall", Vector3.new(wallThickness, wallHeight, floorSize.Z), CFrame.new(center.X + halfX, wallY, center.Z), wallColor)
	makePart(
		lobby,
		"Roof",
		Vector3.new(floorSize.X, 1, floorSize.Z),
		CFrame.new(center.X, floorTopY + wallHeight, center.Z),
		wallColor
	)

	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "LobbySpawn"
	spawn.Size = Vector3.new(6, 0.5, 6)
	spawn.CFrame = CFrame.new(center + Config.Lobby.SPAWN_OFFSET)
	spawn.Anchored = true
	spawn.Neutral = true
	spawn.Duration = 0
	spawn.Color = Config.Colors.PlayPad
	spawn.Material = Enum.Material.Neon
	spawn.Parent = lobby

	local padY = floorTopY + 0.35
	local playPad = makePart(
		lobby,
		"PlayPad",
		Vector3.new(10, 0.7, 10),
		CFrame.new(center.X + 15, padY, center.Z - 5),
		Config.Colors.PlayPad,
		{ Material = Enum.Material.Neon }
	)
	addPrompt(playPad, "JUGAR", "Partida")

	local trainingPad = makePart(
		lobby,
		"TrainingPad",
		Vector3.new(10, 0.7, 10),
		CFrame.new(center.X + 15, padY, center.Z + 9),
		Config.Colors.TrainingPad,
		{ Material = Enum.Material.Neon }
	)
	addPrompt(trainingPad, "ENTRENAMIENTO", "Práctica")

	local sign = makePart(
		lobby,
		"ControlsSign",
		Vector3.new(12, 7, 0.5),
		CFrame.new(center.X - 13, floorTopY + 5, center.Z - halfZ + 0.8),
		Color3.fromRGB(35, 45, 55),
		{ CanCollide = false }
	)
	local surfaceGui = Instance.new("SurfaceGui")
	surfaceGui.Name = "ControlsDisplay"
	surfaceGui.Face = Enum.NormalId.Back
	surfaceGui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	surfaceGui.PixelsPerStud = 40
	surfaceGui.Parent = sign
	local label = Instance.new("TextLabel")
	label.Name = "Text"
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Text = "CONTROLES\nWASD: moverse   |   ESPACIO: saltar\nE: recibir   |   F: colocar   |   R: rematar\nQ: bloquear   |   C: lanzarse"
	label.TextColor3 = Color3.new(1, 1, 1)
	label.TextScaled = true
	label.Font = Enum.Font.GothamBold
	label.Parent = surfaceGui
	addPrompt(sign, "CONTROLES", "Ayuda")
end

function CourtService.Build(): Model
	local existing = Workspace:FindFirstChild("VolleyballWorld")
	if existing then
		existing:Destroy()
	end

	local baseplate = Workspace:FindFirstChild("Baseplate")
	if baseplate and baseplate:IsA("BasePart") then
		baseplate.Transparency = 1
		baseplate.CanCollide = false
	end

	local world = Instance.new("Model")
	world.Name = "VolleyballWorld"
	world.Parent = Workspace

	buildCourt(world)
	buildLobby(world)
	return world
end

return CourtService
