# Dialogue

`DialogueView` es un `Control` que escribe una secuencia de líneas carácter por
carácter y anima una caja de entrada y salida alrededor. La caja puede ser una
caja de diálogo en pantalla o un globo sobre un personaje, en 2D o en 3D
(`DialogueView3D`). Las líneas viven en un
`DialogueResource`, así que escribir contenido nunca implica tocar la vista.

## Cuándo usarlo

- Cuando necesitas una caja de diálogo con efecto máquina de escribir y animación de apertura y cierre.
- Cuando quieres que el contenido sea data, editable como recurso.
- Cuando tus líneas usan BBCode y deben revelarse correctamente, etiqueta por etiqueta.
- Cuando quieres una caja fija abajo en la pantalla, globos en el mundo, o ambos.

## API clave

- `play(resource)` inicia una secuencia. Es el punto de entrada principal.
- `stop()` cancela el diálogo actual y reproduce la animación de cierre.
- `apply_theme()` reaplica `dialogue_theme`; `play()` ya lo llama.
- `is_playing()` es true desde `play()` hasta `dialogue_finished`.
- `skip()` completa la línea actual o avanza, como una pulsación de `skip_action`.
- `back()` vuelve a mostrar la línea anterior; `@export back_action` lo hace desde la entrada.
- `@export history: DialogueHistory` registra cada línea mostrada; se puede compartir entre vistas.
- `@export hide_action` oculta todos los diálogos mientras se mantiene; `DialogueView.set_all_hidden()` desde código.
- `@export layout`: `SCREEN` (caja abajo) o `BUBBLE` (globo).
- `@export input_mode`: `AUTO`, `EVENTS`, `POLLING` o `NONE`.
- `DialogueView3D` es un globo `Node3D` que envuelve un `DialogueView`.
- Señales: `dialogue_started`, `line_changed(index)`, `dialogue_finished`.
- `@export skip_action` es la acción de entrada que salta el tipeo o avanza. Por defecto `ui_accept`.
- `DialogueResource` contiene las líneas y toda la configuración de tiempos y animación.
- `DialogueConstants.AdvanceMode`: `AUTO`, `MANUAL`, `HYBRID`.

## Uso: agregar la vista

Instancia `res://addons/ss-gameforge-dialogue/scenes/dialogue_view.tscn` en tu
escena. Arranca oculto y se muestra solo cuando corre `play()`.

La vista ocupa todo su padre (toda la pantalla si no está dentro de un
contenedor) y deja pasar el mouse. La caja abarca el ancho, queda a
`position_margin` del borde inferior y crece hacia arriba según su texto, que
salta a tantas líneas como necesite. Pon la vista en un `CanvasLayer` si tu juego
usa una `Camera2D`, para que la cámara no la mueva.

> No la metas dentro de un `VBoxContainer` u otro contenedor: el contenedor la
> reduce a su tamaño mínimo y la caja se queda sin dónde anclarse.

## Uso: escribir el contenido

Crea un `DialogueResource` y llena `dialogues`:

```gdscript
var resource := DialogueResource.new()
resource.dialogues = [
	"La puerta no se abrirá sin el sello.",
	"Búscalo en el [i]ala este[/i].",
]
resource.use_translation = false
```

> `use_translation` viene en **true**, lo que significa que cada entrada se trata
> como clave de traducción y pasa por `tr()`. Ponlo en `false` para mostrar los
> textos tal como están escritos.

Los saltos de línea funcionan con un `\n` literal dentro del string, que la vista
convierte en un salto real.

## Uso: reproducir una secuencia

```gdscript
@onready var dialogue_view: DialogueView = $DialogueView

func _on_npc_hablado() -> void:
	dialogue_view.dialogue_finished.connect(_on_dialogue_finished, CONNECT_ONE_SHOT)
	dialogue_view.play(resource)

func _on_dialogue_finished() -> void:
	print("listo")
```

> `CONNECT_ONE_SHOT` importa cuando la misma vista reproduce muchas secuencias:
> sin él, el callback se acumula en cada reproducción.

Reutilizar un recurso ya autorado para varios diálogos se resuelve con
`duplicate()`, que es lo que hace el showcase:

```gdscript
const BASE_RESOURCE := preload("res://examples/showcase/game_manager_dialogue_resource.tres")

var resource := BASE_RESOURCE.duplicate() as DialogueResource
resource.dialogues = pokemon_flavor_texts
dialogue_view.play(resource)
```

`play()` se ignora mientras otra secuencia está corriendo o cerrándose, así que
es seguro llamarlo desde un manejador de entrada. `stop()` es seguro en cualquier
momento, incluso durante la espera inicial o la animación de apertura, y
`dialogue_finished` se emite una vez por secuencia (ninguna si `stop()` cancela
durante la espera inicial, porque no se abrió nada).

La pulsación de `skip_action` que salta o avanza se marca como manejada, así que
no le llega también al juego. Las pulsaciones durante la animación de apertura se
descartan, así que la misma pulsación que inició la conversación nunca salta su
primera línea.

## Uso: cómo avanzan las líneas

`advance_mode` en el recurso decide quién mueve el diálogo hacia adelante:

| Modo | Comportamiento |
|---|---|
| `AUTO` | Avanza solo tras `hold_after_line`. La espera no se puede saltar. |
| `MANUAL` | Espera `skip_action`. Sin temporizador. |
| `HYBRID` | Avanza por temporizador o por entrada del jugador. Es el valor por defecto. |

En todos los modos, presionar `skip_action` mientras una línea se está
escribiendo la completa de inmediato — siempre que `allow_skip` sea true.

## Uso: layouts — caja de pantalla o globo

`layout` decide dónde va la caja. El mismo recurso, tema y API funcionan con los
dos, así que un juego puede usar la caja de pantalla en las escenas de historia y
globos para la charla de fondo.

| Layout | Se ve como | Sirve para |
|---|---|---|
| `SCREEN` (por defecto) | Una caja a lo ancho de la parte de abajo de la vista, que crece hacia arriba. | Juegos con vista cenital o lateral y una caja de diálogo fija. |
| `BUBBLE` | Una caja del tamaño de su texto (salta de línea en el `bubble_max_width` del tema), con su centro inferior en el origen de la vista. | Globos de diálogo sobre personajes, en 2D o 3D. |

### Globo en 2D

Pon un `DialogueView` con `layout = BUBBLE` bajo un `Node2D` (un `Marker2D` sobre
la cabeza del personaje funciona bien). La cola del globo queda en ese punto y
sigue al personaje y a la cámara:

```gdscript
@onready var bubble: DialogueView = $HeadMarker/DialogueView  # layout = BUBBLE

func talk() -> void:
	bubble.play(npc_lines)
```

### Globo en 3D: `DialogueView3D`

`DialogueView3D` es un `Node3D` que arma solo el montaje en el mundo: un
`SubViewport` transparente con un `DialogueView` en layout `BUBBLE`, mostrado en
un `Sprite3D` con billboard, y el viewport se ajusta al globo en cada línea.
Ponlo donde debe apuntar la cola y llama a `play()`:

```gdscript
@onready var bubble: DialogueView3D = $Head/DialogueView3D

func talk() -> void:
	bubble.play(npc_lines)
```

Reenvía `play()`, `stop()`, `skip()`, `is_playing()` y las tres señales;
`get_view()` devuelve el `DialogueView` interno para lo demás. Opciones del
sprite: `pixel_size` (unidades del mundo por píxel del globo, por defecto
`0.01`), `billboard`, `no_depth_test` (activo por defecto, para que la geometría
nunca tape el texto) y `fixed_size` (mismo tamaño en pantalla a cualquier
distancia).

## Uso: entrada

`skip_action` se lee según `input_mode`:

| Modo | Lee la entrada de |
|---|---|
| `AUTO` (por defecto) | Eventos de `_unhandled_input`, marcando la pulsación como manejada. Si la vista está en un `SubViewport` que no recibe eventos (uno usado como textura, como dentro de `DialogueView3D`), hace polling. |
| `EVENTS` | Solo eventos. |
| `POLLING` | `Input.is_action_just_pressed()` cada frame, en cualquier viewport. La pulsación no se consume. |
| `NONE` | Nada: maneja el diálogo tú mismo con `skip()`. |

`skip()` hace lo mismo que una pulsación: completa la línea que se está
escribiendo o avanza a la siguiente (salvo en modo de avance `AUTO`). Devuelve
`true` cuando hizo algo, así que puedes reenviar la entrada desde tu propio
sistema, por ejemplo por jugador:

```gdscript
func _process(_delta: float) -> void:
	if player.is_action_just_pressed("talk"):
		bubble.skip()
```

## Uso: historial y volver atrás

Cada línea que muestra una vista se escribe en su `history`, un recurso
`DialogueHistory`. Asigna el mismo a varias vistas (caja de pantalla, globos 2D y
3D) y junta a todos los personajes en un solo registro:

```gdscript
var log := DialogueHistory.new()

func _ready() -> void:
	$DialogueView.history = log
	$Npc/DialogueView3D.history = log
```

Cada entrada es `{"text", "resource", "index"}`, con el texto tal como se mostró
(traducido, con BBCode). El addon registra; tu juego decide cómo se ve el
historial:

```gdscript
func open_backlog() -> void:
	for entry in log.get_entries():
		backlog_list.append_text(entry["text"] + "\n")
```

`max_entries` (por defecto 200, `0` = sin límite) descarta las más viejas,
`clear()` lo vacía y `entry_added` se emite con cada línea nueva. Una vista sin
historial asignado guarda el suyo propio.

`back()`, o una pulsación de la acción opcional `back_action`, vuelve a mostrar la
línea anterior de la secuencia en curso, ya completa. Al avanzar de nuevo esas
líneas no se registran dos veces.

## Uso: ocultar todos los diálogos

Asigna una acción a `hide_action` y, mientras el jugador la mantenga presionada,
todos los diálogos (caja de pantalla, globos 2D y 3D) se ocultan para que se vea
la escena detrás. No se pausan: las líneas siguen escribiéndose y `skip_action`
sigue avanzando. Al soltar el botón vuelven a verse.

Asigna `hide_action` a un botón cercano al de `skip_action`: el jugador lo
mantiene para mirar, lo suelta para leer y presiona continuar como siempre.

> Usa el ocultar con el modo de avance `MANUAL`. En `AUTO` y `HYBRID` el
> temporizador sigue avanzando mientras el diálogo está oculto, así que el
> jugador puede perderse líneas.

Desde código, `DialogueView.set_all_hidden(true)` los oculta todos hasta
`set_all_hidden(false)`, sin depender del botón, y `DialogueView.is_all_hidden()`
dice si están ocultos. Las vistas creadas mientras están ocultos arrancan
ocultas.

## Uso: tiempos y animación

Todo vive en el recurso:

```gdscript
resource.text_speed = 0.075       # segundos por carácter visible
resource.time_to_start = 0.25     # espera entre play() y la aparición de la caja
resource.hold_after_line = 0.75   # pausa antes de avanzar automáticamente
resource.open_time = 0.55
resource.open_transition = Tween.TRANS_ELASTIC
resource.close_time = 0.20
```

## Uso: tematizar

Asigna un `DialogueTheme` al `dialogue_theme` de la vista. Sin uno, se aplica un
estilo oscuro incorporado.

```gdscript
dialogue_view.dialogue_theme = preload("res://ui/mi_dialogue_theme.tres")
dialogue_view.apply_theme()
```

El tema cubre la caja (`background_color`, `border_color`, `border_width`,
`corner_radius`, `padding`), el texto (`font_color`, `font_size`, `font`) y
`position_margin`, la distancia a los bordes izquierdo, derecho e inferior de la
vista (layout `SCREEN`), y `bubble_max_width`, donde el texto de un globo empieza
a saltar de línea (layout `BUBBLE`, por defecto 320 px).

Para una caja con textura, define `background_texture` (se dibuja como 9-slice,
con `texture_patch_margin` píxeles de borde sin estirar). `background_color`
entonces tiñe la textura, y el borde y las esquinas se ignoran.

## BBCode

El revelado entiende BBCode: la línea completa se acomoda primero y se revela con
`RichTextLabel.visible_characters`, así que una línea como
`Búscalo en el [i]ala este[/i].` se escribe sin filtrar el marcado, y las
palabras nunca saltan a la siguiente línea a mitad del tipeo.

`BBCodeParser` sigue disponible como utilidad (`visible_length()`, `prefix()`)
para tu propio código.
