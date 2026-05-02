extends Control
class_name EndGame

static var instance: EndGame

func _init() -> void:
	instance = self

func show_lose(reason: String) -> void:
	$Text.text = "[center]\n\n\n[font_size=52]%s[/font_size]\n\n[font_size=24]Игра окончена[/font_size][/center]" % reason
	show()

func show_end_game(impacts: Dictionary, parts: Array[MutationPartData]):
	var meta_stats = _calculate_meta_stats(impacts, parts)
	var description = _get_result_description(meta_stats)
	
	var message = """
Результат мутаций:

Продуктивность: %d
Стабильность: %d
Странность: %d

%s
""" % [
	meta_stats[GameEnums.MetaStat.PRODUCTIVITY],
	meta_stats[GameEnums.MetaStat.STABILITY],
	meta_stats[GameEnums.MetaStat.WEIRDNESS],
	description
]
	$Text.text = message
	
	show()


func _calculate_meta_stats(impacts: Dictionary, parts: Array[MutationPartData]) -> Dictionary[GameEnums.MetaStat, int]:
	var totals: Dictionary[GameEnums.MetaStat, int] = {
		GameEnums.MetaStat.PRODUCTIVITY: 0,
		GameEnums.MetaStat.STABILITY: 0,
		GameEnums.MetaStat.WEIRDNESS: 0
	}
	
	for mutation in parts:
		
		var impact = impacts.get(mutation.id, {})
		for meta_stat in totals.keys():
			totals[meta_stat] += impact.get(meta_stat, 0)
	
	var max_possible = 8 * 4
	for key in totals:
		totals[key] = clamp((totals[key] + max_possible) * 100 / (2 * max_possible), 0, 100)
	
	return totals

func _get_result_description(meta_stats: Dictionary) -> String:
	var prod = meta_stats[GameEnums.MetaStat.PRODUCTIVITY]
	var stab = meta_stats[GameEnums.MetaStat.STABILITY]
	var weird = meta_stats[GameEnums.MetaStat.WEIRDNESS]
	
	if prod >= 70 and stab >= 70:
		return "Идеальная ферма: всё растёт, всё предсказуемо, скукотища!"
	elif prod >= 70 and weird >= 70:
		return "Безумный урожай: растения плодоносят, но вы не знаете чем именно..."
	elif stab >= 70 and weird >= 70:
		return "Стабильная аномалия: предсказуемый хаос, странно но надёжно"
	elif prod >= 70:
		return "Промышленный комплекс: еды до фига, но работать здесь — ад"
	elif stab >= 70:
		return "Консерватория: ничего нового, но хотя бы не разваливается"
	elif weird >= 70:
		return "Паноптикум: лучше не спрашивать, что здесь происходит"
	elif prod >= 40 and stab >= 40:
		return "Добротная теплица: хороша, но без изюминки"
	elif prod >= 40 and weird >= 40:
		return "Мутагенный огород: то сгниёт, то зацветёт"
	elif stab >= 40 and weird >= 40:
		return "Зыбкое равновесие: держится на честном слове"
	else:
		return "Руины: лучше снести и построить заново"
