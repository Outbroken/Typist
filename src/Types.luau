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

-- >> Writer <<

export type WriterExitState = "Success" | "Skipped" | "Canceled" | "Destroyed"

export type WriterSettings = {
	-- Display
	Font: Font,
	FontSize: number,
	Tracking: number,
	LineSpacing: number,
	Wrapping: boolean,

	-- Writer
	WritingSpeed: number,
	PauseOnPunctuation: boolean,
	WritingAnimation: string,
}

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
