--!strict

-->>--------------------------------------------<<--
-- @Created: September 19th, 2025
-- @Authors: Outbroken

-- @Description:
-- Rich Text Style: Italic
-->>--------------------------------------------<<--

-- >> Types <<

type TagContent = { [string]: string }
type StyleProperties = { [string]: any }

-- >> Methods <<

local Style = {}
Style.TagName = "i"

function Style.Add(_: TagContent): StyleProperties
	return { Italic = true }
end

function Style.Apply(character: TextLabel, _: StyleProperties)
	local currentFont = character.FontFace
	currentFont.Style = Enum.FontStyle.Italic

	character.FontFace = currentFont
end

return Style
