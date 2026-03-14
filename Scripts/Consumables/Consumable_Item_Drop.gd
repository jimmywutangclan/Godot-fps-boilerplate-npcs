extends Node

@export var Item_Name: String
@export var Item_Type: String

func Get_Usable_Item():
	var Usable_Item = load("res://Assets/Consumables/" + Item_Name + "/" + Item_Name +".tscn")
	return Usable_Item

func Get_Stats(): # index 0 always returns item type, next indices return a bunch of stats
	return [0, 0, 0]

func Setup_With_Stats(Stats):
	pass
