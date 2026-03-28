extends RefCounted
class_name ToastData

# Immutable payload used to render a toast.
var text: String
var style: ToastConstants.ToastStyle
var overrides: Dictionary

# Stores the text, base style, and any per-toast overrides.
func _init(p_text: String = "", p_style: ToastConstants.ToastStyle = ToastConstants.ToastStyle.INFO, p_overrides: Dictionary = {}) -> void:
	text = p_text
	style = p_style
	overrides = p_overrides.duplicate()

# Serializes the toast data to a dictionary.
func to_dict() -> Dictionary:
	return {
		"text": text,
		"style": style,
		"overrides": overrides
	}

# Builds a ToastData instance from a dictionary payload.
static func from_dict(data: Dictionary) -> ToastData:
	return ToastData.new(
		data.get("text", ""),
		data.get("style", ToastConstants.ToastStyle.INFO),
		data.get("overrides", {})
	)