extends SingletonNode
class_name EventBus

## Base class for a game's event bus.
##
## Extend it, declare your game's typed signals, and add the `.i` accessor:
##
##     class_name GameEvents extends EventBus
##     static var i: GameEvents:
##         get: return SingletonNode.get_instance_for(GameEvents) as GameEvents
##     signal player_died(player_id: int)
##
## Emit with the native API (`GameEvents.i.player_died.emit(1)`) and subscribe with
## `listen()`, which disconnects automatically when the owner leaves the tree.

## Prints every emission of the subclass's signals, one line each (debug builds only).
var trace: bool = false:
	set(value):
		trace = value
		_update_trace_hooks()

# signal name -> logger Callable connected while trace is on
var _trace_hooks: Dictionary = {}

# owner instance id -> { "owner": WeakRef, "bindings": Array[[Signal, Callable]], "hook": Callable }
var _registry: Dictionary = {}


## Connects every `Signal -> Callable` pair in `bindings` on behalf of `owner`.
## All of them are disconnected when `owner` leaves the scene tree, or on `unlisten(owner)`.
## Call it from `_enter_tree()` so a node re-added to the tree subscribes again.
func listen(owner: Node, bindings: Dictionary) -> void:
	_prune()
	if OS.is_debug_build() and not owner.is_inside_tree():
		push_warning("EventBus.listen(): %s is not in the scene tree; its bindings are only removed on tree exit or unlisten()." % owner)
	var id := owner.get_instance_id()
	if not _registry.has(id):
		var hook := unlisten.bind(owner)
		_registry[id] = {"owner": weakref(owner), "bindings": [], "hook": hook}
		owner.tree_exiting.connect(hook, CONNECT_ONE_SHOT)
	var entry: Dictionary = _registry[id]
	for sig in bindings:
		var pair := [sig, bindings[sig]]
		if _owns(entry, pair):
			continue
		if not (sig as Signal).is_connected(pair[1]):
			(sig as Signal).connect(pair[1])
		entry["bindings"].append(pair)


## Disconnects everything `owner` registered through `listen()`.
func unlisten(owner: Node) -> void:
	_prune()
	var id := owner.get_instance_id()
	if not _registry.has(id):
		return
	var entry: Dictionary = _registry[id]
	_disconnect_bindings(id)
	if owner.tree_exiting.is_connected(entry["hook"]):
		owner.tree_exiting.disconnect(entry["hook"])
	_registry.erase(id)


# Disconnects the entry's pairs, except those another owner still holds: the same
# Callable on the same Signal is a single Godot connection shared by every owner.
func _disconnect_bindings(id: int) -> void:
	for pair in _registry[id]["bindings"]:
		if _held_elsewhere(id, pair):
			continue
		var sig: Signal = pair[0]
		var cb: Callable = pair[1]
		if sig.is_connected(cb):
			sig.disconnect(cb)


func _owns(entry: Dictionary, pair: Array) -> bool:
	for p in entry["bindings"]:
		if p[0] == pair[0] and p[1] == pair[1]:
			return true
	return false


func _held_elsewhere(id: int, pair: Array) -> bool:
	for other_id in _registry:
		if other_id != id and _owns(_registry[other_id], pair):
			return true
	return false


# Drops entries whose owner was freed without leaving the tree (e.g. never added).
func _prune() -> void:
	for id in _registry.keys():
		var entry: Dictionary = _registry[id]
		if (entry["owner"] as WeakRef).get_ref() == null:
			_disconnect_bindings(id)
			_registry.erase(id)


func _update_trace_hooks() -> void:
	var enable := trace and OS.is_debug_build()
	if enable:
		for info in get_script().get_script_signal_list():
			var signal_name: StringName = info["name"]
			if _trace_hooks.has(signal_name):
				continue
			var hook := _on_traced.bind(signal_name)
			connect(signal_name, hook)
			_trace_hooks[signal_name] = hook
	else:
		for signal_name in _trace_hooks:
			if is_connected(signal_name, _trace_hooks[signal_name]):
				disconnect(signal_name, _trace_hooks[signal_name])
		_trace_hooks.clear()


# Bound with the signal name, which arrives as the last argument.
func _on_traced(...args: Array) -> void:
	var signal_name: StringName = args.pop_back()
	print(_format_trace(signal_name, args))


func _format_trace(signal_name: StringName, args: Array) -> String:
	return "[EventBus] %s(%s)" % [signal_name, ", ".join(args.map(func(a): return str(a)))]
