class_name DialogueView extends Control

## Emitted when the open animation starts.
signal dialogue_started
## Emitted each time a new line starts. index is 0-based.
signal line_changed(index: int)
## Emitted once when the sequence ends (all lines done, or stop()) and the close
## animation finishes.
signal dialogue_finished

## Input action used to skip typing or advance to the next line.
@export var skip_action: StringName = "ui_accept"
## Visual configuration. When null, a built-in default style is applied.
@export var dialogue_theme: DialogueTheme
## Optional: assign a resource to auto-start when auto_start is true on it.
@export var resource: DialogueResource

enum _State { IDLE, WAITING, OPENING, TYPING, HOLDING, CLOSING }

@onready var _box: PanelContainer = $DialogueBox
@onready var _margin: MarginContainer = $DialogueBox/Margin
@onready var _label: RichTextLabel = $DialogueBox/Margin/DialogueText
@onready var _timer: Timer = $Timer

var _resource: DialogueResource
var _idx: int = 0
var _state: _State = _State.IDLE
var _box_tween: Tween
var _current_tween: Tween
var _current_line: String = ""
var _current_line_visible_length: int = 0


func _ready() -> void:
	_label.bbcode_enabled = true
	_label.visible_characters_behavior = TextServer.VC_CHARS_AFTER_SHAPING
	_clear_current_line()
	_box.visible = false
	_box.scale = Vector2.ZERO
	set_process_unhandled_input(false)
	apply_theme()
	if resource and resource.auto_start:
		play(resource)


## Primary entry point. Call this to start a dialogue sequence.
## Applies the current dialogue_theme before starting, so runtime theme changes take effect.
## Ignored while another sequence is running or closing.
func play(res: DialogueResource) -> void:
	if res == null:
		push_error("DialogueView.play(): resource is null.")
		return
	if _state != _State.IDLE:
		return
	apply_theme()
	_resource = res
	_state = _State.WAITING
	_start_timer(_resource.time_to_start)


## Cancels the current dialogue and plays the close animation.
## Safe to call at any time, including during the pre-start delay, the open
## animation, or more than once. dialogue_finished is emitted once.
func stop() -> void:
	match _state:
		_State.IDLE, _State.CLOSING:
			return
		_State.WAITING:
			_timer.stop()
			_state = _State.IDLE
			return
	_finish_dialogue()


## True from play() until dialogue_finished.
func is_playing() -> bool:
	return _state != _State.IDLE


func apply_theme() -> void:
	var t := dialogue_theme if dialogue_theme != null else _default_theme()

	var style: StyleBox
	if t.background_texture != null:
		var tex := StyleBoxTexture.new()
		tex.texture = t.background_texture
		tex.texture_margin_left = t.texture_patch_margin
		tex.texture_margin_top = t.texture_patch_margin
		tex.texture_margin_right = t.texture_patch_margin
		tex.texture_margin_bottom = t.texture_patch_margin
		tex.modulate_color = t.background_color
		style = tex
	else:
		var flat := StyleBoxFlat.new()
		flat.bg_color = t.background_color
		flat.border_color = t.border_color
		flat.set_border_width_all(t.border_width)
		flat.set_corner_radius_all(int(t.corner_radius))
		style = flat
	_box.add_theme_stylebox_override("panel", style)

	_margin.add_theme_constant_override("margin_left", int(t.padding.x))
	_margin.add_theme_constant_override("margin_right", int(t.padding.x))
	_margin.add_theme_constant_override("margin_top", int(t.padding.y))
	_margin.add_theme_constant_override("margin_bottom", int(t.padding.y))

	_label.add_theme_color_override("default_color", t.font_color)
	_label.add_theme_font_size_override("normal_font_size", t.font_size)
	if t.font:
		_label.add_theme_font_override("normal_font", t.font)
	else:
		_label.remove_theme_font_override("normal_font")

	# Full width minus the margins, bottom edge position_margin.y above the
	# view's bottom; the box grows upward to fit its text.
	_box.set_anchor_and_offset(SIDE_LEFT, 0.0, t.position_margin.x)
	_box.set_anchor_and_offset(SIDE_RIGHT, 1.0, -t.position_margin.x)
	_box.set_anchor_and_offset(SIDE_TOP, 1.0, -t.position_margin.y)
	_box.set_anchor_and_offset(SIDE_BOTTOM, 1.0, -t.position_margin.y)
	_box.grow_vertical = Control.GROW_DIRECTION_BEGIN


func _start_dialogue() -> void:
	_box.visible = true
	_idx = 0
	_state = _State.OPENING
	# Lay out the first line before opening, so the box opens at its final size.
	if not _resource.dialogues.is_empty():
		_set_current_line(_line_text(0))
	set_process_unhandled_input(true)
	dialogue_started.emit()
	_animate_box(
		Vector2.ONE,
		_resource.open_time,
		_resource.open_transition,
		_resource.open_ease,
		_show_line
	)


func _line_text(index: int) -> String:
	var key := _resource.dialogues[index]
	var line := tr(key) if _resource.use_translation else key
	return line.replace("\\n", "\n")


func _show_line() -> void:
	if _idx >= _resource.dialogues.size():
		_finish_dialogue()
		return

	_set_current_line(_line_text(_idx))
	_state = _State.TYPING
	line_changed.emit(_idx)

	var duration := maxf(0.01, _resource.text_speed * float(_current_line_visible_length))
	_current_tween = create_tween()
	_current_tween.tween_property(_label, "visible_characters", _current_line_visible_length, duration)\
		.from(0)
	_current_tween.finished.connect(func():
		_current_tween = null
		_on_line_typed()
	)


func _on_line_typed() -> void:
	_label.visible_characters = -1
	_state = _State.HOLDING
	match _resource.advance_mode:
		DialogueConstants.AdvanceMode.AUTO, DialogueConstants.AdvanceMode.HYBRID:
			_start_timer(_resource.hold_after_line)
		DialogueConstants.AdvanceMode.MANUAL:
			pass


func _advance() -> void:
	_idx += 1
	_show_line()


func _finish_dialogue() -> void:
	_state = _State.CLOSING
	_timer.stop()
	set_process_unhandled_input(false)
	if _current_tween != null:
		_current_tween.kill()
		_current_tween = null
	_animate_box(
		Vector2.ZERO,
		_resource.close_time,
		_resource.close_transition,
		_resource.close_ease,
		func():
			_box.visible = false
			_state = _State.IDLE
			_clear_current_line()
			dialogue_finished.emit()
	)


func _on_timer_timeout() -> void:
	match _state:
		_State.WAITING:
			_start_dialogue()
		_State.HOLDING:
			_advance()


func _unhandled_input(event: InputEvent) -> void:
	if not _resource.allow_skip or not event.is_action_pressed(skip_action):
		return
	match _state:
		_State.TYPING:
			get_viewport().set_input_as_handled()
			if _current_tween != null:
				_current_tween.kill()
				_current_tween = null
			_on_line_typed()
		_State.HOLDING:
			if _resource.advance_mode == DialogueConstants.AdvanceMode.AUTO:
				return
			get_viewport().set_input_as_handled()
			_timer.stop()
			_advance()
		_State.OPENING:
			# Swallow it so the press that opened the dialogue does not skip line 0.
			get_viewport().set_input_as_handled()


# Timer.start(0) would reuse the node's wait_time, so a zero delay is clamped
# to the shortest one instead.
func _start_timer(seconds: float) -> void:
	_timer.start(maxf(seconds, 0.001))


func _animate_box(
	target_scale: Vector2,
	time: float,
	trans: Tween.TransitionType,
	ease: Tween.EaseType,
	callback: Callable
) -> void:
	if _box_tween != null:
		_box_tween.kill()
	_box.pivot_offset = _box.size / 2.0
	_box_tween = create_tween()
	_box_tween.tween_property(_box, "scale", target_scale, maxf(time, 0.0))\
		.set_trans(trans)\
		.set_ease(ease)
	_box_tween.finished.connect(func():
		_box_tween = null
		callback.call()
	)


func _set_current_line(line: String) -> void:
	_current_line = line
	_label.text = line
	_current_line_visible_length = _label.get_total_character_count()
	_label.visible_characters = 0


func _clear_current_line() -> void:
	_current_line = ""
	_current_line_visible_length = 0
	_label.text = ""
	_label.visible_characters = -1


static func _default_theme() -> DialogueTheme:
	return DialogueTheme.new()
