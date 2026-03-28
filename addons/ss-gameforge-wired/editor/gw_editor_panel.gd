## GodotWired editor panel.
## Left: action list. Right: selected action properties (adapts to Button vs Axis type).
## Generates a GWConfig resource loaded at runtime with GWInputManager.i.load_config().
@tool
extends VBoxContainer

const _GWConfig := preload("res://addons/ss-gameforge-wired/core/gw_config.gd")
const _GWActionConfig := preload("res://addons/ss-gameforge-wired/core/gw_action_config.gd")

const DEFAULT_CONFIG_PATH := "res://gw_config.tres"

var _config: RefCounted = null
var _selected_index: int = -1
var _selected_action: RefCounted = null

# --- UI references ---
var _mode_option: OptionButton = null
var _max_players_row: HBoxContainer = null
var _max_players_spin: SpinBox = null
var _action_list: ItemList = null
var _path_edit: LineEdit = null
var _status_label: Label = null

# Properties panel
var _prop_placeholder: Label = null
var _prop_grid: GridContainer = null
var _prop_id_label: Label = null
var _prop_name: LineEdit = null
var _prop_desc_name: LineEdit = null
var _prop_category: LineEdit = null
var _prop_type: OptionButton = null
var _prop_allow_rebind: CheckBox = null

# Axis-only rows (hidden for Button)
var _axis_rows: Array[Control] = []
var _prop_positive_name: LineEdit = null
var _prop_negative_name: LineEdit = null


func _ready() -> void:
	_build_layout()
	_load_or_new()


# --- Layout ---

func _build_layout() -> void:
	add_theme_constant_override("separation", 6)
	custom_minimum_size = Vector2(480, 0)

	# ── Player Configuration ──────────────────────────────────────
	_add_section_label("Player Configuration")

	var mode_row := HBoxContainer.new()
	add_child(mode_row)

	var mode_lbl := Label.new()
	mode_lbl.text = "Mode"
	mode_lbl.custom_minimum_size.x = 90
	mode_row.add_child(mode_lbl)

	_mode_option = OptionButton.new()
	_mode_option.add_item("Single Player", _GWConfig.PlayerMode.SINGLE)
	_mode_option.add_item("Local Co-op",   _GWConfig.PlayerMode.LOCAL_COOP)
	_mode_option.add_item("Online",        _GWConfig.PlayerMode.ONLINE)
	_mode_option.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_mode_option.item_selected.connect(_on_mode_changed)
	mode_row.add_child(_mode_option)

	_max_players_row = HBoxContainer.new()
	add_child(_max_players_row)

	var mp_lbl := Label.new()
	mp_lbl.text = "Max Players"
	mp_lbl.custom_minimum_size.x = 90
	_max_players_row.add_child(mp_lbl)

	_max_players_spin = SpinBox.new()
	_max_players_spin.min_value = 2
	_max_players_spin.max_value = 8
	_max_players_spin.value = 2
	_max_players_spin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_max_players_spin.value_changed.connect(func(v: float): _config.set("max_local_players", int(v)))
	_max_players_row.add_child(_max_players_spin)

	add_child(HSeparator.new())

	# ── Actions list + Properties ─────────────────────────────────
	var split := HSplitContainer.new()
	split.size_flags_vertical = Control.SIZE_EXPAND_FILL
	split.split_offset = 170
	add_child(split)

	# Left — action list
	var left := VBoxContainer.new()
	left.add_theme_constant_override("separation", 4)
	split.add_child(left)

	_add_column_label("Actions", left)

	_action_list = ItemList.new()
	_action_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_action_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_action_list.custom_minimum_size = Vector2(150, 180)
	_action_list.item_selected.connect(_on_action_selected)
	left.add_child(_action_list)

	var list_btns := HBoxContainer.new()
	left.add_child(list_btns)

	var add_btn := Button.new()
	add_btn.text = "+ Add"
	add_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_btn.pressed.connect(_on_add_action_pressed)
	list_btns.add_child(add_btn)

	var remove_btn := Button.new()
	remove_btn.text = "- Remove"
	remove_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	remove_btn.pressed.connect(_on_remove_action_pressed)
	list_btns.add_child(remove_btn)

	# Right — properties
	var right := VBoxContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.add_theme_constant_override("separation", 6)
	split.add_child(right)

	_add_column_label("Properties", right)

	_prop_placeholder = Label.new()
	_prop_placeholder.text = "Select an action to edit its properties."
	_prop_placeholder.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
	_prop_placeholder.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	right.add_child(_prop_placeholder)

	_prop_grid = GridContainer.new()
	_prop_grid.columns = 2
	_prop_grid.add_theme_constant_override("h_separation", 8)
	_prop_grid.add_theme_constant_override("v_separation", 6)
	_prop_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_prop_grid.visible = false
	right.add_child(_prop_grid)

	# ── Shared fields (Button and Axis) ───────────────────────────
	_prop_id_label = _add_prop_label_row("Action Id")

	_prop_name = _add_prop_line_edit_row("Name",
		func(v: String): _on_prop_name_changed(v))

	_prop_desc_name = _add_prop_line_edit_row("Descriptive Name",
		func(v: String): _selected_action.set("display_name", v))

	_prop_category = _add_prop_line_edit_row("Category",
		func(v: String): _selected_action.set("category", v))

	_prop_type = OptionButton.new()
	_prop_type.add_item("Button", 0)
	_prop_type.add_item("Axis", 1)
	_prop_type.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_prop_type.item_selected.connect(_on_type_changed)
	_add_prop_custom_row("Type", _prop_type)

	# ── Axis-only fields ──────────────────────────────────────────
	var pos_lbl := Label.new()
	pos_lbl.text = "Positive Name"
	pos_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_prop_grid.add_child(pos_lbl)

	_prop_positive_name = LineEdit.new()
	_prop_positive_name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_prop_positive_name.placeholder_text = "e.g. right, up"
	_prop_positive_name.text_changed.connect(func(v: String): _selected_action.set("positive_name", v))
	_prop_grid.add_child(_prop_positive_name)

	_axis_rows.append(pos_lbl)
	_axis_rows.append(_prop_positive_name)

	var neg_lbl := Label.new()
	neg_lbl.text = "Negative Name"
	neg_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_prop_grid.add_child(neg_lbl)

	_prop_negative_name = LineEdit.new()
	_prop_negative_name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_prop_negative_name.placeholder_text = "e.g. left, down"
	_prop_negative_name.text_changed.connect(func(v: String): _selected_action.set("negative_name", v))
	_prop_grid.add_child(_prop_negative_name)

	_axis_rows.append(neg_lbl)
	_axis_rows.append(_prop_negative_name)

	# ── Allow Rebind (always last) ────────────────────────────────
	_prop_allow_rebind = CheckBox.new()
	_prop_allow_rebind.text = ""
	_prop_allow_rebind.toggled.connect(func(v: bool): _selected_action.set("allow_rebind", v))
	_add_prop_custom_row("Allow Rebind", _prop_allow_rebind)

	add_child(HSeparator.new())

	# ── Config File ───────────────────────────────────────────────
	_add_section_label("Config File")

	var path_row := HBoxContainer.new()
	add_child(path_row)

	_path_edit = LineEdit.new()
	_path_edit.text = DEFAULT_CONFIG_PATH
	_path_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_path_edit.placeholder_text = "res://gw_config.tres"
	path_row.add_child(_path_edit)

	var load_btn := Button.new()
	load_btn.text = "Load"
	load_btn.pressed.connect(_load_or_new)
	path_row.add_child(load_btn)

	var save_btn := Button.new()
	save_btn.text = "Save Config"
	save_btn.pressed.connect(_on_save_pressed)
	add_child(save_btn)

	_status_label = Label.new()
	_status_label.text = ""
	_status_label.add_theme_font_size_override("font_size", 11)
	_status_label.add_theme_color_override("font_color", Color(0.6, 0.85, 0.6))
	add_child(_status_label)


# --- Layout helpers ---

func _add_section_label(text: String) -> void:
	var lbl := Label.new()
	lbl.text = text
	lbl.add_theme_color_override("font_color", Color(0.55, 0.75, 1.0))
	lbl.add_theme_font_size_override("font_size", 11)
	add_child(lbl)


func _add_column_label(text: String, parent: Control) -> void:
	var lbl := Label.new()
	lbl.text = text
	lbl.add_theme_color_override("font_color", Color(0.55, 0.75, 1.0))
	lbl.add_theme_font_size_override("font_size", 11)
	parent.add_child(lbl)


func _add_prop_label_row(label_text: String) -> Label:
	var lbl := Label.new()
	lbl.text = label_text
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_prop_grid.add_child(lbl)
	var value_lbl := Label.new()
	value_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_prop_grid.add_child(value_lbl)
	return value_lbl


func _add_prop_line_edit_row(label_text: String, callback: Callable) -> LineEdit:
	var lbl := Label.new()
	lbl.text = label_text
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_prop_grid.add_child(lbl)
	var edit := LineEdit.new()
	edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	edit.text_changed.connect(callback)
	_prop_grid.add_child(edit)
	return edit


func _add_prop_custom_row(label_text: String, control: Control) -> void:
	var lbl := Label.new()
	lbl.text = label_text
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_prop_grid.add_child(lbl)
	_prop_grid.add_child(control)


# --- Config loading / saving ---

func _load_or_new() -> void:
	_selected_index = -1
	_selected_action = null
	var path := _path_edit.text if _path_edit != null else DEFAULT_CONFIG_PATH
	if ResourceLoader.exists(path):
		_config = ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_IGNORE)
		if _status_label != null:
			_status_label.text = "Loaded %s" % path
	else:
		_config = _GWConfig.new()
		if _status_label != null:
			_status_label.text = "New config (not saved yet)"
	_populate_from_config()


func _populate_from_config() -> void:
	_mode_option.selected = _config.get("player_mode") as int
	_max_players_spin.value = _config.get("max_local_players")
	_update_max_players_visibility()
	_rebuild_action_list()
	_show_properties(false)


func _on_save_pressed() -> void:
	var path := _path_edit.text
	if path.is_empty():
		path = DEFAULT_CONFIG_PATH
	var err := ResourceSaver.save(_config, path)
	_status_label.text = "Saved to %s" % path if err == OK else "Error saving: %d" % err


# --- Player mode ---

func _on_mode_changed(index: int) -> void:
	_config.set("player_mode", _mode_option.get_item_id(index))
	_update_max_players_visibility()


func _update_max_players_visibility() -> void:
	_max_players_row.visible = _config.get("player_mode") == _GWConfig.PlayerMode.LOCAL_COOP


# --- Action list ---

func _rebuild_action_list() -> void:
	_action_list.clear()
	var actions: Array = _config.get("actions")
	for i in actions.size():
		_action_list.add_item("%d : %s" % [i, actions[i].get("action_name")])
	if _selected_index >= 0 and _selected_index < actions.size():
		_action_list.select(_selected_index)


func _on_action_selected(index: int) -> void:
	_selected_index = index
	var actions: Array = _config.get("actions")
	if index < actions.size():
		_selected_action = actions[index]
		_populate_properties()
		_show_properties(true)


func _on_add_action_pressed() -> void:
	var action: RefCounted = _GWActionConfig.new()
	var actions: Array = _config.get("actions")
	action.set("action_name", "action_%d" % actions.size())
	action.set("display_name", "")
	action.set("category", "General")
	action.set("action_type", 0)
	action.set("positive_name", "")
	action.set("negative_name", "")
	action.set("max_bindings", 2)
	action.set("allow_rebind", true)
	actions.append(action)
	_rebuild_action_list()
	var new_idx := actions.size() - 1
	_action_list.select(new_idx)
	_on_action_selected(new_idx)


func _on_remove_action_pressed() -> void:
	if _selected_index < 0:
		return
	var actions: Array = _config.get("actions")
	if _selected_index >= actions.size():
		return
	actions.remove_at(_selected_index)
	_selected_index = -1
	_selected_action = null
	_rebuild_action_list()
	_show_properties(false)


# --- Properties panel ---

func _show_properties(visible: bool) -> void:
	_prop_placeholder.visible = not visible
	_prop_grid.visible = visible


func _populate_properties() -> void:
	if _selected_action == null:
		return
	_prop_id_label.text = str(_selected_index)
	_prop_name.text = _selected_action.get("action_name")
	_prop_desc_name.text = _selected_action.get("display_name")
	_prop_category.text = _selected_action.get("category")
	var action_type: int = _selected_action.get("action_type")
	_prop_type.selected = action_type
	_prop_positive_name.text = _selected_action.get("positive_name")
	_prop_negative_name.text = _selected_action.get("negative_name")
	_prop_allow_rebind.button_pressed = _selected_action.get("allow_rebind")
	_update_axis_rows_visibility(action_type)


func _on_prop_name_changed(value: String) -> void:
	if _selected_action == null:
		return
	_selected_action.set("action_name", value)
	if _selected_index >= 0 and _selected_index < _action_list.item_count:
		_action_list.set_item_text(_selected_index, "%d : %s" % [_selected_index, value])


func _on_type_changed(index: int) -> void:
	if _selected_action == null:
		return
	_selected_action.set("action_type", index)
	_update_axis_rows_visibility(index)


func _update_axis_rows_visibility(action_type: int) -> void:
	var is_axis := action_type == 1  # ActionType.AXIS
	for row in _axis_rows:
		row.visible = is_axis
