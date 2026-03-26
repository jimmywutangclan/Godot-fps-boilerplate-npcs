extends Node

@export var Thumbnail: Texture2D
@export var Effects: Dictionary # key: Player property, value: Amount
@export var EffectTime: int
@export var Spawn_On_Drop: PackedScene
@export var Consume_Sound: AudioStreamMP3

@export var Item_Name: String = "Consumable"

func On_Open():
	pass

func Shoot():
	var Target = get_parent().get_parent().get_parent().get_parent().get_parent()
	var Item_Manager = Target.Item_Manager
	Target.Apply_Item_Stats(Effects, EffectTime)
	Target.Talking_Audio_Player.stream = Consume_Sound
	Target.Talking_Audio_Player.play()
	
	Item_Manager.Release_Item_Slot(self)
	
func Reload():
	pass

func Get_Stats():
	return [0, 0, 0]
	
func Setup_With_Stats(Stats):
	pass
