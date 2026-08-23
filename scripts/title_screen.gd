extends Control

@onready var audio_stream_player: AudioStreamPlayer = $AudioStreamPlayer


func _ready() -> void:
	audio_stream_player.volume_db = -10
	audio_stream_player.play()


func _on_start_pressed() -> void:
	get_tree().change_scene_to_file("res://scene/tropic.tscn")
	audio_stream_player.stop()
	


func _on_quit_pressed() -> void:
	audio_stream_player.stop()
	get_tree().quit()
