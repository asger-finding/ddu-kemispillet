extends Node

var normal = preload("res://Assets/Cursor/normal.png")
var active = preload("res://Assets/Cursor/active.png")

func _ready():
	_set_all(normal)

func _input(event):
	if event is InputEventMouseButton:
		if event.pressed:
			_set_all(active)
		else:
			_set_all(normal)

func _set_all(tex):
	for shape in [
		Input.CURSOR_ARROW,
		Input.CURSOR_IBEAM,
		Input.CURSOR_POINTING_HAND,
		Input.CURSOR_CROSS,
		Input.CURSOR_WAIT,
		Input.CURSOR_BUSY,
		Input.CURSOR_DRAG,
		Input.CURSOR_HSIZE,
		Input.CURSOR_VSIZE,
		Input.CURSOR_HSPLIT,
		Input.CURSOR_VSPLIT,
		Input.CURSOR_HELP,
		Input.CURSOR_FORBIDDEN,
		Input.CURSOR_MOVE,
	]:
		Input.set_custom_mouse_cursor(tex, shape)
