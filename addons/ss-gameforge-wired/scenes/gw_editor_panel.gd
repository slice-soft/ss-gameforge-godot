@tool
extends VBoxContainer

const GWConfig = preload("res://addons/ss-gameforge-wired/core/gw_config.gd")
const GWActionConfig = preload("res://addons/ss-gameforge-wired/core/gw_action_config.gd")

const DEFAULT_CONFIG_PATH := "res://gw_config.tres"

var _config: GWConfig = null
var _current_action: GWActionConfig = null

# --- UI references ---
@onready var mode_option: OptionButton = $ModeRow/ModeOption
@onready var max_players_row: HBoxContainer = $MaxPlayersRow
@onready var max_players_spin: SpinBox = $MaxPlayersRow/MaxPlayersSpin
@onready var action_list: ItemList = $MainSplit/LeftPanel/ActionList
@onready var path_edit: LineEdit = $PathRow/PathEdit
@onready var status_label: Label = $StatusLabel

# Properties panel
@onready var prop_placeholder: Label = $MainSplit/RightPanel/PropPlaceholder
@onready var prop_grid: GridContainer = $MainSplit/RightPanel/PropGrid
@onready var action_id_value_label: Label = $MainSplit/RightPanel/PropGrid/ActionIdValueLabel
@onready var prop_name: LineEdit = $MainSplit/RightPanel/PropGrid/PropName
@onready var prop_desc_name: LineEdit = $MainSplit/RightPanel/PropGrid/PropDescName
@onready var prop_description: LineEdit = $MainSplit/RightPanel/PropGrid/PropDescription
@onready var prop_category: LineEdit = $MainSplit/RightPanel/PropGrid/PropCategory
@onready var prop_type: OptionButton = $MainSplit/RightPanel/PropGrid/PropType
@onready var prop_allow_rebind: CheckBox = $MainSplit/RightPanel/PropGrid/PropAllowRebind

# Axis-only rows
@onready var positive_name_text_label: Label = $MainSplit/RightPanel/PropGrid/PositiveNameTextLabel
@onready var prop_positive_name: LineEdit = $MainSplit/RightPanel/PropGrid/PropPositiveName
@onready var negative_name_text_label: Label = $MainSplit/RightPanel/PropGrid/NegativeNameTextLabel
@onready var prop_negative_name: LineEdit = $MainSplit/RightPanel/PropGrid/PropNegativeName

@onready var add_action_button: Button = $MainSplit/LeftPanel/ActionButtonsRow/AddActionButton
@onready var remove_action_button: Button = $MainSplit/LeftPanel/ActionButtonsRow/RemoveActionButton
@onready var load_button: Button = $PathRow/LoadButton
@onready var save_button: Button = $SaveButton

var _axis_rows: Array[Control] = []

func _ready() -> void:
	_axis_rows = [
		positive_name_text_label,
		prop_positive_name,
		negative_name_text_label,
		prop_negative_name
	]
	
	max_players_spin.min_value = 2
	max_players_spin.max_value = 8
	max_players_spin.step = 1
	
	mode_option.item_selected.connect(_on_mode_changed)
	max_players_spin.value_changed.connect(_on_max_players_changed)
	action_list.item_selected.connect(_on_action_selected)
	add_action_button.pressed.connect(_on_add_action_pressed)
	remove_action_button.pressed.connect(_on_remove_action_pressed)
	load_button.pressed.connect(_load_or_new)
	save_button.pressed.connect(_on_save_pressed)

	prop_name.text_changed.connect(_on_prop_name_changed)
	prop_desc_name.text_changed.connect(_on_prop_desc_name_changed)
	prop_description.text_changed.connect(_on_prop_description_changed)
	prop_category.text_changed.connect(_on_prop_category_changed)
	prop_type.item_selected.connect(_on_type_changed)
	prop_positive_name.text_changed.connect(_on_prop_positive_name_changed)
	prop_negative_name.text_changed.connect(_on_prop_negative_name_changed)
	prop_allow_rebind.toggled.connect(_on_prop_allow_rebind_toggled)
	_load_or_new()


# callbacks

func _on_mode_changed(index: int) -> void:
	if _config == null:
		return
	_config.set("player_mode", mode_option.get_item_id(index))
	_update_max_players_visibility()

func _on_max_players_changed(value: float) -> void:
	if _config == null:
		return
	_config.set("max_local_players", int(value))

func _on_action_selected(index: int) -> void:
	if _config == null:
		return
	var actions: Array[GWActionConfig] = _config.get("actions")
	if index >= 0 and index < actions.size():
		_populate_properties(actions[index])

func _on_add_action_pressed() -> void:
	if _config == null:
		return
	var actions: Array[GWActionConfig] = _config.get("actions")
	var new_action := GWActionConfig.new()
	new_action.action_id = _generate_unique_action_id(actions)
	new_action.action_name = _generate_unique_action_name(actions)
	new_action.display_name = "Action " + str(actions.size())
	new_action.description = "Hold to charge, press to dash..."
	actions.append(new_action)
	action_list.add_item(new_action.action_name)
	action_list.select(actions.size() - 1)
	_populate_properties(new_action)

func _on_remove_action_pressed() -> void:
	if _current_action == null or _config == null:
		return
	var actions: Array[GWActionConfig] = _config.get("actions")
	var index := actions.find(_current_action)
	if index != -1:
		actions.remove_at(index)
		action_list.remove_item(index)
		_current_action = null
		prop_placeholder.visible = true
		prop_grid.visible = false

func _load_or_new() -> void:
	var file_path := path_edit.text.strip_edges()
	if file_path == "":
		file_path = DEFAULT_CONFIG_PATH
	path_edit.text = file_path

	if ResourceLoader.exists(file_path):
		var res := ResourceLoader.load(file_path, "", ResourceLoader.CACHE_MODE_IGNORE)
		if res is GWConfig:
			_config = res
			_populate_ui_from_config()
			status_label.text = "Config loaded from: " + file_path
			return
		else:
			status_label.text = "Error: Resource is not a valid GWConfig."

	_config = GWConfig.new()
	_populate_ui_from_config()
	if not ResourceLoader.exists(file_path):
		status_label.text = "New config created."

func _on_save_pressed() -> void:
	if _config == null:
		status_label.text = "Error: No config to save."
		return
	var file_path := path_edit.text.strip_edges()
	if file_path.is_empty():
		file_path = DEFAULT_CONFIG_PATH
	var err := ResourceSaver.save(_config, file_path)
	if err == OK:
		status_label.text = "Config saved to: " + file_path
	else:
		status_label.text = "Error saving config: " + str(err)

func _on_prop_name_changed(new_text: String) -> void:
	if _current_action == null:
		return
	_current_action.set("action_name", new_text)
	var actions: Array[GWActionConfig] = _config.get("actions")
	var index := actions.find(_current_action)
	if index != -1:
		action_list.set_item_text(index, new_text)

func _on_prop_desc_name_changed(new_text: String) -> void:
	if _current_action == null:
		return
	_current_action.set("display_name", new_text)

func _on_prop_description_changed(new_text: String) -> void:
	if _current_action == null:
		return
	_current_action.set("description", new_text)

func _on_prop_category_changed(new_text: String) -> void:
	if _current_action == null:
		return
	_current_action.set("category", new_text)

func _on_type_changed(index: int) -> void:
	if _current_action == null:
		return
	_current_action.set("action_type", prop_type.get_item_id(index))
	_update_axis_rows_visibility(_current_action.action_type)

func _on_prop_positive_name_changed(new_text: String) -> void:
	if _current_action == null:
		return
	_current_action.set("positive_name", new_text)

func _on_prop_negative_name_changed(new_text: String) -> void:
	if _current_action == null:
		return
	_current_action.set("negative_name", new_text)

func _on_prop_allow_rebind_toggled(pressed: bool) -> void:
	if _current_action == null:
		return
	_current_action.set("allow_rebind", pressed)

# helpers

func _update_max_players_visibility() -> void:
	if _config == null:
		return
	max_players_row.visible = _config.get("player_mode") == GWConfig.PlayerMode.LOCAL_COOP

func _update_axis_rows_visibility(action_type: int) -> void:
	var is_axis := action_type == GWActionConfig.ActionType.AXIS
	for control in _axis_rows:
		control.visible = is_axis

func _populate_properties(action: GWActionConfig) -> void:
	_current_action = action
	prop_placeholder.visible = false
	prop_grid.visible = true
	
	action_id_value_label.text = action.action_id
	prop_name.text = action.action_name
	prop_desc_name.text = action.display_name
	prop_description.text = action.description
	prop_category.text = action.category
	var type_index := prop_type.get_item_index(action.action_type)
	if type_index == -1:
		type_index = 0
	prop_type.select(type_index)
	prop_allow_rebind.button_pressed = action.allow_rebind
	_update_axis_rows_visibility(action.action_type)
	
	if action.action_type == GWActionConfig.ActionType.AXIS:
		prop_positive_name.text = action.positive_name
		prop_negative_name.text = action.negative_name

func _populate_ui_from_config() -> void:
	if _config == null:
		return
	_current_action = null
	action_list.deselect_all()
	prop_placeholder.visible = true
	prop_grid.visible = false

	var mode_index := mode_option.get_item_index(_config.get("player_mode"))
	if mode_index == -1:
		mode_index = 0
	mode_option.select(mode_index)
	max_players_spin.value = int(_config.get("max_local_players")) if _config.get("player_mode") == GWConfig.PlayerMode.LOCAL_COOP else 2
	action_list.clear()
	var actions: Array[GWActionConfig] = _config.get("actions")
	_ensure_unique_action_ids(actions)
	for action in actions:
		action_list.add_item(action.action_name)
	_update_max_players_visibility()

func _generate_unique_action_id(actions: Array[GWActionConfig]) -> String:
	var used_ids := {}
	for action in actions:
		used_ids[str(action.action_id)] = true
	while true:
		var candidate := "act_%d_%x" % [Time.get_ticks_usec(), randi() & 0xfffff]
		if not used_ids.has(candidate):
			return candidate
	return ""

func _generate_unique_action_name(actions: Array[GWActionConfig]) -> String:
	var used_names := {}
	for action in actions:
		used_names[str(action.action_name)] = true
	var idx := actions.size()
	while true:
		var candidate := "action_%d" % idx
		if not used_names.has(candidate):
			return candidate
		idx += 1
	return ""

func _ensure_unique_action_ids(actions: Array[GWActionConfig]) -> void:
	var used_ids := {}
	for action in actions:
		var current_id := str(action.action_id).strip_edges()
		if current_id.is_empty() or used_ids.has(current_id):
			current_id = _generate_unique_action_id(actions)
			action.action_id = current_id
		used_ids[current_id] = true
