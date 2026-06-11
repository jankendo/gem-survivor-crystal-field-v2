import math
import struct
import wave
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
SOUNDS = ROOT / "assets" / "sounds"
RATE = 44_100


def envelope(t: float, duration: float) -> float:
    attack = min(0.015, duration * 0.2)
    release = min(0.08, duration * 0.45)
    if t < attack:
        return t / attack
    if t > duration - release:
        return max(0.0, (duration - t) / release)
    return 1.0


def synth(path: Path, notes: list[tuple[float, float]], volume: float = 0.35) -> None:
    duration = sum(length for _, length in notes)
    samples = []
    cursor = 0.0
    for freq, length in notes:
        note_samples = int(RATE * length)
        for i in range(note_samples):
            t = i / RATE
            global_t = cursor + t
            env = envelope(t, length)
            tone = math.sin(2 * math.pi * freq * t)
            tone += 0.35 * math.sin(2 * math.pi * freq * 2.0 * t)
            click = 0.08 * math.sin(2 * math.pi * 1200 * t) * max(0.0, 1.0 - t * 30.0)
            value = (tone * 0.75 + click) * env * volume
            samples.append(max(-1.0, min(1.0, value)))
        cursor += length
    with wave.open(str(path), "wb") as wav:
        wav.setnchannels(1)
        wav.setsampwidth(2)
        wav.setframerate(RATE)
        wav.writeframes(b"".join(struct.pack("<h", int(sample * 32767)) for sample in samples))


def main() -> None:
    SOUNDS.mkdir(parents=True, exist_ok=True)
    specs = {
        "sfx_attack.wav": [(640, 0.035)],
        "sfx_enemy_hit.wav": [(240, 0.05)],
        "sfx_enemy_die.wav": [(360, 0.05), (180, 0.08)],
        "sfx_gem.wav": [(900, 0.035), (1320, 0.045)],
        "sfx_levelup.wav": [(660, 0.06), (990, 0.08), (1320, 0.12)],
        "sfx_reward_select.wav": [(720, 0.06), (1080, 0.08)],
        "sfx_chest.wav": [(520, 0.05), (780, 0.05), (1170, 0.12)],
        "sfx_evolution.wav": [(330, 0.06), (660, 0.08), (990, 0.08), (1480, 0.18)],
        "sfx_damage.wav": [(150, 0.16)],
        "sfx_gameover.wav": [(330, 0.12), (220, 0.16), (165, 0.22)],
        "sfx_bestscore.wav": [(660, 0.06), (880, 0.06), (1100, 0.06), (1480, 0.16)],
    }
    for filename, notes in specs.items():
        synth(SOUNDS / filename, notes)
    print(f"generated {len(specs)} WAV assets in {SOUNDS}")


if __name__ == "__main__":
    main()
