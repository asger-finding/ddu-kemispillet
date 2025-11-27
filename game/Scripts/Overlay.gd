extends Control

@onready var hearts_container = $HealthContainer
@onready var filling_label = $FillingContainer/FillingLabel
@onready var scrap_label = $ScrapContainer/ScrapLabel

var last_health = -1
var last_filling = -1
var last_scrap = -1

func _process(_delta):
	if (not GameManager.player_exists): return
	
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

func update_countdown():
	pass
	# filling_label.text = str(Global.Inventory.filling)
	# scrap_label.text   = str(Global.Inventory.scrap)
