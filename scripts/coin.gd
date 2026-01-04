extends StaticBody3D


const SPIN_VELOCITY = 3

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	rotate_y(SPIN_VELOCITY * delta)

func touched() -> void:
	$AudioStreamPlayer3D.play()

func _on_audio_stream_player_3d_finished() -> void:
	pass #queue_free()
