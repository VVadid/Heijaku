extends State

func enter(_msg: Dictionary = {}) -> void:
	# No need to stop here – the move state already left us with near-zero speed
	player.movement_component.stop()   # still safe, just zeroes any residual
	var anim = "Idle_ver_A" if player.weapon_version == "ver_A" else "Idle_ver_B"
	player.travel_to_anim(anim)

func update(_delta: float) -> void:
	if player.movement_component.has_input():
		state_machine.change_state("move")
	elif Input.is_action_just_pressed("jump"):
		state_machine.change_state("air", {"jump": true})
	elif Input.is_action_just_pressed("attack"):
		state_machine.change_state("attack")
	elif Input.is_action_just_pressed("dash"):
		state_machine.change_state("dash")
	elif Input.is_action_pressed("crouch"):
		state_machine.change_state("crouch")
