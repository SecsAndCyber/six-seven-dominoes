class_name LossMenu
extends Node3D

@onready var label_loss_stat: Label3D = $Camera3D/Splash/Label_Loss_Stat
@onready var streak_label: Label3D = $Camera3D/StreakLabel
@onready var debug_label: Label3D = $Camera3D/DebugLabel
@onready var coins_label: Label3D = $Camera3D/CoinsLabel

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	for db in find_children("*", "DominoBlock", true, true):
		GameManager.board_dominos.append(db)
	if GameManager.dominos_abandoned == 1:
		label_loss_stat.text = "1 tile left on the table"
	else:
		label_loss_stat.text = "%s tiles left on the table" % GameManager.dominos_abandoned


func _on_resume_button_3d_button_pressed() -> void:
	GameManager.advance_to_level(GameManager.STARTING_LEVEL)
