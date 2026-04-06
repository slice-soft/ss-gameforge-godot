extends GameManagerStateBase
class_name BootState

func start() -> void:
	SingletonNode.ensure_for(ToastService, get_tree().root, "ToastService")
	SingletonNode.ensure_for(GWInputManager, get_tree().root, "GWInputManager")
	_setup_input()
	var timer := get_tree().create_timer(0.8)
	ToastService.i.loader_task("Iniciando...", timer.timeout)
	await timer.timeout
	state_machine.change_to(game_manager.states.Loading)

func _setup_input() -> void:
	var wired := GWInputManager.i

	wired.define_action("next_pokemon", "Next Pokémon", [
		GWBinding.from_key(KEY_RIGHT),
		GWBinding.from_key(KEY_D),
	], "Navigation", 2)

	wired.define_action("prev_pokemon", "Previous Pokémon", [
		GWBinding.from_key(KEY_LEFT),
		GWBinding.from_key(KEY_A),
	], "Navigation", 2)

	wired.define_action("random_pokemon", "Random Pokémon", [
		GWBinding.from_key(KEY_R),
	], "Navigation", 1)

	wired.define_action("open_pokedex", "Open Pokédex", [
		GWBinding.from_key(KEY_ENTER),
		GWBinding.from_key(KEY_SPACE),
	], "Navigation", 2)

	var player := wired.create_player(0, "Player 1")
	player.accepts_keyboard = true
