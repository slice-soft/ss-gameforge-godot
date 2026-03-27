extends Object
class_name ToastStyleResolver

# Keys supported by the style resolution pipeline.
const RESOLVE_KEYS := [
	"background_color",
	"text_color",
	"icon",
	"icon_color",
	"icon_scene",
	"icon_spin",
	"icon_spin_speed",
	"duration",
	"font_size",
	"icon_size",
	"padding",
	"corner_radius",
	"position",
	"position_margin",
]

# Resolves a complete style dictionary based on theme, style, and overrides.
static func resolve(theme: ToastTheme, style: ToastConstants.ToastStyle, overrides: Dictionary = {}) -> Dictionary:
	var data := _get_base_style_data(theme, style)
	_apply_global_defaults(data, theme)
	_apply_overrides(data, overrides)
	return data

# Returns style-specific colors and icons.
static func _get_base_style_data(theme: ToastTheme, style: ToastConstants.ToastStyle) -> Dictionary:
	match style:
		ToastConstants.ToastStyle.LOADER:
			return {
				"background_color": theme.loader_background_color,
				"text_color": theme.loader_text_color,
				"icon": theme.loader_icon,
			}
		ToastConstants.ToastStyle.SUCCESS:
			return {
				"background_color": theme.success_background_color,
				"text_color": theme.success_text_color,
				"icon": theme.success_icon,
			}
		ToastConstants.ToastStyle.DANGER:
			return {
				"background_color": theme.danger_background_color,
				"text_color": theme.danger_text_color,
				"icon": theme.danger_icon,
			}
		ToastConstants.ToastStyle.CUSTOM:
			return {
				"background_color": theme.custom_background_color,
				"text_color": theme.custom_text_color,
				"icon": theme.custom_icon,
			}
		_:
			return {
				"background_color": theme.info_background_color,
				"text_color": theme.info_text_color,
				"icon": theme.info_icon,
			}

# Applies global theme defaults to the style dictionary.
static func _apply_global_defaults(data: Dictionary, theme: ToastTheme) -> void:
	data["duration"] = theme.duration
	data["font_size"] = theme.font_size
	data["icon_size"] = theme.icon_size
	data["padding"] = theme.padding
	data["corner_radius"] = theme.corner_radius
	data["position"] = theme.position
	data["position_margin"] = theme.position_margin

# Overrides any keys provided by the caller.
static func _apply_overrides(data: Dictionary, overrides: Dictionary) -> void:
	for key in overrides.keys():
		data[key] = overrides[key]
