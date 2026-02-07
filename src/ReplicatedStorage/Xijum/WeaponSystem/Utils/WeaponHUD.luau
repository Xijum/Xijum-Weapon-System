local TweenService = game:GetService("TweenService")

local WeaponHUD = {}
WeaponHUD.__index = WeaponHUD

--// Constructor
function WeaponHUD.new(hudFrame: Frame, hudHit: Frame)
	assert(hudFrame:IsA("Frame"), "hudFrame must be a Frame instance")
	assert(hudHit:IsA("Frame"), "hudHit must be a Frame instance")
	assert(hudFrame:FindFirstChild("WeaponName"), "hudFrame must contain a 'WeaponName' TextLabel")
	assert(hudFrame:FindFirstChild("WeaponFiremode"), "hudFrame must contain a 'WeaponFiremode' TextLabel")
	assert(hudFrame:FindFirstChild("WeaponAmmo"), "hudFrame must contain a 'WeaponAmmo' TextLabel")

	local self = setmetatable({}, WeaponHUD)

	self.hud = hudFrame
	self.hudHit = hudHit
	self.gunNameLabel = hudFrame:FindFirstChild("WeaponName")
	self.fireModeLabel = hudFrame:FindFirstChild("WeaponFiremode")

	self.player = game:GetService("Players").LocalPlayer

	-- Main ammo label
	self.ammoLabel = hudFrame:FindFirstChild("WeaponAmmo")
	self.ammoLabel.TextTransparency = 0

	-- Tween settings
	self.fastTween = TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	self.slowTween = TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	self.fadeTween = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

	-- Store positions for enable/disable animation
	self.originalPosition = hudFrame.Position
	self.hiddenPosition = hudFrame.Position + UDim2.fromOffset(0, 20)
	hudFrame.Position = self.hiddenPosition
	hudFrame.BackgroundTransparency = 1
	hudFrame.Visible = false

	-- Ammo state
	self.reserveAmmo = 0

	return self
end

--// Internal helper: Tween text transparency
local function tweenText(label: TextLabel, text: string)
	label.TextTransparency = 1
	label.Text = text
	TweenService:Create(label, TweenInfo.new(0.15), { TextTransparency = 0 }):Play()
end

--// Setters
function WeaponHUD:setGunName(name: string)
	tweenText(self.gunNameLabel, name)
end

function WeaponHUD:setFireMode(fireMode: string)
	tweenText(self.fireModeLabel, fireMode)
end

function WeaponHUD:setAmmo(current: number, reserve: number, override: string?)
	if override then
		self.ammoLabel.Text = override
		return
	end

	self.reserveAmmo = reserve
	local newText = string.format("%d / %d", current, reserve)
	self.ammoLabel.Text = newText
end

--// Bulk update
function WeaponHUD:update(gunName: string, fireMode: string, currentAmmo: number, reserveAmmo: number)
	self:setGunName(gunName)
	self:setFireMode(fireMode)
	self:setAmmo(currentAmmo, reserveAmmo)
end

--// Enable/disable HUD with animation
function WeaponHUD:setEnabled(enabled: boolean)
	if enabled then
		self.hud.Visible = true
		TweenService:Create(self.hud, self.slowTween, {
			Position = self.originalPosition,
			BackgroundTransparency = 0,
		}):Play()
	else
		local tween = TweenService:Create(self.hud, self.slowTween, {
			Position = self.hiddenPosition,
			BackgroundTransparency = 1,
		})
		tween:Play()
		tween.Completed:Once(function()
			self.hud.Visible = false
		end)
	end
end

--// Show hitmarker effect
function WeaponHUD:showHitmarker(hit: boolean)
	local hitmarker = self.hudHit:FindFirstChild("Hitmarker")
	if not hitmarker then
		return
	end
	task.spawn(function()
		hitmarker.Visible = true
		hitmarker.ImageTransparency = 0

		local tween = TweenService:Create(hitmarker, self.fadeTween, {
			ImageTransparency = 1,
		})
		tween:Play()
		tween.Completed:Once(function()
			hitmarker.Visible = false
		end)
	end)
end

-- Crosshair stuff

function WeaponHUD:setCrosshairVisible(visible: boolean)
	local crosshair = self.hudHit:FindFirstChild("Crosshair")
	if not crosshair then
		return
	end

	local mouse = self.player:GetMouse()
	local offsetX = crosshair.AbsoluteSize.X / 2
	local offsetY = crosshair.AbsoluteSize.Y / 2
	self.hudHit.Position = UDim2.fromOffset(mouse.X - offsetX, mouse.Y - offsetY)

	local tween = TweenService:Create(crosshair, self.fadeTween, {
		ImageTransparency = visible and 0 or 1,
	})
	tween:Play()
end

--// Change crosshair color if aiming an active target
function WeaponHUD:setCrosshairActive(active: boolean)
	local crosshair = self.hudHit:FindFirstChild("Crosshair")
	if not crosshair then
		return
	end

	local tween = TweenService:Create(crosshair, self.fastTween, {
		ImageColor3 = active and Color3.new(1, 0, 0) or Color3.new(1, 1, 1),
	})
	tween:Play()
end

return WeaponHUD
