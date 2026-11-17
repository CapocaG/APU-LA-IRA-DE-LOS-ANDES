extends Control

@onready var sonido_jugar: AudioStreamPlayer = $AudioJugar
@onready var btn_nuevo_juego: TextureButton = $VBoxContainer/NuevoJuego

signal nuevo_juego_pressed(origin: String)
signal continuar_pressed(origin: String)
signal opciones_pressed(origin: String)
signal salir_pressed(origin: String)

func _on_nuevo_juego_pressed() -> void:
	btn_nuevo_juego.disabled = true
	if is_instance_valid(sonido_jugar) and sonido_jugar.stream:
		sonido_jugar.play()
		await sonido_jugar.finished
	nuevo_juego_pressed.emit("menu")
	btn_nuevo_juego.disabled = false

func _on_continuar_pressed() -> void:
	continuar_pressed.emit("menu")

func _on_opciones_pressed() -> void:
	opciones_pressed.emit("menu")

func _on_salir_pressed() -> void:
	salir_pressed.emit("menu")
