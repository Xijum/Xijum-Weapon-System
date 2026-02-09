local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Xijum = ReplicatedStorage:WaitForChild("Xijum")
local WeaponSystem = Xijum:WaitForChild("WeaponSystem")

local RemoteNames = require(WeaponSystem:WaitForChild("RemotesDefinitions"))
local Remotes = WeaponSystem:WaitForChild("Remotes")

local HitmarkerRemote = Remotes:WaitForChild(RemoteNames.RemoteEvents.HitmarkerRemote)

local HitValidation = require(WeaponSystem:WaitForChild("Utils"):WaitForChild("HitValidation"))
local DamageService = require(WeaponSystem:WaitForChild("Utils"):WaitForChild("DamageService"))
local BulletEffect = require(WeaponSystem:WaitForChild("Utils"):WaitForChild("BulletEffect"))

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
	damage: {},
	canPierce: boolean,
	maxPierces: number,
	player: Player,
	caseType: string,
}

function Bullet.new(startPosition: Vector3, direction: Vector3, config: BulletConfig)
	local self = setmetatable({}, Bullet)

	self.position = startPosition
	self.direction = direction.Unit
	self.config = config

	self.shooter = config.player
	warn(self.shooter)
	self.shooterCharacter = self.shooter.Character

	self.pierceCount = 0
	self.hitTargets = {}
	self.alive = true

	self:_createVisuals()
	self:_createRaycastParams()

	return self
end

-- ============================================================================
-- VISUALS
-- ============================================================================

function Bullet:_createVisuals()
	local part = Instance.new("Part")
	part.Shape = Enum.PartType.Ball
	part.Size = self.config.size
	part.Color = self.config.color
	part.Material = self.config.material
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.Anchored = true
	part.CFrame = CFrame.new(self.position)
	part.Parent = Workspace

	local pointLight = Instance.new("PointLight")
	pointLight.Color = self.config.color
	pointLight.Brightness = 2
	pointLight.Range = 15
	pointLight.Parent = part

	self.part = part
end

-- ============================================================================
-- RAYCAST SETUP
-- ============================================================================

function Bullet:_createRaycastParams()
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { self.part, self.shooterCharacter }
	params.IgnoreWater = true

	self.raycastParams = params
end

-- ============================================================================
-- UPDATE
-- ============================================================================

function Bullet:update(deltaTime: number)
	if not self.alive then
		return
	end

	local travelDistance = self.config.speed * deltaTime
	local nextPosition = self.position + (self.direction * travelDistance)
	local rayDirection = nextPosition - self.position

	local result = Workspace:Raycast(self.position, rayDirection, self.raycastParams)

	if result then
		self:_processHit(result)
	else
		self.position = nextPosition
		self.part.CFrame = CFrame.new(self.position)
	end

	self.config.lifetime -= deltaTime
	if self.config.lifetime <= 0 then
		self:destroy()
	end
end

-- ============================================================================
-- HIT HANDLING
-- ============================================================================

function Bullet:_processHit(result: RaycastResult)
	local hitPart = result.Instance

	-- Move bullet to impact point
	self.position = result.Position
	self.part.CFrame = CFrame.new(self.position)

	-- Prevent multi-hitting same target
	if self.hitTargets[hitPart] then
		return
	end
	self.hitTargets[hitPart] = true

	-- Validate hit
	local isValid, characterData = HitValidation.HitValidationDetection(hitPart)
	if isValid then
		DamageService.ApplyDamage(characterData, self.config.damage.Default)
		HitmarkerRemote:FireClient(self.shooter, true)
	end

	BulletEffect.createImpactEffect(
		hitPart,
		result.Position,
		result.Normal, -- << REQUIRED AFTER REFACTOR
		isValid,
		{
			decalSize = 1,
			decalLifetime = 30,
			soundVolume = 0.5,
		}
	)

	-- Stop bullet if no pierce
	if not self.config.canPierce or self.pierceCount >= self.config.maxPierces then
		self:destroy()
		return
	end

	-- Prepare for next pierce
	self.pierceCount += 1

	-- Blacklist hit part
	table.insert(self.raycastParams.FilterDescendantsInstances, hitPart)

	-- Advance slightly to avoid re-hit
	self.position += self.direction * 0.01
end

-- ============================================================================
-- CLEANUP
-- ============================================================================

function Bullet:destroy()
	self.alive = false
	if self.part then
		self.part:Destroy()
	end
end

return Bullet
