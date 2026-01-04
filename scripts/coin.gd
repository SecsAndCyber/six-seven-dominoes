class_name Coin
extends StaticBody3D

signal animation_completed

@export var spin_velocity = 3
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass

func animate_to_position_free(target_pos: Vector3, dest_pos:Vector3, duration:float=2.0):
	$AudioStreamPlayer3D.play()
	var tween = create_tween()
	tween.tween_property(self, "global_transform:origin", target_pos, duration)\
		.set_trans(Tween.TRANS_BACK)\
		.set_ease(Tween.EASE_OUT)
	tween.finished.connect(
		func():
			var inner_tween = create_tween()
			inner_tween.tween_property(self, "global_transform:origin", dest_pos, duration/2)\
				.set_trans(Tween.TRANS_LINEAR)
			inner_tween.finished.connect(
				func():
					animation_completed.emit()
					queue_free()
			)
	)
	return animation_completed


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	rotate_y(spin_velocity * delta)

func touched() -> void:
	$AudioStreamPlayer3D.play()

func _on_audio_stream_player_3d_finished() -> void:
	pass #queue_free()
