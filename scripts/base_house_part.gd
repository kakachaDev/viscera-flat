extends Area2D
class_name GraftCell

enum State { HEALED, CUT, GRAFTING, GRAFTED }

signal grafting_succeeded(cell: GraftCell)
signal grafting_failed(cell: GraftCell, mutation: MutationPartData)

const HOLD_DURATION := 0.9
const HOLD_SHOW_DELAY := 0.3

static var _cursor_owner: Node = null

@export var change_stat_text_info_prefab: PackedScene

@export var graft_opened: Texture2D
@export var graft_closed: Texture2D
@export var mirrored: bool = false

var _part_data: HousePartData = null
var _state: State = State.HEALED
var _passive_timer: float = 0.0
var _grafted_mutation: MutationPartData = null
var _graft_timer: float = 0.0
var _active: bool = false

var _is_holding := false
var _hold_timer := 0.0
var _hold_indicator: HoldProgressIndicator
var _graft_indicator: HoldProgressIndicator
var _mutation_node: Node = null

func _ready() -> void:
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	input_event.connect(_on_input_event)

	_hold_indicator = HoldProgressIndicator.new()
	_hold_indicator.hide()
	add_child(_hold_indicator)

	_graft_indicator = HoldProgressIndicator.new()
	_graft_indicator.radius = 22.0
	_graft_indicator.width = 4.0
	_graft_indicator.hide()
	add_child(_graft_indicator)

func set_part_data(data: HousePartData) -> void:
	_part_data = data
	_passive_timer = randf() * data.update_time
	_update_visuals()

func set_active(value: bool) -> void:
	_active = value
	if not value:
		visible = (_state == State.GRAFTED)
	else:
		visible = true
	modulate.a = 1.0

func can_accept_card() -> bool:
	return _active and _state == State.CUT

func start_grafting(mutation: MutationPartData) -> void:
	if _state != State.CUT:
		return
	_state = State.GRAFTING
	_grafted_mutation = mutation
	_graft_timer = 0.0
	_graft_indicator.progress = 0.0
	_graft_indicator.show()
	_spawn_mutation_prefab()
	_update_visuals()
	if GraftCell._cursor_owner == self:
		_update_tooltip()

func tick(delta: float, current_stats: Dictionary) -> Variant:
	match _state:
		State.HEALED:
			return _tick_passive(delta, 1)
		State.CUT:
			return _tick_passive(delta, 0)
		State.GRAFTING:
			return _tick_grafting(delta, current_stats)
		State.GRAFTED:
			return _tick_grafted(delta)
	return null

func _tick_passive(delta: float, state_idx: int) -> Variant:
	if _part_data == null:
		return null
	_passive_timer += delta
	if _passive_timer >= _part_data.update_time:
		_passive_timer -= _part_data.update_time
		var stats = _part_data.stat_change[state_idx].stat_changes.duplicate()
		for k in stats.keys():
			if stats[k] == 0:
				stats.erase(k)
		if stats.size() > 0:
			_spawn_stat_text(stats)
			return stats
	return null

func _tick_grafting(delta: float, current_stats: Dictionary) -> Variant:
	for key in _grafted_mutation.conditions.keys():
		var sep := (key as String).rfind("_")
		var stat_name := (key as String).substr(0, sep)
		var cond := (key as String).substr(sep + 1)
		var stat_type := DataLoader._string_to_stat_type(stat_name)
		var threshold := float(_grafted_mutation.conditions[key])
		var val := float(current_stats.get(stat_type, 50.0))
		if cond == "min" and val < threshold:
			_fail_graft()
			return null
		if cond == "max" and val > threshold:
			_fail_graft()
			return null

	_graft_timer += delta
	_graft_indicator.progress = minf(_graft_timer / _grafted_mutation.graft_time, 1.0)

	if _graft_timer >= _grafted_mutation.graft_time:
		_succeed_graft()
		return null

	return _tick_passive(delta, 0)

func _tick_grafted(delta: float) -> Variant:
	if _grafted_mutation == null:
		return null
	_passive_timer += delta
	if _passive_timer >= _grafted_mutation.update_time:
		_passive_timer -= _grafted_mutation.update_time
		var stats = _grafted_mutation.stat_change.duplicate()
		for k in stats.keys():
			if stats[k] == 0:
				stats.erase(k)
		if stats.size() > 0:
			_spawn_stat_text(stats)
			return stats
	return null

func _spawn_stat_text(stats: Dictionary) -> void:
	if change_stat_text_info_prefab == null:
		return
	var text := change_stat_text_info_prefab.instantiate() as ChangeStatTextInfo
	text.set_stats(stats)
	add_child(text)
	text.position = -text.size / 2

func _succeed_graft() -> void:
	_state = State.GRAFTED
	_graft_indicator.hide()
	_passive_timer = 0.0
	_update_visuals()
	if GraftCell._cursor_owner == self:
		_update_tooltip()
	grafting_succeeded.emit(self)

func _spawn_mutation_prefab() -> void:
	if _grafted_mutation == null:
		return
	var prefab_path := "res://assets/prefabs/mutations/" + _grafted_mutation.id + ".tscn"
	if not ResourceLoader.exists(prefab_path):
		return
	var packed := load(prefab_path) as PackedScene
	_mutation_node = packed.instantiate()
	if mirrored:
		_mutation_node.scale.x = -1.0
	add_child(_mutation_node)

func _fail_graft() -> void:
	var mutation := _grafted_mutation
	_state = State.CUT
	_grafted_mutation = null
	_graft_timer = 0.0
	_graft_indicator.hide()
	_graft_indicator.progress = 0.0
	if _mutation_node != null:
		_mutation_node.queue_free()
		_mutation_node = null
	_update_visuals()
	_show_fail_floater()
	if GraftCell._cursor_owner == self:
		_update_tooltip()
	grafting_failed.emit(self, mutation)

func _show_fail_floater() -> void:
	var label := Label.new()
	label.text = "Неудачно"
	label.add_theme_color_override("font_color", Color.RED)
	add_child(label)
	label.position = Vector2(-32, -60)
	var tween := create_tween()
	tween.tween_property(label, "position", label.position + Vector2(0, -50), 1.5)
	tween.parallel().tween_property(label, "modulate:a", 0.0, 1.5)
	tween.tween_callback(label.queue_free)

func _update_visuals() -> void:
	if not has_node("Body"):
		return
	var sprite := $Body as Sprite2D
	match _state:
		State.HEALED:
			sprite.show()
			sprite.texture = graft_closed
		State.CUT:
			sprite.show()
			sprite.texture = graft_opened
		State.GRAFTING:
			sprite.show()
			sprite.texture = graft_opened
		State.GRAFTED:
			sprite.hide()

# ---- Input / Hold mechanic ----

func _on_mouse_entered() -> void:
	GraftCell._cursor_owner = self
	Input.set_default_cursor_shape(Input.CURSOR_POINTING_HAND)
	Tooltip.instance.show_for(self)
	_update_tooltip()

func _on_mouse_exited() -> void:
	if GraftCell._cursor_owner == self:
		GraftCell._cursor_owner = null
		Input.set_default_cursor_shape(Input.CURSOR_ARROW)
	Tooltip.instance.hide_from(self)
	_cancel_hold()

func _update_tooltip() -> void:
	if _part_data == null:
		return
	Tooltip.instance.set_graft_cell(_part_data, _state, _grafted_mutation)

func _on_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if not _active or _state == State.GRAFTING or _state == State.GRAFTED:
		return
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT:
			if mb.pressed:
				_start_hold()
			else:
				_cancel_hold()

func _input(event: InputEvent) -> void:
	if not _is_holding:
		return
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT and not mb.pressed:
			_cancel_hold()

func _process(delta: float) -> void:
	if not _is_holding:
		return
	_hold_timer += delta
	if _hold_timer >= HOLD_SHOW_DELAY:
		_hold_indicator.show()
		_hold_indicator.progress = minf(
			(_hold_timer - HOLD_SHOW_DELAY) / (HOLD_DURATION - HOLD_SHOW_DELAY), 1.0)
	if _hold_timer >= HOLD_DURATION:
		_toggle_cut_healed()
		_cancel_hold()

func _toggle_cut_healed() -> void:
	if _state == State.HEALED:
		_state = State.CUT
	elif _state == State.CUT:
		_state = State.HEALED
	_update_visuals()
	if GraftCell._cursor_owner == self:
		_update_tooltip()

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
