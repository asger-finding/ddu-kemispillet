extends CanvasLayer

@onready var text = $PauseText

var text_fade_multiplier := 4.0
var camera_zoom := Vector2(0.3, 0.3)
var text_opacity := 1.0

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS

func _process(delta: float) -> void:
	if (not PlayerManager.player_exists or not PlayerManager.player.is_alive()):
		return

	if Input.is_action_just_pressed("Pause"):
		get_tree().paused = !get_tree().paused
	
	if get_tree().paused:
		text.visible = true
		
		var col: Color = text.modulate
		text_opacity = lerp(text_opacity, 1.0, delta * text_fade_multiplier)
		col.a = text_opacity
		text.modulate = col
	else:
		text.visible = false
		text_opacity = 0.0
		text.modulate.a = text_opacity

func _on_give_up_button_button_up() -> void:
	get_tree().quit()

func _on_resume_button_button_up() -> void:
	get_tree().paused = false
