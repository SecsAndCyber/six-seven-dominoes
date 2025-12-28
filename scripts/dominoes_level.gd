extends Node3D

@onready var table_top: StaticBody3D = $TableTop
@onready var hand: StaticBody3D = $Hand

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	GameManager.prepare_level()
	var _board_dominos: Array[DominoBlock] = []
	for child in table_top.get_children():
		if child is DominoBlock:
			_board_dominos.append(child)
	GameManager.board_dominos = _board_dominos
	var _hand_dominos: Array[DominoBlock] = []
	for child in hand.get_children():
		if child is DominoBlock:
			_hand_dominos.append(child)
	GameManager.hand_dominos = _hand_dominos

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
