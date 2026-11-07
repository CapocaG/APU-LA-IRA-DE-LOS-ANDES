extends Control

@onready var health_bar: ProgressBar = $HealthFrame/HealthBar
@onready var energy_bar: ProgressBar = $EnergyFrame/EnergyBar
@onready var health_value: Label = $HealthFrame/HealthValue
@onready var energy_value: Label = $EnergyFrame/EnergyValue

var player: CharacterBody2D

func _ready() -> void:
	bind_player(get_tree().get_first_node_in_group("player") as CharacterBody2D)
	
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
