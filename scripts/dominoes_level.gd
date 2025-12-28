extends Node3D

@onready var table_top: StaticBody3D = $TableTop
@onready var hand: StaticBody3D = $Hand
@onready var capture_point: CapturePoint = $CapturePoint

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var live_dominos: Array[DominoBlock] = []
	var stack_height = 0
	GameManager.prepare_level()
	var _board_dominos: Array[DominoBlock] = []
	for child in table_top.get_children():
		if child is DominoBlock:
			stack_height = max(stack_height, child.global_transform.origin.y)
			_board_dominos.append(child)
	GameManager.board_dominos = _board_dominos
	var _hand_dominos: Array[DominoBlock] = []
	for child in hand.get_children():
		if child is DominoBlock:
			_hand_dominos.append(child)
	GameManager.hand_dominos = _hand_dominos
	for child in capture_point.get_children():
		if child is DominoBlock:
			live_dominos.append(child)
	live_dominos += _board_dominos + _hand_dominos
	print(live_dominos.size(), " dominos in play")
	
	var domino_values: Array[Vector2i] = []
	var t: int = 0
	var bs: Array[int] = []
	var b_index: int = 0
	for db in live_dominos:
		if not t in bs:
			bs.append(t)
		domino_values.append(Vector2i(t,bs[b_index]))
		if b_index == bs.size()-1:
			b_index = 0
			t += 1
		else:
			b_index += 1
	for db in domino_values:
		prints("(%d,%d)" % [db.x, db.y])
	domino_values.shuffle()
	for db in domino_values:
		prints("(%d,%d)" % [db.x, db.y])
	b_index = 0
	for db in live_dominos:
		db.value_t = domino_values[b_index].x
		db.value_b = domino_values[b_index].y
		b_index += 1
	
	capture_point.float_point.global_transform.origin.y = stack_height
	capture_point.init()

# Called every frame. 'delta' is the elapsed time since the previous frame.
const LEVEL_RESET_DELAY: int = 250 # .25 second in milliseconds
func _process(delta: float) -> void:
	if GameManager.level_complete and GameManager.level_complete < Time.get_ticks_msec():
		GameManager.get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

func is_game_active():
	if GameManager.board_dominos.size() == 0:
		GameManager.level_complete = Time.get_ticks_msec() + LEVEL_RESET_DELAY

func _on_table_top_child_exiting_tree(node: Node) -> void:
	node.tree_exited.connect(func():is_game_active())


func _on_hand_child_exiting_tree(node: Node) -> void:
	node.tree_exited.connect(func():is_game_active())
