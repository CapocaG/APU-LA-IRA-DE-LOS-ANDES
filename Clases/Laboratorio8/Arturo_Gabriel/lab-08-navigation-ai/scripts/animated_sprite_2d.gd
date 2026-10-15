extends AnimatedSprite2D

enum PlayerState {
IDLE,
RUN,
JUMP,
FALL,
WALL_SLIDE,
DASH
}
var current_state: PlayerState = PlayerState.IDLE

@onready var animated_sprite: AnimatedSprite2D = (
	$Visuals/AnimatedSprite2D
	)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	animated_sprite.play("idle")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _update_facing(direction: float) -> void:
	if direction == 0.0:
		return
	animated_sprite.flip_h = direction < 0.0

func _update_state() -> void:
	if is_dashing:
		_change_state(PlayerState.DASH)
		return
	if is_on_wall() and not is_on_floor() and velocity.y > 0.0:
		_change_state(PlayerState.WALL_SLIDE)
		return
	if not is_on_floor():
		if velocity.y < 0.0:
			_change_state(PlayerState.JUMP)
		else:
			_change_state(PlayerState.FALL)
		return
	if abs(velocity.x) > 10.0:
		_change_state(PlayerState.RUN)
	else:
		_change_state(PlayerState.IDLE)

func _change_state(new_state: PlayerState) -> void:
	if new_state == current_state:
		return
	current_state = new_state
	_play_state_animation()
	
func _play_state_animation() -> void:
	match current_state:
		PlayerState.IDLE:
			animated_sprite.play("idle")
		PlayerState.RUN:
			animated_sprite.play("run")
		PlayerState.JUMP:
			animated_sprite.play("jump")
		PlayerState.FALL:
			animated_sprite.play("fall")
		PlayerState.WALL_SLIDE:
			animated_sprite.play("wall_slide")
		PlayerState.DASH:
			animated_sprite.play("dash")
		
