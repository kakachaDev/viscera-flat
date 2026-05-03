extends Control
class_name EndGame

static var instance: EndGame

var _lbl_aes: Label
var _lbl_func: Label
var _lbl_mon: Label
var _lbl_time: Label
var _lbl_desc: RichTextLabel

func _init() -> void:
	instance = self

func _ready() -> void:
	_build_layout()

func _build_layout() -> void:
	# Right half dark overlay
	var overlay := ColorRect.new()
	overlay.color = Color(0.04, 0.04, 0.07, 1.0)
	overlay.anchor_left = 0.5
	overlay.anchor_top = 0.0
	overlay.anchor_right = 1.0
	overlay.anchor_bottom = 1.0
	overlay.offset_left = 0
	overlay.offset_top = 0
	overlay.offset_right = 0
	overlay.offset_bottom = 0
	add_child(overlay)

	# Content VBox on right half
	var vbox := VBoxContainer.new()
	vbox.anchor_left = 0.5
	vbox.anchor_top = 0.0
	vbox.anchor_right = 1.0
	vbox.anchor_bottom = 1.0
	vbox.offset_left = 32
	vbox.offset_top = 40
	vbox.offset_right = -32
	vbox.offset_bottom = -32
	vbox.add_theme_constant_override("separation", 14)
	add_child(vbox)

	var title := Label.new()
	title.text = "ИМАГО ДОСТИГНУТО"
	title.add_theme_font_size_override("font_size", 30)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "Дом завершил метаморфозу"
	subtitle.add_theme_font_size_override("font_size", 15)
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.modulate = Color(0.75, 0.75, 0.75)
	vbox.add_child(subtitle)

	vbox.add_child(_make_separator())

	var stats_header := Label.new()
	stats_header.text = "Статистика"
	stats_header.add_theme_font_size_override("font_size", 18)
	vbox.add_child(stats_header)

	_lbl_aes  = _make_stat_label(); vbox.add_child(_lbl_aes)
	_lbl_func = _make_stat_label(); vbox.add_child(_lbl_func)
	_lbl_mon  = _make_stat_label(); vbox.add_child(_lbl_mon)
	_lbl_time = _make_stat_label(); vbox.add_child(_lbl_time)

	vbox.add_child(_make_separator())

	_lbl_desc = RichTextLabel.new()
	_lbl_desc.bbcode_enabled = true
	_lbl_desc.fit_content = true
	_lbl_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_lbl_desc.add_theme_font_size_override("normal_font_size", 14)
	vbox.add_child(_lbl_desc)

	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(spacer)

	var btn_row := HBoxContainer.new()
	btn_row.add_theme_constant_override("separation", 16)
	vbox.add_child(btn_row)

	var btn_same := Button.new()
	btn_same.text = "Ещё раз с этим семенем"
	btn_same.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn_same.pressed.connect(_on_same_seed)
	btn_row.add_child(btn_same)

	var btn_new := Button.new()
	btn_new.text = "Новое семя"
	btn_new.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn_new.pressed.connect(_on_new_seed)
	btn_row.add_child(btn_new)

func _make_stat_label() -> Label:
	var lbl := Label.new()
	lbl.add_theme_font_size_override("font_size", 14)
	return lbl

func _make_separator() -> HSeparator:
	var sep := HSeparator.new()
	sep.add_theme_constant_override("separation", 6)
	return sep

func show_end_game(impacts: Dictionary, parts: Array[MutationPartData], game_time: float = 0.0) -> void:
	var meta_stats := _calculate_meta_stats(impacts, parts)
	var description := _get_result_description(meta_stats)

	var aes: int  = meta_stats[GameEnums.MetaStat.AESTHETICS]
	var func_: int = meta_stats[GameEnums.MetaStat.FUNCTIONALITY]
	var mon: int  = meta_stats[GameEnums.MetaStat.MONSTROUSNESS]

	_lbl_aes.text  = "Эстетика:            %d / 100" % aes
	_lbl_func.text = "Функциональность: %d / 100" % func_
	_lbl_mon.text  = "Чудовищность:      %d / 100" % mon

	var minutes := int(game_time) / 60
	var seconds := int(game_time) % 60
	_lbl_time.text = "Время мутации: %d:%02d" % [minutes, seconds]

	_lbl_desc.text = "[i]%s[/i]" % description

	modulate.a = 0.0
	show()
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.5)

func _on_same_seed() -> void:
	get_tree().reload_current_scene()

func _on_new_seed() -> void:
	randomize()
	get_tree().reload_current_scene()

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
