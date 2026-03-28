class_name BBCodeParser

## Returns the number of visible (non-tag) characters in a BBCode string.
static func visible_length(s: String) -> int:
	var n := 0
	var i := 0
	var open_tags: Array[String] = []
	while i < s.length():
		var tag := _read_tag(s, i, open_tags)
		if not tag.is_empty():
			n += int(tag.get("visible_length", 0))
			i = int(tag["end"]) + 1
			continue
		n += 1
		i += 1
	return n


## Returns the BBCode prefix that reveals exactly visible_count visible characters,
## automatically closing any open tags to keep the markup valid.
static func prefix(s: String, visible_count: int) -> String:
	if visible_count <= 0:
		return ""

	var result := ""
	var visible := 0
	var i := 0
	var open_tags: Array[String] = []

	while i < s.length():
		var tag := _read_tag(s, i, open_tags)
		if not tag.is_empty():
			var tag_visible_length := int(tag.get("visible_length", 0))
			if tag_visible_length > 0:
				if visible >= visible_count:
					break
				result += String(tag["text"])
				visible += tag_visible_length
			else:
				result += String(tag["text"])
			i = int(tag["end"]) + 1
			continue

		if visible >= visible_count:
			break

		result += s[i]
		visible += 1
		i += 1

	for j in range(open_tags.size() - 1, -1, -1):
		result += "[/%s]" % open_tags[j]

	return result


static func _read_tag(s: String, start: int, open_tags: Array[String]) -> Dictionary:
	if s[start] != "[":
		return {}

	var end := s.find("]", start)
	if end == -1:
		return {}

	var content := s.substr(start + 1, end - start - 1).strip_edges()
	if content.is_empty():
		return {}

	var text := s.substr(start, end - start + 1)
	var is_closing := content.begins_with("/")
	var raw_name := content.substr(1 if is_closing else 0).strip_edges()
	if raw_name.ends_with("/"):
		raw_name = raw_name.substr(0, raw_name.length() - 1).strip_edges()

	var tag_name := _tag_name(raw_name)
	if tag_name.is_empty():
		return {}

	if is_closing:
		var open_index := _find_last_open_tag(open_tags, tag_name)
		if open_index == -1:
			return {}
		open_tags.remove_at(open_index)
		return {"end": end, "text": text, "visible_length": 0}

	if tag_name == "br":
		return {"end": end, "text": text, "visible_length": 1}

	if not _has_closing_tag(s, end + 1, tag_name):
		return {}

	open_tags.append(tag_name)
	return {"end": end, "text": text, "visible_length": 0}


static func _tag_name(raw_name: String) -> String:
	var end := raw_name.length()
	var equal_index := raw_name.find("=")
	var space_index := raw_name.find(" ")
	if equal_index != -1:
		end = min(end, equal_index)
	if space_index != -1:
		end = min(end, space_index)
	return raw_name.substr(0, end).to_lower()


static func _has_closing_tag(s: String, from: int, tag_name: String) -> bool:
	return s.to_lower().find("[/%s]" % tag_name, from) != -1


static func _find_last_open_tag(open_tags: Array[String], tag_name: String) -> int:
	for i in range(open_tags.size() - 1, -1, -1):
		if open_tags[i] == tag_name:
			return i
	return -1
