extends Node3D

@onready var clickArea = $MainBall/Area3D
@onready var mainSphere = $MainBall

@onready var sceneCamera = $Camera3D
@onready var cameraShake = $Camera3D/CameraShake

var mouseIsInside = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

# Parameters
const mainSphere_ScaleIn = Vector3(2,2,2)
const mainSphere_ScaleOut = Vector3(1,1,1)
const mainSphere_ScaleSpeed = 12.0 # higher = snappier
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:

	var target := mainSphere_ScaleIn if mouseIsInside else mainSphere_ScaleOut
	mainSphere.scale = mainSphere.scale.lerp(target, 1.0 - exp(-mainSphere_ScaleSpeed * _delta))


func _on_area_3d_mouse_entered() -> void:
	mouseIsInside = true

func _on_area_3d_mouse_exited() -> void:
	mouseIsInside = false

func _on_area_3d_input_event(_camera: Node, event: InputEvent, _event_position: Vector3, _normal: Vector3, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_on_clicked()
		
func _on_clicked() -> void:
	print("clicked")
	shake_camera(0.0, 0.2, 0.3, 0.6)
	
func shake_camera( easein:float,easout:float, duration:float, shake_amnt:float) -> void:
	cameraShake.shake(shake_amnt, duration, 20.0, Vector2.ZERO, easein, easout)
