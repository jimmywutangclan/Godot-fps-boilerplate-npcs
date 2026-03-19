extends CharacterBody3D

@export var Navigation_Agent: NavigationAgent3D
@export var Nav_Trail_Group: Node3D
@export var Walk_Speed: int
@export var Current_Health: int
@export var Walk_Sfx: AudioStreamMP3
@export var Audio_Player: AudioStreamPlayer3D
@export var Start_Goalpost: int
@export var Start_Reversed: bool = false

# patrol
var Nav_Trail: Array
var Current_Goalpost: int
var Reversing: bool
var Arrived: bool
enum Move_Sound { WALK, NONE }
var current_move_sound: Move_Sound = Move_Sound.NONE

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Current_Goalpost = Start_Goalpost
	Reversing = Start_Reversed
	Arrived = false
	
	for Nav_Point in Nav_Trail_Group.get_children():
		Nav_Trail.append(Nav_Point)

	var Pos = Nav_Trail[Current_Goalpost].get_global_transform().origin
	Navigation_Agent.set_target_position(Pos)

func Update_Goalpost():
	if Reversing == false and Current_Goalpost == len(Nav_Trail) - 1:
		Reversing = true
	if Reversing == true and Current_Goalpost == 0:
		Reversing = false
		
	if Reversing == false:
		Current_Goalpost += 1
	else:
		Current_Goalpost -= 1
		
	var Pos = Nav_Trail[Current_Goalpost].get_global_transform().origin
	Navigation_Agent.set_target_position(Pos)
	
	Arrived = false

func Move_NPC(delta):
	var velocity_speed = Walk_Speed
	var desired_sound = Move_Sound.WALK
	var turn_speed = 5
		
	var destination = Navigation_Agent.get_next_path_position()
	var local_destination = destination - global_position
	var direction = local_destination.normalized()
	velocity = direction * velocity_speed
		
	if direction.length() > 0.1:
		var look_target = global_position + direction
		var target_transform = transform.looking_at(look_target, Vector3.UP)
		transform.basis = Basis(transform.basis.get_rotation_quaternion().slerp(
			target_transform.basis.get_rotation_quaternion(), 
			turn_speed * delta
		))
		
	if desired_sound != current_move_sound:
		current_move_sound = desired_sound
		match desired_sound:
			Move_Sound.WALK:
				Audio_Player.stream = Walk_Sfx
				Audio_Player.play()
			Move_Sound.NONE:
				pass
	move_and_slide()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if Arrived:
		Update_Goalpost()
	Move_NPC(delta)


func _on_navigation_agent_3d_navigation_finished() -> void:
	Arrived = true


func _on_audio_stream_player_3d_finished() -> void:
	current_move_sound = Move_Sound.NONE
	
func Hit_Successful(Damage, _Direction:= Vector3.ZERO, _Position:= Vector3.ZERO, _Force_Modifier:= 1, _Origin_Player = null):
	Current_Health -= Damage
	print("NPC takes damage to " + str(Current_Health))
	
	if Current_Health <= 0:
		queue_free()
