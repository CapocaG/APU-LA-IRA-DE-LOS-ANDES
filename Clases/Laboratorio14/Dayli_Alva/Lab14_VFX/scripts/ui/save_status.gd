extends Label

var _fade_tween: Tween

func _ready() -> void:
	visible = false
	modulate.a = 0.0
	SaveManager.save_started.connect(_on_save_started)
	SaveManager.save_finished.connect(_on_save_finished)

func _on_save_started() -> void:
	if _fade_tween != null and _fade_tween.is_running():
		_fade_tween.kill()
	text = "Guardando..."
	visible = true
	modulate.a = 1.0

func _on_save_finished(success: bool) -> void:
	text = "Progreso guardado" if success else "No se pudo guardar"
	visible = true
	modulate.a = 1.0
	_fade_tween = create_tween()
	_fade_tween.tween_interval(1.6)
	_fade_tween.tween_property(self, "modulate:a", 0.0, 0.35)
	_fade_tween.tween_callback(_hide_status)

func _hide_status() -> void:
	visible = false
