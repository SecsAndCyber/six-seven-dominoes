@tool
class_name DominoBlock
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
var mesh_container: Node3D = null
var start_flip: String = ""
@export var rotation_speed: float = .5
@onready var area_3d: Area3D = $Area3D
var dominos_in_zone: Dictionary = {} # Using a Dictionary as a Set

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
	print("update_domino_look")
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
	var scene_path = "res://scenes/dominos/%s/Domino.%d.%d.tscn" % [skin, a, b]
	
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
	if under_dominos():
		face = "down"
		start_flip = ""
	if face == "up":
		mesh_container.rotation.y = 0
	elif face == "down":
		mesh_container.rotation.y = PI

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	# If we are in the editor, stop here and don't run tick logic
	if Engine.is_editor_hint():
		return
	
	if not start_flip == "":
		if start_flip == "down":
			if mesh_container.rotation.y < PI:
				mesh_container.rotation.y = clampf(
					rotation_speed + mesh_container.rotation.y, 0, PI)
				if mesh_container.rotation.y >= PI - 0.0001:
					start_flip = "" if start_flip == face else face
			else:
					start_flip = "" if start_flip == face else face
		if start_flip == "up":
			if mesh_container.rotation.y > 0:
				mesh_container.rotation.y = clampf(
					mesh_container.rotation.y - rotation_speed, 0, PI)
				if mesh_container.rotation.y <= 0 + 0.0001:
					start_flip = "" if start_flip == face else face
			else:
				start_flip = "" if start_flip == face else face
	
func _physics_process(_delta):
	# If we are in the editor, stop here and don't run physics logic
	if Engine.is_editor_hint():
		return

var last_touch_time: int = 0
const TOUCH_DELAY_MS: int = 100 # .1 second in milliseconds
func touched():
	var current_time = Time.get_ticks_msec()
	# Check if enough time has passed
	if current_time - last_touch_time < TOUCH_DELAY_MS:
		return # Exit early if called too soon
	if not start_flip == "":
		return # Turning domino was clicked
	# Update the timestamp for the next valid touch
	last_touch_time = current_time
	
	print("Touched ", face, " on ", self, " to test ", GameManager.get_capture_point())
	if face=="up" and GameManager.get_capture_point():
		if GameManager.get_capture_point().collectable:
			if GameManager.get_capture_point().test_collection(self):
				GameManager.get_capture_point().collect_new_domino(self)
			else:
				start_flip = "down" if face == "up" else "up"
	else:
		print(area_3d.get_overlapping_bodies())

func under_dominos() -> bool:
	for body in area_3d.get_overlapping_bodies():
		if body is DominoBlock:
			if body.get_parent() == get_parent():
				# ignore any moving blocks
				return true
	return false

func _on_area_3d_body_exited(body: Node3D) -> void:
	if not under_dominos():
		face = "up"


func _on_area_3d_body_entered(body: Node3D) -> void:
	pass
