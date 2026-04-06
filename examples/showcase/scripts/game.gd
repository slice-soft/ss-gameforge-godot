extends Node
class_name GameManager

@onready var state_machine: StateMachine = $StateMachine
@onready var name_label: Label = $VBoxContainer/NameLabel
@onready var number_label: Label = $VBoxContainer/NumberLabel
@onready var sprite_texture: TextureRect = $VBoxContainer/SpriteTexture
@onready var dialogue_view: DialogueView = $VBoxContainer/DialogueView
@onready var states: GameManagerStates = GameManagerStates.new()

var current_pokemon_id: int = 1
var current_pokemon_name: String = ""
var current_pokemon_flavor_texts: Array[String] = []
var current_pokemon_texture: ImageTexture = null

func _enter_tree() -> void:
	SingletonNode.ensure_for(ToastService, get_tree().root, "ToastService")
	SingletonNode.ensure_for(GWInputManager, get_tree().root, "GWInputManager")
