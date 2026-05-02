extends Node2D
class_name HoldProgressIndicator

const RADIUS := 48.0
const WIDTH := 5.0

var progress: float = 0.0 : set = _set_progress

func _set_progress(value: float) -> void:
	progress = value
	queue_redraw()

func _draw() -> void:
	if progress <= 0.0:
		return
	draw_arc(Vector2.ZERO, RADIUS, -PI / 2.0, -PI / 2.0 + TAU, 64, Color(1, 1, 1, 0.2), WIDTH)
	draw_arc(Vector2.ZERO, RADIUS, -PI / 2.0, -PI / 2.0 + TAU * progress, maxi(2, int(64.0 * progress)), Color(1, 1, 1, 0.9), WIDTH)
