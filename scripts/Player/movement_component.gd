class_name MovementComponent
extends Node

# ---- SPEED & JUMP ----
@export var walk_speed: float = 2.0
@export var run_speed: float = 6.0
@export var crouch_speed: float = 1.0
@export var jump_force: float = 8.0
@export var double_jump_force: float = 9.0
@export var gravity: float = 20.0
@export var max_jumps: int = 2

# ---- MOVEMENT SMOOTHING (ACCELERATION / DECELERATION) ----
@export var acceleration: float = 10.0
@export var deceleration: float = 12.0

# ---- ROTATION (360° smooth turning) ----
@export var turn_speed: float = 12.0   # Higher = snappier, lower = heavier

# ---- STATE ----
var jumps_remaining: int = 2
var current_speed: float = 0.0
var player: Player

func _ready() -> void:
	player = get_parent() as Player

# ------------------------------------------------------------
# INPUT & DIRECTION
# ------------------------------------------------------------
func get_input_direction() -> Vector2:
	var raw = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	return Vector2(raw.x, -raw.y)   # Y inverted so W = forward

func has_input() -> bool:
	return get_input_direction().length_squared() > 0.01

func get_desired_speed() -> float:
	if Input.is_action_pressed("crouch"):
		return crouch_speed
	if Input.is_action_pressed("run"):
		return run_speed
	return walk_speed

# ------------------------------------------------------------
# MOVEMENT UPDATES
# ------------------------------------------------------------
func update_movement(direction: Vector2, delta: float) -> void:
	var target_speed = get_desired_speed()
	var input_len = direction.length()

	if input_len < 0.01:
		target_speed = 0.0   # decelerate when no input

	# Smooth acceleration / deceleration
	if target_speed > current_speed:
		current_speed = move_toward(current_speed, target_speed, acceleration * delta)
	else:
		current_speed = move_toward(current_speed, target_speed, deceleration * delta)

	if current_speed < 0.1:
		stop()
		return

	# Camera-relative world direction
	var cam = get_viewport().get_camera_3d()
	if not cam:
		return

	var forward = -cam.global_transform.basis.z
	forward.y = 0
	forward = forward.normalized()

	var right = cam.global_transform.basis.x
	right.y = 0
	right = right.normalized()

	var world_dir = (forward * direction.y + right * direction.x).normalized()
	player.velocity.x = world_dir.x * current_speed
	player.velocity.z = world_dir.z * current_speed

func air_move(direction: Vector2) -> void:
	var cam = get_viewport().get_camera_3d()
	if not cam: return
	var forward = -cam.global_transform.basis.z
	forward.y = 0; forward = forward.normalized()
	var right = cam.global_transform.basis.x
	right.y = 0; right = right.normalized()
	var world_dir = (forward * direction.y + right * direction.x).normalized()
	player.velocity.x = lerp(player.velocity.x, world_dir.x * run_speed, 0.15)
	player.velocity.z = lerp(player.velocity.z, world_dir.z * run_speed, 0.15)

func stop() -> void:
	current_speed = 0.0
	player.velocity.x = 0.0
	player.velocity.z = 0.0

# ------------------------------------------------------------
# ROTATION (smoothly face movement direction)
# ------------------------------------------------------------
func rotate_towards(target_dir: Vector3, delta: float) -> void:
	if target_dir.length_squared() < 0.01: return
	var target_yaw = atan2(target_dir.x, target_dir.z)
	player.rotation.y = lerp_angle(player.rotation.y, target_yaw, turn_speed * delta)

# ------------------------------------------------------------
# JUMP HANDLING
# ------------------------------------------------------------
func jump() -> void:
	player.velocity.y = jump_force
	jumps_remaining -= 1

func double_jump() -> void:
	player.velocity.y = double_jump_force
	jumps_remaining -= 1

func can_jump() -> bool:
	return jumps_remaining > 0

func reset_jumps() -> void:
	jumps_remaining = max_jumps
