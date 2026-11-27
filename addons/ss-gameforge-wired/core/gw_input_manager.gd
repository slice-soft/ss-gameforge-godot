extends SingletonNode
class_name GWInputManager

static var i: GWInputManager:
	get:
		return SingletonNode.get_instance_for(GWInputManager) as GWInputManager


static func ensure(root: Node) -> GWInputManager:
	return SingletonNode.ensure_for(GWInputManager, root, "GWInputManager") as GWInputManager

signal player_created(player_id: int)
signal player_removed(player_id: int)
signal device_connected(device_id: int, device_name: String)
signal device_disconnected(device_id: int)
signal binding_remapped(player_id: int, action_name: String)
signal rebind_listening(player_id: int, action_name: String, binding_index: int)
signal rebind_cancelled(player_id: int)
## Emitted after a rebind when the new input is also bound to other actions of
## the same player. The rebind is kept; the game decides whether to swap or warn.
signal rebind_conflict(player_id: int, action_name: String, conflicting_actions: Array[String])
## Emitted when an unassigned device produces a press. Use this to drive "press to join" logic.
signal unassigned_device_pressed(device_id: int)

# --- Constants ---
const DEFAULT_SAVE_PATH := "user://gw_bindings.json"

# --- Internal state ---
## Action templates (the blueprints copied to each new player).
var _action_templates: Dictionary = {}
## Registered players keyed by player_id.
var players: Dictionary = {}
## Connected devices keyed by device_id (-1 = keyboard/mouse).
var devices: Dictionary = {}
## Active rebind context. Empty when not listening.
var _rebind_ctx: Dictionary = {}
## Owner of each pad that disconnected while assigned, so it is handed back on
## reconnect. { device_id: player_id }
var _pad_owner_on_disconnect: Dictionary = {}


# --- Lifecycle ---

func _ready() -> void:
	Input.joy_connection_changed.connect(_on_joy_connection_changed)
	_scan_devices()


func _input(event: InputEvent) -> void:
	if _rebind_ctx.get("listening", false):
		_process_rebind_input(event)
		return

	for player_id in players:
		(players[player_id] as GWPlayer).feed_event(event)

	if _is_join_press(event):
		var dev_id := _get_event_device_id(event)
		if _is_device_unassigned(dev_id):
			unassigned_device_pressed.emit(dev_id)


# --- Config API ---

## Initializes the system from a GWConfig resource created in the editor panel.
## Clears all existing templates and players before applying the new config.
func load_config(config: GWConfig) -> void:
	for player_id in players.keys():
		remove_player(player_id)
	_action_templates.clear()

	for action_cfg in config.actions:
		var a := define_action(
			action_cfg.action_name,
			action_cfg.display_name if not action_cfg.display_name.is_empty() else action_cfg.action_name,
			action_cfg.default_bindings,
			action_cfg.category,
			action_cfg.max_bindings
		)
		a.allow_rebind = action_cfg.allow_rebind
		a.action_type = action_cfg.action_type as GWAction.ActionType
		a.positive_name = action_cfg.positive_name
		a.negative_name = action_cfg.negative_name

	match config.player_mode:
		GWConfig.PlayerMode.SINGLE:
			var p := create_player(0)
			p.accepts_keyboard = true
			p.accepts_any_gamepad = true
		GWConfig.PlayerMode.LOCAL_COOP:
			# Players are created but devices are assigned separately (e.g. lobby).
			for i in config.max_local_players:
				create_player(i)
		GWConfig.PlayerMode.ONLINE:
			# One local player. Remote players are the game's responsibility.
			var p := create_player(0)
			p.accepts_keyboard = true
			p.accepts_any_gamepad = true


# --- Action template API ---

## Registers a new action template. Must be called before create_player().
func define_action(
	action_name: String,
	display_name: String = "",
	default_bindings: Array = [],
	category: String = "General",
	max_bindings: int = 2
) -> GWAction:
	var action := GWAction.new()
	action.action_name = action_name
	action.display_name = display_name if not display_name.is_empty() else action_name
	action.category = category
	action.max_bindings = max_bindings
	for b in default_bindings:
		action.add_binding(b)
	_action_templates[action_name] = action
	return action


## Removes an action template. Does not affect existing players.
func undefine_action(action_name: String) -> void:
	_action_templates.erase(action_name)


## Returns the template GWAction for the given name, or null.
func get_action_template(action_name: String) -> GWAction:
	return _action_templates.get(action_name) as GWAction


## Returns all registered action names.
func get_action_names() -> Array:
	return _action_templates.keys()


## Returns action names grouped by category: { "Movement": ["move_left", ...], ... }
func get_actions_by_category() -> Dictionary:
	var result: Dictionary = {}
	for action_name in _action_templates:
		var action: GWAction = _action_templates[action_name]
		if not result.has(action.category):
			result[action.category] = []
		result[action.category].append(action_name)
	return result


# --- Player management ---

## Creates and registers a player, cloning all current action templates into it.
## If a player with this id already exists it is removed first (player_removed fires).
func create_player(player_id: int, player_name: String = "") -> GWPlayer:
	if players.has(player_id):
		remove_player(player_id)
	var player := GWPlayer.new()
	player.player_id = player_id
	player.player_name = player_name if not player_name.is_empty() else "Player %d" % (player_id + 1)
	for action_name in _action_templates:
		var template: GWAction = _action_templates[action_name]
		player.actions[action_name] = template.duplicate_full()
	player.free_gamepads_source = _free_gamepads_for.bind(player_id)
	player.device_assigned.connect(_on_player_device_assigned.bind(player_id))
	player.device_unassigned.connect(_on_player_device_unassigned.bind(player_id))
	players[player_id] = player
	player_created.emit(player_id)
	return player


## Returns the GWPlayer with the given ID, or null.
func get_player(player_id: int) -> GWPlayer:
	return players.get(player_id) as GWPlayer


## Shorthand for get_player(0).
func get_default_player() -> GWPlayer:
	return get_player(0)


## Removes a player from the registry and frees its gamepads.
func remove_player(player_id: int) -> void:
	if not players.has(player_id):
		return
	var player: GWPlayer = players[player_id]
	player.unassign_all_gamepads()
	for dev_id in _pad_owner_on_disconnect.keys():
		if _pad_owner_on_disconnect[dev_id] == player_id:
			_pad_owner_on_disconnect.erase(dev_id)
	players.erase(player_id)
	player_removed.emit(player_id)


# --- Gameplay shorthand API ---

## Returns true if the named action is pressed for the given player.
func is_action_pressed(action_name: String, player_id: int = 0) -> bool:
	var player := get_player(player_id)
	if player == null:
		return false
	return player.is_action_pressed(action_name)


## Returns the current strength [0.0, 1.0] of the named action for the given player.
func get_action_strength(action_name: String, player_id: int = 0) -> float:
	var player := get_player(player_id)
	if player == null:
		return 0.0
	return player.get_action_strength(action_name)


## Returns true if the action was just pressed this frame (or in a specific event) for the given player.
## When event is null, uses frame-state tracking — safe to call from _process() and _physics_process().
func is_action_just_pressed(action_name: String, event: InputEvent = null, player_id: int = 0) -> bool:
	var player := get_player(player_id)
	if player == null:
		return false
	if event == null:
		return player.is_action_just_pressed_this_frame(action_name)
	return player.is_action_just_pressed(action_name, event)


## Returns true if the action was just released this frame (or in a specific event) for the given player.
## When event is null, uses frame-state tracking — safe to call from _process() and _physics_process().
func is_action_just_released(action_name: String, event: InputEvent = null, player_id: int = 0) -> bool:
	var player := get_player(player_id)
	if player == null:
		return false
	if event == null:
		return player.is_action_just_released_this_frame(action_name)
	return player.is_action_just_released(action_name, event)


## For AXIS actions: returns net value in [-1.0, 1.0] for the given player.
func get_action_axis(action_name: String, player_id: int = 0) -> float:
	var player := get_player(player_id)
	if player == null:
		return 0.0
	return player.get_action_axis(action_name)


## Returns a movement vector from four action names for the given player.
func get_vector(neg_x: String, pos_x: String, neg_y: String, pos_y: String, player_id: int = 0) -> Vector2:
	var player := get_player(player_id)
	if player == null:
		return Vector2.ZERO
	return player.get_vector(neg_x, pos_x, neg_y, pos_y)


# --- Rebinding API ---

## Enters listen mode: the next input from a device the player owns becomes the
## new binding. Set negative = true to capture the negative side of an AXIS action.
## Returns false (and does not listen) if the player or action does not exist or
## the action has allow_rebind = false.
## While listening, is_listening_for_rebind() returns true — gameplay queries
## receive no input until the rebind ends.
func start_rebind_listen(player_id: int, action_name: String, binding_index: int = 0, negative: bool = false) -> bool:
	var player := get_player(player_id)
	if player == null or not player.actions.has(action_name):
		push_warning("[GWInputManager] Cannot rebind '%s' for player %d: not found." % [action_name, player_id])
		return false
	if not (player.actions[action_name] as GWAction).allow_rebind:
		push_warning("[GWInputManager] Action '%s' does not allow rebinding." % action_name)
		return false
	_rebind_ctx = {
		"player_id": player_id,
		"action_name": action_name,
		"binding_index": binding_index,
		"negative": negative,
		"listening": true,
	}
	rebind_listening.emit(player_id, action_name, binding_index)
	return true


## Cancels an active listen mode without applying any binding.
func cancel_rebind_listen() -> void:
	if not _rebind_ctx.get("listening", false):
		return
	var pid: int = _rebind_ctx.get("player_id", 0)
	_end_rebind()
	rebind_cancelled.emit(pid)


## Returns true while the system is waiting for the next input to rebind.
func is_listening_for_rebind() -> bool:
	return _rebind_ctx.get("listening", false)


# --- Device API ---

## Returns all connected devices (including keyboard/mouse).
func get_connected_devices() -> Array:
	return devices.values()


## Returns connected gamepads that no player reads yet — neither assigned with
## assign_gamepad() nor picked up by an accepts_any_gamepad player.
func get_unassigned_gamepads() -> Array:
	var result: Array = []
	for dev_id in devices:
		if (dev_id as int) < 0:
			continue
		if _is_device_unassigned(dev_id):
			result.append(devices[dev_id])
	return result


# --- Persistence ---

## Saves all player binding profiles to a JSON file.
func save_all_profiles(path: String = DEFAULT_SAVE_PATH) -> void:
	var data: Dictionary = {}
	for player_id in players:
		var player: GWPlayer = players[player_id]
		data[str(player_id)] = player.to_dict()
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_error("[GWInputManager] Cannot write to: %s" % path)
		return
	file.store_string(JSON.stringify(data, "\t"))
	file.close()


## Loads player binding profiles from a JSON file.
## Silently does nothing if the file does not exist.
## Only applies bindings to players that already exist.
func load_all_profiles(path: String = DEFAULT_SAVE_PATH) -> void:
	if not FileAccess.file_exists(path):
		return
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("[GWInputManager] Cannot read: %s" % path)
		return
	var content := file.get_as_text()
	file.close()
	var parsed := JSON.parse_string(content)
	if not parsed is Dictionary:
		push_error("[GWInputManager] Invalid JSON in: %s" % path)
		return
	for pid_str in (parsed as Dictionary):
		var pid := int(pid_str)
		if not players.has(pid):
			continue
		var player: GWPlayer = players[pid]
		player.apply_dict((parsed as Dictionary)[pid_str])
		for action_name in player.actions:
			binding_remapped.emit(pid, action_name)


## Restores all players to the default bindings defined in action templates.
func reset_all_to_defaults() -> void:
	for player_id in players:
		var player: GWPlayer = players[player_id]
		for action_name in _action_templates:
			var template: GWAction = _action_templates[action_name]
			player.actions[action_name] = template.duplicate_full()
			binding_remapped.emit(player_id, action_name)
		player.clear_input_state()


# --- Private: device scanning ---

func _scan_devices() -> void:
	devices[-1] = GWDevice.create_keyboard_mouse()
	for idx in Input.get_connected_joypads():
		devices[idx] = GWDevice.create_gamepad(idx)


func _on_joy_connection_changed(device_id: int, connected: bool) -> void:
	if connected:
		var d := GWDevice.create_gamepad(device_id)
		devices[device_id] = d
		# Hand the pad back to whoever owned it before it dropped.
		var owner_id: int = _pad_owner_on_disconnect.get(device_id, -1)
		_pad_owner_on_disconnect.erase(device_id)
		if players.has(owner_id):
			(players[owner_id] as GWPlayer).assign_gamepad(device_id)
		device_connected.emit(device_id, d.device_name)
	else:
		for player_id in players:
			var player: GWPlayer = players[player_id]
			if player.assigned_gamepads.has(device_id):
				_pad_owner_on_disconnect[device_id] = player_id
				player.unassign_gamepad(device_id)
			player.clear_input_state()
		if devices.has(device_id):
			(devices[device_id] as GWDevice).is_connected = false
			devices.erase(device_id)
		device_disconnected.emit(device_id)


func _on_player_device_assigned(device_id: int, player_id: int) -> void:
	# Exclusive assignment: take the pad away from any other player.
	for other_id in players:
		if other_id != player_id:
			(players[other_id] as GWPlayer).unassign_gamepad(device_id)
	if devices.has(device_id):
		(devices[device_id] as GWDevice).assigned_player = player_id


func _on_player_device_unassigned(device_id: int, player_id: int) -> void:
	if devices.has(device_id) and (devices[device_id] as GWDevice).assigned_player == player_id:
		(devices[device_id] as GWDevice).assigned_player = -1


## Connected pads an any-gamepad player may read: everything not assigned to
## another player.
func _free_gamepads_for(player_id: int) -> Array:
	var result: Array = []
	for dev_id in devices:
		if (dev_id as int) < 0:
			continue
		var owner_id := (devices[dev_id] as GWDevice).assigned_player
		if owner_id == -1 or owner_id == player_id:
			result.append(dev_id)
	return result


# --- Private: device join detection ---

func _get_event_device_id(event: InputEvent) -> int:
	if event is InputEventKey or event is InputEventMouseButton:
		return -1
	if event is InputEventJoypadButton:
		return (event as InputEventJoypadButton).device
	if event is InputEventJoypadMotion:
		return (event as InputEventJoypadMotion).device
	return -99


func _is_join_press(event: InputEvent) -> bool:
	if event is InputEventKey:
		var ev := event as InputEventKey
		return ev.is_pressed() and not ev.is_echo()
	if event is InputEventMouseButton:
		return (event as InputEventMouseButton).is_pressed()
	if event is InputEventJoypadButton:
		return (event as InputEventJoypadButton).is_pressed()
	if event is InputEventJoypadMotion:
		return absf((event as InputEventJoypadMotion).axis_value) > 0.5
	return false


func _is_device_unassigned(device_id: int) -> bool:
	if device_id == -99:
		return false
	for player_id in players:
		if (players[player_id] as GWPlayer).owns_device(device_id):
			return false
	return true


# --- Private: rebind processing ---

func _process_rebind_input(event: InputEvent) -> void:
	# Ignore mouse motion — it fires constantly and must never trigger a rebind.
	if event is InputEventMouseMotion:
		return

	# Escape cancels the active rebind.
	if event is InputEventKey:
		var ev := event as InputEventKey
		if ev.keycode == KEY_ESCAPE and ev.is_pressed() and not ev.is_echo():
			cancel_rebind_listen()
			get_viewport().set_input_as_handled()
			return

	var pid: int = _rebind_ctx["player_id"]
	var action_name: String = _rebind_ctx["action_name"]
	var binding_index: int = _rebind_ctx["binding_index"]
	var negative: bool = _rebind_ctx.get("negative", false)
	var player := get_player(pid)
	if player == null:
		cancel_rebind_listen()
		return

	# Only the rebinding player's own devices can provide the new input.
	var dev_id := _get_event_device_id(event)
	if dev_id == -99 or not player.owns_device(dev_id):
		return

	# Build the new binding from the first valid event. Pad bindings are stored
	# with device_id = -1 ("any pad this player owns") so they survive
	# reconnects and other machines.
	var new_binding: GWBinding = null

	if event is InputEventKey:
		var ev := event as InputEventKey
		if ev.is_pressed() and not ev.is_echo():
			new_binding = GWBinding.from_key(ev.keycode)
	elif event is InputEventMouseButton:
		var ev := event as InputEventMouseButton
		if ev.is_pressed():
			new_binding = GWBinding.from_mouse_button(ev.button_index)
	elif event is InputEventJoypadButton:
		var ev := event as InputEventJoypadButton
		if ev.is_pressed():
			new_binding = GWBinding.from_joy_button(ev.button_index)
	elif event is InputEventJoypadMotion:
		var ev := event as InputEventJoypadMotion
		if absf(ev.axis_value) > 0.5:
			var dir := 1.0 if ev.axis_value > 0.0 else -1.0
			new_binding = GWBinding.from_joy_axis(ev.axis, dir)

	if new_binding == null:
		return

	get_viewport().set_input_as_handled()
	if not player.set_binding(action_name, binding_index, new_binding, negative):
		push_warning("[GWInputManager] Slot %d of '%s' cannot be filled (max_bindings)." % [binding_index, action_name])
		cancel_rebind_listen()
		return

	var conflicts: Array[String] = []
	for other in player.find_conflicts(event, action_name):
		conflicts.append(other.action_name)
	_end_rebind()
	binding_remapped.emit(pid, action_name)
	if not conflicts.is_empty():
		rebind_conflict.emit(pid, action_name, conflicts)


## Leaves listen mode. Held state is reset because players received no input
## while listening, so a release may have been missed.
func _end_rebind() -> void:
	_rebind_ctx = {}
	for player_id in players:
		(players[player_id] as GWPlayer).clear_input_state()
