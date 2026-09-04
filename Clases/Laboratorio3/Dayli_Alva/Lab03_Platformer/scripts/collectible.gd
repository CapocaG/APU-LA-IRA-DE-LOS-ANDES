extends Area2D

signal collected(points: int)

@export var points: int = 1

@onready var audio_player: AudioStreamPlayer2D = $AudioStreamPlayer2D

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		collected.emit(points)
		audio_player.play()
		$CollisionShape2D.set_deferred("disabled", true)
		$Sprite2D.hide()
		await audio_player.finished
		queue_free()
