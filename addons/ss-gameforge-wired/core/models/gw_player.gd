## A logical player with independent copies of all actions and its own device list.
## Uses RefCounted — not a Node — to avoid SceneTree coupling.
extends RefCounted
class_name GWPlayer

signal device_assigned(device_id: int)
signal device_unassigned(device_id: int)
signal action_rebound(action_name: String)

## Unique identifier for this player.
var player_id: int = 0
## Display name shown in the UI.
var player_name: String = ""
## IDs of gamepads exclusively assigned to this player.
var assigned_gamepads: Array[int] = []
## Whether this player processes keyboard and mouse events.
var accepts_keyboard: bool = false
## Whether this player also reads every connected gamepad that no other player
## has claimed with assign_gamepad(). Set for player 0 in SINGLE and ONLINE modes.
var accepts_any_gamepad: bool = false
## Private copies of all registered actions keyed by action_name.
var actions: Dictionary = {}

## Returns the gamepad ids an any-gamepad player may read. GWInputManager
## replaces it so pads owned by other players are left out.
var free_gamepads_source: Callable = func() -> Array: return Input.get_connected_joypads()

# Edge-detection state, fed by feed_event().
var _held: Dictionary = {}            # action_name -> bool
var _pressed_frames: Dictionary = {}  # action_name -> Vector2i(process_frame, physics_frame)
var _released_frames: Dictionary = {} # action_name -> Vector2i(process_frame, physics_frame)
var _last_event: InputEvent = null
var _last_event_pressed: Array[String] = []
var _last_event_released: Array[String] = []
var _warned_missing: Dictionary = {}


# --- Device API ---

## Assigns the given gamepad to this player.
func assign_gamepad(device_id: int) -> void:
	if not assigned_gamepads.has(device_id):
		assigned_gamepads.append(device_id)
		device_assigned.emit(device_id)


## Removes the given gamepad from this player.
func unassign_gamepad(device_id: int) -> void:
	var idx := assigned_gamepads.find(device_id)
	if idx >= 0:
		assigned_gamepads.remove_at(idx)
		device_unassigned.emit(device_id)


## Removes all assigned gamepads from this player.
func unassign_all_gamepads() -> void:
	for dev_id in assigned_gamepads.duplicate():
		unassign_gamepad(dev_id)


## Returns true if this player has at least one device (keyboard or any gamepad).
func has_any_device() -> bool:
	return accepts_keyboard or accepts_any_gamepad or not assigned_gamepads.is_empty()


## Returns the array of active device IDs for this player.
## -1 is included when accepts_keyboard is true. With accepts_any_gamepad,
## every free connected pad is included as well.
func get_active_device_ids() -> Array:
	var ids: Array = []
	if accepts_keyboard:
		ids.append(-1)
	for dev_id in assigned_gamepads:
		ids.append(dev_id)
	if accepts_any_gamepad:
		for dev_id in free_gamepads_source.call():
			if not ids.has(dev_id):
				ids.append(dev_id)
	return ids


## Returns true if input from the given device id belongs to this player.
## -1 is keyboard/mouse; ids >= 0 are gamepads.
func owns_device(device_id: int) -> bool:
	if device_id == -1:
		return accepts_keyboard
	if device_id < -1:
		return false
	if assigned_gamepads.has(device_id):
		return true
	return accepts_any_gamepad and free_gamepads_source.call().has(device_id)


# --- Gameplay API ---

## Returns true if the named action is currently held by this player.
func is_action_pressed(action_name: String) -> bool:
	var action := _get_action(action_name)
	if action == null:
		return false
	return action.is_pressed(get_active_device_ids())


## Returns the current strength [0.0, 1.0] of the named action for this player.
func get_action_strength(action_name: String) -> float:
	var action := _get_action(action_name)
	if action == null:
		return 0.0
	return action.get_strength(get_active_device_ids())


## For AXIS actions: returns net value in [-1.0, 1.0].
func get_action_axis(action_name: String) -> float:
	var action := _get_action(action_name)
	if action == null:
		return 0.0
	return action.get_axis(get_active_device_ids())


## Returns true if this event turned the action on (it was not held before).
## Only true when the event's device belongs to this player. Holding a stick,
## key repeat and pressing a second binding of an already held action do not count.
func is_action_just_pressed(action_name: String, event: InputEvent) -> bool:
	if _get_action(action_name) == null:
		return false
	feed_event(event)
	return _last_event_pressed.has(action_name)


## Returns true if this event turned the action off (no binding is held anymore).
## Only true when the event's device belongs to this player.
func is_action_just_released(action_name: String, event: InputEvent) -> bool:
	if _get_action(action_name) == null:
		return false
	feed_event(event)
	return _last_event_released.has(action_name)


## Returns true if the action turned on during the current process frame, or
## the current physics frame when called from _physics_process().
func is_action_just_pressed_this_frame(action_name: String) -> bool:
	return _is_current_frame(_pressed_frames.get(action_name, Vector2i(-1, -1)))


## Returns true if the action turned off during the current process frame, or
## the current physics frame when called from _physics_process().
func is_action_just_released_this_frame(action_name: String) -> bool:
	return _is_current_frame(_released_frames.get(action_name, Vector2i(-1, -1)))


## Updates edge state from an input event. GWInputManager calls it for every
## event; calling it again with the same event object is a no-op, so the
## event-based queries above are safe whichever node sees the event first.
func feed_event(event: InputEvent) -> void:
	if event == _last_event:
		return
	_last_event = event
	_last_event_pressed.clear()
	_last_event_released.clear()
	if not _event_belongs_to_player(event):
		return
	var devs := get_active_device_ids()
	# Physics frames advance at the start of each step, so an event handled
	# outside a step belongs to the next one.
	var physics := Engine.get_physics_frames() + (0 if Engine.is_in_physics_frame() else 1)
	var frames := Vector2i(Engine.get_process_frames(), physics)
	for a_name in actions:
		var action: GWAction = actions[a_name]
		if not action.matches_event(event):
			continue
		var was: bool = _held.get(a_name, false)
		var now := action.is_active(devs)
		if now and not was:
			_mark_pressed(a_name, frames)
		elif was and not now:
			_mark_released(a_name, frames)
		elif not now and event is InputEventMouseButton and event.is_pressed():
			# Wheel "buttons" never read as held: count the press itself.
			_mark_pressed(a_name, frames)
		_held[a_name] = now


## Forgets all held/edge state. Called when bindings or devices change under it.
func clear_input_state() -> void:
	_held.clear()
	_pressed_frames.clear()
	_released_frames.clear()
	_last_event = null
	_last_event_pressed.clear()
	_last_event_released.clear()


## Returns a movement vector from four directional action names.
## Clamped to unit length when the raw magnitude exceeds 1.0.
func get_vector(neg_x: String, pos_x: String, neg_y: String, pos_y: String) -> Vector2:
	var x := get_action_strength(pos_x) - get_action_strength(neg_x)
	var y := get_action_strength(pos_y) - get_action_strength(neg_y)
	var v := Vector2(x, y)
	return v if v.length_squared() <= 1.0 else v.normalized()


# --- Rebinding API ---

## Sets or replaces the binding at slot index for the named action.
## With negative = true it writes the negative side of an AXIS action.
## Returns false if the action does not exist or the slot cannot be filled.
func set_binding(action_name: String, index: int, binding: GWBinding, negative: bool = false) -> bool:
	var action := _get_action(action_name)
	if action == null:
		return false
	if not action.set_binding(index, binding, negative):
		return false
	_held.erase(action_name)
	action_rebound.emit(action_name)
	return true


## Clears all bindings for the named action.
func clear_action_bindings(action_name: String) -> void:
	var action := _get_action(action_name)
	if action == null:
		return
	action.clear_bindings()
	_held.erase(action_name)
	action_rebound.emit(action_name)


## Returns all actions whose bindings conflict with the given event.
## exclude_action is excluded from the search (typically the action being rebound).
func find_conflicts(event: InputEvent, exclude_action: String = "") -> Array[GWAction]:
	var conflicts: Array[GWAction] = []
	for a_name in actions:
		if a_name == exclude_action:
			continue
		var action: GWAction = actions[a_name]
		if action.conflicts_with_event(event):
			conflicts.append(action)
	return conflicts


# --- Serialization ---

## Serializes this player's bindings and device config to a plain Dictionary.
func to_dict() -> Dictionary:
	var action_dicts: Dictionary = {}
	for a_name in actions:
		var action: GWAction = actions[a_name]
		var binding_list: Array = []
		for b in action.bindings:
			binding_list.append(b.to_dict())
		var neg_list: Array = []
		for b in action.negative_bindings:
			neg_list.append(b.to_dict())
		action_dicts[a_name] = {
			"action_name": action.action_name,
			"bindings": binding_list,
			"negative_bindings": neg_list,
		}
	return {
		"player_id": player_id,
		"player_name": player_name,
		"accepts_keyboard": accepts_keyboard,
		"accepts_any_gamepad": accepts_any_gamepad,
		"actions": action_dicts,
	}


## Applies serialized bindings and keyboard/any-gamepad flags from a Dictionary
## without recreating the player. Gamepad assignments are not restored: device
## ids change between sessions. Emits action_rebound for each restored action.
func apply_dict(d: Dictionary) -> void:
	accepts_keyboard = d.get("accepts_keyboard", accepts_keyboard)
	accepts_any_gamepad = d.get("accepts_any_gamepad", accepts_any_gamepad)
	var saved_actions: Dictionary = d.get("actions", {})
	for a_name in saved_actions:
		if not actions.has(a_name):
			continue
		var action: GWAction = actions[a_name]
		action.clear_bindings()
		action.negative_bindings.clear()
		for b_dict in saved_actions[a_name].get("bindings", []):
			action.add_binding(GWBinding.from_dict(b_dict))
		for b_dict in saved_actions[a_name].get("negative_bindings", []):
			action.set_binding(action.negative_bindings.size(), GWBinding.from_dict(b_dict), true)
		_held.erase(a_name)
		action_rebound.emit(a_name)


# --- Private ---

func _get_action(action_name: String) -> GWAction:
	if not actions.has(action_name):
		if not _warned_missing.has(action_name):
			_warned_missing[action_name] = true
			push_warning("[GWPlayer] Action not found: %s" % action_name)
		return null
	return actions[action_name] as GWAction


func _event_belongs_to_player(event: InputEvent) -> bool:
	if event is InputEventKey or event is InputEventMouseButton:
		return accepts_keyboard
	if event is InputEventJoypadButton or event is InputEventJoypadMotion:
		return owns_device(event.device)
	return false


func _mark_pressed(a_name: String, frames: Vector2i) -> void:
	_pressed_frames[a_name] = frames
	_last_event_pressed.append(a_name)


func _mark_released(a_name: String, frames: Vector2i) -> void:
	_released_frames[a_name] = frames
	_last_event_released.append(a_name)


static func _is_current_frame(frames: Vector2i) -> bool:
	if Engine.is_in_physics_frame():
		return frames.y == Engine.get_physics_frames()
	return frames.x == Engine.get_process_frames()
