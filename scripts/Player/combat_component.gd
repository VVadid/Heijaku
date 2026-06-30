class_name CombatComponent
extends Node

signal hit_landed(target: Node3D, damage: float)

@export var hitbox: Area3D
@export var base_damage: float = 10.0
var damage_multiplier: float = 1.0

func _ready() -> void:
	if hitbox:
		hitbox.body_entered.connect(_on_hitbox_body_entered)

func enable_hitbox(active: bool) -> void:
	if not hitbox: return
	hitbox.monitoring = active
	if active:
		# Reset hit list for this attack
		if not hitbox.has_meta("hits"):
			hitbox.set_meta("hits", [])
		hitbox.set_meta("hits", [])

func _on_hitbox_body_entered(body: Node3D) -> void:
	if body == get_parent(): return   # don't hit self
	if not hitbox.has_meta("hits"):
		hitbox.set_meta("hits", [])
	var hits = hitbox.get_meta("hits")
	if body in hits: return
	hits.append(body)
	if body.has_method("take_damage"):
		var dmg = base_damage * damage_multiplier
		var knock = (body.global_position - hitbox.global_position).normalized()
		body.take_damage(dmg, knock)
		hit_landed.emit(body, dmg)
