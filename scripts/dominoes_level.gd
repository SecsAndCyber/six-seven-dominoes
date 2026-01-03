class_name DominosLevel
extends Node3D

@export var next_level: String
@onready var table_top: StaticBody3D = $TableTop
@onready var hand: StaticBody3D = $Hand
@onready var capture_point: CapturePoint = $CapturePoint
@onready var camera_3d: Camera3D = $Camera3D
@onready var streak_label: Label3D = $Camera3D/StreakLabel
@onready var debug_label: Label3D = $Camera3D/DebugLabel
# Called when the node enters the scene tree for the first time.
var pre_loss:bool = false
var max_pair_domino: DominoBlock = null
var ready_done:bool = false
	
func _ready() -> void:
	pre_loss = false
	for child in get_children():
		if child is DominoBlock:
			remove_child(child)
			table_top.add_child(child)
	var live_dominos: Array[DominoBlock] = []
	var stack_height = 0
	GameManager.prepare_level(self)
	var _board_dominos: Array[DominoBlock] = []
	for child in table_top.get_children():
		if child is DominoBlock:
			stack_height = max(stack_height, child.global_transform.origin.y)
			_board_dominos.append(child)
			child.init_pending = false
	GameManager.board_dominos = _board_dominos
	var _hand_dominos: Array[DominoBlock] = []
	for child in hand.get_children():
		if child is DominoBlock:
			_hand_dominos.append(child)
			child.init_pending = false
	GameManager.hand_dominos = _hand_dominos
	for child in capture_point.get_children():
		if child is DominoBlock:
			live_dominos.append(child)
			child.init_pending = false
	live_dominos += _board_dominos + _hand_dominos
	shuffle_live_dominoes(live_dominos)
	
	capture_point.float_point.global_transform.origin.y = stack_height
	capture_point.init()
	ready_done = true

func shuffle_live_dominoes(live_dominos):
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
			assert(t <= 7)
		else:
			b_index += 1
	var max_pair:Vector2i
	for db in domino_values:
		max_pair = db
	print("Max Found! ", max_pair)
	domino_values.shuffle()
	b_index = 0
	for db in live_dominos:
		if max_pair == domino_values[b_index]:
			max_pair_domino = db
		db.value_t = domino_values[b_index].x
		db.value_b = domino_values[b_index].y
		b_index += 1
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
const LEVEL_RESET_DELAY: int = 250 # .25 second in milliseconds
func _process(_delta: float) -> void:
	if not ready_done:
		return
	if OS.is_debug_build():
		debug_label.text = "{LevelName} FPS:{FPS}".format({
			'LevelName':get_node("/root/").get_children()[3].name,
			'FPS':int(1.0 / _delta)
		})
	elif debug_label.text.length() > 0:
		debug_label.text = ""
	if not null == max_pair_domino and not null == max_pair_domino.surface_material:
		var pips_node = max_pair_domino.get_node('MeshContainer').find_child('RenderTopPip',true, false)
		table_top.get_node("TableTop2").get_active_material(0).albedo_color = \
			pips_node.get_active_material(1).albedo_color
		max_pair_domino = null # We have set the table color
	streak_label.text = "%s Streak" % ["•".repeat(GameManager.click_streak)]
	if GameManager.level_complete == 0xDEADBEEF:
		return GameManager.advance_to_level("res://scenes/loss_menu.tscn", true)
	if GameManager.level_complete and GameManager.level_complete < Time.get_ticks_msec():
		GameManager.last_played = next_level
		GameManager.advance_to_level(next_level)
	if GameManager.hand_dominos.size() == 0 and GameManager.board_dominos.size() > 0:
		var lost = (not hand.has_wild_card and
						not GameManager.get_capture_point().active_block.is_wildcard
					)
		for bd in GameManager.board_dominos:
			if GameManager.active_capture_point and bd.face == "up":
				if bd.value_b in GameManager.get_capture_point().current_values:
					lost = false
				if bd.value_t in GameManager.get_capture_point().current_values:
					lost = false
		if not null == GameManager.get_capture_point().moving_block:
			lost = false
		if lost:
			pre_loss = true
			get_tree().create_timer(LEVEL_RESET_DELAY / 100).timeout.connect(
				func():
					GameManager.level_complete = 0xDEADBEEF
			)

func is_game_active() -> bool:
	if pre_loss:
		return false
	if GameManager.board_dominos.size() == 0:
		GameManager.level_complete = Time.get_ticks_msec() + LEVEL_RESET_DELAY
		return false
	return true

func _on_table_top_child_exiting_tree(node: Node) -> void:
	node.tree_exited.connect(func():is_game_active())


func _on_hand_child_exiting_tree(node: Node) -> void:
	node.tree_exited.connect(func():is_game_active())
