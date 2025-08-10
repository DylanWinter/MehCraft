extends Control

var selected : bool = false
const border_texture := preload("res://Assets/hotbarbox.png")
const highlight_texture := preload("res://Assets/hotbarboxh.png")

func _process(_delta: float) -> void:
	if selected:
		$Border.texture = highlight_texture
	else:
		$Border.texture = border_texture
