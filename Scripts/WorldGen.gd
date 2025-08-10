extends Node3D

@export var WORLD_WIDTH : int # in blocks
@export var SEED : int = 2009
const WORLD_DEPTH : int = 32
const CHUNK_SIZE : int = 16

class Chunk:
	var blocks: Array
	var static_body : StaticBody3D
	var mesh_instance : MeshInstance3D
	func _init():
		blocks = []
		for x in CHUNK_SIZE:
			var y_layer := []
			for y in WORLD_DEPTH:
				var z_layer := []
				for z in CHUNK_SIZE:
					z_layer.append(null)
				y_layer.append(z_layer)
			blocks.append(y_layer)

var chunks: Dictionary = {}
var noise = FastNoiseLite.new()

var block_material := StandardMaterial3D.new()
const TILESET_PATH : String = "res://Assets/tileset.png"

func _ready():
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	noise.seed = SEED
	noise.frequency = 0.004
	generate_world()
	build_world()
	block_material.albedo_texture = load(TILESET_PATH)
	block_material.roughness = 1.0
	block_material.uv1_scale = Vector3(1.0 / 8, 1.0 / 8, 1.0)
	block_material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST

# -- Conversions --	
func world_to_block_coords(world_pos: Vector3) -> Vector3i:
	return Vector3i(
		floor(world_pos.x + WORLD_WIDTH / 2),
		floor(world_pos.y + WORLD_DEPTH / 2),
		floor(world_pos.z + WORLD_WIDTH / 2)
	)

func mod_floor(a: int, b: int) -> int:
	var result := a % b
	return result if result >= 0 else result + b

func world_to_local_coords(pos: Vector3i) -> Vector3i:
	return Vector3i(
		mod_floor(pos.x, CHUNK_SIZE),
		mod_floor(pos.y, CHUNK_SIZE),
		mod_floor(pos.z, CHUNK_SIZE)
	)

func get_chunk_coords(block_pos: Vector3i) -> Vector2i:
	return Vector2i(
		floor(block_pos.x / CHUNK_SIZE),
		floor(block_pos.z / CHUNK_SIZE)
	)

func get_block_in_chunk(chunk: Chunk, local_pos: Vector3i) -> Block:
	if local_pos.x < 0 or local_pos.x >= CHUNK_SIZE: return null
	if local_pos.y < 0 or local_pos.y >= WORLD_DEPTH: return null
	if local_pos.z < 0 or local_pos.z >= CHUNK_SIZE: return null
	return chunk.blocks[local_pos.x][local_pos.y][local_pos.z]

func set_block_in_chunk(chunk: Chunk, local_pos: Vector3i, block) -> void:
	if local_pos.x < 0 or local_pos.x >= CHUNK_SIZE: return
	if local_pos.y < 0 or local_pos.y >= WORLD_DEPTH: return
	if local_pos.z < 0 or local_pos.z >= CHUNK_SIZE: return
	chunk.blocks[local_pos.x][local_pos.y][local_pos.z] = block
	
func block_to_chunk_coords(pos: Vector3i) -> Vector2i:
	return Vector2i(floor(pos.x / CHUNK_SIZE), floor(pos.z / CHUNK_SIZE))
	
func block_to_local_coords(pos: Vector3i) -> Vector3i:
	return Vector3i(
		pos.x % CHUNK_SIZE,
		pos.y,
		pos.z % CHUNK_SIZE
	)

# Determines whether a block is air/OoB	
func is_air(pos: Vector3i) -> bool:
	if pos.y < 0 or pos.y >= WORLD_DEPTH:
		return true
	var chunk_coords := Vector2i(floor(pos.x / CHUNK_SIZE), floor(pos.z / CHUNK_SIZE))
	if not chunks.has(chunk_coords):
		return true
	var chunk = chunks[chunk_coords]
	var local_x: int = pos.x % CHUNK_SIZE
	if local_x < 0:
		local_x += CHUNK_SIZE
	var local_z: int = pos.z % CHUNK_SIZE
	if local_z < 0:
		local_z += CHUNK_SIZE
	return chunk.blocks[local_x][pos.y][local_z] == null

# Gets the block at a position	
func get_block(pos: Vector3i) -> Block:
	var chunk_pos := block_to_chunk_coords(pos)
	if not chunks.has(chunk_pos):
		return null

	var chunk = chunks[chunk_pos]
	var local_pos := block_to_local_coords(pos)

	if local_pos.y < 0 or local_pos.y >= WORLD_DEPTH:
		return null

	return chunk.blocks[local_pos.x][local_pos.y][local_pos.z]	

# Sets the block at a position	
func set_block(pos: Vector3i, block: Block) -> void:
	var chunk_pos := block_to_chunk_coords(pos)
	if not chunks.has(chunk_pos):
		return 

	var chunk = chunks[chunk_pos]
	var local_pos := block_to_local_coords(pos)

	if local_pos.y < 0 or local_pos.y >= WORLD_DEPTH:
		return

	chunk.blocks[local_pos.x][local_pos.y][local_pos.z] = block	

# Generates the world; does not handle visuals or collision	
func generate_world():
	var chunk_count_x: int = int(ceil(float(WORLD_WIDTH) / CHUNK_SIZE))
	var chunk_count_z: int = int(ceil(float(WORLD_WIDTH) / CHUNK_SIZE))

	for cx in range(chunk_count_x):
		for cz in range(chunk_count_z):
			var chunk_coords: Vector2i = Vector2i(cx, cz)
			var chunk = Chunk.new()

			# Populate chunk
			for lx in range(CHUNK_SIZE):
				for lz in CHUNK_SIZE:
					var wx: int = cx * CHUNK_SIZE + lx
					var wz: int = cz * CHUNK_SIZE + lz

					if wx >= WORLD_WIDTH or wz >= WORLD_WIDTH:
						continue

					var height: int = int((noise.get_noise_2d(wx, wz) + 1) / 2 * (WORLD_DEPTH - 1))
					for y in WORLD_DEPTH:
						var block = null
						if y == height + 6:
							block = Block.new(Block.BlockType.GRASS)
						elif y <= height:
							block = Block.new(Block.BlockType.STONE)
						elif y <= height + 6:
							block = Block.new(Block.BlockType.DIRT)
						if block:
							set_block_in_chunk(chunk, Vector3i(lx, y, lz), block)

			chunks[chunk_coords] = chunk

# Builds the mesh and collision for a specified chunk
func build_chunk_mesh(chunk_coords: Vector2i) -> void:
	if not chunks.has(chunk_coords):
		return

	var chunk = chunks[chunk_coords]

	# Remove old mesh nodes if they exist
	if chunk.mesh_instance and chunk.mesh_instance.is_inside_tree():
		chunk.mesh_instance.queue_free()
	if chunk.static_body and chunk.static_body.is_inside_tree():
		chunk.static_body.queue_free()

	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	var start_x := chunk_coords.x * CHUNK_SIZE
	var start_z := chunk_coords.y * CHUNK_SIZE

	# Build mesh from blocks in this chunk
	for x_local in range(CHUNK_SIZE):
		for y in range(WORLD_DEPTH):
			for z_local in range(CHUNK_SIZE):
				var block = chunk.blocks[x_local][y][z_local]
				if block == null:
					continue

				var x = start_x + x_local
				var z = start_z + z_local

				# Position in world space (assuming centered origin)
				var pos: Vector3 = Vector3(
							  x - WORLD_WIDTH / 2,
							  y - WORLD_DEPTH / 2,
							  z - WORLD_WIDTH / 2
						  )

				# Calculate block vertices (p000..p111) same as your build_world()
				var p000 : Vector3 = pos + Vector3(0, 0, 0)
				var p100 : Vector3 = pos + Vector3(1, 0, 0)
				var p110 : Vector3 = pos + Vector3(1, 1, 0)
				var p010 : Vector3 = pos + Vector3(0, 1, 0)
				var p001 : Vector3 = pos + Vector3(0, 0, 1)
				var p101 : Vector3 = pos + Vector3(1, 0, 1)
				var p111 : Vector3 = pos + Vector3(1, 1, 1)
				var p011 : Vector3 = pos + Vector3(0, 1, 1)
				
				# Front (Z-)
				if is_air(Vector3i(x, y, z - 1)):
					var uvs = block.get_tile_uvs(block.side)
					st.set_normal(Vector3(0, 0, -1))
					st.set_uv(uvs[3]); st.add_vertex(p000)
					st.set_uv(uvs[2]); st.add_vertex(p100)
					st.set_uv(uvs[1]); st.add_vertex(p110)
					st.set_uv(uvs[1]); st.add_vertex(p110)
					st.set_uv(uvs[0]); st.add_vertex(p010)
					st.set_uv(uvs[3]); st.add_vertex(p000)
			
				# Back (Z+)
				if is_air(Vector3i(x, y, z + 1)):
					var uvs = block.get_tile_uvs(block.side)
					st.set_normal(Vector3(0, 0, 1))
					st.set_uv(uvs[3]); st.add_vertex(p101)
					st.set_uv(uvs[2]); st.add_vertex(p001)
					st.set_uv(uvs[1]); st.add_vertex(p011)
					st.set_uv(uvs[1]); st.add_vertex(p011)
					st.set_uv(uvs[0]); st.add_vertex(p111)
					st.set_uv(uvs[3]); st.add_vertex(p101)
				
				# Left (X-)
				if is_air(Vector3i(x - 1, y, z)):
					var uvs = block.get_tile_uvs(block.side)
					st.set_normal(Vector3(-1, 0, 0))
					st.set_uv(uvs[3]); st.add_vertex(p001)
					st.set_uv(uvs[2]); st.add_vertex(p000)
					st.set_uv(uvs[1]); st.add_vertex(p010)
					st.set_uv(uvs[1]); st.add_vertex(p010)
					st.set_uv(uvs[0]); st.add_vertex(p011)
					st.set_uv(uvs[3]); st.add_vertex(p001)
				
				# Right (X+)
				if is_air(Vector3i(x + 1, y, z)):
					var uvs = block.get_tile_uvs(block.side)
					st.set_normal(Vector3(1, 0, 0))
					st.set_uv(uvs[3]); st.add_vertex(p100)
					st.set_uv(uvs[2]); st.add_vertex(p101)
					st.set_uv(uvs[1]); st.add_vertex(p111)
					st.set_uv(uvs[1]); st.add_vertex(p111)
					st.set_uv(uvs[0]); st.add_vertex(p110)
					st.set_uv(uvs[3]); st.add_vertex(p100)
				
				# Top (Y+)
				if is_air(Vector3i(x, y + 1, z)):
					var uvs = block.get_tile_uvs(block.top)
					st.set_normal(Vector3(0, 1, 0))
					st.set_uv(uvs[3]); st.add_vertex(p010)
					st.set_uv(uvs[2]); st.add_vertex(p110)
					st.set_uv(uvs[1]); st.add_vertex(p111)
					st.set_uv(uvs[1]); st.add_vertex(p111)
					st.set_uv(uvs[0]); st.add_vertex(p011)
					st.set_uv(uvs[3]); st.add_vertex(p010)
				
				# Bottom (Y-)
				if is_air(Vector3i(x, y - 1, z)):
					var uvs = block.get_tile_uvs(block.bottom)
					st.set_normal(Vector3(0, -1, 0))
					st.set_uv(uvs[3]); st.add_vertex(p001)
					st.set_uv(uvs[2]); st.add_vertex(p101)
					st.set_uv(uvs[1]); st.add_vertex(p100)
					st.set_uv(uvs[1]); st.add_vertex(p100)
					st.set_uv(uvs[0]); st.add_vertex(p000)
					st.set_uv(uvs[3]); st.add_vertex(p001)

	# Commit mesh
	var mesh = st.commit()
	mesh.surface_set_material(0, block_material)
	var mesh_instance = MeshInstance3D.new()
	mesh_instance.mesh = mesh
	# Create collision
	var collision_shape = CollisionShape3D.new()
	var shape = ConcavePolygonShape3D.new()
	shape.set_faces(mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX])
	collision_shape.shape = shape
	# Add to world
	var static_body = StaticBody3D.new()
	static_body.add_child(collision_shape)
	static_body.add_child(mesh_instance)
	add_child(static_body)
	chunk.static_body = static_body
	chunk.mesh_instance = mesh_instance

func update_adjacent_chunks(block_pos: Vector3i) -> void:
	var chunk_coords := block_to_chunk_coords(block_pos)
	var local_pos := block_to_local_coords(block_pos)
	# Rebuild current chunk mesh
	if chunks.has(chunk_coords):
		build_chunk_mesh(chunk_coords)
	var neighbors_to_update := []
	# Check X edges
	if local_pos.x == 0:
		neighbors_to_update.append(chunk_coords + Vector2i(-1, 0))
	elif local_pos.x == CHUNK_SIZE - 1:
		neighbors_to_update.append(chunk_coords + Vector2i(1, 0))
	# Check Z edges
	if local_pos.z == 0:
		neighbors_to_update.append(chunk_coords + Vector2i(0, -1))
	elif local_pos.z == CHUNK_SIZE - 1:
		neighbors_to_update.append(chunk_coords + Vector2i(0, 1))
	# Rebuild neighbor chunk meshes if they exist
	for neighbor_coords in neighbors_to_update:
		if chunks.has(neighbor_coords):
			build_chunk_mesh(neighbor_coords)
	
# Builds the mesh and collision for each chunk in the world
func build_world() -> void:
	for chunk in chunks.values():
		if chunk.static_body and chunk.static_body.is_inside_tree():
			chunk.static_body.queue_free()
	
	for x in range(WORLD_WIDTH):
		for y in range(WORLD_DEPTH):
			for z in range(WORLD_WIDTH):
				var block := get_block(Vector3i(x, y, z))
				if block == null:
					continue

				var world_pos: Vector3i = Vector3i(x, y, z)
				var chunk_coords := block_to_chunk_coords(world_pos)
				var local_coords := block_to_local_coords(world_pos)

				if not chunks.has(chunk_coords):
					var new_chunk = Chunk.new()
					chunks[chunk_coords] = new_chunk

				chunks[chunk_coords].blocks[local_coords.x][local_coords.y][local_coords.z] = block

	# Build mesh for each chunk
	for chunk_coords in chunks.keys():
		build_chunk_mesh(chunk_coords)
		
# Raycasts to find a block; used for breaking and placing
func raycast_block(from: Vector3, direction: Vector3, max_distance: float = 10.0) -> Dictionary:
	var block_pos: Vector3i            = world_to_block_coords(from)
	var ray_origin_blockspace: Vector3 = Vector3(
								  from.x + WORLD_WIDTH / 2,
								  from.y + WORLD_DEPTH / 2,
								  from.z + WORLD_WIDTH / 2
							  )

	var step: Vector3i = Vector3i(
				   sign(direction.x),
				   sign(direction.y),
				   sign(direction.z)
			   )

	var t_delta: Vector3 = Vector3(
					  abs(1.0 / direction.x) if direction.x != 0 else INF,
					  abs(1.0 / direction.y) if direction.y != 0 else INF,
					  abs(1.0 / direction.z) if direction.z != 0 else INF
				  )

	var next_boundary: Vector3 = Vector3(
							((block_pos.x + (step.x > 0 as int)) - ray_origin_blockspace.x) / direction.x if direction.x != 0 else INF,
							((block_pos.y + (step.y > 0 as int)) - ray_origin_blockspace.y) / direction.y if direction.y != 0 else INF,
							((block_pos.z + (step.z > 0 as int)) - ray_origin_blockspace.z) / direction.z if direction.z != 0 else INF
						)

	var t_max: Vector3    =  next_boundary
	var distance_traveled := 0.0
	var previous_pos: Vector3i = block_pos
	
	# DDA
	while distance_traveled < max_distance:
		# Bounds check
		if block_pos.x >= 0 and block_pos.x < WORLD_WIDTH and \
		block_pos.y >= 0 and block_pos.y < WORLD_DEPTH and \
		block_pos.z >= 0 and block_pos.z < WORLD_WIDTH:

			if not is_air(Vector3i(block_pos.x, block_pos.y, block_pos.z)):
				return {
					"hit": block_pos,
					"previous": previous_pos
				}

		previous_pos = block_pos

		# Step to next voxel
		if t_max.x < t_max.y and t_max.x < t_max.z:
			block_pos.x += step.x
			distance_traveled = t_max.x
			t_max.x += t_delta.x
		elif t_max.y < t_max.z:
			block_pos.y += step.y
			distance_traveled = t_max.y
			t_max.y += t_delta.y
		else:
			block_pos.z += step.z
			distance_traveled = t_max.z
			t_max.z += t_delta.z

	return {}  # No hit



	
