extends Node

@export var lanes: Array[float] = [-7.0, 0.0, 7.0]
@export var tile_count: int = 3
@export var spacing: float = 10.0
@export var tileSpeed = 8.33
var activeTiles: Array[MeshInstance3D] = []
var started := false


@onready var tile: MeshInstance3D = $"../Tile"

func _ready() -> void:
	tile.visible = false
	tile.get_node("StaticBody3D/CollisionShape3D").disabled = true
	
func _process(delta: float) -> void:
	if started:
		for tile in activeTiles.duplicate():
			tile.position.z += tileSpeed * delta
			if tile.position.z > 10.0:
				tile.queue_free()
				activeTiles.erase(tile)
	
	while activeTiles.size() < 3:
		var z = 0.0 if activeTiles.is_empty() else activeTiles.back().position.z - spacing
		activeTiles.append(spawn_tile(Vector3(lanes.pick_random(), -1, z)))


func spawn_tile(spawn_position: Vector3) -> MeshInstance3D:
	var new_tile: MeshInstance3D = tile.duplicate()
	new_tile.visible = true
	new_tile.get_node("StaticBody3D/CollisionShape3D").disabled = false
	get_parent().add_child(new_tile)
	new_tile.global_position = spawn_position
	return new_tile
