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
	local r = self.config.Recoil

	local vertical = r.Vertical + ((math.random() - 0.5) * 2 * r.VerticalRandom)
	local horizontal = (math.random() - 0.5) * 2 * r.Horizontal

	self.currentRecoil += Vector2.new(horizontal, vertical)

	-- CLAMP (this is the important part)
	self.currentRecoil = Vector2.new(
		math.clamp(self.currentRecoil.X, -r.MaxHorizontal, r.MaxHorizontal),
		math.clamp(self.currentRecoil.Y, 0, r.MaxVertical)
	)
end

function Recoil:UpdateRecoil(dt)
	local returnSpeed = self.config.Recoil.ReturnSpeed

	self.currentRecoil -= self.currentRecoil * math.min(returnSpeed * dt, 1)
end

function Recoil:GetCurrentRecoil()
	return self.currentRecoil
end

return Recoil
