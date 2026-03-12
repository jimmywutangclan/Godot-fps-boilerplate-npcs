extends Node3D

@export var Item_Name: String
@export var Thumbnail: Texture2D

@export var Current_Ammo: int
@export var Max_Clip_Ammo: int
@export var Reserve_Ammo: int
@export var Max_Reserve_Ammo: int			
@export var Automatic: bool
@export var Projectile_Velocity: int

@export var Spawn_On_Drop: PackedScene
@export var Animation_Player: AnimationPlayer

@export var Projectile_To_Load: PackedScene

@export var Shootpoint: Node

@export var Audio_Player: AudioStreamPlayer3D
@export var Shoot_Sfx: AudioStreamMP3
@export var Reload_Sfx: AudioStreamMP3

@export var Is_NPC_Weapon: bool = false

var Action_Locked = false

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

func _on_animation_player_animation_finished(action: StringName) -> void:
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

func Shoot():
	if Action_Locked == true:
		return
	if Current_Ammo <= 0:
		Animation_Player.play("Empty")
		return
		
	Action_Locked = true
	Animation_Player.play("Shoot")
	Audio_Player.stream = Shoot_Sfx
	Audio_Player.play()
	Current_Ammo -= 1
	
	var Item_Manager = get_parent().get_parent().get_parent()
	var Destination = Item_Manager.get_Camera_Collision(30)[1]
	
	var Player_Source = get_parent().get_parent().get_parent().get_parent().get_parent()
	
	var Direction = (Destination - Shootpoint.get_global_transform().origin).normalized()
	var Projectile_Obj = Projectile_To_Load.instantiate()
	Projectile_Obj.Source = Player_Source
	Shootpoint.add_child(Projectile_Obj)
	Projectile_Obj.global_position = Shootpoint.get_global_transform().origin
	Projectile_Obj.set_linear_velocity(Direction*Projectile_Velocity)	
	Projectile_Obj.look_at(Destination, Vector3.UP)
	
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
	
	var Direction = (Target_Position - Shootpoint.get_global_transform().origin).normalized()
	var Projectile_Obj = Projectile_To_Load.instantiate()
	Shootpoint.add_child(Projectile_Obj)
	Projectile_Obj.global_position = Shootpoint.get_global_transform().origin
	Projectile_Obj.set_linear_velocity(Direction*Projectile_Velocity)	
	Projectile_Obj.look_at(Target_Position, Vector3.UP)
	
	Current_Ammo -= 1
	Action_Locked = true

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

func Update_Canvas():
	var Item_Manager = get_parent().get_parent().get_parent()
	var Label_Contents = Item_Name + ": " + str(Current_Ammo) + "/" + str(Reserve_Ammo)
	Item_Manager.Update_Gun_Stats_Canvas(Label_Contents)
