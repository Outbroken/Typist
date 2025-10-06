--!strict

-->>--------------------------------------------<<--
-- @Created: September 29th, 2025
-- @Authors: Outbroken

-- @Description:
-- Dreamy Animation for the Writer
-->>--------------------------------------------<<--

return function(object: GuiLabel): Animation
	return {
		Object = object,
		Repeat = true,
		Anchor = { Position = object.Position },
		Keyframes = {
			{
				Properties = {
					Position = UDim2.fromOffset(0, object.Size.Y.Offset * 0.25),
				},
			},
			{
				Time = 0.75,
				EasingStyle = Enum.EasingStyle.Sine,
				EasingDirection = Enum.EasingDirection.InOut,
				Properties = {
					Position = UDim2.fromOffset(0, -object.Size.Y.Offset * 0.25),
				},
			},
			{
				Time = 1.5,
				EasingStyle = Enum.EasingStyle.Sine,
				EasingDirection = Enum.EasingDirection.InOut,
				Properties = {
					Position = UDim2.fromOffset(0, object.Size.Y.Offset * 0.25),
				},
			},
		},
	}
end
