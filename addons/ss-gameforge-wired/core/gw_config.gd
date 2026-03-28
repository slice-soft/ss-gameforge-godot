## Project-level configuration resource for GodotWired.
## Create and edit this via the GodotWired editor panel,
## then load it at runtime with GWInputManager.i.load_config(config).
extends Resource
class_name GWConfig

## How players are structured in this project.
enum PlayerMode {
	## One local player. Keyboard/mouse + any connected gamepad.
	SINGLE,
	## N local players, each assigned an exclusive device.
	## Device assignment is handled by the game (e.g. lobby screen).
	LOCAL_COOP,
	## One local player. Remote players are managed by the game's network layer.
	ONLINE,
}

## Player structure for this project.
@export var player_mode: PlayerMode = PlayerMode.SINGLE
## Number of local players. Only relevant when player_mode == LOCAL_COOP.
@export_range(2, 8) var max_local_players: int = 2
## All actions available in the game.
@export var actions: Array[GWActionConfig] = []
