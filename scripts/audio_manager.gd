extends Node

const SR: int = 22050
const SETTINGS_FILE: String = "user://settings.cfg"

static var _music_volume_db: float = -12.0
static var _sfx_volume_db: float = 0.0
static var _settings_loaded: bool = false

static var _click_stream: AudioStreamWAV = null
static var _hover_stream: AudioStreamWAV = null
static var _error_stream: AudioStreamWAV = null
static var _dragon_roar_stream: AudioStreamWAV = null
static var _breath_stream: AudioStreamWAV = null
static var _impact_stream: AudioStreamWAV = null
static var _meteor_stream: AudioStreamWAV = null
static var _vortex_hum_stream: AudioStreamWAV = null
static var _hit_stream: AudioStreamWAV = null
static var _level_up_stream: AudioStreamWAV = null
static var _vortex_player: AudioStreamPlayer = null

func _ready() -> void:
	load_settings()

static func get_music_volume_db() -> float:
	return _music_volume_db

static func get_sfx_volume_db() -> float:
	return _sfx_volume_db

static func set_music_volume_db(v: float) -> void:
	_music_volume_db = v
	_apply_bus_volumes()
	save_settings()

static func set_sfx_volume_db(v: float) -> void:
	_sfx_volume_db = v
	_apply_bus_volumes()
	save_settings()

static func load_settings() -> void:
	if _settings_loaded:
		return
	_settings_loaded = true
	_apply_bus_volumes()
	var cfg := ConfigFile.new()
	var err := cfg.load(SETTINGS_FILE)
	if err != OK:
		return
	_music_volume_db = cfg.get_value("audio", "music_volume_db", -12.0)
	_sfx_volume_db = cfg.get_value("audio", "sfx_volume_db", 0.0)
	_apply_bus_volumes()

static func _apply_bus_volumes() -> void:
	var mi := AudioServer.get_bus_index("Music")
	if mi >= 0:
		AudioServer.set_bus_volume_db(mi, _music_volume_db)
	var si := AudioServer.get_bus_index("SFX")
	if si >= 0:
		AudioServer.set_bus_volume_db(si, _sfx_volume_db)

static func save_settings() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("audio", "music_volume_db", _music_volume_db)
	cfg.set_value("audio", "sfx_volume_db", _sfx_volume_db)
	cfg.save(SETTINGS_FILE)

static func _make_wav(duration: float, gen: Callable) -> AudioStreamWAV:
	var n = ceili(duration * SR)
	var data := PackedByteArray()
	data.resize(n * 2)
	for i in n:
		var t = float(i) / SR
		var v = gen.call(t, float(i), n)
		v = clampf(v, -1.0, 1.0)
		var s = int(v * 32767)
		data.encode_s16(i * 2, s)
	var wav = AudioStreamWAV.new()
	wav.data = data
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = SR
	wav.stereo = false
	return wav

static func _cache(key: String, dur: float, gen: Callable) -> AudioStreamWAV:
	return _make_wav(dur, gen)

static func _sq(freq: float, t: float) -> float:
	return -1.0 if int(t * freq * 2.0) % 2 == 0 else 1.0

static func _tri(freq: float, t: float) -> float:
	var phase = fmod(t * freq, 1.0)
	return 1.0 - 4.0 * absf(phase - 0.5)

static func click(t: float, _i: float, _n: int) -> float:
	var env = exp(-t * 50.0)
	var tri = _tri(400.0, t) * env * 0.5
	var sub = sin(2.0 * PI * 80.0 * t) * env * 0.3
	return (tri + sub) * 0.6

static func hover(t: float, _i: float, _n: int) -> float:
	var env = exp(-t * 80.0)
	var tone = sin(2.0 * PI * 300.0 * t) * env * 0.4
	var rumble = _sq(50.0, t) * env * 0.2
	return (tone + rumble) * 0.5

static func error_snd(t: float, _i: float, _n: int) -> float:
	var env = exp(-t * 12.0)
	var sq = _sq(100.0, t) * env * 0.4
	var sub = sin(2.0 * PI * 40.0 * t) * env * 0.3
	return (sq + sub) * 0.5

static func roar(t: float, _i: float, _n: int) -> float:
	var env = exp(-t * 3.0)
	var lfo = 0.4 + 0.6 * sin(2.0 * PI * 20.0 * t)
	var sub = sin(2.0 * PI * 40.0 * t) * env * 0.6
	var growl = _sq(80.0, t) * env * lfo * 0.5
	var noise = randf_range(-1.0, 1.0) * env * lfo * 0.3
	return (sub + growl + noise) * 0.5

static func breath(t: float, _i: float, _n: int) -> float:
	var env = exp(-t * 2.0)
	var lfo = 0.6 + 0.4 * sin(2.0 * PI * 30.0 * t)
	var rumble = sin(2.0 * PI * 80.0 * t) * env * lfo * 0.5
	var lpnoise = randf_range(-1.0, 1.0) * env * lfo * 0.3
	lpnoise = lpnoise * 0.5 + sin(t * 200.0) * env * 0.15
	return (rumble + lpnoise) * 0.5

static func impact(t: float, _i: float, _n: int) -> float:
	var env = exp(-t * 5.0)
	var sub = sin(2.0 * PI * 25.0 * t) * env * 0.7
	var crunch = _sq(60.0, t) * env * 0.5
	var noise = randf_range(-1.0, 1.0) * exp(-t * 10.0) * 0.4
	return (sub + crunch + noise) * 0.5

static func meteor(t: float, _i: float, _n: int) -> float:
	var dur = float(_n) / SR
	var freq = 400.0 - (t / dur) * 370.0
	freq = maxf(freq, 30.0)
	var env = exp(-t * 1.8)
	var tone = sin(2.0 * PI * freq * t) * env * 0.5
	var sub = sin(2.0 * PI * 30.0 * t) * env * 0.3
	return (tone + sub) * 0.5

static func vortex_hum(t: float, _i: float, _n: int) -> float:
	var lfo = sin(2.0 * PI * 3.0 * t) * 30.0
	var tone = sin(2.0 * PI * (55.0 + lfo) * t) * 0.4
	var sub = sin(2.0 * PI * 27.5 * t) * 0.35
	var growl = _sq(27.5, t) * 0.15
	return (tone + sub + growl) * 0.5

static func hit(t: float, _i: float, _n: int) -> float:
	var env = exp(-t * 20.0)
	var tone = sin(2.0 * PI * 120.0 * t) * env * 0.5
	var sub = sin(2.0 * PI * 40.0 * t) * env * 0.3
	return (tone + sub) * 0.6

static func level_up(t: float, i: float, _n: int) -> float:
	var dur = float(_n) / SR
	var note_idx = int(t / (dur / 4.0))
	note_idx = mini(note_idx, 3)
	var freqs = [130.81, 164.81, 196.0, 261.63]
	var freq = freqs[note_idx]
	var note_t = t - (dur / 4.0) * note_idx
	var note_dur = dur / 4.0
	var env = exp(-note_t * 6.0) if note_t < note_dur * 0.8 else 0.0
	var tone = sin(2.0 * PI * freq * t) * env * 0.4
	var sub = sin(2.0 * PI * freq * 0.5 * t) * env * 0.2
	return (tone + sub) * 0.5

static func fireball(t: float, _i: float, _n: int) -> float:
	var dur = float(_n) / SR
	var freq = 400.0 + (t / dur) * 400.0
	var env = exp(-t * 4.0)
	var tone = sin(2.0 * PI * freq * t) * env * 0.5
	var noise = randf_range(-1.0, 1.0) * env * 0.3
	return (tone + noise) * 0.5

static func ice_lance(t: float, _i: float, _n: int) -> float:
	var dur = float(_n) / SR
	var freq = 2000.0 - (t / dur) * 1500.0
	freq = maxf(freq, 500.0)
	var env = exp(-t * 3.0)
	var tone = sin(2.0 * PI * freq * t) * env * 0.5
	var shard = sin(2.0 * PI * freq * 1.5 * t) * env * 0.2
	return (tone + shard) * 0.5

static func ice_wall(t: float, _i: float, _n: int) -> float:
	var env = exp(-t * 2.0)
	var crackle = randf_range(-1.0, 1.0) * env * 0.4
	var hum = sin(2.0 * PI * 100.0 * t) * env * 0.3
	return (crackle + hum) * 0.5

static func channel_start(t: float, _i: float, _n: int) -> float:
	var env = exp(-t * 6.0)
	var lfo = sin(2.0 * PI * 8.0 * t) * 0.3
	var tone = sin(2.0 * PI * (300.0 + lfo * 50.0) * t) * env * 0.4
	return tone * 0.5

static func melee_swing(t: float, _i: float, _n: int) -> float:
	var env = exp(-t * 8.0)
	var sq = _sq(150.0, t) * env * 0.5
	var noise = randf_range(-1.0, 1.0) * env * 0.3
	return (sq + noise) * 0.5

static func enemy_death(t: float, _i: float, _n: int) -> float:
	var dur = float(_n) / SR
	var freq = 80.0 - (t / dur) * 50.0
	freq = maxf(freq, 30.0)
	var env = exp(-t * 2.5)
	var tone = sin(2.0 * PI * freq * t) * env * 0.5
	var sub = sin(2.0 * PI * 30.0 * t) * env * 0.3
	return (tone + sub) * 0.5

static func mage_shoot(t: float, _i: float, _n: int) -> float:
	var dur = float(_n) / SR
	var freq = 600.0 - (t / dur) * 200.0
	var env = exp(-t * 6.0)
	var tone = sin(2.0 * PI * freq * t) * env * 0.4
	var sub = sin(2.0 * PI * freq * 0.5 * t) * env * 0.2
	return (tone + sub) * 0.5

static func summon_spawn(t: float, _i: float, _n: int) -> float:
	var dur = float(_n) / SR
	var freq = 100.0 + (t / dur) * 200.0
	var env = exp(-t * 3.0)
	var tone = sin(2.0 * PI * freq * t) * env * 0.5
	var sub = sin(2.0 * PI * 50.0 * t) * env * 0.3
	return (tone + sub) * 0.5

static func summon_death(t: float, _i: float, _n: int) -> float:
	var dur = float(_n) / SR
	var freq = 200.0 - (t / dur) * 160.0
	freq = maxf(freq, 40.0)
	var env = exp(-t * 3.5)
	var tone = sin(2.0 * PI * freq * t) * env * 0.4
	var sub = sin(2.0 * PI * 40.0 * t) * env * 0.3
	return (tone + sub) * 0.5

static func xp_gain(t: float, _i: float, _n: int) -> float:
	var env = exp(-t * 10.0)
	var tone = sin(2.0 * PI * 300.0 * t) * env * 0.4
	var noise = randf_range(-1.0, 1.0) * env * 0.2
	return (tone + noise) * 0.5

static func pentagram_tick(t: float, _i: float, _n: int) -> float:
	var dur = float(_n) / SR
	var freq = 500.0 + (t / dur) * 300.0
	var env = exp(-t * 12.0)
	var tone = sin(2.0 * PI * freq * t) * env * 0.5
	return tone * 0.5

static func pentagram_done(t: float, _i: float, _n: int) -> float:
	var dur = float(_n) / SR / 3.0
	var idx = int(t / dur)
	idx = mini(idx, 2)
	var freqs = [200.0, 400.0, 600.0]
	var freq = freqs[idx]
	var note_t = t - dur * idx
	var env = exp(-note_t * 5.0) if note_t < dur * 0.8 else 0.0
	var tone = sin(2.0 * PI * freq * t) * env * 0.6
	return tone * 0.5

static func spawn_wave(t: float, _i: float, _n: int) -> float:
	var env = exp(-t * 3.0)
	var tone = sin(2.0 * PI * 100.0 * t) * env * 0.4
	var sub = sin(2.0 * PI * 40.0 * t) * env * 0.3
	var noise = randf_range(-1.0, 1.0) * env * 0.2
	return (tone + sub + noise) * 0.5

static func game_over(t: float, _i: float, _n: int) -> float:
	var dur = float(_n) / SR
	var freq = 80.0 - (t / dur) * 50.0
	freq = maxf(freq, 30.0)
	var env = exp(-t * 1.5)
	var tone = sin(2.0 * PI * freq * t) * env * 0.4
	var sub = sin(2.0 * PI * 25.0 * t) * env * 0.3
	var noise = randf_range(-1.0, 1.0) * env * 0.2
	return (tone + sub + noise) * 0.5

static func heal(t: float, _i: float, _n: int) -> float:
	var dur = float(_n) / SR
	var freq = 300.0 + (t / dur) * 400.0
	var env = exp(-t * 4.0)
	var tone = sin(2.0 * PI * freq * t) * env * 0.4
	var shimmer = sin(2.0 * PI * freq * 2.0 * t) * env * 0.2
	var sub = sin(2.0 * PI * 100.0 * t) * env * 0.2
	return (tone + shimmer + sub) * 0.5

static func grimoire(t: float, _i: float, _n: int) -> float:
	var env = exp(-t * 8.0)
	var tone = sin(2.0 * PI * 200.0 * t) * env * 0.4
	var sub = sin(2.0 * PI * 60.0 * t) * env * 0.3
	var rustle = randf_range(-1.0, 1.0) * env * 0.2
	return (tone + sub + rustle) * 0.5

static func play_click() -> void:
	if _click_stream == null:
		_click_stream = _cache("click", 0.06, click)
	_play_2d(_click_stream, -6.0)

static func play_hover() -> void:
	if _hover_stream == null:
		_hover_stream = _cache("hover", 0.04, hover)
	_play_2d(_hover_stream, -10.0)

static func play_error() -> void:
	if _error_stream == null:
		_error_stream = _cache("error", 0.2, error_snd)
	_play_2d(_error_stream, -4.0)

static func play_dragon_roar(pos: Vector3) -> void:
	if _dragon_roar_stream == null:
		_dragon_roar_stream = _cache("roar", 0.7, roar)
	_play_3d(_dragon_roar_stream, pos, 2.0)

static func play_breath(pos: Vector3) -> void:
	if _breath_stream == null:
		_breath_stream = _cache("breath", 0.5, breath)
	_play_3d(_breath_stream, pos, -2.0)

static func play_impact(pos: Vector3) -> void:
	if _impact_stream == null:
		_impact_stream = _cache("impact", 0.6, impact)
	_play_3d(_impact_stream, pos, 3.0)

static func play_meteor(pos: Vector3) -> void:
	if _meteor_stream == null:
		_meteor_stream = _cache("meteor", 0.9, meteor)
	_play_3d(_meteor_stream, pos, -1.0)

static func play_vortex_start() -> void:
	if _vortex_hum_stream == null:
		_vortex_hum_stream = _cache("vortex", 5.0, vortex_hum)
	_vortex_hum_stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	if _vortex_player == null or not is_instance_valid(_vortex_player):
		_vortex_player = AudioStreamPlayer.new()
		if Engine.get_main_loop():
			Engine.get_main_loop().root.add_child(_vortex_player)
	if _vortex_player:
		_vortex_player.stream = _vortex_hum_stream
		_vortex_player.bus = "SFX"
		_vortex_player.volume_db = -8.0
		_vortex_player.play()

static func play_vortex_stop() -> void:
	if _vortex_player and is_instance_valid(_vortex_player):
		_vortex_player.stop()

static func play_hit() -> void:
	if _hit_stream == null:
		_hit_stream = _cache("hit", 0.1, hit)
	_play_2d(_hit_stream, -2.0)

static func play_level_up() -> void:
	if _level_up_stream == null:
		_level_up_stream = _cache("levelup", 0.7, level_up)
	_play_2d(_level_up_stream, 0.0)

static var _fireball_stream: AudioStreamWAV = null
static var _ice_lance_stream: AudioStreamWAV = null
static var _ice_wall_stream: AudioStreamWAV = null
static var _channel_stream: AudioStreamWAV = null
static var _melee_swing_stream: AudioStreamWAV = null
static var _enemy_death_stream: AudioStreamWAV = null
static var _mage_shoot_stream: AudioStreamWAV = null
static var _summon_spawn_stream: AudioStreamWAV = null
static var _summon_death_stream: AudioStreamWAV = null
static var _xp_stream: AudioStreamWAV = null
static var _pentagram_tick_stream: AudioStreamWAV = null
static var _pentagram_done_stream: AudioStreamWAV = null
static var _spawn_wave_stream: AudioStreamWAV = null
static var _game_over_stream: AudioStreamWAV = null
static var _grimoire_stream: AudioStreamWAV = null

static func play_fireball(pos: Vector3) -> void:
	if _fireball_stream == null:
		_fireball_stream = _cache("fire", 0.25, fireball)
	_play_3d(_fireball_stream, pos, -2.0)

static func play_ice_lance(pos: Vector3) -> void:
	if _ice_lance_stream == null:
		_ice_lance_stream = _cache("icelance", 0.3, ice_lance)
	_play_3d(_ice_lance_stream, pos, -3.0)

static func play_ice_wall(pos: Vector3) -> void:
	if _ice_wall_stream == null:
		_ice_wall_stream = _cache("icewall", 0.5, ice_wall)
	_play_3d(_ice_wall_stream, pos, -4.0)

static func play_channel_start() -> void:
	if _channel_stream == null:
		_channel_stream = _cache("channel", 0.2, channel_start)
	_play_2d(_channel_stream, -6.0)

static func play_melee_swing(pos: Vector3) -> void:
	if _melee_swing_stream == null:
		_melee_swing_stream = _cache("melee", 0.2, melee_swing)
	_play_3d(_melee_swing_stream, pos, -4.0)

static func play_enemy_death(pos: Vector3) -> void:
	if _enemy_death_stream == null:
		_enemy_death_stream = _cache("edie", 0.4, enemy_death)
	_play_3d(_enemy_death_stream, pos, -2.0)

static func play_mage_shoot(pos: Vector3) -> void:
	if _mage_shoot_stream == null:
		_mage_shoot_stream = _cache("mshoot", 0.2, mage_shoot)
	_play_3d(_mage_shoot_stream, pos, -5.0)

static func play_summon_spawn(pos: Vector3) -> void:
	if _summon_spawn_stream == null:
		_summon_spawn_stream = _cache("sspawn", 0.3, summon_spawn)
	_play_3d(_summon_spawn_stream, pos, 0.0)

static func play_summon_death(pos: Vector3) -> void:
	if _summon_death_stream == null:
		_summon_death_stream = _cache("sdeath", 0.35, summon_death)
	_play_3d(_summon_death_stream, pos, -3.0)

static func play_xp_gain() -> void:
	if _xp_stream == null:
		_xp_stream = _cache("xp", 0.12, xp_gain)
	_play_2d(_xp_stream, -6.0)

static func play_pentagram_tick() -> void:
	if _pentagram_tick_stream == null:
		_pentagram_tick_stream = _cache("ptick", 0.08, pentagram_tick)
	_play_2d(_pentagram_tick_stream, -8.0)

static func play_pentagram_complete() -> void:
	if _pentagram_done_stream == null:
		_pentagram_done_stream = _cache("pcomp", 0.4, pentagram_done)
	_play_2d(_pentagram_done_stream, 0.0)

static func play_spawn_wave(pos: Vector3) -> void:
	if _spawn_wave_stream == null:
		_spawn_wave_stream = _cache("wave", 0.4, spawn_wave)
	_play_3d(_spawn_wave_stream, pos, -2.0)

static func play_game_over() -> void:
	if _game_over_stream == null:
		_game_over_stream = _cache("over", 1.2, game_over)
	_play_2d(_game_over_stream, -2.0)

static func play_heal() -> void:
	var s = _cache("heal", 0.35, heal)
	_play_2d(s, -4.0)

static func play_grimoire_open() -> void:
	if _grimoire_stream == null:
		_grimoire_stream = _cache("grim", 0.15, grimoire)
	_play_2d(_grimoire_stream, -4.0)

static func play_element_select() -> void:
	if _click_stream == null:
		_click_stream = _cache("click", 0.06, click)
	_play_2d(_click_stream, -10.0)

static func _get_tree() -> SceneTree:
	return Engine.get_main_loop()

static func _play_2d(stream: AudioStreamWAV, vol_db: float) -> void:
	var p = AudioStreamPlayer.new()
	p.stream = stream
	p.volume_db = vol_db
	p.bus = "SFX"
	_get_tree().root.add_child(p)
	p.play()
	p.finished.connect(p.queue_free)

static func _play_3d(stream: AudioStreamWAV, pos: Vector3, vol_db: float) -> void:
	var p = AudioStreamPlayer3D.new()
	p.stream = stream
	p.volume_db = vol_db
	p.bus = "SFX"
	p.global_position = pos
	p.max_distance = 30.0
	p.attenuation_model = 0
	_get_tree().root.add_child(p)
	p.play()
	p.finished.connect(p.queue_free)
