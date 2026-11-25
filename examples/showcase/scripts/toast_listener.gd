extends Node

## Turns showcase events into toasts, so the states never call ToastService directly.


func _enter_tree() -> void:
	# ShowcaseEvents is added to the root with call_deferred (SingletonNode.ensure_for),
	# so subscribe one deferred step later, once it exists.
	_subscribe.call_deferred()


func _subscribe() -> void:
	ShowcaseEvents.i.listen(self, {
		ShowcaseEvents.i.pokemon_loaded: _on_pokemon_loaded,
		ShowcaseEvents.i.pokemon_load_failed: _on_pokemon_load_failed,
	})


func _on_pokemon_loaded(pokemon_name: String) -> void:
	ToastService.i.success("%s cargado" % pokemon_name)


func _on_pokemon_load_failed(reason: String) -> void:
	ToastService.i.danger(reason)
