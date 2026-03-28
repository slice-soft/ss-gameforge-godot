## Serializable definition of a single action.
## Used as the data source for the editor panel and GWConfig.
## Default bindings are editable in the Godot inspector on each resource instance.
extends Resource
class_name GWActionConfig

## Whether this action represents a digital press or an analog axis.
enum ActionType { BUTTON, AXIS }

## Internal identifier used in gameplay code (e.g. "jump", "move_left").
@export var action_name: String = ""
## Label shown in the player's rebind screen.
@export var display_name: String = ""
## Optional tooltip for the rebind screen.
@export var description: String = ""
## Groups this action in the rebind screen (e.g. "Movement", "Combat").
@export var category: String = "General"
## Maximum binding slots per player. 0 = unlimited.
@export var max_bindings: int = 2
## Whether this action is a digital button or an analog axis.
@export var action_type: ActionType = ActionType.BUTTON
## Axis only — label for the positive direction (e.g. "right", "up", "accelerate").
@export var positive_name: String = ""
## Axis only — label for the negative direction (e.g. "left", "down", "brake").
@export var negative_name: String = ""
## If false, the action cannot be rebound at runtime.
@export var allow_rebind: bool = true
## Default bindings cloned into each player on load_config().
## Configure these in the Godot inspector or via code after load_config().
@export var default_bindings: Array[GWBinding] = []
