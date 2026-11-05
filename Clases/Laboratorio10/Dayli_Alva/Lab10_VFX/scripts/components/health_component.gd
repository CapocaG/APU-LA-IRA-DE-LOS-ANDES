class_name HealthComponent
extends Node

signal health_changed(current: float, maximum: float)
signal damaged(amount: float)
signal died

@export var max_health: float = 40.0
var current_health: float

func _ready() -> void:
	current_health = max_health
	health_changed.emit(current_health, max_health)

func take_damage(amount: float) -> void:
	if current_health <= 0.0:
		return

	var applied_damage: float = minf(amount, current_health)
	current_health -= applied_damage

	damaged.emit(applied_damage)
	health_changed.emit(current_health, max_health)

	if current_health <= 0.0:
		died.emit()

func heal(amount: float) -> void:
	if current_health <= 0.0:
		return

	current_health = min(
		current_health + amount,
		max_health
	)

	health_changed.emit(current_health, max_health)
	
func reset_health() -> void:
	current_health = max_health
	health_changed.emit(
		current_health,
		max_health
	)
