--!strict

local CollectionService = game:GetService("CollectionService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ObbyConfig = require(ReplicatedStorage.Shared.ObbyConfig)

local StageBuilder = {}
local ROOT = Vector3.new(0, 0, 226)
local STAGE_LENGTH = 42
local PLATFORM_GAP = 0.5

local function createPart(parent: Instance, name: string, size: Vector3, position: Vector3, color: Color3, material: Enum.Material?): Part
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.Position = position
	part.Anchored = true
	part.Color = color
	part.Material = material or Enum.Material.SmoothPlastic
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Parent = parent
	return part
end

local function tagPlatform(part: Part, stage: number, sequence: number)
	part:SetAttribute("ObbyPlatform", true)
	part:SetAttribute("Stage", stage)
	part:SetAttribute("Sequence", sequence)
	CollectionService:AddTag(part, "ObbyPlatform")
end

local function tagHazard(part: Part, tag: string, stage: number)
	part:SetAttribute("Stage", stage)
	CollectionService:AddTag(part, tag)
end

local function addMover(part: Part, offset: Vector3, seconds: number)
	part:SetAttribute("MoveOffset", offset)
	part:SetAttribute("MoveTime", seconds)
	CollectionService:AddTag(part, "Mover")
	local origin = part.CFrame
	local tween = TweenService:Create(part, TweenInfo.new(seconds, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), { CFrame = origin + offset })
	tween:Play()
end

local function buildStage(folder: Folder, stageData, index: number)
	local model = Instance.new("Model")
	model.Name = string.format("Stage%02d", index)
	model.ModelStreamingMode = Enum.ModelStreamingMode.Atomic
	model.Parent = folder
	local zoneFloor = createPart(model, "ZoneFloor", Vector3.new(40, 1, 20), ROOT + Vector3.new((index - 1) * STAGE_LENGTH + 20, -3, 0), stageData.Color, Enum.Material.Concrete)
	zoneFloor.CanTouch = false
	zoneFloor.CanQuery = false

	local startX = (index - 1) * STAGE_LENGTH + 2
	local zOffset = 0
	for sequence = 1, 6 do
		local x = startX + (sequence - 1) * 6.5
		local y = 2
		local z = ROOT.Z
		local width = 7
		local length = 7
		local kind = stageData.Kind
		if kind == "Benches" then y = 1 + (sequence - 1) * 0.55; length = 8
		elseif kind == "NarrowWalkway" then width = 5; length = 8
		elseif kind == "Zigzag" then zOffset = if sequence % 2 == 0 then 4 else -4; z += zOffset
		elseif kind == "Fading" then length = 6
		elseif kind == "NetClimb" and sequence == 3 then y = 5
		elseif kind == "Conveyor" and sequence >= 2 and sequence <= 5 then width = 8
		elseif kind == "MovingPlatforms" and sequence >= 2 and sequence <= 5 then width = 6
		elseif kind == "RollingBalls" and sequence == 3 then y = 3
		elseif kind == "Arc" then z += math.sin(sequence * math.pi / 7) * 4
		elseif kind == "Pillars" then y = 1 + (sequence % 3) * 1.3; width = 6
		elseif kind == "Trampolines" and sequence == 2 then y = 3
		elseif kind == "Elevators" and sequence >= 2 and sequence <= 5 then y = 3
		elseif kind == "Blinking" then length = 6
		elseif kind == "SpikeJump" then x += if sequence >= 3 then 1 else 0
		elseif kind == "Podium" and sequence >= 4 then y = 1 + (sequence - 3) * 0.8
		end

		local platform = createPart(model, "Platform" .. sequence, Vector3.new(length, 1, width), Vector3.new(x, y, z), stageData.Color)
		tagPlatform(platform, index, sequence)
		if kind == "Fading" then tagHazard(platform, "Fader", index) end
		if kind == "MovingPlatforms" and sequence % 2 == 0 then addMover(platform, Vector3.new(0, 0, 4), 2.8) end
		if kind == "Elevators" and sequence % 2 == 0 then addMover(platform, Vector3.new(0, 4, 0), 3.5) end
		if kind == "Blinking" and sequence >= 2 and sequence <= 5 then tagHazard(platform, "Fader", index) end
		if kind == "Trampolines" and sequence == 2 then
			platform.Material = Enum.Material.Neon
			platform.Color = Color3.fromRGB(65, 225, 225)
			platform:SetAttribute("Trampoline", true)
		end
		if kind == "Conveyor" and sequence >= 2 and sequence <= 5 then
			platform:SetAttribute("ConveyorSpeed", 8)
			CollectionService:AddTag(platform, "Conveyor")
		end
		if kind == "Lasers" and sequence % 2 == 0 then
			local laser = createPart(model, "Laser", Vector3.new(1, 4, 7), Vector3.new(x, y + 2.5, z), Color3.fromRGB(255, 35, 55), Enum.Material.Neon)
			laser:SetAttribute("CycleSeconds", 2)
			tagHazard(laser, "Laser", index)
		end
		if (kind == "Sweeper" or kind == "DoubleSweepers") and sequence == 3 or (kind == "DoubleSweepers" and sequence == 5) then
			local sweeper = createPart(model, "Sweeper", Vector3.new(10, 0.7, 0.7), Vector3.new(x, y + 1, z), Color3.fromRGB(235, 105, 55), Enum.Material.Metal)
			sweeper:SetAttribute("SpinTime", 4)
			tagHazard(sweeper, "Spinner", index)
			tagHazard(sweeper, "KillBrick", index)
		end
		if kind == "Discs" and sequence % 2 == 0 then
			local disc = createPart(model, "RotatingDisc", Vector3.new(6, 0.7, 6), Vector3.new(x, y, z), Color3.fromRGB(200, 110, 255), Enum.Material.Metal)
			disc.Shape = Enum.PartType.Cylinder
			disc:SetAttribute("SpinTime", 7)
			tagHazard(disc, "Spinner", index)
		end
		if kind == "RollingBalls" and sequence == 3 or kind == "RollingBalls" and sequence == 5 then
			local ball = createPart(model, "RollingBall", Vector3.new(5, 5, 5), Vector3.new(x, y + 4, z), Color3.fromRGB(245, 205, 65), Enum.Material.SmoothPlastic)
			ball.Shape = Enum.PartType.Ball
			addMover(ball, Vector3.new(0, 0, 8), 2.5)
		end
	end

	if stageData.Kind == "NetClimb" then
		local truss = Instance.new("TrussPart")
		truss.Name = "NetClimbTruss"
		truss.Size = Vector3.new(2, 8, 2)
		truss.Position = Vector3.new(ROOT.X + startX + 19, 4.5, ROOT.Z)
		truss.Anchored = true
		truss.Parent = model
	end

	if index == 1 then
		local welcome = createPart(model, "WelcomeSign", Vector3.new(1, 6, 10), ROOT + Vector3.new(startX - 2, 4, -8), Color3.fromRGB(30, 70, 90), Enum.Material.Metal)
		welcome.CanCollide = false
		welcome.CanTouch = false
		local welcomeGui = Instance.new("SurfaceGui")
		welcomeGui.Face = Enum.NormalId.Right
		welcomeGui.Parent = welcome
		local welcomeText = Instance.new("TextLabel")
		welcomeText.Size = UDim2.fromScale(1, 1)
		welcomeText.BackgroundTransparency = 1
		welcomeText.Text = "¡BIENVENIDO!\nCamina, salta y toca cada checkpoint en orden.\nUsa Reiniciar etapa si lo necesitas."
		welcomeText.TextColor3 = Color3.new(1, 1, 1)
		welcomeText.TextScaled = true
		welcomeText.Parent = welcomeGui
	end

	local checkpoint = createPart(model, "Checkpoint", Vector3.new(8, 1, 8), ROOT + Vector3.new((index - 1) * STAGE_LENGTH + 39, 2, 0), Color3.fromRGB(65, 230, 100), Enum.Material.Neon)
	checkpoint:SetAttribute("Stage", index)
	CollectionService:AddTag(checkpoint, "Checkpoint")
	if index == ObbyConfig.StageCount then
		checkpoint.Name = "Finish"
		local trophy = createPart(model, "Trophy", Vector3.new(2, 4, 2), checkpoint.Position + Vector3.new(0, 3, 0), Color3.fromRGB(255, 210, 40), Enum.Material.Metal)
		trophy.CanCollide = false
		trophy.CanTouch = false
		trophy.CanQuery = false
		local exitPrompt = Instance.new("ProximityPrompt")
		exitPrompt.Name = "ReturnLobbyPrompt"
		exitPrompt.ActionText = "VOLVER AL LOBBY"
		exitPrompt.ObjectText = "Meta"
		exitPrompt.HoldDuration = 0
		exitPrompt.Parent = checkpoint
	end
	local sign = createPart(model, "StageSign", Vector3.new(1, 5, 8), ROOT + Vector3.new((index - 1) * STAGE_LENGTH + 1, 3, -7), Color3.fromRGB(35, 45, 60), Enum.Material.Metal)
	sign.CanCollide = false
	sign.CanTouch = false
	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Right
	gui.Parent = sign
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Text = string.format("%02d — %s\n%s", index, stageData.Kind, stageData.Name)
	label.TextColor3 = Color3.new(1, 1, 1)
	label.TextScaled = true
	label.Font = Enum.Font.GothamBold
	label.Parent = gui
end

function StageBuilder.Build(world: Model): Folder
	local existing = world:FindFirstChild("Obby")
	if existing then existing:Destroy() end
	local obby = Instance.new("Model")
	obby.Name = "Obby"
	obby.ModelStreamingMode = Enum.ModelStreamingMode.Atomic
	obby.Parent = world
	local stagesFolder = Instance.new("Folder")
	stagesFolder.Name = "Stages"
	stagesFolder.Parent = obby
	for index, stage in ipairs(ObbyConfig.Stages) do buildStage(stagesFolder, stage, index) end
	local start = createPart(obby, "StartPoint", Vector3.new(8, 1, 8), ROOT + Vector3.new(-5, 2, 0), Color3.fromRGB(55, 220, 180), Enum.Material.Neon)
	start:SetAttribute("Stage", 0)
	CollectionService:AddTag(start, "Checkpoint")
	local void = createPart(obby, "VoidKillBrick", Vector3.new(900, 2, 60), ROOT + Vector3.new(420, -12, 0), Color3.fromRGB(200, 30, 35), Enum.Material.Neon)
	void.Transparency = 0.25
	tagHazard(void, "KillBrick", 0)
	return obby
end

return StageBuilder
