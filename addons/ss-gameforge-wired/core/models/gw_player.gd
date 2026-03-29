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
## Private copies of all registered actions keyed by action_name.
var actions: Dictionary = {}


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
	return accepts_keyboard or not assigned_gamepads.is_empty()


## Returns the array of active device IDs for this player.
## -1 is included when accepts_keyboard is true.
func get_active_device_ids() -> Array:
	var ids: Array = []
	if accepts_keyboard:
		ids.append(-1)
	for dev_id in assigned_gamepads:
		ids.append(dev_id)
	return ids


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


## Returns true if the action was just pressed in the given event.
## Only true when the event's device belongs to this player.
func is_action_just_pressed(action_name: String, event: InputEvent) -> bool:
	if not _event_belongs_to_player(event):
		return false
	var action := _get_action(action_name)
	if action == null:
		return false
	return action.was_just_pressed(get_active_device_ids(), event)


## Returns true if the action was just released in the given event.
## Only true when the event's device belongs to this player.
func is_action_just_released(action_name: String, event: InputEvent) -> bool:
	if not _event_belongs_to_player(event):
		return false
	var action := _get_action(action_name)
	if action == null:
		return false
	return action.was_just_released(get_active_device_ids(), event)


## Returns a movement vector from four directional action names.
## Clamped to unit length when the raw magnitude exceeds 1.0.
func get_vector(neg_x: String, pos_x: String, neg_y: String, pos_y: String) -> Vector2:
	var x := get_action_strength(pos_x) - get_action_strength(neg_x)
	var y := get_action_strength(pos_y) - get_action_strength(neg_y)
	var v := Vector2(x, y)
	return v if v.length_squared() <= 1.0 else v.normalized()


# --- Rebinding API ---

## Sets or replaces the binding at slot index for the named action.
## Returns false if the action does not exist.
func set_binding(action_name: String, index: int, binding: GWBinding) -> bool:
	var action := _get_action(action_name)
	if action == null:
		return false
	action.set_binding(index, binding)
	action_rebound.emit(action_name)
	return true


## Clears all bindings for the named action.
func clear_action_bindings(action_name: String) -> void:
	var action := _get_action(action_name)
	if action == null:
		return
	action.clear_bindings()
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
		action_dicts[a_name] = {
			"action_name": action.action_name,
			"bindings": binding_list,
		}
	return {
		"player_id": player_id,
		"player_name": player_name,
		"accepts_keyboard": accepts_keyboard,
		"actions": action_dicts,
	}


## Applies serialized bindings from a Dictionary without recreating the player.
## Emits action_rebound for each restored action.
func apply_dict(d: Dictionary) -> void:
	var saved_actions: Dictionary = d.get("actions", {})
	for a_name in saved_actions:
		if not actions.has(a_name):
			continue
		var action: GWAction = actions[a_name]
		action.clear_bindings()
		for b_dict in saved_actions[a_name].get("bindings", []):
			action.add_binding(GWBinding.from_dict(b_dict))
		action_rebound.emit(a_name)


# --- Private ---

func _get_action(action_name: String) -> GWAction:
	if not actions.has(action_name):
		push_warning("[GWPlayer] Action not found: %s" % action_name)
		return null
	return actions[action_name] as GWAction


func _event_belongs_to_player(event: InputEvent) -> bool:
	if event is InputEventKey or event is InputEventMouseButton:
		return accepts_keyboard
	if event is InputEventJoypadButton:
		return assigned_gamepads.has((event as InputEventJoypadButton).device)
	if event is InputEventJoypadMotion:
		return assigned_gamepads.has((event as InputEventJoypadMotion).device)
	return false
