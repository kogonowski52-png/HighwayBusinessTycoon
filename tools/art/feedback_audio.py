"""Generate short, original plucked sounds for the Route 17 user interface."""
import math
import struct
import wave
from pathlib import Path

SAMPLE_RATE = 24_000
SOUNDS = {
    "sale": [(0.00, 740, 0.113, 0.37), (0.067, 988, 0.161, 0.32)],
    "reward": [(0.00, 523, 0.23, 0.31), (0.065, 659, 0.24, 0.27), (0.127, 880, 0.29, 0.25)],
    "build": [(0.00, 262, 0.27, 0.31), (0.075, 392, 0.24, 0.24), (0.139, 523, 0.34, 0.35)],
    "rank": [(0.00, 440, 0.25, 0.24), (0.073, 587, 0.28, 0.29), (0.139, 740, 0.29, 0.27),
             (0.237, 988, 0.36, 0.25)],
}


def sample(at, notes):
    value = 0.0
    for start, pitch, length, amplitude in notes:
        time = at - start
        if 0.0 <= time < length:
            angle = math.tau * pitch * time
            volume = (1.0 - math.exp(-time * 210)) * math.exp(-time * 9.3) * (1 - time / length) ** 1.5
            tone = math.sin(angle) + 0.28 * math.sin(angle * 2) + 0.09 * math.sin(angle * 3.01)
            value += tone * volume * amplitude
    return round(27_000 * math.tanh(value))


folder = Path(__file__).resolve().parents[2] / "assets/audio"
for name, notes in SOUNDS.items():
    end = max(start + length for start, _, length, _ in notes)
    with wave.open(str(folder / (name + ".wav")), "wb") as stream:
        stream.setparams((1, 2, SAMPLE_RATE, 0, "NONE", "not compressed"))
        stream.writeframes(b"".join(struct.pack("<h", sample(index / SAMPLE_RATE, notes))
                                    for index in range(math.ceil(end * SAMPLE_RATE))))
