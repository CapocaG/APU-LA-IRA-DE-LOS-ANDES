extends Node2D

signal levelup

@export var escena_final_packed: PackedScene

var total_enemies: int
var killed_enemies: int = 0

@onready var HUD: Control = $UI/HUD

func _ready() -> void: 
	var enemy_array: Array = get_tree().get_nodes_in_group("enemies") 
	total_enemies = enemy_array.size()
	for i in enemy_array: 
		i.died.connect(experience_gained)
	var player: CharacterBody2D = $level/Player
	levelup.connect(player.calculate_stats)
	player.game_over.connect(display_escena_final)
	player.update_hp_bar.connect(HUD.update_hp_bar)
	
func enemy_died(exp_reward: int) -> void:
	killed_enemies += 1
	experience_gained(exp_reward)
	if killed_enemies == total_enemies:
		display_escena_final(true)

func experience_gained(exp_gain: int) -> void: 
	if PlayerData.level == LevelData.MAX_LEVEL: 
		return 
	var new_experience: int = PlayerData.experience + exp_gain 
	if new_experience >= LevelData.LEVEL_THRESHOLDS[PlayerData.level - 1]: 
		level_up(new_experience) 
	else: 
		PlayerData.experience = new_experience 

func level_up(new_experience: int) -> void: 
	print("Yay, I got more powerful!") 
	new_experience -= LevelData.LEVEL_THRESHOLDS[PlayerData.level - 1] 
	PlayerData.level += 1 
	PlayerData.experience = new_experience
	levelup.emit()
	
func display_escena_final(victoria: bool) -> void: 
	var escena_final_juego: Control = escena_final_packed.instantiate() 
	escena_final_juego.victoria = victoria 
	
	var gestor_escena: Node = get_node("/root/GestorEscena") 
	escena_final_juego.repeat_level.connect(gestor_escena.nuevo_juego) 
	escena_final_juego.menu.connect(gestor_escena.load_menu) 
	$UI.add_child(escena_final_juego)
	
	await get_tree().create_timer(0.4).timeout 
	var player: CharacterBody2D = $level/Player
	player.set_process_mode(PROCESS_MODE_DISABLED) 
	var enemies: Array = get_tree().get_nodes_in_group("enemies") 
	for i: CharacterBody2D in enemies: 
		i.set_process_mode(PROCESS_MODE_DISABLED)
