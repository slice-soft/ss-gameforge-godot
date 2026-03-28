@tool
extends EditorPlugin

const _RESOURCE_SCRIPT = preload("core/models/dialogue_resource.gd")
const _THEME_SCRIPT = preload("theme/dialogue_theme.gd")


func _enter_tree() -> void:
	add_custom_type("DialogueResource", "Resource", _RESOURCE_SCRIPT, null)
	add_custom_type("DialogueTheme", "Resource", _THEME_SCRIPT, null)


func _exit_tree() -> void:
	remove_custom_type("DialogueResource")
	remove_custom_type("DialogueTheme")

