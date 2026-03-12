extends RigidBody3D

@export var Current_Health: int
@export var Maximum_Health: int

@export var Audio_Player: AudioStreamPlayer3D
@export var Bump_Sfx: AudioStreamMP3
@export var Destroy_Sfx: AudioStreamMP3

func Hit_Successful(Damage, _Direction:= Vector3.ZERO, _Position:= Vector3.ZERO, _Force_Modifier:= 1, _Origin_Player = null):
	var Hit_Position = _Position - get_global_transform().origin
	Current_Health -= Damage
	
	if Current_Health <= 0:
		Audio_Player.stream = Destroy_Sfx
		Audio_Player.play()
		queue_free()
		
	if _Direction != Vector3.ZERO:
		apply_impulse((_Direction*Damage * _Force_Modifier), Hit_Position)


func _on_body_entered(body: Node) -> void:
	Audio_Player.stream = Bump_Sfx
	Audio_Player.play()
