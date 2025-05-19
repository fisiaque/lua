# Non-Humanoid Examples

Pathfinding for non-humanoid models can get a little complicated. Consider converting your non-humanoid model to a humanoid if possible.

<br>

## Example 1

```lua linenums="1"
local TweenService = game:GetService("TweenService")
local BayaPath = loadstring(game:HttpGet("https://raw.githubusercontent.com/fisiaque/lua/refs/heads/main/BayaPathfinder/src.lua"))()

local Model = workspace.Model
local Destination = workspace.Destination
local Path = BayaPath.new(Model)

local function tween(part, destination)
	local tweenBase = TweenService:Create(part, TweenInfo.new(0.07), {Position = destination + Vector3.new(0, 0.5, 0)})
	tweenBase:Play()
	tweenBase.Completed:Wait()
end

Path.Visualize = true

--Tween model to final waypoint when reached
Path.Reached:Connect(function(model, finalWaypoint)
	tween(model.PrimaryPart, finalWaypoint.Position)
end)

--Call Path:Run() at the end of the event to indicate the end of movement for the current waypoint
Path.WaypointReached:Connect(function(model, lastWaypoint, nextWaypoint)
	tween(model.PrimaryPart, nextWaypoint.Position)
	Path:Run()
end)

Path:Run(Destination)
```

<hr>

## Example 2

```lua linenums="1"
local TweenService = game:GetService("TweenService")
local BayaPath = loadstring(game:HttpGet("https://raw.githubusercontent.com/fisiaque/lua/refs/heads/main/BayaPathfinder/src.lua"))()

local Model = workspace.Model
local Destination = workspace.Destination

local Path = BayaPath.new(Model)

local function tween(part, destination)
	local tweenBase = TweenService:Create(part, TweenInfo.new(0.07), {Position = destination + Vector3.new(0, 0.5, 0)})
	tweenBase:Play()
	tweenBase.Completed:Wait()
end

Path.Visualize = true

--If the path is blocked
Path.Blocked:Connect(function()
	Path:Run(Destination)
end)

--In case of an error
Path.Error:Connect(function()
	Path:Run(Destination)
end)

Path.Reached:Connect(function(model, finalWaypoint)
	tween(model.PrimaryPart, finalWaypoint.Position)
	Path:Run(Destination)
end)

Path.WaypointReached:Connect(function(model, lastWaypoint, nextWaypoint)
	tween(model.PrimaryPart, nextWaypoint.Position)
	Path:Run(Destination)
end)

Path:Run(Destination)
```

<hr>

## Example 3

```lua linenums="1"
local TweenService = game:GetService("TweenService")
local BayaPath = loadstring(game:HttpGet("https://raw.githubusercontent.com/fisiaque/lua/refs/heads/main/BayaPathfinder/src.lua"))()

local Model = workspace.Model
local Destination = workspace.Destination
local Path = BayaPath.new(Model)

Path.Visualize = true

Path.Reached:Connect(function(model, finalWaypoint)
	model.PrimaryPart.Position = finalWaypoint.Position + Vector3.new(0, 0.5, 1)
end)

Path.WaypointReached:Connect(function(model, lastWaypoint, nextWaypoint)
	model.PrimaryPart.Position = nextWaypoint.Position + Vector3.new(0, 0.5, 1)
end)

while true do
	Path:Run(Destination)
	task.wait()
end
```