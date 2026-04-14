class_name Tile
extends RefCounted

enum Type {
    NORMAL,
    SURGE,
    EVENT,
    START
}

var type: Type = Type.NORMAL
var index: int = 0

func _init(p_index: int, p_type: Type = Type.NORMAL) -> void:
    index = p_index
    type = p_type
