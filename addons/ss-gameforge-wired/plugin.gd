@tool
extends EditorPlugin

const _PANEL_SCRIPT = preload("res://addons/ss-gameforge-wired/editor/gw_editor_panel.gd")

var _panel: Control = null


func _enter_tree() -> void:
	_panel = _PANEL_SCRIPT.new()
	_panel.name = "GodotWired"
	add_control_to_dock(DOCK_SLOT_RIGHT_BL, _panel)


func _exit_tree() -> void:
	if _panel != null:
		remove_control_from_docks(_panel)
		_panel.queue_free()
		_panel = null


func _enable_plugin() -> void:
	pass


func _disable_plugin() -> void:
	pass
