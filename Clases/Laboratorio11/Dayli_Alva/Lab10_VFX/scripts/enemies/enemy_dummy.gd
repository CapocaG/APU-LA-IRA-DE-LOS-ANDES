extends CharacterBody2D

@onready var health: HealthComponent = $HealthComponent
@onready var hurtbox: HurtboxComponent = $HurtboxComponent
@onready var sprite: AnimatedSprite2D = $Visuals/AnimatedSprite2D

@export var stats: CharacterStats

func _ready() -> void:
	assert(stats != null, "EnemyDummy requiere CharacterStats.")
	health.configure_from_stats(stats)
	hurtbox.hit_received.connect(_on_hit_received)
	health.died.connect(_on_died)

func _on_hit_received(attack: AttackData, direction: Vector2) -> void:
	if health.current_health <= 0.0:
		return

	velocity = direction * attack.knockback_force
	sprite.play("hurt")

func _on_died() -> void:
	sprite.play("dead")
	set_physics_process(false)
