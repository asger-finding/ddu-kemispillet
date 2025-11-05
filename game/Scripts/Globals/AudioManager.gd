extends Node

@export var music_bus: StringName = "Music"
@export var sfx_bus: StringName = "SFX"

var music_player: AudioStreamPlayer
var sfx_players: Array[AudioStreamPlayer] = []

func _ready() -> void:
	music_player = AudioStreamPlayer.new()
	music_player.bus = music_bus
	add_child(music_player)

func play_music(stream: AudioStream, loop: bool = true, volume_db: float = 0.0) -> void:
	if not stream:
		return
	
	music_player.stop()
	music_player.stream = stream
	music_player.volume_db = volume_db
	music_player.stream_paused = false
	music_player.loop = loop
	music_player.play()

func stop_music() -> void:
	music_player.stop()

func set_music_volume(volume_db: float) -> void:
	music_player.volume_db = volume_db

func play_sfx(stream: AudioStream, volume_db: float = 0.0) -> void:
	if not stream:
		return
	
	var sfx_player := AudioStreamPlayer.new()
	sfx_player.bus = sfx_bus
	sfx_player.stream = stream
	sfx_player.volume_db = volume_db
	add_child(sfx_player)
	sfx_players.append(sfx_player)
	sfx_player.play()
	sfx_player.connect("finished", Callable(self, "_on_sfx_finished").bind(sfx_player))

func pause_all(paused: bool) -> void:
	music_player.stream_paused = paused
	for p in sfx_players:
		p.stream_paused = paused

func mute_all(muted: bool) -> void:
	AudioServer.set_bus_mute(AudioServer.get_bus_index(music_bus), muted)
	AudioServer.set_bus_mute(AudioServer.get_bus_index(sfx_bus), muted)

func save_volume():
	var config = ConfigFile.new()
	config.set_value("audio", "music_volume", music_player.volume_db)
	config.save("user://settings.cfg")

func load_volume():
	var config = ConfigFile.new()
	if config.load("user://settings.cfg") == OK:
		set_music_volume(config.get_value("audio", "music_volume", 0))

func _on_sfx_finished(sfx_player: AudioStreamPlayer) -> void:
	if is_instance_valid(sfx_player):
		sfx_player.queue_free()
	sfx_players.erase(sfx_player)
