## Abstraction of a physical input device (keyboard/mouse or gamepad).
## Uses RefCounted to avoid SceneTree overhead — not a Node.
extends RefCounted
class_name GWDevice

## Category of physical device.
enum DeviceType { KEYBOARD_MOUSE, GAMEPAD, UNKNOWN }

## Godot device index. -1 = keyboard/mouse.
var device_id: int = -1
## Category of this device.
var device_type: DeviceType = DeviceType.UNKNOWN
## Name reported by the operating system.
var device_name: String = ""
## Whether the device is currently connected.
var is_connected: bool = true
## ID of the player this device is assigned to. -1 = unassigned.
var assigned_player: int = -1


# --- Factories ---

## Creates the keyboard/mouse device entry (device_id = -1).
static func create_keyboard_mouse() -> GWDevice:
	var d := GWDevice.new()
	d.device_id = -1
	d.device_type = DeviceType.KEYBOARD_MOUSE
	d.device_name = "Keyboard & Mouse"
	d.is_connected = true
	return d


## Creates a GWDevice for the given Godot gamepad index.
static func create_gamepad(device_index: int) -> GWDevice:
	var d := GWDevice.new()
	d.device_id = device_index
	d.device_type = DeviceType.GAMEPAD
	d.device_name = Input.get_joy_name(device_index)
	d.is_connected = true
	return d


## Scans and returns all currently connected devices (keyboard/mouse + all gamepads).
static func scan_connected_devices() -> Array:
	var result: Array = []
	result.append(GWDevice.create_keyboard_mouse())
	for idx in Input.get_connected_joypads():
		result.append(GWDevice.create_gamepad(idx))
	return result


# --- Queries ---

## Returns a display-friendly name, including player slot if assigned.
func get_display_name() -> String:
	if device_type == DeviceType.KEYBOARD_MOUSE:
		return "Keyboard & Mouse"
	var base := device_name if not device_name.is_empty() else "Gamepad %d" % device_id
	if assigned_player >= 0:
		return "%s (P%d)" % [base, assigned_player + 1]
	return base


## Returns true if this device is a gamepad.
func is_gamepad() -> bool:
	return device_type == DeviceType.GAMEPAD


## Returns true if this device is assigned to a player.
func is_assigned() -> bool:
	return assigned_player >= 0
