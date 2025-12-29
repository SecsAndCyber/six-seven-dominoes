extends Node3D

@onready var splash: Node3D = $Camera3D/Splash
@onready var menu_a: Node3D = $Camera3D/MenuA
@onready var menu_about: Node3D = $Camera3D/MenuAbout

func change_menu(new_menu: Node3D) -> void:
	for menu in [splash, menu_a, menu_about]:
		if menu == new_menu:
			menu.visible = true
		else:
			menu.visible = false
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	for db in find_children("*", "DominoBlock", true, true):
		db.freeze = true
		db.set_collision_layer_value(1, false)
	change_menu(splash)

func _input(event):
	if splash.visible:
		if event is InputEventMouseButton or event is InputEventScreenTouch:
			if event.is_pressed():
				change_menu(menu_a)
	elif menu_a.visible:
		if event is InputEventMouseButton or event is InputEventScreenTouch:
			if event.is_pressed():
				print(event)
				get_tree().change_scene_to_file("res://scenes/main_table_space.tscn")
