extends Node2D

@export var amplitude := 65.0
@export var frequency_hz := 1.1
@export var speed_x := 115.0
@export var travel_distance := 900.0

var elapsed := 0.0
var origin := Vector2.ZERO

func _ready() -> void:
	origin = global_position

func _physics_process(delta: float) -> void:
	elapsed += delta
	var distance_x := fposmod(
		speed_x * elapsed,
		travel_distance
	)
	var wave_y := amplitude * sin(
		TAU * frequency_hz * elapsed
	)
	global_position = origin + Vector2(
		distance_x,
		wave_y
	)

func _draw() -> void:
	draw_circle(Vector2.ZERO, 11.0, Color("#35A4AE"))
	draw_circle(Vector2.ZERO, 4.0, Color.WHITE)
