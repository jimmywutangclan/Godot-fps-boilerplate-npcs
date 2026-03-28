extends Node

@export var Item_Stash_Spawns: Array[Node3D]
@export var Item_Stashes: Array[PackedScene]
@export var Teleporter: Node3D
@export var Available_Level_Names = []
var Completed_Levels: Array[String] = []
var Current_Level: String = ""
var Won: bool

@export var Wave_Override: int = -1
var Overriden: bool

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Select_Next_Level()
	Won = false
	Spawn_Wave_Item_Stash(0)
	if Wave_Override != -1:
		for i in range(1, Wave_Override):
			Spawn_Wave_Item_Stash(i)
	Overriden = false

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if Overriden == false and Wave_Override != -1:
		print("Overriding wave")
		Switch_Scenes.Current_Wave = Wave_Override
		Overriden = true
	if Won:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		Switch_Scenes.Clear_Game_Return_To_UI("res://Levels/You_Won.tscn") 

func Spawn_Wave_Item_Stash(level_index: int):
	var Level_Item_Stash = Item_Stashes.get(level_index).instantiate()
	var Level_Item_Spawn = Item_Stash_Spawns.get(level_index)
	Level_Item_Spawn.add_child(Level_Item_Stash)

func Select_Next_Level():
	var Incomplete = []
	for Level in Available_Level_Names:
		if Level not in Completed_Levels:
			Incomplete.append(Level)
	var Random_Index = randi() % Incomplete.size()
	Current_Level = Incomplete[Random_Index]
	Teleporter.Set_Next_Scene(Current_Level, "SpawnPoint1")
	
func Complete_Level():
	Completed_Levels.append(Current_Level)
	if Completed_Levels.size() == Available_Level_Names.size():
		Increase_Difficulty_Tier()
	else:
		Select_Next_Level()

func Increase_Difficulty_Tier():
	Switch_Scenes.Current_Wave += 1
	Spawn_Wave_Item_Stash(Switch_Scenes.Current_Wave - 1)
	Completed_Levels = []
	print("Tier is now " + str(Switch_Scenes.Current_Wave))
	if Switch_Scenes.Current_Wave > 3:
		print("You won!") # TODO: transition straight to victory scene by clearing UI with win screen
		Won = true
	# TODO: Spawn the supplies for finishing your tier
	Select_Next_Level()
