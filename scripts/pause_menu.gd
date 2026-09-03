extends CanvasLayer

@onready var bamboo_sound: AudioStreamPlayer = $Sounds/BambooSound
@onready var fade_out: ColorRect = $FadeOut

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	visible = false
	get_tree().paused = false
	process_mode = Node.PROCESS_MODE_ALWAYS

func _input(_event: InputEvent) -> void:
	if Input.is_action_just_pressed("pause"):
		if get_tree().paused:
			visible = false
			get_tree().paused = false
		else:
			visible = true
			get_tree().paused = true
			

func _on_button_pressed() -> void:
	bamboo_sound.play()
	
	visible = false
	get_tree().paused = false
	

func _on_main_menu_pressed() -> void:
	bamboo_sound.play()
	var tween := create_tween()
	tween.tween_property(fade_out, "modulate:a", 1.0, 0.5)

	await tween.finished

	await get_tree().create_timer(0.7).timeout
	visible = false
	get_tree().paused = false

	get_tree().change_scene_to_file("res://scene/title_screen.tscn")
	queue_free()
