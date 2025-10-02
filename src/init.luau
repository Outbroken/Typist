--!strict

-->>--------------------------------------------<<--
-- @Created: September 5th, 2025
-- @Authors: Outbroken

-- @Description:
-- The main typewriter object

-- @License:
-- https://mit-license.org
-->>--------------------------------------------<<--

-- TODO: Maintain character position in animation while being adjusted for container size

-- >> Core Services <<

local RunService = game:GetService("RunService")

-- >> References : Modules <<

local RichText = require(script.Components.RichText)
local Wrapper = require(script.Components.Wrapper)
local Audio = require(script.Components.Audio)

local Animator = require(script.Components.Animator)
local Signal = require(script.Packages.GoodSignal)

local Presets = {}
for _, presetModule in pairs(script.Presets:GetChildren()) do
	local preset = require(presetModule)
	Presets[preset.PresetName] = preset
end

-- >> References : Types <<

local T_Types = require(script.Types)
type CharacterProperties = T_Types.CharacterProperties
--type Character = T_Types.Character

type WriterExitState = T_Types.WriterExitState
type WriterPreset = T_Types.WriterPreset

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

-- >> Module : Core <<

--[=[
	@class Writer

	The main typewriter class.
]=]
local Writer = {}
Writer.__index = Writer

export type WriterClass = typeof(setmetatable(
	{} :: {
		onWriterComplete: () -> WriterExitState,
		onFlagActivate: () -> number,
		onDestroy: () -> (),

		_Thread: thread?,
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
function Writer.new(): WriterClass
	-- #region OBJ_DOC
	--[=[
		A unique number to identify the Writer.

		@prop Id number
		@within Writer
		@readonly
	]=]

	--[=[
		An internal property that contains the mount state of the Writer.

		@prop _isMounted boolean
		@within Writer
		@private
	]=]

	--[=[
		An internal property that contains the writing state of the Writer.

		@prop _isWriting boolean
		@within Writer
		@private
	]=]

	--[=[
		An internal property that contains the skipping state of the Writer.

		@prop _isSkipped boolean
		@within Writer
		@private
	]=]

	--[=[
		An internal property that contains the pause state of the Writer.

		@prop _isPaused boolean
		@within Writer
		@private
	]=]

	-- #endregion

	currentWriterIndex += 1

	local WriterData = {
		-- >> Core <<
		Id = currentWriterIndex,
		Mount = nil,

		-- >> Internal / State <<
		_isMounted = false,
		_isWriting = false,
		_isSkipped = false,
		_isPaused = false,

		-- >> Internal / Objects <<
		_Animator = Animator.new(),

		-- >> Internal <<
		_Thread = nil,
		_activeCharacters = {},
		_activeTransforms = {},

		_writingStartTime = -1,
		_updateCycle = nil,
		_lastContainerSize = nil,
		_lastContainerResizeTime = -1,

		-- >> Settings <<
		activePreset = Presets._default,

		-- >> Callback Events <<
		onWriterComplete = Signal.new(),
		onFlagActivate = Signal.new(),
		onDestroy = Signal.new(),
	}

	return setmetatable(WriterData, Writer)
end

--[[
@Overview:
Initializes the writer

@Inputs:
- Container: the object to write into

@Output:
Returns true if the action was successful
]]
function Writer:Mount(mount: Instance): boolean
	-- Safety checks
	if typeof(mount) ~= "Instance" then
		warn(`Could not initialize writer! {typeof(mount)} is not a valid container type.`)
		return false
	end
	self.Mount = mount

	-- Set up the container
	if not self.Mount:FindFirstChild("_Characters") then
		local newCharactersFolder = Instance.new("Folder")
		newCharactersFolder.Name = "_Characters"
		newCharactersFolder.Parent = self.Mount
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
	if os.clock() - self._lastContainerResizeTime > 0.25 and self.Mount.AbsoluteSize ~= self._lastContainerSize then
		self:_ContainerResized()
		self._lastContainerResizeTime = os.clock()
		self._lastContainerSize = self.Mount.AbsoluteSize
	end

	if not self._isPaused then
		self._Animator:Update(deltaTime)
	end
end

--[[
@Overview:
Recalcuates transforms to match with the new container size
]]
function Writer:_ContainerResized()
	-- Calculate new transforms
	local newTransforms = Wrapper.CalculateTransforms(self._activeCharacters, self.Mount, self.activePreset)

	-- Update already written characters
	for index, character in pairs(self._activeCharacters) do
		if not character.Model then
			continue
		end

		character.Transform = newTransforms[index]
		character:UpdatePosition(self._Animator, newTransforms[index])

		--[[
		TweenService:Create(
			character.Instance,
			TweenInfo.new(0.15, Enum.EasingStyle.Sine),
			{ Position = newTransforms[index].Position }
		):Play()]]
	end

	--self._Animator:Update(0)

	self._activeTransforms = newTransforms
end

-- >> Module : Properties <<

--[=[
	Loads a **Preset** to the writer.

	@param Preset WriterPreset -- The preset to load
	@param Overwrite boolean -- If true, overrides the current preset instead
]=]
function Writer:LoadPreset(Preset: WriterPreset, Overwrite: boolean)
	-- The preset to use as a fallback for missing values
	local basePreset = Presets._default

	-- If overwrite is true, overwrite the current preset instead of the default
	if Overwrite then
		basePreset = self.activePreset
	end

	-- Load the preset
	for currentProperty, currentValue in pairs(basePreset) do
		self.activePreset[currentProperty] = Preset[currentProperty] or currentValue
	end
end

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
function Writer:Write(text: string): boolean
	-- Safety Checks
	if self._isWriting == true then
		warn("Cannot write while the writer is already writing! Cancel the current process first.")
		return false
	end

	if self._isInitialized == false then
		warn("The writer must be initialized before it can start writing! Call Writer:Init().")
		return false
	end

	if type(text) ~= "string" then
		warn(`{type(text)} is not a valid input type! Only strings are accepted.`)
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

	-- Reset Animator
	self._Animator:Reset()

	-- Start writing
	self._isWriting = true
	self._writingStartTime = os.clock()

	self._Thread = coroutine.create(function()
		-- Parse raw string into character data
		if self.activePreset.RichText == true then
			self._activeCharacters = RichText.Enrich(text)
		else
			self._activeCharacters = RichText.Raw(text)
		end

		-- Handle wrapping
		self._activeTransforms = Wrapper.CalculateTransforms(self._activeCharacters, self.Mount, self.activePreset)

		-- Handle split points
		local splitPoints = {}
		local currentSplitPoint = 1

		for index, character in pairs(self._activeCharacters) do
			if character.Properties.Split == true then
				splitPoints[#splitPoints + 1] = index
			end
		end

		local function calculateWaitLength(character, delayType, delayLength)
			if delayType then
				if delayType == "Word" and character ~= " " then
					return 0
				end

				if delayType == "IgnoreSpace" and character == " " then
					return 0
				end

				return delayLength
			end

			local baseCooldown = 1 / self.activePreset.WritingSpeed
			local cooldownMultiple = 1

			if self.activePreset.PauseAfterPunctuation == true then
				cooldownMultiple = PUNCTUATION_PAUSE_MULTIPLES[character.Value] or 1
			end

			return baseCooldown * cooldownMultiple
		end

		-- Loop through each character
		for characterIndex, character in pairs(self._activeCharacters) do
			-- If paused, yield the thread
			if self._isPaused == true then
				coroutine.yield()
			end

			-- Write the character
			character.Transform = self._activeTransforms[characterIndex]
			character:Write(self.Mount, self._Animator, self._isSkipped)

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

				-- Calculate skipped time and progress the animator by that amount
				self._Animator:Update(
					calculateWaitLength(
						character.Value,
						character.Properties.DelayType,
						character.Properties.DelayLength
					)
				)

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
			local baseCooldown = 1 / self.activePreset.WritingSpeed
			local cooldownMultiple = 1

			if self.activePreset.PauseAfterPunctuation == true then
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
	coroutine.resume(self._Thread)

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

	coroutine.close(self._Thread)
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
	coroutine.resume(self._Thread)

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

function Writer:GetStatus()
	return {
		Mounted = self._isMounted,
		Writing = self._isWriting,
		Skipped = self._isSkipped,
		Paused = self._isPaused,
	}
end

return Writer
