local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Xijum = ReplicatedStorage:WaitForChild("Xijum")
local WeaponSystem = Xijum:WaitForChild("WeaponSystem")

local RemoteNames = require(WeaponSystem:WaitForChild("RemotesDefinitions"))

local folder = Instance.new("Folder")
folder.Name = "Remotes"
folder.Parent = WeaponSystem

local function createRemote(name: string)
	local remote = Instance.new("RemoteEvent")
	remote.Name = name
	remote.Parent = folder
	return remote
end

local function createRemoteFunction(name: string)
	local remoteFunction = Instance.new("RemoteFunction")
	remoteFunction.Name = name
	remoteFunction.Parent = folder
	return remoteFunction
end

local RemotesEvents = {
	Equip = createRemote(RemoteNames.RemoteEvents.Equip),
	Fire = createRemote(RemoteNames.RemoteEvents.Fire),
	Reload = createRemote(RemoteNames.RemoteEvents.Reload),
	Aim = createRemote(RemoteNames.RemoteEvents.Aim),
	FiremodeChange = createRemote(RemoteNames.RemoteEvents.FiremodeChange),
	Unequip = createRemote(RemoteNames.RemoteEvents.Unequip),
	Sound = createRemote(RemoteNames.RemoteEvents.Sound),
	AimUpdate = createRemote(RemoteNames.RemoteEvents.AimUpdate),
	HolsterRemote = createRemote(RemoteNames.RemoteEvents.HolsterRemote),

	AmmoUpdateRemote = createRemote(RemoteNames.RemoteEvents.AmmoUpdateRemote),
	HitmarkerRemote = createRemote(RemoteNames.RemoteEvents.HitmarkerRemote),
}
local RemotesFunctions = {
	GetAmmo = createRemoteFunction(RemoteNames.RemoteFunctions.GetAmmo),
	GenerateGUID = createRemoteFunction(RemoteNames.RemoteFunctions.GenerateGUID),
}

function log(player, action, details)
	print(string.format("[XijumWeaponSystem] Player: %s | Action: %s | Details: %s", player.Name, action, details))
end

-- Hook points
RemotesEvents.Fire.OnServerEvent:Connect(function(player, _)
	log(player, "Fire", "Weapon fired")
end)

RemotesEvents.Reload.OnServerEvent:Connect(function(player, _)
	log(player, "Reload", "Weapon reloaded")
end)

RemotesEvents.Equip.OnServerEvent:Connect(function(player, _)
	log(player, "Equip", "Weapon equipped")
end)

RemotesEvents.Aim.OnServerEvent:Connect(function(player, _)
	log(player, "Aim", "Aiming state changed")
end)

RemotesEvents.FiremodeChange.OnServerEvent:Connect(function(player, _)
	log(player, "FiremodeChange", "Fire mode changed")
end)

RemotesEvents.Unequip.OnServerEvent:Connect(function(player, _)
	log(player, "Unequip", "Weapon unequipped")
end)

RemotesEvents.Sound.OnServerEvent:Connect(function(player, soundId)
	log(player, "Sound", "Play sound with ID: " .. tostring(soundId))

	local character = player.Character
	if character then
		local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
		if humanoidRootPart then
			local sound = Instance.new("Sound")
			sound.SoundId = soundId
			sound.Parent = humanoidRootPart
			sound:Play()
			sound.Ended:Connect(function()
				sound:Destroy()
			end)
		end
	end
end)

RemotesEvents.AimUpdate.OnServerEvent:Connect(function(player, isAiming)
	--log(player, "AimUpdate", "Aiming update: " .. tostring(isAiming))
end)

RemotesEvents.AmmoUpdateRemote.OnServerEvent:Connect(function(player, weaponId, currentAmmo, reserveAmmo)
	log(
		player,
		"AmmoUpdate",
		string.format(
			"Weapon ID: %s | Current Ammo: %d | Reserve Ammo: %d",
			tostring(weaponId),
			currentAmmo,
			reserveAmmo
		)
	)
end)

RemotesEvents.HitmarkerRemote.OnServerEvent:Connect(function(player, hitType)
	log(player, "Hitmarker", "Hit type: " .. tostring(hitType))
end)

RemotesEvents.HolsterRemote.OnServerEvent:Connect(function(player, weaponId)
	log(player, "Holster", "Weapon ID: " .. tostring(weaponId) .. " holstered")
end)

-- FUNCTIONS

RemotesFunctions.GetAmmo.OnServerInvoke = function(player, weaponId)
	log(player, "GetAmmo", "Requested ammo for weapon ID: " .. tostring(weaponId))
	return 15 -- Placeholder value
end

RemotesFunctions.GenerateGUID.OnServerInvoke = function(player)
	log(player, "GenerateGUID", "Requested new weapon GUID")
end

print("[XijumWeaponSystem] Remotes created")
