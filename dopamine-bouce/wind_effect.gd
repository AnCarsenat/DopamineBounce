extends ColorRect
## Full-screen speed lines whose strength follows the ball's speed multiplier.

## How quickly the effect catches up with speed changes.
@export var smoothing: float = 2.0

@onready var player = $"../../PlayerBody"

var _intensity: float = 0.0


func _process(delta: float) -> void:
	var target := inverse_lerp(1.0, player.max_speed_multiplier, player.speed_multiplier)
	if player.max_speed_multiplier <= 1.0:
		target = 0.0
	_intensity = lerpf(_intensity, clampf(target, 0.0, 1.0), clampf(smoothing * delta, 0.0, 1.0))
	visible = _intensity > 0.005
	(material as ShaderMaterial).set_shader_parameter("intensity", _intensity)
