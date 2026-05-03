extends Node
class_name HouseStatsTicker

signal on_stats_changed()

const UPDATE_TIME := 1.0 / 20.0
const CELLS_PER_STAGE := 2
const TOTAL_STAGES := 4
const CARDS_PER_STAGE := 3

var _stats: Dictionary[GameEnums.StatType, float] = {
	GameEnums.StatType.Light: 50,
	GameEnums.StatType.Moisture: 50
}

@export var cells: Array[GraftCell]
@export var card_tray: Control
@export var hud_stage_label: Label
@export var hud_grafted_label: Label

var mutation_card_prefab: PackedScene

var _active := true
var _stats_changed := false

var _mutation_data: Array[MutationPartData]
var _impacts: Dictionary

var _current_stage: int = 0
var _stage_grafted_count: int = 0

const CARD_WIDTH := 160.0
const CARD_GAP := 16.0

func _ready() -> void:
	mutation_card_prefab = load("res://assets/prefabs/mutation_card.tscn")

	var house_parts: Array[HousePartData] = DataLoader.load_house_parts_from_json("res://data/house_parts.json")
	for i in cells.size():
		cells[i].set_part_data(house_parts[i])
		cells[i].grafting_succeeded.connect(_on_grafting_succeeded)
		cells[i].grafting_failed.connect(_on_grafting_failed)

	_mutation_data = DataLoader.load_mutations_from_json("res://data/mutations.json")
	_impacts = DataLoader.load_meta_impacts_from_json("res://data/mutation_meta_impact.json")

	_base_update_stats(UPDATE_TIME)
	call_deferred("_activate_stage", 0)

func _activate_stage(stage: int) -> void:
	_current_stage = stage
	_stage_grafted_count = 0

	for i in cells.size():
		var is_current := i / CELLS_PER_STAGE == stage
		if is_current:
			cells[i].set_active(true)
		elif cells[i]._state != GraftCell.State.GRAFTED:
			cells[i].set_active(false)

	_deal_cards()
	_update_hud()

func _deal_cards() -> void:
	for child in card_tray.get_children():
		child.queue_free()

	for i in CARDS_PER_STAGE:
		var mutation := _mutation_data[randi() % _mutation_data.size()]
		var card := mutation_card_prefab.instantiate() as MutationCard
		card.setup(mutation)
		card.card_dropped.connect(_on_card_dropped.bind(card))
		card_tray.add_child(card)
		card.animate_in(_card_slot_pos(i, CARDS_PER_STAGE), i * 0.08)

func _relayout_cards() -> void:
	var live: Array = card_tray.get_children().filter(
		func(c): return not c.is_queued_for_deletion())
	var n := live.size()
	for i in n:
		var card := live[i] as MutationCard
		if card == null or card._dragging:
			continue
		var target := _card_slot_pos(i, n)
		card.set_home(target)
		var tw := card.create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
		tw.tween_property(card, "position", target, 0.18)

func _card_slot_pos(idx: int, total: int) -> Vector2:
	var tray_width := card_tray.size.x if card_tray.size.x > 0 else 560.0
	var row_width := CARD_WIDTH * total + CARD_GAP * (total - 1)
	var start_x := maxf(8.0, (tray_width - row_width) / 2.0)
	return Vector2(start_x + idx * (CARD_WIDTH + CARD_GAP), 8.0)

func _on_card_dropped(mutation: MutationPartData, screen_pos: Vector2, card: MutationCard) -> void:
	var stage_start := _current_stage * CELLS_PER_STAGE
	for i in CELLS_PER_STAGE:
		var cell := cells[stage_start + i]
		if not cell.can_accept_card():
			continue
		var cell_rect := Rect2(cell.global_position - Vector2(64, 64), Vector2(128, 128))
		if cell_rect.has_point(screen_pos):
			cell.start_grafting(mutation)
			card.queue_free()
			_relayout_cards.call_deferred()
			return
	card.snap_back()

func _on_grafting_succeeded(cell: GraftCell) -> void:
	_stage_grafted_count += 1
	_update_hud()
	if _stage_grafted_count >= CELLS_PER_STAGE:
		if _current_stage < TOTAL_STAGES - 1:
			_activate_stage(_current_stage + 1)
		else:
			_active = false
			_show_end_game()

func _on_grafting_failed(_cell: GraftCell, _mutation: MutationPartData) -> void:
	if mutation_card_prefab == null:
		return
	var new_card := mutation_card_prefab.instantiate() as MutationCard
	var new_mutation := _mutation_data[randi() % _mutation_data.size()]
	new_card.setup(new_mutation)
	new_card.card_dropped.connect(_on_card_dropped.bind(new_card))
	card_tray.add_child(new_card)
	_relayout_cards()
	new_card.animate_in(new_card._home_position)

func _base_update_stats(delta: float) -> void:
	if not _active:
		return

	for cell in cells:
		if cell.visible:
			_change_stat(cell.tick(delta, _stats))

	if _stats_changed:
		on_stats_changed.emit(_stats)
		_stats_changed = false

	get_tree().create_timer(UPDATE_TIME).timeout.connect(_base_update_stats.bind(UPDATE_TIME))

func _update_hud() -> void:
	if hud_stage_label:
		hud_stage_label.text = "Этап: %d/%d" % [_current_stage + 1, TOTAL_STAGES]
	if hud_grafted_label:
		hud_grafted_label.text = "Привито: %d/%d" % [_stage_grafted_count, CELLS_PER_STAGE]

func _show_end_game() -> void:
	var grafted: Array[MutationPartData] = []
	for cell in cells:
		if cell._state == GraftCell.State.GRAFTED and cell._grafted_mutation != null:
			grafted.append(cell._grafted_mutation)
	EndGame.instance.show_end_game(_impacts, grafted)

func _change_stat(new_stats) -> void:
	if new_stats == null:
		return
	for k in new_stats.keys():
		_stats[k] = clampf(_stats.get_or_add(k, 0) + new_stats[k], 0.0, 100.0)
	_stats_changed = true
