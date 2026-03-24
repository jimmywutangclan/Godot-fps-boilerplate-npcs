extends Node

@export var Limit_Recruitment: bool = false
@export var Limited_Recruitment_Count: int = 2

var NPC_Group: Array = []


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	for NPC in get_children():
		NPC_Group.append(NPC)
		NPC.Group = self

func Alert_All(Target):
	if Limit_Recruitment:
		var RNG = RandomNumberGenerator.new()
		var To_Recruit = []
		while To_Recruit.size() < min(Limited_Recruitment_Count, NPC_Group.size()):
			var index = RNG.randi_range(0, NPC_Group.size() - 1)
			if index not in To_Recruit:
				To_Recruit.append(index)
		
		for index in To_Recruit:
			var NPC = NPC_Group.get(index)	
			if NPC.Current_State != NPC.STATE.CHASE:
				NPC.Transition_Chase_No_Cascade(Target)
	else:
		for NPC in NPC_Group:
			if NPC.Current_State != NPC.STATE.CHASE:
				NPC.Transition_Chase(Target)

func Add_NPC(NPC):
	NPC_Group.append(NPC)
	NPC.Group = self

func Remove_Self(NPC):
	NPC_Group.erase(NPC)
