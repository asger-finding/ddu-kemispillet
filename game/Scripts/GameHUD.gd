extends CanvasLayer

@onready var hearts_container: HBoxContainer = $HealthContainer
@onready var _countdown_label: Label = $CountdownLabel
@onready var _time_until_next_question: TextureProgressBar = $TimeUntilNextQuestion
@onready var _color_overlay: ColorRect = $ColorOverlay
@onready var mat: ShaderMaterial = _color_overlay.material

var last_health := -1
var backdrop_multiplier := 2.0
var text_multiplier := 2.0
var vignette_strength: float = 0.0
var vignette_radius: float = 1.0
var camera_zoom := Vector2(0.3, 0.3)
var text_opacity := 1.0

func _ready() -> void:
	GameManager._new_question.connect(_on_new_question)
	GameManager._question_answered_correct.connect(_on_question_success)
	GameManager._question_answered_wrong.connect(_on_question_fail)
	GameManager._question_quit.connect(_on_question_fail)

func _on_new_question(_question: Dictionary) -> void:
	mat.set_shader_parameter("vignette_color", Vector3(0.0, 0.0, 0.0))

func _on_question_success(_popup: Control) -> void:
	mat.set_shader_parameter("vignette_color", Vector3(0.0, 0.8, 0.0))

func _on_question_fail(_popup: Control) -> void:
	mat.set_shader_parameter("vignette_color", Vector3(0.6, 0.0, 0.0))

func _process(delta: float) -> void:
	if (not GameManager.player_exists): return
	
	if GameManager.player.frozen:
		_color_overlay.visible = true
		
		var target_strength = 2.0
		var target_radius = 0.9
		var target_zoom = Vector2(0.5, 0.5)
		var target_opacity = 1.0
		
		vignette_strength = lerp(vignette_strength, target_strength, delta * backdrop_multiplier)
		vignette_radius = lerp(vignette_radius, target_radius, delta * backdrop_multiplier)
		camera_zoom = camera_zoom.lerp(target_zoom, delta * backdrop_multiplier)
		text_opacity = lerp(text_opacity, target_opacity, delta * text_multiplier)
	else:
		var target_strength = 0.0
		var target_radius = 1.0
		var target_zoom = Vector2(0.3, 0.3)
		var target_opacity = 0.0
	
		vignette_strength = lerp(vignette_strength, target_strength, delta * backdrop_multiplier)
		vignette_radius = lerp(vignette_radius, target_radius, delta * backdrop_multiplier)
		camera_zoom = camera_zoom.lerp(target_zoom, delta * backdrop_multiplier)
		text_opacity = lerp(text_opacity, target_opacity, delta * text_multiplier)
		
		if vignette_strength < 0.01:
			_color_overlay.visible = false
	
	mat.set_shader_parameter("vignette_strength", vignette_strength)
	mat.set_shader_parameter("vignette_radius", vignette_radius)
	mat.set_shader_parameter("camera_zoom", camera_zoom)
	
	if GameManager.is_countdown_active():
		_countdown_label.text = "Spil begynder om %s s ..." % floori(GameManager.get_countdown_remaining())
		_countdown_label.show()
	else:
		_countdown_label.hide()
	
	_time_until_next_question.value = clamp(
		GameManager.get_question_countdown_remaining() / Constants.TIME_BETWEEN_QUESTIONS,
		0.0,
		1.0
	)
	
	var current = GameManager.player.get_health()
	if current != last_health:
		last_health = current
		update_health()

func update_health():
	# Clear previous hearts
	for child in hearts_container.get_children():
		child.queue_free()
	
	var max_health = GameManager.player.HEALTH
	var current = GameManager.player.get_health()

	# Create new sprites
	for i in range(max_health):
		var holder = Control.new()
		holder.custom_minimum_size = Vector2(190, 160)

		var heart = AnimatedSprite2D.new()
		var frames = SpriteFrames.new()
		
		frames.add_animation("Alive")
		frames.add_frame("Alive", preload("res://Assets/GameHUD/Health/Alive/frame_0.png"))
		frames.add_frame("Alive", preload("res://Assets/GameHUD/Health/Alive/frame_1.png"))
		
		frames.add_animation("Dead")
		frames.add_frame("Dead", preload("res://Assets/GameHUD/Health/Dead/frame_0.png"))
		frames.add_frame("Dead", preload("res://Assets/GameHUD/Health/Dead/frame_1.png"))

		heart.frames = frames
		heart.animation = "Alive" if (i < current) else "Dead"
		heart.play(&"", 0.5)
		
		heart.rotation = randf_range(-0.15, 0.15)

		holder.add_child(heart)
		hearts_container.add_child(holder)
		hearts_container.move_child(holder, 0)
