# Dialogue

`DialogueView` is a `Control` that types out a sequence of lines, one character
at a time, and animates a box in and out around them. The lines live in a
`DialogueResource`, so writing content never means touching the view.

## When to use

- You need a dialogue box with a typewriter reveal and open/close animation.
- You want the text content to be data, editable as a resource.
- Your lines use BBCode and must reveal correctly, tag by tag.

## Key API

- `play(resource)` starts a sequence. This is the primary entry point.
- `stop()` cancels the current dialogue and plays the close animation.
- `apply_theme()` re-applies `dialogue_theme`; `play()` already calls it.
- `is_playing()` is true from `play()` until `dialogue_finished`.
- Signals: `dialogue_started`, `line_changed(index)`, `dialogue_finished`.
- `@export skip_action` is the input action that skips typing or advances. Defaults to `ui_accept`.
- `DialogueResource` holds the lines and every timing/animation setting.
- `DialogueConstants.AdvanceMode`: `AUTO`, `MANUAL`, `HYBRID`.

## Usage: adding the view

Instance `res://addons/ss-gameforge-dialogue/scenes/dialogue_view.tscn` in your
scene. It starts hidden and shows itself when `play()` runs.

The view fills its parent (the whole screen when it is not inside a container)
and lets mouse input pass through. The box spans the width, sits
`position_margin` above the bottom edge and grows upward to fit its text, which
wraps onto as many lines as it needs. Put the view on a `CanvasLayer` if your
game uses a `Camera2D`, so the camera does not move it.

> Do not put the view inside a `VBoxContainer` or another container: the
> container sizes it to its minimum and the box has nowhere to anchor.

## Usage: writing the content

Create a `DialogueResource` and fill `dialogues`:

```gdscript
var resource := DialogueResource.new()
resource.dialogues = [
	"The gate will not open without the seal.",
	"Look for it in the [i]east wing[/i].",
]
resource.use_translation = false
```

> `use_translation` defaults to **true**, which means each entry is treated as a
> translation key and passed through `tr()`. Set it to `false` to display the
> strings as written.

Line breaks work with a literal `\n` inside the string, which the view converts
into a real newline.

## Usage: playing a sequence

```gdscript
@onready var dialogue_view: DialogueView = $DialogueView

func _on_npc_talked() -> void:
	dialogue_view.dialogue_finished.connect(_on_dialogue_finished, CONNECT_ONE_SHOT)
	dialogue_view.play(resource)

func _on_dialogue_finished() -> void:
	print("done")
```

> `CONNECT_ONE_SHOT` matters when the same view plays many sequences: without it
> the callback stacks up on every play.

Reusing one authored resource for several dialogues is easiest with
`duplicate()`, which is what the showcase does:

```gdscript
const BASE_RESOURCE := preload("res://examples/showcase/game_manager_dialogue_resource.tres")

var resource := BASE_RESOURCE.duplicate() as DialogueResource
resource.dialogues = pokemon_flavor_texts
dialogue_view.play(resource)
```

`play()` is ignored while another sequence is running or closing, so it is safe
to call from an input handler. `stop()` is safe at any point, including during
the start delay or the open animation, and `dialogue_finished` fires once per
sequence (not at all when `stop()` cancels during the start delay, since nothing
opened).

The press of `skip_action` that skips or advances is marked as handled, so it
does not also reach gameplay. Presses during the open animation are swallowed,
so the press that started a conversation never skips its first line.

## Usage: how lines advance

`advance_mode` on the resource decides who moves the dialogue forward:

| Mode | Behaviour |
|---|---|
| `AUTO` | Advances on its own after `hold_after_line`. The hold cannot be skipped. |
| `MANUAL` | Waits for `skip_action`. No timer. |
| `HYBRID` | Either the timer or the player's input advances it. The default. |

In every mode, pressing `skip_action` while a line is still typing completes
that line instantly — as long as `allow_skip` is true.

## Usage: timing and animation

All of it lives on the resource:

```gdscript
resource.text_speed = 0.075       # seconds per visible character
resource.time_to_start = 0.25     # delay between play() and the box appearing
resource.hold_after_line = 0.75   # pause before auto-advancing
resource.open_time = 0.55
resource.open_transition = Tween.TRANS_ELASTIC
resource.close_time = 0.20
```

## Usage: theming

Assign a `DialogueTheme` to the view's `dialogue_theme`. Without one, a built-in
dark style is used.

```gdscript
dialogue_view.dialogue_theme = preload("res://ui/my_dialogue_theme.tres")
dialogue_view.apply_theme()
```

The theme covers the box (`background_color`, `border_color`, `border_width`,
`corner_radius`, `padding`), the text (`font_color`, `font_size`, `font`) and
`position_margin`, the distance from the view's left, right and bottom edges.

For a textured box, set `background_texture` (drawn as a 9-slice, with
`texture_patch_margin` pixels of unstretched border). `background_color` then
tints the texture, and the border and corner settings are ignored.

## BBCode

The reveal is BBCode-aware: the whole line is laid out first and revealed with
`RichTextLabel.visible_characters`, so a line like
`Look for it in the [i]east wing[/i].` types out without leaking markup, and
words never jump to the next line halfway through being typed.

`BBCodeParser` is still available as a utility (`visible_length()`, `prefix()`)
for your own code.
