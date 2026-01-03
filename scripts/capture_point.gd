class_name CapturePoint
extends Node3D

@onready var active_block: DominoBlock = $ActiveDominoBlock
var moving_block: DominoBlock = null
@onready var float_point: Node3D = $FloatPoint

@export var collection_speed : float = 5
var rotation_tween = null
var rotated: bool = false
var incoming_from_hand: bool = false
var set_from_hand: bool = true
var single_value: bool = false
var current_values: Dictionary = {}

var collectable: bool :
	get():
		if active_block == null:
			return false
		if not moving_block == null:
			return false
		return true
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass

func init() -> void:
	GameManager.active_capture_point = self
	# active_block.skin = skin
	current_values = {
		active_block.value_b: true,
		active_block.value_t: true
	}

func _exit_tree() -> void:
	if GameManager.active_capture_point == self:
		GameManager.active_capture_point = null

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if is_instance_valid(active_block):
		setup_active_block()
	else:
		active_block = find_child("*", true, false) as DominoBlock
	if not moving_block == null:
		move_block_toward_capture(delta)

func setup_active_block():
	active_block.freeze = true
	active_block.set_collision_layer_value(1, false)
	var cbr = compute_block_rotation(active_block)
	active_block.rotation = cbr
	
func compute_block_rotation(db: DominoBlock):
	if db==active_block:
		if db.is_wildcard:
			return Vector3(PI, 0, PI/2)
		elif db.value_t == db.value_b:
			return Vector3(0, 0, PI/2)
		elif set_from_hand and db==active_block:
			return Vector3(0, 0, PI/2)
		elif single_value and db==active_block:
			if db.value_t in current_values:
				return Vector3(0, -PI/2, PI/2)
			else:
				return Vector3(0, PI/2, PI/2)
	elif not db==active_block:
		if db.is_wildcard:
			return Vector3(PI, 0, PI/2)
		elif db.value_b in current_values and\
			db.value_t in current_values:
				return Vector3(0, 0, PI/2)
		elif db.value_t in current_values:
			return Vector3(0, PI/2, PI/2)
		else:
			return Vector3(0, -PI/2, PI/2)
	else:
		printerr("Unknown DominoBlock", db)
	
var moved_to_float_point: bool = false
func move_block_toward_capture(delta: float):
	moving_block.freeze = true
	moving_block.surface_material.render_priority = moving_block.surface_material.RENDER_PRIORITY_MAX
	
	var destination: Node3D = self if moved_to_float_point else float_point
	if not moved_to_float_point and moving_block.global_transform.origin.y < float_point.global_transform.origin.y:
		moving_block.global_transform.origin.y = move_toward(
				moving_block.global_transform.origin.y,
				destination.global_transform.origin.y,
				collection_speed * delta
			)
	else:
		if rotation_tween == null:
			rotation_tween = create_tween()
			var target_rotation = Quaternion.from_euler(
									compute_block_rotation(moving_block)
								)
			rotation_tween.tween_property(moving_block, "quaternion", target_rotation, 1)\
				.set_trans(Tween.TRANS_BACK)\
				.set_ease(Tween.EASE_OUT)
			rotation_tween.finished.connect(func(): rotated = true)
		if absf(moving_block.global_transform.origin.x - destination.global_transform.origin.x) > .01:
			moving_block.global_transform.origin.x = move_toward(
				moving_block.global_transform.origin.x, 
				destination.global_transform.origin.x, 
				collection_speed * delta
			)
		else:
			moving_block.global_transform.origin.x = destination.global_transform.origin.x
		if absf(moving_block.global_transform.origin.z - destination.global_transform.origin.z) > .01:
			moving_block.global_transform.origin.z = move_toward(
				moving_block.global_transform.origin.z, 
				destination.global_transform.origin.z, 
				collection_speed * delta
			)
		else:
			moving_block.global_transform.origin.z = destination.global_transform.origin.z
		if absf(moving_block.global_transform.origin.y - float_point.global_transform.origin.y) > .01:
			moving_block.global_transform.origin.y = move_toward(
				moving_block.global_transform.origin.y, 
				float_point.global_transform.origin.y,
				collection_speed * delta
			)
		else:
			moving_block.global_transform.origin.y = float_point.global_transform.origin.y
	if (moving_block.global_transform.origin.x == float_point.global_transform.origin.x and
		moving_block.global_transform.origin.z == float_point.global_transform.origin.z):
		moved_to_float_point = true
	if (moving_block.global_transform.origin.x == global_transform.origin.x and
		moving_block.global_transform.origin.z == global_transform.origin.z):
			setup_active_block_from_movement()

func setup_active_block_from_movement():
	var replaced_wildcard = active_block.is_wildcard
	if moving_block.is_wildcard:
		print("Merging a wildcard!")
	active_block.replace(moving_block)
	
	rotation_tween = null
	var next_values = {
		active_block.value_b: true,
		active_block.value_t: true
	}
	set_from_hand = incoming_from_hand or replaced_wildcard
	if incoming_from_hand:
		single_value = false
		incoming_from_hand = false
		current_values = next_values
		if active_block.is_wildcard:
			for x in range(-1,10):
				current_values[x] = true
	else:
		single_value = not (next_values.size() == 1 or -1 in current_values)
		if single_value:
			for key in current_values:
				if key in next_values:
					next_values.erase(key)
		current_values = next_values
	moving_block.visible = false
	moving_block = GameManager.remove_domino(moving_block)

func test_collection(db : DominoBlock) -> bool:
	if not collectable:
		# Cannot collect while animating
		return false
	var incoming_values = {
		db.value_b: true,
		db.value_t: true
	}
	prints("Testing", incoming_values , current_values)
	for key in current_values:
		if key in incoming_values:
			return true
	return false

func collect_new_domino(db : DominoBlock, adding_from_hand: bool = false) -> void:
	incoming_from_hand = adding_from_hand
	moved_to_float_point = false
	db.set_collision_layer_value(1, false)
	var gt = db.global_transform
	db.get_parent().remove_child(db)
	add_child(db)
	db.global_transform = gt
	moving_block = db
	rotation_tween = null
	rotated = false
