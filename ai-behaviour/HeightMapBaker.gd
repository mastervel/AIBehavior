@tool
extends MeshInstance3D

# Plane size and subdivisions
@export var width: float = 10.0:
	get = getWidth,
	set = setWidth
@export var depth: float = 10.0:
	get = getDepth,
	set = setDepth
@export_range(1, 1024, 1) var subdiv_width: int = 10:
	get = getSubDivWidth,
	set = setSubDivWidth
@export_range(1, 1024, 1) var subdiv_depth: int = 10:
	get = getSubDivDepth,
	set = setSubDivDepth
@export var heightmap : Texture2D:
	get = getHeightMapPath,
	set = setHeightMapPath
@export var tiling : float = 1:
	get = getTiling,
	set = setTiling

func _enter_tree() -> void:
	if Engine.is_editor_hint():
		_generate_plane_mesh()

#region Setter & Getters 
func getTiling():
	return tiling

func setTiling(t: float) -> void:
	tiling = t
	if Engine.is_editor_hint():
		_generate_plane_mesh()

func getHeightMapPath():
	return heightmap

func setHeightMapPath(s: Texture2D) -> void:
	heightmap = s
	if Engine.is_editor_hint():
		_generate_plane_mesh()

func getWidth() -> float:
	return width

func setWidth(v: float) -> void:
	width = v
	if Engine.is_editor_hint():
		_generate_plane_mesh()

func getDepth() -> float:
	return depth

func setDepth(v: float) -> void:
	depth = v
	if Engine.is_editor_hint():
		_generate_plane_mesh()

func getSubDivWidth() -> int:
	return subdiv_width

func setSubDivWidth(v: int) -> void:
	subdiv_width = v
	if Engine.is_editor_hint():
		_generate_plane_mesh()

func getSubDivDepth() -> int:
	return subdiv_depth

func setSubDivDepth(v: int) -> void:
	subdiv_depth = v
	if Engine.is_editor_hint():
		_generate_plane_mesh()
#endregion

func _generate_plane_mesh() -> void:
	
	if heightmap == null:
		var pm := PlaneMesh.new()
		pm.size = Vector2(width,depth)
		pm.subdivide_width = subdiv_width
		pm.subdivide_depth = subdiv_depth
		self.mesh = pm
		return
	
	# Heightmap Retrieved
	var img : Image = heightmap.get_image()
	
	# Vertex Positions & UVs
	var verts_uvs := _get_verts_and_UVs(img)
	var verts : PackedVector3Array = verts_uvs[0]
	var uvs : PackedVector2Array = verts_uvs[1]
	
	# Indices 
	var indices := _get_indices()
	
	# Normals
	var normals := _get_normals(verts, indices)
	
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_INDEX] = indices
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_NORMAL] = normals
	
	var array_mesh := ArrayMesh.new()
	array_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	self.mesh = array_mesh


#region Helper Functions
func _sample_height(img: Image, u: float, v: float) -> float:
	var w := float(img.get_width())
	var h := float(img.get_height())
	
	# Get Pixel Coord
	var px := int(floor(u * (w - 1.0)))
	var py := int(floor(v * (h - 1.0)))
	
	# Get Color at Pixel Coord
	var height := img.get_pixel(px,py).r
	
	return height

func _get_verts_and_UVs(img: Image) -> Array:
	var verts_array := PackedVector3Array()
	var uvs_array := PackedVector2Array()
	
	var step_x := width / float(subdiv_width)
	var step_z := depth / float(subdiv_depth)
	var start_x := -width * 0.5
	var start_z := -depth * 0.5
	
	# Vertex Positions & UVs
	for z in range(subdiv_depth + 1):
		var v_uv := float(z) / float(subdiv_depth)
		for x in range(subdiv_width + 1):
			var u_uv := float(x) / float(subdiv_width)
			var vert_x := start_x + float(x) * step_x
			var vert_y := _sample_height(img, u_uv, v_uv)
			var vert_z := start_z + float(z) * step_z
			verts_array.append(Vector3(vert_x, vert_y, vert_z))
			uvs_array.append(Vector2(u_uv * tiling, v_uv * tiling))
	return [verts_array, uvs_array]

func _get_indices() -> PackedInt32Array:
	var index_array := PackedInt32Array()
	for z in range(subdiv_depth):
		for x in range(subdiv_width):
			var i0 := z * (subdiv_width + 1) + x
			var i1 := i0 + 1
			var i2 := i0 + (subdiv_width + 1)
			var i3 := i2 + 1
				# Triangle 1
			index_array.append(i0)
			index_array.append(i1)
			index_array.append(i2)
				# Triangle 2
			index_array.append(i1)
			index_array.append(i3)
			index_array.append(i2)
	return index_array

func _get_normals(verts: PackedVector3Array, indices: PackedInt32Array) -> PackedVector3Array:
	var normals := PackedVector3Array()
	normals.resize(verts.size())
	for i in range(normals.size()):
		normals[i] = Vector3.ZERO
	
	for i in range(0, indices.size(), 3):
		# Get the indices for the triangle
		var index_a := indices[i]
		var index_b := indices[i + 1]
		var index_c := indices[i + 2]
		# Get the corresponding vertex position
		var pos_a := verts[index_a]
		var pos_b := verts[index_b]
		var pos_c := verts[index_c]
		# Calculate triangle face normal
		var face_normal: Vector3 = (pos_c - pos_a).cross(pos_b - pos_a)
		if face_normal.length() == 0:
			continue # Skipping degenerate triangles
		
		face_normal = face_normal.normalized()
		normals[index_a] += face_normal
		normals[index_b] += face_normal
		normals[index_c] += face_normal
	
	for i in range(normals.size()):
		if normals[i].length() == 0:
			normals[i] = Vector3.UP
		else:
			normals[i] = normals[i].normalized()
	return normals
#endregion
