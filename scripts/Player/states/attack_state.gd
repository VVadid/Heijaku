extends State

var combo_data = [
	{"anim": "Attack_3Combo_1", "duration": 0.4, "window": [0.1, 0.3], "mult": 1.0},
	{"anim": "Attack_3Combo_2", "duration": 0.4, "window": [0.1, 0.3], "mult": 1.0},
	{"anim": "Attack_3Combo_3", "duration": 0.7, "window": [0.2, 0.5], "mult": 2.5}
]
var step: int = 0
var timer: float = 0.0
var next_queued: bool = false

func enter(msg: Dictionary = {}) -> void:
	step = msg.get("step", 0)
	timer = 0.0
	next_queued = false
	player.combat_component.damage_multiplier = combo_data[step]["mult"]
	player.combat_component.enable_hitbox(false)
	# No animation call until you add an AttackState node to the tree

func update(delta: float) -> void:
	timer += delta
	var data = combo_data[step]
	if timer >= data["window"][0] and timer <= data["window"][1]:
		player.combat_component.enable_hitbox(true)
	else:
		player.combat_component.enable_hitbox(false)

	if timer > data["window"][1] and Input.is_action_just_pressed("attack") and step < combo_data.size() - 1:
		next_queued = true

	if timer >= data["duration"]:
		if next_queued:
			state_machine.change_state("attack", {"step": step + 1})
		else:
			if player.is_on_floor():
				state_machine.change_state("idle")
			else:
				state_machine.change_state("air")

func exit() -> void:
	player.combat_component.enable_hitbox(false)
