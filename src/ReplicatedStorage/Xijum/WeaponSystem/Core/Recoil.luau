-- Recoil Framework
local Recoil = {}
Recoil.__index = Recoil

function Recoil.new(config)
	local self = setmetatable({}, Recoil)
	self.config = config
	self.currentRecoil = Vector2.new(0, 0)
	return self
end

function Recoil:SetConfig(config)
	self.config = config
end

function Recoil:ApplyRecoil()
	local recoilConfig = self.config.Recoil
	local verticalRecoil = recoilConfig.Vertical
	local horizontalRecoil = (math.random() - 0.5) * 2 * recoilConfig.Horizontal

	self.currentRecoil = self.currentRecoil + Vector2.new(horizontalRecoil, verticalRecoil)
	warn(self.currentRecoil)
end

function Recoil:UpdateRecoil(deltaTime)
	local returnSpeed = self.config.Recoil.ReturnSpeed
	local recoilReduction = returnSpeed * deltaTime

	if self.currentRecoil.Y > 0 then
		self.currentRecoil = self.currentRecoil - Vector2.new(0, math.min(recoilReduction, self.currentRecoil.Y))
	end

	if math.abs(self.currentRecoil.X) > 0 then
		local horizontalReduction = math.min(recoilReduction, math.abs(self.currentRecoil.X))
		self.currentRecoil = self.currentRecoil - Vector2.new(math.sign(self.currentRecoil.X) * horizontalReduction, 0)
	end
end

function Recoil:GetCurrentRecoil()
	return self.currentRecoil
end

return Recoil
