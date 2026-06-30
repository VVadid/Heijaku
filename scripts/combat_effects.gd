extends Node

func hit_pause(duration: float, time_scale: float = 0.1) -> void:
	Engine.time_scale = time_scale
	await get_tree().create_timer(duration * time_scale).timeout
	Engine.time_scale = 1.0
