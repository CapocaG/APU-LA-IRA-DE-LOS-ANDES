extends Node2D

@export var hit_effect_scene: PackedScene
@export var landing_dust_scene: PackedScene
@export var damage_flash_material: ShaderMaterial
@export var dissolve_material: ShaderMaterial

@onready var vfx_spawner: VFXSpawner = $VFXSpawner
@onready var player: CharacterBody2D = $Player
@onready var player_sprite: AnimatedSprite2D = $Player/Visuals/AnimatedSprite2D
@onready var player_hurtbox: HurtboxComponent = $Player/HurtboxComponent
@onready var enemy: CharacterBody2D = $Enemy
@onready var enemy_sprite: AnimatedSprite2D = $Enemy/Visuals/AnimatedSprite2D
@onready var enemy_hurtbox: HurtboxComponent = $Enemy/HurtboxComponent
@onready var game_camera: MathCamera = $Player/Camera2D
@onready var ambient_light: PointLight2D = $PointLight2D

var dash_light_tween: Tween

func _ready() -> void:
	GameState.current_level_id = &"vfx_lab"
	assert(hit_effect_scene != null, "VFXLab requiere la escena de impacto.")
	assert(landing_dust_scene != null, "VFXLab requiere la escena de polvo.")
	assert(damage_flash_material != null, "VFXLab requiere el material de daño.")
	assert(dissolve_material != null, "VFXLab requiere el material de disolución.")
	player_sprite.material = damage_flash_material.duplicate()
	enemy_sprite.material = damage_flash_material.duplicate()

	player.jump_started.connect(_on_player_jump_started)
	player.landed.connect(_on_player_landed)
	player.run_dust_requested.connect(_on_run_dust_requested)
	player.dash_started.connect(_on_dash_started)
	player_hurtbox.hit_received.connect(_on_player_damaged)
	enemy_hurtbox.hit_received.connect(_on_enemy_damaged)
	player.died.connect(_on_player_died)
	enemy.died.connect(_on_enemy_died)


func _on_player_jump_started(effect_position: Vector2) -> void:
	_spawn_dust(effect_position, 0.65)

func _on_player_landed(effect_position: Vector2) -> void:
	_spawn_dust(effect_position, 1.0)

func _on_run_dust_requested(effect_position: Vector2) -> void:
	_spawn_dust(effect_position, 0.4)

func _spawn_dust(effect_position: Vector2, effect_scale: float) -> void:
	var effect := vfx_spawner.spawn_effect(landing_dust_scene, effect_position)
	if effect != null:
		effect.scale = Vector2.ONE * effect_scale

func _on_dash_started(_effect_position: Vector2) -> void:
	if dash_light_tween and dash_light_tween.is_running():
		dash_light_tween.kill()
	ambient_light.energy = 1.2
	dash_light_tween = create_tween()
	dash_light_tween.tween_property(ambient_light, "energy", 2.0, 0.04).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	dash_light_tween.tween_property(ambient_light, "energy", 1.2, 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)

func _on_player_damaged(_attack: AttackData, direction: Vector2) -> void:
	_play_damage_flash(player_sprite)
	_spawn_hit_effect(player_hurtbox.global_position, direction)
	game_camera.trigger_shake(2.0)

func _on_enemy_damaged(_attack: AttackData, direction: Vector2) -> void:
	_play_damage_flash(enemy_sprite)
	_spawn_hit_effect(enemy_hurtbox.global_position, direction)
	game_camera.trigger_shake(4.0)

func _spawn_hit_effect(hit_position: Vector2, hit_direction: Vector2) -> void:
	var angle := 0.0
	if hit_direction.length_squared() > 0.0001:
		angle = hit_direction.angle()
	vfx_spawner.spawn_effect(hit_effect_scene, hit_position, angle)

func _play_damage_flash(sprite: AnimatedSprite2D) -> void:
	var shader_material := sprite.material as ShaderMaterial
	if shader_material == null:
		return
	shader_material.set_shader_parameter("flash_amount", 1.0)
	var tween := create_tween()
	tween.tween_method(
		func(value: float) -> void:
			shader_material.set_shader_parameter("flash_amount", value),
		1.0,
		0.0,
		0.15
	)

func _on_player_died() -> void:
	# Keep the active view in the level when the dying player is removed.
	if game_camera.get_parent() == player:
		game_camera.position_smoothing_enabled = false
		game_camera.reparent(self, true)
		game_camera.reset_smoothing()
	_dissolve_and_remove(player, player_sprite)

func _on_enemy_died() -> void:
	_dissolve_and_remove(enemy, enemy_sprite)

func _dissolve_and_remove(actor: Node2D, visual: CanvasItem) -> void:
	var runtime_material := dissolve_material.duplicate() as ShaderMaterial
	visual.material = runtime_material
	var tween := create_tween()
	tween.tween_method(
		func(value: float) -> void:
			runtime_material.set_shader_parameter("threshold", value),
		0.0,
		1.0,
		0.75
	)
	tween.tween_callback(actor.queue_free)
