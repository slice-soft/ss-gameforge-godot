# GodotWired — Documentación Técnica

> Plugin de input avanzado para Godot 4. Remapeo en runtime, aislamiento multi-jugador, detección automática de dispositivos y UI lista para usar. Inspirado en Rewired para Unity.
> 
> **Autor:** SliceSoft — **Versión objetivo:** 1.0.0 — **Motor:** Godot 4.x — **Lenguaje:** GDScript puro

---

## Tabla de contenidos

1. [Motivación y contexto](#1-motivación-y-contexto)
2. [Filosofía de diseño](#2-filosofía-de-diseño)
3. [Estructura del proyecto](#3-estructura-del-proyecto)
4. [Arquitectura y capas](#4-arquitectura-y-capas)
5. [Modelos de datos](#5-modelos-de-datos)
   - 5.1 [GWBinding](#51-gwbinding)
   - 5.2 [GWAction](#52-gwaction)
   - 5.3 [GWDevice](#53-gwdevice)
   - 5.4 [GWPlayer](#54-gwplayer)
6. [Singleton central — GWInputManager](#6-singleton-central--gwinputmanager)
7. [Flujo de rebinding](#7-flujo-de-rebinding)
8. [Capa de persistencia](#8-capa-de-persistencia)
9. [Componentes UI](#9-componentes-ui)
   - 9.1 [GWBindingUI](#91-gwbindingui)
   - 9.2 [GWDeviceSelector](#92-gwdeviceselector)
10. [API pública — referencia completa](#10-api-pública--referencia-completa)
11. [Señales del sistema](#11-señales-del-sistema)
12. [Guía de uso rápido](#12-guía-de-uso-rápido)
13. [Decisiones de diseño y trade-offs](#13-decisiones-de-diseño-y-trade-offs)
14. [Roadmap](#14-roadmap)

---

## 1. Motivación y contexto

El `InputMap` nativo de Godot resuelve bien el caso básico: mapear teclas a acciones y consultarlas con `Input.is_action_pressed()`. Sin embargo, tiene limitaciones estructurales para juegos con requerimientos avanzados:

| Limitación del InputMap nativo | Impacto |
|---|---|
| El mapa de inputs es **global** — no existe el concepto de jugador | Imposible aislar inputs de P1 vs P2 sin hacks |
| No hay UI de remapeo incluida | Cada juego la reimplementa desde cero |
| El remapeo en runtime modifica el estado global | Un rebind de P1 afecta a P2 |
| No hay modelo de "dispositivo asignado" | No se puede saber qué gamepad pertenece a quién |
| No hay persistencia de bindings | Hay que serializar manualmente |

GodotWired resuelve estos problemas introduciendo una capa de abstracción sobre `InputMap` con el concepto de **jugadores lógicos**, cada uno con su propio set independiente de bindings.

---

## 2. Filosofía de diseño

### Actions como contrato, no como teclas

El código de gameplay **nunca menciona teclas ni botones**. Solo conoce nombres de acciones abstractas:

```gdscript
# ❌ Acoplado al hardware
if Input.is_key_pressed(KEY_SPACE):
    jump()

# ✅ GodotWired — desacoplado
if GWInputManager.is_action_pressed("jump", player_id):
    jump()
```

Esto permite remapear cualquier acción sin tocar una línea de código de gameplay.

### Aislamiento por jugador

Cada `GWPlayer` posee una **copia independiente** de todas las acciones. Cambiar el binding de `"jump"` en P1 no afecta a P2.

### Sin dependencias externas

El plugin es GDScript puro. No requiere plugins de C++, GDNative ni addons de terceros. Funciona en todas las plataformas que soporta Godot 4.

### UI sin `.tscn`

Los componentes de UI se construyen completamente en código. El desarrollador no necesita instanciar escenas ni configurar nada en el editor — solo `add_child(GWBindingUI.new())`.

---

## 3. Estructura del proyecto

```
addons/godot_wired/
│
├── plugin.cfg                        # Metadata del plugin (nombre, versión, autor)
├── plugin.gd                         # EditorPlugin — registra el autoload al activar
│
├── core/
│   ├── gw_binding.gd                 # Binding concreto (tecla, botón, eje)
│   ├── gw_action.gd                  # Acción abstracta con N bindings
│   ├── gw_device.gd                  # Abstracción de dispositivo físico
│   ├── gw_player.gd                  # Jugador lógico con bindings independientes
│   └── gw_input_manager.gd           # Autoload central (singleton)
│
├── ui/
│   ├── gw_binding_ui.gd              # Panel de remapeo completo
│   └── gw_device_selector.gd         # Widget de asignación de dispositivos
│
└── examples/
    ├── game_setup.gd                 # Ejemplo: configuración inicial completa
    ├── example_player.gd             # Ejemplo: CharacterBody2D con GodotWired
    └── example_settings_menu.gd      # Ejemplo: menú de settings con tabs
```

---

## 4. Arquitectura y capas

```
┌─────────────────────────────────────────────────────────┐
│                    GAMEPLAY CODE                        │
│  player.gd, enemy.gd, ui.gd ...                        │
│  Solo conoce: GWInputManager + nombres de acciones      │
└────────────────────────┬────────────────────────────────┘
                         │ is_action_pressed("jump", 0)
                         ▼
┌─────────────────────────────────────────────────────────┐
│               GWInputManager  (Autoload)                │
│  - Registro de action templates                         │
│  - Creación y gestión de GWPlayers                      │
│  - Flujo de rebind-listen                               │
│  - Detección de dispositivos                            │
│  - Persistencia (save / load JSON)                      │
└────────┬───────────────────────────────┬────────────────┘
         │                               │
         ▼                               ▼
┌─────────────────┐             ┌─────────────────┐
│   GWPlayer[0]   │             │   GWPlayer[1]   │
│  KB + Gamepad1  │             │   Gamepad2      │
│                 │             │                 │
│  actions: {     │             │  actions: {     │
│   "jump": ...   │             │   "jump": ...   │  ← copias independientes
│   "attack": ... │             │   "attack": ... │
│  }              │             │  }              │
└────────┬────────┘             └────────┬────────┘
         │                               │
         ▼                               ▼
┌─────────────────────────────────────────────────────────┐
│                    GWAction                             │
│  action_name, display_name, category, max_bindings      │
│  bindings: [GWBinding, GWBinding, ...]                  │
└────────────────────────┬────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────┐
│                    GWBinding                            │
│  type: KEY | JOY_BUTTON | JOY_AXIS | MOUSE_BUTTON       │
│  key_code / joy_button / joy_axis / axis_direction      │
│  device_id, deadzone                                    │
│                                                         │
│  matches_event(event) → bool                            │
│  get_strength(devices) → float                          │
│  get_display_name() → String                            │
└─────────────────────────────────────────────────────────┘
```

---

## 5. Modelos de datos

### 5.1 GWBinding

**Archivo:** `core/gw_binding.gd`  
**Clase:** `GWBinding extends Resource`

El átomo del sistema. Representa **un único input físico** mapeado a nada — los bindings no saben a qué acción pertenecen.

#### Propiedades

| Propiedad | Tipo | Default | Descripción |
|---|---|---|---|
| `type` | `BindingType` | `KEY` | Tipo de input físico |
| `device_id` | `int` | `-1` | `-1` = cualquier gamepad; `≥0` = gamepad específico |
| `key_code` | `Key` | `KEY_NONE` | Tecla (solo si `type == KEY`) |
| `mouse_button` | `MouseButton` | `MOUSE_BUTTON_NONE` | Botón de mouse |
| `joy_button` | `JoyButton` | `JOY_BUTTON_INVALID` | Botón de gamepad |
| `joy_axis` | `JoyAxis` | `JOY_AXIS_INVALID` | Eje de gamepad |
| `axis_direction` | `float` | `1.0` | `+1.0` o `-1.0` — dirección del eje |
| `deadzone` | `float` | `0.2` | Valor mínimo para considerar el eje activo |

#### Enum `BindingType`

```
KEY, MOUSE_BUTTON, JOY_BUTTON, JOY_AXIS
```

#### Factories estáticos

```gdscript
GWBinding.from_key(KEY_SPACE)
GWBinding.from_joy_button(JOY_BUTTON_A, device_id)
GWBinding.from_joy_axis(JOY_AXIS_LEFT_X, -1.0, device_id)
GWBinding.from_mouse_button(MOUSE_BUTTON_LEFT)
```

El parámetro `device_id` es opcional; si se omite, el binding responde a cualquier gamepad (`-1`).

#### Métodos de evaluación

```gdscript
binding.matches_event(event: InputEvent) -> bool
binding.is_pressed(assigned_devices: Array) -> bool
binding.get_strength(assigned_devices: Array) -> float   # [0.0 .. 1.0]
binding.get_display_name() -> String                     # "Space", "A Button", "LX +"
```

#### Serialización

```gdscript
binding.to_dict() -> Dictionary
GWBinding.from_dict(d: Dictionary) -> GWBinding
```

---

### 5.2 GWAction

**Archivo:** `core/gw_action.gd`  
**Clase:** `GWAction extends Resource`

Una acción abstracta que agrupa entre 1 y N bindings. Es la interfaz que el código de gameplay conoce.

#### Propiedades

| Propiedad | Tipo | Descripción |
|---|---|---|
| `action_name` | `String` | Identificador interno (`"jump"`, `"attack"`) |
| `display_name` | `String` | Nombre mostrado en la UI (`"Saltar"`) |
| `description` | `String` | Descripción / tooltip en la UI |
| `category` | `String` | Agrupa acciones en la UI (`"Movement"`, `"Combat"`) |
| `max_bindings` | `int` | Slots máximos. `0` = ilimitado |
| `allow_rebind` | `bool` | Si `false`, no aparece como editable en la UI |
| `bindings` | `Array[GWBinding]` | Lista de bindings activos |

#### Señales

```gdscript
signal binding_added(binding: GWBinding)
signal binding_removed(index: int)
signal bindings_cleared()
```

#### Métodos principales

```gdscript
action.add_binding(binding) -> bool          # false si max_bindings alcanzado
action.set_binding(index, binding)           # reemplaza o añade en index
action.remove_binding(index)
action.clear_bindings()

# Evaluación (llamados por GWPlayer)
action.is_pressed(assigned_devices) -> bool
action.get_strength(assigned_devices) -> float
action.was_just_pressed(assigned_devices, event) -> bool
action.was_just_released(assigned_devices, event) -> bool

# Detección de conflictos
action.conflicts_with_event(event) -> bool

# Clonado profundo (usado internamente al crear GWPlayer)
action.duplicate_full() -> GWAction
```

---

### 5.3 GWDevice

**Archivo:** `core/gw_device.gd`  
**Clase:** `GWDevice extends RefCounted`

Abstracción de un dispositivo físico conectado. No hereda de `Node` para evitar overhead.

#### Propiedades

| Propiedad | Tipo | Descripción |
|---|---|---|
| `device_id` | `int` | ID de Godot. `-1` = teclado/mouse |
| `device_type` | `DeviceType` | `KEYBOARD_MOUSE`, `GAMEPAD`, `UNKNOWN` |
| `device_name` | `String` | Nombre reportado por el SO |
| `is_connected` | `bool` | Estado de conexión |
| `assigned_player` | `int` | Player ID que lo tiene asignado. `-1` = libre |

#### Factories

```gdscript
GWDevice.create_keyboard_mouse() -> GWDevice
GWDevice.create_gamepad(device_index: int) -> GWDevice
GWDevice.scan_connected_devices() -> Array[GWDevice]   # escanea todos los actuales
```

#### Métodos de consulta

```gdscript
device.get_display_name() -> String   # "Keyboard & Mouse", "DualSense (P1)"
device.is_gamepad() -> bool
device.is_assigned() -> bool
```

---

### 5.4 GWPlayer

**Archivo:** `core/gw_player.gd`  
**Clase:** `GWPlayer extends RefCounted`

Un jugador lógico. Mantiene sus propias copias de acciones y la lista de dispositivos que le pertenecen.

#### Propiedades

| Propiedad | Tipo | Descripción |
|---|---|---|
| `player_id` | `int` | Identificador único del jugador |
| `player_name` | `String` | Nombre para mostrar |
| `assigned_gamepads` | `Array[int]` | IDs de gamepads asignados exclusivamente |
| `accepts_keyboard` | `bool` | Si acepta inputs de teclado y mouse |
| `actions` | `Dictionary` | `action_name -> GWAction` (copias propias) |

#### Señales

```gdscript
signal device_assigned(device_id: int)
signal device_unassigned(device_id: int)
signal action_rebound(action_name: String)
```

#### API de dispositivos

```gdscript
player.assign_gamepad(device_id)
player.unassign_gamepad(device_id)
player.unassign_all_gamepads()
player.has_any_device() -> bool
player.get_active_device_ids() -> Array
```

#### API de gameplay

```gdscript
player.is_action_pressed(action_name) -> bool
player.get_action_strength(action_name) -> float
player.is_action_just_pressed(action_name, event) -> bool
player.is_action_just_released(action_name, event) -> bool
player.get_vector(neg_x, pos_x, neg_y, pos_y) -> Vector2
```

> **Nota sobre `just_pressed` / `just_released`:** estos métodos reciben el `InputEvent` del callback `_input(event)`. GWPlayer internamente verifica que el evento pertenezca al jugador (teclado solo si `accepts_keyboard`, gamepad solo si `device in assigned_gamepads`) antes de retornar `true`.

#### API de rebinding

```gdscript
player.set_binding(action_name, index, binding) -> bool
player.clear_action_bindings(action_name)
player.find_conflicts(event, exclude_action) -> Array[GWAction]
```

#### Serialización

```gdscript
player.to_dict() -> Dictionary
player.apply_dict(d: Dictionary)    # aplica bindings desde dict sin recrear el jugador
```

---

## 6. Singleton central — GWInputManager

**Archivo:** `core/gw_input_manager.gd`  
**Clase:** `GWInputManager extends Node`  
**Registrado como autoload con nombre:** `GWInputManager`

Punto único de entrada para todo el sistema. Se registra automáticamente al habilitar el plugin.

### Responsabilidades

- Mantener el catálogo de **action templates** (los moldes que se copian a cada jugador)
- Crear, registrar y destruir **GWPlayers**
- Exponer la **API de gameplay** como shorthand que delega a `GWPlayer`
- Orquestar el **flujo de rebind-listen** (captura el siguiente `InputEvent` y lo aplica)
- Detectar y trackear **dispositivos conectados/desconectados**
- **Guardar y cargar** perfiles de bindings en JSON

### Estado interno

```gdscript
var _action_templates: Dictionary   # action_name -> GWAction (templates)
var players: Dictionary             # player_id -> GWPlayer
var devices: Dictionary             # device_id -> GWDevice  (-1 = KB/mouse)
var _rebind_ctx: Dictionary         # contexto activo del rebind-listen (vacío si inactivo)
```

### Ciclo de vida

```
_ready()
  └── Input.joy_connection_changed.connect(_on_joy_connection_changed)
  └── _scan_devices()   ← escanea gamepads ya conectados al inicio

_input(event)
  └── si _rebind_ctx.listening → _process_rebind_input(event)

_on_joy_connection_changed(device_id, connected)
  └── conectado: crea GWDevice y lo agrega a devices[]
  └── desconectado: lo desasigna de players, lo quita de devices[]
```

---

## 7. Flujo de rebinding

El rebinding funciona con un patrón de "listen mode": el sistema pone una bandera y el próximo `InputEvent` válido que llegue a `_input()` se convierte en el nuevo binding.

```
Usuario presiona "Rebind"
        │
        ▼
GWInputManager.start_rebind_listen(player_id, action_name, binding_index)
        │
        ├── _rebind_ctx = { player_id, action_name, binding_index, listening: true }
        └── emit rebind_listening(player_id, action_name, binding_index)
                │
                ▼ (la UI muestra "Press any key...")
        
Siguiente InputEvent llega a _input(event)
        │
        ├── Si es MouseMotion → ignorar
        ├── Si es Escape pressed → cancel_rebind_listen()
        │       └── emit rebind_cancelled(player_id)
        │
        ├── Si es Key pressed → GWBinding.from_key(keycode)
        ├── Si es JoyButton pressed → GWBinding.from_joy_button(button, device)
        └── Si es JoyAxis con |value| > 0.5 → GWBinding.from_joy_axis(axis, dir, device)
                │
                ▼
        player.set_binding(action_name, binding_index, new_binding)
                │
                └── emit binding_remapped(player_id, action_name)
                        │
                        ▼ (la UI refresca el botón)
        
_rebind_ctx = {}   ← limpia el contexto
get_viewport().set_input_as_handled()   ← consume el evento
```

### Consideraciones

- Solo se captura el **primer** evento válido (no echo, pressed).
- El evento se **consume** con `set_input_as_handled()` para que no lo procese el juego.
- Mientras `_rebind_ctx.listening == true`, `is_listening_for_rebind()` retorna `true` — úsalo para pausar el gameplay si es necesario.

---

## 8. Capa de persistencia

La persistencia se maneja enteramente en `GWInputManager` y se serializa a **JSON**. No hay base de datos ni formato propietario.

### Estructura del archivo JSON

```json
{
    "0": {
        "player_id": 0,
        "player_name": "Player 1",
        "accepts_keyboard": true,
        "actions": {
            "jump": {
                "action_name": "jump",
                "bindings": [
                    { "type": 0, "key_code": 32, "device_id": -1, ... },
                    { "type": 2, "joy_button": 0, "device_id": 0, ... }
                ]
            }
        }
    }
}
```

### API

```gdscript
GWInputManager.save_all_profiles()                           # → user://gw_bindings.json
GWInputManager.save_all_profiles("user://custom_path.json")

GWInputManager.load_all_profiles()
GWInputManager.load_all_profiles("user://custom_path.json")

GWInputManager.reset_all_to_defaults()   # restaura desde _action_templates
```

### Comportamiento de `load_all_profiles`

- Si el archivo no existe, no hace nada (silent).
- Aplica bindings **solo a jugadores que ya existen** (`players.has(pid)`).
- Usa `player.apply_dict()` que limpia los bindings actuales y los reemplaza — no mezcla.
- Emite `binding_remapped` por cada acción restaurada, lo que actualiza la UI automáticamente.

### Comportamiento de `reset_all_to_defaults`

Recorre `_action_templates` y hace un `duplicate_full()` de cada uno, reemplazando las copias en cada jugador. Emite `binding_remapped` para cada acción.

---

## 9. Componentes UI

### 9.1 GWBindingUI

**Archivo:** `ui/gw_binding_ui.gd`  
**Clase:** `GWBindingUI extends PanelContainer`

Panel completo de remapeo de controles. Se construye en código — no requiere `.tscn`.

#### Uso básico

```gdscript
var ui = GWBindingUI.new()
ui.player_id = 0
add_child(ui)
```

#### Propiedades exportadas

| Propiedad | Tipo | Default | Descripción |
|---|---|---|---|
| `player_id` | `int` | `0` | Jugador cuyos bindings se muestran |
| `show_categories` | `bool` | `true` | Agrupa por categoría con headers |
| `listening_color` | `Color` | amarillo suave | Color del row en modo listen |
| `conflict_color` | `Color` | rojo suave | Color para indicar conflicto |

#### Estructura visual generada

```
┌─────────────────────────────────────────────────┐
│ Controls                          [Reset] [Save] │
├─────────────────────────────────────────────────┤
│  Action          Primary       Secondary         │
├─────────────────────────────────────────────────┤
│ ── MOVEMENT ─────────────────────────────────── │
│  Move Left      [ A ]          [ LX← ]          │
│  Move Right     [ D ]          [ LX→ ]          │
├─────────────────────────────────────────────────┤
│ ── COMBAT ───────────────────────────────────── │
│  Jump           [ Space ]      [ A Button ]     │
│  Attack         [ Mouse L ]    [ X Button ]     │
├─────────────────────────────────────────────────┤
│ Ready.                                          │
└─────────────────────────────────────────────────┘
```

#### Flujo de interacción

1. Usuario hace clic en un botón de binding → `start_rebind_listen()` en el manager.
2. El botón cambia su texto a `"Press any key..."`.
3. El manager captura el siguiente evento y llama `set_binding()` en el `GWPlayer`.
4. El manager emite `binding_remapped` → la UI escucha esta señal y refresca el botón.
5. Si el usuario presiona Escape → `rebind_cancelled` → la UI restaura el texto anterior.

#### Botones de acción

- **Reset Defaults** → llama `GWInputManager.reset_all_to_defaults()` y re-popula la UI.
- **Save** → llama `GWInputManager.save_all_profiles()`.

---

### 9.2 GWDeviceSelector

**Archivo:** `ui/gw_device_selector.gd`  
**Clase:** `GWDeviceSelector extends PanelContainer`

Widget para pantallas de lobby o settings. Muestra todos los dispositivos conectados y permite que cada jugador reclame uno.

#### Uso básico

```gdscript
var sel = GWDeviceSelector.new()
sel.max_players = 2
add_child(sel)
```

#### Propiedades

| Propiedad | Tipo | Default | Descripción |
|---|---|---|---|
| `max_players` | `int` | `4` | Cuántas filas de jugador mostrar |

#### Comportamiento

- Se actualiza automáticamente cuando `GWInputManager` emite `device_connected` o `device_disconnected`.
- Al seleccionar "Keyboard & Mouse" (`device_id == -1`): activa `player.accepts_keyboard = true` y limpia gamepads.
- Al seleccionar un gamepad (`device_id >= 0`): llama `player.assign_gamepad(device_id)` y desactiva teclado.
- Al seleccionar "— None —": llama `player.unassign_all_gamepads()` y desactiva teclado.

> **Importante:** el widget no valida que el mismo dispositivo esté asignado a dos jugadores distintos. Para juegos competitivos, agregar esa validación en `_on_device_selected()`.

---

## 10. API pública — referencia completa

### GWInputManager

#### Definición de acciones

```gdscript
# Registra una nueva acción. Llamar antes de create_player().
define_action(
    action_name: String,
    display_name: String = "",
    default_bindings: Array = [],
    category: String = "General",
    max_bindings: int = 2
) -> GWAction

undefine_action(action_name: String)
get_action_template(action_name: String) -> GWAction
get_action_names() -> Array
get_actions_by_category() -> Dictionary    # { "Movement": ["move_left", ...], ... }
```

#### Gestión de jugadores

```gdscript
create_player(player_id: int, player_name: String = "") -> GWPlayer
get_player(player_id: int) -> GWPlayer     # null si no existe
get_default_player() -> GWPlayer           # shorthand para player 0
remove_player(player_id: int)
```

#### API de gameplay (shorthand)

```gdscript
is_action_pressed(action_name, player_id = 0) -> bool
get_action_strength(action_name, player_id = 0) -> float
is_action_just_pressed(action_name, event, player_id = 0) -> bool
is_action_just_released(action_name, event, player_id = 0) -> bool
get_vector(neg_x, pos_x, neg_y, pos_y, player_id = 0) -> Vector2
```

#### Rebinding

```gdscript
start_rebind_listen(player_id: int, action_name: String, binding_index: int = 0)
cancel_rebind_listen()
is_listening_for_rebind() -> bool
```

#### Dispositivos

```gdscript
get_connected_devices() -> Array          # Array de GWDevice
get_unassigned_gamepads() -> Array        # GWDevices sin jugador asignado
```

#### Persistencia

```gdscript
save_all_profiles(path: String = "user://gw_bindings.json")
load_all_profiles(path: String = "user://gw_bindings.json")
reset_all_to_defaults()
```

---

## 11. Señales del sistema

Todas las señales se emiten desde `GWInputManager` (el autoload).

| Señal | Parámetros | Cuándo se emite |
|---|---|---|
| `player_created` | `player_id: int` | Al llamar `create_player()` |
| `player_removed` | `player_id: int` | Al llamar `remove_player()` |
| `device_connected` | `device_id: int, device_name: String` | Gamepad conectado en runtime |
| `device_disconnected` | `device_id: int` | Gamepad desconectado en runtime |
| `binding_remapped` | `player_id: int, action_name: String` | Rebind exitoso |
| `rebind_listening` | `player_id: int, action_name: String, binding_index: int` | Listen mode activado |
| `rebind_cancelled` | `player_id: int` | Listen mode cancelado (Escape) |

### Ejemplo de uso de señales

```gdscript
func _ready():
    GWInputManager.device_disconnected.connect(_on_controller_lost)
    GWInputManager.binding_remapped.connect(_on_rebind_done)

func _on_controller_lost(device_id: int):
    # Pausar el juego y mostrar aviso "Controlador desconectado"
    pass

func _on_rebind_done(player_id: int, action_name: String):
    # Actualizar el HUD con el nuevo ícono del binding
    pass
```

---

## 12. Guía de uso rápido

### Paso 1 — Habilitar el plugin

`Project → Project Settings → Plugins → GodotWired → Enable`

El autoload `GWInputManager` queda registrado automáticamente.

### Paso 2 — Definir acciones

Hacer esto en tu autoload `Game` o en el `_ready()` de la escena principal, **antes de crear jugadores**.

```gdscript
func _ready():
    GWInputManager.define_action("move_left", "Move Left", [
        GWBinding.from_key(KEY_A),
        GWBinding.from_joy_axis(JOY_AXIS_LEFT_X, -1.0),
    ], "Movement")

    GWInputManager.define_action("jump", "Jump", [
        GWBinding.from_key(KEY_SPACE),
        GWBinding.from_joy_button(JOY_BUTTON_A),
    ], "Combat")
```

### Paso 3 — Crear jugadores y asignar dispositivos

```gdscript
    var p0 = GWInputManager.create_player(0, "Player 1")
    p0.accepts_keyboard = true

    var p1 = GWInputManager.create_player(1, "Player 2")
    p1.accepts_keyboard = false
    if Input.get_connected_joypads().size() > 0:
        p1.assign_gamepad(Input.get_connected_joypads()[0])

    GWInputManager.load_all_profiles()   # cargar bindings guardados
```

### Paso 4 — Usar en gameplay

```gdscript
# En CharacterBody2D / CharacterBody3D

func _physics_process(delta):
    var dir = GWInputManager.get_vector(
        "move_left", "move_right", "move_up", "move_down", player_id
    )
    velocity = dir * speed
    move_and_slide()

func _input(event):
    if GWInputManager.is_action_just_pressed("jump", event, player_id):
        jump()
```

### Paso 5 — Agregar UI de remapeo

```gdscript
# En tu menú de pausa o settings

func _ready():
    var binding_ui = GWBindingUI.new()
    binding_ui.player_id = 0
    $SettingsPanel.add_child(binding_ui)
```

---

## 13. Decisiones de diseño y trade-offs

### ¿Por qué no usar el InputMap nativo como backend?

Se evaluó usar `InputMap.add_action()` y `InputMap.action_add_event()` para mantener compatibilidad con `Input.is_action_pressed()` nativo. Se descartó porque:

- El InputMap es global — no hay namespace por jugador.
- Añadir acciones por jugador con prefijos (ej. `"p0_jump"`, `"p1_jump"`) funciona, pero escala mal y contamina el InputMap del proyecto.
- Manejar la evaluación directamente sobre `Input.get_joy_axis()` e `Input.is_key_pressed()` da más control sobre deadzone y axis_direction.

### ¿Por qué `RefCounted` y no `Node` para GWPlayer?

`GWPlayer` no necesita estar en el SceneTree. Usar `RefCounted` elimina la necesidad de `add_child()` y evita que el jugador dependa del ciclo de vida de un nodo padre. El garbage collector de GDScript limpia la referencia automáticamente cuando se llama `remove_player()`.

### ¿Por qué la UI sin `.tscn`?

Eliminar la dependencia de archivos `.tscn` hace el plugin más portable y fácil de integrar: no hay rutas de recursos que actualizar, no hay conflictos de merge en Git con archivos binarios de escena, y el desarrollador puede subclasear `GWBindingUI` y sobreescribir `_build_layout()` para tematizarla.

### Limitaciones conocidas en v1.0

- **No hay detección de tipo de controlador** — todos los gamepads usan los mismos íconos/labels. Para íconos de PlayStation vs Xbox habría que leer el `device_name` y hacer matching.
- **No hay resolución automática de conflictos** — si asignas una tecla que ya existe en otra acción, ambas la tendrán. La detección está implementada (`find_conflicts()`), pero la UI no la expone todavía.
- **No hay soporte de Hold/Tap/Double-tap** — todos los bindings son "presionado o no". Las interacciones de tiempo (hold 500ms = acción diferente) son una feature de v1.1.

---

*Documentación generada para GodotWired v1.0.0-dev — SliceSoft*