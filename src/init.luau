--!strict

-->>--------------------------------------------<<--
-- @Created: September 5th, 2025
-- @Authors: Outbroken

-- @Description:
-- The main typewriter object

-- @License:
-- https://mit-license.org
-->>--------------------------------------------<<--

-- >> Core Services <<

local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

-- >> References : Modules <<

local RichText = require(script.Features.RichText)
local Wrapper = require(script.Features.Wrapper)
local Animator = require(script.Features.Animator)
local Audio = require(script.Features.Audio)

local Signal = require(script.Packages.GoodSignal)

local Styles = {}
for _, styleModule in pairs(script.Features.RichText.Styles:GetChildren()) do
	local style = require(styleModule)
	Styles[style.TagName] = style
end

local Presets = {}
for _, presetModule in pairs(script.Presets:GetChildren()) do
	local preset = require(presetModule)
	Presets[preset.PresetName] = preset
end

-- >> References : Types <<

local _CharacterTypes = require(script.Types)
type CharacterProperties = _CharacterTypes.CharacterProperties
type Character = _CharacterTypes.Character

local _WriterTypes = require(script.Types)
type WriterExitState = _WriterTypes.WriterExitState
type WriterSettings = _WriterTypes.WriterSettings

-- >> Constants <<

local PUNCTUATION_PAUSE_MULTIPLES = {
	["."] = 6, -- 6x slower than the typewriter's base speed
	["?"] = 6,
	["!"] = 3,

	[","] = 4,
	[":"] = 2,
	["'"] = 2,
}

-- >> Variables <<

local currentWriterIndex = 0

-- >> Functions : Utility <<

local function overridePreset(preset, override)
	local overridenPreset = {}

	for propertyName, propertyValue in pairs(preset) do
		overridenPreset[propertyName] = override[propertyName] or propertyValue
	end

	return overridenPreset
end

-- >> Module : Core <<

local Writer = {}
Writer.__index = Writer

export type WriterClass = typeof(setmetatable(
	{} :: {
		onWriterComplete: () -> WriterExitState,
		onFlagActivate: () -> number,
		onDestroy: () -> (),

		_writerThread: thread?,
		_isWriting: boolean,
		_isSkipped: boolean,

		Font: Font,
		FontSize: number,
		Tracking: number,
		Wrapping: boolean,

		WritingSpeed: number,
		PauseOnPunctuation: boolean,
		WritingAnimation: string,

		Container: Instance,
	},
	Writer
))

--[[
	Creates a new Writer!

	```lua
	local myWriter = Typist.new()
	```

	@return WriterClass -- a new writer object
]]
function Writer.new(Preset: WriterPreset): WriterClass
	currentWriterIndex += 1

	return setmetatable({
		-- >> Core <<
		Id = currentWriterIndex,
		Container = nil,

		-- >> Internal / State <<
		_isInitialized = false,
		_isWriting = false,
		_isSkipped = false,
		_isPaused = false,

		-- >> Internal / Objects <<
		_Animator = Animator.new(),

		-- >> Internal <<
		_writerThread = nil,
		_activeCharacters = {},
		_activeTransforms = {},

		_writingStartTime = -1,
		_updateCycle = nil,
		_lastContainerSize = nil,
		_lastContainerResizeTime = -1,

		-- >> Settings <<
		Settings = overridePreset(Presets._default, Presets[Preset] or Presets._default),

		-- >> Callback Events <<
		onWriterComplete = Signal.new(),
		onFlagActivate = Signal.new(),
		onDestroy = Signal.new(),
	}, Writer)
end

--[[
@Overview:
Initializes the writer

@Inputs:
- Container: the object to write into

@Output:
Returns true if the action was successful
]]
function Writer:Init(Container: Instance): boolean
	-- Safety checks
	if typeof(Container) ~= "Instance" then
		warn(`Could not initialize writer! {typeof(Container)} is not a valid container type.`)
		return false
	end
	self.Container = Container

	-- Set up the container
	if not self.Container:FindFirstChild("_Characters") then
		local newCharactersFolder = Instance.new("Folder")
		newCharactersFolder.Name = "_Characters"
		newCharactersFolder.Parent = self.Container
	end

	-- Initialize the update cycle
	self._updateCycle = RunService.RenderStepped:Connect(function(deltaTime: number)
		self:_Update(deltaTime)
	end)

	-- Initialize the audio module
	Audio.Initialize(self)

	self._isInitialized = true
end

-- >> Module : Internal <<

--[[
@Overview:
Called every frame, syncs animations

@Inputs:
- deltaTime: time passed since the last frame
]]
function Writer:_Update(deltaTime: number)
	if os.clock() - self._lastContainerResizeTime > 0.25 and self.Container.AbsoluteSize ~= self._lastContainerSize then
		self:_ContainerResized()
		self._lastContainerResizeTime = os.clock()
		self._lastContainerSize = self.Container.AbsoluteSize
	end

	self._Animator:Update(deltaTime)
end

--[[
@Overview:
Recalcuates transforms to match with the new container size
]]
function Writer:_ContainerResized()
	-- Calculate new transforms
	local newTransforms = Wrapper.CalculateTransforms(self._activeCharacters, {
		FontSize = self.Settings.FontSize,
		Font = self.Settings.Font,
	}, self.Container.AbsoluteSize)

	-- Update already written characters
	for index, character in pairs(self._activeCharacters) do
		if not character.Instance then
			break
		end

		TweenService:Create(
			character.Instance,
			TweenInfo.new(0.15, Enum.EasingStyle.Sine),
			{ Position = newTransforms[index].Position }
		):Play()
	end

	-- Update characters that will be written
	self._activeTransforms = newTransforms
end

--[[
@Description:
Writes a character to the container

@Inputs:
- character: The character to write
- characterTransform: the position data for the character
- skipped: whether the writer is being skipped

@Output:
Returns the newly created character instance
]]
function Writer:_WriteCharacter(character: Character, characterTransform: {}, skipped: boolean): Instance
	local Properties = character.Properties
	local newCharacter = nil

	if character.Properties.Image then
		newCharacter = Instance.new("ImageLabel")
		newCharacter.BackgroundTransparency = 1
		newCharacter.ScaleType = Enum.ScaleType.Fit
		newCharacter.Image = "rbxassetid://" .. character.Properties.Image.Id

		-- Set the remaining static properties
		newCharacter.Size = characterTransform.Size
		newCharacter.Name = characterTransform.AbsoluteIndex
		newCharacter.Parent = self.Container._Characters
	else
		-- Create the character with a few initial settings
		newCharacter = Instance.new("TextLabel")
		newCharacter.BorderSizePixel = 0
		newCharacter.BackgroundTransparency = 1
		newCharacter.TextStrokeColor3 = Color3.new(0, 0, 0)
		newCharacter.TextStrokeTransparency = 1
		newCharacter.TextScaled = true
		newCharacter.TextColor3 = Color3.new(1, 1, 1)
		newCharacter.FontFace = self.Settings.Font
		newCharacter.Text = character.Value

		-- Style Tags
		for styleName, styleContent in pairs(Properties.Styles) do
			Styles[styleName].Apply(newCharacter, styleContent, self._Animator)
		end

		-- Set the remaining static properties
		newCharacter.Size = characterTransform.Size
		newCharacter.Name = characterTransform.AbsoluteIndex
		newCharacter.Parent = self.Container._Characters

		-- Tag: Mood
		if Properties.AnimationName then
			newCharacter.Position = characterTransform.Position
			Animator.PlayMoodAnimation(Properties.AnimationName, newCharacter)

			return newCharacter
		end
	end

	-- If skipped, don't play the write-on animation
	if skipped == true then
		newCharacter.Position = characterTransform.Position
		return newCharacter
	end

	-- Play the write on animation
	self._Animator:addAnimation({
		Object = newCharacter,
		Keyframes = {
			{
				Properties = {
					Position = characterTransform.Position - UDim2.fromOffset(0, newCharacter.Size.Y.Offset / 2),
				},
			},
			{
				Time = 0.15,
				EasingStyle = Enum.EasingStyle.Linear,
				EasingDirection = Enum.EasingDirection.Out,
				Properties = { Position = characterTransform.Position },
			},
		},
	})
	self._Animator:Update(0)
	--[[
	Animator.PlayWriteOnAnimation(
		self.Settings.WritingAnimation,
		newCharacter,
		characterTransform.Position,
		1 / self.Settings.WritingSpeed
	)]]

	return newCharacter
end

-- >> Module : Properties <<

--[[
@Overview:
Safely applies settings to the typewriter

@Inputs:
- Settings <WriterSettings>: the settings to apply
]]
function Writer:ApplySettings(Settings: WriterSettings)
	local errStr = "Could not set property: "
	local wrnStr = "Warning, property: "

	-- Initial
	if typeof(Settings) ~= "table" then
		warn(`Could not apply settings! Please input a valid table.`)
		return
	end

	-- Font
	if Settings.Font then
		if typeof(Settings.Font) == "Font" then
			self.Font = Settings.Font
		else
			warn(`{errStr}Font! Type {typeof(Settings.Font)} given, Type [Font] required.`)
		end
	end

	-- Font Size
	if Settings.FontSize then
		if typeof(Settings.Font) == "number" then
			self.FontSize = Settings.FontSize

			if Settings.FontSize < 0 or Settings.FontSize > 200 then
				warn(`{wrnStr}FontSize [{Settings.Tracking}] is outside of the recommended range (0-200).`)
			end
		else
			warn(`{errStr}FontSize! Type [{typeof(Settings.Font)}] given, Type [number] required.`)
		end
	end

	-- Tracking
	if Settings.Tracking then
		if typeof(Settings.Tracking) == "number" then
			self.Tracking = Settings.Tracking

			if Settings.Tracking < 0 or Settings.Tracking > 2 then
				warn(`{wrnStr}Tracking [{Settings.Tracking}] is outside of the recommended range (0-2).`)
			end
		else
			warn(`{errStr}Tracking! Type [{typeof(Settings.Tracking)}] given, Type [number] required.`)
		end
	end

	-- Line Spacing
	if Settings.LineSpacing then
		if typeof(Settings.LineSpacing) == "number" then
			self.LineSpacing = Settings.LineSpacing

			if Settings.LineSpacing < 0 or Settings.LineSpacing > 2 then
				warn(`{wrnStr}LineSpacing [{Settings.LineSpacing}] is outside of the recommended range (0-2).`)
			end
		else
			warn(`{errStr}LineSpacing! Type [{typeof(Settings.LineSpacing)}] given, Type [number] required.`)
		end
	end

	-- Wrapping
	if Settings.Wrapping ~= nil then
		if typeof(Settings.Wrapping) == "boolean" then
			self.Wrapping = Settings.Wrapping
		else
			warn(`{errStr}Wrapping! Type [{typeof(Settings.Wrapping)}] given, Type [boolean] required.`)
		end
	end

	-- Writing Speed
	if Settings.WritingSpeed then
		if typeof(Settings.WritingSpeed) == "number" then
			self.WritingSpeed = Settings.WritingSpeed

			if Settings.WritingSpeed < 0 or Settings.WritingSpeed > 100 then
				warn(`{wrnStr}WritingSpeed [{Settings.WritingSpeed}] is outside of the recommended range (0-100).`)
			end
		else
			warn(`{errStr}WritingSpeed! Type [{typeof(Settings.WritingSpeed)}] given, Type [number] required.`)
		end
	end

	-- Pause on punctuation
	if Settings.PauseOnPunctuation ~= nil then
		if typeof(Settings.PauseOnPunctuation) == "boolean" then
			self.PauseOnPunctuation = Settings.PauseOnPunctuation
		else
			warn(
				`{errStr}PauseOnPunctuation! Type [{typeof(Settings.PauseOnPunctuation)}] given, Type [boolean] required.`
			)
		end
	end

	-- Writing Animation
	if Settings.WritingAnimation then
		if typeof(Settings.WritingAnimation) == "string" then
			if WritingEffects[Settings.WritingAnimation] then -- BROKEN!!
				self.WritingAnimation = Settings.WritingAnimation
			else
				warn(`{errStr}WritingAnimation! [{Settings.WritingAnimation}] is not a valid animation.`)
			end
		else
			warn(`{errStr}WritingAnimation! Type [{typeof(Settings.WritingAnimation)}] given, Type [string] required.`)
		end
	end
end

-- >> Module : Actions <<

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
function Writer:Write(Text: string): boolean
	-- Safety Checks
	if self._isWriting == true then
		warn("Cannot write while the writer is already writing! Cancel the current process first.")
		return false
	end

	if self._isInitialized == false then
		warn("The writer must be initialized before it can start writing! Call Writer:Init().")
		return false
	end

	if type(Text) ~= "string" then
		warn(`{type(Text)} is not a valid input type! Only strings are accepted.`)
		return false
	end

	-- Clear old text
	if #self._activeCharacters > 0 then
		for _, character in pairs(self._activeCharacters) do
			character.Instance:Destroy()
		end

		self._activeCharacters = {}
		self._activeTransforms = {}
	end

	-- Start writing
	self._isWriting = true
	self._writingStartTime = os.clock()

	self._writerThread = coroutine.create(function()
		-- Parse raw string into character data
		if self.Settings.RichText == true then
			self._activeCharacters = RichText.Enrich(Text)
		else
			self._activeCharacters = RichText.Raw(Text)
		end

		-- Handle wrapping
		self._activeTransforms = Wrapper.CalculateTransforms(self._activeCharacters, {
			FontSize = self.Settings.FontSize,
			Font = self.Settings.Font,
		}, self.Container.AbsoluteSize)

		-- Handle split points
		local splitPoints = {}
		local currentSplitPoint = 1

		for index, character in pairs(self._activeCharacters) do
			if character.Properties.Split == true then
				splitPoints[#splitPoints + 1] = index
			end
		end

		-- Loop through each character
		for characterIndex, character in pairs(self._activeCharacters) do
			-- If paused, yield the thread
			if self._isPaused == true then
				coroutine.yield()
			end

			-- Write the character
			local characterTransform = self._activeTransforms[characterIndex]
			self._activeCharacters[characterIndex].Instance =
				self:_WriteCharacter(character, characterTransform, self._isSkipped)

			-- Handle Flags
			if character.Properties.Flag then
				self.onFlagActivate:Fire(character.Properties.Flag)
			end

			-- Handle Custom Sounds
			local customSound = character.Properties.Sound
			if customSound then
				Audio.playCustomSound(self.Id, customSound.Id, customSound.Volume, customSound.Pitch)
			end

			-- If skipped, ignore the cooldown and move on to the next character immediately
			if self._isSkipped == true then
				-- If the current index is a split point, stop skipping
				if characterIndex == splitPoints[currentSplitPoint] then
					currentSplitPoint += 1
					self._isSkipped = false
				end

				continue
			end

			-- If the delay property exists, override the default waiting
			if character.Properties.DelayType then
				-- If the delay type is Word, skip over non-space characters
				if character.Properties.DelayType == "Word" and character.Value ~= " " then
					continue
				end

				-- If the delay type is IgnoreSpace, skip over space characters
				if character.Properties.DelayType == "IgnoreSpace" and character.Value == " " then
					continue
				end

				-- Play the writing sound
				Audio.playCharacterSound(self.Id)

				-- Wait the delay length
				task.wait(character.Properties.DelayLength)
				continue
			end

			-- Play the writing sound
			Audio.playCharacterSound(self.Id)

			-- Calculate the length of time to wait for
			local baseCooldown = 1 / self.Settings.WritingSpeed
			local cooldownMultiple = 1

			if self.Settings.PauseAfterPunctuation == true then
				cooldownMultiple = PUNCTUATION_PAUSE_MULTIPLES[character.Value] or 1
			end

			-- Wait
			task.wait(baseCooldown * cooldownMultiple)
		end

		-- Reset internal variables
		self._isSkipped = false
		self._isWriting = false

		-- Callback
		if self.onWriterComplete then
			if self._isSkipped then
				self.onWriterComplete:Fire("Skipped")
			else
				self.onWriterComplete:Fire("Success")
			end
		end
	end)
	coroutine.resume(self._writerThread)

	return true
end

--[[
	Cancels the writer's current action
	* The **Writer** must actively be writing in order to be cancelled

	```lua
	myWriter:Write("I'm about to be cancelled!")
	myWriter:Cancel()
	```

	@return boolean -- The **Writer** cancelled without issue
]]
function Writer:Cancel(): boolean
	if self._isWriting == false then
		warn("Can't cancel the writer since it isn't writing! Start it first.")
		return false
	end

	self._isWriting = false
	self._isSkipped = false
	self._isPaused = false

	coroutine.close(self._writerThread)
	return true
end

--[[
	Pauses the writer, halting execution until it is resumed.
	* The **Writer** must actively be writing in order to be paused

	```lua
	myWriter:Write("Oh no! I'm about to be paused!")
	myWriter:Pause()
	```

	@return boolean -- The **Writer** paused without issue
]]
function Writer:Pause(): boolean
	if self._isWriting == false then
		warn("Can't pause the writer since it isn't writing! Start it first.")
		return false
	end

	self._isPaused = true
	return true
end

--[[
	Resumes the **Writer**, continuing execution.
	* The **Writer** must be paused in order to be resumed

	```lua
	myWriter:Write("I'm about to be paused. Though I'm sure I'll be resumed again!")
	myWriter:Pause()
	myWriter:Resume()
	```

	@return boolean -- The **Writer** resumed without issue
]]
function Writer:Resume(): boolean
	if self._isWriting == false then
		warn("Can't resume the writer since it isn't writing! Start it first.")
		return false
	end

	if self._isPaused == false then
		warn("Can't resume the writer since it isn't paused! This call is redundant.")
		return false
	end

	self._isPaused = false
	coroutine.resume(self._writerThread)

	return true
end

--[[
	Ignores the delay, instantly writing all characters.
	* The **Writer** must be writing in order to be skipped

	```lua
	myWriter:Write("I'm going to get skipped.")
	myWriter:Skip()
	```

	Note: If the text contains a *split*, skipping will stop at the next one found.
	```lua
	myWriter:Write("This part will get skipped.<//split> But this part won't.")
	myWriter:Skip()
	```

	@return boolean -- The **Writer** skipped without issue
]]
function Writer:Skip(): boolean
	if self._isWriting == false then
		warn("Can't skip when the writer isn't writing! Start it first.")
		return false
	end

	self._isSkipped = true
	return true
end

--[[
@Description:
Destroys the writer, disconnecting events and cleaning up
]]
function Writer:Destroy()
	self.onDestroy:Fire()

	self.onWriterComplete:Disconnect()
	self.onDestroy:Disconnect()

	setmetatable(self, nil)
	table.clear(self)
end

return Writer
