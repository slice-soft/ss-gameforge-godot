# Toast

`ToastService` muestra notificaciones breves que no bloquean el juego. Encola los
mensajes, puede apilar varios en pantalla y trae cinco estilos y nueve posiciones
de anclaje.

> Requiere `ss-gameforge-singleton`: `ToastService` extiende `SingletonNode`.

## Cuándo usarlo

- Cuando quieres feedback rápido que no interrumpa la partida ("Partida guardada", "Sin conexión").
- Cuando necesitas indicar progreso y que el aviso permanezca hasta que termine una tarea.
- Cuando pueden dispararse varios mensajes a la vez y no quieres que se superpongan.

## API clave

- `ToastService.i` devuelve la instancia activa.
- `show(text, style, overrides)` encola un toast con un estilo explícito.
- `info(text, overrides)`, `success(text, overrides)`, `danger(text, overrides)`,
  `custom(text, overrides)` son atajos para los estilos estándar.
- `loader(text, overrides)` muestra un toast con ícono giratorio.
- `loader_task(text, task, overrides)` mantiene el loader abierto hasta que se emita la señal `task`.
- `ToastConstants.ToastStyle`: `INFO`, `SUCCESS`, `DANGER`, `CUSTOM`, `LOADER`.
- `ToastConstants.ToastPosition`: los nueve anclajes, de `TOP_LEFT` a `BOTTOM_RIGHT`.
- `ToastTheme` es el recurso que define todos los valores por defecto.

## Uso: crear el servicio

`ToastService` es un `SingletonNode`, así que debe existir antes de la primera
llamada. Créalo una vez en tu escena principal:

```gdscript
func _enter_tree() -> void:
	SingletonNode.ensure_for(ToastService, get_tree().root, "ToastService")
```

## Uso: mostrar un toast

```gdscript
ToastService.i.info("Partida guardada")
ToastService.i.success("Nivel completado")
ToastService.i.danger("Se perdió la conexión")
```

`custom()` usa el estilo neutro del tema, pensado para combinarse con overrides.

## Uso: un loader atado a una tarea

`loader_task()` recibe cualquier `Signal` y mantiene el toast abierto hasta que
se emita. El toast no tiene duración propia: la señal es la que lo cierra.

```gdscript
var timer := get_tree().create_timer(0.8)
ToastService.i.loader_task("Iniciando...", timer.timeout)
await timer.timeout
```

Sirve cualquier señal, que es lo que lo hace útil con trabajo real:

```gdscript
var request := HTTPRequest.new()
add_child(request)
ToastService.i.loader_task("Descargando...", request.request_completed)
request.request(url)
```

> Usa `loader()` cuando quieras un spinner que se cierre con la duración normal
> en vez de esperar una señal.

## Uso: sobrescribir un solo toast

El tercer argumento sobrescribe el tema para ese toast puntual. Estas son las
claves que entiende el resolutor:

| Clave | Clave | Clave |
|---|---|---|
| `background_color` | `text_color` | `duration` |
| `icon` | `icon_color` | `icon_scene` |
| `icon_spin` | `icon_spin_speed` | `icon_size` |
| `font_size` | `padding` | `corner_radius` |
| `position` | `position_margin` | |

```gdscript
ToastService.i.info("Logro desbloqueado", {
	"duration": 4.0,
	"position": ToastConstants.ToastPosition.TOP_RIGHT,
	"corner_radius": 4.0,
})
```

## Uso: tematizar todos los toasts

Crea un recurso `ToastTheme`, define colores, íconos y tiempos, y asígnalo al
servicio. Si no asignas ninguno se usa el tema incluido en
`res://addons/ss-gameforge-toast/themes/toast_default.tres`.

```gdscript
func _enter_tree() -> void:
	SingletonNode.ensure_for(ToastService, get_tree().root, "ToastService")
	ToastService.i.theme = preload("res://ui/mi_toast_theme.tres")
```

`ToastTheme` expone los valores globales (`duration`, `font_size`, `icon_size`,
`corner_radius`, `padding`, `position`, `position_margin`) más un color de fondo,
color de texto e ícono por cada estilo.

## Uso: cola y apilado

Estas propiedades están exportadas en el servicio, así que también puedes
ajustarlas desde el inspector:

```gdscript
ToastService.i.stack_toasts = true   # false muestra uno a la vez
ToastService.i.max_visible = 4       # toasts simultáneos al apilar
ToastService.i.stack_spacing = 8.0   # píxeles entre toasts apilados
ToastService.i.max_queue = 50        # mensajes en cola antes de descartar
```

> Con `stack_toasts = false` el servicio espera a que termine el toast activo
> antes de mostrar el siguiente de la cola.
