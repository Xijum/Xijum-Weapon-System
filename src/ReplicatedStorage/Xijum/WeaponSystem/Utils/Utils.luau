local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")

local Xijum = ReplicatedStorage:WaitForChild("Xijum")
local WeaponSystem = Xijum:WaitForChild("WeaponSystem")
local Assets = WeaponSystem:WaitForChild("Assets")

local Utils = {}
Utils.__index = Utils

function Utils:Holster(character, weapon, Position, Orientation, Target)
	if character and not character:FindFirstChild(weapon.Name .. "_Holster") then
		local torso = character.UpperTorso
		local toolClone = weapon:Clone()
		toolClone.WeaponConfiguration:Destroy()

		local toolModel = Instance.new("Model")
		for _, v in pairs(toolClone:GetChildren()) do
			v.Parent = toolModel
		end
		toolClone:Destroy()
		toolModel.Parent = character
		toolModel.Name = weapon.Name .. "_Holster"

		local weld = Instance.new("Weld")
		weld.Name = "WeldHolster"
		if Target and character:FindFirstChild(Target) then
			weld.Part0 = character:FindFirstChild(Target)
		else
			weld.Part0 = torso
		end
		weld.Part1 = toolModel.Handle
		weld.C0 = CFrame.new(table.unpack(Position))
		weld.C0 = weld.C0
			* CFrame.fromOrientation(math.rad(Orientation[1]), math.rad(Orientation[2]), math.rad(Orientation[3]))
		weld.Parent = toolModel.Handle
	end
end

function Utils:Sheath(character, weapon)
	if character and character:FindFirstChild(weapon.Name .. "_Holster") then
		character:FindFirstChild(weapon.Name .. "_Holster"):Destroy()
	end
end

function Utils:bulletHole(result)
	local hole = Assets.BulletHole:Clone()
	hole.Parent = result.instance
	hole.Position = result.position
	hole.CFrame = CFrame.new(hole.Position, hole.Position + result.normal)
	hole.CanTouch = false
	hole.CanCollide = false
	task.wait()
	if result.blood then
		hole.Dust.Color = ColorSequence.new(Color3.new(1, 0, 0))
		hole.Dust:Emit(3)
	else
		hole.Dust:Emit(3)
		hole.Pebbel:Emit(3)
	end
	local wc = Instance.new("WeldConstraint")
	wc.Parent = hole
	wc.Part0 = hole
	wc.Part1 = result.Instance
	Debris:AddItem(hole, 5)
end

function Utils:EjectShell(Receiver, Case)
	local shellModel = Assets:FindFirstChild(Case)
	assert(shellModel, "Shell model not found")

	if shellModel then
		local newShell = shellModel:Clone()
		newShell.Name = "EjectedShell"
		newShell.Position = Receiver.Position
		newShell.CFrame = Receiver.CFrame
		newShell.Velocity = (Receiver.CFrame.LookVector * 8) + (Receiver.CFrame.RightVector * 8) + Vector3.new(0, 15, 0)
		newShell.Parent = workspace
		Receiver:FindFirstChild("Smoke"):Emit(3)
		Debris:AddItem(newShell, 5)
	end
end

function Utils:VFX(Parent)
	local SpotLight: SpotLight = Parent:WaitForChild("FlashFX")
	local FlashFX: ParticleEmitter = Parent:WaitForChild("FlashFX[Flash]")
	local Smoke: ParticleEmitter = Parent:WaitForChild("Smoke")

	task.spawn(function()
		SpotLight.Enabled = true
		task.wait(1)
		SpotLight.Enabled = false
	end)
	task.wait()
	FlashFX:Emit(3)
	Smoke:Emit(3)
end

return Utils
