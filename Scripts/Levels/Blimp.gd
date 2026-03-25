extends Node

@export var Help_Screen: TextureRect
@export var Win_Screen: TextureRect
@export var Win_Sound: AudioStreamPlayer2D
@export var Next_Scene: PackedScene

@export var Shootpoints: Array[Node3D]

@export var Explosion_Decal: PackedScene
@export var Cannonball: PackedScene
@export var Cannonball_Speed: Array[float]
@export var Wave_Time: Array[float]
@export var Wave_Interval: Array[float]

@export var Dash: Node3D
var Player: Node3D

var Current_Cannonball_Speed: float
var Current_Wave_Time_Limit: float
var Time_Between_Cannonballs: float

var Round_Started: bool
var Shooting_Started: bool
var Time_Elapsed_Since_Round_Started: float
var Round_Won: bool
var Time_Elapsed_Since_Round_Won: float
var Time_Elapsed_Since_Shot: float
var RNG: RandomNumberGenerator

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Round_Started = false
	Shooting_Started = false
	Time_Elapsed_Since_Round_Started = 0.0
	Round_Won = false
	Time_Elapsed_Since_Round_Won = 0.0
	Time_Elapsed_Since_Shot = 0.0
	RNG = RandomNumberGenerator.new()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if Round_Started:
		Time_Elapsed_Since_Round_Started += delta
		if Time_Elapsed_Since_Round_Started > Current_Wave_Time_Limit + 5.0:
			if Round_Won == false:
				Round_Won = true
				Win_Screen.visible = true
				Win_Sound.play()
			Time_Elapsed_Since_Round_Won += delta
			if Time_Elapsed_Since_Round_Won >= 5.0:
				Switch_Scenes.Clear_Instance_Return_To_Lobby(Player, Next_Scene.resource_path, "SpawnPoint1")
		else:
			if Time_Elapsed_Since_Round_Started >= 5.0:
				if Shooting_Started == false:
					Help_Screen.visible = false
					Shooting_Started = true

				Time_Elapsed_Since_Shot += delta
				if Time_Elapsed_Since_Shot > Time_Between_Cannonballs:
					var Shootpoint_Selected_Idx = RNG.randi_range(0, Shootpoints.size() - 1)
					var Shootpoint_Selected = Shootpoints.get(Shootpoint_Selected_Idx).get_global_transform().origin
					var Target = Player.get_global_transform().origin
					var Direction = (Target - Shootpoint_Selected).normalized()
					
					var Instiatiated_Explosion_Decal = Explosion_Decal.instantiate()
					var Instantiated_Cannonball = Cannonball.instantiate()
					Instiatiated_Explosion_Decal.global_position = Shootpoint_Selected
					Instantiated_Cannonball.global_position = Shootpoint_Selected
					Instantiated_Cannonball.set_linear_velocity(Direction * Current_Cannonball_Speed)
					Instantiated_Cannonball.look_at(Target, Vector3.UP)
					var Audio_Player = Shootpoints.get(Shootpoint_Selected_Idx).get_child(0)
					print(Audio_Player)
					Audio_Player.play()
					Shootpoints.get(Shootpoint_Selected_Idx).add_child(Instantiated_Cannonball)
					Shootpoints.get(Shootpoint_Selected_Idx).add_child(Instiatiated_Explosion_Decal)
					
					Time_Elapsed_Since_Shot = 0.0

func Instantiate_Round(Wave_Number: int, _Player: Node3D):
	Player = _Player
	
	var Wave_Index = Wave_Number - 1
	var Wave_Cannonball_Speed = Cannonball_Speed.get(Wave_Index)
	var Wave_Wave_Time = Wave_Time.get(Wave_Index)
	var Wave_Cannonball_Interval = Wave_Interval.get(Wave_Index)
	
	Current_Cannonball_Speed = Wave_Cannonball_Speed
	Current_Wave_Time_Limit = Wave_Wave_Time
	Time_Between_Cannonballs = Wave_Cannonball_Interval
	
	Dash.Recruit(Player.get_node("Head").get_node("ItemManager"))
	Round_Started = true

	
