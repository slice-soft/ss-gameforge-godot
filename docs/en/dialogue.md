# Dialogue

`DialogueView` is a `Control` that types out a sequence of lines, one character
at a time, and animates a box in and out around them. The box can be a screen
dialogue box or a speech bubble over a character, in 2D or 3D
(`DialogueView3D`). The lines live in a
`DialogueResource`, so writing content never means touching the view.

## When to use

- You need a dialogue box with a typewriter reveal and open/close animation.
- You want the text content to be data, editable as a resource.
- Your lines use BBCode and must reveal correctly, tag by tag.
- You want a fixed box at the bottom of the screen, speech bubbles in the world, or both.

## Key API

- `play(resource)` starts a sequence. This is the primary entry point.
- `stop()` cancels the current dialogue and plays the close animation.
- `apply_theme()` re-applies `dialogue_theme`; `play()` already calls it.
- `is_playing()` is true from `play()` until `dialogue_finished`.
- `skip()` completes the current line or advances, like a `skip_action` press.
- `back()` shows the previous line again; `@export back_action` does it from input.
- `@export history: DialogueHistory` records every line shown, shareable between views.
- `@export hide_action` hides every dialogue while held; `DialogueView.set_all_hidden()` from code.
- `@export layout`: `SCREEN` (bottom box) or `BUBBLE` (speech bubble).
- `@export input_mode`: `AUTO`, `EVENTS`, `POLLING` or `NONE`.
- `DialogueView3D` is a `Node3D` speech bubble wrapping a `DialogueView`.
- `DialogueSpeaker` gives a line a name, portrait and voice; `get_speaker()` returns the current one.
- Signals: `dialogue_started`, `line_changed(index)`, `character_typed(character)`, `dialogue_finished`.
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

## Usage: layouts — screen box or speech bubble

`layout` decides where the box goes. The same resource, theme and API work with
both, so one game can use a screen box for story scenes and bubbles for
background chatter.

| Layout | Looks like | Fits |
|---|---|---|
| `SCREEN` (default) | A box across the bottom of the view, growing upward. | Top-down and side-view games with a fixed dialogue box. |
| `BUBBLE` | A box sized to its text (wrapping at the theme's `bubble_max_width`), with its bottom-centre on the view's origin. | Speech bubbles over characters, in 2D or 3D. |

### 2D speech bubble

Put a `DialogueView` with `layout = BUBBLE` under a `Node2D` (a `Marker2D`
above the character's head works well). The bubble's tail sits on that point and
follows the character and the camera:

```gdscript
@onready var bubble: DialogueView = $HeadMarker/DialogueView  # layout = BUBBLE

func talk() -> void:
	bubble.play(npc_lines)
```

### 3D speech bubble: `DialogueView3D`

`DialogueView3D` is a `Node3D` that builds the world-space setup for you: a
transparent `SubViewport` holding a `DialogueView` in `BUBBLE` layout, shown on
a billboard `Sprite3D`, with the viewport resized to the bubble on every line.
Place it where the tail should point and call `play()`:

```gdscript
@onready var bubble: DialogueView3D = $Head/DialogueView3D

func talk() -> void:
	bubble.play(npc_lines)
```

It forwards `play()`, `stop()`, `skip()`, `is_playing()` and the three signals;
`get_view()` returns the inner `DialogueView` for anything else. Sprite options:
`pixel_size` (world units per bubble pixel, default `0.01`), `billboard`,
`no_depth_test` (on by default, so geometry never hides the text) and
`fixed_size` (same size on screen at any distance).

## Usage: input

`skip_action` is read according to `input_mode`:

| Mode | Reads input from |
|---|---|
| `AUTO` (default) | `_unhandled_input` events, marking the press handled. When the view sits in a `SubViewport` that gets no events (one used as a texture, like inside `DialogueView3D`), it polls instead. |
| `EVENTS` | Only events. |
| `POLLING` | `Input.is_action_just_pressed()` every frame, in any viewport. The press is not consumed. |
| `NONE` | Nothing: drive the dialogue yourself with `skip()`. |

`skip()` does what a press does: completes the line being typed, or advances to
the next line (except in `AUTO` advance mode). It returns `true` when it did
something, so you can forward input from your own system, e.g. per player:

```gdscript
func _process(_delta: float) -> void:
	if player.is_action_just_pressed("talk"):
		bubble.skip()
```

## Usage: speakers — name, portrait and voice

A `DialogueSpeaker` resource describes who is talking. Make one per character
and reuse it:

| Field | Does |
|---|---|
| `display_name` | Shown above the text (through `tr()` when the resource uses translation). Empty = no name. |
| `name_color` | Colour of the name. Transparent = the theme's `name_color`. |
| `portrait` | Drawn beside the text at the theme's `portrait_size`. Empty = no portrait. |
| `voice` | Short sound played while the line types. Empty = silent. |
| `voice_pitch`, `pitch_variation` | Base pitch, and the random change per blip (`0.05` = ±5%). |
| `voice_every` | Blip every this many characters (spaces skipped). |
| `voice_volume_db` | Volume of the blip. |

Set `speaker` on the resource for the whole sequence, and `line_speakers` to
change speaker on given lines (by index; a missing or empty entry uses
`speaker`):

```gdscript
const ANA := preload("res://characters/ana_speaker.tres")
const BO := preload("res://characters/bo_speaker.tres")

resource.dialogues = ["Did you hear that?", "Hear what?", "Never mind."]
resource.speaker = ANA
resource.line_speakers = [null, BO]   # line 1 is Bo, the rest Ana
```

It works the same in the screen box and in 2D/3D bubbles; a bubble grows to fit
the portrait and the name. Voice blips play on `voice_bus` (default `Master`).
Skipping a line completes it silently.

For anything else per character — mouth flaps, your own sound system — connect
`character_typed(character)`, emitted for each character as it is revealed.

## Usage: history and going back

Every line a view shows is written to its `history`, a `DialogueHistory`
resource. Assign the same one to several views (screen box, 2D and 3D bubbles)
and it gathers every speaker in one log:

```gdscript
var log := DialogueHistory.new()

func _ready() -> void:
	$DialogueView.history = log
	$Npc/DialogueView3D.history = log
```

Each entry is `{"text", "speaker", "speaker_name", "resource", "index"}`, with the text as it was shown
(translated, BBCode included). The addon records; your game decides how the
backlog looks:

```gdscript
func open_backlog() -> void:
	for entry in log.get_entries():
		backlog_list.append_text(entry["text"] + "\n")
```

`max_entries` (default 200, `0` = unlimited) drops the oldest, `clear()` empties
it, and `entry_added` fires on every new line. A view with no history assigned
keeps its own.

`back()`, or a press of the optional `back_action`, shows the previous line of
the running sequence again, already complete. Moving forward again does not
record those lines twice.

## Usage: hiding every dialogue

Set `hide_action` to an input action and, while the player holds it, every
dialogue (screen box, 2D and 3D bubbles) is hidden so the scene behind can be
seen. They are not paused: lines keep typing and `skip_action` still advances.
Releasing the button shows them again.

Bind `hide_action` to a button next to `skip_action`: the player holds it to
look, lets go to read, and presses continue as usual.

> Use hiding with `MANUAL` advance mode. In `AUTO` and `HYBRID` the timer keeps
> advancing while the dialogue is hidden, so the player can miss lines.

From code, `DialogueView.set_all_hidden(true)` hides them all until
`set_all_hidden(false)`, independently from the button, and
`DialogueView.is_all_hidden()` tells whether they are hidden. Views created
while hidden start hidden.

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
`corner_radius`, `padding`), the text (`font_color`, `font_size`, `font`), the speaker (`name_color`,
`name_font_size`, `portrait_size`) and
`position_margin`, the distance from the view's left, right and bottom edges
(`SCREEN` layout), and `bubble_max_width`, where a bubble's text starts to wrap
(`BUBBLE` layout, default 320 px).

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
