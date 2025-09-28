local TagUtilities = {}

--[[
@Description:
Converts a color string into a Color3 value
ex. #ffffff -> Color3.new(1, 1, 1)

@Inputs:
- colourContent <string>: the string to evaluate

@Output:
<Color3> the color obtained from it
]]
function TagUtilities.evaluateColorContent(colorContent: string): Color3
	local startingCharacter = string.sub(colorContent, 1, 1)

	if startingCharacter == "#" then
		-- Hex
		return Color3.fromHex(colorContent)
	end

	warn("A color must begin with either #, RGB, or HSV. Other types are not supported. ")
	return Color3.new(1, 1, 1)
end

--[[
@Description:
Converts a ratio string into a number
ex. 30% -> 0.3

@Inputs:
- ratioContent <string>: the ratio to evaluate

@Output:
<number> the number obtained from it
]]
function TagUtilities.evaluateRatioContent(ratioContent: string): number
	local terminatingCharacter = string.sub(ratioContent, #ratioContent, #ratioContent)

	if terminatingCharacter == "%" then
		-- Percentage
		local Percentage = tonumber(string.sub(ratioContent, 1, #ratioContent - 1))
		return Percentage / 100
	elseif string.find(ratioContent, "/") then
		-- Fraction
		local Fraction = string.split(ratioContent, "/")
		local Numerator = tonumber(Fraction[1])
		local Denominator = tonumber(Fraction[2])

		return Numerator / Denominator
	else
		-- Decimal
		return tonumber(ratioContent)
	end
end

function TagUtilities.evaluateAdvancedColorContent(colorContent: string): {}
	-- If there is no "fade" keyword, process the color like normal
	if string.sub(colorContent, 1, 4) ~= "fade" then
		return TagUtilities.evaluateColorContent(colorContent)
	end

	local fadePropertiesString = string.match(colorContent, "%(.-%)")
	local fadeProperties = string.split(string.sub(fadePropertiesString, 2, #fadePropertiesString - 1), ", ")

	local fadeDuration = tonumber(fadeProperties[1])
	local fadeEasing = Enum.EasingStyle[fadeProperties[2]]
	local fadeRepeat = fadeProperties[3] ~= nil

	local fadeValuesStart, fadeValuesEnd = string.find(colorContent, "%{.-%}")
	local fadeValues = string.split(string.sub(colorContent, fadeValuesStart + 1, fadeValuesEnd - 1), ", ")

	local keyframes = {}
	for index, fadeValue in pairs(fadeValues) do
		keyframes[index] = TagUtilities.evaluateColorContent(fadeValue)
	end

	return {
		Properties = {
			Duration = fadeDuration,
			Easing = fadeEasing,
			Repeat = fadeRepeat,
		},
		Keyframes = keyframes,
	}
end

return TagUtilities
