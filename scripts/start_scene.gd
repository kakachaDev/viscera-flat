extends Node

enum Phase { FADE_IN, TEXT_1, ANIM_PLAY, TEXT_2, FADE_OUT }

const TEXT_1 := "Современные технологии позволяют выращивать дома прямо из растений"
const TEXT_2 := "А вот какой дом по итогу вырастет — зависит от вас"
const CHAR_DELAY := 0.035

var _phase := Phase.FADE_IN
var _overlay: ColorRect
var _subs: Panel
var _lbl_text: Label
var _lbl_next: Label
var _anim_main: AnimationPlayer
var _anim_seed: AnimationPlayer
var _typing := false
var _typing_timer := 0.0

func _ready() -> void:
	_subs = $CanvasLayer/Subs
	_lbl_text = $CanvasLayer/Subs/Text
	_lbl_next = $CanvasLayer/Subs/Next
	_anim_main = $Start
	_anim_seed = $SeedClosed/AnimationPlayer

	_overlay = ColorRect.new()
	_overlay.color = Color(0, 0, 0, 1)
	_overlay.anchor_right = 1.0
	_overlay.anchor_bottom = 1.0
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	$CanvasLayer.add_child(_overlay)

	_subs.hide()
	_lbl_next.hide()
	_anim_seed.play("seed")

	var tween := create_tween()
	tween.tween_property(_overlay, "color:a", 0.0, 1.5)
	tween.tween_callback(_start_text_1)

func _start_text_1() -> void:
	_phase = Phase.TEXT_1
	_show_text(TEXT_1)

func _show_text(text: String) -> void:
	_lbl_text.text = text
	_lbl_text.visible_characters = 0
	_lbl_next.hide()
	_subs.show()
	_typing = true
	_typing_timer = 0.0

func _process(delta: float) -> void:
	if not _typing:
		return
	_typing_timer += delta
	var chars := int(_typing_timer / CHAR_DELAY)
	if chars >= _lbl_text.text.length():
		_finish_typing()
	else:
		_lbl_text.visible_characters = chars

func _finish_typing() -> void:
	_lbl_text.visible_characters = -1
	_typing = false
	_lbl_next.show()

func _input(event: InputEvent) -> void:
	if _phase == Phase.FADE_IN or _phase == Phase.ANIM_PLAY or _phase == Phase.FADE_OUT:
		return
	if not (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT):
		return
	get_viewport().set_input_as_handled()

	if _typing:
		_finish_typing()
		return

	match _phase:
		Phase.TEXT_1:
			_phase = Phase.ANIM_PLAY
			_subs.hide()
			_anim_main.play("start")
			_anim_main.animation_finished.connect(_on_anim_finished, CONNECT_ONE_SHOT)
		Phase.TEXT_2:
			_phase = Phase.FADE_OUT
			_subs.hide()
			var tween := create_tween()
			tween.tween_property(_overlay, "color:a", 1.0, 1.0)
			tween.tween_callback(func(): get_tree().change_scene_to_file("res://scenes/Main.tscn"))

func _on_anim_finished(_anim_name: StringName) -> void:
	_phase = Phase.TEXT_2
	_show_text(TEXT_2)
