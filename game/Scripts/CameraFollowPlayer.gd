extends Camera2D
# --- State ---
var effective_velocity := 0.0
var is_game_active := false
# --- Constants ---
const FOLLOW_X_INTERPOLATION_SPEED = 8.5 # lerp weight
const FOLLOW_Y_INTERPOLATION_SPEED = 12.0 # lerp weight
const CAMERA_Y_FLOOR = 0 # px
const CAMERA_ZOOM_CLOSEST = 0.4 # coeff of furthest we are zoomed in
const CAMERA_ZOOM_FURTHEST = 0.1 # coeff of furthest we can zoom out
const CAMERA_ZOOM_PLAYER_SPEED_COEFF = 0.0001 # how fast should we zoom out according to player speed

func _ready() -> void:
	# Initialize with closest zoom
	zoom = Vector2.ONE * CAMERA_ZOOM_CLOSEST

func _process(delta: float) -> void:
	if (not GameManager.player_exists or not GameManager.player.is_alive()):
		# Player is not spawned or dead. Intentionally do nothing.
		return
	
	# Check if game is actually playing
	var player_is_active = GameManager.player.is_processing()
	
	# Decay smoothing
	var x_decay = exp(-FOLLOW_X_INTERPOLATION_SPEED * delta)
	var y_decay = exp(-FOLLOW_Y_INTERPOLATION_SPEED * delta)
	
	position.x = lerp(GameManager.player.position.x, position.x, x_decay)
	position.y = min(
		lerp(GameManager.player.position.y, position.y, y_decay),
		CAMERA_Y_FLOOR
	)
	
	# Only update zoom if player is active
	if player_is_active:
		# Smooth velocity tracking
		var target_velocity: float = GameManager.player.velocity.length()
		var smoothing := 5.0
		var velocity_weight = clamp(smoothing * delta, 0.0, 1.0)
		effective_velocity = lerp(effective_velocity, target_velocity, velocity_weight)
		
		# Stabilize zoom factor
		var speed_over: float = max(effective_velocity - 500.0, 0.0)
		var zoom_factor: float = clamp(-exp(speed_over * CAMERA_ZOOM_PLAYER_SPEED_COEFF) + 2.0, 0.0, 1.0)
		
		var target_zoom: float = lerp(CAMERA_ZOOM_FURTHEST, CAMERA_ZOOM_CLOSEST, zoom_factor)
		zoom = Vector2.ONE * target_zoom
	else:
		# When game is paused/countdown, maintain current zoom or reset to closest
		zoom = Vector2.ONE * CAMERA_ZOOM_CLOSEST
		effective_velocity = 0.0
