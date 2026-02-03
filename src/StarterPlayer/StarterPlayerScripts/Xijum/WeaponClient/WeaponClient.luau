local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

-- ============================================================================
-- SERVICES & INITIALIZATION
-- ============================================================================

local player = Players.LocalPlayer
local mouse = player:GetMouse()

local Xijum = ReplicatedStorage:WaitForChild("Xijum")
local WeaponSystem = Xijum:WaitForChild("WeaponSystem")

local Camera = require(WeaponSystem:WaitForChild("Core"):WaitForChild("Camera"))
local AnimationHandler = require(script.Parent.AnimationHandler)
local RemoteNames = require(WeaponSystem:WaitForChild("RemotesDefinitions"))
local Remotes = WeaponSystem:WaitForChild("Remotes")

local EquipRemote = Remotes:WaitForChild(RemoteNames.RemoteEvents.Equip)
local FireRemote = Remotes:WaitForChild(RemoteNames.RemoteEvents.Fire)
local ReloadRemote = Remotes:WaitForChild(RemoteNames.RemoteEvents.Reload)
local AimRemote = Remotes:WaitForChild(RemoteNames.RemoteEvents.Aim)
local UnequipRemote = Remotes:WaitForChild(RemoteNames.RemoteEvents.Unequip)
local SoundRemote = Remotes:WaitForChild(RemoteNames.RemoteEvents.Sound)

local GetAmmoFunction = Remotes:WaitForChild(RemoteNames.RemoteFunctions.GetAmmo)

-- ============================================================================
-- CLASS DEFINITION
-- ============================================================================

local WeaponClient = {}
WeaponClient.__index = WeaponClient

function WeaponClient.new()
	local self = setmetatable({}, WeaponClient)
	self.CurrentWeapon = nil
	self.LastShot = 0
	self.InputBound = false
	self.IsAiming = false

	self.AnimationHandler = AnimationHandler.new()
	self.Camera = Camera.new()
	self:AttachCamera()

	return self
end

-- ============================================================================
-- WEAPON MANAGEMENT
-- ============================================================================

function WeaponClient:EquipWeapon(weapon: Tool)
	-- Each player can have multiple instances of the way window but only be able to equip one at the
	--same time so each gun must have a UUID even fi they are the same type as "AssaultRifle",
	--the server handles this by setting an attribute wit hthe UUID,
	--we use this to distinguisg the different weapons the player has
	-- and with this we know the stats and config of each weapon even if they are the same class/type

	self.Config = require(weapon:WaitForChild("XijumConfig"))
	self.AnimationHandler:Initialize(self.Config)
	self.AnimationHandler:LoadAnimations(weapon.Parent)
	self.Camera:SetConfig(self.Config)
	self.Camera:Activate()
	self.Camera:ToggleMode("Orbital")
	self.CurrentWeapon = weapon
	EquipRemote:FireServer(self.CurrentWeapon)

	self:PlayAnimation("Equip")
	self:PlayAnimation("Idle")
	self:PlaySound("Local", "Equip")
end

function WeaponClient:UnequipWeapon()
	if not self.CurrentWeapon then
		return
	end

	self.AnimationHandler:StopAllAnimations()
	self:PlayAnimation("Unequip")
	self:PlaySound("Local", "Unequip")
	self:ToggleAiming(false) -- Ensure aiming is disabled

	-- Get animation length from config, default to 0.5s
	local unequipDuration = 0.5
	if self.Config and self.Config.Animations and self.Config.Animations.Unequip then
		-- Assume animation duration is stored in config, or use default
		unequipDuration = self.Config.AnimationSpeeds and self.Config.AnimationSpeeds.Unequip or 0.5
	end

	task.wait(unequipDuration)

	UnequipRemote:FireServer(self.CurrentWeapon:GetAttribute("WeaponUID"))
	self.Camera:Deactivate()

	self.CurrentWeapon = nil
	self.Config = nil
	self.IsFiring = false
end

function WeaponClient:GetCurrentWeapon()
	return self.CurrentWeapon
end

function WeaponClient:GetConfig()
	return self.Config
end

-- ============================================================================
-- AIMING & FIRING STATE
-- ============================================================================

function WeaponClient:SetFiring(state)
	self.IsFiring = state
end

function WeaponClient:IsFiring()
	return self.IsFiring
end

function WeaponClient:ToggleAiming(isAiming)
	if not self.CurrentWeapon then
		return
	end
	self.IsAiming = isAiming
	if isAiming then
		self:PlayAnimation("Aim")
		self:ActivateCamera()
	else
		self:StopAnimation("Aim")
		self:DeactivateCamera()
	end
	AimRemote:FireServer(isAiming)

	self:PlaySound("Local", "Aim")
end

function WeaponClient:ActivateCamera()
	if self.Camera then
		self.Camera:Activate()
		self.Camera:ToggleMode("OTS")
	end
end

function WeaponClient:DeactivateCamera()
	if self.Camera then
		self.Camera:ToggleMode("Orbital")
	end
end

function WeaponClient:AttachCamera()
	RunService.RenderStepped:Connect(function(dt)
		local currentSelf = self
		if currentSelf.Camera and currentSelf.Camera.isActive then
			currentSelf.Camera:UpdateCamera(dt)
		end
	end)
end

-- ============================================================================
-- RELOAD LOGIC
-- ============================================================================

function WeaponClient:Reload()
	if not self.CurrentWeapon or not self.Config then
		return
	end

	self:PlayAnimation("Reload")
	self:PlaySound("Server", "Reload")

	self.IsReloading = true
	ReloadRemote:FireServer(self.CurrentWeapon:GetAttribute("WeaponUID"))

	task.wait(self.Config.ReloadTime)
	self.IsReloading = false
end

function WeaponClient:GetReloadingState()
	return self.IsReloading or false
end

function WeaponClient:SetReloading(state)
	self.IsReloading = state
end

-- ============================================================================
-- FIRING LOGIC
-- ============================================================================

function WeaponClient:CanFire()
	if not self.Config then
		return false
	end
	if not self.IsAiming then
		return false
	end
	if self:GetReloadingState() then
		return false
	end
	local ammo, reserve = GetAmmoFunction:InvokeServer(self.CurrentWeapon:GetAttribute("WeaponUID"))
	if ammo <= 0 then
		return false
	end
	-- Fire rate check
	local rpm = self.Config.FireRate
	local delay = 60 / rpm
	return (tick() - self.LastShot) >= delay
end

function WeaponClient:Fire()
	if not self:CanFire() then
		return
	end
	self.LastShot = tick()
	local origin = workspace.CurrentCamera.CFrame.Position
	local baseDirection = workspace.CurrentCamera.CFrame.LookVector

	-- Apply spread
	local spreadValue = self.Camera.Spread:GetCurrentSpread(self.IsAiming, false)
	local spreadAngle = math.rad(spreadValue)

	-- Random deviation within spread cone
	local randomYaw = (math.random() - 0.5) * 2 * spreadAngle
	local randomPitch = (math.random() - 0.5) * 2 * spreadAngle

	-- Create spread rotation and apply to base direction
	local spreadRotation = CFrame.Angles(randomPitch, randomYaw, 0)
	local spreadCFrame = CFrame.new(Vector3.new(0, 0, 0), baseDirection)
	local finalCFrame = spreadCFrame * spreadRotation
	local direction = finalCFrame.LookVector * self.Config.Range

	FireRemote:FireServer({
		origin = origin,
		direction = direction,
		weapon = self.CurrentWeapon,
		timestamp = tick(),
		firemode = self.Config.FireMode[1],
	})

	self:PlayAnimation("Fire")
	self:PlaySound("Server", "Fire")

	-- Here we also handle recoil
	self.Camera:ApplyRecoilFromShot()
end

-- ============================================================================
-- Misc Logic
-- ============================================================================

function WeaponClient:ToggleFireMode()
	if not self.CurrentWeapon or not self.Config or self:IsAiming() then
		return
	end
	-- Check if config allows for fire mode toggling
	if not self.Config.FireMode or #self.Config.FireMode < 2 then
		return
	end

	self:PlayAnimation("Firemode")

	local currentMode = self.Config.FireMode[1]
	local modes = self.Config.FireMode
	local currentIndex = table.find(modes, currentMode)
	local nextIndex = currentIndex % #modes + 1
	self.Config.FireMode[1] = modes[nextIndex]
end

function WeaponClient:PlayAnimation(animationType: string, speed: number?)
	if not self.CurrentWeapon or not self.Config or not self.Config.Animations then
		return
	end

	local animationId = self.Config.Animations[animationType]
	if animationId and animationId ~= "" then
		self.AnimationHandler:PlayAnimation(animationType, speed)
	end
end

function WeaponClient:StopAnimation(animationType: string)
	if not self.CurrentWeapon or not self.Config or not self.Config.Animations then
		return
	end

	local animationId = self.Config.Animations[animationType]
	if animationId and animationId ~= "" then
		self.AnimationHandler:StopAnimation(animationType)
	end
end

function playLocalSound(soundId: string)
	local sound = Instance.new("Sound")
	sound.SoundId = soundId
	sound.Parent = workspace.CurrentCamera
	sound:Play()
	sound.Ended:Connect(function()
		sound:Destroy()
	end)
end

function WeaponClient:PlaySound(soundType: string, soundName: string)
	if not self.CurrentWeapon or not self.Config or not self.Config.Sounds then
		return
	end

	local soundId = self.Config.Sounds[soundName]
	if soundId and soundId ~= "" then
		if soundType == "Local" then
			playLocalSound(soundId)
		elseif soundType == "Server" then
			SoundRemote:FireServer(soundId)
		end
	end
end

-- ============================================================================
-- INPUT BINDING
-- ============================================================================

function WeaponClient:BindInput()
	if self.InputBound then
		return
	end
	self.InputBound = true

	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed or not self.CurrentWeapon then
			return
		end
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			print("Firing")
			self.IsFiring = true
			while self.IsFiring do
				self:Fire()
				if self.Config.FireMode[1] ~= "Auto" then
					break
				end
				RunService.Heartbeat:Wait()
			end
		elseif input.KeyCode == Enum.KeyCode.R then
			self:Reload()
		elseif input.UserInputType == Enum.UserInputType.MouseButton2 then
			self:ToggleAiming(true)
		end
	end)

	UserInputService.InputEnded:Connect(function(input, gameProcessed)
		if gameProcessed then
			return
		end
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			self.IsFiring = false
		elseif input.UserInputType == Enum.UserInputType.MouseButton2 then
			self:ToggleAiming(false)
		end
	end)

	-- Tool equip/unequip detection for XijumWeapon
	player.CharacterAdded:Connect(function(character)
		local connectedTools = {}

		local function onToolEquipped(tool)
			if tool:IsA("Tool") and tool:FindFirstChild("XijumWeapon").Value then
				self:EquipWeapon(tool)
			end
		end

		local function onToolUnequipped(tool)
			if tool:IsA("Tool") and tool:FindFirstChild("XijumWeapon").Value then
				self:UnequipWeapon()
			end
		end

		character.ChildAdded:Connect(function(child)
			if child:IsA("Tool") and child:FindFirstChild("XijumWeapon").Value then
				if not connectedTools[child] then
					connectedTools[child] = true
					child.Equipped:Connect(function()
						onToolEquipped(child)
					end)
					child.Unequipped:Connect(function()
						onToolUnequipped(child)
					end)
				end
			end
		end)
	end)
end

function WeaponClient:OnCharacterDied()
	self:UnequipWeapon()
	self.CurrentWeapon = nil
	self.Config = nil
	self.IsFiring = false
	self.IsReloading = false
end

return WeaponClient
