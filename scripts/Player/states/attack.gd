extends PlayerState

# Combo steps: [duration, damage_window_start, damage_window_end, damage_multiplier, knockback_strength, stun_duration]
var combo_steps = [
	# attack 1 – light
	{"duration": 0.4, "window_start": 0.1, "window_end": 0.3, "dmg_mult": 1.0, "knockback": 8.0, "stun": 0.3},
	# attack 2 – light
	{"duration": 0.4, "window_start": 0.1, "window_end": 0.3, "dmg_mult": 1.0, "knockback": 8.0, "stun": 0.3},
	# attack 3 – light
	{"duration": 0.4, "window_start": 0.1, "window_end": 0.3, "dmg_mult": 1.0, "knockback": 8.0, "stun": 0.3},
	# attack 4 – heavy finisher
	{"duration": 0.7, "window_start": 0.2, "window_end": 0.5, "dmg_mult": 2.5, "knockback": 18.0, "stun": 1.2},
]

var timer: float = 0.0
var current_step: int = 0
var step_data: Dictionary = {}
var buffer_window: float = 0.2
var next_attack_queued: bool = false
var hits: Array = []

func enter(_msg: Dictionary = {}) -> void:
	timer = 0.0
	hits.clear()
	next_attack_queued = false
	
	# Manage combo count
	if player.combo_timer <= 0.0:
		player.combo_count = 0
	player.combo_count += 1
	player.combo_timer = player.combo_timeout
	
	# Clamp
	player.combo_count = clamp(player.combo_count, 1, player.max_combo)
	current_step = player.combo_count - 1
	
	# Get step data and store in player for hit callback
	step_data = combo_steps[current_step]
	player.attack_step_data = step_data
	
	# Lock movement
	player.velocity = Vector3.ZERO
	
	# Clear hit list on hitbox
	if player.attack_hitbox.has_meta("hits"):
		player.attack_hitbox.set_meta("hits", [])
	
	# Hitbox starts off
	player.attack_hitbox.monitoring = false
	player.attack_hitbox.monitorable = false
	
	player.can_attack = false

func update(delta: float) -> void:
	timer += delta
	
	# Enable/disable hitbox based on damage window
	if timer >= step_data["window_start"] and timer <= step_data["window_end"]:
		if not player.attack_hitbox.monitoring:
			player.attack_hitbox.monitoring = true
			# For the heavy finisher (index 3), push player back when hitbox first appears
			if current_step == 3:
				_apply_heavy_self_knockback()
	else:
		if player.attack_hitbox.monitoring:
			player.attack_hitbox.monitoring = false
	
	# Check for input buffer during the final part of the attack
	var buffer_start = step_data["duration"] - buffer_window
	if timer >= buffer_start and timer < step_data["duration"]:
		if player.attack_pressed and not next_attack_queued:
			next_attack_queued = true
	
	# End of this step
	if timer >= step_data["duration"]:
		player.attack_hitbox.monitoring = false
		
		if next_attack_queued and player.combo_count < player.max_combo:
			change_state("Attack")
		else:
			player.reset_combo()
			if player.is_on_floor():
				change_state("Ground")
			else:
				change_state("Air")

func physics_update(_delta: float) -> void:
	pass

func exit() -> void:
	player.attack_hitbox.monitoring = false

func _apply_heavy_self_knockback() -> void:
	# Push player backward opposite to facing direction
	var backward = -player.global_transform.basis.z
	backward.y = 0
	backward = backward.normalized()
	player.velocity = backward * player.knockback_force * 0.5   # 50% of player knockback
	if player.is_on_floor():
		player.velocity.y = player.knockback_force * 0.3
