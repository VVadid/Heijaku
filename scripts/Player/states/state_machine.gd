class_name StateMachine
extends Node

var player: Player
var states: Dictionary = {}
var current_state: State = null

func init(p: Player) -> void:
	player = p
	for child in get_children():
		if child is State:
			child.player = p
			child.state_machine = self
			states[child.name.to_lower()] = child
			print("[StateMachine] Registered state: ", child.name.to_lower())
	if states.has("idle"):
		change_state("idle")
	else:
		push_error("StateMachine needs an 'Idle' state as child.")

func change_state(state_name: String, msg: Dictionary = {}) -> void:
	print("[StateMachine] change_state requested: ", state_name, " from: ", current_state.name if current_state else "none")
	var new_state = states.get(state_name.to_lower())
	if not new_state:
		push_error("State not found: " + state_name)
		return
	if current_state:
		current_state.exit()
	current_state = new_state
	current_state.enter(msg)
	print("[StateMachine] State changed to: ", current_state.name)

func physics_update(delta: float) -> void:
	if current_state:
		current_state.update(delta)
		current_state.physics_update(delta)
