extends Control

@onready var menu_click_sound: AudioStreamPlayer = $Audios/MenuClickSound
@onready var on_hover_sound: AudioStreamPlayer = $Audios/OnHoverSound
@onready var fade_out: ColorRect = $FadeOut

func _on_start_pressed() -> void:
	menu_click_sound.play()
	await get_tree().create_timer(0.09).timeout
	var tween := create_tween()
	tween.tween_property(fade_out, "modulate:a", 1.0, 0.5)

	await tween.finished

	await get_tree().create_timer(0.7).timeout
	visible = false
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scene/tropic.tscn")

func _on_quit_pressed() -> void:
	get_tree().quit()

func _on_start_mouse_entered() -> void:
	on_hover_sound.play()
	return

func _on_options_mouse_entered() -> void:
	on_hover_sound.play()
	return

func _on_quit_mouse_entered() -> void:
	on_hover_sound.play()
	return
