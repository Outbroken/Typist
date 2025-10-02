--!strict

-->>--------------------------------------------<<--
-- @Created: September 29th, 2025
-- @Authors: Outbroken

-- @Description:
-- Cryptic Animation for the Writer
-->>--------------------------------------------<<--

local characters = "abcdefghijklmnopqrstuvwxyz0123456789.,/;:!@#$%^&*-+"
local characterCount = 5
local characterInterval = 0.05

return function(object: GuiLabel): Animation
	local keyframes = { {
		Properties = {
			Text = object.Text,
		},
	} }

	for index = 1, characterCount, 1 do
		local randomValue = math.random(1, #characters)
		local letter = string.sub(characters, randomValue, randomValue)

		keyframes[index + 1] = {
			Time = index * characterInterval,
			EasingStyle = Enum.EasingStyle.Linear,
			EasingDirection = Enum.EasingDirection.In,
			Properties = { Text = letter },
		}
	end

	return {
		Object = object,
		Repeat = true,
		Keyframes = keyframes,
	}
end
