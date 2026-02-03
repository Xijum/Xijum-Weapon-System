-- DamageService Framework
-- This handles everything related to Damage Application which goes from simply Humanoid damage to being compatible with other Xijum Systems

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Xijum = ReplicatedStorage:WaitForChild("Xijum")

local DamageService = {}
local XijumSystems = {}

-- Registers systems that are found within the game related to Xijum and add them
-- System compatible with XijumWeapon
-- XijumHealth

for _, v in pairs(Xijum:GetChildren()) do
	if v:IsA("Folder") and v.Name ~= "WeaponSystem" then
		local systemModule = require(v)
		if systemModule and systemModule.IsXijumSystem then
			XijumSystems[v.Name] = systemModule
		end
	end
end

-- Default function for simple Humanoid, aka only XWS is in game and nothing else

local function HumanoidDamage(data, damage) -- data should be in the form of the character data
	local character = data.character:FindFirstAncestorOfClass("Model")
	if character then
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if humanoid and humanoid.Health > 0 then
			humanoid:TakeDamage(damage)
			return true
		end
	end
	return false
end

-- Advanced damage application if other systems are found

function DamageService.ApplyDamage(data, damage)
	for _systemName, systemModule in pairs(XijumSystems) do
		if systemModule.ApplyDamage then
			local success = systemModule.ApplyDamage(data, damage)
			if success then
				return true
			end
		end
	end
	-- Fallback to Humanoid damage if no other system handled it
	return HumanoidDamage(data, damage)
end

return DamageService
