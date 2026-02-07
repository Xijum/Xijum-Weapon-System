local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local RenderStepped = game:GetService("RunService").Heartbeat

local Xijum = ReplicatedStorage:WaitForChild("Xijum")
local WeaponSystem = Xijum:WaitForChild("WeaponSystem")

local RemoteNames = require(WeaponSystem:WaitForChild("RemotesDefinitions"))
local Remotes = WeaponSystem:WaitForChild("Remotes")

local Raycast = require(WeaponSystem:WaitForChild("Utils"):WaitForChild("Raycast"))
local Bullet = require(WeaponSystem:WaitForChild("Utils"):WaitForChild("Bullet"))
local BodyAim = require(WeaponSystem:WaitForChild("Utils"):WaitForChild("BodyAim"))
local BulletCase = require(WeaponSystem:WaitForChild("Utils"):WaitForChild("BulletCase"))
local Holster = require(WeaponSystem:WaitForChild("Utils"):WaitForChild("Holster"))

local AmmoUpdateRemote = Remotes:WaitForChild(RemoteNames.RemoteEvents.AmmoUpdateRemote)

-- ============================================================================
-- WEAPON CONTROLLER
-- ============================================================================

local WeaponController = {}
WeaponController.__index = WeaponController

function WeaponController.new(player)
	local self = setmetatable({}, WeaponController)
	self.Player = player
	self.Raycast = Raycast.new()
	self.BodyAim = nil
	self.CurrentWeapon = nil
	self.CurrentConfig = nil
	self.IsReloading = false
	self.IsAiming = false
	self.IsFiring = false
	self.Ammo = {
		Loaded = {},
		Reserve = {},
	}
	self.Bullets = {}
	--self.HolsterWeapons['player']['weaponId] = createHolster(character)
	self.HolsterWeapons = {}

	-- On the server side, you should use Heartbeat instead of RenderStepped.
	-- Place this in a server script context (not in a LocalScript).

	RenderStepped:Connect(function(deltaTime)
		for _, bullet in pairs(self.Bullets) do
			bullet:update(deltaTime)
		end
	end)

	return self
end

-- ============================================================================
-- WEAPON MANAGEMENT
-- ============================================================================

function WeaponController:GenerateGUID(weapon: Tool)
	local weaponId = weapon:GetAttribute("WeaponUID")
	if not weaponId then
		weaponId = HttpService:GenerateGUID()
		weapon:SetAttribute("WeaponUID", weaponId)
	end

	return weaponId
end

function checkUUID(weapon: Tool)
	local weaponId = weapon:GetAttribute("WeaponUID")
	if not weaponId then
		weaponId = HttpService:GenerateGUID()
		weapon:SetAttribute("WeaponUID", weaponId)
	end

	return weaponId
end

function WeaponController:EquipWeapon(weapon: Tool)
	local weaponId = checkUUID(weapon)
	assert(weaponId, "Weapon has no WeaponUID")

	self.CurrentWeapon = weapon
	self.CurrentConfig = require(weapon:WaitForChild("XijumConfig"))

	-- HARD initialize (only once per weapon lifetime)
	if self.Ammo.Loaded[weaponId] == nil then
		self.Ammo.Loaded[weaponId] = self.CurrentConfig.MagazineSize
	end

	if self.Ammo.Reserve[weaponId] == nil then
		self.Ammo.Reserve[weaponId] = self.CurrentConfig.ReserveAmmo
	end

	-- PUSH ammo to client
	AmmoUpdateRemote:FireClient(self.Player, self.Ammo.Loaded[weaponId], self.Ammo.Reserve[weaponId])

	-- Check if weapon holster class has been created
	--[[
	if not self.HolsterWeapons[self.Player.UserId][weaponId] then
		self.HolsterWeapons[self.Player.UserId][weaponId] =
			Holster(self.Player.Character or self.Player.CharacterAdded:Wait()):registerWeapon()(weapon)
	end

	if self.HolsterWeapons[self.Player.UserId][weaponId] then
		self.HolsterWeapons[self.Player.UserId][weaponId]:unholster(weapon)
	end]]

	return true
end

function WeaponController:UnequipWeapon()
	--[[
	if self.HolsterWeapons[self.Player.UserId][self.CurrentWeapon] then
		self.HolsterWeapons[self.Player.UserId][self.CurrentWeapon]:holster(self.CurrentWeapon)
	end]]

	self.CurrentWeapon = nil
	self.CurrentConfig = nil
	self.IsAiming = false
	self.IsFiring = false
end
-- ============================================================================
-- FIRING & RELOAD
-- ============================================================================

--[[
	 fireData {
	 	origin,
		direction,
		weapon,
		timestap,
		firemode,
	 }
]]

function WeaponController:Fire(fireData)
	if not self.CurrentWeapon or self.IsReloading then
		return false
	end
	if (self.Ammo["Loaded"][checkUUID(self.CurrentWeapon)] or 0) <= 0 then
		return false
	end

	local ray = self.Raycast:PerformRaycast(fireData.origin, fireData.direction, { self.Player.Character })

	-- if hit result then check if hit was an enemy, apply damage, etc.
	if ray then
		warn("Hit: ", ray.Instance:GetFullName())

		local bullet = Bullet.new(fireData.origin, fireData.direction, {
			speed = 500,
			lifetime = 5,
			size = Vector3.new(0.2, 0.2, 1),
			color = Color3.new(1, 0, 0),
			material = Enum.Material.Neon,
			damage = self.CurrentConfig.Damage,
			canPierce = self.CurrentConfig.CanPierce,
			maxPierces = self.CurrentConfig.MaxPierces,
			player = self.Player,
		})

		table.insert(self.Bullets, bullet)
	end

	self.Ammo["Loaded"][checkUUID(self.CurrentWeapon)] -= 1
	AmmoUpdateRemote:FireClient(
		self.Player,
		self.Ammo.Loaded[checkUUID(self.CurrentWeapon)],
		self.Ammo.Reserve[checkUUID(self.CurrentWeapon)]
	)
	if fireData.weapon:FindFirstChild("Attachments"):FindFirstChild("EjectAttachment") then
		BulletCase.new(fireData.weapon:FindFirstChild("Attachments"):FindFirstChild("EjectAttachment")):eject()
	end
	return true
end

-- Helper function to duplciate mag and drop it to make it immersive
function WeaponController:DropMagazine(reloadTime)
	if not self.CurrentWeapon then
		return
	end

	local magOriginal = self.CurrentWeapon:FindFirstChild("Magazine")
	if not magOriginal then
		return
	end
	magOriginal.Transparency = 1

	local magazine = magOriginal:Clone()
	magazine.CFrame = magOriginal.CFrame
	magazine.CanCollide = true
	magazine.Transparency = 0
	magazine.Parent = workspace

	-- Add physics to the dropped magazine
	--local bodyVelocity = Instance.new("BodyVelocity")
	--bodyVelocity.Velocity = (magazine.CFrame.LookVector + Vector3.new(0, 1, 0)) * 10
	--bodyVelocity.MaxForce = Vector3.new(1000, 1000, 1000)
	--bodyVelocity.Parent = magazine

	task.wait(reloadTime)

	magOriginal.Transparency = 0

	-- Clean up after some time
	game.Debris:AddItem(magazine, 10)
end

function WeaponController:Reload(weaponId)
	if not self.CurrentWeapon or self.IsReloading then
		return false
	end

	local loadedAmmo = self.Ammo.Loaded[weaponId] or 0
	local reserveAmmo = self.Ammo.Reserve[weaponId] or 0
	local magSize = self.CurrentConfig.MagazineSize

	local neededAmmo = magSize - loadedAmmo
	if neededAmmo <= 0 or reserveAmmo <= 0 then
		return false
	end

	self:DropMagazine(self.CurrentConfig.ReloadTime)

	self.IsReloading = true
	task.wait(self.CurrentConfig.ReloadTime)

	local ammoToLoad = math.min(neededAmmo, reserveAmmo)
	self.Ammo.Loaded[weaponId] = loadedAmmo + ammoToLoad
	self.Ammo.Reserve[weaponId] = reserveAmmo - ammoToLoad
	AmmoUpdateRemote:FireClient(self.Player, self.Ammo.Loaded[weaponId], self.Ammo.Reserve[weaponId])
	self.IsReloading = false
	return true
end

function WeaponController:GetAmmo(weaponId)
	local loaded = self.Ammo.Loaded[weaponId]
	local reserve = self.Ammo.Reserve[weaponId]

	if loaded == nil or reserve == nil then
		return 0, 0
	end

	return loaded, reserve
end

-- ============================================================================
-- AIMING
-- ============================================================================

function WeaponController:SetAiming(state)
	self.IsAiming = state
	if state then
		-- Enable body aim when aiming
		if self.BodyAim then
			self.BodyAim:SetEnabled(true)
		end
	else
		-- Disable body aim when not aiming
		if self.BodyAim then
			self.BodyAim:SetEnabled(false)
		end
	end
end

function WeaponController:UpdateAimPitch(pitch)
	if self.BodyAim then
		self.BodyAim:UpdatePitch(pitch)
	end
end

-- ============================================================================
-- CHARACTER HANDLER
-- ============================================================================

function WeaponController:OnCharacterAdded(character: Model)
	-- Reinitialize BodyAim for the new character
	if self.BodyAim then
		self.BodyAim:Destroy()
		self.BodyAim = nil
	end

	self.BodyAim = BodyAim.new(character)
	self.BodyAim:Start()
end

function WeaponController:OnCharacterRemoving()
	if self.BodyAim then
		self.BodyAim:Destroy()
		self.BodyAim = nil
	end
end

return WeaponController
