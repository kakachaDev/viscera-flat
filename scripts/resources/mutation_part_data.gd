extends Resource
class_name MutationPartData

@export var id: String = ""
@export var description: String = ""
@export var conditions: Dictionary = {}
@export var update_time: float = 1.0
@export var graft_time: float = 8.0
@export var stat_change: Dictionary[GameEnums.StatType, float]
