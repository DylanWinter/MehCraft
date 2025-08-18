extends GridContainer

const HotbarSlotScene := preload("res://hotbar_box.tscn")
const TILESET_PATH : String = "res://Assets/tileset.png"

var HotbarNodes : Array = []

func _ready():
	var tileset: Texture2D = load(TILESET_PATH) as Texture2D
	columns = Block.BlockType.size()
	for block_type in Block.BlockType.values():
		if block_type == Block.BlockType.BEDROCK:
			continue
		var slot: Node = HotbarSlotScene.instantiate()
		var block = Block.new(block_type)
		var tile_texture := Block.get_tile_image(block.top, tileset)
		slot.get_node("Fill").texture = tile_texture
		slot.name = str(int(block_type))
		HotbarNodes.append(slot)
		add_child(slot)
