class_name StateMachine extends Node
## Improved state machine with validations and logging.

signal state_changed(from: String, to: String)

@onready var controlled_node = self.owner

@export var default_state: StateBase
@export var enable_debug_logging: bool = false

var current_state: StateBase = null
var previous_state: StateBase = null

# Debug statistics.
var state_changes: int = 0
var state_history: Array[String] = []
const MAX_HISTORY: int = 10


func _ready() -> void:
	call_deferred("_state_default_start")


func _state_default_start() -> void:
	if not default_state:
		push_error("[StateMachine] No default_state set on %s" % owner.name)
		return
	current_state = default_state
	_state_start()


func change_to(new_state: String) -> void:
	# Validate: state exists.
	if not has_node(new_state):
		push_error("[StateMachine] State not found: %s on %s" % [new_state, owner.name])
		return

	# Validate: avoid transitioning to the same state (comment out if needed).
	if current_state and current_state.name == new_state:
		if enable_debug_logging:
			push_warning("[StateMachine] Attempted transition to the same state: %s" % new_state)
		return

	# Log transition.
	if enable_debug_logging and OS.is_debug_build():
		var from_state: String = "null"
		if current_state:
			from_state = current_state.name
		print("[StateMachine] %s: %s -> %s" % [owner.name, from_state, new_state])

	var from_name: String = current_state.name if current_state else ""

	# Run end() on the current state.
	if current_state:
		if current_state.has_method("end"):
			current_state.end()
		previous_state = current_state

	# Switch to the new state.
	current_state = get_node(new_state)

	# Update statistics.
	state_changes += 1
	_update_history(new_state)

	_state_start()
	state_changed.emit(from_name, new_state)


func change_to_previous() -> void:
	if previous_state == null:
		if enable_debug_logging:
			push_warning("[StateMachine] No previous state to return to on %s" % owner.name)
		return
	change_to(previous_state.name)


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
