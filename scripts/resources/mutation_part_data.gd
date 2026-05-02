extends Resource
class_name MutationPartData

@export var id: String = ""
@export var description: String = ""
@export var trigger_stat: GameEnums.StatType = GameEnums.StatType.Light
@export var trigger_type: String = ""  # "positive" или "negative"
@export var update_time: float = 1.0
@export var stat_change: Dictionary[GameEnums.StatType, float]
