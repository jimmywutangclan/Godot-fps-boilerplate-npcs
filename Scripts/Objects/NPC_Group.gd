extends Node

var NPC_Group: Array = []


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	for NPC in get_children():
		NPC_Group.append(NPC)
		NPC.Group = self

func Alert_All(Target):
	for NPC in NPC_Group:
		if NPC.Current_State != NPC.STATE.CHASE:
			NPC.Transition_Chase(Target)

func Remove_Self(NPC):
	NPC_Group.erase(NPC)
