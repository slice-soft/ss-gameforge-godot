# SingletonNode

`SingletonNode` es una clase base que garantiza una única instancia activa por
script. Si otra instancia del mismo script entra al árbol de escenas, la nueva
instancia se libera automáticamente.

## Cuándo usarlo

- Cuando necesitas un nodo tipo servicio que exista solo una vez.
- Cuando quieres acceder a ese nodo de forma global sin Autoloads.
- Cuando quieres crear el singleton bajo demanda.

## API clave

- `SingletonNode.get_instance_for(script)` devuelve la instancia activa para un script.
- `SingletonNode.ensure_for(script, root, instance_name)` crea y añade la instancia si falta.
- `is_active_instance()` verifica si el nodo actual es la instancia activa.

## Uso: extendiendo `SingletonNode`

Tanto `BossFightDirector` como `SaveService` extienden `SingletonNode`:

```gdscript
extends SingletonNode
class_name BossFightDirector

static var i: BossFightDirector:
	get:
		return SingletonNode.get_instance_for(BossFightDirector) as BossFightDirector

var phase := 1

func next_phase() -> int:
	phase += 1
	print("[BossFightDirector] phase -> ", phase)
	return phase
```

```gdscript
extends SingletonNode
class_name SaveService

static var i: SaveService:
	get:
		return SingletonNode.get_instance_for(SaveService) as SaveService

func save_game(data: Dictionary) -> void:
	pass
```

## Uso: colocar en la escena

**BossFightDirector** debe añadirse como un nodo en la escena donde ocurra el combate de jefe.
Puedes adjuntar el script directamente a un Node en tu árbol de escenas.

> Si otra instancia del mismo script entra al árbol de escenas, será liberada automáticamente.

## Uso: acceder al singleton

```gdscript
if BossFightDirector.i:
	BossFightDirector.i.next_phase()
```

## Uso: asegurar la instancia

Usa `ensure_for()` para crear el singleton si no existe:

- **Automático**: Llámalo en el `_ready()` de la escena principal para servicios necesarios de inmediato.
- **Bajo demanda**: Llámalo tras un evento del jugador (como guardar, cargar, entrar en combate de jefe).

```gdscript
# En el _ready() de tu escena principal para inicialización automática
func _ready() -> void:
	SingletonNode.ensure_for(SaveService, get_tree().root, "SaveService")

# O tras un evento del jugador
func _on_player_entered_boss_fight() -> void:
	SingletonNode.ensure_for(BossFightDirector, get_tree().root, "BossFightDirector")
```

> Nota: `ensure_for()` es seguro llamarlo múltiples veces.  
> Si ya existe una instancia, no se creará un nuevo nodo.
