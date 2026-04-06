extends GameManagerStateBase
class_name LoadingState

signal _loading_done

var _http_nodes: Array[HTTPRequest] = []
var _sprite_done: bool = false
var _species_done: bool = false

func start() -> void:
	_sprite_done = false
	_species_done = false
	ToastService.i.loader_task("Cargando Pokémon #%d..." % game_manager.current_pokemon_id, _loading_done)
	_fetch_pokemon()

func end() -> void:
	for http in _http_nodes:
		if is_instance_valid(http):
			http.queue_free()
	_http_nodes.clear()

func _fetch_pokemon() -> void:
	var http := _create_http()
	http.request_completed.connect(_on_pokemon_completed)
	http.request("https://pokeapi.co/api/v2/pokemon/%d" % game_manager.current_pokemon_id)

func _on_pokemon_completed(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	if result != HTTPRequest.RESULT_SUCCESS or response_code != 200:
		ToastService.i.danger("Error al cargar el Pokémon")
		return

	var json := JSON.new()
	json.parse(body.get_string_from_utf8())
	var data: Dictionary = json.get_data()

	game_manager.current_pokemon_name = (data["name"] as String).capitalize()
	var sprite_url: String = data["sprites"]["front_default"]

	_fetch_sprite(sprite_url)
	_fetch_species()

func _fetch_sprite(url: String) -> void:
	var http := _create_http()
	http.request_completed.connect(_on_sprite_completed)
	http.request(url)

func _on_sprite_completed(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	if result != HTTPRequest.RESULT_SUCCESS or response_code != 200:
		game_manager.current_pokemon_texture = null
	else:
		var image := Image.new()
		image.load_png_from_buffer(body)
		game_manager.current_pokemon_texture = ImageTexture.create_from_image(image)

	_sprite_done = true
	_try_finish()

func _fetch_species() -> void:
	var http := _create_http()
	http.request_completed.connect(_on_species_completed)
	http.request("https://pokeapi.co/api/v2/pokemon-species/%d" % game_manager.current_pokemon_id)

func _on_species_completed(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	if result != HTTPRequest.RESULT_SUCCESS or response_code != 200:
		ToastService.i.danger("Error al cargar especie")
		return

	var json := JSON.new()
	json.parse(body.get_string_from_utf8())
	var data: Dictionary = json.get_data()

	var texts: Array[String] = []
	for entry in data["flavor_text_entries"]:
		if entry["language"]["name"] == "es":
			var text: String = (
				(entry["flavor_text"] as String)
				.replace("\n", " ")
				.replace("\f", " ")
			)
			var words := text.split(" ")
			var lines: Array[String] = []
			var line := ""
			for word in words:
				if line.length() + word.length() + 1 > 80:
					if line != "":
						lines.append(line)
					line = word
				else:
					if line != "":
						line += " "
					line += word
			if line != "":
				lines.append(line)
			var wrapped_text := "\n".join(lines)
			if not texts.has(wrapped_text):
				texts.append(wrapped_text)
	game_manager.current_pokemon_flavor_texts = texts
	_species_done = true
	_try_finish()

func _try_finish() -> void:
	if not (_sprite_done and _species_done):
		return
	_loading_done.emit()
	ToastService.i.success("%s cargado" % game_manager.current_pokemon_name)
	state_machine.change_to(GameManagerStates.Viewing)

func _create_http() -> HTTPRequest:
	var http := HTTPRequest.new()
	game_manager.add_child(http)
	_http_nodes.append(http)
	return http
