extends Node2D
class_name HoldProgressIndicator

var radius: float = 48.0
var width: float = 5.0
var bg_color: Color = Color(0, 0, 0, 0.65)
var fg_color: Color = Color(1, 1, 1, 0.9)

var progress: float = 0.0 : set = _set_progress

func _set_progress(value: float) -> void:
	progress = value
	queue_redraw()

func _draw() -> void:
	if progress <= 0.0:
		return
	draw_arc(Vector2.ZERO, radius, -PI / 2.0, -PI / 2.0 + TAU, 64, bg_color, width + 10.0)
	draw_arc(Vector2.ZERO, radius, -PI / 2.0, -PI / 2.0 + TAU * progress, maxi(2, int(64.0 * progress)), fg_color, width)
