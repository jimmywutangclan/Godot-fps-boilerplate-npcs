extends Node3D

class SpawnGroup:
	var Route: Node3D
	var NPC_Types: Array[PackedScene]
	var NPC_Counts: Array[int]
	
	func _init(_Route: Node3D, _NPC_Types: Array[PackedScene], _NPC_Counts: Array[int]):
		Route = _Route
		NPC_Types = _NPC_Types
		NPC_Counts = _NPC_Counts

@export var Help_Screen: TextureRect
@export var Win_Screen: TextureRect
@export var Win_Audio_Player: AudioStreamPlayer2D

@export var Next_Scene: PackedScene
@export var NPC_Parent_Prefab: PackedScene
@export var Wave1_RouteGroup: Node3D
@export var Wave1_NPC_Types: Array[PackedScene]
@export var Wave1_NPC_Counts: Array[int]

@export var Wave2_RouteGroup: Node3D
@export var Wave2_NPC_Types: Array[PackedScene]
@export var Wave2_NPC_Counts: Array[int]

@export var Wave3_RouteGroup: Node3D
@export var Wave3_NPC_Types: Array[PackedScene]
@export var Wave3_NPC_Counts: Array[int]

@export var Wave4_RouteGroup: Node3D
@export var Wave4_NPC_Types: Array[PackedScene]
@export var Wave4_NPC_Counts: Array[int]

var Wave1: Array[SpawnGroup]
var Wave2: Array[SpawnGroup]
var Wave3: Array[SpawnGroup]
var Wave4: Array[SpawnGroup]
var Waves: Array
var Current_Wave: int = 1

var Current_Groups: Array
var Round_Over: bool
var Time_Elapsed: float
var Time_Since_Win: float
var Player: Node3D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# setup wave 1
	var Wave1Group = SpawnGroup.new(Wave1_RouteGroup, Wave1_NPC_Types, Wave1_NPC_Counts)
	Wave1 = [Wave1Group]
	
	# setup wave 2
	var Wave2Group = SpawnGroup.new(Wave2_RouteGroup, Wave2_NPC_Types, Wave2_NPC_Counts)
	Wave2 = [Wave2Group]
	
	# setup wave 3
	var Wave3Group = SpawnGroup.new(Wave3_RouteGroup, Wave3_NPC_Types, Wave3_NPC_Counts)
	Wave3 = [Wave3Group]
	
	# setup wave 4
	var Wave4Group = SpawnGroup.new(Wave4_RouteGroup, Wave4_NPC_Types, Wave4_NPC_Counts)
	Wave4 = [Wave4Group]
	
	Waves = [Wave1, Wave2, Wave3, Wave4]
	
	Current_Groups = []
	Round_Over = false
	Time_Elapsed = 0.0
	Time_Since_Win = 0.0
	
	Player = null


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	Time_Elapsed += delta
	if Time_Elapsed >= 5.0 and Help_Screen.visible == true:
		Help_Screen.visible = false
	
	if Round_Over == false:
		var All_Killed = true
		for Group in Current_Groups:
			if Group.get_child_count() != 0:
				All_Killed = false
		if All_Killed:
			Round_Over = true
			Win_Screen.visible = true
			Win_Audio_Player.play()
	else:
		Time_Since_Win += delta
		if Time_Since_Win > 5.0:
			print("Round over")
			Switch_Scenes.Clear_Instance_Return_To_Lobby(Player, Next_Scene.resource_path, "SpawnPoint1")

func Instantiate_Round(Wave_Number: int, _Player: Node3D):
	Player = _Player
	var Wave_Number_Rounded = Wave_Number - 1
	var Wave_To_Spawn = Waves[Wave_Number_Rounded]
	var rng = RandomNumberGenerator.new()
	
	for Wave_Group in Wave_To_Spawn:
		var Route_Group = Wave_Group.Route
		var NPC_Types = Wave_Group.NPC_Types
		var NPC_Counts = Wave_Group.NPC_Counts
		
		var NPC_Group = NPC_Parent_Prefab.instantiate()
		for i in range(NPC_Types.size()):
			var NPC_Type = NPC_Types[i]
			var NPC_Count = NPC_Counts[i]
			for j in range(NPC_Count):
				var Instantiated_Enemy = NPC_Type.instantiate()
				var Start_Goalpost_Index = rng.randi_range(0, Route_Group.get_child_count() - 1)
				var Start_Goalpost_Node = Route_Group.get_child(Start_Goalpost_Index)
				Instantiated_Enemy.Nav_Trail_Group = Route_Group
				Instantiated_Enemy.Start_Goalpost = Start_Goalpost_Index
				Instantiated_Enemy.Start_Reversed = (true if rng.randi_range(0, 1) == 1 else false)
				Instantiated_Enemy.position = Start_Goalpost_Node.get_global_transform().origin
				NPC_Group.add_child(Instantiated_Enemy)
		
		add_child(NPC_Group) # add NPC group to this scene(the to-be world scene) last since initialization time matters
		Current_Groups.append(NPC_Group)
