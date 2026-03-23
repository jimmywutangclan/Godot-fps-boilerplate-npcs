extends Node

class Wave:
	var Enemies: Array[PackedScene]
	var EnemyWeights: Array[int]
	var SpawnInterval: float
	
	func _init(_Enemies: Array[PackedScene], _EnemyWeights: Array[int], _SpawnInterval: float):
		Enemies = _Enemies
		EnemyWeights = _EnemyWeights
		SpawnInterval = _SpawnInterval

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

var Ripe_Trees_Left: int
var Round_Started: bool
var Player: Node3D
var Current_Interval: float
var Time_Elapsed: float
var Time_Elapsed_Since_Last_Spawn: float
var Time_Since_Win: float
var Waves: Array
var Current_Wave_Spawnable: Array
var Won: bool

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
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
	Won = false


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	Time_Elapsed += delta
	if Round_Started and Won:
		Time_Since_Win += delta
	elif Round_Started:
		Time_Elapsed_Since_Last_Spawn += delta

func Handle_Bucked_Tree():
	print("Tree bucked")
	Ripe_Trees_Left -= 1

func Instantiate_Round(Wave_Number: int, _Player: Node3D):
	Player = _Player
	var RNG = RandomNumberGenerator.new()
	
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
