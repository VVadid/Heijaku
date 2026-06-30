# animation_library.gd
class_name AnimationLibrary
extends Resource

# Format: { "state_key": { "ver_A": {"forward": "anim_name", ...}, "ver_B": {...} } }
@export var entries: Dictionary = {}

func get_animation(state: String, version: String, direction: Vector2, speed: float) -> String:
	# Simple mapping: choose direction string (e.g., "fwd", "bwd", "left", "right", "idle")
	var dir_str = "idle"
	if speed > 0.01:
		# Determine octant direction
		var angle = direction.angle()
		# Map to 8‑way
		dir_str = _angle_to_dir(angle)
	var key = state + "_" + dir_str
	if entries.has(key) and entries[key].has(version):
		return entries[key][version]
	return "Idle_ver_A"   # fallback
