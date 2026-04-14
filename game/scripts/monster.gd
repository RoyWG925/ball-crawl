class_name Monster
extends StaticBody2D

@export var max_hp: int = 3
var hp: int = 0

signal died

@onready var hp_label: Label = $HPLabel

func _ready() -> void:
    hp = max_hp
    _update_label()

func take_damage(amount: int) -> void:
    hp = max(0, hp - amount)
    _update_label()
    if is_dead():
        died.emit()
        queue_free()

func is_dead() -> bool:
    return hp <= 0

func _update_label() -> void:
    if is_node_ready() and hp_label != null:
        hp_label.text = str(hp)
