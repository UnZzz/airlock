class_name BaseEffect
extends Resource

@export
var effect_name : String = "unknown"
@export
var display_name : String = ""
@export
#-1 means infinite duration
var duration : int = -1
@export
var next_effect : BaseEffect
@export
var is_fatal : bool = false
