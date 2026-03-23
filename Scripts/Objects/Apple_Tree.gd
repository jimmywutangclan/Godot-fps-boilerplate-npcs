extends Node

signal Apple_Picked

var Ripe: bool = false
@export var Ripe_Tree: Sprite3D
@export var Unripe_Tree: Sprite3D
@export var Audio_Player: AudioStreamPlayer3D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func Set_Ripe():
	Ripe = true
	Ripe_Tree.visible = true
	Unripe_Tree.visible = false

func Buck_Tree():
	if Ripe:
		print("picking tree")
		Ripe = false
		Ripe_Tree.visible = false
		Unripe_Tree.visible = true
		Audio_Player.play()
		emit_signal("Apple_Picked")
