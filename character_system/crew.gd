extends Node

signal crew_changed
signal member_died(member: CrewMember, cause: String)
signal member_exiled(member: CrewMember)
signal intimidate_unlocked(criminal: CrewMember)
signal mutiny(criminal: CrewMember)

@export
var member_templates : Array[CrewMember] = []
@export
var injured_effect : BaseEffect
@export
var critical_effect : BaseEffect
@export
var sick_effect : BaseEffect
@export
var max_loyalty : int = 3
@export
var starvation_limit : int = 3
@export
var chef_food_multiplier : float = 0.75
@export
var maintenance_cost : int = 1
@export
var treatment_cost : int = 2
@export
var sickness_cure_cost : int = 1

var members : Array[CrewMember] = []


func _ready() -> void:
	EffectSystem.effect_added.connect(_on_effect_added)


func reset() -> void:
	members.clear()
	for template in member_templates:
		var member : CrewMember = template.duplicate() as CrewMember
		Journal.localize_member(member)
		members.append(member)
	crew_changed.emit()


func get_member(member_id: String) -> CrewMember:
	for member in members:
		if member.member_id == member_id:
			return member
	return null


func get_by_role(role: CrewMember.Role) -> CrewMember:
	for member in members:
		if member.role == role:
			return member
	return null


func is_on_board(member_id: String) -> bool:
	var member : CrewMember = get_member(member_id)
	return member != null and member.is_on_board()


func is_role_on_board(role: CrewMember.Role) -> bool:
	var member : CrewMember = get_by_role(role)
	return member != null and member.is_on_board()


func on_board() -> Array[CrewMember]:
	var result : Array[CrewMember] = []
	for member in members:
		if member.is_on_board():
			result.append(member)
	return result


func passengers_on_board() -> Array[CrewMember]:
	var result : Array[CrewMember] = []
	for member in on_board():
		if member.role != CrewMember.Role.CAPTAIN:
			result.append(member)
	return result


func exiled_count() -> int:
	var count : int = 0
	for member in members:
		if member.status == CrewMember.Status.EXILED:
			count += 1
	return count


func get_health(member_id: String) -> CrewMember.Health:
	if EffectSystem.has_effect(member_id, critical_effect.effect_name):
		return CrewMember.Health.CRITICAL
	if EffectSystem.has_effect(member_id, injured_effect.effect_name):
		return CrewMember.Health.INJURED
	return CrewMember.Health.HEALTHY


func get_injury_effect(member_id: String) -> BaseEffect:
	match get_health(member_id):
		CrewMember.Health.CRITICAL:
			return critical_effect
		CrewMember.Health.INJURED:
			return injured_effect
	return null


func is_sick(member_id: String) -> bool:
	return sick_effect != null and EffectSystem.has_effect(member_id, sick_effect.effect_name)


func make_sick(member_id: String) -> void:
	if not is_on_board(member_id) or is_sick(member_id):
		return
	EffectSystem.add_effect(member_id, sick_effect)
	crew_changed.emit()


func cure_sickness(member_id: String) -> void:
	if not is_sick(member_id):
		return
	EffectSystem.remove_effect(member_id, sick_effect.effect_name)
	crew_changed.emit()


func can_cure_sickness(member_id: String) -> bool:
	return is_sick(member_id) and Inventory.can_afford(0, sickness_cure_cost)


func cure_sickness_with_mouthwash(member_id: String) -> bool:
	if not can_cure_sickness(member_id):
		return false
	Inventory.spend(0, sickness_cure_cost)
	cure_sickness(member_id)
	return true


func injure(member_id: String) -> void:
	if not is_on_board(member_id):
		return
	match get_health(member_id):
		CrewMember.Health.HEALTHY:
			EffectSystem.add_effect(member_id, injured_effect)
		CrewMember.Health.INJURED:
			EffectSystem.remove_effect(member_id, injured_effect.effect_name)
			EffectSystem.add_effect(member_id, critical_effect)
		CrewMember.Health.CRITICAL:
			kill(member_id, "injury")
	crew_changed.emit()


func is_injury_countdown_full(member_id: String) -> bool:
	var effect : BaseEffect = get_injury_effect(member_id)
	if effect == null:
		return false
	return EffectSystem.get_remaining(member_id, effect.effect_name) >= effect.duration


func can_maintain(member_id: String) -> bool:
	if get_injury_effect(member_id) == null:
		return false
	if is_injury_countdown_full(member_id):
		return false
	return Inventory.can_afford(0, maintenance_cost)


func maintain(member_id: String) -> bool:
	if not can_maintain(member_id):
		return false
	Inventory.spend(0, maintenance_cost)
	get_member(member_id).last_mouthwash_day = Timeline.current_day
	EffectSystem.reset_duration(member_id, get_injury_effect(member_id).effect_name)
	crew_changed.emit()
	return true


func doctor_available() -> bool:
	var doctor : CrewMember = get_by_role(CrewMember.Role.DOCTOR)
	if doctor == null or not doctor.is_on_board():
		return false
	return get_health(doctor.member_id) != CrewMember.Health.CRITICAL


func can_treat(member_id: String) -> bool:
	if get_injury_effect(member_id) == null:
		return false
	if not doctor_available():
		return false
	return Inventory.can_afford(0, treatment_cost)


func treat(member_id: String) -> bool:
	if not can_treat(member_id):
		return false
	Inventory.spend(0, treatment_cost)
	EffectSystem.remove_effect(member_id, injured_effect.effect_name)
	EffectSystem.remove_effect(member_id, critical_effect.effect_name)
	crew_changed.emit()
	return true


func heal(member_id: String) -> void:
	if get_injury_effect(member_id) == null:
		return
	EffectSystem.remove_effect(member_id, injured_effect.effect_name)
	EffectSystem.remove_effect(member_id, critical_effect.effect_name)
	crew_changed.emit()


func kill(member_id: String, cause: String) -> void:
	var member : CrewMember = get_member(member_id)
	if member == null or not member.is_on_board():
		return
	member.status = CrewMember.Status.DEAD
	member.death_cause = cause
	EffectSystem.clear_target(member_id)
	member_died.emit(member, cause)
	crew_changed.emit()


func exile(member_id: String, cause: String = "airlock") -> void:
	var member : CrewMember = get_member(member_id)
	if member == null or not member.is_on_board():
		return
	member.status = CrewMember.Status.EXILED
	member.exile_cause = cause
	EffectSystem.clear_target(member_id)
	member_exiled.emit(member)
	crew_changed.emit()


func change_loyalty(delta: int) -> void:
	var criminal : CrewMember = get_by_role(CrewMember.Role.CRIMINAL)
	if criminal == null or not criminal.is_on_board() or delta == 0:
		return
	criminal.loyalty = clampi(criminal.loyalty + delta, 0, max_loyalty)
	if criminal.loyalty >= max_loyalty and not criminal.reached_max_loyalty:
		criminal.reached_max_loyalty = true
		criminal.intimidate_unlocked = true
		intimidate_unlocked.emit(criminal)
	crew_changed.emit()
	if criminal.reached_max_loyalty and criminal.loyalty == 0:
		mutiny.emit(criminal)


func is_loyalty_full() -> bool:
	var criminal : CrewMember = get_by_role(CrewMember.Role.CRIMINAL)
	return criminal != null and criminal.is_on_board() and criminal.loyalty >= max_loyalty


func can_intimidate() -> bool:
	var criminal : CrewMember = get_by_role(CrewMember.Role.CRIMINAL)
	if criminal == null or not criminal.is_on_board():
		return false
	return criminal.intimidate_unlocked and criminal.loyalty > 0


func refuses_meal(member: CrewMember) -> bool:
	return member.role == CrewMember.Role.WORKER and member.knows_airlock_secret and Timeline.is_time_to_kick_out


func meal_cost(count: int) -> int:
	if count <= 0:
		return 0
	if is_role_on_board(CrewMember.Role.CHEF):
		return ceili(count * chef_food_multiplier)
	return count


func serve_meals(fed_ids: Array[String]) -> bool:
	var eaters : Array[CrewMember] = []
	for member in on_board():
		if fed_ids.has(member.member_id) and not refuses_meal(member):
			eaters.append(member)
	if not Inventory.spend(meal_cost(eaters.size()), 0):
		return false
	for member in on_board():
		member.fed_today = eaters.has(member)
	crew_changed.emit()
	return true


func end_day() -> void:
	for member in on_board():
		if member.fed_today:
			member.days_without_food = 0
		else:
			member.days_without_food += 1
			member.hungry_day_count += 1
		member.fed_today = false
	for member in on_board():
		if member.days_without_food >= starvation_limit:
			kill(member.member_id, "starvation")
	crew_changed.emit()


func _on_effect_added(target_id: String, effect: BaseEffect) -> void:
	if effect.is_fatal:
		kill(target_id, "injury")
