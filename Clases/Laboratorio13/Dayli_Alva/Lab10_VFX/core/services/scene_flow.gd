extends Node

const LEVELS: Dictionary = {
	&"level_01": preload("res://resources/levels/level_01.tres"),
	&"level_02": preload("res://resources/levels/level_02.tres"),
	&"level_03": preload("res://resources/levels/level_03.tres"),
}

var is_changing_scene: bool = false
var _fade_rect: ColorRect

func _ready() -> void:
	var transition_layer := CanvasLayer.new()
	transition_layer.layer = 100
	add_child(transition_layer)

	_fade_rect = ColorRect.new()
	_fade_rect.name = "Fade"
	_fade_rect.color = Color(0.0, 0.0, 0.0, 0.0)
	_fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	transition_layer.add_child(_fade_rect)

func get_level_data(level_id: StringName) -> LevelData:
	return LEVELS.get(level_id) as LevelData

func has_level(level_id: StringName) -> bool:
	return get_level_data(level_id) != null

func go_to_level(level_id: StringName) -> void:
	if is_changing_scene:
		return
	var level_data := get_level_data(level_id)
	if level_data == null:
		push_error("Nivel desconocido: %s" % level_id)
		return
	GameState.current_level_id = level_id
	change_to(level_data.scene_path)

func change_to(scene_path: String) -> void:
	if is_changing_scene:
		return
	if not ResourceLoader.exists(scene_path):
		push_error("SceneFlow no encuentra la escena: " + scene_path)
		return
	is_changing_scene = true
	call_deferred("_perform_transition", scene_path)

func _perform_transition(scene_path: String) -> void:
	await _fade_to(1.0)
	var error := get_tree().change_scene_to_file(scene_path)
	if error != OK:
		push_error("No se pudo cargar la escena: " + scene_path)
		await _fade_to(0.0)
		is_changing_scene = false
		return

	await get_tree().scene_changed
	await _fade_to(0.0)
	is_changing_scene = false

func _fade_to(alpha: float) -> void:
	var tween := create_tween()
	tween.tween_property(_fade_rect, "color:a", alpha, 0.25)
	await tween.finished
