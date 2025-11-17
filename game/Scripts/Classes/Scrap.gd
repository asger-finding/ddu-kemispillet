extends Sprite2D
class_name Scrap

const FLOAT_AMPLITUDE: float = 40.0    # how many pixels to float up/down
const FLOAT_SPEED: float = 2.0         # how fast the floating motion is

var _float_timer: float = 0.0
var _base_position: float

func _ready() -> void:
	_base_position = global_position.y
	rotation = randf_range(-0.7, 0.7)

func _process(delta: float) -> void:
	_handle_floating_motion(delta)

func _handle_floating_motion(delta: float) -> void:
	_float_timer += delta
	var float_offset = sin(_float_timer * FLOAT_SPEED) * FLOAT_AMPLITUDE
	global_position.y = _base_position + float_offset

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body is Player:
		# TODO: Some pickup action
		queue_free()
