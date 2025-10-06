-->>--------------------------------------------<<--
-- @Created: September 26th, 2025
-- @Authors: Outbroken

-- @Description:
-- The default preset used in the typewriter module
-- Other presets override this one

-- @Important: This preset shouldn't be modified. Create another one instead.
-->>--------------------------------------------<<--

return {
	PresetName = "_default", -- Name of the preset

	-- Main
	Font = Font.new("rbxasset://fonts/families/RobotoMono.json"), -- Ref: https://create.roblox.com/docs/reference/engine/datatypes/Font
	FontSize = 30, -- Size of the font, in pixels

	-- Rich Text
	RichText = true, -- Whether the text is parsed for rich text
	ValidateRichText = true, -- Whether rich text is automatically checked for errors

	-- Wrapping
	WrapText = true, -- Controls whether text is wrapped when it overflows
	ForceMonospace = false, -- Forces all characters to have a static width (monospace)
	DynamicLineHeight = false, -- Automatically adjust line height when appropriate
	ScaleFont = true, -- Determines whether the font is automatically scaled for different screen sizes

	Tracking = 1, -- The horizontal space between individual characters, as a multiple of the character's width
	LineSpacing = 1, -- The vertical space between lines of text
	HorizontalPadding = 15, -- Horizontal space between the text and the mount
	VerticalPadding = 15, -- Vertical space between the text and the mount

	-- Writing
	WritingSpeed = 20, -- The speed at which the writer writes, in characters per second
	PauseAfterPunctuation = true, -- Whether the typewriter pauses longer on punctuation
	WritingAnimation = "Writer_Flow", -- The animation effect played as a character is written
	WritingSound = "rbxassetid://147982968", -- The sound effect played as a character is written
}
