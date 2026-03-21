extends Node

class Wave:
	var Enemies: Array[PackedScene]
	var EnemyCounts: Array[int]
	var SpawnInterval: float
	
	func _init(_Enemies: Array[PackedScene], _EnemyCounts: Array[int], _SpawnInterval: float):
		Enemies = _Enemies
		EnemyCounts = _EnemyCounts
		SpawnInterval = _SpawnInterval

@export var Wave1Enemies: Array[PackedScene]
@export var Wave1EnemyCounts: Array[int]
@export var Wave1Interval: float

@export var Wave2Enemies: Array[PackedScene]
@export var Wave2EnemyCounts: Array[int]
@export var Wave2Interval: float

@export var Wave3Enemies: Array[PackedScene]
@export var Wave3EnemyCounts: Array[int]
@export var Wave3Interval: float

@export var Wave4Enemies: Array[PackedScene]
@export var Wave4EnemyCounts: Array[int]
@export var Wave4Interval: float

@export var Next_Scene: PackedScene
@export var NPC_Group_Prefab: PackedScene
@export var Spawnpoints: Node3D
@export var Patrol_Route_Nodes: Node3D

@export var Help_Screen: TextureRect
@export var Win_Screen: TextureRect
@export var Win_Audio_Player: AudioStreamPlayer2D

var Waves: Array[Wave]

var Current_Wave_Spawnable: Array
var Current_Interval: float
var Time_Elapsed: float
var Time_Elapsed_Since_Last_Spawn: float
var Round_Started: bool
var RNG: RandomNumberGenerator
var NPC_Group: Node3D
var Won: bool
var Time_Since_Win: float

var Player: Node3D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Waves.append(Wave.new(Wave1Enemies, Wave1EnemyCounts, Wave1Interval))
	Waves.append(Wave.new(Wave2Enemies, Wave2EnemyCounts, Wave2Interval))
	Waves.append(Wave.new(Wave3Enemies, Wave3EnemyCounts, Wave3Interval))
	Waves.append(Wave.new(Wave4Enemies, Wave4EnemyCounts, Wave4Interval))
	
	RNG = RandomNumberGenerator.new()
	Time_Elapsed = 0.0
	Current_Wave_Spawnable = []
	Current_Interval = 0.0
	Time_Elapsed_Since_Last_Spawn = 0.0
	Round_Started = false
	Won = false
	Time_Since_Win = 0.0


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	Time_Elapsed += delta
	if Time_Elapsed >= 5.0 and Help_Screen.visible == true:
		Help_Screen.visible = false
	
	if Round_Started == true and Won == true:
		Time_Since_Win += delta
		if Time_Since_Win > 5.0:
			Switch_Scenes.Clear_Instance_Return_To_Lobby(Player, Next_Scene.resource_path, "SpawnPoint1")
	elif Round_Started:
		if Current_Wave_Spawnable.size() > 0:
			Time_Elapsed_Since_Last_Spawn += delta
			if Time_Elapsed_Since_Last_Spawn > Current_Interval:
				# Select spawnpoint
				var Spawnpoint_Index = RNG.randi_range(0, Spawnpoints.get_child_count()-1)
				var Spawnpoint = Spawnpoints.get_child(Spawnpoint_Index)
				
				# Spawn enemy
				var Selected_Enemy_Index = RNG.randi_range(0, Current_Wave_Spawnable.size()-1)
				var Selected_Enemy = Current_Wave_Spawnable.get(Selected_Enemy_Index)
				var Created_Enemy = Selected_Enemy.instantiate()
				Current_Wave_Spawnable.remove_at(Selected_Enemy_Index)
				Created_Enemy.Nav_Trail_Group = Patrol_Route_Nodes
				Created_Enemy.Start_Goalpost = 0
				Created_Enemy.Start_Reversed = false
				Created_Enemy.position = Spawnpoint.get_global_transform().origin
				
				NPC_Group.add_child(Created_Enemy)
				NPC_Group.Add_NPC(Created_Enemy)
				
				Time_Elapsed_Since_Last_Spawn = 0.0
		else:
			if NPC_Group.get_child_count() == 0:
				Won = true
				Win_Screen.visible = true
				Win_Audio_Player.play()

func Instantiate_Round(Wave_Number: int, _Player: Node3D):
	Player = _Player
	NPC_Group = NPC_Group_Prefab.instantiate()
	
	var Wave_Number_Index = Wave_Number - 1
	var Current_Wave = Waves[Wave_Number_Index]
	Current_Interval = Current_Wave.SpawnInterval
	
	for i in range(Current_Wave.Enemies.size()):
		var Enemy_Type = Current_Wave.Enemies[i]
		var Enemy_Count = Current_Wave.EnemyCounts[i]
		
		for c in range(Enemy_Count):
			Current_Wave_Spawnable.append(Enemy_Type)
			
	add_child(NPC_Group)
	Round_Started = true
	
	
