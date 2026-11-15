extends Node

@export var lanes: Array[float] = [-7.0, 0.0, 7.0]
@export var tile_count: int = 3
@export var spacing: float = 10.0
@export var tileSpeed = 8.33
## Chance for a new tile to carry an item (whitehole or sun, equally likely).
@export_range(0.0, 1.0) var item_chance: float = 1.0 / 12.0
## Height of the item above the tile's centre.
@export var item_height: float = 0.9
## The first few tiles never carry an item.
@export var item_free_tiles: int = 3
var _tiles_spawned: int = 0
@onready var effects = $"../ItemEffects"
var activeTiles: Array[MeshInstance3D] = []
var started := false
## Actual scroll speed right now; re-tuned by the ball on every bounce.
var current_speed: float = 0.0


@onready var tile: MeshInstance3D = $"../Tile"

func _ready() -> void:
	current_speed = tileSpeed
	tile.visible = false
	tile.get_node("StaticBody3D/CollisionShape3D").disabled = true
	

func get_tile_pos_from_pos():
	var curr_pos = activeTiles[0].position.x
	print(curr_pos)

	if (curr_pos == lanes[1]):
		return lanes.pick_random()
	if curr_pos == lanes[0]:
		return [lanes[0],lanes[1]].pick_random()
	if curr_pos == lanes[2]:
		return [lanes[1],lanes[2]].pick_random()
	return 0
		
func _process(delta: float) -> void:
	if started:
		for tile in activeTiles.duplicate():
			tile.position.z += current_speed * delta
			if tile.position.z > 10.0:
				tile.queue_free()
				activeTiles.erase(tile)
	
	
	while activeTiles.size() < 3:
		var z = 0.0 if activeTiles.is_empty() else activeTiles.back().position.z - spacing
		# The ball starts over the middle lane, so the very first tile must be there.
		var lane_x: float = lanes[lanes.size() / 2] if _tiles_spawned == 0 else get_tile_pos_from_pos()
		activeTiles.append(spawn_tile(Vector3(lane_x, -1, z)))


## Called by the ball each time it bounces. Picks the scroll speed that brings the
## next tile under the ball exactly when it lands, so timing errors never pile up
## while the game is speeding up.
func sync_to_bounce(multiplier: float, air_time: float) -> void:
	var nominal: float = tileSpeed * multiplier
	current_speed = nominal

	var next_tile: MeshInstance3D = null
	for t in activeTiles:
		if t.position.z < -spacing * 0.5 and (next_tile == null or t.position.z > next_tile.position.z):
			next_tile = t
	if next_tile and air_time > 0.0:
		current_speed = clampf(-next_tile.position.z / air_time, nominal * 0.75, nominal * 1.25)


func spawn_tile(spawn_position: Vector3) -> MeshInstance3D:
	var new_tile: MeshInstance3D = tile.duplicate()
	new_tile.visible = true
	new_tile.get_node("StaticBody3D/CollisionShape3D").disabled = false
	get_parent().add_child(new_tile)
	new_tile.global_position = spawn_position

	_tiles_spawned += 1
	if _tiles_spawned > item_free_tiles and randf() < item_chance:
		var type: TileItem.Type = [TileItem.Type.WHITEHOLE, TileItem.Type.SUN].pick_random()
		# No second copy of an effect that is already running.
		if not effects.is_active(type):
			var item := TileItem.new()
			item.type = type
			item.effects = effects
			item.position.y = item_height
			new_tile.add_child(item)
	return new_tile
