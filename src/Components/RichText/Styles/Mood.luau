--!strict

-->>--------------------------------------------<<--
-- @Created: September 29th, 2025
-- @Authors: Outbroken

-- @Description:
-- Rich Text Style: Mood
-->>--------------------------------------------<<--

-- >> Types <<

type TagContent = { [string]: string }
type StyleProperties = { [string]: any }

-- >> Methods <<

local Style = {}
Style.TagName = "mood"

function Style.Add(tagContent: TagContent): StyleProperties
	local styleProperties = {}

	if tagContent.Name then
		styleProperties.Mood = tagContent.Name
	end

	return styleProperties
end

function Style.Apply(character: TextLabel, styleProperties: StyleProperties, Animator: {})
	Animator:PlayAnimation("Mood_" .. styleProperties.Mood, character)
end

return Style
