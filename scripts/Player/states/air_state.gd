extends State

var used_double_jump: bool = false

func enter(msg: Dictionary = {}) -> void:
	used_double_jump = false
	if msg.get("jump", false):
		player.movement_component.jump()
		player.travel_to_anim("AirState/JumpStart")
	else:
		player.travel_to_anim("AirState/JumpFall")

func update(delta: float) -> void:
	var input = player.movement_component.get_input_direction()
	player.movement_component.air_move(input)

	if Input.is_action_just_pressed("jump") and player.movement_component.can_jump() and not used_double_jump:
		player.movement_component.double_jump()
		used_double_jump = true
		player.travel_to_anim("AirState/DoubleJumpStart")

	if player.is_on_floor():
		state_machine.change_state("idle")
	elif Input.is_action_just_pressed("attack"):
		state_machine.change_state("attack")

func physics_update(delta: float) -> void:
	player.velocity.y -= player.movement_component.gravity * delta
