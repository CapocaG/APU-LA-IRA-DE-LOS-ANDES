extends Control

@onready var health_bar: ProgressBar = $HealthFrame/HealthBar
@onready var energy_bar: ProgressBar = $EnergyFrame/EnergyBar
@onready var health_value: Label = $HealthFrame/HealthValue
@onready var energy_value: Label = $EnergyFrame/EnergyValue
@onready var vignette: TextureRect = $VignetteOverlay

@export_range(0.05, 0.5) var low_health_threshold: float = 0.25
@export var pulse_speed: float = 4.0
@export_range(0.0, 1.0) var max_vignette_alpha: float = 0.85

var player: CharacterBody2D
var is_low_health: bool = false
var pulse_time: float = 0.0

func _ready() -> void:
	if is_instance_valid(vignette):
		vignette.modulate.a=0.0
	bind_player(get_tree().get_first_node_in_group("player") as CharacterBody2D)

func _process(delta: float) -> void:
	if not is_instance_valid(vignette):
		return
		
	if is_low_health:
		pulse_time += delta * pulse_speed
		var wave: float = (sin(pulse_time) + 1.0) * 0.5
		vignette.modulate.a = lerpf(0.25, max_vignette_alpha, wave)
	elif vignette.modulate.a > 0.0:
		pulse_time = 0.0
		vignette.modulate.a = move_toward(vignette.modulate.a, 0.0, delta * 2.0)
	
func bind_player(current_player: CharacterBody2D) -> void:
	if is_instance_valid(player) and player.stats_changed.is_connected(_update_stats):
		player.stats_changed.disconnect(_update_stats)
	player = current_player
	if not is_instance_valid(player):
		return
	player.stats_changed.connect(_update_stats)
	_update_stats(player.hitpoints, player.hitpoints_max, player.energy, player.max_energy)

func _update_stats(health: int, max_health: int, energy: float, max_energy: float) -> void:
	health_bar.max_value = max_health
	health_bar.value = health
	energy_bar.max_value = max_energy
	energy_bar.value = energy
	health_value.text = "%d/%d" % [health, max_health]
	energy_value.text = "%d/%d" % [roundi(energy), roundi(max_energy)]
	
	var health_ratio: float = float(health) / float(maxi(max_health, 1))
	is_low_health = health > 0 and health_ratio <= low_health_threshold
