--!strict

local CollectionService = game:GetService("CollectionService")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")

local HazardService = {}

local function getPlayerFromHit(hit: BasePart): Player?
	local model = hit:FindFirstAncestorOfClass("Model")
	return if model then Players:GetPlayerFromCharacter(model) else nil
end

function HazardService.Start(obby: Model, getCheckpoint: (Player) -> CFrame?)
	for _, part in ipairs(CollectionService:GetTagged("KillBrick")) do
		if part:IsDescendantOf(obby) and part:IsA("BasePart") then
			part.Touched:Connect(function(hit)
				local player = getPlayerFromHit(hit)
				local character = player and player.Character
				local target = player and getCheckpoint(player)
				if character and player and player:GetAttribute("InObby") and target then character:PivotTo(target) end
			end)
		end
	end
	for _, part in ipairs(CollectionService:GetTagged("Fader")) do
		if part:IsDescendantOf(obby) and part:IsA("BasePart") then
			local busy = false
			part.Touched:Connect(function(hit)
				if busy or not getPlayerFromHit(hit) then return end
				busy = true
				task.delay(1, function()
					if part.Parent then
						part.Transparency = 1
						part.CanCollide = false
						task.wait(3)
						if part.Parent then
							part.Transparency = 0
							part.CanCollide = true
						end
					end
					busy = false
				end)
			end)
		end
	end
	for _, part in ipairs(CollectionService:GetTagged("Laser")) do
		if part:IsDescendantOf(obby) and part:IsA("BasePart") then
			task.spawn(function()
				while part.Parent do
					part:SetAttribute("Active", false)
					part.Transparency = 0.85
					part.CanTouch = false
					task.wait(1)
					if not part.Parent then break end
					part:SetAttribute("Active", true)
					part.Transparency = 0.1
					part.CanTouch = true
					task.wait(1)
				end
			end)
			part.Touched:Connect(function(hit)
				if part:GetAttribute("Active") ~= true then return end
				local player = getPlayerFromHit(hit)
				local character = player and player.Character
				local target = player and getCheckpoint(player)
				if player and character and player:GetAttribute("InObby") and target then character:PivotTo(target) end
			end)
		end
	end
	for _, part in ipairs(CollectionService:GetTagged("Spinner")) do
		if part:IsDescendantOf(obby) and part:IsA("BasePart") then
			local duration = part:GetAttribute("SpinTime") or 5
			local origin = part.CFrame
			TweenService:Create(part, TweenInfo.new(duration, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1), {
			CFrame = origin * CFrame.Angles(math.pi, 0, 0),
			}):Play()
		end
	end
	for _, part in ipairs(CollectionService:GetTagged("Conveyor")) do
		if part:IsDescendantOf(obby) and part:IsA("BasePart") then
			part.Touched:Connect(function(hit)
				local player = getPlayerFromHit(hit)
				local root = player and player.Character and player.Character:FindFirstChild("HumanoidRootPart")
				if root and root:IsA("BasePart") and player:GetAttribute("InObby") then
					root.AssemblyLinearVelocity += Vector3.new(-(part:GetAttribute("ConveyorSpeed") or 8), 0, 0)
				end
			end)
		end
	end
	for _, part in ipairs(CollectionService:GetTagged("Mover")) do
		if part:IsDescendantOf(obby) and part:IsA("BasePart") and not part:GetAttribute("MoverTweenStarted") then
			part:SetAttribute("MoverTweenStarted", true)
			local offset = part:GetAttribute("MoveOffset")
			local duration = part:GetAttribute("MoveTime") or 3
			if typeof(offset) == "Vector3" then
				local origin = part.CFrame
				TweenService:Create(part, TweenInfo.new(duration, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), { CFrame = origin + offset }):Play()
			end
		end
	end
	for _, part in ipairs(obby:GetDescendants()) do
		if part:IsA("BasePart") and part:GetAttribute("Trampoline") == true then
			part.Touched:Connect(function(hit)
				local player = getPlayerFromHit(hit)
				local root = player and player.Character and player.Character:FindFirstChild("HumanoidRootPart")
				if player and root and root:IsA("BasePart") and player:GetAttribute("InObby") then
					root.AssemblyLinearVelocity = Vector3.new(root.AssemblyLinearVelocity.X, 65, root.AssemblyLinearVelocity.Z)
				end
			end)
		end
	end
end

return HazardService
