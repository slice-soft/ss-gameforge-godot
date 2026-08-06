# Wired

`GWInputManager` es un sistema de entrada construido alrededor de **acciones** y
**jugadores**. El código de gameplay pide `"jump"`, nunca `KEY_SPACE`. Cada
jugador tiene una copia privada de todas las acciones, así que dos personas en la
misma máquina pueden remapear la misma acción de forma distinta.

> Requiere `ss-gameforge-singleton`: `GWInputManager` extiende `SingletonNode`.

## Cuándo usarlo

- Cuando los jugadores deben poder remapear controles en tiempo de ejecución.
- Cuando necesitas cooperativo local donde cada jugador tiene su dispositivo y sus bindings.
- Cuando quieres gamepads conectables en caliente, incluido "presiona cualquier botón para unirte".
- Cuando el mapa de entrada del proyecto en Godot no alcanza porque es global.

## El modelo

| Concepto | Qué es |
|---|---|
| `GWBinding` | Una entrada física: una tecla, un botón de mouse, un botón de pad, un lado de eje. |
| `GWAction` | Un grupo con nombre de 1..N bindings. Es a lo que se refiere el gameplay. |
| `GWPlayer` | Un jugador con su copia de todas las acciones y su lista de dispositivos. |
| `GWDevice` | Un dispositivo conectado. `-1` es siempre teclado/mouse. |

Las acciones se registran primero como **plantillas** en el manager, y luego se
clonan en cada jugador al crearlo. Remapear la acción de un jugador nunca toca la
plantilla ni a los demás jugadores.

## API clave

- `GWInputManager.i` devuelve la instancia activa; `GWInputManager.ensure(root)` la crea.
- `define_action(name, display_name, bindings, category, max_bindings)` registra una plantilla.
- `create_player(player_id, player_name)` clona las plantillas en un jugador nuevo.
- `is_action_pressed(name, player_id)`, `is_action_just_pressed(name, event, player_id)`,
  `is_action_just_released(name, event, player_id)`, `get_action_strength(name, player_id)`.
- `get_action_axis(name, player_id)` y `get_vector(neg_x, pos_x, neg_y, pos_y, player_id)`.
- `start_rebind_listen(player_id, action_name, binding_index)` captura la siguiente entrada.
- `save_all_profiles(path)` / `load_all_profiles(path)` persisten los bindings como JSON.
- `GWBinding.from_key()`, `.from_joy_button()`, `.from_joy_axis()`, `.from_mouse_button()`.

## Uso: crear el manager

```gdscript
func _enter_tree() -> void:
	SingletonNode.ensure_for(GWInputManager, get_tree().root, "GWInputManager")
```

`GWInputManager.ensure(get_tree().root)` hace lo mismo en una sola llamada.

## Uso: definir acciones y un jugador

Las plantillas deben existir **antes** de `create_player()`, porque es ahí donde
se clonan. Esta es la configuración del showcase:

```gdscript
func _setup_input() -> void:
	var wired := GWInputManager.i

	wired.define_action("next_pokemon", "Next Pokémon", [
		GWBinding.from_key(KEY_RIGHT),
		GWBinding.from_key(KEY_D),
	], "Navigation", 2)

	wired.define_action("open_pokedex", "Open Pokédex", [
		GWBinding.from_key(KEY_ENTER),
		GWBinding.from_key(KEY_SPACE),
	], "Navigation", 2)

	var player := wired.create_player(0, "Player 1")
	player.accepts_keyboard = true
```

`display_name` y `category` son lo que muestra y agrupa una pantalla de
remapeo; `max_bindings` limita cuántas alternativas acepta la acción
(`0` = sin límite).

> Un jugador creado antes de definir una acción no la tendrá. Define todas las
> acciones primero, o vuelve a llamar `create_player()` después de agregar más.

## Uso: leer la entrada

El jugador `0` es el predeterminado, así que el código de un solo jugador queda corto:

```gdscript
func _process(_delta: float) -> void:
	if GWInputManager.i.is_action_just_pressed("open_pokedex"):
		abrir_pokedex()

	if GWInputManager.i.is_action_pressed("run"):
		speed = run_speed
```

Llamados sin evento, `is_action_just_pressed()` e `is_action_just_released()`
usan seguimiento por frame, así que son seguros dentro de `_process()`. Pasa el
evento cuando estés en `_input()` y quieras reaccionar a ese evento exacto:

```gdscript
func _input(event: InputEvent) -> void:
	if GWInputManager.i.is_action_just_pressed("jump", event):
		saltar()
```

Para movimiento, `get_vector()` arma el vector con cuatro acciones:

```gdscript
var direction := GWInputManager.i.get_vector(
	"move_left", "move_right", "move_up", "move_down"
)
```

## Uso: cooperativo local

Dale a cada jugador su propio dispositivo. El teclado se habilita por jugador;
los gamepads se asignan en exclusiva:

```gdscript
var p1 := wired.create_player(0, "Player 1")
p1.accepts_keyboard = true

var p2 := wired.create_player(1, "Player 2")
p2.assign_gamepad(0)
```

Luego pasa el id del jugador al leer:

```gdscript
if GWInputManager.i.is_action_pressed("attack", 1):
	players[1].attack()
```

### Presiona para unirte

`unassigned_device_pressed` se emite cuando un dispositivo que nadie tiene
asignado produce una pulsación — que es justo la señal que necesita una pantalla
de ingreso:

```gdscript
func _ready() -> void:
	GWInputManager.i.unassigned_device_pressed.connect(_on_device_pressed)

func _on_device_pressed(device_id: int) -> void:
	var slot := siguiente_slot_libre()
	var player := GWInputManager.i.create_player(slot, "Player %d" % (slot + 1))
	player.assign_gamepad(device_id)
```

`get_unassigned_gamepads()` lista los pads todavía libres, y
`device_connected` / `device_disconnected` cubren la conexión en caliente.

## Uso: remapear en tiempo de ejecución

El remapeo es un modo de escucha: el manager captura la siguiente entrada válida
y la escribe en el slot que nombraste.

```gdscript
func _on_boton_remapear(action_name: String) -> void:
	GWInputManager.i.rebind_listening.connect(_on_listening, CONNECT_ONE_SHOT)
	GWInputManager.i.binding_remapped.connect(_on_remapped, CONNECT_ONE_SHOT)
	GWInputManager.i.start_rebind_listen(0, action_name, 0)

func _on_listening(player_id: int, action_name: String, binding_index: int) -> void:
	label.text = "Presiona una entrada para %s..." % action_name

func _on_remapped(player_id: int, action_name: String) -> void:
	refrescar_lista_remapeo()
```

`binding_index` es qué slot sobrescribir — `0` es el binding principal, `1` la
primera alternativa, y así.

Mientras escucha, `is_listening_for_rebind()` devuelve true. Úsalo para pausar el
gameplay; si no, la tecla que se está capturando también dispara aquello a lo que
está asignada hoy. `cancel_rebind_listen()` aborta y emite `rebind_cancelled`.

> Las acciones con `allow_rebind` en false están pensadas para quedarse fijas;
> déjalas fuera de la pantalla de remapeo.

## Uso: guardar los bindings

```gdscript
GWInputManager.i.save_all_profiles()                  # user://gw_bindings.json
GWInputManager.i.load_all_profiles()
GWInputManager.i.reset_all_to_defaults()
```

`load_all_profiles()` no hace nada si el archivo no existe, y solo aplica
bindings a jugadores que **ya existen** — así que crea los jugadores primero y
carga después.

Para varios perfiles con nombre, `GWProfileManager` envuelve lo mismo en slots:

```gdscript
GWProfileManager.save(GWInputManager.i, "zurdo")
GWProfileManager.load_profile(GWInputManager.i, "zurdo")
GWProfileManager.list_profiles()      # ["zurdo", "default"]
GWProfileManager.delete_profile("zurdo")
```

Cada perfil es su propio archivo, `user://gw_profile_<nombre>.json`.

## Uso: el panel del editor

Al habilitar el plugin aparece una pestaña principal **GodotWired** junto a 2D,
3D y Script. Úsala para construir un recurso `GWConfig` — la lista de acciones
del proyecto, su modo de jugadores (`SINGLE`, `LOCAL_COOP`, `ONLINE`) y los
bindings por defecto — y cárgalo al arrancar en vez de llamar `define_action()` a
mano:

```gdscript
const CONFIG := preload("res://input/game_input.tres")

func _enter_tree() -> void:
	SingletonNode.ensure_for(GWInputManager, get_tree().root, "GWInputManager")
	GWInputManager.i.load_config(CONFIG)
```

> `load_config()` limpia todas las plantillas **y jugadores** existentes antes de
> aplicar la configuración. Llámalo durante el arranque, no a mitad de partida.

## Acciones de eje

Una acción puede ser un eje en vez de un botón. Entonces guarda bindings para la
dirección positiva y una segunda lista para la negativa, y se lee como un único
valor en `[-1.0, 1.0]`:

```gdscript
var throttle := GWInputManager.i.get_action_axis("throttle")
```

`positive_name` y `negative_name` en la acción son las etiquetas que muestra una
pantalla de remapeo para cada lado ("acelerar" / "frenar").
