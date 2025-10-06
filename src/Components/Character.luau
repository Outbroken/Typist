--!strict

-->>--------------------------------------------<<--
-- @Created: September 30th, 2025
-- @Authors: Outbroken

-- @Description:
-- A class that represents a character
-->>--------------------------------------------<<--

-- >> Core Services <<

local TweenService = game:GetService("TweenService")

-- >> References : Modules

local Styles = {}
for _, styleModule: ModuleScript in pairs(script.Parent.RichText.Styles:GetChildren()) do
	local style = require(styleModule) :: { TagName: string }
	Styles[style.TagName] = style
end

-- >> Types <<

local _Types = require(script.Parent.Parent.Types)
type WriterPreset = _Types.WriterPreset
type CharacterProperties = _Types.CharacterProperties
type CharacterTransform = _Types.CharacterTransform

-- >> Module <<

local Character = {}
Character.__index = Character

export type CharacterClass = typeof(setmetatable(
	{} :: {
		Value: string,
		Properties: CharacterProperties | {},
		Transform: CharacterTransform | {},
		Model: Instance?,
	},
	Character
))

--[[
	Creates a new character
]]
function Character.new(): CharacterClass
	return setmetatable({
		Value = "",
		Properties = {},
		Transform = {},
		Model = nil,
	}, Character)
end

--[[
	Writes a character to the mount
]]
function Character:Write(mount: GuiObject, animator: {}, activePreset: WriterPreset, Skipped: boolean)
	local newModel = Instance.new("TextLabel")

	-- Create the character with initial settings
	newModel.BorderSizePixel = 0
	newModel.BackgroundTransparency = 1
	newModel.BackgroundColor3 = Color3.new(0, 0, 0)
	newModel.TextStrokeColor3 = Color3.new(0, 0, 0)
	newModel.TextStrokeTransparency = 0.6
	newModel.TextScaled = true
	newModel.TextColor3 = Color3.new(1, 1, 1)
	newModel.FontFace = activePreset.Font
	newModel.Text = self.Value

	-- Set the remaining static properties
	newModel.Position = self.Transform.Position
	newModel.Size = self.Transform.Size

	-- Apply styles
	for styleName, styleContent in pairs(self.Properties.Styles) do
		Styles[styleName].Apply(newModel, styleContent, animator, self.Transform.Position)
	end

	-- Parent the model
	newModel.Name = self.Transform.AbsoluteIndex
	newModel.Parent = mount._Characters
	self.Model = newModel

	-- If we are not skipping, play the writing animation
	if Skipped == true then
		return
	end

	animator:PlayAnimation(activePreset.WritingAnimation, newModel, self.Transform.Position)
	animator:Update(0)
end

--[[
	Updates the transform of a character, adjusting position and size
]]
function Character:UpdateTransform(newTransform: CharacterTransform, animator)
	-- Reanchor the object for animations
	animator:AnchorObject(self.Model, {
		Position = newTransform.Position,
		Size = newTransform.Size,
	})

	-- Tween the values that changed
	local transitionData = {}
	if self.Transform.Position ~= newTransform.Position then
		transitionData.Position = newTransform.Position
	end
	if self.Transform.Size ~= newTransform.Size then
		transitionData.Size = newTransform.Size
	end

	self.Transform = newTransform
	TweenService:Create(self.Model, TweenInfo.new(0.15, Enum.EasingStyle.Sine), transitionData):Play()
end

--[[
	Destroys a character, cleaning up
]]
function Character:Destroy()
	if self.Model then
		self.Model:Destroy()
	end

	table.clear(self)
	setmetatable(self, nil)
end

return Character
