extends CharacterBody2D
class_name Player

# --- State ---
var health := 0
var jump_count := 0
var is_rolling := false
var is_punching := false
var is_wall_sliding = false
var did_wall_jump := false
var stun_time := 0.0
var slide_dir = 0
var wall_jump_air_control := 1.0
var ground_buffer_time: float = 0.05
var ground_buffer_timer: float = 0.0
var was_grounded_recently: bool = false

# --- Multiplayer state ---
var action_type := 0
var time_since_last_state_emit := 0.0
var last_multiplayer_state: Dictionary

# --- References ---
@onready var _animated_sprite: AnimatedSprite2D = $PlayerSprite
@onready var _standing_collision: CollisionShape2D = $StandingCollision
@onready var _rolling_collision: CollisionShape2D = $RollingCollision
@onready var _punch_hitbox: CollisionShape2D = $PlayerSprite/Punch/PunchHitbox
@onready var _wall_ray_left: RayCast2D = $WallRayLeft
@onready var _wall_ray_right: RayCast2D = $WallRayRight
@onready var _wall_ray_top: RayCast2D = $WallRayTop
var shader_material: ShaderMaterial

# --- Player constants ---
const HEALTH := 5
const MAX_JUMPS := 2
const START_SPEED := 400.0
const TOP_SPEED := 2000.0
const ACCELERATION := 3000.0
const FLOOR_DEACCELERATION := 7000.0 # x component deacceleration when touching floor
const AIR_DEACCELERATION := 1000.0 # x component deacceleration in the air
const DEAD_DEACCELERATION := 3000.0 # x component deacceleration when our player dies
const JUMP_VELOCITY := 2850.0
const ROLL_VELOCITY := 2200.0
const FLASH_FREQUENCY := 5.0
const WALL_SLIDE_SPEED = 200.0
const WALL_JUMP_SPEED = 3000.0
const WALL_JUMP_LOCK_TIME := 0.35

# --- Multiplayer constants ---
const MULTIPLAYER_STATE_UPDATE_FREQUENCY = 0.2 # 200 ms

# --- Lifecycle ---
func _ready() -> void:
	health = HEALTH
	
	_standing_collision.disabled = false
	_rolling_collision.disabled = true
	
	_setup_shader()

func _process(delta: float) -> void:
	move_and_slide()
	
	if not is_alive():
		return
	elif position.y > 0:
		deal_damage(get_health())
		return
	
	# Drop shadow shader
	var direction = -1 if _animated_sprite.flip_h else 1
	var shadow_exp = max(min(velocity.y / 4000.0, 1), 0)
	var shadow_offset = Vector2(shadow_exp * 35.0 * direction, shadow_exp * 80.0)
	shader_material.set_shader_parameter("blur_std", max(shadow_exp * 20.0, 4.0))
	shader_material.set_shader_parameter("shadow_offset", shadow_offset)

	var was_stunned := process_stun(delta)
	if was_stunned:
		_animated_sprite.play("Hurt")
		return
	
	# Handle animation
	_update_ground_buffer(delta)
	_handle_animation()
	_set_action_type()
	_update_multiplayer_state(delta)

func _physics_process(delta: float) -> void:
	_apply_dead_friction(delta)
	_apply_gravity(delta)
	
	if did_wall_jump:
		wall_jump_air_control = clamp(wall_jump_air_control + delta / WALL_JUMP_LOCK_TIME, 0.0, 1.0)
		if wall_jump_air_control >= 1.0:
			did_wall_jump = false
	
	if stun_time > 0.0:
		is_rolling = false
		is_punching = false
		return
	
	if is_punching:
		return
	
	_punch_hitbox.disabled = true
	
	_handle_wall_slide()
	_handle_jump()
	_handle_wall_jump()
	_handle_roll()
	_handle_punch()
	
	if not is_rolling:
		_handle_horizontal_movement(delta)

# --- Internal: Shader ---
func _setup_shader() -> void:
	var shader_code := '''
shader_type canvas_item;
render_mode skip_vertex_transform;

uniform bool shadow_only = false;
uniform vec4 shadow_color : source_color;
uniform float blur_std = 0.4;
uniform vec2 shadow_offset = vec2(0.0);
uniform bool white = false; // Flash effect uniform

// Precomputed constants
const float SQRT_2 = 1.41421356;

varying vec4 modulate;
varying vec2 texture_size;

void vertex() {
	// Get texture size in pixels
	texture_size = 1.0 / TEXTURE_PIXEL_SIZE;
	
	// Compute padding for blur and offset
	float blur_radius = ceil(blur_std * 3.0);
	vec2 max_offset = abs(shadow_offset);
	vec2 padding = vec2(blur_radius) + max_offset;
	
	// Center and scale vertex to expand geometry
	vec2 center = texture_size * 0.5;
	vec2 factor = (texture_size + 2.0 * padding * TEXTURE_PIXEL_SIZE) / texture_size;
	
	VERTEX = VERTEX - center;
	VERTEX *= factor;
	VERTEX += center;
	VERTEX = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
	
	// Adjust UV to match expanded geometry
	UV = (UV - 0.5) * factor + 0.5;
	
	modulate = COLOR;
}

// Fast approximation of error function
float fast_erf(float x) {
	float x2 = x * x;
	return sign(x) * (1.0 - exp(-x2 * (1.27324 + 0.14001 * x2) / (1.0 + 0.14001 * x2 + 0.01008 * x2 * x2)));
}

// Optimized gaussian CDF difference
float gaussian_cdf_diff(float x1, float x2) {
	float inv_sqrt2_std = 1.0 / (SQRT_2 * blur_std);
	return 0.5 * (fast_erf(x2 * inv_sqrt2_std) - fast_erf(x1 * inv_sqrt2_std));
}

void fragment() {
	// Sample texture with bounds checking
	vec4 c = vec4(0.0);
	if (UV.x >= 0.0 && UV.x <= 1.0 && UV.y >= 0.0 && UV.y <= 1.0) {
		c = texture(TEXTURE, UV);
	}
	
	// Apply flash effect
	vec4 sprite_color = white ? vec4(1.0, 1.0, 1.0, c.a) : c;
	
	// Early exit if completely transparent and no shadow needed
	if (blur_std < 0.1 && c.a <= 0.001) {
		discard;
	}
	
	// Compute shadow
	float weight = 0.0;
	if (blur_std >= 0.1) {
		float blur_radius = ceil(blur_std * 3.0);
		vec2 coord = fract(UV / TEXTURE_PIXEL_SIZE);
		float step_size = max(1.0, blur_radius / 8.0); // Adaptive step size
		
		for (float x = -blur_radius; x <= blur_radius; x += step_size) {
			for (float y = -blur_radius; y <= blur_radius; y += step_size) {
				vec2 offset = vec2(x, y) * TEXTURE_PIXEL_SIZE;
				vec2 sample_uv = UV - shadow_offset * TEXTURE_PIXEL_SIZE + offset;
				
				// Sample only within valid UV bounds
				if (sample_uv.x >= 0.0 && sample_uv.x <= 1.0 && sample_uv.y >= 0.0 && sample_uv.y <= 1.0) {
					float sample_alpha = texture(TEXTURE, sample_uv).a;
					if (sample_alpha > 0.01) {
						float weight_x = gaussian_cdf_diff(-coord.x + x, -coord.x + x + step_size);
						float weight_y = gaussian_cdf_diff(-coord.y + y, -coord.y + y + step_size);
						weight += weight_x * weight_y * sample_alpha;
					}
				}
			}
		}
	}
	
	// Composite shadow and sprite
	float e = shadow_only ? 0.0 : 1.0;
	vec4 shadow = vec4(shadow_color.rgb, weight * shadow_color.a);
	COLOR = c.a * e * sprite_color + (1.0 - c.a * e) * shadow;
	COLOR *= modulate;
	
	if (COLOR.a < 0.001) {
		discard;
	}
}
	'''
	var shader := Shader.new()
	shader.code = shader_code
	shader_material = ShaderMaterial.new()
	shader_material.shader = shader
	shader_material.set_shader_parameter("shadow_color", Color(0.0, 0.0, 0.0, 0.3))
	shader_material.set_shader_parameter("blur_std", 1.0)
	shader_material.set_shader_parameter("shadow_offset", Vector2(0.0, 0.0))
	shader_material.set_shader_parameter("white", false)
	_animated_sprite.material = shader_material

# --- Internal: Animation ---
func _update_ground_buffer(delta: float) -> void:
	if is_on_floor():
		ground_buffer_timer = ground_buffer_time
		was_grounded_recently = true
	else:
		ground_buffer_timer -= delta
		if ground_buffer_timer <= 0.0:
			was_grounded_recently = false

func _handle_animation() -> void:
	_animated_sprite.speed_scale = 1
	
	if is_rolling:
		return
	if is_punching:
		return
	if stun_time > 0.0:
		return
	
	if Input.is_action_just_pressed("Down"):
		_start_roll()
		return
	else:
		_stop_roll()
	
	if Input.is_action_pressed("Right"):
		_animated_sprite.speed_scale *= 1.6 + abs(velocity.x) / TOP_SPEED
		_animated_sprite.flip_h = false
		if was_grounded_recently:
			_animated_sprite.play("Run")
			return
	
	if Input.is_action_pressed("Left"):
		_animated_sprite.speed_scale *= 1.6 + abs(velocity.x) / TOP_SPEED
		_animated_sprite.flip_h = true
		# if you read this, Eliot has infiltrated your code >:(
		# wtf
		if was_grounded_recently:
			_animated_sprite.play("Run")
			return
	
	_animated_sprite.stop()
	
	if is_wall_sliding:
		_animated_sprite.play("Wallslide")
		return
	
	if was_grounded_recently:
		_animated_sprite.play("Idle")
	else:
		if velocity.y <= 0: _animated_sprite.play("Jump")
		else: _animated_sprite.play("Fall")

# --- Internal: Movement ---
func _apply_dead_friction(delta: float) -> void:
	if not is_alive():
		velocity.x = move_toward(velocity.x, 0, DEAD_DEACCELERATION * delta)

func _apply_gravity(delta: float) -> void:
	if not is_on_floor():
		if jump_count <= 1:
			jump_count = 1
		velocity.y += Constants.GRAVITY * delta
	else:
		jump_count = 0

func _handle_wall_slide():
	var wall_dir = is_touching_wall()
	var input_dir = Input.get_axis("Left", "Right")

	if wall_dir != 0 and not is_on_floor() and velocity.y > 0:
		# require pressing towards the wall
		if sign(input_dir) == wall_dir:
			is_wall_sliding = true
			velocity.y = WALL_SLIDE_SPEED
			slide_dir = wall_dir
		else:
			is_wall_sliding = false
	else:
		is_wall_sliding = false

func _handle_wall_jump():
	if is_wall_sliding and (Input.is_action_just_pressed("Up") or Input.is_action_just_pressed("ui_accept")):
		var angle = PI * 60.0 / 180.0
		velocity.x = -slide_dir * (WALL_JUMP_SPEED * cos(angle))
		velocity.y = - (WALL_JUMP_SPEED * sin(angle))
		is_wall_sliding = false
		did_wall_jump = true
		wall_jump_air_control = 0.0

func is_touching_wall() -> int:
	if _wall_ray_left.is_colliding():
		return -1 # wall on left
	if _wall_ray_right.is_colliding():
		return 1 # wall on right
	return 0

func _handle_jump() -> void:
	if Input.is_action_just_pressed("Up") or Input.is_action_just_pressed("ui_accept"):
		if is_wall_sliding:
			return
		if jump_count < MAX_JUMPS:
			if is_rolling and _wall_ray_top.is_colliding():
				return
			velocity.y = -JUMP_VELOCITY
			jump_count += 1
			is_rolling = false

func _handle_roll() -> void:
	if is_rolling:
		velocity.x = (-1 if _animated_sprite.flip_h else 1) * ROLL_VELOCITY

func _start_roll() -> void:
	is_rolling = true
	
	_standing_collision.disabled = true
	_rolling_collision.disabled = false
	
	_animated_sprite.play("Roll")
	
func _stop_roll() -> void:
	is_rolling = false
	
	_standing_collision.disabled = false
	_rolling_collision.disabled = true

func _handle_horizontal_movement(delta: float) -> void:
	var direction := Input.get_axis("Left", "Right")

	if did_wall_jump and wall_jump_air_control == 0.0: 
		return

	if direction != 0:
		var target_x = direction * TOP_SPEED
		
		# When wall_jump_air_control is 1.0 (full control), we use snap behavior
		if wall_jump_air_control >= 1.0:
			if direction * velocity.x <= 0:
				velocity.x = direction * START_SPEED
			else:
				var ratio: float = abs(velocity.x) / TOP_SPEED
				var diff := ratio - 0.5
				var sigma := 0.36
				var peak_accel := 2000.0
				var dynamic_accel := peak_accel * exp(-(diff * diff) / (2.0 * sigma * sigma))
				velocity.x = move_toward(
					velocity.x,
					target_x,
					dynamic_accel * delta
				)
		else:
			# Always ease for wall jump transitions
			var ratio: float = abs(velocity.x) / TOP_SPEED
			var diff := ratio - 0.5
			var sigma := 0.36
			var peak_accel := 2000.0
			var dynamic_accel := peak_accel * exp(-(diff * diff) / (2.0 * sigma * sigma))

			velocity.x = move_toward(
				velocity.x,
				target_x,
				dynamic_accel * delta * wall_jump_air_control
			)
	else:
		var deaccel: float = FLOOR_DEACCELERATION if is_on_floor() else AIR_DEACCELERATION
		if wall_jump_air_control >= 1.0:
			velocity.x = move_toward(velocity.x, 0, deaccel * delta)
		else:
			velocity.x = move_toward(velocity.x, 0, deaccel * delta * wall_jump_air_control)

func _handle_punch():
	if Input.is_action_just_pressed("Punch"):
		# Don't exit roll if we are under a low ceiling
		if is_rolling and _wall_ray_top.is_colliding():
			return
			
		# We can still get pushed into a ceiling by our earnt velocity from the roll
		if is_rolling and (_wall_ray_right.is_colliding() or _wall_ray_left.is_colliding()):
			velocity.x = false
		
		is_rolling = false
		is_punching = true
		_animated_sprite.play("Punch")
		
		var direction = -1 if _animated_sprite.flip_h else 1
		_punch_hitbox.position.x += 400 * direction
		_punch_hitbox.disabled = false
		
		await get_tree().create_timer(0.1).timeout
		_punch_hitbox.disabled = true
		_punch_hitbox.position.x -= 400 * direction

# --- Internal: State ---
func kill() -> void:
	_animated_sprite.play("Death")
	
# --- Internal: Multiplayer state ---
func _set_action_type() -> void:
	match _animated_sprite.animation:
		["Run", "Idle", "Jump", "Fall"]:
			action_type = 0
		"Hurt":
			action_type = 1
		"Punch":
			action_type = 2
		"Roll":
			action_type = 3
		"Wallslide":
			action_type = 4
		_:
			action_type = 0

func _update_multiplayer_state(delta: float) -> void:
	var multiplayer_state = {
		"position": { "x": position.x, "y": position.y },
		"velocity": { "x": velocity.x, "y": velocity.y },
		"action_type": action_type,
		"health": health
	}
	time_since_last_state_emit += delta
	if time_since_last_state_emit >= MULTIPLAYER_STATE_UPDATE_FREQUENCY and last_multiplayer_state != multiplayer_state:
		GameManager.emit_player_state(multiplayer_state)
		time_since_last_state_emit = 0
		last_multiplayer_state = multiplayer_state

# --- Callbacks ---
func _on_animated_sprite_2d_animation_finished() -> void:
	match _animated_sprite.animation:
		"Roll":
			# Continue to roll if we are below a roof
			if is_rolling and _wall_ray_top and _wall_ray_top.is_colliding():
				_animated_sprite.play("Roll")
			else:
				_stop_roll()
		"Punch":
			is_punching = false
			_punch_hitbox.disabled = true
			_animated_sprite.play("Idle")

# --- Public API: Stun ---
func stun(time: float) -> bool:
	if stun_time > 0:
		return true
	stun_time = time
	return false

func process_stun(delta: float) -> bool:
	stun_time = max(0, stun_time - delta)
	var is_stunned := stun_time > 0
	
	if is_stunned:
		is_rolling = false
		var white := (int(floor(stun_time * FLASH_FREQUENCY)) % 2 == 0) if stun_time >= delta else false
		_animated_sprite.material.set_shader_parameter("white", white)
	return is_stunned

# --- Public API: Knockback ---
func knockback_player(direction: Vector2, launch_force: float, ignore_current_velocity = true) -> void:
	var new_velocity = direction * launch_force
	
	if ignore_current_velocity:
		velocity = new_velocity
	else:
		velocity += new_velocity

# --- Public API: Health ---
func get_health() -> int:
	return health

func set_health(new_health: int) -> int:
	assert(new_health >= 0, "Health cannot be set to less than 0")
	health = new_health
	return health

func heal(amount := 1) -> int:
	return _change_health(amount)

func deal_damage(amount := 1) -> int:
	return _change_health(-amount)

func _change_health(delta: int) -> int:
	health = max(0, health + delta)
	if not is_alive(): kill()
	return health

func is_alive() -> bool:
	return health > 0
