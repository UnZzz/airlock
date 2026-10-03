class_name EventOption
extends Resource

@export
var text : String = ""
@export_multiline
var result_text : String = ""
@export
var food_change : int = 0
@export
var mouthwash_change : int = 0
@export
var loyalty_change : int = 0
@export
var required_member : String = ""
@export
var injure_member : String = ""
@export
var intimidatable : bool = false

var action : String = ""
var target_id : String = ""
var is_intimidation : bool = false


func is_visible() -> bool:
	return required_member == "" or Crew.is_on_board(required_member)


func can_afford() -> bool:
	return Inventory.can_afford(max(-food_change, 0), max(-mouthwash_change, 0))


func has_cost() -> bool:
	return food_change < 0 or mouthwash_change < 0


func apply() -> void:
	Inventory.apply_change(food_change, mouthwash_change)
	if loyalty_change != 0:
		Crew.change_loyalty(loyalty_change)
	if injure_member != "":
		Crew.injure(injure_member)


func make_intimidated() -> EventOption:
	var copy : EventOption = duplicate() as EventOption
	copy.food_change = max(food_change, 0)
	copy.mouthwash_change = max(mouthwash_change, 0)
	copy.text = Journal.text("ui_intimidate", {"text": text})
	copy.action = action
	copy.target_id = target_id
	copy.is_intimidation = true
	return copy


static func create(option_text: String, option_action: String, option_target: String = "") -> EventOption:
	var option : EventOption = EventOption.new()
	option.text = option_text
	option.action = option_action
	option.target_id = option_target
	return option
