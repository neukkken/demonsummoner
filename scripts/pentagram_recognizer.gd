extends Node

signal pentagram_detected()
signal pentagram_progress(progress: int, total: int)

const PATTERN: Array[String] = ["UP", "DOWN", "LEFT", "UP", "DOWN"]
const GESTURE_TIMEOUT: float = 1.5

var _buffer: Array[String] = []
var _last_time: float = 0.0
var _tracking: bool = false

func on_gesture(gesture: String) -> void:
	if not _tracking:
		return
	if gesture == "UNKNOWN":
		reset()
		return
	var now: float = Time.get_ticks_msec() / 1000.0
	if _buffer.is_empty() or (now - _last_time) <= GESTURE_TIMEOUT:
		_buffer.append(gesture)
		if _buffer.size() > PATTERN.size():
			_buffer.pop_front()
	else:
		_buffer = [gesture]
	_last_time = now
	_check_pattern()

func _check_pattern() -> void:
	if _buffer.size() < PATTERN.size():
		pentagram_progress.emit(_buffer.size(), PATTERN.size())
		return
	var match_all: bool = true
	for i in PATTERN.size():
		if _buffer[i] != PATTERN[i]:
			match_all = false
			break
	if match_all:
		pentagram_detected.emit()
		pentagram_progress.emit(0, PATTERN.size())
		_buffer.clear()
	else:
		_buffer.pop_front()
		if _buffer.size() > 0:
			pentagram_progress.emit(_buffer.size(), PATTERN.size())

func set_tracking(enable: bool) -> void:
	_tracking = enable
	if not enable:
		reset()

func is_active() -> bool:
	return not _buffer.is_empty()

func is_tracking() -> bool:
	return _tracking

func reset() -> void:
	_buffer.clear()
	pentagram_progress.emit(0, PATTERN.size())
