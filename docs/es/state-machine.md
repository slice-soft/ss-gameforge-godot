# State Machine

`StateMachine` es un `Node` cuyos hijos son los estados. Cada estado es un nodo
`StateBase` que recibe `start()` al entrar y `end()` al salir, y que se suscribe
solo a los callbacks de proceso y entrada que realmente necesita.

## Cuándo usarlo

- Cuando un personaje, enemigo o pantalla de UI tiene comportamiento por fases claras.
- Cuando quieres expresar el flujo de una escena (boot → loading → viewing) como nodos.
- Cuando quieres ver, en el árbol de escenas remoto, qué estado está corriendo.

## API clave

- `change_to(state_name)` transiciona a un estado hijo, por nombre de nodo.
- `change_to_previous()` vuelve al estado que se dejó por último.
- `current_state` y `previous_state` guardan las instancias `StateBase`.
- `signal state_changed(from, to)` se emite después de que el nuevo estado arrancó.
- `@export default_state: StateBase` es el estado al que se entra en `_ready()`.
- `@export enable_debug_logging: bool` imprime las transiciones en builds de depuración.
- `get_state_history()` devuelve los últimos 10 nombres de estado.

En `StateBase`:

- `start()` y `end()`, sobrescritos por cada estado.
- `controlled_node` es el nodo sobre el que actúa la máquina.
- `state_machine` es la referencia de vuelta a la máquina.

## Uso: armar la escena

Agrega un nodo `StateMachine` y haz que cada estado sea hijo suyo:

```
Player
└── StateMachine        (default_state → Idle)
    ├── Idle
    ├── Running
    └── Jumping
```

`change_to()` busca su argumento con `has_node()`, así que **el string debe ser
el nombre del nodo hijo**. Define `default_state` en el inspector apuntando al
estado que debe correr primero.

> `controlled_node` se resuelve como el `owner` de la máquina — la raíz de la
> escena en la que se guardó. Cada estado lo recibe antes de que se llame `start()`.

## Uso: escribir un estado

```gdscript
extends StateBase
class_name RunningState

func start() -> void:
	controlled_node.play_animation("run")

func end() -> void:
	controlled_node.stop_animation()

func on_physics_process(delta: float) -> void:
	if controlled_node.velocity.is_zero_approx():
		state_machine.change_to("Idle")
```

La máquina solo reenvía un callback si el estado lo define, así que un estado que
no necesita física simplemente omite `on_physics_process`. Los hooks disponibles
son `on_process(delta)`, `on_physics_process(delta)`, `on_input(event)`,
`on_unhandled_input(event)` y `on_unhandled_key_input(event)`.

## Uso: tipar `controlled_node`

`controlled_node` es un `Node` a secas. Una pequeña clase base por máquina te da
autocompletado y chequeo de tipos en todos los estados — el showcase lo hace así:

```gdscript
extends StateBase
class_name GameManagerStateBase

var game_manager: GameManager:
	set(value): controlled_node = value
	get: return controlled_node as GameManager
```

Los estados entonces extienden `GameManagerStateBase` y usan `game_manager`
directamente.

## Uso: nombrar estados sin strings mágicos

Las transiciones reciben strings, fáciles de escribir mal. Tenerlos en un recurso
te da un único lugar donde renombrarlos:

```gdscript
extends Resource
class_name GameManagerStates

const Boot: String = "BootState"
const Loading: String = "LoadingState"
const Viewing: String = "ViewingState"
const Dialogue: String = "DialogueState"
```

```gdscript
state_machine.change_to(GameManagerStates.Loading)
```

> El valor de la constante debe coincidir con el **nombre del nodo hijo** en la
> escena, no con el nombre de la clase — arriba se parecen solo porque los nodos
> se nombraron igual que sus clases.

## Uso: reaccionar a las transiciones

```gdscript
func _ready() -> void:
	$StateMachine.state_changed.connect(_on_state_changed)

func _on_state_changed(from: String, to: String) -> void:
	print("%s -> %s" % [from, to])
```

`from` llega como string vacío en la primerísima transición, porque antes no
había nada corriendo.

## Comportamiento que conviene saber

- **Volver a entrar al estado actual se ignora.** `change_to()` retorna temprano
  cuando el destino ya está activo, así que un estado no puede reiniciarse así.
- **Un estado inexistente es un error, no un crash.** Un nombre desconocido llama
  a `push_error()` y deja corriendo el estado actual.
- **El estado por defecto arranca diferido.** `_ready()` difiere la primera
  transición, así que el árbol completo está disponible cuando corre `start()`.
- **`change_to_previous()` recuerda un solo paso atrás.** Es un intercambio, no
  una pila: úsalo para pantallas de pausa, no para historial de navegación profundo.
