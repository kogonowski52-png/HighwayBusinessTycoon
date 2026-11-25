"""Compose and synthesize the original Route 17 music and soundscape."""
from pathlib import Path
import math
import subprocess

import numpy as np

RATE = 24_000
OUT = Path(__file__).resolve().parents[2] / "assets/audio"
RNG = np.random.default_rng(21818)


def encode(name, wave):
    wave = np.clip(wave, -0.985, 0.985)
    channels = 1 if wave.ndim == 1 else wave.shape[1]
    pcm = (wave * 32767).astype("<i2")
    subprocess.run(["ffmpeg", "-hide_banner", "-loglevel", "error", "-y", "-f", "s16le",
                    "-ar", str(RATE), "-ac", str(channels), "-i", "pipe:0",
                    "-c:a", "libvorbis", "-q:a", "4", str(OUT / f"{name}.ogg")],
                   input=pcm.tobytes(), check=True)


def place(destination, sample, start, gain=1.0, pan=0.0):
    index = (np.arange(sample.size) + round(start * RATE)) % destination.shape[0]
    destination[index, 0] += sample * gain * math.sqrt((1 - pan) * .5)
    destination[index, 1] += sample * gain * math.sqrt((1 + pan) * .5)


def pluck(note, length, voice):
    time = np.arange(round(RATE * length)) / RATE
    freq = 440 * (2 ** ((note - 69) / 12))
    angle = 2 * np.pi * freq * time
    if voice == "rim":
        return (np.sin(angle) * .76 + np.sin(angle * 2.05) * .19 + np.sin(angle * 3.74) * .08) * (
            (1 - np.exp(-time * 162)) * np.exp(-time * 6) * (1 - time / length) ** .5)
    if voice == "bass":
        signal = np.sin(angle) + np.sin(angle * 2) * .23
        return signal * (1 - np.exp(-time * 52)) * np.exp(-time * 2.6) * (1 - time / length)
    shaped = np.sin(angle + .16 * np.sin(angle * 2)) + .28 * np.sin(angle * 2.007) * np.exp(-time * 2)
    shaped += .112 * np.sin(angle * 3.997) * np.exp(-time * 6)
    return shaped * (1 - np.exp(-time * 110)) * np.exp(-time * 2.0) * (1 - time / length) ** .6


def band_noise(seconds, lower, upper):
    count = round(seconds * RATE)
    wave = RNG.normal(0, 1, count)
    frequencies = np.fft.rfftfreq(count, 1 / RATE)
    filtered = np.fft.rfft(wave)
    filter_shape = (frequencies / max(1.0, lower)) ** 2
    filter_shape = filter_shape / (1 + filter_shape) / (1 + (frequencies / upper) ** 4)
    wave = np.fft.irfft(filtered * filter_shape, n=count)
    return wave / max(0.00001, np.max(np.abs(wave)))


def music(name, tempo, arrangement):
    beat = 60 / tempo
    out = np.zeros((round(64 * beat * RATE), 2), dtype=np.float64)
    theme = [
        (48, [60, 64, 67, 71], [76, 79, 81, 79]),
        (45, [57, 60, 64, 67], [76, 74, 72, 76]),
        (41, [57, 60, 64, 65], [69, 72, 76, 74]),
        (43, [55, 59, 62, 69], [74, 71, 69, 74]),
        (48, [60, 64, 67, 74], [76, 79, 83, 81]),
        (40, [59, 62, 64, 67], [79, 76, 74, 71]),
        (41, [57, 60, 64, 69], [72, 76, 79, 76]),
        (43, [55, 60, 62, 67], [74, 72, 71, 67]),
    ]
    for bar in range(16):
        root, chord, tune = theme[bar % 8]
        start = bar * 4 * beat
        place(out, pluck(root - (12 if arrangement == "night" else 0), 2.2 * beat, "bass"), start, .15)
        if arrangement != "menu":
            place(out, pluck(root + 7, 1.3 * beat, "bass"), start + 2 * beat, .095, -.12)
        if arrangement == "menu":
            for index, note in enumerate(chord):
                place(out, pluck(note, 4.5 * beat, "keys"), start + index * .035, .115 - index * .012, .29 * (index - 1.5))
        else:
            for note in range(8):
                place(out, pluck(chord[(note + bar % 2) % 4], 2.0 * beat, "rim" if arrangement == "day" else "keys"),
                      start + (.5 * note + (.055 if note % 2 else 0)) * beat, .090 if note % 2 else .109, -.28 + .18 * (note % 4))
        for index, offset in enumerate([.36, 1.35, 2.53, 3.22]):
            if arrangement == "night" and (index + bar) % 3 == 1:
                continue
            note = tune[(index + (bar >= 8)) % 4] - (12 if arrangement == "night" else 0)
            tone = pluck(note, beat * (1.9 if arrangement == "day" else 3.1), "rim" if index == 2 else "keys")
            place(out, tone, start + offset * beat, .13 if index == 1 else .116, .36 if index % 2 else -.12)
        if arrangement == "day":
            tap = band_noise(.085, 280, 1350) * np.exp(-np.arange(round(.085 * RATE)) / RATE * 46)
            for off in [.7, 2.75, 3.79]:
                place(out, tap, start + off * beat, .036, .24)
    original = out.copy()
    for delay, strength in [(.104, .13), (.173, .115), (.266, .085), (.382, .053)]:
        out += strength * np.roll(original[:, ::-1], round(delay * RATE), axis=0)
    return np.tanh(out * 1.36) * .85


def ambient(name):
    seconds = 6
    time = np.arange(RATE * seconds) / RATE
    tau = math.tau
    if name in ("cars", "truck"):
        pitch = 58 if name == "cars" else 37
        phase = tau * pitch * time + .7 * np.sin(tau * time * .5)
        tone = .55 * np.sin(phase) + .19 * np.sin(phase * 2) + .07 * np.sin(phase * 3)
        tone *= .24 + .09 * np.sin(tau * time / 3)
        return tone + band_noise(seconds, 45, 260) * (.29 if name == "truck" else .24)
    if name == "wind":
        return band_noise(seconds, 80, 1400) * (.13 + .09 * np.sin(tau * time / 6))
    if name == "pump":
        return band_noise(seconds, 290, 2100) * (.21 + .05 * np.sin(tau * time * 1.5)) + .053 * np.sin(tau * 103 * time)
    if name == "wash":
        return band_noise(seconds, 450, 4600) * (.19 + .13 * (.5 + .5 * np.sin(tau * time * .5)))
    wave = band_noise(seconds, 170, 950) * .08
    sequence = [(.68, 76), (1.81, 83), (3.20, 67), (3.41, 79), (5.22, 85)] if name == "diner" else [
        (.36, 53), (1.4, 62), (2.20, 59), (3.36, 52), (4.32, 64), (5.41, 55)]
    for at, pitch in sequence:
        strike = pluck(pitch, .29 if name == "diner" else .15, "rim")
        wave[round(at * RATE) + np.arange(strike.size)] += strike * (.21 if name == "diner" else .28)
    return wave


def cue(notes, voice="rim"):
    mix = np.zeros((round(RATE * .62), 2))
    for start, note, length, gain in notes:
        place(mix, pluck(note, length, voice), start, gain, -.21 + start)
    return mix


if __name__ == "__main__":
    for kind, tempo in [("menu", 84), ("day", 98), ("night", 79)]:
        encode("music_" + kind, music(kind, tempo, kind))
    for kind in ["cars", "truck", "wind", "pump", "wash", "workshop", "diner"]:
        encode("world_" + kind, ambient(kind))
    encode("ui_click", cue([(0, 89, .071, .30)]))
    encode("ui_new_site", cue([(0, 52, .25, .36), (.10, 67, .30, .34), (.19, 76, .35, .28)], "keys"))
    encode("ui_manager", cue([(0, 67, .21, .29), (.075, 71, .26, .32), (.162, 79, .35, .35)], "keys"))
    encode("ui_mission", cue([(0, 76, .16, .35), (.11, 84, .40, .29)]))
