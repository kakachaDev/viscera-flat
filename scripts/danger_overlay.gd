extends ColorRect
class_name DangerOverlay

@export var ticker: HouseStatsTicker

var _tween: Tween = null
var _in_danger := false

func _ready() -> void:
	color = Color(1, 0, 0, 0)
	mouse_filter = MOUSE_FILTER_IGNORE
	ticker.on_stats_changed.connect(_on_stats_changed)

func _on_stats_changed(stats: Dictionary) -> void:
	var danger := false
	for v in stats.values():
		if v < 10.0:
			danger = true
			break

	if danger == _in_danger:
		return
	_in_danger = danger

	if _in_danger:
		_start_pulse()
	else:
		_stop_pulse()

func _start_pulse() -> void:
	if _tween:
		_tween.kill()
	_tween = create_tween().set_loops()
	_tween.tween_property(self, "color:a", 0.45, 0.1)
	_tween.tween_property(self, "color:a", 0.0, 0.9)

func _stop_pulse() -> void:
	if _tween:
		_tween.kill()
		_tween = null
	create_tween().tween_property(self, "color:a", 0.0, 0.3)
