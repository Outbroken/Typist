return {
	-- @Description: If enabled, the parser will check for broken or out of order tags automatically
	-- @Default: true
	STRICT_PARSING = false,

	-- @Description: Character used to open a tag
	-- @Default: "<"
	TAG_OPEN_CHARACTER = "<",

	-- @Description: Character used to close a tag
	-- @Default: ">"
	TAG_CLOSE_CHARACTER = ">",

	-- @Description: Character used to terminate a tag (broken)
	-- @Default: "/"
	--TAG_TERMINATE_CHARACTER = "/",

	-- @Description: Character used to open an attribute within a tag
	-- @Default: "["
	ATTRIBUTE_OPEN_CHARACTER = "[",

	-- @Description: Character used to close an attribute
	-- @Default: "]"
	ATTRIBUTE_CLOSE_CHARACTER = "]",

	-- @Description: Character used to seperate the tag's type and the tag's value (broken)
	-- @Default: "="
	--FORMAT_CHARACTER = "=",

	Constants = {
		Chroma = "#ff0000, #ffff00, #00ff00, #00ffff, #0000ff, #ff00ff",
		Breathe = "<delay Length=[2] Type=[Character]> </delay>",
	},
}
