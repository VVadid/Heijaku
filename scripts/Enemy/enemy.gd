extends CharacterBody3D
class_name Enemy

@export var patrol_speed: float = 2.0
@export var turn_speed: float = 5.0
@export var patrol_points: Array[Vector3] = []
var current_point: int = 0

# Health & Combat
@export var max_health: float = 30.0
@export var knockback_resistance: float = 5.0   # higher = less knockback
var health: float
var is_dead: bool = false
var stagger_timer: float = 0.0
var original_color: Color

func _ready() -> void:
	add_to_group("enemies")
	health = max_health
	if patrol_points.is_empty():
		patrol_points.append(global_position)
	# Store material color for flash effect
	if get_node_or_null("MeshInstance3D") and get_node("MeshInstance3D").mesh:
		var mat = get_node("MeshInstance3D").get_surface_override_material(0)
		if mat:
			original_color = mat.albedo_color
		else:
			original_color = Color.WHITE

func _physics_process(delta: float) -> void:
	if is_dead:
		return
	
	# Stagger prevents movement and patrol
	if stagger_timer > 0:
		stagger_timer -= delta
		# Let velocity decay (knockback)
		velocity.x = lerp(velocity.x, 0.0, 10.0 * delta)
		velocity.z = lerp(velocity.z, 0.0, 10.0 * delta)
		move_and_slide()
		return
	
	if patrol_points.is_empty():
		return
	var target = patrol_points[current_point]
	var dir = (target - global_position).normalized()
	velocity = dir * patrol_speed
	move_and_slide()
	
	if dir.length() > 0.1:
		var target_angle = atan2(dir.x, dir.z)
		rotation.y = lerp_angle(rotation.y, target_angle, turn_speed * delta)
	
	if global_position.distance_to(target) < 0.5:
		current_point = (current_point + 1) % patrol_points.size()

func take_damage(amount: float, knockback_dir: Vector3 = Vector3.ZERO, knockback_strength: float = 8.0, stun_duration: float = 0.3) -> void:
	if is_dead:
		return
	
	health -= amount
	print("Enemy took ", amount, " damage, HP: ", health)
	
	# Apply knockback
	if knockback_dir.length() > 0.01:
		velocity = knockback_dir * knockback_strength
		stagger_timer = stun_duration
	
	# Flash white briefly
	flash_damage()
	
	if health <= 0:
		die()
	else:
		# Stagger (stun) duration
		stagger_timer = max(stagger_timer, stun_duration)

func flash_damage() -> void:
	var mesh = get_node_or_null("MeshInstance3D")
	if mesh:
		var mat = mesh.get_surface_override_material(0)
		if mat:
			mat.albedo_color = Color.RED
			await get_tree().create_timer(0.1).timeout
			if is_instance_valid(mesh) and mat:
				mat.albedo_color = original_color

func die() -> void:
	is_dead = true
	# Disable collisions
	$CollisionShape3D.disabled = true
	# Visual: grey and remove after delay
	var mesh = get_node_or_null("MeshInstance3D")
	if mesh:
		mesh.set_surface_override_material(0, StandardMaterial3D.new())
		mesh.get_surface_override_material(0).albedo_color = Color.GRAY
	await get_tree().create_timer(1.0).timeout
	queue_free()
