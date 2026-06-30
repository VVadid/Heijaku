# game_manager.gd (Autoload)
extends Node

signal player_spawned(player: Node3D)
signal player_died()
signal enemy_killed(enemy: Node3D)

var player: Player = null

func register_player(p: Player) -> void:
	player = p
	player_spawned.emit(p)

func unregister_player() -> void:
	player = null
	player_died.emit()
