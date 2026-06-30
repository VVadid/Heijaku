extends State

var knockback: Vector3

func enter(msg: Dictionary = {}) -> void:
	knockback = msg.get("knockback", Vector3.ZERO)
	print("[DamageState] enter, traveling to DamageState")
	player.set_animation_state("DamageState")
	player.velocity = knockback

func update(delta: float) -> void:
	player.velocity = player.velocity.lerp(Vector3.ZERO, 5.0 * delta)
	if player.is_on_floor() and player.velocity.length() < 0.5:
		state_machine.change_state("idle")

func physics_update(delta: float) -> void:
	player.velocity.y -= player.movement_component.gravity * delta
