class_name HurtboxComponent
extends Area2D

signal hit_received(attack: AttackData, direction: Vector2)

@export var health_component: HealthComponent
var is_invulnerable: bool = false

func receive_hit(
	attack: AttackData,
	hit_direction: Vector2
) -> void:
	if is_invulnerable:
		return

	if health_component == null:
		push_warning("Hurtbox without HealthComponent")
		return

	health_component.take_damage(attack.damage)
	hit_received.emit(attack, hit_direction)

	_start_invulnerability(attack.invulnerability_time)

func _start_invulnerability(duration: float) -> void:
	if duration <= 0.0:
		return

	is_invulnerable = true
	await get_tree().create_timer(duration).timeout
	is_invulnerable = false
