class_name GameManagerClass
extends Node

var STARTING_LEVEL: String = "res://scenes/level_4_0_startingLevel.tscn"

static var instance:GameManagerClass = null
func _init():
	if GameManagerClass.instance:
		push_error("Singleton already exists!")
		queue_free()
		return
	GameManagerClass.instance = self
	loadScore()
	
var _save_path = "user://67dominos.state"
static func save_state():
	var file = FileAccess.open(instance._save_path, FileAccess.WRITE)
	if file:
		file.store_line(JSON.stringify({
			'CurrentLevel':instance.last_played,
			'ClickStreak':instance.click_streak,
			'CoinsCollected':instance.coins,
		}))
	else:
		printerr("Unable to save", instance._save_path)

static func loadScore():
	var file = FileAccess.open(instance._save_path, FileAccess.READ)
	if file:
		var json_string = file.get_line()
		print("Loaded", json_string)
		var json = JSON.new()
		var parse_result = json.parse(json_string)
		if parse_result == OK:
			var node_data = json.data
			instance.last_played=node_data.get('CurrentLevel')
			instance.click_streak=node_data.get('ClickStreak', 0)
			instance.coins=node_data.get('CoinsCollected', 0)
	else:
		printerr("Unable to open", instance._save_path)
	
# ++++++++++++ Persistent Values
var last_played : String = ""
var click_streak : int = 0
var coins : int = 0
# ++++++++++++ End Persistent Values

# 0 = not complete
# 0xDEADBEEF = lost
# Other values are a timestamp for when the level should change
# This is a hack while end-of-level modals don't exist
var level_complete : int = 0
var is_transitioning : bool = true
var dominos_abandoned : int = 0

var active_game_level: DominosLevel
var active_capture_point: Node3D
func get_capture_point() -> CapturePoint:
	return active_capture_point as CapturePoint
# Called when the node enters the scene tree for the first time.

var board_dominos: Array[DominoBlock] = []
var hand_dominos: Array[DominoBlock] = []

func clear_hand():
	while hand_dominos.size():
		var db = hand_dominos.pop_back()
		db.get_parent().remove_child(db)
		remove_domino(db)

func remove_domino(db: DominoBlock):
	if board_dominos.has(db):
		board_dominos.erase(db)
	if hand_dominos.has(db):
		hand_dominos.erase(db)
	# The resulting _exit_tree() will handle the return to stack
	db.queue_free()
	return null

func _ready() -> void:
	prepare_level(null)

func prepare_level(dl:DominosLevel) -> void:
	is_transitioning = true
	active_game_level = dl
	level_complete = false
	board_dominos = []
	hand_dominos = []

func advance_to_level(level_path:String, allow_main_menu:bool=false) -> void:
	is_transitioning = true
	var to_remove = board_dominos + hand_dominos
	if level_complete == 0xDEADBEEF:
		dominos_abandoned = board_dominos.size()
		if dominos_abandoned > 0:
			# Clear the click streak if the game was lost
			click_streak = 0
	else:
		dominos_abandoned = 0
	for db in to_remove:
		db.get_parent().remove_child(db)
		remove_domino(db)
	if active_capture_point:
		if not null == get_capture_point().active_block:
			get_capture_point().active_block.get_parent(
				).remove_child(get_capture_point().active_block)
			remove_domino(get_capture_point().active_block)
		if not null == get_capture_point().moving_block:
			get_capture_point().moving_block.get_parent(
				).remove_child(get_capture_point().moving_block)
			remove_domino(get_capture_point().moving_block)
		active_capture_point = null
	DominoStack.validate_stack()
	level_complete = 0
	board_dominos = []
	hand_dominos = []
	if "/levels/" in level_path:
		last_played = level_path
	if last_played and level_path == STARTING_LEVEL:
		level_path = last_played
	if not allow_main_menu:
		if not "/levels/" in last_played:
			level_path = STARTING_LEVEL
	save_state()
	if not OK == get_tree().change_scene_to_file(level_path):
		get_tree().change_scene_to_file(STARTING_LEVEL)

func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		save_state()
		get_tree().quit() # default behavior
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		save_state()
		get_tree().quit() # default behavior
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		save_state()
	if what == NOTIFICATION_APPLICATION_PAUSED:
		save_state()
