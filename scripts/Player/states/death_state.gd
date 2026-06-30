extends State

func enter(_msg: Dictionary = {}) -> void:
	player.travel_to_anim("DeathState")
	player.velocity = Vector3.ZERO
