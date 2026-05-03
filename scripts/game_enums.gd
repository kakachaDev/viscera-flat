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
	AESTHETICS,      # Эстетика (симметрия, редкость органов)
	FUNCTIONALITY,   # Функциональность (пассивный доход ресурсов)
	MONSTROUSNESS    # Чудовищность (шипы, глаза, страх)
}

static var MetaStatName = {
	MetaStat.AESTHETICS:    "Эстетика",
	MetaStat.FUNCTIONALITY: "Функциональность",
	MetaStat.MONSTROUSNESS: "Чудовищность"
}
