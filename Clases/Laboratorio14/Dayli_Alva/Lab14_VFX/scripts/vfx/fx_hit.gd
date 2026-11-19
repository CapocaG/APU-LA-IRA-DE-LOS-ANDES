extends Node2D

@onready var debris: GPUParticles2D = $Debris
@onready var flash_light: PointLight2D = $FlashLight
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var sparks: GPUParticles2D = $Sparks/GPUParticles2D

func _ready() -> void:
	debris.restart()
	flash_light.energy = 0.0
	flash_light.visible = true
	animation_player.play("impact")
	var tween := create_tween()
	tween.tween_property(flash_light, "energy", 2.2, 0.05).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(flash_light, "energy", 0.0, 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_callback(func() -> void: flash_light.visible = false)
	var lifetime := maxf(sparks.lifetime, debris.lifetime)
	await get_tree().create_timer(lifetime + 0.1).timeout
	queue_free()
