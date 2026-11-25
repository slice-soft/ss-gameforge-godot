# Event Bus

`EventBus` lets your game's systems talk without holding references to each other.
The addon does not ship a fixed list of events: every game extends `EventBus` and
declares **its own typed signals**, so Godot validates and autocompletes them.

> Requires `ss-gameforge-singleton`: `EventBus` extends `SingletonNode`.

## When to use

- The UI, audio, or achievements must react to gameplay ("player died", "coin picked up")
  without the player script knowing they exist.
- A system is created and destroyed often (enemies, pooled bullets) and should stop
  receiving events as soon as it leaves the scene.

## Key API

- `class_name MyEvents extends EventBus` declares your game's bus and its `signal`s.
- `MyEvents.i` returns the active instance. You write this accessor in your subclass.
- `listen(owner, {signal: callable})` connects every pair for `owner`. Everything is
  disconnected when `owner` leaves the scene tree.
- `unlisten(owner)` disconnects everything `owner` registered, whenever you want.
- `trace` (default `false`): when `true` in a debug build, prints one line per
  emission, such as `[EventBus] player_died(1)`.
- Emit with Godot's own API: `MyEvents.i.player_died.emit(1)`.

## Usage: declaring your bus

```gdscript
# game_events.gd
class_name GameEvents
extends EventBus

static var i: GameEvents:
	get:
		return SingletonNode.get_instance_for(GameEvents) as GameEvents

signal player_died(player_id: int)
signal health_changed(current: int, max_value: int)
```

Create it once, early, for example in your main scene:

```gdscript
func _enter_tree() -> void:
	SingletonNode.ensure_for(GameEvents, get_tree().root, "GameEvents")
```

## Usage: emitting and listening

```gdscript
# player.gd
GameEvents.i.player_died.emit(player_id)
```

```gdscript
# hud.gd
func _enter_tree() -> void:
	_subscribe.call_deferred()

func _subscribe() -> void:
	GameEvents.i.listen(self, {
		GameEvents.i.player_died: _on_player_died,
		GameEvents.i.health_changed: _on_health_changed,
	})

func _on_player_died(player_id: int) -> void:
	...
```

`ensure_for` adds the bus with `call_deferred`, so a node that enters the tree in the
same frame subscribes one deferred step later. That is why the example uses
`_subscribe.call_deferred()`.

## Debugging

```gdscript
GameEvents.i.trace = true   # [EventBus] player_died(1)
```

Only the signals your subclass declares are traced. Release builds never print.

## Pitfalls

- **Call `listen` from `_enter_tree`, not `_ready`.** Leaving the tree removes the
  subscriptions, and `_ready` runs only once, so a pooled or re-parented node would
  stop receiving events after its first trip out of the tree.
- **Listening from a node outside the tree** prints a warning. Its bindings are
  removed only on tree exit or `unlisten()`. If it is freed without ever entering the
  tree, Godot drops bindings to its own methods automatically, but a lambda or another
  object's method keeps firing until the next `listen()` or `unlisten()` call on that
  bus cleans it up. Call `unlisten(node)` before freeing a node that never entered the tree.
- **Several buses are fine.** Each subclass (`GameEvents`, `UIEvents`, ...) has its own
  instance.
