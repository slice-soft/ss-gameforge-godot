extends GameManagerStateBase
class_name ViewingState

const MIN_ID := 1
const MAX_ID := 1025

func start() -> void:
	var gm := game_manager
	gm.name_label.text = gm.current_pokemon_name
	gm.number_label.text = "#%03d" % gm.current_pokemon_id
	if gm.current_pokemon_texture:
		gm.sprite_texture.texture = gm.current_pokemon_texture
	else:
		gm.sprite_texture.texture = null

func on_unhandled_key_input(event: InputEvent) -> void:
	var wired := GWInputManager.i

	if wired.is_action_just_pressed("next_pokemon", event, 0):
		_go_to(game_manager.current_pokemon_id + 1)
	elif wired.is_action_just_pressed("prev_pokemon", event, 0):
		_go_to(game_manager.current_pokemon_id - 1)
	elif wired.is_action_just_pressed("random_pokemon", event, 0):
		game_manager.current_pokemon_id = randi_range(MIN_ID, MAX_ID)
		ToastService.i.info("Pokémon aleatorio")
		state_machine.change_to(GameManagerStates.Loading)
	elif wired.is_action_just_pressed("open_pokedex", event, 0):
		state_machine.change_to(GameManagerStates.Dialogue)

# Clamps to the valid Pokédex range and skips the reload when already at an edge,
# so pressing past #1 or #1025 does not refetch and re-toast the same Pokémon.
func _go_to(id: int) -> void:
	var clamped := clampi(id, MIN_ID, MAX_ID)
	if clamped == game_manager.current_pokemon_id:
		return
	game_manager.current_pokemon_id = clamped
	state_machine.change_to(GameManagerStates.Loading)
