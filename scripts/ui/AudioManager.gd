extends Node
class_name AudioManager

const FILES := {
	"attack": "res://assets/sounds/sfx_attack.wav",
	"enemy_hit": "res://assets/sounds/sfx_enemy_hit.wav",
	"enemy_die": "res://assets/sounds/sfx_enemy_die.wav",
	"gem": "res://assets/sounds/sfx_gem.wav",
	"levelup": "res://assets/sounds/sfx_levelup.wav",
	"reward_select": "res://assets/sounds/sfx_reward_select.wav",
	"chest": "res://assets/sounds/sfx_chest.wav",
	"evolution": "res://assets/sounds/sfx_evolution.wav",
	"damage": "res://assets/sounds/sfx_damage.wav",
	"gameover": "res://assets/sounds/sfx_gameover.wav",
	"bestscore": "res://assets/sounds/sfx_bestscore.wav"
}

const VOLUMES := {
	"attack": -12.0,
	"enemy_hit": -10.0,
	"enemy_die": -8.0,
	"gem": -7.0,
	"levelup": -6.0,
	"reward_select": -7.0,
	"chest": -6.0,
	"evolution": -5.0,
	"damage": -9.0,
	"gameover": -7.0,
	"bestscore": -7.0
}

var streams: Dictionary = {}
var players: Array = []
var next_player := 0
var cooldown_until: Dictionary = {}
var audio_event_count := 0

const POOL_SIZE := 8
const COOLDOWN_MS := {
	"attack": 55,
	"enemy_hit": 45,
	"enemy_die": 35,
	"gem": 45,
	"damage": 90
}

func _ready() -> void:
	for key in FILES.keys():
		var path := String(FILES[key])
		if FileAccess.file_exists(path):
			var stream: AudioStreamWAV = _load_pcm_wav(path)
			if stream != null:
				streams[key] = stream
	for i in range(POOL_SIZE):
		var player := AudioStreamPlayer.new()
		player.name = "SfxPlayer%d" % i
		add_child(player)
		players.append(player)

func play_sfx(name: String) -> bool:
	if DisplayServer.get_name() == "headless":
		return false
	if not streams.has(name):
		return false
	var now := Time.get_ticks_msec()
	if now < int(cooldown_until.get(name, 0)):
		return false
	cooldown_until[name] = now + int(COOLDOWN_MS.get(name, 20))
	if players.is_empty():
		return false
	var player: AudioStreamPlayer = players[next_player]
	next_player = (next_player + 1) % players.size()
	player.stop()
	player.stream = streams[name]
	player.volume_db = float(VOLUMES.get(name, -8.0))
	player.play()
	audio_event_count += 1
	return true

func _load_pcm_wav(path: String) -> AudioStreamWAV:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return null
	var bytes: PackedByteArray = file.get_buffer(file.get_length())
	if bytes.size() < 44:
		return null
	if not _matches(bytes, 0, [82, 73, 70, 70]) or not _matches(bytes, 8, [87, 65, 86, 69]):
		return null
	var offset := 12
	var channels := 1
	var sample_rate := 44100
	var bits_per_sample := 16
	var pcm := PackedByteArray()
	while offset + 8 <= bytes.size():
		var is_fmt := _matches(bytes, offset, [102, 109, 116, 32])
		var is_data := _matches(bytes, offset, [100, 97, 116, 97])
		var chunk_size := _u32(bytes, offset + 4)
		var chunk_data := offset + 8
		if is_fmt and chunk_data + 16 <= bytes.size():
			channels = _u16(bytes, chunk_data + 2)
			sample_rate = _u32(bytes, chunk_data + 4)
			bits_per_sample = _u16(bytes, chunk_data + 14)
		elif is_data and chunk_data + chunk_size <= bytes.size():
			pcm = bytes.slice(chunk_data, chunk_data + chunk_size)
			break
		offset = chunk_data + chunk_size
		if offset % 2 == 1:
			offset += 1
	if pcm.is_empty() or bits_per_sample != 16:
		return null
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.stereo = channels == 2
	stream.data = pcm
	return stream

func _matches(bytes: PackedByteArray, offset: int, pattern: Array) -> bool:
	if offset + pattern.size() > bytes.size():
		return false
	for i in range(pattern.size()):
		if int(bytes[offset + i]) != int(pattern[i]):
			return false
	return true

func _u16(bytes: PackedByteArray, offset: int) -> int:
	return int(bytes[offset]) | (int(bytes[offset + 1]) << 8)

func _u32(bytes: PackedByteArray, offset: int) -> int:
	return int(bytes[offset]) | (int(bytes[offset + 1]) << 8) | (int(bytes[offset + 2]) << 16) | (int(bytes[offset + 3]) << 24)
