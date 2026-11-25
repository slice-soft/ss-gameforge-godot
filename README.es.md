<img src="icon.svg" width="128" height="128">

# GameForge para Godot

[English Version](README.md)

`ss-gameforge-godot` es el toolkit reutilizable de Slice Soft para
**Godot Engine 4.x**. Reúne bloques prácticos de gameplay y arquitectura para
acelerar proyectos sin imponer una estructura rígida.

[![Release](https://img.shields.io/github/v/release/slice-soft/ss-gameforge-godot)](https://github.com/slice-soft/ss-gameforge-godot/releases)
![Godot](https://img.shields.io/badge/Godot-4.x-478CBF?logo=godotengine&logoColor=white)
![License](https://img.shields.io/badge/License-MIT-green)
![Made in Colombia](https://img.shields.io/badge/Made%20in-Colombia-FCD116?labelColor=003893)
[![Sponsor](https://img.shields.io/badge/Sponsor-SliceSoft-003893?logo=github-sponsors&logoColor=green)](https://github.com/sponsors/slice-soft)

## Filosofía

GameForge sigue una línea simple:

- **Opt-in sobre lock-in**: usa solo los módulos que tu juego necesita
- **Legible sobre mágico**: el código debe poder inspeccionarse y extenderse con facilidad
- **Reutilizable sobre desechable**: la base debe servir en varios proyectos Godot
- **Práctico sobre ceremonial**: resolver problemas comunes con APIs pequeñas y directas

## Addons

- `ss-gameforge-dialogue`
- `ss-gameforge-event-bus`
- `ss-gameforge-singleton`
- `ss-gameforge-state-machine`
- `ss-gameforge-toast`
- `ss-gameforge-wired`

## Módulos incluidos

### SingletonNode
Acceso seguro a singletons tipo servicio.

```gdscript
SaveService.i.save_game()
BossFightDirector.i.next_phase()
```

### State Machine
Utilidades FSM orientadas a gameplay para personajes, enemigos, UI y flujos.
Los estados son nodos hijos, y la máquina solo reenvía los callbacks que cada uno define.

```gdscript
state_machine.change_to("Running")
```

### Toast UI
Helpers de feedback visual con cola, animaciones y soporte de temas.

```gdscript
ToastService.i.info("Guardado")
ToastService.i.success("Nivel completado")
ToastService.i.danger("Error al cargar")
```

### Dialogue Manager
Orquestación de diálogos desacoplada de la presentación. Las líneas viven en un
`DialogueResource`, así que escribir contenido nunca implica tocar la vista.

```gdscript
dialogue_view.play(resource)
```

> Etapa temprana: las líneas se reproducen en secuencia, con efecto máquina de
> escribir y soporte de BBCode. Las ramificaciones y opciones todavía no están.

### Wired
Entrada basada en acciones: el gameplay pide `"jump"`, nunca `KEY_SPACE`. Soporta
bindings por jugador, remapeo en runtime, cooperativo local y gamepads en caliente.

```gdscript
if GWInputManager.i.is_action_just_pressed("jump"):
	saltar()
```

### Event Bus
Eventos tipados por juego: cada juego extiende `EventBus` con sus propias señales, y
los listeners se desconectan solos cuando salen del árbol de escena.

```gdscript
GameEvents.i.player_died.emit(player_id)
GameEvents.i.listen(self, {GameEvents.i.player_died: _on_player_died})
```

## Documentación

Cada addon tiene su página de referencia en ambos idiomas:

| Addon | Español | English |
|---|---|---|
| `ss-gameforge-singleton` | [SingletonNode](docs/es/singleton-node.md) | [SingletonNode](docs/en/singleton-node.md) |
| `ss-gameforge-toast` | [Toast](docs/es/toast.md) | [Toast](docs/en/toast.md) |
| `ss-gameforge-dialogue` | [Dialogue](docs/es/dialogue.md) | [Dialogue](docs/en/dialogue.md) |
| `ss-gameforge-state-machine` | [State Machine](docs/es/state-machine.md) | [State Machine](docs/en/state-machine.md) |
| `ss-gameforge-wired` | [Wired](docs/es/wired.md) | [Wired](docs/en/wired.md) |
| `ss-gameforge-event-bus` | [Event Bus](docs/es/event-bus.md) | [Event Bus](docs/en/event-bus.md) |

## Primeros pasos

1. Copia el addon de este repositorio dentro de `res://addons/` en tu proyecto Godot.
2. Activa el plugin desde `Project Settings -> Plugins`.
3. Instala los autoloads requeridos desde el panel del plugin si el módulo lo necesita.

> Cada módulo es su propio directorio de addon — `addons/ss-gameforge-toast/`,
> `addons/ss-gameforge-wired/`, y así. Copia solo los que necesites, más
> `ss-gameforge-singleton`: Toast, Wired y Event Bus extienden `SingletonNode`.

## Roadmap

- [ ] Wizard de autoloads
- [ ] Generadores de escenas y features
- [ ] Importadores de diálogos (JSON / CSV)
- [ ] Documentación ampliada por módulo
- [ ] Escenas demo

## Flujo de release

- Los features (`feature/<issue>-desc`, `fix/<issue>-desc`, ...) llegan a `release` mediante
  squash merge. Los títulos de PR siguen Conventional Commits y terminan en `(#<issue>)`.
- release-please abre un PR rc en `release`. Al mergearlo se publican prereleases como
  `ss-gameforge-toast-v1.2.0-rc.1`.
- Después de QA, abre el PR de promoción de `release` a `main` y mergéalo con
  **merge commit** (el único método que `main` permite). Así `release` sigue siendo
  ancestro de `main` y las ramas no divergen.
- Luego release-please abre el PR de release estable en `main`. Al mergearlo se publican
  los releases estables y el pipeline abre los PRs de actualización de versiones en los
  repos de la landing y la documentación.
- Por último, haz fast-forward de `release` a `main` para que el siguiente ciclo parta
  del estado estable.

## Contribuir

Consulta [CONTRIBUTING.md](./CONTRIBUTING.md) para setup y reglas específicas
de este repositorio. El flujo general, las convenciones de commit y las normas
de comunidad viven en
[ss-community](https://github.com/slice-soft/ss-community/blob/main/CONTRIBUTING.md).

## Comunidad

| Documento | |
|---|---|
| [CONTRIBUTING.md](https://github.com/slice-soft/ss-community/blob/main/CONTRIBUTING.md) | Flujo de trabajo, commits y PRs |
| [GOVERNANCE.md](https://github.com/slice-soft/ss-community/blob/main/GOVERNANCE.md) | Toma de decisiones y roles |
| [CODE_OF_CONDUCT.md](https://github.com/slice-soft/ss-community/blob/main/CODE_OF_CONDUCT.md) | Estándares de comunidad |
| [VERSIONING.md](https://github.com/slice-soft/ss-community/blob/main/VERSIONING.md) | Política SemVer y breaking changes |
| [SECURITY.md](https://github.com/slice-soft/ss-community/blob/main/SECURITY.md) | Reporte de vulnerabilidades |
| [MAINTAINERS.md](https://github.com/slice-soft/ss-community/blob/main/MAINTAINERS.md) | Maintainers activos |

## Licencia

MIT. Consulta [LICENSE](./LICENSE).
