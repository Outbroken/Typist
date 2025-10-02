--!strict

-->>--------------------------------------------<<--
-- @Created: September 19th, 2025
-- @Authors: Outbroken

-- @Description:
-- Rich Text Style: Bold
-->>--------------------------------------------<<--

-- >> Types <<

type TagContent = { [string]: string }
type StyleProperties = { [string]: any }

-- >> Methods <<

local Style = {}
Style.TagName = "b"

function Style.Add(_: TagContent): StyleProperties
	return { Bold = true }
end

function Style.Apply(character: TextLabel, _: StyleProperties)
	local currentFont = character.FontFace
	currentFont.Weight = Enum.FontWeight.Bold

	character.FontFace = currentFont
end

return Style
