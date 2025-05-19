# Humanoid Examples

The following examples is explained in detail [here](../guides/BayaPathfinder-getting-started.md).

<br>

## Using Events

[more info on Flags](../BayaPathfinder/API.md)

```lua linenums="1"
-- Default settings which you can edit
local Flags = {
	TIME_VARIANCE = 0.07;

	COMPARISON_CHECKS = 1;

	JUMP_WHEN_STUCK = true;
}

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

--Compute a new path every time the Character reaches the Destination part
Path.Reached:Connect(function()
    Path:Destroy() -- Destroy connections
end)

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

<hr>

## Using Loops

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