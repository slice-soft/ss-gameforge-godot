extends Control
class_name ToastView

# Emitted when the toast finishes its life cycle.
signal finished

@export_group("Debug")
@export var debug_on_ready := false
@export var debug_theme: ToastTheme = load("res://addons/ss-gameforge-toast/themes/toast_default.tres") as ToastTheme
@export var debug_text := "Sample toast"
@export var debug_style := ToastConstants.ToastStyle.INFO
@export var debug_options: Dictionary = {}

@onready var panel_container: PanelContainer = $PanelContainer
@onready var icon: TextureRect = $PanelContainer/Content/Icon
@onready var label: RichTextLabel = $PanelContainer/Content/Label

var _base_position: ToastConstants.ToastPosition = ToastConstants.ToastPosition.BOTTOM_CENTER
var _base_margin: Vector2 = Vector2(16, 16)
# Toasts at the same position that sit closer to the anchor than this one.
var _stack_before: Array = []
var _stack_spacing := 0.0
var _icon_custom_node: Node = null
var _icon_spin_tween: Tween = null
var _open_tween: Tween = null
var _life_tween: Tween = null
var _closing := false
var _position_request_id := 0

# Plays a debug toast when enabled from the inspector.
func _ready() -> void:
	if debug_on_ready:
		var resolved_data := ToastStyleResolver.resolve(debug_theme, debug_style, debug_options)
		play(debug_text, resolved_data)

# Public entry point used by the service to render a toast.
func play(text: String, style_data: Dictionary) -> void:
	_set_text(text)
	_apply_visual_styles(style_data)
	_apply_wrap(text, style_data)
	_start_animation(style_data)

# Returns the base position before stacking offsets.
func get_base_position() -> int:
	return _base_position

# Updates stacking information and triggers repositioning.
func apply_stack(before: Array, spacing: float) -> void:
	_stack_before = before
	_stack_spacing = spacing
	_request_position_update(_base_position, _base_margin)

# Applies the text content to the label.
func _set_text(text: String) -> void:
	label.bbcode_enabled = false
	label.text = text

# Resolves and applies visual style data to UI elements.
func _apply_visual_styles(style_data: Dictionary) -> void:
	var result := ToastVisualApplier.apply_visual_styles(
		panel_container,
		label,
		icon,
		style_data,
		_icon_custom_node
	)
	
	_base_position = result.base_position
	_base_margin = result.base_margin
	_icon_custom_node = result.icon_custom_node
	
	_apply_icon_spin(
		result.icon_spin_enabled,
		result.icon_spin_speed,
		result.toast_duration,
		result.icon_spin_target
	)
	
	_request_position_update(_base_position, _base_margin)

# Starts the toast life cycle animation and emits when done.
# If duration == 0.0, the toast stays open until dismiss() is called.
func _start_animation(style_data: Dictionary) -> void:
	modulate.a = 0.0
	show()

	var duration: float = float(style_data.get("duration", 2.0))

	if duration > 0.0:
		_life_tween = ToastAnimator.play_toast_animation(self, duration)
		_life_tween.finished.connect(_close)
	else:
		_open_tween = ToastAnimator.fade_in(self)

# Closes the toast early with a fade-out. Safe to call more than once, and on a
# toast that has a duration.
func dismiss() -> void:
	if _closing:
		return
	_closing = true
	for tween in [_open_tween, _life_tween]:
		if tween != null and is_instance_valid(tween):
			tween.kill()
	_open_tween = null
	_life_tween = null
	ToastAnimator.fade_out(self).finished.connect(_close)

# Emits finished exactly once and frees the view.
func _close() -> void:
	if is_queued_for_deletion():
		return
	_closing = true
	finished.emit()
	queue_free()

# Wraps the text when the toast would grow past max_width (or past the screen).
func _apply_wrap(text: String, style_data: Dictionary) -> void:
	var max_width := float(style_data.get("max_width", 480.0))
	var margin: Vector2 = style_data.get("position_margin", Vector2(16, 16))
	max_width = minf(max_width, get_viewport_rect().size.x - margin.x * 2.0)
	var padding := float(style_data.get("padding", 10.0))
	var font_size := int(style_data.get("font_size", 14))
	var font := label.get_theme_font("normal_font")
	var text_width := font.get_multiline_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	var chrome := padding * 2.0
	if icon.visible:
		chrome += icon.custom_minimum_size.x + float(($PanelContainer/Content as HBoxContainer).get_theme_constant("separation"))
	var room := maxf(max_width - chrome, 1.0)
	if max_width > 0.0 and text_width > room:
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.custom_minimum_size.x = room
	else:
		label.autowrap_mode = TextServer.AUTOWRAP_OFF
		label.custom_minimum_size.x = 0.0

# Enables a spinning animation for loader-style icons.
func _apply_icon_spin(
	enabled: bool,
	speed: float,
	toast_duration: float,
	target: CanvasItem
) -> void:
	_stop_current_spin()
	
	if not enabled or target == null:
		return
	
	call_deferred("_start_icon_spin_deferred", target, speed, toast_duration)

# Stops any existing spin tween.
func _stop_current_spin() -> void:
	if _icon_spin_tween != null and is_instance_valid(_icon_spin_tween):
		_icon_spin_tween.kill()
		_icon_spin_tween = null

# Starts spinning after the node is in the tree.
func _start_icon_spin_deferred(target: CanvasItem, speed: float, toast_duration: float) -> void:
	if target == null or not is_instance_valid(target):
		return
	
	_icon_spin_tween = ToastAnimator.create_spin_animation(target, speed, toast_duration)

# Coalesces position updates to avoid layout thrashing.
func _request_position_update(pos: ToastConstants.ToastPosition, margin: Vector2) -> void:
	_position_request_id += 1
	call_deferred("_apply_position", pos, margin, _position_request_id)

# Applies position after a deferred layout pass.
func _apply_position(pos: ToastConstants.ToastPosition, margin: Vector2, request_id: int) -> void:
	panel_container.queue_sort()
	await get_tree().process_frame
	
	if request_id != _position_request_id:
		return
	
	var heights: Array[float] = []
	for other in _stack_before:
		if is_instance_valid(other):
			heights.append((other as ToastView).panel_container.size.y)
	var stack_offset := ToastPositionCalculator.calculate_stack_offset(pos, heights, _stack_spacing)
	
	ToastPositionCalculator.apply_position(panel_container, pos, margin, stack_offset)
