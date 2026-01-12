class_name GameManagerClass
extends Node

var STARTING_LEVEL: String = "res://scenes/level_4_0_startingLevel.tscn"
var is_low_spec: bool = false
var is_cheat: bool:
	get():
		return OS.is_debug_build()
var game_pieces_scale: float:
	get():
		if null == active_game_level:
			return 1.0
		return active_game_level.domino_scale

static var instance:GameManagerClass = null
func _init():
	if GameManagerClass.instance:
		push_error("Singleton already exists!")
		queue_free()
		return
	GameManagerClass.instance = self
	if RenderingServer.get_current_rendering_method() == "gl_compatibility":
		is_low_spec = true
		
	loadScore()
	
var _save_path = "user://67dominos.state"
func save_state():
	var file = FileAccess.open(instance._save_path, FileAccess.WRITE)
	if file:
		file.store_line(JSON.stringify({
			'CurrentLevel':instance.internal_last_played,
			'ClickStreak':instance.internal_click_streak,
			'CoinsCollected':instance.internal_coins,
		}))
	else:
		printerr("Unable to save", instance._save_path)

func loadScore():
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
var internal_last_played : String = ""
var internal_click_streak : int = 0
var internal_coins : int = 0
# ++++++++++++ End Persistent Values
var coins_string: String = ""
var coins: int:
	get():
		return internal_coins
	set(val):
		coin_changed.emit()
		internal_coins = val
		coins_string = "%s Coins" % [val]
signal coin_changed

var click_streak_string: String = ""
var click_streak: int:
	get():
		return internal_click_streak
	set(val):
		internal_click_streak = val
		click_streak_string = "%s Streak" % ["•".repeat(val)]

var last_played: String:
	get():
		return internal_last_played
	set(val):
		internal_last_played = val


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

@export var pause:bool = true
func clear_hand(score:bool):
	var coin_graphics = []
	if hand_dominos.size() == 0:
		var center_spawn = active_game_level.hand.global_transform.origin
		for i in range(25):
			var coin: Coin = active_game_level.hand.coin_prefab_scene.instantiate()
			coin_graphics.append(coin)
			coin.set_collision_layer_value(1, false)
			coin.set_collision_layer_value(2, false)
			coin.spin_velocity = 0
			coin.scale = Vector3(1,1,1)
			coin.rotation = Vector3(0,0,90)
			# Add to scene
			active_game_level.add_child(coin)
			var burst_offset = Vector3(randf_range(-2, 2), 0, 0)
			coin.global_transform.origin = center_spawn + burst_offset
			
			# Animate the burst and then fly to the capture point
			coin.animate_to_position_free(
				active_game_level.hand.float_point.global_transform.origin,
				active_game_level.hand.coin_capture.global_transform.origin,
				randf_range(0.8, 1.5) # Varied speeds for a "fountain" effect
			).finished.connect(func(): GameManager.coins += 1)
			
			# Stagger the spawns so it doesn't hitch the FPS
			await get_tree().create_timer(0.0125).timeout
	while hand_dominos.size():
		var db = hand_dominos.pop_back()
		if score and not is_transitioning:
			var coin:Coin = active_game_level.hand.coin_prefab_scene.instantiate()
			coin_graphics.append(coin)
			coin.set_collision_layer_value(1, false)
			coin.set_collision_layer_value(2, false)
			coin.spin_velocity = 0
			coin.scale = Vector3(1,1,1)
			coin.rotation = Vector3(0,0,90)
			db.get_parent().add_child(coin)
			coin.global_transform.origin = db.global_transform.origin
			db.get_parent().remove_child(db)
			await get_tree().create_timer(0.2).timeout			
			coin.animate_to_position_free(
				active_game_level.hand.float_point.global_transform.origin,
				active_game_level.hand.coin_capture.global_transform.origin,
				1.0
			).finished.connect(func(): GameManager.coins += 1)
		remove_domino(db)
	if score and not is_transitioning:
		await get_tree().create_timer(2).timeout
	

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

func advance_to_level(level_path:String, prevent_redirection:bool=false) -> void:
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
		if db.is_inside_tree():
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
	if prevent_redirection:
		pass
	else:
		if "/levels/" in level_path:
			internal_last_played = level_path
		if internal_last_played and level_path == STARTING_LEVEL:
			level_path = internal_last_played
		if not "/levels/" in internal_last_played:
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
