extends Node

var inventory = []
var player : Node = null
signal inventory_updated
@onready var inventory_slot_scene = preload("res://scene/inventory_slot.tscn")

func _ready():
	#08 Slots
	inventory.resize(6)

func add_item(item):
	for i in range(inventory.size()):
		if inventory[i] != null && inventory[i]["type"] == item["type"] && inventory[i]["effect"] == item["effect"]:
			inventory[i]["quantity"] += item["quantity"]
			inventory_updated.emit()
			return true

	for i in range(inventory.size()):
		if inventory[i] == null:
			inventory[i] = item
			inventory_updated.emit()
			return true

	return false
	
func remove_item(item_type, item_effect):
	for i in range(inventory.size()):
		if inventory[i] != null && inventory[i]["type"] == item_type && inventory[i]["effect"] == item_effect:
			inventory[i]["quantity"] -= 1
			if inventory[i]["quantity"] <= 0:
				inventory[i] = null
			inventory_updated.emit()
			return true	
	return false
	
func adjust_drop_position(pos: Vector2) -> Vector2:
	var radius = 100.0
	var nearby_items = get_tree().get_nodes_in_group("Items")
	
	for item in nearby_items:
		# Garante que o item possui a propriedade antes de acessar
		if "global_position" in item and item.global_position.distance_to(pos) < radius:
			var random_offset = Vector2(randf_range(-radius, radius), randf_range(-radius, radius))
			pos += random_offset
			break # Sai do loop assim que encontra uma colisão e aplica o offset
			
	return pos # Retorna a posição (alterada ou original) FORA do loop for
			
func drop_item(item_data, drop_position: Vector2) -> void:
	var item_scene = load(item_data["scene_path"])
	var item_instance = item_scene.instantiate()
	
	item_instance.set_item_data(item_data)
	get_tree().current_scene.add_child(item_instance)
	
	# Ajuste este Vector2(x, y) para posicionar onde desejar em relação ao Player.
	# Se estiver caindo 50px abaixo, subtraia no Y:
	var offset_manual = Vector2(0, -49) 
	
	var final_position = adjust_drop_position(drop_position + offset_manual)
	item_instance.global_position = final_position
	
func increase_inventory():
	inventory_updated.emit()
	
func set_player_reference(actual_player):
	self.player = actual_player
	
func increase_inventory_size(extra_slots):
	inventory.resize(extra_slots + inventory.size())
	inventory_updated.emit()
	
