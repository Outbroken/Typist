--!strict

--[[
@Description:
Converts strings into useable character data

@Created: 9/6/25
@Modified: 9/6/25
]]
-- >> Core Services <<

local TextService = game:GetService("TextService")

-- >> References : Modules <<

local _CharacterTypes = require(script.Parent.Parent.Types)
type CharacterStyle = _CharacterTypes.CharacterStyle
type Character = _CharacterTypes.Character

-- >> Types <<

type Tag = {
	Content: string,
	Start: number,
	End: number,
}

-- >> Functions <<

--[[
@Overview: 
Converts a string into a set of Characters, without searching for tags

@Inputs:
- text <string>: a string of text to convert

@Output:
<Character[]> a set of characters
]]
local function wrapTextToLines(characters: { Character }, TextData: {}, maxWidth: number): { { Character } }
	-- Break characters into words
	local Words = { {} }
	local wordIndex = 1

	for _, character in pairs(characters) do
		-- If the character is a space, start writing the next word
		if character.Value == " " then
			wordIndex += 1
			Words[wordIndex] = {}
		end

		-- Add the character to the current word
		Words[wordIndex][#Words[wordIndex] + 1] = character
	end

	-- Wrap the words
	local Lines = { {} }
	local currentWidth = 0
	local lineIndex = 1

	local textBoundParams = Instance.new("GetTextBoundsParams")
	textBoundParams.Text = ""
	textBoundParams.Font = TextData.Font
	textBoundParams.Size = 0
	textBoundParams.Width = 10000

	for _, word in pairs(Words) do
		-- Calculate word width
		local wordWidth = 0
		for _, character in pairs(word) do
			textBoundParams.Text = character.Value
			textBoundParams.Size = character.Properties.Size or TextData.FontSize

			local characterSize = TextService:GetTextBoundsAsync(textBoundParams)
			wordWidth += (characterSize.X * 2)
		end
		currentWidth += wordWidth

		-- If overflowing, move to the next line
		if currentWidth > maxWidth then
			lineIndex += 1
			currentWidth = wordWidth
			Lines[lineIndex] = {}

			-- If the first character is a space, move the space to the previous line
			if word[1].Value == " " then
				Lines[lineIndex - 1][#Lines[lineIndex - 1] + 1] = word[1]
				table.remove(word, 1)
			end
		end

		-- Add word to the current line
		for _, character in pairs(word) do
			Lines[lineIndex][#Lines[lineIndex] + 1] = character
		end
	end

	return Lines
end

-- >> Module <<

local Wrapper = {}

function Wrapper.CalculateTransforms(Characters: { Character }, TextData: {}, ContainerSize: Vector2): { UDim2 }
	-- Wrap text to lines
	local textLines = wrapTextToLines(Characters, TextData, ContainerSize.X - (TextData.FontSize * 2))

	-- Calculate positions
	local characterTransforms = {}
	local absoluteIndex = 1

	local offsetX = TextData.FontSize
	local offsetY = TextData.FontSize
	local currentLineHeight = 0

	local textBoundParams = Instance.new("GetTextBoundsParams")
	textBoundParams.Text = ""
	textBoundParams.Font = TextData.Font
	textBoundParams.Size = 0
	textBoundParams.Width = 10000

	for lineIndex = 1, #textLines, 1 do
		currentLineHeight = 0
		offsetX = TextData.FontSize

		-- Iterate through each character in the line
		for characterIndex = 1, #textLines[lineIndex], 1 do
			local character = Characters[absoluteIndex]

			textBoundParams.Text = character.Value
			textBoundParams.Size = character.Properties.Size or TextData.FontSize
			local characterSize = TextService:GetTextBoundsAsync(textBoundParams)

			if characterSize.Y > currentLineHeight then
				currentLineHeight = (characterSize.Y * 2)
			end

			local centeringOffset = (currentLineHeight - characterSize.Y * 2) / 2
			local Transform = {
				Position = UDim2.fromOffset(offsetX, offsetY),
				Size = UDim2.fromOffset(characterSize.X * 2, (characterSize.Y * 2) + centeringOffset),
				LineNumber = lineIndex,
				CharacterNumber = characterIndex,
				AbsoluteIndex = absoluteIndex,
			}

			characterTransforms[#characterTransforms + 1] = Transform
			offsetX += (characterSize.X * 2)
			absoluteIndex += 1
		end

		offsetY += currentLineHeight
	end

	return characterTransforms
end

return Wrapper
