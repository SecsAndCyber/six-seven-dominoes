extends StaticBody3D

var dominos_in_hand:Array = []
var domino_drawn: DominoBlock = null
@export var collection_speed : float = 0.10
@onready var float_point: Node3D = $FloatPoint
var rotation_tween = null
var lifted: bool = false
var rotated: bool = false
var ready_to_set: bool = false

func start_setting_domino(db: DominoBlock):
	db.freeze = true
	db.set_collision_layer_value(2, false)
	rotation_tween = create_tween()
	var target_rotation = Quaternion.from_euler(Vector3(0, PI/2, PI/2))
	rotation_tween.tween_property(db, "quaternion", target_rotation, 0.6)\
		.set_trans(Tween.TRANS_BACK)\
		.set_ease(Tween.EASE_OUT)
	rotation_tween.finished.connect(func(): rotated = true)
	lifted = false
	rotated = false
	ready_to_set = false
	domino_drawn = db
	
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	for child in get_children():
		if child is DominoBlock:
			print(child, child.transform.origin)
			dominos_in_hand.append(child)

func _process(delta: float) -> void:
	if not domino_drawn == null:
		if domino_drawn.global_transform.origin.y < float_point.global_transform.origin.y:
			domino_drawn.global_transform.origin.y = clampf(
				domino_drawn.global_transform.origin.y + collection_speed * delta,
				.25,
				float_point.global_transform.origin.y
			)
		else:
			lifted = true
		if lifted and rotated:
			if domino_drawn.global_transform.origin.z > float_point.global_transform.origin.z:
				domino_drawn.global_transform.origin.z = clampf(
					domino_drawn.global_transform.origin.z - collection_speed * delta,
					float_point.global_transform.origin.z,
					domino_drawn.global_transform.origin.z
				)
			else:
				ready_to_set = true
		if ready_to_set:
			domino_drawn.freeze = false
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
	# Update the timestamp for the next valid touch
	last_touch_time = current_time
	if GameManager.get_capture_point():
		if GameManager.get_capture_point().collectable:
			if dominos_in_hand.size():
				start_setting_domino(dominos_in_hand.pop_back())
