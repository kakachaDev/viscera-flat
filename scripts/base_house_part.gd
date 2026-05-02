extends Area2D
class_name BaseHousePart

@export var change_stat_text_info_prefab : PackedScene

var _part_data: HousePartData
var _current_state: int = 1
var _current_timer = 0

func _ready() -> void:
	mouse_entered.connect(_on_mouse_entered.bind())
	mouse_exited.connect(_on_mouse_exited.bind())
	input_event.connect(_on_input_event.bind())

func _on_mouse_entered() -> void:
	Input.set_default_cursor_shape(Input.CURSOR_POINTING_HAND)
	
	Tooltip.instance.show()
	_update_tooltip()

func _on_mouse_exited() -> void:
	Input.set_default_cursor_shape(Input.CURSOR_ARROW)
	
	Tooltip.instance.hide()

func _update_tooltip():
	var stats = _part_data.stat_change[_current_state].stat_changes.duplicate()
	for stat_key in stats.keys():
		stats[stat_key] = stats.get(stat_key, 0)
		if stats[stat_key] == 0:
			stats.erase(stat_key)
	Tooltip.instance.set_text(_part_data.description, stats, _part_data.update_time)

func _on_input_event(viewport: Node, event: InputEvent, shape_idx: int) -> void:
	if event is InputEventMouseButton:
		if (event as InputEventMouseButton).pressed:
			match (event as InputEventMouseButton).button_index:
				MouseButton.MOUSE_BUTTON_LEFT:
					if _current_state < _part_data.stat_change.size() - 1:
						_current_state += 1
						_update_tooltip()
				MouseButton.MOUSE_BUTTON_RIGHT:
					if _current_state > 0:
						_current_state -= 1
						_update_tooltip()

func set_part_data(data: HousePartData):
	_part_data = data
	_current_state = min(_part_data.start_state, _part_data.stat_change.size()-1)
	_current_timer = randf() * _part_data.update_time

func tick(delta: float, ticker: HouseStatsTicker) -> Variant:
	_current_timer += delta
	if (_current_timer >= _part_data.update_time):
		_current_timer -= _part_data.update_time
		var stats = _part_data.stat_change[_current_state].stat_changes.duplicate()
		for stat_key in stats.keys():
			stats[stat_key] = stats.get(stat_key, 0)
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
