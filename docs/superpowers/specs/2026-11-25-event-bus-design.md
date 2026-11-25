# ss-gameforge-event-bus: design

Issue: #47 · Status: approved 2026-11-25

## Intent

Let a game's systems (player, UI, audio, ...) talk without holding references to each
other. Every game has its own mechanics, so the addon does not ship a fixed event
catalog. Each game declares its own **typed signals** on its own bus.

## Goals

- `EventBus` base class. A game creates `class_name GameEvents extends EventBus` and
  declares `signal player_died(player_id: int)` and so on.
- Single instance through `SingletonNode`, accessed as `GameEvents.i`, the same pattern
  as `ToastService` and `GWInputManager`. It is created at runtime with
  `SingletonNode.ensure_for(...)`, with no autoload or project setting.
- `listen(owner: Node, bindings: Dictionary)` (keys are `Signal`, values are `Callable`)
  connects them all. It disconnects them when `owner` leaves the scene tree
  (`tree_exiting`), not only when it is freed, so pooled or reparented nodes stop
  receiving events. Returns nothing. Calling it twice for the same owner/signal pair
  must not double-connect.
- `unlisten(owner: Node)` disconnects everything that `owner` registered, for manual
  control.
- `trace: bool` (default `false`). When true **and** `OS.is_debug_build()`, every
  emission of a signal declared by the subclass is printed with its name and arguments.
- `plugin.cfg` declares `dependencies=["ss-gameforge-singleton"]`, the first
  machine-readable dependency key, for the future addon-download tool.

## Non-goals

- String-named events (`emit("player_died")`). This approach was rejected in favor of
  typed signals.
- Queues, priorities, deferred delivery, persistence, networking.
- An editor dock or visual event inspector.

## Approaches considered

- **A. String-named events** (the original README sketch): flexible, but typos fail
  silently and arguments are not validated.
- **B. Typed signals on a per-game subclass** (**chosen**): Godot validates and
  autocompletes, and each game models its own mechanics. Costs one small subclass per game.
- **C. String events plus optional `define()` validation**: middle ground. Rejected:
  B already gives the validation natively.

## Constraints

- Godot 4.5+ (the dev project targets 4.7). GDScript only.
- Must follow the existing addon layout: `addons/ss-gameforge-event-bus/` with
  `plugin.cfg` (release-please version markers), `plugin.gd`, `CHANGELOG.md`, and core
  scripts.
- Registered in `release-please-config.json`, `release-please-config.rc.json` and both
  manifests, starting at `0.1.0`. Add it to the README addons table and remove it from
  "Planned Modules".
- Docs: `docs/en/event-bus.md` and `docs/es/event-bus.md`.

## Deliverables

1. The addon (base class, plugin files).
2. Release-please registration.
3. Docs en/es plus README updates (en/es).
4. Showcase demo: a `ShowcaseEvents` bus. The states emit `pokemon_loaded` /
   `pokemon_load_failed`, and a listener shows the toasts, instead of the states
   calling `ToastService` directly.
5. Headless tests (local harness under `tests/`, never committed) covering emit,
   `listen`, auto-disconnect on tree exit, `unlisten`, no double connect, and trace.

## Left to the builder

- Internal bookkeeping structure for `listen` (per-owner registry).
- Exact trace output format (one line per emission, prefixed with `[EventBus]`).
- How trace hooks the subclass signals: iterate the script's own signal list in
  `_ready()` and connect a variadic logger. GDScript variadic functions need Godot 4.5.
