extends Node3D

signal Update_Weapon_Stats
signal Update_Inventory

@onready var Animation_Player = get_node("AnimationPlayer")

var Current_Item = 1
var Next_Item = 1
var Use_Locked = false
var Target_Item: Node = null
var Is_Dead = false

@export var Item_Points: Array[Node3D]
@export var Drop_Point: Node3D
@export var Vision_Range: int

@export var Audio_Player: AudioStreamPlayer3D
@export var Pickup_Sfx: AudioStreamMP3

# ========== GAME LOOP HANDLERS IN GODOT ================

func _ready():
	for i in range(0, 10): # instantiate inventory bar
		Update_Inventory_Hbox(i)
		
	Animation_Player.play("ItemHolder" + str(Current_Item) + "Activate")
	
func _process(delta: float):
	var Sight_Collision = get_Camera_Collision(Vision_Range)[0]
	
	if Sight_Collision != null:
		var Valid_Categories = ["ItemPickup", "AmmoBox", "Interactible"]
		for Category in Valid_Categories:
			if Sight_Collision.collider.is_in_group(Category):
				Target_Item = Sight_Collision.collider
				return
	else:
		Target_Item = null

func _input(event):
	if Is_Dead:
		return
	if event.is_action_pressed("ScrollInventoryUp"):
		Next_Item = Current_Item - 1
		if Next_Item < 0:
			Next_Item = 9
		Withdraw_Current_Weapon()
	if event.is_action_pressed("ScrollInventoryDown"):
		Next_Item = Current_Item + 1
		if Next_Item > 9:
			Next_Item = 0
		Withdraw_Current_Weapon()
	if event.is_action_pressed("Shoot"):
		if Use_Locked == false:
			Shoot()
	if event.is_action_pressed("Reload"):
		if Use_Locked == false:
			Reload()
	if event.is_action_pressed("Drop"):
		if Use_Locked == false:
			Drop_Item()
	if event.is_action_pressed("Interact"):
		if Target_Item != null:
			if Target_Item.is_in_group("ItemPickup"):
				Pickup_Item(Target_Item)
			if Target_Item.is_in_group("AmmoBox"):
				Pickup_AmmoBox(Target_Item)
			if Target_Item.is_in_group("Interactible"):
				Interact_Item(Target_Item)
			Audio_Player.stream = Pickup_Sfx
			Audio_Player.play()
	for i in range(0, 10):
		if event.is_action_pressed("Item" + str(i)):
			Next_Item = i
			Withdraw_Current_Weapon()

func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	if anim_name == "ItemHolder" + str(Current_Item) + "Withdraw":
		Animation_Player.play("ItemHolder" + str(Next_Item) + "Activate")
	if anim_name == "ItemHolder" + str(Next_Item) + "Activate":
		Current_Item = Next_Item
		Use_Locked = false
		var Current_Item_Child = Get_Current_Item()
		if Current_Item_Child != null:
			Current_Item_Child.On_Open()
		else:
			Setup_Empty_Object()
		Update_Inventory_Hbox(Current_Item)

# =================== LOGICAL HANDLERS ========================

func Setup_Empty_Object():
	Update_Gun_Stats_Canvas("you got Jack shit here")

func Withdraw_Current_Weapon():
	if Animation_Player.get_current_animation() != "ItemHolder" + str(Current_Item) + "Withdraw":
		Animation_Player.play("ItemHolder" + str(Current_Item) + "Withdraw")
		Use_Locked = true

func Shoot():
	var Child = Get_Current_Item()
	if Child != null:
		Child.Shoot()

func Reload():
	var Child = Get_Current_Item()
	if Child != null:
		Child.Reload()

func Drop_Item():
	var Child = Get_Current_Item()
	if Child != null:
		var Item_Stats = Child.Get_Stats()
		var To_Drop = Child.Spawn_On_Drop
		var Dropped_Weapon = To_Drop.instantiate()
		Dropped_Weapon.Setup_With_Stats(Item_Stats)
		
		Dropped_Weapon.set_global_transform(Drop_Point.get_global_transform())
		var World = get_tree().root.get_child(-1)
		World.add_child(Dropped_Weapon)
		Item_Points[Current_Item].remove_child(Child)
		Child.queue_free()
		Update_Inventory_Hbox(Current_Item)
		Setup_Empty_Object()

func Pickup_Item(Target_Item: Node):
	var Child = Get_Current_Item()
	var Item_Holder = Item_Points[Current_Item]
	if Child == null:
		var Pickup = Target_Item.Get_Usable_Item().instantiate()
		var Stats = Target_Item.Get_Stats()
		Pickup.Setup_With_Stats(Stats)
		Item_Holder.add_child(Pickup)
		Target_Item.queue_free()
		Update_Inventory_Hbox(Current_Item)
		Pickup.On_Open()
	else:
		if Child.Item_Name == Target_Item.Item_Name and Target_Item.Item_Type == "Weapon":
			var Stats = Target_Item.Get_Stats()
			var Reserve_Remaining = Child.Siphon_Resources(Stats)
			Target_Item.Setup_With_Stats(["Weapon", 0, Reserve_Remaining])

func Pickup_AmmoBox(Target_Item: Node):
	var Child = Get_Current_Item()
	if Child != null and Child.Item_Name == Target_Item.Item_Name:
		var Stats = Target_Item.Get_Stats()
		var Reserve_Remaining = Child.Siphon_Resources(Stats)
		Target_Item.Setup_With_Stats(["Weapon", 0, Reserve_Remaining])

func Interact_Item(Target_Item: Node):
	Target_Item.Interact()

func Release_Item_Slot(Item):
	Item_Points[Current_Item].remove_child(Item)
	Item.queue_free()
	Update_Inventory_Hbox(Current_Item)
	Setup_Empty_Object()

# =========== EXTERNAL CALLS ===============

func Update_Gun_Stats_Canvas(Label_Contents):
	emit_signal("Update_Weapon_Stats", Label_Contents)

func Update_Inventory_Hbox(Idx):
	var Child = Get_Item_From_Idx(Idx)
	var Thumbnail = null
	if Child != null:
		Thumbnail = Child.Thumbnail
	emit_signal("Update_Inventory", Idx, Thumbnail)
	

# =========== HELPERS ==================

func Get_Current_Item():
	var Item_Holder = Item_Points[Current_Item]
	var Item_Holder_Children = Item_Holder.get_children()
	for Child in Item_Holder_Children:
		if Child.is_in_group("Item"):
			return Child
	return null
	
func Get_Item_From_Idx(Idx):
	var Item_Holder = Item_Points[Idx]
	var Item_Holder_Children = Item_Holder.get_children()
	for Child in Item_Holder_Children:
		if Child.is_in_group("Item"):
			return Child
	return null

func get_Camera_Collision(range: int): # returns intersection transform and position
	var camera = get_viewport().get_camera_3d()
	var viewport = get_viewport().get_size()
	
	var Ray_Origin = camera.project_ray_origin(viewport / 2)
	var Ray_End = Ray_Origin + camera.project_ray_normal(viewport / 2) * range
	
	var New_Intersection = PhysicsRayQueryParameters3D.create(Ray_Origin,Ray_End)
	var Intersection = get_world_3d().direct_space_state.intersect_ray(New_Intersection)
	
	if not Intersection.is_empty():
		return [Intersection, Intersection.position]
	else:
		return [null, Ray_End]
