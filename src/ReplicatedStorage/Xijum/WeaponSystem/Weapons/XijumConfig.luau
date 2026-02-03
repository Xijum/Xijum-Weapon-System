return {
	Name = "FX-05 Xijum",

	FireMode = { "Auto", "Semi" }, -- Auto | Semi | Burst | Pump
	FireRate = 750, -- RPM

	Damage = 24,
	Range = 1000,

	MagazineSize = 30,
	ReserveAmmo = 120,
	ReloadTime = 2.4,

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

	Animations = {
		Idle = "rbxassetid://10686514105",
		Fire = "rbxassetid://135830481157981",
		Aim = "rbxassetid://10686522656",
		Reload = "rbxassetid://111829045939459",
		Equip = "rbxassetid://86022375945841",
		Unequip = "rbxassetid://124291191673246",
	},

	Sounds = {
		Fire = "rbxassetid://240718012",
		Reload = "rbxassetid://5445945972",
		Equip = "rbxassetid://5508953366",
		Unequip = "rbxassetid://5508953366",
		Aim = "rbxassetid://125800774064191",
		Firemode = "rbxassetid://102002648823684",
		Emtpy = "rbxassetid://321719832",
		EmptyClick = "rbxassetid://743780661",
	},

	Bullet = {},
}
