extends RefCounted
class_name ToastStackManager

# Tracks active toast views and repositions them for stacking.
var _active_views: Array[ToastView] = []
var _stack_spacing: float = 8.0

# Sets vertical spacing between stacked toasts.
func set_stack_spacing(spacing: float) -> void:
	_stack_spacing = spacing

# Registers a view and reflows the stack.
func add_view(view: ToastView) -> void:
	if not _active_views.has(view):
		_active_views.append(view)
		_reflow_stack()

# Removes a view and reflows the stack.
func remove_view(view: ToastView) -> void:
	_active_views.erase(view)
	_reflow_stack()

# Returns the total number of active toasts.
func get_active_count() -> int:
	return _active_views.size()

# Returns the number of active toasts at a given position.
func get_active_count_at_position(position: ToastConstants.ToastPosition) -> int:
	var count := 0
	for view in _active_views:
		if view != null and is_instance_valid(view):
			if view.get_base_position() == position:
				count += 1
	return count

# Removes freed views from the list.
func cleanup_invalid_views() -> void:
	_active_views = _active_views.filter(func(view): return is_instance_valid(view))

# Recomputes stacking order per position.
func _reflow_stack() -> void:
	cleanup_invalid_views()
	
	var views_by_position := {}
	for view in _active_views:
		if view == null or not is_instance_valid(view):
			continue
		
		var pos: int = view.get_base_position()
		if not views_by_position.has(pos):
			views_by_position[pos] = []
		views_by_position[pos].append(view)
	
	for pos in views_by_position.keys():
		var views_at_position: Array = views_by_position[pos]
		for i in range(views_at_position.size()):
			var view: ToastView = views_at_position[i]
			if view != null and is_instance_valid(view):
				view.apply_stack(i, _stack_spacing)

# Clears all tracked views.
func clear() -> void:
	_active_views.clear()

# Returns all views that share the same base position.
func get_views_at_position(position: ToastConstants.ToastPosition) -> Array[ToastView]:
	var result: Array[ToastView] = []
	for view in _active_views:
		if view != null and is_instance_valid(view):
			if view.get_base_position() == position:
				result.append(view)
	return result