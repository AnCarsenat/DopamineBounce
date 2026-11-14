class_name CameraShake
extends Node
## Add as a child of a Camera2D or Camera3D, then call shake().
## Shakes stack (summed, capped by max_force) and fade out over their duration.
## Applies offsets additively, so other code moving the camera keeps working.
##
##   $Camera2D/CameraShake.shake(0.6, 0.25)                 # small hit
##   $Camera2D/CameraShake.shake(1.0, 0.6, 30.0)            # big, buzzy explosion
##   $Camera2D/CameraShake.shake(0.8, 0.2, 20.0, Vector2.RIGHT)  # directional kick
##   CameraShake.shake_all(get_tree(), 1.0, 0.5)            # every camera (split screen)

const GROUP := &"camera_shake"

## Max displacement at force 1.0. Pixels for Camera2D.
@export var max_offset_2d := Vector2(24, 18)
## Max displacement at force 1.0. Meters for Camera3D.
@export var max_offset_3d := Vector2(0.25, 0.2)
## Max roll at force 1.0, in degrees. For Camera2D, needs ignore_rotation = false.
@export var max_roll_degrees := 3.0
## Cap on total force when several shakes overlap.
@export var max_force := 1.5
## Falloff curve: 1 = linear, 2 = quadratic (snappy), 0.5 = lingers.
@export var decay_exponent := 2.0
## Global multiplier, e.g. hook to an accessibility "screen shake" slider (0 disables).
@export_range(0.0, 2.0) var intensity_scale := 1.0

var _camera: Node
var _noise := FastNoiseLite.new()
var _shakes: Array[Dictionary] = []
var _applied_offset := Vector2.ZERO
var _applied_roll := 0.0
var _seed_counter := 0.0


func _ready() -> void:
	_camera = get_parent()
	assert(_camera is Camera3D, "CameraShake must be a child of Camera3D")
	add_to_group(GROUP)
	_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	_noise.fractal_type = FastNoiseLite.FRACTAL_NONE
	_noise.frequency = 1.0


## force: 0..1 typical (above 1 allowed). duration: seconds. frequency: wobbles per second.
## direction: non-zero restricts the shake to that axis (recoil, impacts).
## ease_in: seconds to ramp up to full force (0 = instant hit).
## ease_out: seconds of fade at the end; negative = fade across the whole duration.
func shake(force := 0.5, duration := 0.3, frequency := 20.0, direction := Vector2.ZERO, ease_in := 0.0, ease_out := -1.0) -> void:
	if force <= 0.0 or duration <= 0.0:
		return
	_seed_counter += 37.0  # independent noise track per shake
	_shakes.append({
		"force": force,
		"duration": duration,
		"frequency": frequency,
		"direction": direction.normalized(),
		"ease_in": ease_in,
		"ease_out": ease_out,
		"time": 0.0,
		"seed": _seed_counter,
		"phase": randf() * 1000.0,  # random start so first frames are not always weak
	})


## Shakes every CameraShake in the tree (both halves of a split screen, etc.).
static func shake_all(tree: SceneTree, force := 0.5, duration := 0.3, frequency := 20.0, direction := Vector2.ZERO, ease_in := 0.0, ease_out := -1.0) -> void:
	for node in tree.get_nodes_in_group(GROUP):
		node.shake(force, duration, frequency, direction, ease_in, ease_out)


## Cancels all shakes and puts the camera back.
func stop() -> void:
	_shakes.clear()
	_apply(Vector2.ZERO, 0.0)


func is_shaking() -> bool:
	return not _shakes.is_empty()


func _process(delta: float) -> void:
	if _shakes.is_empty() and _applied_offset == Vector2.ZERO and _applied_roll == 0.0:
		return

	var offset := Vector2.ZERO
	var roll := 0.0
	var total_amp := 0.0

	for i in range(_shakes.size() - 1, -1, -1):
		var s := _shakes[i]
		s.time += delta
		var t: float = s.time / s.duration
		if t >= 1.0:
			_shakes.remove_at(i)
			continue
		var amp: float = s.force * _envelope(s, t)
		var x: float = s.phase + s.time * s.frequency
		var n := Vector2(_noise.get_noise_2d(s.seed, x), _noise.get_noise_2d(s.seed + 100.0, x))
		var dir: Vector2 = s.direction
		if dir != Vector2.ZERO:
			n = dir * n.x
		offset += n * amp
		roll += _noise.get_noise_2d(s.seed + 200.0, x) * amp
		total_amp += amp

	if total_amp > max_force:
		var k := max_force / total_amp
		offset *= k
		roll *= k

	offset *= intensity_scale
	roll *= intensity_scale
	var max_offset := max_offset_2d if _camera is Camera2D else max_offset_3d
	_apply(offset * max_offset, deg_to_rad(roll * max_roll_degrees))


## 0..1 strength over a shake's life: smooth ramp-up, then decay curve.
func _envelope(s: Dictionary, t: float) -> float:
	var rise := 1.0
	if s.ease_in > 0.0:
		rise = smoothstep(0.0, s.ease_in, s.time)
	var fall: float
	if s.ease_out < 0.0:
		fall = pow(1.0 - t, decay_exponent)
	elif s.ease_out == 0.0:
		fall = 1.0
	else:
		fall = pow(clampf((s.duration - s.time) / s.ease_out, 0.0, 1.0), decay_exponent)
	return rise * fall


func _apply(new_offset: Vector2, new_roll: float) -> void:
	var d_offset := new_offset - _applied_offset
	var d_roll := new_roll - _applied_roll
	if _camera is Camera2D:
		_camera.offset += d_offset
		_camera.rotation += d_roll
	elif _camera is Camera3D:
		_camera.h_offset += d_offset.x
		_camera.v_offset += d_offset.y
		_camera.rotation.z += d_roll
	_applied_offset = new_offset
	_applied_roll = new_roll


func _exit_tree() -> void:
	stop()
