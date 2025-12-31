#@tool
class_name DominoBlock
extends RigidBody3D

var look_update_needed = false
@export_range(0,7) var value_t: int = 5:
	set(val):
			_id.x = -1
			_id.y = -1
			value_t = clampi(val, 0, 7)
			look_update_needed = true
@export_range(0,7) var value_b: int = 5:
	set(val):
			_id.x = -1
			_id.y = -1
			value_b = clampi(val, 0, 7)
			look_update_needed = true
@export_enum("up","down") var face: String = "up":
	set(val):
			if not face == val:
				start_flip = val
			face = val

var _id: Vector2i = Vector2i(-1,-1)
var id: Vector2i:
	get():
		if _id.x < 0 or _id.y < 0:
			var a = min(value_t, value_b)
			var b = max(value_t, value_b)
			_id.x = a
			_id.y = b
		return _id
		
			
@export var rolling_force: float = 10
var start_flip: String = ""
@export var rotation_speed: float = 25
@onready var area_3d: Area3D = $Area3D
@onready var mesh_container: Node3D = $MeshContainer
@onready var debug_mesh: MeshInstance3D = $DebugMesh

var dominos_in_zone: Dictionary = {} # Using a Dictionary as a Set
@onready var current_renderer = ProjectSettings.get_setting("rendering/renderer/rendering_method")
var surface_material : StandardMaterial3D = null
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	debug_mesh.queue_free()

func _enter_tree() -> void:
	look_update_needed = true
	
func _exit_tree() -> void:
	if mesh_container.get_child_count() > 0:
		DominoStack.return_to_stack(self)

func replace(db:DominoBlock):
	DominoStack.return_to_stack(self)
	value_t = db.value_t
	value_b = db.value_b
	DominoStack.return_to_stack(db)
	look_update_needed = true

func update_domino_look():
	if not is_inside_tree(): 
		return
	if mesh_container == null:
		return
	# 2. Clear old visuals
	if mesh_container.get_child_count() > 0:
		for child in mesh_container.get_children():
			prints(self, "Resetting", child.name)
		DominoStack.return_to_stack(self)
	
	var image = DominoStack.draw_from_stack(id, mesh_container)
	if image == null:
		printerr("Inable to draw", self)
		return
	if current_renderer == "mobile":
		for child in image.get_children():
			var mat = child.get_active_material(0).duplicate()
			if "TableTop" == get_parent().name:
				mat.render_priority = global_transform.origin.y * 10
			child.set_surface_override_material(0, mat)
			if child.name == "Surface":
				surface_material = mat
	# Fixed assignment of large on top
	if id.y==value_t and not id.x==id.y:
		mesh_container.rotation = Vector3.RIGHT * PI
	else:
		mesh_container.rotation = Vector3.RIGHT * 0

	if face == "up":
		mesh_container.rotation.y = 0
		if current_renderer == "mobile":
			surface_material.render_priority += 1
	elif face == "down":
		mesh_container.rotation.y = PI

func _to_string() -> String:
	return "<DominoBlock {value_t},{value_b} {draw_order}>".format({
		'value_t':value_t,
		'value_b':value_b,
		'draw_order':surface_material.render_priority if not null == surface_material else 0
	})
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if look_update_needed:
		look_update_needed = false
		update_domino_look()
	# If we are in the editor, stop here and don't run tick logic
	if Engine.is_editor_hint():
		return

	if under_dominos():
		face = "down"
		start_flip = ""
	
	if not start_flip == "":
		if start_flip == "down":
			if mesh_container.rotation.y < PI:
				mesh_container.rotation.y = clampf(
					delta * rotation_speed + mesh_container.rotation.y, 0, PI)
				if mesh_container.rotation.y >= PI - 0.0001:
					start_flip = "" if start_flip == face else face
			else:
					start_flip = "" if start_flip == face else face
		if start_flip == "up":
			if mesh_container.rotation.y > 0:
				mesh_container.rotation.y = clampf(
					mesh_container.rotation.y - delta * rotation_speed, 0, PI)
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
				GameManager.click_streak += 1
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

func _on_area_3d_body_exited(_body: Node3D) -> void:
	if not under_dominos():
		face = "up"
	else:
		face = "down"


func _on_area_3d_body_entered(_body: Node3D) -> void:
	pass
