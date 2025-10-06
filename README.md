# Typist

## THIS MODULE IS IN DEVELOPMENT
## What is it?
Typist is a Roblox module built to replicate a typewriter effect found in many games.
* Text is drawn to the screen character-by-character to allow for more control
* Supports dynamic and advanced animations through custom rich text.

## Creating your first Writer
Reference the module then call the *.new()* method.
```lua
local Typist = require(script.Parent.Typist) -- Reference the module
local myWriter = Typist.new()
```
Before writing, the writer **must** be mounted to an element.
```lua
local myElement = Instance.new("Frame") -- Can be any type of GUI Object
myWriter:Mount(myElement)
```

## Writing Text
To write a string of text, simply call *:Write()*!
```lua
myWriter:Write("Hello, World")
```
Where this module really shines however is through its custom implementation of rich text.
**Try this:**
```lua
myWriter:Write("Hello, I'm <b>Bold!</b>")

-- Example of a more advanced effect:
myWriter:Write("I'm <fill Color=[fade(){%Chroma%}]>Rainbow!</fill>") 
```
To learn more about how to use this, click [here]!

## Skipping and Stopping
Calling *:Skip()* will instantly write all the characters. 
* If the text contains a split, the writer will skip until there instead.
```lua
myWriter:Skip()
```
To stop the writing process, call *:Cancel()*
```lua
myWriter:Cancel()
```

## Pausing and Resuming
The writer can be paused and resumed at any point, halting or continuing its execution.
```lua
myWriter:Pause() -- Pauses the writer until it is resumed again

myWriter:Resume() -- Resumes the writer
```

## Events