--[[
@Description:
Handles animation for the typewriter

@Created: 9/10/25
@Modified: 9/10/25
]]

-- >> Core Services <<

local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

-- >> References : Modules

local Styles = {}
for _, styleModule: ModuleScript in pairs(script.Parent.RichText.Styles:GetChildren()) do
	local style = require(styleModule) :: { TagName: string }
	Styles[style.TagName] = style
end

-- >> Types <<

local _Types = require(script.Parent.Parent.Types)

-- >> Functions <<

-- >> Module <<

local Character = {}
Character.__index = Character

function Character.new()
	return setmetatable({
		Value = "",
		Properties = {},
		Transform = {},
		Model = nil,
	}, Character)
end

function Character:Write(Mount, Animator, Skipped)
	local newModel = Instance.new("TextLabel")

	-- Create the character with a few initial settings
	newModel.BorderSizePixel = 0
	newModel.BackgroundTransparency = 1
	newModel.TextStrokeColor3 = Color3.new(0, 0, 0)
	newModel.TextStrokeTransparency = 1
	newModel.TextScaled = true
	newModel.TextColor3 = Color3.new(1, 1, 1)
	newModel.FontFace = Font.new("rbxasset://fonts/families/RobotoMono.json")
	newModel.Text = self.Value

	-- Set the remaining static properties
	newModel.Position = self.Transform.Position
	newModel.Size = self.Transform.Size

	-- Style Tags
	for styleName, styleContent in pairs(self.Properties.Styles) do
		Styles[styleName].Apply(newModel, styleContent, Animator, self.Transform.Position)
	end

	newModel.Name = self.Transform.AbsoluteIndex
	newModel.Parent = Mount._Characters

	self.Model = newModel

	if Skipped == true then
		return
	end

	Animator:PlayAnimation("Writer_Flow", newModel, self.Transform.Position)
	Animator:Update(0)
end

function Character:UpdatePosition(Animator)
	if Animator:AnchorObject(self.Model, self.Transform.Position) == false then
		TweenService:Create(self.Model, TweenInfo.new(0.15, Enum.EasingStyle.Sine), {
			Position = self.Transform.Position,
			Size = self.Transform.Size,
		}):Play()
	else
		TweenService:Create(self.Model, TweenInfo.new(0.15, Enum.EasingStyle.Sine), {
			Size = self.Transform.Size,
		}):Play()
	end
end

return Character
