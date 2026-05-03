extends Control
class_name MutationCard

signal card_dropped(mutation: MutationPartData, screen_pos: Vector2)

var _mutation: MutationPartData = null
var _dragging := false
var _drag_offset := Vector2.ZERO
var _drag_target := Vector2.ZERO
var _home_position := Vector2.ZERO
var _hover_tween: Tween = null

@onready var _title_label: RichTextLabel = $Title
@onready var _mutation_image: TextureRect = $mutation_image
@onready var _wait_title: RichTextLabel = $VBox/WAIT_TITLE
@onready var _mut_title: RichTextLabel  = $VBox/MUT_TITLE
@onready var _stat_type:  RichTextLabel = $VBox/stat_type
@onready var _stat_wait:  RichTextLabel = $VBox/stat_wait_value
@onready var _stat_mut:   RichTextLabel = $VBox/stat_mut_value
@onready var _stat_type2: RichTextLabel = $VBox/stat_type2
@onready var _stat_wait2: RichTextLabel = $VBox/stat_wait_value2
@onready var _stat_mut2:  RichTextLabel = $VBox/stat_mut_value2

func _ready() -> void:
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	pivot_offset = size / 2.0

func setup(mutation: MutationPartData) -> void:
	_mutation = mutation
	await ready
	_update_display()

func get_mutation() -> MutationPartData:
	return _mutation

func set_home(pos: Vector2) -> void:
	_home_position = pos

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
	tween.parallel().tween_property(self, "scale", Vector2.ONE, 0.2)
	tween.parallel().tween_property(self, "rotation", 0.0, 0.15)

func _update_display() -> void:
	_title_label.text = _mutation.description

	_wait_title.text = "Прив. (%.0fс)" % _mutation.graft_time
	_mut_title.text  = "Эфф. (%.1fс)" % _mutation.update_time

	# Set mutation image from prefab sprite
	var prefab_path := "res://assets/prefabs/mutations/" + _mutation.id + ".tscn"
	if ResourceLoader.exists(prefab_path):
		var packed := load(prefab_path) as PackedScene
		var node := packed.instantiate()
		if node is Sprite2D:
			_mutation_image.texture = (node as Sprite2D).texture
		node.queue_free()

	# Populate stat rows: row 1 = Light, row 2 = Moisture
	_fill_stat_row(
		_stat_type, _stat_wait, _stat_mut,
		GameEnums.StatType.Light, "Свет", Color.GOLD
	)
	_fill_stat_row(
		_stat_type2, _stat_wait2, _stat_mut2,
		GameEnums.StatType.Moisture, "Влажн.", Color.DEEP_SKY_BLUE
	)

func _fill_stat_row(
	lbl_type: RichTextLabel,
	lbl_wait: RichTextLabel,
	lbl_mut: RichTextLabel,
	stat: GameEnums.StatType,
	stat_name: String,
	stat_color: Color
) -> void:
	var color_hex := stat_color.to_html()
	var has_anything := false

	# Condition
	var cond_text := ""
	for key in _mutation.conditions.keys():
		var sep := (key as String).rfind("_")
		var key_stat := (key as String).substr(0, sep)
		var key_cond := (key as String).substr(sep + 1)
		if DataLoader._string_to_stat_type(key_stat) == stat:
			var val: float = _mutation.conditions[key]
			var label := "мин" if key_cond == "min" else "макс"
			cond_text = "%s %.0f%%" % [label, val]
			has_anything = true
			break
	lbl_wait.text = cond_text

	# Effect
	var effect_text := ""
	if _mutation.stat_change.has(stat):
		var v := _mutation.stat_change[stat]
		var sign := "+" if v > 0 else ""
		var eff_color := Color.GREEN if v > 0 else Color.TOMATO
		effect_text = "[color=%s]%s%.1f%%[/color]" % [eff_color.to_html(), sign, v]
		has_anything = true
	lbl_mut.text = effect_text

	# Stat type label (only show if row has content)
	if has_anything:
		lbl_type.text = "[color=%s]%s[/color]" % [color_hex, stat_name]
	else:
		lbl_type.text = ""

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
	position = _home_position
	_drag_offset = get_global_mouse_position() - global_position
	_drag_target = global_position
	z_index = 100
	var tween := create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	tween.tween_property(self, "scale", Vector2(0.85, 0.85), 0.12)

func _end_drag() -> void:
	_dragging = false
	z_index = 0
	card_dropped.emit(_mutation, get_global_mouse_position())

func _process(delta: float) -> void:
	if not _dragging:
		return
	_drag_target = get_global_mouse_position() - _drag_offset
	global_position = global_position.lerp(_drag_target, minf(1.0, 15.0 * delta))
	var dx := _drag_target.x - global_position.x
	rotation = lerpf(rotation, clampf(dx * 0.012, -0.4, 0.4), minf(1.0, 10.0 * delta))

func _on_mouse_entered() -> void:
	if _dragging:
		return
	_kill_hover_tween()
	_hover_tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	_hover_tween.tween_property(self, "scale", Vector2(1.2, 1.2), 0.15)
	_hover_tween.parallel().tween_property(self, "position:y", _home_position.y - 20.0, 0.15)

func _on_mouse_exited() -> void:
	if _dragging:
		return
	_kill_hover_tween()
	_hover_tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	_hover_tween.tween_property(self, "scale", Vector2.ONE, 0.15)
	_hover_tween.parallel().tween_property(self, "position:y", _home_position.y, 0.12)

func _kill_hover_tween() -> void:
	if _hover_tween and _hover_tween.is_valid():
		_hover_tween.kill()
	_hover_tween = null
