local AnimationHandler = {}
AnimationHandler.__index = AnimationHandler

function AnimationHandler.new()
	local self = setmetatable({}, AnimationHandler)
	self.AnimationsList = {}
	self.Animations = {}
	self.Humanoid = nil
	return self
end

function AnimationHandler:Initialize(config)
	self.AnimationsList = config.Animations
end

function AnimationHandler:LoadAnimations(character)
	self.Humanoid = character:WaitForChild("Humanoid")
	for name, animationId in pairs(self.AnimationsList) do
		if animationId ~= "" then
			local animation = Instance.new("Animation")
			animation.AnimationId = animationId
			self.Animations[name] = self.Humanoid.Animator:LoadAnimation(animation)
			if name == "Aim" or name == "Reload" or name == "Fire" then
				self.Animations[name].Priority = Enum.AnimationPriority.Action2
			end
		end
	end
end

function AnimationHandler:PlayAnimation(name, speed: number?)
	if self.Animations[name] then
		if speed then
			self.Animations[name].PlaybackSpeed = speed
		end
		self.Animations[name]:Play()
	end
end

function AnimationHandler:StopAnimation(name)
	if self.Animations[name] then
		self.Animations[name]:Stop()
	end
end

function AnimationHandler:StopAllAnimations()
	for _, animation in pairs(self.Animations) do
		animation:Stop()
	end
end

return AnimationHandler
