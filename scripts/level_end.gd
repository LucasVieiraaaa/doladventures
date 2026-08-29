extends Area2D

@export var next_level = ""

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("PlayerMisc"):
		return
	
	if body.name != "PlayerClone":
		call_deferred("load_next_scene")
	
func load_next_scene():
	if(next_level.length() > 0):
		get_tree().change_scene_to_file("res://scene/" + next_level + ".tscn")
	
