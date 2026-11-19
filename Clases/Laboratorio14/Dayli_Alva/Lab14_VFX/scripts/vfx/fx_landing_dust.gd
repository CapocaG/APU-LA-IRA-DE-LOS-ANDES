extends Node2D
@onready var particles: GPUParticles2D = $GPUParticles2D
func _ready() -> void:
	particles.finished.connect(_on_particles_finished)
	particles.restart()
func _on_particles_finished() -> void:
	queue_free()
