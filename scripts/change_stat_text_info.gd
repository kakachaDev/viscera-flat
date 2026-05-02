extends RichTextLabel
class_name ChangeStatTextInfo

@export var speed: float = 1

func set_stats(stats: Dictionary[GameEnums.StatType, float]):
	var text_parts = []
	for stat in stats.keys():
		text_parts.append("[font_size=%d][color=%s]%s%.2f%s[/color][/font_size]" % [
			(int)(16 + 8 * abs(stats[stat])),
			(GameEnums.StatColor.get(stat, Color.WHITE) as Color).to_html(),
			"+" if stats[stat] > 0 else "",
			stats[stat],
			"%"
		])
	text = " ".join(text_parts)

func set_insufficient(stat: GameEnums.StatType) -> void:
	var color := (GameEnums.StatColor.get(stat, Color.WHITE) as Color).to_html()
	var stat_name := GameEnums.StatName.get(stat, GameEnums.StatType.find_key(stat)) as String
	text = "[font_size=16]Недостаточно [color=%s]%s[/color][/font_size]" % [color, stat_name]

func _ready() -> void:
	var tween = get_tree().create_tween()
	tween.tween_property(self, "modulate", Color.TRANSPARENT, 1.0)
	tween.tween_callback(self.queue_free)


func _process(delta: float) -> void:
	position += Vector2.UP * speed * delta
