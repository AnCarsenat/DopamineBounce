extends Node
## Runs the timed effects triggered by tile items:
##  - Whitehole: the ball only bounces when the player presses space.
##  - Sun: the light flickers and tiles are only visible during the flashes.

@export var whitehole_duration: float = 20.0
@export var sun_duration: float = 45.0
## Automatic bounces still given right after picking up a whitehole, so the player has time to react.
@export var whitehole_grace_bounces: int = 2

@export_group("Sun Flicker")
## Light energy between flashes, as a fraction of normal (keeps the ball visible).
@export var dark_light_factor: float = 0.3
## Light energy at the peak of a flash, as a fraction of normal.
@export var flash_light_factor: float = 2.0
## All timings below are in bounces, so the flicker speeds up with the game and stays fair.
@export var flash_hold: float = 0.2
@export var flash_fade: float = 0.4
@export var cycle_min: float = 1.3
@export var cycle_max: float = 1.6

@onready var player = $"../PlayerBody"
@onready var light: DirectionalLight3D = $"../DirectionalLight3D"
@onready var label: Label = $"../Hud/EffectsLabel"
@onready var tile_material: BaseMaterial3D = $"../Tile".mesh.material
@onready var _base_light_energy: float = light.light_energy

var manual_time_left: float = 0.0
var manual_grace: int = 0
var sun_time_left: float = 0.0
## Tile items copy this so they hide together with the tiles.
var items_visible: bool = true

var _cycle_time: float = 0.0
var _cycle_length: float = 1.0

## True while the ball must be bounced by hand.
var manual_bounce: bool:
	get:
		return manual_time_left > 0.0


func _ready() -> void:
	# The tile material is shared with the cached scene, so make sure a death
	# in the middle of a sun effect does not leave it faded after the reload.
	_set_darkness(1.0, 1.0)
	tile_material.transparency = BaseMaterial3D.TRANSPARENCY_DISABLED


func _exit_tree() -> void:
	tile_material.albedo_color.a = 1.0
	tile_material.transparency = BaseMaterial3D.TRANSPARENCY_DISABLED


func is_active(type: TileItem.Type) -> bool:
	return manual_bounce if type == TileItem.Type.WHITEHOLE else sun_time_left > 0.0


func activate(type: TileItem.Type) -> void:
	if type == TileItem.Type.WHITEHOLE:
		if not manual_bounce:
			manual_grace = whitehole_grace_bounces
		manual_time_left = whitehole_duration
	else:
		if sun_time_left <= 0.0:
			_cycle_time = 0.0
			_cycle_length = 0.0
			tile_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		sun_time_left = sun_duration


func _process(delta: float) -> void:
	if manual_time_left > 0.0:
		manual_time_left -= delta

	if sun_time_left > 0.0:
		sun_time_left -= delta
		if sun_time_left > 0.0:
			_update_flicker(delta)
		else:
			_set_darkness(1.0, 1.0)
			tile_material.transparency = BaseMaterial3D.TRANSPARENCY_DISABLED

	_update_label()


func _update_flicker(delta: float) -> void:
	var bounce_time: float = 2.0 * player.bounce_velocity / (player.gravity * player.speed_multiplier)
	_cycle_time += delta
	if _cycle_time >= _cycle_length:
		_cycle_time = 0.0
		_cycle_length = randf_range(cycle_min, cycle_max) * bounce_time

	var hold := flash_hold * bounce_time
	var fade := flash_fade * bounce_time
	if _cycle_time < hold:
		# Flash: tiles fully visible, light spikes then settles.
		_set_darkness(1.0, lerpf(flash_light_factor, 1.0, _cycle_time / hold))
	elif _cycle_time < hold + fade:
		var k := (_cycle_time - hold) / fade
		_set_darkness(1.0 - k, lerpf(1.0, dark_light_factor, k))
	else:
		_set_darkness(0.0, dark_light_factor)


func _set_darkness(tile_alpha: float, light_factor: float) -> void:
	tile_material.albedo_color.a = tile_alpha
	light.light_energy = _base_light_energy * light_factor
	var show_items := tile_alpha > 0.3
	if show_items != items_visible:
		items_visible = show_items
		get_tree().call_group(TileItem.GROUP, "set_visible", show_items)


func _update_label() -> void:
	var lines: PackedStringArray = []
	if manual_time_left > 0.0:
		lines.append("WHITEHOLE - press SPACE to bounce  %ds" % ceili(manual_time_left))
	if sun_time_left > 0.0:
		lines.append("SUN - lights out  %ds" % ceili(sun_time_left))
	label.text = "\n".join(lines)
