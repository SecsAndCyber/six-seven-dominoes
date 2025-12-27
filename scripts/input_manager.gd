extends Node
# We store the velocity so other scripts can read it
var gyro_velocity: Vector3 = Vector3.ZERO
var tilt_vector: Vector3 = Vector3.ZERO

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	if OS.has_feature("mobile"):
		gyro_velocity = Input.get_gyroscope()
		tilt_vector = Input.get_gravity()

func _input(event):
	if event is InputEventScreenTouch and event.pressed:
		# Use a Raycast from the camera to see if the user touched this domino
		# If hit, call apply_player_push()
		pass
