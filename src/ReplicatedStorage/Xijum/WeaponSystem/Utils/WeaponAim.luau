local RunService = game:GetService("RunService")

local WeaponAim = {}
WeaponAim.__index = WeaponAim

function WeaponAim.new(player: Player, tool: Tool)
	local self = setmetatable({}, WeaponAim)

	self.Player = player
	self.Tool = tool
	self.Character = player.Character or player.CharacterAdded:Wait()
	self.Humanoid = self.Character:WaitForChild("Humanoid")
	self.RootPart = self.Character:WaitForChild("HumanoidRootPart")
	self.Handle = tool:WaitForChild("Handle")

	self.Connection = nil

	return self
end

function WeaponAim:Start()
	if self.Connection then
		return
	end

	self.Connection = RunService.RenderStepped:Connect(function()
		if not self.Tool.Parent == self.Character then
			return
		end

		local camera = workspace.CurrentCamera
		local lookVector = camera.CFrame.LookVector

		-- Calculate the target position ahead of the player
		local targetPosition = self.RootPart.Position + (lookVector * 100)

		-- Make the handle look at the target position
		local currentPosition = self.Handle.Position
		local newCFrame = CFrame.lookAt(currentPosition, targetPosition)

		-- Apply the rotation to the handle
		self.Handle.CFrame = newCFrame
	end)
end

function WeaponAim:Stop()
	if self.Connection then
		self.Connection:Disconnect()
		self.Connection = nil
	end
end

function WeaponAim:Destroy()
	self:Stop()
	self.Player = nil
	self.Tool = nil
	self.Character = nil
	self.Humanoid = nil
	self.RootPart = nil
	self.Handle = nil
end

return WeaponAim
