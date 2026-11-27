## An abstract action that groups between 1 and N physical bindings.
## This is the interface gameplay code uses — it never references keys or buttons directly.
extends Resource
class_name GWAction

signal binding_added(binding: GWBinding)
signal binding_removed(index: int)
signal bindings_cleared()

## Whether this action is a digital button or an analog axis.
enum ActionType { BUTTON, AXIS }

## Internal identifier used in gameplay code (e.g. "jump", "attack").
var action_name: String = ""
## Label shown in the rebind UI (e.g. "Jump", "Attack").
var display_name: String = ""
## Optional tooltip shown in the rebind UI.
var description: String = ""
## Groups this action with others in the UI (e.g. "Movement", "Combat").
var category: String = "General"
## Maximum number of simultaneous bindings. 0 = unlimited.
var max_bindings: int = 2
## Whether this action is a digital button or an analog axis.
var action_type: ActionType = ActionType.BUTTON
## Axis only — label for the positive direction (e.g. "right", "up").
var positive_name: String = ""
## Axis only — label for the negative direction (e.g. "left", "down").
var negative_name: String = ""
## If false, this action does not appear as editable in the rebind UI.
var allow_rebind: bool = true
## Active bindings list (positive direction for AXIS actions).
var bindings: Array[GWBinding] = []
## Axis only — bindings that push toward -1.0.
var negative_bindings: Array[GWBinding] = []


# --- Binding management ---

## Appends a binding. Returns false if max_bindings is already reached.
func add_binding(binding: GWBinding) -> bool:
	if max_bindings > 0 and bindings.size() >= max_bindings:
		return false
	bindings.append(binding)
	binding_added.emit(binding)
	return true


## Sets or replaces the binding at the given slot index.
## An index at or past the end appends, if max_bindings allows.
## With negative = true it writes the negative side of an AXIS action.
## Returns false if the binding could not be stored.
func set_binding(index: int, binding: GWBinding, negative: bool = false) -> bool:
	if index < 0:
		return false
	var list := negative_bindings if negative else bindings
	if index < list.size():
		list[index] = binding
	elif max_bindings == 0 or list.size() < max_bindings:
		list.append(binding)
	else:
		return false
	binding_added.emit(binding)
	return true


## Removes the binding at the given slot index.
func remove_binding(index: int) -> void:
	if index < 0 or index >= bindings.size():
		return
	bindings.remove_at(index)
	binding_removed.emit(index)


## Clears all bindings from this action.
func clear_bindings() -> void:
	bindings.clear()
	bindings_cleared.emit()


# --- Polling evaluation ---

## Returns true if any binding is currently held.
func is_pressed(assigned_devices: Array) -> bool:
	for binding in bindings:
		if binding.is_pressed(assigned_devices):
			return true
	return false


## Returns the maximum strength among all bindings in [0.0, 1.0].
func get_strength(assigned_devices: Array) -> float:
	var best := 0.0
	for binding in bindings:
		best = maxf(best, binding.get_strength(assigned_devices))
	return best


## For AXIS actions: returns net value in [-1.0, 1.0].
## bindings push toward +1.0, negative_bindings push toward -1.0.
func get_axis(assigned_devices: Array) -> float:
	var pos := 0.0
	for b in bindings:
		pos = maxf(pos, b.get_strength(assigned_devices))
	var neg := 0.0
	for b in negative_bindings:
		neg = maxf(neg, b.get_strength(assigned_devices))
	return clampf(pos - neg, -1.0, 1.0)


## Returns true if any binding on either side is held.
## For BUTTON actions this equals is_pressed(); for AXIS actions it also counts the negative side.
## This is the state just_pressed / just_released edges are computed from.
func is_active(assigned_devices: Array) -> bool:
	if is_pressed(assigned_devices):
		return true
	for binding in negative_bindings:
		if binding.is_pressed(assigned_devices):
			return true
	return false


## Returns true if the event comes from an input bound on either side of this action.
func matches_event(event: InputEvent) -> bool:
	for binding in bindings:
		if binding.matches_input(event):
			return true
	for binding in negative_bindings:
		if binding.matches_input(event):
			return true
	return false


# --- Event-based evaluation ---

## Returns true if any binding matches a just-pressed InputEvent.
func was_just_pressed(assigned_devices: Array, event: InputEvent) -> bool:
	if event.is_echo() or not event.is_pressed():
		return false
	for binding in bindings:
		if binding.matches_event(event):
			return true
	return false


## Returns true if any binding matches a just-released InputEvent.
func was_just_released(assigned_devices: Array, event: InputEvent) -> bool:
	if event.is_pressed():
		return false
	for binding in bindings:
		if binding.matches_event(event):
			return true
	return false


# --- Conflict detection ---

## Returns true if any of this action's bindings (either side) would match the given event.
func conflicts_with_event(event: InputEvent) -> bool:
	for binding in bindings:
		if binding.matches_event(event):
			return true
	for binding in negative_bindings:
		if binding.matches_event(event):
			return true
	return false


# --- Deep clone ---

## Creates an independent deep copy of this action, including all bindings.
## Used internally when assigning action templates to a new GWPlayer.
func duplicate_full() -> GWAction:
	var copy := GWAction.new()
	copy.action_name = action_name
	copy.display_name = display_name
	copy.description = description
	copy.category = category
	copy.max_bindings = max_bindings
	copy.action_type = action_type
	copy.positive_name = positive_name
	copy.negative_name = negative_name
	copy.allow_rebind = allow_rebind
	for b in bindings:
		copy.bindings.append(b.duplicate() as GWBinding)
	for b in negative_bindings:
		copy.negative_bindings.append(b.duplicate() as GWBinding)
	return copy
