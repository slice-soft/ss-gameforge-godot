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

<!-- ADDONS-TABLE:START -->
| Addon | Version | Download |
|-------|---------|----------|
| `ss-gameforge-dialogue` | [v1.1.0](https://github.com/slice-soft/ss-gameforge-godot/releases/tag/ss-gameforge-dialogue-v1.1.0) | [`ss-gameforge-dialogue-v1.1.0.zip`](https://github.com/slice-soft/ss-gameforge-godot/releases/download/ss-gameforge-dialogue-v1.1.0/ss-gameforge-dialogue-v1.1.0.zip) |
| `ss-gameforge-singleton` | [v1.0.1](https://github.com/slice-soft/ss-gameforge-godot/releases/tag/ss-gameforge-singleton-v1.0.1) | [`ss-gameforge-singleton-v1.0.1.zip`](https://github.com/slice-soft/ss-gameforge-godot/releases/download/ss-gameforge-singleton-v1.0.1/ss-gameforge-singleton-v1.0.1.zip) |
| `ss-gameforge-state-machine` | [v1.0.1](https://github.com/slice-soft/ss-gameforge-godot/releases/tag/ss-gameforge-state-machine-v1.0.1) | [`ss-gameforge-state-machine-v1.0.1.zip`](https://github.com/slice-soft/ss-gameforge-godot/releases/download/ss-gameforge-state-machine-v1.0.1/ss-gameforge-state-machine-v1.0.1.zip) |
| `ss-gameforge-toast` | [v1.0.1](https://github.com/slice-soft/ss-gameforge-godot/releases/tag/ss-gameforge-toast-v1.0.1) | [`ss-gameforge-toast-v1.0.1.zip`](https://github.com/slice-soft/ss-gameforge-godot/releases/download/ss-gameforge-toast-v1.0.1/ss-gameforge-toast-v1.0.1.zip) |
<!-- ADDONS-TABLE:END -->

## Módulos incluidos

### SingletonNode
Acceso seguro a singletons tipo servicio.

```gdscript
SaveService.i.save_game()
BossFightDirector.i.next_phase()
```

### EventBus
Comunicación desacoplada entre sistemas sin referencias fuertes.

```gdscript
EventBus.on(self, {
  "player_died": "_on_player_died",
  "health_changed": "_on_health_changed",
})

EventBus.emit("player_died", player_id)
```

### State Machine
Utilidades FSM orientadas a gameplay para personajes, enemigos, UI y flujos.

### Toast UI
Helpers de feedback visual con cola, animaciones y soporte de temas.

```gdscript
Toast.show("Guardado")
Toast.warn("Sin conexión")
Toast.error("Error al cargar")
```

### Dialogue Manager
Orquestación de diálogos desacoplada de la presentación.

```gdscript
Dialogue.play("intro")
Dialogue.choose(0)
```

## Documentación

- [English: SingletonNode](docs/en/singleton-node.md)
- [English: Toast](docs/en/toast.md)
- [Español: SingletonNode](docs/es/singleton-node.md)
- [Español: Toast](docs/es/toast.md)

## Primeros pasos

1. Copia el addon de este repositorio dentro de `res://addons/` en tu proyecto Godot.
2. Activa el plugin desde `Project Settings -> Plugins`.
3. Instala los autoloads requeridos desde el panel del plugin si el módulo lo necesita.

> Nota de naming: la identidad pública del repositorio y el path interno del
> addon en Godot ahora quedan alineados como `ss-gameforge-godot` y
> `addons/ss-gameforge-godot/`. Usa ese path al copiar el addon a proyectos
> reales.

## Roadmap

- [ ] Wizard de autoloads
- [ ] Generadores de escenas y features
- [ ] Importadores de diálogos (JSON / CSV)
- [ ] Documentación ampliada por módulo
- [ ] Escenas demo

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
