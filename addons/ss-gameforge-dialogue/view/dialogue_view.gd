class_name DialogueView extends Control

## Emitted when the open animation finishes and typing begins.
signal dialogue_started
## Emitted each time a new line starts. index is 0-based.
signal line_changed(index: int)
## Emitted when all lines are done and the close animation finishes.
signal dialogue_finished

## Input action used to skip typing or advance to the next line.
@export var skip_action: StringName = "ui_accept"
## Visual configuration. When null, a built-in default style is applied.
@export var dialogue_theme: DialogueTheme
## Optional: assign a resource to auto-start when auto_start is true on it.
@export var resource: DialogueResource

@onready var _box: MarginContainer = $DialogueBox
@onready var _margin: MarginContainer = $DialogueBox/Margin
@onready var _label: RichTextLabel = $DialogueBox/Margin/DialogueText
@onready var _timer: Timer = $Timer

var _resource: DialogueResource
var _idx: int = 0
var _playing: bool = false
var _current_tween: Tween
var _current_line: String = ""
var _current_line_visible_length: int = 0
var _revealed_character_count: int = -1


func _ready() -> void:
	_label.bbcode_enabled = true
	_clear_current_line()
	_box.visible = false
	_box.size = Vector2.ONE
	_box.scale = Vector2.ZERO
	set_process_unhandled_input(false)
	apply_theme()
	if resource and resource.auto_start:
		play(resource)


## Primary entry point. Call this to start a dialogue sequence.
## Applies the current dialogue_theme before starting, so runtime theme changes take effect.
func play(res: DialogueResource) -> void:
	if _playing or not _timer.is_stopped():
		return
	apply_theme()
	_resource = res
	_timer.start(_resource.time_to_start)


## Cancels the current dialogue and plays the close animation.
## Safe to call at any time, including during the pre-start delay.
func stop() -> void:
	_timer.stop()
	if not _playing:
		return
	if _current_tween != null:
		_current_tween.kill()
		_current_tween = null
	_finish_dialogue()


func apply_theme() -> void:
	var t := dialogue_theme if dialogue_theme != null else _default_theme()

	var style := StyleBoxFlat.new()
	style.bg_color = t.background_color
	style.border_color = t.border_color
	style.set_border_width_all(t.border_width)
	style.set_corner_radius_all(int(t.corner_radius))
	_box.add_theme_stylebox_override("panel", style)

	_margin.add_theme_constant_override("margin_left", int(t.padding.x))
	_margin.add_theme_constant_override("margin_right", int(t.padding.x))
	_margin.add_theme_constant_override("margin_top", int(t.padding.y))
	_margin.add_theme_constant_override("margin_bottom", int(t.padding.y))

	_label.add_theme_color_override("default_color", t.font_color)
	_label.add_theme_font_size_override("normal_font_size", t.font_size)
	if t.font:
		_label.add_theme_font_override("normal_font", t.font)

	_box.set_anchor_and_offset(SIDE_LEFT, 0.0, t.position_margin.x)
	_box.set_anchor_and_offset(SIDE_TOP, 1.0, -t.position_margin.y)
	_box.set_anchor_and_offset(SIDE_RIGHT, 1.0, -t.position_margin.x)
	_box.set_anchor_and_offset(SIDE_BOTTOM, 1.0, 0.0)
	# _box.set_anchor_and_offset(SIDE_BOTTOM, 1.0, -t.position_margin.y)
	# _box.grow_vertical = Control.GROW_DIRECTION_BEGIN


func _start_dialogue() -> void:
	if _playing:
		return
	_box.visible = true
	_playing = true
	_idx = 0
	set_process_unhandled_input(true)
	dialogue_started.emit()
	_animate_box(
		Vector2.ONE,
		_resource.open_time,
		_resource.open_transition,
		_resource.open_ease,
		_show_line
	)


func _show_line() -> void:
	if _idx >= _resource.dialogues.size():
		_finish_dialogue()
		return

	var key := _resource.dialogues[_idx]
	var line := tr(key) if _resource.use_translation else key
	line = line.replace("\\n", "\n")
	_set_current_line(line)
	line_changed.emit(_idx)

	var duration := maxf(0.01, _resource.text_speed * float(_current_line_visible_length))
	_current_tween = create_tween()
	_current_tween.tween_method(
		Callable(self, "_set_revealed_character_count"),
		0.0,
		float(_current_line_visible_length),
		duration
	)
	_current_tween.finished.connect(func():
		_current_tween = null
		_set_revealed_character_count(float(_current_line_visible_length))
		_on_line_typed()
	)


func _on_line_typed() -> void:
	match _resource.advance_mode:
		DialogueConstants.AdvanceMode.AUTO, DialogueConstants.AdvanceMode.HYBRID:
			_timer.start(_resource.hold_after_line)
		DialogueConstants.AdvanceMode.MANUAL:
			pass


func _advance() -> void:
	_idx += 1
	_show_line()


func _finish_dialogue() -> void:
	set_process_unhandled_input(false)
	_animate_box(
		Vector2.ZERO,
		_resource.close_time,
		_resource.close_transition,
		_resource.close_ease,
		func():
			_box.visible = false
			_playing = false
			_clear_current_line()
			dialogue_finished.emit()
	)


func _on_timer_timeout() -> void:
	if not _playing:
		_start_dialogue()
		return
	_advance()


func _unhandled_input(event: InputEvent) -> void:
	if not _playing or not _resource.allow_skip:
		return
	if not event.is_action_pressed(skip_action):
		return

	if _current_tween != null and _current_tween.is_running():
		_current_tween.kill()
		_current_tween = null
		_set_revealed_character_count(float(_current_line_visible_length))
		_on_line_typed()
	else:
		match _resource.advance_mode:
			DialogueConstants.AdvanceMode.MANUAL, DialogueConstants.AdvanceMode.HYBRID:
				if not _timer.is_stopped():
					_timer.stop()
				_advance()


func _animate_box(
	target_scale: Vector2,
	time: float,
	trans: Tween.TransitionType,
	ease: Tween.EaseType,
	callback: Callable
) -> void:
	_box.pivot_offset = _box.size / 2.0
	var tween := create_tween()
	tween.tween_property(_box, "scale", target_scale, time)\
		.set_trans(trans)\
		.set_ease(ease)
	tween.finished.connect(callback)


func _set_current_line(line: String) -> void:
	_current_line = line
	_current_line_visible_length = BBCodeParser.visible_length(line)
	_revealed_character_count = -1
	_set_revealed_character_count(0.0)


func _clear_current_line() -> void:
	_current_line = ""
	_current_line_visible_length = 0
	_revealed_character_count = -1
	_label.text = ""
	_label.visible_ratio = 1.0


func _set_revealed_character_count(value: float) -> void:
	var count := clampi(int(floor(value)), 0, _current_line_visible_length)
	if count == _revealed_character_count:
		return
	_revealed_character_count = count
	_label.text = BBCodeParser.prefix(_current_line, count)
	_label.visible_ratio = 1.0


static func _default_theme() -> DialogueTheme:
	var t := DialogueTheme.new()
	t.background_color = Color(0.082, 0.082, 0.118, 0.921)
	t.border_color = Color(0.255, 0.255, 0.353, 1.0)
	t.border_width = 2
	t.corner_radius = 10.0
	t.padding = Vector2(16.0, 12.0)
	t.font_color = Color.WHITE
	t.font_size = 16
	t.position_margin = Vector2(24.0, 24.0)
	return t
