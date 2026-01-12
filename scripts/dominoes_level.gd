class_name DominosLevel
extends Node3D

@export var next_level: String
@export var domino_scale: float = 1.0
@onready var table_top: StaticBody3D = $TableTop
@onready var hand: HandRack = $Hand
@onready var capture_point: CapturePoint = $CapturePoint
@onready var camera_3d: Camera3D = $Camera3D
@onready var streak_label: Label3D = $Camera3D/StreakLabel
@onready var debug_label: Label3D = $Camera3D/DebugLabel
@onready var coins_label: Label3D = $Camera3D/CoinsLabel
@onready var buy_wildcard: Node3D = $BuyWildcard
@onready var cancel_button_3d: BoxButton3D = $Camera3D/DebugLabel/Button3D

# Called when the node enters the scene tree for the first time.
var pre_loss:bool = false
var pre_win:bool = false
var max_pair_domino: DominoBlock = null
var ready_done:bool = false

func update_ui():
	setup_buy_button()

func setup_buy_button():
	if GameManager.coins >= 50:
		if not hand.has_wild_card and not capture_point.has_wild:
			buy_wildcard.visible = true
			if DominoStack.wildcard_domino and buy_wildcard.get_node("MeshContainer").get_child_count() == 0:
				buy_wildcard.get_node("MeshContainer").transform.origin = Vector3.ZERO
				buy_wildcard.get_node("MeshContainer").rotation_degrees = Vector3(-18.5,43, -90)
				buy_wildcard.get_node("MeshContainer").scale = Vector3(.475,.475,.475)
				var db:DominoBlock = hand.create_wild_card(buy_wildcard.get_node("MeshContainer"),buy_wildcard)
				db.freeze = true
				db.scale = 2.105 * Vector3.ONE
				db.transform.origin = Vector3.ZERO
			else:
				if not buy_wildcard.get_node("MeshContainer").scale == Vector3(.25,.25,.25):
					buy_wildcard.get_node("MeshContainer").transform.origin = Vector3(0,-.32,0)
					buy_wildcard.get_node("MeshContainer").rotation_degrees = Vector3(-34,-128.5, 7.0)
					buy_wildcard.get_node("MeshContainer").scale = Vector3(.25,.25,.25)
		else:
			if buy_wildcard.visible:
				buy_wildcard.visible = false
	else:
		if buy_wildcard.visible:
			buy_wildcard.visible = false

func _ready() -> void:
	pre_loss = false
	pre_win = false
	
	for child in get_children():
		if child is DominoBlock:
			remove_child(child)
			table_top.add_child(child)
			child.scale = Vector3.ONE * domino_scale
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
	get_viewport().size_changed.connect(_on_window_resized)
	_on_window_resized()
	GameManager.is_transitioning = false

func _on_window_resized():
	var cam = get_viewport().get_camera_3d()
	var buy_wildcard_pos = Vector2(get_viewport().get_visible_rect().size.x - 50,
							get_viewport().get_visible_rect().size.y - 150)
	var world_pos = cam.project_position(buy_wildcard_pos, 7.5) # 10.0 is distance from camera
	
	buy_wildcard.global_position = world_pos

func shuffle_live_dominoes(live_dominos):
	var domino_values: Array[Vector2i] = []
	var t: int = 0
	var bs: Array[int] = []
	var b_index: int = 0
	for db in live_dominos:
		if not t in bs:
			assert(t <= 7)
			bs.append(t)
		domino_values.append(Vector2i(t,bs[b_index]))
		if b_index == bs.size()-1:
			b_index = 0
			t += 1
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
const LEVEL_RESET_DELAY_MSEC: int = 10 # very short
const LEVEL_RESET_DELAY_SEC: float = .25
func _process(_delta: float) -> void:
	if not ready_done or GameManager.is_transitioning:
		return
	update_ui()
	if GameManager.level_complete == 0xDEADBEEF:
		return GameManager.advance_to_level("res://scenes/loss_menu.tscn", true)
	if pre_loss:
		return
	if not null == max_pair_domino and not null == max_pair_domino.surface_material:
		if not GameManager.is_low_spec:
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
						not GameManager.get_capture_point().has_wild
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
		pre_win = true
		# Clear the hand so we don't double-count if _process runs again
		await GameManager.clear_hand(true)
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


func _on_buy_wild_button_pressed() -> void:
	if not hand.has_wild_card and not capture_point.has_wild:
		if GameManager.coins >= 50:
			hand.create_wild_card(hand, hand.wild_card_location)
			GameManager.coins -= 50


func _on_cancel_button_pressed() -> void:
	GameManager.advance_to_level("res://scenes/main_menu.tscn", true)
