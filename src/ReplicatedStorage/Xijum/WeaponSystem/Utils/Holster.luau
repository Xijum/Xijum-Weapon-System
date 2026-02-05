local function createHolster(character: Model)
	local weapons = {}
	local weaponsFolder = character:FindFirstChild("HolsterWeapons") or Instance.new("Folder")
	weaponsFolder.Name = "HolsterWeapons"
	weaponsFolder.Parent = character

	local function registerWeapon(weapon)
		weapon.Parent = weaponsFolder
		if weapon:FindFirstChild("Handle") then
			weapon.Handle.CanCollide = false
		end
		table.insert(weapons, weapon)
		return weapon
	end

	local function holster(tool: Tool)
		local weapon = tool:Clone()
		weapon.Parent = weaponsFolder
		if weapon:FindFirstChild("Handle") then
			weapon.Handle.CanCollide = false
		end
		table.insert(weapons, weapon)
		return weapon
	end

	local function unholster(weapon: Model)
		local index = table.find(weapons, weapon)
		if index then
			weapons[index]:Destroy()
			table.remove(weapons, index)
		end
	end

	local function unholsterAll()
		for i = #weapons, 1, -1 do
			weapons[i]:Destroy()
		end
		table.clear(weapons)
	end

	local function getWeapons()
		return weapons
	end

	return {
		holster = holster,
		unholster = unholster,
		unholsterAll = unholsterAll,
		getWeapons = getWeapons,
		registerWeapon = registerWeapon,
	}
end

return createHolster
