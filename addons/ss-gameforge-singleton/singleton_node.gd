class_name SingletonNode
extends Node

# Keeps the active instance per script (singleton per script).
static var _instances: Dictionary = {}

# Returns the active instance for a given script, if any. An instance created by
# ensure_for() is returned right away, before it has entered the tree.
static func get_instance_for(script: Script) -> Node:
	if not _instances.has(script):
		return null
	var inst = _instances[script]
	if not is_instance_valid(inst):
		_instances.erase(script)
		return null
	return inst as Node

# Ensures an instance exists for the given script and adds it to the root.
# Optionally sets a custom name for the created instance.
# The node is registered immediately, so calling it again (or reading the
# instance) in the same frame returns the same node. It is added to `root`
# deferred, so it enters the tree at the end of the frame.
static func ensure_for(script: Script, root: Node, instance_name: String = "") -> Node:
	var inst := get_instance_for(script)
	if inst:
		return inst

	inst = script.new() as Node
	if instance_name != "":
		inst.name = instance_name

	_instances[script] = inst
	_add_when_idle.call_deferred(root.get_instance_id(), inst.get_instance_id())
	return inst

# Deferred add that tolerates the root or the instance being freed meanwhile.
static func _add_when_idle(root_id: int, inst_id: int) -> void:
	var root := instance_from_id(root_id) as Node
	var inst := instance_from_id(inst_id) as Node
	if root == null or inst == null or inst.is_queued_for_deletion() or inst.get_parent() != null:
		return
	root.add_child(inst)

# Register this node as the active instance for its script.
# If another instance is already active in the tree, this one is disabled and
# freed. A pending ensure_for() instance that has not entered the tree yet is
# replaced by this one.
# Subclasses that override _enter_tree() must call super().
func _enter_tree() -> void:
	var key: Script = get_script()
	var active := get_instance_for(key)
	if active != null and active != self and not active.is_inside_tree():
		# An ensure_for() instance still waiting for its deferred add yields to a
		# node that actually enters the tree (e.g. one placed in a scene, with its
		# inspector settings).
		active.queue_free()
		active = null
	if active != null and active != self:
		push_warning("SingletonNode: %s is a second %s; the active one is %s. Freeing the new one." % [
			get_path(), _script_label(key), active.get_path() if active.is_inside_tree() else str(active)])
		process_mode = Node.PROCESS_MODE_DISABLED
		queue_free()
		return
	_instances[key] = self

static func _script_label(script: Script) -> String:
	if script.get_global_name() != &"":
		return script.get_global_name()
	if script.resource_path != "":
		return script.resource_path.get_file()
	return str(script)

# Remove this node from the registry if it's the active instance.
# Subclasses that override _exit_tree() must call super().
func _exit_tree() -> void:
	var key: Script = get_script()
	if _instances.get(key) == self:
		_instances.erase(key)

# Returns true if this node is the active instance for its script. A duplicate
# still runs its own _ready() before it is freed; guard work there with this.
func is_active_instance() -> bool:
	return _instances.get(get_script()) == self
