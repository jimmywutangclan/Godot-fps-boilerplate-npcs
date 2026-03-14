extends Node

var Cached_Scenes: Dictionary = {}
var Current_Scene_Name = ""

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass

func Get_Current_Scene(): # load current scene
	var Root = get_tree().root
	return Root.get_child(-1)

func Transition_Scenes(Player, Next_Scene_Path, Target_Spawn):
	Deferred_Switch_Scene.call_deferred(Player, Next_Scene_Path, Target_Spawn)

func Deferred_Switch_Scene(Player, Next_Scene_Path, Target_Spawn):
	var Current_Scene = Get_Current_Scene()
	
	get_tree().root.remove_child(Current_Scene)
	Current_Scene.free()
	Current_Scene = null
	
	# create the new scene
	var Next_Scene = ResourceLoader.load(Next_Scene_Path).instantiate()
	var Target_Spawnpoint_Node = Next_Scene.get_node(Target_Spawn)
	Next_Scene.add_child(Player)
	Player.position = Target_Spawnpoint_Node.get_global_transform().origin

	Current_Scene_Name = Next_Scene_Path
	Cached_Scenes[Current_Scene_Name] = Next_Scene
	
	get_tree().root.add_child(Next_Scene)
	
func Transition_Scene_Persisted(Player, Next_Scene_Path, Target_Spawn):
	Deferred_Switch_Scene_Persisted.call_deferred(Player, Next_Scene_Path, Target_Spawn)
	
func Deferred_Switch_Scene_Persisted(Player, Next_Scene_Path, Target_Spawn):
	var Current_Scene = Get_Current_Scene()
	if Current_Scene_Name != "":
		Cached_Scenes[Current_Scene_Name] = Current_Scene
	Current_Scene_Name = Next_Scene_Path
	
	# persist player independently before deactivating the scene
	Player.get_parent().remove_child(Player)
	get_tree().root.remove_child(Current_Scene)
	
	# create the new scene
	var Next_Scene
	if Next_Scene_Path not in Cached_Scenes:
		Next_Scene = ResourceLoader.load(Next_Scene_Path).instantiate()
	else:
		Next_Scene = Cached_Scenes[Next_Scene_Path]
	
	var Target_Spawnpoint_Node = Next_Scene.get_node(Target_Spawn)
	Next_Scene.add_child(Player)
	Player.position = Target_Spawnpoint_Node.get_global_transform().origin
	
	get_tree().root.add_child(Next_Scene)

func Switch_To_UI(UI_Scene_Path):
	Deferred_Switch_To_UI.call_deferred(UI_Scene_Path)

func Deferred_Switch_To_UI(UI_Scene_Path):
	var Current_Scene = Get_Current_Scene()
	var Current_Scene_Freed = false
	
	for Scene_Name in Cached_Scenes:
		if Cached_Scenes[Scene_Name] == Current_Scene:
			Current_Scene_Freed = true
		Cached_Scenes[Scene_Name].free()
		
	Cached_Scenes = {}

	if Current_Scene_Freed == false:
		Current_Scene.free()
	
	var Next_Scene = ResourceLoader.load(UI_Scene_Path).instantiate()
	get_tree().root.add_child(Next_Scene)
	
