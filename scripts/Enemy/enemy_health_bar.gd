extends Node3D

@onready var bar: Sprite3D = $Bar
var full_scale_x: float = 0.05
var max_health: float = 30.0

func init(enemy_max_health: float):
	max_health = enemy_max_health

func update_health(current_health: float):
	var ratio = clamp(current_health / max_health, 0.0, 1.0)
	bar.scale.x = full_scale_x * ratio
	if current_health <= 0:
		queue_free()
