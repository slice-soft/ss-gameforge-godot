extends Resource
class_name ToastTheme

# Theme resource that defines default visuals for all toast types.
@export var duration := 2.0
@export var font_size := 14
@export var icon_size := 18.0
@export var corner_radius := 10.0
@export var padding := 10.0
@export var position_margin := Vector2(16, 16)
@export var position := ToastConstants.ToastPosition.BOTTOM_CENTER

# Per-style visual configuration.
@export_group("Info")
@export var info_background_color := Color("#2D9CDB")
@export var info_text_color := Color.WHITE
@export var info_icon: Texture2D = load("res://addons/ss-gameforge-godot/ui/toast/assets/icons/info.svg")

@export_group("Success")
@export var success_background_color := Color("#27AE60")
@export var success_text_color := Color.WHITE
@export var success_icon: Texture2D = load("res://addons/ss-gameforge-godot/ui/toast/assets/icons/success.svg")

@export_group("Danger")
@export var danger_background_color := Color("#EB5757")
@export var danger_text_color := Color.WHITE
@export var danger_icon: Texture2D = load("res://addons/ss-gameforge-godot/ui/toast/assets/icons/danger.svg")

@export_group("Custom")
@export var custom_background_color := Color("#333333")
@export var custom_text_color := Color.WHITE
@export var custom_icon: Texture2D

@export_group("Loader")
@export var loader_background_color := Color("#333333")
@export var loader_text_color := Color.WHITE
@export var loader_icon: Texture2D = load("res://addons/ss-gameforge-godot/ui/toast/assets/icons/loader.svg")
@export var loader_spin_speed := 1.5
