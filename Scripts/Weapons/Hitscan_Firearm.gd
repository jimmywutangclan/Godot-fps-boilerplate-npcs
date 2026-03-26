extends Node3D

@export var Item_Name: String
@export var Thumbnail: Texture2D

@export var Current_Ammo: int
@export var Max_Clip_Ammo: int
@export var Reserve_Ammo: int
@export var Max_Reserve_Ammo: int
@export var Automatic: bool
@export var Gun_Range: int
@export var Damage: int
@export var Force_Modifier: float

@export var Spawn_On_Drop: PackedScene
@export var Animation_Player: AnimationPlayer

@export var Bullet_Mark: PackedScene = preload("res://Assets/Shared_Weapons/Hitmarker.tscn")

@export var Audio_Player: AudioStreamPlayer3D
@export var Shoot_Sfx: AudioStreamMP3
@export var Reload_Sfx: AudioStreamMP3

var Shootpoint: Node
var Action_Locked = false

@export var Is_NPC_Weapon: bool = false
@export var Is_Friendly_NPC_Weapon: bool = false

func _ready():
	Animation_Player.animation_finished.connect(Finished_Animation)
	Shootpoint = get_node("Shootpoint")

func Get_Stats():
	return ["Weapon", Current_Ammo, Reserve_Ammo]

func Setup_With_Stats(Stats):
	Current_Ammo = Stats[1]
	Reserve_Ammo = Stats[2]
	
func Siphon_Resources(Stats):
	var Cumulative_Ammo = Stats[1] + Stats[2]
	var Ammo_Needed = Max_Reserve_Ammo - Reserve_Ammo
	var Ammo_To_Replenish = min(Ammo_Needed, Cumulative_Ammo)
	Reserve_Ammo += Ammo_To_Replenish
	Update_Canvas()
	return Cumulative_Ammo - Ammo_To_Replenish
	
func On_Open():
	Update_Canvas()

func Shoot():
	if Action_Locked == true:
		return
	if Current_Ammo <= 0:
		Animation_Player.play("Empty")
		return
	Animation_Player.play("Shoot")
	Audio_Player.stream = Shoot_Sfx
	Audio_Player.play()
	var Item_Manager = get_parent().get_parent().get_parent()
	var Intersection = Item_Manager.get_Camera_Collision(Gun_Range)[0]
	if Intersection != null:
		var Hit_Position = Intersection.position
		hitscan_Collision(Hit_Position)
	Current_Ammo -= 1
	Action_Locked = true
	Update_Canvas()
	
func NPC_Shoot(Target_Position):
	if Action_Locked == true:
		return
	if Current_Ammo <= 0:
		Animation_Player.play("Empty")
		return
	Animation_Player.play("Shoot")
	Audio_Player.stream = Shoot_Sfx
	Audio_Player.play()
	
	var Target_Intersection = PhysicsRayQueryParameters3D.create(Shootpoint.get_global_transform().origin,Target_Position)
	var Seen_Target = get_world_3d().direct_space_state.intersect_ray(Target_Intersection)
	if Seen_Target:
		var Hit_Position = Seen_Target.position
		hitscan_Collision(Hit_Position)
	Current_Ammo -= 1
	Action_Locked = true

func hitscan_Collision(Collision_Point):
	var Bullet_Dir = (Collision_Point - Shootpoint.get_global_transform().origin).normalized()
	var New_Intersection = PhysicsRayQueryParameters3D.create(Shootpoint.get_global_transform().origin,Collision_Point+Bullet_Dir*2)

	var Bullet_Collision = get_world_3d().direct_space_state.intersect_ray(New_Intersection)
	
	if Bullet_Collision:
		var Hit_Indicator = Bullet_Mark.instantiate()
		Hit_Indicator.scale = Vector3.ONE * 0.01
		Bullet_Collision.collider.add_child(Hit_Indicator)
		Hit_Indicator.global_position = Bullet_Collision.position
		
		var Collider = Bullet_Collision.collider
		var Direction = Bullet_Dir
		var Position = Bullet_Collision.position
		
		if Is_Friendly_NPC_Weapon and (Collider.is_in_group("Player") or Collider.is_in_group("Friendly")):
			return
		
		if Collider.is_in_group("Target") and Collider.has_method("Hit_Successful"):
			var Target = null
			if Is_NPC_Weapon == false:
				Target = get_parent().get_parent().get_parent().get_parent().get_parent()
			elif Is_Friendly_NPC_Weapon == true:
				Target = get_parent().Player

			Collider.Hit_Successful(Damage, Direction, Position, Force_Modifier, Target)

func Reload():
	if Action_Locked == true or Reserve_Ammo <= 0 or Current_Ammo == Max_Clip_Ammo:
		return
	Animation_Player.play("Reload")
	Audio_Player.stream = Reload_Sfx
	Audio_Player.play()
	
	Action_Locked = true
	
func NPC_Reload():
	if Action_Locked == true or Reserve_Ammo <= 0 or Current_Ammo == Max_Clip_Ammo:
		return
	Animation_Player.play("Reload")
	Audio_Player.stream = Reload_Sfx
	Audio_Player.play()
	
	Action_Locked = true
	
func Finished_Animation(action: String):
	if action == "Shoot":
		Action_Locked = false
		if Input.is_action_pressed("Shoot") and Automatic == true and Is_NPC_Weapon == false:
			Shoot()
	if action == "Reload":
		var Needed_Ammo = Max_Clip_Ammo - Current_Ammo
		var Ammo_To_Take = min(Needed_Ammo, Reserve_Ammo)
		
		Reserve_Ammo -= Ammo_To_Take
		Current_Ammo += Ammo_To_Take
		Action_Locked = false
		if Is_NPC_Weapon == false:
			Update_Canvas()

func Update_Canvas():
	var Item_Manager = get_parent().get_parent().get_parent()
	var Label_Contents = Item_Name + ": " + str(Current_Ammo) + "/" + str(Reserve_Ammo)
	Item_Manager.Update_Gun_Stats_Canvas(Label_Contents)
	
