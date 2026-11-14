class_name InfohudControl
extends Node

@onready var subviewport:SubViewport = self.get_parent()
@onready var control:Control = subviewport.find_child("Control")
@onready var feed:RichTextLabel = control.find_child("Feed")
@onready var info:RichTextLabel = control.find_child("Info")

@export var maxLineCount = 10

@export var lineLife = 3000 # ms

var lines = []

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	_clear_old_lines()
	


func _clear_old_lines()->void:
	var current = Time.get_ticks_msec()
	var keep = []
	for line in lines:
		if line[1] > current:
			keep.append(line)
	if keep.size() != lines.size():
		lines = keep
		_render_feed()
			

class RTLColors:
	const RED     := "#FF0000"
	const GREEN   := "#00FF00"
	const BLUE    := "#0000FF"
	const YELLOW  := "#FFFF00"
	const CYAN    := "#00FFFF"
	const MAGENTA := "#FF00FF"
	const ORANGE  := "#FFA500"
	const PURPLE  := "#800080"
	const WHITE   := "#FFFFFF"
	const BLACK   := "#000000"
	const GRAY    := "#808080"

static func wrap(text: String, color: String) -> String:
	return "[color=%s]%s[/color]" % [color, text]

func set_info(infotext:String)->void:
	info.text = infotext

func addline(line:String)->void:
	if lines.size() >= maxLineCount:
		lines.remove_at(0)
	lines.append([line, Time.get_ticks_msec() + lineLife])
	_render_feed()

func _render_feed()->void:
	feed.clear()
	for i in lines.size():
		if i > 0:
			feed.newline()
		feed.append_text(lines[i][0])
