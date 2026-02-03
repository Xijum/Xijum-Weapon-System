local RunService = game:GetService("RunService")

-- ============================================================================
-- CLASS DEFINITION
-- ============================================================================

local BodyAim = {}
BodyAim.__index = BodyAim

function BodyAim.new(character: Model)
	local self = setmetatable({}, BodyAim)

	self.Character = character

	self.UpperTorso = character:WaitForChild("UpperTorso")
	self.Waist = self.UpperTorso:WaitForChild("Waist")

	self.DefaultC0 = self.Waist.C0

	-- State
	self.Enabled = false
	self.Active = false
	self.CurrentPitch = 0

	-- Settings
	self.MaxPitch = math.rad(40)
	self.PitchMultiplier = 1
	self.LerpSpeed = 0.25

	self._conn = nil

	return self
end

-- ============================================================================
-- CONTROL
-- ============================================================================

function BodyAim:Start()
	if self.Active then
		return
	end
	self.Active = true

	self._conn = RunService.Heartbeat:Connect(function(dt)
		self:_update(dt)
	end)
end

function BodyAim:Stop()
	if not self.Active then
		return
	end
	self.Active = false

	if self._conn then
		self._conn:Disconnect()
		self._conn = nil
	end

	-- Hard reset
	self.CurrentPitch = 0
	self.Waist.C0 = self.DefaultC0
end

function BodyAim:SetEnabled(enabled: boolean)
	self.Enabled = enabled
end

-- ============================================================================
-- INPUT
-- ============================================================================

function BodyAim:UpdatePitch(pitchRadians: number)
	if not self.Enabled then
		return
	end

	local pitch = pitchRadians * self.PitchMultiplier
	self.CurrentPitch = math.clamp(pitch, -self.MaxPitch, self.MaxPitch)
end

-- ============================================================================
-- INTERNAL
-- ============================================================================

function BodyAim:_update(dt)
	if not self.Enabled then
		self.Waist.C0 = self.Waist.C0:Lerp(self.DefaultC0, self.LerpSpeed)
		return
	end

	local targetC0 = self.DefaultC0 * CFrame.Angles(self.CurrentPitch, 0, 0)
	--self.Waist.C0 = self.Waist.C0:Lerp(targetC0, self.LerpSpeed)
	self.Waist.C0 = targetC0
end

function BodyAim:Destroy()
	self:Stop()
	self.Character = nil
end

return BodyAim
