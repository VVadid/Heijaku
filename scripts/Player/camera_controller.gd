class_name CameraController
extends Node3D

# ======================================================
# PLAYER & SPRING ARM
# ======================================================
@export var player: Player
@export var spring_arm: SpringArm3D

# ======================================================
# DISTANCE (zoom)
# ======================================================
## If true, the camera distance NEVER changes – always equals idle_distance.
@export var constant_distance: bool = true
@export var idle_distance: float = 4.0          # used always when constant_distance is on
@export var walk_distance: float = 4.8          # only used if constant_distance = false
@export var run_distance: float = 5.5
@export var sprint_distance: float = 6.5
@export var distance_smooth_speed: float = 3.0

# ======================================================
# HEIGHT & VERTICAL FOLLOW
# ======================================================
@export var height_offset: float = 1.5
@export var position_follow_speed: float = 8.0

# ======================================================
# HORIZONTAL OFFSET – per state (idle / walk / run)
# ======================================================
## Enable this to have the camera slide sideways depending on movement speed.
@export var state_based_h_offset: bool = false

@export var idle_h_offset: float = 0.0      # e.g. 0.5 for over‑the‑right‑shoulder when standing
@export var walk_h_offset: float = 0.7      # a bit further to the side when walking
@export var run_h_offset: float = 1.2       # maximum offset when running
@export var h_offset_smooth_speed: float = 4.0

# ======================================================
# LOOK AHEAD (camera nudges in movement direction)
# ======================================================
@export var look_ahead_enabled: bool = true
@export var look_ahead_max_distance: float = 1.5
@export var look_ahead_return_speed: float = 4.0

# ======================================================
# MOUSE / RIGHT STICK
# ======================================================
@export var mouse_sensitivity: float = 0.002
@export var invert_y: bool = false
@export var invert_x: bool = false
@export var pitch_min: float = -1.2
@export var pitch_max: float = 1.2
@export var rotation_smooth: float = 0.0

# ======================================================
# AUTO‑FOLLOW
# ======================================================
@export var auto_follow: bool = false
@export var auto_follow_speed: float = 5.0
@export var auto_follow_requires_input: bool = true

# ======================================================
# LOCK‑ON & SHAKE
# ======================================================
@export var lock_on_range: float = 15.0
@export var trauma_decay: float = 0.8
@export var max_shake_angle: float = 0.1

# ======================================================
# INTERNAL STATE
# ======================================================
var lock_target: Node3D = null
var yaw: float = 0.0
var pitch: float = 0.0
var trauma: float = 0.0
var current_spring_length: float = 4.0
var current_h_offset: float = 0.0
var look_ahead_offset: Vector3 = Vector3.ZERO

func _ready() -> void:
	if not player:
		player = get_tree().get_first_node_in_group("player") as Player
	if spring_arm and spring_arm.get_child(0) is Camera3D:
		spring_arm.get_child(0).current = true
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	current_spring_length = idle_distance
	current_h_offset = idle_h_offset

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		if lock_target == null:
			var dx = event.relative.x * mouse_sensitivity
			var dy = event.relative.y * mouse_sensitivity
			if invert_x: dx = -dx
			if invert_y: dy = -dy
			yaw -= dx
			pitch -= dy
			pitch = clamp(pitch, pitch_min, pitch_max)

func update_camera(delta: float) -> void:
	if not is_instance_valid(player): return

	# ---- 1. Pivot follows player (height + dynamic horizontal offset) ----
	var flat_speed = Vector2(player.velocity.x, player.velocity.z).length()
	
	# Compute target horizontal offset (per state or static)
	if state_based_h_offset:
		var target_h = _get_h_offset_from_speed(flat_speed)
		current_h_offset = lerp(current_h_offset, target_h, h_offset_smooth_speed * delta)
	else:
		# Use a single static lateral offset if you want; here we just use idle_h_offset
		current_h_offset = idle_h_offset

	var desired_pos = player.global_position + Vector3.UP * height_offset
	if current_h_offset != 0.0:
		desired_pos += player.global_transform.basis.x * current_h_offset   # right vector

	global_position = global_position.lerp(desired_pos, position_follow_speed * delta)

	# ---- 2. Look ahead ----
	if look_ahead_enabled:
		var vel_flat = Vector3(player.velocity.x, 0, player.velocity.z)
		var speed_ratio = clamp(flat_speed / player.movement_component.run_speed, 0.0, 1.0)
		var target_ahead = vel_flat.normalized() * look_ahead_max_distance * speed_ratio
		look_ahead_offset = look_ahead_offset.lerp(target_ahead, look_ahead_return_speed * delta)
		global_position += look_ahead_offset

	# ---- 3. Distance (zoom) ----
	if constant_distance:
		current_spring_length = idle_distance
	else:
		var target_length = _get_dynamic_distance(flat_speed)
		current_spring_length = lerp(current_spring_length, target_length, distance_smooth_speed * delta)
	
	if spring_arm:
		spring_arm.spring_length = current_spring_length

	# ---- 4. Rotation ----
	var target_yaw = yaw
	var target_pitch = pitch

	if auto_follow and lock_target == null:
		var vel = Vector3(player.velocity.x, 0, player.velocity.z)
		if (not auto_follow_requires_input or player.movement_component.has_input()) and vel.length() > 0.5:
			target_yaw = atan2(vel.x, vel.z)
			target_pitch = 0.0

	if lock_target and is_instance_valid(lock_target):
		var dir = lock_target.global_position - player.global_position
		dir.y = 0
		target_yaw = atan2(dir.x, dir.z) + PI
		target_pitch = 0.0

	if rotation_smooth > 0.0:
		yaw = lerp_angle(yaw, target_yaw, 1.0 - rotation_smooth)
		pitch = lerp(pitch, target_pitch, 1.0 - rotation_smooth)
	else:
		yaw = target_yaw
		pitch = target_pitch

	if trauma > 0:
		var sx = randf_range(-trauma, trauma) * max_shake_angle
		var sy = randf_range(-trauma, trauma) * max_shake_angle
		rotation = Vector3(pitch + sy, yaw + sx, 0)
		trauma = max(trauma - trauma_decay * delta, 0)
	else:
		rotation = Vector3(pitch, yaw, 0)

# ------------------------------------------------------
func _get_h_offset_from_speed(flat_speed: float) -> float:
	if flat_speed < 0.1:
		return idle_h_offset
	var walk = player.movement_component.walk_speed
	var run = player.movement_component.run_speed
	if flat_speed <= walk:
		return lerp(idle_h_offset, walk_h_offset, flat_speed / walk)
	elif flat_speed <= run:
		return lerp(walk_h_offset, run_h_offset, (flat_speed - walk) / (run - walk))
	else:
		return run_h_offset

func _get_dynamic_distance(flat_speed: float) -> float:
	if flat_speed < 0.1:
		return idle_distance
	var walk = player.movement_component.walk_speed
	var run = player.movement_component.run_speed
	if flat_speed <= walk:
		return lerp(idle_distance, walk_distance, flat_speed / walk)
	elif flat_speed <= run:
		return lerp(walk_distance, run_distance, (flat_speed - walk) / (run - walk))
	else:
		return sprint_distance

func add_trauma(amount: float) -> void:
	trauma = min(trauma + amount, 1.0)
