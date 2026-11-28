class_name GWRebindMenu extends PanelContainer
## Ready-made control remapping screen for one player.
##
## Lists the player's actions by category, one row per action (two for an axis:
## its positive and negative side) and one button per binding slot. Pressing a
## slot captures the player's next input as the new binding; right-click clears
## it. Conflicts are reported or swapped, "Reset to defaults" restores the
## templates, and every change can be saved straight away.
##
## Style it with a regular Godot Theme. Besides the stock types it uses the
## type variations GWRebindCategory (Label), GWRebindAction (Label),
## GWRebindSlot (Button) and GWRebindStatus (Label).

## The player clicked "Back" or pressed ui_cancel while not listening.
signal closed
## A slot got a new binding, or was cleared.
signal binding_changed(action_name: String, slot: int, negative: bool)
## The new binding is also used by other actions of the same player.
signal conflict_detected(action_name: String, conflicting_actions: Array[String])

## What to do when the captured input is already bound to other actions.
enum ConflictPolicy {
	WARN, ## Keep both and show a warning.
	SWAP, ## Give the other actions the binding this slot had before.
}

## Player whose bindings are shown.
@export var player_id: int = 0:
	set(value):
		player_id = value
		if is_node_ready():
			refresh()
## Binding slots shown per row. An action with a lower max_bindings shows fewer.
@export_range(1, 4) var slots: int = 2:
	set(value):
		slots = value
		if is_node_ready():
			refresh()
## Only these categories, in this order. Empty = every category.
@export var categories: Array[String] = []
## Show actions with allow_rebind = false, disabled.
@export var show_locked_actions: bool = false
@export var conflict_policy: ConflictPolicy = ConflictPolicy.WARN
## Seconds to wait for an input before giving up. 0 = wait forever (Escape
## always cancels).
@export_range(0.0, 30.0, 0.5) var listen_timeout: float = 5.0
## Save every change with save_all_profiles().
@export var auto_save: bool = true
## File used by auto_save. Empty = the manager's default (user://gw_bindings.json).
@export var save_path: String = ""
## Focus the first slot whenever the menu is shown, for gamepad navigation.
@export var focus_on_show: bool = true

@export_group("Texts")
@export var title_text: String = "Controls"
@export var listening_text: String = "Press a key or button… (Esc to cancel)"
@export var empty_slot_text: String = "—"
## %s = the other actions' names.
@export var conflict_text: String = "Also used by: %s"
## %s = the other actions' names.
@export var swapped_text: String = "Swapped with: %s"
@export var reset_text: String = "Reset to defaults"
@export var back_text: String = "Back"

@onready var _title: Label = %Title
@onready var _list: VBoxContainer = %List
@onready var _status: Label = %Status
@onready var _reset: Button = %Reset
@onready var _back: Button = %Back

# slot Button -> {"action", "slot", "negative"}
var _slot_info: Dictionary = {}
var _listening_button: Button
var _previous: GWBinding
var _captured: GWBinding
var _timer: Timer


func _ready() -> void:
	_timer = Timer.new()
	_timer.one_shot = true
	_timer.timeout.connect(_on_listen_timeout)
	add_child(_timer)
	_reset.pressed.connect(reset_to_defaults)
	_back.pressed.connect(func(): closed.emit())
	visibility_changed.connect(_on_visibility_changed)
	_connect_manager.call_deferred()
	refresh()


## Rebuilds the list from the player's current bindings.
func refresh() -> void:
	_title.text = tr(title_text)
	_reset.text = tr(reset_text)
	_back.text = tr(back_text)
	for child in _list.get_children():
		_list.remove_child(child)
		child.queue_free()
	_slot_info.clear()
	_listening_button = null
	var player := _player()
	if player == null:
		_set_status("")
		return
	var groups := _grouped_actions(player)
	for category in groups:
		var header := Label.new()
		header.text = tr(category)
		header.theme_type_variation = &"GWRebindCategory"
		_list.add_child(header)
		var grid := GridContainer.new()
		grid.columns = 1 + slots
		_list.add_child(grid)
		for action: GWAction in groups[category]:
			if action.action_type == GWAction.ActionType.AXIS:
				_add_row(grid, action, false)
				_add_row(grid, action, true)
			else:
				_add_row(grid, action, false)
	if focus_on_show and is_visible_in_tree():
		focus_first_slot()


## Restores the player's default bindings (and saves, with auto_save).
func reset_to_defaults() -> void:
	var manager := GWInputManager.i
	if manager == null:
		return
	if manager.is_listening_for_rebind():
		manager.cancel_rebind_listen()
	manager.reset_player_to_defaults(player_id)
	_save()
	refresh()
	_set_status("")


## Moves focus to the first slot button.
func focus_first_slot() -> void:
	for button in _slot_info:
		if not (button as Button).disabled:
			(button as Button).grab_focus()
			return


## True while the menu waits for the player's input.
func is_listening() -> bool:
	return _listening_button != null


func _unhandled_input(event: InputEvent) -> void:
	if not is_visible_in_tree() or is_listening():
		return
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		closed.emit()


func _add_row(grid: GridContainer, action: GWAction, negative: bool) -> void:
	var label := Label.new()
	label.text = _row_name(action, negative)
	label.theme_type_variation = &"GWRebindAction"
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if action.description != "":
		label.tooltip_text = tr(action.description)
		label.mouse_filter = Control.MOUSE_FILTER_PASS
	grid.add_child(label)
	var list := action.negative_bindings if negative else action.bindings
	var usable := slots if action.max_bindings <= 0 else mini(slots, action.max_bindings)
	for i in slots:
		var button := Button.new()
		button.theme_type_variation = &"GWRebindSlot"
		button.custom_minimum_size.x = 120
		button.clip_text = true
		if i >= usable:
			button.visible = false
			button.disabled = true
		else:
			# A slot past the filled ones appends, so only the first empty one is usable.
			button.disabled = not action.allow_rebind or i > list.size()
		button.text = _binding_text(list, i)
		button.pressed.connect(_on_slot_pressed.bind(button))
		button.gui_input.connect(_on_slot_gui_input.bind(button))
		grid.add_child(button)
		_slot_info[button] = {"action": action.action_name, "slot": i, "negative": negative}


func _row_name(action: GWAction, negative: bool) -> String:
	var base := tr(action.display_name if action.display_name != "" else action.action_name)
	if action.action_type != GWAction.ActionType.AXIS:
		return base
	var side := action.negative_name if negative else action.positive_name
	if side == "":
		side = "−" if negative else "+"
	return "%s (%s)" % [base, tr(side)]


func _binding_text(list: Array[GWBinding], i: int) -> String:
	if i < list.size() and list[i] != null:
		return list[i].get_display_name()
	return tr(empty_slot_text)


func _grouped_actions(player: GWPlayer) -> Dictionary:
	var groups: Dictionary = {}
	for category in categories:
		groups[category] = []
	for action_name in player.actions:
		var action: GWAction = player.actions[action_name]
		if not action.allow_rebind and not show_locked_actions:
			continue
		if not categories.is_empty() and not categories.has(action.category):
			continue
		if not groups.has(action.category):
			groups[action.category] = []
		groups[action.category].append(action)
	for category in groups.keys():
		if (groups[category] as Array).is_empty():
			groups.erase(category)
	return groups


func _on_slot_pressed(button: Button) -> void:
	var manager := GWInputManager.i
	if manager == null or is_listening() or manager.is_listening_for_rebind():
		return
	var info: Dictionary = _slot_info[button]
	var action := _action(info["action"])
	if action == null:
		return
	var list := action.negative_bindings if info["negative"] else action.bindings
	_previous = list[info["slot"]].duplicate() if info["slot"] < list.size() else null
	if not manager.start_rebind_listen(player_id, info["action"], info["slot"], info["negative"]):
		return
	_listening_button = button
	button.text = "…"
	_set_status(tr(listening_text))
	if listen_timeout > 0.0:
		_timer.start(listen_timeout)


# Right-click clears a slot.
func _on_slot_gui_input(event: InputEvent, button: Button) -> void:
	var mb := event as InputEventMouseButton
	if mb == null or not mb.pressed or mb.button_index != MOUSE_BUTTON_RIGHT or is_listening():
		return
	var info: Dictionary = _slot_info[button]
	var player := _player()
	var action := _action(info["action"])
	if player == null or action == null or not action.allow_rebind:
		return
	var list := action.negative_bindings if info["negative"] else action.bindings
	if info["slot"] >= list.size():
		return
	player.remove_binding(info["action"], info["slot"], info["negative"])
	button.accept_event()
	_save()
	binding_changed.emit(info["action"], info["slot"], info["negative"])
	refresh()


func _connect_manager() -> void:
	var manager := GWInputManager.i
	if manager == null:
		push_warning("GWRebindMenu: no GWInputManager; create it before showing the menu.")
		return
	if not manager.binding_remapped.is_connected(_on_binding_remapped):
		manager.binding_remapped.connect(_on_binding_remapped)
		manager.rebind_cancelled.connect(_on_rebind_cancelled)
		manager.rebind_conflict.connect(_on_rebind_conflict)
		manager.player_created.connect(func(pid): if pid == player_id: refresh())
	refresh()


func _on_binding_remapped(pid: int, action_name: String) -> void:
	if pid != player_id or not is_listening():
		return
	var info: Dictionary = _slot_info[_listening_button]
	if info["action"] != action_name:
		return
	var action := _action(action_name)
	var list := action.negative_bindings if info["negative"] else action.bindings
	_captured = list[info["slot"]] if info["slot"] < list.size() else null
	_end_listen()
	_save()
	binding_changed.emit(action_name, info["slot"], info["negative"])
	refresh()
	_focus_slot(info)


func _on_rebind_conflict(pid: int, action_name: String, others: Array[String]) -> void:
	if pid != player_id:
		return
	conflict_detected.emit(action_name, others)
	var names := ", ".join(others.map(func(n): return _display(n)))
	if conflict_policy == ConflictPolicy.SWAP:
		_swap(action_name, others)
		_save()
		refresh()
		_set_status(tr(swapped_text) % names)
	else:
		_set_status(tr(conflict_text) % names)


func _on_rebind_cancelled(pid: int) -> void:
	if pid != player_id or not is_listening():
		return
	var info: Dictionary = _slot_info[_listening_button]
	_end_listen()
	refresh()
	_set_status("")
	_focus_slot(info)


func _on_listen_timeout() -> void:
	if is_listening() and GWInputManager.i != null:
		GWInputManager.i.cancel_rebind_listen()


func _end_listen() -> void:
	_timer.stop()
	_listening_button = null
	_set_status("")


# Hands the slot's previous binding to every other action that had the new input.
func _swap(action_name: String, others: Array[String]) -> void:
	var player := _player()
	if player == null or _captured == null:
		return
	for other_name in others:
		var other := _action(other_name)
		if other == null:
			continue
		for negative in [false, true]:
			var list := other.negative_bindings if negative else other.bindings
			for i in range(list.size() - 1, -1, -1):
				if not _captured.same_input(list[i]):
					continue
				if _previous != null and not _previous.same_input(list[i]):
					player.set_binding(other_name, i, _previous.duplicate(), negative)
				else:
					player.remove_binding(other_name, i, negative)


func _focus_slot(info: Dictionary) -> void:
	if not is_visible_in_tree():
		return
	for button in _slot_info:
		var other: Dictionary = _slot_info[button]
		if other["action"] == info["action"] and other["slot"] == info["slot"] and other["negative"] == info["negative"]:
			(button as Button).grab_focus()
			return


func _on_visibility_changed() -> void:
	if not is_visible_in_tree() and is_listening() and GWInputManager.i != null:
		GWInputManager.i.cancel_rebind_listen()
	elif is_visible_in_tree() and is_node_ready():
		refresh()


func _save() -> void:
	if not auto_save or GWInputManager.i == null:
		return
	if save_path == "":
		GWInputManager.i.save_all_profiles()
	else:
		GWInputManager.i.save_all_profiles(save_path)


func _set_status(text: String) -> void:
	_status.text = text
	_status.visible = text != ""


func _display(action_name: String) -> String:
	var action := _action(action_name)
	if action == null or action.display_name == "":
		return action_name
	return tr(action.display_name)


func _player() -> GWPlayer:
	var manager := GWInputManager.i
	return manager.get_player(player_id) if manager != null else null


func _action(action_name: String) -> GWAction:
	var player := _player()
	if player == null or not player.actions.has(action_name):
		return null
	return player.actions[action_name]
