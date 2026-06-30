class_name HealthComponent
extends Node

signal damage_taken(amount: float, knockback: Vector3)
signal health_depleted()

@export var max_health: float = 100.0
var current_health: float

func _ready() -> void:
	current_health = max_health

func take_damage(amount: float, knockback_dir: Vector3 = Vector3.ZERO) -> void:
	current_health -= amount
	damage_taken.emit(amount, knockback_dir)
	if current_health <= 0:
		health_depleted.emit()
