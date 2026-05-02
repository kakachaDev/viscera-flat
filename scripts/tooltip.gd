extends PanelContainer
class_name Tooltip

static var instance: Tooltip

var _owner: Node = null

func _init() -> void:
	instance = self

func _ready() -> void:
	hide()

func show_for(node: Node) -> void:
	_owner = node
	show()

func hide_from(node: Node) -> void:
	if _owner == node:
		_owner = null
		hide()

func set_graft_cell(part_data: HousePartData, state: GraftCell.State, mutation: MutationPartData) -> void:
	size = Vector2(300, 0)
	var lines: Array[String] = []

	match state:
		GraftCell.State.HEALED:
			lines = [
				"[b]Заживленная ячейка[/b]",
				"",
				_format_stats(part_data.stat_change[1].stat_changes, part_data.update_time),
				"",
				"[color=aaaaaa]Удерж. 0.9с → Разрезать[/color]",
			]
		GraftCell.State.CUT:
			lines = [
				"[b]Разрезанная ячейка[/b]",
				"",
				_format_stats(part_data.stat_change[0].stat_changes, part_data.update_time),
				"",
				"[color=aaaaaa]Удерж. 0.9с → Заживить[/color]",
				"[color=aaaaaa]Перетащите карточку мутации[/color]",
			]
		GraftCell.State.GRAFTING:
			if mutation != null:
				lines = [
					"[b]Прививка: %s[/b]" % mutation.description,
					"",
					_format_conditions(mutation),
					"",
					"Итог: " + _format_stats(mutation.stat_change, mutation.update_time),
				]
		GraftCell.State.GRAFTED:
			if mutation != null:
				lines = [
					"[b]Привито: %s[/b]" % mutation.description,
					"",
					_format_stats(mutation.stat_change, mutation.update_time),
				]

	$Text.text = "\n".join(lines)
	await get_tree().process_frame
	size = Vector2(300, 0)

func set_mutation(data: MutationPartData) -> void:
	size = Vector2(300, 0)
	var lines := [
		data.description,
		"",
		_format_stats(data.stat_change, data.update_time),
	]
	$Text.text = "\n".join(lines)
	await get_tree().process_frame
	size = Vector2(300, 0)

func _format_conditions(mutation: MutationPartData) -> String:
	var parts: Array[String] = []
	for key in mutation.conditions.keys():
		var sep := (key as String).rfind("_")
		var stat_name := (key as String).substr(0, sep)
		var cond := (key as String).substr(sep + 1)
		var val: float = mutation.conditions[key]
		var label := "≥" if cond == "min" else "≤"
		var stat_type := DataLoader._string_to_stat_type(stat_name)
		var color := (GameEnums.StatColor.get(stat_type, Color.WHITE) as Color).to_html()
		var name := GameEnums.StatName.get(stat_type, stat_name) as String
		parts.append("[color=%s]%s %s %.0f%%[/color]" % [color, name, label, val])
	return "Условия: " + ", ".join(parts)

func _format_stats(stats: Dictionary, update_time: float) -> String:
	var parts: Array[String] = []
	for stat in stats.keys():
		var color := (GameEnums.StatColor.get(stat, Color.WHITE) as Color).to_html()
		var name := GameEnums.StatName.get(stat, "?") as String
		var sign := "+" if stats[stat] > 0 else ""
		parts.append("[color=%s]%s %s%.1f%%[/color]" % [color, name, sign, stats[stat]])
	return "каждые %.1fс:  %s" % [update_time, "  ".join(parts)]

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		position = get_global_mouse_position() + Vector2(30, 30)
