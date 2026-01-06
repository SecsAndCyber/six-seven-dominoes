extends Camera3D

@onready var camera_environment: Environment = $".".environment
@onready var parent: Node3D = $".".get_parent()
@onready var coin: Coin = $CoinsLabel/Coin
@onready var directional_light_3d: DirectionalLight3D = $DirectionalLight3D

@onready var streak_label: Label3D = $"."/StreakLabel
@onready var debug_label: Label3D = $"."/DebugLabel
@onready var coins_label: Label3D = $"."/CoinsLabel
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if OS.has_feature("simple_colors"):
		coin.queue_free()

func _process(delta: float) -> void:
	update_ui(delta)

func _enter_tree() -> void:
	streak_label = $"."/StreakLabel
	debug_label = $"."/DebugLabel
	coins_label = $"."/CoinsLabel
	if OS.has_feature("simple_colors"):
		parent = $".".get_parent()
		camera_environment = $".".environment
		directional_light_3d = $DirectionalLight3D
		directional_light_3d.shadow_enabled = false
		var tt = parent.get_node("TableTop")
		if tt:
			var TableTop2 = tt.get_node("TableTop2")
			TableTop2.mesh.material.albedo_color = "#222222"
		if camera_environment:
			camera_environment.ambient_light_energy = 1.0
			camera_environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
			camera_environment.ambient_light_color = "#000000"
			camera_environment.background_mode = Environment.BG_CANVAS
			camera_environment.tonemap_mode = Environment.TONE_MAPPER_LINEAR
			camera_environment.tonemap_white = 1.0
			camera_environment.tonemap_exposure = 1.0
		else:
			printerr("Unable to locate camera_environment")
	else:
		camera_environment = $".".environment
		camera_environment.ssao_enabled = true
		camera_environment.ssil_enabled = true
	update_ui(0)


func update_ui(_delta:float = 0.0):
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
