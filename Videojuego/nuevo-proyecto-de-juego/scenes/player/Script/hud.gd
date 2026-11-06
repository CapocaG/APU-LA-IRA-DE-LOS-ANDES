extends CanvasLayer

@onready var health_bar: TextureProgressBar = $MarginContainer/TextureProgressBar
@onready var danger_overlay: TextureRect = $DangerOverlay
var danger_tween: Tween # Guardamos la animación para poder detenerla

func _ready() -> void:
	await get_tree().process_frame
	
	var player = get_tree().get_first_node_in_group("player")
	if player:
		player.update_hp_bar.connect(_on_update_hp_bar)
		health_bar.max_value = 100
		
		@warning_ignore("integer_division")
		var initial_percentage = (player.hitpoints * 100) / player.hitpoints_max
		health_bar.value = initial_percentage
		
		# Comprobamos la vida inicial por si empieza con poca vida
		check_danger_state(initial_percentage)

func _on_update_hp_bar(percentage: int) -> void:
	# 1. Actualizamos la barra gráfica
	health_bar.value = percentage
	
	# 2. Comprobamos si debemos activar la alerta visual
	check_danger_state(percentage)

func check_danger_state(percentage: int) -> void:
	# Si la vida es 25% o menos, iniciamos el parpadeo
	if percentage <= 25:
		start_danger_pulse()
	else:
		# Si te curas y sube del 25%, detenemos el parpadeo
		stop_danger_pulse()

func start_danger_pulse() -> void:
	if danger_tween and danger_tween.is_running():
		return
	danger_tween = create_tween().set_loops()
	
	# Anima la opacidad máxima hasta 0.8 (80% visible) para que el humo se note bien
	# Nota que cambiamos "color:a" por "modulate:a"
	danger_tween.tween_property(danger_overlay, "modulate:a", 0.8, 0.5).set_trans(Tween.TRANS_SINE)
	danger_tween.tween_property(danger_overlay, "modulate:a", 0.0, 0.5).set_trans(Tween.TRANS_SINE)

func stop_danger_pulse() -> void:
	if danger_tween:
		danger_tween.kill()
	
	# Apagamos la transparencia desde la propiedad modulate
	danger_overlay.modulate.a = 0.0
