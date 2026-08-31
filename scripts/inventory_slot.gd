extends Control

@onready var icon = $Slot/ItemIcon
@onready var quantity_label = $Slot/Quantity
@onready var details_panel = $DetailsPanel
@onready var item_name = $DetailsPanel/ItemName
@onready var item_type =$DetailsPanel/ItemType
@onready var item_effect =$DetailsPanel/ItemEffect
@onready var usage_panel = $UsagePanel

var item = null

func _ready() -> void:
	pass # Replace with function body.

func _on_item_button_pressed() -> void:
	if item != null:
		usage_panel.visible = !usage_panel.visible

func _on_item_button_mouse_entered() -> void:
	if item != null:
		usage_panel.visible = false
		details_panel.visible = true

func _on_item_button_mouse_exited() -> void:
	details_panel.visible = false
	
	
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
