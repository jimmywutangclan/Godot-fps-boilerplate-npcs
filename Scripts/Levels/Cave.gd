extends Node

var Player: Node3D

class SpawnGroup:
	var Route: Node3D
	var NPC_Types: Array[PackedScene]
	var NPC_Counts: Array[int]
	var Stationary_NPC_Types: Array[PackedScene]
	var Stationary_NPC_Counts: Array[int]
	var Teleport: Node3D
	
	func _init(_Route: Node3D, _NPC_Types: Array[PackedScene], _NPC_Counts: Array[int], _Stationary_NPC_Types: Array[PackedScene], _Stationary_NPC_Counts: Array[int], _Teleport: Node3D):
		Route = _Route
		NPC_Types = _NPC_Types
		NPC_Counts = _NPC_Counts
		Stationary_NPC_Types = _Stationary_NPC_Types
		Stationary_NPC_Counts = _Stationary_NPC_Counts
		Teleport = _Teleport

@export var Next_Scene: PackedScene
@export var Route: Node3D
@export var Stationary_Points: Array[Node3D]

@export var NPC_Group: Node3D

@export var Wave1_NPC_Types: Array[PackedScene]
@export var Wave1_NPC_Counts: Array[int]
@export var Wave1_Stationary_NPC_Types: Array[PackedScene]
@export var Wave1_Stationary_NPC_Counts: Array[int]
@export var Wave1_Teleport: Node3D

@export var Wave2_NPC_Types: Array[PackedScene]
@export var Wave2_NPC_Counts: Array[int]
@export var Wave2_Stationary_NPC_Types: Array[PackedScene]
@export var Wave2_Stationary_NPC_Counts: Array[int]
@export var Wave2_Teleport: Node3D

@export var Wave3_NPC_Types: Array[PackedScene]
@export var Wave3_NPC_Counts: Array[int]
@export var Wave3_Stationary_NPC_Types: Array[PackedScene]
@export var Wave3_Stationary_NPC_Counts: Array[int]
@export var Wave3_Teleport: Node3D

@export var Wave4_NPC_Types: Array[PackedScene]
@export var Wave4_NPC_Counts: Array[int]
@export var Wave4_Stationary_NPC_Types: Array[PackedScene]
@export var Wave4_Stationary_NPC_Counts: Array[int]
@export var Wave4_Teleport: Node3D

@export var Help_Screen: TextureRect
@export var Win_Screen: TextureRect
@export var Win_Audio: AudioStreamPlayer2D

@export var Rarity: Node3D

var Current_Wave_Number: int
var Waves: Array
var Won: bool
var Time_Elapsed_Since_Start: float
var Time_Elapsed_Since_Win: float

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# setup wave 1
	var Wave1Group = SpawnGroup.new(Route, Wave1_NPC_Types, Wave1_NPC_Counts, Wave1_Stationary_NPC_Types, Wave1_Stationary_NPC_Counts, Wave1_Teleport)
	
	# setup wave 2
	var Wave2Group = SpawnGroup.new(Route, Wave2_NPC_Types, Wave2_NPC_Counts, Wave2_Stationary_NPC_Types, Wave2_Stationary_NPC_Counts, Wave2_Teleport)
	
	# setup wave 3
	var Wave3Group = SpawnGroup.new(Route, Wave3_NPC_Types, Wave3_NPC_Counts, Wave3_Stationary_NPC_Types, Wave3_Stationary_NPC_Counts, Wave3_Teleport)
	
	# setup wave 4
	var Wave4Group = SpawnGroup.new(Route, Wave4_NPC_Types, Wave4_NPC_Counts, Wave4_Stationary_NPC_Types, Wave4_Stationary_NPC_Counts, Wave4_Teleport)
	
	Waves = [Wave1Group, Wave2Group, Wave3Group, Wave4Group]
	Won = false
	Time_Elapsed_Since_Start = 0.0
	Time_Elapsed_Since_Win = 0.0

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	Time_Elapsed_Since_Start += delta
	if Help_Screen.visible == true and Time_Elapsed_Since_Start > 5.0:
		Help_Screen.visible = false
	if Won:
		Time_Elapsed_Since_Win += delta
		if Time_Elapsed_Since_Win >= 5.0:
			Player.Invincible = false
			Switch_Scenes.Clear_Instance_Return_To_Lobby(Player, Next_Scene.resource_path, "SpawnPoint1")

func Instantiate_Round(Wave_Number: int, _Player: Node3D):
	Player = _Player
	Rarity.Recruit(Player.get_node("Head").get_node("ItemManager"))
	Current_Wave_Number = Wave_Number - 1
	var Wave_Group = Waves[Current_Wave_Number]
	var rng = RandomNumberGenerator.new()
	
	var Route_Group = Wave_Group.Route
	var NPC_Types = Wave_Group.NPC_Types
	var NPC_Counts = Wave_Group.NPC_Counts
	var Stationary_NPC_Types = Wave_Group.Stationary_NPC_Types
	var Stationary_NPC_Counts = Wave_Group.Stationary_NPC_Counts
	
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
			NPC_Group.Add_NPC(Instantiated_Enemy)
			
	for i in range(Stationary_NPC_Types.size()):
		var NPC_Type = Stationary_NPC_Types[i]
		var NPC_Count = Stationary_NPC_Counts[i]
		for j in range(NPC_Count):
			var Instantiated_Enemy = NPC_Type.instantiate()
			var Station_Index = rng.randi_range(0, Stationary_Points.size() - 1)
			var Station_Point_Node = Stationary_Points.get(Station_Index)
			
			var Station_Point = Station_Point_Node.get_node("Standpoint")
			var Station_Point_Dir = Station_Point_Node.get_node("Direction")
			Instantiated_Enemy.Station_Point = Station_Point
			Instantiated_Enemy.Direction_To_Face = Station_Point_Dir
			Instantiated_Enemy.position = Station_Point.get_global_transform().origin
			NPC_Group.add_child(Instantiated_Enemy)
			NPC_Group.Add_NPC(Instantiated_Enemy)
			
	var Teleports_Choice = [Wave1_Teleport, Wave2_Teleport, Wave3_Teleport]
	var Teleport_Selected_Index = rng.randi_range(0 , Teleports_Choice.size() - 1)
	var Teleport = Teleports_Choice[Teleport_Selected_Index]
			
	Teleport.visible = true
	Teleport.Cave_Portal_Found.connect(_on_teleport_target_reached)
	
func _on_teleport_target_reached():
	if Won == false:
		Player.Invincible = true
		Won = true
		Win_Screen.visible = true
		Win_Audio.play()
	
func _on_timer_timeout() -> void: # punishment with a second wave
	print("You wasted too much, reinforcements have arrived")
	var Wave_Group = Waves[Current_Wave_Number]
	var rng = RandomNumberGenerator.new()
	
	var Route_Group = Wave_Group.Route
	var NPC_Types = Wave_Group.NPC_Types
	var NPC_Counts = Wave_Group.NPC_Counts
	var Stationary_NPC_Types = Wave_Group.Stationary_NPC_Types
	var Stationary_NPC_Counts = Wave_Group.Stationary_NPC_Counts
	
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
			NPC_Group.Add_NPC(Instantiated_Enemy)
			
	for i in range(Stationary_NPC_Types.size()):
		var NPC_Type = Stationary_NPC_Types[i]
		var NPC_Count = Stationary_NPC_Counts[i]
		for j in range(NPC_Count):
			var Instantiated_Enemy = NPC_Type.instantiate()
			var Station_Index = rng.randi_range(0, Stationary_Points.size() - 1)
			var Station_Point_Node = Stationary_Points.get(Station_Index)
			
			var Station_Point = Station_Point_Node.get_node("Standpoint")
			var Station_Point_Dir = Station_Point_Node.get_node("Direction")
			Instantiated_Enemy.Station_Point = Station_Point
			Instantiated_Enemy.Direction_To_Face = Station_Point_Dir
			Instantiated_Enemy.position = Station_Point.get_global_transform().origin
			NPC_Group.add_child(Instantiated_Enemy)
			NPC_Group.Add_NPC(Instantiated_Enemy)
