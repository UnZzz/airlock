extends Node

signal inventory_changed

@export
var food_count = 10
@export
var bottle_of_mouthwash_count = 10

var start_food_count : int = 0
var start_mouthwash_count : int = 0


func _ready() -> void:
	start_food_count = food_count
	start_mouthwash_count = bottle_of_mouthwash_count


func reset() -> void:
	food_count = start_food_count
	bottle_of_mouthwash_count = start_mouthwash_count
	inventory_changed.emit()


func can_afford(food: int, mouthwash: int) -> bool:
	return food_count >= food and bottle_of_mouthwash_count >= mouthwash


func spend(food: int, mouthwash: int) -> bool:
	if not can_afford(food, mouthwash):
		return false
	apply_change(-food, -mouthwash)
	return true


func apply_change(food_delta: int, mouthwash_delta: int) -> void:
	if food_delta == 0 and mouthwash_delta == 0:
		return
	food_count = max(food_count + food_delta, 0)
	bottle_of_mouthwash_count = max(bottle_of_mouthwash_count + mouthwash_delta, 0)
	inventory_changed.emit()
