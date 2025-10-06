--!strict

-->>--------------------------------------------<<--
-- @Created: September 19th, 2025
-- @Authors: Outbroken

-- @Description:
-- Rich Text Style: Stroke
-->>--------------------------------------------<<--

-- >> References <<

local util = require(script.Parent.Parent.TagUtilities)

-- >> Types <<

type TagContent = { [string]: string }
type StyleProperties = { [string]: any }

-- >> Methods <<

local Style = {}
Style.TagName = "stroke"

function Style.Add(tagContent: TagContent): StyleProperties
	local styleProperties = {}

	if tagContent.Color then
		styleProperties.Color = util.evaluateAdvancedColorContent(tagContent.Color)
	end

	if tagContent.Opacity then
		styleProperties.Opacity = util.evaluateRatioContent(tagContent.Opacity)
	end

	if tagContent.Thickness then
		styleProperties.Thickness = tonumber(tagContent.Thickness)
	end

	return styleProperties
end

function Style.Apply(character: TextLabel, styleProperties: StyleProperties, Animator: {})
	-- Override default character properties
	character.TextStrokeTransparency = 1

	-- Create a new stroke object
	local newStroke = Instance.new("UIStroke")

	if styleProperties.Thickness then
		newStroke.Thickness = styleProperties.Thickness
	end

	if styleProperties.Opacity then
		newStroke.Transparency = 1 - styleProperties.Opacity
	end

	if styleProperties.Color then
		if typeof(styleProperties.Color) == "Color3" then
			-- If the color is static, apply it like normal
			newStroke.Color = styleProperties.Color
		else
			-- If it is a dynamic color, create an animator animation
			local colorProperties = styleProperties.Color.Properties
			local styleKeyframes = styleProperties.Color.Keyframes

			local animatorKeyframes = { {
				Properties = { Color = Color3.new(1, 1, 1) },
			} }

			local currentTime = 0
			for _, color in pairs(styleKeyframes) do
				animatorKeyframes[#animatorKeyframes + 1] = {
					Time = currentTime,
					Properties = { Color = color },
					EasingStyle = colorProperties.Easing,
					EasingDirection = Enum.EasingDirection.In,
				}
				currentTime += colorProperties.Duration / #styleKeyframes
			end

			Animator:AddAnimation({
				Object = newStroke,
				Repeat = true,
				Keyframes = animatorKeyframes,
			})
		end
	end

	newStroke.Parent = character
end

return Style
