class_name DialogueTheme extends Resource

@export_group("Box")
## Box fill. With background_texture set, it tints the texture instead.
@export var background_color: Color = Color(0.082, 0.082, 0.118, 0.921)
@export var border_color: Color = Color(0.255, 0.255, 0.353, 1.0)
@export var border_width: int = 2
@export var corner_radius: float = 10.0
## Inner padding: x = horizontal, y = vertical.
@export var padding: Vector2 = Vector2(16.0, 12.0)
## Optional 9-slice texture for the box. When set, it replaces the flat box and
## border_color, border_width and corner_radius are ignored.
@export var background_texture: Texture2D
## Size of the texture's non-stretching borders, in pixels.
@export var texture_patch_margin: int = 8

@export_group("Text")
@export var font_color: Color = Color.WHITE
@export var font_size: int = 16
## Leave empty to use the project's default theme font.
@export var font: Font

@export_group("Position")
## Distance from the left, right and bottom edges of the DialogueView (the whole
## screen by default). The box spans the width and grows upward to fit its text.
@export var position_margin: Vector2 = Vector2(24.0, 24.0)
