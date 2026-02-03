-- Ability using UIS to test different debug features
local UserInputService = game:GetService("UserInputService")
if true then
	return
end
-- Camera Framework Testing
local Camera = require(game.ReplicatedStorage.Xijum.WeaponSystem.Core.Camera)

local cameraConfig = {
	Recoil = {
		Vertical = 1.2,
		Horizontal = 0.6,
		ReturnSpeed = 18,
	},

	Spread = {
		Hip = 2.5,
		Aim = 0.8,
		MovePenalty = 1.2,
	},

	Camera = {
		ADS_FOV = 65,
		OTS_Offset = Vector3.new(1.8, 1.2, 3),
	},
}

local camera = Camera.new(cameraConfig)

UserInputService.InputBegan:Connect(function(input, gameProcessedEvent)
	if gameProcessedEvent then
		return
	end

	if input.KeyCode == Enum.KeyCode.C then
		if camera.isActive then
			camera:Deactivate()
			print("Camera deactivated.")
		else
			camera:Activate()
			print("Camera activated.")
		end
	elseif input.KeyCode == Enum.KeyCode.V then
		camera:ToggleMode()
		print("Camera mode toggled.")
	end
end)

game:GetService("RunService").RenderStepped:Connect(function()
	camera:UpdateCamera()
end)
