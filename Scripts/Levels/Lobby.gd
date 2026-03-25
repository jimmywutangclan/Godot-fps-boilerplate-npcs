extends Node

@export var Teleporter: Node3D
@export var Available_Level_Names = []
var Completed_Levels: Array[String] = []
var Current_Level: String = ""
var Won: bool

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Select_Next_Level()
	Won = false

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if Won:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		Switch_Scenes.Clear_Game_Return_To_UI("res://Levels/You_Won.tscn") 

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
	Completed_Levels = []
	print("Tier is now " + str(Switch_Scenes.Current_Wave))
	if Switch_Scenes.Current_Wave > 3:
		print("You won!") # TODO: transition straight to victory scene by clearing UI with win screen
		Won = true
	# TODO: Spawn the supplies for finishing your tier
	Select_Next_Level()
