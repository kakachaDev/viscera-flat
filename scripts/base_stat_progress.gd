extends TextureProgressBar

@export var stat: GameEnums.StatType
@export var ticker: HouseStatsTicker
@export var speed: float = 10

var _target_value : float = 50

func _ready() -> void:
	ticker.on_stats_changed.connect(update_stat.bind())
	_target_value = ticker._stats.get(stat, 50)
	value = _target_value
	$Label.text = GameEnums.StatName.get(stat, GameEnums.StatType.find_key(stat))

func update_stat(stats: Dictionary[GameEnums.StatType, float]):
	_target_value = stats.get(stat, 50)

func _process(delta: float) -> void:
	value = lerp(value, _target_value, speed * delta)
