local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")

local Xijum = ReplicatedStorage:WaitForChild("Xijum")
local WeaponSystem = Xijum:WaitForChild("WeaponSystem")
local Assets = WeaponSystem:WaitForChild("Assets")

-- ============================================================================
-- CLASS
-- ============================================================================

local BulletEffect = {}
BulletEffect.__index = BulletEffect

export type EffectConfig = {
	decalSize: number,
	decalLifetime: number,
	soundVolume: number,
}

local DEFAULT_CONFIG: EffectConfig = {
	decalSize = 0.4,
	decalLifetime = 30,
	soundVolume = 0.5,
}

-- ============================================================================
-- SOUNDS
-- ============================================================================

local MATERIAL_SOUNDS = {
	[Enum.Material.Concrete] = "rbxassetid://142082166",
	[Enum.Material.Brick] = "rbxassetid://139818366003696",
	[Enum.Material.Cobblestone] = "rbxassetid://139818366003696",
	[Enum.Material.Metal] = "rbxassetid://9116673678",
	[Enum.Material.DiamondPlate] = "rbxassetid://9116673678",
	[Enum.Material.CorrodedMetal] = "rbxassetid://9116673678",
	[Enum.Material.Wood] = "rbxassetid://8542226017",
	[Enum.Material.WoodPlanks] = "rbxassetid://8542224819",
	[Enum.Material.Glass] = "rbxassetid://116374735080767",
	[Enum.Material.Sand] = "rbxassetid://104300505318787",
	[Enum.Material.Grass] = "rbxassetid://1055286841",
}

local DEFAULT_SOUND = "rbxassetid://8636404035"
local BLOOD_SOUND = "rbxassetid://76525344270919"

-- ============================================================================
-- PUBLIC API
-- ============================================================================

function BulletEffect.createImpactEffect(
	hitPart: BasePart,
	hitPosition: Vector3,
	hitNormal: Vector3,
	isPlayer: boolean,
	config: EffectConfig
)
	config = config or DEFAULT_CONFIG

	if isPlayer then
		BulletEffect:_createBloodEffect(hitPart, hitPosition, hitNormal, config)
	else
		BulletEffect:_createBulletHole(hitPart, hitPosition, hitNormal, config)
	end
end

-- ============================================================================
-- BLOOD
-- ============================================================================

function BulletEffect:_createBloodEffect(
	hitPart: BasePart,
	hitPosition: Vector3,
	hitNormal: Vector3,
	config: EffectConfig
)
	local attachment = Instance.new("Attachment")
	attachment.WorldPosition = hitPosition
	attachment.Parent = Workspace.Terrain

	local emitter = ReplicatedStorage:WaitForChild("Xijum")
		:WaitForChild("WeaponSystem")
		:WaitForChild("Assets")
		:WaitForChild("BloodEmitter")
		:Clone()

	emitter.Parent = attachment
	emitter.Enabled = false
	emitter:Emit(25)

	BulletEffect:_playSound(hitPosition, BLOOD_SOUND, config.soundVolume)

	Debris:AddItem(attachment, 0.5)
end

-- ============================================================================
-- BULLET HOLE
-- ============================================================================

function BulletEffect:_createBulletHole(
	hitPart: BasePart,
	hitPosition: Vector3,
	hitNormal: Vector3,
	config: EffectConfig
)
	-- Thin bullet hole part
	local hole = Assets:FindFirstChild("BulletHole"):Clone()
	assert(hole, "Hole Model not found in Assets")

	-- Offset slightly so it doesn't Z-fight
	hole.CFrame = CFrame.new(hitPosition + hitNormal * 0.01, hitPosition + hitNormal)

	hole.Parent = Workspace

	-- Weld to surface
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = hole
	weld.Part1 = hitPart
	weld.Parent = hole

	-- Impact particles
	local attachment = Instance.new("Attachment")
	attachment.Parent = hole

	-- PLAY MODEL EMMITERS
	task.wait()
	hole.Dust:Emit(3)
	hole.Pebbel:Emit(3)

	-- Sound
	--local soundId = MATERIAL_SOUNDS[hitPart.Material] or DEFAULT_SOUND
	--BulletEffect:_playSound(hitPosition, soundId, config.soundVolume)

	Debris:AddItem(hole, config.decalLifetime)
end

-- ============================================================================
-- SOUND
-- ============================================================================

function BulletEffect:_playSound(position: Vector3, soundId: string, volume: number)
	local part = Instance.new("Part")
	part.Anchored = true
	part.CanCollide = false
	part.CanTouch = false
	part.CanQuery = false
	part.Transparency = 1
	part.Size = Vector3.new(0.2, 0.2, 0.2)
	part.CFrame = CFrame.new(position)
	part.Parent = Workspace

	local sound = Instance.new("Sound")
	sound.SoundId = soundId
	sound.Volume = volume
	sound.RollOffMaxDistance = 80
	sound.Parent = part
	sound:Play()

	Debris:AddItem(part, sound.TimeLength + 0.5)
end

return BulletEffect
