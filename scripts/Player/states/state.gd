class_name PlayerState
extends Node

var player: PlayerMovement

func enter(_msg: Dictionary = {}) -> void:
	pass

func update(_delta: float) -> void:
	pass

func physics_update(_delta: float) -> void:
	pass

func exit() -> void:
	pass

func change_state(state_name: String, msg: Dictionary = {}) -> void:
	player.change_state(state_name, msg)
