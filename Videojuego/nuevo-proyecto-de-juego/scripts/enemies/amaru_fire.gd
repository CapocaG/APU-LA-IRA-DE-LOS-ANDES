extends Area2D

@export var speed: float = 380.0
@export var damage: int = 15
@export var lifetime: float = 2.5

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

var direction: Vector2 = Vector2.RIGHT
var age: float = 0.0
var has_hit: bool = false

func _ready() -> void:
	area_entered.connect(_on_area_entered)
	body_entered.connect(_on_body_entered)
	rotation = direction.angle()
	sprite.play("fly")

func _physics_process(delta: float) -> void:
	if has_hit:
		return
	position += direction * speed * delta
	age += delta
	if age >= lifetime:
		queue_free()

func _on_area_entered(area: Area2D) -> void:
	if has_hit:
		return
	var target := area.owner
	if target != null and target.is_in_group("player"):
		if target.has_method("take_damage") and (not target.has_method("is_dead") or not bool(target.call("is_dead"))):
			target.take_damage(damage)
		_explode()

func _on_body_entered(body: Node2D) -> void:
	if has_hit:
		return
	if body is TileMapLayer or body is StaticBody2D:
		_explode()

func _explode() -> void:
	has_hit = true
	$CollisionShape2D.set_deferred("disabled", true)
	rotation = 0.0
	sprite.offset = Vector2.ZERO
	sprite.play("hit")
	await sprite.animation_finished
	queue_free()
