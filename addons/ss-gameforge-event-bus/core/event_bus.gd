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

## Prints every emission of the subclass's signals (debug builds only).
var trace: bool = false

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
		var cb: Callable = bindings[sig]
		if (sig as Signal).is_connected(cb):
			continue
		(sig as Signal).connect(cb)
		entry["bindings"].append([sig, cb])


## Disconnects everything `owner` registered through `listen()`.
func unlisten(owner: Node) -> void:
	var id := owner.get_instance_id()
	if not _registry.has(id):
		return
	var entry: Dictionary = _registry[id]
	_disconnect_bindings(entry)
	if owner.tree_exiting.is_connected(entry["hook"]):
		owner.tree_exiting.disconnect(entry["hook"])
	_registry.erase(id)


func _disconnect_bindings(entry: Dictionary) -> void:
	for pair in entry["bindings"]:
		var sig: Signal = pair[0]
		var cb: Callable = pair[1]
		if sig.is_connected(cb):
			sig.disconnect(cb)


# Drops entries whose owner was freed without leaving the tree (e.g. never added).
func _prune() -> void:
	for id in _registry.keys():
		var entry: Dictionary = _registry[id]
		if (entry["owner"] as WeakRef).get_ref() == null:
			_disconnect_bindings(entry)
			_registry.erase(id)
