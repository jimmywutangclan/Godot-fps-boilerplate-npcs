extends Node

signal Cave_Portal_Found

@export var Audio_Player: AudioStreamPlayer3D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

# Handle round completion
func _on_body_entered(body: Node3D) -> void:
	emit_signal("Cave_Portal_Found")


func _on_audio_stream_player_3d_finished() -> void:
	Audio_Player.play()
