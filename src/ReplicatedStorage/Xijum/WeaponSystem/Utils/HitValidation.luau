-- HitValidation Framework
-- This handles everything related to Hit Validation which goes from simply HUmanoid deteciton to being compatible with other Xijum Systems

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Xijum = ReplicatedStorage:WaitForChild("Xijum")

local HitValidation = {}
local XijumSystems = {}

-- Registers system that are found witihng the game related to Xijum and add them
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

-- Default functions for simple Humanoid, aka only XWS is in game and nothing else

local function HumanoidDetection(hitPart)
	local character = hitPart:FindFirstAncestorOfClass("Model")
	if character then
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if humanoid and humanoid.Health > 0 then
			return true, { character = character }
		end
	end
	return false, nil
end

-- Advance hit validation if other system are found

function HitValidation.HitValidationDetection(hitPart)
	for _systemName, systemModule in pairs(XijumSystems) do
		if systemModule.HitValidationDetection then
			local isValid, character = systemModule.HitValidationDetection(hitPart)
			if isValid then
				return true, character
			end
		end
	end
	-- Fallback to Humanoid detection if no other system validated the hit
	return HumanoidDetection(hitPart)
end

-- Main function used by other modules for hit validation

return HitValidation
