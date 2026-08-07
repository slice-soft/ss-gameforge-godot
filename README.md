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

## Addons

- `ss-gameforge-dialogue`
- `ss-gameforge-singleton`
- `ss-gameforge-state-machine`
- `ss-gameforge-toast`
- `ss-gameforge-wired`

## Included Modules

### SingletonNode
Safe singleton access for service-like nodes.

```gdscript
SaveService.i.save_game()
BossFightDirector.i.next_phase()
```

### State Machine
Gameplay-oriented FSM utilities for characters, enemies, UI, and flow control.
States are child nodes, and the machine forwards only the callbacks each one defines.

```gdscript
state_machine.change_to("Running")
```

### Toast UI
Quick feedback helpers with queueing, animations, and theme support.

```gdscript
ToastService.i.info("Saved")
ToastService.i.success("Level complete")
ToastService.i.danger("Load error")
```

### Dialogue Manager
Dialogue orchestration decoupled from presentation. The lines live in a
`DialogueResource`, so writing content never means touching the view.

```gdscript
dialogue_view.play(resource)
```

> Early stage: lines play in sequence, with a typewriter reveal and BBCode
> support. Branching and choices are not implemented yet.

### Wired
Action-based input: gameplay asks for `"jump"`, never for `KEY_SPACE`. Supports
per-player bindings, runtime rebinding, local co-op and hot-plugged gamepads.

```gdscript
if GWInputManager.i.is_action_just_pressed("jump"):
	jump()
```

## Planned Modules

Not shipped yet. Listed so the direction is visible — do not code against these.

### EventBus
Decoupled communication between systems without hard references.

```gdscript
EventBus.on(self, {
  "player_died": "_on_player_died",
  "health_changed": "_on_health_changed",
})

EventBus.emit("player_died", player_id)
```

## Documentation

Every addon has a reference page in both languages:

| Addon | English | Español |
|---|---|---|
| `ss-gameforge-singleton` | [SingletonNode](docs/en/singleton-node.md) | [SingletonNode](docs/es/singleton-node.md) |
| `ss-gameforge-toast` | [Toast](docs/en/toast.md) | [Toast](docs/es/toast.md) |
| `ss-gameforge-dialogue` | [Dialogue](docs/en/dialogue.md) | [Dialogue](docs/es/dialogue.md) |
| `ss-gameforge-state-machine` | [State Machine](docs/en/state-machine.md) | [State Machine](docs/es/state-machine.md) |
| `ss-gameforge-wired` | [Wired](docs/en/wired.md) | [Wired](docs/es/wired.md) |

## Getting Started

1. Copy the addon from this repository into your Godot project under `res://addons/`.
2. Enable the plugin from `Project Settings -> Plugins`.
3. Install the required autoloads from the plugin panel if the module needs them.

> Each module is its own addon directory — `addons/ss-gameforge-toast/`,
> `addons/ss-gameforge-wired/`, and so on. Copy only the ones you need, plus
> `ss-gameforge-singleton`: Toast and Wired both extend `SingletonNode`.

## Roadmap

- [ ] Autoload setup wizard
- [ ] Scene and feature generators
- [ ] Dialogue importers (JSON / CSV)
- [ ] Expanded module documentation
- [ ] Demo scenes

## Release Flow

- Feature work lands in `release` through squash merges.
- Pushes to `release` create prereleases such as `ss-gameforge-toast-v1.2.0-rc.1`.
- After QA, open the promotion PR from `release` to `main` and merge it with **rebase**,
  which keeps one commit per feature on `main`.
- Stable releases are created only after the `release -> main` promotion is merged.
- The addons list in the README, landing page, and docs are updated manually from stable releases on `main`.

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
