extends Node

@export var Player: PackedScene
@export var Start_Level: PackedScene

func _on_button_pressed() -> void:
	var Player_Node = Player.instantiate()
	Switch_Scenes.Discard_Previous_Persist_Current_Scene(Player_Node, Start_Level.resource_path, "SpawnPoint1")
