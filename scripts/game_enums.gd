class_name GameEnums
extends Node

enum StatType {
	Light,
	Moisture
}

static var StatColor : Dictionary[StatType, Color] = {
	StatType.Light : Color.GOLD,
	StatType.Moisture : Color.DEEP_SKY_BLUE
}

static var StatName : Dictionary[StatType, String] = {
	StatType.Light : "Освещение",
	StatType.Moisture : "Влажность"
}

enum MetaStat {
	PRODUCTIVITY,   # Продуктивность (урожайность, эффективность)
	STABILITY,      # Стабильность (надёжность, предсказуемость)
	WEIRDNESS       # Странность (мутагенность, непредсказуемость)
}

static var MetaStatName = {
	MetaStat.PRODUCTIVITY: "Продуктивность",
	MetaStat.STABILITY: "Стабильность",
	MetaStat.WEIRDNESS: "Странность"
}
