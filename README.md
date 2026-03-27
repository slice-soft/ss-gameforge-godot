<img src="icon.svg" width="128" height="128">

# GameForge for Godot

[Versión en Español](README.es.md)

`ss-gameforge-godot` is Slice Soft's reusable toolkit for **Godot Engine 4.x**.
It packages practical gameplay and architecture building blocks that can move
from prototype to production without forcing a rigid project structure.

[![Release](https://img.shields.io/github/v/release/slice-soft/ss-gameforge-godot)](https://github.com/slice-soft/ss-gameforge-godot/releases)
![Godot](https://img.shields.io/badge/Godot-4.x-478CBF?logo=godotengine&logoColor=white)
![License](https://img.shields.io/badge/License-MIT-green)
![Made in Colombia](https://img.shields.io/badge/Made%20in-Colombia-FCD116?labelColor=003893)
[![Sponsor](https://img.shields.io/badge/Sponsor-SliceSoft-003893?logo=github-sponsors&logoColor=green)](https://github.com/sponsors/slice-soft)

## Philosophy

GameForge is built around a few simple principles:

- **Opt-in over lock-in**: use only the modules your game actually needs
- **Readable over magical**: the implementation should stay easy to inspect and extend
- **Reusable over disposable**: carry the same foundation across multiple Godot projects
- **Practical over ceremonial**: solve common problems with small, direct APIs

## Included Modules

### SingletonNode
Safe singleton access for service-like nodes.

```gdscript
SaveService.i.save_game()
BossFightDirector.i.next_phase()
```

### EventBus
Decoupled communication between systems without hard references.

```gdscript
EventBus.on(self, {
  "player_died": "_on_player_died",
  "health_changed": "_on_health_changed",
})

EventBus.emit("player_died", player_id)
```

### State Machine
Gameplay-oriented FSM utilities for characters, enemies, UI, and flow control.

### Toast UI
Quick feedback helpers with queueing, animations, and theme support.

```gdscript
Toast.show("Saved")
Toast.warn("No connection")
Toast.error("Load error")
```

### Dialogue Manager
Dialogue orchestration decoupled from presentation.

```gdscript
Dialogue.play("intro")
Dialogue.choose(0)
```

## Documentation

- [English: SingletonNode](docs/en/singleton-node.md)
- [English: Toast](docs/en/toast.md)
- [Español: SingletonNode](docs/es/singleton-node.md)
- [Español: Toast](docs/es/toast.md)

## Getting Started

1. Copy the addon from this repository into your Godot project under `res://addons/`.
2. Enable the plugin from `Project Settings -> Plugins`.
3. Install the required autoloads from the plugin panel if the module needs them.

> Naming note: the public repository and the internal Godot addon path are now
> aligned as `ss-gameforge-godot` and `addons/ss-gameforge-godot/`. Use that
> path when copying the addon into real projects.

## Roadmap

- [ ] Autoload setup wizard
- [ ] Scene and feature generators
- [ ] Dialogue importers (JSON / CSV)
- [ ] Expanded module documentation
- [ ] Demo scenes

## Contributing

See [CONTRIBUTING.md](./CONTRIBUTING.md) for setup and repository-specific
rules. The shared workflow, commit conventions, and community standards live in
[ss-community](https://github.com/slice-soft/ss-community/blob/main/CONTRIBUTING.md).

## Community

| Document | |
|---|---|
| [CONTRIBUTING.md](https://github.com/slice-soft/ss-community/blob/main/CONTRIBUTING.md) | Workflow, commit conventions, and PR guidelines |
| [GOVERNANCE.md](https://github.com/slice-soft/ss-community/blob/main/GOVERNANCE.md) | Decision-making and project roles |
| [CODE_OF_CONDUCT.md](https://github.com/slice-soft/ss-community/blob/main/CODE_OF_CONDUCT.md) | Community standards |
| [VERSIONING.md](https://github.com/slice-soft/ss-community/blob/main/VERSIONING.md) | SemVer policy and breaking changes |
| [SECURITY.md](https://github.com/slice-soft/ss-community/blob/main/SECURITY.md) | How to report vulnerabilities |
| [MAINTAINERS.md](https://github.com/slice-soft/ss-community/blob/main/MAINTAINERS.md) | Active maintainers |

## License

MIT. See [LICENSE](./LICENSE).
