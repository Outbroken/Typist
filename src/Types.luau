--!strict

-->>--------------------------------------------<<--
-- @Created: September 14th, 2025
-- @Authors: Outbroken

-- @Description:
-- A collection of types used in the module
-->>--------------------------------------------<<--

-- >> Character <<
export type CharacterProperties = {
	Styles: { [string]: any },

	Size: number?,
	SizingType: ("Absolute" | "Relative")?,
	DelayLength: number?,
	DelayType: ("IgnoreSpace" | "Word")?,
	AnimationName: string?,

	Flag: number?,
	Split: boolean?,
	Image: { Id: number }?,
	Sound: {
		Id: number,
		Volume: number,
		Pitch: number,
	}?,
}

export type Character = {
	Value: string,
	Properties: CharacterProperties,
	Instance: Instance?,
}

export type CharacterTransform = {
	Position: UDim2,
	Size: UDim2,
	LineNumber: number,
	CharacterNumber: number,
	AbsoluteIndex: number,
}

-- >> Writer <<

--[=[
	@interface WriterPreset
	@within Writer
	.PresetName string -- The name of the preset

	.Font Font -- Font used for characters
	.FontSize number -- Size of the font, in pixels
	.FontSizingType string -- Absolute / Relative, the method used to determine the font's size

	.RichText boolean -- Whether the text is parsed for rich text

	.WrapText boolean -- Whether text is wrapped when it exceeds its bounds
	.AbsoluteCharacterWidth boolean -- Forces all characters to match the font width
	.AbsoluteLineHeight boolean -- Forces all lines to match the font height
	.Anchor Vector2 -- Alignment of text within the container
	.Tracking number -- Horizontal space between each character
	.LineSpacing number -- Vertical space between each line

	.WritingSpeed number -- The speed at which the writer writes, in characters per minute
	.PauseAfterPunctuation boolean -- Whether the writer pauses longer after punctuation
	.WritingAnimation string -- The animation effect played as a character is written
	.WritingSound string -- The sound effect played as a character is written, as an assetId
]=]
export type WriterPreset = {
	PresetName: string,
	Font: Font,
	FontSize: number,
	FontSizingType: string,
	RichText: boolean,
	WrapText: boolean,
	AbsoluteCharacterWidth: boolean,
	AbsoluteLineHeight: boolean,
	Anchor: Vector2,
	Tracking: number,
	LineSpacing: number,
	WritingSpeed: number,
	PauseAfterPunctuation: boolean,
	WritingAnimation: string,
	WritingSound: string,
}

export type WriterExitState = "Success" | "Skipped" | "Canceled" | "Destroyed"

-- >> Rich Text <<

export type TagToken = {
	Type: "TAG",
	Name: string,
	Opening: boolean,
	Action: boolean,
	Content: { [string]: string },
}

export type TextToken = {
	Type: "TEXT",
	Content: string,
}

export type Token = TagToken | TextToken

return nil
