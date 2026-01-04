extends Node3D

@export var next_level: String = GameManager.STARTING_LEVEL
@onready var splash: Node3D = $Camera3D/Splash
@onready var splash_button_3d: BoxButton3D = $Camera3D/Splash/SplashButton3D

@onready var menu_a: Node3D = $Camera3D/MenuA
@onready var start_button_3d: BoxButton3D = $Camera3D/MenuA/DominoBlock/StartButton3D
@onready var continue_button_3d: BoxButton3D = $Camera3D/MenuA/DominoBlock2/ContinueButton3D
@onready var about_button_3d: BoxButton3D = $Camera3D/MenuA/DominoBlock3/AboutButton3D

@onready var menu_about: Node3D = $Camera3D/MenuAbout
@onready var contact_button_3d: BoxButton3D = $Camera3D/MenuAbout/DominoBlock3/ContactButton3D

@onready var streak_label: Label3D = $Camera3D/StreakLabel
@onready var debug_label: Label3D = $Camera3D/DebugLabel
@onready var coins_label: Label3D = $Camera3D/CoinsLabel

@onready var menus:Array = [
	[splash, [splash_button_3d]],
	[menu_a, [start_button_3d, continue_button_3d, about_button_3d]],
	[menu_about, [contact_button_3d]],
]
func change_menu(new_menu: Node3D) -> void:
	for menu_array in menus:
		var menu = menu_array[0]
		var buttons = menu_array[1]
		
		if menu == new_menu:
			menu.visible = true
			for button in buttons as Array[PhysicalBone3D]:
				button.set_collision_layer_value(1, true)
		else:
			menu.visible = false
			for button in buttons as Array[PhysicalBone3D]:
				button.set_collision_layer_value(1, false)

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
	GameManager.loadScore()
	update_ui()
	for db in find_children("*", "DominoBlock", true, true):
		db.freeze = true
		db.set_collision_layer_value(1, false)
		prints("Adding", db, "to GameManager")
		GameManager.board_dominos.append(db)
	change_menu(splash)

#func _input(event):
	#if splash.visible:
		#if event is InputEventMouseButton or event is InputEventScreenTouch:
			#if event.is_pressed():
				#change_menu(menu_a)
	#elif menu_a.visible:
		#if event is InputEventMouseButton or event is InputEventScreenTouch:
			#if event.is_pressed():
				#GameManager.advance_to_level(next_level)


func _on_splash_button_3d_button_pressed() -> void:
	if splash.visible:
		change_menu(menu_a)


func _on_menua_about_button_pressed() -> void:
	if menu_a.visible:
		change_menu(menu_about)


func _on_menua_continue_button_pressed() -> void:
	GameManager.advance_to_level(next_level)


func _on_menua_start_button_pressed() -> void:
	GameManager.advance_to_level(next_level, true)


func _on_contact_button_pressed() -> void:
	OS.shell_open("https://bsky.app/profile/slaircoding.itch.io")
