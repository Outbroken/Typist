--!strict

-->>--------------------------------------------<<--
-- @Created: September 6th, 2025
-- @Authors: Outbroken

-- @Description:
-- Wraps and positions text
-->>--------------------------------------------<<--

-- >> Core Services <<

local TextService = game:GetService("TextService")

-- >> References : Modules <<

local _Types = require(script.Parent.Parent.Types)
type WriterPreset = _Types.WriterPreset
type Character = _Types.Character
type CharacterTransform = _Types.CharacterTransform

-- >> Functions <<

--[[
@Overview:
Converts a string into a set of Characters, without searching for tags

@Inputs:
- text <string>: a string of text to convert

@Output:
<Character[]> a set of characters
]]
local function wrapTextToLines(characters: { Character }, maxWidth: number, fontData: {}): { { Character } }
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
	textBoundParams.Font = fontData.Font
	textBoundParams.Size = 0
	textBoundParams.Width = 10000

	for _, word in pairs(Words) do
		-- Calculate word width
		local wordWidth = 0
		for _, character in pairs(word) do
			textBoundParams.Text = character.Value

			if character.Properties.Size then
				textBoundParams.Size = fontData.FontSize * (1 + (character.Properties.Size / 100))
			else
				textBoundParams.Size = fontData.FontSize
			end

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

function Wrapper.CalculateTransforms(
	characters: { Character },
	Container: Instance,
	activePreset: WriterPreset
): { CharacterTransform }
	local processedFontSize = activePreset.FontSize

	if activePreset.AutoResizeFont then
		local screenHeight = workspace.CurrentCamera.ViewportSize.Y
		processedFontSize = activePreset.FontSize * (screenHeight / 563)
	end

	local containerSize = Container.AbsoluteSize
	local useableContainerWidth = containerSize.X - (processedFontSize * 2)

	-- Wrap text to lines
	local textLines =
		wrapTextToLines(characters, useableContainerWidth, { Font = activePreset.Font, FontSize = processedFontSize })

	-- Calculate positions
	local characterTransforms = {}
	local absoluteIndex = 1

	local offsetX = processedFontSize
	local offsetY = processedFontSize
	local currentLineHeight = 0

	local textBoundParams = Instance.new("GetTextBoundsParams")
	textBoundParams.Text = ""
	textBoundParams.Font = activePreset.Font
	textBoundParams.Size = 0
	textBoundParams.Width = 10000

	for lineIndex = 1, #textLines, 1 do
		currentLineHeight = 0
		offsetX = processedFontSize

		-- Iterate through each character in the line
		for characterIndex = 1, #textLines[lineIndex], 1 do
			local character = characters[absoluteIndex]

			textBoundParams.Text = character.Value

			if character.Properties.Size then
				textBoundParams.Size = processedFontSize * (1 + (character.Properties.Size / 100))
			else
				textBoundParams.Size = processedFontSize
			end

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
