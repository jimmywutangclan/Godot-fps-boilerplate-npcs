extends Node

@export var Item_Name: String
@export var Item_Type: String

@export var Current_Ammo: int
@export var Reserve_Ammo: int

func Get_Usable_Item():
	var Usable_Item = load("res://Assets/" + Item_Name + "/" + Item_Name +".tscn")
	return Usable_Item

func Get_Stats(): # index 0 always returns item type, next indices return a bunch of stats
	return [Item_Type, Current_Ammo, Reserve_Ammo]

func Setup_With_Stats(Stats):
	Current_Ammo = Stats[1]
	Reserve_Ammo = Stats[2]
