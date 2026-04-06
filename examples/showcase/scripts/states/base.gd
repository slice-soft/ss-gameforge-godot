extends StateBase
class_name GameManagerStateBase

var game_manager: GameManager:
	set(value): controlled_node = value
	get: return controlled_node as GameManager
