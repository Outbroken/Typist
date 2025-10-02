--!strict

-->>--------------------------------------------<<--
-- @Created: September 29th, 2025
-- @Authors: Outbroken

-- @Description:
-- Jelly Animation for the Writer
-->>--------------------------------------------<<--

return function(object: GuiLabel): Animation
	return {
		Object = object,
		Keyframes = {
			{
				Properties = {
					Size = UDim2.fromOffset(object.Size.X.Offset * 0.8, object.Size.Y.Offset * 0.8),
				},
			},
			{
				Time = 0.25,
				EasingStyle = Enum.EasingStyle.Sine,
				EasingDirection = Enum.EasingDirection.InOut,
				Properties = { Size = UDim2.fromOffset(object.Size.X.Offset * 1.2, object.Size.Y.Offset * 1.2) },
			},
			{
				Time = 0.55,
				EasingStyle = Enum.EasingStyle.Sine,
				EasingDirection = Enum.EasingDirection.Out,
				Properties = { Size = object.Size },
			},
		},
	}
end
