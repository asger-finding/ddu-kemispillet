extends CharacterBody2D
class_name MultiplayerPlayer

# --- State (received from network) ---
var health := 5
var action_type := 0
var target_position := Vector2.ZERO
var target_velocity := Vector2.ZERO

# --- References ---
@onready var _animated_sprite: AnimatedSprite2D = $PlayerSprite
@onready var _standing_collision: CollisionShape2D = $StandingCollision

# --- Network interpolation ---
var position_smoothing := 0.15  # Lower = smoother but more lag
var last_update_time := 0.0

# --- Lifecycle ---
func _ready() -> void:
	_standing_collision.disabled = false
	target_position = position

func _process(_delta: float) -> void:
	_handle_animation()

func _physics_process(_delta: float) -> void:
	# Interpolate position smoothly
	position = position.lerp(target_position, position_smoothing)
	
	# Apply velocity for physics interactions
	velocity = target_velocity
	move_and_slide()

# --- Animation ---
func _handle_animation() -> void:
	match action_type:
		0:
			_animated_sprite.speed_scale = 1.0
			
			# Handle movement animations
			var moving_horizontally: bool = abs(velocity.x) > 10.0
			var on_ground: bool = abs(velocity.y) < 10.0
			
			if moving_horizontally and on_ground:
				_animated_sprite.speed_scale = 1.6 + abs(velocity.x) / 2000.0
				_animated_sprite.play("Run")
			elif on_ground:
				_animated_sprite.play("Idle")
			else:
				if velocity.y <= 0:
					_animated_sprite.play("Jump")
				else:
					_animated_sprite.play("Fall")
		1:
			# hurt
			_animated_sprite.play("Fall")
		2:
			_animated_sprite.play("Punch")
		3:
			_animated_sprite.play("Roll")
		4:
			_animated_sprite.play("Wallslide")
		_:
			pass

# --- Network Update ---
func update_from_network(data: Dictionary) -> void:
	last_update_time = Time.get_ticks_msec() / 1000.0
	
	# Update target position (smoothly interpolated in _physics_process)
	if data.has("position"):
		target_position = Vector2(data.position.x, data.position.y)
	
	# Update velocity
	if data.has("velocity"):
		target_velocity = Vector2(data.velocity.x, data.velocity.y)
	
	# Update sprite flip
	if data.has("flipped"):
		_animated_sprite.flip_h = data.flipped
	
	# Update health
	if data.has("health"):
		var new_health = int(data.health)
		if new_health <= 0 and health > 0:
			kill()
		health = new_health
	
	# Update rotation (if needed)
	if data.has("rotation"):
		rotation = data.rotation

# --- Death ---
func kill() -> void:
	_animated_sprite.play("Death")

# --- Public API ---
func get_health() -> int:
	return health

func is_alive() -> bool:
	return health > 0
