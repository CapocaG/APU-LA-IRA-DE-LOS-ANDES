extends Node

var is_changing_scene: bool = false

func _ready() -> void:
	get_tree().scene_changed.connect(_on_scene_changed)

func change_to(scene_path: String) -> void:
	if is_changing_scene:
		return
	if not ResourceLoader.exists(scene_path):
		push_error("SceneFlow no encuentra la escena: " + scene_path)
		return
	is_changing_scene = true
	call_deferred("_change_deferred", scene_path)

func _change_deferred(scene_path: String) -> void:
	var error := get_tree().change_scene_to_file(scene_path)
	if error != OK:
		push_error("No se pudo cargar la escena: " + scene_path)
		is_changing_scene = false

func _on_scene_changed() -> void:
	is_changing_scene = false
