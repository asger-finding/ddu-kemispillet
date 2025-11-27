extends CharacterBody2D
class_name MultiplayerPlayer

# --- State (received from network) ---
var username: String = ""
var player_id: String
var player_skin: String = "Male_1"
var health := 5
var action_type := 0
var network_velocity := Vector2.ZERO

# --- References ---
@onready var _animated_sprite: AnimatedSprite2D = $PlayerSprite
@onready var _standing_collision: CollisionShape2D = $StandingCollision
@onready var _username_label: Label = $Username

# --- Entity Interpolation (https://www.gabrielgambetta.com/entity-interpolation.html) ---
var position_buffer := []  # { position: Vector2, timestamp: float }[]
const RENDER_DELAY := 0.2  # Render 2 state updates behund

# --- Lifecycle ---
func _ready() -> void:
	_standing_collision.disabled = false
	_username_label.text = username

func _process(_delta: float) -> void:
	_handle_animation()

func _physics_process(_delta: float) -> void:
	if position_buffer.size() < 2:
		return
	
	var now = Time.get_ticks_msec() / 1000.0
	var render_timestamp = now - RENDER_DELAY
	
	var from_idx = -1
	var to_idx = -1
	
	for i in range(position_buffer.size() - 1):
		if position_buffer[i].timestamp <= render_timestamp and position_buffer[i + 1].timestamp >= render_timestamp:
			from_idx = i
			to_idx = i + 1
			break
	
	if from_idx != -1 and to_idx != -1:
		var from = position_buffer[from_idx]
		var to = position_buffer[to_idx]
		
		var total_time = to.timestamp - from.timestamp
		var elapsed_time = render_timestamp - from.timestamp
		
		var t = clampf(elapsed_time / total_time, 0.0, 1.0) if total_time > 0 else 0.0
		
		position = from.position.lerp(to.position, t)
		velocity = (to.position - from.position) / total_time if total_time > 0 else Vector2.ZERO
	else:
		# Fallback if render_timestamp is beyond the buffer,
		# then we hold at the last known position
		if position_buffer.size() > 0:
			position = position_buffer[-1].position
			velocity = network_velocity
	
	# Cleanup
	while position_buffer.size() > 2 and position_buffer[1].timestamp < render_timestamp:
		position_buffer.pop_front()
	
	move_and_slide()

# --- Animation ---
func _handle_animation() -> void:
	if network_velocity.x != 0: _animated_sprite.flip_h = network_velocity.x < 0
	_username_label.pivot_offset.x = 9 if _animated_sprite.flip_h else 0
	
	match action_type:
		0:
			_animated_sprite.speed_scale = 1.0
			
			var moving_horizontally: bool = abs(velocity.x) > 10.0
			var on_ground: bool = abs(velocity.y) < 10.0
			
			if moving_horizontally and on_ground:
				_animated_sprite.speed_scale = 1.6 + abs(velocity.x) / 2000.0
				_animated_sprite.play(player_skin + "_Run")
			elif on_ground:
				_animated_sprite.play(player_skin + "_Idle")
			else:
				if velocity.y <= 0:
					_animated_sprite.play(player_skin + "_Jump")
				else:
					_animated_sprite.play(player_skin + "_Fall")
		1:
			_animated_sprite.play(player_skin + "_Roll")
		2:
			_animated_sprite.play(player_skin + "_Wallslide")
		_:
			pass

# --- Network ---
func set_username(_username: String) -> void:
	username = _username

func set_player_id(_player_id: String) -> void:
	player_id = _player_id

func set_player_skin(_player_skin: String) -> void:
	player_skin = _player_skin

func update_state(data: Dictionary) -> void:
	if data.has("position"):
		var new_position = Vector2(data.position.x, data.position.y)
		var timestamp = Time.get_ticks_msec() / 1000.0
		
		position_buffer.append({
			"position": new_position,
			"timestamp": timestamp
		})
		
		while position_buffer.size() > 10:
			position_buffer.pop_front()
		
		# Snap first position immediately
		if position_buffer.size() == 1:
			position = new_position
	
	if data.has("velocity"):
		network_velocity = Vector2(data.velocity.x, data.velocity.y)
	
	if data.has("health"):
		var new_health = int(data.health)
		if new_health <= 0 and health > 0:
			kill()
		health = new_health
	
	if data.has("action_type"):
		action_type = data.action_type

# --- Death ---
func kill() -> void:
	_animated_sprite.play("Death")

# --- Public API ---
func get_health() -> int:
	return health

func is_alive() -> bool:
	return health > 0
