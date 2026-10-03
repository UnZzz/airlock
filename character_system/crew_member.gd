class_name CrewMember
extends Resource

enum Role { CAPTAIN, CRIMINAL, WORKER, DOCTOR, CHEF }
enum Status { ON_BOARD, EXILED, DEAD }
enum Health { HEALTHY, INJURED, CRITICAL }
enum Promise { NONE, SKIP_NEXT_TASK, SPARE_NEXT_AIRLOCK, EXILE_TARGET }

@export
var member_id : String = ""
@export
var display_name : String = ""
@export
var short_name : String = ""
@export
var pronoun : String = ""
@export
var role : Role = Role.CAPTAIN
@export
var loyalty : int = 0

var status : Status = Status.ON_BOARD
var death_cause : String = ""
var days_without_food : int = 0
var fed_today : bool = false
var reached_max_loyalty : bool = false
var intimidate_unlocked : bool = false
var knows_airlock_secret : bool = false
var current_promise : Promise = Promise.NONE
var requested_exile_target : String = ""
var refuses_next_task : bool = false


func is_on_board() -> bool:
	return status == Status.ON_BOARD
