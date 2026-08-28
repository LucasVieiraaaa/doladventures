extends Control
@onready var bamboo_sound: AudioStreamPlayer = $BambooSound

func _ready() -> void:
	pass

func _on_start_pressed() -> void:
	print("apertou")
	bamboo_sound.play()
	await get_tree().create_timer(0.09).timeout
	get_tree().change_scene_to_file("res://scene/tropic.tscn")

func _on_quit_pressed() -> void:
	get_tree().quit()
