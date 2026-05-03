extends Node
class_name DataLoader

static func load_house_parts_from_json(file_path: String) -> Array[HousePartData]:
	var parts: Array[HousePartData] = []
	
	var file = FileAccess.open(file_path, FileAccess.READ)
	if not file:
		push_error("Не удалось открыть файл: ", file_path)
		return parts
	
	var json_string = file.get_as_text()
	var json = JSON.new()
	var parse_result = json.parse(json_string)
	
	if parse_result != OK:
		push_error("Ошибка парсинга JSON: ", json.get_error_message())
		return parts
	
	var data = json.data
	
	if typeof(data) != TYPE_ARRAY:
		push_error("JSON должен содержать массив")
		return parts
	
	for item in data:
		var part = HousePartData.new()
		part.description = item.get("description", "")
		part.update_time = item.get("update_time", 1.0)
		part.start_state = item.get("start_state", 0)
		
		if item.has("stat_change"):
			for stat_change_data in item["stat_change"]:
				var farming_stats = FarmingStats.new()
				
				if stat_change_data.has("stat_changes"):
					for stat_name in stat_change_data["stat_changes"]:
						var stat_type = _string_to_stat_type(stat_name)
						var value = float(stat_change_data["stat_changes"][stat_name])
						farming_stats.stat_changes[stat_type] = value
				
				part.stat_change.append(farming_stats)
		
		parts.append(part)
	
	file.close()
	return parts

static func load_mutations_from_json(file_path: String) -> Array[MutationPartData]:
	var mutations: Array[MutationPartData] = []
	var file = FileAccess.open(file_path, FileAccess.READ)
	var json_string = file.get_as_text()
	var json = JSON.new()
	json.parse(json_string)
	var data = json.data
	
	for mut_data in data:
		var mut = MutationPartData.new()
		mut.id = mut_data.get("id", "")
		mut.description = mut_data.get("description", "")
		mut.update_time = mut_data.get("update_time", 1.0)
		mut.graft_time = mut_data.get("graft_time", 8.0)
		for condition_key in mut_data.get("conditions", {}).keys():
			mut.conditions[condition_key] = float(mut_data["conditions"][condition_key])
		
		for stat_name in mut_data.get("stat_change", {}):
			var stat_type = _string_to_stat_type(stat_name)
			mut.stat_change[stat_type] = mut_data["stat_change"][stat_name]
		
		mutations.append(mut)
	
	return mutations

static func load_meta_impacts_from_json(file_path: String) -> Dictionary:
	var impacts: Dictionary = {}
	var file = FileAccess.open(file_path, FileAccess.READ)
	
	if not file:
		push_error("Не удалось открыть файл мета-эффектов: ", file_path)
		return impacts
	
	var json_string = file.get_as_text()
	var json = JSON.new()
	var parse_result = json.parse(json_string)
	
	if parse_result != OK:
		push_error("Ошибка парсинга JSON мета-эффектов: ", json.get_error_message())
		return impacts
	
	var data = json.data
	
	for item in data:
		var mutation_id = item.get("mutation_id", "")
		if (mutation_id as String).is_empty(): continue
		
		impacts[mutation_id] = {}
		
		var impacts_data = item.get("impacts", {})
		if impacts_data.size() == 0: continue
		
		for meta_stat_name in impacts_data:
			var stat = _string_to_meta_stat(meta_stat_name)
			impacts[mutation_id][stat] = impacts_data[meta_stat_name]
	
	file.close()
	return impacts

static func _string_to_meta_stat(stat_name: String) -> GameEnums.MetaStat:
	match stat_name:
		"AESTHETICS":
			return GameEnums.MetaStat.AESTHETICS
		"FUNCTIONALITY":
			return GameEnums.MetaStat.FUNCTIONALITY
		"MONSTROUSNESS":
			return GameEnums.MetaStat.MONSTROUSNESS
		_:
			push_warning("Неизвестный тип мета-статистики: ", stat_name)
			return GameEnums.MetaStat.AESTHETICS

static func _string_to_stat_type(stat_name: String) -> GameEnums.StatType:
	match stat_name:
		"Light":
			return GameEnums.StatType.Light
		"Moisture":
			return GameEnums.StatType.Moisture
		_:
			push_warning("Неизвестный тип статистики: ", stat_name)
			return GameEnums.StatType.Light
