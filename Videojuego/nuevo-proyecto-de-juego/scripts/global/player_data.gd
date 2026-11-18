extends Node


var level: int = 1
var experience: int = 0

var bonus_damage: int = 0
var bonus_speed: int = 0
var bonus_max_hp: int = 0
var bonus_max_energy: float = 0.0

func reset_run() -> void:
	level = 1
	experience = 0
	bonus_damage = 0
	bonus_speed = 0
	bonus_max_hp = 0
	bonus_max_energy = 0.0
