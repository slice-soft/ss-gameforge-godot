extends Object
class_name ToastPositionCalculator

# Computes and applies anchors/offsets for the requested position.
static func apply_position(
	panel: Control, 
	position: ToastConstants.ToastPosition, 
	margin: Vector2,
	stack_offset: Vector2 = Vector2.ZERO
) -> void:
	var size := panel.size
	
	match position:
		ToastConstants.ToastPosition.TOP_LEFT:
			_set_anchors_and_offsets(panel, 0.0, 0.0, margin.x + stack_offset.x, margin.y + stack_offset.y, size)
		ToastConstants.ToastPosition.TOP_CENTER:
			_set_anchors_and_offsets(panel, 0.5, 0.0, -size.x / 2.0 + stack_offset.x, margin.y + stack_offset.y, size)
		ToastConstants.ToastPosition.TOP_RIGHT:
			_set_anchors_and_offsets(panel, 1.0, 0.0, -size.x - margin.x + stack_offset.x, margin.y + stack_offset.y, size)
		
		ToastConstants.ToastPosition.CENTER_LEFT:
			_set_anchors_and_offsets(panel, 0.0, 0.5, margin.x + stack_offset.x, -size.y / 2.0 + stack_offset.y, size)
		ToastConstants.ToastPosition.CENTER:
			_set_anchors_and_offsets(panel, 0.5, 0.5, -size.x / 2.0 + stack_offset.x, -size.y / 2.0 + stack_offset.y, size)
		ToastConstants.ToastPosition.CENTER_RIGHT:
			_set_anchors_and_offsets(panel, 1.0, 0.5, -size.x - margin.x + stack_offset.x, -size.y / 2.0 + stack_offset.y, size)
		
		ToastConstants.ToastPosition.BOTTOM_LEFT:
			_set_anchors_and_offsets(panel, 0.0, 1.0, margin.x + stack_offset.x, -size.y - margin.y + stack_offset.y, size)
		ToastConstants.ToastPosition.BOTTOM_CENTER:
			_set_anchors_and_offsets(panel, 0.5, 1.0, -size.x / 2.0 + stack_offset.x, -size.y - margin.y + stack_offset.y, size)
		ToastConstants.ToastPosition.BOTTOM_RIGHT:
			_set_anchors_and_offsets(panel, 1.0, 1.0, -size.x - margin.x + stack_offset.x, -size.y - margin.y + stack_offset.y, size)

# Calculates the vertical offset for stacked toasts in the same position.
static func calculate_stack_offset(
	position: ToastConstants.ToastPosition,
	stack_index: int,
	panel_size: Vector2,
	spacing: float
) -> Vector2:
	if stack_index <= 0:
		return Vector2.ZERO
	
	var offset_amount := (panel_size.y + spacing) * float(stack_index)
	
	match position:
		ToastConstants.ToastPosition.TOP_LEFT, \
		ToastConstants.ToastPosition.TOP_CENTER, \
		ToastConstants.ToastPosition.TOP_RIGHT:
			return Vector2(0.0, offset_amount)
		
		ToastConstants.ToastPosition.BOTTOM_LEFT, \
		ToastConstants.ToastPosition.BOTTOM_CENTER, \
		ToastConstants.ToastPosition.BOTTOM_RIGHT:
			return Vector2(0.0, -offset_amount)
		
		ToastConstants.ToastPosition.CENTER_LEFT, \
		ToastConstants.ToastPosition.CENTER, \
		ToastConstants.ToastPosition.CENTER_RIGHT:
			return Vector2(0.0, offset_amount)
	
	return Vector2.ZERO

# Helper to set anchors and offsets in one place.
static func _set_anchors_and_offsets(
	panel: Control, 
	anchor_x: float, 
	anchor_y: float, 
	left: float, 
	top: float, 
	size: Vector2
) -> void:
	panel.anchor_left = anchor_x
	panel.anchor_right = anchor_x
	panel.anchor_top = anchor_y
	panel.anchor_bottom = anchor_y
	
	panel.offset_left = left
	panel.offset_top = top
	panel.offset_right = left + size.x
	panel.offset_bottom = top + size.y