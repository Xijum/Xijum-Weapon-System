local BulletCase = {}
BulletCase.__index = BulletCase

function BulletCase.new(attachment: Attachment)
	local self = setmetatable({}, BulletCase)
	self.attachment = attachment
	return self
end

function BulletCase:eject()
	local bulletCase = Instance.new("Part")
	bulletCase.Size = Vector3.new(0.1, 0.3, 0.1)
	bulletCase.Color = Color3.new(0.5, 0.5, 0.5)
	bulletCase.Material = Enum.Material.Metal
	bulletCase.Position = self.attachment.WorldPosition
	bulletCase.Anchored = false
	bulletCase.Parent = workspace

	local bodyVelocity = Instance.new("BodyVelocity")
	bodyVelocity.Velocity = Vector3.new(math.random(-10, 10), math.random(5, 15), math.random(-10, 10))
	bodyVelocity.MaxForce = Vector3.new(1000, 1000, 1000)
	bodyVelocity.Parent = bulletCase

	game:GetService("Debris"):AddItem(bulletCase, 5)
end

return BulletCase
