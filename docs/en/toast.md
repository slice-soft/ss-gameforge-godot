# Toast

`ToastService` shows short, non-blocking notifications. It queues messages, can
stack several on screen at once, and ships with five styles and nine anchor
positions.

> Requires `ss-gameforge-singleton`: `ToastService` extends `SingletonNode`.

## When to use

- You want quick feedback that does not interrupt play ("Game saved", "No connection").
- You need progress feedback that stays on screen until a task finishes.
- Several messages may fire at once and you do not want them overlapping.

## Key API

- `ToastService.i` returns the active instance.
- `show(text, style, overrides)` enqueues a toast with an explicit style.
- `info(text, overrides)`, `success(text, overrides)`, `danger(text, overrides)`,
  `custom(text, overrides)` are shorthands for the standard styles.
- `loader(text, overrides)` shows a toast with a spinning icon.
- `loader_task(text, task, overrides)` keeps a loader open until the `task` signal fires.
- `ToastConstants.ToastStyle`: `INFO`, `SUCCESS`, `DANGER`, `CUSTOM`, `LOADER`.
- `ToastConstants.ToastPosition`: the nine anchors, from `TOP_LEFT` to `BOTTOM_RIGHT`.
- `ToastTheme` is the resource holding every default.

## Usage: creating the service

`ToastService` is a `SingletonNode`, so it must exist before the first call.
Create it once in your main scene:

```gdscript
func _enter_tree() -> void:
	SingletonNode.ensure_for(ToastService, get_tree().root, "ToastService")
```

## Usage: showing a toast

```gdscript
ToastService.i.info("Game saved")
ToastService.i.success("Level complete")
ToastService.i.danger("Connection lost")
```

`custom()` uses the neutral style from the theme, meant to be paired with overrides.

## Usage: a loader tied to a task

`loader_task()` takes any `Signal` and keeps the toast open until it fires. The
toast has no duration of its own, so the signal is what dismisses it:

```gdscript
var timer := get_tree().create_timer(0.8)
ToastService.i.loader_task("Loading...", timer.timeout)
await timer.timeout
```

Any signal works, which is what makes it useful for real work:

```gdscript
var request := HTTPRequest.new()
add_child(request)
ToastService.i.loader_task("Downloading...", request.request_completed)
request.request(url)
```

> Use `loader()` instead when you want a spinner that dismisses on the normal
> duration rather than waiting on a signal.

## Usage: overriding a single toast

The third argument overrides the theme for that one toast. These are the keys
the resolver understands:

| Key | Key | Key |
|---|---|---|
| `background_color` | `text_color` | `duration` |
| `icon` | `icon_color` | `icon_scene` |
| `icon_spin` | `icon_spin_speed` | `icon_size` |
| `font_size` | `padding` | `corner_radius` |
| `position` | `position_margin` | |

```gdscript
ToastService.i.info("Achievement unlocked", {
	"duration": 4.0,
	"position": ToastConstants.ToastPosition.TOP_RIGHT,
	"corner_radius": 4.0,
})
```

## Usage: theming every toast

Create a `ToastTheme` resource, set the colors, icons and timings, and assign it
to the service. When no theme is assigned, the built-in
`res://addons/ss-gameforge-toast/themes/toast_default.tres` is used.

```gdscript
func _enter_tree() -> void:
	SingletonNode.ensure_for(ToastService, get_tree().root, "ToastService")
	ToastService.i.theme = preload("res://ui/my_toast_theme.tres")
```

`ToastTheme` exposes global defaults (`duration`, `font_size`, `icon_size`,
`corner_radius`, `padding`, `position`, `position_margin`) plus a colour, text
colour and icon per style.

## Usage: queueing and stacking

These properties are exported on the service, so you can also set them in the
inspector:

```gdscript
ToastService.i.stack_toasts = true   # false shows one at a time
ToastService.i.max_visible = 4       # simultaneous toasts when stacking
ToastService.i.stack_spacing = 8.0   # pixels between stacked toasts
ToastService.i.max_queue = 50        # messages held before dropping
```

> With `stack_toasts = false` the service waits for the active toast to finish
> before showing the next one in the queue.
