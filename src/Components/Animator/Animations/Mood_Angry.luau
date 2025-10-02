--!strict

-->>--------------------------------------------<<--
-- @Created: September 29th, 2025
-- @Authors: Outbroken

-- @Description:
-- Angry Animation for the Writer
-->>--------------------------------------------<<--

return function(object: GuiLabel): Animation
	-- Randomize everything
	local magnitude = math.random(10, 15)
	local duration = math.random(25, 45) / 100

	-- Randomly generate an offset
	local randomAngle = math.rad(math.random(1, 360))
	local newX = math.cos(randomAngle) * magnitude
	local newY = math.sin(randomAngle) * magnitude

	return {
		Object = object,
		Repeat = true,
		PositionAnchor = object.Position,
		Keyframes = {
			{
				Properties = {
					Position = UDim2.new(),
				},
			},
			{
				Time = duration + 0.05,
				EasingStyle = Enum.EasingStyle.Elastic,
				EasingDirection = Enum.EasingDirection.In,
				Properties = {
					Position = UDim2.fromOffset(newX, newY),
				},
			},
			{
				Time = duration + 0.25,
				EasingStyle = Enum.EasingStyle.Elastic,
				EasingDirection = Enum.EasingDirection.In,
				Properties = {
					Position = UDim2.new(),
				},
			},
			{
				Time = duration + 0.55,
				EasingStyle = Enum.EasingStyle.Elastic,
				EasingDirection = Enum.EasingDirection.In,
				Properties = {
					Position = UDim2.new(),
				},
			},
		},
	}
end
