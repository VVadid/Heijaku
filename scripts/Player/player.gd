extends CharacterBody3D
class_name PlayerMovement

# ----------------------------------------
# Movement Parameters
# ----------------------------------------
@export var run_speed: float = 8.0
@export var air_control: float = 0.6
@export var jump_velocity: float = 6.0
@export var max_jumps: int = 2
@export var gravity: float = 20.0

# Dash
@export var dash_speed: float = 18.0
@export var dash_duration: float = 0.25
@export var dash_cooldown: float = 1

# Roll
@export var roll_speed: float = 12.0
@export var roll_duration: float = 0.5
@export var roll_cooldown: float = 1.0
@export var roll_iframes_duration: float = 0.4

# Combat
@export var attack_damage: float = 10.0
@export var attack_cooldown: float = 0.5
@export var max_health: float = 100.0
@export var knockback_force: float = 15.0          # how hard player gets knocked back
@export var invulnerability_duration: float = 1.0  # after taking damage
@export var camera_shake_intensity: float = 0.03   # radians rotation shake on hit
@onready var attack_hitbox: Area3D = $AttackHitbox

# Combo system
var combo_count: int = 0
var combo_timer: float = 0.0
@export var combo_timeout: float = 1.5
@export var max_combo: int = 4
var attack_step_data: Dictionary = {}   # set by attack state for current step

# Camera (external)
@export var camera_rig: Node3D
@export var camera_spring: SpringArm3D
@export var mouse_sensitivity: float = 0.002
@export var camera_distance: float = 4.0
@export var camera_smoothing: float = 10.0
@export var camera_follow_smoothing: float = 15.0

# Lock-on
@export var lock_on_range: float = 10.0
@export var lock_on_angle: float = 60.0

# Player rotation
@export var rotation_speed: float = 10.0

# UI Indicator
@export var lock_on_indicator: TextureRect

# ----------------------------------------
# Node References
# ----------------------------------------
var states: Dictionary = {}
var current_state: Node

var input_dir: Vector2 = Vector2.ZERO
var current_yaw: float = 0.0
var current_pitch: float = 0.0

var jumps_left: int = 0

var can_dash: bool = true
var dash_timer: float = 0.0
var dash_cooldown_timer: float = 0.0

var can_roll: bool = true
var roll_timer: float = 0.0
var roll_cooldown_timer: float = 0.0
var is_invincible: bool = false
var roll_iframes_timer: float = 0.0

var jump_pressed: bool = false
var dash_pressed: bool = false
var roll_pressed: bool = false
var attack_pressed: bool = false

var lock_on_target: Node3D = null
var lock_on_button_held: bool = false

# Health & Damage
var health: float
var is_dead: bool = false
var damage_invulnerability_timer: float = 0.0

# Attack Cooldown
var attack_cooldown_timer: float = 0.0
var can_attack: bool = true

# Camera Shake
var shake_remaining: float = 0.0
var shake_intensity_current: float = 0.0
var original_camera_rotation: Vector3   # store when shake starts

# ----------------------------------------
# Initialization
# ----------------------------------------
func _ready() -> void:
	var state_scripts = {
		"Ground": preload("res://scripts/Player/states/ground.gd"),
		"Air": preload("res://scripts/Player/states/air.gd"),
		"Dash": preload("res://scripts/Player/states/dash.gd"),
		"Roll": preload("res://scripts/Player/states/roll.gd"),
		"Attack": preload("res://scripts/Player/states/attack.gd")
	}
	for state_name in state_scripts:
		var state = state_scripts[state_name].new()
		state.player = self
		add_child(state)
		states[state_name] = state
	
	change_state("Ground")
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	jumps_left = max_jumps
	health = max_health
	combo_count = 0
	
	if camera_spring:
		camera_spring.spring_length = camera_distance
	if camera_rig:
		camera_rig.global_position = global_position
		var cam = camera_rig.get_node_or_null("SpringArm3D/Camera3D")
		if cam and cam is Camera3D:
			cam.current = true
	
	if lock_on_indicator:
		lock_on_indicator.visible = false

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		if lock_on_target == null and shake_remaining <= 0.0:  # don't rotate during shake
			current_yaw -= event.relative.x * mouse_sensitivity
			current_pitch -= event.relative.y * mouse_sensitivity
			current_pitch = clamp(current_pitch, -1.2, 1.2)
			if camera_rig:
				camera_rig.rotation = Vector3(current_pitch, current_yaw, 0)
	
	if event.is_action_pressed("lock_on"):
		lock_on_button_held = true
		attempt_lock_on()
	elif event.is_action_released("lock_on"):
		lock_on_button_held = false
		release_lock_on()

func _process(delta: float) -> void:
	input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	jump_pressed = Input.is_action_just_pressed("jump")
	dash_pressed = Input.is_action_just_pressed("dash")
	roll_pressed = Input.is_action_just_pressed("roll")
	attack_pressed = Input.is_action_just_pressed("attack")
	
	update_timers(delta)
	
	# Camera shake update (applied after all other rotations)
	if shake_remaining > 0:
		apply_camera_shake(delta)
	
	# Follow player with camera rig
	if camera_rig:
		var target_pos = global_position
		camera_rig.global_position = camera_rig.global_position.lerp(target_pos, camera_follow_smoothing * delta)
	
	# Lock-on camera yaw
	if lock_on_target and is_instance_valid(lock_on_target):
		var dist = global_position.distance_to(lock_on_target.global_position)
		if dist > lock_on_range:
			release_lock_on()
		elif shake_remaining <= 0:  # lock-on camera only updates if not shaking
			update_lock_on_camera(delta)
	
	# Player body rotation
	if lock_on_target and is_instance_valid(lock_on_target):
		var target_dir = lock_on_target.global_position - global_position
		target_dir.y = 0
		if target_dir.length() > 0.01:
			var target_angle = atan2(target_dir.x, target_dir.z)
			rotation.y = lerp_angle(rotation.y, target_angle, rotation_speed * delta)
	else:
		var move_dir = get_movement_direction()
		if move_dir.length() > 0.01:
			var target_angle = atan2(move_dir.x, move_dir.z)
			rotation.y = lerp_angle(rotation.y, target_angle, rotation_speed * delta)
	
	# Update lock-on indicator (UI)
	if lock_on_target and is_instance_valid(lock_on_target):
		var cam = camera_rig.get_node_or_null("SpringArm3D/Camera3D")
		if cam and lock_on_indicator:
			var dir_to_enemy = lock_on_target.global_position - cam.global_position
			var is_in_front = cam.global_transform.basis.z.dot(dir_to_enemy) < 0
			if is_in_front:
				lock_on_indicator.visible = false
			else:
				lock_on_indicator.visible = true
				var screen_pos = get_screen_position(lock_on_target.global_position)
				lock_on_indicator.position = screen_pos - lock_on_indicator.size * 0.5
	else:
		if lock_on_indicator:
			lock_on_indicator.visible = false
	
	if current_state:
		current_state.update(delta)

func _physics_process(delta: float) -> void:
	if current_state:
		current_state.physics_update(delta)
	move_and_slide()

# ----------------------------------------
# Helper: get 2D screen position of a 3D point
# ----------------------------------------
func get_screen_position(world_pos: Vector3) -> Vector2:
	if not camera_rig:
		return Vector2.ZERO
	var cam = camera_rig.get_node_or_null("SpringArm3D/Camera3D")
	if not cam:
		return Vector2.ZERO
	return cam.unproject_position(world_pos)

# ----------------------------------------
# Camera & Lock-on (world-space)
# ----------------------------------------
func attempt_lock_on() -> void:
	var nearest: Node3D = null
	var nearest_dist = lock_on_range
	
	var cam_forward = -camera_rig.global_transform.basis.z
	cam_forward.y = 0
	cam_forward = cam_forward.normalized()
	
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if enemy == self:
			continue
		var dir = enemy.global_position - global_position
		var dist = dir.length()
		if dist > lock_on_range:
			continue
		var dir_h = dir
		dir_h.y = 0
		var angle_deg = rad_to_deg(abs(dir_h.angle_to(cam_forward)))
		if angle_deg > lock_on_angle:
			continue
		if dist < nearest_dist:
			nearest_dist = dist
			nearest = enemy
	
	if nearest:
		lock_on_target = nearest
		print("Locked on: ", nearest.name)
	else:
		print("No target")

func update_lock_on_camera(delta: float) -> void:
	if not lock_on_target:
		return
	
	var target_dir = lock_on_target.global_position - global_position
	target_dir.y = 0
	var target_yaw = atan2(target_dir.x, target_dir.z)
	target_yaw += PI  # keep camera behind player
	
	current_yaw = lerp_angle(current_yaw, target_yaw, camera_smoothing * delta)
	
	if camera_rig:
		camera_rig.rotation = Vector3(current_pitch, current_yaw, 0)

func release_lock_on() -> void:
	lock_on_target = null

# ----------------------------------------
# Movement direction – ALWAYS relative to camera
# ----------------------------------------
func get_movement_direction() -> Vector3:
	if input_dir.length() < 0.01:
		return Vector3.ZERO
	
	var forward = -camera_rig.global_transform.basis.z
	forward.y = 0
	forward = forward.normalized()
	var right = camera_rig.global_transform.basis.x
	right.y = 0
	right = right.normalized()
	
	return (forward * -input_dir.y + right * input_dir.x).normalized()

# ----------------------------------------
# Timers & Helpers
# ----------------------------------------
func update_timers(delta: float) -> void:
	if dash_timer > 0:
		dash_timer -= delta
	if dash_cooldown_timer > 0:
		dash_cooldown_timer -= delta
		if dash_cooldown_timer <= 0:
			can_dash = true
	if roll_timer > 0:
		roll_timer -= delta
	if roll_cooldown_timer > 0:
		roll_cooldown_timer -= delta
		if roll_cooldown_timer <= 0:
			can_roll = true
	if roll_iframes_timer > 0:
		roll_iframes_timer -= delta
		if roll_iframes_timer <= 0:
			is_invincible = false
	
	# Attack cooldown
	if attack_cooldown_timer > 0:
		attack_cooldown_timer -= delta
		if attack_cooldown_timer <= 0:
			can_attack = true
	
	# Damage invulnerability
	if damage_invulnerability_timer > 0:
		damage_invulnerability_timer -= delta
		if damage_invulnerability_timer <= 0:
			pass
	
	# Combo timeout
	if combo_timer > 0:
		combo_timer -= delta
		if combo_timer <= 0:
			reset_combo()
	
	_update_invincibility()

func _update_invincibility() -> void:
	is_invincible = (dash_timer > 0) or (roll_iframes_timer > 0) or (damage_invulnerability_timer > 0)

func change_state(state_name: String, msg: Dictionary = {}) -> void:
	if not states.has(state_name):
		return
	if current_state:
		current_state.exit()
	current_state = states[state_name]
	current_state.enter(msg)

func apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= gravity * delta

func reset_jumps_on_ground() -> void:
	if is_on_floor():
		jumps_left = max_jumps

func attempt_jump() -> bool:
	if jumps_left > 0:
		velocity.y = jump_velocity
		jumps_left -= 1
		return true
	return false

func reset_combo() -> void:
	combo_count = 0
	combo_timer = 0.0
	can_attack = true

# ----------------------------------------
# Combat Functions
# ----------------------------------------
func take_damage(amount: float, knockback_dir: Vector3 = Vector3.ZERO) -> void:
	if is_dead or damage_invulnerability_timer > 0:
		return
	
	health -= amount
	print("Player took ", amount, " damage, HP: ", health)
	
	if knockback_dir.length() > 0.01:
		velocity = knockback_dir * knockback_force
		if is_on_floor():
			velocity.y = knockback_force * 0.5
	
	damage_invulnerability_timer = invulnerability_duration
	
	var mesh = get_node_or_null("MeshInstance3D")
	if mesh:
		var mat = mesh.get_surface_override_material(0)
		if mat:
			mat.albedo_color = Color.RED
			await get_tree().create_timer(0.1).timeout
			if is_instance_valid(mesh) and mat:
				mat.albedo_color = Color.WHITE
	
	if health <= 0:
		die()

func die() -> void:
	is_dead = true
	print("Player died")

func trigger_attack_hit_feedback() -> void:
	start_camera_shake(camera_shake_intensity, 0.1)

# ----------------------------------------
# Camera Shake
# ----------------------------------------
func start_camera_shake(intensity: float, duration: float) -> void:
	shake_intensity_current = intensity
	shake_remaining = duration
	if camera_rig:
		original_camera_rotation = camera_rig.rotation

func apply_camera_shake(delta: float) -> void:
	if not camera_rig:
		return
	
	shake_remaining -= delta
	if shake_remaining <= 0:
		shake_remaining = 0.0
		return
	
	var offset = Vector3(
		randf_range(-shake_intensity_current, shake_intensity_current),
		randf_range(-shake_intensity_current, shake_intensity_current),
		0.0
	)
	camera_rig.rotation = original_camera_rotation + offset

# ----------------------------------------
# Hitbox callback
# ----------------------------------------
func _on_attack_hitbox_body_entered(body: Node3D) -> void:
	if not body.is_in_group("enemies"):
		return
	if attack_hitbox.has_meta("hits"):
		var hit_list = attack_hitbox.get_meta("hits")
		if body in hit_list:
			return
		hit_list.append(body)
	else:
		attack_hitbox.set_meta("hits", [body])
	
	if body.has_method("take_damage"):
		var knockback_dir = (body.global_position - global_position).normalized()
		knockback_dir.y = 0.0
		var dmg = attack_damage * attack_step_data.get("dmg_mult", 1.0)
		var kb_str = attack_step_data.get("knockback", 8.0)
		var stun = attack_step_data.get("stun", 0.3)
		body.take_damage(dmg, knockback_dir, kb_str, stun)
	
	trigger_attack_hit_feedback()

func _on_attack_hitbox_body_exited(body: Node3D) -> void:
	pass
