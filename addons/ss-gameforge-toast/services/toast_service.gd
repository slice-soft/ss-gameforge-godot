extends SingletonNode
class_name ToastService

# Central singleton entry point to show toast notifications.
const TOAST_VIEW_SCENE := preload("res://addons/ss-gameforge-toast/scenes/toast_view.tscn")
var DEFAULT_THEME := load("res://addons/ss-gameforge-toast/themes/toast_default.tres") as ToastTheme

var _queue_manager := ToastQueueManager.new()
var _stack_manager := ToastStackManager.new()

@export var theme: ToastTheme
@export var max_queue := 50:
	set(value):
		max_queue = value
		_queue_manager.set_max_size(value)
@export var stack_toasts := true
@export var max_visible := 4
@export var stack_spacing := 8.0:
	set(value):
		stack_spacing = value
		_stack_manager.set_stack_spacing(value)
		_stack_manager.reflow()
## Canvas layer the toasts are drawn on. Toasts live on their own CanvasLayer, so
## cameras never move them and they draw above HUD layers with a lower value.
@export var layer := 100:
	set(value):
		layer = value
		if _layer != null:
			_layer.layer = value

# Convenient singleton accessor.
static var i: ToastService:
	get:
		return SingletonNode.get_instance_for(ToastService) as ToastService

var _is_showing_single := false
var _layer: CanvasLayer

# Applies queue and stack settings, and shows anything queued before the service
# entered the tree.
func _ready() -> void:
	_queue_manager.set_max_size(max_queue)
	_stack_manager.set_stack_spacing(stack_spacing)
	_try_show_next()

# Enqueues a toast and triggers playback if possible.
func show(text: String, style: ToastConstants.ToastStyle = ToastConstants.ToastStyle.INFO, overrides: Dictionary = {}) -> void:
	var toast_data := ToastData.new(text, style, overrides)
	_queue_manager.enqueue(toast_data)
	_try_show_next()

# Convenience helpers for standard toast styles.
func info(text: String, overrides: Dictionary = {}) -> void:
	show(text, ToastConstants.ToastStyle.INFO, overrides)

func success(text: String, overrides: Dictionary = {}) -> void:
	show(text, ToastConstants.ToastStyle.SUCCESS, overrides)

func danger(text: String, overrides: Dictionary = {}) -> void:
	show(text, ToastConstants.ToastStyle.DANGER, overrides)

func custom(text: String, overrides: Dictionary = {}) -> void:
	show(text, ToastConstants.ToastStyle.CUSTOM, overrides)

# Loader toasts default to a spinning icon unless overridden.
func loader(text: String, overrides: Dictionary = {}) -> void:
	var effective_theme := _get_effective_theme()
	var merged := _prepare_loader_overrides(effective_theme, overrides)
	show(text, ToastConstants.ToastStyle.LOADER, merged)

## Shows a loader toast right away (outside the queue) and keeps it open until
## `task` fires. The signal may carry any number of arguments.
func loader_task(text: String, task: Signal, overrides: Dictionary = {}) -> void:
	if not is_inside_tree():
		push_error("ToastService.loader_task(): the service is not in the scene tree yet.")
		return
	var effective_theme := _get_effective_theme()
	var merged := _prepare_loader_overrides(effective_theme, overrides)
	merged["duration"] = 0.0

	var toast_data := ToastData.new(text, ToastConstants.ToastStyle.LOADER, merged)
	var view := _spawn_view()
	view.finished.connect(func():
		_stack_manager.remove_view(view)
		_try_show_next()
	)
	_play_item_in_view(view, toast_data)
	_stack_manager.add_view(view)

	task.connect(func(..._args):
		if is_instance_valid(view):
			view.dismiss()
	, CONNECT_ONE_SHOT)

# Ensures loader toasts include a spinner-friendly icon configuration.
func _prepare_loader_overrides(theme: ToastTheme, overrides: Dictionary) -> Dictionary:
	var merged := overrides.duplicate()

	if theme != null and theme.loader_icon != null and not merged.has("icon"):
		merged["icon"] = theme.loader_icon

	if not merged.has("icon_spin"):
		merged["icon_spin"] = true

	if not merged.has("icon_spin_speed") and theme != null:
		merged["icon_spin_speed"] = theme.loader_spin_speed

	return merged

# Returns the user-defined theme or the default fallback.
func _get_effective_theme() -> ToastTheme:
	return theme if theme != null else DEFAULT_THEME

# Instantiates a ToastView on the service's own canvas layer.
func _spawn_view() -> ToastView:
	if _layer == null:
		_layer = CanvasLayer.new()
		_layer.name = "Toasts"
		_layer.layer = layer
		add_child(_layer)
	var view := TOAST_VIEW_SCENE.instantiate() as ToastView
	_layer.add_child(view)
	return view

# Resolves styling and triggers playback on a view.
func _play_item_in_view(view: ToastView, toast_data: ToastData) -> void:
	var effective_theme := _get_effective_theme()
	var resolved_data := ToastStyleResolver.resolve(effective_theme, toast_data.style, toast_data.overrides)
	view.play(toast_data.text, resolved_data)

# Chooses between stacked or single rendering behavior. Toasts requested before
# the service is in the tree stay queued until _ready().
func _try_show_next() -> void:
	if not is_inside_tree():
		return
	if stack_toasts:
		_try_show_stacked()
	else:
		_try_show_single()

# Shows as many toasts as allowed while stacking them on screen.
func _try_show_stacked() -> void:
	while not _queue_manager.is_empty() and _stack_manager.get_active_count() < max_visible:
		var toast_data := _queue_manager.dequeue()
		if toast_data == null:
			break

		var view := _spawn_view()

		view.finished.connect(func():
			_stack_manager.remove_view(view)
			_try_show_next()
		)

		_play_item_in_view(view, toast_data)
		_stack_manager.add_view(view)

# Shows toasts one at a time, waiting until the active one ends.
func _try_show_single() -> void:
	if _is_showing_single or _queue_manager.is_empty():
		return

	_is_showing_single = true
	var toast_data := _queue_manager.dequeue()

	if toast_data == null:
		_is_showing_single = false
		return

	var view := _spawn_view()

	view.finished.connect(func():
		_is_showing_single = false
		_try_show_next()
	)

	_play_item_in_view(view, toast_data)
