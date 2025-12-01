extends CharacterBody3D

@export var nav_agent : NavigationAgent3D
@export var player : CharacterBody3D
@export var enemy_body : MeshInstance3D
@export var aggro_timer : Timer
@export var vision_area : Area3D

var target_pos : Vector3
var has_target : bool = false
@export var SPEED : float = 3.0 

enum State {IDLE, ROAM, ALERT, AGGRO}
var state_names := ["IDLE", "ROAM", "ALERT", "AGGRO"]
var state : State = State.IDLE:
	set = changeState

@export var AGGRO_TIME: float = 1.0

func _ready() -> void:
	aggro_timer.wait_time = AGGRO_TIME
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
			if not nav_agent.is_target_reachable():
				print("Target Position Not Reachable!")
			has_target = true
		[State.ALERT,State.ROAM]:
			nav_agent.target_position = player.global_position
			has_target = true
			aggro_timer.stop()
			print("Interrupted!")
		[State.ROAM,State.ALERT]:
			has_target = false
		[State.ALERT,State.AGGRO]:
			nav_agent.target_position = player.global_position
			has_target = true
	
	match state:
		State.ROAM:
			_body_color(Color.GREEN)
		State.ALERT:
			_body_color(Color.YELLOW)
			aggro_timer.start()
			print("Timer started.")
		State.AGGRO:
			_body_color(Color.RED)
#endregion

#region State Process Functions

func _roam_process(_delta: float) -> void:
	if not has_target:
		nav_agent.target_position = _get_random_position()
		if not nav_agent.is_target_reachable():
			print("Target Position Not Reachable!")
		has_target = true

func _alert_process(delta: float) -> void:
	_look_at_target(delta, player)
	if not vision_area.overlaps_body(player):
		state = State.ROAM

func _aggro_process(_delta: float) -> void:
	if not has_target:
		state = State.ALERT

#endregion

#region Helper Functions

func _move_to_target(delta: float) -> void:
	var next_path_pos := nav_agent.get_next_path_position()
	var direction := global_position.direction_to(next_path_pos) * Vector3(1.0,0.0,1.0)
	velocity = direction * SPEED
		
	if nav_agent.is_navigation_finished():
		has_target = false
		velocity = Vector3.ZERO
	
	_rotate_to_target(delta, direction)

func _rotate_to_target(delta: float, direction: Vector3) -> void:
	var ROTATION_SPEED := 4.0
	var target_rotation := atan2(direction.x, direction.z)
	var angle_diff: float = abs(wrapf(target_rotation - rotation.y, -PI, PI))
	if angle_diff > deg_to_rad(60):
		ROTATION_SPEED = 20
	rotation.y = lerp_angle(rotation.y, target_rotation, clamp(delta * ROTATION_SPEED, 0.0, 1.0))

func _look_at_target(delta: float, target: Node3D) -> void:
		var target_position := target.global_position
		var to_target := target_position - global_position
		if to_target.length_squared() < 0.00001:
			return
		_rotate_to_target(delta, to_target)

func _get_random_position(dist: float = 4.0, degrees: float = 20.0) -> Vector3:
	var forward = global_transform.basis.z.normalized()
	var rand_angle := randf_range(-degrees,degrees)
	var rotated_forward = forward.rotated(Vector3.UP,deg_to_rad(rand_angle))
	return global_transform.origin + rotated_forward * dist

func _avoid_boundary() -> void:
	if not nav_agent.is_target_reachable():
		var old_target := nav_agent.get_final_position()

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

func _on_aggro_timer_timeout() -> void:
	print("Aggroed!")
	state = State.AGGRO

#endregion
