extends Resource
class_name Block

const BlockTile = preload("res://Scripts/BlockTile.gd")

enum BlockType { DIRT=0, GRASS=1, STONE=2, LOG=3, LEAVES=4, BRICKS=5, PLANKS=6, BEDROCK=7 }

static var TILE_SIZE : float = 1.0

var block_type
var top : int = BlockTile.Tile.GRASS
var side : int = BlockTile.Tile.DIRT
var bottom : int = BlockTile.Tile.DIRT

func _init(type : BlockType = BlockType.GRASS):
	block_type = type
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

static func get_tile_image(tile_type: BlockTile.Tile, atlas: Texture2D) -> Texture2D:
	var px_size: int = 16
	var tile_coord: Vector2 = tile_coords[tile_type]
	var img := atlas.get_image()
	var region := Rect2i(
					 int(tile_coord.x * px_size),
					 int(tile_coord.y * px_size),
					 px_size,
					 px_size
				 )
	var cropped := img.get_region(region)
	var tex := ImageTexture.create_from_image(cropped)
	return tex

	
static var blocks : Dictionary = {
									 BlockType.GRASS: [BlockTile.Tile.GRASS, BlockTile.Tile.GRASS_SIDE, BlockTile.Tile.DIRT],
									 BlockType.DIRT:  [BlockTile.Tile.DIRT,  BlockTile.Tile.DIRT,       BlockTile.Tile.DIRT],
									 BlockType.STONE:  [BlockTile.Tile.STONE,  BlockTile.Tile.STONE,       BlockTile.Tile.STONE],
									 BlockType.BRICKS:  [BlockTile.Tile.BRICKS,  BlockTile.Tile.BRICKS,       BlockTile.Tile.BRICKS],
									 BlockType.LOG:  [BlockTile.Tile.LOG,  BlockTile.Tile.LOG_SIDE,       BlockTile.Tile.LOG],
									 BlockType.LEAVES:  [BlockTile.Tile.LEAVES,  BlockTile.Tile.LEAVES,       BlockTile.Tile.LEAVES],
									 BlockType.PLANKS:  [BlockTile.Tile.PLANKS,  BlockTile.Tile.PLANKS,       BlockTile.Tile.PLANKS],
									 BlockType.BEDROCK:  [BlockTile.Tile.BEDROCK,  BlockTile.Tile.BEDROCK,       BlockTile.Tile.BEDROCK],
								 };

static var tile_coords : Dictionary = {
										BlockTile.Tile.GRASS : Vector2(0, 0),	
										BlockTile.Tile.GRASS_SIDE : Vector2(0, 1),
										BlockTile.Tile.DIRT: Vector2(0, 2),
										BlockTile.Tile.STONE : Vector2(1, 3),
										BlockTile.Tile.LOG : Vector2(0, 3),
										BlockTile.Tile.LOG_SIDE : Vector2(0, 4),
										BlockTile.Tile.LEAVES : Vector2(1, 0),
										BlockTile.Tile.BRICKS : Vector2(1, 1),
										BlockTile.Tile.PLANKS : Vector2(1, 2),
										BlockTile.Tile.BEDROCK : Vector2(1, 4)
									}									
	
