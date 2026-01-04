extends Node3D

@export var next_level: String = "res://scenes/level_4_0_startingLevel.tscn"
@onready var splash: Node3D = $Camera3D/Splash
@onready var menu_a: Node3D = $Camera3D/MenuA
@onready var menu_about: Node3D = $Camera3D/MenuAbout
@onready var debug_label: Label3D = $Camera3D/DebugLabel

func change_menu(new_menu: Node3D) -> void:
	for menu in [splash, menu_a, menu_about]:
		if menu == new_menu:
			menu.visible = true
		else:
			menu.visible = false
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if OS.is_debug_build():
		debug_label.text = "DEV {LevelName}".format({
			'LevelName':get_node("/root/").get_children()[3].name,
		})
	elif debug_label.text.length() > 0:
		debug_label.text = ""
	for db in find_children("*", "DominoBlock", true, true):
		db.freeze = true
		db.set_collision_layer_value(1, false)
		prints("Adding", db, "to GameManager")
		GameManager.board_dominos.append(db)
	change_menu(splash)

func _input(event):
	if splash.visible:
		if event is InputEventMouseButton or event is InputEventScreenTouch:
			if event.is_pressed():
				change_menu(menu_a)
	elif menu_a.visible:
		if event is InputEventMouseButton or event is InputEventScreenTouch:
			if event.is_pressed():
				GameManager.advance_to_level(next_level)
