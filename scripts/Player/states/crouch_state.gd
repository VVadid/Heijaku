extends State

var weapon_version: String = ""

func enter(_msg: Dictionary = {}) -> void:
	weapon_version = player.weapon_version
	_travel_to_crouch_locomotion()

func update(delta: float) -> void:
	var input_dir = player.movement_component.get_input_direction()
	player.movement_component.update_movement(input_dir, delta)

	# Smooth rotation while moving
	if player.movement_component.current_speed > 0.1:
		var move_dir = Vector3(player.velocity.x, 0, player.velocity.z)
		player.movement_component.rotate_towards(move_dir, delta)

	_update_blend_position()

	if not Input.is_action_pressed("crouch"):
		state_machine.change_state("idle")
	elif Input.is_action_just_pressed("jump"):
		state_machine.change_state("air", {"jump": true})
	elif Input.is_action_just_pressed("attack"):
		state_machine.change_state("attack")

func _travel_to_crouch_locomotion():
	var path = (
		"Unarmed_Ground/Crouch_Locmotion"
		if weapon_version == "ver_A"
		else "Melee_Ground/Crouch_Locmotion"
	)
	player.travel_to_anim(path)

func _update_blend_position():
	var speed_ratio = clamp(
		player.movement_component.current_speed / player.movement_component.run_speed,
		0.0, 0.4
	)
	var param = (
		"parameters/Unarmed_Ground/Crouch_Locmotion/blend_position"
		if weapon_version == "ver_A"
		else "parameters/Melee_Ground/Crouch_Locmotion/blend_position"
	)
	player.set_anim_param(param, speed_ratio)
