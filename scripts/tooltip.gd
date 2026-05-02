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

func set_house_part(data: HousePartData, current_state: int) -> void:
	size = Vector2(300, 0)
	var food_color := (GameEnums.StatColor[GameEnums.StatType.Food] as Color).to_html()
	var food_name := GameEnums.StatName[GameEnums.StatType.Food] as String
	var state_label := "Открыто" if current_state == 0 else "Закрыто"

	var lines := [
		data.description,
		"",
		"● %s" % state_label,
		"  " + _format_stats(data.stat_change[current_state].stat_changes, data.update_time),
	]

	if current_state == 0:
		lines.append_array([
			"",
			"▲ Закрыть  [удерж. 0.9с]  [color=%s]%s −%d[/color]" % [food_color, food_name, data.upgrade_cost],
			"  " + _format_stats(data.stat_change[1].stat_changes, data.update_time),
		])
	else:
		lines.append_array([
			"",
			"▼ Открыть  [клик]  [color=%s]%s −%d[/color]" % [food_color, food_name, data.downgrade_cost],
			"  " + _format_stats(data.stat_change[0].stat_changes, data.update_time),
		])

	$Text.text = "\n".join(lines)
	await get_tree().process_frame
	size = Vector2(300, 0)

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
