extends CharacterBody3D

@export var Navigation_Agent: NavigationAgent3D
@export var NPC_Group: Node3D
@export var Nav_Trail_Group: Node3D

@export var Eyelevel: Node3D
@export var Eyelevel_Forward: Node3D
@export var Vision_Distance: int
@export var Aim_Distance: int
@export var Aim_Error: float
@export var Walk_Speed: int
@export var Run_Speed: int
@export var Max_Cumulative_Time_Before_Chase: float
@export var Max_Cumulative_Time_Before_Disengage_Chase: float
@export var Aggro_Reaction_Time: float

# Verify stuckness
var Last_Position: Vector3
var Stuck_Timer: float = 0.0
@export var Stuck_Threshold: float = 0.5  # seconds
@export var Stuck_Distance: float = 0.01   # movement threshold

@export var Current_Health: int

@export var Start_Reversed: bool = false
@export var Start_Goalpost: int = 0

@export var Walk_Sfx: AudioStreamMP3
@export var Run_Sfx: AudioStreamMP3
@export var Audio_Player: AudioStreamPlayer3D

# patrol+investigation
var Fight_Started: bool = false
var Fight_Target: Node3D = null
var Fight_Elapsed_Reaction_Time: float = 0.0

# patrol
var Nav_Trail: Array
var Current_Goalpost: int
var Reversing: bool
var Arrived: bool

# investigation
var Investigation_Target_Pos: Vector3
var Investigation_Target: Node3D
var Cumulative_Time_Seen: float
var Pending_Final_Decision: bool

# chase
var Chase_Target: Node3D
var Cumulative_Time_Detached: float
@export var Weapon: Node3D
@export var Minimum_Attack_Distance: float = 0
var Skip_Dir_Changes: bool

# vision
var Inrange_Nodes: Array
# behind the NPC
var Behind_Nodes: Array
# vision forward for passives
var Inrange_Passives: Array

enum STATE {PATROL, INVESTIGATE, CHASE}
var Current_State: STATE
enum Move_Sound { WALK, RUN, NONE }
var current_move_sound: Move_Sound = Move_Sound.NONE
var Group: Node3D

func _ready():
	Current_State = STATE.PATROL
	Current_Goalpost = Start_Goalpost
	Reversing = Start_Reversed
	Arrived = false
	
	for Nav_Point in Nav_Trail_Group.get_children():
		Nav_Trail.append(Nav_Point)
		
	Inrange_Nodes = []
	Inrange_Passives = []
	
	var Pos = Nav_Trail[Current_Goalpost].get_global_transform().origin
	Navigation_Agent.set_target_position(Pos)
	
	Cumulative_Time_Seen = 0.0
	Pending_Final_Decision = false
	
	Cumulative_Time_Detached = 0.0

func _physics_process(delta: float) -> void: # We run our finite state per loop
	Skip_Dir_Changes = false
	if Fight_Started:
		if Fight_Elapsed_Reaction_Time < Aggro_Reaction_Time:
			Fight_Elapsed_Reaction_Time += delta
		else:
			Transition_Chase(Fight_Target)
	
	if Current_State == STATE.PATROL: # Keep walking and checking for player		
		if Arrived:
			Update_Goalpost()
					
		for Target in Inrange_Nodes:
			var Seen_Target = Raycast_Target(Target)
			if Seen_Target and Seen_Target.collider == Target:
				Transition_Investigate(Seen_Target.collider)
				break
		
		for Target in Behind_Nodes:
			Test_Target_Audible(Target)
			
		# if no player found, harass a passive instead
		if Current_State == STATE.PATROL:
			for Target in Inrange_Passives:
				var Seen_Target = Raycast_Target(Target)
				if Seen_Target and Seen_Target.collider == Target:
					Attack_Passive(Seen_Target.collider)
					break
	elif Current_State == STATE.INVESTIGATE: # Walk to our destination and keep lookout for player
		if Pending_Final_Decision:
			Conclude_Investigation()
		else:
			Process_Investigation(delta)
	elif Current_State == STATE.CHASE:
		Process_Chase_Target(delta)

	# Manage per tick motion
	Move_NPC(delta)

# =================================== TRANSITIONS ================

func Transition_Patrol():
	print("Entering patrol state")
	Cumulative_Time_Seen = 0.0
	Cumulative_Time_Detached = 0.0
	var Pos = Nav_Trail[Current_Goalpost].get_global_transform().origin
	Navigation_Agent.set_target_position(Pos)
	Current_State = STATE.PATROL
	
func Transition_Investigate(Target):
	print("Entering investigation state")
	Cumulative_Time_Seen = 0.0
	Cumulative_Time_Detached = 0.0
	Investigation_Target_Pos = Target.get_global_transform().origin
	Investigation_Target = Target
	Navigation_Agent.set_target_position(Investigation_Target_Pos)
	Current_State = STATE.INVESTIGATE

func Transition_Chase(Target):
	print("Entering chase state")
	Cumulative_Time_Seen = 0.0
	Cumulative_Time_Detached = 0.0
	Chase_Target = Target
	Current_State = STATE.CHASE
	Fight_Started = false
	Fight_Target = null
	Fight_Elapsed_Reaction_Time = 0.0
	Group.Alert_All(Target)

# ==================== HELPERS ============
	
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

func Test_Target_Audible(Target):
	if Target.is_in_group("Player"):
		var Player_Distance = (Target.get_global_transform().origin - global_position).length()
		var Player_Walk_Speed = Target.base_speed
		var Player_Run_Speed = Target.sprint_speed
		var Perceived_Player_Speed = Target.move_speed / Target.speed_perception_modifier
		
		if Perceived_Player_Speed == Player_Run_Speed or (Perceived_Player_Speed > Player_Walk_Speed / 2.0 and Player_Distance <= 5):
			Transition_Investigate(Target)
			
func Attack_Passive(Target):
	if Target.is_in_group("Passive"):
		Skip_Dir_Changes = true
		look_at(Target.get_global_transform().origin, Vector3.UP)
		
		if Weapon.get("Current_Ammo") != null and Weapon.Current_Ammo == 0 and Weapon.Reserve_Ammo > 0:
			Weapon.NPC_Reload()
		
		Weapon.NPC_Shoot(Target.position)
		
	
func Conclude_Investigation():
	var Seen_Target = Raycast_Target(Investigation_Target)
	var To_Chase = false
	
	if Seen_Target and Seen_Target.collider == Investigation_Target:
		var Distance = (Seen_Target.position - Eyelevel.get_global_transform().origin).length_squared()
		if Distance <= Vision_Distance * Vision_Distance:
			Transition_Chase(Seen_Target.collider)
			To_Chase = true
	
	if To_Chase == false:
		Transition_Patrol()
		
	Pending_Final_Decision = false

func Process_Investigation(delta):
	var Seen_Target = Raycast_Target(Investigation_Target)
	if Seen_Target and Seen_Target.collider == Investigation_Target:
		var Distance = (Seen_Target.position - Eyelevel.get_global_transform().origin).length()
		if Distance <= Vision_Distance:
			Cumulative_Time_Seen += delta
			if Cumulative_Time_Seen >= Max_Cumulative_Time_Before_Chase:
				Transition_Chase(Seen_Target.collider)
	
func Process_Chase_Target(delta):
	Skip_Dir_Changes = true
	look_at(Chase_Target.get_global_transform().origin, Vector3.UP)
	Navigation_Agent.set_target_position(Chase_Target.get_global_transform().origin)
	var Seen_Target = Raycast_Target(Chase_Target)
	
	if Weapon.get("Current_Ammo") != null and Weapon.Current_Ammo == 0 and Weapon.Reserve_Ammo > 0:
		Weapon.NPC_Reload()
	
	if not Seen_Target or Seen_Target.collider != Chase_Target:
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
		Transition_Patrol()

func Raycast_Target(Target):
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
	if Current_State == STATE.CHASE:
		velocity_speed = Run_Speed
		desired_sound = Move_Sound.RUN
		turn_speed = 5
	else:
		velocity_speed = Walk_Speed
		desired_sound = Move_Sound.WALK
		turn_speed = 1.5
		
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

func _on_navigation_agent_3d_navigation_finished() -> void:
	if Current_State == STATE.PATROL:
		Arrived = true
	elif Current_State == STATE.INVESTIGATE:
		Pending_Final_Decision = true
	

func _on_area_3d_body_entered(body: Node3D) -> void:
	if body.is_in_group("Player"): 
		Inrange_Nodes.append(body)
	elif body.is_in_group("Passive"):
		Inrange_Passives.append(body)

func _on_area_3d_body_exited(body: Node3D) -> void:
	if body.is_in_group("Player"):
		Inrange_Nodes.erase(body)
	elif body.is_in_group("Passive"):
		Inrange_Passives.erase(body)

func _on_back_audio_detection_body_entered(body: Node3D) -> void:
	if body.is_in_group("Player"):
		Behind_Nodes.append(body)

func _on_back_audio_detection_body_exited(body: Node3D) -> void:
	if body.is_in_group("Player"):
		Behind_Nodes.erase(body) 

func Hit_Successful(Damage, _Direction:= Vector3.ZERO, _Position:= Vector3.ZERO, _Force_Modifier:= 1, _Origin_Player = null):
	Current_Health -= Damage
	print("NPC takes damage to " + str(Current_Health))
	print(_Origin_Player)
	
	if Current_State != STATE.CHASE and _Origin_Player != null:
		Fight_Started = true
		Fight_Target = _Origin_Player
	
	if Current_Health <= 0:
		Group.Remove_Self(self)
		queue_free()


func _on_audio_stream_player_3d_finished() -> void:
	current_move_sound = Move_Sound.NONE
