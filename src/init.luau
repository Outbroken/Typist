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

local RunService = game:GetService("RunService")

-- >> References : Modules <<

local RichText = require(script.Components.RichText)
local Wrapper = require(script.Components.Wrapper)

local Animator = require(script.Components.Animator)
local SoundPlayer = require(script.Components.SoundPlayer)
local Character = require(script.Components.Character)

local Signal = require(script.Packages.GoodSignal)

local Presets = {}
for _, presetModule in pairs(script.Presets:GetChildren()) do
	local preset = require(presetModule)
	Presets[preset.PresetName] = preset
end

-- >> References : Types <<

local Types = require(script.Types)

type WriterExitState = Types.WriterExitState
type WriterPreset = Types.WriterPreset
type WriterState = Types.WriterState

type CharacterClass = Character.CharacterClass
type CharacterTransform = Types.CharacterTransform

type SoundPlayerClass = SoundPlayer.SoundPlayerClass

-- >> Constants <<

-- If PauseOnPunctuation is active, multiply the delay of a character by this amount:
local PUNCTUATION_PAUSE_MULTIPLES = {
	["."] = 6,
	["?"] = 6,
	["!"] = 6,

	[","] = 4,
	[":"] = 2,
	["'"] = 2,
}

-- >> Variables <<

local _currentWriterIndex = 0

-- >> Functions : Utility <<

--[[
	Updates a writer's mount, recalculating transforms and updating positions
]]
local function updateMount(writer)
	-- Calculate new transforms
	local newTransforms = Wrapper(writer._activeCharacters, writer.Mount, writer.activePreset)

	-- Update already written characters
	for index, character in pairs(writer._activeCharacters) do
		if not character.Model then
			continue
		end

		character:UpdateTransform(newTransforms[index], writer._Animator)
	end

	writer._activeTransforms = newTransforms
end

--[[
	Updates a writer, updating animations and mounts
]]
local function updateWriter(writer, deltaTime: number)
	if
		os.clock() - writer._lastContainerResizeTime > 0.25
		and writer.Mount.AbsoluteSize ~= writer._lastContainerSize
	then
		updateMount(writer)
		writer._lastContainerResizeTime = os.clock()
		writer._lastContainerSize = writer.Mount.AbsoluteSize
	end

	if not writer._Paused then
		writer._Animator:Update(deltaTime)
	end
end

-- >> Module : Core <<

--[=[
	@class Writer

	The main typewriter class.
]=]
local Writer = {}
Writer.__index = Writer

export type WriterClass = typeof(setmetatable(
	{} :: {
		Id: number,
		Mount: GuiObject,
		_state: WriterState,
		_thread: thread?,
		_activeCharacters: { CharacterClass },
		_activeTransforms: { CharacterTransform },
		_Animator: {}, -- AnimatorClass
		_SoundPlayer: SoundPlayerClass,
		activePreset: WriterPreset,
		onWriterComplete: () -> WriterExitState,
		onFlagReached: () -> number,
		onDestroy: () -> (),
	},
	Writer
))

--[=[
	Creates a new **Writer**!

	```lua
	local myWriter = Typist.new()
	```

	@return Writer
]=]
function Writer.new(): WriterClass
	-- #region OBJ_DOC
	--[=[
		A unique number to identify the Writer.

		@prop Id number
		@within Writer
		@readonly
	]=]

	--[=[
		The object the writer writes to.

		@prop Mount GuiObject
		@within Writer
		@readonly
	]=]

	--[=[
		An internal property that contains the state of the writer

		@prop _state WriterState
		@within Writer
		@private
	]=]

	--[=[
		An internal property that holds the writer's execution thread

		@prop _thread thread
		@within Writer
		@private
	]=]

	--[=[
		An internal property that stores the characters being written.

		@prop _activeCharacters { CharacterClass }
		@within Writer
		@private
	]=]

	--[=[
		An internal property that stores the location data of the characters being written.

		@prop _activeTransforms { CharacterTransform }
		@within Writer
		@private
	]=]

	--[=[
		Stores the active preset the writer is using.

		@prop activePreset { WriterPreset }
		@within Writer
	]=]

	--[=[
		Event fired after the writer has finished writing the text.

		@prop onWriterComplete GoodSignal
		@within Writer
		@tag event
	]=]

	--[=[
		Event fired when a flag is reached in the text.

		@prop onFlagReached GoodSignal
		@within Writer
		@tag event
	]=]

	--[=[
		Event fired immediately before the writer is destroyed.

		@prop onDestroy GoodSignal
		@within Writer
		@tag event
	]=]
	-- #endregion

	_currentWriterIndex += 1

	local WriterData = {
		-- >> Core <<
		Id = _currentWriterIndex,
		Mount = nil,

		-- >> Internal <<
		_state = {
			Mounted = false,
			Writing = false,
			Skipped = false,
			Paused = false,
		},
		_thread = nil,
		_activeCharacters = {},
		_activeTransforms = {},

		_writingStartTime = -1,
		_updateCycle = nil,
		_lastContainerSize = nil,
		_lastContainerResizeTime = -1,

		-- >> Internal / Objects <<
		_Animator = Animator.new(),
		_SoundPlayer = SoundPlayer.new(),

		-- >> Settings <<
		activePreset = Presets._default,

		-- >> Callback Events <<
		onWriterComplete = Signal.new(),
		onFlagReached = Signal.new(),
		onDestroy = Signal.new(),
	}

	return setmetatable(WriterData, Writer)
end

--[=[
	Mounts the writer, preparing it for use.

	```lua
	myWriter:Mount(mountElement)
	```

	@param mount Instance -- The element to write into
	@return boolean -- The writer was mounted without issue
]=]
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
		updateWriter(self, deltaTime)
	end)

	-- Initialize the audio module
	self._SoundPlayer:Init(self.Id, self.activePreset)

	self._state.Mounted = true
	return true
end

-- >> Module : Properties <<

--[=[
	Loads a **Preset** to the writer.

	@param presetName string -- The name of the preset to load
	@param overwrite boolean -- If true, overrides the current preset instead

	@return boolean -- The preset was loaded without issue

	:::warning
		Switching presets while the writer is writing may cause issues!
	:::
]=]
function Writer:LoadPreset(presetName: string, overwrite: boolean): boolean
	-- Reference the preset, if it doesn't exist, return
	local newPreset = Presets[presetName]

	if not newPreset then
		warn(`Could not load preset. "{presetName}" is not a known preset.`)
		return false
	end

	-- The preset to use as a fallback for missing values
	local basePreset = Presets._default

	-- If overwrite is true, overwrite the current preset instead of the default
	if overwrite then
		basePreset = self.activePreset
	end

	-- Load the preset
	for currentProperty, currentValue in pairs(basePreset) do
		self.activePreset[currentProperty] = newPreset[currentProperty] or currentValue
	end

	return true
end

-- >> Module : Actions <<

--[=[
	Writes a string of text.

	```lua
	myWriter:Write("Hello, World!")
	```

	@param text string -- The text to write
	@return boolean -- **Writer** successfully started writing

	:::note
		The Writer must be mounted!
	:::
]=]
function Writer:Write(text: string): boolean
	-- Safety Checks
	if self._state.Writing then
		warn("Cannot write while the writer is already writing! Cancel the current process first.")
		return false
	end

	if self._state.Mounted == false then
		warn("The writer must be mounted before it can start writing! Call Writer:Mount().")
		return false
	end

	if type(text) ~= "string" then
		warn(`{type(text)} is not a valid input type! Only strings are accepted.`)
		return false
	end

	-- Clear old text
	if #self._activeCharacters > 0 then
		for _, character in pairs(self._activeCharacters) do
			character:Destroy()
		end

		self._activeCharacters = {}
		self._activeTransforms = {}
	end

	-- Reset Animator
	self._Animator:Reset()

	-- Start writing
	self._state.Writing = true
	self._writingStartTime = os.clock()

	self._thread = coroutine.create(function()
		-- Parse raw string into character data
		if self.activePreset.RichText == true then
			self._activeCharacters = RichText.Enrich(text, self.activePreset.ValidateRichText)
		else
			self._activeCharacters = RichText.Raw(text)
		end

		-- Handle wrapping
		self._activeTransforms = Wrapper(self._activeCharacters, self.Mount, self.activePreset)

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
			if self._state.Paused then
				coroutine.yield()
			end

			-- Write the character
			character.Transform = self._activeTransforms[characterIndex]
			character:Write(self.Mount, self._Animator, self.activePreset, self._state.Skipped)

			-- Handle Flags and Custom Sounds
			if character.Properties.Flag then
				self.onFlagReached:Fire(character.Properties.Flag)
			end

			local customSound = character.Properties.Sound
			if customSound then
				self._SoundPlayer:PlayCustomSound(customSound.Id, customSound.Volume, customSound.Pitch)
			end

			-- The amount of time to delay until the next character is written
			local waitTime = 0

			-- If the delay property exists, calculate the wait time from there
			if character.Properties.DelayType then
				local Skip = false

				-- If the delay type is Word, skip over non-space characters
				if character.Properties.DelayType == "Word" and character.Value ~= " " then
					Skip = true
				end

				-- If the delay type is IgnoreSpace, skip over space characters
				if character.Properties.DelayType == "IgnoreSpace" and character.Value == " " then
					Skip = true
				end

				-- Wait the delay's length
				if Skip == false then
					waitTime = character.Properties.DelayLength
				end
			else
				-- Calculate the length of time to wait for
				local baseCooldown = 1 / self.activePreset.WritingSpeed
				local cooldownMultiple = 1

				-- If pausing after punctuation is active, calculate the amount of time to pause for
				if self.activePreset.PauseAfterPunctuation == true then
					cooldownMultiple = PUNCTUATION_PAUSE_MULTIPLES[character.Value] or 1
				end

				waitTime = baseCooldown * cooldownMultiple
			end

			-- If skipped, ignore the wait time and move on to the next character immediately
			if self._state.Skipped == true then
				-- If the current character has a split point, stop skipping
				if characterIndex == splitPoints[currentSplitPoint] then
					currentSplitPoint += 1
					self._state.Skipped = false
				end

				-- Apply the wait time to the animator instead
				self._Animator:Update(waitTime)
				continue
			end

			-- If there is no wait time, don't play the character sound
			if waitTime == 0 then
				continue
			end

			-- Play the writing sound
			self._SoundPlayer:PlayCharacterSound()

			-- Wait
			task.wait(waitTime)
		end

		-- Reset internal variables
		self._state.Skipped = false
		self._state.Paused = false
		self._state.Writing = false

		-- Fire the onWriterComplete event if it exists
		if self.onWriterComplete then
			if self._Skipped then
				self.onWriterComplete:Fire("Skipped")
			else
				self.onWriterComplete:Fire("Success")
			end
		end
	end)

	-- Automatically start writing
	coroutine.resume(self._thread)

	return true
end

--[=[
	Cancels the active writer process.

	```lua
	myWriter:Cancel()
	```

	@return boolean -- **Writer** cancelled without an issue
]=]
function Writer:Cancel(): boolean
	if self._state.Writing == false then
		warn("Can't cancel the writer since it isn't writing! Start it first.")
		return false
	end

	self._state.Writing = false
	self._state.Skipped = false
	self._state.Paused = false

	coroutine.close(self._thread)
	return true
end

--[=[
	Pauses the **Writer**, halting execution until it is resumed.

	```lua
	myWriter:Pause()
	```

	@return boolean -- **Writer** paused without an issue
]=]
function Writer:Pause(): boolean
	if self._state.Writing == false then
		warn("Can't pause the writer since it isn't writing! Start it first.")
		return false
	end

	self._state.Paused = true
	return true
end

--[=[
	Resumes the **Writer**, continuing execution.

	```lua
	myWriter:Resume()
	```

	@return boolean -- **Writer** resumed without an issue
]=]
function Writer:Resume(): boolean
	if self._state.Writing == false then
		warn("Can't resume the writer since it isn't writing! Start it first.")
		return false
	end

	if self._state.Paused == false then
		warn("Can't resume the writer since it isn't paused! This call is redundant.")
		return false
	end

	self._state.Paused = false
	coroutine.resume(self._thread)

	return true
end

--[=[
	Instantly writes all characters, ignoring the usual cooldown.

	```lua
	myWriter:Skip()
	```

	If the string of text contains a split, the **Writer** will skip until there instead.
	```lua
	myWriter:Write("This will get skipped immediately.<//split> This part will after another call.")
	myWriter:Skip()
	```

	@return boolean -- **Writer** skipped without an issue
]=]
function Writer:Skip(): boolean
	if self._state.Writing == false then
		warn("Can't skip when the writer isn't writing! Start it first.")
		return false
	end

	self._state.Skipped = true
	return true
end

--[=[
	Destroys the writer, freeing memory and cleaning up.

	```lua
	myWriter:Destroy()
	```
]=]
function Writer:Destroy()
	-- GoodSignal events should get gced automatically
	-- Disconnect the writer update cycle
	self._updateCycle:Disconnect()

	-- Destroy the animator and soundplayer
	self._Animator:Destroy()
	self._SoundPlayer:Destroy()

	-- Destroy the mount folder
	if self.Mount._Characters then
		self.Mount._Characters:Destroy()
	end

	-- Clear self
	setmetatable(self, nil)
	table.clear(self)
end

-- >> Module : Reading/Debug <<

--[=[
	Debugs the writer.

	@private
]=]
function Writer:_Diagnose()
	local date = os.date("!*t")
	local timestamp = string.format("%02i:%02i", (os.date("!*t").hour - 4) % 24, date.min)

	print("<<------------------------ Diagnosing Writer! -------------------------->>")
	print("| Time (EST):", timestamp)
	print("| Time (os):", os.clock())
	print("<---------- State ---------->")
	print(`| Mounted: {self._state.Mounted}`)
	print(`| Writing: {self._state.Writing}`)
	print(`| Skipped: {self._state.Skipped}`)
	print(`| Paused: {self._state.Paused}`)
	print("<<------------------------ Diagnosis Complete! ------------------------->>")
end

return Writer
