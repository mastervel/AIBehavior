extends CharacterBody3D

@export var nav_agent : NavigationAgent3D
@export var player : CharacterBody3D
@export var enemy_body : MeshInstance3D

var target_pos : Vector3
var has_target : bool = false
@export var SPEED : float = 3.0 

enum State {IDLE, ROAM, ALERT, AGGRO}
var state_names := ["IDLE", "ROAM", "ALERT", "AGGRO"]
var state : State = State.IDLE:
	set = changeState

func _ready() -> void:
	_body_color(Color.GRAY)
	randomize()

func _physics_process(delta: float) -> void:
	if has_target == false and Input.is_action_pressed("follow"):
		state = State.ROAM
	
	match state:
		State.IDLE:
			pass
		State.ROAM:
			_roam_process(delta)
		State.ALERT:
			_alert_process(delta)
		State.AGGRO:
			_aggro_process(delta)
	
	if has_target: 
		_move_to_target(delta)
	else:
		velocity.x = lerp(velocity.x, 0.0, delta)
		velocity.z = lerp(velocity.z, 0.0, delta)
	
	move_and_slide()

#region Setters and Getters Functions
func changeState(s: State) -> void:
	var prev_state = state
	state = s
	print(state_names[prev_state], " to ", state_names[state])
	# Handles State Transition Logic
	match [prev_state, state]:
		[State.ROAM,State.ROAM]:
			nav_agent.target_position = _get_random_position()
			has_target = true
		[State.ALERT,State.ROAM]:
			nav_agent.target_position = player.global_position
			has_target = true
		[State.ROAM,State.ALERT]:
			has_target = false
	
	match state:
		State.ROAM:
			_body_color(Color.GREEN)
		State.ALERT:
			_body_color(Color.YELLOW)
#endregion

#region State Process Functions

func _roam_process(_delta: float) -> void:
	if not has_target:
		nav_agent.target_position = _get_random_position()
		has_target = true

func _alert_process(delta: float) -> void:
	_look_at_target(delta, player, true)

func _aggro_process(_delta: float) -> void:
	pass

#endregion

#region Helper Functions

func _move_to_target(delta: float) -> void:
	var next_path_pos := nav_agent.get_next_path_position()
	var direction := global_position.direction_to(next_path_pos) * Vector3(1.0,0.0,1.0)
	velocity = direction * SPEED
		
	if nav_agent.is_navigation_finished():
		has_target = false
		velocity = Vector3.ZERO
	
	var ROTATION_SPEED := 4.0
	var target_rotation := direction.signed_angle_to(Vector3.MODEL_FRONT, Vector3.DOWN)
	if abs(target_rotation - rotation.y) > deg_to_rad(60):
		ROTATION_SPEED = 20.0
	rotation.y = move_toward(rotation.y, target_rotation, delta * ROTATION_SPEED)

func _look_at_target(delta: float, target: Node3D, 
		use_model_front: bool = false, look_at_speed: float = 5.0
	) -> void:
	var forward = (target.global_position - global_position).normalized()
	var z = (forward if use_model_front else -forward)
	var x = Vector3.UP.cross(z).normalized()
	var y = z.cross(x)
	global_transform.basis = lerp(
		global_transform.basis, Basis(x,y,z), delta * look_at_speed
		)

func _get_random_position(dist: float = 4.0, degrees: float = 20.0) -> Vector3:
	var forward = global_transform.basis.z.normalized()
	var rand_angle := randf_range(-degrees,degrees)
	var rotated_forward = forward.rotated(Vector3.UP,deg_to_rad(rand_angle))
	return global_transform.origin + rotated_forward * dist

func _body_color(col: Color) -> void:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = col
	enemy_body.material_override = mat

func _on_body_entered(_body: Node3D) -> void:
	match state:
		State.IDLE:
			pass
		State.ROAM:
			state = State.ALERT
		State.ALERT:
			pass
		State.AGGRO:
			pass

func _on_body_exited(_body: Node3D) -> void:
	match state:
		State.IDLE:
			pass
		State.ROAM:
			pass
		State.ALERT:
			state = State.ROAM
		State.AGGRO:
			pass

#endregion
