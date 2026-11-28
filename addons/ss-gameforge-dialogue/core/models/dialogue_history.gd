class_name DialogueHistory extends Resource
## Log of the dialogue lines that have been shown. Assign the same instance to
## several DialogueViews (or DialogueView3Ds) to gather every speaker in one log,
## then draw your own backlog screen from get_entries().

## Emitted when a line is recorded. entry has "text", "resource" and "index".
signal entry_added(entry: Dictionary)
## Emitted by clear().
signal cleared

## Oldest entries are dropped past this many. 0 = unlimited.
@export var max_entries: int = 200

var _entries: Array[Dictionary] = []


## Records a shown line. Called by DialogueView; you can also add your own.
func add(text: String, resource: DialogueResource = null, index: int = -1) -> void:
	var entry := {"text": text, "resource": resource, "index": index}
	_entries.append(entry)
	if max_entries > 0:
		while _entries.size() > max_entries:
			_entries.pop_front()
	entry_added.emit(entry)


## Every recorded entry, oldest first. Each is {"text", "resource", "index"};
## text is the line as displayed (translated, BBCode included).
func get_entries() -> Array[Dictionary]:
	return _entries.duplicate()


## Number of recorded entries.
func size() -> int:
	return _entries.size()


func clear() -> void:
	_entries.clear()
	cleared.emit()
