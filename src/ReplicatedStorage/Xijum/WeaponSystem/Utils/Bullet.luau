local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- ============================================================================
-- SERVICES & INITIALIZATION
-- ============================================================================

local Xijum = ReplicatedStorage:WaitForChild("Xijum")
local WeaponSystem = Xijum:WaitForChild("WeaponSystem"):WaitForChild("Utils")

local HitValidation = require(WeaponSystem:WaitForChild("HitValidation"))
local DamageService = require(WeaponSystem:WaitForChild("DamageService"))

-- ============================================================================
-- CLASS DEFINITION
-- ============================================================================

local Bullet = {}
Bullet.__index = Bullet

export type BulletConfig = {
	speed: number,
	lifetime: number,
	size: Vector3,
	color: Color3,
	material: Enum.Material,
	damage: number,
	canPierce: boolean,
	maxPierces: number,
}

function Bullet.new(startPosition: Vector3, direction: Vector3, config: BulletConfig)
	local self = setmetatable({}, Bullet)

	self.position = startPosition
	self.direction = direction.Unit
	self.config = config
	self.pierceCount = 0
	self.hitTargets = {}
	self.alive = true

	self:_createVisuals()

	return self
end

function Bullet:_createVisuals()
	local part = Instance.new("Part")
	part.Shape = Enum.PartType.Ball
	part.Size = self.config.size
	part.Color = self.config.color
	part.Material = self.config.material
	part.CanCollide = false
	part.CFrame = CFrame.new(self.position)
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Parent = workspace

	self.part = part
end

function Bullet:update(deltaTime: number)
	if not self.alive then
		return
	end

	self.position = self.position + (self.direction * self.config.speed * deltaTime)
	self.part.CFrame = CFrame.new(self.position)
	self.config.lifetime -= deltaTime

	if self.config.lifetime <= 0 then
		self:destroy()
	end
end

function Bullet:onHit(hitPart: BasePart)
	if self.hitTargets[hitPart] then
		return
	end

	self.hitTargets[hitPart] = true

	local isValid, characterData = HitValidation.HitValidationDetection(hitPart)
	if isValid then
		DamageService.ApplyDamage(characterData, self.config.damage)
	end

	if not self.config.canPierce or self.pierceCount >= self.config.maxPierces then
		self:destroy()
	else
		self.pierceCount += 1
	end
end

function Bullet:destroy()
	self.alive = false
	if self.part then
		self.part:Destroy()
	end
end

return Bullet
