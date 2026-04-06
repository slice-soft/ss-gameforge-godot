extends GameManagerStateBase
class_name DialogueState

const BASE_RESOURCE := preload("res://examples/showcase/game_manager_dialogue_resource.tres")

func start() -> void:
	var gm := game_manager
	if gm.current_pokemon_flavor_texts.is_empty():
		state_machine.change_to(GameManagerStates.Viewing)
		return

	var resource := BASE_RESOURCE.duplicate() as DialogueResource
	resource.dialogues = gm.current_pokemon_flavor_texts

	gm.dialogue_view.dialogue_finished.connect(_on_dialogue_finished, CONNECT_ONE_SHOT)
	gm.dialogue_view.play(resource)

func end() -> void:
	game_manager.dialogue_view.stop()

func _on_dialogue_finished() -> void:
	state_machine.change_to(GameManagerStates.Viewing)
