extends Area2D
class_name BaseHousePart

@export var change_stat_text_info_prefab : PackedScene

var _part_data: HousePartData
var _current_state: int = 1
var _current_timer = 0

const HOLD_DURATION := 0.9
const HOLD_SHOW_DELAY := 0.3
const CLICK_THRESHOLD := 0.15

static var _cursor_owner: Node = null

var _is_holding := false
var _hold_timer := 0.0
var _hold_indicator: HoldProgressIndicator

func _ready() -> void:
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	input_event.connect(_on_input_event)

	_hold_indicator = HoldProgressIndicator.new()
	_hold_indicator.hide()
	add_child(_hold_indicator)

func _on_mouse_entered() -> void:
	BaseHousePart._cursor_owner = self
	Input.set_default_cursor_shape(Input.CURSOR_POINTING_HAND)
	Tooltip.instance.show_for(self)
	_update_tooltip()

func _on_mouse_exited() -> void:
	if BaseHousePart._cursor_owner == self:
		BaseHousePart._cursor_owner = null
		Input.set_default_cursor_shape(Input.CURSOR_ARROW)
	Tooltip.instance.hide_from(self)
	_cancel_hold()

func _update_tooltip() -> void:
	var stats = _part_data.stat_change[_current_state].stat_changes.duplicate()
	for stat_key in stats.keys():
		stats[stat_key] = stats.get(stat_key, 0)
		if stats[stat_key] == 0:
			stats.erase(stat_key)
	Tooltip.instance.set_text(_part_data.description, stats, _part_data.update_time)

func _on_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT:
			if mb.pressed:
				_start_hold()
			else:
				_release_hold()

func _input(event: InputEvent) -> void:
	if not _is_holding:
		return
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT and not mb.pressed:
			_release_hold()

func _process(delta: float) -> void:
	if not _is_holding:
		return
	_hold_timer += delta
	if _hold_timer >= HOLD_SHOW_DELAY:
		_hold_indicator.show()
		_hold_indicator.progress = minf((_hold_timer - HOLD_SHOW_DELAY) / (HOLD_DURATION - HOLD_SHOW_DELAY), 1.0)
	if _hold_timer >= HOLD_DURATION:
		if _current_state < _part_data.stat_change.size() - 1:
			_current_state += 1
			_update_tooltip()
		_cancel_hold()

func _start_hold() -> void:
	_is_holding = true
	_hold_timer = 0.0

func _cancel_hold() -> void:
	if not _is_holding:
		return
	_is_holding = false
	_hold_timer = 0.0
	_hold_indicator.progress = 0.0
	_hold_indicator.hide()

func _release_hold() -> void:
	if not _is_holding:
		return
	var was_click := _hold_timer < CLICK_THRESHOLD
	_cancel_hold()
	if was_click and _current_state > 0:
		_current_state -= 1
		_update_tooltip()

func set_part_data(data: HousePartData) -> void:
	_part_data = data
	_current_state = min(_part_data.start_state, _part_data.stat_change.size() - 1)
	_current_timer = randf() * _part_data.update_time

func tick(delta: float, _ticker: HouseStatsTicker) -> Variant:
	_current_timer += delta
	if _current_timer >= _part_data.update_time:
		_current_timer -= _part_data.update_time
		var stats = _part_data.stat_change[_current_state].stat_changes.duplicate()
		for stat_key in stats.keys():
			stats[stat_key] = stats.get(stat_key, 0)
			if stats[stat_key] == 0:
				stats.erase(stat_key)
		if stats.size() > 0:
			if change_stat_text_info_prefab:
				var text := change_stat_text_info_prefab.instantiate() as ChangeStatTextInfo
				text.set_stats(stats)
				add_child(text)
				text.position = -text.size / 2
			return stats
	return null
