--[[
@Description:
A collection of mood animations

@Created: 9/7/25
@Modified: 9/7/25
]]

-- >> Core Services <<

local TweenService = game:GetService("TweenService")

-- >> Functions <<

local function simulateTime(positionA, positionB, travelTime, simulatedTime) end

-- >> Module <<

return {
	Angry = function(Character: GuiObject, skippedTime: number)
		-- Randomize everything
		local magnitude = math.random(10, 15)
		local duration = math.random(25, 45) / 100

		-- Randomly generate an offset
		local randomAngle = math.rad(math.random(1, 360))
		local newX = math.cos(randomAngle) * magnitude
		local newY = math.sin(randomAngle) * magnitude

		-- Animate!
		local Animation = TweenService:Create(
			Character,
			TweenInfo.new(duration, Enum.EasingStyle.Elastic, Enum.EasingDirection.In, -1, true),
			{ Position = Character.Position + UDim2.fromOffset(newX, newY) }
		)

		Animation:Play()
	end,

	Dreamlike = function(Character: GuiObject, skippedTime: number)
		local magnitude = 0.25
		Character.Position = Character.Position - UDim2.fromOffset(0, Character.Size.Y.Offset * magnitude)

		-- Animate!
		local Animation = TweenService:Create(
			Character,
			TweenInfo.new(0.75, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
			{ Position = Character.Position + UDim2.fromOffset(0, Character.Size.Y.Offset * (magnitude * 2)) }
		)

		-- Use Tween:GetValue()!!
		Animation:Play()
	end,
}
