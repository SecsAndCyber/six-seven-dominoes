class_name DominoBlock
extends RigidBody3D

var WILDGOLD_COLOR:Color = "#ffdd00"
var STANDARD_COLOR:Color = "#ffffff"

var _is_wildcard:bool = false
var is_wildcard:
	get(): return _is_wildcard
	set(val):
		if init_pending or null == noise or null == surface_material:
			look_update_needed = true
			_is_wildcard = val
			return
		# Run this even if the flag isn't changing due to the possiblity
		# of the originial set happening before all the objects were ready
		setup_surface_material(val)

		if not _is_wildcard == val:
			look_update_needed = true
			_is_wildcard = val

func setup_surface_material(wild:bool):
	if wild:
		wild_glitter_light.visible = true
		surface_material.roughness_texture = noise_tex
		surface_material.albedo_color = WILDGOLD_COLOR
		if not GameManager.is_low_spec:
			surface_material.metallic = .35
			surface_material.roughness = 1.0
			surface_material.metallic_specular = 1.0
			surface_material.emission_enabled = true
			surface_material.emission = WILDGOLD_COLOR
			surface_material.emission_operator = surface_material.EMISSION_OP_ADD
			surface_material.emission_energy_multiplier = .12
	else:
		wild_glitter_light.visible = false
		surface_material.roughness_texture = null
		surface_material.albedo_color = STANDARD_COLOR
		if not GameManager.is_low_spec:
			surface_material.metallic = 0
			surface_material.roughness = 1.0
			surface_material.metallic_specular = 0.0
			surface_material.emission_enabled = false

# init_pending is set by the stage once the tree location has stabilized
# Designer note: Set this as false if the parent isn't DominoLevel
@export var init_pending = true
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
		
var start_flip: String = ""
@export var rotation_speed: float = 25
@onready var area_3d: Area3D = $Area3D
@onready var mesh_container: Node3D = $MeshContainer
@onready var debug_mesh: MeshInstance3D = $DebugMesh
@onready var wild_glitter_light: SpotLight3D = $Area3D/WildGlitter

var dominos_in_zone: Dictionary = {} # Using a Dictionary as a Set
@onready var current_renderer = ProjectSettings.get_setting("rendering/renderer/rendering_method")
var surface_material : StandardMaterial3D = null
# Called when the node enters the scene tree for the first time.
var noise:FastNoiseLite = null
var noise_tex:NoiseTexture2D = null
func _ready() -> void:
	noise = FastNoiseLite.new()
	noise.frequency = 0.17 # High frequency = tiny sparkles
	noise_tex = NoiseTexture2D.new()
	noise_tex.noise = noise
	surface_material = null
	wild_glitter_light.visible = false
	debug_mesh.queue_free()

func _enter_tree() -> void:
	look_update_needed = true
	is_wildcard = _is_wildcard
	
func _exit_tree() -> void:
	if mesh_container.get_child_count() > 0:
		DominoStack.return_to_stack(self)

func _notification(what):
	if what == NOTIFICATION_PREDELETE:
		# Final cleanup: This is where you kill RIDs
		if not null == surface_material:
			surface_material.roughness_texture = null
		surface_material = null
		if not null == noise_tex:
			noise_tex.noise = null
		noise = null
		noise_tex = null

func replace(db:DominoBlock):
	DominoStack.return_to_stack(self)
	self.is_wildcard = db.is_wildcard
	value_t = db.value_t
	value_b = db.value_b
	DominoStack.return_to_stack(db)
	look_update_needed = true

func update_domino_look():
	if init_pending:
		return
	if not is_inside_tree(): 
		return
	if mesh_container == null:
		return
	# 2. Clear old visuals
	if mesh_container.get_child_count() > 0:
		for child in mesh_container.get_children():
			prints(self, "Resetting", child.name)
		DominoStack.return_to_stack(self)
	
	var image: Node3D
	if is_wildcard:
		image = DominoStack.draw_wildcard(mesh_container)
		if image == null:
			printerr("Unable to draw wildcard", self)
			return
	else:
		image = DominoStack.draw_from_stack(id, mesh_container)
		if image == null:
			printerr("Unable to draw", self)
			return
	for child in image.get_children():
		var mat = child.get_active_material(0)
		if "TableTop" == get_parent().name:
			# Dominoes on the table should be drawn stacked
			# This is a visual bug fix for Mobile render
			mat.render_priority = global_transform.origin.y * 10
		if child.name == "Surface":
			if surface_material == null:
				if mat.albedo_color == WILDGOLD_COLOR:
					surface_material = mat
				else:
					surface_material = mat.duplicate()
			setup_surface_material(is_wildcard)
			child.set_surface_override_material(0, surface_material)
	# Fixed assignment of large on top
	if id.y==value_t and not id.x==id.y:
		mesh_container.rotation = Vector3.RIGHT * PI
	else:
		mesh_container.rotation = Vector3.RIGHT * 0

	if face == "up":
		mesh_container.rotation.y = 0
		if surface_material.render_priority < surface_material.RENDER_PRIORITY_MAX:
			surface_material.render_priority = int(global_transform.origin.y * 10 + 1)
	elif face == "down":
		mesh_container.rotation.y = PI

func _to_string() -> String:
	return "<DominoBlock {value_t},{value_b} {draw_order}>".format({
		'value_t':value_t,
		'value_b':value_b,
		'draw_order':surface_material.render_priority if not null == surface_material else 0
	})

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	if init_pending:
		return
	if not is_inside_tree():
		return
	if look_update_needed:
		look_update_needed = false
		update_domino_look()
	if not null == surface_material:
		if is_wildcard:
			# Check to see if the visual effect is not correct
			if not (wild_glitter_light.visible or
				surface_material.albedo_color == WILDGOLD_COLOR):
					# Trigger the missing visual effects
					is_wildcard = _is_wildcard
			# These cause a flicker TODO: Implement this as a shader
			# Due to above check, this only occurs inside the single
			# Wildcard permitted per screen
			if not GameManager.is_low_spec:
				wild_glitter_light.light_energy = randf_range(0.8, 1.2)
				noise.seed = randi()
	if under_dominos():
		face = "down"
		start_flip = ""


func _physics_process(delta: float) -> void:
	if init_pending:
		return
	if not is_inside_tree():
		return
	
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
	
	# print("Touched ", face, " on ", self, " to test ", GameManager.get_capture_point())
	if face=="up" and GameManager.get_capture_point():
		if GameManager.get_capture_point().collectable:
			if Input.is_key_pressed(KEY_ALT):
				GameManager.click_streak += 10
			if Input.is_key_pressed(KEY_CTRL) or Input.is_key_pressed(KEY_META):
				# Cross-platform check
				GameManager.get_capture_point().collect_new_domino(self)
			if GameManager.get_capture_point().test_collection(self):
				if not GameManager.get_capture_point().has_wild:
					if GameManager.active_game_level.hand.has_wild_card:
						GameManager.coins += 1
						print("Coin granted: Matched while holding a wildcard!")
					else:
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
				return true
			# ignore any moving blocks
	return false

func _on_area_3d_body_exited(_body: Node3D) -> void:
	if not under_dominos():
		face = "up"
	else:
		face = "down"

func _on_area_3d_body_entered(_body: Node3D) -> void:
	pass

func _on_sleeping_state_changed() -> void:
	pass
