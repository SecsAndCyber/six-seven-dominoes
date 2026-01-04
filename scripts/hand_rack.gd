extends StaticBody3D

var _ready_done:bool = false
var dominos_in_hand:Array[DominoBlock] = []
var dominos_reset:Array[bool] = []
var domino_drawn: DominoBlock = null
@export var collection_speed : float = 0.10
@onready var float_point: Node3D = $FloatPoint
@onready var wild_card_location: Node3D = $WildCardLocation
var domino_prefab_scene = preload("res://scenes/domino_block.tscn")

var rotation_tween = null
var lifted: bool = false
var rotated: bool = false
var ready_to_set: bool = false
var has_wild_card : bool = false

func start_setting_domino(db: DominoBlock):
	db.freeze = true
	db.surface_material.render_priority = db.surface_material.RENDER_PRIORITY_MAX
	db.set_collision_layer_value(2, false)
	rotation_tween = create_tween()
	if not db.is_wildcard:
		var target_rotation = Quaternion.from_euler(Vector3(0, PI/2, PI/2))
		rotation_tween.tween_property(db, "quaternion", target_rotation, 0.6)\
			.set_trans(Tween.TRANS_BACK)\
			.set_ease(Tween.EASE_OUT)
		rotation_tween.finished.connect(func(): rotated = true)
	else:
		var target_rotation = Quaternion.from_euler(Vector3(0, PI/2, 0))
		rotation_tween.tween_property(db, "quaternion", target_rotation, 0.6)\
			.set_trans(Tween.TRANS_BACK)\
			.set_ease(Tween.EASE_OUT)
		rotation_tween.finished.connect(func(): rotated = true)
	rotated = false
	lifted = false
	ready_to_set = false
	domino_drawn = db
	_ready_done = true
	
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	for child in get_children():
		if child is DominoBlock:
			dominos_in_hand.append(child)
	get_tree().create_timer(0.05).timeout.connect(fix_ordering)
func fix_ordering():
	# This function fixes a visual bug in Mobile render
	if _ready_done:
		return
	var i = 0
	for child in dominos_in_hand:
		if null == child.surface_material:
			return get_tree().create_timer(0.05).timeout.connect(fix_ordering)
		child.surface_material.render_priority = i
		i += 1
	_ready_done = true
	

func _process(delta: float) -> void:
	if GameManager.click_streak >= 5 and not has_wild_card:
		has_wild_card = true
		var wild_card_db: DominoBlock = domino_prefab_scene.instantiate()
		wild_card_db.is_wildcard = true
		wild_card_db.name = "WildCardDominoBlock"
		if dominos_in_hand.size() > 4:
			wild_card_db.freeze = true
		wild_card_db.set_collision_layer_value(1, false)
		wild_card_db.set_collision_layer_value(2, true)
		add_child(wild_card_db)
		wild_card_db.global_transform = wild_card_location.global_transform
		dominos_in_hand.append(wild_card_db)
		wild_card_db.is_wildcard = true
		wild_card_db.init_pending = false
	if not domino_drawn == null:
		if domino_drawn.global_transform.origin.y < float_point.global_transform.origin.y:
			domino_drawn.global_transform.origin.y = clampf(
				domino_drawn.global_transform.origin.y + collection_speed * delta,
				.25,
				float_point.global_transform.origin.y
			)
		else:
			lifted = true
		if rotated:
			if domino_drawn.global_transform.origin.z > float_point.global_transform.origin.z:
				domino_drawn.global_transform.origin.z = clampf(
					domino_drawn.global_transform.origin.z - collection_speed * delta,
					float_point.global_transform.origin.z,
					domino_drawn.global_transform.origin.z
				)
			elif lifted:
				ready_to_set = true
		if ready_to_set:
			domino_drawn.freeze = false
			if domino_drawn.name == "WildCardDominoBlock":
				has_wild_card = false
			GameManager.get_capture_point().collect_new_domino(domino_drawn, true)
			domino_drawn = null

var last_touch_time: int = 0
const TOUCH_DELAY_MS: int = 100 # .1 second in milliseconds
func touched():
	var current_time = Time.get_ticks_msec()
	# Check if enough time has passed
	if current_time - last_touch_time < TOUCH_DELAY_MS:
		return # Exit early if called too soon
	if not domino_drawn == null:
		return # Already moving a domino from hand
	if GameManager.get_capture_point().active_block.is_wildcard:
		return # Don't override a pending wildcard
	# Update the timestamp for the next valid touch
	last_touch_time = current_time
	if GameManager.get_capture_point():
		if GameManager.get_capture_point().collectable:
			if dominos_in_hand.size():
				GameManager.click_streak = 0
				start_setting_domino(dominos_in_hand.pop_back())
