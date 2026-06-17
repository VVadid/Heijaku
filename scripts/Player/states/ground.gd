extends PlayerState

func enter(_msg: Dictionary = {}) -> void:
	player.reset_jumps_on_ground()
	# Do NOT force is_invincible = false; invincibility is timer‑based

func update(_delta: float) -> void:
	if player.dash_pressed and player.can_dash:
		change_state("Dash", {"dash_dir": player.get_movement_direction()})
		return
	if player.roll_pressed and player.can_roll:
		change_state("Roll", {"roll_dir": player.get_movement_direction()})
		return
	if player.attack_pressed and player.can_attack:
		change_state("Attack")
		return
	if not player.is_on_floor():
		change_state("Air")
		return
	if player.jump_pressed:
		if player.attempt_jump():
			change_state("Air")
			return

func physics_update(delta: float) -> void:
	var move_dir = player.get_movement_direction()
	var target_velocity = move_dir * player.run_speed
	
	player.velocity.x = move_toward(player.velocity.x, target_velocity.x, 15.0 * delta)
	player.velocity.z = move_toward(player.velocity.z, target_velocity.z, 15.0 * delta)
	
	player.apply_gravity(delta)
	if player.is_on_floor():
		player.velocity.y = -0.01

func exit() -> void:
	pass
