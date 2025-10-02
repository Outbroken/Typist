--!strict

-->>--------------------------------------------<<--
-- @Created: September 17th, 2025
-- @Authors: Outbroken

-- @Description:
-- Rich Text Style: Fill
-->>--------------------------------------------<<--

-- >> References <<

local util = require(script.Parent.Parent.TagUtilities)

-- >> Types <<

type TagContent = { [string]: string }
type StyleProperties = { [string]: any }

-- >> Methods <<

local Style = {}
Style.TagName = "fill"

function Style.Add(tagContent: TagContent): StyleProperties
	local styleProperties = {}

	if tagContent.Color then
		styleProperties.Color = util.evaluateAdvancedColorContent(tagContent.Color)
	end

	if tagContent.Opacity then
		styleProperties.Opacity = util.evaluateRatioContent(tagContent.Opacity)
	end

	return styleProperties
end

function Style.Apply(character: TextLabel, styleProperties: StyleProperties, Animator: {})
	if styleProperties.Color then
		if typeof(styleProperties.Color) == "Color3" then
			character.TextColor3 = styleProperties.Color
		else
			local colorProperties = styleProperties.Color.Properties
			local styleKeyframes = styleProperties.Color.Keyframes

			local animatorKeyframes = {
				{
					Properties = { TextColor3 = Color3.new(1, 1, 1) },
				},
			}

			local currentTime = 0
			for _, color in pairs(styleKeyframes) do
				animatorKeyframes[#animatorKeyframes + 1] = {
					Time = currentTime,
					Properties = { TextColor3 = color },
					EasingStyle = colorProperties.Easing,
					EasingDirection = Enum.EasingDirection.In,
				}
				currentTime += colorProperties.Duration / #styleKeyframes
			end

			Animator:AddAnimation({
				Object = character,
				Repeat = true,
				Keyframes = animatorKeyframes,
			})
		end
	end

	if styleProperties.Opacity then
		character.TextTransparency = 1 - styleProperties.Opacity
	end
end

return Style
