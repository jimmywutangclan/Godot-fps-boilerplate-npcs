extends StaticBody3D

@export var Current_Health: int
@export var Maximum_Health: int

func Hit_Successful(Damage, _Direction:= Vector3.ZERO, _Position:= Vector3.ZERO, _Force_Modifier:= 1, _Origin_Player = null):
	Current_Health -= Damage
	
	if Current_Health <= 0:
		queue_free()
