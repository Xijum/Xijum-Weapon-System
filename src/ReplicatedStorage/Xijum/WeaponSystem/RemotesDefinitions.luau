-- Xijum Weapon System - Remote Definitions

return {
	RemoteEvents = {
		Equip = "Xijum_WeaponEquip",
		Fire = "Xijum_WeaponFire",
		Reload = "Xijum_WeaponReload",
		Aim = "Xijum_WeaponAim",
		FiremodeChange = "Xijum_WeaponFiremodeChange",
		Unequip = "Xijum_WeaponUnequip",
		Sound = "Xijum_WeaponSound",
		AimUpdate = "Xijum_WeaponAimUpdate",

		AmmoUpdateRemote = "Xijum_WeaponAmmoUpdate",
		HitmarkerRemote = "Xijum_WeaponHitmarker",
		HolsterRemote = "Xijum_WeaponHolster",
	},
	RemoteFunctions = {
		GetAmmo = "Xijum_WeaponGetAmmoFunction",
		GenerateGUID = "Xijum_GenerateWeaponUIDFunction",
	},
}
