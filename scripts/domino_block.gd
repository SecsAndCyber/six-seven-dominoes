@tool
extends RigidBody3D

@export_range(0,7) var value_t: int = 5:
	set(val):
			value_t = clampi(val, 0, 7)
			update_domino_look() # Update whenever the value changes
@export_range(0,7) var value_b: int = 5:
	set(val):
			value_b = clampi(val, 0, 7)
			update_domino_look() # Update whenever the value changes
@export_enum("default") var skin: String = "default":
	set(val):
			skin = val
			update_domino_look() # Update whenever the value changes
@export_enum("up","down") var face: String = "up":
	set(val):
			if not face == val:
				start_flip = val
			face = val
			
@export var rolling_force: float = 10
var mesh_container: Node3D
var start_flip: String = ""
@export var rotation_speed: float = .5

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Create a container if it doesn't exist to hold the FBX/Scene
	if not has_node("MeshContainer"):
		mesh_container = Node3D.new()
		mesh_container.name = "MeshContainer"
		add_child(mesh_container)
	else:
		mesh_container = get_node("MeshContainer")
	update_domino_look()
	start_flip = ""

func update_domino_look():
	if not is_inside_tree(): 
		return
	if mesh_container == null:
		return
	if skin == "":
		return
		
	# 2. Clear old visuals
	for child in mesh_container.get_children():
		child.free()
		
	# 3. Load and instance the new scene
	var a = min(value_t, value_b)
	var b = max(value_t, value_b)
	var scene_path = "res://scenes/dominoes/%s/Domino.%d.%d.tscn" % [skin, a, b]
	
	if ResourceLoader.exists(scene_path):
		print("Loading: domino file: ", scene_path)
		var scene = ResourceLoader.load(scene_path)
		if scene:
			var instance = scene.instantiate()
			mesh_container.add_child(instance)
			# Fixed assignment of large on top
			if b==value_t and not a==b:
				mesh_container.rotation = Vector3.RIGHT * PI
			else:
				mesh_container.rotation = Vector3.RIGHT * 0
	else:
		# Fallback if the file is missing
		print("Warning: Missing domino file: ", scene_path)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	# If we are in the editor, stop here and don't run tick logic
	if Engine.is_editor_hint():
		return
	
	if not start_flip == "":
		if start_flip == "down" and mesh_container.rotation.y < PI:
			mesh_container.rotation.y = clampf(
				rotation_speed + mesh_container.rotation.y, 0, PI)
			if mesh_container.rotation.y >= PI:
				start_flip = ""
		if start_flip == "up" and mesh_container.rotation.y > 0:
			mesh_container.rotation.y = clampf(
				mesh_container.rotation.y - rotation_speed, 0, PI)
			if mesh_container.rotation.y <= 0:
				start_flip = ""
		print("Rotate toward ", start_flip, " ", mesh_container.rotation.y)
	
func _physics_process(_delta):
	# If we are in the editor, stop here and don't run physics logic
	if Engine.is_editor_hint():
		return
# 1. Get the tilt data from your Global Singleton
	var tilt = InputManager.tilt_vector
	
	# 2. Map the Tilt to World Coordinates
	# On a phone held in Portrait:
	# Tilt X (left/right) -> World X
	# Tilt Y (forward/back) -> World Z
	# We use -tilt.y because tilting the phone forward (positive Y in sensors) 
	# should move the ball away from you (negative Z in Godot).
	var move_direction = Vector3(tilt.x, 0, -tilt.y)
	
	# 3. Apply the force
	if move_direction.length() > 0.1:
		# We use 'apply_central_force' for continuous rolling movement
		apply_central_force(move_direction * rolling_force)
