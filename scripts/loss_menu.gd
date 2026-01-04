class_name LossMenu
extends Node3D

@onready var label_loss_stat: Label3D = $Camera3D/Splash/Label_Loss_Stat
@onready var streak_label: Label3D = $Camera3D/StreakLabel
@onready var debug_label: Label3D = $Camera3D/DebugLabel
@onready var coins_label: Label3D = $Camera3D/CoinsLabel

func update_ui(_delta:float = 0.0):
	if OS.is_debug_build():
		debug_label.text = "DEV {LevelName}".format({
			'LevelName':get_node("/root/").get_children()[3].name,
		})
	elif debug_label.text.length() > 0:
		debug_label.text = ""
	streak_label.text = "%s Streak" % ["•".repeat(GameManager.click_streak)]
	coins_label.text = "%s Coins" % [GameManager.coins]
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	update_ui()
	for db in find_children("*", "DominoBlock", true, true):
		GameManager.board_dominos.append(db)
	if GameManager.dominos_abandoned == 1:
		label_loss_stat.text = "1 tile left on the table"
	else:
		label_loss_stat.text = "%s tiles left on the table" % GameManager.dominos_abandoned

func _process(_delta: float) -> void:
	update_ui(_delta)


func _on_resume_button_3d_button_pressed() -> void:
	GameManager.advance_to_level(GameManager.STARTING_LEVEL)
