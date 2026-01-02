extends Node3D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	for db in find_children("*", "DominoBlock", true, true):
		db.freeze = true
		db.set_collision_layer_value(1, false)
		GameManager.board_dominos.append(db)
	
func _process(delta: float) -> void:
	#@onready
	var label_loss_stat: Label3D = $Camera3D/Splash/Label_Loss_Stat
	if GameManager.dominos_abandoned == 1:
		label_loss_stat.text = "1 tile left on the table"
	else:
		label_loss_stat.text = "%s tiles left on the table" % GameManager.dominos_abandoned


func _input(event):
	if event is InputEventMouseButton or event is InputEventScreenTouch:
		if event.is_pressed():
			GameManager.advance_to_level("res://scenes/level_4_0_startingLevel.tscn")
