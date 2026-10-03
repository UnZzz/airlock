extends Node

## Background music. Only one track group plays at a time; switching crossfades.
##   Music.play_playlist()  # atmosphere -> piano, looping forever
##   Music.play_ambience()  # seamless space-machinery loop for special scenes (e.g. the opening)
##   Music.stop()

const DEFAULT_FADE_TIME = 2.0

@onready var _playlist: AudioStreamPlayer = $Playlist
@onready var _ambience: AudioStreamPlayer = $Ambience

var _full_volume = {}
var _tweens = {}


func _ready() -> void:
	for player in [_playlist, _ambience]:
		_full_volume[player] = player.volume_linear


func play_playlist(fade_time := DEFAULT_FADE_TIME) -> void:
	_switch_to(_playlist, fade_time)


func play_ambience(fade_time := DEFAULT_FADE_TIME) -> void:
	_switch_to(_ambience, fade_time)


func stop(fade_time := DEFAULT_FADE_TIME) -> void:
	_switch_to(null, fade_time)


func _switch_to(target: AudioStreamPlayer, fade_time: float) -> void:
	for player in [_playlist, _ambience]:
		if player == target:
			_fade_in(player, fade_time)
		elif player.playing:
			_fade_out(player, fade_time)


func _fade_in(player: AudioStreamPlayer, fade_time: float) -> void:
	if not player.playing:
		player.volume_linear = 0.0
		player.play()
	# Sine in/out curves give an equal-power crossfade, so loudness doesn't dip mid-switch.
	var tween = _new_tween(player)
	tween.tween_property(player, "volume_linear", _full_volume[player], fade_time) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)


func _fade_out(player: AudioStreamPlayer, fade_time: float) -> void:
	var tween = _new_tween(player)
	tween.tween_property(player, "volume_linear", 0.0, fade_time) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tween.tween_callback(player.stop)


func _new_tween(player: AudioStreamPlayer) -> Tween:
	if _tweens.has(player):
		_tweens[player].kill()
	_tweens[player] = create_tween()
	return _tweens[player]
