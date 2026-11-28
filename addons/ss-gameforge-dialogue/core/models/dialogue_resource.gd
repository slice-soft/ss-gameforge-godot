class_name DialogueResource extends Resource

## Array of strings shown in sequence.
## When use_translation is true, each entry is a translation key passed to tr().
## When use_translation is false, entries are displayed as-is (raw strings or BBCode).
@export_group("Content")
@export var dialogues: Array[String] = ["dialogue_key_placeholder"]
@export var use_translation: bool = true
## Who speaks every line, unless line_speakers names someone else. Empty = no
## name, portrait or voice.
@export var speaker: DialogueSpeaker
## Per-line speaker, by line index. A missing or empty entry uses speaker.
@export var line_speakers: Array[DialogueSpeaker] = []

@export_group("Behavior")
@export var auto_start: bool = false
## Whether the player can interrupt typing or advance lines manually.
## In AUTO mode, only the typing animation can be interrupted; the hold timer is not skippable.
@export var allow_skip: bool = true
@export var advance_mode: DialogueConstants.AdvanceMode = DialogueConstants.AdvanceMode.HYBRID
## Seconds per visible character. Lower = faster reveal.
@export_range(0.01, 0.5, 0.005) var text_speed: float = 0.075

@export_group("Timing")
## Delay before the dialogue box appears after play() is called.
@export_range(0.0, 2.0) var time_to_start: float = 0.25
## Pause after a line finishes typing before auto-advancing (AUTO/HYBRID only).
@export_range(0.0, 3.0) var hold_after_line: float = 0.75

@export_group("Open Animation")
@export_range(0.0, 2.0) var open_time: float = 0.55
@export var open_transition: Tween.TransitionType = Tween.TRANS_ELASTIC
@export var open_ease: Tween.EaseType = Tween.EASE_OUT

@export_group("Close Animation")
@export_range(0.0, 2.0) var close_time: float = 0.20
@export var close_transition: Tween.TransitionType = Tween.TRANS_BACK
@export var close_ease: Tween.EaseType = Tween.EASE_IN_OUT


## The speaker of line `index`: its line_speakers entry, or speaker.
func get_speaker(index: int) -> DialogueSpeaker:
	if index >= 0 and index < line_speakers.size() and line_speakers[index] != null:
		return line_speakers[index]
	return speaker
