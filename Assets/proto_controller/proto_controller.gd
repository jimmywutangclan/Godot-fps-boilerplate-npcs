# ProtoController v1.0 by Brackeys
# CC0 License
# Intended for rapid prototyping of first-person games.
# Happy prototyping!

extends CharacterBody3D

signal Update_Player_Health
signal Update_Player_Armor
signal Update_Player_Death_Fade

## Can we move around?
@export var can_move : bool = true
## Are we affected by gravity?
@export var has_gravity : bool = true
## Can we press to jump?
@export var can_jump : bool = true
## Can we hold to run?
@export var can_sprint : bool = false
## Can we press to enter freefly mode (noclip)?
@export var can_freefly : bool = false

@export_group("Speeds")
## Look around rotation speed.
@export var look_speed : float = 0.002
## Normal speed.
@export var base_speed : float = 7.0
## Speed of jump.
@export var jump_velocity : float = 4.5
## How fast do we run?
@export var sprint_speed : float = 10.0
## How fast do we freefly?
@export var freefly_speed : float = 25.0

@export_group("Input Actions")
## Name of Input Action to move Left.
@export var input_left : String = "ui_left"
## Name of Input Action to move Right.
@export var input_right : String = "ui_right"
## Name of Input Action to move Forward.
@export var input_forward : String = "ui_up"
## Name of Input Action to move Backward.
@export var input_back : String = "ui_down"
## Name of Input Action to Jump.
@export var input_jump : String = "ui_accept"
## Name of Input Action to Sprint.
@export var input_sprint : String = "sprint"
## Name of Input Action to toggle freefly mode.
@export var input_freefly : String = "freefly"

@export var Max_Health: int = 120
var Current_Health: int
@export var Current_Armor: int = 0
var Stats_Constraints: Dictionary

var mouse_captured : bool = false
var look_rotation : Vector2
var move_speed : float = 0.0
var freeflying : bool = false
var speed_perception_modifier : int = 1

var sound_locked : bool = false

## IMPORTANT REFERENCES
@onready var head: Node3D = $Head
@onready var collider: CollisionShape3D = $Collider

@export var Audio_Player: AudioStreamPlayer3D
@export var Walk_Sfx: AudioStreamMP3
@export var Run_Sfx: AudioStreamMP3
@export var Start_Jump_Sfx: AudioStreamMP3
@export var Jump_Landing_Sfx: AudioStreamMP3
@export var Death_Sfx: AudioStreamMP3
@export var Hit_Sfx: AudioStreamMP3
@export var Animation_Player: AnimationPlayer
@export var Talking_Audio_Player: AudioStreamPlayer3D
@export var Injury_Audio_Player: AudioStreamPlayer3D

@export var Top_Cast: Marker3D
@export var Bottom_Cast: Marker3D

@export var Item_Manager: Node3D

@export var Follow_Markers: Node3D

var Active_Effects: Array

enum MoveSound {NONE, WALK, RUN, JUMP}
var current_move_sound: MoveSound = MoveSound.NONE
var was_on_floor: bool = false
var is_crouched: bool = false
var is_dead: bool = false
var death_countdown: float = 0.0

var Follow_Markers_List: Array
var Current_Marker_Assignment: int

var Invincible: bool

func _ready() -> void:
	check_input_mappings()
	Active_Effects = []
	Current_Health = Max_Health
	look_rotation.y = rotation.y
	look_rotation.x = head.rotation.x
	emit_signal("Update_Player_Health", Current_Health, Max_Health)
	Stats_Constraints = {}
	Stats_Constraints["Current_Health"] = "Max_Health"
	
	Current_Marker_Assignment = 0
	var Marks = Follow_Markers.get_children()
	for Mark in Marks:
		Follow_Markers_List.append(Mark)
	
	Invincible = false

func _unhandled_input(event: InputEvent) -> void:
	# Mouse capturing
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		capture_mouse()
	if Input.is_key_pressed(KEY_ESCAPE):
		release_mouse()
	
	# Look around
	if mouse_captured and event is InputEventMouseMotion:
		rotate_look(event.relative)
	
	# Toggle freefly mode
	if can_freefly and Input.is_action_just_pressed(input_freefly):
		if not freeflying:
			enable_freefly()
		else:
			disable_freefly()

func _physics_process(delta: float) -> void:
	if is_dead == true:
		death_countdown += delta
		emit_signal("Update_Player_Death_Fade", (death_countdown / 1.5))
		if death_countdown >= 2.5:
			print("Releasing player")
			release_mouse()
			Switch_Scenes.Clear_Game_Return_To_UI("res://Levels/game_over.tscn")
		return
	
	var desired_sound = MoveSound.NONE
	
	# If freeflying, handle freefly and nothing else
	if can_freefly and freeflying:
		var input_dir := Input.get_vector(input_left, input_right, input_forward, input_back)
		var motion := (head.global_basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
		motion *= freefly_speed * delta
		move_and_collide(motion)
		return
	
	# Apply gravity to velocity
	if has_gravity:
		if not is_on_floor():
			velocity += get_gravity() * delta
			
	var Intersection_Query = PhysicsRayQueryParameters3D.create(Bottom_Cast.get_global_transform().origin,Top_Cast.get_global_transform().origin)
	Intersection_Query.exclude = [get_rid()]
	var Bullet_Collision = get_world_3d().direct_space_state.intersect_ray(Intersection_Query)
	var uncrouch_blocked = Bullet_Collision != { }
			
	# Crouch toggle on and off:
	if Input.is_action_pressed("Crouch") and is_crouched == false:
		Animation_Player.play("StartCrouch")
		is_crouched = true
	elif Input.is_action_pressed("Crouch") == false and uncrouch_blocked == false and is_crouched == true:
		Animation_Player.play("EndCrouch")
		is_crouched = false

	var speed_modifier = 1
	if is_crouched:
		speed_modifier = 0.5

	# Modify speed based on sprinting
	if can_sprint and Input.is_action_pressed(input_sprint):
		move_speed = sprint_speed * speed_modifier
	else:
		move_speed = base_speed * speed_modifier

	# Apply desired movement to velocity
	if can_move:
		var input_dir := Input.get_vector(input_left, input_right, input_forward, input_back)
		var move_dir := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
		var actual_speed = move_dir.length()
		if move_dir:
			velocity.x = move_dir.x * move_speed
			velocity.z = move_dir.z * move_speed
		else:
			velocity.x = move_toward(velocity.x, 0, move_speed)
			velocity.z = move_toward(velocity.z, 0, move_speed)
		if actual_speed != 0.0 and is_on_floor():
			if move_speed == base_speed:
				desired_sound = MoveSound.WALK
			else:
				desired_sound = MoveSound.RUN
	else:
		velocity.x = 0
		velocity.y = 0
	
	# Apply jumping
	if can_jump:
		if Input.is_action_just_pressed(input_jump) and is_on_floor():
			velocity.y = jump_velocity
			desired_sound = MoveSound.JUMP
	
	if was_on_floor == false and is_on_floor() == true:
		desired_sound = MoveSound.WALK
			
	# only change stream if state changed
	if desired_sound != current_move_sound:
		current_move_sound = desired_sound
		match desired_sound:
			MoveSound.JUMP:
				Audio_Player.stream = Start_Jump_Sfx
				Audio_Player.play()
			MoveSound.WALK:
				Audio_Player.stream = Walk_Sfx
				Audio_Player.play()
			MoveSound.RUN:
				Audio_Player.stream = Run_Sfx
				Audio_Player.play()
			MoveSound.NONE:
				pass
	
	was_on_floor = is_on_floor()
	
	Manage_Effects(delta)
	# Use velocity to actually move
	move_and_slide()


## Rotate us to look around.
## Base of controller rotates around y (left/right). Head rotates around x (up/down).
## Modifies look_rotation based on rot_input, then resets basis and rotates by look_rotation.
func rotate_look(rot_input : Vector2):
	look_rotation.x -= rot_input.y * look_speed
	look_rotation.x = clamp(look_rotation.x, deg_to_rad(-85), deg_to_rad(85))
	look_rotation.y -= rot_input.x * look_speed
	transform.basis = Basis()
	rotate_y(look_rotation.y)
	head.transform.basis = Basis()
	head.rotate_x(look_rotation.x)


func enable_freefly():
	collider.disabled = true
	freeflying = true
	velocity = Vector3.ZERO

func disable_freefly():
	collider.disabled = false
	freeflying = false


func capture_mouse():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	mouse_captured = true


func release_mouse():
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	mouse_captured = false


## Checks if some Input Actions haven't been created.
## Disables functionality accordingly.
func check_input_mappings():
	if can_move and not InputMap.has_action(input_left):
		push_error("Movement disabled. No InputAction found for input_left: " + input_left)
		can_move = false
	if can_move and not InputMap.has_action(input_right):
		push_error("Movement disabled. No InputAction found for input_right: " + input_right)
		can_move = false
	if can_move and not InputMap.has_action(input_forward):
		push_error("Movement disabled. No InputAction found for input_forward: " + input_forward)
		can_move = false
	if can_move and not InputMap.has_action(input_back):
		push_error("Movement disabled. No InputAction found for input_back: " + input_back)
		can_move = false
	if can_jump and not InputMap.has_action(input_jump):
		push_error("Jumping disabled. No InputAction found for input_jump: " + input_jump)
		can_jump = false
	if can_sprint and not InputMap.has_action(input_sprint):
		push_error("Sprinting disabled. No InputAction found for input_sprint: " + input_sprint)
		can_sprint = false
	if can_freefly and not InputMap.has_action(input_freefly):
		push_error("Freefly disabled. No InputAction found for input_freefly: " + input_freefly)
		can_freefly = false

func _on_movement_player_finished() -> void:
	current_move_sound = MoveSound.NONE
	
func Assign_Marker():
	var To_Return = Current_Marker_Assignment
	Current_Marker_Assignment += 1
	return To_Return
	
func Get_Marker_Pos(marker_idx):
	if marker_idx > len(Follow_Markers_List):
		return position
	return Follow_Markers_List[marker_idx].get_global_transform().origin

func Hit_Successful(Damage, _Direction:= Vector3.ZERO, _Position:= Vector3.ZERO, _Force_Modifier:= 1, _Origin_Player = null):
	if Invincible == true:
		return
	if is_dead == true:
		return
	
	Injury_Audio_Player.stream = Hit_Sfx
	Injury_Audio_Player.play()
	
	var Damage_Absorbed_By_Armor = min(Current_Armor, Damage)
	var Remainder_Damage = Damage - Damage_Absorbed_By_Armor
	Current_Armor -= Damage_Absorbed_By_Armor
	
	Current_Health -= Damage_Absorbed_By_Armor / 3
	Current_Health -= Remainder_Damage
	Current_Health = max(0, Current_Health)
	emit_signal("Update_Player_Health", Current_Health, Max_Health)
	emit_signal("Update_Player_Armor", Current_Armor)
	if Current_Health <= 0:
		can_move = false
		can_jump = false
		is_dead = true
		Item_Manager.Is_Dead = true
		Talking_Audio_Player.stream = Death_Sfx
		Talking_Audio_Player.play()

func Apply_Item_Stats(Effects, EffectTime):
	for Stat in Effects:
		var Current_Value = get(Stat)
		var Modification_Value = Effects[Stat]
		
		var Original_Value = Current_Value + Modification_Value
		
		var Updated_Value
		if Stats_Constraints.get(Stat) == null:
			Updated_Value = Original_Value
		else:
			var Maximum_Value = get(Stats_Constraints.get(Stat))
			Updated_Value = min(Maximum_Value, Original_Value)

		set(Stat, Updated_Value)
	emit_signal("Update_Player_Health", Current_Health, Max_Health)
	emit_signal("Update_Player_Armor", Current_Armor)
	
	if EffectTime > 0:
		var pair = [EffectTime, Effects]
		Active_Effects.append(pair)
		

func Manage_Effects(delta):
	for pair in Active_Effects:
		pair[0] -= delta
		if pair[0] < 0:
			var Effects = pair[1]
			for Stat in Effects:
				var Current_Value = get(Stat)
				var Modification_Value = Effects[Stat]
				set(Stat, Current_Value - Modification_Value)
			Active_Effects.erase(pair)
