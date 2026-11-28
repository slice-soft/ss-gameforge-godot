class_name DialogueHistory extends Resource
## Log of the dialogue lines that have been shown. Assign the same instance to
## several DialogueViews (or DialogueView3Ds) to gather every speaker in one log,
## then draw your own backlog screen from get_entries().

## Emitted when a line is recorded. entry has "text", "speaker", "speaker_name",
## "resource" and "index".
signal entry_added(entry: Dictionary)
## Emitted by clear().
signal cleared

## Oldest entries are dropped past this many. 0 = unlimited.
@export var max_entries: int = 200

var _entries: Array[Dictionary] = []


## Records a shown line. Called by DialogueView; you can also add your own.
## speaker_name is the name as displayed (translated); empty when nobody is named.
func add(text: String, resource: DialogueResource = null, index: int = -1,
		speaker: DialogueSpeaker = null, speaker_name: String = "") -> void:
	var entry := {"text": text, "speaker": speaker, "speaker_name": speaker_name,
		"resource": resource, "index": index}
	_entries.append(entry)
	if max_entries > 0:
		while _entries.size() > max_entries:
			_entries.pop_front()
	entry_added.emit(entry)


## Every recorded entry, oldest first. Each is {"text", "speaker",
## "speaker_name", "resource", "index"}; text is the line as displayed
## (translated, BBCode included).
func get_entries() -> Array[Dictionary]:
	return _entries.duplicate()


## Number of recorded entries.
func size() -> int:
	return _entries.size()


func clear() -> void:
	_entries.clear()
	cleared.emit()
