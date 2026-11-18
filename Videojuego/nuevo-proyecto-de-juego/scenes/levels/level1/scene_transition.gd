extends CanvasLayer

@onready var fade_rect: ColorRect = $FadeRect
@onready var level_title: Label = get_node_or_null("LevelTitle")
@onready var video_player: VideoStreamPlayer = get_node_or_null("VideoStreamPlayer")

var is_transitioning: bool = false

func _ready() -> void:
	fade_rect.modulate.a = 0.0
	fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if is_instance_valid(level_title):
		level_title.modulate.a = 0.0
	if is_instance_valid(video_player):
		video_player.visible = false

func change_level(target_path: String, subtitle: String = "Siguiente Zona", video_stream: VideoStream = null) -> void:
	if is_transitioning:
		return
	is_transitioning = true

	# 1. Oscurece la pantalla suavemente
	var fade_in := create_tween()
	fade_in.tween_property(fade_rect, "modulate:a", 1.0, 0.6)
	await fade_in.finished

	# 2. Si asignaste un video (.ogv) y existe el nodo, lo reproduce
	if video_stream != null and is_instance_valid(video_player):
		video_player.stream = video_stream
		video_player.visible = true
		video_player.play()
		await video_player.finished
		video_player.visible = false
	elif is_instance_valid(level_title):
		# Muestra el título del capítulo con efecto de aparición
		level_title.text = subtitle
		var text_in := create_tween()
		text_in.tween_property(level_title, "modulate:a", 1.0, 0.5)
		await text_in.finished
		await get_tree().create_timer(1.4).timeout
		var text_out := create_tween()
		text_out.tween_property(level_title, "modulate:a", 0.0, 0.4)
		await text_out.finished

	# 3. Carga el siguiente nivel
	get_tree().change_scene_to_file(target_path)
	await get_tree().process_frame

	# 4. Revela el nuevo nivel
	var fade_out := create_tween()
	fade_out.tween_property(fade_rect, "modulate:a", 0.0, 0.7)
	await fade_out.finished

	is_transitioning = false
