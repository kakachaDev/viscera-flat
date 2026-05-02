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

func set_text(description: String, stats: Dictionary[GameEnums.StatType, float], update_time: float):
	size = Vector2(250, 0)
	var lines = [description]
	
	if stats.size() > 0:
		lines.append_array([ "", "Each %.2fs:" % update_time])
		
		for stat in stats.keys():
			lines.append("[color=%s]%s[/color]: %s%.2f%s" % [
				(GameEnums.StatColor.get(stat, Color.WHITE) as Color).to_html(),
				GameEnums.StatName.get(stat, GameEnums.StatType.find_key(stat)),
				"+" if stats[stat] > 0 else "",
				stats[stat],
				"%"
			])
	
	$Text.text = "\n".join(lines)
	
	await get_tree().process_frame
	size = Vector2(250, 0)

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		position = get_global_mouse_position() + Vector2(30,30)
