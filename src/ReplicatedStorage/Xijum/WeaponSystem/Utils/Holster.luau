local function createHolster(character: Model)
	local self = {} -- this will be the holster object
	self.weapons = {} -- table to track holstered weapons

	local weaponsFolder = character:FindFirstChild("HolsterWeapons") or Instance.new("Folder")
	weaponsFolder.Name = "HolsterWeapons"
	weaponsFolder.Parent = character
	self.weaponsFolder = weaponsFolder

	-- Register / holster a weapon
	function self:registerWeapon(weapon, position: Vector3, orientation: Vector3, targetName: string?)
		-- Prevent double holstering
		if character:FindFirstChild(weapon.Name .. "_Holster") then
			return
		end

		-- Clone and clean weapon
		local toolClone = weapon:Clone()
		if toolClone:FindFirstChild("WeaponConfiguration") then
			toolClone.WeaponConfiguration:Destroy()
		end

		-- Move children into a new model
		local toolModel = Instance.new("Model")
		toolModel.Name = weapon.Name .. "_Holster"
		for _, v in pairs(toolClone:GetChildren()) do
			v.Parent = toolModel
		end
		toolClone:Destroy()

		toolModel.Parent = self.weaponsFolder

		-- Weld to character
		local weld = Instance.new("Weld")
		weld.Name = "WeldHolster"
		local targetPart = targetName and character:FindFirstChild(targetName) or character:FindFirstChild("UpperTorso")
		weld.Part0 = targetPart
		weld.Part1 = toolModel:FindFirstChild("Handle")
		weld.C0 = CFrame.new(table.unpack(position))
			* CFrame.fromOrientation(math.rad(orientation[1]), math.rad(orientation[2]), math.rad(orientation[3]))
		weld.Parent = toolModel.Handle

		-- Track weapon
		self.weapons[weapon.Name] = toolModel
		return toolModel
	end

	-- Unholster a specific weapon
	function self:unholster(weaponName: string)
		local weapon = self.weapons[weaponName]
		if weapon then
			weapon:Destroy()
			self.weapons[weaponName] = nil
		end
	end

	-- Unholster all weapons
	function self:unholsterAll()
		for name, weapon in pairs(self.weapons) do
			if weapon then
				weapon:Destroy()
			end
		end
		self.weapons = {}
	end

	-- Get all currently holstered weapons
	function self:getWeapons()
		local list = {}
		for _, weapon in pairs(self.weapons) do
			table.insert(list, weapon)
		end
		return list
	end

	function self:Destroy()
		self:unholsterAll()
		self.weaponsFolder:Destroy()
		self.weapons = nil
	end

	return self
end

return createHolster
