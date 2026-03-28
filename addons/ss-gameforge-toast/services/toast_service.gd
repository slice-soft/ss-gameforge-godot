extends SingletonNode
class_name ToastService

# Central singleton entry point to show toast notifications.
const TOAST_VIEW_SCENE := preload("res://addons/ss-gameforge-toast/scenes/toast_view.tscn")
var DEFAULT_THEME := load("res://addons/ss-gameforge-toast/themes/toast_default.tres") as ToastTheme

@export var theme: ToastTheme
@export var max_queue := 50
@export var stack_toasts := true
@export var max_visible := 4
@export var stack_spacing := 8.0

# Convenient singleton accessor.
static var i: ToastService:
	get:
		return SingletonNode.get_instance_for(ToastService) as ToastService

var _queue_manager := ToastQueueManager.new()
var _stack_manager := ToastStackManager.new()
var _is_showing_single := false

# Initializes queue and stack settings based on export properties.
func _ready() -> void:
	_queue_manager.set_max_size(max_queue)
	_stack_manager.set_stack_spacing(stack_spacing)

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

# Instantiates and adds a ToastView to the scene tree.
func _spawn_view() -> ToastView:
	var view := TOAST_VIEW_SCENE.instantiate() as ToastView
	get_tree().root.add_child(view)
	return view

# Resolves styling and triggers playback on a view.
func _play_item_in_view(view: ToastView, toast_data: ToastData) -> void:
	var effective_theme := _get_effective_theme()
	var resolved_data := ToastStyleResolver.resolve(effective_theme, toast_data.style, toast_data.overrides)
	view.play(toast_data.text, resolved_data)

# Chooses between stacked or single rendering behavior.
func _try_show_next() -> void:
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
