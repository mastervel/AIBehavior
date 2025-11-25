extends CharacterBody3D

@export var nav_agent : NavigationAgent3D
@export var player : CharacterBody3D

var target_pos : Vector3
var has_target : bool = false
@export var SPEED : float = 3.0 

func _ready() -> void:
	pass

func _physics_process(delta: float) -> void:
	if has_target == false and Input.is_action_just_pressed("follow"):
		print("follow the leader!")
		has_target = true
		nav_agent.target_position = player.global_position
	
	if has_target: 
		var next_path_pos := nav_agent.get_next_path_position()
		var direction := global_position.direction_to(next_path_pos)
		velocity = direction * SPEED
		
		if nav_agent.is_navigation_finished():
			has_target = false
			velocity = Vector3.ZERO
	
		var ROTATION_SPEED := 4.0
		var target_rotation := direction.signed_angle_to(Vector3.MODEL_FRONT, Vector3.DOWN)
		if abs(target_rotation - rotation.y) > deg_to_rad(60):
			ROTATION_SPEED = 20.0
		rotation.y = move_toward(rotation.y, target_rotation, delta * ROTATION_SPEED)
	
	move_and_slide()
