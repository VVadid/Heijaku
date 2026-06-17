extends PlayerState

var roll_dir: Vector3
var remaining: float

func enter(msg: Dictionary = {}) -> void:
	roll_dir = msg.get("roll_dir", Vector3.ZERO)
	if roll_dir == Vector3.ZERO:
		if player.camera_rig:
			roll_dir = -player.camera_rig.global_transform.basis.z
			roll_dir.y = 0
			roll_dir = roll_dir.normalized()
		else:
			roll_dir = -player.global_transform.basis.z
			roll_dir.y = 0
			roll_dir = roll_dir.normalized()
	
	player.velocity.x = roll_dir.x * player.roll_speed
	player.velocity.z = roll_dir.z * player.roll_speed
	player.velocity.y = 0
	
	remaining = player.roll_duration
	player.can_roll = false
	player.roll_timer = player.roll_duration
	player.roll_cooldown_timer = player.roll_cooldown
	player.roll_iframes_timer = player.roll_iframes_duration
	# is_invincible handled by timers

func update(delta: float) -> void:
	remaining -= delta
	if remaining <= 0:
		if player.is_on_floor():
			change_state("Ground")
		else:
			change_state("Air")
		return

func physics_update(_delta: float) -> void:
	pass

func exit() -> void:
	# i‑frames expire via timer
	pass
