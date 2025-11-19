extends CanvasLayer

@onready var overlay = $DeathScreen
@onready var text = $DeathText
@onready var mat: ShaderMaterial = overlay.material

var player_died = false
var backdrop_multiplier := 2.0
var text_multiplier := 2.0
var vignette_strength: float = 0.0
var vignette_radius: float = 1.0
var camera_zoom := Vector2(0.3, 0.3)
var grayscale_amount := 0.0
var text_opacity := 1.0

func _process(delta: float) -> void:
	if (not PlayerManager.player_exists): return
	player_died = not PlayerManager.player.is_alive()

	if player_died:
		overlay.visible = true
		text.visible = true

		vignette_strength = lerp(vignette_strength, 1.0, delta * backdrop_multiplier)
		vignette_radius   = lerp(vignette_radius,   0.9, delta * backdrop_multiplier)
		camera_zoom       = camera_zoom.lerp(Vector2(0.5, 0.5), delta * backdrop_multiplier)
		grayscale_amount  = lerp(grayscale_amount, 1.0, delta * backdrop_multiplier)
		text_opacity      = lerp(text_opacity, 1.0, delta * text_multiplier)

		mat.set_shader_parameter("vignette_strength", vignette_strength)
		mat.set_shader_parameter("vignette_radius", vignette_radius)
		mat.set_shader_parameter("camera_zoom", camera_zoom)
		mat.set_shader_parameter("grayscale_amount", grayscale_amount)

		var col: Color = text.modulate
		col.a = text_opacity
		text.modulate = col
	else:
		overlay.visible = false
		text.visible = false
		text_opacity = 0.0
		text.modulate.a = 0.0

func _on_try_again_button_button_up() -> void:
	SceneManager.load_scene("Game")

func _on_give_up_button_button_up() -> void:
	get_tree().quit()
