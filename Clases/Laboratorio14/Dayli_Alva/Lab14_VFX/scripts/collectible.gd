extends Area2D

signal collected(points: int)

@export var points: int = 1
@export var item_id: StringName = &""

@onready var audio_player: AudioStreamPlayer2D = get_node_or_null("AudioStreamPlayer2D") as AudioStreamPlayer2D

var _is_collected: bool = false

func _ready() -> void:
	add_to_group("collectible")
	if item_id != &"" and GameState.has_collected_item(item_id):
		_is_collected = true
		queue_free()
		return
	if item_id == &"":
		push_warning("Collectible sin item_id estable: %s" % name)
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if _is_collected or not body.is_in_group("player"):
		return
	_is_collected = true
	if item_id != &"":
		GameState.add_collected_item(item_id)
	GameState.add_score(points)
	if item_id != &"":
		SaveManager.save_game()
	collected.emit(points)
	$CollisionShape2D.set_deferred("disabled", true)
	$Sprite2D.hide()
	if audio_player != null:
		audio_player.play()
		await audio_player.finished
	queue_free()
