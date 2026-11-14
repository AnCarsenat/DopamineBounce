extends Node3D
class_name BounceGame

@onready var player = $PlayerBody
@onready var tileSpawner = $TileSpawning


func get_speed()->float:
	return GameSpeed.multiplier

func get_bpm()->float:
	return GameSpeed.bpm

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass
