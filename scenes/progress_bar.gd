extends ProgressBar

func _ready() -> void:
	if GameManager.player:
		var health_comp = GameManager.player.health_component
		max_value = health_comp.max_health
		value = health_comp.current_health
		health_comp.damage_taken.connect(_update_health)

func _update_health(_amount, _knockback) -> void:
	value = GameManager.player.health_component.current_health
