local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Xijum = ReplicatedStorage:WaitForChild("Xijum")
local WeaponSystem = Xijum:WaitForChild("WeaponSystem")

local Settings = require(WeaponSystem:WaitForChild("Settings"):WaitForChild("Humanoid"))

local MovementController = {}
local _Players = game:GetService("Players")

export type MovementType = "normal" | "aiming" | "reloading"

function MovementController.new(character: Model)
	local self = setmetatable({}, { __index = MovementController })

	self.character = character
	self.humanoid = character:WaitForChild("Humanoid")
	self.rootPart = character:WaitForChild("HumanoidRootPart")
	self.isAiming = false
	self.isReloading = false

	return self
end

function MovementController:setWalkSpeed(speed: number)
	self.humanoid.WalkSpeed = speed
end

function MovementController:getWalkSpeed(): number
	return self.humanoid.WalkSpeed
end

function MovementController:setMovementType(movementType: MovementType)
	if movementType == "normal" then
		self:setWalkSpeed(Settings.Speed.Normal)
		self.isAiming = false
		self.isReloading = false
	elseif movementType == "aiming" then
		self:setWalkSpeed(Settings.Speed.Aiming)
		self.isAiming = true
		self.isReloading = false
	elseif movementType == "reloading" then
		self:setWalkSpeed(Settings.Speed.Reloading)
		self.isAiming = false
		self.isReloading = true
	end
end

function MovementController:applySettings()
	-- apply default walk speed and other settings there might be
	self:setWalkSpeed(Settings.Speed.Normal)
end

return MovementController
