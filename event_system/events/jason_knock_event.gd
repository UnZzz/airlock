class_name JasonKnockEvent
extends StoryEvent

@export
var food_gain : int = 2


func can_trigger() -> bool:
	return super.can_trigger() and not EventManager.guest_aboard


func _start() -> void:
	var allow : EventOption = _option("option_allow", "allow")
	allow.food_change = food_gain
	var deny : EventOption = _option("option_deny", "deny")
	deny.food_change = food_gain
	_show(story_text("description"), [allow, deny])


func choose(option: EventOption) -> void:
	option.apply()
	if option.action == "allow":
		EventManager.admit_guest()
	_finish("")
