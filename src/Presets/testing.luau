-->>--------------------------------------------<<--
-- @Created: October 2nd, 2025
-- @Authors: Outbroken

-- @Description:
-- A testing preset to mess around with swapping
-->>--------------------------------------------<<--

return {
	PresetName = "testing", -- Name of the preset

	-- Font
	Font = Font.new("rbxasset://fonts/families/Montserrat.json"), -- Ref: https://create.roblox.com/docs/reference/engine/datatypes/Font
	FontSize = 25, -- Size of the font, in pixels
	AutoResizeFont = true,

	-- RichText
	RichText = true, -- Whether the text is parsed for rich text

	-- Wrapping
	WrapText = true, -- Whether text is wrapped over multiple lines or not
	AbsoluteCharacterWidth = false, -- Forces all characters to match the font width
	AbsoluteLineHeight = false, -- Forces all lines to match the font height
	AnchorX = 0, -- Where the text is aligned within the container, on the horizontal axis
	AnchorY = 0, -- Where the text is aligned within the container, on the vertical axis
	Tracking = 1, -- The space between individual characters
	LineSpacing = 1, -- The space between lines of text

	-- Writing
	WritingSpeed = 20, -- The speed at which the writer writes, in characters per minute
	PauseAfterPunctuation = true, -- Whether the typewriter pauses longer on punctuation
	WritingAnimation = "Writer_Jelly", -- The animation effect played as a character is written
	WritingSound = "rbxassetid://147982968", -- The sound effect played as a character is written
}
