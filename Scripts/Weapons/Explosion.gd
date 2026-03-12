extends Node3D

@export var Damage: int
@export var Force_Modifier: float

@export var Audio_Player: AudioStreamPlayer3D
@export var Explode_Sfx: AudioStreamMP3

var Source: Node3D

func _ready():
	Audio_Player.stream = Explode_Sfx
	Audio_Player.play()

func _on_timer_timeout() -> void:
	queue_free()

func _on_body_entered(node: Node3D) -> void:
	if node is RigidBody3D:
		var Explosion_Dir = (node.get_global_transform().origin - global_transform.origin).normalized()
		node.apply_impulse((Explosion_Dir*Damage * Force_Modifier), node.get_global_transform().origin)	
	if node.is_in_group("Target"):
		node.Hit_Successful(Damage, Vector3.ZERO, Vector3.ZERO, 1, Source)
