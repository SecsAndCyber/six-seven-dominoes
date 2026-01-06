extends Camera3D

@onready var camera_environment: Environment = $".".environment
@onready var parent: Node3D = $".".get_parent()
@onready var coin: Coin = $CoinsLabel/Coin

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if OS.has_feature("simple_colors"):
		coin.queue_free()

func _enter_tree() -> void:
	if OS.has_feature("simple_colors"):
		parent = $".".get_parent()
		camera_environment = $".".environment
		var tt = parent.get_node("TableTop")
		if tt:
			var TableTop2 = tt.get_node("TableTop2")
			TableTop2.mesh.material.albedo_color = "#222222"
		if camera_environment:
			camera_environment.ambient_light_energy = 1.0
			camera_environment.ambient_light_source = Environment.AMBIENT_SOURCE_BG
			camera_environment.ambient_light_color = "#000000"
			camera_environment.ssao_enabled = false
			camera_environment.ssil_enabled = false
		else:
			printerr("Unable to locate camera_environment")
