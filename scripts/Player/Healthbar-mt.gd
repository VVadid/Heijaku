extends ProgressBar

func _process(_delta):
	if Global.player_node:
		value = Global.player_node.health
		max_value = Global.player_node.max_health
