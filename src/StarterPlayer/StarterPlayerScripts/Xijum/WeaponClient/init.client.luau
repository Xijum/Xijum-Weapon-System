local WeaponClient = require(script:WaitForChild("WeaponClient"))

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Xijum = ReplicatedStorage:WaitForChild("Xijum")
local WeaponSystem = Xijum:WaitForChild("WeaponSystem")

local RemoteNames = require(WeaponSystem:WaitForChild("RemotesDefinitions"))
local Remotes = WeaponSystem:WaitForChild("Remotes")

local AmmoUpdateRemote = Remotes:WaitForChild(RemoteNames.RemoteEvents.AmmoUpdateRemote)
local HitmarkerRemote = Remotes:WaitForChild(RemoteNames.RemoteEvents.HitmarkerRemote)

local controller = WeaponClient.new()

local Player = game.Players.LocalPlayer
Player.CharacterAdded:connect(function(Character)
	controller:InitHUD()
	controller:BindInput()

	Character.Humanoid.Died:Connect(function()
		controller:OnCharacterDied()
	end)
end)

AmmoUpdateRemote.OnClientEvent:Connect(function(currentAmmo: number, reserveAmmo: number)
	controller.WeaponHUD:setAmmo(currentAmmo, reserveAmmo)
end)

HitmarkerRemote.OnClientEvent:Connect(function(hit: boolean)
	controller:HitmarkerFeedback(hit)
end)

print("[XijumWeaponSystem] Client successfully started!")
