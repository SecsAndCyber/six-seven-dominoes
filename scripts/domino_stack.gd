# This class manages the visual meshes of the Dominos
# DominoBlock handles the game physics, logic, and memory of the Domino
class_name DominoStackClass
extends Node

@export_enum("default") var skin: String = "default":
	set(val):
		skin = val
			
var idle_dominoes: Dictionary[Vector2i, Node3D]
var preloader: Dictionary[Vector2i, PackedScene]
var wildcard_domino: Node3D = null

func domino_factory(id:Vector2i):
	if id in preloader:
		return preloader[id].instantiate()
	var scene_path = domino_scene(id)
	if ResourceLoader.exists(scene_path):
		preloader[id] = ResourceLoader.load(scene_path)
		return preloader[id].instantiate()
	else:
		printerr("Tried to load missing file ", scene_path)
		return null

func _ready():
	for id in domino_ids():
		var instance = domino_factory(id)
		if null == instance:
			continue
		instance.name = "Domino-%d-%d" % [id.x, id.y]
		idle_dominoes[id] = instance
	wildcard_domino = domino_factory(Vector2i(0,0))
	wildcard_domino.name = "WildCardDomino"

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
	# Return the mesh node to the stack from DominoBlock
	if db is DominoBlock:
		assert(db.get_node("MeshContainer").get_child_count() <= 1,
				"Too many meshes attached!")
		if db.get_node("MeshContainer").get_child_count() > 0:
			var image = db.get_node("MeshContainer").get_child(0)
			if not null == image:
				image.get_parent().remove_child(image)
				if db.is_wildcard:
					# orphan the wildcard mesh so that it doesn't get destroyed
					# on level change. Maintain pointer
					wildcard_domino = image
				else:
					idle_dominoes[db.id] = image
			else:
				printerr("Returned missing image to stack", db)
	else:
		printerr("Unknown return to stack")

func draw_wildcard(parent: Node3D = null):
	if wildcard_domino == null:
		printerr("No wildcard available in stack!")
		return null
	var wd = wildcard_domino
	# We "null" it here so we know it's currently 'in the wild'
	wildcard_domino = null
	if parent:
		parent.add_child(wd)
	return wd

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

func _notification(what):
	if what == NOTIFICATION_PREDELETE:
		validate_stack()
		# --- THE FIX: Clear the pool to prevent leaks ---
		for id in idle_dominoes:
			var node = idle_dominoes[id]
			if is_instance_valid(node):
				node.queue_free()
		idle_dominoes.clear()
		
		if is_instance_valid(wildcard_domino):
			wildcard_domino.queue_free()
