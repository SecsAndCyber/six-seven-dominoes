extends Node3D

@export_enum("default") var skin: String = "default":
	set(val):
		skin = val
			
var idle_dominoes: Dictionary[Vector2i, Node3D]
func _ready():
	for id in domino_ids():
		var scene_path = domino_scene(id)
		if ResourceLoader.exists(scene_path):
			var scene = ResourceLoader.load(scene_path)
			var instance = scene.instantiate()
			instance.name = "Domino-%d-%d" % [id.x, id.y]
			print(id, instance)
			idle_dominoes[id] = instance
		else:
			printerr("Tried to load missing file ", scene_path)

func domino_scene(id) -> String:
	return "res://scenes/dominos/%s/Domino.%d.%d.tscn" % [skin, id.x, id.y]

func domino_ids() -> Array[Vector2i]:
	var examine_id:Vector2i = Vector2i(0,0) 
	var domino_values:Array[Vector2i] = []
	var t:int = 0
	var b_index:int = 0
	var bs:Array[int] = []
	while examine_id.x < 8 and examine_id.y < 8:
		if not t in bs:
			bs.append(t)
		examine_id.x = min(t, bs[b_index])
		examine_id.y = max(t, bs[b_index])
		if not (examine_id.x < 8 and examine_id.y < 8):
			break
		domino_values.append(examine_id)
		if b_index == bs.size()-1:
			b_index = 0
			t += 1
		else:
			b_index += 1
	return domino_values
	
func return_to_stack(db: Node3D):
	if db is DominoBlock:
		if db.get_node("MeshContainer").get_child_count() > 0:
			var image = db.get_node("MeshContainer").get_child(0)
			if not null == image:
				image.get_parent().remove_child(image)
				prints("Returned", db.id, image)
				idle_dominoes[db.id] = image
			else:
				printerr("Returned missing image to stack", db)
	else:
		printerr("Unknown return to stack")

func draw_from_stack(id: Vector2i, parent: Node3D = null):
	if not idle_dominoes.has(id):
		printerr("Requested missing block ", id)
		return null
	if null == idle_dominoes[id]:
		return null
	var db = idle_dominoes[id]
	if null == db:
		printerr("Requested empty block ", id)
	idle_dominoes.erase(id)
	if not null == parent:
		parent.add_child(db)
	return db

func validate_stack():
	for id in domino_ids():
		if not idle_dominoes.has(id):
			printerr("Missing domino:", id)
			continue
		if null == idle_dominoes[id]:
			printerr("Null domino:", id)
			continue
		if idle_dominoes[id].is_inside_tree():
			printerr("Leaked domino:", id)
			continue
			
