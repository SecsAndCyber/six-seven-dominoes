class_name DominosLevel
extends Node3D

@export var next_level: String
@onready var table_top: StaticBody3D = $TableTop
@onready var hand: HandRack = $Hand
@onready var capture_point: CapturePoint = $CapturePoint
@onready var camera_3d: Camera3D = $Camera3D
@onready var streak_label: Label3D = $Camera3D/StreakLabel
@onready var debug_label: Label3D = $Camera3D/DebugLabel
@onready var coins_label: Label3D = $Camera3D/CoinsLabel
# Called when the node enters the scene tree for the first time.
var pre_loss:bool = false
var pre_win:bool = false
var max_pair_domino: DominoBlock = null
var ready_done:bool = false

func update_ui(_delta:float = 0.0):
	if OS.is_debug_build():
		debug_label.text = "{LevelName} FPS:{FPS}".format({
			'LevelName':get_node("/root/").get_children()[3].name,
			'FPS':str(int(1.0 / _delta)) if _delta else '??'
		})
	elif debug_label.text.length() > 0:
		debug_label.text = ""
	streak_label.text = "%s Streak" % ["•".repeat(GameManager.click_streak)]
	coins_label.text = "%s Coins" % [GameManager.coins]

func _ready() -> void:
	pre_loss = false
	pre_win = false
	update_ui(0)
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
	GameManager.is_transitioning = false

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
	print("Level ", max_pair)
	domino_values.shuffle()
	b_index = 0
	for db in live_dominos:
		if max_pair == domino_values[b_index]:
			max_pair_domino = db
		db.value_t = domino_values[b_index].x
		db.value_b = domino_values[b_index].y
		b_index += 1
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
const LEVEL_RESET_DELAY_MSEC: int = 250 # .25 second in milliseconds
const LEVEL_RESET_DELAY_SEC: float = LEVEL_RESET_DELAY_MSEC / 100.0
func _process(_delta: float) -> void:
	if not ready_done or GameManager.is_transitioning:
		return
	update_ui(_delta)
	if GameManager.level_complete == 0xDEADBEEF:
		return GameManager.advance_to_level("res://scenes/loss_menu.tscn", true)
	if pre_loss:
		return
	if not null == max_pair_domino and not null == max_pair_domino.surface_material:
		var pips_node = max_pair_domino.get_node('MeshContainer').find_child('RenderTopPip',true, false)
		table_top.get_node("TableTop2").get_active_material(0).albedo_color = \
			pips_node.get_active_material(1).albedo_color
		max_pair_domino = null # We have set the table color
	if GameManager.level_complete and GameManager.level_complete < Time.get_ticks_msec():
		GameManager.last_played = next_level
		GameManager.advance_to_level(next_level)
	if pre_win:
		return
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
			if lost:
				lost = false
		if lost and not pre_loss and not pre_win:
			pre_loss = true
			get_tree().create_timer(LEVEL_RESET_DELAY_SEC).timeout.connect(
				func():
					GameManager.level_complete = 0xDEADBEEF
			)

func is_level_won() -> bool:
	if pre_loss or pre_win:
		return false
	if GameManager.level_complete != 0:
		return true
	if GameManager.board_dominos.size() == 0:
		if GameManager.hand_dominos.size() > 0:
			pre_win = true
			var bonus = GameManager.hand_dominos.size()
			GameManager.coins += bonus
			print("Bonus coins for remaining hand: ", bonus)
			# Clear the hand so we don't double-count if _process runs again
			GameManager.clear_hand()
		GameManager.level_complete = Time.get_ticks_msec() + LEVEL_RESET_DELAY_MSEC
		return true
	return false

func _on_table_top_child_exiting_tree(node: Node) -> void:
	node.tree_exited.connect(func():is_level_won())


func _on_hand_child_exiting_tree(node: Node) -> void:
	node.tree_exited.connect(func():is_level_won())

#
# The next step for a polished feel: 
# Would you like to add a Camera Shake effect to the DominosLevel
# script that triggers whenever a match is made, or a Haptic Vibration
# call for when the player tries to make an invalid move?
#
