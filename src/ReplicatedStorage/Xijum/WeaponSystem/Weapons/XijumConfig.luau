return {
	Name = "FX-07 Xijum",

	FireMode = { "Auto", "Semi" }, -- Auto | Semi | Burst | Pump
	FireRate = 750, -- RPM

	DamageConfig = {
		Head = 35,
		Torso = 25,
		Limbs = 15,
		Default = 20,
	},

	Range = 1000,

	MagazineSize = 30,
	ReserveAmmo = 120,
	ReloadTime = 2.4,

	Recoil = {
		Vertical = 1.2,
		VerticalRandom = 0.6,
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
		Fire = "rbxassetid://74543338771779",
		Aim = "rbxassetid://94755584744926",
		Reload = "rbxassetid://111829045939459",
		Equip = "rbxassetid://86022375945841",
		Unequip = "rbxassetid://124291191673246",
	},

	Sounds = {
		Fire = "rbxassetid://240718012",
		Reload = "rbxassetid://5445945972",
		Equip = "rbxassetid://5508953366",
		Unequip = "rbxassetid://5508953366",
		AimDown = "rbxassetid://619578856",
		AimUp = "rbxassetid://619576578",
		Firemode = "rbxassetid://102002648823684",
		Emtpy = "rbxassetid://321719832",
		EmptyClick = "rbxassetid://743780661",
		Hitmarker = "rbxassetid://76525344270919",
	},

	Holster = {

		HolsterPosition = { 0, -0.5, -0.9 },
		HolsterOrientation = { -50, 85, 0 },
		HolsterTarget = "UpperTorso",
	},

	BulletConfig = {
		speed = 500,
		lifetime = 5,
		size = Vector3.new(0.2, 0.2, 1),
		color = Color3.new(1, 0, 0),
		material = Enum.Material.Neon,
		canPierce = false,
		maxPierces = 0,
		caseType = "5.56x45mm",
	},
}
