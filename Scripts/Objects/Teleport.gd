extends Node

@export var Next_Scene_Name: String
@export var Spawn_Point_Name: String
var Next_Scene_Path: String

func _ready():
	Next_Scene_Path = "res://Levels/" + Next_Scene_Name + ".tscn"
	pass

func _on_body_entered(Player: Node3D) -> void:
	Switch_Scenes.Transition_Scene_Persisted(Player, Next_Scene_Path, Spawn_Point_Name)
