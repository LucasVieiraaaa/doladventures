extends HBoxContainer

var slots: Array

var normal_texture_0 = preload("res://sprites/UI/Buttons/multi_shadow_clone_icon.png")
var normal_texture_1 = preload("res://sprites/UI/Buttons/odama_rasengan_icon.png")

var original_texture_0
var original_texture_1


func _ready() -> void:
	slots = get_children()

	slots[0].change_key = "Q"
	slots[1].change_key = "E"

	# Guarda as texturas originais
	original_texture_0 = slots[0].texture_normal
	original_texture_1 = slots[1].texture_normal


func _input(input: InputEvent) -> void:
	if input is InputEventKey:
		if input.keycode == KEY_SHIFT:

			if input.pressed:
				# SHIFT pressionado
				slots[0].texture_normal = preload("res://sprites/UI/Buttons/multi_shadow_clone_icon.png")
				slots[1].texture_normal = preload("res://sprites/UI/Buttons/odama_rasengan_icon.png")

			else:
				# SHIFT solto
				slots[0].texture_normal = original_texture_0
				slots[1].texture_normal = original_texture_1
