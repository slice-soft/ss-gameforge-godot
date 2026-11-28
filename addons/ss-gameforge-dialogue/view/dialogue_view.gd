class_name DialogueView extends Control

## Emitted when the open animation starts.
signal dialogue_started
## Emitted each time a new line starts. index is 0-based.
signal line_changed(index: int)
## Emitted once when the sequence ends (all lines done, or stop()) and the close
## animation finishes.
signal dialogue_finished
## BUBBLE layout: emitted when the bubble's size changes (a new line was laid out).
signal bubble_resized(size: Vector2)
## Emitted for each character revealed while a line types (not when a skip
## completes it). Use it for your own effects: mouth flaps, custom sounds.
signal character_typed(character: String)

## How the box is laid out.
enum Layout {
	SCREEN, ## Spans the bottom of the view (the screen by default) and grows upward.
	BUBBLE, ## Sized to its text, bottom-centre on the view's origin. For speech bubbles.
}

## Where skip_action is read from.
enum InputMode {
	AUTO,    ## Input events, or polling when the view's viewport receives none (a SubViewport used as a texture).
	EVENTS,  ## Only _unhandled_input events; the press is marked handled.
	POLLING, ## Input.is_action_just_pressed() every frame; works in any viewport.
	NONE,    ## The view reads no input; call skip() from your own input code.
}

## Input action used to skip typing or advance to the next line.
@export var skip_action: StringName = "ui_accept"
## Visual configuration. When null, a built-in default style is applied.
@export var dialogue_theme: DialogueTheme
## Optional: assign a resource to auto-start when auto_start is true on it.
@export var resource: DialogueResource
## Screen box or speech bubble.
@export var layout: Layout = Layout.SCREEN:
	set(value):
		layout = value
		if is_node_ready():
			apply_theme()
## Where skip_action is read from.
@export var input_mode: InputMode = InputMode.AUTO
## Optional input action that shows the previous line again (empty = off).
@export var back_action: StringName = &""
## Optional input action that hides every dialogue (all views, 2D and 3D) while
## held. They keep running and skip_action still works (empty = off).
@export var hide_action: StringName = &""
## Where shown lines are recorded. Assign one shared DialogueHistory to several
## views to gather every speaker in one log; when empty, the view keeps its own.
@export var history: DialogueHistory
## Audio bus the speakers' voice blips play on.
@export var voice_bus: StringName = &"Master"

const _GROUP := &"ss_gameforge_dialogue_views"
static var _hidden_by_code := false
static var _hidden_by_hold := false

enum _State { IDLE, WAITING, OPENING, TYPING, HOLDING, CLOSING }

@onready var _box: PanelContainer = $DialogueBox
@onready var _margin: MarginContainer = $DialogueBox/Margin
@onready var _content: HBoxContainer = $DialogueBox/Margin/Content
@onready var _portrait: TextureRect = $DialogueBox/Margin/Content/Portrait
@onready var _name_label: Label = $DialogueBox/Margin/Content/Column/SpeakerName
@onready var _label: RichTextLabel = $DialogueBox/Margin/Content/Column/DialogueText
@onready var _timer: Timer = $Timer

var _resource: DialogueResource
var _idx: int = 0
var _state: _State = _State.IDLE
var _box_tween: Tween
var _current_tween: Tween
var _current_line: String = ""
var _current_line_visible_length: int = 0
var _theme: DialogueTheme
# Highest line index of the running sequence already written to history.
var _recorded_upto: int = -1
var _speaker: DialogueSpeaker
var _voice: AudioStreamPlayer
# Revealed characters of the current line, and how many counted for the voice.
var _revealed: int = 0
var _voiced: int = 0


func _ready() -> void:
	_label.bbcode_enabled = true
	_label.visible_characters_behavior = TextServer.VC_CHARS_AFTER_SHAPING
	_clear_current_line()
	_box.visible = false
	_box.scale = Vector2.ZERO
	set_process_unhandled_input(false)
	set_process(false)
	_box.resized.connect(_place_bubble)
	_voice = AudioStreamPlayer.new()
	_voice.name = "Voice"
	_voice.max_polyphony = 1
	add_child(_voice)
	add_to_group(_GROUP)
	if history == null:
		history = DialogueHistory.new()
	_apply_hidden()
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


## Who says the line on screen, or null.
func get_speaker() -> DialogueSpeaker:
	return _speaker


## Shows the previous line of the running sequence again, fully revealed.
## Returns false on the first line or when no line is on screen.
func back() -> bool:
	if _state not in [_State.TYPING, _State.HOLDING] or _idx <= 0:
		return false
	if _current_tween != null:
		_current_tween.kill()
		_current_tween = null
	_timer.stop()
	_idx -= 1
	_set_line(_idx)
	_state = _State.TYPING
	line_changed.emit(_idx)
	_on_line_typed()
	return true


## Hides (true) or shows again (false) every DialogueView and DialogueView3D.
## Hidden dialogues keep running. Independent from hide_action.
static func set_all_hidden(hidden: bool) -> void:
	_hidden_by_code = hidden
	_refresh_hidden()


## True while dialogues are hidden, by set_all_hidden() or a held hide_action.
static func is_all_hidden() -> bool:
	return _hidden_by_code or _hidden_by_hold


static func _set_hold_hidden(hidden: bool) -> void:
	if _hidden_by_hold == hidden:
		return
	_hidden_by_hold = hidden
	_refresh_hidden()


static func _refresh_hidden() -> void:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		return
	for view in tree.get_nodes_in_group(_GROUP):
		(view as DialogueView)._apply_hidden()


func _apply_hidden() -> void:
	visible = not is_all_hidden()


## Does what a skip_action press does: completes the line being typed, or
## advances to the next one (not in AUTO mode). Use it to drive the dialogue
## from your own input code. Returns true if it did something.
func skip() -> bool:
	if _resource == null or not _resource.allow_skip:
		return false
	match _state:
		_State.TYPING:
			if _current_tween != null:
				_current_tween.kill()
				_current_tween = null
			_on_line_typed()
			return true
		_State.HOLDING:
			if _resource.advance_mode == DialogueConstants.AdvanceMode.AUTO:
				return false
			_timer.stop()
			_advance()
			return true
		_State.OPENING:
			# Swallowed so the press that opened the dialogue does not skip line 0.
			return true
	return false


func apply_theme() -> void:
	var t := dialogue_theme if dialogue_theme != null else _default_theme()
	_theme = t

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
	_name_label.add_theme_font_size_override("font_size", t.name_font_size if t.name_font_size > 0 else t.font_size)
	if t.font:
		_label.add_theme_font_override("normal_font", t.font)
		_name_label.add_theme_font_override("font", t.font)
	else:
		_label.remove_theme_font_override("normal_font")
		_name_label.remove_theme_font_override("font")
	_portrait.custom_minimum_size = t.portrait_size
	_apply_speaker()

	if layout == Layout.SCREEN:
		# Full width minus the margins, bottom edge position_margin.y above the
		# view's bottom; the box grows upward to fit its text.
		_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_label.custom_minimum_size.x = 0.0
		_box.set_anchor_and_offset(SIDE_LEFT, 0.0, t.position_margin.x)
		_box.set_anchor_and_offset(SIDE_RIGHT, 1.0, -t.position_margin.x)
		_box.set_anchor_and_offset(SIDE_TOP, 1.0, -t.position_margin.y)
		_box.set_anchor_and_offset(SIDE_BOTTOM, 1.0, -t.position_margin.y)
		_box.grow_vertical = Control.GROW_DIRECTION_BEGIN
	else:
		# Free-sized box; _place_bubble() keeps its bottom-centre on the origin.
		_box.set_anchors_preset(Control.PRESET_TOP_LEFT)
		_fit_bubble()


func _start_dialogue() -> void:
	_box.visible = true
	_idx = 0
	_recorded_upto = -1
	_state = _State.OPENING
	# Lay out the first line before opening, so the box opens at its final size.
	if not _resource.dialogues.is_empty():
		_set_line(0)
	_listen(true)
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

	_set_line(_idx)
	_state = _State.TYPING
	if _idx > _recorded_upto:
		_recorded_upto = _idx
		history.add(_current_line, _resource, _idx, _speaker, _name_label.text if _name_label.visible else "")
	line_changed.emit(_idx)

	var duration := maxf(0.01, _resource.text_speed * float(_current_line_visible_length))
	_revealed = 0
	_voiced = 0
	_current_tween = create_tween()
	_current_tween.tween_method(_reveal, 0.0, float(_current_line_visible_length), duration)
	_current_tween.finished.connect(func():
		_current_tween = null
		_on_line_typed()
	)


# Tween step: reveals up to `amount` characters, signalling each new one.
func _reveal(amount: float) -> void:
	var upto := mini(int(amount), _current_line_visible_length)
	if upto <= _revealed:
		return
	_label.visible_characters = upto
	var parsed := _label.get_parsed_text()
	var voice_due := false
	for i in range(_revealed, upto):
		var ch := parsed[i] if i < parsed.length() else ""
		character_typed.emit(ch)
		if ch.strip_edges() != "":
			_voiced += 1
			if _speaker != null and (_voiced - 1) % maxi(_speaker.voice_every, 1) == 0:
				voice_due = true
	_revealed = upto
	if voice_due:
		_play_voice()


func _play_voice() -> void:
	if _speaker == null or _speaker.voice == null:
		return
	_voice.stream = _speaker.voice
	_voice.bus = voice_bus
	_voice.volume_db = _speaker.voice_volume_db
	var v := _speaker.pitch_variation
	_voice.pitch_scale = maxf(_speaker.voice_pitch * randf_range(1.0 - v, 1.0 + v), 0.01)
	_voice.play()


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
	_listen(false)
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
	if event.is_action_pressed(skip_action) and skip():
		get_viewport().set_input_as_handled()
	elif _has_action(back_action) and event.is_action_pressed(back_action) and back():
		get_viewport().set_input_as_handled()


func _process(_delta: float) -> void:
	if _uses_polling():
		if Input.is_action_just_pressed(skip_action):
			skip()
		elif _has_action(back_action) and Input.is_action_just_pressed(back_action):
			back()
	if _has_action(hide_action):
		_set_hold_hidden(Input.is_action_pressed(hide_action))


# Turns the chosen input source on or off for the running sequence.
func _listen(on: bool) -> void:
	var reads_input := input_mode != InputMode.NONE
	var polling := _uses_polling()
	set_process_unhandled_input(on and reads_input and not polling)
	set_process(on and reads_input and (polling or _has_action(hide_action)))
	if _has_action(hide_action):
		# On start, pick up a hold already in progress. On stop, release it: this
		# view no longer watches the button, and any other view still running
		# re-applies it on its next frame.
		_set_hold_hidden(on and reads_input and Input.is_action_pressed(hide_action))


static func _has_action(action: StringName) -> bool:
	return action != &"" and InputMap.has_action(action)


func _uses_polling() -> bool:
	match input_mode:
		InputMode.POLLING:
			return true
		InputMode.AUTO:
			# A SubViewport only gets events through a SubViewportContainer (or
			# when the game pushes them); one used as a texture gets none.
			var vp := get_viewport()
			return vp is SubViewport and not (vp.get_parent() is SubViewportContainer)
	return false


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
	_box.pivot_offset = _pivot()
	_box_tween = create_tween()
	_box_tween.tween_property(_box, "scale", target_scale, maxf(time, 0.0))\
		.set_trans(trans)\
		.set_ease(ease)
	_box_tween.finished.connect(func():
		_box_tween = null
		callback.call()
	)


# Puts line `index` and its speaker on screen, nothing revealed yet.
func _set_line(index: int) -> void:
	_speaker = _resource.get_speaker(index)
	_apply_speaker()
	_set_current_line(_line_text(index))


# Shows the current speaker's name and portrait, or hides them.
func _apply_speaker() -> void:
	var shown_name := ""
	if _speaker != null and _speaker.display_name != "":
		shown_name = tr(_speaker.display_name) if _resource != null and _resource.use_translation else _speaker.display_name
	_name_label.text = shown_name
	_name_label.visible = shown_name != ""
	var color := _theme.name_color if _theme != null else Color.WHITE
	if _speaker != null and _speaker.name_color.a > 0.0:
		color = _speaker.name_color
	_name_label.add_theme_color_override("font_color", color)
	_portrait.texture = _speaker.portrait if _speaker != null else null
	_portrait.visible = _portrait.texture != null


func _set_current_line(line: String) -> void:
	_current_line = line
	_label.text = line
	_current_line_visible_length = _label.get_total_character_count()
	_label.visible_characters = 0
	if layout == Layout.BUBBLE:
		_fit_bubble()


# BUBBLE: one line as wide as its text, wrapping at bubble_max_width.
func _fit_bubble() -> void:
	if _theme == null:
		return
	var font := _label.get_theme_font("normal_font")
	var font_size := _label.get_theme_font_size("normal_font_size")
	var text_width := font.get_multiline_string_size(_label.get_parsed_text(), HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	var style := _box.get_theme_stylebox("panel")
	var chrome := _theme.padding.x * 2.0 + style.get_margin(SIDE_LEFT) + style.get_margin(SIDE_RIGHT)
	if _portrait.visible:
		chrome += _portrait.custom_minimum_size.x + _content.get_theme_constant("separation")
	if _name_label.visible:
		# A long name widens a short line's bubble rather than overflowing it.
		text_width = maxf(text_width, _name_label.get_minimum_size().x)
	var room := maxf(_theme.bubble_max_width - chrome, 1.0)
	if text_width > room:
		_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_label.custom_minimum_size.x = room
	else:
		_label.autowrap_mode = TextServer.AUTOWRAP_OFF
		_label.custom_minimum_size.x = ceilf(text_width)
	_box.reset_size()
	_place_bubble()
	# The wrapped label only knows its height once it has its new width, which
	# happens on the next layout pass; shrink the box again then, or it keeps the
	# height measured at the old, narrower width.
	_shrink_bubble.call_deferred()


func _shrink_bubble() -> void:
	if layout != Layout.BUBBLE:
		return
	_box.reset_size()
	_place_bubble()


func _place_bubble() -> void:
	if layout != Layout.BUBBLE:
		return
	_box.position = Vector2(-_box.size.x / 2.0, -_box.size.y)
	_box.pivot_offset = _pivot()
	bubble_resized.emit(_box.size)


# Scale animations grow from the bubble's tail (bottom-centre) or the box centre.
func _pivot() -> Vector2:
	if layout == Layout.BUBBLE:
		return Vector2(_box.size.x / 2.0, _box.size.y)
	return _box.size / 2.0


func _clear_current_line() -> void:
	_speaker = null
	_apply_speaker()
	_current_line = ""
	_current_line_visible_length = 0
	_label.text = ""
	_label.visible_characters = -1


static func _default_theme() -> DialogueTheme:
	return DialogueTheme.new()
