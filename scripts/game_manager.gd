extends Node

var level_complete : int = 0
var active_capture_point: Node3D
func get_capture_point() -> CapturePoint:
	return active_capture_point as CapturePoint
# Called when the node enters the scene tree for the first time.

var board_dominos: Array[DominoBlock] = []
var hand_dominos: Array[DominoBlock] = []

func remove_domino(db: DominoBlock):
	if board_dominos.has(db):
		board_dominos.erase(db)
	if hand_dominos.has(db):
		hand_dominos.erase(db)
	db.queue_free()
	return null

func _ready() -> void:
	prepare_level()

func prepare_level() -> void:
	level_complete = false
	board_dominos = []
	hand_dominos = []
