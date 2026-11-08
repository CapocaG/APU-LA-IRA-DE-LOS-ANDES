class_name CharacterStats
extends Resource

@export_category("Health")
@export var max_health: int = 100

@export_category("Movement")
@export var move_speed: float = 260.0
@export var acceleration: float = 1500.0

@export_category("Combat")
@export var attack_damage: int = 20
@export var knockback_force: float = 220.0
