extends GameManagerStateBase
class_name ViewingState

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
		game_manager.current_pokemon_id = mini(game_manager.current_pokemon_id + 1, 1025)
		state_machine.change_to(GameManagerStates.Loading)
	elif wired.is_action_just_pressed("prev_pokemon", event, 0):
		game_manager.current_pokemon_id = maxi(game_manager.current_pokemon_id - 1, 1)
		state_machine.change_to(GameManagerStates.Loading)
	elif wired.is_action_just_pressed("random_pokemon", event, 0):
		game_manager.current_pokemon_id = randi_range(1, 1025)
		ToastService.i.info("Pokémon aleatorio")
		state_machine.change_to(GameManagerStates.Loading)
	elif wired.is_action_just_pressed("open_pokedex", event, 0):
		state_machine.change_to(GameManagerStates.Dialogue)
