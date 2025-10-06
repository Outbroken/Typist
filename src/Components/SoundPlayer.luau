--!strict

-->>--------------------------------------------<<--
-- @Created: September 21st, 2025
-- @Authors: Outbroken

-- @Description:
-- Plays and manages audio for the writer
-->>--------------------------------------------<<--

-- >> Core Services <<

local SoundService = game:GetService("SoundService")

-- >> Types <<

local _Types = require(script.Parent.Parent.Types)
type WriterPreset = _Types.WriterPreset

-- >> Module <<

local SoundPlayer = {}
SoundPlayer.__index = SoundPlayer

export type SoundPlayerClass = typeof(setmetatable(
	{} :: {
		soundFolder: Folder?,
		characterSound: string,
		volume: number,
		pitchRandomness: number,
	},
	SoundPlayer
))

--[[
	Creates a new sound player
]]
function SoundPlayer.new(): SoundPlayerClass
	return setmetatable({
		soundFolder = nil,

		characterSound = "",
		volume = 1,
		pitchRandomness = 1.5,
	}, SoundPlayer)
end

--[[
	Initializes the sound player, binding it to a writer
]]
function SoundPlayer:Init(writerId: number, activePreset: WriterPreset)
	local rootFolder = SoundService:FindFirstChild("Typist")

	if not rootFolder then
		local newRoot = Instance.new("Folder")
		newRoot.Name = "Typist"
		newRoot.Parent = SoundService

		rootFolder = newRoot
	end

	local writerFolder = Instance.new("Folder")
	writerFolder.Name = tostring(writerId)
	writerFolder.Parent = rootFolder

	local characterFolder = Instance.new("Folder")
	characterFolder.Name = "Character"
	characterFolder.Parent = writerFolder

	for index = 1, 5, 1 do
		local newWritingSound = Instance.new("Sound")
		newWritingSound.SoundId = activePreset.WritingSound
		newWritingSound.Name = tostring(index)
		newWritingSound.Parent = characterFolder
	end

	local customFolder = Instance.new("Folder")
	customFolder.Name = "Custom"
	customFolder.Parent = writerFolder

	self.soundFolder = writerFolder
	self.characterSound = activePreset.WritingSound
end

--[[
	Plays the character sound
]]
function SoundPlayer:PlayCharacterSound()
	for index = 1, 5, 1 do
		local Sound = self.soundFolder.Character[index]
		if Sound.Playing == true then
			continue
		end

		local randomPitch = math.random(100, self.pitchRandomness :: number * 100) / 100
		Sound.SoundId = self.characterSound
		Sound.Volume = 0.4 * self.volume
		Sound.PlaybackSpeed = randomPitch
		Sound:Play()

		break
	end
end

--[[
	Plays a custom sound, specified with an id
]]
function SoundPlayer:PlayCustomSound(soundId: number, volume: number, pitch: number)
	local newSound = Instance.new("Sound")
	newSound.Volume = (volume or 0.5) * self.volume
	newSound.PlaybackSpeed = pitch or 1
	newSound.SoundId = "rbxassetid://" .. soundId

	newSound.Name = tostring(soundId)
	newSound.Parent = self.soundFolder.Custom

	newSound:Play()
	newSound.Ended:Once(function()
		newSound:Destroy()
	end)
end

--[[
	Destroys the sound player, cleaning up
]]
function SoundPlayer:Destroy()
	self.soundFolder:Destroy()

	table.clear(self)
	setmetatable(self, nil)
end

return SoundPlayer
