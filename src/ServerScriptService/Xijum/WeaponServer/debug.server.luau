local Players = game:GetService("Players")

local function giveAssaultRifle(player)
	local tool = Instance.new("Tool")
	tool.Name = "AssaultRifle"
	tool.RequiresHandle = false

	local boolValue = Instance.new("BoolValue")
	boolValue.Name = "XijumWeapon"
	boolValue.Value = true
	boolValue.Parent = tool

	tool.Parent = player.Backpack
end

local function onPlayerAdded(player)
	player.CharacterAdded:Connect(function()
		giveAssaultRifle(player)
	end)
end

Players.PlayerAdded:Connect(onPlayerAdded)
