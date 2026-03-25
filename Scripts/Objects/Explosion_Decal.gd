extends Node3D

func _ready():
	pass

func _on_timer_timeout() -> void:
	queue_free()
