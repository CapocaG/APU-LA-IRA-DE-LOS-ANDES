extends CharacterBody2D

@export var speed: float = 220.0

@onready var animated_sprite: AnimatedSprite2D = $Visuals/AnimatedSprite2D
@onready var camera: Camera2D = $Camera2D
@onready var name_label: Label = $NameLabel


func _enter_tree() -> void:
	var peer_id := str(name).to_int()
	if peer_id > 0:
		set_multiplayer_authority(peer_id, true)


func _ready() -> void:
	var peer_id := str(name).to_int()
	name_label.text = "Peer %d" % peer_id
	camera.enabled = is_multiplayer_authority()


func _physics_process(_delta: float) -> void:
	if not is_multiplayer_authority():
		return

	var direction := Input.get_vector(
		"move_left",
		"move_right",
		"move_up",
		"move_down"
	)
	velocity = direction * speed
	move_and_slide()

	if direction.length() > 0.0:
		animated_sprite.play("run")
		if direction.x != 0.0:
			animated_sprite.flip_h = direction.x < 0.0
	else:
		animated_sprite.play("idle")
