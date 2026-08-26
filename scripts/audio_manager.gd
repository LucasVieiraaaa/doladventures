extends Node

var music_player: AudioStreamPlayer
var sfx_player: AudioStreamPlayer

func _ready() -> void:
	music_player = AudioStreamPlayer.new()
	music_player.volume_db = 0
	add_child(music_player)

	sfx_player = AudioStreamPlayer.new()
	sfx_player.volume_db = -5
	add_child(sfx_player)


func play_music(audio: AudioStream) -> void:
	if music_player.stream != audio:
		music_player.stream = audio
		music_player.play()


func play_sfx(audio: AudioStream) -> void:
	sfx_player.stream = audio
	sfx_player.play()
