--!strict

-->>--------------------------------------------<<--
-- @Created: September 21st, 2025
-- @Authors: Outbroken

-- @Description:
-- Plays and manages audio for the writer
-->>--------------------------------------------<<--

-- >> Core Services <<

local SoundService = game:GetService("SoundService")

-- >> Module <<

local Audio = {}

function Audio.Initialize(Writer: {})
	local rootFolder = SoundService:FindFirstChild("Typist")

	if not rootFolder then
		local newRoot = Instance.new("Folder")
		newRoot.Name = "Typist"
		newRoot.Parent = SoundService

		rootFolder = newRoot
	end

	local writerFolder = rootFolder:FindFirstChild(Writer.Id)

	if writerFolder then
		return
	end

	writerFolder = Instance.new("Folder")
	writerFolder.Name = Writer.Id
	writerFolder.Parent = rootFolder

	local characterFolder = Instance.new("Folder")
	characterFolder.Name = "Character"
	characterFolder.Parent = writerFolder

	for index = 1, 5, 1 do
		local newWritingSound = Instance.new("Sound")
		newWritingSound.Volume = 0.4
		newWritingSound.SoundId = Writer.activePreset.WritingSound
		newWritingSound.Name = index
		newWritingSound.Parent = characterFolder
	end

	local customFolder = Instance.new("Folder")
	customFolder.Name = "Custom"
	customFolder.Parent = writerFolder
end

function Audio.playCharacterSound(WriterId: number)
	for index = 1, 5, 1 do
		local Sound = SoundService.Typist[tostring(WriterId)].Character[index]
		if Sound.Playing == true then
			continue
		end

		Sound.PlaybackSpeed = 1 + (math.random(1, 50) / 100)
		Sound:Play()

		break
	end
end

function Audio.playCustomSound(WriterId: number, SoundId: number, Volume: number, Pitch: number)
	local newSound = Instance.new("Sound")
	newSound.Volume = Volume or 0.5
	newSound.PlaybackSpeed = Pitch or 1
	newSound.SoundId = "rbxassetid://" .. SoundId

	newSound.Name = SoundId
	newSound.Parent = SoundService.Typist[tostring(WriterId)].Custom

	newSound:Play()
	newSound.Ended:Once(function()
		newSound:Destroy()
	end)
end

return Audio
