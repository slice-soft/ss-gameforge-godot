class_name SingletonNode
extends Node

# Keeps the active instance per script (singleton per script).
static var _instances: Dictionary = {}

# Returns the active instance for a given script, if any.
static func get_instance_for(script: Script) -> Node:
	return _instances.get(script) as Node

# Ensures an instance exists for the given script and adds it to the root.
# Optionally sets a custom name for the created instance.
static func ensure_for(script: Script, root: Node, instance_name: String = "") -> Node:
	var inst := get_instance_for(script)
	if inst:
		return inst

	inst = script.new() as Node
	if instance_name != "":
		inst.name = instance_name

	root.add_child(inst)
	return inst

# Register this node as the active instance for its script.
# If another instance is already active, free this one.
func _enter_tree() -> void:
	var key: Script = get_script()
	if _instances.has(key) and _instances[key] != self:
		queue_free()
		return
	_instances[key] = self

# Remove this node from the registry if it's the active instance.
func _exit_tree() -> void:
	var key: Script = get_script()
	if _instances.get(key) == self:
		_instances.erase(key)

# Returns true if this node is the active instance for its script.
func is_active_instance() -> bool:
	return _instances.get(get_script()) == self
