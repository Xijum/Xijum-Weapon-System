-- Spread Framework
local Spread = {}
Spread.__index = Spread

function Spread.new(config)
	local self = setmetatable({}, Spread)
	self.config = config
	return self
end

function Spread:SetConfig(config)
	self.config = config
end

function Spread:GetCurrentSpread(isAiming, isMoving)
	local baseSpread = isAiming and self.config.Spread.Aim or self.config.Spread.Hip
	local aimingModifier = isAiming and self.config.Spread.Aim or 1
	local movementModifier = isMoving and self.config.Spread.MovePenalty or 1

	local currentSpread = baseSpread * aimingModifier * movementModifier
	return currentSpread
end

return Spread
