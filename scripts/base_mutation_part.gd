extends Area2D
class_name BaseMutationPart

@export var change_stat_text_info_prefab : PackedScene

var _part_data: MutationPartData
var _current_timer = 0

func _ready() -> void:
	mouse_entered.connect(_on_mouse_entered.bind())
	mouse_exited.connect(_on_mouse_exited.bind())

func _on_mouse_entered() -> void:
	BaseHousePart._cursor_owner = self
	Input.set_default_cursor_shape(Input.CURSOR_HELP)
	Tooltip.instance.show_for(self)
	_update_tooltip()

func _update_tooltip():
	var stats = _part_data.stat_change.duplicate()
	for stat_key in stats.keys():
		stats[stat_key] = stats.get(stat_key, 0)
		if stats[stat_key] == 0:
			stats.erase(stat_key)
	Tooltip.instance.set_text(_part_data.description, stats, _part_data.update_time)

func _on_mouse_exited() -> void:
	if BaseHousePart._cursor_owner == self:
		BaseHousePart._cursor_owner = null
		Input.set_default_cursor_shape(Input.CURSOR_ARROW)
	Tooltip.instance.hide_from(self)

func set_part_data(data: MutationPartData):
	_part_data = data
	_current_timer = randf() * _part_data.update_time

func tick(delta: float, ticker: HouseStatsTicker) -> Variant:
	if not is_visible_in_tree(): return
	
	_current_timer += delta
	if (_current_timer >= _part_data.update_time):
		_current_timer -= _part_data.update_time
		var stats = _part_data.stat_change.duplicate() 
		
		for stat_key in stats.keys():
			if stats[stat_key] == 0:
				stats.erase(stat_key)
			
		if stats.size() > 0:
			if change_stat_text_info_prefab:
				var text = change_stat_text_info_prefab.instantiate() as ChangeStatTextInfo
				text.set_stats(stats)
				add_child(text)
				text.position = -text.size / 2
			return stats
	return null
