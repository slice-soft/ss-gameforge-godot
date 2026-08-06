# State Machine

`StateMachine` is a `Node` whose children are the states. Each state is a
`StateBase` node that receives `start()` when entered and `end()` when left, and
can opt into the process and input callbacks it actually needs.

## When to use

- A character, enemy or UI screen has behaviour that changes in clear phases.
- You want the flow of a scene (boot → loading → viewing) expressed as nodes.
- You want to see, in the remote scene tree, which state is currently running.

## Key API

- `change_to(state_name)` transitions to a child state, by node name.
- `change_to_previous()` returns to the state left last.
- `current_state` and `previous_state` hold the `StateBase` instances.
- `signal state_changed(from, to)` fires after the new state has started.
- `@export default_state: StateBase` is the state entered on `_ready()`.
- `@export enable_debug_logging: bool` prints transitions in debug builds.
- `get_state_history()` returns the last 10 state names.

On `StateBase`:

- `start()` and `end()`, overridden by each state.
- `controlled_node` is the node the machine acts on.
- `state_machine` is a reference back to the machine.

## Usage: laying out the scene

Add a `StateMachine` node and make each state a child of it:

```
Player
└── StateMachine        (default_state → Idle)
    ├── Idle
    ├── Running
    └── Jumping
```

`change_to()` looks its argument up with `has_node()`, so **the string must be
the child node's name**. Set `default_state` in the inspector to the state that
should run first.

> `controlled_node` is resolved as the machine's `owner` — the root of the scene
> the machine was saved in. Each state receives it before `start()` is called.

## Usage: writing a state

```gdscript
extends StateBase
class_name RunningState

func start() -> void:
	controlled_node.play_animation("run")

func end() -> void:
	controlled_node.stop_animation()

func on_physics_process(delta: float) -> void:
	if controlled_node.velocity.is_zero_approx():
		state_machine.change_to("Idle")
```

The machine only forwards a callback if the state defines it, so a state that
does not need physics simply omits `on_physics_process`. The available hooks are
`on_process(delta)`, `on_physics_process(delta)`, `on_input(event)`,
`on_unhandled_input(event)` and `on_unhandled_key_input(event)`.

## Usage: typing `controlled_node`

`controlled_node` is a plain `Node`. A small base class per machine buys you
autocompletion and type checks in every state — the showcase does this:

```gdscript
extends StateBase
class_name GameManagerStateBase

var game_manager: GameManager:
	set(value): controlled_node = value
	get: return controlled_node as GameManager
```

States then extend `GameManagerStateBase` and use `game_manager` directly.

## Usage: naming states without magic strings

Transitions take strings, which are easy to typo. Keeping them in one resource
gives you a single place to rename them:

```gdscript
extends Resource
class_name GameManagerStates

const Boot: String = "BootState"
const Loading: String = "LoadingState"
const Viewing: String = "ViewingState"
const Dialogue: String = "DialogueState"
```

```gdscript
state_machine.change_to(GameManagerStates.Loading)
```

> The constant's value must match the **child node's name** in the scene, not
> the class name — they only look alike above because the nodes were named after
> their classes.

## Usage: reacting to transitions

```gdscript
func _ready() -> void:
	$StateMachine.state_changed.connect(_on_state_changed)

func _on_state_changed(from: String, to: String) -> void:
	print("%s -> %s" % [from, to])
```

`from` is an empty string on the very first transition, since nothing was
running before it.

## Behaviour worth knowing

- **Re-entering the current state is ignored.** `change_to()` returns early when
  the target is already active, so a state cannot restart itself this way.
- **A missing state is an error, not a crash.** An unknown name calls
  `push_error()` and leaves the current state running.
- **The default state starts deferred.** `_ready()` defers the first transition,
  so the whole tree is available by the time `start()` runs.
- **`change_to_previous()` only remembers one step back.** It is a swap, not a
  stack: use it for pause screens, not for deep navigation history.
