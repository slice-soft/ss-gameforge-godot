# Wired

`GWInputManager` is an input system built around **actions** and **players**.
Gameplay code asks for `"jump"`, never for `KEY_SPACE`. Each player owns a
private copy of every action, so two people on the same machine can rebind the
same action differently.

> Requires `ss-gameforge-singleton`: `GWInputManager` extends `SingletonNode`.

## When to use

- Players must be able to rebind controls at runtime.
- You need local co-op where each player has their own device and bindings.
- You want gamepads to be hot-pluggable, including "press any button to join".
- Godot's project-wide input map is not enough because it is global.

## The model

| Concept | What it is |
|---|---|
| `GWBinding` | One physical input: a key, a mouse button, a pad button, an axis side. |
| `GWAction` | A named group of 1..N bindings. What gameplay code refers to. |
| `GWPlayer` | A player with its own copy of every action and its own device list. |
| `GWDevice` | A connected device. `-1` is always keyboard/mouse. |

Actions are first registered as **templates** on the manager, then cloned into
each player as it is created. Rebinding a player's action never touches the
template or the other players.

## Key API

- `GWInputManager.i` returns the active instance; `GWInputManager.ensure(root)` creates it.
- `define_action(name, display_name, bindings, category, max_bindings)` registers a template.
- `create_player(player_id, player_name)` clones the templates into a new player.
- `is_action_pressed(name, player_id)`, `is_action_just_pressed(name, event, player_id)`,
  `is_action_just_released(name, event, player_id)`, `get_action_strength(name, player_id)`.
- `get_action_axis(name, player_id)` and `get_vector(neg_x, pos_x, neg_y, pos_y, player_id)`.
- `start_rebind_listen(player_id, action_name, binding_index)` captures the next input.
- `save_all_profiles(path)` / `load_all_profiles(path)` persist bindings as JSON.
- `GWBinding.from_key()`, `.from_joy_button()`, `.from_joy_axis()`, `.from_mouse_button()`.

## Usage: creating the manager

```gdscript
func _enter_tree() -> void:
	SingletonNode.ensure_for(GWInputManager, get_tree().root, "GWInputManager")
```

`GWInputManager.ensure(get_tree().root)` does the same thing in one call.

## Usage: defining actions and a player

Templates must exist **before** `create_player()`, because that is when they are
cloned. This is the showcase's setup:

```gdscript
func _setup_input() -> void:
	var wired := GWInputManager.i

	wired.define_action("next_pokemon", "Next Pokémon", [
		GWBinding.from_key(KEY_RIGHT),
		GWBinding.from_key(KEY_D),
	], "Navigation", 2)

	wired.define_action("open_pokedex", "Open Pokédex", [
		GWBinding.from_key(KEY_ENTER),
		GWBinding.from_key(KEY_SPACE),
	], "Navigation", 2)

	var player := wired.create_player(0, "Player 1")
	player.accepts_keyboard = true
```

`display_name` and `category` are what a rebind screen shows and groups by;
`max_bindings` caps how many alternates the action accepts (`0` = unlimited).

> A player created before an action was defined will not have it. Define every
> action first, or call `create_player()` again after adding more.

## Usage: reading input

Player `0` is the default, so single-player code stays short:

```gdscript
func _process(_delta: float) -> void:
	if GWInputManager.i.is_action_just_pressed("open_pokedex"):
		open_pokedex()

	if GWInputManager.i.is_action_pressed("run"):
		speed = run_speed
```

Called without an event, `is_action_just_pressed()` and
`is_action_just_released()` use per-frame tracking, so they are safe in
`_process()`. Pass the event when you are inside `_input()` and want to react to
that exact event:

```gdscript
func _input(event: InputEvent) -> void:
	if GWInputManager.i.is_action_just_pressed("jump", event):
		jump()
```

For movement, `get_vector()` builds the vector from four actions:

```gdscript
var direction := GWInputManager.i.get_vector(
	"move_left", "move_right", "move_up", "move_down"
)
```

## Usage: local co-op

Give each player its own device. Keyboard is opt-in per player; gamepads are
assigned exclusively:

```gdscript
var p1 := wired.create_player(0, "Player 1")
p1.accepts_keyboard = true

var p2 := wired.create_player(1, "Player 2")
p2.assign_gamepad(0)
```

Then pass the player id when reading:

```gdscript
if GWInputManager.i.is_action_pressed("attack", 1):
	players[1].attack()
```

### Press to join

`unassigned_device_pressed` fires when a device nobody owns produces a press —
which is exactly the signal a join screen needs:

```gdscript
func _ready() -> void:
	GWInputManager.i.unassigned_device_pressed.connect(_on_device_pressed)

func _on_device_pressed(device_id: int) -> void:
	var slot := next_free_slot()
	var player := GWInputManager.i.create_player(slot, "Player %d" % (slot + 1))
	player.assign_gamepad(device_id)
```

`get_unassigned_gamepads()` lists the pads still free, and
`device_connected` / `device_disconnected` cover hot-plugging.

## Usage: rebinding at runtime

Rebinding is a listen mode: the manager captures the next valid input and writes
it into the slot you named.

```gdscript
func _on_rebind_button_pressed(action_name: String) -> void:
	GWInputManager.i.rebind_listening.connect(_on_listening, CONNECT_ONE_SHOT)
	GWInputManager.i.binding_remapped.connect(_on_remapped, CONNECT_ONE_SHOT)
	GWInputManager.i.start_rebind_listen(0, action_name, 0)

func _on_listening(player_id: int, action_name: String, binding_index: int) -> void:
	label.text = "Press any input for %s..." % action_name

func _on_remapped(player_id: int, action_name: String) -> void:
	refresh_rebind_list()
```

`binding_index` is which slot to overwrite — `0` is the primary binding, `1` the
first alternate, and so on.

While listening, `is_listening_for_rebind()` returns true. Use it to pause
gameplay, otherwise the key being captured also triggers whatever it is bound to
today. `cancel_rebind_listen()` aborts and emits `rebind_cancelled`.

> Actions whose `allow_rebind` is false are meant to stay fixed; keep them out of
> the rebind screen.

## Usage: saving bindings

```gdscript
GWInputManager.i.save_all_profiles()                  # user://gw_bindings.json
GWInputManager.i.load_all_profiles()
GWInputManager.i.reset_all_to_defaults()
```

`load_all_profiles()` does nothing if the file is missing, and only applies
bindings to players that **already exist** — so create the players first, then
load.

For several named profiles, `GWProfileManager` wraps the same thing in slots:

```gdscript
GWProfileManager.save(GWInputManager.i, "southpaw")
GWProfileManager.load_profile(GWInputManager.i, "southpaw")
GWProfileManager.list_profiles()      # ["southpaw", "default"]
GWProfileManager.delete_profile("southpaw")
```

Each profile is its own file, `user://gw_profile_<name>.json`.

## Usage: the editor panel

Enabling the plugin adds a **GodotWired** main-screen tab next to 2D, 3D and
Script. Use it to build a `GWConfig` resource — the project's action list, its
player mode (`SINGLE`, `LOCAL_COOP`, `ONLINE`) and the default bindings — and
load it at startup instead of calling `define_action()` by hand:

```gdscript
const CONFIG := preload("res://input/game_input.tres")

func _enter_tree() -> void:
	SingletonNode.ensure_for(GWInputManager, get_tree().root, "GWInputManager")
	GWInputManager.i.load_config(CONFIG)
```

> `load_config()` clears every existing template **and player** before applying
> the config. Call it during startup, not mid-game.

## Axis actions

An action can be an axis instead of a button. It then holds bindings for the
positive direction and a second list for the negative one, and reads back as a
single value in `[-1.0, 1.0]`:

```gdscript
var throttle := GWInputManager.i.get_action_axis("throttle")
```

`positive_name` and `negative_name` on the action are the labels a rebind screen
shows for each side ("accelerate" / "brake").
