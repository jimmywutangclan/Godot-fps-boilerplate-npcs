extends CharacterBody3D

@export var Directly_Recruitable: bool = true
@export var Navigation_Agent: NavigationAgent3D

@export var Eyelevel: Node3D
@export var Eyelevel_Forward: Node3D
@export var Vision_Distance: int
@export var Aim_Distance: int
@export var Aim_Error: float
@export var Walk_Speed: int
@export var Run_Speed: int
@export var Aggro_Reaction_Time: float

# Verify stuckness
var Last_Position: Vector3
var Stuck_Timer: float = 0.0
@export var Stuck_Threshold: float = 0.5  # seconds
@export var Stuck_Distance: float = 0.01   # movement threshold

@export var Current_Health: int

@export var Walk_Sfx: AudioStreamMP3
@export var Run_Sfx: AudioStreamMP3
@export var Audio_Player: AudioStreamPlayer3D

# vision
var Inrange_Nodes: Array

enum STATE {IDLE, FOLLOW, CHASE}
@export var Current_State: STATE
enum Move_Sound { WALK, RUN, NONE }
var current_move_sound: Move_Sound = Move_Sound.NONE
var Group: Node3D

# after recruitment in follow state
var Player: Node3D
var Player_Follow_Marker: int
@export var Follow_Distance: int # teleports if exceeded

# chase state
var Enemy: Node3D
@export var Weapon: Node3D
@export var Max_Cumulative_Time_Before_Disengage_Chase: float
var Cumulative_Time_Detached: float = 0.0
@export var Minimum_Attack_Distance: float = 0
var Skip_Dir_Changes: bool

func _ready():
	Current_State = STATE.IDLE
	Inrange_Nodes= []
	Player_Follow_Marker = -1

func _physics_process(delta: float) -> void: # We run our finite state per loop
	Skip_Dir_Changes = false
	# Manage per tick motion
	if Current_State == STATE.IDLE:
		return
	elif Current_State == STATE.FOLLOW:
		Follow_Player()
		for Target in Inrange_Nodes:
			var Seen_Target = Raycast_Target(Target)
			if Seen_Target and Seen_Target.collider == Target:
				Transition_Chase(Target)
	elif Current_State == STATE.CHASE:
		Process_Chase_Target(delta)
	Move_NPC(delta)

# =================================== TRANSITIONS ================

func Transition_Idle():
	print("Friendly transition to idle")
	Current_State = STATE.IDLE
	Enemy = null
	Player = null
	Cumulative_Time_Detached = 0.0

func Transition_Follow(Target):
	print("Friendly transition to follow")
	Enemy = null
	Player = Target
	Current_State = STATE.FOLLOW
	Cumulative_Time_Detached = 0.0

func Transition_Chase(Target):
	print("Friendly transitioning to chasing enemy")
	Enemy = Target
	Cumulative_Time_Detached = 0.0
	Current_State = STATE.CHASE

# ==================== HELPERS ============
	
func Follow_Player():
	Navigation_Agent.set_target_position(Player.Get_Marker_Pos(Player_Follow_Marker))

func Process_Chase_Target(delta):
	if is_instance_valid(Enemy) == false:
		Enemy = null
		Transition_Follow(Player)
		return
	
	Skip_Dir_Changes = true
	look_at(Enemy.get_global_transform().origin, Vector3.UP)
	Navigation_Agent.set_target_position(Enemy.get_global_transform().origin)
	var Seen_Target = Raycast_Target(Enemy, [Player])
	
	if Weapon.get("Current_Ammo") != null and Weapon.Current_Ammo == 0 and Weapon.Reserve_Ammo > 0:
		Weapon.NPC_Reload()
	
	if not Seen_Target or Seen_Target.collider != Enemy:
		Cumulative_Time_Detached += delta
	else:
		var Distance = (Seen_Target.position - Eyelevel.get_global_transform().origin).length_squared()
		if Distance <= Minimum_Attack_Distance * Minimum_Attack_Distance:
			var Turn_Away_Dir = (Seen_Target.position - Eyelevel.get_global_transform().origin).normalized() * 0.2
			Navigation_Agent.set_target_position(global_position - Turn_Away_Dir)
		if Distance <= Vision_Distance * Vision_Distance:
			var Can_Shoot = Can_Attack_From_Angle(Eyelevel.get_global_transform().origin, Eyelevel_Forward.get_global_transform().origin, Seen_Target.position)
			if Can_Shoot:
				var Aim_Noise = Vector3(
					randf_range(-Aim_Error, Aim_Error),
					randf_range(-Aim_Error, Aim_Error),
					randf_range(-Aim_Error, Aim_Error)
				)
				Weapon.NPC_Shoot(Seen_Target.position + Aim_Noise)
			Cumulative_Time_Detached = 0.0
		else:
			Cumulative_Time_Detached += delta
	if Cumulative_Time_Detached >= Max_Cumulative_Time_Before_Disengage_Chase:
		Transition_Follow(Player)
	
func Raycast_Target(Target, Exclude := []):
	var Top_Cast = Target.get_node("TopCast")
	var Bottom_Cast = Target.get_node("BottomCast")
	var List
	if Top_Cast == null or Bottom_Cast == null:
		List = [Target.get_global_transform().origin]
	else:
		var Top_Cast_Pos = Target.get_node("TopCast").get_global_transform().origin
		var Bottom_Cast_Pos = Target.get_node("BottomCast").get_global_transform().origin
		var Middle_Cast_Pos = Vector3(Top_Cast_Pos.x, (Top_Cast_Pos.y + Bottom_Cast_Pos.y) / 2, Top_Cast_Pos.z)
		List = [Top_Cast_Pos, Bottom_Cast_Pos, Middle_Cast_Pos]
	
	for Vision_Target in List:
		var Target_Intersection = PhysicsRayQueryParameters3D.create(Eyelevel.get_global_transform().origin,Vision_Target)
		Target_Intersection.exclude = [get_rid()]
		for Excluded in Exclude:
			Target_Intersection.exclude.append(Excluded.get_rid())
		var Seen_Target = get_world_3d().direct_space_state.intersect_ray(Target_Intersection)
		
		if Seen_Target and Seen_Target.collider == Target:
			return Seen_Target
	
	return null
	
func Can_Attack_From_Angle(Origin, Forward, Target):
	var Max_Angle = PI / 4
	
	var Dir_Forward = (Forward - Origin)
	var Dir_Target = (Target - Origin)
	Dir_Forward.y = 0
	Dir_Target.y = 0
	return Dir_Forward.normalized().angle_to(Dir_Target.normalized()) <= Max_Angle

func Move_NPC(delta):
	var velocity_speed
	var desired_sound
	var turn_speed
	if Current_State != STATE.IDLE:
		velocity_speed = Run_Speed
		desired_sound = Move_Sound.RUN
		turn_speed = 15
	else:
		return
		
	var destination = Navigation_Agent.get_next_path_position()
	var local_destination = destination - global_position
	var direction = local_destination.normalized()
	velocity = direction * velocity_speed
		
	if direction.length() > 0.1 and Skip_Dir_Changes == false:
		var look_target = global_position + direction
		var target_transform = transform.looking_at(look_target, Vector3.UP)
		transform.basis = Basis(transform.basis.get_rotation_quaternion().slerp(
			target_transform.basis.get_rotation_quaternion(), 
			turn_speed * delta
		))
		# var look_target = global_position + direction
		# look_at(look_target, Vector3.UP) old logic
		
	if desired_sound != current_move_sound:
		current_move_sound = desired_sound
		match desired_sound:
			Move_Sound.WALK:
				Audio_Player.stream = Walk_Sfx
				Audio_Player.play()
			Move_Sound.RUN:
				Audio_Player.stream = Run_Sfx
				Audio_Player.play()
			Move_Sound.NONE:
				pass
		
	Check_If_Stuck(delta)
		
	move_and_slide()

func Check_If_Stuck(delta: float):
	if global_position.distance_to(Last_Position) < Stuck_Distance:
		Stuck_Timer += delta
		if Stuck_Timer >= Stuck_Threshold:
			Try_Open_Door()
			Stuck_Timer = 0.0
	else:
		Stuck_Timer = 0.0
	Last_Position = global_position

func Try_Open_Door() -> void:
	var forward = -global_transform.basis.z
	var query = PhysicsRayQueryParameters3D.create(
		global_position,
		global_position + forward * 1.5  # short range, just in front
	)
	query.exclude = [get_rid()]
	var hit = get_world_3d().direct_space_state.intersect_ray(query)
	
	if hit and hit.collider.is_in_group("Interactible"):
		hit.collider.Interact()

# ===================== Signal listeners
# keep them bare minimum logically

func Recruit(Source_Player):
	print("Recruiting by " + str(Source_Player.get_parent().get_parent()))
	Player_Follow_Marker = Source_Player.get_parent().get_parent().Assign_Marker()
	Transition_Follow(Source_Player.get_parent().get_parent())

func _on_navigation_agent_3d_navigation_finished() -> void:
	pass

func _on_area_3d_body_entered(body: Node3D) -> void:
	if body.is_in_group("Thug"):
		Inrange_Nodes.append(body)

func _on_area_3d_body_exited(body: Node3D) -> void:
	if body.is_in_group("Thug"):
		Inrange_Nodes.erase(body)

func Hit_Successful(Damage, _Direction:= Vector3.ZERO, _Position:= Vector3.ZERO, _Force_Modifier:= 1, _Origin_Player = null):
	Current_Health -= Damage
	print("Friendly NPC takes damage to " + str(Current_Health))
	
	# To stay in scope: NPCs are invincible and offer unlimited combat support
	#if Current_Health <= 0:
	#	Group.Remove_Self(self)
	#	queue_free()

func _on_audio_stream_player_3d_finished() -> void:
	current_move_sound = Move_Sound.NONE
