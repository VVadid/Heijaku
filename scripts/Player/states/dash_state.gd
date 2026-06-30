extends State

var dash_duration: float = 0.3
var timer: float = 0.0

func enter(_msg: Dictionary = {}) -> void:
	timer = 0.0
	var input_dir = player.movement_component.get_input_direction()
	var dash_dir: Vector3
	if input_dir.length() > 0.1:
		var cam = get_viewport().get_camera_3d()
		dash_dir = (-cam.global_transform.basis.z * input_dir.y + cam.global_transform.basis.x * input_dir.x).normalized()
	else:
		dash_dir = -player.camera_controller.global_transform.basis.z
	player.velocity = dash_dir * 15.0
	player.velocity.y = 0
	# Add travel when you have a DashState in the tree:
	# player.travel_to_anim("DashState")

func update(delta: float) -> void:
	timer += delta
	if timer >= dash_duration:
		if player.is_on_floor():
			state_machine.change_state("idle")
		else:
			state_machine.change_state("air")

func physics_update(delta: float) -> void:
	player.velocity.y -= player.movement_component.gravity * delta
