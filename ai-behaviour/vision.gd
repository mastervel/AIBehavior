extends Area3D

@export var vision_ray : RayCast3D

func _ready() -> void:
	vision_ray.enabled = false

func cast_ray_to_target(target: Node3D) -> void:
	var target_local := to_local(target.global_position)
	vision_ray.target_position = target_local

func is_in_los(target: Node3D, group_index := -1) -> bool:
	var target_groups := target.get_groups()
	if target_groups.size() == 0:
		push_error("No group assigned to target node. Will return false.")
		return false
	
	if target_groups.size() > 1 and group_index == -1:
		push_warning("
		More than 1 group assigned to this target node. 
		If this is intended, specify group by index in second argument.
		By default, first group will be used for LOS detection logic.
		")
	
	if group_index == -1:
		group_index = 0
	
	var group := target_groups[group_index]
	vision_ray.enabled = true
	cast_ray_to_target(target)
	vision_ray.force_raycast_update()
	
	if vision_ray.get_collider().is_in_group(group):
		vision_ray.enabled = false
		return true
	
	vision_ray.enabled = false
	return false
