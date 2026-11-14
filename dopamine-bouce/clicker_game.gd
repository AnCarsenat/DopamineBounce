extends Node3D

# === NODES
@onready var clickArea = $MainBall/Area3D
@onready var mainSphere = $MainBall
@onready var sceneCamera = $Camera3D
@onready var cameraShake = $Camera3D/CameraShake
@onready var infohudControl = $"Info hud/SubViewport/InfohudControl"

@onready var cpsTimer = $"CalculateTps"

# work vars (make things work)
var mouseIsInside = false

# vars (game logic)
var totalClicks = 0
var cpsClicks = 0.0
var cps = 0.0


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	cpsTimer.timeout.connect(_calculate_cps)

# === PARAMS 
# Parameters for screenshake
const mainSphere_Scale_amnt = 1.25
const mainSphere_ScaleIn = Vector3(mainSphere_Scale_amnt,mainSphere_Scale_amnt,mainSphere_Scale_amnt)
const mainSphere_ScaleOut = Vector3(1,1,1)
const mainSphere_ScaleSpeed = 12.0 # higher = snappier


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	
	# Grow sphere when clicked
	var target = 1.0
	if mouseIsInside:
		target = mainSphere_Scale_amnt
	target += (cps/10)*1.125
	
	target = Vector3(target,target,target)

	mainSphere.scale = mainSphere.scale.lerp(target, 1.0 - exp(-mainSphere_ScaleSpeed * _delta))
	
	# Cps is calculated outside
	#print(cps)
	#print(totalClicks)

	# Display cps
	update_info_hud()


class CPSGraph:
	# Colors (generated with claude)
	static var colors = {
		"L":     "#6E6E6E",  # dull gray
		"D":     "#0094FF",  # Destructive - blue
		"C":     "#4CFF00",  # Chaotic - green
		"B":     "#FFD800",  # Brutal - yellow
		"A":     "#FF6A00",  # Anarchic - orange
		"A+":    "#FF8C26",  # brighter orange
		"ULTRA": "#FFC800",  # ULTRAKILL gold
		"S":     "#FF0000",  # Supreme - red
		"S+":    "#FF2A2A",
		"SS":    "#FF0000",  # SSadistic - red
		"SS+":   "#FF2A2A",
	}
	
	static var messages = {0:"L",2:"D",3:"C",4:"B",5:"A",6:"A+",7:"ULTRA",8:"S",9:"S+",10:"SS",11:"SS+",12:"GODLY"}
	
	
	static func get_rank(cps: int) -> String:
		var best := 0
		for k in CPSGraph.messages:
			if cps >= k and k > best:
				best = k
		var rank: String = messages[best]
		if rank == "GODLY":
			return "[rainbow freq=0.5 sat=0.9 val=1.0][wave amp=30 freq=6]GODLY[/wave][/rainbow]"
		return "[color=%s]%s[/color]" % [colors[rank], rank]
		
# == LOGIC FUNCS HERE
func _on_clicked() -> void:
	print("clicked")
	totalClicks += 1 
	cpsClicks += 1 
	shake_camera(0.0, 0.2, 0.3, 0.6)
	




# === HELPER FUNCS HERE
func shake_camera( easein:float,easout:float, duration:float, shake_amnt:float) -> void:
	cameraShake.shake(shake_amnt, duration, 20.0, Vector2.ZERO, easein, easout)

func update_info_hud()->void:
	var infotext = "[font_size=32]CPS:[/font_size]{0}[font_size=32]C:[/font_size]{1}".format([cps,totalClicks])
	infohudControl.set_info(infotext)

func add_status_info_hud()->void:
	var level = CPSGraph.get_rank(cps)
	infohudControl.addline(level)
	
	
func _calculate_cps() -> void:
	cps = cpsClicks / cpsTimer.wait_time
	cpsClicks = 0
	add_status_info_hud()
	
# === SIGNALS HERE
func _on_area_3d_mouse_entered() -> void:
	mouseIsInside = true

func _on_area_3d_mouse_exited() -> void:
	mouseIsInside = false

func _on_area_3d_input_event(_camera: Node, event: InputEvent, _event_position: Vector3, _normal: Vector3, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_on_clicked()
		
