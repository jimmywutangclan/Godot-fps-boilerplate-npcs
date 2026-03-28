extends RigidBody3D

@export var Damage: int
var Source: Node3D

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("Target") && body.has_method("Hit_Successful"):
		body.Hit_Successful(Damage)
	explode()

func _on_timer_timeout() -> void:
	explode()
	
func explode():
	queue_free()
