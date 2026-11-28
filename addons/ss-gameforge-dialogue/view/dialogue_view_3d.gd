class_name DialogueView3D extends Node3D
## A speech bubble in 3D space. Place it where the bubble's tail should point
## (e.g. above a character's head): it builds a SubViewport holding a
## DialogueView in BUBBLE layout, shows it on a billboard Sprite3D, and keeps
## the viewport sized to the bubble.

## Emitted when the open animation starts.
signal dialogue_started
## Emitted each time a new line starts. index is 0-based.
signal line_changed(index: int)
## Emitted once when the sequence ends and the close animation finishes.
signal dialogue_finished
## Emitted for each character revealed while a line types.
signal character_typed(character: String)

const _VIEW_SCENE := preload("res://addons/ss-gameforge-dialogue/scenes/dialogue_view.tscn")

## Input action used to skip typing or advance to the next line.
@export var skip_action: StringName = "ui_accept"
## Where skip_action is read from. AUTO polls, since the bubble's viewport gets
## no input events.
@export var input_mode: DialogueView.InputMode = DialogueView.InputMode.AUTO
## Visual configuration. When null, the built-in default style is applied.
@export var dialogue_theme: DialogueTheme
## Optional: assign a resource to auto-start when auto_start is true on it.
@export var resource: DialogueResource
## Optional input action that shows the previous line again (empty = off).
@export var back_action: StringName = &""
## Optional input action that hides every dialogue while held (empty = off).
@export var hide_action: StringName = &""
## Where shown lines are recorded; share one to log every speaker together.
@export var history: DialogueHistory
## Audio bus the speakers' voice blips play on.
@export var voice_bus: StringName = &"Master"

@export_group("Sprite")
## World units per bubble pixel.
@export var pixel_size: float = 0.01:
	set(value):
		pixel_size = value
		if _sprite != null:
			_sprite.pixel_size = value
## Always face the camera.
@export var billboard: bool = true:
	set(value):
		billboard = value
		if _sprite != null:
			_sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED if value else BaseMaterial3D.BILLBOARD_DISABLED
## Draw over geometry, so walls and the speaker's own mesh never hide the text.
@export var no_depth_test: bool = true:
	set(value):
		no_depth_test = value
		if _sprite != null:
			_sprite.no_depth_test = value
## Keep the same size on screen whatever the distance (pixel_size is then a
## fraction of the viewport height).
@export var fixed_size: bool = false:
	set(value):
		fixed_size = value
		if _sprite != null:
			_sprite.fixed_size = value

# Extra room around the bubble so the open animation's overshoot is not clipped.
const _OVERSHOOT := 0.25
const _MARGIN := 4

var _viewport: SubViewport
var _sprite: Sprite3D
var _view: DialogueView


func _ready() -> void:
	_viewport = SubViewport.new()
	_viewport.name = "BubbleViewport"
	_viewport.transparent_bg = true
	_viewport.disable_3d = true
	_viewport.size = Vector2i(2, 2)
	_viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
	add_child(_viewport)

	_view = _VIEW_SCENE.instantiate() as DialogueView
	_view.layout = DialogueView.Layout.BUBBLE
	_view.skip_action = skip_action
	_view.input_mode = input_mode
	_view.dialogue_theme = dialogue_theme
	_view.back_action = back_action
	_view.hide_action = hide_action
	_view.history = history
	_view.voice_bus = voice_bus
	_viewport.add_child(_view)
	history = _view.history
	_view.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_view.size = Vector2.ZERO
	_view.bubble_resized.connect(_on_bubble_resized)
	_view.dialogue_started.connect(func():
		_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		dialogue_started.emit()
	)
	_view.line_changed.connect(line_changed.emit)
	_view.character_typed.connect(character_typed.emit)
	_view.dialogue_finished.connect(func():
		_viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
		dialogue_finished.emit()
	)

	_sprite = Sprite3D.new()
	_sprite.name = "Bubble"
	_sprite.texture = _viewport.get_texture()
	_sprite.shaded = false
	_sprite.double_sided = true
	_sprite.pixel_size = pixel_size
	_sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED if billboard else BaseMaterial3D.BILLBOARD_DISABLED
	_sprite.no_depth_test = no_depth_test
	_sprite.fixed_size = fixed_size
	_sprite.render_priority = 1
	add_child(_sprite)

	if resource and resource.auto_start:
		play(resource)


## Starts a dialogue sequence in the bubble. See DialogueView.play().
func play(res: DialogueResource) -> void:
	_view.dialogue_theme = dialogue_theme
	_view.play(res)


## Cancels the current dialogue. See DialogueView.stop().
func stop() -> void:
	_view.stop()


## Completes the line being typed or advances. See DialogueView.skip().
func skip() -> bool:
	return _view.skip()


## Shows the previous line again. See DialogueView.back().
func back() -> bool:
	return _view.back()


## True from play() until dialogue_finished.
func is_playing() -> bool:
	return _view.is_playing()


## Who says the line on screen, or null.
func get_speaker() -> DialogueSpeaker:
	return _view.get_speaker()


## The DialogueView inside the bubble, for anything not forwarded here.
func get_view() -> DialogueView:
	return _view


# Sizes the viewport to the bubble plus room for the open animation, puts the
# bubble's tail at the bottom-centre, and lifts the sprite so that point sits on
# this node's origin.
func _on_bubble_resized(bubble: Vector2) -> void:
	var w := int(ceilf(bubble.x * (1.0 + _OVERSHOOT))) + _MARGIN * 2
	var h := int(ceilf(bubble.y * (1.0 + _OVERSHOOT))) + _MARGIN * 2
	_viewport.size = Vector2i(maxi(w, 2), maxi(h, 2))
	_view.position = Vector2(w / 2.0, h - _MARGIN)
	_sprite.offset = Vector2(0.0, h / 2.0 - _MARGIN)
