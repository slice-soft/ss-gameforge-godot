class_name DialogueSpeaker extends Resource
## Who says a line: the name and portrait shown in the box, and the voice blip
## played while the line types out. Share one per character across resources.

## Name shown above the text. Passed through tr() when the resource uses
## translation. Empty = no name shown.
@export var display_name: String = ""
## Colour of the name. Fully transparent = the theme's name_color.
@export var name_color: Color = Color(0, 0, 0, 0)
## Shown beside the text. Empty = no portrait.
@export var portrait: Texture2D

@export_group("Voice")
## Short sound played while the line types. Empty = silent.
@export var voice: AudioStream
## Base pitch of the voice; higher sounds smaller or younger.
@export_range(0.25, 4.0, 0.01) var voice_pitch: float = 1.0
## Random pitch change per blip, as a fraction (0.1 = ±10%).
@export_range(0.0, 1.0, 0.01) var pitch_variation: float = 0.05
## Play the voice every this many revealed characters (spaces are not counted).
@export_range(1, 10) var voice_every: int = 2
## Volume of the voice in dB.
@export_range(-40.0, 12.0, 0.5) var voice_volume_db: float = 0.0
