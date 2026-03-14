extends Node

@export var Player: PackedScene
@export var Start_Level: PackedScene
@export var Spawn_Point: String

func _on_start_game_pressed() -> void:
	var Player_Node = Player.instantiate()
	Switch_Scenes.Transition_Scenes(Player_Node, Start_Level.resource_path, Spawn_Point)

func _on_exit_pressed() -> void:
	get_tree().quit()
