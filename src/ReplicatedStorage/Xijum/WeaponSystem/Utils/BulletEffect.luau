local Workspace = game:GetService("Workspace")

-- ============================================================================
-- CLASS DEFINITION
-- ============================================================================

local BulletEffect = {}
BulletEffect.__index = BulletEffect

export type EffectConfig = {
	decalSize: number,
	decalLifetime: number,
	soundVolume: number,
}

local DEFAULT_CONFIG: EffectConfig = {
	decalSize = 1,
	decalLifetime = 30,
	soundVolume = 0.5,
}

local MATERIAL_SOUNDS = {
	[Enum.Material.Concrete] = "rbxasset://sounds/impact_stone.ogg",
	[Enum.Material.Brick] = "rbxasset://sounds/impact_stone.ogg",
	[Enum.Material.Cobblestone] = "rbxasset://sounds/impact_stone.ogg",
	[Enum.Material.Metal] = "rbxasset://sounds/impact_metal.ogg",
	[Enum.Material.DiamondPlate] = "rbxasset://sounds/impact_metal.ogg",
	[Enum.Material.CorrodedMetal] = "rbxasset://sounds/impact_metal.ogg",
	[Enum.Material.Wood] = "rbxasset://sounds/impact_wood.ogg",
	[Enum.Material.WoodPlanks] = "rbxasset://sounds/impact_wood.ogg",
	[Enum.Material.Glass] = "rbxasset://sounds/Glassbreak.ogg",
	[Enum.Material.Sand] = "rbxasset://sounds/impact_sand.ogg",
	[Enum.Material.Grass] = "rbxasset://sounds/impact_grass.ogg",
}

local DEFAULT_SOUND = "rbxasset://sounds/impact_generic.ogg"
local BLOOD_SOUND = "rbxasset://sounds/impact_flesh.ogg"

-- ============================================================================
-- PUBLIC METHODS
-- ============================================================================

function BulletEffect.createImpactEffect(
	hitPart: BasePart,
	hitPosition: Vector3,
	isPlayer: boolean,
	config: EffectConfig
)
	config = config or DEFAULT_CONFIG

	if isPlayer then
		BulletEffect:_createBloodEffect(hitPart, hitPosition, config)
	else
		BulletEffect:_createBulletHole(hitPart, hitPosition, config)
	end
end

-- ============================================================================
-- PRIVATE METHODS
-- ============================================================================

function BulletEffect:_createBloodEffect(hitPart: BasePart, hitPosition: Vector3, config: EffectConfig)
	-- Create blood particle emitter
	local attachment = Instance.new("Attachment")
	attachment.Parent = hitPart
	attachment.WorldPosition = hitPosition

	local emitter = Instance.new("ParticleEmitter")
	emitter.Texture = "rbxasset://textures/Particles/sparkles_main.dds"
	emitter.Color = ColorSequence.new(Color3.fromRGB(139, 0, 0))
	emitter.Size = NumberSequence.new(0.5)
	emitter.Lifetime = NumberSequence.new(2)
	emitter.Rate = 50
	emitter.Speed = NumberRange.new(10, 20)
	emitter.Parent = attachment

	-- Play blood sound
	BulletEffect:_playSound(hitPosition, BLOOD_SOUND, config.soundVolume)

	-- Clean up after lifetime
	game:GetService("Debris"):AddItem(attachment, 0.5)
end

function BulletEffect:_createBulletHole(hitPart: BasePart, hitPosition: Vector3, config: EffectConfig)
	-- Create bullet hole decal
	local decal = Instance.new("Decal")
	decal.Texture = "rbxasset://textures/Bullet_Hole.png"
	decal.Size = NumberSequence.new(config.decalSize)
	decal.Face = BulletEffect:_getNearestFace(hitPart, hitPosition)
	decal.Parent = hitPart

	-- Create particle emitter
	local attachment = Instance.new("Attachment")
	attachment.Parent = hitPart
	attachment.WorldPosition = hitPosition

	local emitter = Instance.new("ParticleEmitter")
	emitter.Texture = "rbxasset://textures/Particles/sparkles_main.dds"
	emitter.Color = ColorSequence.new(Color3.fromRGB(162, 138, 51))
	emitter.Size = NumberSequence.new(0.5)
	emitter.Lifetime = NumberSequence.new(2)
	emitter.Rate = 50
	emitter.Speed = NumberRange.new(10, 20)
	emitter.Parent = attachment

	-- Play material-appropriate sound
	local material = hitPart.Material
	local soundId = MATERIAL_SOUNDS[material] or MATERIAL_SOUNDS[Enum.Material.Concrete]
	BulletEffect:_playSound(hitPosition, soundId, config.soundVolume)

	-- Remove decal after lifetime
	game:GetService("Debris"):AddItem(decal, config.decalLifetime)
	game:GetService("Debris"):AddItem(attachment, 0.5)
end

function BulletEffect:_getNearestFace(part: BasePart, position: Vector3): Enum.NormalId
	local localPosition = part.CFrame:VectorToObjectSpace(position - part.Position)
	local absX = math.abs(localPosition.X)
	local absY = math.abs(localPosition.Y)
	local absZ = math.abs(localPosition.Z)

	if absX > absY and absX > absZ then
		return localPosition.X > 0 and Enum.NormalId.Right or Enum.NormalId.Left
	elseif absY > absZ then
		return localPosition.Y > 0 and Enum.NormalId.Top or Enum.NormalId.Bottom
	else
		return localPosition.Z > 0 and Enum.NormalId.Front or Enum.NormalId.Back
	end
end

function BulletEffect:_playSound(position: Vector3, soundId: string, volume: number)
	local sound = Instance.new("Sound")
	sound.SoundId = soundId
	sound.Volume = volume
	sound.Parent = Workspace

	local part = Instance.new("Part")
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.Transparency = 1
	part.CFrame = CFrame.new(position)
	part.Parent = Workspace

	sound.Parent = part
	sound:Play()

	game:GetService("Debris"):AddItem(part, sound.TimeLength + 0.5)
end

return BulletEffect
