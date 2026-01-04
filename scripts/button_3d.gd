class_name BoxButton3D
extends StaticBody3D

signal button_pressed

@onready var debug_mesh: MeshInstance3D = $DebugMesh
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	debug_mesh.queue_free()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass
	
func touched():
	emit_signal("button_pressed")
	
