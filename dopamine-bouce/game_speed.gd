extends Node
## Global game speed (autoload "GameSpeed").
##
## The BPM is the driver: it ramps from start_bpm to max_bpm, and the speed
## multiplier is derived from it so one platform passes every beat. The music
## track whose BPM is closest plays, pitch-shifted to match the exact BPM.

@export var start_bpm: float = 105 #70.0
@export var max_bpm: float = 105.0
## Seconds of play to go from start_bpm to max_bpm.
@export var ramp_time: float = 90.0
## Beats between two platforms. 1 = bounce on every beat, 2 = every other beat.
@export var beats_per_platform: int = 1
## Pitch-shift the track so it matches the BPM exactly (below 85 the 85 track is slowed down).
@export var match_pitch: bool = true

## BPM -> track. Each track must start on a beat.
var tracks := {
	80.0: preload("res://assets/music/GameJam85.mp3"),
	90.0: preload("res://assets/music/GameJam105.mp3"),
}

## Seconds between platforms at multiplier 1. Set by the ball from its bounce physics.
var base_beat_time: float = 1.2
var bpm: float = 70.0
var multiplier: float = 1.0

var _player: AudioStreamPlayer
var _track_bpm: float = 0.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_player = AudioStreamPlayer.new()
	add_child(_player)
	for stream in tracks.values():
		stream.loop = true
	reset()
	


## Back to the start speed and silence. Called when the run (re)starts.
func reset() -> void:
	bpm = start_bpm
	multiplier = multiplier_for(bpm)
	_player.stop()
	_track_bpm = 0.0


## Seconds between two platforms at the given BPM.
func beat_time_for(at_bpm: float) -> float:
	return 60.0 / at_bpm * beats_per_platform


func multiplier_for(at_bpm: float) -> float:
	return base_beat_time / beat_time_for(at_bpm)


## 0 at start_bpm, 1 at max_bpm.
func progress() -> float:
	if max_bpm <= start_bpm:
		return 0.0
	return inverse_lerp(start_bpm, max_bpm, bpm)


## Called by the ball on every bounce (the only moment speed may change, so arcs
## stay in sync with the tiles). Returns the new speed multiplier.
func on_bounce(run_time: float) -> float:
	var t := clampf(run_time / ramp_time, 0.0, 1.0) if ramp_time > 0.0 else 1.0
	bpm = lerpf(start_bpm, max_bpm, t)
	multiplier = multiplier_for(bpm)
	_update_music()
	return multiplier


func _update_music() -> void:
	var best: float = tracks.keys()[0]
	for track_bpm: float in tracks.keys():
		if absf(track_bpm - bpm) < absf(best - bpm):
			best = track_bpm

	if best != _track_bpm or not _player.playing:
		# Switching happens on a bounce, i.e. on a beat, so starting the new
		# track from its first beat keeps it in phase.
		_track_bpm = best
		_player.stream = tracks[best]
		_player.play()

	_player.pitch_scale = bpm / _track_bpm if match_pitch else 1.0
