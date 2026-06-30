extends State

var weapon_version: String = ""

func enter(_msg: Dictionary = {}) -> void:
	weapon_version = player.weapon_version
	_travel_to_standing_locomotion()

func update(delta: float) -> void:
	var input_dir = player.movement_component.get_input_direction()
	var has_input = input_dir.length_squared() > 0.01

	# Smooth movement update (handles acceleration/deceleration internally)
	player.movement_component.update_movement(input_dir, delta)

	# Smooth rotation towards the actual movement direction
	if player.movement_component.current_speed > 0.1:
		var move_dir = Vector3(player.velocity.x, 0, player.velocity.z)
		player.movement_component.rotate_towards(move_dir, delta)

	_update_blend_position()

	# Transition to idle only when fully stopped
	if not has_input and player.movement_component.current_speed < 0.1:
		state_machine.change_state("idle")
		return

	# Action transitions
	if Input.is_action_just_pressed("jump"):
		state_machine.change_state("air", {"jump": true})
	elif Input.is_action_just_pressed("attack"):
		state_machine.change_state("attack")
	elif Input.is_action_just_pressed("dash"):
		state_machine.change_state("dash")
	elif Input.is_action_pressed("crouch"):
		state_machine.change_state("crouch")

func physics_update(delta: float) -> void:
	player.velocity.y -= player.movement_component.gravity * delta
	if player.is_on_floor():
		player.velocity.y = -0.1

func _travel_to_standing_locomotion():
	var path = (
		"Unarmed_Ground/Standing_Locomotion"
		if weapon_version == "ver_A"
		else "Melee_Ground/Standing_Locmotion"
	)
	player.travel_to_anim(path)

func _update_blend_position():
	var speed_ratio = clamp(
		player.movement_component.current_speed / player.movement_component.run_speed,
		0.0, 1.0
	)
	var param = (
		"parameters/Unarmed_Ground/Standing_Locomotion/blend_position"
		if weapon_version == "ver_A"
		else "parameters/Melee_Ground/Standing_Locmotion/blend_position"
	)
	player.set_anim_param(param, speed_ratio)
