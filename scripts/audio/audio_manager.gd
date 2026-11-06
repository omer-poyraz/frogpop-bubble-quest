extends Node
## SFX pool + music crossfade. Streams are optional: missing files never crash.

const SFX_DIR: String = "res://assets/audio/sfx_%s.ogg"
const POOL_SIZE: int = 12

var _pool: Array[AudioStreamPlayer] = []
var _cache: Dictionary = {}
var _last_play: Dictionary = {}
var _music: Array[AudioStreamPlayer] = []
var _music_idx: int = 0
var current_track: String = ""
var enabled: bool = true

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_ensure_bus("Music")
	_ensure_bus("SFX")
	for i in POOL_SIZE:
		var p := AudioStreamPlayer.new()
		p.bus = "SFX"
		add_child(p)
		_pool.append(p)
	for i in 2:
		var m := AudioStreamPlayer.new()
		m.bus = "Music"
		m.volume_db = -80.0
		add_child(m)
		_music.append(m)
	SettingsManager.changed.connect(func(_k: String) -> void: apply_settings())
	apply_settings()

func _ensure_bus(bus_name: String) -> void:
	if AudioServer.get_bus_index(bus_name) < 0:
		AudioServer.add_bus()
		var idx: int = AudioServer.bus_count - 1
		AudioServer.set_bus_name(idx, bus_name)
		AudioServer.set_bus_send(idx, "Master")

func apply_settings() -> void:
	var sm: Node = SettingsManager
	AudioServer.set_bus_mute(AudioServer.get_bus_index("Master"), sm.muted)
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"), linear_to_db(maxf(sm.music, 0.0001)))
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("SFX"), linear_to_db(maxf(sm.sfx, 0.0001)))

func _stream(name: String) -> AudioStream:
	if _cache.has(name):
		return _cache[name]
	var path: String = SFX_DIR % name
	var s: AudioStream = load(path) if ResourceLoader.exists(path) else null
	_cache[name] = s
	return s

func play(name: String, pitch: float = 1.0, vol_db: float = 0.0, min_gap: float = 0.03) -> void:
	var s: AudioStream = _stream(name)
	if s == null or not enabled:
		return
	var now: float = Time.get_ticks_msec() / 1000.0
	if now - float(_last_play.get(name, -1.0)) < min_gap:
		return
	_last_play[name] = now
	for p in _pool:
		if not p.playing:
			p.stream = s
			p.pitch_scale = pitch
			p.volume_db = vol_db
			p.play()
			return
	# pool exhausted: steal the first one
	_pool[0].stream = s
	_pool[0].pitch_scale = pitch
	_pool[0].play()

## Pop sound that rises with chain level, with small random variation.
func play_pop(level: int = 0, count: int = 3) -> void:
	var pitch: float = 0.92 + 0.06 * float(mini(level, 8)) + randf_range(-0.04, 0.05)
	play("pop", pitch, -2.0 + minf(float(count), 6.0) * 0.2, 0.025)

func play_music(track: String, fade: float = 1.2) -> void:
	if track == current_track:
		return
	current_track = track
	var path: String = "res://assets/audio/%s.ogg" % track
	if not ResourceLoader.exists(path):
		return
	var st: AudioStream = load(path)
	if st is AudioStreamOggVorbis:
		(st as AudioStreamOggVorbis).loop = true
	var old: AudioStreamPlayer = _music[_music_idx]
	_music_idx = 1 - _music_idx
	var nw: AudioStreamPlayer = _music[_music_idx]
	nw.stream = st
	nw.volume_db = -60.0
	nw.play()
	var tw: Tween = create_tween().set_parallel(true)
	tw.tween_property(nw, "volume_db", -6.0, fade)
	tw.tween_property(old, "volume_db", -60.0, fade)
	tw.chain().tween_callback(old.stop)

func stop_music(fade: float = 0.8) -> void:
	current_track = ""
	for m in _music:
		var tw: Tween = create_tween()
		tw.tween_property(m, "volume_db", -70.0, fade)
		tw.tween_callback(m.stop)

func duck_music(db: float, secs: float = 0.4) -> void:
	var m: AudioStreamPlayer = _music[_music_idx]
	var tw: Tween = create_tween()
	tw.tween_property(m, "volume_db", db, 0.1)
	tw.tween_interval(secs)
	tw.tween_property(m, "volume_db", -6.0, 0.5)
