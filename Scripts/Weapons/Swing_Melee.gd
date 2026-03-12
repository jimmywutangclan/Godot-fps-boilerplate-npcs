extends Node

@export var Item_Name: String
@export var Thumbnail: Texture2D

@export var Damage: int

@export var Spawn_On_Drop: PackedScene
@export var Animation_Player: AnimationPlayer

@export var Physics_Start: Node3D
@export var Physics_End: Node3D
@export var Force_Multiplier: int

@export var Audio_Player: AudioStreamPlayer3D
@export var Shoot_Sfx: AudioStreamMP3

var Action_Locked = false

@export var Is_NPC_Weapon: bool = false

func On_Open():
	Update_Canvas()

func Shoot():
	if Action_Locked == true:
		return
	Action_Locked = true
	Animation_Player.play("Shoot")
	Audio_Player.stream = Shoot_Sfx
	Audio_Player.play()
	
func NPC_Shoot(Target_Position):
	if Action_Locked == true:
		return
	Action_Locked = true
	Animation_Player.play("Shoot")
	Audio_Player.stream = Shoot_Sfx
	Audio_Player.play()
	
func Reload():
	pass

func NPC_Reload():
	pass

func Setup_With_Stats(Stats):
	pass

func Get_Stats():
	return ["Weapon", 0, 0]

func Update_Canvas():
	var Item_Manager = get_parent().get_parent().get_parent()
	Item_Manager.Update_Gun_Stats_Canvas("Sword: infinite ammo since it's not a gun")

func _on_area_3d_body_entered(body: Node3D) -> void:
	if Action_Locked == true and body.is_in_group("Target") and body.has_method("Hit_Successful"):
		var Bullet_Dir = (Physics_End.get_global_transform().origin - Physics_Start.get_global_transform().origin).normalized()
		var Target = null
		if Is_NPC_Weapon == false:
			Target = get_parent().get_parent().get_parent().get_parent().get_parent()
		
		body.Hit_Successful(Damage, Bullet_Dir, Vector3.ZERO, Force_Multiplier, Target)

func _on_animation_player_animation_finished(action: StringName) -> void:
	if action == "Shoot":
		Action_Locked = false
