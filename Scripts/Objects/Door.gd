extends Node

@export var Animation_Player: AnimationPlayer
@export var Audio_Player: AudioStreamPlayer3D
@export var Audio: AudioStreamMP3
@export var Start_Open: bool = false

var Action_Locked: bool
var Is_Open: bool

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if Start_Open:
		Animation_Player.play("OpenDoor")
	Action_Locked = false
	Is_Open = Start_Open

func Interact():
	if Is_Open == true:
		Close()
	else:
		Open()

func Open():
	if Action_Locked == false:
		Animation_Player.play("OpenDoor")
		Audio_Player.stream = Audio
		Audio_Player.play()
		Action_Locked == true
		Is_Open = true
		
func Close():
	if Action_Locked == false:
		Animation_Player.play("CloseDoor")
		Audio_Player.stream = Audio
		Audio_Player.play()
		Action_Locked == true
		Is_Open = false

func _on_animation_player_current_animation_changed(name: StringName) -> void:
	Action_Locked == false
