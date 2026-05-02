extends Node
class_name HouseStatsTicker

signal on_stats_changed()

const UPDATE_TIME := 1.0 / 20.0

var _stats: Dictionary[GameEnums.StatType, float] = {
	GameEnums.StatType.Light: 50,
	GameEnums.StatType.Moisture: 50
}

@export var parts: Array[BaseHousePart]
@export var mutations: Array[BaseMutationPart]
@export var hud_mutation_count_label: Label

var _stats_changed := false
var _active := true

var _mutation_part_data: Array[MutationPartData]
var _impacts: Dictionary
var _spawned_mutation_ids: Array[String] = []
var _next_mutation_time := 0.0

func _ready() -> void:
	var house_parts: Array[HousePartData] = DataLoader.load_house_parts_from_json("res://data/house_parts.json")
	for part_idx in parts.size():
		parts[part_idx].set_part_data(house_parts[part_idx])

	_mutation_part_data = DataLoader.load_mutations_from_json("res://data/mutations.json")
	_impacts = DataLoader.load_meta_impacts_from_json("res://data/mutation_meta_impact.json")

	_next_mutation_time = randf_range(10.0, 20.0)
	_update_hud()
	_base_update_stats(UPDATE_TIME)

func _base_update_stats(delta: float) -> void:
	if not _active:
		return

	for part in parts:
		_change_stat(part.tick(delta))
	for part in mutations:
		_change_stat(part.tick(delta))

	if _stats_changed:
		on_stats_changed.emit(_stats)
		_stats_changed = false

	_next_mutation_time -= delta
	if _next_mutation_time <= 0.0:
		_try_spawn_mutation()
		_next_mutation_time = randf_range(10.0, 20.0)

	if _spawned_mutation_ids.size() >= mutations.size():
		_active = false
		_show_end_game()
		return

	get_tree().create_timer(UPDATE_TIME).timeout.connect(_base_update_stats.bind(UPDATE_TIME))

func _update_hud() -> void:
	if hud_mutation_count_label:
		hud_mutation_count_label.text = "Мутации: %d/8" % _spawned_mutation_ids.size()

func _try_spawn_mutation() -> void:
	var eligible: Array[MutationPartData] = []
	for mutation in _mutation_part_data:
		if mutation.id in _spawned_mutation_ids:
			continue
		if _mutation_meets_conditions(mutation):
			eligible.append(mutation)
	if eligible.is_empty():
		return
	var chosen := eligible[randi() % eligible.size()]
	for mutation in mutations:
		if mutation.is_visible_in_tree():
			continue
		mutation.show()
		mutation.set_part_data(chosen)
		break
	_spawned_mutation_ids.append(chosen.id)
	_update_hud()

func _mutation_meets_conditions(mutation: MutationPartData) -> bool:
	for key in mutation.conditions.keys():
		var sep := (key as String).rfind("_")
		var stat := DataLoader._string_to_stat_type((key as String).substr(0, sep))
		var cond := (key as String).substr(sep + 1)
		var threshold := float(mutation.conditions[key])
		if cond == "min" and _stats[stat] < threshold:
			return false
		if cond == "max" and _stats[stat] > threshold:
			return false
	return true

func _show_end_game() -> void:
	var spawned: Array[MutationPartData] = []
	for mutation in mutations:
		if mutation._part_data != null:
			spawned.append(mutation._part_data)
	EndGame.instance.show_end_game(_impacts, spawned)

func _change_stat(new_stats) -> void:
	if new_stats == null:
		return
	for new_stat_key in new_stats.keys():
		_stats[new_stat_key] = clampf(
			_stats.get_or_add(new_stat_key, 0) + new_stats[new_stat_key], 0.0, 100.0)
	_stats_changed = true
