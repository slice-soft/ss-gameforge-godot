class_name DialogueTheme extends Resource

@export_group("Box")
@export var background_color: Color = Color(0.082, 0.082, 0.118, 0.921)
@export var border_color: Color = Color(0.255, 0.255, 0.353, 1.0)
@export var border_width: int = 2
@export var corner_radius: float = 10.0
## Inner padding: x = horizontal, y = vertical.
@export var padding: Vector2 = Vector2(16.0, 12.0)

@export_group("Text")
@export var font_color: Color = Color.WHITE
@export var font_size: int = 16
## Leave empty to use the project's default theme font.
@export var font: Font

@export_group("Position")
## Distance from the screen edges. The dialogue box is anchored to the bottom by default.
@export var position_margin: Vector2 = Vector2(24.0, 24.0)
