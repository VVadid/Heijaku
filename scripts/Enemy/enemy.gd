extends CharacterBody3D
class_name Enemy

# ----- INSPECTOR TOGGLES -----
@export var aggressive_on_sight: bool = false
@export var detection_range: float = 8.0
@export var attack_range: float = 2.0
@export var attack_damage: float = 8.0
@export var attack_cooldown: float = 1.5
@export var chase_speed: float = 4.0
@export var turn_speed: float = 8.0
@export var max_health: float = 30.0
@export var knockback_resistance: float = 5.0

var health: float
var is_dead: bool = false
var stagger_timer: float = 0.0
var original_color: Color
var mesh_mat: StandardMaterial3D

# ----- STATES -----
enum State { IDLE, CHASE, ATTACK, WIND_UP }
var current_state: State = State.IDLE
var target: Node3D = null
var attack_timer: float = 0.0
var wind_up_timer: float = 0.0
var wind_up_duration: float = 0.2

# ----- NODE REFERENCES -----
@onready var detection_area: Area3D = $DetectionArea
@onready var attack_area: Area3D = $AttackArea
@onready var mesh_instance: MeshInstance3D = $MeshInstance3D

func _ready():
	add_to_group("enemies")
	health = max_health
	if mesh_instance and mesh_instance.mesh:
		var mat = mesh_instance.get_surface_override_material(0)
		if mat:
			mesh_mat = mat
			original_color = mat.albedo_color
		else:
			original_color = Color.WHITE
			mesh_mat = null
	else:
		mesh_mat = null

	if detection_area:
		detection_area.body_entered.connect(_on_detection_body_entered)
		detection_area.body_exited.connect(_on_detection_body_exited)
	if attack_area:
		attack_area.body_entered.connect(_on_attack_area_body_entered)
		attack_area.monitoring = false
		attack_area.monitorable = false

func _physics_process(delta):
	if is_dead: return

	if stagger_timer > 0:
		stagger_timer -= delta
		velocity.x = lerp(velocity.x, 0.0, 10.0 * delta)
		velocity.z = lerp(velocity.z, 0.0, 10.0 * delta)
		move_and_slide()
		if stagger_timer <= 0 and mesh_mat:
			mesh_mat.albedo_color = original_color
		return

	if current_state != State.ATTACK and current_state != State.WIND_UP:
		if target == null or not is_instance_valid(target):
			change_state(State.IDLE)
			return

	match current_state:
		State.IDLE:
			velocity = Vector3.ZERO
			if target != null:
				change_state(State.CHASE)

		State.CHASE:
			var distance = global_position.distance_to(target.global_position)
			if distance <= attack_range:
				change_state(State.WIND_UP)
				return
			var dir = (target.global_position - global_position).normalized()
			velocity = dir * chase_speed
			if dir.length() > 0.1:
				var target_angle = atan2(dir.x, dir.z)
				rotation.y = lerp_angle(rotation.y, target_angle, turn_speed * delta)

		State.WIND_UP:
			var distance = global_position.distance_to(target.global_position)
			if distance > attack_range + 1.0:
				change_state(State.CHASE)
				return
			var dir = (target.global_position - global_position).normalized()
			if dir.length() > 0.1:
				var target_angle = atan2(dir.x, dir.z)
				rotation.y = lerp_angle(rotation.y, target_angle, turn_speed * delta)
			wind_up_timer -= delta
			if wind_up_timer <= 0.0:
				change_state(State.ATTACK)
			velocity = Vector3.ZERO

		State.ATTACK:
			var distance = global_position.distance_to(target.global_position)
			if distance > attack_range + 0.5:
				change_state(State.CHASE)
				return
			var dir = (target.global_position - global_position).normalized()
			if dir.length() > 0.1:
				var target_angle = atan2(dir.x, dir.z)
				rotation.y = lerp_angle(rotation.y, target_angle, turn_speed * delta)
			attack_timer -= delta
			if attack_timer <= 0.0:
				perform_attack()
				attack_timer = attack_cooldown
			velocity = Vector3.ZERO

	move_and_slide()

func change_state(new_state: State):
	if current_state == State.WIND_UP:
		if mesh_mat: mesh_mat.albedo_color = original_color

	current_state = new_state
	attack_timer = 0.0

	if new_state == State.WIND_UP:
		wind_up_timer = wind_up_duration
		if mesh_mat: mesh_mat.albedo_color = Color.YELLOW

func perform_attack():
	if not attack_area: return
	attack_area.monitoring = true
	await get_tree().create_timer(0.15).timeout
	if attack_area:
		attack_area.monitoring = false

func take_damage(amount: float, knockback_dir: Vector3 = Vector3.ZERO, knockback_strength: float = 8.0, stun_duration: float = 0.3):
	if is_dead: return
	health -= amount
	print("Enemy took ", amount, " damage, HP: ", health)

	alert(Global.player_node)

	if knockback_dir.length() > 0.01:
		velocity = knockback_dir * knockback_strength
		stagger_timer = stun_duration
		if mesh_mat: mesh_mat.albedo_color = Color(0.3, 0.5, 0.8, 1.0)  # grey-blue stagger
	else:
		flash_damage()
		stagger_timer = max(stagger_timer, stun_duration)

	if health <= 0:
		die()
	else:
		stagger_timer = max(stagger_timer, stun_duration)

func alert(new_target):
	if new_target == null: return
	target = new_target
	if current_state == State.IDLE:
		change_state(State.CHASE)

func _on_detection_body_entered(body):
	if body.is_in_group("player") and aggressive_on_sight:
		alert(body)

func _on_detection_body_exited(body):
	if body == target and current_state != State.ATTACK and current_state != State.WIND_UP:
		target = null
		change_state(State.IDLE)

func _on_attack_area_body_entered(body):
	if body.is_in_group("player") and body.has_method("take_damage"):
		var kb_dir = (body.global_position - global_position).normalized()
		kb_dir.y = 0.0
		body.take_damage(attack_damage, kb_dir)

func flash_damage():
	if mesh_mat:
		mesh_mat.albedo_color = Color.RED
		await get_tree().create_timer(0.1).timeout
		if is_instance_valid(self) and mesh_mat:
			mesh_mat.albedo_color = original_color

func die():
	is_dead = true
	$CollisionShape3D.disabled = true
	if mesh_mat:
		mesh_mat.albedo_color = Color.GRAY
	await get_tree().create_timer(1.0).timeout
	queue_free()
