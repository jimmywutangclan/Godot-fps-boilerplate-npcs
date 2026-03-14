extends Node

@onready var WeaponStatsBox = $VBoxContainer/AmmoBox/WeaponStats
@onready var HealthStatsBox = $VBoxContainer/Healthbox/HealthStats
@onready var YoudiedBox = $VBoxContainer/YoudiedBox/YoudiedLabel
@onready var ArmorBox = $VBoxContainer/ArmorBox/ArmorStats

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


func _on_proto_controller_update_player_health(Current_Health, Max_Health) -> void:
	HealthStatsBox.set_text("Health: " + str(Current_Health) + "/" + str(Max_Health))
	if Current_Health == 0:
		YoudiedBox.set_text("You suck")


func _on_proto_controller_update_player_armor(Armor) -> void:
	if Armor == 0:
		ArmorBox.set_text("")
	else:
		ArmorBox.set_text("Armor: " + str(Armor))
		
