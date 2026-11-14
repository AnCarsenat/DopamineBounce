class_name TileItem
extends Area3D
## A collectible that sits on a tile. Built from primitives in code; the ball
## picks it up by landing on the tile, which triggers its effect.

enum Type { WHITEHOLE, SUN }

const GROUP := &"tile_items"

var type: Type = Type.WHITEHOLE
var effects: Node

var _visual := Node3D.new()
var _time := 0.0


func _ready() -> void:
	add_to_group(GROUP)

	var shape := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = 0.8
	shape.shape = sphere
	add_child(shape)

	add_child(_visual)
	if type == Type.WHITEHOLE:
		_build_whitehole()
	else:
		_build_sun()

	visible = effects.items_visible
	body_entered.connect(_on_body_entered)


func _process(delta: float) -> void:
	_time += delta
	_visual.position.y = sin(_time * 3.0) * 0.08
	if type == Type.WHITEHOLE:
		_visual.rotate_y(delta * 4.0)
	else:
		_visual.rotate_z(delta * 1.5)
		_visual.scale = Vector3.ONE * (1.0 + sin(_time * 6.0) * 0.06)


func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		effects.activate(type)
		queue_free()


func _build_whitehole() -> void:
	_add_part(_sphere(0.32), Color(1.0, 1.0, 1.0))
	_add_part(_sphere(0.5), Color(0.8, 0.9, 1.0, 0.25))
	var torus := TorusMesh.new()
	torus.inner_radius = 0.48
	torus.outer_radius = 0.62
	var ring := _add_part(torus, Color(0.65, 0.85, 1.0))
	ring.rotation_degrees = Vector3(20.0, 0.0, 15.0)


func _build_sun() -> void:
	_add_part(_sphere(0.36), Color(1.0, 0.8, 0.15))
	_add_part(_sphere(0.52), Color(1.0, 0.45, 0.0, 0.3))
	var ray := BoxMesh.new()
	ray.size = Vector3(0.07, 0.26, 0.07)
	for i in 8:
		var part := _add_part(ray, Color(1.0, 0.7, 0.1))
		part.rotation.z = TAU * i / 8.0
		part.position = Vector3.UP.rotated(Vector3.BACK, part.rotation.z) * 0.72


func _sphere(radius: float) -> SphereMesh:
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	return mesh


func _add_part(mesh: Mesh, color: Color) -> MeshInstance3D:
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = color
	if color.a < 1.0:
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	var part := MeshInstance3D.new()
	part.mesh = mesh
	part.material_override = material
	part.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_visual.add_child(part)
	return part
