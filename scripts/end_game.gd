extends Control
class_name EndGame

static var instance: EndGame

func _init() -> void:
	instance = self

func show_end_game(impacts: Dictionary, parts: Array[MutationPartData]):
	var meta_stats := _calculate_meta_stats(impacts, parts)
	var description := _get_result_description(meta_stats)

	var aes: int  = meta_stats[GameEnums.MetaStat.AESTHETICS]
	var func_: int = meta_stats[GameEnums.MetaStat.FUNCTIONALITY]
	var mon: int  = meta_stats[GameEnums.MetaStat.MONSTROUSNESS]

	var message := """
Результат мутаций дерева:

Эстетика:          %d%%
Функциональность:  %d%%
Чудовищность:      %d%%

%s
""" % [aes, func_, mon, description]

	$Text.text = message
	show()


func _calculate_meta_stats(impacts: Dictionary, parts: Array[MutationPartData]) -> Dictionary:
	var totals := {
		GameEnums.MetaStat.AESTHETICS:    0,
		GameEnums.MetaStat.FUNCTIONALITY: 0,
		GameEnums.MetaStat.MONSTROUSNESS: 0,
	}

	for mutation in parts:
		var impact: Dictionary = impacts.get(mutation.id, {})
		for meta_stat in totals.keys():
			totals[meta_stat] += impact.get(meta_stat, 0)

	var max_possible := parts.size() * 4
	if max_possible == 0:
		max_possible = 1
	for key in totals:
		totals[key] = clampi((totals[key] + max_possible) * 100 / (2 * max_possible), 0, 100)

	return totals


func _get_result_description(meta_stats: Dictionary) -> String:
	var aes: int   = meta_stats[GameEnums.MetaStat.AESTHETICS]
	var func_: int = meta_stats[GameEnums.MetaStat.FUNCTIONALITY]
	var mon: int   = meta_stats[GameEnums.MetaStat.MONSTROUSNESS]

	if aes >= 70 and func_ >= 70 and mon >= 70:
		return "Апофеоз: прекрасное, полезное и ужасающее одновременно. Это уже не дерево."
	elif aes >= 70 and func_ >= 70:
		return "Идеальный организм: красота и польза в гармонии."
	elif aes >= 70 and mon >= 70:
		return "Чудовищная красота: завораживает и пугает в равной мере."
	elif func_ >= 70 and mon >= 70:
		return "Эффективный монстр: уродливо, но невероятно живуч."
	elif aes >= 70:
		return "Скульптура из плоти: бесполезно, зато глаз не оторвать."
	elif func_ >= 70:
		return "Биореактор: некрасиво, зато работает на полную."
	elif mon >= 70:
		return "Ночной кошмар: непонятно что это, и лучше не знать."
	elif aes >= 45 and func_ >= 45:
		return "Жизнеспособный гибрид: ничего выдающегося, но держится."
	elif aes >= 45 and mon >= 45:
		return "Странная красота: немного жутковато, но по-своему мило."
	elif func_ >= 45 and mon >= 45:
		return "Зловещий механизм: пугает, но свою работу делает."
	else:
		return "Недоразумение: дерево смотрит на вас с немым укором."
