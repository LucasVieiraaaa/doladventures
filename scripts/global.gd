extends Node

var inventory = []
var player : Node = null
signal inventory_updated

func _ready():
	#30 Slots
	inventory.resize(30)

func add_item(item):
	for i in range(inventory.size()):
		if inventory[i] != null && inventory[i]["type"] == item["type"] && inventory[i]["effect"] == item["effect"]:
			inventory[i]["quantity"] += item["quantity"]
			inventory_updated.emit()
			return true
		elif inventory[i] == null:
			inventory[i] = item
			inventory_updated.emit()
			return true
		return false
	
func remove_item():
	inventory_updated.emit()
	
func increase_inventory():
	inventory_updated.emit()
	
func set_player_reference(actual_player):
	self.player = actual_player
	
