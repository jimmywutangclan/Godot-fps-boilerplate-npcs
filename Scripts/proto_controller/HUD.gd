extends Node

@onready var WeaponStatsBox = $VBoxContainer/AmmoBox/WeaponStats
@onready var HealthStatsBox = $VBoxContainer/Healthbox/HealthStats
@onready var YoudiedBox = $VBoxContainer/YoudiedBox/YoudiedLabel

func _on_item_manager_update_weapon_stats(Value) -> void:
	WeaponStatsBox.set_text(Value)


func _on_item_manager_update_inventory(Current_Item, Thumbnail) -> void:
	for i in range(0, 10):
		var ItemBox = get_node("HBoxContainer/ItemBox" + str(i) + "/")
		var ActivityFrame = ItemBox.get_node("ActivityFrame/")
		var ItemThumbnailHolder = ItemBox.get_node("Thumbnail/")
		if i == Current_Item:
			ActivityFrame.visible = true
			if ItemThumbnailHolder.texture != Thumbnail:
				ItemThumbnailHolder.texture = Thumbnail
		else:
			ActivityFrame.visible = false


func _on_proto_controller_update_player_health(Health) -> void:
	HealthStatsBox.set_text("Health: " + str(Health))
	if Health == 0:
		YoudiedBox.set_text("You suck")
