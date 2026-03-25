extends RigidBody3D

@export var Current_Health: int
@export var Damage: int
@export var Explosion: PackedScene
var Source: Node3D

func _on_body_entered(body: Node) -> void:
	print(body)
	if body.is_in_group("Target") && body.has_method("Hit_Successful"):
		body.Hit_Successful(Damage)
	explode()
	
func explode():
	var Explosion_Instance = Explosion.instantiate()
	Explosion_Instance.Damage = 25
	Explosion_Instance.Source = Source
	var World = get_tree().get_root().get_child(0)
	Explosion_Instance.set_global_transform(global_transform)
	World.add_child(Explosion_Instance)
	
	await get_tree().create_timer(0.1).timeout
	queue_free()
	
func Hit_Successful(Damage, _Direction:= Vector3.ZERO, _Position:= Vector3.ZERO, _Force_Modifier:= 1, _Origin_Player = null):
	Current_Health -= Damage
	
	if Current_Health <= 0:
		queue_free()
