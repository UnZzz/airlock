class_name SawdustMealEvent
extends StoryEvent

@export
var elias_food_gain : int = 5
@export
var elias_sick_chance : float = 0.3
@export
var voss_food_gain : int = 3
@export
var compensation_food : int = 1
@export
var compensation_mouthwash : int = 1
@export
var nonsense_loyalty_change : int = 1

var pending_plan : String = ""


func _start() -> void:
	pending_plan = ""
	_show(story_text("description"), [
		_option("option_elias", "elias"),
		_option("option_voss", "voss"),
		_option("option_nonsense", "nonsense"),
	])


func choose(option: EventOption) -> void:
	match option.action:
		"elias":
			_elias_plan()
		"voss", "nonsense":
			pending_plan = option.action
			_show_complaint()
		"pay":
			option.apply()
			_other_plan()


func _show_complaint() -> void:
	var food : EventOption = _option("complaint_food", "pay")
	food.food_change = -compensation_food
	var mouthwash : EventOption = _option("complaint_mouthwash", "pay")
	mouthwash.mouthwash_change = -compensation_mouthwash
	_show(story_text("complaint"), [food, mouthwash, _option("complaint_give_in", "elias")])


func _elias_plan() -> void:
	Inventory.apply_change(elias_food_gain, 0)
	var lines : Array[String] = []
	for member in _ordered_passengers():
		if not Crew.is_sick(member.member_id) and randf() < elias_sick_chance:
			Crew.make_sick(member.member_id)
			lines.append(Journal.text("event_sick", {"name": member.display_name}))
	_finish("\n\n".join(lines))


func _other_plan() -> void:
	if pending_plan == "voss":
		Inventory.apply_change(voss_food_gain, 0)
	else:
		Crew.change_loyalty(nonsense_loyalty_change)
	_finish("")
