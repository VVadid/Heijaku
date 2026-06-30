class_name Player
extends CharacterBody3D

@export var state_machine: StateMachine
@export var health_component: HealthComponent
@export var combat_component: CombatComponent
@export var movement_component: MovementComponent
@export var camera_controller: CameraController
@onready var animation_tree: AnimationTree = $AnimationTree
@onready var anim_player: AnimationPlayer = $Wadid/AnimationPlayer

var weapon_version: String = "ver_A"
var is_dead: bool = false

func _ready() -> void:
	GameManager.register_player(self)
	health_component.health_depleted.connect(_on_death)
	combat_component.hit_landed.connect(_on_hit_landed)
	state_machine.init(self)

func _physics_process(delta: float) -> void:
	if is_dead: return
	state_machine.physics_update(delta)
	move_and_slide()
	if camera_controller:
		camera_controller.update_camera(delta)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("draw_weapon"):
		_toggle_weapon()

func _toggle_weapon() -> void:
	if weapon_version == "ver_A":
		weapon_version = "ver_B"
		if state_machine.current_state.name == "Idle":
			travel_to_anim("Idle_A_to_B")
	else:
		weapon_version = "ver_A"
		if state_machine.current_state.name == "Idle":
			travel_to_anim("Idle_B_to_A")

func travel_to_anim(path: String) -> void:
	if animation_tree:
		var playback = animation_tree.get("parameters/playback")
		if playback:
			playback.travel(path)

func set_anim_param(param: String, value) -> void:
	if animation_tree:
		animation_tree.set(param, value)

func _on_death() -> void:
	is_dead = true
	state_machine.change_state("death")
	GameManager.unregister_player()

func _on_hit_landed(target: Node3D, damage: float) -> void:
	if camera_controller:
		camera_controller.add_trauma(0.3)
	CombatEffects.hit_pause(0.05)
