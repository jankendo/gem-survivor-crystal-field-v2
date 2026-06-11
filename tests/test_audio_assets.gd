extends RefCounted

const REQUIRED := [
	"sfx_attack.wav",
	"sfx_enemy_hit.wav",
	"sfx_enemy_die.wav",
	"sfx_gem.wav",
	"sfx_levelup.wav",
	"sfx_reward_select.wav",
	"sfx_chest.wav",
	"sfx_evolution.wav",
	"sfx_damage.wav",
	"sfx_gameover.wav",
	"sfx_bestscore.wav"
]

func run(t) -> void:
	test_required_wavs_exist(t)
	test_audio_manager_reads_wavs(t)

func test_required_wavs_exist(t) -> void:
	for file_name in REQUIRED:
		var path: String = "res://assets/sounds/%s" % file_name
		t.assert_true(FileAccess.file_exists(path), "%s should exist" % path)

func test_audio_manager_reads_wavs(t) -> void:
	var manager := AudioManager.new()
	for file_name in REQUIRED:
		var path: String = "res://assets/sounds/%s" % file_name
		var stream: AudioStreamWAV = manager._load_pcm_wav(path)
		t.assert_true(stream != null, "%s should load through AudioManager WAV parser" % path)
		if stream != null:
			t.assert_eq(stream.mix_rate, 44100, "%s should keep expected sample rate" % path)
	manager.free()
