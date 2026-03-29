## Static utility for named input profile persistence.
## Wraps GWInputManager save/load with a named-slot pattern.
## Each profile is stored as a separate JSON file: gw_profile_{name}.json
class_name GWProfileManager

const _PREFIX := "gw_profile_"
const _EXT := ".json"


## Saves the current player bindings as a named profile.
static func save(manager: GWInputManager, profile_name: String, base_path: String = "user://") -> void:
	manager.save_all_profiles(_profile_path(profile_name, base_path))


## Loads a named profile into the manager. Players must exist first.
static func load_profile(manager: GWInputManager, profile_name: String, base_path: String = "user://") -> void:
	manager.load_all_profiles(_profile_path(profile_name, base_path))


## Returns true if the named profile file exists.
static func profile_exists(profile_name: String, base_path: String = "user://") -> bool:
	return FileAccess.file_exists(_profile_path(profile_name, base_path))


## Returns all saved profile names found in the given directory.
static func list_profiles(base_path: String = "user://") -> Array[String]:
	var dir := DirAccess.open(base_path)
	var result: Array[String] = []
	if dir == null:
		return result
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if not dir.current_is_dir() \
				and file_name.begins_with(_PREFIX) \
				and file_name.ends_with(_EXT):
			result.append(file_name.trim_prefix(_PREFIX).trim_suffix(_EXT))
		file_name = dir.get_next()
	dir.list_dir_end()
	return result


## Deletes a saved profile. Does nothing if the file does not exist.
static func delete_profile(profile_name: String, base_path: String = "user://") -> void:
	var path := _profile_path(profile_name, base_path)
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)


static func _profile_path(profile_name: String, base_path: String) -> String:
	return base_path.trim_suffix("/") + "/" + _PREFIX + profile_name + _EXT
