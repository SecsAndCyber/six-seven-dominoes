class_name InputManagerClass
extends Node

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

func _input(event):
	# print(event)
	if (event is InputEventMouseButton) and event.is_pressed():
		_perform_raycast(event.position, event.is_pressed())

func get_active_camera() -> Camera3D:
	# This gets the camera currently rendering to the main window
	return get_viewport().get_camera_3d()

func _perform_raycast(screen_pos: Vector2, pressed: bool) -> void:
	if GameManager.level_complete == 0xDEADBEEF: return
	if get_viewport() == null: return
	if get_active_camera() == null: return
	if not GameManager.active_game_level == null:
		if GameManager.active_game_level.pre_loss:
			return
		if GameManager.active_game_level.pre_win:
			return
	# 1. Calculate the start and end points of the ray
	var ray_origin = get_active_camera().project_ray_origin(screen_pos)
	var ray_end = ray_origin + get_active_camera().project_ray_normal(screen_pos) * 2000.0 # Length of ray

	# 2. Set up the physics query
	var space_state = get_active_camera().get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(ray_origin, ray_end)
	
	# Only hit dominos on a specific layer (e.g., Layer 1, Clickable)
	query.collision_mask = 1

	# 3. Cast the ray
	var result = space_state.intersect_ray(query)

	# 4. Handle the hit
	if result:
		var collider = result.collider
		if pressed:
			if collider.has_method("touched"):
				collider.touched()
			elif collider.get_parent().has_method("touched"):
				printerr("Touched a collider in child node:",
					collider.get_parent(),
					collider)
				collider.get_parent().touched()
		elif not pressed:
			if collider.has_method("released"):
				collider.released()
			elif collider.get_parent().has_method("released"):
				printerr("Touched a collider in child node:",
					collider.get_parent(),
					collider)
				collider.get_parent().released()
			
