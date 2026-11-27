# Dialogue

`DialogueView` es un `Control` que escribe una secuencia de líneas carácter por
carácter y anima una caja de entrada y salida alrededor. Las líneas viven en un
`DialogueResource`, así que escribir contenido nunca implica tocar la vista.

## Cuándo usarlo

- Cuando necesitas una caja de diálogo con efecto máquina de escribir y animación de apertura y cierre.
- Cuando quieres que el contenido sea data, editable como recurso.
- Cuando tus líneas usan BBCode y deben revelarse correctamente, etiqueta por etiqueta.

## API clave

- `play(resource)` inicia una secuencia. Es el punto de entrada principal.
- `stop()` cancela el diálogo actual y reproduce la animación de cierre.
- `apply_theme()` reaplica `dialogue_theme`; `play()` ya lo llama.
- `is_playing()` es true desde `play()` hasta `dialogue_finished`.
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
vista.

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
