--!strict

-->>--------------------------------------------<<--
-- @Created: September 6th, 2025
-- @Authors: Outbroken

-- @Description:
-- Converts strings into rich character data
-->>--------------------------------------------<<--

-- >> References : Modules <<

local Config = require(script.Config)
local Stack = require(script.Parent.Parent.Packages.Stack)

local Styles = {}
for _, styleModule: ModuleScript in pairs(script.Styles:GetChildren()) do
	local style = require(styleModule) :: { TagName: string }
	Styles[style.TagName] = style
end

-- >> Types <<

local _Types = require(script.Parent.Parent.Types)
type Character = _Types.Character
type CharacterProperties = _Types.CharacterProperties

type Token = _Types.Token
type TagToken = _Types.TagToken
type TextToken = _Types.TextToken

-- >> Functions : Utility <<

-- The function used for deep cloning a table

--[[
@Reference: https://create.roblox.com/docs/luau/tables#deep-clones

@Description:
Clones a table and its sub-tables
]]
local function deepClone(original: { any }): {}
	-- Define the new table for the copy
	local clone = table.clone(original)

	-- Loop through the original table to check for table values
	-- If a table is found as a value, deep clone it to the key (index)
	for key, value in original do
		if typeof(value) == "table" then
			clone[key] = deepClone(value)
		end
	end

	-- Return the finalized copy of the deep cloned table
	return clone
end

--[[
@Description:
Converts an HSV color into an RGB color
]]
local function HSVToRGB(h: number, s: number, v: number): { number }
	s = s / 100
	v = v / 100

	local c = v * s
	local h_sector = h / 60
	local x = c * (1 - math.abs(h_sector % 2 - 1))

	local r = nil
	local g = nil
	local b = nil

	if h_sector < 1 then
		r, g, b = c, x, 0
	elseif h_sector < 2 then
		r, g, b = x, c, 0
	elseif h_sector < 3 then
		r, g, b = 0, c, x
	elseif h_sector < 4 then
		r, g, b = 0, x, c
	elseif h_sector < 5 then
		r, g, b = x, 0, c
	else
		r, g, b = c, 0, x
	end

	local m = v - c
	r = math.floor((r + m) * 255 + 0.5)
	g = math.floor((g + m) * 255 + 0.5)
	b = math.floor((b + m) * 255 + 0.5)

	return { r, g, b }
end

-- >> Functions : Parsing <<

--[[
@Reference: https://devforum.roblox.com/t/writing-your-own-rich-text-system/3460917

@Description:
Reads a tag, converting a string into a table of values

@Inputs:
- Tag <string>: a tag string (ex: "")

@Output:
<Tag?> a token with data about the tag
]]
local function readTag(Tag: string): Token?
	-- * "<" Matches the opening angle bracket
	-- * "%s*" Matches zero or more whitespace characters
	-- * "/?/?" Matches up to two slashes
	-- * "%a+" Matches one or more letters: the tag's name
	-- * "(.-)" Captures as little as possible: the tag's attributes
	-- * "%s*" Matches trailing whitespace inside the tag
	-- * ">" Matches the closing angle bracket
	local ValidTag = string.match(Tag, "<%s*/?/?%a+(.-)%s*>")

	-- If no match is found, the tag's syntax is invalid
	if not ValidTag then
		warn(`Parsed Tag ({Tag}) could not be read: Invalid tag syntax.`)
		return
	end

	-- While an attribute stills exists, check it
	while #ValidTag > 0 do
		-- * "^" Anchors the match to the start of the line
		-- * "%s+" Matches one or more whitespace characters at the start
		-- * "%a+" Matches one or more letters: the attribute's name
		-- * "%s*" Matches optional whitespace after the attribute's name
		-- * "=" Matches a literal equals sign: setting the attribute
		-- * "%s* Matches optional whitespace after the "="
		-- * "%[.-%] Matches anything inside square brackets: the content of the attribute
		local Expression = "^%s+%a+%s*=%s*%[.-%]"
		local Attribute = string.match(ValidTag, Expression)

		-- Tag is invalid, there is a syntax error with its attributes
		if not Attribute then
			warn(`Parsed Tag ({Tag}) could not be read: Invalid attribute syntax.`)
			return
		end

		-- Remove the current attribute from the tag so the next can be checked
		ValidTag = string.sub(ValidTag, #Attribute + 1, -1)
	end

	-- Strip away the first(<) and last(>) character
	Tag = string.sub(Tag, 2, -2)

	-- Get the chunk of the tag with the name in it, ex: "//TagName"
	-- * "^" Anchors the match to the start of the line
	-- * "%s*" Matchez zero or more whitespace characters
	-- * "/?/?" Matches up to two slashes
	-- * "%a+" Matches one or more letters: the tag's name
	-- * "%s*" Matches optional whitespace after the tag's name
	local NameChunk = string.match(Tag, "^%s*/?/?%a+%s*") or ""
	local Opening = string.find(NameChunk, "/") == nil -- If there is no forward slash, it is an opening tag
	local Action = string.find(NameChunk, "//") ~= nil -- If there is a double forward slash, it is an action tag
	local Name = string.gsub(NameChunk, "[%s/]", "") -- Remove all whitespace and forward slashes to leave only the tag's name

	-- The rest of the tag contains the attributes
	local AttributesChunk = string.sub(Tag, #NameChunk + 1, -1)
	local Content = {} -- Create an empty table to contain the attribute content of the tag

	-- Loop over each attribute by matching the pattern of an attribute repeatedly through gmatch
	-- * "%a+" Matches one or more letters: the attribute's name
	-- * "%s*" Matches optional whitespace after the attribute's name
	-- * "=" Matches a literal equals sign: setting the attribute
	-- * "%s* Matches optional whitespace after the "="
	-- * "%[.-%] Matches anything inside square brackets: the content of the attribute
	for Attribute in string.gmatch(AttributesChunk, "%a+%s*=%s*%[.-%]") do
		-- Split the attribute into it's name and it's content
		local attributeName, attributeContent = table.unpack(string.split(Attribute, "="))
		attributeContent = string.sub(attributeContent, 2, -2) -- Remove the "[ ]" around the attribute's content
		Content[attributeName] = attributeContent -- Add attribute to content table
	end

	-- Build a Tag Token and return it
	return {
		Type = "TAG",
		Name = Name,
		Opening = Opening,
		Action = Action,
		Content = Content,
	}
end

--[[
@Source: https://devforum.roblox.com/t/writing-your-own-rich-text-system/3460917

@Description:
Parses a string for tags

@Inputs:
- Input <string>: the input string to parse

@Output:
<Tag[]> a list with tag data
]]
local function parseText(Input: string): { Token }
	-- Tells the parser which characters to check for a tag within
	local TagExpression = "%" .. Config.TAG_OPEN_CHARACTER .. ".-%" .. Config.TAG_CLOSE_CHARACTER

	-- Substitute all constants
	for constantString: string, subString in pairs(Config.Constants) do
		Input = string.gsub(Input, "%%" .. constantString .. "%%", subString)
	end

	-- To make things easier, replace all instances of rgb and hsv with hex
	Input = string.gsub(Input, "rgb%(.-%)", function(match: string)
		local rgb = string.split(string.sub(match, 5, #match - 1), ", ")
		return string.format("#%02x%02x%02x", tonumber(rgb[1]) or 0, tonumber(rgb[2]) or 0, tonumber(rgb[3]) or 0)
	end)

	Input = string.gsub(Input, "hsv%(.-%)", function(match: string)
		local hsv = string.split(string.sub(match, 5, #match - 1), ", ")
		local rgb = HSVToRGB(tonumber(hsv[1]) or 0, tonumber(hsv[2]) or 0, tonumber(hsv[3]) or 0)
		return string.format("#%02x%02x%02x", rgb[1], rgb[2], rgb[3])
	end)

	-- A list of found tags
	local Tokens: { Token } = {}

	while #Input > 0 do
		local TagStart, TagEnd = string.find(Input, TagExpression) -- Using the simple pattern to find tags.

		-- If there is no tag, process the rest of the string
		-- If there is a tag, and it is at the beginning, process it
		-- If there is a tag, but it is not at the beginning, process up until the tag
		local ProcessingTag = TagStart == 1
		local ChunkEnd = ProcessingTag and TagEnd or TagStart and TagStart - 1 or #Input

		local Chunk = string.sub(Input, 1, ChunkEnd) -- Separate the chunk

		if ProcessingTag then -- We are processing a tag
			table.insert(Tokens, readTag(Chunk) or {
				Type = "TEXT",
				Content = Chunk,
			})
		else -- We are processing text, just create a token with the content being the raw text
			table.insert(Tokens, {
				Type = "TEXT",
				Content = Chunk,
			})
		end

		Input = string.sub(Input, ChunkEnd + 1, -1) -- Remove the chunk we processed
	end

	return Tokens
end

--[[
@Source: https://devforum.roblox.com/t/writing-your-own-rich-text-system/3460917

@Description:
Validates a set of tokens

@Inputs:
- Tokens <Tag[]>: a set of tokens to

@Output:
<boolean> true if no errors were found
]]
local function validateTokens(Tokens: { TagToken }): boolean
	local tagPrefix = Config.TAG_OPEN_CHARACTER .. "/"
	local tagSuffix = Config.TAG_CLOSE_CHARACTER

	local Tags = Stack.new()

	for _, Token in Tokens do
		if Token.Type ~= "TAG" then
			continue
		end -- We only care about tags for this validation

		if Token.Opening then
			Tags:Push(Token.Name) -- If it is an opening tag, push it to the stack
		else
			if next(Token.Content) ~= nil then
				warn(
					`Warning, attributes defined for closing tag ({Token.Name}), please define attributes in opening tag instead.`
				)
			end

			local Top = Tags:Pop() -- Remove tag from top of stack
			if Top ~= Token.Name then -- Tag name mismatch
				-- Output expected and recieved name of tag for debugging
				warn(
					`Invalid nesting of Tags. Expected {tagPrefix}{Top}{tagSuffix}, got {tagPrefix}{Token.Name}{tagSuffix}.`
				)
				return false -- Invalidate tokens
			end
		end
	end

	if not Tags:Empty() then -- If not all tags were closed
		for _, Tag: Tag in Tags do
			warn(`Missing closing tag: {tagPrefix}{Tag}{Config.TAG_CLOSE_CHARACTER}`) -- Output their name for debugging
		end
		return false -- Invalidate tokens
	end

	return true -- No validation issues found
end

local function addAction(tagData: TagToken, currentActions: {}): {}
	local newActions = currentActions

	local tagName = tagData.Name
	local tagContent = tagData.Content

	if tagName == "flag" then
		newActions.Flag = tonumber(tagContent.Id)
	elseif tagName == "split" then
		newActions.Split = true
	elseif tagName == "image" then
		newActions.Image = {
			Id = tagContent.Id,
		}
	elseif tagName == "sound" then
		newActions.Sound = {
			Id = tagContent.Id,
			Volume = tagContent.Volume,
			Pitch = tagContent.Pitch,
		}
	end

	return newActions
end

local function removeTag(tagData: TagToken, currentProperties: CharacterProperties): CharacterProperties
	local newProperties = currentProperties
	local tagName = tagData.Name

	-- Style Tag
	local Style = Styles[tagName]
	if Style then
		newProperties.Styles[Style.TagName] = nil
		return newProperties
	end

	-- Other Tags
	if tagName == "size" then
		newProperties.Size = nil
		newProperties.SizingType = nil
	elseif tagName == "delay" then
		newProperties.DelayLength = nil
		newProperties.DelayType = nil
	elseif tagName == "animate" then
		newProperties.AnimationName = nil
	else
		warn(`Unknown Tag: {Config.TAG_OPEN_CHARACTER}/{tagName}{Config.TAG_CLOSE_CHARACTER}!`)
	end

	return newProperties
end

--[[
@Description:
Processes a tag, adding it to the currently active properties

@Inputs:
- currentProperties <CharacterProperties>: currently active properties
- tagData <Tag>: a tag to process

@Output:
<CharacterProperties> a new set of properties, with the tag applied
]]
local function addTag(tagData: TagToken, currentProperties: CharacterProperties): CharacterProperties
	local newProperties = currentProperties
	local tagName = tagData.Name
	local tagContent = tagData.Content

	-- Style Tags
	local Style = Styles[tagName]
	if Style then
		newProperties.Styles[Style.TagName] = Style.Add(tagContent)
		return newProperties
	end

	-- Other Tags
	if tagName == "size" then
		local terminatingCharacter = string.sub(tagContent.Size, #tagContent.Size, #tagContent.Size - 1)

		if terminatingCharacter == "%" then
			newProperties.Size = tonumber(string.sub(tagContent.Size, 1, #tagContent.Size - 1))
			newProperties.SizingType = "RELATIVE"
		else
			newProperties.Size = tonumber(tagContent.Size)
			newProperties.SizingType = "ABSOLUTE"
		end
	elseif tagName == "delay" then
		newProperties.DelayLength = tonumber(tagContent.Length) or 0.5
		newProperties.DelayType = tagContent.Type or "IgnoreSpace"
	elseif tagName == "animate" then
		if tagContent.Name then
			newProperties.AnimationName = tagContent.Name
		end
	else
		warn(`Unknown Tag: {Config.TAG_OPEN_CHARACTER}{tagName}{Config.TAG_CLOSE_CHARACTER}!`)
	end

	return newProperties
end

--[[
@Description:
Processes a set of tokens, generating a list of rich characters from it

@Inputs:
- Tokens <Tag[]>: a set of tokens to apply

@Output:
<Character[]> a list of rich characters
]]
local function processTokens(Tokens: { Token }): { Character }
	local Characters: { Character } = {}

	-- Properties that apply to every character until the tag is closed
	local currentProperties = { Styles = {} }

	-- Properties that apply once to the next valid character
	local Actions = {}

	-- Loop through each token
	for _, token in pairs(Tokens) do
		if token.Type == "TAG" then
			-- The token is a tag
			if token.Action == true then
				-- Action tag, add the action
				Actions = addAction(token, Actions)
			else
				-- Regular tag, add or remove the tag depending on whether it is open or closed
				if token.Opening == true then
					currentProperties = addTag(token, currentProperties)
				else
					currentProperties = removeTag(token, currentProperties)
				end
			end
		elseif token.Type == "TEXT" then
			-- The token is text, split the content into a table of characters
			local newCharacters = string.split(token.Content, "")

			-- Index of the character an action will apply to
			local actionCharacter = #Characters + 1

			-- Apply properties to every character
			for _, character in pairs(newCharacters) do
				Characters[#Characters + 1] = {
					Value = character,
					Properties = deepClone(currentProperties),
				}
			end

			-- Determine if an action exists within the action table
			local actionExists = false
			for _, _ in pairs(Actions) do
				actionExists = true
				break
			end

			-- If so, merge the action's properties into the character's properties
			if actionExists then
				for propertyName, propertyValue in pairs(Actions) do
					Characters[actionCharacter].Properties[propertyName] = propertyValue
				end

				Actions = {}
			end
		end
	end

	return Characters
end

-- >> Module <<

local RichText = {}

--[[
	Writes a string of text to the screen.
	* The input will be parsed automatically
	* Proper syntax can be found [here]()

	```lua
	myWriter:Write("Hello, World! I'm <b>Bold!</b>")
	```

	@param Text string -- Text for the writer to write, parsed by default.
	@return boolean -- Writer successfully started writing
]]
function RichText.Enrich(Text: string): { Character }
	local tokens = parseText(Text)

	if Config.STRICT_PARSING and not validateTokens(tokens) then
		warn("Could not validate Tokens!")
		return {}
	end

	return processTokens(tokens)
end

function RichText.Derich(Characters: { Character }): string
	local derichedText = ""

	for _, character in pairs(Characters) do
		derichedText ..= character.Value
	end

	return derichedText
end

function RichText.Raw(Text: string): { Character }
	local Characters = string.split(Text, "")
	local newCharacters = {}

	for _, character in pairs(Characters) do
		newCharacters[#newCharacters + 1] = {
			Value = character,
			Properties = { Styles = {} },
		}
	end

	return newCharacters
end

return RichText
