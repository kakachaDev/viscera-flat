extends Node
class_name HouseStatsTicker

signal on_stats_changed()

const UPDATE_TIME = 1.0/20 # 20 ticks

var _stats: Dictionary[GameEnums.StatType, float] = {
	GameEnums.StatType.Light: 50,
	GameEnums.StatType.Food: 50,
	GameEnums.StatType.Moisture: 50
}

@export var parts: Array[BaseHousePart]
@export var mutations: Array[BaseMutationPart]

var _stats_changed := false
var _active := true

var _mutation_part_data : Array[MutationPartData]
var _impacts : Dictionary

func _ready() -> void:
	# Грузим части короче
	var house_parts: Array[HousePartData] = DataLoader.load_house_parts_from_json("res://data/house_parts.json")
	for part_idx in parts.size():
		parts[part_idx].set_part_data(house_parts[part_idx])
	
	_mutation_part_data = DataLoader.load_mutations_from_json("res://data/mutations.json")
	_impacts = DataLoader.load_meta_impacts_from_json("res://data/mutation_meta_impact.json")
	
	_base_update_stats(UPDATE_TIME)

func _base_update_stats(delta):
	if !_active: return
	
	for part in parts:
		_change_stat(part.tick(delta, self))
	
	for part in mutations:
		_change_stat(part.tick(delta, self))
	
	if _stats_changed:
		on_stats_changed.emit(_stats)
		_stats_changed = false
	
	for stat_key in _stats.keys():
		if _stats[stat_key] <= 10:
			if _try_apply_mutation(stat_key, "negative"): 
				_change_stat({stat_key: 20.0})
				break
		elif _stats[stat_key] >= 90:
			if _try_apply_mutation(stat_key, "positive"): 
				_change_stat({stat_key: -20.0})
				break
	
	if not _check_free_mutation_slots():
		_active = false
		_show_end_game()
	
	get_tree().create_timer(UPDATE_TIME).timeout.connect(_base_update_stats.bind(UPDATE_TIME))

func _check_free_mutation_slots() -> bool:
	for mutation in mutations:
		if not mutation.is_visible_in_tree(): return true
	return false

func _show_end_game():
	var parts: Array[MutationPartData] = []
	for mutation in mutations:
		if mutation._part_data == null:
			continue
		
		parts.append(mutation._part_data)
	
	EndGame.instance.show_end_game(_impacts, parts)


func _try_apply_mutation(stat_type: GameEnums.StatType, trigger_type: String) -> bool:
	if randf() > 0.05: return false # 5% шанса
	
	for mutation in _mutation_part_data:
		if mutation.trigger_stat == stat_type and mutation.trigger_type == trigger_type:
			_open_next_mutation(mutation)
			return true
	return false

func _open_next_mutation(mutation_data: MutationPartData):
	for mutation in mutations:
		if mutation.is_visible_in_tree(): continue
		
		mutation.show()
		mutation.set_part_data(mutation_data)
		break




func has_food(amount: float) -> bool:
	return _stats[GameEnums.StatType.Food] >= amount

func try_spend_food(amount: float) -> bool:
	if _stats[GameEnums.StatType.Food] < amount:
		return false
	_stats[GameEnums.StatType.Food] -= amount
	_stats_changed = true
	return true

func _change_stat(new_stats):
	if new_stats == null: return

	for new_stat_key in new_stats.keys():
		_stats[new_stat_key] = _stats.get_or_add(new_stat_key, 0) + new_stats[new_stat_key]
	_stats_changed = true
