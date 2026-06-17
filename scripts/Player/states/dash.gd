extends PlayerState

var dash_dir: Vector3
var remaining: float

func enter(msg: Dictionary = {}) -> void:
	dash_dir = msg.get("dash_dir", Vector3.ZERO)
	if dash_dir == Vector3.ZERO:
		# Fallback to camera forward; if camera_rig is missing, use player's own facing
		if player.camera_rig:
			dash_dir = -player.camera_rig.global_transform.basis.z
			dash_dir.y = 0
			dash_dir = dash_dir.normalized()
		else:
			dash_dir = -player.global_transform.basis.z
			dash_dir.y = 0
			dash_dir = dash_dir.normalized()
	
	player.velocity.x = dash_dir.x * player.dash_speed
	player.velocity.z = dash_dir.z * player.dash_speed
	player.velocity.y = 0  # horizontal dash only
	
	remaining = player.dash_duration
	player.can_dash = false
	player.dash_timer = player.dash_duration
	player.dash_cooldown_timer = player.dash_cooldown
	# player.is_invincible handled by timers

func update(delta: float) -> void:
	remaining -= delta
	if remaining <= 0:
		if player.is_on_floor():
			change_state("Ground")
		else:
			change_state("Air")
		return

func physics_update(_delta: float) -> void:
	# Hold dash velocity, ignore gravity
	pass

func exit() -> void:
	# Do NOT set is_invincible = false here; timers manage it
	player.velocity *= 0.9  # momentum preservation
