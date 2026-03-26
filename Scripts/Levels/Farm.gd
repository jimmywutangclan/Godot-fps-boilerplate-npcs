extends Node

class Wave:
	var Enemies: Array[PackedScene]
	var EnemyWeights: Array[int]
	var SpawnInterval: float
	
	func _init(_Enemies: Array[PackedScene], _EnemyWeights: Array[int], _SpawnInterval: float):
		Enemies = _Enemies
		EnemyWeights = _EnemyWeights
		SpawnInterval = _SpawnInterval

@export var Next_Scene: PackedScene

@export var Wave1Enemies: Array[PackedScene]
@export var Wave1EnemyWeights: Array[int]
@export var Wave1Interval: float

@export var Wave2Enemies: Array[PackedScene]
@export var Wave2EnemyWeights: Array[int]
@export var Wave2Interval: float

@export var Wave3Enemies: Array[PackedScene]
@export var Wave3EnemyWeights: Array[int]
@export var Wave3Interval: float

@export var Wave4Enemies: Array[PackedScene]
@export var Wave4EnemyWeights: Array[int]
@export var Wave4Interval: float

@export var Trees: Array[Node3D]
@export var Ripe_Trees: int

# below 3 are tightly coupled together
@export var Spawn_Points: Array[Node3D]
@export var Patrol_Groups: Array[Node3D]
@export var NPC_Groups: Array[Node3D]

@export var Win_Sound: AudioStreamPlayer2D
@export var Win_Screen: TextureRect
@export var Help_Text1: TextureRect
@export var Help_Text2: TextureRect

@export var Applejack: Node3D
@export var Big_Mac: Node3D

var RNG: RandomNumberGenerator

var Ripe_Trees_Left: int
var Round_Started: bool
var Player: Node3D
var Current_Interval: float
var Time_Elapsed: float
var Time_Elapsed_Since_Last_Spawn: float
var Time_Since_Final_Stage: float
var Time_Since_Win: float
var Waves: Array
var Current_Wave_Spawnable: Array

var In_Final_Stage: bool
var Won: bool

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	RNG = RandomNumberGenerator.new()
	
	Waves = []
	Waves.append(Wave.new(Wave1Enemies, Wave1EnemyWeights, Wave1Interval))
	Waves.append(Wave.new(Wave2Enemies, Wave2EnemyWeights, Wave2Interval))
	Waves.append(Wave.new(Wave3Enemies, Wave3EnemyWeights, Wave3Interval))
	Waves.append(Wave.new(Wave4Enemies, Wave4EnemyWeights, Wave4Interval))
	
	Ripe_Trees_Left = Ripe_Trees
	Round_Started = false
	Current_Interval = 0.0
	Time_Elapsed_Since_Last_Spawn = 0.0
	Time_Since_Win = 0.0
	Time_Since_Final_Stage = 0.0
	Won = false
	In_Final_Stage= false


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	Time_Elapsed += delta
	if Time_Elapsed > 5.0 and Help_Text1.visible == true:
		Help_Text1.visible = false
	
	if Round_Started and Won:
		Time_Since_Win += delta
		if Time_Since_Win > 5.0:
			Player.Invincible = false
			Switch_Scenes.Clear_Instance_Return_To_Lobby(Player, Next_Scene.resource_path, "SpawnPoint1")
	elif Round_Started and In_Final_Stage:
		Time_Since_Final_Stage += delta
		if Time_Since_Final_Stage > 5.0 and Help_Text2.visible == true:
			Help_Text2.visible = false
	elif Round_Started:
		Time_Elapsed_Since_Last_Spawn += delta
		if Time_Elapsed_Since_Last_Spawn > Current_Interval:
			# Select spawnpoint
			var Spawnpoint_Index = RNG.randi_range(0, Spawn_Points.size()-1)
			var Spawnpoint = Spawn_Points.get(Spawnpoint_Index)
			var Patrol_Nodes = Patrol_Groups.get(Spawnpoint_Index)
			var Spawned_NPC_Group = NPC_Groups.get(Spawnpoint_Index)
			
			# Spawn enemy
			var Selected_Enemy_Index = RNG.randi_range(0, Current_Wave_Spawnable.size()-1)
			var Selected_Enemy = Current_Wave_Spawnable.get(Selected_Enemy_Index)
			var Created_Enemy = Selected_Enemy.instantiate()
			Created_Enemy.Nav_Trail_Group = Patrol_Nodes
			Created_Enemy.Start_Goalpost = 0
			Created_Enemy.Start_Reversed = false
			Created_Enemy.position = Spawnpoint.get_global_transform().origin
			
			Spawned_NPC_Group.add_child(Created_Enemy)
			Spawned_NPC_Group.Add_NPC(Created_Enemy)
			
			Time_Elapsed_Since_Last_Spawn = 0

func Handle_Bucked_Tree():
	print("Tree bucked")
	Ripe_Trees_Left -= 1
	if Ripe_Trees_Left == 0:
		In_Final_Stage = true
		Help_Text2.visible = true

func Instantiate_Round(Wave_Number: int, _Player: Node3D):
	Player = _Player
	Applejack.Recruit(Player.get_node("Head").get_node("ItemManager"))
	Big_Mac.Recruit(Player.get_node("Head").get_node("ItemManager"))
	
	var Wave_Number_Index = Wave_Number - 1
	var Current_Wave = Waves[Wave_Number_Index]
	Current_Interval = Current_Wave.SpawnInterval
	Current_Wave_Spawnable = []
	
	for i in range(Current_Wave.Enemies.size()):
		var Enemy_Type = Current_Wave.Enemies[i]
		var Enemy_Weight = Current_Wave.EnemyWeights[i]
		
		for c in range(Enemy_Weight):
			Current_Wave_Spawnable.append(Enemy_Type)
			
	var Ripe_Tree_Indices_Chosen = []
	while Ripe_Tree_Indices_Chosen.size() < Ripe_Trees:
		var Selected_Index = RNG.randi_range(0, Trees.size() - 1)
		if Selected_Index not in Ripe_Tree_Indices_Chosen:
			Ripe_Tree_Indices_Chosen.append(Selected_Index)
		else:
			continue
			
	for Tree_Index in Ripe_Tree_Indices_Chosen:
		var Ripened_Tree = Trees.get(Tree_Index)
		Ripened_Tree.Set_Ripe()
		Ripened_Tree.Apple_Picked.connect(Handle_Bucked_Tree)
		
	print(Ripe_Tree_Indices_Chosen)
		
	Round_Started = true


func _on_win_area_body_entered(body: Node3D) -> void:
	print(body)
	if In_Final_Stage == true and body.is_in_group("Player"):
		Won = true
		Player.Invincible = true
		Win_Screen.visible = true
		Win_Sound.play()
		
