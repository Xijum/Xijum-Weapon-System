local WeaponClient = require(script:WaitForChild("WeaponClient"))

local controller = WeaponClient.new()

controller:BindInput()

local Player = game.Players.LocalPlayer
local Character = Player.Character or Player.CharacterAdded:Wait()
Character.Humanoid.Died:Connect(function()
	controller:OnCharacterDied()
end)

print("[XijumWeaponSystem] Client successfully started!")
