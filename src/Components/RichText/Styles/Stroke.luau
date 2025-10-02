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
		styleProperties.Color = util.evaluateColorContent(tagContent.Color)
	end

	if tagContent.Opacity then
		styleProperties.Opacity = util.evaluateRatioContent(tagContent.Opacity)
	end

	return styleProperties
end

function Style.Apply(character: TextLabel, styleProperties: StyleProperties)
	if styleProperties.Color then
		character.TextStrokeColor3 = styleProperties.Color
		character.TextStrokeTransparency = 0
	end

	if styleProperties.Opacity then
		character.TextStrokeTransparency = 1 - styleProperties.Opacity
	end
end

return Style
