class_name LossMenu
extends Node3D

@onready var label_loss_stat: Label3D = $Camera3D/Splash/Label_Loss_Stat
@onready var debug_label: Label3D = $Camera3D/DebugLabel
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if OS.is_debug_build():
		debug_label.text = "DEV {LevelName}".format({
			'LevelName':get_node("/root/").get_children()[3].name,
		})
	elif debug_label.text.length() > 0:
		debug_label.text = ""
	for db in find_children("*", "DominoBlock", true, true):
		GameManager.board_dominos.append(db)
	if GameManager.dominos_abandoned == 1:
		label_loss_stat.text = "1 tile left on the table"
	else:
		label_loss_stat.text = "%s tiles left on the table" % GameManager.dominos_abandoned


func _input(event):
	if event is InputEventMouseButton or event is InputEventScreenTouch:
		if event.is_pressed():
			GameManager.advance_to_level("res://scenes/level_4_0_startingLevel.tscn")
