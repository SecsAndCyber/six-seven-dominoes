@tool
extends EditorScript

#Build domino scenes by creating a child MeshInstance3D on
#`res://scenes/domino_block.tscn` for each FBX in
#`res://assets/ExportedFbx/`, saving results to
#`res://scenes/dominos/default/`.
#
#Run from the Godot Editor (Script -> Run) or attach to an EditorPlugin.
#*/

func _run():
	var src_dir := "res://assets/ExportedFbx"
	var out_dir := "res://scenes/dominos/default"
	var block_path := "res://scenes/domino_block.tscn"
	
	var block_res = ResourceLoader.load(block_path)
	if not block_res:
		printerr("Could not load %s" % block_path)
		return

	# Ensure output directory exists
	DirAccess.make_dir_recursive_absolute(out_dir)
	# Clear output directory
	if DirAccess.dir_exists_absolute(out_dir):
		var dir_access = DirAccess.open(out_dir)
		if dir_access:
			dir_access.list_dir_begin()
			var file = dir_access.get_next()
			while file != "":
				if not file.begins_with("."):
					dir_access.remove(out_dir + "/" + file)
				file = dir_access.get_next()
	var dir = DirAccess.open(src_dir)
	if not dir:
		printerr("Could not open %s" % src_dir)
		return

	dir.list_dir_begin()
	var file_name = dir.get_next()
	while file_name != "":
		if file_name.begins_with("."):
			file_name = dir.get_next()
			continue

		if not dir.current_is_dir() and file_name.to_lower().ends_with(".fbx"):
			var fbx_path := src_dir + "/" + String(file_name)
			var res = ResourceLoader.load(fbx_path)
			var meshes = []
			
			print("Opening %s as %s" % [fbx_path, res])
			if res is PackedScene:
				var inst = res.instantiate()
				meshes = _find_mesh_in_node(inst)
			elif res is Mesh:
				meshes = [res]
			if meshes == null:
				printerr("No mesh found for %s" % fbx_path)
			else:
				var scene_inst = Node3D.new()
				scene_inst.name = file_name
				for mesh_node in meshes:
					# Add MeshInstance3D child with the FBX mesh
					var mi = MeshInstance3D.new()
					mi.name = mesh_node.name
					mi.mesh = mesh_node.mesh
					scene_inst.add_child(mi)
					mi.transform = mesh_node.transform
					# set owner so the node is included when packing/saving
					if scene_inst.has_method("set_owner"):
						mi.owner = scene_inst
				# scene_inst.rotate_object_local(Vector3.RIGHT, PI / 2)
				# scene_inst.scale = Vector3.ONE * 100

				var out_path := out_dir + "/" + file_name.get_basename() + ".tscn"
				var packed := PackedScene.new()
				var err = packed.pack(scene_inst)
				if err != OK:
					printerr("Failed to pack scene for %s" % out_path)
				else:
					var save_err = ResourceSaver.save(packed, out_path)
					if save_err != OK:
						printerr("Failed to save %s" % out_path)
					else:
						print("Saved: %s" % out_path)

		file_name = dir.get_next()

	dir.list_dir_end()
	print("build_dominos: done")


func _find_mesh_in_node(node):
	var meshes = []
	if node == null:
		return meshes
	if node is MeshInstance3D:
		if not node.mesh == null:
			meshes.append(node)
	for child in node.get_children():
		meshes.append_array(_find_mesh_in_node(child))
	return meshes
