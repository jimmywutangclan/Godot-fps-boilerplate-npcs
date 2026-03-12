extends Node

@export var Item_Name: String
@export var Reserve_Ammo: int

func Get_Stats():
	return ["Weapon", 0, Reserve_Ammo]

func Setup_With_Stats(Stats):
	Reserve_Ammo = Stats[2]
	if Reserve_Ammo <= 0:
		queue_free()
