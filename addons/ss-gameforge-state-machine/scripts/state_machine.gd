class_name StateMachine extends Node
## Improved state machine with validations and logging.

## Fires after the new state has started. `from` is "" for the default state.
signal state_changed(from: String, to: String)

## The node the states act on: the machine's owner (the scene root), or its
## parent when the machine itself is the scene root.
@onready var controlled_node: Node = owner if owner != null else get_parent()

@export var default_state: StateBase
@export var enable_debug_logging: bool = false

var current_state: StateBase = null
var previous_state: StateBase = null

# Debug statistics.
var state_changes: int = 0
var state_history: Array[String] = []
const MAX_HISTORY: int = 10

# True while end()/start() of a transition run; change_to() calls made from
# them are queued and run once the current transition has finished.
var _transitioning := false
var _pending: Array[String] = []


func _ready() -> void:
	call_deferred("_state_default_start")


func _state_default_start() -> void:
	# A change_to() before this deferred start already picked the first state.
	if current_state != null:
		return
	if not default_state:
		push_error("[StateMachine] No default_state set on %s" % _host_name())
		return
	_enter(default_state)


func change_to(new_state: String) -> void:
	if _transitioning:
		_pending.append(new_state)
		return

	# Validate: state exists and is a state.
	if not has_node(new_state):
		push_error("[StateMachine] State not found: %s on %s" % [new_state, _host_name()])
		return
	var target := get_node(new_state) as StateBase
	if target == null:
		push_error("[StateMachine] %s on %s is not a StateBase" % [new_state, _host_name()])
		return

	# Validate: avoid transitioning to the same state.
	if current_state == target:
		if enable_debug_logging:
			push_warning("[StateMachine] Attempted transition to the same state: %s" % new_state)
		return

	_enter(target)


func change_to_previous() -> void:
	if previous_state == null:
		if enable_debug_logging:
			push_warning("[StateMachine] No previous state to return to on %s" % _host_name())
		return
	change_to(previous_state.name)


# Ends the current state, starts `target`, emits state_changed, then runs any
# transition requested meanwhile, so listeners always see transitions in order.
func _enter(target: StateBase) -> void:
	var from_name: String = current_state.name if current_state else ""

	if enable_debug_logging and OS.is_debug_build():
		print("[StateMachine] %s: %s -> %s" % [_host_name(), from_name if from_name != "" else "null", target.name])

	_transitioning = true
	if current_state:
		if current_state.has_method("end"):
			current_state.end()
		previous_state = current_state

	current_state = target
	state_changes += 1
	_update_history(target.name)
	_state_start()
	_transitioning = false

	state_changed.emit(from_name, target.name)

	while not _pending.is_empty() and not _transitioning:
		change_to(_pending.pop_front())


func _update_history(state_name: String) -> void:
	"""Maintains a state history for debugging."""
	state_history.append(state_name)
	if state_history.size() > MAX_HISTORY:
		state_history.pop_front()


func get_state_history() -> Array[String]:
	"""Returns the state history (useful for debugging)."""
	return state_history.duplicate()

func _state_start() -> void:
	current_state.controlled_node = controlled_node
	current_state.state_machine = self
	current_state.start()

func _host_name() -> String:
	return String(controlled_node.name) if controlled_node != null else String(name)

func _process(delta: float) -> void:
	if current_state and current_state.has_method("on_process"):
		current_state.on_process(delta)

func _physics_process(delta: float) -> void:
	if current_state and current_state.has_method("on_physics_process"):
		current_state.on_physics_process(delta)

func _input(event: InputEvent) -> void:
	if current_state and current_state.has_method("on_input"):
		current_state.on_input(event)

func _unhandled_input(event: InputEvent) -> void:
	if current_state and current_state.has_method("on_unhandled_input"):
		current_state.on_unhandled_input(event)

func _unhandled_key_input(event: InputEvent) -> void:
	if current_state and current_state.has_method("on_unhandled_key_input"):
		current_state.on_unhandled_key_input(event)
