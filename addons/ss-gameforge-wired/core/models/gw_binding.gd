## Atom of the input system. Represents a single physical input.
## Bindings do not know which action they belong to.
extends Resource
class_name GWBinding

## Type of physical input this binding represents.
enum BindingType { KEY, MOUSE_BUTTON, JOY_BUTTON, JOY_AXIS }

## Type of physical input.
@export var type: BindingType = BindingType.KEY
## Device ID. -1 = any gamepad or keyboard/mouse. >= 0 = specific gamepad.
@export var device_id: int = -1
## Keyboard key (only when type == KEY).
@export var key_code: Key = KEY_NONE
## Mouse button (only when type == MOUSE_BUTTON).
@export var mouse_button: MouseButton = MOUSE_BUTTON_NONE
## Gamepad button (only when type == JOY_BUTTON).
@export var joy_button: JoyButton = JOY_BUTTON_INVALID
## Gamepad axis (only when type == JOY_AXIS).
@export var joy_axis: JoyAxis = JOY_AXIS_INVALID
## Axis direction: +1.0 (positive side) or -1.0 (negative side).
@export var axis_direction: float = 1.0
## Minimum axis magnitude to consider the binding active.
@export var deadzone: float = 0.2


# --- Factories ---

## Creates a binding from a keyboard key.
static func from_key(p_key_code: Key) -> GWBinding:
	var b := GWBinding.new()
	b.type = BindingType.KEY
	b.key_code = p_key_code
	return b


## Creates a binding from a gamepad button. device_id = -1 matches any gamepad.
static func from_joy_button(p_joy_button: JoyButton, p_device_id: int = -1) -> GWBinding:
	var b := GWBinding.new()
	b.type = BindingType.JOY_BUTTON
	b.joy_button = p_joy_button
	b.device_id = p_device_id
	return b


## Creates a binding from a gamepad axis. axis_direction is +1.0 or -1.0.
static func from_joy_axis(p_joy_axis: JoyAxis, p_axis_direction: float = 1.0, p_device_id: int = -1) -> GWBinding:
	var b := GWBinding.new()
	b.type = BindingType.JOY_AXIS
	b.joy_axis = p_joy_axis
	b.axis_direction = p_axis_direction
	b.device_id = p_device_id
	return b


## Creates a binding from a mouse button.
static func from_mouse_button(p_mouse_button: MouseButton) -> GWBinding:
	var b := GWBinding.new()
	b.type = BindingType.MOUSE_BUTTON
	b.mouse_button = p_mouse_button
	return b


# --- Evaluation ---

## Returns true if the given InputEvent matches this binding's configuration.
func matches_event(event: InputEvent) -> bool:
	match type:
		BindingType.KEY:
			if event is InputEventKey:
				return (event as InputEventKey).keycode == key_code
		BindingType.MOUSE_BUTTON:
			if event is InputEventMouseButton:
				return (event as InputEventMouseButton).button_index == mouse_button
		BindingType.JOY_BUTTON:
			if event is InputEventJoypadButton:
				var ev := event as InputEventJoypadButton
				return (device_id < 0 or device_id == ev.device) and ev.button_index == joy_button
		BindingType.JOY_AXIS:
			if event is InputEventJoypadMotion:
				var ev := event as InputEventJoypadMotion
				var dir := 1.0 if ev.axis_value > 0.0 else -1.0
				return (device_id < 0 or device_id == ev.device) and ev.axis == joy_axis and dir == axis_direction
	return false


## Returns true if this binding is currently held.
## assigned_devices is the list of int device IDs owned by the querying player.
func is_pressed(assigned_devices: Array) -> bool:
	return get_strength(assigned_devices) > 0.0


## Returns the current input strength in [0.0, 1.0].
## assigned_devices is the list of int device IDs owned by the querying player.
func get_strength(assigned_devices: Array) -> float:
	match type:
		BindingType.KEY:
			if not assigned_devices.has(-1):
				return 0.0
			return 1.0 if Input.is_key_pressed(key_code) else 0.0
		BindingType.MOUSE_BUTTON:
			if not assigned_devices.has(-1):
				return 0.0
			return 1.0 if Input.is_mouse_button_pressed(mouse_button) else 0.0
		BindingType.JOY_BUTTON:
			for dev_id in assigned_devices:
				if (dev_id as int) < 0:
					continue
				if device_id >= 0 and device_id != dev_id:
					continue
				if Input.is_joy_button_pressed(dev_id, joy_button):
					return 1.0
			return 0.0
		BindingType.JOY_AXIS:
			var best := 0.0
			for dev_id in assigned_devices:
				if (dev_id as int) < 0:
					continue
				if device_id >= 0 and device_id != dev_id:
					continue
				var raw := Input.get_joy_axis(dev_id, joy_axis)
				var directed := raw * axis_direction
				if directed > deadzone:
					best = maxf(best, directed)
			return best
	return 0.0


## Returns a human-readable label: "Space", "A Button", "LX +", "Mouse L", etc.
func get_display_name() -> String:
	match type:
		BindingType.KEY:
			return OS.get_keycode_string(key_code)
		BindingType.MOUSE_BUTTON:
			match mouse_button:
				MOUSE_BUTTON_LEFT:       return "Mouse L"
				MOUSE_BUTTON_RIGHT:      return "Mouse R"
				MOUSE_BUTTON_MIDDLE:     return "Mouse M"
				MOUSE_BUTTON_WHEEL_UP:   return "Wheel Up"
				MOUSE_BUTTON_WHEEL_DOWN: return "Wheel Down"
				_: return "Mouse %d" % mouse_button
		BindingType.JOY_BUTTON:
			return Input.get_joy_button_string(joy_button)
		BindingType.JOY_AXIS:
			var dir_str := "+" if axis_direction > 0.0 else "-"
			return "%s %s" % [Input.get_joy_axis_string(joy_axis), dir_str]
	return "Unknown"


# --- Serialization ---

## Serializes this binding to a plain Dictionary.
func to_dict() -> Dictionary:
	return {
		"type": type,
		"device_id": device_id,
		"key_code": key_code,
		"mouse_button": mouse_button,
		"joy_button": joy_button,
		"joy_axis": joy_axis,
		"axis_direction": axis_direction,
		"deadzone": deadzone,
	}


## Deserializes a GWBinding from a plain Dictionary.
static func from_dict(d: Dictionary) -> GWBinding:
	var b := GWBinding.new()
	b.type = d.get("type", GWBinding.BindingType.KEY) as GWBinding.BindingType
	b.device_id = d.get("device_id", -1)
	b.key_code = d.get("key_code", KEY_NONE) as Key
	b.mouse_button = d.get("mouse_button", MOUSE_BUTTON_NONE) as MouseButton
	b.joy_button = d.get("joy_button", JOY_BUTTON_INVALID) as JoyButton
	b.joy_axis = d.get("joy_axis", JOY_AXIS_INVALID) as JoyAxis
	b.axis_direction = d.get("axis_direction", 1.0)
	b.deadzone = d.get("deadzone", 0.2)
	return b
