extends Object
class_name ToastIconManager

# Result object describing the icon node and spin target.
class IconResult extends RefCounted:
	var custom_node: Node
	var spin_target: CanvasItem
	
	func _init(p_custom: Node = null, p_spin: CanvasItem = null) -> void:
		custom_node = p_custom
		spin_target = p_spin

# Applies icon styling and returns what should spin.
static func apply_icon_style(
	icon_rect: TextureRect,
	icon_scene,
	icon_texture: Texture2D,
	icon_size: float,
	icon_color: Color,
	current_custom_node: Node
) -> IconResult:
	var result := IconResult.new()
	
	if icon_scene is PackedScene:
		result = _apply_scene_icon(icon_rect, icon_scene, icon_size, icon_color, current_custom_node)
	elif icon_texture != null:
		result = _apply_texture_icon(icon_rect, icon_texture, icon_size, icon_color, current_custom_node)
	else:
		result = _apply_no_icon(icon_rect, current_custom_node)
	
	return result

# Instantiates a custom icon scene and places it inside the texture rect.
static func _apply_scene_icon(
	icon_rect: TextureRect,
	icon_scene: PackedScene,
	icon_size: float,
	icon_color: Color,
	current_custom: Node
) -> IconResult:
	var result := IconResult.new()
	result.custom_node = _clear_custom_node(current_custom)
	
	var node := icon_scene.instantiate()
	result.custom_node = node
	
	icon_rect.texture = null
	icon_rect.visible = true
	icon_rect.custom_minimum_size = Vector2(icon_size, icon_size)
	icon_rect.add_child(node)
	
	_configure_scene_node(node, icon_size, icon_color)
	
	if node is CanvasItem:
		result.spin_target = node as CanvasItem
	else:
		result.spin_target = icon_rect
	
	return result

# Normalizes layout and color for custom scene icons.
static func _configure_scene_node(node: Node, icon_size: float, icon_color: Color) -> void:
	if node is Control:
		var control := node as Control
		control.anchor_left = 0.0
		control.anchor_top = 0.0
		control.anchor_right = 1.0
		control.anchor_bottom = 1.0
		control.offset_left = 0.0
		control.offset_top = 0.0
		control.offset_right = 0.0
		control.offset_bottom = 0.0
	elif node is Node2D:
		var node_2d := node as Node2D
		node_2d.position = Vector2(icon_size / 2.0, icon_size / 2.0)
	
	if node is CanvasItem:
		(node as CanvasItem).modulate = icon_color

# Applies a direct texture icon.
static func _apply_texture_icon(
	icon_rect: TextureRect,
	icon_texture: Texture2D,
	icon_size: float,
	icon_color: Color,
	current_custom: Node
) -> IconResult:
	var result := IconResult.new()
	result.custom_node = _clear_custom_node(current_custom)
	
	icon_rect.texture = icon_texture
	icon_rect.modulate = icon_color
	icon_rect.custom_minimum_size = Vector2(icon_size, icon_size)
	icon_rect.visible = true
	result.spin_target = icon_rect
	
	return result

# Clears the icon when no texture or scene is provided.
static func _apply_no_icon(
	icon_rect: TextureRect,
	current_custom: Node
) -> IconResult:
	var result := IconResult.new()
	result.custom_node = _clear_custom_node(current_custom)
	
	icon_rect.texture = null
	icon_rect.visible = false
	result.spin_target = null
	
	return result

# Frees any previous custom icon node.
static func _clear_custom_node(custom: Node) -> Node:
	if custom != null and is_instance_valid(custom):
		custom.queue_free()
	return null