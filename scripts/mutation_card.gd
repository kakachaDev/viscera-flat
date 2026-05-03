extends PanelContainer
class_name MutationCard

signal card_dropped(mutation: MutationPartData, screen_pos: Vector2)

var _mutation: MutationPartData = null
var _dragging := false
var _drag_offset := Vector2.ZERO
var _home_position := Vector2.ZERO
var _hover_tween: Tween = null

@onready var _title_label: Label = $VBox/Title
@onready var _stats_label: RichTextLabel = $VBox/Stats

func _ready() -> void:
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)

func setup(mutation: MutationPartData) -> void:
	_mutation = mutation
	await ready
	_update_display()

func get_mutation() -> MutationPartData:
	return _mutation

# Call after positioning the card in the tray so hover and snap_back know where home is.
func set_home(pos: Vector2) -> void:
	_home_position = pos

# Slide in from below the tray with optional delay for staggering.
func animate_in(target_pos: Vector2, delay: float = 0.0) -> void:
	_home_position = target_pos
	position = Vector2(target_pos.x, 200.0)
	modulate.a = 0.0
	var tween := create_tween()
	if delay > 0.0:
		tween.tween_interval(delay)
	tween.tween_property(self, "position", target_pos, 0.3) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tween.parallel().tween_property(self, "modulate:a", 1.0, 0.2)

func snap_back() -> void:
	_dragging = false
	z_index = 0
	var tween := create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	tween.tween_property(self, "position", _home_position, 0.2)

func _update_display() -> void:
	_title_label.text = _mutation.description

	var lines: Array[String] = []
	for key in _mutation.conditions.keys():
		var sep := (key as String).rfind("_")
		var stat_name := (key as String).substr(0, sep)
		var cond_type := (key as String).substr(sep + 1)
		var val: float = _mutation.conditions[key]
		var label := "мин" if cond_type == "min" else "макс"
		var color := Color.GOLD.to_html() if stat_name == "Light" else Color.DEEP_SKY_BLUE.to_html()
		var display_name := "Свет" if stat_name == "Light" else "Влажн."
		lines.append("[color=%s]%s %s: %.0f%%[/color]" % [color, display_name, label, val])

	lines.append("Приживл.: %.0fс" % _mutation.graft_time)

	for stat_key in _mutation.stat_change.keys():
		var color := (GameEnums.StatColor.get(stat_key, Color.WHITE) as Color).to_html()
		var name := GameEnums.StatName.get(stat_key, "?") as String
		var v := _mutation.stat_change[stat_key]
		var sign := "+" if v > 0 else ""
		lines.append("[color=%s]%s %s%.1f%%[/color]" % [color, name, sign, v])

	_stats_label.text = "\n".join(lines)

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT:
			if mb.pressed and not _dragging:
				_start_drag()
			elif not mb.pressed and _dragging:
				_end_drag()

func _start_drag() -> void:
	_dragging = true
	_kill_hover_tween()
	position = _home_position  # snap out of hover offset before dragging
	_drag_offset = get_global_mouse_position() - global_position
	z_index = 100

func _end_drag() -> void:
	_dragging = false
	z_index = 0
	card_dropped.emit(_mutation, get_global_mouse_position())

func _process(_delta: float) -> void:
	if _dragging:
		global_position = get_global_mouse_position() - _drag_offset

func _on_mouse_entered() -> void:
	if _dragging:
		return
	_kill_hover_tween()
	_hover_tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	_hover_tween.tween_property(self, "position:y", _home_position.y - 12.0, 0.12)

func _on_mouse_exited() -> void:
	if _dragging:
		return
	_kill_hover_tween()
	_hover_tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	_hover_tween.tween_property(self, "position:y", _home_position.y, 0.12)

func _kill_hover_tween() -> void:
	if _hover_tween and _hover_tween.is_valid():
		_hover_tween.kill()
	_hover_tween = null
