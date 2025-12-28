extends Node3D

@onready var table_top: StaticBody3D = $TableTop
@onready var hand: StaticBody3D = $Hand

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var _board_dominoes: Array[DominoBlock] = []
	for child in table_top.get_children():
		if child is DominoBlock:
			_board_dominoes.append(child)
	GameManager.board_dominoes = _board_dominoes
	var _hand_dominoes: Array[DominoBlock] = []
	for child in hand.get_children():
		if child is DominoBlock:
			_hand_dominoes.append(child)
	GameManager.hand_dominoes = _hand_dominoes

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if GameManager.level_complete:
		GameManager.get_tree().quit()

func is_game_active():
	if GameManager.board_dominoes.size() == 0:
		GameManager.level_complete = true

func _on_table_top_child_exiting_tree(node: Node) -> void:
	node.tree_exited.connect(func():is_game_active())


func _on_hand_child_exiting_tree(node: Node) -> void:
	node.tree_exited.connect(func():is_game_active())
