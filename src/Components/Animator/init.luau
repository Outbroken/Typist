--!strict

-->>--------------------------------------------<<--
-- @Created: September 10th, 2025
-- @Authors: Outbroken

-- @Description:
-- Animation module with sequencing and more robust timing
-->>--------------------------------------------<<--

-- TODO: Anchor size like position is currently so it can be processed relatively

-- >> Core Services <<

local TweenService = game:GetService("TweenService")

-- >> References : Modules

local Oklab = require(script.Oklab)

local Animations = {}
for _, animationModule in pairs(script.Animations:GetChildren()) do
	local animation = require(animationModule)
	Animations[animationModule.Name] = animation
end

-- >> Functions <<

local function interpolateKeyframes(keyframe1, keyframe2, time: number)
	local interpolatedProperties = {}

	for propertyName, propertyValue1 in pairs(keyframe1.Properties) do
		local propertyValue2 = keyframe2.Properties[propertyName]

		if typeof(propertyValue2) == "Color3" then
			interpolatedProperties[propertyName] = Oklab(propertyValue1, propertyValue2, time)
		elseif typeof(propertyValue2) == "UDim2" then
			interpolatedProperties[propertyName] = propertyValue1:Lerp(propertyValue2, time)
		elseif typeof(propertyValue2) == "number" then
			interpolatedProperties[propertyName] = math.lerp(propertyValue1, propertyValue2, time)
		else
			if time < 0.5 then
				interpolatedProperties[propertyName] = propertyValue1
			else
				interpolatedProperties[propertyName] = propertyValue2
			end
		end
	end

	return interpolatedProperties
end

local function getAnimationFrame(keyframes: {}, animationTime: number): {}
	-- Before the first keyframe
	if animationTime <= keyframes[1].Time then
		return keyframes[1].Properties
	end

	-- After the last keyframe
	if animationTime >= keyframes[#keyframes].Time then
		return keyframes[#keyframes].Properties
	end

	-- Find the two keyframes time falls between
	for index = 1, #keyframes - 1, 1 do
		local keyframe1 = keyframes[index]
		local keyframe2 = keyframes[index + 1]

		if animationTime >= keyframe1.Time and animationTime <= keyframe2.Time then
			local t = (animationTime - keyframe1.Time) / (keyframe2.Time - keyframe1.Time)
			local easedTime = TweenService:GetValue(t, keyframe2.EasingStyle, keyframe2.EasingDirection)
			return interpolateKeyframes(keyframe1, keyframe2, easedTime)
		end
	end
end

-- >> Module <<

local Animator = {}
Animator.__index = Animator

function Animator.new()
	return setmetatable({
		_activeAnimations = {},
		currentTime = 0,
	}, Animator)
end

function Animator:AddAnimation(animation: {})
	local newAnimation = animation
	newAnimation.CreationTime = self.currentTime
	newAnimation.Anchor = animation.Anchor or {}

	-- Substitute fallback values if needed
	local newKeyframes = {}
	for index, keyframe in pairs(newAnimation.Keyframes) do
		newKeyframes[index] = {
			Time = keyframe.Time or 0,
			EasingStyle = keyframe.EasingStyle or Enum.EasingStyle.Linear,
			EasingDirection = keyframe.EasingType or Enum.EasingDirection.In,
			Properties = keyframe.Properties or {},
		}
	end

	newAnimation.Keyframes = newKeyframes
	self._activeAnimations[#self._activeAnimations + 1] = newAnimation
end

function Animator:Reset()
	self._activeAnimations = {}
	self.currentTime = 0
end

function Animator:Update(deltaTime: number)
	self.currentTime += deltaTime

	for index, animation in pairs(self._activeAnimations) do
		local object = animation.Object
		local Keyframes = animation.Keyframes
		local creationTime = animation.CreationTime

		local animationTime = self.currentTime - creationTime

		if animationTime - deltaTime > Keyframes[#Keyframes].Time then
			if animation.Repeat == true then
				-- hack: adds the animation length to the creation time, so it's like if the animation has just begun
				self._activeAnimations[index].CreationTime += Keyframes[#Keyframes].Time
			else
				self._activeAnimations[index] = nil
				continue
			end
		end

		local currentProperties = getAnimationFrame(Keyframes, animationTime)

		for propertyName, propertyValue in pairs(currentProperties) do
			if propertyName == "Position" and animation.Anchor.Position then
				object.Position = animation.Anchor.Position + propertyValue
			elseif propertyName == "Size" and animation.Anchor.Size then
				local anchorSize = animation.Anchor.Size
				object.Size = UDim2.new(
					anchorSize.X.Scale,
					anchorSize.X.Offset * propertyValue,
					anchorSize.Y.Scale,
					anchorSize.Y.Offset * propertyValue
				)
			else
				object[propertyName] = propertyValue
			end
		end
	end
end

function Animator:LazyUpdate(deltaTime: number)
	self.currentTime += deltaTime
end

function Animator:PlayAnimation(animationName: string, ...)
	self:AddAnimation(Animations[animationName](...))
end

function Animator:AnchorObject(object, newAnchor)
	for index, animation in pairs(self._activeAnimations) do
		if animation.Object == object then
			if animation.Anchor.Position then
				self._activeAnimations[index].Anchor.Position = newAnchor.Position
			elseif animation.Anchor.Size then
				self._activeAnimations[index].Anchor.Size = newAnchor.Size
			end

			return true
		end
	end

	return false
end

function Animator:Destroy()
	setmetatable(self, nil)
	table.clear(self)
end

return Animator
