extends Node

var level_complete = false
var active_capture_point: Node3D
func get_capture_point() -> CapturePoint:
	return active_capture_point as CapturePoint
# Called when the node enters the scene tree for the first time.

var board_dominoes: Array[DominoBlock] = []
var hand_dominoes: Array[DominoBlock] = []

func remove_domino(db: DominoBlock):
	if board_dominoes.has(db):
		board_dominoes.erase(db)
	if hand_dominoes.has(db):
		hand_dominoes.erase(db)
	db.queue_free()
	return null

func _ready() -> void:
	level_complete = false


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
