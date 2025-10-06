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
		Anchor = { Size = object.Size },
		Keyframes = {
			{
				Properties = {
					Size = 0.8,
				},
			},
			{
				Time = 0.25,
				EasingStyle = Enum.EasingStyle.Sine,
				EasingDirection = Enum.EasingDirection.InOut,
				Properties = { Size = 1.2 },
			},
			{
				Time = 0.55,
				EasingStyle = Enum.EasingStyle.Sine,
				EasingDirection = Enum.EasingDirection.Out,
				Properties = { Size = 1 },
			},
		},
	}
end
