local Services = setmetatable({}, {
	__index = function(self, key)
		local cloneref = cloneref or function(...) return ... end
		local succ, result = pcall(cloneref, game:FindService(key))
		rawset(self, key, succ and result or Instance.new(key))

		return rawget(self, key)
	end
})

local flags = flags or {
	time_variance = 0.07,
	comparison_checks = 1,
	jump_when_stuck = true,
}

-- Services
local pathfinding_service = Services.PathfindingService
local players = Services.Players

local function output(func, msg)
	func(((func == error and "BayaPathfinder Error: ") or "BayaPathfinder: ")..msg)
end

local Path = {
	status_type = {
		idle = "Idle",
		active = "Active",
	},
	error_type = {
		limit_reached = "LimitReached",
		target_unreachable = "TargetUnreachable",
		computation_error = "ComputationError",
		agent_stuck = "AgentStuck",
	},
}

Path.__metatable = false

Path.__index = function(table, index)
	if index == "Stopped" and not table._humanoid then
		output(error, "Attempt to use Path.Stopped on a non-humanoid.")
	end
	return (table._events[index] and table._events[index].Event)
		or (index == "LastError" and table._last_error)
		or (index == "Status" and table._status)
		or Path[index]
end

-- Used to visualize waypoints
local visual_waypoint = Instance.new("Part")
visual_waypoint.Size = Vector3.new(0.3, 0.3, 0.3)
visual_waypoint.Anchored = true
visual_waypoint.CanCollide = false
visual_waypoint.Material = Enum.Material.Neon
visual_waypoint.Shape = Enum.PartType.Ball

--[[ PRIVATE FUNCTIONS ]]--
local function declare_error(self, error_type)
	self._last_error = error_type
	self._events.Error:Fire(error_type)
end

local function create_visual_waypoints(waypoints)
	local visual_waypoints = {}
	for _, waypoint in ipairs(waypoints) do
		local clone = visual_waypoint:Clone()
		clone.Position = waypoint.Position
		clone.Parent = workspace
		clone.Color =
			(waypoint == waypoints[#waypoints] and Color3.fromRGB(0, 255, 0))
			or (waypoint.Action == Enum.PathWaypointAction.Jump and Color3.fromRGB(255, 0, 0))
			or Color3.fromRGB(255, 139, 0)
		table.insert(visual_waypoints, clone)
	end
	return visual_waypoints
end

local function destroy_visual_waypoints(waypoints)
	if waypoints then
		for _, waypoint in ipairs(waypoints) do
			waypoint:Destroy()
		end
	end
end

local function get_non_humanoid_waypoint(self)
	if self and (self._waypoints and #self._waypoints ~= nil) then
		for i = 2, #self._waypoints do
			if (self._waypoints[i].Position - self._waypoints[i - 1].Position).Magnitude > 0.1 then
				return i
			end
		end
	end
	return 2
end

local function set_jump_state(self)
	pcall(function()
		if self._humanoid:GetState() ~= Enum.HumanoidStateType.Jumping
			and self._humanoid:GetState() ~= Enum.HumanoidStateType.Freefall then
			self._humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
		end
	end)
end

local function move(self)
	if self._waypoints[self._current_waypoint].Action == Enum.PathWaypointAction.Jump then
		set_jump_state(self)
	end
	self._humanoid:MoveTo(self._waypoints[self._current_waypoint].Position)
end

local function disconnect_move_connection(self)
	if self._move_connection then
		self._move_connection:Disconnect()
		self._move_connection = nil
	end
end

local function invoke_waypoint_reached(self)
	local last_waypoint = self._waypoints[self._current_waypoint - 1]
	local next_waypoint = self._waypoints[self._current_waypoint]
	self._events.WaypointReached:Fire(self._agent, last_waypoint, next_waypoint)
end

local function move_to_finished(self, reached)
	if not getmetatable(self) then return end

	if not self._humanoid then
		if reached and self._current_waypoint + 1 <= #self._waypoints then
			invoke_waypoint_reached(self)
			self._current_waypoint += 1
		elseif reached then
			self._visual_waypoints = destroy_visual_waypoints(self._visual_waypoints)
			self._target = nil
			self._events.Reached:Fire(self._agent, self._waypoints[self._current_waypoint])
		else
			self._visual_waypoints = destroy_visual_waypoints(self._visual_waypoints)
			self._target = nil
			declare_error(self, self.error_type.target_unreachable)
		end
		return
	end

	if reached and self._current_waypoint + 1 <= #self._waypoints then
		if self._current_waypoint + 1 < #self._waypoints then
			invoke_waypoint_reached(self)
		end
		self._current_waypoint += 1
		move(self)
	elseif reached then
		disconnect_move_connection(self)
		self._status = Path.status_type.idle
		self._visual_waypoints = destroy_visual_waypoints(self._visual_waypoints)
		self._events.Reached:Fire(self._agent, self._waypoints[self._current_waypoint])
	else
		disconnect_move_connection(self)
		self._status = Path.status_type.idle
		self._visual_waypoints = destroy_visual_waypoints(self._visual_waypoints)
		declare_error(self, self.error_type.target_unreachable)
	end
end

local function compare_position(self)
	if self._current_waypoint == #self._waypoints then return end
	self._position._count = ((self._agent.PrimaryPart.Position - self._position._last).Magnitude <= 0.07 and (self._position._count + 1)) or 0
	self._position._last = self._agent.PrimaryPart.Position
	if self._position._count >= self._settings.comparison_checks then
		if self._settings.jump_when_stuck then
			set_jump_state(self)
		end
		declare_error(self, self.error_type.agent_stuck)
	end
end

--[[ STATIC METHODS ]]--
function Path.get_nearest_character(from_position)
	local character, dist = nil, math.huge
	for _, player in ipairs(players:GetPlayers()) do
		if player.Character and (player.Character.PrimaryPart.Position - from_position).Magnitude < dist then
			character, dist = player.Character, (player.Character.PrimaryPart.Position - from_position).Magnitude
		end
	end
	return character
end

--[[ CONSTRUCTOR ]]--
function Path.new(agent, agent_parameters, override)
	if not (agent and agent:IsA("Model") and agent.PrimaryPart) then
		output(error, "Pathfinding agent must be a valid Model Instance with a set PrimaryPart.")
	end

	local self = setmetatable({
		_settings = override or flags,
		_events = {
			Reached = Instance.new("BindableEvent"),
			WaypointReached = Instance.new("BindableEvent"),
			Blocked = Instance.new("BindableEvent"),
			Error = Instance.new("BindableEvent"),
			Stopped = Instance.new("BindableEvent"),
		},
		_agent = agent,
		_humanoid = agent:FindFirstChildOfClass("Humanoid"),
		_path = pathfinding_service:CreatePath(agent_parameters),
		_status = "Idle",
		_t = 0,
		_position = {
			_last = Vector3.new(),
			_count = 0,
		},
	}, Path)

	for setting, value in pairs(flags) do
		self._settings[setting] = self._settings[setting] == nil and value or self._settings[setting]
	end

	self._path.Blocked:Connect(function(...)
		if (self._current_waypoint <= ... and self._current_waypoint + 1 >= ...) and self._humanoid then
			set_jump_state(self)
			self._events.Blocked:Fire(self._agent, self._waypoints[...])
		end
	end)

	return self
end

--[[ NON-STATIC METHODS ]]--
function Path:Destroy()
	self._running = false
	self._destroyed = true

	if self._events then
		for _, event in ipairs(self._events) do
			if typeof(event) == "RBXScriptConnection" then
				event:Disconnect()
			elseif typeof(event) == "table" and typeof(event.Destroy) == "function" then
				event:Destroy()
			end
		end
		self._events = nil
	end

	if rawget(self, "_visual_waypoints") then
		self._visual_waypoints = destroy_visual_waypoints(self._visual_waypoints)
	end

	local humanoid = self._humanoid or (self._character and self._character:FindFirstChildOfClass("Humanoid"))
	if humanoid then
		humanoid:MoveTo(humanoid.RootPart.Position)
	end

	if self._path and typeof(self._path.Destroy) == "function" then
		self._path:Destroy()
	end

	setmetatable(self, nil)
	table.clear(self)
end

function Path:Stop()
	if self._destroyed then return end

	if not self._humanoid then
		output(error, "Attempt to call Path:Stop() on a non-humanoid.")
		return
	end
	if self._status == Path.status_type.idle then
		output(function(m)
			warn(debug.traceback(m))
		end, "Attempt to run Path:Stop() in idle state")
		return
	end
	disconnect_move_connection(self)
	self._status = Path.status_type.idle
	self._visual_waypoints = destroy_visual_waypoints(self._visual_waypoints)
	self._events.Stopped:Fire(self._model)
end

function Path:Run(target)
	if self._destroyed then return end

	if not target and not self._humanoid and self._target then
		move_to_finished(self, true)
		return
	end

	if not (target and (typeof(target) == "Vector3" or target:IsA("BasePart"))) then
		output(error, "Pathfinding target must be a valid Vector3 or BasePart.")
	end

	if os.clock() - self._t <= self._settings.time_variance and self._humanoid then
		task.wait(os.clock() - self._t)
		declare_error(self, self.error_type.limit_reached)
		return false
	elseif self._humanoid then
		self._t = os.clock()
	end

	local computed = pcall(function()
		self._path:ComputeAsync(self._agent.PrimaryPart.Position, (typeof(target) == "Vector3" and target) or target.Position)
	end)

	if not computed
		or (self._path and self._path.Status == Enum.PathStatus.NoPath)
		or (self._path and #self._path:GetWaypoints() < 2)
		or (self._humanoid and self._humanoid:GetState() == Enum.HumanoidStateType.Freefall) then
		self._visual_waypoints = destroy_visual_waypoints(self._visual_waypoints)
		task.wait()
		declare_error(self, self.error_type.computation_error)
		return false
	end

	self._status = (self._humanoid and Path.status_type.active) or Path.status_type.idle
	self._target = target

	pcall(function()
		self._agent.PrimaryPart:SetNetworkOwner(nil)
	end)

	self._waypoints = self._path and self._path:GetWaypoints() or nil
	self._current_waypoint = 2

	if self._humanoid then
		compare_position(self)
	end

	destroy_visual_waypoints(self._visual_waypoints)
	self._visual_waypoints = (self.Visualize and create_visual_waypoints(self._waypoints))

	self._move_connection = self._humanoid and (self._move_connection or self._humanoid.MoveToFinished:Connect(function(...)
		move_to_finished(self, ...)
	end))

	if self and (self._humanoid and self._waypoints and self._current_waypoint) then
		self._humanoid:MoveTo(self._waypoints[self._current_waypoint].Position)
	elseif self and (self._waypoints and #self._waypoints == 2) then
		self._target = nil
		self._visual_waypoints = destroy_visual_waypoints(self._visual_waypoints)
		self._events.Reached:Fire(self._agent, self._waypoints[2])
	else
		if self and (self._current_waypoint) then
			self._current_waypoint = get_non_humanoid_waypoint(self)
			move_to_finished(self, true)
		end
	end
	return true
end

return Path
