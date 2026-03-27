extends Node

func _on_start_game_pressed() -> void:
	Switch_Scenes.Clear_Game_Return_To_UI("res://Levels/Lore.tscn")

func _on_exit_pressed() -> void:
	get_tree().quit()
