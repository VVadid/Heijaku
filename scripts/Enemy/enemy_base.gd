class_name EnemyBase
extends CharacterBody3D

@export var health: float = 30
@export var move_speed: float = 3.0
@export var attack_damage: float = 8.0
@export var detection_range: float = 10.0

var is_dead: bool = false
var target: Node3D = null

func _ready() -> void:
	add_to_group("enemies")

func _physics_process(delta: float) -> void:
	if is_dead: return
	if target:
		var dir = target.global_position - global_position
		dir.y = 0
		if dir.length() < 2.0:
			# attack (simplified)
			pass
		else:
			velocity = dir.normalized() * move_speed
			rotation.y = lerp_angle(rotation.y, atan2(dir.x, dir.z), 10 * delta)
	else:
		# search for player
		if GameManager.player:
			var dist = global_position.distance_to(GameManager.player.global_position)
			if dist < detection_range:
				target = GameManager.player
	velocity.y -= 20 * delta
	move_and_slide()

func take_damage(amount: float, knockback: Vector3) -> void:
	health -= amount
	velocity += knockback * 5
	if health <= 0:
		die()

func die() -> void:
	is_dead = true
	GameManager.enemy_killed.emit(self)
	queue_free()
