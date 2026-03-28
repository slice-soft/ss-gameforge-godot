extends Object
class_name ToastVisualApplier

# Aggregated result of applying visual styles to a toast view.
class VisualResult extends RefCounted:
	var base_position: ToastConstants.ToastPosition
	var base_margin: Vector2
	var icon_custom_node: Node
	var icon_spin_target: CanvasItem
	var icon_spin_enabled: bool
	var icon_spin_speed: float
	var toast_duration: float
	
	func _init() -> void:
		base_position = ToastConstants.ToastPosition.BOTTOM_CENTER
		base_margin = Vector2(16, 16)
		icon_spin_enabled = false
		icon_spin_speed = 1.5
		toast_duration = 2.0

# Applies panel, text, and icon styles, and returns values needed by the view.
static func apply_visual_styles(
	panel_container: PanelContainer,
	label: RichTextLabel,
	icon_rect: TextureRect,
	style_data: Dictionary,
	current_icon_custom: Node
) -> VisualResult:
	var result := VisualResult.new()
	
	var bg_color: Color = style_data.get("background_color", Color("#333333"))
	var text_color: Color = style_data.get("text_color", Color.WHITE)
	var icon_texture: Texture2D = style_data.get("icon", null)
	var icon_color: Color = style_data.get("icon_color", Color.WHITE)
	var icon_scene = style_data.get("icon_scene", null)
	
	result.icon_spin_enabled = bool(style_data.get("icon_spin", false))
	result.icon_spin_speed = float(style_data.get("icon_spin_speed", 1.5))
	result.toast_duration = float(style_data.get("duration", 2.0))
	
	var font_size: int = int(style_data.get("font_size", 14))
	var icon_size: float = float(style_data.get("icon_size", 18.0))
	var padding: float = float(style_data.get("padding", 10.0))
	var corner_radius: float = float(style_data.get("corner_radius", 10.0))
	
	result.base_position = int(style_data.get("position", ToastConstants.ToastPosition.BOTTOM_CENTER))
	result.base_margin = style_data.get("position_margin", Vector2(16, 16))
	
	_apply_background_style(panel_container, bg_color, padding, corner_radius)
	_apply_text_style(label, text_color, font_size)
	
	var icon_result := ToastIconManager.apply_icon_style(
		icon_rect,
		icon_scene,
		icon_texture,
		icon_size,
		icon_color,
		current_icon_custom
	)
	
	result.icon_custom_node = icon_result.custom_node
	result.icon_spin_target = icon_result.spin_target
	
	return result

# Builds and applies the panel's StyleBox with padding and corner radius.
static func _apply_background_style(
	panel_container: PanelContainer,
	bg_color: Color,
	padding: float,
	corner_radius: float
) -> void:
	var style_box := StyleBoxFlat.new()
	style_box.bg_color = bg_color
	style_box.set_corner_radius_all(int(corner_radius))
	style_box.content_margin_left = padding
	style_box.content_margin_right = padding
	style_box.content_margin_top = padding
	style_box.content_margin_bottom = padding
	panel_container.add_theme_stylebox_override("panel", style_box)

# Updates label color and font size.
static func _apply_text_style(
	label: RichTextLabel,
	text_color: Color,
	font_size: int
) -> void:
	label.add_theme_color_override("default_color", text_color)
	label.add_theme_font_size_override("normal_font_size", font_size)