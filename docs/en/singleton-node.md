# SingletonNode

`SingletonNode` is a helper base class that guarantees a single active instance
per script. If another instance of the same script enters the scene tree, the
new one is freed automatically.

## When to use

- You want a service-like node that must exist only once.
- You need to access that node globally without relying on autoloads.
- You want the singleton to be created on-demand.

## Key API

- `SingletonNode.get_instance_for(script)` returns the active instance for a script.
- `SingletonNode.ensure_for(script, root, instance_name)` creates and adds the instance if missing.
- `is_active_instance()` checks if the current node is the active singleton.

## Usage: extending `SingletonNode`

Both `BossFightDirector` and `SaveService` extend `SingletonNode`:

```gdscript
extends SingletonNode
class_name BossFightDirector

static var i: BossFightDirector:
	get:
		return SingletonNode.get_instance_for(BossFightDirector) as BossFightDirector

var phase := 1

func next_phase() -> int:
	phase += 1
	print("[BossFightDirector] phase -> ", phase)
	return phase
```

```gdscript
extends SingletonNode
class_name SaveService

static var i: SaveService:
	get:
		return SingletonNode.get_instance_for(SaveService) as SaveService

func save_game(data: Dictionary) -> void:
	pass
```

## Usage: placing in the scene

**BossFightDirector** must be added as a node in the scene where the boss fight occurs.
You can attach the script directly to a Node in your scene tree.

> If another instance of the same script enters the scene tree, it will be automatically freed.

## Usage: accessing the singleton

```gdscript
if BossFightDirector.i:
	BossFightDirector.i.next_phase()
```

## Usage: ensure instance exists

Use `ensure_for()` to create the singleton if it doesn't exist:

- **Automatic**: Call it in the main scene's `_enter_tree()` for services needed immediately.
- **On-demand**: Call it after a player event (like saving, loading, entering a boss fight).

```gdscript
# In your main scene _ready() for automatic initialization
func _ready() -> void:
	SingletonNode.ensure_for(SaveService, get_tree().root, "SaveService")

# Or after a player event
func _on_player_entered_boss_fight() -> void:
	SingletonNode.ensure_for(BossFightDirector, get_tree().root, "BossFightDirector")
```
> Note: `ensure_for()` is safe to call multiple times, even in the same frame.
> If an instance already exists, no new node will be created.

The new node is registered right away, so `get_instance_for()` (and an `.i`
accessor) returns it immediately, but it is added to `root` deferred: it enters
the tree, and runs `_ready()`, at the end of the frame. Code that needs the tree
(`get_tree()`, timers, children) should wait for that.

If a node of the same script that was placed in a scene enters the tree before
the deferred add happens, the scene node wins (it keeps its inspector settings)
and the pending one is discarded. Read the instance back through
`get_instance_for()` or `.i` rather than keeping the reference `ensure_for()`
returned.

## Duplicates

When a second instance enters the tree while one is active, it logs a warning,
stops processing and is freed at the end of the frame. Its `_ready()` still
runs once, so guard one-time setup with `is_active_instance()`:

```gdscript
func _ready() -> void:
	if not is_active_instance():
		return
	Input.joy_connection_changed.connect(_on_joy_changed)
```

Subclasses that override `_enter_tree()` or `_exit_tree()` must call `super()`,
or the registry is never updated.