extends Object
class_name ToastAnimator

# Default fade durations used for toast animations.
const DEFAULT_FADE_IN := 0.18
const DEFAULT_FADE_OUT := 0.28

# Plays a fade-in, wait, fade-out sequence for a toast view.
static func play_toast_animation(
	view: CanvasItem, 
	duration: float, 
	fade_in: float = DEFAULT_FADE_IN, 
	fade_out: float = DEFAULT_FADE_OUT
) -> Tween:
	var tween := view.create_tween()
	
	tween.tween_property(view, "modulate:a", 1.0, fade_in)
	
	tween.tween_interval(duration)
	
	tween.tween_property(view, "modulate:a", 0.0, fade_out)
	
	return tween

# Fades a canvas item to full opacity.
static func fade_in(target: CanvasItem, duration: float = DEFAULT_FADE_IN) -> Tween:
	var tween := target.create_tween()
	tween.tween_property(target, "modulate:a", 1.0, duration)
	return tween

# Fades a canvas item to transparent.
static func fade_out(target: CanvasItem, duration: float = DEFAULT_FADE_OUT) -> Tween:
	var tween := target.create_tween()
	tween.tween_property(target, "modulate:a", 0.0, duration)
	return tween

# Creates a looping rotation tween used for loader icons.
static func create_spin_animation(
	target: CanvasItem,
	speed: float = 1.5,
	total_duration: float = 0.0
) -> Tween:
	if target == null:
		return null
	
	_prepare_spin_target(target)
	
	var spin_duration := _calculate_spin_duration(speed, total_duration)
	
	var tween := target.create_tween()
	tween.set_loops(-1)
	tween.tween_property(target, "rotation", TAU, spin_duration)
	
	return tween

# Ensures the pivot is centered before spinning.
static func _prepare_spin_target(target: CanvasItem) -> void:
	if target is Control:
		var ctrl := target as Control
		ctrl.pivot_offset = ctrl.size / 2.0
		ctrl.rotation = 0.0
	elif target is Node2D:
		var node_2d := target as Node2D
		node_2d.rotation = 0.0

# Derives the duration of a full rotation based on speed.
static func _calculate_spin_duration(speed: float, total_duration: float) -> float:
	var safe_speed := max(speed, 0.01)
	
	if total_duration > 0.0:
		return total_duration / safe_speed
	
	return 1.0 / safe_speed