local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

-- ============================================================================
-- SERVICES & INITIALIZATION
-- ============================================================================

local Xijum = ReplicatedStorage:WaitForChild("Xijum")
local WeaponSystem = Xijum:WaitForChild("WeaponSystem")

local RecoilModule = require(WeaponSystem:WaitForChild("Core"):WaitForChild("Recoil"))
local SpreadModule = require(WeaponSystem:WaitForChild("Core"):WaitForChild("Spread"))

-- ============================================================================
-- CLASS DEFINITION
-- ============================================================================

local Camera = {}
Camera.__index = Camera

function Camera.new(config)
	local self = setmetatable({}, Camera)

	self.config = config or {}
	self.Recoil = RecoilModule.new(self.config)
	self.Spread = SpreadModule.new(self.config)

	self.isActive = false
	self.cameraMode = "OTS" -- OTS | Orbital

	self.currentCamera = workspace.CurrentCamera
	self.player = Players.LocalPlayer

	-- Camera smoothing
	self.smoothSpeed = 0.15
	self.rotationSmooth = 0.15 -- 0.25
	self.mouseSensitivity = 1.2

	-- Camera state
	self.targetCFrame = CFrame.new()
	self.targetFOV = 70
	self.isAiming = false

	-- Settings

	self.distance = 12
	self.targetDistance = 12

	self.minDistance = 4
	self.maxDistance = 18
	self.zoomSpeed = 2.5

	-- Orbital rotation state
	self.yaw = 0
	self.pitch = 0
	self.targetYaw = 0
	self.targetPitch = 0

	self.otsYaw = 0
	self.otsPitch = 0

	self.mouseLocked = false
	self.isTransitioning = false
	self.transitionAlpha = 1
	self.transitionSpeed = 8

	-- Recoil tracking
	self.recoilOffset = Vector3.new(0, 0, 0)

	-- Input
	UserInputService.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseWheel then
			self.targetDistance -= input.Position.Z * self.zoomSpeed
			self.targetDistance = math.clamp(self.targetDistance, self.minDistance, self.maxDistance)
		end
	end)

	return self
end

-- ============================================================================
-- BASIC CONTROLS
-- ============================================================================

function Camera:SetConfig(config)
	self.config = config
	self.Recoil:SetConfig(config)
	self.Spread:SetConfig(config)
end

function Camera:Activate()
	self.isActive = true
	self.currentCamera.CameraType = Enum.CameraType.Scriptable
	self:SetMouseLocked(true)
	UserInputService.MouseIconEnabled = false
end

function Camera:Deactivate()
	self.isActive = false
	self:SetMouseLocked(false)
	self.currentCamera.CameraType = Enum.CameraType.Custom
	UserInputService.MouseIconEnabled = true
end

function Camera:SetMouseLocked(state)
	self.mouseLocked = state
	UserInputService.MouseBehavior = state and Enum.MouseBehavior.LockCenter or Enum.MouseBehavior.Default
end

function Camera:SyncOTSFromCamera(rootPart)
	local camCF = workspace.CurrentCamera.CFrame
	local look = camCF.LookVector

	-- Yaw from camera direction
	self.otsYaw = math.atan2(-look.X, -look.Z)

	-- Pitch from camera direction
	self.otsPitch = math.asin(look.Y)
	self.otsPitch = math.clamp(self.otsPitch, math.rad(-40), math.rad(40))

	-- Rotate character to face camera yaw (smooth lerp)
	rootPart.CFrame = rootPart.CFrame:Lerp(CFrame.new(rootPart.Position) * CFrame.Angles(0, self.otsYaw, 0), 0.2)
end

function Camera:ToggleMode(mode)
	self.targetYaw = self.yaw
	self.targetPitch = self.pitch
	self.otsYaw = self.yaw
	self.otsPitch = self.pitch

	self.cameraMode = mode or (self.cameraMode == "OTS" and "Orbital" or "OTS")
	self:SetMouseLocked(true)

	self.isTransitioning = true
	self.transitionAlpha = 0

	if self.cameraMode == "OTS" then
		-- Lock the mouse so camera can rotate
		self:SetMouseLocked(true)
		UserInputService.MouseIconEnabled = true

		-- Sync initial yaw/pitch from character
		local character = self.player.Character
		if character then
			local rootPart = character:FindFirstChild("HumanoidRootPart")
			if rootPart then
				self:SyncOTSFromCamera(rootPart)
			end
		end
	else
		-- Orbital mode behavior
		self:SetMouseLocked(true)
		UserInputService.MouseIconEnabled = false

		-- Enable autorotate
		local character = self.player.Character
		if character then
			local humanoid = character:FindFirstChildOfClass("Humanoid")
			if humanoid then
				humanoid.AutoRotate = true
			end
		end
	end
end

-- ============================================================================
-- UPDATE LOOP
-- ============================================================================

function Camera:UpdateCamera(dt)
	if not self.isActive then
		return
	end

	local character = self.player.Character
	if not character then
		return
	end

	local rootPart = character:FindFirstChild("HumanoidRootPart")
	if not rootPart then
		return
	end

	if self.cameraMode == "OTS" then
		self:UpdateOTSCamera(rootPart)
	else
		self:UpdateOrbitalCamera(rootPart)
	end

	self.Recoil:UpdateRecoil(dt)
	self:ApplyRecoilToCamera()
	self:SmoothCamera(dt)
end

-- ============================================================================
-- OTS CAMERA
-- ============================================================================

function Camera:UpdateOTSCamera(rootPart)
	local delta = UserInputService:GetMouseDelta()
	local sensitivity = self.isAiming and 0.0025 or 0.0015

	-- Camera rotation
	self.otsYaw -= delta.X * sensitivity
	self.otsPitch -= delta.Y * sensitivity
	self.otsPitch = math.clamp(self.otsPitch, math.rad(-40), math.rad(40))

	local otsOffset = self.config.Camera.OTS_Offset or Vector3.new(1.8, 1.2, -3)

	local humanoid = rootPart.Parent:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.AutoRotate = false
	end

	-- Camera pivot
	local pivot = CFrame.new(rootPart.Position) * CFrame.new(0, 1.2, 0)

	-- Camera CFrame
	local cameraCFrame = pivot
		* CFrame.Angles(0, self.otsYaw, 0)
		* CFrame.Angles(self.otsPitch, 0, 0)
		* CFrame.new(otsOffset)

	self.targetCFrame = cameraCFrame

	-- Rotate character to face camera yaw
	--rootPart.CFrame = CFrame.new(rootPart.Position) * CFrame.Angles(0, self.otsYaw, 0)
	rootPart.CFrame = rootPart.CFrame:Lerp(CFrame.new(rootPart.Position) * CFrame.Angles(0, self.otsYaw, 0), 0.2)

	-- FOV
	self.targetFOV = self.isAiming and (self.config.Camera and self.config.Camera.ADS_FOV or 65) or 70
end

-- ============================================================================
-- ORBITAL CAMERA
-- ============================================================================

function Camera:UpdateOrbitalCamera(rootPart)
	local delta = UserInputService:GetMouseDelta()
	local sensitivity = self.mouseSensitivity

	-- Accumulate TARGET rotation (raw input)
	self.targetYaw -= delta.X * sensitivity * 0.0025
	self.targetPitch += delta.Y * sensitivity * 0.0025

	-- Clamp target pitch
	self.targetPitch = math.clamp(self.targetPitch, math.rad(-65), math.rad(75))

	-- Smooth actual rotation toward target
	self.yaw += (self.targetYaw - self.yaw) * self.rotationSmooth
	self.pitch += (self.targetPitch - self.pitch) * self.rotationSmooth

	-- Camera settings
	self.distance += (self.targetDistance - self.distance) * 0.25
	local distance = self.distance
	local heightOffset = 1.5

	local focusPoint = rootPart.Position + Vector3.new(0, heightOffset, 0)

	-- Rotation
	local rotation = CFrame.Angles(0, self.yaw, 0) * CFrame.Angles(self.pitch, 0, 0)

	-- Offset behind character
	local offset = rotation:VectorToWorldSpace(Vector3.new(0, 0, -distance))
	local cameraPos = focusPoint + offset

	self.targetCFrame = CFrame.lookAt(cameraPos, focusPoint)
	self.targetFOV = self.isAiming and 55 or 70
end

-- ============================================================================
-- SMOOTHING
-- ============================================================================

function Camera:SmoothCamera(dt)
	if self.isTransitioning then
		self.currentCamera.CFrame = self.currentCamera.CFrame:Lerp(
			self.targetCFrame * CFrame.new(self.recoilOffset),
			1 - math.exp(-self.transitionSpeed * dt)
		)

		-- Stop transitioning when close enough
		if (self.currentCamera.CFrame.Position - self.targetCFrame.Position).Magnitude < 0.05 then
			self.isTransitioning = false
		end
	elseif self.cameraMode == "Orbital" then
		self.currentCamera.CFrame = self.targetCFrame * CFrame.new(self.recoilOffset)
	else
		self.currentCamera.CFrame =
			self.currentCamera.CFrame:Lerp(self.targetCFrame * CFrame.new(self.recoilOffset), self.smoothSpeed)
	end

	-- FOV smoothing
	self.currentCamera.FieldOfView += (self.targetFOV - self.currentCamera.FieldOfView) * self.smoothSpeed
end

-- ============================================================================
-- RECOIL
-- ============================================================================

function Camera:ApplyRecoilFromShot()
	self.Recoil:ApplyRecoil()
	self:ApplyRecoilToCamera()
end

function Camera:ApplyRecoilToCamera()
	local recoil = self.Recoil:GetCurrentRecoil()
	local spread = self.Spread:GetCurrentSpread(self.isAiming, false)

	-- Apply recoil as position offset
	self.recoilOffset = Vector3.new(recoil.X * 0.15, -recoil.Y * 0.2, 0)
end

-- ============================================================================
-- DIED
-- ============================================================================

function Camera:PlayerDied()
	self.isActive = false

	local cam = workspace.CurrentCamera
	cam.CameraType = Enum.CameraType.Custom
	cam.CameraSubject = nil
	cam.FieldOfView = 70

	UserInputService.MouseBehavior = Enum.MouseBehavior.Default
	UserInputService.MouseIconEnabled = true
	self.player:GetMouse().Icon = ""
end

return Camera
