-- Raycast Framework
local Raycast = {}
Raycast.__index = Raycast
function Raycast.new()
	local self = setmetatable({}, Raycast)
	return self
end
function Raycast:PerformRaycast(origin, direction, ignoreList)
	local raycastParams = RaycastParams.new()
	raycastParams.FilterType = Enum.RaycastFilterType.Exclude
	raycastParams.FilterDescendantsInstances = ignoreList or {}
	local result = workspace:Raycast(origin, direction, raycastParams)
	return result
end

return Raycast
