extends Camera3D

signal cancel_button_pressed
@onready var camera_environment: Environment = $".".environment
@onready var parent: Node = $".".get_parent()
@onready var coin: Coin = $CoinsLabel/Coin
@onready var directional_light_3d: DirectionalLight3D = $DirectionalLight3D

@onready var streak_label: Label3D = $"."/StreakLabel
@onready var debug_label: Label3D = $"."/DebugLabel
@onready var coins_label: Label3D = $"."/CoinsLabel
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	get_viewport().size_changed.connect(_on_window_resized)
	_on_window_resized()
	if GameManager.is_low_spec:
		coin.queue_free()

func _process(delta: float) -> void:
	update_ui(delta)

func _enter_tree() -> void:
	streak_label = $"."/StreakLabel
	debug_label = $"."/DebugLabel
	coins_label = $"."/CoinsLabel
	if GameManager.is_low_spec:
		parent = $".".get_parent()
		camera_environment = $".".environment
		directional_light_3d = $DirectionalLight3D
		directional_light_3d.shadow_enabled = false
		var tt = parent.get_node("TableTop")
		if tt:
			var TableTop2 = tt.get_node("TableTop2")
			TableTop2.mesh.material.albedo_color = "#222222"
		if camera_environment:
			camera_environment.ssao_enabled = false
			camera_environment.ssil_enabled = false
			camera_environment.glow_enabled = false
			camera_environment.ambient_light_energy = 1.0
			camera_environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
			camera_environment.ambient_light_color = "#000000"
			camera_environment.background_mode = Environment.BG_COLOR
			camera_environment.tonemap_mode = Environment.TONE_MAPPER_LINEAR
			camera_environment.tonemap_white = 1.0
			camera_environment.tonemap_exposure = 1.0
			get_viewport().scaling_3d_scale = 0.70
		else:
			printerr("Unable to locate camera_environment")
	else:
		get_viewport().screen_space_aa = Viewport.SCREEN_SPACE_AA_SMAA
		camera_environment = $".".environment
		camera_environment.ssao_enabled = true
		camera_environment.ssil_enabled = true
	update_ui(0)


func update_ui(_delta:float = 0.0):
	if not is_inside_tree():
		return
	if OS.is_debug_build():
		debug_label.text = "{LevelName} FPS:{FPS}".format({
			'LevelName':get_node("/root/").get_children()[3].name,
			'FPS':str(int(1.0 / _delta)) if _delta else '??'
		})
	elif debug_label.text.length() > 0:
		debug_label.text = ""
	if streak_label:
		streak_label.text = GameManager.click_streak_string
	if coins_label:
		coins_label.text = GameManager.coins_string

func _on_window_resized():
	var debug_label_pos = Vector2(5,25)
	var streak_label_pos = Vector2(get_viewport().get_visible_rect().size.x - 5,20)
	var coin_label_pos = Vector2(
							get_viewport().get_visible_rect().size.x - 25,
							get_viewport().get_visible_rect().size.y - 15)
	var world_pos = self.project_position(debug_label_pos, 6.0) # 10.0 is distance from camera
	
	debug_label.global_position = world_pos
	
	world_pos = self.project_position(streak_label_pos, 6.0)
	streak_label.global_position= world_pos

	world_pos = self.project_position(coin_label_pos, 3.0)
	coins_label.global_position= world_pos


func _cancel_button_pressed() -> void:
	cancel_button_pressed.emit()
