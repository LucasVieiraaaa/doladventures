extends Control

@onready var icon = $Slot/ItemIcon
@onready var quantity_label = $Slot/Quantity
@onready var details_panel = $DetailsPanel
@onready var item_name = $DetailsPanel/ItemName
@onready var item_type =$DetailsPanel/ItemType
@onready var item_effect =$DetailsPanel/ItemEffect
@onready var usage_panel = $UsagePanel
@onready var item_info: TextureRect = $"ItemInfo"

var clicked: bool = false
var item = null

func _ready() -> void:
	pass # Replace with function body.

func _on_item_button_pressed() -> void:
	if item == null:
		return

	if clicked:
		close_slot()
	else:
		for slot in get_tree().get_nodes_in_group("InventorySlots"):
			if slot != self:
				slot.close_slot()

		open_slot()
		
func _on_item_button_mouse_entered() -> void:
	pass

func _on_item_button_mouse_exited() -> void:
	pass
	
func set_empty_slot():
	icon.texture = null
	quantity_label.text = ""
	
func set_item(new_item):
	item = new_item
	icon.texture = new_item["texture"]
	quantity_label.text = str(item["quantity"])
	item_name.text = str(item["name"])
	item_type.text = str(item["type"])
	if item["effect"] != "":
		item_effect.text = str("+ ", item["effect"])
	else:
		item_effect.text = ""


func _on_drop_button_pressed() -> void:
	if item != null:
		var drop_position = Global.player.global_position
		var drop_offset = Vector2(0,50)
		drop_offset = drop_offset.rotated(Global.player.rotation)
		Global.drop_item(item, drop_position + drop_offset)
		Global.remove_item(item["type"],item["effect"])
		usage_panel.visible = false

func _on_use_button_pressed() -> void:
	usage_panel.visible = false
	item_info.visible = false
	
	if item != null && item["effect"] != "":
		if Global.player: 
			Global.player.apply_item_effect(item)
			Global.remove_item(item["type"], item["effect"])

func open_slot() -> void:
	clicked = true

	usage_panel.visible = true
	item_info.visible = true
	details_panel.visible = true

func close_slot() -> void:
	clicked = false

	usage_panel.visible = false
	item_info.visible = false
	details_panel.visible = false
