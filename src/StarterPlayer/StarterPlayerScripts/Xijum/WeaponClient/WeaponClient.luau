local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

-- ============================================================================
-- SERVICES & INITIALIZATION
-- ============================================================================

local player = Players.LocalPlayer

local Xijum = ReplicatedStorage:WaitForChild("Xijum")
local WeaponSystem = Xijum:WaitForChild("WeaponSystem")

local Camera = require(WeaponSystem:WaitForChild("Core"):WaitForChild("Camera"))
local AnimationHandler = require(script.Parent.AnimationHandler)
local RemoteNames = require(WeaponSystem:WaitForChild("RemotesDefinitions"))
local Remotes = WeaponSystem:WaitForChild("Remotes")

local WeaponHUD = require(WeaponSystem:WaitForChild("Utils"):WaitForChild("WeaponHUD"))
local HitValidation = require(WeaponSystem:WaitForChild("Utils"):WaitForChild("HitValidation"))
local Raycast = require(WeaponSystem:WaitForChild("Utils"):WaitForChild("Raycast"))

local EquipRemote = Remotes:WaitForChild(RemoteNames.RemoteEvents.Equip)
local FireRemote = Remotes:WaitForChild(RemoteNames.RemoteEvents.Fire)
local ReloadRemote = Remotes:WaitForChild(RemoteNames.RemoteEvents.Reload)
local AimRemote = Remotes:WaitForChild(RemoteNames.RemoteEvents.Aim)
local UnequipRemote = Remotes:WaitForChild(RemoteNames.RemoteEvents.Unequip)
local SoundRemote = Remotes:WaitForChild(RemoteNames.RemoteEvents.Sound)
local AimUpdateRemote = Remotes:WaitForChild(RemoteNames.RemoteEvents.AimUpdate)

local GetAmmoFunction = Remotes:WaitForChild(RemoteNames.RemoteFunctions.GetAmmo)
local GenerateGUIDFunction = Remotes:WaitForChild(RemoteNames.RemoteFunctions.GenerateGUID)

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

	self.WeaponHUD = nil
	self.AnimationHandler = AnimationHandler.new()
	self.Camera = Camera.new()
	self.Ray = Raycast.new()
	self:AttachCamera()

	-- self.Firemode['UID'] = "Auto"
	self.Firemode = {}

	return self
end

function WeaponClient:InitHUD()
	local playerGui = player:WaitForChild("PlayerGui")

	local hudGui = playerGui:WaitForChild("XijumHUD")
	local weaponHudFrame = hudGui:WaitForChild("WeaponHUD")
	local hitmarkerContainer = hudGui:WaitForChild("HitmarkerContainer")

	self.WeaponHUD = WeaponHUD.new(weaponHudFrame, hitmarkerContainer)
end

function WeaponClient:GetWeaponUID()
	if not self.CurrentWeaponUID then
		error("WeaponUID accessed before being set")
	end
	return self.CurrentWeaponUID
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

	local uid = weapon:GetAttribute("WeaponUID")
	if not uid then
		warn("Weapon equipped without WeaponUID:", weapon.Name)
		return
	end

	self.CurrentWeaponUID = uid

	self.Firemode[uid] = self.Firemode[uid] or self.Config.FireMode[1]

	local currentAmmo, reserveAmmo = GetAmmoFunction:InvokeServer(self.CurrentWeaponUID)
	self.WeaponHUD:update(
		self.Config.Name,
		self.Firemode[self.CurrentWeaponUID] or self.Config.FireMode[1],
		currentAmmo,
		reserveAmmo
	)
	self.WeaponHUD:setEnabled(true)

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

	self.Camera:Deactivate()

	self.CurrentWeapon = nil
	self.Config = nil
	self.IsFiring = false
	self.WeaponHUD:setEnabled(false)

	-- Get animation length from config, default to 0.5s
	local unequipDuration = 0.5
	if self.Config and self.Config.Animations and self.Config.Animations.Unequip then
		-- Assume animation duration is stored in config, or use default
		unequipDuration = self.Config.AnimationSpeeds and self.Config.AnimationSpeeds.Unequip or 0.5
	end

	task.wait(unequipDuration)
	UnequipRemote:FireServer(self.CurrentWeaponUID)
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
	if not self.CurrentWeapon or self.IsReloading then
		return
	end
	self.IsAiming = isAiming
	self.WeaponHUD:setCrosshairVisible(isAiming)
	if isAiming then
		self:PlayAnimation("Aim")
		self:ActivateCamera()
	else
		self:StopAnimation("Aim")
		self:DeactivateCamera()
	end
	AimRemote:FireServer(isAiming)

	self:PlaySound("Local", "Aim")

	if isAiming then
		self._CrosshairConnection = RunService.Heartbeat:Connect(function()
			if self.WeaponHUD then
				local origin = workspace.CurrentCamera.CFrame.Position
				local direction = workspace.CurrentCamera.CFrame.LookVector

				local rayResult = workspace:Raycast(origin, direction)
				--print(rayResult)
				if rayResult and rayResult.Instance then
					local isValid, _ = HitValidation.HitValidationDetection(rayResult.Instance)
					self.WeaponHUD:setCrosshairActive(isValid)
				else
					self.WeaponHUD:setCrosshairActive(false)
				end
				--local isValid, _ = HitValidation.HitValidationDetection(hitPart.Instance)
				--self.WeaponHUD:setCrosshairActive(isValid)
			end
		end)
	else
		if self._CrosshairConnection then
			self._CrosshairConnection:Disconnect()
			self._CrosshairConnection = nil
		end
	end
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
	-- Disconnect the previous connection if it exists
	if self.CameraConnection then
		self.CameraConnection:Disconnect()
		self.CameraConnection = nil
	end

	-- Set up the new connection to RenderStepped
	self.CameraConnection = RunService.RenderStepped:Connect(function(dt)
		local currentSelf = self
		if currentSelf.Camera and currentSelf.Camera.isActive then
			currentSelf.Camera:UpdateCamera(dt)
		end

		if self.IsAiming then
			local lookY = workspace.CurrentCamera.CFrame.LookVector.Y
			local pitch = math.asin(lookY)

			AimUpdateRemote:FireServer(pitch)
		end
	end)
end

-- ============================================================================
-- RELOAD LOGIC
-- ============================================================================

function WeaponClient:Reload()
	if not self.CurrentWeapon or not self.Config or self.IsReloading or self.IsAiming then
		return
	end

	self:PlayAnimation("Reload")
	self:PlaySound("Server", "Reload")

	self.WeaponHUD:setAmmo(nil, nil, "Reloading...")

	self.IsReloading = true
	ReloadRemote:FireServer(self.CurrentWeaponUID)

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
	local ammo, _ = GetAmmoFunction:InvokeServer(self.CurrentWeaponUID)
	if ammo <= 0 then
		self:PlaySound("Local", "EmptyClick")
		warn("a")
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
	if not self.CurrentWeapon or not self.Config then
		return
	end
	-- Check if config allows for fire mode toggling
	if not self.Config.FireMode or #self.Config.FireMode < 2 then
		return
	end

	self:PlayAnimation("Firemode")

	local currentMode = self.Firemode[self.CurrentWeaponUID] or self.Config.FireMode[1]
	local modes = self.Config.FireMode
	local currentIndex = table.find(modes, currentMode)
	local nextIndex = currentIndex % #modes + 1
	self.Firemode[self.CurrentWeaponUID] = modes[nextIndex]
	self.WeaponHUD:setFireMode(self.Firemode[self.CurrentWeaponUID])
	self:PlaySound("Local", "Firemode")
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
	if self.Camera then
		self:AttachCamera()
	end

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
				if self.Firemode[self.CurrentWeaponUID] ~= "Auto" then
					break
				end
				RunService.Heartbeat:Wait()
			end
		elseif input.KeyCode == Enum.KeyCode.R then
			self:Reload()
		elseif input.KeyCode == Enum.KeyCode.V then
			self:ToggleFireMode()
		elseif input.KeyCode == Enum.KeyCode.T then
			self.Camera:ToggleOTSSide()
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
				if self.CurrentWeapon and self.CurrentWeapon ~= tool then
					self:UnequipWeapon()
				end
				self:EquipWeapon(tool)
			end
		end

		local function onToolUnequipped(tool)
			if tool:IsA("Tool") and tool:FindFirstChild("XijumWeapon").Value then
				if self.CurrentWeapon == tool then
					self:UnequipWeapon()
				end
			end
		end

		character.ChildAdded:Connect(function(child)
			if child:IsA("Tool") and child:FindFirstChild("XijumWeapon").Value then
				if not connectedTools[child] then
					connectedTools[child] = true

					-- check if gun has UID if not request server to create one
					local uid = child:GetAttribute("WeaponUID")
					if not uid then
						uid = GenerateGUIDFunction:InvokeServer(child)
					end

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

function WeaponClient:HitmarkerFeedback(hit: boolean)
	if self.WeaponHUD then
		self.WeaponHUD:showHitmarker(hit)
	end

	self:PlaySound("Local", "Hitmarker")
end

function WeaponClient:OnCharacterDied()
	if self.Camera then
		self.Camera:PlayerDied()
	end

	if self.CameraConnection then
		self.CameraConnection:Disconnect()
		self.CameraConnection = nil
	end

	self.CurrentWeapon = nil
	self.Config = nil
	self.IsFiring = false
	self.IsReloading = false
	self.IsAiming = false
end

return WeaponClient
