--!strict

-->>--------------------------------------------<<--
-- @Created: September 29th, 2025
-- @Authors: Outbroken

-- @Description:
-- Flow Animation for the Writer
-->>--------------------------------------------<<--

return function(object: GuiLabel, newPosition: UDim2): Animation
	return {
		Object = object,
		Keyframes = {
			{
				Properties = {
					TextTransparency = 1,
					Position = newPosition - UDim2.fromOffset(0, object.Size.Y.Offset / 2),
					Rotation = -12,
				},
			},
			{
				Time = 0.15,
				EasingStyle = Enum.EasingStyle.Linear,
				EasingDirection = Enum.EasingDirection.Out,
				Properties = {
					TextTransparency = 0,
					Position = newPosition,
					Rotation = 0,
				},
			},
		},
	}
end
