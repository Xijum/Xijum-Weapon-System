local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Xijum = ReplicatedStorage:WaitForChild("Xijum")
local WeaponSystem = Xijum:WaitForChild("WeaponSystem")
local RemoteNames = require(WeaponSystem:WaitForChild("RemotesDefinitions"))
local Remotes = WeaponSystem:WaitForChild("Remotes")
warn(Remotes)

-- ============================================================================
-- WEAPON SERVICE
-- ============================================================================

local playerControllers = {}

local WeaponController = require(WeaponSystem.Core:WaitForChild("WeaponController"))

-- ============================================================================
-- INITIALIZATION
-- ============================================================================

local function initializePlayer(player)
	playerControllers[player.UserId] = WeaponController.new(player)
end

local function cleanupPlayer(player)
	playerControllers[player.UserId] = nil
end

Players.PlayerAdded:Connect(initializePlayer)
Players.PlayerRemoving:Connect(cleanupPlayer)

for _, player in pairs(Players:GetPlayers()) do
	initializePlayer(player)
end

-- ============================================================================
-- REMOTE HANDLERS
-- ============================================================================

local function getController(player)
	local controller = playerControllers[player.UserId]
	if not controller then
		return nil
	end
	return controller
end

Remotes:WaitForChild(RemoteNames.RemoteEvents.Equip).OnServerEvent:Connect(function(player, weapon: Tool)
	local controller = getController(player)
	if not controller then
		return
	end
	controller:EquipWeapon(weapon)
end)

Remotes:WaitForChild(RemoteNames.RemoteEvents.Unequip).OnServerEvent:Connect(function(player, weapon: Tool)
	local controller = getController(player)
	if not controller then
		return
	end
	controller:UnequipWeapon(weapon)
end)

Remotes:WaitForChild(RemoteNames.RemoteEvents.Fire).OnServerEvent:Connect(function(player, fireData)
	local controller = getController(player)
	if not controller then
		return
	end
	controller:Fire(fireData)
end)

Remotes:WaitForChild(RemoteNames.RemoteEvents.Reload).OnServerEvent:Connect(function(player, weaponId)
	local controller = getController(player)
	if not controller then
		return
	end
	controller:Reload(weaponId)
end)

Remotes:WaitForChild(RemoteNames.RemoteFunctions.GetAmmo).OnServerInvoke = function(player, weaponId)
	local controller = getController(player)
	if not controller then
		return 0
	end
	return controller:GetAmmo(weaponId)
end

Remotes:WaitForChild(RemoteNames.RemoteEvents.Aim).OnServerEvent:Connect(function(player, state)
	local controller = getController(player)
	if not controller then
		return
	end
	controller:SetAiming(state)
end)

print("[XijumWeaponSystem] Server successfully started!")
