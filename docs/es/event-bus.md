# Event Bus

`EventBus` permite que los sistemas de tu juego se comuniquen sin tener referencias
entre sí. El addon no trae una lista fija de eventos: cada juego extiende `EventBus` y
declara **sus propias señales tipadas**, así Godot las valida y autocompleta.

> Requiere `ss-gameforge-singleton`: `EventBus` extiende `SingletonNode`.

## Cuándo usarlo

- La UI, el audio o los logros deben reaccionar al gameplay ("el jugador murió",
  "recogió una moneda") sin que el script del jugador sepa que existen.
- Un sistema se crea y se destruye seguido (enemigos, balas en pool) y debe dejar de
  recibir eventos apenas sale de la escena.

## API principal

- `class_name MisEventos extends EventBus` declara el bus de tu juego y sus `signal`s.
- `MisEventos.i` devuelve la instancia activa. Este acceso lo escribes en tu subclase.
- `listen(owner, {señal: callable})` conecta cada par para `owner`. Todo se desconecta
  cuando `owner` sale del árbol de escena.
- `unlisten(owner)` desconecta todo lo que registró `owner`, cuando quieras.
- `trace` (por defecto `false`): en `true` y en un build de debug, imprime una línea por
  emisión, como `[EventBus] player_died(1)`.
- Se emite con la API de Godot: `MisEventos.i.player_died.emit(1)`.

## Uso: declarar tu bus

```gdscript
# game_events.gd
class_name GameEvents
extends EventBus

static var i: GameEvents:
	get:
		return SingletonNode.get_instance_for(GameEvents) as GameEvents

signal player_died(player_id: int)
signal health_changed(current: int, max_value: int)
```

Créalo una vez y temprano, por ejemplo en tu escena principal:

```gdscript
func _enter_tree() -> void:
	SingletonNode.ensure_for(GameEvents, get_tree().root, "GameEvents")
```

## Uso: emitir y escuchar

```gdscript
# player.gd
GameEvents.i.player_died.emit(player_id)
```

```gdscript
# hud.gd
func _enter_tree() -> void:
	_subscribe.call_deferred()

func _subscribe() -> void:
	GameEvents.i.listen(self, {
		GameEvents.i.player_died: _on_player_died,
		GameEvents.i.health_changed: _on_health_changed,
	})

func _on_player_died(player_id: int) -> void:
	...
```

`ensure_for` agrega el bus con `call_deferred`, así que un nodo que entra al árbol en el
mismo frame se suscribe un paso diferido después. Por eso el ejemplo usa
`_subscribe.call_deferred()`.

## Depuración

```gdscript
GameEvents.i.trace = true   # [EventBus] player_died(1)
```

Solo se trazan las señales que declara tu subclase. Los builds de release nunca imprimen.

## Errores comunes

- **Llama a `listen` desde `_enter_tree`, no desde `_ready`.** Salir del árbol elimina
  las suscripciones, y `_ready` corre una sola vez, así que un nodo reciclado o
  re-emparentado dejaría de recibir eventos después de su primera salida del árbol.
- **Escuchar desde un nodo fuera del árbol** imprime una advertencia. Sus conexiones solo
  se eliminan al salir del árbol o con `unlisten()`. Si se libera sin haber entrado nunca
  al árbol, Godot quita solo las conexiones a sus propios métodos; una lambda o un método
  de otro objeto sigue recibiendo eventos hasta `unlisten()`.
- **Varios buses están bien.** Cada subclase (`GameEvents`, `UIEvents`, ...) tiene su
  propia instancia.
