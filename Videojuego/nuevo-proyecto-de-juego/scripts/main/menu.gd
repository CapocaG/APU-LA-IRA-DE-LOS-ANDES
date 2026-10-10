extends Control

@onready var sonido_jugar: AudioStreamPlayer = $AudioJugar

signal nuevo_juego_pressed(origin: String)
signal continuar_pressed(origin: String)
signal opciones_pressed(origin: String)
signal salir_pressed(origin: String)

func _on_nuevo_juego_pressed() -> void:
	sonido_jugar.play()
	nuevo_juego_pressed.emit("menu")

func _on_continuar_pressed() -> void:
	continuar_pressed.emit("menu")

func _on_opciones_pressed() -> void:
	opciones_pressed.emit("menu")

func _on_salir_pressed() -> void:
	salir_pressed.emit("menu")
	
