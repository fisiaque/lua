This tutorial shows you how you can set up BayaPath and teaches you a basic implementation of the module.

## Installation

Get the [latest release](https://github.com/fisiaque/lua/BayaPathfinder) from GitHub.

!!! Note
	Paste the folowing code to start using the module:

```lua
--Import the module so you can start using it
local BayaPath = loadstring(game:HttpGet(""))()

```

The next part of the code defines all of the different variables that will be used in the script:


```lua
--Define character
local Character = game.Players.LocalPlayer.Character

--Define a part called "Destination"
local Destination = workspace.Destination

--Create a new Path using the Character
local Path = BayaPath.new(Character)
```

!!! Note
	`BayaPath.new()` is a constructor that creates a new Path and it should only be created once per agent. You can call `Path:Run()` on the same Path object multiple times without having to create a new Path every time you need to do pathfinding.

<hr>

## Method 1: Using Events

The following part of the tutorial shows you how you can make a pathfinding script using only events. 

To make the Character move towards the destination, you only need one line of code:
```lua
Path:Run(Destination)
```

Even though this single line of code seems sufficient, there are a few important things to keep in mind. Firstly, if some object comes in-between the path of the Character, the Character will just stop pathfinding before reaching the destination because `Path:Run()` is not called a second time to compute the path again. To fix this, you can use the `Path.Blocked` event and call `Path:Run()` whenever something blocks the path:

```lua
--Character knows to compute path again if something blocks the path
Path.Blocked:Connect(function()
    Path:Run(Destination)
end)
```

The next thing to keep in mind is the position of the destination part. In the case where the destination part is constantly moving, how can you alter the current path of Character to make sure that it reaches the exact position of the destination part? You can do this by adding in 2 more events. 

The `Path.WaypointReached` event will compute a new Path everytime the Character reaches the next waypoint and accounts for a new position of the destination part if it changed.

```lua
--If the position of Destination changes at the next waypoint, compute path again
Path.WaypointReached:Connect(function()
    Path:Run(Destination)
end)
```

The second event is `Path.Error`. You can compute a new path every time the target becomes unreachable or the path to the destination is not traversable. For example, if the part is floating in the sky, the Character would not be able to reach it and `Path.Error` fires.

```lua
--Dummmy knows to compute path again if an error occurs
Path.Error:Connect(function(errorType)
    Path:Run(Destination)
end)
```

Your code should look something like this after adding everything in:

```lua linenums="1"
--Import the module so you can start using it
local BayaPath = loadstring(game:HttpGet(""))()

--Define character
local Character = game.Players.LocalPlayer.Character

-- Define a part called "Destination"
local Destination = workspace.Destination

--Create a new Path using the Character
local Path = BayaPath.new(Character)

--Helps to visualize the path
Path.Visualize = true

--Character knows to compute path again if something blocks the path
Path.Blocked:Connect(function()
    Path:Run(Destination)
end)

--If the position of Destination changes at the next waypoint, compute path again
Path.WaypointReached:Connect(function()
    Path:Run(Destination)
end)

--Dummmy knows to compute path again if an error occurs
Path.Error:Connect(function(errorType)
    Path:Run(Destination)
end)

Path:Run(Destination)

```

!!! Info
	Set `Path.Visualize` to `true` before the very first `Path:Run()` call to see the waypoints.

If you want the Character to always follow the destination part even after reaching it, you can simply use the `Path.Reached` event:


```lua
--Compute a new path every time the Character reaches the destination part
Path.Reached:Connect(function()
    Path:Run(Destination)
end)
```

<hr>

## Method 2: Using Loops

In the following tutorial, you will learn how to use BayaPath using loops instead of events.

Using BayaPath in a loop is way simpler than using events. You only need 3 lines of code:
```lua
while true do
    Path:Run(Destination)
end
```

`Path:Run()` does not require a wait because it automatically yields if the maximum time elapsed between consecutive calls are less than `Settings.TIME_VARIANCE`.

If you are using loops, your final code should look something like this:

```lua linenums="1"
--Import the module so you can start using it
local BayaPath = loadstring(game:HttpGet(""))()

--Define character
local Character = game.Players.LocalPlayer.Character

-- Define a part called "Destination"
local Destination = workspace.Destination

--Create a new Path using the Character
local Path = BayaPath.new(Character)

--Helps to visualize the path
Path.Visualize = true

while true do
    Path:Run(Destination)
end

```

<hr>

## Choosing the right method

BayaPath gives you the freedom to code in any method you prefer. You are not limited to the two methods mentioned in this tutorial as they are simply meant to be examples. You can even combine both methods and implement them together at once. It all depends on how you decide to structure your code based on the performance, compatibility, etc. and personal preference.