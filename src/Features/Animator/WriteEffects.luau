--[[
@Description:
A collection of write-on animations

@Created: 9/6/25
@Modified: 9/6/25
]]

-- >> Core Services <<

local TweenService = game:GetService("TweenService")

-- >> Module <<

return {
	DropIn = function(Character: GuiObject, desiredPosition: UDim2, writeOnCooldown: number)
		Character.Position = desiredPosition - UDim2.new(0, 0, 0, Character.Size.Y.Offset / 2)

		local animation = TweenService:Create(
			Character,
			TweenInfo.new(writeOnCooldown * 3, Enum.EasingStyle.Sine),
			{ Position = desiredPosition }
		)

		animation:Play()
	end,

	FadeIn = function(Character: GuiObject, desiredPosition: UDim2, writeOnCooldown: number)
		Character.Position = desiredPosition
		Character.TextTransparency = 1

		local animation = TweenService:Create(
			Character,
			TweenInfo.new(writeOnCooldown * 5, Enum.EasingStyle.Quad),
			{ TextTransparency = 0 }
		)

		animation:Play()
	end,

	BounceIn = function(Character: GuiObject, desiredPosition: UDim2, writeOnCooldown: number)
		Character.Position = desiredPosition - UDim2.new(0, 0, 0, Character.Size.Y.Offset / 2)

		local animation =
			TweenService:Create(Character, TweenInfo.new(0.2, Enum.EasingStyle.Bounce), { Position = desiredPosition })

		animation:Play()
	end,
}
