@tool
extends EditorPlugin

const _PANEL_SCRIPT = preload("res://addons/ss-gameforge-wired/scenes/gw_editor_panel.tscn")

var _panel: Control


func _enter_tree() -> void:
	_panel = _PANEL_SCRIPT.instantiate() as Control
	get_editor_interface().get_editor_main_screen().add_child(_panel)
	_panel.owner = null
	_panel.hide()


func _exit_tree() -> void:
	if _panel != null:
		_panel.queue_free()

func _has_main_screen() -> bool:
	return true

func _make_visible(visible: bool) -> void:
	if _panel:
		_panel.visible = visible


func _get_plugin_name() -> String:
	return "GodotWired"

func _get_plugin_icon() -> Texture2D:
	return get_editor_interface().get_base_control().get_theme_icon("Node", "EditorIcons")