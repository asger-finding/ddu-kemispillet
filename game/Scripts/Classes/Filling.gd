extends Sprite2D
class_name Filling

@export_range(0, 5) var filling_frame: int = 0
@export var _physics_active: bool = true
@export var initial_velocity: Vector2 = Vector2.ZERO

# Constants - no need to expose these
const BOUNCE_DAMPING: float = 0.7
const DRAG: float = 800.0
const HOVER_HEIGHT: float = 200.0
const SETTLE_THRESHOLD: float = 30.0
const FLOAT_AMPLITUDE: float = 40.0    # how many pixels to float up/down
const FLOAT_SPEED: float = 2.0         # how fast the floating motion is

@onready var _ray = $Area2D/RayCast2D

# internals
var velocity: Vector2 = Vector2.ZERO
var _settled: bool = false
var _settle_position: float = 0.0
var _float_timer: float = 0.0

func _ready() -> void:
	var path := "res://Assets/Collectibles/filling_%s.png" % filling_frame
	assert(ResourceLoader.exists(path), "Filling texture frame not found: " + path)
	
	texture = load(path)
	
	velocity = initial_velocity
	
	_ray.target_position = Vector2(0, HOVER_HEIGHT + 100.0)
	_ray.enabled = true

func _physics_process(delta: float) -> void:
	if _settled or not _physics_active:
		_handle_floating_motion(delta)
		return
	
	velocity.y += Constants.GRAVITY * delta
	
	var drag_multiplier = 3.0 if _is_near_ground() else 1.0
	velocity.x = move_toward(velocity.x, 0.0, DRAG * drag_multiplier * delta)
	
	global_position += velocity * delta
	
	_check_ground_collision()

func _check_ground_collision() -> void:
	if not _ray or not _ray.is_inside_tree():
		return

	_ray.force_raycast_update()

	if _ray.is_colliding():
		var col_point: Vector2 = _ray.get_collision_point()
		var col_normal: Vector2 = _ray.get_collision_normal()

		if col_normal.y < -0.3:
			var dist_to_ground = col_point.y - global_position.y
			if dist_to_ground <= HOVER_HEIGHT:
				var target_y = col_point.y - HOVER_HEIGHT
				global_position.y = target_y

				if abs(velocity.y) > SETTLE_THRESHOLD:
					velocity.y = -abs(velocity.y) * BOUNCE_DAMPING
					velocity.x *= 0.7
				else:
					velocity = Vector2.ZERO
					_settle_at_position(target_y)

func _settle_at_position(y_pos: float) -> void:
	_settled = true
	_physics_active = false
	_settle_position = y_pos
	_float_timer = 0.0
	velocity = Vector2.ZERO
	
	_ray.enabled = false

func _handle_floating_motion(delta: float) -> void:
	_float_timer += delta
	
	var float_offset = sin(_float_timer * FLOAT_SPEED) * FLOAT_AMPLITUDE
	global_position.y = _settle_position + float_offset

func _is_near_ground() -> bool:
	if not _ray or not _ray.is_inside_tree():
		return false
	_ray.force_raycast_update()
	return _ray.is_colliding()

func _on_area_2d_body_entered(body: Node2D) -> void:
	# TODO: Some pickup action
	queue_free()
