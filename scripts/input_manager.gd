extends Node

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass

func _input(event):
	if (event is InputEventMouseButton
		or event is InputEventScreenTouch) and event.is_pressed():
		_perform_raycast(event.position)

func get_active_camera() -> Camera3D:
	# This gets the camera currently rendering to the main window
	return get_viewport().get_camera_3d()

func _perform_raycast(screen_pos: Vector2) -> void:
	# 1. Calculate the start and end points of the ray
	var ray_origin = get_active_camera().project_ray_origin(screen_pos)
	var ray_end = ray_origin + get_active_camera().project_ray_normal(screen_pos) * 2000.0 # Length of ray

	# 2. Set up the physics query
	var space_state = get_active_camera().get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(ray_origin, ray_end)
	
	# Only hit dominoes on a specific layer (e.g., Layer 1, Clickable)
	query.collision_mask = 1

	# 3. Cast the ray
	var result = space_state.intersect_ray(query)

	# 4. Handle the hit
	if result:
		var hit_object = result.collider
		
		# Check if the hit object is one of your dominoes
		if hit_object is PhysicsBody3D and hit_object.has_method("touched"):
			hit_object.touched()
			print("Pushed: ", hit_object.name)
