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

local Character = require(script.Parent.Character)

-- >> Types <<

local _Types = require(script.Parent.Parent.Types)

type WriterPreset = _Types.WriterPreset
type CharacterClass = Character.CharacterClass
type CharacterTransform = _Types.CharacterTransform

-- >> Constants <<

-- The screen height that fonts are scaled from
-- At this height, font sizes display at their intended value
local SCREEN_HEIGHT_REFERENCE = 1080

-- Character to help calculate the height of a line
local lineHeightCharacter = Character.new()
lineHeightCharacter.Value = "H"

-- >> Functions <<

--[[
	Calculates the size of a list of characters
]]
local function getCharacterSizes(characters: { CharacterClass }, activePreset: WriterPreset): { Vector2 }
	-- Create an empty of list of character sizes
	local characterSizes = {}

	-- Create a text boundary param template
	local textBoundParams = Instance.new("GetTextBoundsParams")
	textBoundParams.Font = activePreset.Font

	-- Rescale font to the portion the mount takes up of the screen
	local scaledFontSize = activePreset.FontSize
	if activePreset.ScaleFont then
		local currentScreenHeight = workspace.CurrentCamera.ViewportSize.Y
		scaledFontSize = activePreset.FontSize * (currentScreenHeight / SCREEN_HEIGHT_REFERENCE)
	end

	-- Get the tracking multiplier from the active preet
	local trackingMultiple = activePreset.Tracking or 1

	-- Loop through each character
	for index, character in pairs(characters) do
		-- If custom font styles are present, apply them
		textBoundParams.Font.Style = Enum.FontStyle.Normal
		textBoundParams.Font.Bold = false

		if character.Properties.Styles then
			if character.Properties.Styles.i then
				textBoundParams.Font.Style = Enum.FontStyle.Italic
			end

			if character.Properties.Styles.b then
				textBoundParams.Font.Bold = true
			end
		end

		local styledFontSize = scaledFontSize * (character.Properties.Size or 1)
		textBoundParams.Size = styledFontSize

		-- If ForceMonospace is true, use the static width of a "W"
		if activePreset.ForceMonospace then
			textBoundParams.Text = "W"
		else
			-- Otherwise, use the character's text
			textBoundParams.Text = character.Value
		end

		-- Calculate the size using a roblox method
		local characterSize = TextService:GetTextBoundsAsync(textBoundParams)

		-- Add the size to the table
		characterSizes[index] = Vector2.new(characterSize.X * 2 * trackingMultiple, characterSize.Y * 2)
	end

	return characterSizes
end

--[[
	Wraps a list of characters over multiple lines
]]
local function wrapCharacters(
	characters: { CharacterClass },
	characterSizes: { Vector2 },
	maxWidth: number
): { { CharacterClass } }
	-- Break the characters into words
	local words = { {} }
	local wordIndex = 1

	for _, character in pairs(characters) do
		-- If the character is a space, start writing the next word
		if character.Value == " " then
			wordIndex += 1
			words[wordIndex] = {}
		end

		-- Add the character to the current word
		words[wordIndex][#words[wordIndex] + 1] = character
	end

	-- Wrap the words
	local lines = { {} }
	local currentWidth = 0
	local lineIndex = 1

	local characterIndex = 0
	for _, word in pairs(words) do
		-- Calculate word width
		local wordWidth = 0
		for _, _ in pairs(word) do
			characterIndex += 1
			wordWidth += characterSizes[characterIndex].X
		end
		currentWidth += wordWidth

		-- If overflowing, wrap to the next line
		if currentWidth > maxWidth then
			lineIndex += 1
			currentWidth = wordWidth
			lines[lineIndex] = {}

			-- If the first character is a space, move the space to the previous line
			if word[1].Value == " " then
				lines[lineIndex - 1][#lines[lineIndex - 1] + 1] = word[1]
				table.remove(word, 1)
			end
		end

		-- Add the current word to the current line
		for _, character in pairs(word) do
			lines[lineIndex][#lines[lineIndex] + 1] = character
		end
	end

	return lines
end

-- >> Module <<

--[[
	Gets a set of character transforms
]]
return function(characters: { CharacterClass }, mount: GuiObject, activePreset: WriterPreset): { CharacterTransform }
	-- Get the sizes of the characters
	local characterSizes = getCharacterSizes(characters, activePreset)

	-- Calculate the container's width
	local containerSize = mount.AbsoluteSize
	local maxWidth = containerSize.X - (activePreset.HorizontalPadding * 2)

	-- If wrapping is enabled, wrap the text
	local textLines = nil
	if activePreset.WrapText then
		textLines = wrapCharacters(characters, characterSizes, maxWidth)
	else
		-- Otherwise, push the characters to a single line
		textLines = { characters }
	end

	-- Calculate line heights
	local absoluteIndex = 1
	local currentLineHeight = 0
	local baseLineHeight = getCharacterSizes({ lineHeightCharacter }, activePreset)[1].Y

	local lineHeights = {}
	for lineIndex = 1, #textLines, 1 do
		currentLineHeight = baseLineHeight

		for _ = 1, #textLines[lineIndex], 1 do
			local characterSize = characterSizes[absoluteIndex]

			-- If the line height is dynamic, adjust based on character height
			if activePreset.DynamicLineHeight and characterSize.Y > currentLineHeight then
				currentLineHeight = characterSize.Y
			end

			absoluteIndex += 1
		end

		lineHeights[lineIndex] = currentLineHeight
	end

	-- Calculate positions
	local characterTransforms = {}
	absoluteIndex = 1

	local offsetX = activePreset.HorizontalPadding
	local offsetY = activePreset.VerticalPadding

	for lineIndex = 1, #textLines, 1 do
		offsetX = activePreset.HorizontalPadding

		-- Loop through each character in the line
		for characterIndex = 1, #textLines[lineIndex], 1 do
			local characterSize = characterSizes[absoluteIndex]

			local centeringOffset = (lineHeights[lineIndex] - characterSize.Y) * 0.5
			local transform = {
				Position = UDim2.fromOffset(offsetX, offsetY + centeringOffset),
				Size = UDim2.fromOffset(characterSize.X, characterSize.Y),
				LineNumber = lineIndex,
				CharacterNumber = characterIndex,
				AbsoluteIndex = absoluteIndex,
			}

			characterTransforms[#characterTransforms + 1] = transform
			offsetX += characterSize.X
			absoluteIndex += 1
		end

		offsetY += lineHeights[lineIndex] * (activePreset.LineSpacing or 1)
	end

	return characterTransforms
end
