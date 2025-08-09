extends Resource
class_name Block

const BlockTile = preload("res://Scripts/BlockTile.gd")

enum BlockType { AIR, DIRT, GRASS, STONE, LOG, LEAVES, BRICKS }

var TILE_SIZE : float = 1.0

var top : int = BlockTile.Tile.GRASS
var side : int = BlockTile.Tile.DIRT
var bottom : int = BlockTile.Tile.DIRT

func _init(type : BlockType = BlockType.GRASS):
	top = blocks[type][0]
	side = blocks[type][1]
	bottom = blocks[type][2]
	
func get_tile_uvs(tile_type: BlockTile.Tile) -> Array:
	var tile_coord : Vector2 = tile_coords[tile_type]
	var uv_origin: Vector2 = Vector2(tile_coord.x, tile_coord.y) * TILE_SIZE
	return [
		uv_origin + Vector2(0, 0),
		uv_origin + Vector2(TILE_SIZE, 0),
		uv_origin + Vector2(TILE_SIZE, TILE_SIZE),
		uv_origin + Vector2(0, TILE_SIZE)
	]
	
static var blocks : Dictionary = {
									 BlockType.GRASS: [BlockTile.Tile.GRASS, BlockTile.Tile.GRASS_SIDE, BlockTile.Tile.DIRT],
									 BlockType.DIRT:  [BlockTile.Tile.DIRT,  BlockTile.Tile.DIRT,       BlockTile.Tile.DIRT],
									 BlockType.STONE:  [BlockTile.Tile.STONE,  BlockTile.Tile.STONE,       BlockTile.Tile.STONE],
								 };

static var tile_coords : Dictionary = {
										BlockTile.Tile.GRASS : Vector2(0, 0),	
										BlockTile.Tile.GRASS_SIDE : Vector2(0, 1),
										BlockTile.Tile.DIRT: Vector2(0, 2),
										BlockTile.Tile.STONE : Vector2(1, 3),
										BlockTile.Tile.LOG : Vector2(0, 3),
										BlockTile.Tile.LOG_SIDE : Vector2(0, 4),
										BlockTile.Tile.LEAVES : Vector2(1, 0),
										BlockTile.Tile.BRICKS : Vector2(1, 2)
									}									
	
